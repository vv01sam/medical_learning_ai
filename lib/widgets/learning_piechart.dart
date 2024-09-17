import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart'; // ローカライズのインポートを追加
import 'package:medical_learning_ai/models/progress_tracker.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/interval_kind.dart'; // IntervalKindのインポートを追加

class DeckProgressPieChart extends StatefulWidget {
  final ProgressTracker progressTracker;

  DeckProgressPieChart({required this.progressTracker});

  @override
  _DeckProgressPieChartState createState() => _DeckProgressPieChartState();
}

class _DeckProgressPieChartState extends State<DeckProgressPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
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
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: showingSections(),
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> showingSections() {
    final cardStatusData = widget.progressTracker.cardStatusData;
    if (cardStatusData.values.every((value) => value == 0)) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: AppLocalizations.of(context)!.noData,
          radius: 100,
          titleStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ];
    }

    return cardStatusData.entries.map((entry) {
      final isTouched =
          cardStatusData.entries.toList().indexOf(entry) == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;

      // IntervalKindを直接使用してカラーを取得
      final color = _getColorForIntervalKind(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // IntervalKindに基づいた色を直接取得
  Color _getColorForIntervalKind(IntervalKind intervalKind) {
    switch (intervalKind) {
      case IntervalKind.newCard:
        return Color(0xFF4AD1B0); // electric blue
      case IntervalKind.learning:
        return Color(0xFF9D8FD9); // banana
      case IntervalKind.review:
        return Color(0xFFFF7F6A); // watermelon
      case IntervalKind.relearning:
        return Color(0xFFFFCA3A); // canteloupe
      default:
        return Colors.grey.shade400; // Default color for unknown status
    }
  }

  // IntervalKindからローカライズされた英語のステータスラベルを取得
  String _getStatusLabel(IntervalKind status) {
    switch (status) {
      case IntervalKind.newCard:
        return AppLocalizations.of(context)!.newCardsLabel;
      case IntervalKind.learning:
        return AppLocalizations.of(context)!.learningCardsLabel;
      case IntervalKind.review:
        return AppLocalizations.of(context)!.reviewCardsLabel;
      case IntervalKind.relearning:
        return AppLocalizations.of(context)!.relearningCardsLabel;
      default:
        return AppLocalizations.of(context)!.unknownStatus;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({Key? key, required this.color, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}