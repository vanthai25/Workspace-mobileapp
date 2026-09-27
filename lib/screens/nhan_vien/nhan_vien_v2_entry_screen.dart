import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/nhan_vien_v2_provider.dart';
import '../../services/nhan_vien_v2_service.dart';
import 'nhan_vien_v2_web_screen.dart';

class NhanVienV2EntryScreen extends StatelessWidget {
  final Widget mobileScreen;

  final NhanVienV2Service service;

  final Set<int> roleIds;

  const NhanVienV2EntryScreen({
    super.key,
    required this.mobileScreen,
    required this.service,
    required this.roleIds,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return mobileScreen;
    }

    return ChangeNotifierProvider(
      create: (_) => NhanVienV2Provider(service: service)..initialize(),
      child: NhanVienV2WebScreen(roleIds: roleIds),
    );
  }
}
