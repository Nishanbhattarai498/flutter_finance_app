import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ExpenseChart extends StatelessWidget {
  final List<Map<String, dynamic>> expenseData;

  const ExpenseChart({
    Key? key,
    required this.expenseData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppTheme.primaryColor.withOpacity(0.8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${DateFormat('MMM').format(expenseData[groupIndex]['date'])}\n'
                  '${NumberFormat.currency(symbol: 'NPR ', decimalDigits: 2, locale: 'en_NP').format(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < expenseData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM')
                            .format(expenseData[value.toInt()]['date']),
                        style: const TextStyle(
                          color: AppTheme.textColorLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compactCurrency(symbol: 'NPR ').format(value),
                    style: const TextStyle(
                      color: AppTheme.textColorLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: _createBarGroups(),
        ),
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var data in expenseData) {
      if (data['amount'] > max) {
        max = data['amount'];
      }
    }
    return max * 1.2; // Add 20% padding
  }

  List<BarChartGroupData> _createBarGroups() {
    return List.generate(expenseData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: expenseData[index]['amount'],
            color: AppTheme.primaryColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }
}
