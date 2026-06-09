class Pagination<T> {
  Pagination({required this.items, required this.page, required this.total});
  final List<T> items;
  final int page;
  final int total;

  bool get hasMore => items.length + (page - 1) * _pageSize < total;
  static const _pageSize = 20;
}
