import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/thuc_hanh_models.dart';
import '../../services/api_client.dart';
import '../../services/thuc_hanh_service.dart';
import 'thuc_hanh_file_viewer.dart';

class ThucHanhPublicScreen extends StatefulWidget {
  final String? publicToken;
  final ThucHanhService? service;

  const ThucHanhPublicScreen({super.key, this.publicToken, this.service});
  @override
  State<ThucHanhPublicScreen> createState() => _ThucHanhPublicScreenState();
}

class _ThucHanhPublicScreenState extends State<ThucHanhPublicScreen> {
  late final ThucHanhService service;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      cccd = TextEditingController(),
      phone = TextEditingController(),
      email = TextEditingController(),
      address = TextEditingController(),
      currentAddress = TextEditingController(),
      school = TextEditingController(),
      major = TextEditingController(),
      level = TextEditingController(),
      content = TextEditingController();
  DotThucHanhModel? batch;
  ThucHanhPage<DotThucHanhModel> batches = const ThucHanhPage();
  String batchKeyword = '';
  Timer? searchTimer;
  DateTime? birthday;
  bool? gender;
  bool consent = false, loading = true, saving = false;
  String? error;
  String? successLookupCode;
  String get _publicWebUrl {
    final uri = Uri.base;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return uri.origin;
    }

