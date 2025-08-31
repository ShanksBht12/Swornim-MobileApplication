// widgets/client/dashboard/service_grid.dart
// Add this import at the top if not already present
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:swornim/pages/service_providers/venues/venuelistpage.dart';
import 'package:swornim/pages/service_providers/photographer/photographer_list_page.dart';
import 'package:swornim/pages/service_providers/makeupartist/makeupartist_list_page.dart';
import 'package:swornim/pages/service_providers/decorator/decorator_list_page.dart';
import 'package:swornim/pages/service_providers/caterer/caterer_list_page.dart';
import 'package:swornim/main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swornim/pages/events/event_list_page.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  void _handleServiceTap(String title, BuildContext context) {
    if (title == 'Venues') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VenueListPage()));
    } else if (title == 'Photo' || title == 'Photography') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PhotographerListPage()));
    } else if (title == 'Makeup') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MakeupArtistListPage()));
    } else if (title == 'Decor') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DecoratorListPage()));
    } else if (title == 'Catering') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CatererListPage()));
    } else if (title == 'Events') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EventListPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Enhanced Services section header
        Container(
          margin: const EdgeInsets.only(bottom: 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => GradientTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'Our Services',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Professional services for your special events',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: GradientTheme.primaryGradient.colors.first.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: GradientButton(
                  onPressed: () {
                    // Handle view all services
                  },
                  text: 'View All  ›',
                  gradient: GradientTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600, 
                    color: Colors.white,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Services grid with 2 cards per row
        Column(
          children: [
            // First row
            Row(
              children: [
                Expanded(
                  child: _buildCompactServiceCard(
                    LucideIcons.building,
                    'Venues',
                    'Event spaces',
                    context,
                    0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactServiceCard(
                    LucideIcons.camera,
                    'Photo',
                    'Photography',
                    context,
                    1,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Second row
            Row(
              children: [
                Expanded(
                  child: _buildCompactServiceCard(
                    LucideIcons.brush,
                    'Makeup',
                    'Beauty service',
                    context,
                    2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactServiceCard(
                    LucideIcons.sparkles,
                    'Decor',
                    'Event styling',
                    context,
                    3,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Third row
            Row(
              children: [
                Expanded(
                  child: _buildCompactServiceCard(
                    LucideIcons.utensils,
                    'Catering',
                    'Food service',
                    context,
                    4,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactServiceCard(
                    LucideIcons.calendar,
                    'Events',
                    'Public events',
                    context,
                    5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactServiceCard(
    IconData icon,
    String title,
    String subtitle,
    BuildContext context,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _handleServiceTap(title, context);
                },
                borderRadius: BorderRadius.circular(12),
                splashColor: colorScheme.primary.withOpacity(0.1),
                highlightColor: colorScheme.primary.withOpacity(0.05),
                child: Container(
                  height: 78, // Slightly smaller height
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                    color: isDark 
                      ? colorScheme.surface
                      : Colors.white,
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Simple icon container
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontSize: 14,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 2),
                            
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Simple arrow
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

