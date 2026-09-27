import 'package:flutter/material.dart';

import '../../../models/su_kien_effect_models.dart';
import '../../../models/su_kien_v2_models.dart';
import '../../../widgets/home_event_effect_layer.dart';

class SuKienEffectPreview extends StatefulWidget {
  const SuKienEffectPreview({
    super.key,
    required this.config,
    required this.mobile,
  });
  final SuKienEffectConfig config;
  final bool mobile;

  @override
  State<SuKienEffectPreview> createState() => _SuKienEffectPreviewState();
}

class _SuKienEffectPreviewState extends State<SuKienEffectPreview> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final event = SuKienV2Model(
      idSuKien: -1,
      tenSuKien: 'Xem trước sự kiện',
      tuNgay: now,
      denNgay: now.add(const Duration(days: 1)),
      isActive: true,
      showCountdown: false,
      effectConfig: widget.config.toJsonString(),
    );
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: widget.mobile ? 390 : 960,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.mobile ? 'Xem trước điện thoại' : 'Xem trước PC',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chạy lại',
                    onPressed: () => setState(() => _revision++),
                    icon: const Icon(Icons.replay),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: widget.mobile ? 360 : 960,
                  height: widget.mobile ? 540 : 460,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: const Color(0xFFF4F7FB),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 165,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1274BC),
                                      Color(0xFF56AFC7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.celebration_outlined,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Chào mừng sự kiện',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Nội dung trang chủ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Hiệu ứng nhẹ ở hai bên, giữ vùng nội dung thoáng và dễ đọc.',
                              ),
                              const SizedBox(height: 20),
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('Thông báo và các tiện ích'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      HomeEventEffectLayer(
                        key: ValueKey(_revision),
                        event: event,
                        preview: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
