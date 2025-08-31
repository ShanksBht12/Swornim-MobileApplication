import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swornim/pages/auth/login.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _floatingController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _floatingAnimation;

  int _currentPage = 0;

  final List<IntroPage> _pages = [
    IntroPage(
      title: "Book Premium Venues",
      subtitle: "Discover Excellence",
      description: "Discover and reserve exclusive venues for your special occasions. From intimate gatherings to grand celebrations.",
      imagePath: 'assets/book_venue.webp',
      icon: Icons.location_city_rounded,
    ),
    IntroPage(
      title: "Professional Photography",
      subtitle: "Capture Moments",
      description: "Connect with talented photographers and videographers to capture your precious moments with artistic perfection.",
      imagePath: 'assets/photographer.webp',
      icon: Icons.camera_alt_rounded,
    ),
    IntroPage(
      title: "Expert Beauty Services",
      subtitle: "Transform Yourself",
      description: "Transform your look with skilled makeup artists and beauty professionals for that perfect, radiant appearance.",
      imagePath: 'assets/makeup_artist.webp',
      icon: Icons.face_rounded,
    ),
    IntroPage(
      title: "Creative Decorations",
      subtitle: "Bring Vision to Life",
      description: "Bring your vision to life with innovative decorators who specialize in creating magical, memorable atmospheres.",
      imagePath: 'assets/decorater.webp',
      icon: Icons.auto_awesome_rounded,
    ),
    IntroPage(
      title: "Live Events & Experiences",
      subtitle: "Connect & Celebrate",
      description: "Join exciting live events in your area and connect with like-minded people sharing similar interests.",
      imagePath: 'assets/live_event.webp',
      icon: Icons.celebration_rounded,
    ),
    IntroPage(
      title: "Vendor Management Hub",
      subtitle: "Grow Your Business",
      description: "Comprehensive dashboard for vendors to manage bookings, showcase services, and grow their business efficiently.",
      imagePath: 'assets/dashboard.webp',
      icon: Icons.dashboard_rounded,
    ),
  ];

  // Define page-specific color themes that complement your main theme
  final List<PageTheme> _pageThemes = [
    PageTheme(
      primaryColor: Color(0xFF2563EB), // Theme primary
      secondaryColor: Color(0xFF3B82F6),
      accentColor: Color(0xFF1E40AF),
    ),
    PageTheme(
      primaryColor: Color(0xFF059669),
      secondaryColor: Color(0xFF10B981),
      accentColor: Color(0xFF047857),
    ),
    PageTheme(
      primaryColor: Color(0xFFDC2626), // Theme error color
      secondaryColor: Color(0xFFEF4444),
      accentColor: Color(0xFFB91C1C),
    ),
    PageTheme(
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFFF59E0B),
      accentColor: Color(0xFFB45309),
    ),
    PageTheme(
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFF8B5CF6),
      accentColor: Color(0xFF6D28D9),
    ),
    PageTheme(
      primaryColor: Color(0xFF0369A1),
      secondaryColor: Color(0xFF0EA5E9),
      accentColor: Color(0xFF0284C7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize animation controllers with proper durations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOutCubic,
    ));
    
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOut,
    ));
    
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _contentController.forward();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _backgroundController.dispose();
    _contentController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  PageTheme get _currentPageTheme => _pageThemes[_currentPage];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skipToLogin() {
    HapticFeedback.lightImpact();
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onSignupClicked: () {
            // TODO: Implement navigation to signup page
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.tertiary.withOpacity(_backgroundAnimation.value),
                  const Color(0xFF0F172A).withOpacity(_backgroundAnimation.value),
                  const Color(0xFF020617).withOpacity(_backgroundAnimation.value),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Enhanced background elements using theme colors
                _buildBackgroundElements(theme),
                
                // Main content with theme integration
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Enhanced header with theme
                        _buildHeader(theme),
                        
                        // Page content with theme styling
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                              _contentController.reset();
                              _contentController.forward();
                            },
                            itemCount: _pages.length,
                            itemBuilder: (context, index) {
                              return _buildPageContent(_pages[index], size, theme);
                            },
                          ),
                        ),
                        
                        // Enhanced bottom navigation with theme
                        _buildBottomNavigation(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundElements(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundAnimation, _floatingAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // Primary gradient orb
            Positioned(
              top: -120 + (_floatingAnimation.value * 20),
              right: -80 + (_floatingAnimation.value * 15),
              child: Opacity(
                opacity: _backgroundAnimation.value * 0.15,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _currentPageTheme.primaryColor.withOpacity(0.4),
                        _currentPageTheme.primaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            
            // Secondary gradient orb
            Positioned(
              bottom: -180 - (_floatingAnimation.value * 25),
              left: -120 - (_floatingAnimation.value * 10),
              child: Opacity(
                opacity: _backgroundAnimation.value * 0.12,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _currentPageTheme.secondaryColor.withOpacity(0.3),
                        _currentPageTheme.secondaryColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            
            // Floating particles with theme colors
            ...List.generate(12, (index) {
              final isLeft = index % 2 == 0;
              final verticalOffset = (index * 80).toDouble();
              final horizontalOffset = isLeft ? 40.0 : MediaQuery.of(context).size.width - 60;
              final floatOffset = _floatingAnimation.value * (index % 2 == 0 ? 10 : -10);
              
              return Positioned(
                top: 100 + verticalOffset + floatOffset,
                left: horizontalOffset,
                child: Opacity(
                  opacity: _backgroundAnimation.value * (0.3 + (index % 3) * 0.2),
                  child: Container(
                    width: 4 + (index % 3).toDouble(),
                    height: 4 + (index % 3).toDouble(),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.surface.withOpacity(0.9),
                          _currentPageTheme.primaryColor.withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.surface.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            
            // Subtle grid pattern
            Positioned.fill(
              child: Opacity(
                opacity: _backgroundAnimation.value * 0.03,
                child: CustomPaint(
                  painter: GridPainter(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0), // Reduced from 24.0
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand logo area - reduced horizontal padding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced from 16
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.secondary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              "Swornim",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Page indicator - reduced spacing and width
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced from 16
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.surface.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Add this
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 2), // Reduced from 3
                  width: _currentPage == index ? 24 : 6, // Reduced from 28 and 8
                  height: 6, // Reduced from 8
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: _currentPage == index
                        ? LinearGradient(
                            colors: [
                              _currentPageTheme.primaryColor,
                              _currentPageTheme.secondaryColor,
                            ],
                          )
                        : null,
                    color: _currentPage == index
                        ? null
                        : theme.colorScheme.surface.withOpacity(0.4),
                  ),
                );
              }),
            ),
          ),
          
          // Skip button - reduced padding
          GestureDetector(
            onTap: _skipToLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced from 20,10
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface.withOpacity(0.15),
                    theme.colorScheme.surface.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.surface.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                "Skip",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the _buildPageContent method
  Widget _buildPageContent(IntroPage page, Size size, ThemeData theme) {
    return SlideTransition(
      position: _contentSlideAnimation,
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0), // Reduced from 24.0
          child: Column(
            children: [
              const SizedBox(height: 16), // Reduced from 20
              
              // Reduced image section height
              SizedBox(
                height: size.height * 0.35, // Reduced from 0.38
                child: _buildImageSection(page, size, theme),
              ),
              
              const SizedBox(height: 24), // Reduced from 32
              
              _buildTextSection(page, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(IntroPage page, Size size, ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background glow effect with theme colors
        Container(
          width: size.width * 0.75,
          height: size.width * 0.75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _currentPageTheme.primaryColor.withOpacity(0.2),
                _currentPageTheme.secondaryColor.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),
        
        // Main image container with glassmorphism effect
        Container(
          width: size.width * 0.62,
          height: size.width * 0.62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withOpacity(0.1),
                theme.colorScheme.surface.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.surface.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _currentPageTheme.primaryColor.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(33),
            child: Image.asset(
              page.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _currentPageTheme.primaryColor,
                        _currentPageTheme.secondaryColor,
                      ],
                    ),
                  ),
                  child: Icon(
                    page.icon,
                    size: 90,
                    color: theme.colorScheme.surface.withOpacity(0.9),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Enhanced floating icon with theme colors
        Positioned(
          bottom: 15,
          right: size.width * 0.12,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _currentPageTheme.primaryColor,
                  _currentPageTheme.secondaryColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _currentPageTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              color: theme.colorScheme.surface,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  // Update the _buildTextSection method
  Widget _buildTextSection(IntroPage page, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subtitle with theme styling
        Text(
          page.subtitle.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: _currentPageTheme.primaryColor,
            fontSize: 12, // Reduced from 13
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8, // Reduced from 2.0
          ),
        ),
        
        const SizedBox(height: 8), // Reduced from 12
        
        // Title with theme styling - using displayMedium for consistency
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.surface,
            fontSize: 24, // Reduced from 26
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.1, // Reduced from 1.2
          ),
        ),
        
        const SizedBox(height: 16), // Reduced from 20
        
        // Description container with reduced padding
        Container(
          padding: const EdgeInsets.all(16), // Reduced from 20
          margin: const EdgeInsets.symmetric(horizontal: 4), // Reduced from 8
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withOpacity(0.15),
                theme.colorScheme.surface.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16), // Reduced from 20
            border: Border.all(
              color: theme.colorScheme.surface.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Text(
            page.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.surface.withOpacity(0.9),
              fontSize: 14, // Reduced from 15
              height: 1.5, // Reduced from 1.6
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0), // Reduced vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Enhanced previous button with theme colors
          GestureDetector(
            onTap: _currentPage > 0 ? _previousPage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _currentPage > 0 
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.surface.withOpacity(0.2),
                          theme.colorScheme.surface.withOpacity(0.1),
                        ],
                      )
                    : null,
                border: Border.all(
                  color: _currentPage > 0 
                      ? theme.colorScheme.surface.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
                boxShadow: _currentPage > 0 ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ] : null,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: _currentPage > 0 
                    ? theme.colorScheme.surface
                    : Colors.transparent,
                size: 24,
              ),
            ),
          ),
          
          // Enhanced next/get started button with theme colors
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: _currentPage == _pages.length - 1
                  ? const EdgeInsets.symmetric(horizontal: 36, vertical: 18)
                  : const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: _currentPage == _pages.length - 1
                    ? BorderRadius.circular(35)
                    : BorderRadius.circular(50),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _currentPageTheme.primaryColor,
                    _currentPageTheme.secondaryColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _currentPageTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _currentPage == _pages.length - 1
                  ? Text(
                      "Get Started",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.surface,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    )
                  : Icon(
                      Icons.arrow_forward_rounded,
                      color: theme.colorScheme.surface,
                      size: 26,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntroPage {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final IconData icon;

  IntroPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.icon,
  });
}

class PageTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  PageTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}