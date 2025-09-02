import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:gecko/services/diagnostic_service.dart';

/// Enhanced Sentry service that automatically includes diagnostic reports
/// with all error reports sent to Sentry
class SentryService {
  static SentryService? _instance;
  static SentryService get instance => _instance ??= SentryService._();

  SentryService._();

  static BuildContext? _currentContext;
  static WidgetRef? _currentRef;

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
    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.replay.sessionSampleRate = 1.0;
      options.replay.onErrorSampleRate = 1.0;

      // Privacy settings for PII masking
      //TODO: Set this to false in production for Ğ1
      options.privacy.maskAllText = false;
      options.privacy.maskAllImages = false;

      // Configure automatic error reporting with diagnostic data
      options.beforeSend = _beforeSendCallback;
    }, appRunner: appRunner);
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

      // Log that we're sending an event with diagnostic data (debug only)
      if (kDebugMode) {
        debugPrint('🚨 Sentry: Sending event with diagnostic data: ${event.eventId}');
      }

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
      // but include information about the failure
      if (kDebugMode) {
        debugPrint('🚨 Sentry: Failed to add diagnostic data: $e');
      }

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
            scope.setTag('capture_$key', value.toString());
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
}
