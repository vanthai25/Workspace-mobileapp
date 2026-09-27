import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/su_kien_v2_models.dart';
import '../services/api_client.dart';
import '../services/su_kien_home_service.dart';
import '../services/su_kien_changes.dart';

/// Carousel sự kiện cho cả Home mobile và Web PC.
/// Ảnh được tải bằng Dio/JWT từ API hiện tại; không dùng Image.network.
/// Ảnh poster được hiển thị đầy đủ (contain), không cắt mất chữ có sẵn trên ảnh.
/// Hiệu ứng toàn trang thuộc HomeEventEffectLayer, không đặt trong carousel.
class SuKienHomeCarousel extends StatefulWidget {
  const SuKienHomeCarousel({
    super.key,
    this.desktop = false,
    this.onOpenScreen,
    this.onActiveEventChanged,
    this.refreshRevision = 0,
    this.motionPaused = false,
    this.onMotionPausedChanged,
    this.service,
  });

  final bool desktop;
  final int refreshRevision;
  final bool motionPaused;
  final ValueChanged<bool>? onMotionPausedChanged;
  final SuKienHomeService? service;
  final ValueChanged<String>? onOpenScreen;
  final ValueChanged<SuKienV2Model?>? onActiveEventChanged;

  @override
  State<SuKienHomeCarousel> createState() => _SuKienHomeCarouselState();
}

class _SuKienSlide {
  const _SuKienSlide(this.event, this.banner);

  final SuKienV2Model event;
  final SuKienBannerV2Model banner;
}

