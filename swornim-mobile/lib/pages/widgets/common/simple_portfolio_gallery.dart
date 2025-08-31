import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swornim/pages/services/simple_image_service.dart';
import 'package:swornim/config/app_config.dart';

class SimplePortfolioGallery extends StatefulWidget {
  final List<String> images;
  final String serviceProviderType;
  final bool isEditable;
  final Function(String)? onImageAdded;
  final Function(String)? onImageRemoved;
  final int maxImages;
  final double imageSize;
  final int crossAxisCount;

  const SimplePortfolioGallery({
    Key? key,
    required this.images,
    required this.serviceProviderType,
    this.isEditable = false,
    this.onImageAdded,
    this.onImageRemoved,
    this.maxImages = 10,
    this.imageSize = 100,
    this.crossAxisCount = 3,
  }) : super(key: key);

  @override
  State<SimplePortfolioGallery> createState() => _SimplePortfolioGalleryState();
}

class _SimplePortfolioGalleryState extends State<SimplePortfolioGallery> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.photo_library,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Portfolio Gallery',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (widget.isEditable && widget.images.length < widget.maxImages)
              IconButton(
                onPressed: _addImage,
                icon: const Icon(Icons.add_photo_alternate),
                tooltip: 'Add Image',
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Image grid
        if (widget.images.isEmpty)
          _buildEmptyState()
        else
          _buildImageGrid(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.imageSize * 2,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No portfolio images yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            if (widget.isEditable) ...[
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first image',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.images.length + (widget.isEditable && widget.images.length < widget.maxImages ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.isEditable && index == widget.images.length) {
          return _buildAddImageTile();
        }
        return _buildImageTile(widget.images[index], index);
      },
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: _addImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              'Add Image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _showImageDialog(imageUrl),
      child: Container(
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
        child: Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            
            // Remove button (if editable)
            if (widget.isEditable)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(imageUrl),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addImage() async {
    try {
      File? selectedImage = await SimpleImageService.showImageSourceDialog(
        context: context,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (selectedImage != null) {
        // Validate file
        if (!SimpleImageService.isValidImageFile(selectedImage)) {
          _showError('Please select a valid image file (JPG, PNG, GIF, WebP)');
          return;
        }

        if (!SimpleImageService.isFileSizeValid(selectedImage, maxSizeMB: 5.0)) {
          _showError('Image size must be less than 5MB');
          return;
        }

        // Upload image
        String? uploadedUrl = await SimpleImageService.uploadPortfolioImage(
          imageFile: selectedImage,
          serviceProviderType: widget.serviceProviderType,
        );

        if (uploadedUrl != null) {
          widget.onImageAdded?.call(uploadedUrl);
          _showSuccess('Image added to portfolio');
        } else {
          _showError('Failed to upload image');
        }
      }
    } catch (e) {
      _showError('Error adding image: $e');
    }
  }

  Future<void> _removeImage(String imageUrl) async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from backend
        bool success = await SimpleImageService.deleteImage(
          imageUrl: imageUrl,
          endpoint: '${AppConfig.getServiceProviderUrl(widget.serviceProviderType)}/portfolio/images',
          body: {'imageUrl': imageUrl},
        );

        if (success) {
          widget.onImageRemoved?.call(imageUrl);
          _showSuccess('Image removed from portfolio');
        } else {
          _showError('Failed to remove image');
        }
      } catch (e) {
        _showError('Error removing image: $e');
      }
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                if (widget.isEditable)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _removeImage(imageUrl);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
} 