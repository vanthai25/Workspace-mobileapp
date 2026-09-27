import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/su_kien_v2_models.dart';
import '../../../../providers/su_kien_v2_provider.dart';

class SuKienBannerFormDialog extends StatefulWidget {
  final int idSuKien;

  final SuKienBannerV2Model? banner;

  const SuKienBannerFormDialog({
    super.key,
    required this.idSuKien,
    this.banner,
  });

  bool get isEdit => banner != null;

  @override
  State<SuKienBannerFormDialog> createState() => _SuKienBannerFormDialogState();
}

class _SuKienBannerFormDialogState extends State<SuKienBannerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tieuDeController;

  late final TextEditingController _moTaController;

  late final TextEditingController _actionValueController;

  late final TextEditingController _buttonTextController;

  late final TextEditingController _thuTuController;

  PlatformFile? _file;

  String _actionType = 'none';

  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    final item = widget.banner;

    _tieuDeController = TextEditingController(text: item?.tieuDe ?? '');

    _moTaController = TextEditingController(text: item?.moTa ?? '');

    _actionValueController = TextEditingController(
      text: item?.actionValue ?? '',
    );

    _buttonTextController = TextEditingController(text: item?.buttonText ?? '');

    _thuTuController = TextEditingController(text: '${item?.thuTu ?? 0}');

    final action = item?.actionType?.trim().toLowerCase();

    _actionType =
        const {'none', 'url', 'screen', 'pdf', 'article'}.contains(action)
        ? action!
        : 'none';

    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _tieuDeController.dispose();

    _moTaController.dispose();

    _actionValueController.dispose();

    _buttonTextController.dispose();

    _thuTuController.dispose();

    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,

      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],

      allowMultiple: false,

      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final file = result.files.first;

    if (file.bytes == null) {
      _showError('Không đọc được nội dung file.');

      return;
    }

    setState(() {
      _file = file;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!widget.isEdit && _file == null) {
      _showError('Vui lòng chọn ảnh banner.');

      return;
    }

    final provider = context.read<SuKienV2Provider>();

    final actionValue = _actionType == 'none'
        ? null
        : _emptyToNull(_actionValueController.text);

    final buttonText = _actionType == 'none'
        ? null
        : _emptyToNull(_buttonTextController.text);

    final bool ok;

    if (!widget.isEdit) {
      ok = await provider.uploadBanner(
        idSuKien: widget.idSuKien,

        file: _file!,

        tieuDe: _emptyToNull(_tieuDeController.text),

        moTa: _emptyToNull(_moTaController.text),

        actionType: _actionType,

        actionValue: actionValue,

        buttonText: buttonText,

        thuTu: int.tryParse(_thuTuController.text.trim()) ?? 0,

        isActive: _isActive,
      );
    } else {
      ok = await provider.updateBanner(
        idSuKien: widget.idSuKien,

        idBanner: widget.banner!.idBanner,

        tieuDe: _emptyToNull(_tieuDeController.text),

        moTa: _emptyToNull(_moTaController.text),

        actionType: _actionType,

        actionValue: actionValue,

        buttonText: buttonText,

        thuTu: int.tryParse(_thuTuController.text.trim()) ?? 0,

        isActive: _isActive,
      );
    }

    if (!mounted) {
      return;
    }

    if (!ok) {
      _showError(provider.bannerErrorMessage ?? 'Không thể lưu banner.');

      return;
    }

    Navigator.pop(context, true);
  }

  String? _emptyToNull(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor: const Color(0xFFC43C35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuKienV2Provider>();

    return AlertDialog(
      title: Text(widget.isEdit ? 'Sửa banner' : 'Thêm banner'),

      content: SizedBox(
        width: 700,

        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                if (!widget.isEdit) _filePicker(),

                if (widget.isEdit)
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FA),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Text(
                      'Ảnh hiện tại sẽ được giữ nguyên. '
                      'Form này chỉ sửa thông tin banner.',
                    ),
                  ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _tieuDeController,

                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _moTaController,

                  maxLines: 3,

                  decoration: const InputDecoration(
                    labelText: 'Mô tả',

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _actionType,

                        decoration: const InputDecoration(
                          labelText: 'Hành động',

                          border: OutlineInputBorder(),
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 'none',
                            child: Text('Không có'),
                          ),

                          DropdownMenuItem(value: 'url', child: Text('Mở URL')),

                          DropdownMenuItem(
                            value: 'screen',
                            child: Text('Mở màn hình trong app'),
                          ),

                          DropdownMenuItem(value: 'pdf', child: Text('Mở PDF')),

                          DropdownMenuItem(
                            value: 'article',
                            child: Text('Mở bài viết'),
                          ),
                        ],

                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _actionType = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      width: 160,

                      child: TextFormField(
                        controller: _thuTuController,

                        keyboardType: TextInputType.number,

                        decoration: const InputDecoration(
                          labelText: 'Thứ tự',

                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_actionType != 'none') ...[
                  const SizedBox(height: 14),

                  if (_actionType == 'screen')
                    DropdownButtonFormField<String>(
                      initialValue:
                          _actionValueController.text.trim().toLowerCase() ==
                              'dao-tao'
                          ? 'dao-tao'
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Màn hình đích',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'dao-tao',
                          child: Text('Đào tạo / CME'),
                        ),
                      ],
                      onChanged: (value) =>
                          _actionValueController.text = value ?? '',
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn màn hình đích.' : null,
                    )
                  else
                    TextFormField(
                      controller: _actionValueController,

                      decoration: InputDecoration(
                        labelText: _actionValueLabel(),

                        border: const OutlineInputBorder(),
                      ),

                      validator: (value) {
                        if (_actionType == 'none') {
                          return null;
                        }

                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập giá trị hành động.';
                        }

                        final uri = Uri.tryParse(value.trim());
                        if (uri == null ||
                            !const {'https', 'http'}.contains(uri.scheme) ||
                            uri.host.isEmpty) {
                          return 'Vui lòng nhập liên kết http:// hoặc https:// hợp lệ.';
                        }
                        return null;
                      },
                    ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _buttonTextController,

                    decoration: const InputDecoration(
                      labelText: 'Nội dung nút',

                      hintText: 'Ví dụ: Xem thêm',

                      border: OutlineInputBorder(),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,

                  value: _isActive,

                  title: const Text('Hiển thị banner'),

                  subtitle: const Text(
                    'Banner tắt sẽ không xuất hiện trên trang chủ.',
                  ),

                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: provider.isSavingBanner
              ? null
              : () => Navigator.pop(context),

          child: const Text('Hủy'),
        ),

        FilledButton.icon(
          onPressed: provider.isSavingBanner ? null : _save,

          icon: provider.isSavingBanner
              ? const SizedBox(
                  width: 16,
                  height: 16,

                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),

          label: Text(provider.isSavingBanner ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }

  Widget _filePicker() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: const Color(0xFFDCE5EC)),
      ),

      child: Row(
        children: [
          const Icon(Icons.image_outlined, size: 34, color: Color(0xFF1274BC)),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  _file == null ? 'Chưa chọn ảnh' : _file!.name,

                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 3),

                const Text(
                  'JPG, PNG hoặc WEBP • tối đa 8 MB',
                  style: TextStyle(color: Color(0xFF718394), fontSize: 11),
                ),
              ],
            ),
          ),

          OutlinedButton.icon(
            onPressed: _pickFile,

            icon: const Icon(Icons.folder_open_outlined),

            label: const Text('Chọn ảnh'),
          ),
        ],
      ),
    );
  }

  String _actionValueLabel() {
    switch (_actionType) {
      case 'url':
        return 'Đường dẫn URL';

      case 'screen':
        return 'Tên màn hình / route';

      case 'pdf':
        return 'Mã hoặc đường dẫn PDF';

      case 'article':
        return 'Mã bài viết';

      default:
        return 'Giá trị';
    }
  }
}