class _SuKienHomeCarouselState extends State<SuKienHomeCarousel>
    with WidgetsBindingObserver {
  static const Color _primary = Color(0xFF1274BC);
  static const Color _ink = Color(0xFF18344D);

  late final SuKienHomeService _service;
  late final PageController _pageController;

  final Map<int, Future<Uint8List>> _imageFutures = {};
  List<SuKienV2Model> _events = [];
  Timer? _autoTimer;
  Timer? _pollTimer;
  Timer? _clockTimer;
  Timer? _expiryTimer;
  bool _loading = false;
  int _currentPage = 0;
  String _slidesSignature = '';
  String? _activeSignature;
  final Set<int> _failedImages = {};
  final Map<int, int> _imageVersions = {};
  bool _running = false;
  bool _tickerEnabled = false;
  bool _foreground = true;
  bool _reduceMotion = false;
  bool _reloadPending = false;
  bool _touching = false;
  bool _hovering = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    SuKienChanges.revision.addListener(_requestRefresh);
    _service = widget.service ?? SuKienHomeService(ApiClient().dio);
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncVisibility();
    });
  }

  @override
  void didUpdateWidget(covariant SuKienHomeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshRevision != widget.refreshRevision) _requestRefresh();
    if (oldWidget.motionPaused != widget.motionPaused) {
      _restartAutoplay(_visibleSlides(DateTime.now()).length);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncVisibility();
  }

  void _requestRefresh() {
    if (!_running) return; // Returning to Home always fetches current data.
    _load();
  }

  void _syncVisibility() {
    final running = _tickerEnabled && _foreground;
    if (_running == running) {
      _restartAutoplay(_visibleSlides(DateTime.now()).length);
      return;
    }
    _running = running;
    _autoTimer?.cancel();
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _expiryTimer?.cancel();
    if (!running) return;
    _publishActiveEvent();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) => _load());
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || !_running) return;
      _publishActiveEvent();
      setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    SuKienChanges.revision.removeListener(_requestRefresh);
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _expiryTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool _isCurrent(SuKienV2Model event, DateTime now) {
    return event.isActive &&
        !now.isBefore(event.tuNgay) &&
        !now.isAfter(event.denNgay);
  }

  List<_SuKienSlide> _visibleSlides(DateTime now) {
    final slides = <_SuKienSlide>[];
    for (final event in _events) {
      if (!_isCurrent(event, now)) continue;
      final banners = event.banners.where((b) => b.isActive).toList()
        ..sort((a, b) {
          final order = a.thuTu.compareTo(b.thuTu);
          return order != 0 ? order : a.idBanner.compareTo(b.idBanner);
        });
      for (final banner in banners) {
        slides.add(_SuKienSlide(event, banner));
      }
    }
    return slides;
  }

  /// Chỉ chọn một sự kiện ưu tiên nhất làm hiệu ứng phủ toàn Home.
  void _publishActiveEvent() {
    final now = DateTime.now();
    SuKienV2Model? active;
    for (final event in _events) {
      if (_isCurrent(event, now)) {
        active = event;
        break;
      }
    }
    final signature = active == null
        ? ''
        : '${active.idSuKien}|${active.effectType}|${active.effectConfig}|${active.denNgay.toIso8601String()}';
    if (signature == _activeSignature) return;
    _activeSignature = signature;
    widget.onActiveEventChanged?.call(active);
  }

  Future<void> _load() async {
    if (!_running) return;
    if (_loading) {
      _reloadPending = true;
      return;
    }
    _loading = true;
    try {
      final fetched = await _service.getCurrent();
      if (!mounted) return;
      fetched.sort((a, b) {
        final priority = b.mucUuTien.compareTo(a.mucUuTien);
        return priority != 0 ? priority : a.tuNgay.compareTo(b.tuNgay);
      });

      for (final id in _failedImages) {
        _imageFutures.remove(id);
      }
      _failedImages.clear();
      for (final banner in fetched.expand((event) => event.banners)) {
        if (_imageVersions[banner.idBanner] != banner.idFile) {
          _imageFutures.remove(banner.idBanner);
        }
        _imageVersions[banner.idBanner] = banner.idFile;
      }
      final ids = fetched
          .expand((event) => event.banners)
          .map((banner) => banner.idBanner)
          .toSet();
      _imageFutures.removeWhere((id, _) => !ids.contains(id));
      _imageVersions.removeWhere((id, _) => !ids.contains(id));
      final newSignature = fetched
          .expand((event) {
            final banners = event.banners.where((b) => b.isActive).toList()
              ..sort((a, b) {
                final order = a.thuTu.compareTo(b.thuTu);
                return order != 0 ? order : a.idBanner.compareTo(b.idBanner);
              });
            return banners.map(
              (banner) => '${event.idSuKien}:${banner.idBanner}',
            );
          })
          .join(',');
      final hasChanged = newSignature != _slidesSignature;
      _slidesSignature = newSignature;

      setState(() {
        _events = fetched;
        _loadFailed = false;
        if (hasChanged) _currentPage = 0;
      });
      if (hasChanged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
      _publishActiveEvent();
      _restartAutoplay(_visibleSlides(DateTime.now()).length);
      _scheduleExpiry();
    } catch (error) {
      // Không làm lỗi cả Home khi mạng gián đoạn. Hạn sự kiện vẫn được kiểm tra local.
      debugPrint('Home: không tải được banner sự kiện: $error');
      if (mounted) {
        setState(() => _loadFailed = true);
        _publishActiveEvent();
      }
    } finally {
      _loading = false;
      if (mounted && _running) {
        _scheduleExpiry();
        if (_reloadPending) {
          _reloadPending = false;
          _load();
        }
      }
    }
  }

  void _restartAutoplay(int count) {
    _autoTimer?.cancel();
    if (!_running ||
        widget.motionPaused ||
        _reduceMotion ||
        _touching ||
        _hovering ||
        count < 2) {
      return;
    }
    _autoTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_pageController.hasClients) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
      final slides = _visibleSlides(DateTime.now());
      if (slides.length < 2) return;
      final next = (_currentPage + 1) % slides.length;
      _goToPage(next);
    });
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    if (!_running) return;
    final now = DateTime.now();
    final ends =
        _events
            .where((event) => event.denNgay.isAfter(now))
            .map((event) => event.denNgay)
            .toList()
          ..sort();
    if (ends.isEmpty) return;
    _expiryTimer = Timer(
      ends.first.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        _publishActiveEvent();
        setState(() {});
        _load();
      },
    );
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) return;
    if (_reduceMotion) {
      _pageController.jumpToPage(index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 470),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<Uint8List> _imageFor(int idBanner) {
    return _imageFutures.putIfAbsent(idBanner, () async {
      try {
        return await _service.getBannerImage(idBanner);
      } catch (_) {
        _failedImages.add(idBanner);
        rethrow;
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAction(_SuKienSlide slide) async {
    final type = (slide.banner.actionType ?? 'none').trim().toLowerCase();
    final value = (slide.banner.actionValue ?? '').trim();
    if (type.isEmpty || type == 'none' || value.isEmpty) return;

    if (type == 'screen') {
      if (widget.onOpenScreen == null) {
        _showMessage('Màn hình này chưa được hỗ trợ trong app.');
      } else {
        widget.onOpenScreen!(value);
      }
      return;
    }

    if (const {'url', 'pdf', 'article'}.contains(type)) {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        _showMessage('Liên kết banner chưa hợp lệ.');
        return;
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showMessage('Không thể mở liên kết này.');
      }
      return;
    }
    _showMessage('Hành động banner này chưa được hỗ trợ.');
  }

  /// Không có action: chạm ảnh để xem trọn poster và phóng to khi cần.
  Future<void> _openImagePreview(_SuKienSlide slide) async {
    try {
      final bytes = await _imageFor(slide.banner.idBanner);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final size = MediaQuery.sizeOf(dialogContext);
          return Dialog(
            backgroundColor: const Color(0xFF071A2B),
            insetPadding: const EdgeInsets.all(12),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: (size.width * 0.96).clamp(280.0, 1450.0),
              height: size.height * 0.88,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.memory(bytes, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filledTonal(
                      tooltip: 'Đóng ảnh',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      _showMessage('Không thể mở ảnh banner: $error');
    }
  }

  String? _countdownText(SuKienV2Model event, DateTime now) {
    if (!event.showCountdown || event.ngaySuKien == null) return null;
    final date = event.ngaySuKien!;
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final days = eventDay.difference(today).inDays;
    if (days < 0) return null;
    return days == 0 ? 'Hôm nay là ngày sự kiện' : 'Còn $days ngày';
  }

  @override
  Widget build(BuildContext context) {
    final slides = _visibleSlides(DateTime.now());
    if (slides.isEmpty) {
      if (_loadFailed) {
        return Center(
          child: TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại sự kiện'),
          ),
        );
      }
      if (_events.any((event) => _isCurrent(event, DateTime.now()))) {
        return Align(alignment: Alignment.centerRight, child: _motionControl());
      }
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final horizontalPadding = widget.desktop ? 0.0 : 20.0;

        final cardWidth = widget.desktop
            ? availableWidth.clamp(0.0, 1280.0)
            : (availableWidth - horizontalPadding * 2).clamp(
                0.0,
                double.infinity,
              );

        final imageHeight = widget.desktop
            ? (cardWidth / 3.2).clamp(260.0, 400.0)
            : (cardWidth / 2.5).clamp(120.0, 180.0);
        final footerHeight = widget.desktop ? 65.0 : 78.0;
        final maxIndex = slides.length - 1;
        final index = _currentPage.clamp(0, maxIndex);
        final disableAnimations =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            widget.desktop ? 12 : 4,
            horizontalPadding,
            widget.desktop ? 12 : 6,
          ),
          child: Center(
            child: SizedBox(
              width: cardWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        widget.desktop ? 22 : 19,
                      ),
                      border: Border.all(color: const Color(0xFFE3EAF2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0B426B,
                          ).withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        SizedBox(
                          height: imageHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MouseRegion(
                                onEnter: (_) {
                                  _hovering = true;
                                  _autoTimer?.cancel();
                                },
                                onExit: (_) {
                                  _hovering = false;
                                  _restartAutoplay(slides.length);
                                },
                                child: Listener(
                                  onPointerDown: (_) {
                                    _touching = true;
                                    _autoTimer?.cancel();
                                  },
                                  onPointerUp: (_) {
                                    _touching = false;
                                    _restartAutoplay(slides.length);
                                  },
                                  onPointerCancel: (_) {
                                    _touching = false;
                                    _restartAutoplay(slides.length);
                                  },
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: slides.length,
                                    onPageChanged: (page) {
                                      if (mounted) {
                                        setState(() => _currentPage = page);
                                      }
                                    },
                                    itemBuilder: (context, page) =>
                                        _poster(slides[page]),
                                  ),
                                ),
                              ),
                              if (slides.length > 1 && widget.desktop) ...[
                                Positioned(
                                  left: 12,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: _arrow(
                                      Icons.chevron_left_rounded,
                                      index - 1 < 0 ? maxIndex : index - 1,
                                      'Banner trước',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 12,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: _arrow(
                                      Icons.chevron_right_rounded,
                                      index + 1 > maxIndex ? 0 : index + 1,
                                      'Banner tiếp',
                                    ),
                                  ),
                                ),
                              ],
                              // Bộ đếm chỉ hiện trên Web PC.
                              if (widget.desktop && slides.length > 1)
                                Positioned(
                                  right: 18,
                                  top: 16,
                                  child: _imageCounter(
                                    index + 1,
                                    slides.length,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _footer(slides[index], footerHeight),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _motionControl(),
                  ),
                  if (slides.length > 1) ...[
                    const SizedBox(height: 11),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: List.generate(slides.length, (page) {
                        final selected = page == index;
                        return Semantics(
                          button: true,
                          label: 'Đến banner ${page + 1}',
                          child: InkWell(
                            onTap: () => _goToPage(page),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: AnimatedContainer(
                                duration: disableAnimations
                                    ? Duration.zero
                                    : const Duration(milliseconds: 220),
                                width: selected ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _primary
                                      : const Color(0xFFBBCBD9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _motionControl() {
    if (widget.onMotionPausedChanged == null || _reduceMotion) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      onPressed: () => widget.onMotionPausedChanged!(!widget.motionPaused),
      icon: Icon(
        widget.motionPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
        size: 18,
      ),
      label: Text(
        widget.motionPaused ? 'Bật chuyển động' : 'Tạm dừng chuyển động',
      ),
    );
  }

  Widget _arrow(IconData icon, int page, String tooltip) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        onPressed: () => _goToPage(page),
        icon: Icon(icon, color: _ink),
      ),
    );
  }

  Widget _imageCounter(int page, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2943).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$page / $count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _poster(_SuKienSlide slide) {
    final type = (slide.banner.actionType ?? 'none').trim().toLowerCase();
    final value = (slide.banner.actionValue ?? '').trim();
    final hasAction = type.isNotEmpty && type != 'none' && value.isNotEmpty;

    return FutureBuilder<Uint8List>(
      future: _imageFor(slide.banner.idBanner),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ColoredBox(
            color: const Color(0xFFEDF4F9),
            child: Center(
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _imageFutures.remove(slide.banner.idBanner);
                  _failedImages.remove(slide.banner.idBanner);
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tải lại ảnh'),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const ColoredBox(
            color: Color(0xFFF0F5F9),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final bytes = snapshot.data!;
        return Material(
          color: const Color(0xFFEAF0F5),
          child: InkWell(
            // Mobile/Web mobile: giữ action nếu có, không mở chế độ phóng to.
            // Web PC: không có action thì vẫn cho xem poster kích thước lớn.
            onTap: hasAction
                ? () => _openAction(slide)
                : (widget.desktop ? () => _openImagePreview(slide) : null),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background phủ đầy card; ảnh này có thể crop nhưng chỉ để tạo nền.
                if (widget.desktop)
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Transform.scale(
                      scale: 1.07,
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        cacheWidth: 640,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        filterQuality: FilterQuality.low,
                      ),
                    ),
                  ),
                if (widget.desktop) const ColoredBox(color: Color(0x330B2943)),
                if (!widget.desktop)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF1F8FD), Color(0xFFDCEAF5)],
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(widget.desktop ? 6 : 0),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    cacheWidth: widget.desktop ? 1920 : 1080,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
                  ),
                ),
                // Chỉ Web PC hiện biểu tượng mở/phóng to ảnh.
                if (widget.desktop)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B2943).withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        hasAction
                            ? Icons.open_in_new_rounded
                            : Icons.zoom_out_map_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _footer(_SuKienSlide slide, double height) {
    final event = slide.event;
    final banner = slide.banner;
    final countdown = _countdownText(event, DateTime.now());
    final type = (banner.actionType ?? 'none').trim().toLowerCase();
    final hasAction =
        type.isNotEmpty &&
        type != 'none' &&
        (banner.actionValue?.trim().isNotEmpty ?? false);
    final description = banner.moTa?.trim() ?? '';

    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsets.symmetric(
        horizontal: widget.desktop ? 18 : 12,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9EEF3))),
      ),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F5FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.celebration_outlined,
              color: _primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.tieuDe?.trim().isNotEmpty == true
                      ? banner.tieuDe!.trim()
                      : event.tenSuKien,
                  maxLines: widget.desktop ? 1 : 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: widget.desktop ? 14 : 12,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                if (countdown != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    countdown,
                    style: const TextStyle(
                      color: Color(0xFF995D12),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (description.isNotEmpty && widget.desktop) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6D8092),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasAction) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.desktop ? 200 : 110),
              child: TextButton.icon(
                onPressed: () => _openAction(slide),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: Text(
                  banner.buttonText?.trim().isNotEmpty == true
                      ? banner.buttonText!.trim()
                      : 'Xem thêm',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
