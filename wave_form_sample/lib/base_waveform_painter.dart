import 'dart:async';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave_form_sample/trend_data_point.dart';

class BaseWaveformPainter extends CustomPainter {
  List<TrendDataPoint> currentChartEntries = [];
  List<TrendDataPoint> previousChartEntries = [];
  List<Color> currentChartSetColors = [];
  List<Color> previousChartSetColors = [];

  //axis min and max variables
  late double xAxisMinimum;
  late double xAxisMaximum;
  late double yAxisMinimum;
  late double yAxisMaximum;

  BaseWaveformPainter(
    this.xAxisMinimum,
    this.xAxisMaximum,
    this.yAxisMinimum,
    this.yAxisMaximum,
    this.currentChartEntries,
    this.previousChartEntries,
    this.currentChartSetColors,
    this.previousChartSetColors,
  );

  @override
  void paint(Canvas canvas, Size size) {
    double xAxisScale = size.width / (xAxisMaximum - xAxisMinimum);
    double yAxisScale = size.height / (yAxisMaximum - yAxisMinimum);

    var paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var path = Path();
    //draw current chart set
    for (int i = 0; i < currentChartEntries.length; i++) {
      var chartEntry = currentChartEntries[i];
      var x = (chartEntry.refTime * xAxisScale);
      var y = (size.height - chartEntry.value * yAxisScale);
      if (i == 0) {
        path.moveTo(x, y);
        //paint.color = currentChartSetColors[i];
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    path = Path();
    //draw current chart set
    for (int i = 0; i < previousChartEntries.length; i++) {
      var chartEntry = previousChartEntries[i];
      var x = (chartEntry.refTime * xAxisScale);
      var y = (size.height - chartEntry.value * yAxisScale);
      if (i == 0) {
        path.moveTo(x, y);
        //paint.color = currentChartSetColors[i];
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
