import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/cme_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cme_provider.dart';

const Color _cmePrimaryColor = Color(0xFF1274BC);

/// Opens the CME request detail dialog.
///
/// The result is `true` when the request was approved or rejected so the
/// calling list can refresh itself. Closing the dialog without a mutation
/// returns `false`.
Future<bool> showCmeDetailDialog(
  BuildContext context, {
  required int requestId,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CmeDetailDialog(requestId: requestId),
  );

  return result ?? false;
}

class _CmeDetailDialog extends StatefulWidget {
  const _CmeDetailDialog({required this.requestId});

  final int requestId;

  @override
  State<_CmeDetailDialog> createState() => _CmeDetailDialogState();
}

class _CmeDetailDialogState extends State<_CmeDetailDialog> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  CmeRequestModel? _request;
  CmeAttachment? _attachment;
  String? _loadError;
  String? _attachmentError;
  String? _pdfLoadError;
  int _pdfPreviewRevision = 0;
  bool _isLoading = true;
  bool _isLoadingAttachment = false;
  bool _isMutating = false;
  late final PdfViewerController _pdfViewerController;
  late final TransformationController _imageViewerController;
  double _pdfZoomLevel = 1;
  double _imageZoomLevel = 1;
  int _previewQuarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _imageViewerController = TransformationController();
    unawaited(_loadRequest());
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _imageViewerController.dispose();
    super.dispose();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _request = null;
      _attachment = null;
      _attachmentError = null;
      _pdfLoadError = null;
      _previewQuarterTurns = 0;
      _pdfPreviewRevision++;
    });

    try {
      final CmeRequestModel request = await context.read<CmeProvider>().getById(
        widget.requestId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _request = request;
        _isLoading = false;
      });

      unawaited(_loadAttachment());
    } on CmeApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = 'Không thể tải chi tiết yêu cầu CME. Vui lòng thử lại.';
      });
    }
  }

  Future<CmeAttachment?> _loadAttachment() async {
    final CmeRequestModel? request = _request;
    if (request == null || _isLoadingAttachment) {
      return _attachment;
    }

    if (_attachment != null) {
      return _attachment;
    }

    setState(() {
      _isLoadingAttachment = true;
      _attachmentError = null;
    });

    try {
      final CmeAttachment attachment = await context
          .read<CmeProvider>()
          .downloadAttachment(request.id);

      if (!mounted) {
        return null;
      }

      setState(() {
        _attachment = attachment;
        _isLoadingAttachment = false;
        _pdfLoadError = null;
        _pdfPreviewRevision++;
      });
      _resetPreviewZoom(notify: false);

      return attachment;
    } on CmeApiException catch (error) {
      if (!mounted) {
        return null;
      }

      setState(() {
        _isLoadingAttachment = false;
        _attachmentError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return null;
      }

      setState(() {
        _isLoadingAttachment = false;
        _attachmentError = 'Không thể tải file đính kèm.';
      });
    }

    return null;
  }

  Future<void> _saveAttachment() async {
    if (_isLoadingAttachment) {
      return;
    }

    final CmeAttachment? attachment = _attachment ?? await _loadAttachment();
    if (attachment == null || !mounted) {
      return;
    }

    try {
      final String requestFileName = _request?.fileName?.trim() ?? '';
      await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu file chứng chỉ CME',
        fileName: requestFileName.isEmpty
            ? attachment.fileName
            : requestFileName,
        bytes: attachment.bytes,
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          'Không thể lưu file đính kèm. Vui lòng thử lại.',
          isError: true,
        );
      }
    }
  }

  void _handlePdfLoadFailed(PdfDocumentLoadFailedDetails details) {
    final String description = details.description.trim();
    final String message = description.isEmpty
        ? 'File PDF không hợp lệ hoặc trình duyệt không thể đọc nội dung.'
        : description;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pdfLoadError != null) {
        return;
      }

      setState(() {
        _pdfLoadError = message;
      });
    });
  }

  Future<void> _retryPdfPreview() async {
    if (_isLoadingAttachment) {
      return;
    }

    setState(() {
      _attachment = null;
      _attachmentError = null;
      _pdfLoadError = null;
      _pdfPreviewRevision++;
    });

    await _loadAttachment();
  }

  void _setPdfZoom(double value) {
    final double next = value.clamp(1.0, 3.0).toDouble();
    if (!mounted) {
      return;
    }
    setState(() => _pdfZoomLevel = next);
    _pdfViewerController.zoomLevel = next;
  }

  void _syncPdfZoom(PdfZoomDetails details) {
    final double next = details.newZoomLevel.clamp(1.0, 3.0).toDouble();
    if (!mounted || (_pdfZoomLevel - next).abs() < 0.001) {
      return;
    }
    setState(() => _pdfZoomLevel = next);
  }

  void _setImageZoom(double value) {
    final double next = value.clamp(0.5, 5.0).toDouble();
    _imageViewerController.value = Matrix4.diagonal3Values(next, next, 1);
    if (!mounted) {
      return;
    }
    setState(() => _imageZoomLevel = next);
  }

  void _resetPreviewZoom({bool notify = true}) {
    _pdfViewerController.zoomLevel = 1;
    _imageViewerController.value = Matrix4.identity();
    _pdfZoomLevel = 1;
    _imageZoomLevel = 1;
    if (notify && mounted) {
      setState(() {});
    }
  }

  void _rotatePreview() {
    if (!mounted) {
      return;
    }
    setState(() => _previewQuarterTurns = (_previewQuarterTurns + 1) % 4);
  }

  Future<void> _openFullscreenPreview(
    CmeAttachment attachment, {
    required bool isPdf,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FullscreenAttachmentViewer(
        attachment: attachment,
        fileName: _request?.fileName,
        isPdf: isPdf,
        initialQuarterTurns: _previewQuarterTurns,
        onDownload: _saveAttachment,
      ),
    );
  }

  Future<void> _deleteRequest() async {
    final CmeRequestModel? request = _request;
    if (request == null || !_canDelete(request) || _isMutating) {
      return;
    }

    final bool confirmed = await _showDeleteConfirmation();
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isMutating = true);

    try {
      await context.read<CmeProvider>().deleteRequest(request.id);
      if (!mounted) {
        return;
      }

      setState(() => _isMutating = false);
      _showSnackBar('Đã xóa yêu cầu CME.');
      Navigator.of(context).pop(true);
    } on CmeApiException catch (error) {
      if (mounted) {
        _showSnackBar(error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          'Không thể xóa yêu cầu CME. Vui lòng thử lại.',
          isError: true,
        );
      }
    } finally {
      if (mounted && _isMutating) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _approve() async {
    final CmeRequestModel? request = _request;
    if (request == null || !_canApprove(request) || _isMutating) {
      return;
    }

    final bool confirmed = await _showApproveConfirmation();
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      await context.read<CmeProvider>().approve(request.id);

      if (!mounted) {
        return;
      }

      setState(() => _isMutating = false);
      _showSnackBar('Đã duyệt yêu cầu CME thành công.');
      Navigator.of(context).pop(true);
    } on CmeApiException catch (error) {
      if (mounted) {
        _showSnackBar(error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          'Không thể duyệt yêu cầu CME. Vui lòng thử lại.',
          isError: true,
        );
      }
    } finally {
      if (mounted && _isMutating) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    final CmeRequestModel? request = _request;
    if (request == null || !_canReject(request) || _isMutating) {
      return;
    }

    final String? reason = await _showRejectReasonDialog(
      wasApproved: request.isApproved,
    );
    if (reason == null || !mounted) {
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      await context.read<CmeProvider>().reject(request.id, reason);

      if (!mounted) {
        return;
      }

      setState(() => _isMutating = false);
      _showSnackBar('Đã từ chối yêu cầu CME.');
      Navigator.of(context).pop(true);
    } on CmeApiException catch (error) {
      if (mounted) {
        _showSnackBar(error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          'Không thể từ chối yêu cầu CME. Vui lòng thử lại.',
          isError: true,
        );
      }
    } finally {
      if (mounted && _isMutating) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _cancelApproval() async {
    final CmeRequestModel? request = _request;
    if (request == null || !_canManageApproved(request) || _isMutating) {
      return;
    }

    final bool confirmed = await _showCancelApprovalConfirmation();
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      await context.read<CmeProvider>().cancelApproval(request.id);

      if (!mounted) {
        return;
      }

      setState(() => _isMutating = false);
      _showSnackBar('Đã hủy duyệt yêu cầu CME.');
      Navigator.of(context).pop(true);
    } on CmeApiException catch (error) {
      if (mounted) {
        _showSnackBar(error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          'Không thể hủy duyệt yêu cầu CME. Vui lòng thử lại.',
          isError: true,
        );
      }
    } finally {
      if (mounted && _isMutating) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<bool> _showApproveConfirmation() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.green),
              SizedBox(width: 10),
              Expanded(child: Text('Xác nhận duyệt CME')),
            ],
          ),
          content: const Text(
            'Thông tin chứng chỉ sẽ được chuyển vào hồ sơ chứng chỉ của '
            'nhân viên. Bạn có chắc chắn muốn duyệt yêu cầu này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.check_rounded, size: 19),
              label: const Text('Duyệt yêu cầu'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _showCancelApprovalConfirmation() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.undo_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text('Hủy duyệt yêu cầu CME')),
            ],
          ),
          content: const Text(
            'Yêu cầu sẽ được chuyển lại trạng thái chờ duyệt và chứng chỉ '
            'đã tạo từ yêu cầu này sẽ được gỡ bỏ. Bạn có chắc chắn muốn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Không'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.undo_rounded, size: 19),
              label: const Text('Hủy duyệt'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _showDeleteConfirmation() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
              const SizedBox(width: 10),
              const Expanded(child: Text('Xóa yêu cầu CME')),
            ],
          ),
          content: const Text(
            'Yêu cầu và file minh chứng đính kèm sẽ bị xóa. '
            'Bạn có chắc chắn muốn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Không'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: const Text('Xóa yêu cầu'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<String?> _showRejectReasonDialog({required bool wasApproved}) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CmeRejectReasonDialog(wasApproved: wasApproved),
    );
  }

  bool _canApprove(CmeRequestModel request) {
    final AuthProvider auth = context.read<AuthProvider>();
    return auth.currentRoleIds.contains(36) &&
        request.isPending &&
        !_isOwnRequest(request, auth.currentManv);
  }

  bool _canManageApproved(CmeRequestModel request) {
    final AuthProvider auth = context.read<AuthProvider>();
    final String currentManv = auth.currentManv?.trim().toLowerCase() ?? '';
    final String approverManv =
        request.maSoNguoiDuyet?.trim().toLowerCase() ?? '';

    return auth.currentRoleIds.contains(36) &&
        request.isApproved &&
        currentManv.isNotEmpty &&
        approverManv.isNotEmpty &&
        currentManv == approverManv;
  }

  bool _canReject(CmeRequestModel request) {
    return _canApprove(request) || _canManageApproved(request);
  }

  bool _canDelete(CmeRequestModel request) {
    final AuthProvider auth = context.read<AuthProvider>();
    return (request.isPending || request.isRejected) &&
        _isOwnRequest(request, auth.currentManv);
  }

  bool _isOwnRequest(CmeRequestModel request, String? currentManv) {
    final String normalizedCurrentManv =
        currentManv?.trim().toLowerCase() ?? '';
    return normalizedCurrentManv.isNotEmpty &&
        request.maSoNguoiGui.trim().toLowerCase() == normalizedCurrentManv;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double dialogHeight = screenSize.height * 0.9;

    return PopScope(
      canPop: !_isMutating,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenSize.width < 600 ? 12 : 28,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 860),
          child: SizedBox(
            width: double.maxFinite,
            height: dialogHeight,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
                if (_request != null) _buildFooter(_request!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final CmeRequestModel? request = _request;
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 22,
        compact ? 13 : 17,
        compact ? 6 : 12,
        compact ? 13 : 17,
      ),
      decoration: const BoxDecoration(color: _cmePrimaryColor),
      child: Row(
        children: [
          if (!compact) ...[
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
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết yêu cầu CME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request == null
                      ? 'Đang tải thông tin...'
                      : 'Mã yêu cầu #${request.id}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (request != null && !compact) ...[
            _StatusBadge(status: request.trangThai),
            const SizedBox(width: 4),
          ],
          IconButton(
            tooltip: 'Đóng',
            onPressed: _isMutating ? null : () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _cmePrimaryColor),
            SizedBox(height: 14),
            Text('Đang tải chi tiết yêu cầu...'),
          ],
        ),
      );
    }

    if (_loadError != null || _request == null) {
      return _ErrorPanel(
        message: _loadError ?? 'Không tìm thấy yêu cầu CME.',
        onRetry: _loadRequest,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 780) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildDetails(_request!),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildAttachmentPanel()),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDetails(_request!),
              const SizedBox(height: 16),
              SizedBox(height: 430, child: _buildAttachmentPanel()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetails(CmeRequestModel request) {
    final AuthProvider auth = context.read<AuthProvider>();
    final bool isSelfReview =
        auth.currentRoleIds.contains(36) &&
        request.isPending &&
        _isOwnRequest(request, auth.currentManv);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailSection(
          icon: Icons.person_outline_rounded,
          title: 'Người gửi',
          child: _InfoGrid(
            children: [
              _InfoItem(
                label: 'Họ tên',
                value: _personDisplay(
                  request.tenNguoiGui,
                  request.maSoNguoiGui,
                ),
              ),
              _InfoItem(
                label: 'Khoa / Phòng',
                value: _departmentDisplay(request.tenKhoa, request.maKhoa),
              ),
              _InfoItem(
                label: 'Ngày gửi',
                value: _formatDateTime(request.ngayGui),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          icon: Icons.school_outlined,
          title: 'Thông tin chứng chỉ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                request.tenChungChi.trim(),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17324D),
                ),
              ),
              const SizedBox(height: 14),
              _InfoGrid(
                children: [
                  _InfoItem(
                    label: 'Số chứng chỉ',
                    value: _textOrDash(request.soChungChi),
                  ),
                  _InfoItem(
                    label: 'Đơn vị đào tạo',
                    value: _textOrDash(request.donViDaoTao),
                  ),
                  _InfoItem(
                    label: 'Hình thức đào tạo',
                    value: _textOrDash(request.tenHinhThucDaoTao),
                  ),
                  _InfoItem(
                    label: 'Thời gian đào tạo',
                    value: _dateRange(request.ngayBatDau, request.ngayKetThuc),
                  ),
                  _InfoItem(
                    label: 'Giờ tín chỉ',
                    value: _numberOrDash(request.soTiet),
                  ),
                  _InfoItem(
                    label: 'Ngày cấp',
                    value: _formatDate(request.ngayCap),
                  ),
                  _InfoItem(
                    label: 'Ngày hết hạn',
                    value: _formatDate(request.ngayHetHan),
                  ),
                  _InfoItem(
                    label: 'Chu kỳ',
                    value: request.chuKy?.toString() ?? '—',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DetailSection(
          icon: Icons.fact_check_outlined,
          title: 'Kết quả xử lý',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoGrid(
                children: [
                  _InfoItem(
                    label: 'Trạng thái',
                    value: _statusLabel(request.trangThai),
                  ),
                  _InfoItem(
                    label: 'Người duyệt',
                    value: _personDisplay(
                      request.tenNguoiDuyet,
                      request.maSoNguoiDuyet,
                    ),
                  ),
                  _InfoItem(
                    label: 'Ngày xử lý',
                    value: _formatDateTime(request.ngayDuyet),
                  ),
                  if (request.idChungChi != null)
                    _InfoItem(
                      label: 'Mã chứng chỉ',
                      value: '#${request.idChungChi}',
                    ),
                ],
              ),
              if (request.lyDoTuChoi?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lý do từ chối',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              request.lyDoTuChoi!.trim(),
                              style: TextStyle(
                                color: Colors.red.shade900,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isSelfReview) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Colors.amber.shade900,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Bạn không thể duyệt hoặc từ chối yêu cầu do chính mình gửi.',
                    style: TextStyle(color: Colors.amber.shade900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentPanel() {
    final String requestFileName = _request?.fileName?.trim() ?? '';
    final String attachmentFileName = _attachment?.fileName.trim() ?? '';
    final String fileName = requestFileName.isNotEmpty
        ? requestFileName
        : attachmentFileName.isNotEmpty
        ? attachmentFileName
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  color: _cmePrimaryColor,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File minh chứng',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tải xuống',
                  onPressed: _isLoadingAttachment ? null : _saveAttachment,
                  icon: const Icon(Icons.download_rounded),
                  color: _cmePrimaryColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildAttachmentPreview()),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    if (_isLoadingAttachment) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _cmePrimaryColor),
            SizedBox(height: 12),
            Text('Đang tải file đính kèm...'),
          ],
        ),
      );
    }

    if (_attachmentError != null) {
      return _ErrorPanel(
        message: _attachmentError!,
        onRetry: _loadAttachment,
        compact: true,
      );
    }

    final CmeAttachment? attachment = _attachment;
    if (attachment == null) {
      return const Center(child: Text('Không có file đính kèm.'));
    }

    if (_isPdf(attachment)) {
      if (_pdfLoadError != null) {
        return _PdfLoadFailurePanel(
          message: _pdfLoadError!,
          onRetry: _retryPdfPreview,
          onDownload: _saveAttachment,
        );
      }

      return Column(
        children: [
          _AttachmentZoomToolbar(
            zoomLevel: _pdfZoomLevel,
            minZoom: 1,
            maxZoom: 3,
            onZoomOut: () => _setPdfZoom(_pdfZoomLevel - 0.25),
            onZoomIn: () => _setPdfZoom(_pdfZoomLevel + 0.25),
            onReset: () => _setPdfZoom(1),
            onRotate: _rotatePreview,
            onFullscreen: () => _openFullscreenPreview(attachment, isPdf: true),
          ),
          const Divider(height: 1),
          Expanded(
            child: RotatedBox(
              quarterTurns: _previewQuarterTurns,
              child: SfPdfViewer.memory(
                attachment.bytes,
                key: ValueKey<String>(
                  'cme-pdf-${_request?.id ?? widget.requestId}-$_pdfPreviewRevision',
                ),
                controller: _pdfViewerController,
                onDocumentLoadFailed: _handlePdfLoadFailed,
                onZoomLevelChanged: _syncPdfZoom,
              ),
            ),
          ),
        ],
      );
    }

    if (_isHeic(attachment)) {
      return _UnsupportedPreview(
        icon: Icons.image_not_supported_outlined,
        title: 'Không thể xem trước HEIC/HEIF',
        message:
            'Trình duyệt có thể không hỗ trợ định dạng ảnh này. Hãy tải file xuống để xem.',
        onDownload: _saveAttachment,
      );
    }

    if (_isCommonImage(attachment)) {
      return Column(
        children: [
          _AttachmentZoomToolbar(
            zoomLevel: _imageZoomLevel,
            minZoom: 0.5,
            maxZoom: 5,
            onZoomOut: () => _setImageZoom(_imageZoomLevel - 0.25),
            onZoomIn: () => _setImageZoom(_imageZoomLevel + 0.25),
            onReset: () => _setImageZoom(1),
            onRotate: _rotatePreview,
            onFullscreen: () =>
                _openFullscreenPreview(attachment, isPdf: false),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFEEF2F6),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: InteractiveViewer(
                transformationController: _imageViewerController,
                alignment: Alignment.center,
                minScale: 0.5,
                maxScale: 5,
                onInteractionEnd: (_) {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _imageZoomLevel = _imageViewerController.value
                        .getMaxScaleOnAxis()
                        .clamp(0.5, 5.0)
                        .toDouble();
                  });
                },
                child: RotatedBox(
                  quarterTurns: _previewQuarterTurns,
                  child: Image.memory(
                    attachment.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _UnsupportedPreview(
                        icon: Icons.broken_image_outlined,
                        title: 'Không thể hiển thị ảnh',
                        message:
                            'Hãy tải file xuống để xem trên thiết bị của bạn.',
                        onDownload: _saveAttachment,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _UnsupportedPreview(
      icon: Icons.insert_drive_file_outlined,
      title: 'Không hỗ trợ xem trước',
      message: 'Hãy tải file xuống để xem nội dung.',
      onDownload: _saveAttachment,
    );
  }

  Widget _buildFooter(CmeRequestModel request) {
    final bool canApprove = _canApprove(request);
    final bool canManageApproved = _canManageApproved(request);
    final bool canDelete = _canDelete(request);
    final bool isProcessing = _isMutating;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5EAF0))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          TextButton.icon(
            onPressed: isProcessing
                ? null
                : () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Đóng'),
          ),
          if (isProcessing) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.3),
            ),
            const SizedBox(width: 10),
            const Text('Đang xử lý...'),
          ] else if (canDelete) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
              onPressed: _deleteRequest,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: const Text('Xóa yêu cầu'),
            ),
          ] else if (canApprove) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
              onPressed: _reject,
              icon: const Icon(Icons.close_rounded, size: 19),
              label: const Text('Từ chối'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _approve,
              icon: const Icon(Icons.check_rounded, size: 19),
              label: const Text('Duyệt'),
            ),
          ] else if (canManageApproved) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                side: BorderSide(color: Colors.orange.shade400),
              ),
              onPressed: _cancelApproval,
              icon: const Icon(Icons.undo_rounded, size: 19),
              label: const Text('Hủy duyệt'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: _reject,
              icon: const Icon(Icons.close_rounded, size: 19),
              label: const Text('Từ chối'),
            ),
          ],
        ],
      ),
    );
  }

  bool _isPdf(CmeAttachment attachment) {
    if (_hasPdfMagic(attachment.bytes)) {
      return true;
    }

    return _looksLikePdfType(attachment.contentType) ||
        _extension(attachment.fileName) == 'pdf' ||
        _looksLikePdfType(_request?.fileType) ||
        _extension(_request?.fileName ?? '') == 'pdf';
  }

  static bool _hasPdfMagic(List<int> bytes) {
    const List<int> signature = <int>[0x25, 0x50, 0x44, 0x46]; // %PDF
    if (bytes.length < signature.length) {
      return false;
    }

    // PDF headers normally start at byte zero. Scanning the first 1024 bytes
    // also handles files that contain a small BOM/preamble before `%PDF`.
    final int searchLength = bytes.length < 1024 ? bytes.length : 1024;
    for (int index = 0; index <= searchLength - signature.length; index++) {
      bool matches = true;
      for (int offset = 0; offset < signature.length; offset++) {
        if (bytes[index + offset] != signature[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return true;
      }
    }

    return false;
  }

  static bool _looksLikePdfType(String? value) {
    final String normalized = value?.trim().toLowerCase() ?? '';
    return normalized == 'pdf' ||
        normalized == '.pdf' ||
        normalized == 'application/pdf';
  }

  static bool _isHeic(CmeAttachment attachment) {
    final String type = attachment.contentType.toLowerCase();
    final String extension = _extension(attachment.fileName);
    return type.contains('heic') ||
        type.contains('heif') ||
        extension == 'heic' ||
        extension == 'heif';
  }

  static bool _isCommonImage(CmeAttachment attachment) {
    final String type = attachment.contentType.toLowerCase();
    final String extension = _extension(attachment.fileName);
    return type == 'image/jpeg' ||
        type == 'image/jpg' ||
        type == 'image/png' ||
        type == 'image/webp' ||
        <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
  }

  static String _extension(String fileName) {
    final int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  static String _textOrDash(String? value) {
    final String text = value?.trim() ?? '';
    return text.isEmpty ? '—' : text;
  }

  static String _personDisplay(String? name, String? code) {
    final String normalizedName = name?.trim() ?? '';
    final String normalizedCode = code?.trim() ?? '';
    if (normalizedName.isEmpty) {
      return normalizedCode.isEmpty ? '—' : normalizedCode;
    }
    return normalizedCode.isEmpty
        ? normalizedName
        : '$normalizedName ($normalizedCode)';
  }

  static String _departmentDisplay(String? name, String? code) {
    final String normalizedName = name?.trim() ?? '';
    final String normalizedCode = code?.trim() ?? '';
    if (normalizedName.isEmpty) {
      return normalizedCode.isEmpty ? '—' : normalizedCode;
    }
    return normalizedCode.isEmpty
        ? normalizedName
        : '$normalizedName ($normalizedCode)';
  }

  static String _formatDate(DateTime? value) {
    return value == null ? '—' : _dateFormat.format(value);
  }

  static String _formatDateTime(DateTime? value) {
    return value == null ? '—' : _dateTimeFormat.format(value);
  }

  static String _dateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return '—';
    }
    if (start == null) {
      return 'Đến ${_dateFormat.format(end!)}';
    }
    if (end == null) {
      return 'Từ ${_dateFormat.format(start)}';
    }
    return '${_dateFormat.format(start)} – ${_dateFormat.format(end)}';
  }

  static String _numberOrDash(num? value) {
    if (value == null) {
      return '—';
    }
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }
}

