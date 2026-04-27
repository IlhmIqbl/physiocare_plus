import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/models/session_model.dart';

class PainTrendChart extends StatelessWidget {
  const PainTrendChart({super.key, required this.progressEntries});

  final List<ProgressModel> progressEntries;

  @override
  Widget build(BuildContext context) {
    if (progressEntries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final beforeSpots = progressEntries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.painLevelBefore.toDouble());
    }).toList();

    final afterSpots = progressEntries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.painLevelAfter.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 10,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 2,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.4)),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= progressEntries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: beforeSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.red,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
            ),
            LineChartBarData(
              spots: afterSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklySessionsChart extends StatelessWidget {
  const WeeklySessionsChart({super.key, required this.sessions});

  final List<SessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Build a map: weekday index (0=Mon … 6=Sun) -> count for the last 7 days
    final counts = List<int>.filled(7, 0);
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    for (final session in sessions) {
      if (!session.completed) continue;
      final date = session.startedAt;
      if (date.isBefore(cutoff)) continue;
      // weekday: 1=Mon … 7=Sun  → index 0–6
      final idx = date.weekday - 1;
      counts[idx]++;
    }

    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = (counts.reduce((a, b) => a > b ? a : b) + 1).toDouble();

    final hasAny = counts.any((c) => c > 0);
    if (!hasAny) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No sessions this week',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final barGroups = List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: counts[i].toDouble(),
            color: Colors.teal,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.4)),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[i],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  }
}
