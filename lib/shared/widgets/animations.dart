import 'package:flutter/material.dart';

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class PriceFlashAnimation extends StatefulWidget {
  final Widget child;
  final dynamic value;

  const PriceFlashAnimation({
    super.key,
    required this.child,
    required this.value,
  });

  @override
  State<PriceFlashAnimation> createState() => _PriceFlashAnimationState();
}

class _PriceFlashAnimationState extends State<PriceFlashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  bool _isDecreasing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(PriceFlashAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value is num && oldWidget.value is num) {
        _isDecreasing = widget.value < oldWidget.value;
      }
      _controller.forward(from: 0.0).then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _opacity,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value * 0.2,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDecreasing ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}

