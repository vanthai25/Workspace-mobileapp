import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/su_kien_effect_models.dart';
import '../../../../models/su_kien_v2_models.dart';
import '../../../../providers/su_kien_v2_provider.dart';
import '../../widgets/su_kien_effect_editor.dart';


class SuKienFormDialog
    extends StatefulWidget {
  final SuKienV2Model? item;

  const SuKienFormDialog({
    super.key,
    this.item,
  });

  bool get isEdit =>
      item != null;

  @override
  State<SuKienFormDialog>
      createState() =>
          _SuKienFormDialogState();
}


class _SuKienFormDialogState
    extends State<SuKienFormDialog> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _maController;

  late final TextEditingController
      _tenController;

  late final TextEditingController
      _moTaController;

  late final TextEditingController
      _uuTienController;

  late DateTime _tuNgay;

  late DateTime _denNgay;

  DateTime? _ngaySuKien;

  bool _isActive =
      true;

  bool _showCountdown =
      false;
  late SuKienEffectConfig
    _effectConfig;


  @override
  void initState() {
    super.initState();

    final item =
        widget.item;

    _maController =
        TextEditingController(
      text:
          item?.maSuKien ??
          '',
    );

    _tenController =
        TextEditingController(
      text:
          item?.tenSuKien ??
          '',
    );

    _moTaController =
        TextEditingController(
      text:
          item?.moTa ??
          '',
    );

    _uuTienController =
        TextEditingController(
      text:
          '${item?.mucUuTien ?? 0}',
    );

    _tuNgay =
        item?.tuNgay ??
        DateTime.now();

    _denNgay =
        item?.denNgay ??
        DateTime.now().add(
          const Duration(
            days: 7,
          ),
        );

    _ngaySuKien =
        item?.ngaySuKien;

    _isActive =
        item?.isActive ??
        true;

    _showCountdown =
        item?.showCountdown ??
        false;

    _effectConfig =
        SuKienEffectConfig.fromStored(
      item?.effectConfig,
      legacyType:
          item?.effectType,
    );
  }


  @override
  void dispose() {
    _maController.dispose();
    _tenController.dispose();
    _moTaController.dispose();
    _uuTienController.dispose();

    super.dispose();
  }


  Future<DateTime?> _pickDateTime(
    DateTime initial,
  ) async {
    final date =
        await showDatePicker(
      context:
          context,

      initialDate:
          initial,

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2100),
    );

    if (date == null ||
        !mounted) {
      return null;
    }

    final time =
        await showTimePicker(
      context:
          context,

      initialTime:
          TimeOfDay.fromDateTime(
        initial,
      ),
    );

    if (time == null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
      );
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }


  String _dateTimeText(
    DateTime value,
  ) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }


  Future<void> _save() async {
    if (!(_formKey.currentState
            ?.validate() ??
        false)) {
      return;
    }

    if (_tuNgay.isAfter(
      _denNgay,
    )) {
      _showError(
        'Thời gian bắt đầu không được lớn hơn thời gian kết thúc.',
      );

      return;
    }

    if (_ngaySuKien != null &&
        (
          _ngaySuKien!.isBefore(
            _tuNgay,
          ) ||
          _ngaySuKien!.isAfter(
            _denNgay,
          )
        )) {
      _showError(
        'Ngày sự kiện phải nằm trong khoảng thời gian hiển thị.',
      );

      return;
    }

    final payload =
        <String, dynamic>{
      'maSuKien':
          _emptyToNull(
        _maController.text,
      ),

      'tenSuKien':
          _tenController.text.trim(),

      'moTa':
          _emptyToNull(
        _moTaController.text,
      ),

      'tuNgay':
          _tuNgay.toIso8601String(),

      'denNgay':
          _denNgay.toIso8601String(),

      'ngaySuKien':
          _ngaySuKien
              ?.toIso8601String(),

      'isActive':
          _isActive,

      'showCountdown':
          _showCountdown,

      'effectType':
        _effectConfig
            .primaryEffectType,

      'effectConfig':
          _effectConfig
              .toJsonString(),

      'mucUuTien':
          int.tryParse(
            _uuTienController.text
                .trim(),
          ) ??
          0,
    };



    final provider =
        context.read<
            SuKienV2Provider>();

    final bool ok;

    if (widget.item == null) {
      ok =
          await provider.create(
        payload,
      );
    } else {
      ok =
          await provider.update(
        widget.item!.idSuKien,
        payload,
      );
    }

    if (!mounted) {
      return;
    }

    if (!ok) {
      _showError(
        provider.errorMessage ??
            'Không thể lưu sự kiện.',
      );

      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }


  String? _emptyToNull(
    String value,
  ) {
    final text =
        value.trim();

    return text.isEmpty
        ? null
        : text;
  }


  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            Colors.red.shade700,
      ),
    );
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    final provider =
        context.watch<
            SuKienV2Provider>();

    return AlertDialog(
      title:
          Text(
        widget.isEdit
            ? 'Sửa sự kiện'
            : 'Thêm sự kiện',
      ),

      content:
          SizedBox(
        width:
            760,

        child:
            Form(
          key:
              _formKey,

          child:
              SingleChildScrollView(
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            _maController,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Mã sự kiện',

                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                          12,
                    ),

                    Expanded(
                      flex:
                          2,

                      child:
                          TextFormField(
                        controller:
                            _tenController,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Tên sự kiện *',

                          border:
                              OutlineInputBorder(),
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Vui lòng nhập tên sự kiện.';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      14,
                ),

                TextFormField(
                  controller:
                      _moTaController,

                  maxLines:
                      3,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Mô tả',

                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height:
                      14,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          _dateBox(
                        label:
                            'Bắt đầu',

                        value:
                            _tuNgay,

                        onTap:
                            () async {
                          final value =
                              await _pickDateTime(
                            _tuNgay,
                          );

                          if (value !=
                              null) {
                            setState(
                              () =>
                                  _tuNgay =
                                      value,
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(
                      width:
                          12,
                    ),

                    Expanded(
                      child:
                          _dateBox(
                        label:
                            'Kết thúc',

                        value:
                            _denNgay,

                        onTap:
                            () async {
                          final value =
                              await _pickDateTime(
                            _denNgay,
                          );

                          if (value !=
                              null) {
                            setState(
                              () =>
                                  _denNgay =
                                      value,
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(
                      width:
                          12,
                    ),

                    Expanded(
                      child:
                          _optionalDateBox(
                        label:
                            'Ngày sự kiện',

                        value:
                            _ngaySuKien,

                        onTap:
                            () async {
                          final value =
                              await _pickDateTime(
                            _ngaySuKien ??
                                _tuNgay,
                          );

                          if (value !=
                              null) {
                            setState(
                              () =>
                                  _ngaySuKien =
                                      value,
                            );
                          }
                        },

                        onClear:
                            () {
                          setState(
                            () =>
                                _ngaySuKien =
                                    null,
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      14,
                ),

                SuKienEffectEditor(
                  config:
                      _effectConfig,

                  onChanged:
                      (value) {
                    setState(() {
                      _effectConfig =
                          value;
                    });
                  },
                ),

                const SizedBox(
                  height:
                      14,
                ),

                TextFormField(
                  controller:
                      _uuTienController,

                  keyboardType:
                      TextInputType.number,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Mức ưu tiên',

                    helperText:
                        'Số lớn hơn được ưu tiên hiển thị trước',

                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                SwitchListTile(
                  contentPadding:
                      EdgeInsets.zero,

                  value:
                      _isActive,

                  title:
                      const Text(
                    'Đang bật',
                  ),

                  subtitle:
                      const Text(
                    'Sự kiện chỉ được hiển thị khi đang bật và nằm trong thời gian hiệu lực.',
                  ),

                  onChanged:
                      (value) {
                    setState(
                      () =>
                          _isActive =
                              value,
                    );
                  },
                ),

                SwitchListTile(
                  contentPadding:
                      EdgeInsets.zero,

                  value:
                      _showCountdown,

                  title:
                      const Text(
                    'Hiển thị đếm ngược',
                  ),

                  subtitle:
                      const Text(
                    'Dùng Ngày sự kiện để tính số ngày còn lại.',
                  ),

                  onChanged:
                      (value) {
                    setState(
                      () =>
                          _showCountdown =
                              value,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed:
              provider.isSaving
                  ? null
                  : () =>
                      Navigator.pop(
                        context,
                      ),

          child:
              const Text(
            'Hủy',
          ),
        ),

        FilledButton.icon(
          onPressed:
              provider.isSaving
                  ? null
                  : _save,

          icon:
              provider.isSaving
                  ? const SizedBox(
                      width:
                          16,
                      height:
                          16,

                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                      ),
                    )
                  : const Icon(
                      Icons.save_outlined,
                    ),

          label:
              Text(
            provider.isSaving
                ? 'Đang lưu...'
                : 'Lưu',
          ),
        ),
      ],
    );
  }


  Widget _dateBox({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap:
          onTap,

      child:
          InputDecorator(
        decoration:
            InputDecoration(
          labelText:
              label,

          border:
              const OutlineInputBorder(),

          suffixIcon:
              const Icon(
            Icons.calendar_month_outlined,
          ),
        ),

        child:
            Text(
          _dateTimeText(
            value,
          ),
        ),
      ),
    );
  }


  Widget _optionalDateBox({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap:
          onTap,

      child:
          InputDecorator(
        decoration:
            InputDecoration(
          labelText:
              label,

          border:
              const OutlineInputBorder(),

          suffixIcon:
              value == null
                  ? const Icon(
                      Icons.calendar_month_outlined,
                    )
                  : IconButton(
                      onPressed:
                          onClear,

                      icon:
                          const Icon(
                        Icons.close_rounded,
                      ),
                    ),
        ),

        child:
            Text(
          value == null
              ? 'Chưa chọn'
              : _dateTimeText(
                  value,
                ),
        ),
      ),
    );
  }
}