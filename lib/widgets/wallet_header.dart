// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/models/wallet_header_data.dart';

class WalletHeader extends StatefulWidget {
  const WalletHeader({
    super.key,
    required this.address,
    this.customImagePath,
    this.defaultImagePath,
  });

  final String address;
  final String? customImagePath;
  final String? defaultImagePath;

  @override
  State<WalletHeader> createState() => _WalletHeaderState();
}

class _WalletHeaderState extends State<WalletHeader> {
  late Future<WalletHeaderData> _loadData;
  bool _isPickerOpen = false;
  String _newCustomImagePath = '';

  @override
  void initState() {
    super.initState();
    _loadData = _initializeData();
  }

  Future<WalletHeaderData> _initializeData() async {
    // Check cache from Hive
    final cached = walletHeaderDataBox.get(widget.address);
    if (cached != null) {
      // Refresh in background
      _refreshData();
      return cached;
    }

    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    // Load all data in parallel with proper typing
    final (idtyStatus, balance, certData) = await (
      sub.idtyStatus(widget.address),
      sub.getBalance(widget.address),
      sub.getCertsCounter(widget.address),
    ).wait;

    final data = WalletHeaderData(
      hasIdentity: idtyStatus != IdtyStatus.none,
      isOwner: myWalletProvider.isOwner(widget.address),
      walletName: duniterIndexer.walletNameIndexer[widget.address],
      balance: BigInt.from(balance.transferableBalance),
      certCount: certData,
    );

    // Save to Hive cache
    await walletHeaderDataBox.put(widget.address, data);
    return data;
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    // Load all data in parallel with proper typing
    final (idtyStatus, balance, certData) = await (
      sub.idtyStatus(widget.address),
      sub.getBalance(widget.address),
      sub.getCertsCounter(widget.address),
    ).wait;

    final data = WalletHeaderData(
      hasIdentity: idtyStatus != IdtyStatus.none,
      isOwner: myWalletProvider.isOwner(widget.address),
      walletName: duniterIndexer.walletNameIndexer[widget.address],
      balance: BigInt.from(balance.transferableBalance),
      certCount: certData,
    );

    final existing = walletHeaderDataBox.get(widget.address);
    if (existing == null || !existing.equals(data)) {
      await walletHeaderDataBox.put(widget.address, data);
      if (mounted) {
        setState(() {
          _loadData = Future.value(data);
        });
      }
    }
  }

