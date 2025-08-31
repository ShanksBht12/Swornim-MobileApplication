const Booking = require('./booking.model');
const { CreateBookingDTO, UpdateBookingDTO, UpdateBookingStatusDTO } = require('./booking.validator');
const User = require('../user/user.model');
const ServicePackage = require('../package/package.model');
const { UserType } = require('../../config/constants');
const bookingService = require('./booking.service');

// Create a new booking
async function createBooking(req, res, next) {
  try {
    console.log('=== CREATE BOOKING CONTROLLER ===');
    console.log('Headers:', req.headers);
    console.log('Body:', req.body);
    console.log('User:', req.loggedInUser?.id);
    console.log('==============================');
    
    const { error, value } = CreateBookingDTO.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });
    
    // Extract clientId from authenticated user
    const clientId = req.user?.id || req.loggedInUser?.id;
    
    if (!clientId) {
      console.error('No user ID found in request');
      return res.status(401).json({ error: 'User not authenticated' });
    }
    
    // Fetch the package and create a snapshot
    const packageId = value.packageId;
    const servicePackage = await ServicePackage.findByPk(packageId);
    if (!servicePackage) {
      return res.status(404).json({ error: 'Selected package not found' });
    }
    const packageSnapshot = {
      id: servicePackage.id,
      name: servicePackage.name,
      basePrice: servicePackage.basePrice,
      durationHours: servicePackage.durationHours,
      features: servicePackage.features,
      description: servicePackage.description,
      serviceType: servicePackage.serviceType,
      isActive: servicePackage.isActive,
    };
    const bookingData = {
      ...value,
      serviceType: servicePackage.serviceType,
      packageSnapshot,
    };
    console.log('Booking creation debug:');
    console.log('  clientId:', clientId);
    console.log('  serviceProviderId:', bookingData.serviceProviderId);
    console.log('  bookingData:', bookingData);
    const booking = await bookingService.createBooking(bookingData, clientId);
    console.log('Booking created successfully:', booking.id);
    return res.status(201).json(booking);
  } catch (err) {
    console.error('Error creating booking:', err);
    next(err);
  }
}

// Get all bookings (filtered by authenticated user)
async function getBookings(req, res, next) {
  try {
    console.log('=== GET BOOKINGS CONTROLLER ===');
    console.log('Headers:', req.headers);
    console.log('Authorization header:', req.headers['authorization']);
    console.log('User:', req.user);
    const user = req.user;
    const where = {};
    if (user.userType === UserType.CLIENT) {
      where.clientId = user.id;
    } else if ([
      UserType.PHOTOGRAPHER,
      UserType.MAKEUP_ARTIST,
      UserType.DECORATOR,
      UserType.VENUE,
      UserType.CATERER
    ].includes(user.userType)) {
      where.serviceProviderId = user.id;
    } else {
      return res.status(403).json({ error: 'Not authorized to view bookings' });
    }
    console.log('Bookings WHERE clause:', where);
    const bookings = await Booking.findAll({
      where,
      include: [
        { model: User, as: 'client', attributes: ['id', 'name', 'email', 'phone'] },
        { model: User, as: 'serviceProvider', attributes: ['id', 'name', 'email', 'phone'] },
        { model: ServicePackage, as: 'package', attributes: ['id', 'name', 'basePrice'] }
      ]
    });
    return res.json(bookings);
  } catch (err) {
    next(err);
  }
}

// Get a single booking by ID
async function getBookingById(req, res, next) {
  try {
    // The booking is attached to the request by the checkBookingOwnership middleware
    return res.json(req.booking);
  } catch (err) {
    next(err);
  }
}

// Update a booking
async function updateBooking(req, res, next) {
  try {
    const { error, value } = UpdateBookingDTO.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });
    
    // The booking is attached to the request by the checkBookingOwnership middleware
    const booking = req.booking;
    await booking.update(value);
    return res.json(booking);
  } catch (err) {
    next(err);
  }
}

// Delete a booking
async function deleteBooking(req, res, next) {
  try {
    // The booking is attached to the request by the checkBookingOwnership middleware
    const booking = req.booking;
    await booking.destroy();
    return res.status(204).send();
  } catch (err) {
    next(err);
  }
}

