import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';

Future<bool?> confirmPopup(BuildContext context, String title) async {
  return showDialog<bool>(
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
                key: keyConfirm,
                child: Text(
                  "yes".tr(),
                  style: scaledTextStyle(
                    fontSize: 18,
                    color: const Color(0xffD80000),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
              ScaledSizedBox(width: 20),
              TextButton(
                child: Text(
                  "no".tr(),
                  style: scaledTextStyle(fontSize: 18, color: Colors.blueAccent),
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              ScaledSizedBox(height: 70)
            ],
          )
        ],
      );
    },
  );
}

Future<bool?> confirmPopupCertification(BuildContext context, String question1, String username, String question2, String address) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        content: ScaledSizedBox(
          height: 220,
          child: Column(
            children: [
              ScaledSizedBox(height: 10),
              Text(
                question1,
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              ScaledSizedBox(height: 15),
              Text(
                username,
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 19, fontWeight: FontWeight.w500),
              ),
              ScaledSizedBox(height: 15),
              Text(
                question2,
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              ScaledSizedBox(height: 15),
              Text(
                address,
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              ScaledSizedBox(height: 15),
              Text(
                '?',
                textAlign: TextAlign.center,
                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                key: keyConfirm,
                child: Text(
                  "yes".tr(),
                  style: scaledTextStyle(
                    fontSize: 18,
                    color: const Color(0xffD80000),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
              ScaledSizedBox(width: 32),
              TextButton(
                child: Text(
                  "no".tr(),
                  style: scaledTextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              ScaledSizedBox(height: 120)
            ],
          )
        ],
      );
    },
  );
}

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
