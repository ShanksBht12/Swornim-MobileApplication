import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/models/user/user.dart';
import 'package:swornim/pages/models/bookings/service_package.dart';
import 'package:swornim/pages/models/bookings/booking.dart';
import 'package:swornim/pages/providers/bookings/bookings.dart';
import 'package:swornim/pages/serviceprovider_dashboard/widgets/package_form_dialog.dart';
import 'package:swornim/pages/models/user/user_types.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';

class PackageManagement extends ConsumerStatefulWidget {
  final User provider;
  
  const PackageManagement({required this.provider, Key? key}) : super(key: key);

  @override
  ConsumerState<PackageManagement> createState() => _PackageManagementState();
}

class _PackageManagementState extends ConsumerState<PackageManagement> 
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _showActiveOnly = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final packagesAsync = ref.watch(packagesProvider(widget.provider.id));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.background,
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          // Enhanced Header with Search and Actions
          _buildEnhancedHeader(theme, colorScheme),
          
          // Packages List with animations
          Expanded(
            child: packagesAsync.when(
              data: (packages) => _buildPackagesList(packages, theme, colorScheme),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(theme, colorScheme, error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title with Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Package Management',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Create and manage your service packages',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search Bar with Enhanced Design
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search packages by name or description...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filter and Action Row
          Row(
            children: [
              // Active Only Filter
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _showActiveOnly
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          )
                        : null,
                    color: _showActiveOnly ? null : colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: _showActiveOnly
                        ? null
                        : Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showActiveOnly = !_showActiveOnly;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showActiveOnly ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 18,
                              color: _showActiveOnly
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Active Only',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _showActiveOnly
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Create Package Button
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 180),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _createNewPackage(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Create Package',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading packages...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesList(List<ServicePackage> packages, ThemeData theme, ColorScheme colorScheme) {
    final filteredPackages = _getFilteredPackages(packages);
    
    if (filteredPackages.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPackages.length,
      itemBuilder: (context, index) {
        final package = filteredPackages[index];
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            ));
            
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildEnhancedPackageCard(package, theme, colorScheme),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedPackageCard(ServicePackage package, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: package.isActive
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.outline.withOpacity(0.1),
          width: package.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Package Header with Enhanced Design
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: package.isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.1),
                        colorScheme.secondary.withOpacity(0.05),
                      ],
                    )
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Enhanced Package Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: package.isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          )
                        : LinearGradient(
                            colors: [
                              colorScheme.surfaceVariant,
                              colorScheme.surfaceVariant.withOpacity(0.7),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: package.isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _getServiceTypeIcon(package.serviceType),
                    color: package.isActive ? Colors.white : colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Package Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              package.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: package.isActive 
                                  ? const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.withOpacity(0.2),
                                        Colors.grey.withOpacity(0.1),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              package.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: package.isActive ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        package.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Price and Duration Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Price',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          package.formattedPrice,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary.withOpacity(0.1),
                          colorScheme.secondary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Duration',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${package.durationHours}h',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Package Features with Enhanced Design
          if (package.features.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: package.features.take(4).map((feature) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.surfaceVariant.withOpacity(0.7),
                            colorScheme.surfaceVariant.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        feature,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )).toList(),
                  ),
                  if (package.features.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${package.features.length - 4} more features',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Enhanced Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _editPackage(context, package),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Edit',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // More Options Button
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _showPackageMenu(context, package),
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'More options',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.1),
                        colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No packages found',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create your first service package to start\nreceiving bookings from clients',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _createNewPackage(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Create Package',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme, String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.redAccent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading packages',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(packagesProvider(widget.provider.id));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ServicePackage> _getFilteredPackages(List<ServicePackage> packages) {
    List<ServicePackage> filtered = packages;

    // Apply active filter
    if (_showActiveOnly) {
      filtered = filtered.where((package) => package.isActive).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((package) {
        final query = _searchQuery.toLowerCase();
        return package.name.toLowerCase().contains(query) ||
               package.description.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  IconData _getServiceTypeIcon(ServiceType serviceType) {
    switch (serviceType) {
      case ServiceType.photography:
        return Icons.camera_alt;
      case ServiceType.makeup:
        return Icons.face;
      case ServiceType.decoration:
        return Icons.celebration;
      case ServiceType.venue:
        return Icons.location_on;
      case ServiceType.catering:
        return Icons.restaurant;
      case ServiceType.music:
        return Icons.music_note;
      case ServiceType.planning:
        return Icons.event_note;
    }
    return Icons.event; // Default fallback
  }

  // All the existing methods with enhanced error handling and loading states
  void _createNewPackage(BuildContext context) async {
    final fixedServiceType = serviceTypeFromUserType(widget.provider.userType);
    try {
      print('🔐 PackageManagement: Starting package creation for provider: ${widget.provider.id}');
      print('🔐 PackageManagement: Current auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      print('🔐 PackageManagement: Current auth state - user: ${ref.read(authProvider).user?.name}');
      
      final newPackage = await showDialog<ServicePackage>(
        context: context,
        builder: (context) => PackageFormDialog(
          onSubmit: (pkg) => Navigator.of(context).pop(pkg),
          fixedServiceType: fixedServiceType,
          providerId: widget.provider.id,
        ),
      );
      
      print('🔐 PackageManagement: Dialog closed, newPackage: ${newPackage?.name}');
      
      if (newPackage != null) {
        print('🔐 PackageManagement: Package created in dialog, calling manager.createPackage');
        print('🔐 PackageManagement: Auth state before manager call - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        
        // Show loading state
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Creating package...'),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        final manager = ref.read(packageManagerProvider);
        await manager.createPackage(newPackage);
        
        print('🔐 PackageManagement: Package created successfully, invalidating provider');
        print('🔐 PackageManagement: Auth state after manager call - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        
        // Check if widget is still mounted before continuing
        if (!mounted) {
          print('🔐 PackageManagement: Widget disposed, stopping execution');
          return;
        }
        
        // Use invalidate instead of refresh to match the working pattern
        ref.invalidate(packagesProvider(widget.provider.id));
        
        print('🔐 PackageManagement: Provider invalidated, auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Package created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        print('🔐 PackageManagement: Success message shown, auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      } else {
        print('🔐 PackageManagement: Dialog was cancelled, no package created');
      }
    } catch (e, st) {
      print('🔐 PackageManagement: Error creating package: $e');
      print('🔐 PackageManagement: Stack trace: $st');
      
      // Only try to access ref if widget is still mounted
      if (mounted) {
        print('🔐 PackageManagement: Auth state after error - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to create package: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        print('🔐 PackageManagement: Widget disposed, cannot show error message');
      }
      debugPrint('Error creating package: $e\n$st');
    }
  }

  void _editPackage(BuildContext context, ServicePackage package) async {
    final fixedServiceType = serviceTypeFromUserType(widget.provider.userType);
    try {
      print('🔐 PackageManagement: Starting package edit for package: ${package.id}');
      print('🔐 PackageManagement: Current auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      print('🔐 PackageManagement: Current auth state - user: ${ref.read(authProvider).user?.name}');
      
      final updatedPackage = await showDialog<ServicePackage>(
        context: context,
        builder: (context) => PackageFormDialog(
          initialPackage: package,
          isEdit: true,
          onSubmit: (pkg) => Navigator.of(context).pop(pkg),
          fixedServiceType: fixedServiceType,
          providerId: widget.provider.id,
        ),
      );
      
      print('🔐 PackageManagement: Edit dialog closed, updatedPackage: ${updatedPackage?.name}');
      
      if (updatedPackage != null) {
        print('🔐 PackageManagement: Package updated in dialog, calling manager.updatePackage');
        print('🔐 PackageManagement: Auth state before manager call - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        
        // Show loading state
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Updating package...'),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        final manager = ref.read(packageManagerProvider);
        await manager.updatePackage(package.id, updatedPackage.toUpdateJson());
        
        print('🔐 PackageManagement: Package updated successfully, invalidating provider');
        print('🔐 PackageManagement: Auth state after manager call - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        
        // Check if widget is still mounted before continuing
        if (!mounted) {
          print('🔐 PackageManagement: Widget disposed, stopping execution');
          return;
        }
        
        // Use invalidate to match the working pattern
        ref.invalidate(packagesProvider(widget.provider.id));
        
        print('🔐 PackageManagement: Provider invalidated, auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Package updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        print('🔐 PackageManagement: Success message shown, auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      } else {
        print('🔐 PackageManagement: Edit dialog was cancelled, no package updated');
      }
    } catch (e, st) {
      print('🔐 PackageManagement: Error updating package: $e');
      print('🔐 PackageManagement: Stack trace: $st');
      
      // Only try to access ref if widget is still mounted
      if (mounted) {
        print('🔐 PackageManagement: Auth state after error - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update package: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        print('🔐 PackageManagement: Widget disposed, cannot show error message');
      }
      debugPrint('Error updating package: $e\n$st');
    }
  }

  void _duplicatePackage(BuildContext context, ServicePackage package) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy, color: Colors.white),
            const SizedBox(width: 8),
            Text('Duplicate package: ${package.name}'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _togglePackageStatus(ServicePackage package) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              package.isActive ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text('Toggle status for: ${package.name}'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showPackageMenu(BuildContext context, ServicePackage package) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPackageMenu(context, package),
    );
  }

  Widget _buildPackageMenu(BuildContext context, ServicePackage package) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.visibility, color: colorScheme.primary),
                  ),
                  title: const Text('View Details'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Show package details
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.analytics, color: colorScheme.secondary),
                  ),
                  title: const Text('View Analytics'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Show package analytics
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Delete Package', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePackage(context, package);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePackage(BuildContext context, ServicePackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Delete Package'),
          ],
        ),
        content: Text('Are you sure you want to delete "${package.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deletePackage(package);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _deletePackage(ServicePackage package) async {
    try {
      print('🔐 PackageManagement: Starting package deletion for package: ${package.id}');
      print('🔐 PackageManagement: Current auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      print('🔐 PackageManagement: Current auth state - user: ${ref.read(authProvider).user?.name}');
      
      // Show loading state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Deleting package...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      final manager = ref.read(packageManagerProvider);
      await manager.deletePackage(package.id);
      
      print('🔐 PackageManagement: Package deleted successfully, invalidating provider');
      print('🔐 PackageManagement: Auth state after manager call - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      
      // Check if widget is still mounted before continuing
      if (!mounted) {
        print('🔐 PackageManagement: Widget disposed, stopping execution');
        return;
      }
      
      // Use invalidate to match the working pattern
      ref.invalidate(packagesProvider(widget.provider.id));
      
      print('🔐 PackageManagement: Provider invalidated, auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Package deleted successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      print('🔐 PackageManagement: Success message shown, auth state - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
    } catch (e, st) {
      print('🔐 PackageManagement: Error deleting package: $e');
      print('🔐 PackageManagement: Stack trace: $st');
      
      // Only try to access ref if widget is still mounted
      if (mounted) {
        print('🔐 PackageManagement: Auth state after error - isLoggedIn: ${ref.read(authProvider).isLoggedIn}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to delete package: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        print('🔐 PackageManagement: Widget disposed, cannot show error message');
      }
      debugPrint('Error deleting package: $e\n$st');
    }
  }
}