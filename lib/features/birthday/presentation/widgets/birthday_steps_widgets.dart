import 'dart:ui';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/birthday/domain/birthday_model.dart';

class BirthdayStepContainer extends StatelessWidget {
  final Widget child;
  const BirthdayStepContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(child: child),
    );
  }
}

class TypewriterStep extends StatelessWidget {
  final String text;
  final VoidCallback onComplete;

  const TypewriterStep({super.key, required this.text, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BirthdayStepContainer(
      child: DefaultTextStyle(
        style: GoogleFonts.philosopher(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.6,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              text,
              speed: const Duration(milliseconds: 60),
              textAlign: TextAlign.center,
            ),
          ],
          totalRepeatCount: 1,
          onFinished: onComplete,
          displayFullTextOnTap: true,
        ),
      ),
    );
  }
}

class ChapterStep extends StatefulWidget {
  final BirthdayChapter chapter;
  final VoidCallback onNext;

  const ChapterStep({super.key, required this.chapter, required this.onNext});

  @override
  State<ChapterStep> createState() => _ChapterStepState();
}

class _ChapterStepState extends State<ChapterStep> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return BirthdayStepContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isOpen) ...[
            Text(
              widget.chapter.title.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textTertiary,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),
            const SizedBox(height: 16),
            Text(
              widget.chapter.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.philosopher(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => setState(() => _isOpen = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Text(
                      'Reveal Story',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms).scale(curve: Curves.elasticOut),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                widget.chapter.content,
                textAlign: TextAlign.center,
                style: GoogleFonts.philosopher(
                  fontSize: 22,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.8,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 60),
            IconButton(
              onPressed: widget.onNext,
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
              ),
            ).animate().fadeIn(delay: 1.2.seconds).scale(),
          ],
        ],
      ),
    );
  }
}

class May8Step extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onNext;

  const May8Step({super.key, required this.title, required this.message, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return BirthdayStepContainer(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
              child: Text(
                title,
                style: GoogleFonts.philosopher(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -2,
                ),
              ),
            ).animate().fadeIn(duration: 1.seconds).scale(curve: Curves.elasticOut),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'A DAY TO REMEMBER',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: Colors.white60,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 30),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.philosopher(
                fontSize: 20,
                color: Colors.white.withOpacity(0.8),
                height: 1.8,
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
            const SizedBox(height: 50),
            IconButton(
              onPressed: onNext,
              icon: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
              ),
            ).animate().fadeIn(delay: 2.seconds).scale(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class IfICouldStep extends StatefulWidget {
  final List<String> cards;
  final VoidCallback onComplete;

  const IfICouldStep({super.key, required this.cards, required this.onComplete});

  @override
  State<IfICouldStep> createState() => _IfICouldStepState();
}

class _IfICouldStepState extends State<IfICouldStep> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BirthdayStepContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'IF I COULD...'.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textTertiary,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 60),
          SizedBox(
            height: 380,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = widget.cards.length - 1; i >= _currentIndex; i--)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: 400.ms,
                      opacity: i == _currentIndex ? 1.0 : 0.3,
                      child: Transform.scale(
                        scale: 1.0 - (i - _currentIndex) * 0.05,
                        child: Transform.translate(
                          offset: Offset(0, (i - _currentIndex) * 20.0),
                          child: _SwipeCard(
                            text: widget.cards[i],
                            isActive: i == _currentIndex,
                            onSwiped: () {
                              if (_currentIndex < widget.cards.length - 1) {
                                setState(() => _currentIndex++);
                              } else {
                                widget.onComplete();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swipe_left_rounded, color: Colors.white30, size: 16),
              const SizedBox(width: 8),
              Text(
                'Swipe to reveal more',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.3),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.swipe_right_rounded, color: Colors.white30, size: 16),
            ],
          ).animate().fadeIn(delay: 1.seconds),
        ],
      ),
    );
  }
}

