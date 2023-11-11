import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';

Future<bool?> confirmPopup(BuildContext context, String title) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                key: keyConfirm,
                child: Text(
                  "yes".tr(),
                  style: const TextStyle(
                    fontSize: 21,
                    color: Color(0xffD80000),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
              const SizedBox(width: 20),
              TextButton(
                child: Text(
                  "no".tr(),
                  style: const TextStyle(fontSize: 21),
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              const SizedBox(height: 120)
            ],
          )
        ],
      );
    },
  );
}

Future<bool?> confirmPopupCertification(BuildContext context, String question1,
    String username, String question2, String address) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        // actionsPadding: const EdgeInsets.all(0.0),
        backgroundColor: backgroundColor,
        content: SizedBox(
          height: 240,
          child: Column(
            children: [
              const SizedBox(height: 15),
              Text(
                question1,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),
              Text(
                username,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Text(
                question2,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),
              Text(
                address,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              const Text(
                '?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
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
                  style: const TextStyle(
                    fontSize: 25,
                    color: Color(0xffD80000),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
              const SizedBox(width: 35),
              TextButton(
                child: Text(
                  "no".tr(),
                  style: const TextStyle(fontSize: 25),
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              const SizedBox(height: 120)
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
    barrierDismissible: true, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
                    style: const TextStyle(
                      fontSize: 21,
                      color: Color(0xffD80000),
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

bool isAddress(address) {
  final RegExp regExp = RegExp(
    r'^[a-zA-Z0-9]+$',
    caseSensitive: false,
    multiLine: false,
  );

  if (regExp.hasMatch(address) == true &&
      address.length > 45 &&
      address.length < 52) {
    log.d("C'est une adresse !");

    return true;
  } else {
    return false;
  }
}

// Widget geckoAppBar() {
//   return AppBar(
//     toolbarHeight: 60 * ratio,
//     elevation: 0,
//     leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.black),
//         onPressed: () {
//           _walletOptions.isEditing = false;
//           _walletOptions.isBalanceBlur = false;
//           Navigator.pop(context);
//         }),
//     title: SizedBox(
//       height: 22,
//       child: Consumer<WalletOptionsProvider>(
//           builder: (context, walletProvider, _) {
//         return Text(_walletOptions.nameController.text);
//       }),
//     ),
//   );
// }
