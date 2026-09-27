import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/dao_tao_v2_provider.dart';

class QuickDaoTaoWidget extends StatelessWidget {
  const QuickDaoTaoWidget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<DaoTaoV2Provider>(
      builder: (context, provider, child) {
        final openClasses = provider.danhSach
            .where((item) => item.isMoDangKy || item.isDaDangKy)
            .toList();

        if ((provider.isLoading && provider.danhSach.isEmpty) ||
            openClasses.isEmpty) {
          return const SizedBox.shrink();
        }

        final first = openClasses.first;
        final deadline = first.ketThucDangKy;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(19),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF087DBA), Color(0xFF25A1CF)],
                  ),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF087DBA).withValues(alpha: .22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .17),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .2),
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'LỚP ĐÀO TẠO ĐANG MỞ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    letterSpacing: .35,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${openClasses.length} lớp',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            first.tenLopDaoTao,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (deadline != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              'Đăng ký đến ${DateFormat('dd/MM/yyyy HH:mm').format(deadline)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .84),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
