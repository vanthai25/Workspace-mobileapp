import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/su_kien_provider.dart';
import '../screens/su_kien/su_kien_screen.dart';

class QuickSuKienWidget
    extends StatelessWidget {
  const QuickSuKienWidget({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Consumer<SuKienProvider>(
      builder: (
        context,
        provider,
        child,
      ) {
        // Đang load lần đầu:
        // không hiện gì để Home không bị giật.
        if (!provider.daLoadDangMo) {
          return const SizedBox
              .shrink();
        }

        final events =
            provider.suKienDangMo;

        // Không có sự kiện còn hạn:
        // ẨN HOÀN TOÀN.
        if (events.isEmpty) {
          return const SizedBox
              .shrink();
        }

        final first =
            events.first;

        return Padding(
            padding: const EdgeInsets.fromLTRB(
                22,
                6,
                22,
                8,
            ),
            child: InkWell(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SuKienScreen(),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFF1274BC),
                    Color(0xFF3D99D5),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withOpacity(
                        0.18,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .celebration_rounded,
                      color:
                          Colors.white,
                      size: 27,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'Sự kiện đang mở đăng ký',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                13,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          first.tentiec ??
                              'Sự kiện',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                15,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),

                        if (first
                                .ngayketthucdky !=
                            null) ...[
                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            'Đăng ký đến '
                            '${DateFormat('dd/MM/yyyy HH:mm').format(first.ngayketthucdky!)}',
                            style:
                                TextStyle(
                              color:
                                  Colors.white
                                      .withOpacity(
                                0.85,
                              ),
                              fontSize:
                                  11,
                            ),
                          ),
                        ],

                        if (events.length >
                            1)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 3,
                            ),
                            child: Text(
                              '+ ${events.length - 1} sự kiện khác',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}