// Update a booking's status
async function updateBookingStatus(req, res, next) {
  try {
    const { error, value } = UpdateBookingStatusDTO.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const { booking, user } = req; // from middleware
    const { status: newStatus } = value;
    const currentStatus = booking.status;
    const isClient = user.id === booking.clientId;
    const isServiceProvider = user.id === booking.serviceProviderId;

    console.log('=== UPDATE BOOKING STATUS ===');
    console.log('Booking ID:', booking.id);
    console.log('Current status:', currentStatus);
    console.log('New status:', newStatus);
    console.log('User ID:', user.id);
    console.log('Is client:', isClient);
    console.log('Is service provider:', isServiceProvider);
    console.log('============================');

    if (currentStatus === newStatus) {
      return res.status(400).json({ message: `Booking is already in '${currentStatus}' status.` });
    }

    // Define the state machine with actual enum values
    const allowedTransitions = {
      pending_provider_confirmation: {
        confirmed_awaiting_payment: isServiceProvider,
        rejected: isServiceProvider,
        modification_requested: isServiceProvider,
        cancelled_by_client: isClient,
      },
      modification_requested: {
        pending_provider_confirmation: isClient, // Client rejects modifications
        confirmed_awaiting_payment: isClient, // Client accepts modifications
      },
      confirmed_awaiting_payment: {
        confirmed_paid: isClient, // After payment
        cancelled_by_client: isClient,
        cancelled_by_provider: isServiceProvider,
      },
      confirmed_paid: {
        in_progress: isServiceProvider,
        cancelled_by_client: isClient,
        cancelled_by_provider: isServiceProvider,
      },
      in_progress: {
        completed: isServiceProvider,
        dispute_raised: isClient || isServiceProvider,
      },
      // Final states
      completed: {},
      cancelled_by_client: {},
      cancelled_by_provider: {},
      rejected: {},
      refunded: {},
      dispute_raised: {},
      dispute_resolved: {},
    };

    // Check if the transition is allowed
    const canTransition = allowedTransitions[currentStatus]?.[newStatus];

    if (canTransition) {
      // Handle special cases
      if (newStatus === 'confirmed_awaiting_payment') {
        // Set payment due date (24 hours from now)
        const paymentDueDate = new Date();
        paymentDueDate.setHours(paymentDueDate.getHours() + 24);
        
        await booking.update({
          status: newStatus,
          confirmedAt: new Date(),
          paymentDueDate,
          autoExpiryDate: null, // Clear auto-expiry since it's confirmed
        });
      } else {
        await booking.update({ status: newStatus });
      }
      
      console.log('Status updated successfully to:', newStatus);
      return res.json(booking);
    } else {
      // If the transition is not defined, it's invalid.
      console.log('Invalid transition attempted');
      return res.status(400).json({
        message: `Cannot change status from '${currentStatus}' to '${newStatus}'. Invalid transition or insufficient permissions.`
      });
    }
  } catch (err) {
    console.error('Error updating booking status:', err);
    next(err);
  }
}

// Enhanced booking flow methods

