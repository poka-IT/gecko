import 'package:flutter/material.dart';

/// Semantic color tokens for the Gecko application.
///
/// Provides a centralized, theme-aware color palette for status indicators,
/// connection states, and semantic UI elements. Registered as a ThemeExtension
/// so that light and dark variants are resolved automatically via the current theme.
@immutable
class GeckoColors extends ThemeExtension<GeckoColors> {
  const GeckoColors({
    required this.success,
    required this.successContainer,
    required this.successText,
    required this.warning,
    required this.warningContainer,
    required this.warningText,
    required this.danger,
    required this.dangerContainer,
    required this.dangerText,
    required this.info,
    required this.infoContainer,
    required this.infoText,
    required this.statusMember,
    required this.statusConfirmed,
    required this.statusCreated,
    required this.statusExpired,
    required this.statusRevoked,
    required this.statusNone,
    required this.connectionOk,
    required this.connectionWarn,
    required this.connectionError,
    required this.deleteAction,
  });

  // -- Semantic status -------------------------------------------------------

  /// Green for positive states (validated, finalized, success).
  final Color success;

  /// Light green background for success containers.
  final Color successContainer;

  /// Dark green for text on success backgrounds.
  final Color successText;

  /// Orange for caution / pending states.
  final Color warning;

  /// Light orange background for warning containers.
  final Color warningContainer;

  /// Dark orange for text on warning backgrounds.
  final Color warningText;

  /// Red for errors, destructive actions.
  final Color danger;

  /// Light red background for danger containers.
  final Color dangerContainer;

  /// Dark red for text on danger backgrounds.
  final Color dangerText;

  /// Blue for informational states.
  final Color info;

  /// Light blue background for info containers.
  final Color infoContainer;

  /// Dark blue for text on info backgrounds.
  final Color infoText;

  // -- Identity status (maps to IdtyStatus) ----------------------------------

  /// Green - validated member.
  final Color statusMember;

  /// Orange - confirmed identity.
  final Color statusConfirmed;

  /// Blue - newly created identity.
  final Color statusCreated;

  /// Red - expired identity.
  final Color statusExpired;

  /// Grey - revoked identity.
  final Color statusRevoked;

  /// Grey - no identity / unknown.
  final Color statusNone;

  // -- Connection status -----------------------------------------------------

  /// Green - connected.
  final Color connectionOk;

  /// Orange - degraded / warning.
  final Color connectionWarn;

  /// Red - disconnected / error.
  final Color connectionError;

  // -- Special ---------------------------------------------------------------

  /// Dark red used for delete/destructive action labels (0xffD80000).
  final Color deleteAction;

  // ---------------------------------------------------------------------------

  @override
  GeckoColors copyWith({
    Color? success,
    Color? successContainer,
    Color? successText,
    Color? warning,
    Color? warningContainer,
    Color? warningText,
    Color? danger,
    Color? dangerContainer,
    Color? dangerText,
    Color? info,
    Color? infoContainer,
    Color? infoText,
    Color? statusMember,
    Color? statusConfirmed,
    Color? statusCreated,
    Color? statusExpired,
    Color? statusRevoked,
    Color? statusNone,
    Color? connectionOk,
    Color? connectionWarn,
    Color? connectionError,
    Color? deleteAction,
  }) {
    return GeckoColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      successText: successText ?? this.successText,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      warningText: warningText ?? this.warningText,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      dangerText: dangerText ?? this.dangerText,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      infoText: infoText ?? this.infoText,
      statusMember: statusMember ?? this.statusMember,
      statusConfirmed: statusConfirmed ?? this.statusConfirmed,
      statusCreated: statusCreated ?? this.statusCreated,
      statusExpired: statusExpired ?? this.statusExpired,
      statusRevoked: statusRevoked ?? this.statusRevoked,
      statusNone: statusNone ?? this.statusNone,
      connectionOk: connectionOk ?? this.connectionOk,
      connectionWarn: connectionWarn ?? this.connectionWarn,
      connectionError: connectionError ?? this.connectionError,
      deleteAction: deleteAction ?? this.deleteAction,
    );
  }

  @override
  GeckoColors lerp(GeckoColors? other, double t) {
    if (other is! GeckoColors) return this;
    return GeckoColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      statusMember: Color.lerp(statusMember, other.statusMember, t)!,
      statusConfirmed: Color.lerp(statusConfirmed, other.statusConfirmed, t)!,
      statusCreated: Color.lerp(statusCreated, other.statusCreated, t)!,
      statusExpired: Color.lerp(statusExpired, other.statusExpired, t)!,
      statusRevoked: Color.lerp(statusRevoked, other.statusRevoked, t)!,
      statusNone: Color.lerp(statusNone, other.statusNone, t)!,
      connectionOk: Color.lerp(connectionOk, other.connectionOk, t)!,
      connectionWarn: Color.lerp(connectionWarn, other.connectionWarn, t)!,
      connectionError: Color.lerp(connectionError, other.connectionError, t)!,
      deleteAction: Color.lerp(deleteAction, other.deleteAction, t)!,
    );
  }
}

