const Review = require('./review.model');
const Booking = require('../booking/booking.model');
const User = require('../user/user.model');

class ReviewService {
  // Create a new review
  async createReview(reviewData) {
    try {
      console.log('=== [DEBUG] reviewService.createReview called ===');
      console.log('[DEBUG] reviewData:', reviewData);
      // Verify the booking exists and is completed
      const booking = await Booking.findByPk(reviewData.bookingId);
      console.log('[DEBUG] Booking found:', booking);
      if (!booking) {
        console.log('[DEBUG] Booking not found');
        throw {
          code: 404,
          message: "Booking not found",
          status: "BOOKING_NOT_FOUND"
        };
      }

      if (booking.status !== 'completed') {
        console.log('[DEBUG] Booking status not completed:', booking.status);
        throw {
          code: 400,
          message: "Can only review completed bookings",
          status: "INVALID_BOOKING_STATUS"
        };
      }

      // Check if review already exists for this booking
      const existingReview = await Review.findOne({
        where: { bookingId: reviewData.bookingId }
      });
      console.log('[DEBUG] existingReview:', existingReview);

      if (existingReview) {
        console.log('[DEBUG] Review already exists for this booking');
        throw {
          code: 400,
          message: "Review already exists for this booking",
          status: "REVIEW_ALREADY_EXISTS"
        };
      }

      // Create the review
      const review = await Review.create(reviewData);
      console.log('[DEBUG] Review created:', review);

      // Update service provider's average rating
      await this.updateProviderRating(reviewData.serviceProviderId);
      console.log('[DEBUG] Provider rating updated');

      return review;
    } catch (error) {
      console.error('Create review error:', error);
      throw error;
    }
  }

  // Get reviews for a service provider
  async getProviderReviews(serviceProviderId, options = {}) {
    try {
      const { page = 1, limit = 10, sortBy = 'createdAt', sortOrder = 'DESC' } = options;
      const offset = (page - 1) * limit;

      const reviews = await Review.findAndCountAll({
        where: { serviceProviderId },
        include: [
          {
            model: User,
            as: 'client',
            attributes: ['id', 'name', 'profileImage'],
          },
          {
            model: Booking,
            as: 'booking',
            attributes: ['id', 'eventType', 'eventDate'],
          },
        ],
        order: [[sortBy, sortOrder]],
        limit,
        offset,
      });

      return {
        reviews: reviews.rows,
        total: reviews.count,
        page,
        totalPages: Math.ceil(reviews.count / limit),
      };
    } catch (error) {
      console.error('Get provider reviews error:', error);
      throw error;
    }
  }

  // Get reviews by a client
  async getClientReviews(clientId, options = {}) {
    try {
      const { page = 1, limit = 10 } = options;
      const offset = (page - 1) * limit;

      const reviews = await Review.findAndCountAll({
        where: { clientId },
        include: [
          {
            model: User,
            as: 'serviceProvider',
            attributes: ['id', 'name', 'profileImage'],
          },
          {
            model: Booking,
            as: 'booking',
            attributes: ['id', 'eventType', 'eventDate', 'serviceType'],
          },
        ],
        order: [['createdAt', 'DESC']],
        limit,
        offset,
      });

      return {
        reviews: reviews.rows,
        total: reviews.count,
        page,
        totalPages: Math.ceil(reviews.count / limit),
      };
    } catch (error) {
      console.error('Get client reviews error:', error);
      throw error;
    }
  }

  // Update a review
  async updateReview(reviewId, clientId, updateData) {
    try {
      const review = await Review.findOne({
        where: { id: reviewId, clientId }
      });

      if (!review) {
        throw {
          code: 404,
          message: "Review not found or unauthorized",
          status: "REVIEW_NOT_FOUND"
        };
      }

      // Update the review
      await review.update(updateData);

      // Update service provider's average rating
      await this.updateProviderRating(review.serviceProviderId);

      return review;
    } catch (error) {
      console.error('Update review error:', error);
      throw error;
    }
  }

  // Delete a review
  async deleteReview(reviewId, clientId) {
    try {
      const review = await Review.findOne({
        where: { id: reviewId, clientId }
      });

      if (!review) {
        throw {
          code: 404,
          message: "Review not found or unauthorized",
          status: "REVIEW_NOT_FOUND"
        };
      }

      const serviceProviderId = review.serviceProviderId;
      await review.destroy();

      // Update service provider's average rating
      await this.updateProviderRating(serviceProviderId);

      return { success: true };
    } catch (error) {
      console.error('Delete review error:', error);
      throw error;
    }
  }

  // Update service provider's average rating
  async updateProviderRating(serviceProviderId) {
    try {
      const reviews = await Review.findAll({
        where: { serviceProviderId },
        attributes: ['rating']
      });

      if (reviews.length === 0) {
        // No reviews, set default values
        await this.updateProviderRatingFields(serviceProviderId, 0, 0);
        return;
      }

      const totalRating = reviews.reduce((sum, review) => sum + parseFloat(review.rating), 0);
      const averageRating = totalRating / reviews.length;
      const totalReviews = reviews.length;

      await this.updateProviderRatingFields(serviceProviderId, averageRating, totalReviews);
    } catch (error) {
      console.error('Update provider rating error:', error);
      throw error;
    }
  }

  // Update rating fields for different service provider types
  async updateProviderRatingFields(serviceProviderId, averageRating, totalReviews) {
    try {
      // Try to update each service provider type
      const providerTypes = ['photographer', 'makeupartist', 'decorator', 'caterer', 'venue'];
      
      for (const type of providerTypes) {
        try {
          const ProviderModel = require(`../${type}/${type}.model`);
          const provider = await ProviderModel.findOne({
            where: { userId: serviceProviderId }
          });
          
          if (provider) {
            provider.updateRating(averageRating, totalReviews);
            await provider.save();
            break; // Found and updated, exit loop
          }
        } catch (error) {
          // Continue to next provider type
          continue;
        }
      }
    } catch (error) {
      console.error('Update provider rating fields error:', error);
      throw error;
    }
  }

  // Get review statistics for a service provider
  async getReviewStatistics(serviceProviderId) {
    try {
      const reviews = await Review.findAll({
        where: { serviceProviderId },
        attributes: ['rating']
      });

      if (reviews.length === 0) {
        return {
          totalReviews: 0,
          averageRating: 0,
          ratingDistribution: {
            1: 0, 2: 0, 3: 0, 4: 0, 5: 0
          }
        };
      }

      const ratings = reviews.map(r => parseFloat(r.rating));
      const totalReviews = ratings.length;
      const averageRating = ratings.reduce((sum, rating) => sum + rating, 0) / totalReviews;

      // Calculate rating distribution
      const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
      ratings.forEach(rating => {
        const roundedRating = Math.round(rating);
        ratingDistribution[roundedRating]++;
      });

      return {
        totalReviews,
        averageRating: parseFloat(averageRating.toFixed(2)),
        ratingDistribution
      };
    } catch (error) {
      console.error('Get review statistics error:', error);
      throw error;
    }
  }
}

module.exports = new ReviewService(); 