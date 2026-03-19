import 'dart:async';
import 'dart:math' hide log;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:gecko/services/diagnostic_service.dart';
import 'package:gecko/services/log_collection_service.dart';

/// Enhanced Sentry service that automatically includes diagnostic reports
/// with all error reports sent to Sentry
class SentryService {
  static SentryService? _instance;
  static SentryService get instance => _instance ??= SentryService._();

  SentryService._();

  static BuildContext? _currentContext;
  static WidgetRef? _currentRef;
  static bool _isInitialized = false;

  /// Generate a short UUID for manual reports to ensure uniqueness
  static String _generateShortUuid() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// Sanitize PII from Sentry tags. Truncates values that look like wallet addresses.
  static String _sanitizePii(String key, String value) {
    if (key.toLowerCase().contains('address') && value.length > 12) {
      return '${value.substring(0, 8)}...';
    }
    return value;
  }

  /// Recursively flatten diagnostic data and add ALL fields as Sentry tags
  /// This ensures that ANY field added to the diagnostic report will automatically
  /// be included in Sentry reports without modifying this service
  static void _flattenAndAddToScope(Scope scope, Map<String, dynamic> data, String prefix) {
    data.forEach((key, value) {
      final tagKey = '${prefix}_$key';

      if (value is Map<String, dynamic>) {
        // Recursively flatten nested maps
        _flattenAndAddToScope(scope, value, tagKey);
      } else if (value is List) {
        // Handle lists by converting to string or indexing items
        if (value.isEmpty) {
          scope.setTag('${tagKey}_count', '0');
        } else {
          scope.setTag('${tagKey}_count', value.length.toString());
          // Add first few items if they're simple values
          for (int i = 0; i < value.length && i < 5; i++) {
            final item = value[i];
            if (item is String || item is num || item is bool) {
              scope.setTag('${tagKey}_$i', item.toString());
            }
          }
        }
      } else {
        // Add primitive values directly as tags
        scope.setTag(tagKey, value?.toString() ?? 'null');
      }
    });
  }

  /// Initialize Sentry with enhanced configuration
  static Future<void> init({required String dsn, required VoidCallback appRunner}) async {
    // Check if we've already initialized (our own flag)
    if (_isInitialized) {
      appRunner();
      return;
    }

    // Check if Sentry is already initialized by something else
    if (Sentry.isEnabled) {
      _isInitialized = true;
      appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = dsn;
      // options.replay.sessionSampleRate = 1.0;
      // options.replay.onErrorSampleRate = 1.0;

      // // Privacy settings for PII masking
      // //TODO: Set this to false in production for Ğ1
      // options.privacy.maskAllText = false;
      // options.privacy.maskAllImages = false;

      // Configure automatic error reporting with diagnostic data
      options.beforeSend = _beforeSendCallback;

      options.maxBreadcrumbs = 1000; // Maximum breadcrumbs
      options.sampleRate = 1.0; // Send 100% of events
      options.maxCacheItems = 1000; // Maximum cache
    }, appRunner: appRunner);

