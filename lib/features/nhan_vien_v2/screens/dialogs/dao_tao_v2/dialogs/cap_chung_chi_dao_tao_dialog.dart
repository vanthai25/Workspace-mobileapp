import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/dao_tao_v2_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';
import 'dao_tao_design.dart';

class CapChungChiDaoTaoDialog extends StatefulWidget {
  final LopDaoTaoV2Model item;

  const CapChungChiDaoTaoDialog({super.key, required this.item});

  @override
  State<CapChungChiDaoTaoDialog> createState() =>
      _CapChungChiDaoTaoDialogState();
}

class _CapChungChiDaoTaoDialogState extends State<CapChungChiDaoTaoDialog> {
  final _soChungChiController = TextEditingController();

  final Set<String> _selected = {};

  String _keyword = '';

  bool _cme = true;

  DateTime? _ngayHetHan;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<DaoTaoV2Provider>().loadNguoiDangKy(widget.item.idLopDaoTao);
    });
  }

  @override
  void dispose() {
    _soChungChiController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DaoTaoV2Provider>();

    final filtered = provider.nguoiDangKy.where((e) {
      final key = _keyword.trim().toLowerCase();

      if (key.isEmpty) {
        return true;
      }

      return e.maSo.toLowerCase().contains(key) ||
          (e.hoVaTen ?? '').toLowerCase().contains(key) ||
          (e.tenKhoaPhong ?? '').toLowerCase().contains(key);
    }).toList();

    return Theme(
      data: daoTaoTheme(context),
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        backgroundColor: DaoTaoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),

        child: SizedBox(
          width: 1150,
          height: 780,

          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: DaoTaoColors.border),
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2999D7), DaoTaoColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Cấp CME / Chứng chỉ',
                            style: TextStyle(
                              color: DaoTaoColors.text,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          Text(
                            widget.item.tenLopDaoTao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DaoTaoColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DaoTaoColors.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: DaoTaoColors.border),
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: daoTaoInputDecoration(
                          label: 'Tìm nhân viên',
                          hint: 'Mã số, họ tên hoặc khoa/phòng',
                          icon: Icons.search,
                        ),

                        onChanged: (value) {
                          setState(() {
                            _keyword = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _soChungChiController,

                        decoration: daoTaoInputDecoration(
                          label: 'Số chứng chỉ',
                          icon: Icons.numbers_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    OutlinedButton.icon(
                      onPressed: _pickNgayHetHan,

                      icon: const Icon(Icons.event),

                      label: Text(
                        _ngayHetHan == null
                            ? 'Ngày hết hạn'
                            : _date(_ngayHetHan!),
                      ),
                    ),

                    const SizedBox(width: 12),

                    FilterChip(
                      selected: _cme,

                      label: const Text('CME'),

                      onSelected: (value) {
                        setState(() {
                          _cme = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),

                child: Row(
                  children: [
                    Checkbox(
                      value:
                          filtered.isNotEmpty &&
                          filtered.every((e) => _selected.contains(e.maSo)),

                      onChanged: (_) {
                        setState(() {
                          final allSelected = filtered.every(
                            (e) => _selected.contains(e.maSo),
                          );

                          if (allSelected) {
                            for (final item in filtered) {
                              _selected.remove(item.maSo);
                            }
                          } else {
                            for (final item in filtered) {
                              _selected.add(item.maSo);
                            }
                          }
                        });
                      },
                    ),

                    Text(
                      'Chọn tất cả',
                      style: const TextStyle(
                        color: DaoTaoColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DaoTaoStatusPill(
                      label: '${_selected.length} người đã chọn',
                      icon: Icons.people_alt_outlined,
                      color: DaoTaoColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              Expanded(
                child: provider.isLoadingNguoiDangKy
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: DaoTaoColors.primary,
                        ),
                      )
                    : filtered.isEmpty
                    ? const DaoTaoEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'Không tìm thấy nhân viên',
                        message: 'Hãy thử thay đổi từ khóa tìm kiếm.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        itemCount: filtered.length,

                        separatorBuilder: (_, _) => const SizedBox(height: 7),

                        itemBuilder: (_, index) {
                          final item = filtered[index];

                          final daCap = _cme
                              ? item.daCapCme
                              : item.daCapChungChi;

                          return Container(
                            decoration: BoxDecoration(
                              color: DaoTaoColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: daCap
                                    ? const Color(0xFFCDE8DB)
                                    : DaoTaoColors.border,
                              ),
                            ),
                            child: CheckboxListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              value: _selected.contains(item.maSo),

                              onChanged: daCap
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selected.add(item.maSo);
                                        } else {
                                          _selected.remove(item.maSo);
                                        }
                                      });
                                    },

                              title: Text(
                                '${item.maSo} - ${item.hoVaTen ?? ''}',
                                style: const TextStyle(
                                  color: DaoTaoColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              subtitle: Text(
                                '${item.tenKhoaPhong ?? 'Chưa xác định khoa'}'
                                '${daCap ? ' • Đã cấp ${_cme ? 'CME' : 'chứng chỉ'}' : ''}',
                                style: const TextStyle(
                                  color: DaoTaoColors.muted,
                                ),
                              ),

                              secondary: daCap
                                  ? const Icon(
                                      Icons.verified_rounded,
                                      color: DaoTaoColors.success,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 15),
                decoration: const BoxDecoration(
                  color: DaoTaoColors.surface,
                  border: Border(top: BorderSide(color: DaoTaoColors.border)),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,

                  children: [
                    TextButton(
                      onPressed: provider.isCapChungChi
                          ? null
                          : () => Navigator.pop(context),

                      child: const Text('Đóng'),
                    ),

                    const SizedBox(width: 8),

                    FilledButton.icon(
                      onPressed: provider.isCapChungChi || _selected.isEmpty
                          ? null
                          : () => _cap(provider),

                      icon: provider.isCapChungChi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.workspace_premium),

                      label: Text(_cme ? 'Cấp CME' : 'Cấp chứng chỉ'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickNgayHetHan() async {
    final result = await showDatePicker(
      context: context,

      initialDate: _ngayHetHan ?? DateTime.now().add(const Duration(days: 365)),

      firstDate: DateTime.now(),

      lastDate: DateTime(2100),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _ngayHetHan = result;
    });
  }

  Future<void> _cap(DaoTaoV2Provider provider) async {
    final confirm = await showDialog<bool>(
      context: context,

      builder: (_) => AlertDialog(
        title: Text(_cme ? 'Cấp CME' : 'Cấp chứng chỉ'),

        content: Text('Xác nhận cấp cho ${_selected.length} người?'),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),

          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    final result = await provider.capChungChi(
      idLopDaoTao: widget.item.idLopDaoTao,

      maSos: _selected.toList(),

      cme: _cme,

      ngayHetHan: _ngayHetHan,

      soChungChi: _soChungChiController.text,
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      _message(provider.errorMessage ?? 'Không thể cấp chứng chỉ.');

      return;
    }

    _selected.clear();

    setState(() {});

    _message(
      'Đã cấp ${result.soNguoiDuocCap} người'
      '${result.soNguoiBoQua > 0 ? ', bỏ qua ${result.soNguoiBoQua} người đã được cấp.' : '.'}',
    );
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
