import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';

Future<void> infoPopup(BuildContext context, String title) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                key: keyInfoPopup,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    "gotit".tr(),
                    style: scaledTextStyle(
                      fontSize: 18,
                      color: const Color(0xffD80000),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          )
        ],
      );
    },
  );
}
