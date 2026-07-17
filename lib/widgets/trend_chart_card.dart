import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/chat_event.dart';

/// Biomarker trend card shown under an assistant chat bubble when a
/// trajectory query returns a [ChartPayload] (Chart.js-ready data from
/// TrajectoryService.get_chart_data()).
class TrendChartCard extends StatelessWidget {
  final ChartPayload chart;
  const TrendChartCard({super.key, required this.chart});

  Color get _trendColor => switch (chart.trendDirection) {
        'INCREASING' => const Color(0xFFef4444),
        'DECREASING' => const Color(0xFF10b981),
        _            => const Color(0xFF64748b),
      };

  IconData get _trendIcon => switch (chart.trendDirection) {
        'INCREASING' => Icons.trending_up_rounded,
        'DECREASING' => Icons.trending_down_rounded,
        _            => Icons.trending_flat_rounded,
      };

  @override
  Widget build(BuildContext context) {
    if (chart.values.isEmpty) return const SizedBox.shrink();
    final minY = [...chart.values, chart.referenceLow ?? chart.values.first]
        .reduce((a, b) => a < b ? a : b);
    final maxY = [...chart.values, chart.referenceHigh ?? chart.values.first]
        .reduce((a, b) => a > b ? a : b);
    final pad  = ((maxY - minY).abs() * 0.15).clamp(0.5, double.infinity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${chart.displayName}${chart.unit.isNotEmpty ? " (${chart.unit})" : ""}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1e293b))),
          ),
          Icon(_trendIcon, size: 14, color: _trendColor),
          const SizedBox(width: 3),
          Text('${chart.pctChange >= 0 ? "+" : ""}${chart.pctChange.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _trendColor)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: minY - pad, maxY: maxY + pad,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(0), style: const TextStyle(fontSize: 9, color: Color(0xFF94a3b8)))),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.round();
                      if (i < 0 || i >= chart.labels.length) return const SizedBox.shrink();
                      if (chart.labels.length > 4 && i % (chart.labels.length ~/ 4).clamp(1, 100) != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(chart.labels[i], style: const TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                if (chart.referenceLow != null)
                  HorizontalLine(y: chart.referenceLow!, color: const Color(0xFFcbd5e1),
                      strokeWidth: 1, dashArray: [4, 4]),
                if (chart.referenceHigh != null)
                  HorizontalLine(y: chart.referenceHigh!, color: const Color(0xFFcbd5e1),
                      strokeWidth: 1, dashArray: [4, 4]),
              ]),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i < chart.values.length; i++) FlSpot(i.toDouble(), chart.values[i])],
                  isCurved: true,
                  color: const Color(0xFF6366f1),
                  barWidth: 2.5,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: const Color(0xFF6366f1).withValues(alpha: 0.08)),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
