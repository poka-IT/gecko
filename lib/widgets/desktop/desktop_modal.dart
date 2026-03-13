import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';

/// Predefined sizes for desktop modals
enum DesktopModalSize {
  /// 420px wide — PIN entry, simple confirmations
  small(420),

  /// 600px wide — forms, options, settings
  medium(600),

  /// 800px wide — profiles, activity, complex views
  large(800),

  /// 1000px wide — multi-panel views
  extraLarge(1000);

  const DesktopModalSize(this.width);
  final double width;
}

/// Shows a desktop modal dialog with consistent glass-card styling.
///
/// Returns a [Future] that completes with the value passed to [Navigator.pop],
/// or null if dismissed.
Future<T?> showDesktopModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  DesktopModalSize size = DesktopModalSize.medium,
  bool barrierDismissible = true,
  String? title,
  bool showCloseButton = true,
  EdgeInsets? contentPadding,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(curved), child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return _DesktopModalShell<T>(
        size: size,
        title: title,
        showCloseButton: showCloseButton,
        contentPadding: contentPadding,
        builder: builder,
      );
    },
  );
}

class _DesktopModalShell<T> extends StatelessWidget {
  final DesktopModalSize size;
  final String? title;
  final bool showCloseButton;
  final EdgeInsets? contentPadding;
  final WidgetBuilder builder;

  const _DesktopModalShell({
    required this.size,
    required this.title,
    required this.showCloseButton,
    required this.contentPadding,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = contentPadding ?? const EdgeInsets.all(24);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop()},
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.width, maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colorScheme.surface.withValues(alpha: 0.95),
                            context.colorScheme.surfaceContainer.withValues(alpha: 0.88),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null || showCloseButton) _buildHeader(context),
                          Flexible(
                            child: Padding(padding: effectivePadding, child: builder(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          if (showCloseButton)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close_rounded, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}
