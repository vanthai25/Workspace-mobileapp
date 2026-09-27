import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cme_model.dart';
import '../../providers/cme_provider.dart';

const Color _cmePrimaryColor = Color(0xFF1274BC);
const int _maxFileSizeBytes = 10 * 1024 * 1024;
const List<String> _allowedFileExtensions = <String>[
  'pdf',
];

Future<bool> showCmeRequestFormDialog(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CmeRequestFormDialog(),
  );

  return result ?? false;
}

class _CmeRequestFormDialog extends StatefulWidget {
  const _CmeRequestFormDialog();

  @override
  State<_CmeRequestFormDialog> createState() => _CmeRequestFormDialogState();
}

class _CmeRequestFormDialogState extends State<_CmeRequestFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tenChungChiController = TextEditingController();
  final TextEditingController _soChungChiController = TextEditingController();
  final TextEditingController _donViDaoTaoController = TextEditingController();
  final TextEditingController _soTietController = TextEditingController();
  final TextEditingController _chuKyController = TextEditingController();

  int? _idHinhThucDaoTao;
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;
  DateTime? _ngayCap;
  DateTime? _ngayHetHan;

  Uint8List? _fileBytes;
  String? _fileName;
  int? _fileSize;
  String? _fileError;
  bool _isPickingFile = false;

  static final TextInputFormatter _decimalInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final String value = newValue.text;
        if (value.isEmpty ||
            RegExp(r'^\d{0,4}([,.]\d{0,1})?$').hasMatch(value)) {
          return newValue;
        }
        return oldValue;
      });

  @override
  void dispose() {
    _tenChungChiController.dispose();
    _soChungChiController.dispose();
    _donViDaoTaoController.dispose();
    _soTietController.dispose();
    _chuKyController.dispose();
    super.dispose();
  }

  String? _validateRequiredName(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Vui lòng nhập tên chứng chỉ.';
    }
    if (normalized.length > 300) {
      return 'Tên chứng chỉ không được vượt quá 300 ký tự.';
    }
    return null;
  }
  String? _validateRequiredText(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    final String normalized =
        value?.trim() ?? '';

    if (normalized.isEmpty) {
      return 'Vui lòng nhập $fieldName.';
    }

    if (normalized.length > maxLength) {
      return '$fieldName không được vượt quá $maxLength ký tự.';
    }

    return null;
  }
  String? _validateOptionalLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if ((value?.trim().length ?? 0) > maxLength) {
      return '$fieldName không được vượt quá $maxLength ký tự.';
    }
    return null;
  }

  String? _validateSoTiet(
  String? value,
) {
  final String normalized =
      (value ?? '')
          .trim()
          .replaceAll(',', '.');

  if (normalized.isEmpty) {
    return 'Vui lòng nhập giờ tín chỉ.';
  }

  if (!RegExp(
    r'^\d{1,4}(\.\d)?$',
  ).hasMatch(normalized)) {
    return 'Giờ tín chỉ có tối đa một chữ số thập phân.';
  }

  final double? number =
      double.tryParse(
    normalized,
  );

  if (number == null ||
      number < 0.1 ||
      number > 9999.9) {
    return 'Giờ tín chỉ phải từ 0,1 đến 9999,9.';
  }

  return null;
}

  String? _validateChuKy(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final int? number = int.tryParse(normalized);
    if (number == null || number < 0 || number > 2147483647) {
      return 'Chu kỳ phải là số nguyên không âm hợp lệ.';
    }
    return null;
  }
  bool _isPdfFile(
    Uint8List bytes,
  ) {
    // PDF hợp lệ bắt đầu bằng:
    // %PDF-
    if (bytes.length < 5) {
      return false;
    }

    return bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46 && // F
        bytes[4] == 0x2D; // -
  }
  Future<void> _pickFile() async {
  if (_isPickingFile) {
    return;
  }

  setState(() {
    _isPickingFile = true;
    _fileError = null;
  });

  try {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      allowMultiple: false,

      // =====================================================
      // CHỈ CHẤP NHẬN PDF
      // =====================================================

      type: FileType.custom,

      allowedExtensions:
          _allowedFileExtensions,

      dialogTitle:
          'Chọn file PDF',

      // Flutter Web cần bytes để upload.
      withData: true,
    );


    if (
      result == null ||
      result.files.isEmpty ||
      !mounted
    ) {
      return;
    }


    final PlatformFile file =
        result.files.single;


    // =====================================================
    // TÊN FILE
    // =====================================================

    final String name =
        file.name.trim();


    if (
      name.isEmpty ||
      name.length > 250
    ) {
      setState(() {
        _fileError =
            'Tên file phải có từ 1 đến 250 ký tự.';
      });

      return;
    }


    // =====================================================
    // KIỂM TRA EXTENSION
    // =====================================================

    final String extension =
        (
          file.extension ??
          ''
        )
            .trim()
            .toLowerCase();


    if (
      extension != 'pdf'
    ) {
      setState(() {
        _fileError =
            'CME chỉ chấp nhận file PDF.';
      });

      return;
    }


    // =====================================================
    // DUNG LƯỢNG FILE
    // =====================================================

    final int length =
        file.size;


    if (length <= 0) {
      setState(() {
        _fileError =
            'File PDF đã chọn không có dữ liệu.';
      });

      return;
    }


    if (
      length >
      _maxFileSizeBytes
    ) {
      setState(() {
        _fileError =
            'Dung lượng file PDF không được vượt quá 10 MB.';
      });

      return;
    }


    // =====================================================
    // ĐỌC BYTES
    // =====================================================

    final Uint8List? bytes =
        file.bytes;


    if (
      bytes == null ||
      bytes.isEmpty
    ) {
      setState(() {
        _fileError =
            'Không thể đọc dữ liệu từ file PDF đã chọn.';
      });

      return;
    }


    if (
      bytes.length >
      _maxFileSizeBytes
    ) {
      setState(() {
        _fileError =
            'Dung lượng file PDF không được vượt quá 10 MB.';
      });

      return;
    }


    // =====================================================
    // KIỂM TRA SIGNATURE PDF THỰC TẾ
    //
    // Không chấp nhận file khác chỉ đổi đuôi thành .pdf.
    // =====================================================

    if (!_isPdfFile(bytes)) {
      setState(() {
        _fileError =
            'File đã chọn không phải là file PDF hợp lệ.';
      });

      return;
    }


    // =====================================================
    // OK
    // =====================================================

    setState(() {
      _fileBytes =
          bytes;

      _fileName =
          name;

      _fileSize =
          bytes.length;

      _fileError =
          null;
    });
  } catch (_) {
    if (!mounted) {
      return;
    }

    setState(() {
      _fileError =
          'Không thể đọc file PDF. Vui lòng chọn lại.';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isPickingFile =
            false;
      });
    }
  }
}

  void _removeFile() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
      _fileSize = null;
      _fileError = null;
    });
  }

  Future<void> _submit(CmeProvider provider) async {
    if (provider.isSubmitting || _isPickingFile) {
      return;
    }

    FocusScope.of(context).unfocus();
    final bool formIsValid = _formKey.currentState?.validate() ?? false;
    final bool fileIsValid = _fileBytes != null && _fileName != null;

    if (!fileIsValid) {
      setState(() {
        _fileError =
            'Vui lòng đính kèm file PDF.';
      });
    }

    if (
    fileIsValid &&
      !_isPdfFile(_fileBytes!)
    ) {
      setState(() {
        _fileError =
            'File không phải PDF hợp lệ.';
      });

      return;
    }

    final String soTietText = _soTietController.text.trim().replaceAll(
      ',',
      '.',
    );
    final String chuKyText = _chuKyController.text.trim();

    final CmeCreateInput input =
        CmeCreateInput(
      tenChungChi:
          _tenChungChiController
              .text
              .trim(),

      // BẮT BUỘC
      soChungChi:
          _soChungChiController
              .text
              .trim(),

      // BẮT BUỘC
      donViDaoTao:
          _donViDaoTaoController
              .text
              .trim(),

      // Validator đã đảm bảo khác null.
      idHinhThucDaoTao:
          _idHinhThucDaoTao,

      ngayBatDau:
          _ngayBatDau,

      ngayKetThuc:
          _ngayKetThuc,

      // Validator đã đảm bảo có số hợp lệ.
      soTiet:
          double.parse(
        soTietText,
      ),

      ngayCap:
          _ngayCap,

      chuKy:
          chuKyText.isEmpty
              ? null
              : int.parse(
                  chuKyText,
                ),

      ngayHetHan:
          _ngayHetHan,

      fileBytes:
          _fileBytes!,

      fileName:
          _fileName!,
    );

    try {
      await provider.create(input);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu CME thành công.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              provider.submitError ??
                  'Không thể gửi yêu cầu CME. Vui lòng thử lại.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }

  String? _nullableText(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double maxDialogHeight = screenSize.height * 0.92;

    return Consumer<CmeProvider>(
      builder: (context, provider, _) {
        final bool isBusy = provider.isSubmitting || _isPickingFile;

        return PopScope(
          canPop: !isBusy,
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenSize.width < 600 ? 12 : 32,
              vertical: 20,
            ),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 820,
                maxHeight: maxDialogHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildHeader(isBusy),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        screenSize.width < 600 ? 16 : 24,
                        22,
                        screenSize.width < 600 ? 16 : 24,
                        24,
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth >= 660;
                            return _buildForm(
                              provider.trainingTypes,
                              isWide,
                              isBusy,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  _buildActions(provider, isBusy),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isBusy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF1274BC), Color(0xFF07568F)],
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Gửi yêu cầu CME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bổ sung thông tin và chứng chỉ',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
            disabledColor: Colors.white38,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    List<CmeTrainingType> trainingTypes,
    bool isWide,
    bool isBusy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _sectionTitle(
          icon: Icons.badge_outlined,
          title: 'Thông tin chứng chỉ',
          subtitle: 'Các mục có dấu * là bắt buộc',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tenChungChiController,
          enabled: !isBusy,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 300,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(300),
          ],
          decoration: _inputDecoration(
            label: 'Tên chứng chỉ *',
            hint: 'Ví dụ: Cập nhật kiến thức y khoa liên tục',
            icon: Icons.workspace_premium_outlined,
          ),
          validator: _validateRequiredName,
        ),
        const SizedBox(height: 14),
        _responsivePair(
          isWide: isWide,

          // =========================================================
          // SỐ CHỨNG CHỈ - BẮT BUỘC
          // =========================================================

          left: TextFormField(
            controller:
                _soChungChiController,

            enabled:
                !isBusy,

            maxLength:
                50,

            inputFormatters:
                <TextInputFormatter>[
              LengthLimitingTextInputFormatter(
                50,
              ),
            ],

            decoration:
                _inputDecoration(
              label:
                  'Số chứng chỉ *',

              hint:
                  'Nhập số chứng chỉ',

              icon:
                  Icons.numbers_rounded,
            ),

            validator:
                (value) =>
                    _validateRequiredText(
              value,
              50,
              'số chứng chỉ',
            ),
          ),

          // =========================================================
          // ĐƠN VỊ ĐÀO TẠO - BẮT BUỘC
          // =========================================================

          right: TextFormField(
            controller:
                _donViDaoTaoController,

            enabled:
                !isBusy,

            textCapitalization:
                TextCapitalization.words,

            maxLength:
                200,

            inputFormatters:
                <TextInputFormatter>[
              LengthLimitingTextInputFormatter(
                200,
              ),
            ],

            decoration:
                _inputDecoration(
              label:
                  'Đơn vị đào tạo *',

              hint:
                  'Tên đơn vị tổ chức/đào tạo',

              icon:
                  Icons.account_balance_outlined,
            ),

            validator:
                (value) =>
                    _validateRequiredText(
              value,
              200,
              'đơn vị đào tạo',
            ),
          ),
        ),
        const SizedBox(height: 14),
        _responsivePair(
          isWide: isWide,

          // =========================================================
          // HÌNH THỨC ĐÀO TẠO - BẮT BUỘC
          // =========================================================

          left:
              DropdownButtonFormField<int?>(
            initialValue:
                _idHinhThucDaoTao,

            isExpanded:
                true,

            decoration:
                _inputDecoration(
              label:
                  'Hình thức đào tạo *',

              icon:
                  Icons.school_outlined,
            ),

            items:
                <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value:
                    null,

                child:
                    Text(
                  'Chưa chọn',
                ),
              ),

              ...trainingTypes.map(
                (type) =>
                    DropdownMenuItem<int?>(
                  value:
                      type.id,

                  child:
                      Text(
                    type.name.isNotEmpty
                        ? type.name
                        : 'Hình thức #${type.id}',

                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],

            validator:
                (value) {
              if (value == null ||
                  value <= 0) {
                return 'Vui lòng chọn hình thức đào tạo.';
              }

              return null;
            },

            onChanged:
                isBusy
                    ? null
                    : (value) {
                        setState(() {
                          _idHinhThucDaoTao =
                              value;
                        });
                      },
          ),

          // =========================================================
          // SỐ TIẾT - BẮT BUỘC
          // =========================================================

          right:
              TextFormField(
            controller:
                _soTietController,

            enabled:
                !isBusy,

            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal:
                  true,
            ),

            inputFormatters:
                <TextInputFormatter>[
              _decimalInputFormatter,
            ],

            decoration:
                _inputDecoration(
              label:
                  'Giờ tín chỉ *',

              hint:
                  'Ví dụ: 12,5',

              icon:
                  Icons.schedule_outlined,

              suffixText:
                  'tiết',
            ),

            validator:
                _validateSoTiet,
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(
          icon: Icons.date_range_outlined,
          title: 'Thời gian',
          subtitle: 'Chọn các mốc thời gian có trên chứng chỉ',
        ),
        const SizedBox(height: 16),
        _responsivePair(
          isWide: isWide,
          left: _DateFormField(
            label: 'Ngày bắt đầu',
            value: _ngayBatDau,
            enabled: !isBusy,
            onChanged: (value) {
              setState(() {
                _ngayBatDau = value;
              });
            },
          ),
          right: _DateFormField(
            label: 'Ngày kết thúc',
            value: _ngayKetThuc,
            enabled: !isBusy,
            validator: (_) {
              if (_ngayBatDau != null &&
                  _ngayKetThuc != null &&
                  _ngayKetThuc!.isBefore(_ngayBatDau!)) {
                return 'Ngày kết thúc không được trước ngày bắt đầu.';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _ngayKetThuc = value;
              });
            },
          ),
        ),
        const SizedBox(height: 14),
        _responsivePair(
          isWide: isWide,
          left: _DateFormField(
            label: 'Ngày cấp',
            value: _ngayCap,
            enabled: !isBusy,
            onChanged: (value) {
              setState(() {
                _ngayCap = value;
              });
            },
          ),
          right: _DateFormField(
            label: 'Ngày hết hạn',
            value: _ngayHetHan,
            enabled: !isBusy,
            validator: (_) {
              if (_ngayCap != null &&
                  _ngayHetHan != null &&
                  _ngayHetHan!.isBefore(_ngayCap!)) {
                return 'Ngày hết hạn không được trước ngày cấp.';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _ngayHetHan = value;
              });
            },
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 378 : double.infinity),
          child: TextFormField(
            controller: _chuKyController,
            enabled: !isBusy,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _inputDecoration(
              label: 'Chu kỳ',
              hint: 'Nhập chu kỳ ghi trên chứng chỉ',
              icon: Icons.autorenew_rounded,
            ),
            validator: _validateChuKy,
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(
          icon: Icons.attach_file_rounded,
          title: 'File đính kèm *',
          subtitle: 'Chỉ chấp nhận file PDF, dung lượng tối đa 10 MB',
        ),
        const SizedBox(height: 14),
        _buildFilePicker(isBusy),
      ],
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _cmePrimaryColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _cmePrimaryColor),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _responsivePair({
    required bool isWide,
    required Widget left,
    required Widget right,
  }) {
    if (!isWide) {
      return Column(
        children: <Widget>[left, const SizedBox(height: 14), right],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      prefixIcon: Icon(icon, size: 20),
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _cmePrimaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildFilePicker(bool isBusy) {
    final bool hasFile = _fileBytes != null && _fileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasFile ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _fileError != null
                  ? Colors.red.shade400
                  : hasFile
                  ? const Color(0xFF86C99A)
                  : Colors.grey.shade300,
            ),
          ),
          child: hasFile
              ? Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(_fileSize ?? 0),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: isBusy ? null : _pickFile,
                      child: const Text('Đổi file'),
                    ),
                    IconButton(
                      tooltip: 'Xóa file PDF',
                      onPressed: isBusy ? null : _removeFile,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.grey.shade700,
                    ),
                  ],
                )
              : InkWell(
                  onTap: isBusy ? null : _pickFile,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (_isPickingFile)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        else
                          const Icon(
                            Icons.cloud_upload_outlined,
                            color: _cmePrimaryColor,
                            size: 28,
                          ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _isPickingFile
                                    ? 'Đang đọc file PDF...'
                                    : 'Chọn file PDF từ thiết bị',
                                style: const TextStyle(
                                  color: _cmePrimaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!_isPickingFile)
                                Text(
                                  'Chỉ file PDF • Tối đa 10 MB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_fileError != null) ...<Widget>[
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _fileError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(CmeProvider provider, bool isBusy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: isBusy ? null : () => _submit(provider),
            style: FilledButton.styleFrom(
              backgroundColor: _cmePrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 19),
            label: Text(provider.isSubmitting ? 'Đang gửi...' : 'Gửi duyệt'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DateFormField extends StatelessWidget {
  const _DateFormField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;
  final FormFieldValidator<DateTime>? validator;

  Future<void> _selectDate(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        value ?? DateTime(now.year, now.month, now.day);
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1753),
      lastDate: DateTime(9999, 12, 31),
      helpText: label.toUpperCase(),
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );

    if (selected != null) {
      field.didChange(selected);
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      validator: (_) => validator?.call(value),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              onTap: enabled ? () => _selectDate(context, field) : null,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                isEmpty: value == null,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                  ),
                  suffixIcon: value == null
                      ? const Icon(Icons.arrow_drop_down_rounded)
                      : IconButton(
                          tooltip: 'Xóa ngày',
                          onPressed: enabled
                              ? () {
                                  field.didChange(null);
                                  onChanged(null);
                                }
                              : null,
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  filled: true,
                  fillColor: enabled
                      ? const Color(0xFFF8FAFC)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  errorText: field.errorText,
                ),
                child: Text(
                  value == null
                      ? ''
                      : DateFormat('dd/MM/yyyy').format(value!),
                  style: TextStyle(
                    color: value == null
                        ? Colors.grey.shade600
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
