import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';
import 'package:gecko/services/diagnostic_service.dart';

// Provider for copy state indication
final versionCopyStateProvider = NotifierProvider<VersionCopyStateNotifier, bool>(VersionCopyStateNotifier.new);

class VersionCopyStateNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setCopied() {
    state = true;
    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      state = false;
    });
  }
}

class VersionOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const VersionOverlay({super.key, required this.child});

  @override
  ConsumerState<VersionOverlay> createState() => _VersionOverlayState();
}

class _VersionOverlayState extends ConsumerState<VersionOverlay> {
  String _generateDiagnosticReport() {
    return DiagnosticService.instance.generateDiagnosticReport(context: context, ref: ref);
  }

  void _copyDiagnosticReport() {
    final jsonReport = _generateDiagnosticReport();
    Clipboard.setData(ClipboardData(text: jsonReport));

    // Change state to indicate success
    ref.read(versionCopyStateProvider.notifier).setCopied();

    // Show a brief snackbar via navigator context (this widget is above the Scaffold)
    final navCtx = Gecko.navigatorContext;
    if (navCtx != null) {
      ScaffoldMessenger.of(
        navCtx,
      ).showSnackBar(SnackBar(content: Text('diagnosticCopied'.tr()), duration: const Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to avoid system navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isCopied = ref.watch(versionCopyStateProvider);

    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 4 + bottomPadding,
          left: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onLongPress: _copyDiagnosticReport,
            child: Opacity(
              opacity: isCopied ? 0.8 : 0.3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isCopied ? context.geckoColors.success.withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'v$appVersion',
                  style: TextStyle(
                    fontSize: 8,
                    color: isCopied ? context.geckoColors.success : Colors.grey,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
