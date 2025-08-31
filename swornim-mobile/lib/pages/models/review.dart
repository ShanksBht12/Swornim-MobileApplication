class Review {
  final String id;
  final String bookingId;
  final String clientId;
  final String serviceProviderId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String>? images;
  // Client information
  final String? clientName;
  final String? clientProfileImage;

  Review({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.serviceProviderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images,
    this.clientName,
    this.clientProfileImage,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Handle nested client data from backend
    Map<String, dynamic>? clientData;
    if (json['client'] != null) {
      clientData = json['client'] is Map ? Map<String, dynamic>.from(json['client']) : null;
    }

    return Review(
      id: json['id'],
      bookingId: json['bookingId'],
      clientId: json['clientId'],
      serviceProviderId: json['serviceProviderId'],
      rating: json['rating'] is String ? double.parse(json['rating']) : json['rating'].toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      clientName: clientData?['name'] ?? json['clientName'],
      clientProfileImage: clientData?['profileImage'] ?? json['clientProfileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'client_id': clientId,
      'service_provider_id': serviceProviderId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'images': images,
      'client_name': clientName,
      'client_profile_image': clientProfileImage,
    };
  }
}