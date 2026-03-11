import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/build_image.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/next_button.dart';

class InfoIntro extends StatefulWidget {
  const InfoIntro({
    super.key,
    required this.text,
    required this.assetName,
    required this.buttonText,
    required this.nextScreen,
    required this.pagePosition,
    this.isMd = false,
    this.isFast = false,
    this.boxHeight = 340,
    this.imageWidth = 350,
    this.textSize = 17,
    this.routeArguments,
  });

  final String text;
  final String assetName;
  final String buttonText;
  final String nextScreen;
  final double pagePosition;
  final bool isMd;
  final bool isFast;
  final double boxHeight;
  final double imageWidth;
  final double textSize;
  final RouteArguments? routeArguments;

  @override
  State<InfoIntro> createState() => _InfoIntroState();
}

class _InfoIntroState extends State<InfoIntro> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;
  bool _isAtBottom = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Initialize animation
    _animationController = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Start pulsing animation
    _animationController.repeat(reverse: true);

    // Check if content is scrollable after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  @override
  void didUpdateWidget(InfoIntro oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recheck scrollable state when widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // Consider we're at bottom when we've scrolled most of the content
    // Since the button is now fixed, we need to account for the reserved space
    final double scrollableHeight = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final bool isAtBottom = scrollableHeight <= 50 || currentScroll >= (scrollableHeight * 0.85);

    if (_isAtBottom != isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
      });
    }
  }

  void _checkScrollable() {
    if (!_scrollController.hasClients) return;

    // Only show indicator if there's meaningful scroll content (more than 50 pixels)
    final bool isScrollable = _scrollController.position.maxScrollExtent > 50;
    if (_showScrollIndicator != isScrollable) {
      setState(() {
        _showScrollIndicator = isScrollable;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    // Scroll all the way to the bottom
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if we have finite height constraints
        final bool hasFiniteHeight = constraints.maxHeight != double.infinity;

        if (hasFiniteHeight) {
          // We have finite height constraints - use our scroll detection system with fixed button position
          return Stack(
            children: [
              // Scrollable content
              SizedBox(
                height: constraints.maxHeight,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ScaledSizedBox(height: isTall ? 25 : 5),
                        BuildProgressBar(pagePosition: widget.pagePosition),
                        ScaledSizedBox(height: isTall ? 25 : 5),
                        BuildText(text: widget.text, size: widget.textSize, isMd: widget.isMd),
                        BuildImage(
                          assetName: widget.assetName,
                          boxHeight: widget.boxHeight,
                          imageWidth: widget.imageWidth,
                        ),
                        // Add space for the fixed button at the bottom
                        SizedBox(height: scaleSize(120)), // Space for button + padding
                      ],
                    ),
                  ),
                ),
              ),
              // Fixed button at bottom
              Positioned(
                bottom: scaleSize(20),
                left: 0,
                right: 0,
                child: Center(
                  child: NextButton(
                    text: widget.buttonText,
                    nextScreen: widget.nextScreen,
                    isFast: false,
                    routeArguments: widget.routeArguments,
                  ),
                ),
              ),
              // Scroll indicator at bottom (above the button)
              if (_showScrollIndicator && !_isAtBottom)
                Positioned(
                  bottom: scaleSize(90), // Above the button
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: GestureDetector(
                            onTap: _scrollToBottom,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    'scrollToContinue'.tr(),
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        } else {
          // We have infinite height constraints (inside another ScrollView) - use simple Column
          return Column(
            children: <Widget>[
              ScaledSizedBox(height: isTall ? 25 : 5),
              BuildProgressBar(pagePosition: widget.pagePosition),
              ScaledSizedBox(height: isTall ? 25 : 5),
              BuildText(text: widget.text, size: widget.textSize, isMd: widget.isMd),
              BuildImage(assetName: widget.assetName, boxHeight: widget.boxHeight, imageWidth: widget.imageWidth),
              Container(
                padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: NextButton(
                    text: widget.buttonText,
                    nextScreen: widget.nextScreen,
                    isFast: false,
                    routeArguments: widget.routeArguments,
                  ),
                ),
              ),
              ScaledSizedBox(height: isTall ? 40 : 5),
            ],
          );
        }
      },
    );
  }
}
