import 'package:flutter/material.dart';

abstract final class NhanVienWebColors {
  static const primary = Color(0xFF1274BC);
  static const primaryDark = Color(0xFF0B426B);
  static const background = Color(0xFFF2F6FA);
  static const surface = Colors.white;
  static const border = Color(0xFFDCE7F0);
  static const text = Color(0xFF20384D);
  static const muted = Color(0xFF687B8C);
  static const success = Color(0xFF16835B);
  static const warning = Color(0xFFE28A16);
  static const danger = Color(0xFFC43C35);
}

ThemeData nhanVienWebTheme(BuildContext context) {
  final base = Theme.of(context);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: NhanVienWebColors.primary,
      primaryContainer: const Color(0xFFE6F3FB),
      onPrimaryContainer: NhanVienWebColors.primaryDark,
      secondaryContainer: const Color(0xFFEAF5FC),
      onSecondaryContainer: NhanVienWebColors.primaryDark,
      surface: NhanVienWebColors.surface,
      surfaceContainerLowest: const Color(0xFFF8FAFC),
      outlineVariant: NhanVienWebColors.border,
      error: NhanVienWebColors.danger,
    ),
    scaffoldBackgroundColor: NhanVienWebColors.background,
    dividerColor: NhanVienWebColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NhanVienWebColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NhanVienWebColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: NhanVienWebColors.primary,
          width: 1.5,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NhanVienWebColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NhanVienWebColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        side: const BorderSide(color: Color(0xFFB7D9EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    cardTheme: CardThemeData(
      color: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NhanVienWebColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: NhanVienWebColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
  );
}

class NhanVienMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const NhanVienMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: NhanVienWebColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: NhanVienWebColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NhanVienWebColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NhanVienWebColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
