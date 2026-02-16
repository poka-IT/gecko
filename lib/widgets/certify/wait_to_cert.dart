import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/screens/profile_view.dart' show buttonSize, buttonFontSize;

class WaitToCertWidget extends StatelessWidget {
  final String label;
  final String duration;
  final bool showSpinner;
  final bool isSuccess;

  const WaitToCertWidget({
    super.key,
    required this.label,
    required this.duration,
    this.showSpinner = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    // This widget is not clickable, so we don't use ProfileActionButton
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: scaleSize(buttonSize),
          width: scaleSize(buttonSize),
          decoration: BoxDecoration(
            color: showSpinner
                ? Colors.blue.withValues(alpha: 0.2)
                : isSuccess
                ? Colors.green.withValues(alpha: 0.15)
                : const Color(0xffFFD58D).withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: showSpinner
                ? Center(
                    child: SizedBox(
                      width: scaleSize(buttonSize * 0.5),
                      height: scaleSize(buttonSize * 0.5),
                      child: CircularProgressIndicator(strokeWidth: scaleSize(3), color: Colors.blue),
                    ),
                  )
                : isSuccess
                ? Center(
                    child: Icon(Icons.check_circle, size: scaleSize(buttonSize * 0.6), color: Colors.green),
                  )
                : Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(scaleSize(4)),
                        child: Opacity(opacity: 0.6, child: Image.asset('assets/gecko_certify.png')),
                      ),
                      // Light grey overlay to show disabled state
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.25), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        ScaledSizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: scaledTextStyle(
            fontSize: buttonFontSize - 4,
            fontWeight: FontWeight.w400,
            color: showSpinner
                ? Colors.blue
                : isSuccess
                ? Colors.green[700]
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
