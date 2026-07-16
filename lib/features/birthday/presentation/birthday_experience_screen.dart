import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/birthday/domain/birthday_model.dart';
import 'package:nowplaying/features/birthday/presentation/widgets/birthday_steps_widgets.dart';
import 'package:nowplaying/shared/data/firestore_service.dart';

class BirthdayExperienceScreen extends ConsumerStatefulWidget {
  final BirthdayContent content;
  final int year;

  const BirthdayExperienceScreen({super.key, required this.content, required this.year});

  @override
  ConsumerState<BirthdayExperienceScreen> createState() => _BirthdayExperienceScreenState();
}

class _BirthdayExperienceScreenState extends ConsumerState<BirthdayExperienceScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isFinished = false;

  void _next() {
    if (_currentStep < 8) {
      _pageController.nextPage(duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = 7 + widget.content.chapters.length; // Calculate actual steps

    if (_isFinished) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: const Text(
            'The best chapters\nare still waiting\nto be written.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300, height: 1.6),
          ).animate().fadeIn(duration: 2.seconds).then(delay: 2.seconds).fadeOut(duration: 1.seconds),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _StarBackground(),
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentStep = i),
            itemCount: totalSteps,
            itemBuilder: (context, index) {
              final children = [
                TypewriterStep(text: widget.content.opening, onComplete: _next),
                TypewriterStep(text: widget.content.story, onComplete: _next),
                for (var chapter in widget.content.chapters)
                  ChapterStep(chapter: chapter, onNext: _next),
                May8Step(title: widget.content.may8Title, message: widget.content.may8Message, onNext: _next),
                IfICouldStep(cards: widget.content.ifICouldCards, onComplete: _next),
                FutureStep(timeline: widget.content.timeline, onNext: _next),
                CakeStep(message: widget.content.cakeMessage, onComplete: _next),
                FinalLetterStep(
                  text: widget.content.finalLetter,
                  onFinish: () {
                    // Immediate UI feedback
                    if (mounted) setState(() => _isFinished = true);

                    // Trigger Firestore update in background
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      ref.read(firestoreServiceProvider).updateBirthdayCompleted(uid, widget.year);
                    }

                    // Auto-close after animation sequence
                    Future.delayed(5.seconds, () {
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      
                    });
                  },
                ),
              ];
              
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
                  }
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: children[index],
                    ),
                  );
                },
              );
            },
          ),
          // Progress indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalSteps,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index <= _currentStep ? Colors.white : Colors.white24,
                  ),
                ),
              ),
            ).animate().fadeIn(),
          ),
        ],
      ),
    );
  }
}

class _StarBackground extends StatefulWidget {
  const _StarBackground();

  @override
  State<_StarBackground> createState() => _StarBackgroundState();
}

class _StarBackgroundState extends State<_StarBackground> with SingleTickerProviderStateMixin {
  late List<_Star> _stars;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(100, (index) => _Star());
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(painter: _StarPainter(_stars), size: Size.infinite);
      },
    );
  }
}

class _Star {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double size = Random().nextDouble() * 2;
  double opacity = Random().nextDouble();
  double speed = Random().nextDouble() * 0.001;

  void update() {
    y -= speed;
    if (y < 0) {
      y = 1;
      x = Random().nextDouble();
    }
  }
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  _StarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var star in stars) {
      star.update();
      paint.color = Colors.white.withValues(alpha: star.opacity);
      canvas.drawCircle(Offset(star.x * size.width, star.y * size.height), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