// Provider confirms booking
async function confirmBooking(req, res, next) {
  try {
    const bookingId = req.params.id; // Fix: use req.params.id instead of req.params.bookingId
    const providerId = req.user?.id || req.loggedInUser?.id;

    if (!providerId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    console.log('Confirming booking:', { bookingId, providerId });
    const booking = await bookingService.confirmBooking(bookingId, providerId);
    
    res.json({
      success: true,
      data: booking,
      message: "Booking confirmed successfully",
      status: "BOOKING_CONFIRMED"
    });
  } catch (error) {
    console.error('Confirm booking error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Provider rejects booking
async function rejectBooking(req, res, next) {
  try {
    const bookingId = req.params.id; // Fix: use req.params.id instead of req.params.bookingId
    const { reason } = req.body;
    const providerId = req.user?.id || req.loggedInUser?.id;

    if (!providerId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    if (!reason) {
      return res.status(400).json({ error: 'Rejection reason is required' });
    }

    console.log('Rejecting booking:', { bookingId, providerId, reason });
    const booking = await bookingService.rejectBooking(bookingId, providerId, reason);
    
    res.json({
      success: true,
      data: booking,
      message: "Booking rejected successfully",
      status: "BOOKING_REJECTED"
    });
  } catch (error) {
    console.error('Reject booking error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Provider requests modifications
async function requestModification(req, res, next) {
  try {
    const bookingId = req.params.id; // Fix: use req.params.id instead of req.params.bookingId
    const { modificationRequest } = req.body;
    const providerId = req.user?.id || req.loggedInUser?.id;

    if (!providerId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    if (!modificationRequest) {
      return res.status(400).json({ error: 'Modification request is required' });
    }

    console.log('Requesting modification:', { bookingId, providerId });
    const booking = await bookingService.requestModification(bookingId, providerId, modificationRequest);
    
    res.json({
      success: true,
      data: booking,
      message: "Modification request sent successfully",
      status: "MODIFICATION_REQUESTED"
    });
  } catch (error) {
    console.error('Request modification error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Client responds to modification request
async function respondToModification(req, res, next) {
  try {
    const bookingId = req.params.id; // Fix: use req.params.id instead of req.params.bookingId
    const { response } = req.body;
    const clientId = req.user?.id || req.loggedInUser?.id;

    if (!clientId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    if (!response) {
      return res.status(400).json({ error: 'Response is required' });
    }

    console.log('Responding to modification:', { bookingId, clientId });
    const booking = await bookingService.respondToModification(bookingId, clientId, response);
    
    res.json({
      success: true,
      data: booking,
      message: response.accepted ? "Modifications accepted" : "Modifications rejected",
      status: response.accepted ? "MODIFICATIONS_ACCEPTED" : "MODIFICATIONS_REJECTED"
    });
  } catch (error) {
    console.error('Respond to modification error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Cancel booking
async function cancelBooking(req, res, next) {
  try {
    const bookingId = req.params.id; // Fix: use req.params.id instead of req.params.bookingId
    const { reason } = req.body;
    const userId = req.user?.id || req.loggedInUser?.id;
    const userType = req.user?.userType === UserType.CLIENT ? 'client' : 'provider';

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    if (!reason) {
      return res.status(400).json({ error: 'Cancellation reason is required' });
    }

    console.log('Cancelling booking:', { bookingId, userId, userType, reason });
    const booking = await bookingService.cancelBooking(bookingId, userId, userType, reason);
    
    res.json({
      success: true,
      data: booking,
      message: "Booking cancelled successfully",
      status: "BOOKING_CANCELLED"
    });
  } catch (error) {
    console.error('Cancel booking error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Start service
async function startService(req, res, next) {
  try {
    const bookingId = req.params.id; // Fix: use req.params.id instead of req.params.bookingId
    const providerId = req.user?.id || req.loggedInUser?.id;

    if (!providerId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    console.log('Starting service:', { bookingId, providerId });
    const booking = await bookingService.startService(bookingId, providerId);
    
    res.json({
      success: true,
      data: booking,
      message: "Service started successfully",
      status: "SERVICE_STARTED"
    });
  } catch (error) {
    console.error('Start service error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Complete service
async function completeService(req, res, next) {
  try {
    const bookingId = req.params.id; // Fix: use req.params.id instead of req.params.bookingId
    const providerId = req.user?.id || req.loggedInUser?.id;

    if (!providerId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    console.log('Completing service:', { bookingId, providerId });
    const booking = await bookingService.completeService(bookingId, providerId);
    
    res.json({
      success: true,
      data: booking,
      message: "Service completed successfully",
      status: "SERVICE_COMPLETED"
    });
  } catch (error) {
    console.error('Complete service error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Raise dispute
async function raiseDispute(req, res, next) {
  try {
    const bookingId = req.params.id; // Fix: use req.params.id instead of req.params.bookingId
    const { disputeDetails } = req.body;
    const userId = req.user?.id || req.loggedInUser?.id;
    const userType = req.user?.userType === UserType.CLIENT ? 'client' : 'provider';

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    if (!disputeDetails) {
      return res.status(400).json({ error: 'Dispute details are required' });
    }

    console.log('Raising dispute:', { bookingId, userId, userType });
    const booking = await bookingService.raiseDispute(bookingId, userId, userType, disputeDetails);
    
    res.json({
      success: true,
      data: booking,
      message: "Dispute raised successfully",
      status: "DISPUTE_RAISED"
    });
  } catch (error) {
    console.error('Raise dispute error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Get booking statistics
async function getBookingStats(req, res, next) {
  try {
    const userId = req.user?.id || req.loggedInUser?.id;
    const userType = req.user?.userType === UserType.CLIENT ? 'client' : 'provider';

    if (!userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const stats = await bookingService.getBookingStats(userId, userType);
    
    res.json({
      success: true,
      data: stats,
      message: "Booking statistics retrieved successfully",
      status: "STATS_RETRIEVED"
    });
  } catch (error) {
    console.error('Get booking stats error:', error);
    next(error);
  }
}

module.exports = {
  createBooking,
  getBookings,
  getBookingById,
  updateBooking,
  deleteBooking,
  updateBookingStatus,
  confirmBooking,
  rejectBooking,
  requestModification,
  respondToModification,
  cancelBooking,
  startService,
  completeService,
  raiseDispute,
  getBookingStats,
}; 