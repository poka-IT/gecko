import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:durt2/durt2.dart' show BidouilleLang, Durt;
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
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
    _captureTimer?.cancel();
    _captureTimer = null;

    // Ensure camera is properly disposed
    _cameraController?.dispose().catchError((e) {
      // Log camera disposal errors but don't crash
      if (kDebugMode) {
        debugPrint('🚨 MnemonicScanner: Camera disposal error: $e');
      }
    });
    _cameraController = null;

    // Ensure ML Kit recognizer is properly closed
    _textRecognizer.close().catchError((e) {
      // Log ML Kit disposal errors but don't crash
      if (kDebugMode) {
        debugPrint('🚨 MnemonicScanner: ML Kit disposal error: $e');
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
    if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isNotEmpty) {
        final textWithPositions = _extractTextWithPositions(recognizedText.blocks);
        await _handleDetectedText(textWithPositions);
      }
    } catch (e) {
      // Log the error to Sentry for debugging
      if (kDebugMode) {
        debugPrint('🚨 MnemonicScanner: Camera/ML Kit error: $e');
      }
      // Report to Sentry in production
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
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Map<String, Rect> _extractTextWithPositions(List<TextBlock> blocks) {
    final textPositions = <String, Rect>{};

    // Sort blocks spatially (top to bottom, left to right)
    final sortedBlocks = List<TextBlock>.from(blocks);
    sortedBlocks.sort((a, b) {
      final yDiff = a.boundingBox.top.compareTo(b.boundingBox.top);
      if (yDiff.abs() > 50) return yDiff;
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });

    for (final block in sortedBlocks) {
      // Filter: exclude UI text but keep mnemonic area
      if (block.boundingBox.top < 480 || block.boundingBox.bottom > 800) {
        continue;
      }
      final lines = block.text.split('\n');
      if (lines.length > 1) {
        // Handle multi-line blocks
        for (int i = 0; i < lines.length; i++) {
          final processedLine = _processText(lines[i]);
          if (processedLine.isNotEmpty) {
            final adjustedRect = Rect.fromLTRB(
              block.boundingBox.left,
              block.boundingBox.top + (i * 20),
              block.boundingBox.right,
              block.boundingBox.top + (i * 20) + 20,
            );
            textPositions[processedLine] = adjustedRect;
          }
        }
      } else {
        final processedText = _processText(block.text);
        if (processedText.isNotEmpty) {
          textPositions[processedText] = block.boundingBox;
        }
      }
    }

    return textPositions;
  }

  String _processText(String text) {
    return text
        .trim()
        .replaceAll('0', 'o') // Fix common OCR errors
        .toLowerCase();
  }

  Future<void> _handleDetectedText(Map<String, Rect> textPositions) async {
    if (!mounted) return;

    setState(() {
      _statusMessage = 'ocrScanInProgress'.tr();
    });

    final mnemonicWords = await _extractMnemonicWords(textPositions);

    if (mnemonicWords.length == 12) {
      final isValid = await _validateMnemonic(mnemonicWords);
      if (isValid) {
        widget.onMnemonicDetected(mnemonicWords);
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    // Update status
    if (mounted) {
      setState(() {
        _statusMessage = mnemonicWords.isNotEmpty
            ? 'Found ${mnemonicWords.length}/12 words'
            : 'mnemonicNotFoundInImage'.tr();
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  Future<List<String>> _extractMnemonicWords(Map<String, Rect> textPositions) async {
    // Simplified: arrange words by their physical grid position (3 rows x 4 cols)
    final validWords = <MapEntry<String, Rect>>[];

    // Filter and split combined words
    for (final entry in textPositions.entries) {
      final words = entry.key.split(' '); // Split combined words
      for (final word in words) {
        if (word.trim().isNotEmpty && await _isValidBip39Word(word.trim())) {
          // Create a new entry for each valid word, keeping original position
          validWords.add(MapEntry(word.trim(), entry.value));
        }
      }
    }

    // Sort by 3x4 grid: group by rows, then sort each row by X
    const rowHeight = 100.0; // Approximate height between rows
    final rows = <int, List<MapEntry<String, Rect>>>{};

    // Group words by row
    for (final word in validWords) {
      final rowIndex = (word.value.top / rowHeight).floor();
      rows.putIfAbsent(rowIndex, () => []).add(word);
    }

    // Sort each row by X coordinate
    final sortedWords = <MapEntry<String, Rect>>[];
    for (final rowIndex in rows.keys.toList()..sort()) {
      final rowWords = rows[rowIndex]!;
      rowWords.sort((a, b) => a.value.left.compareTo(b.value.left));
      sortedWords.addAll(rowWords);
    }

    validWords.clear();
    validWords.addAll(sortedWords);

    final orderedWords = validWords.map((e) => e.key).toList();

    return orderedWords.take(12).toList();
  }

  Future<bool> _isValidBip39Word(String word) async {
    if (word.length < 3) return false; // Too short to be a BIP39 word

    try {
      final multilangService = Durt.i.wallets.multilangService;
      final detectedLanguage = await multilangService.detectMnemonicLanguageFromWords([word]);
      return detectedLanguage != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _validateMnemonic(List<String> words) async {
    if (words.length != 12 || words.any((word) => word.isEmpty)) {
      return false;
    }

    try {
      final mnemonic = words.join(' ');

      final multilangService = Durt.i.wallets.multilangService;
      final detectedLanguage = await multilangService.detectMnemonicLanguageFromWords(words);

      if (detectedLanguage == null) {
        return false;
      }

      if (detectedLanguage == BidouilleLang.english) {
        final isValid = Durt.i.wallets.isMnemonicValid(mnemonic);
        return isValid;
      } else {
        final englishMnemonic = await multilangService.convertToEnglish(mnemonic, sourceLanguage: detectedLanguage);
        final isValid = Durt.i.wallets.isMnemonicValid(englishMnemonic);
        return isValid;
      }
    } catch (e) {
      return false;
    }
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

            // Simplified camera view for mnemonic scanning
            Container(
              height: scaleSize(150), // Reduced height for mnemonic focus
              margin: EdgeInsets.symmetric(horizontal: scaleSize(32)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.primary,
                  width: 3,
                ), // Use theme primary color instead of red
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

            // Cancel button with theme consistency
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