  Widget _buildContent(BuildContext context, BigInt currentWalletBalance, bool hasIdentity, bool isOwner, bool isPickerOpen, String newCustomImagePath,
      DuniterIndexer duniterIndexer) {
    const double avatarSize = 90;
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    Provider.of<SubstrateSdk>(context); //To refresh header color on block changes

    final balance = walletOptions.balanceCache[widget.address] == null ? currentWalletBalance : BigInt.from(walletOptions.balanceCache[widget.address] ?? 0);

    final isEmptyWallet = balance == BigInt.zero;

    return Container(
      decoration: BoxDecoration(
        color: isEmptyWallet ? Colors.grey[300] : headerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.only(
        left: scaleSize(16),
        right: scaleSize(16),
        bottom: scaleSize(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar section
          Container(
            width: scaleSize(90),
            height: scaleSize(90),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<WalletOptionsProvider>(
              builder: (context, walletOptionsProvider, child) {
                if (_newCustomImagePath.isEmpty) {
                  _newCustomImagePath = widget.customImagePath ?? '';
                }
                return Stack(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isOwner && !_isPickerOpen
                            ? () async {
                                setState(() => _isPickerOpen = true);
                                walletOptionsProvider.reload();
                                final newPath = await walletOptionsProvider.changeAvatar();
                                setState(() {
                                  _newCustomImagePath = newPath;
                                  _isPickerOpen = false;
                                });
                                walletOptionsProvider.reload();
                              }
                            : null,
                        customBorder: const CircleBorder(),
                        child: ClipOval(
                          child: _newCustomImagePath.isEmpty
                              ? (widget.defaultImagePath != null
                                  ? Image.asset(
                                      'assets/avatars/${widget.defaultImagePath}',
                                      fit: BoxFit.cover,
                                    )
                                  : DatapodAvatar(
                                      address: widget.address,
                                      size: avatarSize,
                                    ))
                              : Image.file(
                                  File(_newCustomImagePath),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    if (isOwner)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: avatarSize * 0.35,
                          height: avatarSize * 0.35,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: !_isPickerOpen
                                  ? () async {
                                      setState(() => _isPickerOpen = true);
                                      walletOptionsProvider.reload();
                                      final newPath = await walletOptionsProvider.changeAvatar();
                                      setState(() {
                                        _newCustomImagePath = newPath;
                                        _isPickerOpen = false;
                                      });
                                      walletOptionsProvider.reload();
                                    }
                                  : null,
                              customBorder: const CircleBorder(),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: avatarSize * 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          SizedBox(width: scaleSize(20)),

          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address row
                GestureDetector(
                  key: keyCopyAddress,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.address));
                    snackCopyKey(context);
                  },
                  child: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            getShortPubkey(widget.address),
                            style: scaledTextStyle(
                              fontSize: 20,
                              fontFamily: 'Monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: scaleSize(14)),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.copy,
                          size: scaleSize(20),
                          color: orangeC.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.address));
                          snackCopyKey(context);
                        },
                      ),
                    ],
                  ),
                ),
                ScaledSizedBox(height: 8),

                // Balance
                Balance(address: widget.address, size: 18),

                // Certifications section
                ScaledSizedBox(height: 12),
                Visibility(
                  visible: hasIdentity,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      PageNoTransit(
                        builder: (context) => CertificationsScreen(
                          address: widget.address,
                          username: duniterIndexer.walletNameIndexer[widget.address] ?? '',
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.transparent,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IdentityStatus(
                              address: widget.address,
                              color: orangeC,
                            ),
                            SizedBox(width: scaleSize(8)),
                            Certifications(
                              address: widget.address,
                              size: 13,
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: scaleSize(15),
                              color: orangeC.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader() {
    const double avatarSize = 90;
    return Container(
      color: headerColor,
      padding: EdgeInsets.only(
        left: scaleSize(16),
        right: scaleSize(16),
        bottom: scaleSize(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar placeholder
          Container(
            width: scaleSize(avatarSize),
            height: scaleSize(avatarSize),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: scaleSize(20)),

          // Info section placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address placeholder
                Row(
                  children: [
                    Container(
                      width: scaleSize(150),
                      height: scaleSize(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    SizedBox(width: scaleSize(14)),
                    Container(
                      width: scaleSize(20),
                      height: scaleSize(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
                ScaledSizedBox(height: 8),

                // Balance placeholder
                Container(
                  width: scaleSize(120),
                  height: scaleSize(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),

                // Certifications placeholder
                ScaledSizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: scaleSize(20),
                      height: scaleSize(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    SizedBox(width: scaleSize(8)),
                    Container(
                      width: scaleSize(80),
                      height: scaleSize(13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Container(
                      width: scaleSize(15),
                      height: scaleSize(15),
                      margin: EdgeInsets.only(left: scaleSize(4)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    // If data is in cache, show it immediately
    final cached = walletHeaderDataBox.get(widget.address);
    if (cached != null) {
      return _buildContent(
        context,
        cached.balance,
        cached.hasIdentity,
        cached.isOwner,
        _isPickerOpen,
        _newCustomImagePath,
        duniterIndexer,
      );
    }

    // Sinon on affiche le loading
    return FutureBuilder<WalletHeaderData>(
      future: _loadData,
      builder: (context, AsyncSnapshot<WalletHeaderData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingHeader();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        return _buildContent(
          context,
          data.balance,
          data.hasIdentity,
          data.isOwner,
          _isPickerOpen,
          _newCustomImagePath,
          duniterIndexer,
        );
      },
    );
  }
}
