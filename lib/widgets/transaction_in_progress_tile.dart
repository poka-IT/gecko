import 'dart:async';
import 'dart:convert';

import 'package:durt2/durt2.dart' hide Provider;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/bottom_app_bar_provider.dart';

import 'package:gecko/utils.dart';
import 'package:gecko/widgets/buttons/primary_button.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:gecko/widgets/transaction_state_icon.dart';
import 'package:gecko/providers/trm_data_provider.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';
import 'package:gecko/widgets/safe_fade_and_translate.dart';

// Static cache to preserve transaction status across widget reconstructions
class TransactionStatusCache {
  static final Map<String, TransactionStatus> _cache = {};
  // Map temporary keys to real transaction hashes
  static final Map<String, String> _temporaryToRealKeyMap = {};

  static String _generateKey(TransactionInProgressData data) {
    // Use the real transaction ID if available, otherwise fall back to a temporary key
    if (data.transactionId != null && data.transactionId!.isNotEmpty) {
      return data.transactionId!;
    }
    // Fallback for when transaction ID is not yet available
    return '${data.status.hashCode}_${data.toAddress}_${data.amount}_${data.comment}';
  }

  static String _generateTemporaryKey(TransactionInProgressData data) {
    // Always generate the temporary key format
    return '${data.status.hashCode}_${data.toAddress}_${data.amount}_${data.comment}';
  }

  static TransactionStatus? getLastKnownStatus(TransactionInProgressData data) {
    final key = _generateKey(data);

    // If it's a temporary key, check if we have a mapping to a real hash
    if (data.transactionId == null || data.transactionId!.isEmpty) {
      final realKey = _temporaryToRealKeyMap[key];
      if (realKey != null) {
        return _cache[realKey];
      }
    }

    return _cache[key];
  }

  static void setLastKnownStatus(TransactionInProgressData data, TransactionStatus status) {
    final key = _generateKey(data);
    _cache[key] = status;
  }

  static void migrateToRealHash(TransactionInProgressData oldData, TransactionInProgressData newData) {
    // If we're moving from temporary key to real hash, migrate the cache entry
    if (oldData.transactionId == null && newData.transactionId != null) {
      final tempKey = _generateTemporaryKey(oldData);
      final realKey = newData.transactionId!;

      // Create mapping from temporary key to real key for future lookups
      _temporaryToRealKeyMap[tempKey] = realKey;

      // Copy status from temporary key to real hash key
      final status = _cache[tempKey];
      if (status != null) {
        _cache[realKey] = status;
        // Remove the temporary key entry
        _cache.remove(tempKey);
      }
    }
  }

  static bool isTransactionComplete(TransactionInProgressData data) {
    final key = _generateKey(data);
    TransactionStatus? cachedStatus = _cache[key];

    // If it's a temporary key, check if we have a mapping to a real hash
    if ((data.transactionId == null || data.transactionId!.isEmpty) && cachedStatus == null) {
      final realKey = _temporaryToRealKeyMap[key];
      if (realKey != null) {
        cachedStatus = _cache[realKey];
      }
    }

    // Transaction is complete only if it's in a truly final state
    return cachedStatus != null && _isTrulyFinalStatus(cachedStatus);
  }

  static bool _isTrulyFinalStatus(TransactionStatus status) {
    return status.state == TransactionState.finalized ||
        status.state == TransactionState.error ||
        status.state == TransactionState.timeout ||
        status.state == TransactionState.none;
  }

  static void clearCache() {
    _cache.clear();
    _temporaryToRealKeyMap.clear();
  }
}

// StateNotifier pour gérer l'état de la copie
class CopyStateNotifier extends StateNotifier<bool> {
  Timer? _timer;

  CopyStateNotifier() : super(false);

