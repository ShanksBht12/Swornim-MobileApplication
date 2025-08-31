const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database.config');

const EventTicketBooking = sequelize.define('EventTicketBooking', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  event_id: { type: DataTypes.UUID, allowNull: false },
  user_id: { type: DataTypes.UUID, allowNull: false },
  ticket_type: {
    type: DataTypes.ENUM('regular', 'vip', 'student', 'early_bird', 'group', 'complimentary'),
    allowNull: false,
    defaultValue: 'regular',
  },
  quantity: { type: DataTypes.INTEGER, allowNull: false },
  price_per_ticket: { type: DataTypes.FLOAT, allowNull: false },
  total_amount: { type: DataTypes.FLOAT, allowNull: false },
  payment_status: { type: DataTypes.ENUM('pending', 'paid', 'failed', 'refunded'), defaultValue: 'pending' },
  status: {
    type: DataTypes.ENUM('pending', 'confirmed', 'cancelled', 'attended', 'no_show', 'refunded'),
    defaultValue: 'pending',
    allowNull: false,
  },
  booking_status: { type: DataTypes.ENUM('confirmed', 'cancelled', 'refunded'), defaultValue: 'confirmed' },
  qr_code: { type: DataTypes.STRING, allowNull: true },
  special_requests: { type: DataTypes.TEXT, allowNull: true },
  ticket_holder_details: { type: DataTypes.JSONB, allowNull: true },
  payment_method: { type: DataTypes.STRING, allowNull: true },
  payment_date: { type: DataTypes.DATE, allowNull: true },
  discount_amount: { type: DataTypes.FLOAT, allowNull: true },
  discount_code: { type: DataTypes.STRING, allowNull: true },
  cancellation_reason: { type: DataTypes.TEXT, allowNull: true },
}, {
  timestamps: true,
  tableName: 'event_ticket_bookings',
});

// Add association to User
const User = require('../user/user.model');
EventTicketBooking.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

module.exports = EventTicketBooking; 