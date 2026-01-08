import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ExpenseChart extends StatefulWidget {
  final List<Map<String, dynamic>> expenseData;

  const ExpenseChart({
    Key? key,
    required this.expenseData,
  }) : super(key: key);

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient:
            isDark ? AppTheme.glassGradientDark : AppTheme.glassGradientLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Expense Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.trending_up_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('This month'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1.25,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 54,
                      sections: _showingSections(),
                      centerSpaceColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Column(
                  children: _buildLegend(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLegend() {
    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (var item in widget.expenseData) {
      final category = item['category'] as String? ?? 'Other';
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }

    // Check if there's no data
    if (categoryTotals.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'No expense data for current month',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      ];
    }

    // Sort categories by amount (descending)
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 6 categories for better readability, group the rest as "Other"
    if (sortedCategories.length > 6) {
      final topCategories = sortedCategories.take(5).toList();
      final otherCategories = sortedCategories.skip(5);

      // Calculate total for "Other" category
      final otherTotal =
          otherCategories.fold(0.0, (sum, entry) => sum + entry.value);

      // Add "Other" as a single category
      if (otherTotal > 0) {
        topCategories.add(MapEntry('Other', otherTotal));
      }

      sortedCategories.clear();
      sortedCategories.addAll(topCategories);
    }

    // Calculate total for percentage display
    final totalAmount =
        sortedCategories.fold(0.0, (sum, entry) => sum + entry.value);

    // Create legend items
    return sortedCategories.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;
      final color = _getCategoryColor(category);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              NumberFormat.currency(symbol: 'NPR ', decimalDigits: 0)
                  .format(amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _showingSections() {
    // Group expenses by category if not already done
    final Map<String, double> categoryTotals = {};
    for (var item in widget.expenseData) {
      final category = item['category'] as String? ?? 'Other';
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }

    // Calculate total amount for percentage calculation
    final totalAmount =
        categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    if (totalAmount <= 0) {
      // Return a placeholder section if there are no expenses
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: 'No Data',
          radius: 110.0,
          titleStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        )
      ];
    }

    // Sort categories by amount (descending)
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 6 categories for better readability, group the rest as "Other"
    if (sortedCategories.length > 6) {
      final topCategories = sortedCategories.take(5).toList();
      final otherCategories = sortedCategories.skip(5);

      // Calculate total for "Other" category
      final otherTotal =
          otherCategories.fold(0.0, (sum, entry) => sum + entry.value);

      // Add "Other" as a single category
      if (otherTotal > 0) {
        topCategories.add(MapEntry('Other', otherTotal));
      }

      sortedCategories.clear();
      sortedCategories.addAll(topCategories);
    } // Create pie sections
    return sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / totalAmount) * 100;
      final isTouched = index == touchedIndex;

      // Increase size contrast between touched and untouched sections
      final fontSize = isTouched ? 19.0 : 13.0;
      final radius = isTouched ? 125.0 : 96.0;
      final color = _getCategoryColor(category);

      // Add a bright border to highlight touched sections
      final borderSide = isTouched
          ? BorderSide(color: Colors.white, width: 3)
          : BorderSide(color: color.withOpacity(0.5), width: 1);

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        badgeWidget: isTouched
            ? _CategoryBadge(category: category, amount: amount)
            : null,
        badgePositionPercentageOffset: 1.1,
        borderSide: borderSide,
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    // Return consistent colors for each category with more vibrant and distinguishable colors
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF6B6B); // Coral
      case 'transport':
        return const Color(0xFF00A3FF); // Blue
      case 'housing':
        return const Color(0xFF12B0A5); // Teal
      case 'utilities':
        return const Color(0xFF9C6BFF); // Violet
      case 'entertainment':
        return const Color(0xFFFFB341); // Amber
      case 'healthcare':
        return const Color(0xFF1DD1A1); // Green
      case 'education':
        return const Color(0xFF4E54C8); // Indigo
      case 'shopping':
        return const Color(0xFFEF72A7); // Pink
      case 'travel':
        return const Color(0xFF6EC3FF); // Sky
      case 'other':
        return const Color(0xFF7B8FA6); // Muted blue grey
      default:
        final hue = (category.hashCode % 12) * 30.0;
        return HSLColor.fromAHSL(1.0, hue, 0.7, 0.55).toColor();
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  final double amount;

  const _CategoryBadge({
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: 'NPR ', decimalDigits: 0)
                .format(amount),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