  void setCopied() {
    _timer?.cancel();

    state = true;
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        state = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Provider pour l'état de la copie
final copyStateProvider = StateNotifierProvider<CopyStateNotifier, bool>((ref) {
  return CopyStateNotifier();
});

class TransactionInProgressTule extends ConsumerStatefulWidget {
  const TransactionInProgressTule({super.key, required this.transactionData});

  final TransactionInProgressData transactionData;

  @override
  ConsumerState<TransactionInProgressTule> createState() => _TransactionInProgressTuleState();
}

class _TransactionInProgressTuleState extends ConsumerState<TransactionInProgressTule> {
  StreamSubscription<TransactionStatus>? _subscription;
  TransactionStatus _status = TransactionStatus(state: TransactionState.pending);
  bool _isVisible = true;
  bool _errorSnackbarShown = false;
  TransactionInProgressData _currentTransactionData;

  _TransactionInProgressTuleState()
    : _currentTransactionData = const TransactionInProgressData(
        status: Stream.empty(),
        toAddress: '',
        amount: 0,
        comment: '',
      );

  @override
  void initState() {
    super.initState();
    _currentTransactionData = widget.transactionData;

    // Check if this transaction is already complete
    if (TransactionStatusCache.isTransactionComplete(_currentTransactionData)) {
      final cachedStatus = TransactionStatusCache.getLastKnownStatus(_currentTransactionData);
      if (cachedStatus != null) {
        _status = cachedStatus;
        _isVisible = false;
        return;
      }
    }

    // Initialize with last known status if available
    final lastKnownStatus = TransactionStatusCache.getLastKnownStatus(_currentTransactionData);
    if (lastKnownStatus != null) {
      _status = lastKnownStatus;
    }

    _subscription = widget.transactionData.status.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });

        // Update the transaction data with the real transaction ID from the status
        if (status.hash != null && status.hash!.isNotEmpty && _currentTransactionData.transactionId == null) {
          final oldTransactionData = _currentTransactionData;
          _currentTransactionData = TransactionInProgressData(
            status: _currentTransactionData.status,
            toAddress: _currentTransactionData.toAddress,
            amount: _currentTransactionData.amount,
            comment: _currentTransactionData.comment,
            transactionId: status.hash,
          );

          // Migrate cache entry from temporary key to real hash
          TransactionStatusCache.migrateToRealHash(oldTransactionData, _currentTransactionData);
        }

        // Always cache the current status with the updated transaction data
        TransactionStatusCache.setLastKnownStatus(_currentTransactionData, status);

        // Hide tile only for truly final states
        if (status.state == TransactionState.finalized ||
            status.state == TransactionState.error ||
            status.state == TransactionState.timeout) {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    // Fermer la snackbar si elle est affichée quand le widget est disposé
    if (_errorSnackbarShown) {
      ScaffoldMessenger.of(homeContext).hideCurrentSnackBar();
    }
    super.dispose();
  }

  String _generateErrorReport(String? errorMessage, dynamic fromWallet, TransactionInProgressData transactionData) {
    final timestamp = DateTime.now().toIso8601String();

    final errorReport = {
      'timestamp': timestamp,
      'error': {'message': errorMessage ?? 'Unknown error occurred', 'type': 'transaction_error'},
      'transaction': {
        'from_address': fromWallet?.address ?? 'Unknown',
        'to_address': transactionData.toAddress,
        'amount': transactionData.amount * -1,
        'comment': transactionData.comment.isEmpty ? null : transactionData.comment,
      },
      'context': {
        'app_version': 'Ğecko $appVersion',
        'duniter_endpoint': Networks.duniterEndpoint,
        'squid_endpoint': Networks.squidEndpoint,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(errorReport);
  }

  void _copyErrorReport(String? errorMessage, dynamic fromWallet, TransactionInProgressData transactionData) {
    final jsonReport = _generateErrorReport(errorMessage, fromWallet, transactionData);
    Clipboard.setData(ClipboardData(text: jsonReport));

    // Change icon to indicate success using Riverpod
    ref.read(copyStateProvider.notifier).setCopied();
  }

  void _showTransactionErrorDetails({
    required BuildContext context,
    required String? errorMessage,
    required WalletEntity? fromWallet,
    required TransactionInProgressData transactionData,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                SizedBox(height: 20),
                // Title
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'transactionFailedTitle'.tr(),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Error details with copy button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('errorDetails'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Consumer(
                      builder: (context, ref, child) {
                        final isCopied = ref.watch(copyStateProvider);
                        return InkWell(
                          onTap: () => _copyErrorReport(errorMessage, fromWallet, transactionData),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCopied ? Icons.check : Icons.copy,
                                  size: 14,
                                  color: isCopied ? Colors.green[600] : Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isCopied ? 'copied'.tr() : 'copy'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCopied ? Colors.green[600] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    errorMessage ?? 'Unknown error occurred',
                    style: TextStyle(fontSize: 14, fontFamily: 'Monospace', color: Colors.red[800]),
                  ),
                ),
                SizedBox(height: 20),
                // Transaction details
                Text('transactionDetails'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fromWallet == null ? 'From: Unknown' : 'From: ${getShortPubkey(fromWallet.address)}'),
                      SizedBox(height: 4),
                      Text('To: ${getShortPubkey(transactionData.toAddress)}'),
                      SizedBox(height: 4),
                      Text('Amount: ${transactionData.amount * -1}'),
                      if (transactionData.comment.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text('Comment: ${transactionData.comment}'),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Close button using PrimaryButton widget
                PrimaryButton(onPressed: () => Navigator.of(context).pop(), label: 'close'.tr()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == TransactionStatus(state: TransactionState.none)) {
      return const SizedBox.shrink();
    }

    String humanStatus = '';
    final finalAmount = _currentTransactionData.amount * -1;

    if (_status.state == TransactionState.finalized) {
      // This part is for the text, but the tile will start disappearing.
      humanStatus = 'extrinsicValidated'.tr(args: [actionMap['pay']!]);
    } else if (_status.state == TransactionState.error) {
      humanStatus = errorTransactionMap[_status.errorMessage] ?? _status.errorMessage!;

      // N'afficher la snackbar qu'une seule fois par erreur
      if (!_errorSnackbarShown) {
        _errorSnackbarShown = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final errorMessage = _status.errorMessage;
            // Sauvegarder les valeurs nécessaires pour éviter d'utiliser ref dans les callbacks
            final fromWallet = ref.read(walletServiceProvider).defaultWallet;
            final transactionData = _currentTransactionData;

            ScaffoldMessenger.of(homeContext).hideCurrentSnackBar();

            // Calculate bottom margin based on bottom app bar visibility
            final container = ProviderScope.containerOf(homeContext);
            final bottomBarState = container.read(bottomAppBarProvider);
            final isBottomBarVisible = bottomBarState.isBottomBarActuallyVisible;
            final bottomMargin = isBottomBarVisible
                ? scaleSize(67) + 16.0
                : 16.0; // Bottom bar height + standard margin

            ScaffoldMessenger.of(homeContext).showSnackBar(
              SnackBar(
                content: GestureDetector(
                  onTap: () {
                    // Close the SnackBar first
                    ScaffoldMessenger.of(homeContext).hideCurrentSnackBar();
                    // Then show the error details
                    _showTransactionErrorDetails(
                      context: homeContext,
                      errorMessage: errorMessage,
                      fromWallet: fromWallet,
                      transactionData: transactionData,
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'transactionFailed'.tr(),
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'tapForDetails'.tr(),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.info_outline, color: Colors.white.withValues(alpha: 0.7), size: 12),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _status = TransactionStatus(state: TransactionState.none);
                            ScaffoldMessenger.of(homeContext).hideCurrentSnackBar();
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                backgroundColor: Colors.red[700],
                duration: Duration(days: 365), // Persist indefinitely
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottomMargin),
              ),
            );
          }
        });
      }
    } else {
      humanStatus = statusStatusMap[_status.state] ?? 'Unknown status: ${_status.state}';
    }

    final statusIcon = TransactionStateIcon(_status.state, size: scaleSize(14), stroke: 2);

    return SafeFadeAndTranslate(
      visible: _isVisible,
      translate: const Offset(0, -40),
      delay: const Duration(seconds: 2),
      duration: const Duration(milliseconds: 700),
      onCompleted: () {
        ref.invalidate(transactionHistoryProvider(_currentTransactionData.toAddress));
        _status = TransactionStatus(state: TransactionState.none);
        // Cache the final 'none' status to prevent reappearance
        TransactionStatusCache.setLastKnownStatus(_currentTransactionData, _status);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(scaleSize(12)),
          border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.3), width: 2),
        ),
        child: Material(
          color: context.colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(scaleSize(12)),
          child: Padding(
            padding: EdgeInsets.all(scaleSize(12)),
            child: Row(
              children: [
                // Avatar
                DatapodAvatar(address: _currentTransactionData.toAddress, size: scaleSize(40)),

                ScaledSizedBox(width: 12),

                // Main content area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top row: Address and Amount
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Address and optionally identity name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Identity name if available
                                Consumer(
                                  builder: (context, ref, child) {
                                    final identityName = ref.watch(
                                      identityNameProvider(_currentTransactionData.toAddress),
                                    );

                                    return identityName.when(
                                      data: (name) {
                                        if (name != null && name.isNotEmpty) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: scaledTextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: context.colorScheme.onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              ScaledSizedBox(height: 2),
                                              Text(
                                                getShortPubkey(_currentTransactionData.toAddress),
                                                style: scaledTextStyle(
                                                  fontSize: 13,
                                                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          );
                                        } else {
                                          // No identity name, show only address
                                          return Text(
                                            getShortPubkey(_currentTransactionData.toAddress),
                                            style: scaledTextStyle(
                                              fontSize: 16,
                                              color: context.colorScheme.onSurface.withValues(alpha: 1.0),
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }
                                      },
                                      loading: () => Text(
                                        getShortPubkey(_currentTransactionData.toAddress),
                                        style: scaledTextStyle(
                                          fontSize: 16,
                                          color: context.colorScheme.onSurface.withValues(alpha: 1.0),
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      error: (_, _) => Text(
                                        getShortPubkey(_currentTransactionData.toAddress),
                                        style: scaledTextStyle(
                                          fontSize: 16,
                                          color: context.colorScheme.onSurface.withValues(alpha: 1.0),
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),

                                // Status with icon - inline after address
                                ScaledSizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Status icon
                                    statusIcon,
                                    ScaledSizedBox(width: 6),
                                    // Status text
                                    Expanded(
                                      child: Text(
                                        humanStatus,
                                        style: scaledTextStyle(
                                          fontSize: 13,
                                          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                // Comment with arrow - inline after status if comment exists
                                if (_currentTransactionData.comment.isNotEmpty) ...[
                                  ScaledSizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Direction arrow
                                      Icon(
                                        Icons.call_made, // Always outgoing for transaction in progress
                                        size: scaleSize(14),
                                        color: Colors.blue,
                                      ),
                                      ScaledSizedBox(width: 6),
                                      // Comment text
                                      Expanded(
                                        child: Text(
                                          _currentTransactionData.comment,
                                          style: scaledTextStyle(
                                            fontSize: 13,
                                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          ScaledSizedBox(width: 12),

                          // Right: Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Amount
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    finalAmount.toString(),
                                    style: scaledTextStyle(
                                      fontSize: 16,
                                      color: context.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  ScaledSizedBox(width: 4),
                                  Text(
                                    ref.watch(currencySymbolProvider),
                                    style: scaledTextStyle(
                                      fontSize: 13,
                                      color: context.colorScheme.primary.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              ScaledSizedBox(height: 4),

                              // Status badge
                              Container(
                                width: scaleSize(80),
                                padding: EdgeInsets.symmetric(horizontal: scaleSize(6), vertical: scaleSize(2)),
                                decoration: BoxDecoration(
                                  color:
                                      (_status.state == TransactionState.inBlock ||
                                          _status.state == TransactionState.finalized)
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : context.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(scaleSize(4)),
                                  border: Border.all(
                                    color:
                                        (_status.state == TransactionState.inBlock ||
                                            _status.state == TransactionState.finalized)
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : context.colorScheme.primary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  (_status.state == TransactionState.inBlock ||
                                          _status.state == TransactionState.finalized)
                                      ? 'validated'.tr()
                                      : 'transactionInProgress'.tr(),
                                  textAlign: TextAlign.center,
                                  style: scaledTextStyle(
                                    fontSize: 10,
                                    color:
                                        (_status.state == TransactionState.inBlock ||
                                            _status.state == TransactionState.finalized)
                                        ? Colors.green
                                        : context.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
