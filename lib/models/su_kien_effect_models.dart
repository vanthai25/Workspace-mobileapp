import 'dart:convert';

class SuKienEffectItem {
  final String type;
  final bool enabled;
  final int intensity;
  final int intervalSeconds;
  final bool playOnce;

  const SuKienEffectItem({
    required this.type,
    this.enabled = false,
    this.intensity = 1,
    this.intervalSeconds = 5,
    this.playOnce = false,
  });

  SuKienEffectItem copyWith({
    bool? enabled,
    int? intensity,
    int? intervalSeconds,
    bool? playOnce,
  }) {
    return SuKienEffectItem(
      type: type,
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      intervalSeconds:
          intervalSeconds ?? this.intervalSeconds,
      playOnce: playOnce ?? this.playOnce,
    );
  }

  factory SuKienEffectItem.fromJson(
    Map<String, dynamic> json,
  ) {
    int toInt(
      dynamic value,
      int fallback,
    ) {
      if (value is int) {
        return value;
      }

      return int.tryParse(
            value?.toString() ?? '',
          ) ??
          fallback;
    }

    bool toBool(
      dynamic value,
      bool fallback,
    ) {
      if (value is bool) {
        return value;
      }

      if (value == 1 ||
          value?.toString().toLowerCase() ==
              'true') {
        return true;
      }

      if (value == 0 ||
          value?.toString().toLowerCase() ==
              'false') {
        return false;
      }

      return fallback;
    }

    return SuKienEffectItem(
      type:
          json['type']?.toString().trim().toLowerCase() ??
          '',

      enabled:
          toBool(
        json['enabled'],
        true,
      ),

      intensity:
          toInt(
        json['intensity'],
        1,
      ).clamp(0, 3),

      intervalSeconds:
          toInt(
        json['intervalSeconds'],
        5,
      ).clamp(2, 60),

      playOnce:
          toBool(
        json['playOnce'],
        false,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'enabled': enabled,
      'intensity': intensity,
      'intervalSeconds':
          intervalSeconds,
      'playOnce': playOnce,
    };
  }
}


class SuKienEffectConfig {
  static const List<String>
      supportedTypes = [
    'fireworks',
    'confetti',
    'sparkle',
    'balloon',
    'snow',
    'flower',
  ];

  final List<SuKienEffectItem> effects;

  const SuKienEffectConfig({
    required this.effects,
  });

  factory SuKienEffectConfig.empty() {
    return SuKienEffectConfig(
      effects:
          supportedTypes.map(
        (type) {
          return SuKienEffectItem(
            type: type,
            playOnce:
                type == 'confetti',
          );
        },
      ).toList(),
    );
  }

  factory SuKienEffectConfig.fromStored(
    String? raw, {
    String? legacyType,
  }) {
    bool parsedSuccessfully =
        false;

    final parsed =
        <String, SuKienEffectItem>{};

    if (raw != null &&
        raw.trim().isNotEmpty) {
      try {
        final dynamic root =
            jsonDecode(
          raw,
        );

        if (root is Map &&
            root['effects'] is List) {
          parsedSuccessfully =
              true;

          for (final dynamic value
              in root['effects']) {
            if (value is! Map) {
              continue;
            }

            final item =
                SuKienEffectItem
                    .fromJson(
              Map<String, dynamic>.from(
                value,
              ),
            );

            if (supportedTypes
                .contains(
              item.type,
            )) {
              parsed[item.type] =
                  item;
            }
          }
        }
      } catch (_) {
        parsedSuccessfully =
            false;
      }
    }

    if (!parsedSuccessfully) {
      return SuKienEffectConfig.fromLegacy(
        legacyType,
      );
    }

    return SuKienEffectConfig(
      effects:
          supportedTypes.map(
        (type) {
          return parsed[type] ??
              SuKienEffectItem(
                type: type,
                playOnce:
                    type ==
                        'confetti',
              );
        },
      ).toList(),
    );
  }

