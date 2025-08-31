const express = require('express');
const router = express.Router();
const reviewController = require('./review.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

// Add debug logging middleware for review routes
router.use((req, res, next) => {
  console.log('=== REVIEW ROUTER ===');
  console.log('Method:', req.method);
  console.log('URL:', req.url);
  console.log('Path:', req.path);
  console.log('Headers:', req.headers);
  console.log('=====================');
  next();
});

// Apply authentication middleware to all routes
console.log('[DEBUG] Applying auth middleware to review routes');
router.use(authMiddleware());

// Create a new review
router.post('/', (req, res, next) => {
  console.log('=== [DEBUG] POST /reviews route handler called ===');
  console.log('Request body:', req.body);
  reviewController.createReview(req, res, next);
});

// Get reviews for a service provider
router.get('/provider/:serviceProviderId', reviewController.getProviderReviews);

// Get reviews by the authenticated client
router.get('/client', reviewController.getClientReviews);

// Get review statistics for a service provider
router.get('/statistics/:serviceProviderId', reviewController.getReviewStatistics);

// Update a review (only by the client who created it)
router.put('/:reviewId', reviewController.updateReview);

// Delete a review (only by the client who created it)
router.delete('/:reviewId', reviewController.deleteReview);

module.exports = router; 