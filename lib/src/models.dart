class DBRow {
  final Map<String, dynamic> items;
  final int Function(Map<String, dynamic> items) indexQueryCallback;

  DBRow({required this.items, required this.indexQueryCallback});

  int get index => indexQueryCallback.call(items);
}