class _SwipeCard extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onSwiped;

  const _SwipeCard({required this.text, required this.isActive, required this.onSwiped});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return _buildCard(false);

    return Draggable(
      axis: Axis.horizontal,
      onDragEnd: (details) {
        if (details.offset.dx.abs() > 120) {
          onSwiped();
        }
      },
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 80,
          height: 380,
          child: _buildCard(true),
        ),
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: _buildCard(false),
    );
  }

  Widget _buildCard(bool dragging) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Colors.white.withOpacity(0.05), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary.withOpacity(0.5),
                  size: 40,
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                const SizedBox(height: 40),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.philosopher(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FutureStep extends StatelessWidget {
  final List<BirthdayMilestone> timeline;
  final VoidCallback onNext;

  const FutureStep({super.key, required this.timeline, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return BirthdayStepContainer(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'OUR JOURNEY AHEAD',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textTertiary,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 40),
            ...timeline.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Center(
                          child: Text(m.date, style: const TextStyle(fontSize: 24)),
                        ),
                      ).animate().fadeIn(delay: (i * 300).ms).scale(),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            if (i == 0)
                              Text(
                                'Starting now...',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ).animate(onPlay: (c) => c.repeat()).shimmer(),
                          ],
                        ),
                      ).animate().fadeIn(delay: (i * 300 + 100).ms).slideX(begin: 0.1),
                    ],
                  ),
                  if (i < timeline.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Container(
                        width: 2,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white24, Colors.white.withOpacity(0.01)],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (i * 300 + 200).ms),
                ],
              );
            }),
            const SizedBox(height: 40),
            IconButton(
              onPressed: onNext,
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
              ),
            ).animate().fadeIn(delay: 2.seconds).slideY(begin: -0.5, curve: Curves.easeInOutBack),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class CakeStep extends StatefulWidget {
  final String message;
  final VoidCallback onComplete;

  const CakeStep({super.key, required this.message, required this.onComplete});

  @override
  State<CakeStep> createState() => _CakeStepState();
}

class _CakeStepState extends State<CakeStep> {
  bool _isBlown = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _blow() {
    if (_isBlown) return;
    setState(() => _isBlown = true);
    _confettiController.play();
    Future.delayed(4.seconds, widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return BirthdayStepContainer(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.pink, Colors.purple, Colors.orange, Colors.white, Colors.cyan],
                gravity: 0.1,
                numberOfParticles: 50,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'MAKE A WISH',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _blow,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          // Cake Glow
                          if (!_isBlown)
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.15),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.2, 1.2),
                                  duration: 2.seconds,
                                ),
                          
                          // Replacing Icon with a custom Drawn Cake
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Candle
                            if (!_isBlown)
                              Container(
                                width: 8,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            // Cake Top Tier
                            Container(
                              width: 80,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.pink.shade200,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                border: Border.all(color: Colors.white24),
                              ),
                            ),
                            // Cake Bottom Tier
                            Container(
                              width: 120,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.pink.shade300,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                border: Border.all(color: Colors.white24),
                              ),
                            ),
                          ],
                        )
                              .animate(target: _isBlown ? 1 : 0)
                              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 400.ms),
                          
                          if (!_isBlown)
                            Positioned(
                              top: -45, // Adjust based on candle height
                              child: const Icon(Icons.fireplace_rounded, color: Colors.orangeAccent, size: 40)
                                  .animate(onPlay: (c) => c.repeat())
                                  .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 600.ms)
                                  .moveY(begin: 0, end: -5, duration: 600.ms),
                            ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      if (!_isBlown)

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            'Tap the candle to blow it out',
                            style: GoogleFonts.montserrat(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
                    ],
                  ),
                ),
                if (_isBlown) ...[
                  const SizedBox(height: 40),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.philosopher(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FinalLetterStep extends StatelessWidget {
  final String text;
  final VoidCallback onFinish;

  const FinalLetterStep({super.key, required this.text, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return BirthdayStepContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.mail_outline_rounded, color: Colors.white30, size: 24),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.philosopher(
                    fontSize: 22,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.8,
                    fontStyle: FontStyle.italic,
                  ),
                ).animate().fadeIn(duration: 2.seconds),
              ),
            ),
          ),
          const SizedBox(height: 60),
          GestureDetector(
            onTap: onFinish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Text(
                'Finish ❤️',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 2.seconds).scale(curve: Curves.elasticOut),
        ],
      ),
    );
  }
}
