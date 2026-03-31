import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/screens/settings/tabs/advanced_tab.dart';
import 'package:gecko/screens/settings/tabs/appearance_tab.dart';
import 'package:gecko/screens/settings/tabs/general_tab.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class SettingsScreen extends StatelessWidget {
  /// When true, renders without Scaffold/AppBar (for embedding in desktop modal).
  final bool embeddedMode;

  const SettingsScreen({super.key, this.embeddedMode = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: embeddedMode ? const _EmbeddedSettingsBody() : const _FullSettingsBody(),
    );
  }
}

TabBar _buildTabBar() {
  return TabBar(
    labelStyle: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: scaledTextStyle(fontSize: 14),
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: Colors.transparent,
    tabs: [
      Tab(text: 'appearance'.tr()),
      Tab(text: 'generalSettings'.tr()),
      Tab(text: 'advanced'.tr()),
    ],
  );
}

const _tabBarView = TabBarView(children: [AppearanceTab(), GeneralTab(), AdvancedTab()]);

/// Full-screen mode with Scaffold + AppBar (mobile).
class _FullSettingsBody extends StatelessWidget {
  const _FullSettingsBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GeckoAppBar('parameters'.tr(), bottom: _buildTabBar()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: _tabBarView),
        ),
      ),
    );
  }
}

/// Embedded mode without Scaffold (desktop modal).
class _EmbeddedSettingsBody extends StatelessWidget {
  const _EmbeddedSettingsBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: _tabBarView),
          ),
        ),
      ],
    );
  }
}
