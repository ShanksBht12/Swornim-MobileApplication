import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/map/routing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../providers/service_providers/models/base_service_provider.dart';
import '../providers/service_providers/models/photographer.dart';
import '../providers/service_providers/models/venue.dart';
import '../providers/service_providers/models/caterer.dart';
import '../providers/service_providers/models/decorator.dart';
import '../providers/service_providers/models/makeup_artist.dart';
import '../providers/service_providers/models/event_organizer.dart';
import '../providers/service_providers/service_provider_factory.dart';
import '../providers/service_providers/service_provider_manager.dart';
import '../../utils/location_service.dart';
// import '../../services/osm_routing_service.dart'; // Add this import
import '../../widgets/provider_marker.dart';
import '../../widgets/provider_info_popup.dart';

// Provider to fetch all service providers for the map
final mapProvidersProvider = FutureProvider<List<ServiceProvider>>((ref) async {
  final manager = ref.read(serviceProviderManagerProvider);
  final allProviders = <ServiceProvider>[];
  
  // Fetch all provider types
  final types = ServiceProviderType.values;
  for (final type in types) {
    final result = await manager.getServiceProviders(type);
    if (!result.isError && result.data != null) {
      allProviders.addAll(result.data!);
    }
  }
  
  return allProviders;
});

// Provider for search suggestions
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.isEmpty) return [];
  // Mock implementation - replace with actual search API
  return ['Kathmandu', 'Pokhara', 'Lalitpur', 'Bhaktapur']
      .where((city) => city.toLowerCase().contains(query.toLowerCase()))
      .toList();
});

// Provider for route data
final routeProvider = StateProvider<RouteResult?>((ref) => null);
final routeLoadingProvider = StateProvider<bool>((ref) => false);

class MapScreen extends ConsumerStatefulWidget {
  final String? filterType;
  const MapScreen({Key? key, this.filterType}) : super(key: key);

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final PopupController _popupController = PopupController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  LatLng? _userLocation;
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedFilterType;
  bool _showSearchSuggestions = false;
  bool _isListView = false;
  double _currentZoom = 13;
  
  // Route-related variables
  ServiceProvider? _selectedProvider;
  bool _showingRoute = false;
  String _routeProfile = 'driving'; // driving, walking, cycling
  
  // Animation controllers
  late AnimationController _filterAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _routeAnimationController;
  late Animation<double> _filterAnimation;
  late Animation<double> _fabAnimation;
  late Animation<double> _routeAnimation;

  // Track if widget is disposed
  bool _isDisposed = false;

  // All available provider types for filtering
  static const List<MapFilter> _providerTypes = [
    MapFilter('all', 'All Providers', Icons.business, Colors.grey),
    MapFilter('photographer', 'Photographers', Icons.camera_alt, Colors.purple),
    MapFilter('venue', 'Venues', Icons.location_city, Colors.blue),
    MapFilter('caterer', 'Caterers', Icons.restaurant, Colors.orange),
    MapFilter('decorator', 'Decorators', Icons.palette, Colors.pink),
    MapFilter('makeup_artist', 'Makeup Artists', Icons.face, Colors.red),
    MapFilter('event_organizer', 'Event Organizers', Icons.event, Colors.green),
  ];

  // Route profiles with their display info
  static const Map<String, RouteProfileInfo> _routeProfiles = {
    'driving': RouteProfileInfo('Driving', Icons.directions_car, Colors.blue),
    'walking': RouteProfileInfo('Walking', Icons.directions_walk, Colors.green),
    'cycling': RouteProfileInfo('Cycling', Icons.directions_bike, Colors.orange),
  };

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initLocation();
    _selectedFilterType = widget.filterType ?? 'all';
    
