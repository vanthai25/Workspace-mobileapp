import 'package:flutter/material.dart';

import '../../../models/su_kien_effect_models.dart';
import 'su_kien_effect_preview.dart';

class SuKienEffectEditor extends StatelessWidget {
  const SuKienEffectEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final SuKienEffectConfig config;

  final ValueChanged<SuKienEffectConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFDDE6ED)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF1274BC)),

              SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Hiệu ứng trang chủ',

                      style: TextStyle(
                        fontSize: 14,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Có thể bật nhiều hiệu ứng cùng lúc.',

                      style: TextStyle(color: Color(0xFF738595), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            'Mẫu nhanh',

            style: TextStyle(
              fontSize: 11,

              fontWeight: FontWeight.w700,

              color: Color(0xFF667A8C),
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,

            runSpacing: 8,

            children: [
              _presetButton(
                label: '🎂 Sinh nhật',

                onTap: () => onChanged(SuKienEffectConfig.birthday()),
              ),

              _presetButton(
                label: '🧧 Tết',

                onTap: () => onChanged(SuKienEffectConfig.tet()),
              ),

              _presetButton(
                label: '🎄 Noel',

                onTap: () => onChanged(SuKienEffectConfig.christmas()),
              ),

              _presetButton(
                label: '🌸 Hoa',

                onTap: () => onChanged(SuKienEffectConfig.flower()),
              ),

              _presetButton(
                label: '✨ Nhẹ',

                onTap: () => onChanged(SuKienEffectConfig.subtle()),
              ),

              _presetButton(
                label: 'Tắt hết',

                onTap: () => onChanged(SuKienEffectConfig.empty()),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mobile in [false, true])
                OutlinedButton.icon(
                  icon: Icon(
                    mobile
                        ? Icons.phone_android
                        : Icons.desktop_windows_outlined,
                  ),
                  label: Text(mobile ? 'Xem trước điện thoại' : 'Xem trước PC'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        SuKienEffectPreview(config: config, mobile: mobile),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _effectCard(
            type: 'fireworks',

            icon: Icons.celebration_rounded,

            title: 'Pháo hoa',

            subtitle: 'Pháo hoa theo đợt, có khoảng nghỉ giữa các lần.',
          ),

          _effectCard(
            type: 'confetti',

            icon: Icons.blur_on_rounded,

            title: 'Pháo giấy',

            subtitle: 'Giấy màu rơi tạo không khí lễ hội.',
          ),

          _effectCard(
            type: 'sparkle',

            icon: Icons.auto_awesome_rounded,

            title: 'Lấp lánh',

            subtitle: 'Các điểm sáng nhấp nháy nhẹ trên nền.',
          ),

          _effectCard(
            type: 'balloon',

            icon: Icons.circle_outlined,

            title: 'Bóng bay',

            subtitle: 'Bóng bay từ từ bay lên trên màn hình.',
          ),

          _effectCard(
            type: 'snow',

            icon: Icons.ac_unit_rounded,

            title: 'Tuyết',

            subtitle: 'Phù hợp Giáng sinh và các sự kiện mùa đông.',
          ),

          _effectCard(
            type: 'flower',

            icon: Icons.local_florist_outlined,

            title: 'Cánh hoa',

            subtitle: 'Cánh hoa rơi nhẹ, phù hợp Tết, 8/3, 20/10.',
          ),
        ],
      ),
    );
  }

  Widget _presetButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }

  Widget _effectCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final item = config.effectOf(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),

      padding: const EdgeInsets.fromLTRB(12, 8, 12, 11),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: item.enabled
              ? const Color(0xFFBBDDF3)
              : const Color(0xFFE2E8EE),
        ),
      ),

      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,

            dense: true,

            value: item.enabled,

            secondary: Icon(
              icon,

              color: item.enabled
                  ? const Color(0xFF1274BC)
                  : const Color(0xFF94A3AF),
            ),

            title: Text(
              title,

              style: const TextStyle(fontWeight: FontWeight.w700),
            ),

            subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),

            onChanged: (value) {
              onChanged(config.replace(item.copyWith(enabled: value)));
            },
          ),

          if (item.enabled)
            Padding(
              padding: const EdgeInsets.only(left: 48),

              child: Wrap(
                spacing: 22,

                runSpacing: 10,

                crossAxisAlignment: WrapCrossAlignment.center,

                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      const Text('Mức độ:', style: TextStyle(fontSize: 11)),

                      const SizedBox(width: 8),

                      DropdownButton<int>(
                        value: item.intensity,

                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Nhẹ')),

                          DropdownMenuItem(value: 2, child: Text('Vừa')),

                          DropdownMenuItem(value: 3, child: Text('Mạnh')),
                        ],

                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          onChanged(
                            config.replace(item.copyWith(intensity: value)),
                          );
                        },
                      ),
                    ],
                  ),

                  if (type == 'fireworks')
                    Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        const Text('Chu kỳ:', style: TextStyle(fontSize: 11)),

                        const SizedBox(width: 8),

                        DropdownButton<int>(
                          value:
                              const {
                                3,
                                5,
                                7,
                                10,
                                15,
                              }.contains(item.intervalSeconds)
                              ? item.intervalSeconds
                              : 5,

                          items: const [
                            DropdownMenuItem(value: 3, child: Text('3 giây')),

                            DropdownMenuItem(value: 5, child: Text('5 giây')),

                            DropdownMenuItem(value: 7, child: Text('7 giây')),

                            DropdownMenuItem(value: 10, child: Text('10 giây')),

                            DropdownMenuItem(value: 15, child: Text('15 giây')),
                          ],

                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            onChanged(
                              config.replace(
                                item.copyWith(intervalSeconds: value),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                  if (type == 'confetti')
                    Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Checkbox(
                          value: item.playOnce,

                          onChanged: (value) {
                            onChanged(
                              config.replace(
                                item.copyWith(playOnce: value ?? false),
                              ),
                            );
                          },
                        ),

                        const Text(
                          'Chỉ chạy một lần mỗi ngày',

                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
