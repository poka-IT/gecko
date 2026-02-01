import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/mnemonic_service.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/buttons/primary_button.dart';
import 'package:gecko/services/sentry_service.dart';
import 'dart:async';

class MnemonicScanner extends StatefulWidget {
  final Function(List<String> words) onMnemonicDetected;

  const MnemonicScanner({super.key, required this.onMnemonicDetected});

  @override
  State<MnemonicScanner> createState() => _MnemonicScannerState();
}

class _MnemonicScannerState extends State<MnemonicScanner> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isDisposed = false;
  String _statusMessage = '';

  final TextRecognizer _textRecognizer = TextRecognizer();
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _captureTimer?.cancel();
    _captureTimer = null;

    // Ensure camera is properly disposed
    _cameraController?.dispose().catchError((e) {
      if (kDebugMode) {
        debugPrint('MnemonicScanner: Camera disposal error: $e');
      }
    });
    _cameraController = null;

    // Ensure ML Kit recognizer is properly closed
    _textRecognizer.close().catchError((e) {
      if (kDebugMode) {
        debugPrint('MnemonicScanner: ML Kit disposal error: $e');
      }
    });

    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _startImageCapture();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera initialization failed';
        });
      }
    }
  }

  void _startImageCapture() {
    _captureTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && !_isProcessing && _cameraController?.value.isInitialized == true) {
        _captureAndProcessImage();
      }
    });
  }

  Future<void> _captureAndProcessImage() async {
    if (_isDisposed || !mounted || _cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_isDisposed) return;
      final XFile imageFile = await _cameraController!.takePicture();
      if (_isDisposed) return;
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (_isDisposed) return;

      if (recognizedText.blocks.isNotEmpty) {
        final words = await _parseMnemonicFromBlocks(recognizedText.blocks);
        if (words != null && words.length == 12) {
          widget.onMnemonicDetected(words);
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }

        // Update status with partial results
        if (mounted && !_isDisposed) {
          final allItems = _extractAllTextElements(recognizedText.blocks);
          final validCount = await _countValidBip39Words(allItems);
          setState(() {
            _statusMessage = validCount > 0 ? 'Found $validCount/12 words' : 'mnemonicNotFoundInImage'.tr();
          });
        }
      } else {
        if (mounted && !_isDisposed) {
          setState(() {
            _statusMessage = 'mnemonicNotFoundInImage'.tr();
          });
        }
      }
    } on CameraException catch (e) {
      // Camera closed during capture (race condition on dispose) — ignore
      if (e.description?.contains('Camera is closed') == true) return;
      if (kDebugMode) {
        debugPrint('MnemonicScanner: Camera error: $e');
      }
      SentryService.captureException(
        e,
        tag: 'mnemonic_scanner_error',
        extra: {
          'camera_initialized': _cameraController?.value.isInitialized ?? false,
          'is_processing': _isProcessing,
          'mounted': mounted,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MnemonicScanner: Camera/ML Kit error: $e');
      }
      SentryService.captureException(
        e,
        tag: 'mnemonic_scanner_error',
        extra: {
          'camera_initialized': _cameraController?.value.isInitialized ?? false,
          'is_processing': _isProcessing,
          'mounted': mounted,
        },
      );
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // --- OCR Parsing Logic ---

  /// Extract all individual text elements with their bounding boxes from ML Kit blocks.
  List<_OcrTextItem> _extractAllTextElements(List<TextBlock> blocks) {
    final items = <_OcrTextItem>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          items.add(_OcrTextItem(text: element.text, boundingBox: element.boundingBox));
        }
      }
    }
    return items;
  }

  /// Main entry point: try multiple extraction strategies and return the first
  /// result that passes BIP39 checksum validation.
  Future<List<String>?> _parseMnemonicFromBlocks(List<TextBlock> blocks) async {
    final items = _extractAllTextElements(blocks);
    if (items.isEmpty) return null;

    // Pre-classify all elements: numbers (1-12) and valid BIP39 words
    final numberItems = <int, _OcrTextItem>{};
    final bip39Items = <_OcrTextItem>[];

    for (final item in items) {
      final num = _parseGridNumber(item.text);
      if (num != null) {
        numberItems[num] = item;
        continue;
      }
      final corrected = await _tryCorrectWord(item.text);
      if (corrected != null) {
        bip39Items.add(_OcrTextItem(text: corrected, boundingBox: item.boundingBox));
      }
    }

    // Strategy 1: Numbered grid (if any numbers 1-12 detected)
    if (numberItems.isNotEmpty) {
      final result = await _parseNumberedGrid(bip39Items, numberItems);
      if (result != null) return result;
    }

    // Strategy 2: Spatial reading order (works for both grid and inline)
    final result = await _parseSpatialOrder(bip39Items);
    if (result != null) return result;

    return null;
  }

  /// Parse an integer in the 1-12 range from text, or null if not a grid number.
  int? _parseGridNumber(String text) {
    final cleaned = text.trim();
    final n = int.tryParse(cleaned);
    if (n != null && n >= 1 && n <= 12) return n;
    return null;
  }

  /// Numbered grid mode with partial gap-filling.
  ///
  /// Uses detected numbers as position anchors, then fills missing positions
  /// from remaining unassigned BIP39 words sorted spatially.
  Future<List<String>?> _parseNumberedGrid(List<_OcrTextItem> bip39Items, Map<int, _OcrTextItem> numberItems) async {
    final result = List<String?>.filled(12, null);
    final assignedWords = <_OcrTextItem>{};

    // Phase 1: For each detected number, find the closest BIP39 word below it
    for (final entry in numberItems.entries) {
      final num = entry.key; // 1-12
      final numBox = entry.value.boundingBox;

      _OcrTextItem? bestMatch;
      double bestDistance = double.infinity;

      for (final word in bip39Items) {
        // The word must be below or at the same level as the number
        if (word.boundingBox.top < numBox.top - numBox.height) continue;

        // Vertical distance: how far below the number
        final vertDist = (word.boundingBox.top - numBox.bottom).abs();
        // Horizontal distance: prefer words horizontally aligned with the number
        final horizDist = (word.boundingBox.center.dx - numBox.center.dx).abs();
        final distance = vertDist + horizDist * 0.5;

        if (distance < bestDistance) {
          bestDistance = distance;
          bestMatch = word;
        }
      }

      if (bestMatch != null) {
        result[num - 1] = bestMatch.text;
        assignedWords.add(bestMatch);
      }
    }

    // Phase 2: Fill gaps from remaining unassigned words sorted spatially
    final unassigned = bip39Items.where((w) => !assignedWords.contains(w)).toList();
    _sortByReadingOrder(unassigned);

    final gaps = <int>[];
    for (int i = 0; i < 12; i++) {
      if (result[i] == null) gaps.add(i);
    }

    if (gaps.length <= unassigned.length) {
      for (int g = 0; g < gaps.length && g < unassigned.length; g++) {
        result[gaps[g]] = unassigned[g].text;
      }
    }

    // Check we have all 12 words
    final words = <String>[];
    for (final w in result) {
      if (w == null) return null;
      words.add(w);
    }

    if (await _validateMnemonic(words)) {
      return words;
    }
    return null;
  }

  /// Spatial reading order mode — sort all valid BIP39 words by position
  /// and validate as a 12-word mnemonic.
  ///
  /// Works for grid layouts (3×4), inline phrases (1-3 lines), or any spatial
  /// arrangement. Handles noise (extra non-BIP39 context) since only valid
  /// BIP39 words are in the list.
  Future<List<String>?> _parseSpatialOrder(List<_OcrTextItem> bip39Items) async {
    final sorted = List<_OcrTextItem>.from(bip39Items);
    _sortByReadingOrder(sorted);

    final words = sorted.map((e) => e.text).toList();

    // Exact match: exactly 12 valid words
    if (words.length == 12) {
      if (await _validateMnemonic(words)) return words;
    }

    // More than 12 words: try sliding windows of 12 consecutive words
    // This handles extra context text that happens to be valid BIP39 words
    if (words.length > 12 && words.length <= 24) {
      for (int start = 0; start <= words.length - 12; start++) {
        final window = words.sublist(start, start + 12);
        if (await _validateMnemonic(window)) return window;
      }
    }

    return null;
  }

  /// Sort items in reading order: group by rows (similar Y), then left-to-right.
  void _sortByReadingOrder(List<_OcrTextItem> items) {
    if (items.isEmpty) return;

    items.sort((a, b) {
      final rowA = a.boundingBox.center.dy;
      final rowB = b.boundingBox.center.dy;
      // Use the average height as threshold for "same row"
      final avgHeight = (a.boundingBox.height + b.boundingBox.height) / 2;
      final rowThreshold = avgHeight * 0.7;

      if ((rowA - rowB).abs() > rowThreshold) {
        return rowA.compareTo(rowB);
      }
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });
  }

  /// Try to correct an OCR-read word into a valid BIP39 word.
  ///
  /// Returns the corrected word, or null if no valid correction found.
  Future<String?> _tryCorrectWord(String raw) async {
    final cleaned = raw.trim().toLowerCase();
    if (cleaned.isEmpty || cleaned.length < 3) return null;

    // 1. Try the raw text first
    if (await _isValidBip39Word(cleaned)) return cleaned;

    // 2. Apply common OCR corrections and test each
    final corrections = <String>[
      cleaned.replaceAll('0', 'o'),
      cleaned.replaceAll('1', 'l'),
      cleaned.replaceAll('1', 'i'),
      cleaned.replaceAll('rn', 'm'),
      cleaned.replaceAll('l', 'i'),
      cleaned.replaceAll('vv', 'w'),
      cleaned.replaceAll('ii', 'u'),
      // Combined corrections
      cleaned.replaceAll('0', 'o').replaceAll('rn', 'm'),
      cleaned.replaceAll('0', 'o').replaceAll('1', 'l'),
    ];

    for (final attempt in corrections) {
      if (attempt != cleaned && await _isValidBip39Word(attempt)) {
        return attempt;
      }
    }

    return null;
  }

  /// Check if a word is a valid BIP39 word using MnemonicService.
  Future<bool> _isValidBip39Word(String word) async {
    return await MnemonicService.isValidBip39Word(word);
  }

  /// Validate a complete 12-word mnemonic (BIP39 checksum).
  Future<bool> _validateMnemonic(List<String> words) async {
    if (words.length != 12 || words.any((w) => w.isEmpty)) return false;
    final result = await MnemonicService.validateAndProcessMnemonic(words.join(' '));
    return result != null;
  }

  /// Count valid BIP39 words in the extracted items (for status display).
  Future<int> _countValidBip39Words(List<_OcrTextItem> items) async {
    int count = 0;
    for (final item in items) {
      if (int.tryParse(item.text.trim()) != null) continue;
      final corrected = await _tryCorrectWord(item.text);
      if (corrected != null) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('scanMnemonic'.tr()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('scanMnemonic'.tr()),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions
            Padding(
              padding: EdgeInsets.all(scaleSize(16)),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(scaleSize(16)),
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt, size: scaleSize(48), color: context.colorScheme.primary),
                      SizedBox(height: scaleSize(8)),
                      Text(
                        'mnemonicScannerInstructions'.tr(),
                        textAlign: TextAlign.center,
                        style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: scaleSize(8)),
                      Text(
                        'mnemonicScannerSubtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: scaledTextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Status message
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                child: Container(
                  padding: EdgeInsets.all(scaleSize(12)),
                  decoration: BoxDecoration(
                    color: _isProcessing ? context.colorScheme.primaryContainer : context.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (_isProcessing)
                        SizedBox(
                          width: scaleSize(20),
                          height: scaleSize(20),
                          child: CircularProgressIndicator(strokeWidth: 2, color: context.colorScheme.primary),
                        )
                      else
                        Icon(Icons.info, size: scaleSize(20), color: context.colorScheme.error),
                      SizedBox(width: scaleSize(8)),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: scaledTextStyle(
                            fontSize: 14,
                            color: _isProcessing
                                ? context.colorScheme.onPrimaryContainer
                                : context.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: scaleSize(16)),

            // Camera view
            Container(
              height: scaleSize(150),
              margin: EdgeInsets.symmetric(horizontal: scaleSize(32)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colorScheme.primary, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: scaleSize(16)),

            // Cancel button
            Padding(
              padding: EdgeInsets.all(scaleSize(16)),
              child: PrimaryButton(
                label: 'cancel'.tr(),
                onPressed: () => Navigator.of(context).pop(),
                width: double.infinity,
                height: 55.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A text element extracted from OCR with its bounding box position.
class _OcrTextItem {
  final String text;
  final Rect boundingBox;

  const _OcrTextItem({required this.text, required this.boundingBox});
}
