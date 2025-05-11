import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Monthly Expense Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.3,
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
                  sectionsSpace: 3, // Slightly larger spacing between sections
                  centerSpaceRadius:
                      50, // Larger center hole for better readability
                  sections: _showingSections(),
                ),
              ),
            ),
            const SizedBox(height: 16), // Add legend title
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Expense Categories Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Column(
              children: _buildLegend(),
            ),
          ],
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

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            // Add percentage next to amount
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(width: 8),
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
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 130.0 : 100.0;
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
        return const Color(0xFFFF5252); // Bright red
      case 'transport':
        return const Color(0xFF448AFF); // Strong blue
      case 'housing':
        return const Color(0xFF66BB6A); // Green
      case 'utilities':
        return const Color(0xFF9C27B0); // Purple
      case 'entertainment':
        return const Color(0xFFFF9800); // Orange
      case 'healthcare':
        return const Color(0xFF00BCD4); // Cyan
      case 'education':
        return const Color(0xFF3F51B5); // Indigo
      case 'shopping':
        return const Color(0xFFEC407A); // Pink
      case 'travel':
        return const Color(0xFFFFEB3B); // Yellow
      case 'other':
        return const Color(0xFF78909C); // Blue Grey
      default:
        // Generate a color based on the category name with better contrast
        final hue =
            (category.hashCode % 12) * 30.0; // Space out the hues by 30 degrees
        return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5)
            .toColor(); // More saturated colors
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
