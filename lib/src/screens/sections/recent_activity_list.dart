import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';

// ═══════════════════════════════════════════════════════════
/// Displays audit trail of forensic events.
///
/// Shows recent system notifications like:
/// - Watermark verification results
/// - Asset synchronization events
/// - Routine maintenance snapshots
///
/// Each alert item shows icon, title, subtitle, ID, and time.
/// Color-coded by severity (primary=success, secondary=warning).
// ═══════════════════════════════════════════════════════════
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

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
                    'Recent Alerts',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Audit trail of forensic events and system notifications.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'VIEW FULL LOGS',
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
        _buildAlertItem(
          title: 'Watermark Re-Verification Success',
          subtitle: 'Batch 884 completed with 100% integrity match.',
          id: '#FW-9902-X',
          time: '14:22:01 UTC',
          icon: Icons.security,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          title: 'External Mirror Detected',
          subtitle:
              'Asset \'Campaign_Hero.png\' synchronized on secondary node.',
          id: '#MS-1102-A',
          time: '12:05:48 UTC',
          icon: Icons.sync,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          title: 'Routine Snapshot Taken',
          subtitle: 'Global forensic state preserved for archival compliance.',
          id: '#RS-0021-Z',
          time: '09:00:00 UTC',
          icon: Icons.history,
          color: AppColors.outline,
        ),
      ],
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String subtitle,
    required String id,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.4), width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'ID: $id',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              time,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
