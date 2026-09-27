import 'package:flutter/foundation.dart';

/// Invalidates Home after an admin mutation in this app session.
/// Other devices still refresh when Home opens/resumes and by periodic polling.
class SuKienChanges {
  static final revision = ValueNotifier<int>(0);

  static void notifyChanged() => revision.value++;
}
