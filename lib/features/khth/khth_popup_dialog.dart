import 'package:flutter/material.dart';

import 'khth_web_view.dart';

class KhthPopupDialog extends StatelessWidget {
  final String url;

  const KhthPopupDialog({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding:
          const EdgeInsets.all(18),
      clipBehavior:
          Clip.antiAlias,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child:
          SizedBox(
        width:
            size.width * 0.95,
        height:
            size.height * 0.94,
        child:
            Column(
          children: [

            Container(
              height: 58,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade50,
                border:
                    Border(
                  bottom:
                      BorderSide(
                    color:
                        Colors.grey.shade300,
                  ),
                ),
              ),
              child:
                  Row(
                children: [
                  const Icon(
                    Icons
                        .assessment_outlined,
                    color:
                        Color(
                      0xFF1274BC,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Expanded(
                    child:
                        Text(
                      'Kế hoạch tổng hợp',
                      style:
                          TextStyle(
                        fontSize:
                            18,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(
                          0xFF2C3E50,
                        ),
                      ),
                    ),
                  ),

                  Tooltip(
                    message:
                        'Đóng',
                    child:
                        IconButton(
                      onPressed:
                          () {
                        Navigator.of(
                          context,
                        ).pop();
                      },
                      icon:
                          const Icon(
                        Icons.close,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child:
                  KhthWebView(
                url: url,
              ),
            ),
          ],
        ),
      ),
    );
  }
}