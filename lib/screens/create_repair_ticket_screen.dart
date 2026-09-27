import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/tai_san_model.dart';
import '../models/taisan_repair_model.dart'; 
import '../providers/auth_provider.dart';
import '../services/taisan_repair_service.dart';
import '../services/taisan_service.dart';
import '../utils/helpers.dart'; 
import '../utils/constants.dart'; 
import 'scanner_screen.dart'; // 🔥 Thêm thư viện quét QR mới của bạn

class CreateRepairTicketScreen extends StatefulWidget {
  final TaiSanRepair? editTicket; 
  final TaiSan? initialTaiSan; 

  const CreateRepairTicketScreen({
    super.key, 
    this.editTicket, 
    this.initialTaiSan, 
  }); 

  @override
  State<CreateRepairTicketScreen> createState() => _CreateRepairTicketScreenState();
}

class _CreateRepairTicketScreenState extends State<CreateRepairTicketScreen> {
  
  final TaiSanRepairService _apiService = TaiSanRepairService();
  final TaiSanService _taiSanService = TaiSanService();
  final Color primaryColor = const Color(0xFF1274BC);

  bool _isLoading = false;
  List<TaiSan> _listTaiSan = [];

  // Controllers
  final TextEditingController _tenTaiSanController = TextEditingController();
  final FocusNode _tenTaiSanFocusNode = FocusNode();
  final TextEditingController _viTriController = TextEditingController();
  final TextEditingController _noiDungController = TextEditingController();
  final TextEditingController _ghiChuController = TextEditingController();

  String? _maTaiSanSelected;
  String _khoaNhanSelected = 'CN';
  int _mucUuTienSelected = 1;

  // Quản lý Ảnh
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = []; // Danh sách ảnh MỚI chọn
  List<int> _existingFileIds = []; // Danh sách ID ảnh CŨ từ server
  List<int> _deletedFileIds = [];  // Danh sách ID ảnh CŨ bị người dùng xóa đi

  @override
  void dispose() {
    _tenTaiSanController.dispose();
    _tenTaiSanFocusNode.dispose();
    _viTriController.dispose();
    _noiDungController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    _fetchTaiSan();
    _tenTaiSanController.addListener(() {
      if (_maTaiSanSelected != null) {
         setState(() {
           _maTaiSanSelected = null; 
         });
      }
    });
    if (widget.editTicket != null) {
      _maTaiSanSelected = widget.editTicket!.maTaiSanId;
      _tenTaiSanController.text = widget.editTicket!.tentaisan ?? '';
      _viTriController.text = widget.editTicket!.vitrisudung ?? '';
      _noiDungController.text = widget.editTicket!.noidung ?? '';
      _ghiChuController.text = widget.editTicket!.ghichu ?? '';
      
      if (widget.editTicket!.khoanhan == 'CNTT' || widget.editTicket!.khoanhan == 'CN') {
        _khoaNhanSelected = widget.editTicket!.khoanhan!;
      }
      if (widget.editTicket!.mucuutien != null) {
        _mucUuTienSelected = widget.editTicket!.mucuutien!;
      }
      
      // LOAD DANH SÁCH ẢNH CŨ VÀO BIẾN
      if (widget.editTicket!.fileIds != null && widget.editTicket!.fileIds!.isNotEmpty) {
        _existingFileIds = List.from(widget.editTicket!.fileIds!);
      }
    } 
    else if (widget.initialTaiSan != null) {
      _maTaiSanSelected = widget.initialTaiSan!.maTaiSan;
      _tenTaiSanController.text = widget.initialTaiSan!.tentaisan ?? '';
      _viTriController.text = widget.initialTaiSan!.viTriSuDung ?? '';
    }
  }

  Future<void> _fetchTaiSan() async {
    final data = await _taiSanService.getDanhSachTaiSan(page: 1, pageSize: 20);
    if (mounted) setState(() => _listTaiSan = data);
  }

