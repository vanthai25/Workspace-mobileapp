import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';
import '../../../../screens/nhan_vien/nhan_vien_web_design.dart';

class ThanNhanFormDialog extends StatefulWidget {
  final String maSo;
  final ThanNhanV2Model? item;

  const ThanNhanFormDialog({super.key, required this.maSo, this.item});

  bool get isEdit => item != null;

  @override
  State<ThanNhanFormDialog> createState() => _ThanNhanFormDialogState();
}

class _ThanNhanFormDialogState extends State<ThanNhanFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tenController;
  late final TextEditingController _quanHeController;
  late final TextEditingController _cccdController;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _tenController = TextEditingController(text: item?.tenThanNhan ?? '');
    _quanHeController = TextEditingController(text: item?.moiQuanHe ?? '');
    _cccdController = TextEditingController(text: item?.soCCCD ?? '');
  }

  @override
  void dispose() {
    _tenController.dispose();
    _quanHeController.dispose();
    _cccdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NhanVienV2Provider>();
    final viewport = MediaQuery.sizeOf(context);
    final dialogHeight = viewport.height > 470 ? 470.0 : viewport.height - 32;
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      shadowColor: NhanVienWebColors.primaryDark.withValues(alpha: .18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: 680,
        height: dialogHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2999D7),
                          NhanVienWebColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.family_restroom_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEdit ? 'Sửa thân nhân' : 'Thêm thân nhân',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thông tin người thân của nhân viên',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: provider.isSaving
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thông tin cơ bản',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _tenController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            'Tên thân nhân *',
                            Icons.person_outline,
                            hintText: 'Nhập họ và tên',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên thân nhân';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _responsiveFields([
                          TextFormField(
                            controller: _quanHeController,
                            decoration: _inputDecoration(
                              'Mối quan hệ',
                              Icons.people_outline,
                              hintText: 'Ví dụ: Vợ, chồng, con',
                            ),
                          ),
                          TextFormField(
                            controller: _cccdController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              'Số CCCD',
                              Icons.credit_card_outlined,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              color: colors.surfaceContainerLowest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: provider.isSaving
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: provider.isSaving ? null : _save,
                    icon: provider.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      provider.isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveFields(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 500;
        final fieldWidth = useTwoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: fieldWidth, child: child))
              .toList(),
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hintText,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? text(String value) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    final data = <String, dynamic>{
      'tenThanNhan': _tenController.text.trim(),
      'moiQuanHe': text(_quanHeController.text),
      'soCCCD': text(_cccdController.text),
    };

    final provider = context.read<NhanVienV2Provider>();
    final bool ok;

    if (widget.isEdit) {
      ok = await provider.updateThanNhan(
        widget.maSo,
        widget.item!.idThanNhan,
        data,
      );
    } else {
      ok = await provider.createThanNhan(widget.maSo, data);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(provider.errorMessage ?? 'Không thể lưu thông tin thân nhân.');
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
