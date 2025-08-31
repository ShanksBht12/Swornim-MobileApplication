import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swornim/pages/services/simple_image_service.dart';
import 'package:swornim/config/app_config.dart';

class SimpleImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final String? placeholderText;
  final double width;
  final double height;
  final BoxFit fit;
  final bool isCircular;
  final bool showEditButton;
  final bool showRemoveButton;
  final Function(File)? onImageSelected;
  final Function(String)? onImageUploaded;
  final Function()? onImageRemoved;
  final String? uploadEndpoint;
  final String fieldName;
  final bool showUploadProgress;
  final double maxFileSizeMB;
  final bool allowEditing;

  const SimpleImagePicker({
    Key? key,
    this.currentImageUrl,
    this.placeholderText,
    this.width = 120,
    this.height = 120,
    this.fit = BoxFit.cover,
    this.isCircular = true,
    this.showEditButton = true,
    this.showRemoveButton = true,
    this.onImageSelected,
    this.onImageUploaded,
    this.onImageRemoved,
    this.uploadEndpoint,
    this.fieldName = 'profileImage',
    this.showUploadProgress = true,
    this.maxFileSizeMB = 5.0,
    this.allowEditing = true,
  }) : super(key: key);

  @override
  State<SimpleImagePicker> createState() => _SimpleImagePickerState();
}

class _SimpleImagePickerState extends State<SimpleImagePicker> {
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;
  bool _isImageLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Image display
        GestureDetector(
          onTap: widget.allowEditing ? _showImageSourceDialog : null,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircular ? null : BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Image content
                _buildImageContent(colorScheme),
                
                // Upload progress overlay
                if (_isUploading && widget.showUploadProgress)
                  _buildUploadProgressOverlay(colorScheme),
                
                // Edit button
                if (widget.showEditButton && widget.allowEditing && !_isUploading && !_isImageLoading)
                  _buildEditButton(colorScheme),
                  
                // Loading indicator
                if (_isImageLoading)
                  _buildLoadingIndicator(colorScheme),
              ],
            ),
          ),
        ),
        
        // Error message
        if (_uploadError != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _uploadError!,
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Action buttons
        if (widget.allowEditing && !_isUploading && !_isImageLoading) 
          _buildActionButtons(theme, colorScheme),
      ],
    );
  }

  Widget _buildImageContent(ColorScheme colorScheme) {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: widget.isCircular 
            ? BorderRadius.circular(widget.width / 2)
            : BorderRadius.circular(10),
        child: Image.file(
          _selectedImage!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    } else if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: widget.isCircular 
            ? BorderRadius.circular(widget.width / 2)
            : BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: widget.currentImageUrl!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: (context, url) => _buildPlaceholder(colorScheme),
          errorWidget: (context, url, error) => _buildPlaceholder(colorScheme),
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      return _buildPlaceholder(colorScheme);
    }
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircular ? null : BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: widget.width * 0.25,
            color: colorScheme.onSurfaceVariant,
          ),
          if (widget.placeholderText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.placeholderText!,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressOverlay(ColorScheme colorScheme) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircular ? null : BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: _uploadProgress,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Uploading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.8),
        shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircular ? null : BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(ColorScheme colorScheme) {
    return Positioned(
      bottom: widget.isCircular ? 5 : 8,
      right: widget.isCircular ? 5 : 8,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: _showImageSourceDialog,
          icon: Icon(
            Icons.camera_alt,
            color: colorScheme.onPrimary,
            size: 16,
          ),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Change image button
          OutlinedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: const Icon(Icons.photo_camera, size: 16),
            label: const Text('Change'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // Remove button
          if (widget.showRemoveButton && 
              (widget.currentImageUrl != null || _selectedImage != null))
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    if (!mounted) return;

    setState(() {
      _isImageLoading = true;
      _uploadError = null;
    });

    try {
      debugPrint('DEBUG: Showing image source dialog...');
      
      File? selectedImage = await SimpleImageService.showImageSourceDialog(
        context: context,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (!mounted) {
        debugPrint('DEBUG: Widget not mounted after image selection');
        return;
      }

      setState(() {
        _isImageLoading = false;
      });

      if (selectedImage != null) {
        debugPrint('DEBUG: Image selected: ${selectedImage.path}');
        
        // Validate file
        if (!SimpleImageService.isValidImageFile(selectedImage)) {
          _showError('Please select a valid image file (JPG, PNG, GIF, WebP)');
          return;
        }

        if (!SimpleImageService.isFileSizeValid(selectedImage, maxSizeMB: widget.maxFileSizeMB)) {
          _showError('Image size must be less than ${widget.maxFileSizeMB}MB');
          return;
        }

        setState(() {
          _selectedImage = selectedImage;
          _uploadError = null;
        });

        // Call callback
        widget.onImageSelected?.call(selectedImage);

        // Auto-upload if endpoint is provided
        if (widget.uploadEndpoint != null) {
          await _uploadImage(selectedImage);
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Image selected successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('DEBUG: No image selected or dialog cancelled');
      }
    } catch (e) {
      debugPrint('DEBUG: Error in image selection: $e');
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
        _showError('Error selecting image: $e');
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    if (widget.uploadEndpoint == null || !mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadError = null;
    });

    try {
      String? uploadedUrl = await SimpleImageService.uploadImage(
        imageFile: imageFile,
        endpoint: widget.uploadEndpoint!,
        fieldName: widget.fieldName,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      if (uploadedUrl != null) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 1.0;
        });

        // Call callback
        widget.onImageUploaded?.call(uploadedUrl);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Image uploaded successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Upload failed: No URL returned');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = 'Upload failed: $e';
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadError = null;
    });

    // Call callback
    widget.onImageRemoved?.call();

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Image removed'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String message) {
    setState(() {
      _uploadError = message;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// Specialized image picker for profile images
class SimpleProfileImagePicker extends StatelessWidget {
  final String? currentImageUrl;
  final Function(File)? onImageSelected;
  final Function(String)? onImageUploaded;
  final Function()? onImageRemoved;
  final String serviceProviderType;

  const SimpleProfileImagePicker({
    Key? key,
    this.currentImageUrl,
    this.onImageSelected,
    this.onImageUploaded,
    this.onImageRemoved,
    required this.serviceProviderType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleImagePicker(
      currentImageUrl: currentImageUrl,
      placeholderText: 'Add Profile Photo',
      width: 140,
      height: 140,
      isCircular: true,
      uploadEndpoint: '${AppConfig.getServiceProviderUrl(serviceProviderType)}/profile',
      fieldName: 'profileImage',
      onImageSelected: onImageSelected,
      onImageUploaded: onImageUploaded,
      onImageRemoved: onImageRemoved,
    );
  }
}

// Specialized image picker for portfolio images
class SimplePortfolioImagePicker extends StatelessWidget {
  final Function(File)? onImageSelected;
  final Function(String)? onImageUploaded;
  final String serviceProviderType;

  const SimplePortfolioImagePicker({
    Key? key,
    this.onImageSelected,
    this.onImageUploaded,
    required this.serviceProviderType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleImagePicker(
      placeholderText: 'Add Portfolio Image',
      width: 120,
      height: 120,
      isCircular: false,
      showRemoveButton: false,
      uploadEndpoint: '${AppConfig.getServiceProviderUrl(serviceProviderType)}/portfolio/images',
      fieldName: 'portfolioImage',
      onImageSelected: onImageSelected,
      onImageUploaded: onImageUploaded,
    );
  }
}