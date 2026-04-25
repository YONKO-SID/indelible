import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/activity_event.dart';

/// Displays audit trail of forensic events.
///
/// Fetches real data from backend and shows recent activity like:
/// - Asset protection events
/// - Verification results
/// - System alerts
///
/// Each activity item shows:
/// - Icon and color-coded type
/// - Title and subtitle
/// - Relative timestamp
class RecentActivityList extends StatefulWidget {
  const RecentActivityList({super.key});

  @override
  State<RecentActivityList> createState() => _RecentActivityListState();
}

class _RecentActivityListState extends State<RecentActivityList> {
  late Future<List<ActivityEvent>> _eventsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _eventsFuture = _apiService.fetchActivityEvents(limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Timeline',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Recent protection and verification events',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Full logs export coming soon',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                );
              },
              child: Text(
                'VIEW ALL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<ActivityEvent>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingList();
            } else if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final events = snapshot.data!;
              return Column(
                children: List.generate(
                  events.length,
                  (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityCard(events[index]),
                    );
                  },
                ),
              );
            } else {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No activity yet',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Shimmer(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorContainer.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.errorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load activity: $error',
              style: GoogleFonts.inter(
                color: AppColors.errorContainer,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityEvent event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: event.color.withValues(alpha: 0.6),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              event.icon,
              color: event.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            event.readableTime,
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple shimmer loading animation
class Shimmer extends StatefulWidget {
  const Shimmer({super.key});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Container(
        color: AppColors.surfaceBright.withValues(alpha: _opacity.value),
      ),
    );
  }
}
