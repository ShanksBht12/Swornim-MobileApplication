import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:convert';
import 'package:swornim/config/app_config.dart';

class SimpleImageService {
  static final ImagePicker _picker = ImagePicker();

  // Open app settings - FIXED infinite recursion
  static Future<void> openAppSettings() async {
    await Permission.camera.request();
    await Permission.photos.request();
    await Permission.mediaLibrary.request();
  }

  // Request camera and storage permissions
  static Future<bool> requestPermissions() async {
    try {
      // Check current permission status first
      Map<Permission, PermissionStatus> currentStatuses = {
        Permission.camera: await Permission.camera.status,
        Permission.storage: await Permission.storage.status,
        Permission.photos: await Permission.photos.status,
        Permission.mediaLibrary: await Permission.mediaLibrary.status,
      };

      // Request permissions that are not granted
      List<Permission> permissionsToRequest = [];
      
      if (!currentStatuses[Permission.camera]!.isGranted) {
        permissionsToRequest.add(Permission.camera);
      }
      
      // For Android 13+ (API 33+), use mediaLibrary instead of storage
      if (!currentStatuses[Permission.mediaLibrary]!.isGranted && 
          !currentStatuses[Permission.storage]!.isGranted) {
        permissionsToRequest.add(Permission.mediaLibrary);
      }
      
      if (!currentStatuses[Permission.photos]!.isGranted) {
        permissionsToRequest.add(Permission.photos);
      }

      // Request permissions if needed
      if (permissionsToRequest.isNotEmpty) {
        Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();
        
        // Check if all requested permissions are granted
        bool allGranted = true;
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            allGranted = false;
            debugPrint('Permission denied: $permission - $status');
          }
        });
        
