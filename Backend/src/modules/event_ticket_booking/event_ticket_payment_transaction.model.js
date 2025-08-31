const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database.config');

const EventTicketPaymentTransaction = sequelize.define('EventTicketPaymentTransaction', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  booking_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'event_ticket_bookings',
      key: 'id',
    },
  },
  khalti_transaction_id: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  khalti_payment_url: {
    type: DataTypes.TEXT,
    allowNull: true,
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
    allowNull: false,
  },
  payment_method: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'khalti',
  },
  khalti_response: {
    type: DataTypes.JSONB,
    allowNull: true,
  },
  failure_reason: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  completed_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  timestamps: true,
  tableName: 'event_ticket_payment_transactions',
  underscored: true,
});

module.exports = EventTicketPaymentTransaction; 