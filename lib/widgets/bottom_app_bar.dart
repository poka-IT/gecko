// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:provider/provider.dart';

class GeckoBottomAppBar extends StatefulWidget {
  const GeckoBottomAppBar({super.key, this.actualRoute = ''});
  final String actualRoute;

  @override
  State<GeckoBottomAppBar> createState() => _GeckoBottomAppBarState();
}

class _GeckoBottomAppBarState extends State<GeckoBottomAppBar> with WidgetsBindingObserver {
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Check if widget is still mounted
    if (!mounted) return;

    try {
      // Safe access to viewInsets without context dependency
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return;

      final viewInsets = views.first.viewInsets;
      final bool keyboardVisible = viewInsets.bottom > 0;

      if (_isKeyboardVisible != keyboardVisible) {
        if (mounted) {
          setState(() {
            _isKeyboardVisible = keyboardVisible;
          });
        }
      }
    } catch (e) {
      // Silently handle any access errors during widget disposal
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final historyProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    final size = MediaQuery.of(context).size;
    final bool showBottomBar = !_isKeyboardVisible; // Hide when keyboard is visible
    final lockAction = widget.actualRoute == 'safeHome';

    return Visibility(
      visible: showBottomBar,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: context.colorScheme.tertiary,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), offset: const Offset(0, -4), blurRadius: 10),
            ],
          ),
          width: size.width,
          height: scaleSize(67),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                key: keyAppBarHome,
                icon: Icons.home_outlined,
                isSelected: false,
                onTap: () {
                  searchProvider.reload();
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                },
              ),
              _buildNavItem(
                key: keyAppBarQrcode,
                imagePath: 'assets/qrcode-scan.png',
                isSelected: widget.actualRoute == 'scan',
                onTap: () async {
                  historyProvider.scan(context);
                },
              ),
              _buildNavItem(
                key: keyAppBarSafe,
                imagePath: 'assets/wallet.png',
                isSelected: widget.actualRoute == 'wallet' || lockAction,
                isDisabled: lockAction,
                onTap: lockAction
                    ? null
                    : () async {
                        if (!await myWalletProvider.askPinCode()) return;

                        Navigator.pushNamedAndRemoveUntil(context, '/mywallets', ModalRoute.withName('/'));
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Key key,
    required bool isSelected,
    required VoidCallback? onTap,
    IconData? icon,
    String? imagePath,
    bool isDisabled = false,
  }) {
    // Use local context instead of homeContext to avoid deactivated widget errors
    final color = isSelected
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)
        : Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.8);
    final size = scaleSize(34);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: isDisabled
            ? null
            : () {
                // Safe execution of onTap callback
                if (mounted && onTap != null) {
                  onTap();
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(scaleSize(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5) : Colors.transparent,
          ),
          child: icon != null
              ? Icon(icon, size: size, color: color)
              : Image.asset(imagePath!, height: size, width: size, color: color),
        ),
      ),
    );
  }
}
