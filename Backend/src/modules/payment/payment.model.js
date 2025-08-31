const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database.config');

const PaymentTransaction = sequelize.define('PaymentTransaction', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  bookingId: {
    type: DataTypes.UUID,
    allowNull: false,
    field: 'booking_id',
    references: {
      model: 'bookings',
      key: 'id',
    },
  },
  khaltiTransactionId: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'khalti_transaction_id',
  },
  khaltiPaymentUrl: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'khalti_payment_url',
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  currency: {
    type: DataTypes.STRING(3),
    allowNull: false,
    defaultValue: 'NPR',
  },
  status: {
    type: DataTypes.ENUM('pending', 'completed', 'failed', 'cancelled'),
    defaultValue: 'pending',
  },
  paymentMethod: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'khalti',
    field: 'payment_method',
  },
  khaltiResponse: {
    type: DataTypes.JSONB,
    allowNull: true,
    field: 'khalti_response',
  },
  failureReason: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'failure_reason',
  },
  completedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'completed_at',
  },
}, {
  timestamps: true,
  tableName: 'payment_transactions',
  underscored: true,
});

module.exports = PaymentTransaction; 