        return allGranted;
      }
      
      return true; // All permissions already granted
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // Compress image before processing
  static Future<File?> compressImage(
    File imageFile, {
    int quality = 80,
    int maxWidth = 1200,
    int maxHeight = 1200,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final compressedPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        compressedPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        debugPrint('Image compressed: ${getFileSizeInMB(imageFile).toStringAsFixed(2)}MB -> ${getFileSizeInMB(File(compressedFile.path)).toStringAsFixed(2)}MB');
        return File(compressedFile.path);
      }
      
      return imageFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }

  // Pick image from camera or gallery with optimization
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth = 1200,
    int? maxHeight = 1200,
    int? imageQuality = 85,
    bool autoCompress = true,
  }) async {
    try {
      // Request permissions first
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw Exception('Camera and storage permissions are required. Please grant permissions in app settings.');
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        debugPrint('DEBUG: No image selected');
        return null;
      }

      File imageFile = File(pickedFile.path);
      
      // Auto compress if enabled and file is large
      if (autoCompress && getFileSizeInMB(imageFile) > 1.0) {
        final compressedFile = await compressImage(imageFile);
        if (compressedFile != null) {
          imageFile = compressedFile;
        }
      }

      debugPrint('DEBUG: Image picked successfully: ${imageFile.path}');
      return imageFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  // Show image source selection dialog - SIMPLIFIED approach
  static Future<File?> showImageSourceDialog({
    required BuildContext context,
    int? maxWidth = 1200,
    int? maxHeight = 1200,
    int? imageQuality = 85,
    bool autoCompress = true,
  }) async {
    try {
      if (!context.mounted) {
        debugPrint('DEBUG: Context not mounted when showing dialog');
        return null;
      }

      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(dialogContext).pop(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(dialogContext).pop(ImageSource.gallery);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (source == null) {
        debugPrint('DEBUG: No source selected');
        return null;
      }

      debugPrint('DEBUG: Source selected: $source');
      
      // Now pick the image with the selected source
      final image = await pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        autoCompress: autoCompress,
      );

      debugPrint('DEBUG: Image picker result: ${image?.path}');
      return image;
    } catch (e) {
      debugPrint('Error showing image source dialog: $e');
      return null;
    }
  }

  // Pick multiple images with optimization
  static Future<List<File>> pickMultipleImages({
    int maxImages = 10,
    int? maxWidth = 1200,
    int? maxHeight = 1200,
    int? imageQuality = 85,
    bool autoCompress = true,
  }) async {
    try {
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw Exception('Camera and storage permissions are required');
      }

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      List<File> imageFiles = [];
      for (XFile pickedFile in pickedFiles.take(maxImages)) {
        File imageFile = File(pickedFile.path);
        
        // Auto compress if enabled and file is large
        if (autoCompress && getFileSizeInMB(imageFile) > 1.0) {
          final compressedFile = await compressImage(imageFile);
          if (compressedFile != null) {
            imageFile = compressedFile;
          }
        }
        
        imageFiles.add(imageFile);
      }

      return imageFiles;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      rethrow;
    }
  }

  // Upload image to backend with progress tracking
  static Future<String?> uploadImage({
    required File imageFile,
    required String endpoint,
    String fieldName = 'profileImage',
    Map<String, String>? additionalFields,
    Function(double)? onProgress,
  }) async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          imageFile.path,
        ),
      );

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Send request with progress tracking
      final streamedResponse = await request.send();
      
      // Track upload progress
      if (onProgress != null) {
        int totalBytes = imageFile.lengthSync();
        int uploadedBytes = 0;
        
        streamedResponse.stream.listen(
          (List<int> chunk) {
            uploadedBytes += chunk.length;
            double progress = uploadedBytes / totalBytes;
            onProgress(progress.clamp(0.0, 1.0));
          },
        );
      }

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        debugPrint('DEBUG: Upload response: $jsonData');
        
        // For portfolio images, look for the appropriate field based on service provider type
        if (fieldName == 'portfolioImage') {
          debugPrint('DEBUG: Processing portfolio image upload response');
          debugPrint('DEBUG: Full response data: ${jsonData['data']}');
          
          // Determine service provider type from endpoint
          String serviceProviderType = '';
          if (endpoint.contains('/venues/')) {
            serviceProviderType = 'venue';
          } else if (endpoint.contains('/photographers/')) {
            serviceProviderType = 'photographer';
          } else if (endpoint.contains('/makeup-artists/')) {
            serviceProviderType = 'makeup_artist';
          } else if (endpoint.contains('/caterers/')) {
            serviceProviderType = 'caterer';
          } else if (endpoint.contains('/decorators/')) {
            serviceProviderType = 'decorator';
          }
          
          List<dynamic>? portfolioImages;
          
          if (serviceProviderType == 'venue') {
            // Venues store portfolio images in 'images' field
            portfolioImages = jsonData['data']?['images'] as List<dynamic>?;
            debugPrint('DEBUG: Checking images array for venue: $portfolioImages');
          } else {
            // Other service providers use 'portfolioImages' or 'portfolio'
            portfolioImages = jsonData['data']?['portfolioImages'] as List<dynamic>?;
            debugPrint('DEBUG: Checking portfolioImages array: $portfolioImages');
            
            // Fallback to portfolio field if portfolioImages doesn't exist
            if (portfolioImages == null) {
              portfolioImages = jsonData['data']?['portfolio'] as List<dynamic>?;
              debugPrint('DEBUG: Checking portfolio array (fallback): $portfolioImages');
            }
          }
          
          if (portfolioImages != null && portfolioImages.isNotEmpty) {
            final lastImage = portfolioImages.last.toString();
            debugPrint('DEBUG: Returning last portfolio image: $lastImage');
            return lastImage;
          }
          
          debugPrint('DEBUG: No portfolio images found in response');
        }
        
        // For profile images, look for profile image fields
        return jsonData['data']?['profileImage'] ?? 
               jsonData['data']?['image'] ?? 
               jsonData['data']?['url'];
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // Upload portfolio image
  static Future<String?> uploadPortfolioImage({
    required File imageFile,
    required String serviceProviderType,
    Function(double)? onProgress,
  }) async {
    final endpoint = '${AppConfig.getServiceProviderUrl(serviceProviderType)}/portfolio/images';
    return uploadImage(
      imageFile: imageFile,
      endpoint: endpoint,
      fieldName: 'portfolioImage',
      onProgress: onProgress,
    );
  }

  // Upload profile image
  static Future<String?> uploadProfileImage({
    required File imageFile,
    required String serviceProviderType,
    Function(double)? onProgress,
  }) async {
    final endpoint = '${AppConfig.getServiceProviderUrl(serviceProviderType)}/profile';
    return uploadImage(
      imageFile: imageFile,
      endpoint: endpoint,
      fieldName: 'profileImage',
      onProgress: onProgress,
    );
  }

  // Delete image from backend
  static Future<bool> deleteImage({
    required String imageUrl,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body != null ? json.encode(body) : null,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  // Validate image file
  static bool isValidImageFile(File file) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = file.path.split('.').last.toLowerCase();
    return validExtensions.contains('.$extension');
  }

  // Get file size in MB
  static double getFileSizeInMB(File file) {
    return file.lengthSync() / (1024 * 1024);
  }

  // Check if file size is within limit
  static bool isFileSizeValid(File file, {double maxSizeMB = 5.0}) {
    return getFileSizeInMB(file) <= maxSizeMB;
  }

  // Build cached network image with loading states
  static Widget buildCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 300),
    BorderRadius? borderRadius,
    bool showLoadingProgress = true,
  }) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? 
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: borderRadius,
          ),
          child: showLoadingProgress
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
              )
            : Icon(
                Icons.image,
                color: Colors.grey[400],
                size: 32,
              ),
        ),
      errorWidget: (context, url, error) => errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius,
          ),
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey[600],
            size: 32,
          ),
        ),
      fadeInDuration: fadeInDuration,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  // Build cached image with shimmer effect
  static Widget buildShimmerImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return buildCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[300]!,
              Colors.grey[200]!,
              Colors.grey[300]!,
            ],
          ),
        ),
      ),
    );
  }

  // Preload images for better performance
  static Future<void> preloadImages(
    BuildContext context, 
    List<String> imageUrls, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (!context.mounted) return;

    for (String url in imageUrls) {
      try {
        final provider = CachedNetworkImageProvider(url);
        await precacheImage(provider, context);
        debugPrint('Preloaded image: $url');
      } catch (e) {
        debugPrint('Failed to preload image: $url - $e');
      }
    }
  }

  // Preload single image
  static Future<void> preloadImage(
    BuildContext context, 
    String imageUrl, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (!context.mounted) return;

    try {
      final provider = CachedNetworkImageProvider(imageUrl);
      await precacheImage(provider, context);
      debugPrint('Preloaded image: $imageUrl');
    } catch (e) {
      debugPrint('Failed to preload image: $imageUrl - $e');
    }
  }

  // Clear image cache
  static Future<void> clearImageCache() async {
    await CachedNetworkImage.evictFromCache('');
    debugPrint('Image cache cleared');
  }

  // Get cache size
  static Future<String> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        int totalSize = 0;
        await for (FileSystemEntity entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        }
        double sizeInMB = totalSize / (1024 * 1024);
        return '${sizeInMB.toStringAsFixed(2)} MB';
      }
      return '0 MB';
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 'Unknown';
    }
  }
}