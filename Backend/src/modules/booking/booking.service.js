const Booking = require('./booking.model');
const User = require('../user/user.model');
const ServicePackage = require('../package/package.model');
const PaymentTransaction = require('../payment/payment.model');
const { UserType } = require('../../config/constants');

class BookingService {
  // Create a new booking with enhanced flow
  async createBooking(bookingData, clientId) {
    try {
      // Set auto-expiry date (48 hours from now)
      const autoExpiryDate = new Date();
      autoExpiryDate.setHours(autoExpiryDate.getHours() + 48);

      const booking = await Booking.create({
        ...bookingData,
        clientId,
        status: 'pending_provider_confirmation',
        paymentStatus: 'pending',
        autoExpiryDate,
      });

      // Send notification to service provider (implement notification service)
      await this.sendProviderNotification(booking);

      return booking;
    } catch (error) {
      console.error('Create booking error:', error);
      throw error;
    }
  }

  // Provider reviews and confirms booking
  async confirmBooking(bookingId, providerId, options = {}) {
    try {
      const booking = await Booking.findOne({
        where: {
          id: bookingId,
          serviceProviderId: providerId,
          status: 'pending_provider_confirmation'
        }
      });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or already processed",
          status: "BOOKING_NOT_FOUND"
        };
      }

      // Set payment due date (24 hours from confirmation)
      const paymentDueDate = new Date();
      paymentDueDate.setHours(paymentDueDate.getHours() + 24);

      await booking.update({
        status: 'confirmed_awaiting_payment',
        confirmedAt: new Date(),
        paymentDueDate,
        autoExpiryDate: null, // Clear auto-expiry since it's confirmed
      });

      // Send notification to client
      await this.sendClientNotification(booking, 'confirmed');

