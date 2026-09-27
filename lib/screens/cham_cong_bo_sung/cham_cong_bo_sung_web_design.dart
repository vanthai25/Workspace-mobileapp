import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double chamCongDesktopWebBreakpoint = 900;

bool useChamCongDesktopWeb(BuildContext context) {
  return kIsWeb &&
      MediaQuery.sizeOf(context).width >= chamCongDesktopWebBreakpoint;
}

abstract final class ChamCongWebColors {
  static const primary = Color(0xFF1274BC);
  static const primaryDark = Color(0xFF0B426B);
  static const background = Color(0xFFF3F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFDCE7F0);
  static const text = Color(0xFF20384D);
  static const muted = Color(0xFF687B8C);
  static const success = Color(0xFF16835B);
  static const warning = Color(0xFFE28A16);
  static const danger = Color(0xFFC43C35);
}

ThemeData chamCongWebTheme(BuildContext context) {
  final base = Theme.of(context);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: ChamCongWebColors.primary,
      surface: ChamCongWebColors.surface,
      error: ChamCongWebColors.danger,
    ),
    scaffoldBackgroundColor: ChamCongWebColors.background,
    dividerColor: ChamCongWebColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChamCongWebColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChamCongWebColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ChamCongWebColors.primary,
          width: 1.5,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ChamCongWebColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ChamCongWebColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        side: const BorderSide(color: Color(0xFFB9D9EA)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: ChamCongWebColors.surface,
      surfaceTintColor: ChamCongWebColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ChamCongWebColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ChamCongWebColors.surface,
      surfaceTintColor: ChamCongWebColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

class ChamCongWebPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool showBack;

  const ChamCongWebPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.actions = const [],
    this.maxWidth = 1440,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: chamCongWebTheme(context),
      child: Scaffold(
        backgroundColor: ChamCongWebColors.background,
        body: Column(
          children: [
            Container(
              height: 78,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: ChamCongWebColors.surface,
                border: Border(
                  bottom: BorderSide(color: ChamCongWebColors.border),
                ),
              ),
              child: Row(
                children: [
                  if (showBack) ...[
                    IconButton.filledTonal(
                      tooltip: 'Quay lại',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2999D7),
                          ChamCongWebColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: ChamCongWebColors.primary.withValues(
                            alpha: .2,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 23),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ChamCongWebColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ChamCongWebColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChamCongWebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const ChamCongWebCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: ChamCongWebColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChamCongWebColors.border),
        boxShadow: [
          BoxShadow(
            color: ChamCongWebColors.primaryDark.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ChamCongWebSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;

  const ChamCongWebSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ChamCongWebColors.primary, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ChamCongWebColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle?.trim().isNotEmpty == true)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: ChamCongWebColors.muted,
                    fontSize: 11.5,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ChamCongWebEmpty extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const ChamCongWebEmpty({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5FC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ChamCongWebColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: ChamCongWebColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ChamCongWebColors.muted),
          ),
        ],
      ),
    );
  }
}

double chamCongWebContentWidth(BuildContext context, {double max = 1440}) {
  return math.min(max, MediaQuery.sizeOf(context).width);
}
