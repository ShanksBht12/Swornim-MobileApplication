const express = require('express');
const router = express.Router();
const paymentController = require('./payment.controller');
const auth = require('../../middlewares/auth.middleware');

// Initialize Khalti payment for a booking
router.post(
  '/:bookingId/init-khalti',
  auth(),
  paymentController.initializeKhaltiPayment
);

// Verify Khalti payment
router.post(
  '/verify',
  paymentController.verifyKhaltiPayment
);

// Get payment status for a booking
router.get(
  '/:bookingId/status',
  auth(),
  paymentController.getPaymentStatus
);

// Update payment status for a booking
router.post(
  '/:bookingId/update-status',
  auth(),
  paymentController.updatePaymentStatus
);

// Get payment history for a user
router.get(
  '/history',
  auth(),
  paymentController.getPaymentHistory
);

// Payment success page (for Khalti redirect)
router.get(
  '/success',
  paymentController.paymentSuccessPage
);

// Khalti callback endpoint (webhook) - Not used as Khalti doesn't support webhooks
// router.post(
//   '/khalti-callback',
//   paymentController.khaltiCallback
// );

// Test Khalti configuration
router.get(
  '/test-config',
  paymentController.testKhaltiConfig
);

module.exports = router; 