class _AttachmentZoomToolbar extends StatelessWidget {
  const _AttachmentZoomToolbar({
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onReset,
    required this.onFullscreen,
    this.onRotate,
    this.isFullscreen = false,
  });

  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onReset;
  final VoidCallback onFullscreen;
  final VoidCallback? onRotate;
  final bool isFullscreen;

  @override
  Widget build(BuildContext context) {
    final int zoomPercent = (zoomLevel * 100).round();

    return Material(
      color: Colors.white,
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Thu nhỏ',
              onPressed: zoomLevel > minZoom + 0.001 ? onZoomOut : null,
              icon: const Icon(Icons.zoom_out_rounded, size: 20),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$zoomPercent%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Phóng to',
              onPressed: zoomLevel < maxZoom - 0.001 ? onZoomIn : null,
              icon: const Icon(Icons.zoom_in_rounded, size: 20),
            ),
            IconButton(
              tooltip: 'Đưa về kích thước ban đầu',
              onPressed: (zoomLevel - 1).abs() > 0.001 ? onReset : null,
              icon: const Icon(Icons.center_focus_strong_rounded, size: 19),
            ),
            if (onRotate != null)
              IconButton(
                tooltip: 'Xoay 90° sang phải',
                onPressed: onRotate,
                icon: const Icon(Icons.rotate_right_rounded, size: 21),
                color: _cmePrimaryColor,
              ),
            const Spacer(),
            IconButton(
              tooltip: isFullscreen
                  ? 'Thoát toàn màn hình'
                  : 'Xem toàn màn hình',
              onPressed: onFullscreen,
              icon: Icon(
                isFullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
              ),
              color: _cmePrimaryColor,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _FullscreenAttachmentViewer extends StatefulWidget {
  const _FullscreenAttachmentViewer({
    required this.attachment,
    required this.isPdf,
    required this.initialQuarterTurns,
    required this.onDownload,
    this.fileName,
  });

  final CmeAttachment attachment;
  final String? fileName;
  final bool isPdf;
  final int initialQuarterTurns;
  final Future<void> Function() onDownload;

  @override
  State<_FullscreenAttachmentViewer> createState() =>
      _FullscreenAttachmentViewerState();
}

class _FullscreenAttachmentViewerState
    extends State<_FullscreenAttachmentViewer> {
  late final PdfViewerController _pdfController;
  late final TransformationController _imageController;
  double _zoomLevel = 1;
  String? _pdfError;
  int _pdfRevision = 0;
  late int _quarterTurns;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _imageController = TransformationController();
    _quarterTurns = widget.initialQuarterTurns % 4;
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _setZoom(double value) {
    final double minZoom = widget.isPdf ? 1 : 0.5;
    final double maxZoom = widget.isPdf ? 3 : 5;
    final double next = value.clamp(minZoom, maxZoom).toDouble();

    if (!mounted) {
      return;
    }

    setState(() => _zoomLevel = next);
    if (widget.isPdf) {
      _pdfController.zoomLevel = next;
    } else {
      _imageController.value = Matrix4.diagonal3Values(next, next, 1);
    }
  }

  void _syncPdfZoom(PdfZoomDetails details) {
    final double next = details.newZoomLevel.clamp(1.0, 3.0).toDouble();
    if (!mounted || (_zoomLevel - next).abs() < 0.001) {
      return;
    }
    setState(() => _zoomLevel = next);
  }

  void _rotatePreview() {
    if (!mounted) {
      return;
    }
    setState(() => _quarterTurns = (_quarterTurns + 1) % 4);
  }

  void _handlePdfLoadFailed(PdfDocumentLoadFailedDetails details) {
    final String description = details.description.trim();
    final String message = description.isEmpty
        ? 'File PDF không hợp lệ hoặc trình duyệt không thể đọc nội dung.'
        : description;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pdfError != null) {
        return;
      }
      setState(() => _pdfError = message);
    });
  }

