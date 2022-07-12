class TrendDataPoint {
  late dynamic refTime;
  late dynamic value;
  /*This parameter is defined to show empty graphs
      when disconnected or null value recived by API.
      The chart framework does not plot Null values directly so a dummy value is
      set to value and using proxy value the logic will decide to plug empty space
      on the graph.*/
  String? proxValue;

  TrendDataPoint({required this.refTime, required this.value, this.proxValue});

  static List<TrendDataPoint> listFromJson(List<dynamic> json) {
    return json.map((value) => TrendDataPoint.fromJson(value)).toList();
  }

  TrendDataPoint.fromJson(Map<String, dynamic> json) {
    refTime = json['RefTime'];
    value = json['Value'];
  }
}
