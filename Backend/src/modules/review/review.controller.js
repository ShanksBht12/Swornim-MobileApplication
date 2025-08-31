const reviewService = require('./review.service');
const { validateReviewData } = require('./review.validator');

// Create a new review
async function createReview(req, res, next) {
  try {
    console.log('=== [DEBUG] createReview controller called ===');
    console.log('Request body:', req.body);
    const { error, value } = validateReviewData(req.body);
    if (error) {
      console.log('[DEBUG] Validation error:', error.details[0].message);
      return res.status(400).json({ error: error.details[0].message });
    }

    const clientId = req.user?.id || req.loggedInUser?.id;
    console.log('[DEBUG] clientId:', clientId);
    if (!clientId) {
      console.log('[DEBUG] No user ID found in request');
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const reviewData = {
      ...value,
      clientId,
    };
    console.log('[DEBUG] reviewData to service:', reviewData);

    let review;
    try {
      review = await reviewService.createReview(reviewData);
      console.log('[DEBUG] reviewService.createReview returned:', review);
    } catch (serviceError) {
      console.log('[DEBUG] Error from reviewService.createReview:', serviceError);
      throw serviceError;
    }
    
    res.status(201).json({
      success: true,
      data: review,
      message: "Review created successfully",
      status: "REVIEW_CREATED"
    });
    console.log('[DEBUG] Response sent for createReview');
  } catch (error) {
    console.error('Create review error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Get reviews for a service provider
async function getProviderReviews(req, res, next) {
  try {
    const { serviceProviderId } = req.params;
    const { page, limit, sortBy, sortOrder } = req.query;

    const options = {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 10,
      sortBy: sortBy || 'createdAt',
      sortOrder: sortOrder || 'DESC',
    };

    const result = await reviewService.getProviderReviews(serviceProviderId, options);
    
    res.json({
      success: true,
      data: result,
      message: "Reviews retrieved successfully",
      status: "REVIEWS_RETRIEVED"
    });
  } catch (error) {
    console.error('Get provider reviews error:', error);
    next(error);
  }
}

// Get reviews by a client
async function getClientReviews(req, res, next) {
  try {
    const clientId = req.user?.id || req.loggedInUser?.id;
    if (!clientId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const { page, limit } = req.query;
    const options = {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 10,
    };

    const result = await reviewService.getClientReviews(clientId, options);
    
    res.json({
      success: true,
      data: result,
      message: "Client reviews retrieved successfully",
      status: "CLIENT_REVIEWS_RETRIEVED"
    });
  } catch (error) {
    console.error('Get client reviews error:', error);
    next(error);
  }
}

// Update a review
async function updateReview(req, res, next) {
  try {
    const { reviewId } = req.params;
    const { error, value } = validateReviewData(req.body, true); // true for update
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const clientId = req.user?.id || req.loggedInUser?.id;
    if (!clientId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const review = await reviewService.updateReview(reviewId, clientId, value);
    
    res.json({
      success: true,
      data: review,
      message: "Review updated successfully",
      status: "REVIEW_UPDATED"
    });
  } catch (error) {
    console.error('Update review error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Delete a review
async function deleteReview(req, res, next) {
  try {
    const { reviewId } = req.params;
    const clientId = req.user?.id || req.loggedInUser?.id;
    
    if (!clientId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    await reviewService.deleteReview(reviewId, clientId);
    
    res.json({
      success: true,
      message: "Review deleted successfully",
      status: "REVIEW_DELETED"
    });
  } catch (error) {
    console.error('Delete review error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Get review statistics for a service provider
async function getReviewStatistics(req, res, next) {
  try {
    const { serviceProviderId } = req.params;
    
    const statistics = await reviewService.getReviewStatistics(serviceProviderId);
    
    res.json({
      success: true,
      data: statistics,
      message: "Review statistics retrieved successfully",
      status: "STATISTICS_RETRIEVED"
    });
  } catch (error) {
    console.error('Get review statistics error:', error);
    next(error);
  }
}

module.exports = {
  createReview,
  getProviderReviews,
  getClientReviews,
  updateReview,
  deleteReview,
  getReviewStatistics,
}; 