    // Mark as initialized
    _isInitialized = true;
  }

  /// Update the current context and ref for diagnostic data collection
  static void updateContext(BuildContext? context, WidgetRef? ref) {
    _currentContext = context;
    _currentRef = ref;
  }

  /// Callback executed before sending events to Sentry
  static SentryEvent? _beforeSendCallback(SentryEvent event, Hint hint) {
    try {
      // Generate diagnostic data
      final diagnosticData = DiagnosticService.instance.generateDiagnosticData(
        context: _currentContext,
        ref: _currentRef,
      );

      // Add ALL diagnostic data using tags - flatten the entire diagnostic report
      Sentry.configureScope((scope) {
        scope.setTag('diagnostic_included', 'true');
        scope.setTag('diagnostic_timestamp', DateTime.now().millisecondsSinceEpoch.toString());

        // Recursively flatten and add ALL diagnostic data as tags
        _flattenAndAddToScope(scope, diagnosticData, 'diagnostic');
      });

      return event;
    } catch (e) {
      // If diagnostic data generation fails, still send the original event

      // Add error information using tags
      Sentry.configureScope((scope) {
        scope.setTag('diagnostic_included', 'false');
        scope.setTag('diagnostic_error', 'true');
      });

      return event;
    }
  }

  /// Manually capture an exception with diagnostic data
  static Future<SentryId> captureException(
    dynamic throwable, {
    dynamic stackTrace,
    String? tag,
    Map<String, dynamic>? extra,
    BuildContext? context,
    WidgetRef? ref,
  }) async {
    // Update context if provided
    if (context != null) _currentContext = context;
    if (ref != null) _currentRef = ref;

    return await Sentry.captureException(
      throwable,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (tag != null) {
          scope.setTag('error_type', tag);
        }
        if (extra != null) {
          extra.forEach((key, value) {
            final sanitizedKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
            final tagValue = value is Map
                ? value.entries.map((e) => '${e.key}=${e.value}').join(', ')
                : value.toString();
            scope.setTag('capture_$sanitizedKey', _sanitizePii(sanitizedKey, tagValue));
          });
        }

        // Add timestamp for this specific error
        scope.setTag('manual_capture_timestamp', DateTime.now().toIso8601String());
      },
    );
  }

  /// Manually capture a message with diagnostic data
  static Future<SentryId> captureMessage(
    String message, {
    SentryLevel? level,
    String? tag,
    Map<String, dynamic>? extra,
    BuildContext? context,
    WidgetRef? ref,
  }) async {
    // Update context if provided
    if (context != null) _currentContext = context;
    if (ref != null) _currentRef = ref;

    return await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (tag != null) {
          scope.setTag('message_type', tag);
        }
        if (extra != null) {
          extra.forEach((key, value) {
            scope.setTag('message_$key', value.toString());
          });
        }

        // Add timestamp for this specific message
        scope.setTag('manual_message_timestamp', DateTime.now().toIso8601String());
      },
    );
  }

  /// Add breadcrumb with diagnostic context
  static void addBreadcrumb(String message, {String? category, SentryLevel? level, Map<String, dynamic>? data}) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level ?? SentryLevel.info,
        data: {...?data, 'timestamp': DateTime.now().toIso8601String()},
      ),
    );
  }

  /// Set user information
  static void setUser({String? id, String? email, String? username, Map<String, dynamic>? extras}) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: id, email: email, username: username, data: extras));
    });
  }

  /// Set custom tag
  static void setTag(String key, String value) {
    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Set custom context using tags (since setContext is not available)
  static void setContext(String key, Map<String, dynamic> context) {
    Sentry.configureScope((scope) {
      context.forEach((contextKey, value) {
        scope.setTag('${key}_$contextKey', value.toString());
      });
    });
  }

  /// Manually send a comprehensive issue report with logs and diagnostic data
  /// This is intended for manual user-triggered reports when experiencing issues
  static Future<SentryId> sendManualIssueReport({
    required String userDescription,
    BuildContext? context,
    WidgetRef? ref,
  }) async {
    try {
      // Check if Sentry is initialized
      if (!Sentry.isEnabled) {
        const errorMsg = 'Sentry is not initialized. Please enable Sentry in main.dart';
        LogCollectionService.instance.logError('Manual Sentry report failed', errorMsg);
        if (kDebugMode) {
          debugPrint('🚨 Sentry: Cannot send manual report - Sentry is not enabled');
        }
        throw Exception(errorMsg);
      }

      LogCollectionService.instance.logInfo('Starting manual Sentry issue report');

      // Update context if provided
      if (context != null) _currentContext = context;
      if (ref != null) _currentRef = ref;

      // Generate comprehensive diagnostic data
      final diagnosticData = DiagnosticService.instance.generateDiagnosticData(
        context: _currentContext,
        ref: _currentRef,
      );

      // Get recent logs (last 5000 entries)
      final logsString = LogCollectionService.instance.getLogsAsString(count: 5000);
      final logStats = LogCollectionService.instance.getLogStatistics();

      // Generate a unique UUID for each manual report (for internal tracking)
      final reportUuid = _generateShortUuid();
      String issueTitle;
      if (userDescription.trim().isEmpty) {
        issueTitle = '[Manual Report] - ${DateTime.now().toIso8601String().substring(0, 16)}';
      } else {
        // Take first 50 characters of description and clean it up
        final cleanDescription = userDescription
            .trim()
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .replaceAll(RegExp(r'\s+'), ' ');

        final shortDescription = cleanDescription.length > 50
            ? '${cleanDescription.substring(0, 50)}...'
            : cleanDescription;
        issueTitle = '[Manual Report] - $shortDescription';
      }

      // Create a comprehensive message
      final reportMessage =
          '''
$issueTitle

User Description:
$userDescription

Report Generated: ${DateTime.now().toIso8601String()}

Log Statistics:
${logStats.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Diagnostic Data Summary:
- App Version: ${diagnosticData['app_info']?['version'] ?? 'unknown'}
- Platform: ${diagnosticData['app_info']?['platform'] ?? 'unknown'}
- Network: ${diagnosticData['riverpod_state']?['services']?['network'] ?? 'unknown'}
- Connection Status: ${diagnosticData['riverpod_state']?['connections']?['combined'] ?? 'unknown'}

Recent Application Logs:
$logsString

Full diagnostic data is attached as additional context.
''';

      // Send the report with comprehensive data
      final sentryId = await Sentry.captureMessage(
        reportMessage,
        level: SentryLevel.info,
        withScope: (scope) {
          // Set unique fingerprint to prevent grouping
          scope.fingerprint = ['manual-report', reportUuid];

          // Add manual report tags
          scope.setTag('report_type', 'manual_user_report');
          scope.setTag('manual_report_timestamp', DateTime.now().toIso8601String());
          scope.setTag('user_description_provided', userDescription.isNotEmpty.toString());

          // Add unique identifier for this specific issue
          scope.setTag('report_uuid', reportUuid);
          scope.setTag('issue_title', issueTitle);
          scope.setTag('issue_hash', reportUuid.hashCode.abs().toString());

          // Add log statistics as tags
          logStats.forEach((key, value) {
            scope.setTag('logs_$key', value.toString());
          });

          // Note: Full logs are included in the main message, no need for tags

          // Add user description (truncated for tag)
          final truncatedDescription = userDescription.length > 200
              ? '${userDescription.substring(0, 200)}...'
              : userDescription;
          scope.setTag('user_description', truncatedDescription);

          // The diagnostic data will be automatically added by the beforeSend callback
        },
      );

      log.i('Manual Sentry report sent successfully: $sentryId');

      return sentryId;
    } catch (e) {
      // If manual report fails, still try to send a basic error report
      LogCollectionService.instance.logError('Failed to send manual Sentry report', e);

      return await Sentry.captureException(
        Exception('Failed to send manual issue report: $e'),
        withScope: (scope) {
          scope.setTag('report_type', 'manual_report_failed');
          scope.setTag(
            'original_user_description',
            userDescription.length > 200 ? userDescription.substring(0, 200) : userDescription,
          );
        },
      );
    }
  }
}
