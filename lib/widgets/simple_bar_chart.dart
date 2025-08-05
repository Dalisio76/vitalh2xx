// ===== SIMPLE BAR CHART =====
// lib/app/widgets/charts/simple_bar_chart.dart

import 'package:flutter/material.dart';

class SimpleBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double height;

  const SimpleBarChart({Key? key, required this.data, this.height = 200})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Sem dados para exibir',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final maxValue = data
        .map((item) => item['value'] as double)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            data.map((item) {
              final value = item['value'] as double;
              final name = item['name'] as String;
              final color = item['color'] as Color;
              final percentage = maxValue > 0 ? value / maxValue : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Container(
                        width: double.infinity,
                        height: (height - 60) * percentage,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        name,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
