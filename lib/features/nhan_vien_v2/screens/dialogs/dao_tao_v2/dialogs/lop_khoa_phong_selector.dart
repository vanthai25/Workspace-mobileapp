import 'package:flutter/material.dart';

import '../../../../../../models/dao_tao_v2_models.dart';

class LopKhoaPhongSelector extends StatefulWidget {
  final List<DaoTaoDanhMucItemV2Model> items;
  final Set<int> selectedIds;
  final Set<int> lockedIds;
  final bool enabled;
  final ValueChanged<Set<int>> onChanged;

  const LopKhoaPhongSelector({
    super.key,
    required this.items,
    required this.selectedIds,
    this.lockedIds = const {},
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<LopKhoaPhongSelector> createState() => _LopKhoaPhongSelectorState();
}

class _LopKhoaPhongSelectorState extends State<LopKhoaPhongSelector> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final byId = {for (final item in widget.items) item.id: item};
    for (final id in widget.selectedIds) {
      byId.putIfAbsent(
        id,
        () => DaoTaoDanhMucItemV2Model(id: id, ten: 'Khoa/phòng #$id'),
      );
    }
    final items = byId.values
        .where((item) => item.ten.toLowerCase().contains(_keyword))
        .toList();

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Khoa/phòng được đăng ký (${widget.selectedIds.length})',
        border: const OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ nhân viên thuộc các khoa/phòng được chọn có thể thấy và đăng ký lớp.',
          ),
          const SizedBox(height: 8),
          TextField(
            enabled: widget.enabled,
            decoration: const InputDecoration(
              hintText: 'Tìm khoa/phòng',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) =>
                setState(() => _keyword = value.trim().toLowerCase()),
          ),
          SizedBox(
            height: 220,
            child: items.isEmpty
                ? const Center(child: Text('Không có khoa/phòng phù hợp.'))
                : ListView.builder(
                    primary: false,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final locked = widget.lockedIds.contains(item.id);
                      return CheckboxListTile(
                        key: ValueKey('khoa-phong-${item.id}'),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.ten),
                        subtitle: locked
                            ? const Text('Đã áp dụng cho lớp, được giữ lại')
                            : null,
                        value: widget.selectedIds.contains(item.id),
                        onChanged: !widget.enabled || locked
                            ? null
                            : (checked) {
                                final ids = {...widget.selectedIds};
                                checked == true
                                    ? ids.add(item.id)
                                    : ids.remove(item.id);
                                widget.onChanged(ids);
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
