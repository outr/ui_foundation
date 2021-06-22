class Arguments {
  final Map<String, String> map;

  Arguments(this.map);

  static Arguments empty = Arguments({});

  @override
  int get hashCode => map.toString().hashCode;

  @override
  bool operator ==(Object other) => toString() == other.toString();

  @override
  String toString() => map.toString();
}