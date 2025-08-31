// File: lib/pages/forms/service_provider_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:swornim/pages/service_providers/profile_form/common/form_components.dart';
import 'package:swornim/pages/widgets/common/location_selector.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'package:swornim/pages/serviceprovider_dashboard/service_provider_dashboard.dart';
import 'package:swornim/config/app_config.dart';
import 'package:swornim/pages/widgets/common/simple_image_picker.dart';

enum ServiceProviderType {
  makeupArtist,
  photographer,
  venue,
  caterer,
  decorator,
  eventOrganizer,
}

class ServiceProviderFormData {
  // Common fields
  String businessName = '';
  String description = '';
  String profileImageUrl = '';
  List<String> portfolioImages = [];
  List<String> availableDates = [];
  
  // Location data
  String locationName = '';
  double latitude = 0.0;
  double longitude = 0.0;
  String address = '';
  String city = '';
  String state = '';
  String country = '';
  
  // Makeup Artist specific
  double sessionRate = 0.0;
  double bridalPackageRate = 0.0;
  List<String> makeupSpecializations = [];
  List<String> brands = [];
  bool offersHairServices = false;
  bool travelsToClient = true;
  
  // Photographer specific
  double hourlyRate = 0.0;
  List<String> photographySpecializations = [];
  
  // Venue specific
  int capacity = 0;
  double pricePerHour = 0.0;
  List<String> amenities = [];
  List<String> venueImages = [];
  List<String> venueTypes = [];
  
  // Caterer specific
  double pricePerPerson = 0.0;
  List<String> cuisineTypes = [];
  List<String> serviceTypes = [];
  int minGuests = 10;
  int maxGuests = 500;
  List<String> dietaryOptions = [];
  bool offersEquipment = false;
  bool offersWaiters = false;
  List<String> menuItems = [];
  
  // Decorator specific
  double packageStartingPrice = 0.0;
  double decoratorHourlyRate = 0.0;
  List<String> decoratorSpecializations = [];
  List<String> themes = [];
  bool offersFlowerArrangements = false;
  bool offersLighting = false;
  bool offersRentals = false;
  List<String> availableItems = [];
  
  // Event Organizer specific
  List<String> eventTypes = [];
  List<String> services = [];
  double eventPackageStartingPrice = 0.0;
  double hourlyConsultationRate = 0.0;
  String contactEmail = '';
  String contactPhone = '';
  bool offersVendorCoordination = true;
  bool offersVenueBooking = false;
  bool offersFullPlanning = true;
}

class ServiceProviderForm extends ConsumerStatefulWidget {
  final ServiceProviderType providerType;

  const ServiceProviderForm({
    Key? key,
    required this.providerType,
  }) : super(key: key);

  @override
  ConsumerState<ServiceProviderForm> createState() => _ServiceProviderFormState();
}

