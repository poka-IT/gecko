import 'dart:async';

import 'package:durt2/durt2.dart' as d show ConnectionStatus, Durt, IdentitySuggestion, WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/main.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/screens/profile_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_by_address.dart';

class GlobalSearchPaletteDialog extends ConsumerStatefulWidget {
  const GlobalSearchPaletteDialog({super.key});

  @override
  ConsumerState<GlobalSearchPaletteDialog> createState() => _GlobalSearchPaletteDialogState();
}

class _GlobalSearchPaletteDialogState extends ConsumerState<GlobalSearchPaletteDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _resultsScrollController;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchTextProvider));
    _focusNode = FocusNode(debugLabel: 'global_search_palette');
    _resultsScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _resultsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchTextProvider).trim();
    final squidStatus = ref.watch(squidConnectionStatusProvider);
    final walletResultsAsync = ref.watch(searchResultsProvider);
    final identityResultsAsync = query.length >= 2 && squidStatus == d.ConnectionStatus.connected
        ? ref.watch(searchIdentityProvider(query))
        : const AsyncValue<List<d.IdentitySuggestion>>.data([]);
    final entries = _buildEntries(
      walletResultsAsync.asData?.value ?? const <G1WalletsList>[],
      identityResultsAsync.asData?.value ?? const <d.IdentitySuggestion>[],
    );

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.42),
          child: SafeArea(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.97, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: GestureDetector(
                  onTap: () {},
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colorScheme.surface.withValues(alpha: 0.98),
                            context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 48,
                            offset: const Offset(0, 26),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 14),
                            _buildSearchField(context, entries),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.colorScheme.surface.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.05)),
                                ),
                                child: _buildResultsPane(
                                  context,
                                  query: query,
                                  walletResultsAsync: walletResultsAsync,
                                  identityResultsAsync: identityResultsAsync,
                                  entries: entries,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'search'.tr(),
                style: scaledTextStyle(fontSize: 18, color: context.colorScheme.onSurface, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '⌘K',
                style: scaledTextStyle(
                  fontSize: 11,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _close,
          style: IconButton.styleFrom(
            backgroundColor: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
            foregroundColor: context.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, List<_PaletteSearchEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _close,
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _moveSelection(1, entries),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => _moveSelection(-1, entries),
          const SingleActivator(LogicalKeyboardKey.enter): () => _openHighlightedOrFirstResult(entries),
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            ref.read(searchTextProvider.notifier).set(value);
            setState(() {
              _highlightedIndex = -1;
            });
          },
          onSubmitted: (_) => _openFirstResult(),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'desktopSearchIdentityPlaceholder'.tr(),
            hintStyle: scaledTextStyle(
              fontSize: 15,
              color: context.colorScheme.onSurface.withValues(alpha: 0.36),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: context.colorScheme.primary, size: 22),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchTextProvider.notifier).clear();
                      _focusNode.requestFocus();
                      setState(() {});
                    },
                    icon: Icon(Icons.close_rounded, color: context.colorScheme.onSurface.withValues(alpha: 0.56)),
                  ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          ),
          style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _openFirstResult() async {
    final directEntries = _buildEntries(
      await ref.read(searchResultsProvider.future),
      ref.read(squidConnectionStatusProvider) == d.ConnectionStatus.connected
          ? await ref.read(searchIdentityProvider(_controller.text.trim()).future)
          : const <d.IdentitySuggestion>[],
    );
    if (directEntries.isNotEmpty) {
      _openEntry(directEntries.first);
      return;
    }

    final query = _controller.text.trim();
    if (query.length < 2) return;

    final walletResults = await ref.read(searchResultsProvider.future);
    if (walletResults.isNotEmpty) {
      final first = walletResults.first;
      _openProfile(address: first.address, username: first.username);
      return;
    }

    final squidStatus = ref.read(squidConnectionStatusProvider);
    if (squidStatus != d.ConnectionStatus.connected) return;

    final identities = await ref.read(searchIdentityProvider(query).future);
    if (identities.isNotEmpty) {
      final first = identities.first;
      _openProfile(address: first.address, username: first.name);
    }
  }

  void _openHighlightedOrFirstResult(List<_PaletteSearchEntry> entries) {
    if (entries.isEmpty) {
      unawaited(_openFirstResult());
      return;
    }
    final index = _highlightedIndex >= 0 && _highlightedIndex < entries.length ? _highlightedIndex : 0;
    _openEntry(entries[index]);
  }

  void _moveSelection(int delta, List<_PaletteSearchEntry> entries) {
    if (entries.isEmpty) return;

    setState(() {
      final next = _highlightedIndex + delta;
      if (_highlightedIndex == -1) {
        _highlightedIndex = delta > 0 ? 0 : entries.length - 1;
      } else if (next < 0) {
        _highlightedIndex = entries.length - 1;
      } else if (next >= entries.length) {
        _highlightedIndex = 0;
      } else {
        _highlightedIndex = next;
      }
    });

    if (_resultsScrollController.hasClients) {
      final offset = (_highlightedIndex * 76.0)
          .clamp(0.0, _resultsScrollController.position.maxScrollExtent)
          .toDouble();
      _resultsScrollController.animateTo(offset, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    }
  }

  List<_PaletteSearchEntry> _buildEntries(List<G1WalletsList> wallets, List<d.IdentitySuggestion> identities) {
    return [
      ...wallets.map(
        (wallet) => _PaletteSearchEntry(
          address: wallet.address,
          username: wallet.username,
          title: getShortPubkey(wallet.address),
          kind: _PaletteSearchEntryKind.wallet,
        ),
      ),
      ...identities.map(
        (identity) => _PaletteSearchEntry(
          address: identity.address,
          username: identity.name,
          title: getShortPubkey(identity.address),
          kind: _PaletteSearchEntryKind.identity,
        ),
      ),
    ];
  }

  Widget _buildResultsPane(
    BuildContext context, {
    required String query,
    required AsyncValue<List<G1WalletsList>> walletResultsAsync,
    required AsyncValue<List<d.IdentitySuggestion>> identityResultsAsync,
    required List<_PaletteSearchEntry> entries,
  }) {
    if (query.length < 2) {
      return _SearchPaletteHint(query: query);
    }

    if (walletResultsAsync.isLoading || identityResultsAsync.isLoading) {
      return const Center(child: Loading(stroke: 3, size: 28));
    }

    final walletResults = walletResultsAsync.asData?.value ?? const <G1WalletsList>[];
    final identityResults = identityResultsAsync.asData?.value ?? const <d.IdentitySuggestion>[];

    if (walletResults.isEmpty && identityResults.isEmpty) {
      return Center(
        child: Text(
          'noResult'.tr(),
          style: scaledTextStyle(
            fontSize: 14,
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    var runningIndex = 0;

    return ListView(
      controller: _resultsScrollController,
      padding: const EdgeInsets.all(12),
      children: [
        if (walletResults.isNotEmpty) ...[
          _ResultsSectionTitle(title: 'desktopWalletShortLabel'.tr()),
          const SizedBox(height: 8),
          ...walletResults.map((wallet) {
            final currentIndex = runningIndex++;
            return _WalletResultTile(
              wallet: wallet,
              isHighlighted: currentIndex == _highlightedIndex,
              onTapOverride: () => _openEntry(entries[currentIndex]),
            );
          }),
        ],
        if (identityResults.isNotEmpty) ...[
          if (walletResults.isNotEmpty) const SizedBox(height: 12),
          _ResultsSectionTitle(title: 'desktopIdentityShortLabel'.tr()),
          const SizedBox(height: 8),
          ...identityResults.map((identity) {
            final currentIndex = runningIndex++;
            return _IdentityResultTile(
              identity: identity,
              isHighlighted: currentIndex == _highlightedIndex,
              onTapOverride: () => _openEntry(entries[currentIndex]),
            );
          }),
        ],
      ],
    );
  }

  Future<void> _openEntry(_PaletteSearchEntry entry) async {
    await _openProfile(address: entry.address, username: entry.username);
  }

  Future<void> _openProfile({required String address, String? username}) async {
    final navigatorContext = Gecko.navigatorContext;
    _close(clearSearch: false);
    await WidgetsBinding.instance.endOfFrame;

    if (navigatorContext == null || !navigatorContext.mounted) {
      return;
    }

    await Navigator.of(navigatorContext, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfileViewScreen(address: address, username: username),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _close({bool clearSearch = true}) {
    if (clearSearch) {
      _controller.clear();
      ref.read(searchTextProvider.notifier).clear();
    }
    unawaited(Navigator.of(context, rootNavigator: true).maybePop());
  }
}

class _SearchPaletteHint extends StatelessWidget {
  const _SearchPaletteHint({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded, size: 34, color: context.colorScheme.onSurface.withValues(alpha: 0.28)),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'desktopSearchIdentityPlaceholder'.tr() : 'search'.tr(),
              textAlign: TextAlign.center,
              style: scaledTextStyle(
                fontSize: 14,
                color: context.colorScheme.onSurface.withValues(alpha: 0.48),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsSectionTitle extends StatelessWidget {
  const _ResultsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: scaledTextStyle(
          fontSize: 11,
          color: context.colorScheme.onSurface.withValues(alpha: 0.42),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _WalletResultTile extends ConsumerWidget {
  const _WalletResultTile({required this.wallet, required this.isHighlighted, this.onTapOverride});

  final G1WalletsList wallet;
  final bool isHighlighted;
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchResultTileShell(
      address: wallet.address,
      title: getShortPubkey(wallet.address),
      subtitle: NameByAddress(
        wallet: d.WalletEntity.create(
          address: wallet.address,
          name: wallet.username,
          keyPairType: d.Durt.defaultKeyPairType,
        ),
        size: 13,
      ),
      username: wallet.username,
      isHighlighted: isHighlighted,
      onTap:
          onTapOverride ??
          () {
            ref.read(searchTextProvider.notifier).clear();
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ProfileViewScreen(address: wallet.address, username: wallet.username),
                transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          },
    );
  }
}

class _IdentityResultTile extends ConsumerWidget {
  const _IdentityResultTile({required this.identity, required this.isHighlighted, this.onTapOverride});

  final d.IdentitySuggestion identity;
  final bool isHighlighted;
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchResultTileShell(
      address: identity.address,
      title: getShortPubkey(identity.address),
      subtitle: Text(
        identity.name,
        overflow: TextOverflow.ellipsis,
        style: scaledTextStyle(
          fontSize: 13,
          color: context.colorScheme.onSurface.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
        ),
      ),
      username: identity.name,
      isHighlighted: isHighlighted,
      onTap:
          onTapOverride ??
          () {
            ref.read(searchTextProvider.notifier).clear();
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ProfileViewScreen(address: identity.address, username: identity.name),
                transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          },
    );
  }
}

class _SearchResultTileShell extends StatelessWidget {
  const _SearchResultTileShell({
    required this.address,
    required this.title,
    required this.subtitle,
    required this.username,
    required this.isHighlighted,
    required this.onTap,
  });

  final String address;
  final String title;
  final Widget subtitle;
  final String? username;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? context.colorScheme.primary.withValues(alpha: 0.10)
                  : context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isHighlighted
                    ? context.colorScheme.primary.withValues(alpha: 0.24)
                    : context.colorScheme.outline.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                DatapodAvatar(address: address, size: 42, name: username),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: scaledTextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      subtitle,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Balance(address: address, size: 12, color: context.colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PaletteSearchEntryKind { wallet, identity }

class _PaletteSearchEntry {
  const _PaletteSearchEntry({required this.address, required this.username, required this.title, required this.kind});

  final String address;
  final String? username;
  final String title;
  final _PaletteSearchEntryKind kind;
}