  factory SuKienEffectConfig.fromLegacy(
    String? legacyType,
  ) {
    final type =
        legacyType
            ?.trim()
            .toLowerCase();

    if (type == null ||
        type.isEmpty ||
        type == 'none') {
      return SuKienEffectConfig.empty();
    }

    if (type == 'tet') {
      return SuKienEffectConfig.tet();
    }

    var config =
        SuKienEffectConfig.empty();

    if (supportedTypes.contains(type)) {
      final old =
          config.effectOf(type);

      config =
          config.replace(
        old.copyWith(
          enabled: true,
          intensity: 1,
          playOnce:
              type == 'confetti',
        ),
      );
    }

    return config;
  }

  SuKienEffectItem effectOf(
    String type,
  ) {
    for (final item in effects) {
      if (item.type == type) {
        return item;
      }
    }

    return SuKienEffectItem(
      type: type,
    );
  }

  SuKienEffectConfig replace(
    SuKienEffectItem item,
  ) {
    return SuKienEffectConfig(
      effects:
          effects.map(
        (old) =>
            old.type == item.type
                ? item
                : old,
      ).toList(),
    );
  }

  List<SuKienEffectItem>
      get enabledEffects {
    return effects
        .where(
          (x) =>
              x.enabled &&
              x.intensity > 0,
        )
        .toList();
  }

  String toJsonString() {
    // Chỉ lưu các effect đang bật.
    return jsonEncode({
      'effects':
          enabledEffects
              .map(
                (x) =>
                    x.toJson(),
              )
              .toList(),
    });
  }

  String? get primaryEffectType {
    final enabled =
        enabledEffects;

    return enabled.isEmpty
        ? null
        : enabled.first.type;
  }

  // =========================================================
  // PRESETS
  // =========================================================

  factory SuKienEffectConfig.birthday() {
  var config =
      SuKienEffectConfig.empty();

  // Pháo hoa
  config =
      config.replace(
    config
        .effectOf('fireworks')
        .copyWith(
          enabled: true,
          intensity: 3,
          intervalSeconds: 4,
          playOnce: false,
        ),
  );

  // Pháo giấy
  config =
      config.replace(
    config
        .effectOf('confetti')
        .copyWith(
          enabled: true,
          intensity: 2,
          intervalSeconds: 5,
          playOnce: true,
        ),
  );

  // Lấp lánh
  config =
      config.replace(
    config
        .effectOf('sparkle')
        .copyWith(
          enabled: true,
          intensity: 2,
          intervalSeconds: 5,
          playOnce: false,
        ),
  );

  // Bóng bay
  config =
      config.replace(
    config
        .effectOf('balloon')
        .copyWith(
          enabled: true,
          intensity: 2,
          intervalSeconds: 5,
          playOnce: false,
        ),
  );

  return config;
}

  factory SuKienEffectConfig.tet() {
    var config =
        SuKienEffectConfig.empty();

    config =
        config.replace(
      config
          .effectOf('fireworks')
          .copyWith(
            enabled: true,
            intensity: 2,
            intervalSeconds: 6,
          ),
    );

    config =
        config.replace(
      config
          .effectOf('flower')
          .copyWith(
            enabled: true,
            intensity: 1,
          ),
    );

    config =
        config.replace(
      config
          .effectOf('sparkle')
          .copyWith(
            enabled: true,
            intensity: 1,
          ),
    );

    return config;
  }

  factory SuKienEffectConfig.christmas() {
    var config =
        SuKienEffectConfig.empty();

    config =
        config.replace(
      config
          .effectOf('snow')
          .copyWith(
            enabled: true,
            intensity: 2,
          ),
    );

    config =
        config.replace(
      config
          .effectOf('sparkle')
          .copyWith(
            enabled: true,
            intensity: 1,
          ),
    );

    return config;
  }

  factory SuKienEffectConfig.flower() {
    var config =
        SuKienEffectConfig.empty();

    config =
        config.replace(
      config
          .effectOf('flower')
          .copyWith(
            enabled: true,
            intensity: 2,
          ),
    );

    config =
        config.replace(
      config
          .effectOf('sparkle')
          .copyWith(
            enabled: true,
            intensity: 1,
          ),
    );

    return config;
  }

  factory SuKienEffectConfig.subtle() {
    var config =
        SuKienEffectConfig.empty();

    config =
        config.replace(
      config
          .effectOf('sparkle')
          .copyWith(
            enabled: true,
            intensity: 1,
          ),
    );

    return config;
  }
  
}