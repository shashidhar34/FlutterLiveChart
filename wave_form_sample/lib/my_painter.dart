import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave_form_sample/base_waveform_painter.dart';
import 'package:wave_form_sample/trend_data_point.dart';

class MyPainter extends StatefulWidget {
  @override
  _MyPainterState createState() => _MyPainterState();
}

class _MyPainterState extends State<MyPainter> {
  List<TrendDataPoint> currentChartEntries = [];
  List<TrendDataPoint> previousChartEntries = [];
  List<Color> currentChartSetColors = [];
  List<Color> previousChartSetColors = [];

  // total no. of point to draw for the chart. The timer starts adding one point at a time to the data set to create the animation effect for waveforms. When the no.of points reaches this toatal no.of points i.e, drawing reaching end of screen. Restart drawing from the start of the screen again.
  int totalPoints = 0;
  // The index for the point to be updated on the chart
  int currentPointChangeIndex = 0;
  // The index for the point to be taken from the chart data
  var currentDataIndex = 0;
  List<TrendDataPoint> chartData = [];
  late Timer chartDrawTimer;
  //var chartUniqueId: String?
  bool waitingForNewData = true;
  var chartLineColor = Colors.teal;
  double chartLineWidth = 0.8;
  int blankAreaPointsSize = 25;
  // The no.of points to replace in the current chart set with animation.
  int pointsToUpdateWithAnimation = 1;

  /* The time duration/amount of data should be present in buffer before starting to draw from
        left side. The buffer should be pruned to contain only this duration of data if it has more. */
  double chartDataBufferTime = 2; // in sec.

  int get maxBufferDataSize =>
      (chartDataBufferTime / chartDataSamplingTime).toInt();

  /* The sampling rate for the type of the waveform drawn. */
  // The chart refresh time to make the animation happen.
  int chartDataSamplingTime = 50; // in millis

  //axis min and max variables
  late double xAxisMinimum;
  late double xAxisMaximum;
  late double yAxisMinimum;
  late double yAxisMaximum;

  int currentXValue = 0;
  int currentYValue = 0;

  late List data;
  late List jsonDataPoints;

  Future<String> loadJsonData() async {
    var jsonText = await rootBundle.loadString('assets/response1.json');
    setState(() => data = json.decode(jsonText));
    return 'success';
  }

  @override
  void initState() {
    super.initState();
    loadJsonData().then((value) => jsonDataPoints = data[0]['DataPoints']);

    setScale(0, 500, 0, 500);
    var chartDrawTimer = Timer.periodic(
      Duration(milliseconds: 500),
      (Timer timer) async {
        List<TrendDataPoint> samples = [];
        if (currentXValue > 500) {
          currentXValue = 0;
        }
        if (currentYValue > 500) {
          currentYValue = 0;
        }

        for (int i = 0; i < 400; i++) {
          samples.add(TrendDataPoint(
              refTime: currentXValue % 500,
              value:
                  int.parse(jsonDataPoints[currentYValue % 13839]['YValue'])));
          currentXValue = currentXValue + 1;
          currentYValue = currentYValue + 1;
        }
        addNewSamples(samples);
      },
    );
    startDrawing();
  }

  void setScale(double xMin, double xMax, double yMin, double yMax) {
    totalPoints = (xMax - xMin).toInt();
    xAxisMinimum = xMin;
    xAxisMaximum = xMax;

    yAxisMinimum = yMin;
    yAxisMaximum = yMax;
  }

  void addNewSamples(List<TrendDataPoint> waveformSamples) {
    chartData.addAll(waveformSamples);
  }

  /// Start the new draw cycle. This will draw the chart with animation from left to right
  void startDrawing() {
    waitingForNewData = false;
    chartDrawTimer = Timer.periodic(
      Duration(milliseconds: chartDataSamplingTime),
      (Timer timer) async {
        updateChartPoint();
      },
    );
    print("Chart drawing started.");
  }

  List<double> getNextSetOfPointsToDraw() {
    List<double> points = [];
    for (int i = 0; i < pointsToUpdateWithAnimation; i++) {
      if (chartData.length > currentDataIndex) {
        double value = chartData[currentDataIndex].value + .0;
        currentDataIndex += 1;
        points.add(value);
      }
    }
    return points;
  }

  /// Each subclass must implement this method.
  ///
  /// - Returns: The default value for "null" value wavefrom sample
  double getMissingSampleValue() {
    return -1;
  }