/// Light theme gecko colors — matches the existing hardcoded values.
const lightGeckoColors = GeckoColors(
  // Semantic status
  success: Colors.green,
  successContainer: Color(0xFFE8F5E9), // Colors.green.shade50
  successText: Color(0xFF2E7D32), // Colors.green.shade700-900
  warning: Color(0xFFFF9800), // Colors.orange
  warningContainer: Color(0xFFFFF3E0), // Colors.orange.shade50
  warningText: Color(0xFFE65100), // Colors.orange.shade900
  danger: Colors.red,
  dangerContainer: Color(0xFFFFEBEE), // Colors.red.shade50
  dangerText: Color(0xFFB71C1C), // Colors.red.shade900
  info: Colors.blue,
  infoContainer: Color(0xFFE3F2FD), // Colors.blue.shade50
  infoText: Color(0xFF1565C0), // Colors.blue.shade700
  // Identity status
  statusMember: Colors.green,
  statusConfirmed: Colors.orange,
  statusCreated: Colors.blue,
  statusExpired: Colors.red,
  statusRevoked: Colors.grey,
  statusNone: Colors.grey,

  // Connection status
  connectionOk: Colors.green,
  connectionWarn: Colors.orange,
  connectionError: Colors.red,

  // Special
  deleteAction: Color(0xffD80000),
);

/// Dark theme gecko colors — slightly lighter / desaturated for dark backgrounds.
const darkGeckoColors = GeckoColors(
  // Semantic status
  success: Color(0xFF66BB6A), // Colors.green.shade400
  successContainer: Color(0xFF1B5E20), // dark green bg
  successText: Color(0xFFA5D6A7), // Colors.green.shade300
  warning: Color(0xFFFFB74D), // Colors.orange.shade300
  warningContainer: Color(0xFF4E342E), // dark orange-brown bg
  warningText: Color(0xFFFFCC80), // Colors.orange.shade200
  danger: Color(0xFFEF5350), // Colors.red.shade400
  dangerContainer: Color(0xFF4E1A1A), // dark red bg
  dangerText: Color(0xFFEF9A9A), // Colors.red.shade200
  info: Color(0xFF42A5F5), // Colors.blue.shade400
  infoContainer: Color(0xFF0D47A1), // dark blue bg
  infoText: Color(0xFF90CAF9), // Colors.blue.shade200
  // Identity status
  statusMember: Color(0xFF66BB6A),
  statusConfirmed: Color(0xFFFFB74D),
  statusCreated: Color(0xFF42A5F5),
  statusExpired: Color(0xFFEF5350),
  statusRevoked: Color(0xFF9E9E9E),
  statusNone: Color(0xFF9E9E9E),

  // Connection status
  connectionOk: Color(0xFF66BB6A),
  connectionWarn: Color(0xFFFFB74D),
  connectionError: Color(0xFFEF5350),

  // Special
  deleteAction: Color(0xFFFF5252),
);
