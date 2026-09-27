import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/su_kien_effect_models.dart';
import '../models/su_kien_v2_models.dart';

// ===========================================================
// HOME EVENT EFFECT LAYER
// ===========================================================

class HomeEventEffectLayer extends StatefulWidget {
  const HomeEventEffectLayer({
    super.key,
    required this.event,
    this.enabled = true,
    this.preview = false,
  });

  final SuKienV2Model? event;
  final bool enabled;
  final bool preview;

  @override
  State<HomeEventEffectLayer> createState() => _HomeEventEffectLayerState();
}

class _HomeEventEffectLayerState extends State<HomeEventEffectLayer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ambientController;

  late final AnimationController _fireworksController;

  late final AnimationController _oneShotController;

  SuKienEffectConfig _config = SuKienEffectConfig.empty();

  String _signature = '';
  bool _showOneShot = false;
  bool _foreground = true;
  bool _canAnimate = false;
  bool _oneShotPending = false;
  String? _playedSignature;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _fireworksController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _oneShotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _oneShotController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showOneShot = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(covariant HomeEventEffectLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) setState(_configure);
  }

  void _configure() {
    final event = widget.event;
    final signature = event == null
        ? ''
        : '${event.idSuKien}|${event.effectType}|${event.effectConfig}';
    final canAnimate =
        event != null &&
        widget.enabled &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    final changed = signature != _signature;
    if (changed || canAnimate != _canAnimate) _generation++;
    _canAnimate = canAnimate;
    if (changed) {
      _signature = signature;
      _config = event == null
          ? SuKienEffectConfig.empty()
          : SuKienEffectConfig.fromStored(
              event.effectConfig,
              legacyType: event.effectType,
            );
      _showOneShot = false;
      _playedSignature = null;
      _oneShotController.reset();
    }
    if (!canAnimate) {
      _ambientController.stop();
      _fireworksController.stop();
      _oneShotController.stop();
      return;
    }
    final fireworks = _config.effectOf('fireworks');
    if (fireworks.enabled && fireworks.intensity > 0) {
      final duration = Duration(
        seconds: fireworks.intervalSeconds.clamp(2, 60),
      );
      if (!_fireworksController.isAnimating ||
          _fireworksController.duration != duration) {
        _fireworksController.duration = duration;
        _fireworksController.repeat();
      }
    } else {
      _fireworksController.stop();
    }
    final ambient = _config.enabledEffects.any(
      (effect) =>
          effect.type != 'fireworks' &&
          !(effect.type == 'confetti' && effect.playOnce),
    );
    if (ambient) {
      if (!_ambientController.isAnimating) _ambientController.repeat();
    } else {
      _ambientController.stop();
    }
    final confetti = _config.effectOf('confetti');
    if (_showOneShot) {
      _oneShotController.forward();
    } else if (confetti.enabled &&
        confetti.intensity > 0 &&
        confetti.playOnce &&
        _playedSignature != signature &&
        !_oneShotPending) {
      unawaited(_playOneShotIfNeeded(event, _generation));
    }
  }

  Future<void> _playOneShotIfNeeded(SuKienV2Model event, int generation) async {
    _oneShotPending = true;
    final now = DateTime.now();
    final key =
        'home_event_confetti_${event.idSuKien}_${now.year}-${now.month}-${now.day}';
    SharedPreferences? prefs;
    try {
      if (!widget.preview) {
        prefs = await SharedPreferences.getInstance();
        if (!mounted || generation != _generation || !_canAnimate) return;
        if (prefs.getBool(key) == true) {
          _playedSignature = _signature;
          return;
        }
      }
      if (!mounted || generation != _generation || !_canAnimate) return;
      // Mark played only when visible, not while opening a hidden IndexedStack page.
      _playedSignature = _signature;
      setState(() => _showOneShot = true);
      _oneShotController.forward(from: 0);
      if (prefs != null) await prefs.setBool(key, true);
    } catch (_) {
      // Storage is optional; never let it break the Home screen.
    } finally {
      _oneShotPending = false;
      if (mounted && generation != _generation && _canAnimate) _configure();
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambientController.dispose();

    _fireworksController.dispose();

    _oneShotController.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    if (!_canAnimate || event == null || _config.enabledEffects.isEmpty) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.maybeOf(context);

    if (media?.disableAnimations == true) {
      return const SizedBox.shrink();
    }

    final fireworks = _config.effectOf('fireworks');

    final confetti = _config.effectOf('confetti');

    final ambient = _config.enabledEffects.where((effect) {
      if (effect.type == 'fireworks') {
        return false;
      }

      if (effect.type == 'confetti' && effect.playOnce) {
        return false;
      }

      return true;
    }).toList();

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ===============================================
            // AMBIENT
            // ===============================================
            if (ambient.isNotEmpty)
              AnimatedBuilder(
                animation: _ambientController,

                builder: (context, child) {
                  return ClipPath(
                    clipper: const _EventEdgesClipper(),
                    child: CustomPaint(
                      painter: _AmbientEffectPainter(
                        progress: _ambientController.value,

                        effects: ambient,

                        seed: event.idSuKien,
                      ),
                    ),
                  );
                },
              ),

            // ===============================================
            // ONE SHOT CONFETTI
            // ===============================================
            if (_showOneShot && confetti.enabled)
              AnimatedBuilder(
                animation: _oneShotController,

                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiBurstPainter(
                      progress: _oneShotController.value,

                      intensity: confetti.intensity,

                      seed: event.idSuKien,
                    ),
                  );
                },
              ),

            // ===============================================
            // FIREWORKS
            // ===============================================
            if (fireworks.enabled && fireworks.intensity > 0)
              AnimatedBuilder(
                animation: _fireworksController,

                builder: (context, child) {
                  if (_fireworksController.value > 0.65) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: _FireworksPainter(
                      progress: (_fireworksController.value / 0.65).clamp(
                        0.0,
                        1.0,
                      ),

                      intensity: fireworks.intensity,

                      seed: event.idSuKien,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// FIREWORKS
// ===========================================================

class _FireworksPainter extends CustomPainter {
  const _FireworksPainter({
    required this.progress,
    required this.intensity,
    required this.seed,
  });

  final double progress;
  final int intensity;
  final int seed;

  static const List<Color> _colors = [
    Color(0xFFFFD54F),
    Color(0xFFFF6B81),
    Color(0xFF67D5FF),
    Color(0xFF81E6B4),
    Color(0xFFFF8A65),
    Color(0xFFBA8CFF),
    Color(0xFFFFB7CF),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final int level = intensity.clamp(1, 3);

    final bool compact = size.width < 600;

    // Mobile vẫn nhiều,
    // Web sẽ nhiều hơn nữa.
    final int count = compact ? 2 + level : 3 + level * 2;

    final double minSide = math.min(size.width, size.height);

    for (int i = 0; i < count; i++) {
      final int burstGroup = i % 5;

      final int wave = i ~/ 5;

      final double phaseOffset = burstGroup * 0.035 + wave * 0.26;

      final double local = (progress + phaseOffset) % 1.0;

      final int columnCount = size.width < 600 ? 4 : 7;

      final int column = i % columnCount;

      final double columnWidth = 1.0 / columnCount;

      final double jitterX = (_unit(seed, i, 17) - 0.5) * columnWidth * 0.65;

      final double normalizedX = ((column + 0.5) * columnWidth + jitterX).clamp(
        0.05,
        0.95,
      );

      final double normalizedY = (0.08 + _unit(seed, i, 31) * 0.50).clamp(
        0.06,
        0.60,
      );

      final Offset target = Offset(
        size.width * normalizedX,

        size.height * normalizedY,
      );

      final Color baseColor = _colors[(seed + i * 3) % _colors.length];

      // ===============================================
      // ROCKET BAY LÊN
      // ===============================================

      const double launchEnd = 0.25;

      if (local < launchEnd) {
        final double t = Curves.easeOutCubic.transform(local / launchEnd);

        final Offset rocket = Offset(
          target.dx,

          size.height + 30 - (size.height + 30 - target.dy) * t,
        );

        final double trailLength = 18 + level * 4;

        final Paint trailPaint = Paint()
          ..color = baseColor.withValues(alpha: 0.85)
          ..strokeWidth = 1.8 + level * 0.25
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(rocket.dx, rocket.dy + trailLength),
          rocket,
          trailPaint,
        );

        canvas.drawCircle(
          rocket,
          2.3 + level * 0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );

        continue;
      }

      // ===============================================
      // EXPLOSION
      // ===============================================

      final double explosion = (local - launchEnd) / (1 - launchEnd);

      final double eased = Curves.easeOutCubic.transform(
        explosion.clamp(0.0, 1.0),
      );

      final double alpha = (1.0 - explosion).clamp(0.0, 1.0);

      final double radius = (24 + minSide * (0.10 + level * 0.032)) * eased;

      final int rays = 18 + level * 8;

      // ===============================================
      // MAIN RAYS
      // ===============================================

      for (int ray = 0; ray < rays; ray++) {
        final Color rayColor = _colors[(seed + i * 3 + ray) % _colors.length];

        final double randomAngle = _unit(seed, ray, i + 90) * 0.15;

        final double angle = math.pi * 2 * ray / rays + randomAngle;

        final double randomLength = 0.74 + _unit(seed, ray, i + 120) * 0.30;

        final double length = radius * randomLength;

        final Offset end = Offset(
          target.dx + math.cos(angle) * length,

          target.dy + math.sin(angle) * length,
        );

        final Offset start = Offset(
          target.dx + math.cos(angle) * length * 0.62,

          target.dy + math.sin(angle) * length * 0.62,
        );

        final Paint rayPaint = Paint()
          ..color = rayColor.withValues(alpha: alpha * 0.92)
          ..strokeWidth = level == 3 ? 2.3 : 1.7
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(start, end, rayPaint);

        canvas.drawCircle(end, level == 3 ? 2.2 : 1.55, rayPaint);
      }

      // ===============================================
      // SECOND INNER RING
      // ===============================================

      if (level >= 2) {
        final int innerCount = 10 + level * 3;

        final double innerRadius = radius * 0.48;

        for (int j = 0; j < innerCount; j++) {
          final double angle = math.pi * 2 * j / innerCount + 0.18;

          final Offset dot = Offset(
            target.dx + math.cos(angle) * innerRadius,

            target.dy + math.sin(angle) * innerRadius,
          );

          canvas.drawCircle(
            dot,
            1.4 + level * 0.25,
            Paint()
              ..color = _colors[(j + i) % _colors.length].withValues(
                alpha: alpha * 0.82,
              ),
          );
        }
      }

      // ===============================================
      // CENTER FLASH
      // ===============================================

      canvas.drawCircle(
        target,
        3.0 + level * 0.8,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.seed != seed;
  }
}

// ===========================================================
// AMBIENT EFFECTS
// ===========================================================

class _AmbientEffectPainter extends CustomPainter {
  const _AmbientEffectPainter({
    required this.progress,
    required this.effects,
    required this.seed,
  });

  final double progress;

  final List<SuKienEffectItem> effects;

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    for (final effect in effects) {
      final int intensity = effect.intensity.clamp(1, 3);

      switch (effect.type) {
        case 'sparkle':
          _paintSparkle(canvas, size, intensity);
          break;

        case 'balloon':
          _paintBalloon(canvas, size, intensity);
          break;

        case 'snow':
          _paintSnow(canvas, size, intensity);
          break;

        case 'flower':
          _paintFlower(canvas, size, intensity);
          break;

        case 'confetti':
          _paintConfetti(canvas, size, intensity);
          break;
      }
    }
  }

  // =========================================================
  // SPARKLE
  // =========================================================

  void _paintSparkle(Canvas canvas, Size size, int intensity) {
    const List<Color> sparkleColors = [
      Color(0xFFFFC107),
      Color(0xFFFFD95A),
      Color(0xFFFFB7CF),
      Color(0xFF67D5FF),
      Color(0xFF8FE3C2),
      Colors.white,
    ];

    final bool compact = size.width < 600;

    final int count = compact ? 24 + intensity * 14 : 34 + intensity * 20;

    for (int i = 0; i < count; i++) {
      final double x = _unit(seed, i, 201) * size.width;

      final double y = _unit(seed, i, 202) * size.height;

      final double pulse =
          (math.sin(progress * math.pi * 4 + i * 1.37) + 1) / 2;

      if (pulse < 0.20) {
        continue;
      }

      final double radius = 2.0 + pulse * (2.5 + intensity * 0.9);

      final Color color = sparkleColors[i % sparkleColors.length];

      final Paint paint = Paint()
        ..color = color.withValues(alpha: 0.30 + pulse * 0.65)
        ..strokeWidth = 1.15 + intensity * 0.20
        ..strokeCap = StrokeCap.round;

      // ngang
      canvas.drawLine(Offset(x - radius, y), Offset(x + radius, y), paint);

      // dọc
      canvas.drawLine(Offset(x, y - radius), Offset(x, y + radius), paint);

      // chéo
      final double diagonal = radius * 0.62;

      canvas.drawLine(
        Offset(x - diagonal, y - diagonal),
        Offset(x + diagonal, y + diagonal),
        paint,
      );

      canvas.drawLine(
        Offset(x + diagonal, y - diagonal),
        Offset(x - diagonal, y + diagonal),
        paint,
      );

      if (pulse > 0.75) {
        canvas.drawCircle(
          Offset(x, y),
          1.1,
          Paint()..color = Colors.white.withValues(alpha: pulse),
        );
      }
    }
  }

  // =========================================================
  // BALLOON
  // =========================================================

  void _paintBalloon(Canvas canvas, Size size, int intensity) {
    const List<Color> colors = [
      Color(0xFFFF6B81),
      Color(0xFFFFC107),
      Color(0xFF5DC8FF),
      Color(0xFF8F7CFF),
      Color(0xFF67D6A3),
      Color(0xFFFF8A65),
      Color(0xFFFFB7CF),
    ];

    final bool compact = size.width < 600;

    final int count = compact ? 6 + intensity * 4 : 9 + intensity * 5;

    for (int i = 0; i < count; i++) {
      final double speed = 0.08 + _unit(seed, i, 501) * 0.14;

      final double position = (_unit(seed, i, 502) + progress * speed) % 1.0;

      final double x =
          size.width * (0.02 + _unit(seed, i, 503) * 0.96) +
          math.sin(progress * math.pi * 2 + i * 0.8) * 15;

      final double y = size.height * (1.16 - position * 1.34);

      final double scale = 0.72 + _unit(seed, i, 504) * 0.68;

      final Color color = colors[i % colors.length];

      final double width = (20 + intensity * 3) * scale;

      final double height = (27 + intensity * 4) * scale;

      // balloon
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: width, height: height),
        Paint()..color = color.withValues(alpha: 0.64),
      );

      // highlight
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - width * 0.18, y - height * 0.20),
          width: width * 0.18,
          height: height * 0.28,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );

      // knot
      final Path knot = Path()
        ..moveTo(x, y + height / 2 - 1)
        ..lineTo(x - 3, y + height / 2 + 5)
        ..lineTo(x + 3, y + height / 2 + 5)
        ..close();

      canvas.drawPath(knot, Paint()..color = color.withValues(alpha: 0.72));

      // string
      final Paint stringPaint = Paint()
        ..color = color.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final Path stringPath = Path();

      stringPath.moveTo(x, y + height / 2 + 5);

      stringPath.quadraticBezierTo(
        x + 5,
        y + height / 2 + 16,
        x,
        y + height / 2 + 30,
      );

      canvas.drawPath(stringPath, stringPaint);
    }
  }

  // =========================================================
  // SNOW
  // =========================================================

  void _paintSnow(Canvas canvas, Size size, int intensity) {
    final int count = 24 + intensity * 22;

    for (int i = 0; i < count; i++) {
      final double speed = 0.18 + _unit(seed, i, 301) * 0.38;

      final double yFraction = (_unit(seed, i, 302) + progress * speed) % 1.0;

      final double sway = math.sin(progress * math.pi * 2 + i) * 13;

      final double x = _unit(seed, i, 303) * size.width + sway;

      final double y = yFraction * size.height;

      final double radius = 1.2 + _unit(seed, i, 304) * (1.8 + intensity * 0.5);

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: 0.50 + radius * 0.08),
      );
    }
  }

  // =========================================================
  // FLOWER
  // =========================================================

  void _paintFlower(Canvas canvas, Size size, int intensity) {
    const List<Color> colors = [
      Color(0xFFFF8FA8),
      Color(0xFFFFBCD0),
      Color(0xFFFFD15C),
      Color(0xFFFFB39D),
      Color(0xFFFFE08B),
    ];

    final int count = 14 + intensity * 14;

    for (int i = 0; i < count; i++) {
      final double speed = 0.14 + _unit(seed, i, 401) * 0.30;

      final double yFraction = (_unit(seed, i, 402) + progress * speed) % 1.0;

      final double x =
          _unit(seed, i, 403) * size.width +
          math.sin(progress * math.pi * 2 + i) * 20;

      final double y = yFraction * size.height;

      final double scale = 0.75 + _unit(seed, i, 404) * 0.60;

      canvas.save();

      canvas.translate(x, y);

      canvas.rotate(progress * math.pi * 2 + i);

      final Paint paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.72);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 10 * scale,
          height: 5.5 * scale,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  // =========================================================
  // CONTINUOUS CONFETTI
  // =========================================================

  void _paintConfetti(Canvas canvas, Size size, int intensity) {
    const List<Color> colors = [
      Color(0xFFFFD54F),
      Color(0xFFFF6B81),
      Color(0xFF5DC8FF),
      Color(0xFF81E6B4),
      Color(0xFFBA8CFF),
      Color(0xFFFF8A65),
    ];

    final int count = 24 + intensity * 22;

    for (int i = 0; i < count; i++) {
      final double speed = 0.25 + _unit(seed, i, 601) * 0.42;

      final double yFraction = (_unit(seed, i, 602) + progress * speed) % 1.0;

      final double x =
          _unit(seed, i, 603) * size.width +
          math.sin(progress * math.pi * 3 + i) * 12;

      final double y = yFraction * size.height;

      final double scale = 0.75 + _unit(seed, i, 604) * 0.55;

      canvas.save();

      canvas.translate(x, y);

      canvas.rotate(progress * math.pi * 5 + i);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 8 * scale,
          height: 4.5 * scale,
        ),
        Paint()..color = colors[i % colors.length].withValues(alpha: 0.76),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientEffectPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.seed != seed ||
        oldDelegate.effects != effects;
  }
}