    return '';
  }

  bool successEmailQueued = false;
  bool openingDecision = false;
  final birthdayKey = GlobalKey<FormFieldState<DateTime>>();
  final avatarKey = GlobalKey<FormFieldState<PlatformFile>>();
  PlatformFile? avatar;
  final List<(PlatformFile, int)> files = [];
  @override
  void initState() {
    super.initState();
    service = widget.service ?? ThucHanhService(ApiClient().dio);
    _load();
  }

  @override
  void dispose() {
    for (final x in [
      name,
      cccd,
      phone,
      email,
      address,
      currentAddress,
      school,
      major,
      level,
      content,
    ]) {
      x.dispose();
    }
    searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    try {
      if (widget.publicToken?.isNotEmpty == true) {
        batch = await service.getPublicBatch(widget.publicToken!);
      } else {
        batches = await service.getPublicBatches(
          keyword: batchKeyword,
          page: page,
        );
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F7FA),
    appBar: AppBar(
      elevation: 0,
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF075E91),
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF075E91), Color(0xFF0796C5)],
          ),
        ),
      ),
      title: const Text(
        'Đăng ký thực hành',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7F4F9), Color(0xFFF7FAFC)],
        ),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _error()
          : successLookupCode != null
          ? _successView()
          : batch == null
          ? _chooseBatch()
          : _form(),
    ),
  );
  Widget _error() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 55, color: Colors.red),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                loading = true;
                error = null;
              });
              _load();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
  Widget _chooseBatch() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF075E91), Color(0xFF19A2C9)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33075E91),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng ký thực hành tại bệnh viện',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Chọn đợt đang mở và hoàn thành hồ sơ trực tuyến.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm theo tên hoặc nội dung đợt...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              searchTimer?.cancel();
              searchTimer = Timer(const Duration(milliseconds: 450), () {
                batchKeyword = value.trim();
                _load();
              });
            },
          ),
          const SizedBox(height: 12),
          if (batches.items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Text('Hiện chưa có đợt thực hành đang mở.'),
              ),
            )
          else
            ...batches.items.map(
              (x) => Card(
                elevation: 0,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                  side: const BorderSide(color: Color(0xFFD9E8EF)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    child: Icon(Icons.event_available),
                  ),
                  title: Text(
                    x.tenDot,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Đăng ký đến ${DateFormat('dd/MM/yyyy').format(x.ketThucDangKy)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => batch = x),
                ),
              ),
            ),
          if (batches.totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: batches.page > 1
                      ? () => _load(page: batches.page - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${batches.page}/${batches.totalPages}'),
                IconButton(
                  onPressed: batches.page < batches.totalPages
                      ? () => _load(page: batches.page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _successView() {
    final lookupCode = successLookupCode!;

    final base = _publicWebUrl;

    final lookupLink = base.isEmpty
        ? ''
        : '$base/#/tra-cuu-thuc-hanh/$lookupCode';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCE9EF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22075E91),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF15936D),
                size: 64,
              ),
              const SizedBox(height: 12),
              const Text(
                'Đăng ký thành công',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                successEmailQueued
                    ? 'QR tra cứu đang được gửi tới ${email.text.trim()}.'
                    : 'Chưa xếp hàng gửi được email. Hãy lưu mã hoặc QR tra cứu bên dưới.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF5D7481)),
              ),
              if (lookupLink.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE9EF)),
                  ),
                  child: QrImageView(data: lookupLink, size: 220),
                ),
              ],
              const SizedBox(height: 12),
              const Text('Mã tra cứu', style: TextStyle(fontSize: 12)),
              SelectableText(
                lookupCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF075E91),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 9,
                runSpacing: 9,
                children: [
                  if (lookupLink.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: lookupLink),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép link tra cứu.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Sao chép link'),
                    ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/tra-cuu-thuc-hanh/$lookupCode',
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text('Mở trang tra cứu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form() => Form(
    key: formKey,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 35),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _batchCard(),
                const SizedBox(height: 14),
                _card(
                  title: 'Thông tin cá nhân',
                  icon: Icons.person_outline,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 13,
                    children: [
                      _field(
                        name,
                        'Họ và tên *',
                        required: true,
                        maxLength: 250,
                        textCapitalization: TextCapitalization.words,
                      ),
                      _field(
                        cccd,
                        'Số CCCD *',
                        required: true,
                        maxLength: 15,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validateCccd,
                      ),
                      _field(
                        phone,
                        'Số điện thoại *',
                        required: true,
                        maxLength: 20,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        ],
                        validator: _validatePhone,
                      ),
                      _field(
                        email,
                        'Email *',
                        required: true,
                        maxLength: 150,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      _field(address, 'Địa chỉ thường trú', maxLength: 500),
                      _field(currentAddress, 'Nơi ở hiện tại', maxLength: 500),
                      _field(
                        school,
                        'Trường/đơn vị *',
                        required: true,
                        maxLength: 250,
                      ),
                      _field(
                        major,
                        'Chuyên ngành *',
                        required: true,
                        maxLength: 250,
                      ),
                      _field(
                        level,
                        'Trình độ chuyên môn *',
                        required: true,
                        maxLength: 150,
                      ),
                      SizedBox(
                        width: 390,
                        child: FormField<DateTime>(
                          key: birthdayKey,
                          initialValue: birthday,
                          validator: (v) =>
                              v == null ? 'Vui lòng chọn ngày sinh' : null,
                          builder: (field) => InkWell(
                            onTap: _pickBirthday,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Ngày sinh *',
                                border: const OutlineInputBorder(),
                                errorText: field.errorText,
                                suffixIcon: const Icon(Icons.calendar_month),
                              ),
                              child: Text(
                                birthday == null
                                    ? 'Chọn ngày sinh'
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(birthday!),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 390,
                        child: DropdownButtonFormField<bool>(
                          initialValue: gender,
                          decoration: const InputDecoration(
                            labelText: 'Giới tính *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Nam')),
                            DropdownMenuItem(value: false, child: Text('Nữ')),
                          ],
                          onChanged: (v) => gender = v,
                          validator: (v) =>
                              v == null ? 'Vui lòng chọn giới tính' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  title: 'Ảnh và hồ sơ đính kèm',
                  icon: Icons.attach_file,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (avatar?.bytes != null) ...[
                        Center(
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF8FC9DE),
                                width: 3,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.memory(
                              avatar!.bytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FormField<PlatformFile>(
                            key: avatarKey,
                            validator: (v) =>
                                v == null ? 'Vui lòng chọn ảnh đại diện' : null,
                            builder: (field) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickAvatar,
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: Text(
                                    avatar?.name ?? 'Chọn ảnh đại diện *',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (field.hasError)
                                  Text(
                                    field.errorText!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickDocument,
                            icon: const Icon(Icons.note_add_outlined),
                            label: const Text('Thêm file hồ sơ'),
                          ),
                        ],
                      ),
                      if (files.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          children: files
                              .map(
                                (x) => Chip(
                                  label: Text(
                                    '${_typeName(x.$2)}: ${x.$1.name}',
                                  ),
                                  onDeleted: () =>
                                      setState(() => files.remove(x)),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Chấp nhận PDF, DOC, DOCX, JPG, PNG; tối đa 10 MB mỗi file.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  title: 'Nội dung đăng ký',
                  icon: Icons.edit_note,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: content,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          hintText:
                              'Nội dung hoặc ghi chú gửi bộ phận phụ trách',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      CheckboxListTile(
                        value: consent,
                        onChanged: (v) => setState(() => consent = v ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Tôi đồng ý cho bệnh viện thu thập và xử lý thông tin trong hồ sơ này.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: saving ? null : _submit,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(saving ? 'Đang gửi...' : 'Gửi đăng ký'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _batchCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF087DBA), Color(0xFF24A0C9)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.local_hospital_outlined,
          color: Colors.white,
          size: 38,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                batch!.tenDot,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Thời gian đăng ký đến ${DateFormat('dd/MM/yyyy').format(batch!.ketThucDangKy)}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (batch!.fileQuyetDinh != null)
                TextButton.icon(
                  onPressed: openingDecision ? null : _openDecision,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                  ),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: Text(
                    openingDecision
                        ? 'Đang tải quyết định...'
                        : 'Xem quyết định',
                  ),
                ),
            ],
          ),
        ),
        if (widget.publicToken == null)
          TextButton(
            onPressed: () => setState(() => batch = null),
            child: const Text('Đổi đợt', style: TextStyle(color: Colors.white)),
          ),
      ],
    ),
  );
  Future<void> _openDecision() async {
    final selected = batch!;
    setState(() => openingDecision = true);
    await showThucHanhFile(
      context,
      service,
      service.publicDecisionUrl(selected.publicToken),
      selected.fileQuyetDinh!,
    );
    if (mounted) setState(() => openingDecision = false);
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Card(
    elevation: 0,
    color: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFDCE9EF)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF087DBA)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    ),
  );
  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) => SizedBox(
    width: 390,
    child: TextFormField(
      controller: c,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'Vui lòng nhập thông tin';
        return validator?.call(text);
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FBFC),
        border: const OutlineInputBorder(),
        counterText: '',
      ),
    ),
  );

  String? _validateCccd(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^(?:\d{9}|\d{12})$').hasMatch(value)) {
      return 'CCCD phải gồm 9 hoặc 12 chữ số';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.replaceFirst('+84', '0');
    if (!RegExp(r'^0\d{9,10}$').hasMatch(normalized)) {
      return 'Số điện thoại không đúng định dạng';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  Future<void> _pickBirthday() async {
    final v = await showDatePicker(
      context: context,
      initialDate: birthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (v != null && mounted) {
      setState(() => birthday = v);
      birthdayKey.currentState?.didChange(v);
    }
  }

  Future<void> _pickAvatar() async {
    final r = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (r == null || !mounted) return;
    final file = r.files.single;
    if (file.bytes == null || file.size == 0 || file.size > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn ảnh JPG/PNG có dung lượng tối đa 10 MB.'),
        ),
      );
      return;
    }
    setState(() => avatar = file);
    avatarKey.currentState?.didChange(file);
  }

  Future<void> _pickDocument() async {
    final r = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (r == null || !mounted) return;
    final type = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Loại hồ sơ'),
        children: [
          for (final i in [1, 2, 3, 4, 5, 6, 9])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, i),
              child: Text(_typeName(i)),
            ),
        ],
      ),
    );
    if (type != null) setState(() => files.add((r.files.single, type)));
  }

  String _typeName(int i) => const {
    1: 'CCCD mặt trước',
    2: 'CCCD mặt sau',
    3: 'Bằng chuyên môn',
    4: 'Sơ yếu lý lịch',
    5: 'Giấy giới thiệu',
    6: 'Chứng từ khác',
    9: 'Khác',
  }[i]!;
  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý xử lý dữ liệu cá nhân.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final result = await service.publicRegister(
        batch!.publicToken,
        {
          'hoVaTen': name.text.trim(),
          'ngaySinh': birthday?.toIso8601String(),
          'gioiTinh': gender,
          'soCCCD': cccd.text.trim(),
          'soDienThoai': phone.text.trim(),
          'email': email.text.trim(),
          'diaChiThuongTru': address.text.trim(),
          'noiOHienTai': currentAddress.text.trim(),
          'truongDonVi': school.text.trim(),
          'chuyenNganh': major.text.trim(),
          'trinhDoChuyenMon': level.text.trim(),
          'noiDungDangKy': content.text.trim(),
          'dongYXuLyDuLieu': true,
          'loaiFiles': files.map((x) => x.$2).toList(),
          'fileIdsToDelete': <int>[],
        },
        avatar: avatar,
        files: files.map((x) => x.$1).toList(),
      );
      if (!mounted) return;
      final lookupCode = result['maTraCuu']?.toString() ?? '';
      if (lookupCode.isEmpty) {
        throw Exception('Máy chủ chưa trả về mã tra cứu.');
      }
      setState(() {
        successLookupCode = lookupCode;
        successEmailQueued = result['emailDangGui'] == true;
        saving = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
