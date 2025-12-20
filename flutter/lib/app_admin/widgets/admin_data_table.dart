import 'package:flutter/material.dart';
import '../../core/widgets/core_button.dart';

/// 管理端数据表格组件，支持排序、筛选、分页、操作等功能
class AdminDataTable<T> extends StatefulWidget {
  final List<DataColumn> columns;
  final List<T> data;
  final List<DataRow> Function(List<T> data) buildRows;
  final Widget? title;
  final List<Widget>? actions;
  final bool showSearch;
  final bool showFilter;
  final bool showPagination;
  final int rowsPerPage;
  final Function(String)? onSearch;
  final Function(Map<String, dynamic>)? onFilter;
  final Function(int, T)? onEdit;
  final Function(int, T)? onDelete;
  final Function(int, T)? onView;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.data,
    required this.buildRows,
    this.title,
    this.actions,
    this.showSearch = true,
    this.showFilter = true,
    this.showPagination = true,
    this.rowsPerPage = 10,
    this.onSearch,
    this.onFilter,
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  @override
  State<AdminDataTable<T>> createState() => _AdminDataTableState<T>();
}

class _AdminDataTableState<T> extends State<AdminDataTable<T>> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  int _rowsPerPage = 10;
  List<T> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _filteredData = widget.data;
    _rowsPerPage = widget.rowsPerPage;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部工具栏
        _buildToolbar(context),
        const SizedBox(height: 16),
        // 数据表格
        Expanded(
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  dataRowColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surface,
                  ),
                  border: TableBorder.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  columns: [
                    ...widget.columns,
                    if (widget.onEdit != null ||
                        widget.onDelete != null ||
                        widget.onView != null)
                      const DataColumn(label: Text('操作'), numeric: true),
                  ],
                  rows: _buildDataRows(),
                ),
              ),
            ),
          ),
        ),
        // 分页控件
        if (widget.showPagination && _filteredData.length > _rowsPerPage) ...[
          const SizedBox(height: 16),
          _buildPagination(context),
        ],
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        // 标题
        if (widget.title != null) ...[widget.title!, const Spacer()],
        // 搜索框
        if (widget.showSearch) ...[
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                _handleSearch(value);
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
        // 筛选按钮
        if (widget.showFilter) ...[
          CoreButton(
            label: '筛选',
            onPressed: () => _showFilterDialog(context),
            icon: Icons.filter_list,
            primary: false,
          ),
          const SizedBox(width: 16),
        ],
        // 自定义操作按钮
        if (widget.actions != null) ...widget.actions!,
      ],
    );
  }

  List<DataRow> _buildDataRows() {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredData.length);
    final pageData = _filteredData.sublist(startIndex, endIndex);

    return pageData.asMap().entries.map((entry) {
      final index = entry.key + startIndex;
      final item = entry.value;

      return DataRow(
        cells: [
          ...widget.buildRows([item]).first.cells,
          if (widget.onEdit != null ||
              widget.onDelete != null ||
              widget.onView != null)
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onView != null) ...[
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () => widget.onView!(index, item),
                      tooltip: '查看',
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (widget.onEdit != null) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => widget.onEdit!(index, item),
                      tooltip: '编辑',
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (widget.onDelete != null) ...[
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _showDeleteConfirmDialog(context, index, item),
                      tooltip: '删除',
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }).toList();
  }

  Widget _buildPagination(BuildContext context) {
    final totalPages = (_filteredData.length / _rowsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 0
              ? () => _changePage(_currentPage - 1)
              : null,
        ),
        const SizedBox(width: 16),
        Text('第 ${_currentPage + 1} 页，共 $totalPages 页'),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < totalPages - 1
              ? () => _changePage(_currentPage + 1)
              : null,
        ),
        const Spacer(),
        DropdownButton<int>(
          value: _rowsPerPage,
          items: [10, 20, 50, 100].map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('每页 $value 条'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _rowsPerPage = value;
                _currentPage = 0;
              });
            }
          },
        ),
      ],
    );
  }

  void _handleSearch(String query) {
    if (widget.onSearch != null) {
      widget.onSearch!(query);
    } else {
      // 默认搜索逻辑：在所有字段中搜索
      setState(() {
        _filteredData = widget.data.where((item) {
          final itemString = item.toString().toLowerCase();
          return itemString.contains(query.toLowerCase());
        }).toList();
        _currentPage = 0;
      });
    }
  }

  void _showFilterDialog(BuildContext context) {
    // TODO: 实现筛选对话框
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('筛选功能开发中...')));
  }

  void _showDeleteConfirmDialog(BuildContext context, int index, T item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call(index, item);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
    });
  }
}
