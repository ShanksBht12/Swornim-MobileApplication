const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database.config');

const Booking = sequelize.define('Booking', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  clientId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  serviceProviderId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  packageId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  serviceType: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  eventDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  eventTime: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  eventLocation: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  eventType: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  totalAmount: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM(
      'pending_provider_confirmation',
      'pending_modification', 
      'modification_requested',
      'confirmed_awaiting_payment',
      'confirmed_paid',
      'in_progress',
      'completed',
      'cancelled_by_client',
      'cancelled_by_provider',
      'rejected',
      'refunded',
      'dispute_raised',
      'dispute_resolved'
    ),
    defaultValue: 'pending_provider_confirmation',
  },
  specialRequests: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  paymentStatus: {
    type: DataTypes.ENUM('pending', 'paid', 'refunded', 'failed', 'partiallyPaid', 'authorized'),
    defaultValue: 'pending',
  },
  packageSnapshot: {
    type: DataTypes.JSONB,
    allowNull: true,
  },
  // Enhanced booking management fields
  modificationRequest: {
    type: DataTypes.JSONB,
    allowNull: true,
    comment: 'Stores modification request details from provider'
  },
  cancellationReason: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Reason for cancellation'
  },
  cancellationRequestedBy: {
    type: DataTypes.ENUM('client', 'provider'),
    allowNull: true,
    comment: 'Who requested the cancellation'
  },
  cancellationRequestedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'When cancellation was requested'
  },
  confirmedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'When booking was confirmed by provider'
  },
  paymentDueDate: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'Payment deadline after confirmation'
  },
  autoExpiryDate: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'Auto-cancel date for unconfirmed bookings'
  },
  disputeDetails: {
    type: DataTypes.JSONB,
    allowNull: true,
    comment: 'Dispute information if raised'
  },
}, {
  timestamps: true, // adds createdAt and updatedAt
  tableName: 'bookings',
});

// --- Associations ---
const User = require('../user/user.model');
const ServicePackage = require('../package/package.model');
const PaymentTransaction = require('../payment/payment.model');

Booking.belongsTo(User, { as: 'client', foreignKey: 'clientId' });
Booking.belongsTo(User, { as: 'serviceProvider', foreignKey: 'serviceProviderId' });
Booking.belongsTo(ServicePackage, { as: 'package', foreignKey: 'packageId' });

// Payment Transaction associations
Booking.hasMany(PaymentTransaction, { 
  as: 'paymentTransactions', 
  foreignKey: 'bookingId',
  onDelete: 'CASCADE',
  onUpdate: 'CASCADE'
});

module.exports = Booking; 