// ===========================================================
// ONE SHOT CONFETTI
// ===========================================================

class _ConfettiBurstPainter extends CustomPainter {
  const _ConfettiBurstPainter({
    required this.progress,
    required this.intensity,
    required this.seed,
  });

  final double progress;
  final int intensity;
  final int seed;

  static const List<Color> _colors = [
    Color(0xFFFFD54F),
    Color(0xFFFF6B81),
    Color(0xFF5DC8FF),
    Color(0xFF67D6A3),
    Color(0xFFBA8CFF),
    Color(0xFFFF8A65),
    Color(0xFFFFB7CF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final int level = intensity.clamp(1, 3);

    final int count = size.width < 600 ? 24 + level * 14 : 40 + level * 24;

    final double fade = progress < 0.74
        ? 1.0
        : (1 - (progress - 0.74) / 0.26).clamp(0.0, 1.0);

    for (int i = 0; i < count; i++) {
      final double startX = _unit(seed, i, 701) * size.width;

      final double delay = _unit(seed, i, 702) * 0.24;

      final double local = (progress - delay).clamp(0.0, 1.0);

      final double x =
          startX + math.sin(local * math.pi * 4 + i) * (18 + level * 5);

      final double y =
          -30 +
          local * (size.height + 90) * (0.72 + _unit(seed, i, 703) * 0.48);

      final double scale = 0.65 + _unit(seed, i, 704) * 0.75;

      canvas.save();

      canvas.translate(x, y);

      canvas.rotate(local * math.pi * (6 + level) + i);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 8 * scale,
          height: 5 * scale,
        ),
        Paint()
          ..color = _colors[i % _colors.length].withValues(alpha: fade * 0.92),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.seed != seed;
  }
}

double _unit(int seed, int index, int salt) {
  final double value =
      math.sin(seed * 12.9898 + index * 78.233 + salt * 37.719) * 43758.5453123;

  return value - value.floorToDouble();
}

class _EventEdgesClipper extends CustomClipper<Path> {
  const _EventEdgesClipper();

  @override
  Path getClip(Size size) {
    final edge = size.width < 600 ? size.width * 0.13 : size.width * 0.16;
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, edge, size.height))
      ..addRect(Rect.fromLTWH(size.width - edge, 0, edge, size.height));
  }

  @override
  bool shouldReclip(covariant _EventEdgesClipper oldClipper) => false;
}