    // Listen to search focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchSuggestions = _searchFocusNode.hasFocus;
      });
    });
  }

  void _initAnimation() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _routeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _routeAnimation = CurvedAnimation(
      parent: _routeAnimationController,
      curve: Curves.easeInOut,
    );
    
    _filterAnimationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _searchFocusNode.dispose();
    _filterAnimationController.dispose();
    _fabAnimationController.dispose();
    _routeAnimationController.dispose();
    super.dispose();
  }

  String _getProviderType(ServiceProvider provider) {
    if (provider is Photographer) return 'photographer';
    if (provider is Venue) return 'venue';
    if (provider is Caterer) return 'caterer';
    if (provider is Decorator) return 'decorator';
    if (provider is MakeupArtist) return 'makeup_artist';
    if (provider is EventOrganizer) return 'event_organizer';
    return 'service_provider';
  }

  MapFilter _getFilterInfo(String type) {
    return _providerTypes.firstWhere(
      (filter) => filter.type == type,
      orElse: () => _providerTypes.first,
    );
  }

  Future<void> _initLocation() async {
    if (_isDisposed) return;
    setState(() { _loading = true; });
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null && !_isDisposed) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() { _error = 'Location error: $e'; });
      }
    } finally {
      if (!_isDisposed) {
        setState(() { _loading = false; });
      }
    }
  }

  void _onSearch(String query) async {
    if (_isDisposed) return;
    setState(() { 
      _searchQuery = query;
      _showSearchSuggestions = false;
    });
    _searchFocusNode.unfocus();
    
    if (query.isEmpty) return;
    
    final results = await LocationService.searchLocation(query);
    if (results.isNotEmpty && !_isDisposed) {
      final loc = results.first;
      _safeMapMove(LatLng(loc.latitude, loc.longitude), 14);
    }
  }

  void _filterByType(String? type) {
    if (_isDisposed) return;
    setState(() {
      _selectedFilterType = type ?? 'all';
    });
    
    // Animate filter change
    _filterAnimationController.reset();
    _filterAnimationController.forward();
  }

  List<ServiceProvider> _getFilteredProviders(List<ServiceProvider> allProviders) {
    if (_selectedFilterType == 'all' || _selectedFilterType == null) {
      return allProviders;
    }
    return allProviders.where((p) => _getProviderType(p) == _selectedFilterType).toList();
  }

  void _centerOnUser() {
    if (_userLocation != null && !_isDisposed) {
      _safeMapMove(_userLocation!, 15);
    }
  }

  void _toggleView() {
    if (_isDisposed) return;
    setState(() {
      _isListView = !_isListView;
    });
  }

  // Safe map movement to prevent disposed controller usage
  void _safeMapMove(LatLng latLng, double zoom) {
    if (!_isDisposed) {
      try {
        _mapController.move(latLng, zoom);
      } catch (e) {
        print('Error moving map: $e');
      }
    }
  }

  void _safeFitCamera(CameraFit cameraFit) {
    if (!_isDisposed) {
      try {
        _mapController.fitCamera(cameraFit);
      } catch (e) {
        print('Error fitting camera: $e');
      }
    }
  }

  // Enhanced routing methods
  Future<void> _showDirections(ServiceProvider provider) async {
    if (_isDisposed) return;
    if (_userLocation == null) {
      _showLocationError();
      return;
    }
    if (provider.location == null) {
      _showProviderLocationError();
      return;
    }
    
    setState(() {
      _selectedProvider = provider;
      _showingRoute = true;
    });
    
    _routeAnimationController.forward();
    await _calculateAndShowRoute(provider);
    
    if (mounted && !_isDisposed) {
      _showDirectionOptionsSheet(provider);
    }
  }

  Future<void> _calculateAndShowRoute(ServiceProvider provider) async {
    if (_isDisposed || _userLocation == null || provider.location == null) return;
    
    ref.read(routeLoadingProvider.notifier).state = true;
    
    try {
      final start = _userLocation!;
      final end = LatLng(provider.location!.latitude, provider.location!.longitude);
      
      // Get route from OSRM
      final route = await OSMRoutingService.getRoute(
        start: start,
        end: end,
        profile: _routeProfile,
      );
      
      if (route != null && !_isDisposed) {
        ref.read(routeProvider.notifier).state = route;
        
        // Fit camera to show entire route
        final bounds = LatLngBounds.fromPoints([start, end, ...route.coordinates]);
        _safeFitCamera(CameraFit.bounds(
          bounds: bounds, 
          padding: const EdgeInsets.all(50)
        ));
      } else {
        _showRouteError('Unable to calculate route');
      }
    } catch (e) {
      if (!_isDisposed) {
        _showRouteError('Error calculating route: $e');
      }
    } finally {
      if (!_isDisposed) {
        ref.read(routeLoadingProvider.notifier).state = false;
      }
    }
  }

  void _changeRouteProfile(String profile) {
    if (_isDisposed) return;
    setState(() {
      _routeProfile = profile;
    });
    
    if (_selectedProvider != null) {
      _calculateAndShowRoute(_selectedProvider!);
    }
  }

  void _clearRoute() {
    if (_isDisposed) return;
    setState(() {
      _selectedProvider = null;
      _showingRoute = false;
    });
    
    ref.read(routeProvider.notifier).state = null;
    _routeAnimationController.reverse();
  }

  void _showDirectionOptionsSheet(ServiceProvider provider) {
    if (_isDisposed) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DirectionOptionsSheet(
        provider: provider,
        userLocation: _userLocation!,
        route: ref.read(routeProvider),
        onClose: _clearRoute,
        onProfileChange: _changeRouteProfile,
        currentProfile: _routeProfile,
      ),
    );
  }

  void _showError(String message) {
    if (_isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showLocationError() {
    _showError('Unable to get your current location');
  }

  void _showProviderLocationError() {
    _showError('Provider location not available');
  }

  void _showRouteError(String error) {
    _showError('Error showing route: $error');
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search by address or location',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _showSearchSuggestions = false;
                  });
                },
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: _onSearch,
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    if (!_showSearchSuggestions || _searchController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.grey),
            title: Text(_searchController.text),
            subtitle: const Text('Search this location'),
            onTap: () => _onSearch(_searchController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCount(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$count providers found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _filterAnimation.value,
          child: Container(
            height: 60,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _providerTypes.length,
              itemBuilder: (context, index) {
                final filter = _providerTypes[index];
                final isSelected = _selectedFilterType == filter.type;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      filter.icon,
                      size: 18,
                      color: isSelected ? Colors.white : filter.color,
                    ),
                    label: Text(
                      filter.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _filterByType(filter.type == 'all' ? null : filter.type),
                    backgroundColor: Colors.grey[100],
                    selectedColor: filter.color,
                    checkmarkColor: Colors.white,
                    elevation: isSelected ? 4 : 0,
                    shadowColor: filter.color.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteInfoCard() {
    final route = ref.watch(routeProvider);
    final isLoading = ref.watch(routeLoadingProvider);
    
    if (!_showingRoute) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _routeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _routeAnimation.value)),
          child: Opacity(
            opacity: _routeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedProvider?.businessName ?? 'Route',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _clearRoute,
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isLoading) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Calculating route...'),
                      ],
                    ),
                  ] else if (route != null) ...[
                    Row(
                      children: [
                        _buildRouteInfo(
                          Icons.access_time,
                          route.formattedDuration,
                          Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _buildRouteInfo(
                          Icons.straighten,
                          route.formattedDistance,
                          Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Route profile selector
                    Row(
                      children: _routeProfiles.entries.map((entry) {
                        final isSelected = _routeProfile == entry.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _changeRouteProfile(entry.key),
                            child: Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? entry.value.color : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    entry.value.icon,
                                    size: 16,
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    entry.value.name,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const Text(
                      'Unable to calculate route',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMapView(List<ServiceProvider> providers) {
    final route = ref.watch(routeProvider);
    
    final markers = providers.map((provider) {
      final loc = provider.location;
      if (loc == null) return null;
      
      late final Marker marker;
      marker = Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _popupController.showPopupsOnlyFor([marker]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: providerMarker(_getProviderType(provider)),
          ),
        ),
        key: ValueKey(provider.id),
      );
      return marker;
    }).whereType<Marker>().toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _userLocation ?? const LatLng(27.7172, 85.3240), // Kathmandu
        zoom: _currentZoom,
        onTap: (_, __) {
          _popupController.hideAllPopups();
        },
        onMapEvent: (MapEvent event) {
          if (event is MapEventMove) {
            setState(() {
              _currentZoom = event.camera.zoom;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c', 'd'],
          retinaMode: true,
        ),
        // Enhanced route polyline layer
        if (_showingRoute && route != null && route.coordinates.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.coordinates,
                strokeWidth: 5.0,
                color: _routeProfiles[_routeProfile]?.color ?? Colors.blue,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
                isDotted: false,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        if (_userLocation != null)
          CurrentLocationLayer(
            followOnLocationUpdate: FollowOnLocationUpdate.once,
            turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
            style: LocationMarkerStyle(
              marker: DefaultLocationMarker(
                color: Colors.blue,
                child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 32),
              ),
            ),
          ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            markers: markers,
            popupController: _popupController,
            popupDisplayOptions: PopupDisplayOptions(
              builder: (context, marker) {
                final provider = providers.firstWhere(
                  (p) => p.id == marker.key.toString(),
                  orElse: () => providers.first,
                );
                return _buildProviderPopup(provider);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<ServiceProvider> providers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        final filter = _getFilterInfo(_getProviderType(provider));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: filter.color.withOpacity(0.1),
              child: Icon(filter.icon, color: filter.color),
            ),
            title: Text(
              provider.businessName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter.name,
                  style: TextStyle(
                    color: filter.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (provider.location != null)
                  Text(
                    '${provider.location!.latitude.toStringAsFixed(4)}, ${provider.location!.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.directions),
              onPressed: () => _showDirections(provider),
            ),
            onTap: () {
              // Navigate to provider details
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(mapProvidersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Providers'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isListView ? Icons.map : Icons.list),
            onPressed: _toggleView,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(mapProvidersProvider),
          ),
        ],
      ),
      body: providersAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading service providers...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading providers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.red[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(mapProvidersProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allProviders) {
          final filteredProviders = _getFilteredProviders(allProviders);
          
          if (_loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Main content
              if (_isListView) 
                _buildListView(filteredProviders)
              else
                _buildMapView(filteredProviders),
              
              // Search bar overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    _buildSearchBar(),
                    _buildSearchSuggestions(),
                  ],
                ),
              ),
              
              // Filter chips
              if (!_isListView)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: _buildFilterChips(),
                ),
              
              // Provider count
              if (!_isListView)
                Positioned(
                  top: 150,
                  left: 0,
                  child: _buildProviderCount(filteredProviders.length),
                ),
              
              // Route info card
              if (!_isListView)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: _buildRouteInfoCard(),
                ),
              
              // Floating action buttons
              if (!_isListView)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: AnimatedBuilder(
                    animation: _fabAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _fabAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton(
                              heroTag: "location",
                              onPressed: _centerOnUser,
                              backgroundColor: Colors.blue,
                              child: const Icon(Icons.my_location, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              heroTag: "zoom_in",
                              onPressed: () {
                                final newZoom = (_currentZoom + 1).clamp(1.0, 18.0);
                                _safeMapMove(_mapController.camera.center, newZoom);
                              },
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.zoom_in, color: Colors.black),
                              mini: true,
                            ),
                            const SizedBox(height: 4),
                            FloatingActionButton(
                              heroTag: "zoom_out",
                              onPressed: () {
                                final newZoom = (_currentZoom - 1).clamp(1.0, 18.0);
                                _safeMapMove(_mapController.camera.center, newZoom);
                              },
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.zoom_out, color: Colors.black),
                              mini: true,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProviderPopup(ServiceProvider provider) {
    final filter = _getFilterInfo(_getProviderType(provider));
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: filter.color.withOpacity(0.1),
                  child: Icon(filter.icon, color: filter.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.businessName ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        filter.name,
                        style: TextStyle(
                          color: filter.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.description != null && provider.description!.isNotEmpty) ...[
              Text(
                provider.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showDirections(provider),
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      _showError('Could not launch phone dialer');
    }
  }
}

// Helper classes
class MapFilter {
  final String type;
  final String name;
  final IconData icon;
  final Color color;

  const MapFilter(this.type, this.name, this.icon, this.color);
}

class RouteProfileInfo {
  final String name;
  final IconData icon;
  final Color color;

  const RouteProfileInfo(this.name, this.icon, this.color);
}

class DirectionOptionsSheet extends StatelessWidget {
  final ServiceProvider provider;
  final LatLng userLocation;
  final RouteResult? route;
  final VoidCallback onClose;
  final Function(String) onProfileChange;
  final String currentProfile;

  const DirectionOptionsSheet({
    Key? key,
    required this.provider,
    required this.userLocation,
    required this.route,
    required this.onClose,
    required this.onProfileChange,
    required this.currentProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Directions to ${provider.businessName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (route != null) ...[
            Row(
              children: [
                _buildRouteInfo(Icons.access_time, route!.formattedDuration, Colors.green),
                const SizedBox(width: 24),
                _buildRouteInfo(Icons.straighten, route!.formattedDistance, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Choose transportation mode:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildProfileOption('driving', 'Driving', Icons.directions_car, Colors.blue),
              const SizedBox(width: 8),
              _buildProfileOption('walking', 'Walking', Icons.directions_walk, Colors.green),
              const SizedBox(width: 8),
              _buildProfileOption('cycling', 'Cycling', Icons.directions_bike, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchExternalMaps(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Maps App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption(String profile, String name, IconData icon, Color color) {
    final isSelected = currentProfile == profile;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onProfileChange(profile),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchExternalMaps(BuildContext context) async {
    if (provider.location == null) return;
    
    final lat = provider.location!.latitude;
    final lng = provider.location!.longitude;
    final name = provider.businessName ?? 'Location';
    
    // Try Google Maps first, then Apple Maps
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final appleMapsUrl = 'https://maps.apple.com/?daddr=$lat,$lng';
    
    try {
      await launchUrl(Uri.parse(googleMapsUrl));
    } catch (e) {
      try {
        await launchUrl(Uri.parse(appleMapsUrl));
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}