  // --- HÀM CHỌN ẢNH / CHỤP ẢNH LINH HOẠT ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
        if (image != null) {
          setState(() => _selectedImages.add(File(image.path)));
        }
      } else {
        final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images.map((img) => File(img.path)));
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Chọn phương thức đính kèm ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: primaryColor),
              title: const Text('Chụp ảnh từ Máy ảnh (Camera)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: primaryColor),
              title: const Text('Chọn ảnh từ Thư viện ảnh (Gallery)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removeNewImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _removeExistingImage(int fileId) {
    setState(() {
      _existingFileIds.remove(fileId);
      _deletedFileIds.add(fileId);
    });
  }

  // 🔥 LUỒNG QUÉT QR MỚI (Dùng QrScannerScreen giống list ngoài)
  Future<void> _scanQRCode(TextEditingController searchController) async {
    try {
      final String? barcodeScanRes = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );

      if (barcodeScanRes != null && barcodeScanRes.isNotEmpty) {
        searchController.text = barcodeScanRes;
        _tenTaiSanController.text = barcodeScanRes;
        await _fetchTaiSanByQR(barcodeScanRes); 
      }
    } catch (e) {
      AppHelpers.showSnackBar('Lỗi mở máy quét: $e', isError: true);
    }
  }

  Future<void> _fetchTaiSanByQR(String maTaiSan) async {
    setState(() => _isLoading = true);
    try {
      final results = await _taiSanService.getDanhSachTaiSan(maTaiSan: maTaiSan, pageSize: 1);
      
      if (results.isNotEmpty) {
        final option = results.first;
        setState(() {
          _maTaiSanSelected = option.maTaiSan;
          _tenTaiSanController.text = option.tentaisan ?? '';
          _viTriController.text = option.viTriSuDung ?? '';
        });
        AppHelpers.showSnackBar('✅ Đã quét thấy: ${option.tentaisan}');
      } else {
        AppHelpers.showSnackBar('❌ Không tìm thấy tài sản nào khớp với mã: $maTaiSan', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    final auth = context.read<AuthProvider>();
    final tenTaiSan = _tenTaiSanController.text.trim();
    final noiDung = _noiDungController.text.trim();

    if (tenTaiSan.isEmpty || noiDung.isEmpty) {
      AppHelpers.showSnackBar('Vui lòng nhập Tên tài sản và Nội dung hỏng hóc', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool isSuccess = false;

      if (widget.editTicket != null) {
        int currentRepairId = widget.editTicket!.id!;
        
        List<int> newUploadedFileIds = [];
        if (_selectedImages.isNotEmpty) {
          List<String> filePaths = _selectedImages.map((f) => f.path).toList();
          newUploadedFileIds = await _apiService.uploadFiles(filePaths);
        }

        Map<String, dynamic> updatePayload = {
          "ngaylap": widget.editTicket!.ngaylap,
          "nguoilap": widget.editTicket!.nguoilap ?? auth.currentManv,
          "khoalap": widget.editTicket!.khoalap ?? auth.currentMaKhoa,
          "maTaiSanId": _maTaiSanSelected ?? '',
          "tentaisan": tenTaiSan,
          "vitrisudung": _viTriController.text.trim(),
          "noidung": noiDung,
          "khoanhan": _khoaNhanSelected,
          "mucuutien": _mucUuTienSelected,
          "ghichu": _ghiChuController.text.trim(),
          "newFileIds": newUploadedFileIds,
          "deletedFileIds": _deletedFileIds,
        };

        isSuccess = await _apiService.updateTaiSanRepair(currentRepairId, updatePayload);
      }
      else {
        // 1. Upload ảnh
        List<int> uploadedFileIds = [];
        if (_selectedImages.isNotEmpty) {
          List<String> filePaths = _selectedImages.map((f) => f.path).toList();
          uploadedFileIds = await _apiService.uploadFiles(filePaths);
        }

        // 2. Gửi tạo
        Map<String, dynamic> createPayload = {
          "maTaiSanId": _maTaiSanSelected,
          "tentaisan": tenTaiSan,
          "vitrisudung": _viTriController.text.trim(),
          "noidung": noiDung,
          "nguoilap": auth.currentManv ?? '',
          "khoalap": auth.currentMaKhoa ?? '', 
          "khoanhan": _khoaNhanSelected,
          "mucuutien": _mucUuTienSelected,
          "ghichu": _ghiChuController.text.trim(),
          "fileIds": uploadedFileIds, 
        };

        isSuccess = await _apiService.createTaiSanRepair(createPayload);
      }

      if (isSuccess) {
        if (mounted) {
          AppHelpers.showSnackBar(widget.editTicket != null ? 'Cập nhật phiếu thành công!' : 'Tạo phiếu báo sửa chữa thành công!');
          Navigator.pop(context, true); 
        }
      } else {
        if (mounted) AppHelpers.showSnackBar('Có lỗi xảy ra, không thể lưu phiếu', isError: true);
      }
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.editTicket != null;
    final currentMaKhoa = context.read<AuthProvider>().currentMaKhoa ?? '';
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(isEditing ? 'Cập nhật phiếu #${widget.editTicket!.id}' : 'Báo sửa chữa', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Thông tin tài sản',
                    icon: Icons.inventory_2_rounded,
                    child: Column(
                      children: [
                        Autocomplete<TaiSan>(
                          focusNode: _tenTaiSanFocusNode,
                          textEditingController: _tenTaiSanController,
                          
                          optionsBuilder: (TextEditingValue textEditingValue) async {
                            final query = textEditingValue.text.trim();
                            if (query.length < 2) return const Iterable<TaiSan>.empty();

                            final responses = await Future.wait([
                              _taiSanService.getDanhSachTaiSan(maTaiSan: query, pageSize: 50),
                              _taiSanService.getDanhSachTaiSan(tentaisan: query, pageSize: 50),
                            ]);

                            final Map<String, TaiSan> uniqueMap = {};
                            for (var item in responses[0]) uniqueMap[item.maTaiSan ?? ''] = item;
                            for (var item in responses[1]) uniqueMap[item.maTaiSan ?? ''] = item;
                            List<TaiSan> results = uniqueMap.values.toList();

                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            final myKhoa = auth.currentMaKhoa?.trim().toUpperCase() ?? '';

                            results.sort((a, b) {
                              bool aIsMyKhoa = (a.makhoa?.trim().toUpperCase() == myKhoa);
                              bool bIsMyKhoa = (b.makhoa?.trim().toUpperCase() == myKhoa);
                              
                              if (aIsMyKhoa && !bIsMyKhoa) return -1;
                              if (!aIsMyKhoa && bIsMyKhoa) return 1; 
                              return 0; 
                            });

                            return results;
                          },
                          
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 8.0,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 32,
                                  constraints: const BoxConstraints(maxHeight: 350),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      final auth = Provider.of<AuthProvider>(context, listen: false);
                                      final myKhoa = auth.currentMaKhoa?.trim().toUpperCase() ?? '';
                                      final isMyKhoa = option.makhoa?.trim().toUpperCase() == myKhoa;

                                      return ListTile(
                                        tileColor: isMyKhoa ? Colors.blue.withOpacity(0.08) : null,
                                        leading: Icon(
                                          isMyKhoa ? Icons.star_rounded : Icons.inventory_2_outlined, 
                                          color: isMyKhoa ? Colors.amber : Colors.grey
                                        ),
                                        title: Text(
                                          option.tentaisan ?? '', 
                                          style: TextStyle(
                                            fontWeight: isMyKhoa ? FontWeight.bold : FontWeight.normal,
                                            color: isMyKhoa ? primaryColor : Colors.black87
                                          )
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text('Mã: ${option.maTaiSan ?? 'N/A'}'),
                                            Text('Khoa: ${option.makhoaNavigation?.tenkhoa ?? option.makhoa ?? 'N/A'}'),
                                            Text('Vị trí: ${option.viTriSuDung ?? 'Chưa cập nhật'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          ],
                                        ),
                                        isThreeLine: true,
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          
                          displayStringForOption: (option) => option.tentaisan ?? '',
                          
                          onSelected: (option) {
                            FocusScope.of(context).unfocus(); 
                            
                            setState(() {
                              _maTaiSanSelected = option.maTaiSan;
                              _viTriController.text = option.viTriSuDung ?? '';
                            });
                          },
                          
                          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                            return TextFormField(
                              controller: controller, 
                              focusNode: focusNode,
                              decoration: _inputDecoration(
                                'Tìm kiếm tài sản (Nhập tên/mã...) *', 
                                Icons.search_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.qr_code_scanner_rounded, color: primaryColor, size: 24),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    _scanQRCode(controller);          
                                  },
                                )
                              ),
                              onChanged: (value) {
                                if (_maTaiSanSelected != null) {
                                  setState(() {
                                    _maTaiSanSelected = null;
                                  });
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _viTriController,
                          label: 'Vị trí sử dụng / Phòng',
                          icon: Icons.location_on_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSectionCard(
                    title: 'Nội dung yêu cầu',
                    icon: Icons.build_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đơn vị tiếp nhận *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSelectableBlock(
                                title: 'Phòng Công nghệ thông tin',
                                icon: Icons.computer_rounded,
                                isSelected: _khoaNhanSelected == 'CNTT',
                                onTap: () => setState(() => _khoaNhanSelected = 'CNTT'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSelectableBlock(
                                title: 'Phòng Kỹ thuật - Hạ tầng',
                                icon: Icons.handyman_rounded,
                                isSelected: _khoaNhanSelected == 'CN',
                                onTap: () => setState(() => _khoaNhanSelected = 'CN'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<int>(
                          value: _mucUuTienSelected,
                          decoration: _inputDecoration('Mức độ ưu tiên', Icons.flag_rounded),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 - Bình thường')),
                            DropdownMenuItem(value: 2, child: Text('2 - Ưu tiên', style: TextStyle(color: Colors.orange))),
                            DropdownMenuItem(value: 3, child: Text('3 - Gấp', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) => setState(() => _mucUuTienSelected = val!),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _noiDungController,
                          label: 'Mô tả chi tiết tình trạng hỏng hóc *',
                          icon: Icons.description_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _ghiChuController,
                          label: 'Ghi chú thêm (nếu có)',
                          icon: Icons.notes_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===============================================
                  // VÙNG HIỂN THỊ ẢNH ĐÍNH KÈM CŨ VÀ MỚI
                  // ===============================================
                  _buildSectionCard(
                    title: isEditing ? 'Ảnh đính kèm thực tế' : 'Hình ảnh đính kèm',
                    icon: Icons.image_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // 1. NÚT THÊM ẢNH
                            InkWell(
                              onTap: _showImageSourceActionSheet, 
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, color: primaryColor),
                                    const SizedBox(height: 4),
                                    Text('Thêm ảnh', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ),

                            // 2. HIỂN THỊ ẢNH CŨ (TỪ SERVER)
                            if (isEditing)
                              ..._existingFileIds.map((fileId) {
                                final imageUrl = '${AppConstants.baseUrl}/FileStorage/$fileId';
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        width: 80, height: 80, fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
                                      ),
                                    ),
                                    Positioned(
                                      top: -5, right: -5,
                                      child: InkWell(
                                        onTap: () => _removeExistingImage(fileId),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),

                            // 3. HIỂN THỊ ẢNH MỚI (TỪ ĐIỆN THOẠI)
                            ...List.generate(_selectedImages.length, (index) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_selectedImages[index], width: 80, height: 80, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: -5, right: -5,
                                    child: InkWell(
                                      onTap: () => _removeNewImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitForm,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(isEditing ? 'LƯU THAY ĐỔI' : 'GỬI YÊU CẦU', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),        
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 1)),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectableBlock({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? primaryColor : Colors.black87)
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 18),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, FocusNode? focusNode, required String label, required IconData icon, int maxLines = 1, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon, suffixIcon: suffixIcon),
    );
  }
}