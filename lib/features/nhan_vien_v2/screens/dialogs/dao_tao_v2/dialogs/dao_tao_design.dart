import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class DaoTaoColors {
  static const primary = Color(0xFF1274BC);
  static const primaryDark = Color(0xFF0B426B);
  static const background = Color(0xFFF3F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFDDE7F0);
  static const text = Color(0xFF20384D);
  static const muted = Color(0xFF66788A);
  static const success = Color(0xFF16835B);
  static const warning = Color(0xFFE48A13);
  static const danger = Color(0xFFC43C35);
}

InputDecoration daoTaoInputDecoration({
  String? label,
  String? hint,
  IconData? icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: DaoTaoColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: DaoTaoColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: DaoTaoColors.primary, width: 1.5),
    ),
  );
}

ThemeData daoTaoTheme(BuildContext context) {
  final base = Theme.of(context);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: DaoTaoColors.primary,
      secondary: const Color(0xFF2F8FBF),
      surface: DaoTaoColors.surface,
      error: DaoTaoColors.danger,
    ),
    scaffoldBackgroundColor: DaoTaoColors.background,
    dividerColor: DaoTaoColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DaoTaoColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DaoTaoColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DaoTaoColors.primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: DaoTaoColors.surface,
      surfaceTintColor: DaoTaoColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DaoTaoColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DaoTaoColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DaoTaoColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        side: const BorderSide(color: Color(0xFFB8D9EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: DaoTaoColors.primary,
      unselectedLabelColor: DaoTaoColors.muted,
      indicatorColor: DaoTaoColors.primary,
      dividerColor: Colors.transparent,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DaoTaoColors.surface,
      surfaceTintColor: DaoTaoColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: const TextStyle(
        color: DaoTaoColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class DaoTaoDialogShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Widget? footer;
  final List<Widget> headerActions;
  final double maxWidth;
  final double maxHeight;
  final bool canClose;

  const DaoTaoDialogShell({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.footer,
    this.headerActions = const [],
    this.maxWidth = 1120,
    this.maxHeight = 820,
    this.canClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = math.max(320.0, math.min(maxWidth, size.width - 32));
    final height = math.max(320.0, math.min(maxHeight, size.height - 32));

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      backgroundColor: DaoTaoColors.surface,
      surfaceTintColor: DaoTaoColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: DaoTaoColors.surface,
                border: Border(bottom: BorderSide(color: DaoTaoColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2999D7), DaoTaoColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: DaoTaoColors.primary.withValues(alpha: .2),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DaoTaoColors.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DaoTaoColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ...headerActions,
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: canClose ? () => Navigator.pop(context) : null,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(color: DaoTaoColors.background, child: child),
            ),
            if (footer != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                decoration: const BoxDecoration(
                  color: DaoTaoColors.surface,
                  border: Border(top: BorderSide(color: DaoTaoColors.border)),
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class DaoTaoSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DaoTaoSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: DaoTaoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DaoTaoColors.border),
        boxShadow: [
          BoxShadow(
            color: DaoTaoColors.primaryDark.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: DaoTaoColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DaoTaoColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: DaoTaoColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class DaoTaoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const DaoTaoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
              child: Icon(icon, color: DaoTaoColors.primary, size: 28),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DaoTaoColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            if (message?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 5),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: DaoTaoColors.muted),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

class DaoTaoStatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;

  const DaoTaoStatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
