import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/services/service_provider_profile_service.dart';
import 'package:swornim/pages/services/simple_image_service.dart';
import 'package:swornim/pages/widgets/common/simple_portfolio_gallery.dart';
import 'package:swornim/config/app_config.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_factory.dart';
import 'package:swornim/pages/providers/service_providers/service_provider_manager.dart';
import 'package:swornim/pages/service_providers/venues/venue_detail_page.dart';
import 'package:swornim/pages/service_providers/photographer/photographer_detail_page.dart';
import 'package:swornim/pages/service_providers/makeupartist/makeupartist_detail_page.dart';
import 'package:swornim/pages/service_providers/caterer/caterer_detail_page.dart';
import 'package:swornim/pages/service_providers/decorator/decorator_detail_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:swornim/pages/providers/auth/auth_provider.dart';

class ProfileManagement extends ConsumerStatefulWidget {
  final User provider;
  
  const ProfileManagement({required this.provider, Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileManagement> createState() => _ProfileManagementState();
}

class _ProfileManagementState extends ConsumerState<ProfileManagement> {
  bool _isLoading = false;
  bool _isDeleting = false; // Add delete confirmation state
  Map<String, dynamic> _profileData = {};
  List<String> _portfolioImages = [];
  String? _currentProfileImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = await ServiceProviderProfileService.getProfile(
        userType: widget.provider.userType,
      );

      if (!mounted) return;

      if (profileData != null) {
        debugPrint('DEBUG: Profile data loaded: $profileData');
        setState(() {
          _profileData = profileData;
          _currentProfileImageUrl = profileData['profileImage'] ?? profileData['image'];
          
          // Load portfolio images based on user type
          if (widget.provider.userType == UserType.venue) {
            // Venues store portfolio images in 'images' field
            _portfolioImages = List<String>.from(profileData['images'] ?? []);
            debugPrint('DEBUG: Loaded venue images: $_portfolioImages');
          } else {
            // Other service providers use 'portfolioImages' or 'portfolio'
            _portfolioImages = List<String>.from(profileData['portfolioImages'] ?? profileData['portfolio'] ?? []);
            debugPrint('DEBUG: Loaded portfolio images: $_portfolioImages');
          }
        });
        debugPrint('DEBUG: Current profile image URL set to: $_currentProfileImageUrl');
      } else {
        // No profile exists, use default values
        setState(() {
          _profileData = ServiceProviderProfileService.getProfileFields(widget.provider.userType);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatRating(dynamic rating) {
    if (rating == null) return '0.0';
    
    if (rating is num) {
      return rating.toStringAsFixed(1);
    } else if (rating is String) {
      final numValue = double.tryParse(rating);
      return numValue?.toStringAsFixed(1) ?? '0.0';
    }
    
    return '0.0';
  }

  String _getUserTypeDisplayName(UserType userType) {
    switch (userType) {
      case UserType.photographer:
        return 'Photographer';
      case UserType.makeupArtist:
        return 'Makeup Artist';
      case UserType.decorator:
        return 'Decorator';
      case UserType.venue:
        return 'Venue Owner';
      case UserType.caterer:
        return 'Caterer';
      default:
        return 'Service Provider';
    }
  }

  String _getServiceProviderType() {
    switch (widget.provider.userType) {
      case UserType.photographer:
        return 'photographers';
      case UserType.makeupArtist:
        return 'makeup-artists';
      case UserType.decorator:
        return 'decorators';
      case UserType.venue:
        return 'venues';
      case UserType.caterer:
        return 'caterers';
      case UserType.eventOrganizer:
        return 'event-organizers';
      default:
        return 'photographers';
    }
  }

  Future<void> _removePortfolioImage(String imageUrl) async {
    try {
      final success = await SimpleImageService.deleteImage(
        imageUrl: imageUrl,
        endpoint: '${AppConfig.getServiceProviderUrl(_getServiceProviderType())}/portfolio/images',
        body: {'imageUrl': imageUrl},
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _portfolioImages = _portfolioImages.where((img) => img != imageUrl).toList();
          
          // Update profile data with the correct field name based on user type
          if (widget.provider.userType == UserType.venue) {
            _profileData['images'] = _portfolioImages; // Venues use 'images'
          } else {
            _profileData['portfolioImages'] = _portfolioImages; // Others use 'portfolioImages'
          }
          
          // Clear cache for the removed image
          CachedNetworkImage.evictFromCache(imageUrl);
        });
        _showSuccessSnackBar('Portfolio image removed successfully!');
        
        // Force UI refresh
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      } else {
        _showErrorSnackBar('Failed to remove portfolio image');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error removing portfolio image: $e');
      }
    }
  }

  // Add this method to handle account deletion
  Future<void> _deleteAccount() async {
    try {
      setState(() {
        _isDeleting = true;
      });

      // Make API call to delete user account
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/users/${widget.provider.id}'),
        headers: await ref.read(authProvider.notifier).getValidAuthHeaders(),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Success - logout and navigate to login
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
          // Optionally, show a snackbar after navigation if needed
        }
      } else {
        // Handle error
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to delete account';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error deleting account: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // Add this method to show delete confirmation dialog
  void _showDeleteAccountDialog() {
    final TextEditingController confirmController = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'This action cannot be undone!',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The following will be permanently deleted:',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...{
                      '• Your profile and account information',
                      '• All portfolio images and content',
                      '• Service packages and pricing',
                      '• Reviews and ratings',
                      if (widget.provider.userType == UserType.eventOrganizer)
                        '• All created events and ticket bookings',
                      '• Booking history and records',
                    }.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'If you have active bookings, you must complete or cancel them before deleting your account.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: !_isDeleting ? () {
                Navigator.of(context).pop();
                _showFinalDeleteConfirmation();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isDeleting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  // Add final confirmation dialog
  void _showFinalDeleteConfirmation() {
    final TextEditingController confirmController = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Final Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To confirm deletion, please type "DELETE" below:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                onChanged: (value) {
                  setDialogState(() {
                    canDelete = value.toUpperCase() == 'DELETE';
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    Icons.keyboard,
                    color: Colors.red,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account to be deleted:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            widget.provider.email,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: canDelete && !_isDeleting ? () {
                Navigator.of(context).pop();
                _deleteAccount();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isDeleting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Profile Image
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: _currentProfileImageUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: _currentProfileImageUrl!,
                                      width: 95,
                                      height: 95,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => CircularProgressIndicator(
                                        color: colorScheme.primary,
                                        strokeWidth: 2,
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.person,
                                        size: 50,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 50,
                                    color: colorScheme.primary,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Business Name
                        Text(
                          _profileData['businessName'] ?? widget.provider.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Service Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getUserTypeDisplayName(widget.provider.userType),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Rating and Reviews
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatRating(_profileData['rating']),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_profileData['totalReviews'] ?? 0} reviews',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Profile Options
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  _buildQuickStatsRow(theme, colorScheme),
                  const SizedBox(height: 24),
                  
                  // Profile Management Section
                  _buildSectionHeader('Profile Management', Icons.person, theme, colorScheme.primary),
                  const SizedBox(height: 16),
                  _buildProfileManagementOptions(theme, colorScheme),
                  const SizedBox(height: 32),
                  
                  // Business Section
                  _buildSectionHeader('Business Settings', Icons.business, theme, colorScheme.primary),
                  const SizedBox(height: 16),
                  _buildBusinessOptions(theme, colorScheme),
                  const SizedBox(height: 32),
                  
                  // Portfolio Section
                  _buildSectionHeader('Portfolio & Gallery', Icons.photo_library, theme, colorScheme.primary),
                  const SizedBox(height: 16),
                  _buildPortfolioPreview(theme, colorScheme),
                  const SizedBox(height: 32),
                  
                  // Account Section
                  _buildSectionHeader('Account & Privacy', Icons.security, theme, colorScheme.primary),
                  const SizedBox(height: 16),
                  _buildAccountOptions(theme, colorScheme),
                  
                  // Bottom spacing
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Projects',
            '${_profileData['totalProjects'] ?? 0}',
            Icons.work,
            colorScheme.primary,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Portfolio Images',
            '${_portfolioImages.length}',
            Icons.photo,
            colorScheme.secondary,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rating',
            _formatRating(_profileData['rating']),
            Icons.star,
            Colors.amber,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme, Color customColor) {
    final color = customColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileManagementOptions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildOptionTile(
          'Edit Basic Information',
          'Update your name, description, and contact details',
          Icons.edit,
          () => _navigateToEditProfile(ProfileSection.basicInfo),
          theme,
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          'Change Profile Picture',
          'Update your profile photo',
          Icons.camera_alt,
          () => _navigateToEditProfile(ProfileSection.profilePicture),
          theme,
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          'Service Pricing',
          'Manage your rates and packages',
          Icons.attach_money,
          () => _navigateToEditProfile(ProfileSection.pricing),
          theme,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildBusinessOptions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildOptionTile(
          'Service Specializations',
          'Update your skills and service categories',
          Icons.category,
          () => _navigateToEditProfile(ProfileSection.services),
          theme,
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          'Availability Settings',
          'Manage your booking availability',
          Icons.schedule,
          () => _navigateToEditProfile(ProfileSection.availability),
          theme,
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          'Business Hours',
          'Set your working hours and days',
          Icons.access_time,
          () => _showComingSoon(),
          theme,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildPortfolioPreview(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildOptionTile(
          'Manage Portfolio',
          'Add, edit, or remove your work samples',
          Icons.photo_library,
          () => _navigateToEditProfile(ProfileSection.portfolio),
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        
        // Portfolio Preview
        if (_portfolioImages.isNotEmpty) ...[
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _portfolioImages.length > 5 ? 5 : _portfolioImages.length,
              itemBuilder: (context, index) {
                if (index == 4 && _portfolioImages.length > 5) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${_portfolioImages.length - 4}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'more',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _portfolioImages[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.broken_image,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No portfolio images yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your best work to showcase your skills',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAccountOptions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildOptionTile(
          'Privacy Settings',
          'Control who can see your profile information',
          Icons.privacy_tip,
          () => _showComingSoon(),
          theme,
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          'Notification Preferences',
          'Manage your notification settings',
          Icons.notifications,
          () => _showComingSoon(),
          theme,
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          'Account Settings',
          'Password, email, and account security',
          Icons.settings,
          () => _showComingSoon(),
          theme,
          colorScheme,
        ),
        const SizedBox(height: 20),
        _buildSectionHeader('Danger Zone', Icons.warning, theme, Colors.red[700] ?? Colors.red),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 22,
              ),
            ),
            title: Text(
              'Delete Account',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            subtitle: Text(
              'Permanently delete your account and all data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.red,
              size: 16,
            ),
            onTap: _showDeleteAccountDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.onSurfaceVariant,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _navigateToEditProfile(ProfileSection section) {
    // Navigate to specific edit profile page based on section
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          provider: widget.provider,
          section: section,
          profileData: _profileData,
          portfolioImages: _portfolioImages,
          currentProfileImageUrl: _currentProfileImageUrl,
          onProfileUpdated: (updatedData, updatedImages, updatedProfileUrl) {
            setState(() {
              _profileData = updatedData;
              _portfolioImages = updatedImages;
              _currentProfileImageUrl = updatedProfileUrl;
            });
          },
        ),
      ),
    );
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Coming Soon'),
        content: const Text('This feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

enum ProfileSection {
  basicInfo,
  profilePicture,
  pricing,
  services,
  availability,
  portfolio,
}

// Detailed edit profile page with all the original logic
class EditProfilePage extends ConsumerStatefulWidget {
  final User provider;
  final ProfileSection section;
  final Map<String, dynamic> profileData;
  final List<String> portfolioImages;
  final String? currentProfileImageUrl;
  final Function(Map<String, dynamic>, List<String>, String?) onProfileUpdated;

  const EditProfilePage({
    Key? key,
    required this.provider,
    required this.section,
    required this.profileData,
    required this.portfolioImages,
    required this.currentProfileImageUrl,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isImageLoading = false;
  
  // Form controllers
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  
  // Profile data
  Map<String, dynamic> _profileData = {};
  List<String> _portfolioImages = [];
  File? _selectedProfileImage;
  String? _currentProfileImageUrl;
  
  // Lists for different service provider types
  Map<String, List<String>> _listFields = {};
  
  // Boolean fields
  Map<String, bool> _booleanFields = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeControllers();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  void _initializeData() {
    _profileData = Map.from(widget.profileData);
    _portfolioImages = List.from(widget.portfolioImages);
    _currentProfileImageUrl = widget.currentProfileImageUrl;
    _loadListFields(_profileData);
    _loadBooleanFields(_profileData);
  }

  void _initializeControllers() {
    final fields = ServiceProviderProfileService.getProfileFields(widget.provider.userType);
    fields.forEach((key, value) {
      if (value is String || value is num) {
        _controllers[key] = TextEditingController();
        _focusNodes[key] = FocusNode();
      }
    });
    _populateControllers();
  }

  void _loadListFields(Map<String, dynamic> data) {
    final fieldTypes = ServiceProviderProfileService.getFieldTypes(widget.provider.userType);
    fieldTypes.forEach((key, type) {
      if (type == 'list') {
        _listFields[key] = List<String>.from(data[key] ?? []);
      }
    });
  }

  void _loadBooleanFields(Map<String, dynamic> data) {
    final fieldTypes = ServiceProviderProfileService.getFieldTypes(widget.provider.userType);
    fieldTypes.forEach((key, type) {
      if (type == 'boolean') {
        _booleanFields[key] = data[key] ?? false;
      }
    });
  }

  void _populateControllers() {
    _controllers.forEach((key, controller) {
      final value = _profileData[key];
      if (value != null) {
        controller.text = value.toString();
      }
    });
  }

  Future<void> _saveProfile() async {
    // Check if form is available and validate
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('DEBUG: Starting profile save...');
      
      // Collect form data
      final formData = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          final fieldTypes = ServiceProviderProfileService.getFieldTypes(widget.provider.userType);
          final fieldType = fieldTypes[key];
          
          if (fieldType == 'number') {
            // Handle integer fields specifically
            if (key == 'experienceYears' || key == 'capacity' || key == 'minGuests' || key == 'maxGuests') {
              final intValue = int.tryParse(controller.text);
              if (intValue != null) {
                formData[key] = intValue;
              }
            } else {
              // Handle decimal fields
              final numValue = double.tryParse(controller.text);
              if (numValue != null) {
                formData[key] = numValue;
              }
            }
          } else {
            formData[key] = controller.text;
          }
        }
      });

      // Add list fields
      _listFields.forEach((key, value) {
        if (value.isNotEmpty) {
          formData[key] = value;
        }
      });
      
      // Add boolean fields
      _booleanFields.forEach((key, value) {
        formData[key] = value;
      });

      // Filter out system-managed fields
      final systemManagedFields = widget.provider.userType == UserType.venue 
          ? ['rating', 'totalReviews', 'images', 'image'] // Venues use 'images' and 'image'
          : ['rating', 'totalReviews', 'portfolioImages', 'profileImage']; // Others use 'portfolioImages' and 'profileImage'
      final filteredFormData = <String, dynamic>{};
      formData.forEach((key, value) {
        if (!systemManagedFields.contains(key)) {
          filteredFormData[key] = value;
        }
      });

      debugPrint('DEBUG: Calling updateProfile with filteredFormData: $filteredFormData');
      
      final updatedProfile = await ServiceProviderProfileService.updateProfile(
        userType: widget.provider.userType,
        profileData: filteredFormData,
        profileImage: _selectedProfileImage,
      );

      if (!mounted) return;

      debugPrint('DEBUG: Updated profile response: $updatedProfile');
      debugPrint('DEBUG: Portfolio images in response: ${updatedProfile['portfolioImages']}');

      setState(() {
        _profileData = updatedProfile;
        _selectedProfileImage = null;
        
        // Handle different profile image field names for different service providers
        String? newProfileImageUrl;
        if (widget.provider.userType == UserType.venue) {
          newProfileImageUrl = updatedProfile['image'];
        } else {
          newProfileImageUrl = updatedProfile['profileImage'] ?? updatedProfile['image'];
        }
        
        if (newProfileImageUrl != null) {
          _currentProfileImageUrl = newProfileImageUrl;
          debugPrint('DEBUG: Updated profile image URL to: $_currentProfileImageUrl');
        }
        
        // Update portfolio images from the response
        if (widget.provider.userType == UserType.venue) {
          // Venues store portfolio images in 'images' field
          if (updatedProfile['images'] != null) {
            _portfolioImages = List<String>.from(updatedProfile['images']);
            debugPrint('DEBUG: Updated venue images to: $_portfolioImages');
          }
        } else {
          // Other service providers use 'portfolioImages' or 'portfolio'
          if (updatedProfile['portfolioImages'] != null) {
            _portfolioImages = List<String>.from(updatedProfile['portfolioImages']);
            debugPrint('DEBUG: Updated _portfolioImages to: $_portfolioImages');
          } else if (updatedProfile['portfolio'] != null) {
            _portfolioImages = List<String>.from(updatedProfile['portfolio']);
            debugPrint('DEBUG: Updated _portfolioImages from portfolio field: $_portfolioImages');
          }
        }
        
        // Force cache refresh for the new image
        if (_currentProfileImageUrl != null) {
          CachedNetworkImage.evictFromCache(_currentProfileImageUrl!);
        }
      });

      // Additional UI refresh
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {});
        }
      });

      _showSuccessSnackBar('Profile updated successfully!');
      
      // Invalidate all service provider lists so clients see updates
      for (final type in ServiceProviderType.values) {
        ref.invalidate(serviceProvidersProvider(type));
      }
      // Invalidate the detail provider for the updated provider
      final providerId = widget.provider.id;
      switch (widget.provider.userType) {
        case ServiceProviderType.venue:
          ref.invalidate(venueDetailProvider(providerId));
          break;
        case ServiceProviderType.photographer:
          ref.invalidate(photographerDetailProvider(providerId));
          break;
        case ServiceProviderType.makeupArtist:
          ref.invalidate(makeupArtistDetailProvider(providerId));
          break;
        case ServiceProviderType.caterer:
          ref.invalidate(catererDetailProvider(providerId));
          break;
        case ServiceProviderType.decorator:
          ref.invalidate(decoratorDetailProvider(providerId));
          break;
        case ServiceProviderType.eventOrganizer:
          // Add event organizer detail provider invalidation if/when implemented
          break;
        case UserType.client:
        default:
          // No detail provider to invalidate for client or unknown types
          break;
      }
      
      // Callback to parent
      widget.onProfileUpdated(_profileData, _portfolioImages, _currentProfileImageUrl);
      
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    if (!mounted) return;
    
    setState(() {
      _isImageLoading = true;
    });

    try {
      debugPrint('DEBUG: Picking profile image...');
      
      final image = await SimpleImageService.showImageSourceDialog(
        context: context,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (!mounted) return;

      debugPrint('DEBUG: Selected image: ${image?.path}');
      
      if (image != null) {
        // Validate file
        if (!SimpleImageService.isValidImageFile(image)) {
          _showErrorSnackBar('Please select a valid image file (JPG, PNG, GIF, WebP)');
          return;
        }

        if (!SimpleImageService.isFileSizeValid(image, maxSizeMB: 5.0)) {
          _showErrorSnackBar('Image size must be less than 5MB');
          return;
        }

        setState(() {
          _selectedProfileImage = image;
          // Force UI update by clearing the current URL temporarily
          _currentProfileImageUrl = null;
        });
        debugPrint('DEBUG: Profile image set to: ${_selectedProfileImage?.path}');
        _showSuccessSnackBar('Image selected successfully');

        // Trigger a rebuild after a short delay to show the new image
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error picking profile image: $e');
      if (mounted) {
        _showErrorSnackBar('Error selecting image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  Future<void> _removePortfolioImage(String imageUrl) async {
    try {
      final success = await SimpleImageService.deleteImage(
        imageUrl: imageUrl,
        endpoint: '${AppConfig.getServiceProviderUrl(_getServiceProviderType())}/portfolio/images',
        body: {'imageUrl': imageUrl},
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _portfolioImages = _portfolioImages.where((img) => img != imageUrl).toList();
          
          // Update profile data with the correct field name based on user type
          if (widget.provider.userType == UserType.venue) {
            _profileData['images'] = _portfolioImages; // Venues use 'images'
          } else {
            _profileData['portfolioImages'] = _portfolioImages; // Others use 'portfolioImages'
          }
          
          // Clear cache for the removed image
          CachedNetworkImage.evictFromCache(imageUrl);
        });
        _showSuccessSnackBar('Portfolio image removed successfully!');
        
        // Force UI refresh
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      } else {
        _showErrorSnackBar('Failed to remove portfolio image');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error removing portfolio image: $e');
      }
    }
  }

  String _getServiceProviderType() {
    switch (widget.provider.userType) {
      case UserType.photographer:
        return 'photographers';
      case UserType.makeupArtist:
        return 'makeup-artists';
      case UserType.decorator:
        return 'decorators';
      case UserType.venue:
        return 'venues';
      case UserType.caterer:
        return 'caterers';
      case UserType.eventOrganizer:
        return 'event-organizers';
      default:
        return 'photographers';
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // List management methods
  void _addListItem(String fieldName, String item) {
    setState(() {
      if (!_listFields[fieldName]!.contains(item)) {
        _listFields[fieldName]!.add(item);
      }
    });
  }

  void _removeListItem(String fieldName, String item) {
    setState(() {
      _listFields[fieldName]!.remove(item);
    });
  }

  IconData _getIconForField(String fieldName) {
    switch (fieldName) {
      // Business fields
      case 'businessName':
        return Icons.store;
      case 'description':
        return Icons.description;
      case 'experience':
        return Icons.work;
      case 'experienceYears':
        return Icons.work;
      
      // Pricing fields
      case 'hourlyRate':
      case 'sessionRate':
      case 'bridalPackageRate':
      case 'packageStartingPrice':
      case 'pricePerHour':
      case 'pricePerPerson':
        return Icons.attach_money;
      
      // Capacity fields
      case 'capacity':
      case 'minGuests':
      case 'maxGuests':
        return Icons.people;
      
      // Service-specific boolean fields
      case 'offersHairServices':
        return Icons.content_cut;
      case 'travelsToClient':
        return Icons.directions_car;
      case 'offersFlowerArrangements':
        return Icons.local_florist;
      case 'offersLighting':
        return Icons.lightbulb;
      case 'offersRentals':
        return Icons.inventory;
      case 'offersEquipment':
        return Icons.kitchen;
      case 'offersWaiters':
        return Icons.people;
      case 'isAvailable':
        return Icons.event_available;
      case 'acceptsOnlineBookings':
        return Icons.online_prediction;
      case 'offersConsultation':
        return Icons.chat;
      case 'providesEquipment':
        return Icons.build;
      case 'hasInsurance':
        return Icons.security;
      case 'isVerified':
        return Icons.verified;
      default:
        return Icons.edit;
    }
  }

  // Helper methods for form field configuration
  TextInputType? _getKeyboardTypeForField(String fieldName) {
    switch (fieldName) {
      case 'hourlyRate':
      case 'sessionRate':
      case 'bridalPackageRate':
      case 'packageStartingPrice':
      case 'pricePerHour':
      case 'pricePerPerson':
      case 'capacity':
      case 'experienceYears':
      case 'minGuests':
      case 'maxGuests':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  String? _getPrefixForField(String fieldName) {
    switch (fieldName) {
      case 'hourlyRate':
      case 'sessionRate':
      case 'bridalPackageRate':
      case 'packageStartingPrice':
      case 'pricePerHour':
      case 'pricePerPerson':
        return 'Rs. ';
      default:
        return null;
    }
  }

  String? _getSuffixForField(String fieldName) {
    switch (fieldName) {
      case 'capacity':
      case 'minGuests':
      case 'maxGuests':
        return ' people';
      case 'experienceYears':
        return ' years';
      default:
        return null;
    }
  }

  int _getMaxLinesForField(String fieldName) {
    switch (fieldName) {
      case 'description':
      case 'experience':
        return 4;
      default:
        return 1;
    }
  }

  String? Function(String?)? _getValidatorForField(String fieldName) {
    return (value) {
      if (value == null || value.isEmpty) {
        return '${fieldName.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim()} is required';
      }
      
      switch (fieldName) {
        case 'hourlyRate':
        case 'sessionRate':
        case 'bridalPackageRate':
        case 'packageStartingPrice':
        case 'pricePerHour':
        case 'pricePerPerson':
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          break;
        case 'capacity':
        case 'experienceYears':
        case 'minGuests':
        case 'maxGuests':
          if (int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          break;
      }
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String title = _getSectionTitle(widget.section);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _buildSectionContent(theme, colorScheme),
      bottomNavigationBar: _buildActionButtons(theme, colorScheme),
    );
  }

  Widget _buildSectionContent(ThemeData theme, ColorScheme colorScheme) {
    switch (widget.section) {
      case ProfileSection.basicInfo:
        return _buildBasicInfoSection(theme, colorScheme);
      case ProfileSection.profilePicture:
        return _buildProfilePictureSection(theme, colorScheme);
      case ProfileSection.pricing:
        return _buildPricingSection(theme, colorScheme);
      case ProfileSection.services:
        return _buildServicesSection(theme, colorScheme);
      case ProfileSection.availability:
        return _buildAvailabilitySection(theme, colorScheme);
      case ProfileSection.portfolio:
        return _buildPortfolioSection(theme, colorScheme);
    }
  }

  Widget _buildBasicInfoSection(ThemeData theme, ColorScheme colorScheme) {
    final fieldLabels = ServiceProviderProfileService.getFieldLabels(widget.provider.userType);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your basic profile information',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            
            // Basic info fields only
            ..._controllers.entries.where((entry) {
              return ['businessName', 'description', 'experience'].contains(entry.key);
            }).map((entry) {
              final key = entry.key;
              final controller = entry.value;
              final focusNode = _focusNodes[key]!;
              
              return _buildEnhancedFormField(
                controller: controller,
                focusNode: focusNode,
                label: fieldLabels[key] ?? key,
                icon: _getIconForField(key),
                keyboardType: _getKeyboardTypeForField(key),
                prefix: _getPrefixForField(key),
                suffix: _getSuffixForField(key),
                maxLines: _getMaxLinesForField(key),
                validator: _getValidatorForField(key),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Picture',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a professional photo that represents you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white,
                          child: _isImageLoading
                              ? CircularProgressIndicator(
                                  color: colorScheme.primary,
                                  strokeWidth: 3,
                                )
                              : _selectedProfileImage != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _selectedProfileImage!,
                                        width: 155,
                                        height: 155,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _currentProfileImageUrl != null
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: _currentProfileImageUrl!,
                                            width: 155,
                                            height: 155,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => CircularProgressIndicator(
                                              color: colorScheme.primary,
                                              strokeWidth: 3,
                                            ),
                                            errorWidget: (context, url, error) => Icon(
                                              Icons.person,
                                              size: 80,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 80,
                                          color: colorScheme.primary,
                                        ),
                        ),
                      ),
                      if (!_isImageLoading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _pickProfileImage,
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                ElevatedButton.icon(
                  onPressed: _pickProfileImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Choose New Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Supported formats: JPG, PNG, GIF, WebP\nMaximum size: 5MB',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ThemeData theme, ColorScheme colorScheme) {
    final fieldLabels = ServiceProviderProfileService.getFieldLabels(widget.provider.userType);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Pricing',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your competitive rates and pricing packages',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            
            // Pricing fields only
            ..._controllers.entries.where((entry) {
              return ['hourlyRate', 'sessionRate', 'bridalPackageRate', 'packageStartingPrice', 'pricePerHour', 'pricePerPerson'].contains(entry.key);
            }).map((entry) {
              final key = entry.key;
              final controller = entry.value;
              final focusNode = _focusNodes[key]!;
              
              return _buildEnhancedFormField(
                controller: controller,
                focusNode: focusNode,
                label: fieldLabels[key] ?? key,
                icon: _getIconForField(key),
                keyboardType: _getKeyboardTypeForField(key),
                prefix: _getPrefixForField(key),
                suffix: _getSuffixForField(key),
                maxLines: _getMaxLinesForField(key),
                validator: _getValidatorForField(key),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(ThemeData theme, ColorScheme colorScheme) {
    final fieldLabels = ServiceProviderProfileService.getFieldLabels(widget.provider.userType);
    final fieldTypes = ServiceProviderProfileService.getFieldTypes(widget.provider.userType);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Specializations',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your skills, specializations and service offerings',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // List fields
          ...fieldTypes.entries.where((entry) => entry.value == 'list').map((entry) {
            final fieldName = entry.key;
            final items = _listFields[fieldName] ?? [];
            return _buildEnhancedListField(
              title: fieldLabels[fieldName] ?? fieldName,
              items: items,
              onAdd: (item) => _addListItem(fieldName, item),
              onRemove: (item) => _removeListItem(fieldName, item),
              colorScheme: colorScheme,
              theme: theme,
            );
          }),
          
          // Boolean fields
          ...fieldTypes.entries.where((entry) => entry.value == 'boolean').map((entry) {
            final fieldName = entry.key;
            final value = _booleanFields[fieldName] ?? false;
            return _buildEnhancedSwitchTile(
              title: fieldLabels[fieldName] ?? fieldName,
              value: value,
              onChanged: (newValue) {
                setState(() {
                  _booleanFields[fieldName] = newValue;
                });
              },
              icon: _getIconForField(fieldName),
              colorScheme: colorScheme,
              theme: theme,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control when you\'re available for bookings',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildEnhancedSwitchTile(
            title: 'Available for Bookings',
            subtitle: 'Accept new booking requests',
            value: _profileData['isAvailable'] ?? true,
            onChanged: (value) {
              setState(() {
                _profileData['isAvailable'] = value;
              });
            },
            icon: (_profileData['isAvailable'] ?? true) ? Icons.check_circle : Icons.cancel,
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Management',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Showcase your best work to attract clients',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          SimplePortfolioGallery(
            images: _portfolioImages,
            serviceProviderType: _getServiceProviderType(),
            isEditable: true,
            onImageAdded: (url) {
              setState(() {
                _portfolioImages = [..._portfolioImages, url];
                
                // Update profile data with the correct field name based on user type
                if (widget.provider.userType == UserType.venue) {
                  _profileData['images'] = _portfolioImages; // Venues use 'images'
                } else {
                  _profileData['portfolioImages'] = _portfolioImages; // Others use 'portfolioImages'
                }
              });
              // Force UI refresh
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {});
                }
              });
            },
            onImageRemoved: _removePortfolioImage,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? prefix,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          prefixText: prefix,
          suffixText: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedListField({
    required String title,
    required List<String> items,
    required Function(String) onAdd,
    required Function(String) onRemove,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showAddItemDialog(title, onAdd),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No $title added yet',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => Chip(
                label: Text(
                  item,
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: colorScheme.error,
                ),
                onDeleted: () => onRemove(item),
                backgroundColor: colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: value 
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value 
                ? colorScheme.primary.withOpacity(0.3)
                : colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: SwitchListTile(
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: subtitle != null ? Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ) : null,
          value: value,
          onChanged: onChanged,
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value 
                  ? colorScheme.primary.withOpacity(0.1)
                  : colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value 
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          activeColor: colorScheme.primary,
          activeTrackColor: colorScheme.primary.withOpacity(0.3),
          inactiveThumbColor: colorScheme.outline,
          inactiveTrackColor: colorScheme.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(String title, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Add $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: title,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter a new $title to add to your profile',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSectionTitle(ProfileSection section) {
    switch (section) {
      case ProfileSection.basicInfo:
        return 'Basic Information';
      case ProfileSection.profilePicture:
        return 'Profile Picture';
      case ProfileSection.pricing:
        return 'Service Pricing';
      case ProfileSection.services:
        return 'Service Specializations';
      case ProfileSection.availability:
        return 'Availability Settings';
      case ProfileSection.portfolio:
        return 'Portfolio Management';
    }
  }
}