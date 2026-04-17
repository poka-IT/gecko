import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/pin/gecko_numpad.dart';
import 'package:gecko/widgets/pin/gecko_pin_display.dart';

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Controls a [GeckoPinEntry] widget programmatically.
class GeckoPinEntryController {
  _GeckoPinEntryState? _state;

  void _attach(_GeckoPinEntryState state) => _state = state;
  void _detach() => _state = null;

  String get text => _state?._text ?? '';
  void clear() => _state?._clear();
  void triggerError() => _state?._triggerError();
  void triggerSuccess() => _state?._triggerSuccess();
  void dispose() => _detach();
}

// ---------------------------------------------------------------------------
// Layout constants
// ---------------------------------------------------------------------------

const _kMinButtonSize = 40.0;
const _kMaxButtonSize = 72.0;
const _kIdealButtonSize = 64.0;
const _kButtonSpacingRatio = 0.25; // gap between buttons = buttonSize * ratio
const _kRowGapRatio = 0.10; // vertical gap between rows = buttonSize * ratio
const _kDisplayGapRatio = 0.30; // gap between display and numpad = buttonSize * ratio

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Self-contained PIN entry with virtual numpad and animated display.
///
/// **Layout strategy**: Everything is driven by the button size.
/// - The numpad width = 3 buttons + 2 horizontal gaps
/// - The PIN cells stretch to match the numpad width
/// - Button size is computed from available height, clamped to [48..72]
///
/// Wrap in [Expanded] for best results — the widget adapts to any height.
class GeckoPinEntry extends StatefulWidget {
  const GeckoPinEntry({
    super.key,
    this.controller,
    this.length = pinLength,
    this.enabled = true,
    this.autoFocus = true,
    this.onCompleted,
    this.onChanged,
    this.onErrorAnimationComplete,
    this.bottomLeftWidget,
  });

  final GeckoPinEntryController? controller;
  final int length;
  final bool enabled;
  final bool autoFocus;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onErrorAnimationComplete;
  final Widget? bottomLeftWidget;

  @override
  State<GeckoPinEntry> createState() => _GeckoPinEntryState();
}

class _GeckoPinEntryState extends State<GeckoPinEntry> with SingleTickerProviderStateMixin {
  final List<int> _digits = [];
  PinDisplayMode _displayMode = PinDisplayMode.normal;
  bool _inputLocked = false;
  late final FocusNode _keyboardFocusNode;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  String get _text => _digits.map((d) => d.toString()).join();

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode(debugLabel: 'pin_entry_keyboard');
    widget.controller?._attach(this);

