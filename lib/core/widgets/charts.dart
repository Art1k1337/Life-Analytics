import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/day_entry.dart';
import '../theme/app_colors.dart';

class LifeLineChart extends StatelessWidget {
  const LifeLineChart({
    super.key,
    required this.entries,
    required this.selector,
    this.maxY = 100,
    this.yLabels,
  });

  final List<DayEntry> entries;
  final double Function(DayEntry entry) selector;
  final double maxY;
  final List<double>? yLabels;

  @override
  Widget build(BuildContext context) {
    final points = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    if (points.isEmpty) {
      return SizedBox(
        height: 190,
        child: Center(
          child: Text(
            'Нет данных за период',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4)),
          ),
        ),
      );
    }

    final labels = yLabels ?? [0, 25, 50, 75, 100];
    final interval = maxY / (labels.length - 1);

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .06),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  final idx = labels.indexOf(value);
                  final text = idx >= 0 ? value.toInt().toString() : '';
                  return Text(
                    text,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: _bottomInterval(points.length),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                  final date = points[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('dd.MM').format(date),
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final idx = spot.x.toInt();
                final dateStr = idx >= 0 && idx < points.length
                    ? DateFormat('dd.MM').format(points[idx].date)
                    : '';
                return LineTooltipItem(
                  '$dateStr\n${spot.y.toStringAsFixed(1)}',
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white, height: 1.4),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3,
              gradient: const LinearGradient(colors: [AppColors.blue, AppColors.violet]),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.blue,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue.withValues(alpha: .2),
                    AppColors.violet.withValues(alpha: .02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), selector(points[i]).clamp(0, maxY)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _bottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 31) return 5;
    return 7;
  }
}

class CalendarHeatMap extends StatelessWidget {
  const CalendarHeatMap({super.key, required this.entries, this.onDayTap});

  final List<DayEntry> entries;
  final ValueChanged<DayEntry>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final days = sorted.length > 35 ? sorted.sublist(sorted.length - 35) : sorted;
    final slots = List<DayEntry?>.filled(35, null);
    for (var i = 0; i < days.length; i++) {
      slots[i] = days[i];
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 35,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final entry = slots[index];
        final color = entry == null
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .06)
            : entry.lifeIndex >= 75
                ? AppColors.mint
                : entry.lifeIndex >= 55
                    ? AppColors.amber
                    : AppColors.coral;
        return Tooltip(
          message: entry == null ? 'Нет данных' : '${entry.dayKey}: ${entry.lifeIndex}',
          child: InkWell(
            onTap: entry == null ? null : () => onDayTap?.call(entry),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: color.withValues(alpha: entry == null ? .4 : .85),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: entry == null
                  ? null
                  : Text(
                      entry.date.day.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: entry.lifeIndex >= 55 ? Colors.white : Colors.white.withValues(alpha: .9),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