      return booking;
    } catch (error) {
      console.error('Confirm booking error:', error);
      throw error;
    }
  }

  // Provider rejects booking
  async rejectBooking(bookingId, providerId, reason) {
    try {
      const booking = await Booking.findOne({
        where: {
          id: bookingId,
          serviceProviderId: providerId,
          status: 'pending_provider_confirmation'
        }
      });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or already processed",
          status: "BOOKING_NOT_FOUND"
        };
      }

      await booking.update({
        status: 'rejected',
        cancellationReason: reason,
        cancellationRequestedBy: 'provider',
        cancellationRequestedAt: new Date(),
      });

      // Send notification to client
      await this.sendClientNotification(booking, 'rejected');

      return booking;
    } catch (error) {
      console.error('Reject booking error:', error);
      throw error;
    }
  }

  // Provider requests modifications
  async requestModification(bookingId, providerId, modificationRequest) {
    try {
      const booking = await Booking.findOne({
        where: {
          id: bookingId,
          serviceProviderId: providerId,
          status: 'pending_provider_confirmation'
        }
      });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or already processed",
          status: "BOOKING_NOT_FOUND"
        };
      }

      await booking.update({
        status: 'modification_requested',
        modificationRequest,
      });

      // Send notification to client
      await this.sendClientNotification(booking, 'modification_requested');

      return booking;
    } catch (error) {
      console.error('Request modification error:', error);
      throw error;
    }
  }

  // Client responds to modification request
  async respondToModification(bookingId, clientId, response) {
    try {
      const booking = await Booking.findOne({
        where: {
          id: bookingId,
          clientId,
          status: 'modification_requested'
        }
      });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or not in modification state",
          status: "BOOKING_NOT_FOUND"
        };
      }

      if (response.accepted) {
        // Apply modifications and confirm
        const updatedData = {
          ...response.modifications,
          status: 'confirmed_awaiting_payment',
          confirmedAt: new Date(),
          paymentDueDate: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
          modificationRequest: null,
        };

        await booking.update(updatedData);
        await this.sendProviderNotification(booking);
      } else {
        // Reject modifications, back to pending
        await booking.update({
          status: 'pending_provider_confirmation',
          modificationRequest: null,
        });
      }

      return booking;
    } catch (error) {
      console.error('Respond to modification error:', error);
      throw error;
    }
  }

  // Cancel booking (client or provider)
  async cancelBooking(bookingId, userId, userType, reason) {
    try {
      const whereClause = {
        id: bookingId,
        status: ['pending_provider_confirmation', 'confirmed_awaiting_payment']
      };

      if (userType === 'client') {
        whereClause.clientId = userId;
      } else {
        whereClause.serviceProviderId = userId;
      }

      const booking = await Booking.findOne({ where: whereClause });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or cannot be cancelled",
          status: "BOOKING_NOT_FOUND"
        };
      }

      const cancellationStatus = userType === 'client' ? 'cancelled_by_client' : 'cancelled_by_provider';

      await booking.update({
        status: cancellationStatus,
        cancellationReason: reason,
        cancellationRequestedBy: userType,
        cancellationRequestedAt: new Date(),
      });

      // Handle refund if payment was made
      if (booking.paymentStatus === 'paid') {
        await this.processRefund(booking);
      }

      // Send notification
      const notificationType = userType === 'client' ? 'cancelled_by_client' : 'cancelled_by_provider';
      await this.sendNotification(booking, notificationType);

      return booking;
    } catch (error) {
      console.error('Cancel booking error:', error);
      throw error;
    }
  }

  // Start service (provider)
  async startService(bookingId, providerId) {
    try {
      const booking = await Booking.findOne({
        where: {
          id: bookingId,
          serviceProviderId: providerId,
          status: 'confirmed_paid'
        }
      });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or not ready to start",
          status: "BOOKING_NOT_FOUND"
        };
      }

      await booking.update({
        status: 'in_progress',
      });

      await this.sendClientNotification(booking, 'service_started');

      return booking;
    } catch (error) {
      console.error('Start service error:', error);
      throw error;
    }
  }

  // Complete service (provider)
  async completeService(bookingId, providerId) {
    try {
      const booking = await Booking.findOne({
        where: {
          id: bookingId,
          serviceProviderId: providerId,
          status: 'in_progress'
        }
      });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or not in progress",
          status: "BOOKING_NOT_FOUND"
        };
      }

      await booking.update({
        status: 'completed',
      });

      await this.sendClientNotification(booking, 'service_completed');

      return booking;
    } catch (error) {
      console.error('Complete service error:', error);
      throw error;
    }
  }

  // Raise dispute
  async raiseDispute(bookingId, userId, userType, disputeDetails) {
    try {
      const whereClause = {
        id: bookingId,
        status: ['confirmed_paid', 'in_progress', 'completed']
      };

      if (userType === 'client') {
        whereClause.clientId = userId;
      } else {
        whereClause.serviceProviderId = userId;
      }

      const booking = await Booking.findOne({ where: whereClause });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or cannot raise dispute",
          status: "BOOKING_NOT_FOUND"
        };
      }

      await booking.update({
        status: 'dispute_raised',
        disputeDetails: {
          ...disputeDetails,
          raisedBy: userType,
          raisedAt: new Date(),
        }
      });

      await this.sendNotification(booking, 'dispute_raised');

      return booking;
    } catch (error) {
      console.error('Raise dispute error:', error);
      throw error;
    }
  }

  // Resolve dispute (admin or mutual agreement)
  async resolveDispute(bookingId, resolution) {
    try {
      const booking = await Booking.findOne({
        where: {
          id: bookingId,
          status: 'dispute_raised'
        }
      });

      if (!booking) {
        throw {
          code: 404,
          message: "Booking not found or not in dispute",
          status: "BOOKING_NOT_FOUND"
        };
      }

      await booking.update({
        status: 'dispute_resolved',
        disputeDetails: {
          ...booking.disputeDetails,
          resolution,
          resolvedAt: new Date(),
        }
      });

      await this.sendNotification(booking, 'dispute_resolved');

      return booking;
    } catch (error) {
      console.error('Resolve dispute error:', error);
      throw error;
    }
  }

  // Process refund
  async processRefund(booking) {
    try {
      // Find the payment transaction
      const paymentTransaction = await PaymentTransaction.findOne({
        where: {
          bookingId: booking.id,
          status: 'completed'
        }
      });

      if (paymentTransaction) {
        // Update payment transaction
        await paymentTransaction.update({
          status: 'cancelled',
          failureReason: 'Refunded due to booking cancellation'
        });

        // Update booking payment status
        await booking.update({
          paymentStatus: 'refunded'
        });

        // TODO: Integrate with Khalti refund API
        // await this.initiateKhaltiRefund(paymentTransaction.khaltiTransactionId);
      }
    } catch (error) {
      console.error('Process refund error:', error);
      throw error;
    }
  }

  // Auto-expire pending bookings
  async autoExpirePendingBookings() {
    try {
      const expiredBookings = await Booking.findAll({
        where: {
          status: 'pending_provider_confirmation',
          autoExpiryDate: {
            [require('sequelize').Op.lt]: new Date()
          }
        }
      });

      for (const booking of expiredBookings) {
        await booking.update({
          status: 'cancelled_by_provider',
          cancellationReason: 'Auto-expired due to no response from provider',
          cancellationRequestedBy: 'system',
          cancellationRequestedAt: new Date(),
        });

        await this.sendClientNotification(booking, 'auto_expired');
      }

      return expiredBookings.length;
    } catch (error) {
      console.error('Auto-expire bookings error:', error);
      throw error;
    }
  }

  // Send payment reminders
  async sendPaymentReminders() {
    try {
      const dueBookings = await Booking.findAll({
        where: {
          status: 'confirmed_awaiting_payment',
          paymentDueDate: {
            [require('sequelize').Op.lt]: new Date()
          }
        }
      });

      for (const booking of dueBookings) {
        await this.sendClientNotification(booking, 'payment_reminder');
      }

      return dueBookings.length;
    } catch (error) {
      console.error('Send payment reminders error:', error);
      throw error;
    }
  }

  // Notification methods (placeholder - implement with your notification service)
  async sendProviderNotification(booking) {
    // TODO: Implement notification service
    console.log(`Notification sent to provider ${booking.serviceProviderId} for booking ${booking.id}`);
  }

  async sendClientNotification(booking, type) {
    // TODO: Implement notification service
    console.log(`Notification sent to client ${booking.clientId} for booking ${booking.id} - ${type}`);
  }

  async sendNotification(booking, type) {
    // TODO: Implement notification service
    console.log(`Notification sent for booking ${booking.id} - ${type}`);
  }

  // Get booking statistics
  async getBookingStats(userId, userType) {
    try {
      const whereClause = userType === 'client' 
        ? { clientId: userId }
        : { serviceProviderId: userId };

      const stats = await Booking.findAll({
        where: whereClause,
        attributes: [
          'status',
          [require('sequelize').fn('COUNT', require('sequelize').col('id')), 'count']
        ],
        group: ['status']
      });

      return stats.reduce((acc, stat) => {
        acc[stat.status] = parseInt(stat.dataValues.count);
        return acc;
      }, {});
    } catch (error) {
      console.error('Get booking stats error:', error);
      throw error;
    }
  }
}

module.exports = new BookingService(); 