    _shakeController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeController, curve: _SineCurve(count: 3)));
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onShakeComplete();
    });
  }

  @override
  void didUpdateWidget(GeckoPinEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
      // Reset state: a swapped controller means the parent reused this
      // widget slot for a different logical entry (e.g. PIN → PIN confirm),
      // so _digits/_inputLocked from the previous entry must not leak.
      _digits.clear();
      _inputLocked = false;
      _displayMode = PinDisplayMode.normal;
      _shakeController.reset();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _shakeController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // ---- Controller API ----

  void _clear() {
    setState(() {
      _digits.clear();
      _displayMode = PinDisplayMode.normal;
      _inputLocked = false;
    });
  }

  void _triggerError() {
    setState(() {
      _displayMode = PinDisplayMode.error;
      _inputLocked = true;
    });
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
  }

  void _triggerSuccess() {
    setState(() {
      _displayMode = PinDisplayMode.success;
      _inputLocked = true;
    });
    HapticFeedback.mediumImpact();
  }

  void _onShakeComplete() {
    setState(() {
      _digits.clear();
      _displayMode = PinDisplayMode.normal;
      _inputLocked = false;
    });
    widget.onErrorAnimationComplete?.call();
  }

  // ---- Input handling ----

  void _addDigit(int digit) {
    if (_inputLocked || _digits.length >= widget.length) return;
    setState(() {
      _digits.add(digit);
      _displayMode = PinDisplayMode.normal;
    });
    widget.onChanged?.call(_text);
    if (_digits.length == widget.length) {
      _inputLocked = true;
      widget.onCompleted?.call(_text);
    }
  }

  void _deleteDigit() {
    if (_inputLocked || _digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _digits.removeLast();
      _displayMode = PinDisplayMode.normal;
    });
    widget.onChanged?.call(_text);
  }

  void _clearAll() {
    if (_inputLocked || _digits.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _digits.clear();
      _displayMode = PinDisplayMode.normal;
    });
    widget.onChanged?.call(_text);
  }

  // ---- Physical keyboard (desktop) ----

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) return KeyEventResult.ignored;
    final digit = _parseDigitKey(event.logicalKey);
    if (digit != null) {
      _addDigit(digit);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace || event.logicalKey == LogicalKeyboardKey.delete) {
      _deleteDigit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static int? _parseDigitKey(LogicalKeyboardKey key) {
    final id = key.keyId;
    if (id >= 0x30 && id <= 0x39) return id - 0x30;
    if (id == LogicalKeyboardKey.numpad0.keyId) return 0;
    if (id == LogicalKeyboardKey.numpad1.keyId) return 1;
    if (id == LogicalKeyboardKey.numpad2.keyId) return 2;
    if (id == LogicalKeyboardKey.numpad3.keyId) return 3;
    if (id == LogicalKeyboardKey.numpad4.keyId) return 4;
    if (id == LogicalKeyboardKey.numpad5.keyId) return 5;
    if (id == LogicalKeyboardKey.numpad6.keyId) return 6;
    if (id == LogicalKeyboardKey.numpad7.keyId) return 7;
    if (id == LogicalKeyboardKey.numpad8.keyId) return 8;
    if (id == LogicalKeyboardKey.numpad9.keyId) return 9;
    return null;
  }

  // ---- Layout computation ----

  /// Compute button size from available height.
  /// Total height = pinCellRow + displayGap + 4*button + 3*rowGap
  ///   pinCell height ≈ (numpadWidth - gaps) / pinLength ≈ buttonSize * 0.85
  ///   displayGap = buttonSize * 0.3
  ///   rowGap = buttonSize * 0.1
  /// Total ≈ 0.85*b + 0.3*b + 4*b + 3*0.1*b = 5.45*b
  /// Use 5.6 for safety margin.
  double _computeButtonSize(double availableHeight) {
    const totalRatio = 5.6;
    final computed = availableHeight / totalRatio;
    return computed.clamp(_kMinButtonSize, _kMaxButtonSize);
  }

  /// Numpad total width: 3 buttons + 2 gaps between them
  double _numpadWidth(double buttonSize) {
    final hGap = buttonSize * _kButtonSpacingRatio;
    return buttonSize * 3 + hGap * 2;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: widget.autoFocus,
      onKeyEvent: _onKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasFiniteHeight = constraints.maxHeight.isFinite;

          final buttonSize = hasFiniteHeight
              ? _computeButtonSize(constraints.maxHeight)
              : scaleSize(_kIdealButtonSize).clamp(_kMinButtonSize, _kMaxButtonSize);

          final numpadW = _numpadWidth(buttonSize);
          final rowGap = buttonSize * _kRowGapRatio;
          final displayGap = buttonSize * _kDisplayGapRatio;
          final shakeOffset = buttonSize * 0.15;

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PIN display — same width as numpad
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (_, child) =>
                    Transform.translate(offset: Offset(_shakeAnimation.value * shakeOffset, 0), child: child),
                child: GeckoPinDisplay(
                  filledCount: _digits.length,
                  length: widget.length,
                  mode: _displayMode,
                  width: numpadW,
                ),
              ),
              SizedBox(height: displayGap),
              // Numpad
              GeckoNumpad(
                buttonSize: buttonSize,
                totalWidth: numpadW,
                rowGap: rowGap,
                onDigitPressed: _addDigit,
                onDeletePressed: _deleteDigit,
                onDeleteLongPressed: _clearAll,
                bottomLeftWidget: widget.bottomLeftWidget,
                enabled: widget.enabled && !_inputLocked,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shake curve
// ---------------------------------------------------------------------------

class _SineCurve extends Curve {
  const _SineCurve({this.count = 3});
  final int count;

  @override
  double transformInternal(double t) => sin(count * 2 * pi * t);
}

// ---------------------------------------------------------------------------
// PIN complexity validation
// ---------------------------------------------------------------------------

bool isPinComplex(String pin) {
  if (pin.length != pinLength) return false;
  if (RegExp(r'^(\d)\1{3}$').hasMatch(pin)) return false;
  const sequences = [
    '0123',
    '1234',
    '2345',
    '3456',
    '4567',
    '5678',
    '6789',
    '9876',
    '8765',
    '7654',
    '6543',
    '5432',
    '4321',
    '3210',
  ];
  if (sequences.contains(pin)) return false;
  int sum = 0;
  for (int i = 0; i < 3; i++) {
    sum += (int.parse(pin[i]) - int.parse(pin[i + 1])).abs();
  }
  if (sum < 3) return false;
  final pinInt = int.parse(pin);
  if (pinInt >= 1950 && pinInt <= 2030) return false;
  return true;
}
