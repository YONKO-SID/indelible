import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/themes/app_colors.dart';
import '../services/api_service.dart';
import 'layouts/dashboard_layout.dart';

// ═══════════════════════════════════════════════════════════════
/// Activity Screen — Audit trail, upload graphs, and live logs.
///
/// Sections:
///   1. Bar chart — assets protected per day (last 7 days)
///   2. Key metric cards (total uploads, verifications, size)
///   3. Full audit log table from /logs endpoint
// ═══════════════════════════════════════════════════════════════
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/logs'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Compute bar data (uploads per day over last 7 days) ─────
  List<BarChartGroupData> _buildBarGroups() {
    final Map<int, int> countsPerDay = {};
    final now = DateTime.now();

    for (var log in _logs) {
      try {
        final ts = DateTime.parse(log['watermark_timestamp'] as String? ?? log['protected_at'] as String);
        final daysAgo = now.difference(ts).inDays;
        if (daysAgo < 7) {
          countsPerDay[daysAgo] = (countsPerDay[daysAgo] ?? 0) + 1;
        }
      } catch (_) {}
    }

    return List.generate(7, (i) {
      final day = 6 - i;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: (countsPerDay[day] ?? 0).toDouble(),
          color: AppColors.primary,
          width: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ]);
    });
  }

  String _dayLabel(int index) {
    final now = DateTime.now();
    final day = now.subtract(Duration(days: 6 - index));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[day.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/activity',
      child: RefreshIndicator(
        onRefresh: _fetchLogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 12),
                  Text('Activity Log',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.bold,
                    )),
                  const Spacer(),
                  IconButton(
                    onPressed: _fetchLogs,
                    icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.primary))
              else if (_error != null)
                _buildError()
              else ...[
                // ── Metric Cards ─────────────────────────────
                _buildMetricCards(),
                const SizedBox(height: 32),

                // ── Bar Chart ────────────────────────────────
                _buildChartCard(),
                const SizedBox(height: 32),

                // ── Audit Log Table ───────────────────────────
                _buildAuditLog(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    final totalSize = _logs.fold<double>(0, (sum, l) => sum + ((l['size_kb'] as num?)?.toDouble() ?? 0));
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 600 ? 3 : 1;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.2,
        children: [
          _metricCard('UPLOADS', '${_logs.length}', Icons.upload_rounded, AppColors.tertiary),
          _metricCard('VERIFICATIONS', '${_logs.where((l) => l['creator_fingerprint'] != null).length}', Icons.verified_rounded, AppColors.primary),
          _metricCard('TOTAL SIZE', '${(totalSize / 1024).toStringAsFixed(1)} MB', Icons.storage_rounded, AppColors.secondary),
        ],
      );
    });
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 24, color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }

  Widget _buildChartCard() {
    final groups = _buildBarGroups();
    final maxY = groups.fold<double>(1, (m, g) => g.barRods.first.toY > m ? g.barRods.first.toY : m);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Assets Protected — Last 7 Days',
          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            maxY: maxY + 1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: AppColors.outlineVariant.withValues(alpha: 0.3), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                getTitlesWidget: (v, _) => Text(_dayLabel(v.toInt()), style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)))),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: groups,
          )),
        ),
      ]),
    );
  }

  Widget _buildAuditLog() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Full Audit Trail',
        style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
      const SizedBox(height: 16),
      ..._logs.map((log) => _buildLogRow(log)),
    ]);
  }

  Widget _buildLogRow(Map<String, dynamic> log) {
    final fp = log['creator_fingerprint'] as String? ?? 'unverified';
    final isVerified = fp != 'unverified';
    final color = isVerified ? AppColors.primary : AppColors.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color.withValues(alpha: 0.6), width: 3)),
      ),
      child: Row(children: [
        Icon(isVerified ? Icons.shield_outlined : Icons.help_outline, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log['filename'] as String? ?? '—',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onSurface),
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(fp, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: isVerified ? AppColors.primary : AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
        ])),
        Text('${log['size_kb'] ?? '?'} KB', style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.errorContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.wifi_off, color: AppColors.errorContainer),
        const SizedBox(width: 12),
        Expanded(child: Text(_error!, style: GoogleFonts.inter(color: AppColors.errorContainer))),
        TextButton(onPressed: _fetchLogs, child: const Text('Retry')),
      ]),
    );
  }
}
