import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartDataModel {
  final String label;
  final double value;
  final Color color;

  PieChartDataModel({
    required this.label,
    required this.value,
    required this.color,
  });
}

class CustomPieChartWidget extends StatefulWidget {
  final List<PieChartDataModel> data;
  final String centerText;
  final Function(PieChartDataModel)? onSectionTap;

  const CustomPieChartWidget({
    super.key,
    required this.data,
    this.centerText = '',
    this.onSectionTap,
  });

  @override
  State<CustomPieChartWidget> createState() => _CustomPieChartWidgetState();
}

class _CustomPieChartWidgetState extends State<CustomPieChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
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
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                      
                      if (event is FlTapUpEvent && 
                          pieTouchResponse != null && 
                          pieTouchResponse.touchedSection != null) {
                         final idx = pieTouchResponse.touchedSection!.touchedSectionIndex;
                         if (idx >= 0 && idx < widget.data.length && widget.onSectionTap != null) {
                           widget.onSectionTap!(widget.data[idx]);
                         }
                      }
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: showingSections(),
                ),
              ),
              if (widget.centerText.isNotEmpty)
                Text(
                  widget.centerText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.data.map((item) {
            return GestureDetector(
              onTap: widget.onSectionTap != null ? () => widget.onSectionTap!(item) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(widget.data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final dataItem = widget.data[i];
      
      // Calculate percentage for label
      double total = widget.data.fold(0, (sum, item) => sum + item.value);
      double percentage = total > 0 ? (dataItem.value / total) * 100 : 0;

      return PieChartSectionData(
        color: dataItem.color,
        value: dataItem.value,
        title: isTouched ? '${dataItem.label}\n${percentage.toStringAsFixed(1)}%' : '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
        ),
      );
    });
  }
}