  void truncateChartData() {
    print(
        'Truncate chart data called. chart data count: {$chartData.count}   max buffer size: {$maxBufferDataSize}');
    if (chartData.length > maxBufferDataSize) {
      //chartData is more than total points so remove items at the start
      var size = chartData.length;
      var removeCount = size - maxBufferDataSize;
      print(
          "Truncate chart data called. previous Index:{$currentDataIndex}     remove count:{$removeCount}");
      chartData.removeRange(0, removeCount);
      //change the current data index
      currentDataIndex = currentDataIndex - removeCount;
      if (currentDataIndex < 0) {
        currentDataIndex = 0;
      }
    }
  }

  void updateDrawingDataSets() {
    //reached end of current graphs. restart drawing from start
    currentPointChangeIndex = 0;

    //copy set1 to set2 and empty the set1
    previousChartEntries = currentChartEntries;
    currentChartEntries = [];

    //set the current chart colors to previous chart colors
    previousChartSetColors.clear();
    previousChartSetColors.addAll(currentChartSetColors);
    //clear the current chart set colors
    currentChartSetColors.clear();

    //remove initial set of point to create the empty rectangle while redrawing.
    if (previousChartEntries.length >= blankAreaPointsSize) {
      for (int i = 0; i < blankAreaPointsSize; i++) {
        previousChartEntries.removeAt(0);
        if (previousChartSetColors.length > 1) {
          previousChartSetColors.removeAt(0);
        }
      }
    }

    //clear previous and current sets line chart entries
    /*currentChartSet.clear()
      previousChartSet.clear()
    previousChartSet.values = previousLineChartEntries*/
  }

  bool isMissingSampleValue(double value) {
    return value == getMissingSampleValue();
  }

  void updateChartPoint() {
    if (currentPointChangeIndex > totalPoints) {
      //check if the data set needs to be truncated.
      truncateChartData();
      updateDrawingDataSets();

      //reached end of drawing all points. notify deleteage to update new data.
      /*chartDrawDelegate?.didCompleteDrawing(chartView: self,
        chartUniuqeId: self.chartUniqueId!)*/
    }

    //add the next point in data set1
    var points = getNextSetOfPointsToDraw();
    if (!points.isEmpty) {
      for (double value in points) {
        /* NOTE: setting color for each point to make sure we get disconnected chart for
                     missing samples */
        if (isMissingSampleValue(value)) {
          if (currentChartSetColors.length > 0) {
            //remove the last color value and add clear color to create a gap between the points.
            currentChartSetColors.removeLast();
            currentChartSetColors.add(Colors.transparent);
          }
          currentChartSetColors.add(Colors.transparent);
        } else {
          currentChartSetColors.add(chartLineColor);
        }
        //let dataEntry = ChartDataEntry(x: Double(currentPointChangeIndex), y: Double(value))
        //currentLineChartEntries.append(dataEntry)
        currentChartEntries.add(
            TrendDataPoint(refTime: currentPointChangeIndex, value: value));
        currentPointChangeIndex = currentPointChangeIndex + 1;

        //always make sure that previous data set has the last point so that chart will not adjust when you redraw
        if (previousChartEntries.length > 1) {
          previousChartEntries.removeAt(0);
          if (previousChartSetColors.length > 1) {
            previousChartSetColors.removeAt(0);
          }
        }
      }
      //TODO: Call redraw
      setState(() {});
      //notify delegate that drawing is in progress
      //chartDrawDelegate?.didStartDrawing()
    } else {
      //chart data point to draw is empty. notify the delegate that drawing is stopped and waiting for new data.
      //chartDrawDelegate?.didStopDrawing()
    }
  }

  void stopWaveformDrawing() {
    chartDrawTimer.cancel();
  }

/*deinit {
 stopWaveformDrawing();
}*/

  /// Clears the chart data set and makes the graph empty
  void resetChart() {
    print('resetChart called.');
    currentChartEntries.clear();
    previousChartEntries.clear();
    currentDataIndex = 0;
    currentPointChangeIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lines'),
      ),
      body: CustomPaint(
        painter: BaseWaveformPainter(
          xAxisMinimum,
          xAxisMaximum,
          yAxisMinimum,
          yAxisMaximum,
          currentChartEntries,
          previousChartEntries,
          currentChartSetColors,
          previousChartSetColors,
        ),
        child: Container(),
      ),
    );
  }
}
