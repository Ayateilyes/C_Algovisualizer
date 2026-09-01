import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'package:go_router/go_router.dart';
import '../../../../config/router/app_router.dart';

// ─── CYBER-ACADEMIC Color Constants ───────────────────────────────────────────
class _C {
  static const primary = Color(0xFF00C896); // Neon teal/cyan
  static const surface = Color(0xFF0B0C10); // Deep background
  static const void_ = Color(0xFF050505);
  static const border = Color(0xFF1F2833);
  static const text = Color(0xFFE0E6ED);
  static const muted = Color(0xFF8B949E);
  static const purple = Color(0xFFB180D8);
  static const cyan = Color(0xFF00E5FF);
  static const success = Color(0xFF45E355);
}

// ─── Welcome Screen ───────────────────────────────────────────────────────────
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _overallFadeController;
  late final Animation<double> _overallFadeOpacity;
  late final AnimationController _entranceController;
  late final Animation<double> _heroOpacity;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _cardsOpacity;
  late final Animation<Offset> _cardsSlide;
  late final Animation<double> _signatureOpacity;

  final List<_Particle> _particles = [];
  final _random = Random();
  final _scrollController = ScrollController();
  Offset _mousePos = Offset.zero;

  @override
  void initState() {
    super.initState();

    // Overall screen fade in (replaces splash)
    _overallFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _overallFadeOpacity = CurvedAnimation(
      parent: _overallFadeController,
      curve: Curves.easeIn,
    );

    // Particle animation — loops forever
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Keep it running continuously
    );

    // Generate 60 particles for the network
    for (int i = 0; i < 60; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          vx: (_random.nextDouble() - 0.5) * 0.4,
          vy: (_random.nextDouble() - 0.5) * 0.4,
          radius: 1.0 + _random.nextDouble() * 2.0,
          color: [
            _C.primary,
            _C.purple,
            _C.cyan,
            _C.success,
          ][_random.nextInt(4)].withAlpha(50 + _random.nextInt(100)),
        ),
      );
    }

    // Entrance stagger animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _heroOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
          ),
        );

    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
      ),
    );

    _cardsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 40), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _signatureOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start ALL AnimationControllers here, not in initState directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _overallFadeController.forward();
        _particleController.repeat();

        // Start entrance after a brief delay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _entranceController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _overallFadeController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF050505), // must match splash background
      body: FadeTransition(
        opacity: _overallFadeOpacity,
        child: Stack(
          children: [
            // ── Grid background ──────────────────────────────────────────
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // ── Background & Particles ──────────────────────────────────
            Positioned.fill(
              child: MouseRegion(
                onHover: (e) {
                  setState(() => _mousePos = e.localPosition);
                },
                onExit: (e) {
                  setState(() => _mousePos = Offset.zero);
                },
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) => RepaintBoundary(
                    child: CustomPaint(
                      foregroundPainter: ParticleNetworkPainter(
                        particles: _particles,
                        time: _particleController.value,
                        mousePos: _mousePos,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────────────────
            SafeArea(
              child: isMobile
                  // ── MOBILE: No Stack at all — just scrollable content ──
                  ? RawScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 8,
                      radius: const Radius.circular(8),
                      thumbColor: _C.cyan.withAlpha(220),
                      trackColor: _C.border.withAlpha(100),
                      trackBorderColor: _C.border.withAlpha(60),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Container(
                          constraints: BoxConstraints(minHeight: size.height),
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 32,
                              ),
                              child: AnimatedBuilder(
                                animation: _entranceController,
                                builder: (context, _) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // ── Status badge (scrolls with content) ──
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: _StatusBadge(
                                        opacity: _heroOpacity.value,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // ── Hero text ──
                                    Transform.translate(
                                      offset: _heroSlide.value,
                                      child: Opacity(
                                        opacity: _heroOpacity.value,
                                        child: _HeroText(
                                          screenWidth: size.width,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Subtitle ──
                                    Opacity(
                                      opacity: _subtitleOpacity.value,
                                      child: _Subtitle(isMobile: true),
                                    ),
                                    const SizedBox(height: 32),

                                    // ── Choice cards ──
                                    Transform.translate(
                                      offset: _cardsSlide.value,
                                      child: Opacity(
                                        opacity: _cardsOpacity.value,
                                        child: _ChoiceCards(isMobile: true),
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    // ── Signature ──
                                    Opacity(
                                      opacity: _signatureOpacity.value,
                                      child: const _Signature(),
                                    ),
                                    const SizedBox(height: 32),

                                    // ── LinkedIn button (scrolls with content) ──
                                    Opacity(
                                      opacity: _heroOpacity.value,
                                      child: const _LinkedInButton(),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  // ── DESKTOP: Stack with Positioned overlays ──
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 8,
                          radius: const Radius.circular(8),
                          thumbColor: _C.cyan.withAlpha(220),
                          trackColor: _C.border.withAlpha(100),
                          trackBorderColor: _C.border.withAlpha(60),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Container(
                              constraints: BoxConstraints(
                                minHeight: size.height,
                              ),
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 700,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 32,
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _entranceController,
                                    builder: (context, _) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // ── Hero text ──
                                        Transform.translate(
                                          offset: _heroSlide.value,
                                          child: Opacity(
                                            opacity: _heroOpacity.value,
                                            child: _HeroText(
                                              screenWidth: size.width,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // ── Subtitle ──
                                        Opacity(
                                          opacity: _subtitleOpacity.value,
                                          child: _Subtitle(isMobile: false),
                                        ),
                                        const SizedBox(height: 48),

                                        // ── Choice cards ──
                                        Transform.translate(
                                          offset: _cardsSlide.value,
                                          child: Opacity(
                                            opacity: _cardsOpacity.value,
                                            child: _ChoiceCards(
                                              isMobile: false,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 60),

                                        // ── Signature ──
                                        Opacity(
                                          opacity: _signatureOpacity.value,
                                          child: const _Signature(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Top-right Status badge ──
                        Positioned(
                          top: 24,
                          right: 40,
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, _) =>
                                _StatusBadge(opacity: _heroOpacity.value),
                          ),
                        ),

                        // ── Bottom-left LinkedIn Button ──
                        Positioned(
                          bottom: 24,
                          left: 40,
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, _) => Opacity(
                              opacity: _heroOpacity.value,
                              child: const _LinkedInButton(),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Badge (top-right style) ───────────────────────────────────────────
class _StatusBadge extends StatefulWidget {
  final double opacity;
  const _StatusBadge({required this.opacity});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: _C.border),
            borderRadius: BorderRadius.circular(100),
            color: _C.surface.withAlpha(200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.success,
                    boxShadow: [
                      BoxShadow(
                        color: _C.success.withAlpha(
                          (120 * _pulseController.value).round(),
                        ),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SYSTEMS_ONLINE v1.0',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: _C.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── LinkedIn Action Button ───────────────────────────────────────────────────
class _LinkedInButton extends StatefulWidget {
  const _LinkedInButton();

  @override
  State<_LinkedInButton> createState() => _LinkedInButtonState();
}

class _LinkedInButtonState extends State<_LinkedInButton> {
  bool _hovered = false;

  void _launchLinkedIn() {
    html.window.open('https://www.linkedin.com/in/ayyat-ilyes/', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _launchLinkedIn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF0077b5).withAlpha(30)
                : _C.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? const Color(0xFF0077b5) : _C.border,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF0077b5).withAlpha(100),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          transform: Matrix4.identity()..scale(_hovered ? 1.05 : 1.0),
          transformAlignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons
                      .link_rounded, // Assuming LinkedIn icon isn't in standard set, using a link
                  key: ValueKey(_hovered),
                  size: 20,
                  color: _hovered ? const Color(0xFF0077b5) : _C.muted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Let\'s Connect',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : _C.text,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Text with Interactive Letters ───────────────────────────────────────
class _HeroText extends StatelessWidget {
  final double screenWidth;
  const _HeroText({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    // 3-tier responsive font size
    final double fontSize;
    if (screenWidth < 400) {
      fontSize = 32;
    } else if (screenWidth < 600) {
      fontSize = 42;
    } else if (screenWidth < 900) {
      fontSize = 56;
    } else {
      fontSize = 72;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          _InteractiveWord(
            word: 'C-ALGO',
            fontSize: fontSize,
            delayMs: 100,
            wordKey: 'calgo',
          ),
          _InteractiveWord(
            word: 'VISUALIZER',
            fontSize: fontSize,
            delayMs: 600,
            wordKey: 'visualizer',
          ),
        ],
      ),
    );
  }
}

final _hoveredLetterIndexProvider = StateProvider<int>((ref) => -1);

class _InteractiveWord extends ConsumerStatefulWidget {
  final String word;
  final double fontSize;
  final int delayMs;
  final String wordKey; // to distinguish "C-ALGO" from "VISUALIZER"

  const _InteractiveWord({
    required this.word,
    required this.fontSize,
    required this.wordKey,
    this.delayMs = 0,
  });

  @override
  ConsumerState<_InteractiveWord> createState() => _InteractiveWordState();
}

class _InteractiveWordState extends ConsumerState<_InteractiveWord> {
  int _visibleChars = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    if (widget.delayMs > 0) {
      await Future.delayed(Duration(milliseconds: widget.delayMs));
    }
    if (!mounted) return;

    for (int i = 0; i < widget.word.length; i++) {
      await Future.delayed(const Duration(milliseconds: 60)); // typing speed
      if (!mounted) break;
      setState(() {
        _visibleChars++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final width = renderBox.size.width;
          final letterWidth = width / widget.word.length;
          final index = (e.localPosition.dx / letterWidth).floor();
          if (index >= 0 && index < widget.word.length) {
            // Include wordKey hash to avoid collision between the two words
            ref.read(_hoveredLetterIndexProvider.notifier).state =
                index + widget.wordKey.hashCode;
          }
        }
      },
      onExit: (_) {
        ref.read(_hoveredLetterIndexProvider.notifier).state = -1;
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.word.length, (index) {
          if (index < _visibleChars) {
            return _InteractiveLetter(
              letter: widget.word[index],
              fontSize: widget.fontSize,
              globalIndex: index + widget.wordKey.hashCode,
            );
          } else {
            // Invisible placeholder to maintain layout width
            return Opacity(
              opacity: 0.0,
              child: Text(
                widget.word[index],
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}

class _InteractiveLetter extends ConsumerWidget {
  final String letter;
  final double fontSize;
  final int globalIndex;

  const _InteractiveLetter({
    required this.letter,
    required this.fontSize,
    required this.globalIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoveredIndex = ref.watch(_hoveredLetterIndexProvider);
    final isHovered = hoveredIndex == globalIndex;

    return AnimatedScale(
      scale: isHovered ? 1.3 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: isHovered ? _C.cyan : _C.text,
          letterSpacing: -2,
          height: 1.0,
          shadows: isHovered
              ? [BoxShadow(color: _C.cyan.withAlpha(200), blurRadius: 10)]
              : null,
        ),
        child: Text(letter),
      ),
    );
  }
}

// ─── Subtitle ─────────────────────────────────────────────────────────────────
class _Subtitle extends StatefulWidget {
  final bool isMobile;
  const _Subtitle({required this.isMobile});

  @override
  State<_Subtitle> createState() => _SubtitleState();
}

class _SubtitleState extends State<_Subtitle> {
  // We'll delay the typing start until exactly when the opacity starts fading in (around 25% of entrance animation)
  bool _startTyping = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _startTyping = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_startTyping) return const SizedBox.shrink();

    return Column(
      children: [
        _TypewriterText(
          text: 'Learn C Programming Visually.',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: widget.isMobile ? 14 : 16,
            color: _C.muted,
            height: 1.6,
          ),
          speedMs: 30,
        ),
        _TypewriterText(
          text: 'Step through code. Watch memory. Finally.',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: widget.isMobile ? 14 : 16,
            color: _C.muted,
            height: 1.6,
          ),
          speedMs: 30,
          delayMs: 800, // Wait for first line to finish
        ),
      ],
    );
  }
}

// ─── Typewriter Text Effect ───────────────────────────────────────────────────
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int speedMs;
  final int delayMs;

  const _TypewriterText({
    required this.text,
    required this.style,
    this.speedMs = 40,
    this.delayMs = 0,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    if (widget.delayMs > 0) {
      await Future.delayed(Duration(milliseconds: widget.delayMs));
    }
    _cursorCycle();
    if (!mounted) return;

    for (int i = 0; i < widget.text.length; i++) {
      await Future.delayed(Duration(milliseconds: widget.speedMs));
      if (!mounted) break;
      setState(() {
        _currentIndex++;
        _displayedText = widget.text.substring(0, _currentIndex);
      });
    }
  }

  void _cursorCycle() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _showCursor = !_showCursor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if typing is finished
    bool isFinished = _currentIndex >= widget.text.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_displayedText, textAlign: TextAlign.center, style: widget.style),
        // Only blink cursor while typing or shortly after
        Opacity(
          opacity: _showCursor && !isFinished
              ? 1.0
              : (_showCursor && isFinished ? 0.3 : 0.0),
          child: Text('_', style: widget.style.copyWith(color: _C.cyan)),
        ),
      ],
    );
  }
}

// ─── Choice Cards ─────────────────────────────────────────────────────────────
class _ChoiceCards extends StatelessWidget {
  final bool isMobile;
  const _ChoiceCards({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ChoiceCard(
        icon: Icons.code_rounded,
        iconColor: _C.primary,
        title: 'CODE_LAB',
        subtitle: 'Editor + Live Visualizer',
        tag: 'READY',
        tagColor: _C.success,
        accentColor: _C.primary,
        onTap: () => context.go(AppRoutes.editor),
      ),
      _ChoiceCard(
        icon: Icons.menu_book_rounded,
        iconColor: _C.purple,
        title: 'CURRICULUM',
        subtitle: '11 Modules · 48 Lessons',
        tag: '48 LESSONS',
        tagColor: _C.cyan,
        accentColor: _C.purple,
        onTap: () => context.go(AppRoutes.curriculum),
      ),
    ];

    if (isMobile) {
      return Column(children: [cards[0], const SizedBox(height: 16), cards[1]]);
    }

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 20),
          Expanded(child: cards[1]),
        ],
      ),
    );
  }
}

// ─── Single Choice Card ──────────────────────────────────────────────────────
class _ChoiceCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  Offset _mousePos = Offset.zero;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _mousePos = Offset.zero;
      }),
      onHover: (e) {
        if (!isMobile) {
          setState(() => _mousePos = e.localPosition);
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _hovered ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, hoverState, _) {
            // Calculate 3D Tilt (only on desktop)
            double rotateX = 0;
            double rotateY = 0;

            if (_hovered && !isMobile) {
              // Assuming card width ~ 300, height ~ 200 for calculation
              // We'll normalize mouse pos between -1 and 1
              final normX = (_mousePos.dx / 300.0) * 2 - 1;
              final normY = (_mousePos.dy / 250.0) * 2 - 1;

              // Max tilt angle (radians)
              const maxTilt = 0.08;
              rotateX = -normY * maxTilt; // Pitch
              rotateY = normX * maxTilt; // Yaw
            }

            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(rotateX * hoverState)
              ..rotateY(rotateY * hoverState)
              ..translate(0.0, -8.0 * hoverState, 0.0); // slight lift

            return Transform(
              alignment: FractionalOffset.center,
              transform: matrix,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    constraints: isMobile
                        ? const BoxConstraints()
                        : const BoxConstraints(minWidth: 200, maxWidth: 320),
                    // Outer container for the glowing border padding
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _hovered && !isMobile
                          ? SweepGradient(
                              center: Alignment.center,
                              startAngle: 0.0,
                              endAngle: 2 * pi,
                              colors: [
                                _C.border,
                                widget.accentColor,
                                _C.border,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              transform: GradientRotation(
                                _glowController.value * 2 * pi,
                              ),
                            )
                          : null,
                      boxShadow: _hovered
                          ? [
                              BoxShadow(
                                color: widget.accentColor.withAlpha(
                                  (70 * hoverState).toInt(),
                                ),
                                blurRadius: 40,
                                spreadRadius: -10,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: _C.void_,
                                blurRadius: 100,
                                spreadRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 24 : 32),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      _C.surface,
                      const Color(0xFF131320),
                      hoverState,
                    ),
                    borderRadius: BorderRadius.circular(
                      15,
                    ), // slightly less than outer
                    border: Border.all(
                      color: _hovered
                          ? Colors.transparent
                          : _C.border, // Border managed by outer gradient when hovered
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.iconColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _C.text,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          color: _C.muted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tag chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: widget.tagColor.withAlpha(100),
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          widget.tag,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.tagColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Signature Section ────────────────────────────────────────────────────────
class _Signature extends StatelessWidget {
  const _Signature();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider
        Container(width: 200, height: 1, color: _C.border),
        const SizedBox(height: 20),

        // Built with love
        Text(
          'Built with ❤ for students',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            color: _C.muted,
          ),
        ),
        const SizedBox(height: 10),

        // Memory Decrypt effect for name
        const _MemoryDecryptText(text: 'AYYAT ILYES'),
        const SizedBox(height: 10),

        // Role chips
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _GlowingRoleChip(label: 'Flutter Dev'),
            const SizedBox(width: 8),
            const _GlowingRoleChip(label: 'Algorithmic Lecturer'),
          ],
        ),
      ],
    );
  }
}

class _MemoryDecryptText extends StatefulWidget {
  final String text;
  const _MemoryDecryptText({required this.text});

  @override
  State<_MemoryDecryptText> createState() => _MemoryDecryptTextState();
}

class _MemoryDecryptTextState extends State<_MemoryDecryptText>
    with TickerProviderStateMixin {
  bool _hovered = false;
  bool _showCursor = true;
  String _currentText = '';
  final _rand = Random();
  final String _chars = '01#%&*OX';
  late final AnimationController _scrambleController;
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _currentText = widget.text;

    _scrambleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _cursorController.addListener(() {
      if (mounted) {
        setState(() => _showCursor = _cursorController.value > 0.5);
      }
    });

    _scrambleController.addListener(() {
      if (!mounted) return;
      if (_scrambleController.value < 0.9) {
        // Scramble with 30% chance of keeping the real letter so it feels like it's decoding
        setState(() {
          String newStr = "";
          for (int i = 0; i < widget.text.length; i++) {
            if (widget.text[i] == ' ') {
              newStr += ' ';
            } else {
              newStr += _rand.nextDouble() > 0.3
                  ? _chars[_rand.nextInt(_chars.length)]
                  : widget.text[i];
            }
          }
          _currentText = newStr;
        });
      } else {
        setState(() => _currentText = widget.text);
      }
    });
  }

  void _triggerScramble() {
    if (_scrambleController.isAnimating) return;
    _scrambleController.forward(from: 0);
  }

  @override
  void dispose() {
    _scrambleController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _triggerScramble();
      },
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [_C.primary, _C.purple],
            ).createShader(bounds),
            child: Text(
              _currentText,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          // Blinking cursor
          Opacity(
            opacity: _showCursor ? 1.0 : 0.0,
            child: Text(
              '_',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _hovered ? _C.cyan : _C.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingRoleChip extends StatefulWidget {
  final String label;
  const _GlowingRoleChip({required this.label});

  @override
  State<_GlowingRoleChip> createState() => _GlowingRoleChipState();
}

class _GlowingRoleChipState extends State<_GlowingRoleChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: _hovered ? _C.cyan.withAlpha(200) : _C.border,
          ),
          borderRadius: BorderRadius.circular(100),
          color: _hovered ? _C.cyan.withAlpha(10) : Colors.transparent,
          boxShadow: _hovered
              ? [BoxShadow(color: _C.cyan.withAlpha(50), blurRadius: 8)]
              : [],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            color: _hovered ? _C.text : _C.muted,
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  const _RoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          color: _C.muted,
        ),
      ),
    );
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(7)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Radial fade (center brighter, edges darker)
    final center = Offset(size.width / 2, size.height / 2);
    final fadePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, _C.void_.withAlpha(200), _C.void_],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.6));
    canvas.drawRect(Offset.zero & size, fadePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Particle System ──────────────────────────────────────────────────────────
class _Particle {
  double x; // 0..1
  double y; // 0..1
  double vx; // velocity x
  double vy; // velocity y
  final double radius;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
  });
}

class ParticleNetworkPainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final Offset mousePos;

  ParticleNetworkPainter({
    required this.particles,
    required this.time,
    required this.mousePos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double maxDistance = 120.0;
    final double mouseRepulsionRadius = 150.0;

    // Update and draw particles
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];

      // Move particle
      p.x += p.vx * 0.005;
      p.y += p.vy * 0.005;

      // Bounce off walls
      if (p.x < 0 || p.x > 1.0) p.vx *= -1;
      if (p.y < 0 || p.y > 1.0) p.vy *= -1;

      // Convert to screen coordinates
      double px = p.x * size.width;
      double py = p.y * size.height;

      // Mouse interaction (Repulsion / Parallax)
      if (mousePos != Offset.zero) {
        final double dx = mousePos.dx - px;
        final double dy = mousePos.dy - py;
        final double dist = sqrt(dx * dx + dy * dy);

        if (dist < mouseRepulsionRadius) {
          final double force =
              (mouseRepulsionRadius - dist) / mouseRepulsionRadius;
          px -= (dx / dist) * force * 15.0; // Push away from mouse
          py -= (dy / dist) * force * 15.0;
        }
      }

      // Draw particle
      final paint = Paint()..color = p.color;
      canvas.drawCircle(Offset(px, py), p.radius, paint);

      // Draw connections
      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];

        // Convert p2 to screen coordinates considering mouse as well for connections
        double p2x = p2.x * size.width;
        double p2y = p2.y * size.height;

        if (mousePos != Offset.zero) {
          final double dx2 = mousePos.dx - p2x;
          final double dy2 = mousePos.dy - p2y;
          final double dist2 = sqrt(dx2 * dx2 + dy2 * dy2);
          if (dist2 < mouseRepulsionRadius) {
            final double force2 =
                (mouseRepulsionRadius - dist2) / mouseRepulsionRadius;
            p2x -= (dx2 / dist2) * force2 * 15.0;
            p2y -= (dy2 / dist2) * force2 * 15.0;
          }
        }

        final double cdx = px - p2x;
        final double cdy = py - p2y;
        final double distance = sqrt(cdx * cdx + cdy * cdy);

        if (distance < maxDistance) {
          final double opacity = 1.0 - (distance / maxDistance);
          final linePaint = Paint()
            ..color = p.color.withAlpha((opacity * 100).toInt())
            ..strokeWidth = 0.5;
          canvas.drawLine(Offset(px, py), Offset(p2x, p2y), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Constant repaint for smooth 60fps
}
