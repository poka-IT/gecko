import 'package:flutter/material.dart';
import 'package:gecko/providers/home.dart';
import 'package:provider/provider.dart';

class MessageLog3D extends StatefulWidget {
  const MessageLog3D({super.key});

  @override
  State<MessageLog3D> createState() => _MessageLog3DState();
}

class _MessageLog3DState extends State<MessageLog3D> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<String> _previousMessages = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final messages = homeProvider.homeMessages.reversed.take(3).toList();
        if (messages != _previousMessages) {
          _controller.forward(from: 0.0);
          _previousMessages = List.from(messages);
        }
        return SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: List.generate(messages.length, (index) {
              return MessageCard(
                message: messages[index],
                index: index,
                total: messages.length,
                animation: _controller,
              );
            }),
          ),
        );
      },
    );
  }
}

class MessageCard extends StatelessWidget {
  final String message;
  final int index;
  final int total;
  final AnimationController animation;

  const MessageCard({
    super.key,
    required this.message,
    required this.index,
    required this.total,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final double startScale = 1 - (index * 0.25);
    final double endScale = 1 - ((index + 0.8) * 0.25);
    final double startOpacity = index == 0 ? 1 : 0.7 - (index * 0.2);
    final double endOpacity = index == 0 ? 1 : 0.7 - ((index + 1) * 0.1);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double scale = Tween<double>(begin: startScale, end: endScale).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)).value;
        final double opacity = Tween<double>(begin: startOpacity, end: endOpacity).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)).value;
        final double yOffset =
            Tween<double>(begin: index * 35.0, end: (index + 1) * 35.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)).value;

        return Positioned(
          bottom: yOffset,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(0.0, 0.0, -index * 100.0)
              ..scale(scale),
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: (24 - (index * 4)).clamp(14.0, 24.0).toDouble(),
                  fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
