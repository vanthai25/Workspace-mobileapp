import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobileapp_bvhv/features/su_kien/widgets/su_kien_effect_preview.dart';
import 'package:mobileapp_bvhv/models/su_kien_effect_models.dart';
import 'package:mobileapp_bvhv/models/su_kien_v2_models.dart';
import 'package:mobileapp_bvhv/services/su_kien_changes.dart';
import 'package:mobileapp_bvhv/services/su_kien_home_service.dart';
import 'package:mobileapp_bvhv/widgets/home_event_effect_layer.dart';
import 'package:mobileapp_bvhv/widgets/su_kien_home_carousel.dart';

class _Service extends SuKienHomeService {
  _Service() : super(Dio());
  List<SuKienV2Model> events = [];
  int loads = 0;
  int images = 0;
  bool failImage = false;
  Completer<List<SuKienV2Model>>? pending;

  @override
  Future<List<SuKienV2Model>> getCurrent() async {
    loads++;
    if (pending != null) return pending!.future;
    return [...events];
  }

  @override
  Future<Uint8List> getBannerImage(int idBanner) async {
    images++;
    if (failImage) throw Exception('offline');
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
  }
}

SuKienV2Model _event({int id = 1, int banners = 1}) => SuKienV2Model(
  idSuKien: id,
  tenSuKien: 'Sự kiện $id',
  tuNgay: DateTime.now().subtract(const Duration(days: 1)),
  denNgay: DateTime.now().add(const Duration(days: 1)),
  isActive: true,
  showCountdown: false,
  effectConfig: SuKienEffectConfig.subtle().toJsonString(),
  banners: List.generate(
    banners,
    (index) => SuKienBannerV2Model(
      idBanner: index + 1,
      idSuKien: id,
      idFile: index + 1,
      tieuDe: 'Banner ${index + 1}',
    ),
  ),
);

Future<void> _flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 30));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('Banner layout with long CTA and many slides at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final item = _event(banners: 20);
      item.banners[0] = const SuKienBannerV2Model(
        idBanner: 1,
        idSuKien: 1,
        idFile: 1,
        tieuDe: 'Chương trình đào tạo toàn viện và các hoạt động đặc biệt',
        actionType: 'screen',
        actionValue: 'dao-tao',
        buttonText: 'Xem chi tiết và đăng ký tham gia',
      );
      final service = _Service()..events = [item];
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: const TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SuKienHomeCarousel(
                  service: service,
                  desktop: width > 900,
                ),
              ),
            ),
          ),
        ),
      );
      await _flush(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Reduced motion does not start effect controllers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: HomeEventEffectLayer(event: _event(), preview: true),
        ),
      ),
    );
    await _flush(tester);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Empty initial response clears stale Home effect', (
    tester,
  ) async {
    final service = _Service();
    final updates = <SuKienV2Model?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SuKienHomeCarousel(
          service: service,
          onActiveEventChanged: updates.add,
        ),
      ),
    );
    await _flush(tester);
    expect(service.loads, 1);
    expect(updates, [null]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Failed image can retry and successful image stays cached', (
    tester,
  ) async {
    final service = _Service()
      ..events = [_event()]
      ..failImage = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SuKienHomeCarousel(service: service)),
      ),
    );
    await _flush(tester);
    expect(find.text('Tải lại ảnh'), findsOneWidget);
    service.failImage = false;
    await tester.tap(find.text('Tải lại ảnh'));
    await _flush(tester);
    expect(service.images, 2);
    SuKienChanges.notifyChanged();
    await _flush(tester);
    expect(service.images, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reload retries failed image and admin deletion clears effect', (
    tester,
  ) async {
    final service = _Service()
      ..events = [_event()]
      ..failImage = true;
    final updates = <SuKienV2Model?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SuKienHomeCarousel(
            service: service,
            onActiveEventChanged: updates.add,
          ),
        ),
      ),
    );
    await _flush(tester);
    service.failImage = false;
    SuKienChanges.notifyChanged();
    await _flush(tester);
    expect(service.images, 2);
    service.events = [];
    SuKienChanges.notifyChanged();
    await _flush(tester);
    expect(updates.last, isNull);
    expect(find.byType(PageView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Mutation during an in-flight load queues a fresh request', (
    tester,
  ) async {
    final service = _Service()..pending = Completer<List<SuKienV2Model>>();
    await tester.pumpWidget(
      MaterialApp(home: SuKienHomeCarousel(service: service)),
    );
    await _flush(tester);
    SuKienChanges.notifyChanged();
    final pending = service.pending!;
    service.pending = null;
    pending.complete([]);
    await _flush(tester);
    expect(service.loads, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Hidden Home stops polling and reloads on return', (
    tester,
  ) async {
    final service = _Service();
    var visible = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return TickerMode(
              enabled: visible,
              child: SuKienHomeCarousel(service: service),
            );
          },
        ),
      ),
    );
    await _flush(tester);
    expect(service.loads, 0);
    update(() => visible = true);
    await _flush(tester);
    expect(service.loads, 1);
    update(() => visible = false);
    await _flush(tester);
    await tester.pump(const Duration(minutes: 6));
    SuKienChanges.notifyChanged();
    expect(service.loads, 1);
    update(() => visible = true);
    await _flush(tester);
    expect(service.loads, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Background stops timers and foreground reloads', (tester) async {
    final service = _Service();
    await tester.pumpWidget(
      MaterialApp(home: SuKienHomeCarousel(service: service)),
    );
    await _flush(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 6));
    expect(service.loads, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush(tester);
    expect(service.loads, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Pause prevents autoplay; resume advances banner', (
    tester,
  ) async {
    final service = _Service()..events = [_event(banners: 2)];
    var paused = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SuKienHomeCarousel(
              service: service,
              motionPaused: paused,
              onMotionPausedChanged: (value) => setState(() => paused = value),
            ),
          ),
        ),
      ),
    );
    await _flush(tester);
    final page = tester.widget<PageView>(find.byType(PageView)).controller!;
    await tester.pump(const Duration(seconds: 8));
    expect(page.page, 0);
    await tester.tap(find.text('Bật chuyển động'));
    await _flush(tester);
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 1));
    expect(page.page, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Effect controllers stop when paused or hidden', (tester) async {
    var enabled = true;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return HomeEventEffectLayer(
              event: _event(),
              enabled: enabled,
              preview: true,
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    update(() => enabled = false);
    await _flush(tester);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final mobile in [true, false]) {
    testWidgets('Effect preview fits phone viewport (mobile=$mobile)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: SuKienEffectPreview(
            config: SuKienEffectConfig.birthday(),
            mobile: mobile,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
