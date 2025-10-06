// lib/screens/tabs/stories_tab/story_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../../../models/news_stories_models.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    Key? key,
    required this.stories,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentStoryIndex = 0;
  int _currentSlideIndex = 0;

  late AnimationController _progressController; // controla o progresso do slide atual
  late AnimationController _scaleController; // animação de zoom lento
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    _currentStoryIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _pageController = PageController(initialPage: _currentStoryIndex);

    // controller de progresso (duration será ajustado por slide)
    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused) {
        _nextSlide();
      }
    });
    _progressController.addListener(() {
      // rebuild para atualizar barras
      if (mounted) setState(() {});
    });

    // zoom lento repetido
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // garantir slide index válido
    _currentSlideIndex = 0;
    // inicia progresso para o slide inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProgressForCurrentSlide();
    });
  }

  @override
  void dispose() {
    _progressController.removeStatusListener((_) {});
    _progressController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Story get _currentStory => widget.stories[_currentStoryIndex];
  List<StorySlide> _currentSlides = [];

  int _currentSlideDuration() {
    _currentSlides = _currentStory.slides;
    if (_currentSlides.isEmpty) return _currentStory.duration;
    final slide = _currentSlides[_currentSlideIndex.clamp(0, _currentSlides.length - 1)];
    return slide.duration > 0 ? slide.duration : _currentStory.duration;
  }

  void _startProgressForCurrentSlide() {
    if (!mounted) return;
    _progressController.stop();
    _progressController.reset();

    final durationSec = _currentSlideDuration();
    _progressController.duration = Duration(seconds: durationSec);
    // start from 0
    _progressController.forward(from: 0.0);
    _isPaused = false;
  }

  void _pauseProgress() {
    if (_isPaused) return;
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _resumeProgress() {
    if (!_isPaused) return;
    setState(() => _isPaused = false);
    // resume from current value
    _progressController.forward(from: _progressController.value);
  }

  void _nextSlide() {
    final slides = _currentStory.slides;
    if (slides.isNotEmpty && _currentSlideIndex < slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _startProgressForCurrentSlide();
    } else {
      _nextStory();
    }
  }

  void _previousSlide() {
    final slides = _currentStory.slides;
    if (slides.isNotEmpty && _currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
      });
      _startProgressForCurrentSlide();
    } else {
      _previousStory();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _onStoryChanged(int index) {
    setState(() {
      _currentStoryIndex = index.clamp(0, widget.stories.length - 1);
      _currentSlideIndex = 0;
    });
    _startProgressForCurrentSlide();
  }

  // Ao tocar: esquerda = anterior, direita = próximo
  void _handleTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 2) {
      _previousSlide();
    } else {
      _nextSlide();
    }
  }

  Widget _buildProgressBars(Story story, int storyIndex) {
    final slides = story.slides;
    final total = slides.isEmpty ? 1 : slides.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: List.generate(total, (i) {
          double progress = 0.0;

          if (storyIndex < _currentStoryIndex) {
            // story já vista -> barra completa
            progress = 1.0;
          } else if (storyIndex > _currentStoryIndex) {
            // story futura -> barra vazia
            progress = 0.0;
          } else {
            // story atual -> calcula com base no controller
            if (i < _currentSlideIndex) {
              progress = 1.0;
            } else if (i == _currentSlideIndex) {
              progress = _progressController.value.clamp(0.0, 1.0);
            } else {
              progress = 0.0;
            }
          }

          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(Story story) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                story.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2C2C2E),
                  child: const Icon(CupertinoIcons.photo, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                ),
                Text(
                  _formatTime(story.publishedAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            minSize: 32,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.ellipsis, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 4),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            minSize: 32,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StorySlide slide) {
    if (slide.text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
      child: Text(
        slide.text,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: -0.1),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _handleTapDown,
        onLongPress: _pauseProgress,
        onLongPressUp: _resumeProgress,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onStoryChanged,
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
            final story = widget.stories[index];
            final slides = story.slides;
            final slide = (index == _currentStoryIndex)
                ? (slides.isNotEmpty ? slides[_currentSlideIndex.clamp(0, slides.length - 1)] : StorySlide(imageUrl: story.imageUrl, text: '', duration: story.duration))
                : (slides.isNotEmpty ? slides[0] : StorySlide(imageUrl: story.imageUrl, text: '', duration: story.duration));

            return Stack(
              fit: StackFit.expand,
              children: [
                // Background image com zoom animado
                AnimatedBuilder(
                  animation: _scaleController,
                  builder: (context, child) {
                    final scale = 1.0 + (_scaleController.value * 0.06); // leve
                    return Transform.scale(
                      scale: scale,
                      child: Image.network(
                        slide.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1C1C1E),
                          child: const Icon(CupertinoIcons.photo, color: Color(0xFF8E8E93), size: 64),
                        ),
                      ),
                    );
                  },
                ),

                // Gradiente overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.12, 0.6, 1.0],
                    ),
                  ),
                ),

                // Conteúdo com SafeArea
                SafeArea(
                  child: Column(
                    children: [
                      // Progress bars (passa o index para calcular estado)
                      _buildProgressBars(story, index),
                      _buildHeader(story),
                      const Spacer(),
                      if (slide.text.isNotEmpty) _buildContent(slide),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}