  Future<void> _retryPdf() async {
    if (!mounted) {
      return;
    }
    _pdfController.zoomLevel = 1;
    setState(() {
      _zoomLevel = 1;
      _pdfError = null;
      _pdfRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String requestedName = widget.fileName?.trim() ?? '';
    final String attachmentName = widget.attachment.fileName.trim();
    final String fileName = requestedName.isNotEmpty
        ? requestedName
        : attachmentName.isNotEmpty
        ? attachmentName
        : 'File minh chứng';
    final double minZoom = widget.isPdf ? 1 : 0.5;
    final double maxZoom = widget.isPdf ? 3 : 5;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Tải xuống',
              onPressed: widget.onDownload,
              icon: const Icon(Icons.download_rounded),
              color: _cmePrimaryColor,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _AttachmentZoomToolbar(
              zoomLevel: _zoomLevel,
              minZoom: minZoom,
              maxZoom: maxZoom,
              onZoomOut: () => _setZoom(_zoomLevel - 0.25),
              onZoomIn: () => _setZoom(_zoomLevel + 0.25),
              onReset: () => _setZoom(1),
              onRotate: _rotatePreview,
              onFullscreen: () => Navigator.of(context).pop(),
              isFullscreen: true,
            ),
            const Divider(height: 1),
            Expanded(child: _buildPreview()),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.isPdf) {
      if (_pdfError != null) {
        return _PdfLoadFailurePanel(
          message: _pdfError!,
          onRetry: _retryPdf,
          onDownload: widget.onDownload,
        );
      }

      return RotatedBox(
        quarterTurns: _quarterTurns,
        child: SfPdfViewer.memory(
          widget.attachment.bytes,
          key: ValueKey<int>(_pdfRevision),
          controller: _pdfController,
          onDocumentLoadFailed: _handlePdfLoadFailed,
          onZoomLevelChanged: _syncPdfZoom,
        ),
      );
    }

    return Container(
      color: const Color(0xFF20252B),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: InteractiveViewer(
        transformationController: _imageController,
        alignment: Alignment.center,
        minScale: 0.5,
        maxScale: 5,
        onInteractionEnd: (_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _zoomLevel = _imageController.value
                .getMaxScaleOnAxis()
                .clamp(0.5, 5.0)
                .toDouble();
          });
        },
        child: RotatedBox(
          quarterTurns: _quarterTurns,
          child: Image.memory(
            widget.attachment.bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _UnsupportedPreview(
                icon: Icons.broken_image_outlined,
                title: 'Không thể hiển thị ảnh',
                message: 'Hãy tải file xuống để xem trên thiết bị của bạn.',
                onDownload: widget.onDownload,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CmeRejectReasonDialog extends StatefulWidget {
  const _CmeRejectReasonDialog({required this.wasApproved});

  final bool wasApproved;

  @override
  State<_CmeRejectReasonDialog> createState() => _CmeRejectReasonDialogState();
}

class _CmeRejectReasonDialogState extends State<_CmeRejectReasonDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red),
          SizedBox(width: 10),
          Expanded(child: Text('Từ chối yêu cầu CME')),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.wasApproved) ...[
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Yêu cầu này đã được duyệt. Khi từ chối, chứng chỉ '
                  'đã tạo từ yêu cầu sẽ được gỡ bỏ.',
                  style: TextStyle(height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _reasonController,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                maxLength: 1000,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                decoration: const InputDecoration(
                  labelText: 'Lý do từ chối *',
                  hintText: 'Nhập lý do để người gửi có thể kiểm tra lại...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  final String reason = value?.trim() ?? '';
                  if (reason.isEmpty) {
                    return 'Vui lòng nhập lý do từ chối.';
                  }
                  if (reason.length > 1000) {
                    return 'Lý do không được vượt quá 1000 ký tự.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _submit,
          icon: const Icon(Icons.close_rounded, size: 19),
          label: const Text('Xác nhận từ chối'),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _cmePrimaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _cmePrimaryColor, size: 19),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF25384A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns = constraints.maxWidth >= 470;
        final double itemWidth = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 13,
          children: children
              .map((Widget child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        SelectableText(
          value,
          style: const TextStyle(
            color: Color(0xFF263849),
            fontSize: 13.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final _StatusAppearance appearance = _statusAppearance(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(appearance.icon, color: appearance.color, size: 15),
          const SizedBox(width: 5),
          Text(
            appearance.label,
            style: TextStyle(
              color: appearance.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final Future<dynamic> Function() onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: compact ? 40 : 52,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfLoadFailurePanel extends StatelessWidget {
  const _PdfLoadFailurePanel({
    required this.message,
    required this.onRetry,
    required this.onDownload,
  });

  final String message;
  final Future<void> Function() onRetry;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 52,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không thể xem trước PDF',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 9,
              runSpacing: 9,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tải lại'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Tải xuống'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedPreview extends StatelessWidget {
  const _UnsupportedPreview({
    required this.icon,
    required this.title,
    required this.message,
    required this.onDownload,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: Colors.blueGrey.shade300),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 15),
            FilledButton.tonalIcon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Tải xuống'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusAppearance {
  const _StatusAppearance(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

_StatusAppearance _statusAppearance(String status) {
  switch (status.trim().toUpperCase()) {
    case 'CHO_DUYET':
      return const _StatusAppearance(
        'Chờ duyệt',
        Color(0xFFC36A00),
        Icons.schedule_rounded,
      );
    case 'DA_DUYET':
      return const _StatusAppearance(
        'Đã duyệt',
        Color(0xFF17853D),
        Icons.check_circle_outline_rounded,
      );
    case 'TU_CHOI':
      return const _StatusAppearance(
        'Từ chối',
        Color(0xFFC62828),
        Icons.cancel_outlined,
      );
    default:
      return const _StatusAppearance(
        'Không xác định',
        Colors.blueGrey,
        Icons.help_outline_rounded,
      );
  }
}

String _statusLabel(String status) => _statusAppearance(status).label;
