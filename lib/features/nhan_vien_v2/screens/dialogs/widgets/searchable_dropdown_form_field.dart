import 'package:flutter/material.dart';

class SearchableDropdownFormField<T> extends FormField<T> {
  SearchableDropdownFormField({
    super.key,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    super.initialValue,
    InputDecoration decoration = const InputDecoration(),
    super.validator,
    bool isExpanded = true,
    String searchHintText = 'Nhập để tìm kiếm...',
  }) : super(
         enabled: onChanged != null,
         builder: (field) {
           final selectedItem = _findItem(items, field.value);
           final selectedLabel = selectedItem == null
               ? ''
               : _itemLabel(selectedItem);
           final effectiveDecoration = decoration.copyWith(
             errorText: field.errorText,
             suffixIcon: Icon(
               Icons.keyboard_arrow_down_rounded,
               color: onChanged != null
                   ? Theme.of(field.context).colorScheme.primary
                   : Theme.of(field.context).disabledColor,
             ),
           );

           return InkWell(
             borderRadius: _borderRadiusOf(effectiveDecoration),
             onTap: onChanged == null
                 ? null
                 : () async {
                     final result = await _showSearchDialog<T>(
                       field.context,
                       items: items,
                       selectedValue: field.value,
                       title: _labelTextOf(decoration),
                       searchHintText: searchHintText,
                     );
                     if (result == null) return;
                     field.didChange(result.value);
                     onChanged(result.value);
                   },
             child: InputDecorator(
               decoration: effectiveDecoration,
               isEmpty: selectedItem == null,
               child: Text(
                 selectedLabel,
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: Theme.of(field.context).textTheme.bodyLarge?.copyWith(
                   color: onChanged == null
                       ? Theme.of(field.context).disabledColor
                       : null,
                 ),
               ),
             ),
           );
         },
       );

  static DropdownMenuItem<T>? _findItem<T>(
    List<DropdownMenuItem<T>> items,
    T? value,
  ) {
    for (final item in items) {
      if (item.value == value) return item;
    }
    return null;
  }

  static String _itemLabel<T>(DropdownMenuItem<T> item) {
    final child = item.child;
    if (child is Text) {
      return child.data ?? child.textSpan?.toPlainText() ?? '';
    }
    return item.value?.toString() ?? '';
  }

  static String _labelTextOf(InputDecoration decoration) {
    final text = decoration.labelText?.trim();
    return text == null || text.isEmpty ? 'Chọn thông tin' : text;
  }

  static BorderRadius _borderRadiusOf(InputDecoration decoration) {
    final border = decoration.enabledBorder ?? decoration.border;
    if (border is OutlineInputBorder) return border.borderRadius;
    return BorderRadius.circular(10);
  }

  static Future<_SearchSelection<T>?> _showSearchDialog<T>(
    BuildContext context, {
    required List<DropdownMenuItem<T>> items,
    required T? selectedValue,
    required String title,
    required String searchHintText,
  }) {
    return showDialog<_SearchSelection<T>>(
      context: context,
      builder: (_) => _SearchableSelectionDialog<T>(
        items: items,
        selectedValue: selectedValue,
        title: title,
        searchHintText: searchHintText,
      ),
    );
  }

  static String _normalize(String value) {
    var result = value.trim().toLowerCase();
    const groups = <String, String>{
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    for (final entry in groups.entries) {
      for (final character in entry.value.characters) {
        result = result.replaceAll(character, entry.key);
      }
    }
    return result;
  }
}

class _SearchSelection<T> {
  const _SearchSelection(this.value);

  final T? value;
}

class _SearchableSelectionDialog<T> extends StatefulWidget {
  const _SearchableSelectionDialog({
    required this.items,
    required this.selectedValue,
    required this.title,
    required this.searchHintText,
  });

  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final String title;
  final String searchHintText;

  @override
  State<_SearchableSelectionDialog<T>> createState() =>
      _SearchableSelectionDialogState<T>();
}

class _SearchableSelectionDialogState<T>
    extends State<_SearchableSelectionDialog<T>> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = SearchableDropdownFormField._normalize(
      _searchController.text,
    );
    final filteredItems = keyword.isEmpty
        ? widget.items
        : widget.items
              .where(
                (item) => SearchableDropdownFormField._normalize(
                  SearchableDropdownFormField._itemLabel(item),
                ).contains(keyword),
              )
              .toList();
    final availableHeight = (MediaQuery.sizeOf(context).height - 220)
        .clamp(280.0, 480.0)
        .toDouble();

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: availableHeight,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.searchHintText,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: const Color(0xFFF6F8FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 38,
                            color: Color(0xFF9AA9B7),
                          ),
                          SizedBox(height: 8),
                          Text('Không tìm thấy dữ liệu phù hợp'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFE7EDF3)),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final selected = item.value == widget.selectedValue;
                        return ListTile(
                          enabled: item.enabled,
                          selected: selected,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFFA5B2BE),
                            size: 20,
                          ),
                          title: Text(
                            SearchableDropdownFormField._itemLabel(item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: item.enabled
                              ? () => Navigator.of(
                                  context,
                                ).pop(_SearchSelection(item.value))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