class _ServiceProviderFormState extends ConsumerState<ServiceProviderForm> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  final ServiceProviderFormData _formData = ServiceProviderFormData();
  LocationData? _selectedLocation;

  // Form keys for validation
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _servicesFormKey = GlobalKey<FormState>();
  final _pricingFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();

  // Controllers
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = {
      'businessName': TextEditingController(),
      'description': TextEditingController(),
      'profileImageUrl': TextEditingController(),
      'sessionRate': TextEditingController(),
      'bridalPackageRate': TextEditingController(),
      'brands': TextEditingController(),
      'hourlyRate': TextEditingController(),
      'equipment': TextEditingController(),
      'capacity': TextEditingController(),
      'pricePerHour': TextEditingController(),
      'amenities': TextEditingController(),
      'venueImages': TextEditingController(),
      'pricePerPerson': TextEditingController(),
      'minGuests': TextEditingController(),
      'maxGuests': TextEditingController(),
      'menuItems': TextEditingController(),
      'packageStartingPrice': TextEditingController(),
      'decoratorHourlyRate': TextEditingController(),
      'themes': TextEditingController(),
      'availableItems': TextEditingController(),
      'eventPackageStartingPrice': TextEditingController(),
      'hourlyConsultationRate': TextEditingController(),
      'contactEmail': TextEditingController(),
      'contactPhone': TextEditingController(),
      'availableDates': TextEditingController(),
      'locationName': TextEditingController(),
      'latitude': TextEditingController(),
      'longitude': TextEditingController(),
      'address': TextEditingController(),
      'city': TextEditingController(),
      'state': TextEditingController(),
      'country': TextEditingController(),
    };
  }

  List<String> get _stepTitles {
    switch (widget.providerType) {
      case ServiceProviderType.makeupArtist:
        return ['Basic Info', 'Services & Skills', 'Pricing', 'Location & Portfolio'];
      case ServiceProviderType.photographer:
        return ['Basic Info', 'Specializations', 'Pricing & Equipment', 'Location & Portfolio'];
      case ServiceProviderType.venue:
        return ['Basic Info', 'Venue Details', 'Pricing & Capacity', 'Location & Images'];
      case ServiceProviderType.caterer:
        return ['Basic Info', 'Cuisine & Services', 'Pricing', 'Location & Portfolio'];
      case ServiceProviderType.decorator:
        return ['Basic Info', 'Specializations', 'Pricing & Services', 'Location & Portfolio'];
      case ServiceProviderType.eventOrganizer:
        return ['Basic Info', 'Services & Events', 'Pricing & Availability', 'Location & Portfolio'];
    }
  }

  String get _providerTitle {
    switch (widget.providerType) {
      case ServiceProviderType.makeupArtist:
        return 'Makeup Artist';
      case ServiceProviderType.photographer:
        return 'Photographer';
      case ServiceProviderType.venue:
        return 'Venue';
      case ServiceProviderType.caterer:
        return 'Caterer';
      case ServiceProviderType.decorator:
        return 'Decorator';
      case ServiceProviderType.eventOrganizer:
        return 'Event Organizer';
    }
  }

  String get _apiEndpoint {
    switch (widget.providerType) {
      case ServiceProviderType.makeupArtist:
        return '${AppConfig.makeupArtistsUrl}/profile';
      case ServiceProviderType.photographer:
        return '${AppConfig.photographersUrl}/profile';
      case ServiceProviderType.venue:
        return '${AppConfig.venuesUrl}/profile';
      case ServiceProviderType.caterer:
        return '${AppConfig.caterersUrl}/profile';
      case ServiceProviderType.decorator:
        return '${AppConfig.decoratorsUrl}/profile';
      case ServiceProviderType.eventOrganizer:
        return '${AppConfig.baseUrl}/event-organizers/profile';
    }
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildServicesStep();
      case 2:
        return _buildPricingStep();
      case 3:
        return _buildLocationPortfolioStep();
      default:
        return Container();
    }
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _basicInfoFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SectionCard(
              title: 'Business Information',
              subtitle: 'Tell us about your ${_providerTitle.toLowerCase()} business',
              child: Column(
                children: [
                  CustomTextFormField(
                    label: 'Business Name',
                    hint: 'e.g., Elite ${_providerTitle}',
                    controller: _controllers['businessName']!,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Business name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextFormField(
                    label: 'Business Description',
                    hint: 'Describe your services and expertise...',
                    controller: _controllers['description']!,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      if (value.trim().length < 5) {
                        return 'Description must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (widget.providerType == ServiceProviderType.eventOrganizer) ...[
              const SizedBox(height: 24),
              SectionCard(
                title: 'Contact Information',
                subtitle: 'How can clients reach you?',
                child: Column(
                  children: [
                    CustomTextFormField(
                      label: 'Contact Email',
                      hint: 'business@example.com',
                      controller: _controllers['contactEmail']!,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contact email is required';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      label: 'Contact Phone',
                      hint: '+977-98XXXXXXXX',
                      controller: _controllers['contactPhone']!,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contact phone is required';
                        }
                        // Allow any non-empty phone number, no strict validation
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProviderSpecificServices(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProviderSpecificServices() {
    switch (widget.providerType) {
      case ServiceProviderType.makeupArtist:
        return _buildMakeupArtistServices();
      case ServiceProviderType.photographer:
        return _buildPhotographerServices();
      case ServiceProviderType.venue:
        return _buildVenueServices();
      case ServiceProviderType.caterer:
        return _buildCatererServices();
      case ServiceProviderType.decorator:
        return _buildDecoratorServices();
      case ServiceProviderType.eventOrganizer:
        return _buildEventOrganizerServices();
    }
  }

  Widget _buildMakeupArtistServices() {
    final specializationOptions = [
      'Bridal Makeup', 'Party Makeup', 'Editorial Makeup', 'SFX Makeup',
      'Airbrush Makeup', 'Traditional Makeup', 'HD Makeup', 'Engagement Makeup'
    ];

    return Column(
      children: [
        SectionCard(
          title: 'Specializations',
          subtitle: 'What types of makeup do you specialize in?',
          child: ChipSelector(
            label: 'Makeup Specializations',
            options: specializationOptions,
            selectedOptions: _formData.makeupSpecializations,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.makeupSpecializations = selected;
              });
            },
            required: true,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Brands & Equipment',
          subtitle: 'What makeup brands do you use?',
          child: CustomTextFormField(
            label: 'Preferred Brands',
            hint: 'e.g., MAC, Nars, Urban Decay (comma separated)',
            controller: _controllers['brands']!,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Additional Services',
          subtitle: 'What other services do you offer?',
          child: Column(
            children: [
              CustomSwitch(
                label: 'Hair Services',
                subtitle: 'I also offer hair styling services',
                value: _formData.offersHairServices,
                onChanged: (value) {
                  setState(() {
                    _formData.offersHairServices = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomSwitch(
                label: 'Travel to Client',
                subtitle: 'I can travel to client\'s location',
                value: _formData.travelsToClient,
                onChanged: (value) {
                  setState(() {
                    _formData.travelsToClient = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotographerServices() {
    final specializationOptions = [
      'Wedding Photography', 'Portrait Photography', 'Event Photography', 
      'Commercial Photography', 'Fashion Photography', 'Product Photography',
      'Landscape Photography', 'Street Photography'
    ];

    return Column(
      children: [
        SectionCard(
          title: 'Photography Specializations',
          subtitle: 'What types of photography do you specialize in?',
          child: ChipSelector(
            label: 'Specializations',
            options: specializationOptions,
            selectedOptions: _formData.photographySpecializations,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.photographySpecializations = selected;
              });
            },
            required: true,
          ),
        ),
      ],
    );
  }

  Widget _buildVenueServices() {
    final venueTypeOptions = [
      'wedding', 'conference', 'party', 'exhibition', 'other'
    ];

    return Column(
      children: [
        SectionCard(
          title: 'Venue Types',
          subtitle: 'What types of events is your venue suitable for?',
          child: ChipSelector(
            label: 'Venue Types',
            options: venueTypeOptions,
            selectedOptions: _formData.venueTypes,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.venueTypes = selected;
              });
            },
            required: true,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Amenities',
          subtitle: 'What facilities and amenities do you provide?',
          child: CustomTextFormField(
            label: 'Available Amenities',
            hint: 'e.g., Parking, AC, Stage, Audio System (comma separated)',
            controller: _controllers['amenities']!,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCatererServices() {
    final cuisineOptions = [
      'Nepali', 'Indian', 'Chinese', 'Continental', 'Italian', 'Mexican', 
      'Thai', 'Japanese', 'Multi-Cuisine'
    ];

    final serviceTypeOptions = [
      'Buffet', 'Plated Service', 'Family Style', 'Cocktail Service',
      'BBQ Service', 'Live Cooking', 'Canapés', 'Food Stations'
    ];

    final dietaryOptions = [
      'Vegetarian', 'Vegan', 'Halal', 'Jain', 'Gluten-Free', 'Keto', 'Diabetic-Friendly'
    ];

    return Column(
      children: [
        SectionCard(
          title: 'Cuisine Types',
          subtitle: 'What types of cuisine do you specialize in?',
          child: ChipSelector(
            label: 'Cuisine Specializations',
            options: cuisineOptions,
            selectedOptions: _formData.cuisineTypes,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.cuisineTypes = selected;
              });
            },
            required: true,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Service Types',
          subtitle: 'What types of catering services do you offer?',
          child: ChipSelector(
            label: 'Service Types',
            options: serviceTypeOptions,
            selectedOptions: _formData.serviceTypes,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.serviceTypes = selected;
              });
            },
            required: true,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Dietary Options',
          subtitle: 'What dietary requirements can you accommodate?',
          child: ChipSelector(
            label: 'Dietary Accommodations',
            options: dietaryOptions,
            selectedOptions: _formData.dietaryOptions,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.dietaryOptions = selected;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Additional Services',
          subtitle: 'What additional services do you provide?',
          child: Column(
            children: [
              CustomSwitch(
                label: 'Equipment Rental',
                subtitle: 'Tables, chairs, serving equipment',
                value: _formData.offersEquipment,
                onChanged: (value) {
                  setState(() {
                    _formData.offersEquipment = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomSwitch(
                label: 'Waiter Services',
                subtitle: 'Professional serving staff',
                value: _formData.offersWaiters,
                onChanged: (value) {
                  setState(() {
                    _formData.offersWaiters = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecoratorServices() {
    final specializationOptions = [
      'Wedding Decoration', 'Birthday Decoration', 'Corporate Events', 
      'Anniversary Decoration', 'Festival Decoration', 'Party Decoration',
      'Stage Decoration', 'Balloon Decoration'
    ];

    final themeOptions = [
      'Traditional', 'Modern', 'Vintage', 'Rustic', 'Elegant', 'Bohemian',
      'Minimalist', 'Colorful', 'Romantic', 'Cultural'
    ];

    return Column(
      children: [
        SectionCard(
          title: 'Decoration Specializations',
          subtitle: 'What types of events do you decorate?',
          child: ChipSelector(
            label: 'Specializations',
            options: specializationOptions,
            selectedOptions: _formData.decoratorSpecializations,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.decoratorSpecializations = selected;
              });
            },
            required: true,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Decoration Themes',
          subtitle: 'What decoration themes do you work with?',
          child: ChipSelector(
            label: 'Themes',
            options: themeOptions,
            selectedOptions: _formData.themes,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.themes = selected;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Additional Services',
          subtitle: 'What other decoration services do you offer?',
          child: Column(
            children: [
              CustomSwitch(
                label: 'Flower Arrangements',
                subtitle: 'Fresh flower arrangements and bouquets',
                value: _formData.offersFlowerArrangements,
                onChanged: (value) {
                  setState(() {
                    _formData.offersFlowerArrangements = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomSwitch(
                label: 'Lighting Setup',
                subtitle: 'Professional lighting arrangements',
                value: _formData.offersLighting,
                onChanged: (value) {
                  setState(() {
                    _formData.offersLighting = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomSwitch(
                label: 'Rental Items',
                subtitle: 'Decoration items and props rental',
                value: _formData.offersRentals,
                onChanged: (value) {
                  setState(() {
                    _formData.offersRentals = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventOrganizerServices() {
    final eventTypeOptions = [
      'Wedding', 'Corporate Event', 'Birthday Party', 'Anniversary',
      'Conference', 'Seminar', 'Workshop', 'Product Launch', 'Concert',
      'Music Festival', 'Cultural Show', 'Sports Event', 'Charity Event',
      'Exhibition', 'Trade Show', 'Religious Ceremony', 'Graduation'
    ];

    final serviceOptions = [
      'Full Event Planning', 'Day-of Coordination', 'Vendor Management',
      'Timeline Management', 'Budget Planning', 'Venue Selection',
      'Catering Coordination', 'Entertainment Booking', 'Photography Coordination',
      'Decoration Planning', 'Guest Management', 'Transportation Coordination'
    ];

    return Column(
      children: [
        SectionCard(
          title: 'Event Specializations',
          subtitle: 'What types of events do you organize?',
          child: ChipSelector(
            label: 'Event Types',
            options: eventTypeOptions,
            selectedOptions: _formData.eventTypes,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.eventTypes = selected;
              });
            },
            required: true,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Services Offered',
          subtitle: 'What services do you provide to your clients?',
          child: ChipSelector(
            label: 'Services',
            options: serviceOptions,
            selectedOptions: _formData.services,
            onSelectionChanged: (selected) {
              setState(() {
                _formData.services = selected;
              });
            },
            required: true,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Additional Capabilities',
          subtitle: 'What additional services can you provide?',
          child: Column(
            children: [
              CustomSwitch(
                label: 'Vendor Coordination',
                subtitle: 'Coordinate with other service providers',
                value: _formData.offersVendorCoordination,
                onChanged: (value) {
                  setState(() {
                    _formData.offersVendorCoordination = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomSwitch(
                label: 'Venue Booking Services',
                subtitle: 'Help clients find and book venues',
                value: _formData.offersVenueBooking,
                onChanged: (value) {
                  setState(() {
                    _formData.offersVenueBooking = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomSwitch(
                label: 'Full Event Planning',
                subtitle: 'End-to-end event planning services',
                value: _formData.offersFullPlanning,
                onChanged: (value) {
                  setState(() {
                    _formData.offersFullPlanning = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingStep() {
    return Form(
      key: _pricingFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProviderSpecificPricing(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSpecificPricing() {
    switch (widget.providerType) {
      case ServiceProviderType.makeupArtist:
        return _buildMakeupArtistPricing();
      case ServiceProviderType.photographer:
        return _buildPhotographerPricing();
      case ServiceProviderType.venue:
        return _buildVenuePricing();
      case ServiceProviderType.caterer:
        return _buildCatererPricing();
      case ServiceProviderType.decorator:
        return _buildDecoratorPricing();
      case ServiceProviderType.eventOrganizer:
        return _buildEventOrganizerPricing();
    }
  }

  Widget _buildMakeupArtistPricing() {
    return SectionCard(
      title: 'Pricing Information',
      subtitle: 'Set your rates for different makeup services',
      child: Column(
        children: [
          PriceInputField(
            label: 'Session Rate',
            hint: 'Rate per makeup session',
            controller: _controllers['sessionRate']!,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Session rate is required';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
              if (price < 500) {
                return 'Minimum session rate should be Rs. 500';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          PriceInputField(
            label: 'Bridal Package Rate',
            hint: 'Rate for complete bridal makeup',
            controller: _controllers['bridalPackageRate']!,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bridal package rate is required';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
              if (price < 2000) {
                return 'Minimum bridal package rate should be Rs. 2,000';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotographerPricing() {
    return SectionCard(
      title: 'Pricing Information',
      subtitle: 'Set your rates for photography services',
      child: Column(
        children: [
          PriceInputField(
            label: 'Hourly Rate',
            hint: 'Rate per hour for photography',
            controller: _controllers['hourlyRate']!,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Hourly rate is required';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
              if (price < 1000) {
                return 'Minimum hourly rate should be Rs. 1,000';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVenuePricing() {
    return Column(
      children: [
        SectionCard(
          title: 'Pricing Information',
          subtitle: 'Set your venue rental rates',
          child: Column(
            children: [
              PriceInputField(
                label: 'Price Per Hour',
                hint: 'Hourly rental rate',
                controller: _controllers['pricePerHour']!,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price per hour is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  if (price < 1000) {
                    return 'Minimum hourly rate should be Rs. 1,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextFormField(
                label: 'Capacity',
                hint: 'Maximum number of guests',
                controller: _controllers['capacity']!,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Capacity is required';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter a valid capacity';
                  }
                  if (capacity < 10) {
                    return 'Minimum capacity should be 10 guests';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatererPricing() {
    return Column(
      children: [
        SectionCard(
          title: 'Pricing Information',
          subtitle: 'Set your catering rates',
          child: Column(
            children: [
              PriceInputField(
                label: 'Price Per Person',
                hint: 'Rate per guest',
                controller: _controllers['pricePerPerson']!,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price per person is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  if (price < 200) {
                    return 'Minimum price per person should be Rs. 200';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      label: 'Minimum Guests',
                      hint: '10',
                      controller: _controllers['minGuests']!,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final min = int.tryParse(value);
                          if (min == null || min < 1) {
                            return 'Invalid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextFormField(
                      label: 'Maximum Guests',
                      hint: '500',
                      controller: _controllers['maxGuests']!,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final max = int.tryParse(value);
                          if (max == null || max < 1) {
                            return 'Invalid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecoratorPricing() {
    return SectionCard(
      title: 'Pricing Information',
      subtitle: 'Set your decoration service rates',
      child: Column(
        children: [
          PriceInputField(
            label: 'Package Starting Price',
            hint: 'Starting price for decoration packages',
            controller: _controllers['packageStartingPrice']!,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Package starting price is required';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
              if (price < 2000) {
                return 'Minimum package price should be Rs. 2,000';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          PriceInputField(
            label: 'Hourly Rate',
            hint: 'Rate per hour for decoration work',
            controller: _controllers['decoratorHourlyRate']!,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Hourly rate is required';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
              if (price < 800) {
                return 'Minimum hourly rate should be Rs. 800';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventOrganizerPricing() {
    return Column(
      children: [
        SectionCard(
          title: 'Pricing Information',
          subtitle: 'Set your rates for event organizing services',
          child: Column(
            children: [
              PriceInputField(
                label: 'Package Starting Price',
                hint: 'Starting price for event packages',
                controller: _controllers['eventPackageStartingPrice']!,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Package starting price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  if (price < 10000) {
                    return 'Minimum package price should be Rs. 10,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PriceInputField(
                label: 'Hourly Consultation Rate',
                hint: 'Rate per hour for consultation',
                controller: _controllers['hourlyConsultationRate']!,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hourly consultation rate is required';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Please enter a valid rate';
                  }
                  if (rate < 1000) {
                    return 'Minimum hourly rate should be Rs. 1,000';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Availability',
          subtitle: 'When are you available for events?',
          child: CustomTextFormField(
            label: 'Available Dates',
            hint: 'e.g., Weekends, 2024-03-15, 2024-03-20 (comma separated)',
            controller: _controllers['availableDates']!,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please specify your availability';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPortfolioStep() {
    return Form(
      key: _locationFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SectionCard(
              title: 'Business Location',
              subtitle: 'Where are you based? This helps clients find you.',
              child: Column(
                children: [
                  LocationSelector(
                    onLocationSelected: (location) {
                      setState(() {
                        _selectedLocation = location;
                        _controllers['locationName']!.text = location.name;
                        _controllers['address']!.text = location.address;
                        _controllers['city']!.text = location.city.isNotEmpty ? location.city : 'Kathmandu';
                        _controllers['state']!.text = location.state.isNotEmpty ? location.state : 'Bagmati';
                        _controllers['country']!.text = location.country.isNotEmpty ? location.country : 'Nepal';
                        _controllers['latitude']!.text = location.latitude.toString();
                        _controllers['longitude']!.text = location.longitude.toString();
                      });
                    },
                    initialLocation: _selectedLocation,
                  ),
                  if (_selectedLocation == null) ...[
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      label: 'Address',
                      hint: 'Enter your business address',
                      controller: _controllers['address']!,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            label: 'City',
                            hint: 'Kathmandu',
                            controller: _controllers['city']!,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'City is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextFormField(
                            label: 'State/Province',
                            hint: 'Bagmati',
                            controller: _controllers['state']!,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'State is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      label: 'Country',
                      hint: 'Nepal',
                      controller: _controllers['country']!,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Country is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // SectionCard(
            //   title: 'Profile Image',
            //   subtitle: 'Add a professional photo or your business logo',
            //   child: SimpleImagePicker(
            //     currentImageUrl: _controllers['profileImageUrl']!.text,
            //     onImageUploaded: (url) {
            //       setState(() {
            //         _controllers['profileImageUrl']!.text = url;
            //       });
            //     },
            //     placeholderText: 'Pick a profile image',
            //     width: 120,
            //     height: 120,
            //     isCircular: true,
            //     showEditButton: true,
            //     showRemoveButton: true,
            //     allowEditing: true,
            //   ),
            // ),
            // const SizedBox(height: 24),
            // _buildPortfolioSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Widget _buildPortfolioSection() {
  //   return SectionCard(
  //     title: 'Portfolio',
  //     subtitle: 'Showcase your best work',
  //     child: Column(
  //       children: [
  //         SimpleImagePicker(
  //           currentImageUrl: null,
  //           placeholderText: 'Add portfolio image',
  //           width: 100,
  //           height: 100,
  //           isCircular: false,
  //           showEditButton: true,
  //           showRemoveButton: false,
  //           allowEditing: true,
  //           onImageUploaded: (url) {
  //             setState(() {
  //               if (!_formData.portfolioImages.contains(url)) {
  //                 _formData.portfolioImages.add(url);
  //               }
  //             });
  //           },
  //         ),
  //         if (_formData.portfolioImages.isNotEmpty) ...[
  //           const SizedBox(height: 20),
  //           Text(
  //             'Portfolio Images ( ${_formData.portfolioImages.length})',
  //             style: GoogleFonts.inter(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w500,
  //               color: const Color(0xFF374151),
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           ..._formData.portfolioImages.map((url) => Container(
  //             margin: const EdgeInsets.only(bottom: 8),
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: const Color(0xFFF9FAFB),
  //               borderRadius: BorderRadius.circular(8),
  //               border: Border.all(color: const Color(0xFFE5E7EB)),
  //             ),
  //             child: Row(
  //               children: [
  //                 ClipRRect(
  //                   borderRadius: BorderRadius.circular(8),
  //                   child: Image.network(
  //                     url,
  //                     width: 60,
  //                     height: 60,
  //                     fit: BoxFit.cover,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Text(
  //                     url,
  //                     style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //                 IconButton(
  //                   onPressed: () {
  //                     setState(() {
  //                       _formData.portfolioImages.remove(url);
  //                     });
  //                   },
  //                   icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
  //                   padding: EdgeInsets.zero,
  //                   constraints: const BoxConstraints(),
  //                 ),
  //               ],
  //             ),
  //           )).toList(),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _stepTitles.length - 1) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitForm();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _basicInfoFormKey.currentState?.validate() ?? false;
      case 1:
        return _validateServicesStep();
      case 2:
        return _pricingFormKey.currentState?.validate() ?? false;
      case 3:
        return _locationFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  bool _validateServicesStep() {
    switch (widget.providerType) {
      case ServiceProviderType.makeupArtist:
        if (_formData.makeupSpecializations.isEmpty) {
          _showErrorSnackBar('Please select at least one makeup specialization');
          return false;
        }
        break;
      case ServiceProviderType.photographer:
        if (_formData.photographySpecializations.isEmpty) {
          _showErrorSnackBar('Please select at least one photography specialization');
          return false;
        }
        break;
      case ServiceProviderType.venue:
        if (_formData.venueTypes.isEmpty) {
          _showErrorSnackBar('Please select at least one venue type');
          return false;
        }
        // Ensure only allowed types are submitted
        final allowedVenueTypes = ['wedding', 'conference', 'party', 'exhibition', 'other'];
        if (_formData.venueTypes.any((type) => !allowedVenueTypes.contains(type))) {
          _showErrorSnackBar('Venue type must be one of: wedding, conference, party, exhibition, other');
          return false;
        }
        break;
      case ServiceProviderType.caterer:
        if (_formData.cuisineTypes.isEmpty) {
          _showErrorSnackBar('Please select at least one cuisine type');
          return false;
        }
        if (_formData.serviceTypes.isEmpty) {
          _showErrorSnackBar('Please select at least one service type');
          return false;
        }
        break;
      case ServiceProviderType.decorator:
        if (_formData.decoratorSpecializations.isEmpty) {
          _showErrorSnackBar('Please select at least one decoration specialization');
          return false;
        }
        break;
      case ServiceProviderType.eventOrganizer:
        if (_formData.eventTypes.isEmpty) {
          _showErrorSnackBar('Please select at least one event type');
          return false;
        }
        if (_formData.services.isEmpty) {
          _showErrorSnackBar('Please select at least one service');
          return false;
        }
        break;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await getAccessToken();
      final url = Uri.parse(_apiEndpoint);
      final bodyMap = _buildSubmissionData();
      final body = jsonEncode(bodyMap);

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_providerTitle} profile created successfully!'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          final currentUser = ref.read(authProvider).user;
          if (currentUser != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceProviderDashboard(provider: currentUser),
              ),
            );
          } else {
            Navigator.pop(context);
          }
        }
      } else {
        setState(() {
          _error = 'Failed to create profile: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _buildSubmissionData() {
    final baseData = {
      'businessName': _controllers['businessName']!.text.trim(),
      'description': _controllers['description']!.text.trim(),
      'location': {
        'name': _controllers['locationName']!.text.trim(),
        'latitude': double.tryParse(_controllers['latitude']!.text) ?? 0,
        'longitude': double.tryParse(_controllers['longitude']!.text) ?? 0,
        'address': _controllers['address']!.text.trim(),
        'city': _controllers['city']!.text.trim(),
        'state': _controllers['state']!.text.trim(),
        'country': _controllers['country']!.text.trim(),
      },
    };

    // if (_controllers['profileImageUrl']!.text.trim().isNotEmpty) {
    //   baseData['profileImage'] = _controllers['profileImageUrl']!.text.trim();
    // }

    // if (_formData.portfolioImages.isNotEmpty) {
    //   baseData['portfolioImages'] = _formData.portfolioImages;
    // }

    // Add provider-specific data
    switch (widget.providerType) {
      case ServiceProviderType.makeupArtist:
        baseData.addAll({
          'sessionRate': double.tryParse(_controllers['sessionRate']!.text) ?? 0,
          'bridalPackageRate': double.tryParse(_controllers['bridalPackageRate']!.text) ?? 0,
          'specializations': _formData.makeupSpecializations,
          'brands': _controllers['brands']!.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'offersHairServices': _formData.offersHairServices,
          'travelsToClient': _formData.travelsToClient,
        });
        break;
      case ServiceProviderType.photographer:
        baseData.addAll({
          'hourlyRate': double.tryParse(_controllers['hourlyRate']!.text) ?? 0,
          'specializations': _formData.photographySpecializations,
        });
        break;
      case ServiceProviderType.venue:
        baseData.addAll({
          'capacity': int.tryParse(_controllers['capacity']!.text) ?? 0,
          'pricePerHour': double.tryParse(_controllers['pricePerHour']!.text) ?? 0,
          'amenities': _controllers['amenities']!.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'images': _formData.portfolioImages,
          'venueTypes': _formData.venueTypes,
        });
        break;
      case ServiceProviderType.caterer:
        baseData.addAll({
          'pricePerPerson': double.tryParse(_controllers['pricePerPerson']!.text) ?? 0,
          'cuisineTypes': _formData.cuisineTypes,
          'serviceTypes': _formData.serviceTypes,
          'minGuests': int.tryParse(_controllers['minGuests']!.text) ?? 10,
          'maxGuests': int.tryParse(_controllers['maxGuests']!.text) ?? 500,
          'dietaryOptions': _formData.dietaryOptions,
          'offersEquipment': _formData.offersEquipment,
          'offersWaiters': _formData.offersWaiters,
        });
        break;
      case ServiceProviderType.decorator:
        baseData.addAll({
          'packageStartingPrice': double.tryParse(_controllers['packageStartingPrice']!.text) ?? 0,
          'hourlyRate': double.tryParse(_controllers['decoratorHourlyRate']!.text) ?? 0,
          'specializations': _formData.decoratorSpecializations,
          'themes': _formData.themes,
          'offersFlowerArrangements': _formData.offersFlowerArrangements,
          'offersLighting': _formData.offersLighting,
          'offersRentals': _formData.offersRentals,
        });
        break;
      case ServiceProviderType.eventOrganizer:
        baseData.addAll({
          'eventTypes': _formData.eventTypes,
          'services': _formData.services,
          'packageStartingPrice': double.tryParse(_controllers['eventPackageStartingPrice']!.text) ?? 0,
          'hourlyConsultationRate': double.tryParse(_controllers['hourlyConsultationRate']!.text) ?? 0,
          'contactEmail': _controllers['contactEmail']!.text.trim(),
          'contactPhone': _controllers['contactPhone']!.text.trim(),
          'offersVendorCoordination': _formData.offersVendorCoordination,
          'offersVenueBooking': _formData.offersVenueBooking,
          'offersFullPlanning': _formData.offersFullPlanning,
          'availableDates': _controllers['availableDates']!.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        });
        break;
    }

    return baseData;
  }

  Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create ${_providerTitle} Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          onPressed: _currentStep == 0 ? () => Navigator.pop(context) : _previousStep,
          icon: Icon(Icons.arrow_back, color: const Color(0xFF6B7280)),
        ),
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: FormProgress(
              currentStep: _currentStep,
              totalSteps: _stepTitles.length,
              stepTitles: _stepTitles,
            ),
          ),
          
          // Form Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stepTitles.length,
              itemBuilder: (context, index) => _buildStep(index),
            ),
          ),
          
          // Error Message
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFEF2F2),
              child: Text(
                _error!,
                style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Navigation Buttons
          NavigationButtons(
            onPrevious: _currentStep > 0 ? _previousStep : null,
            onNext: _nextStep,
            isLoading: _isLoading,
            isLastStep: _currentStep == _stepTitles.length - 1,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}