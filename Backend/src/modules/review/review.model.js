const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database.config');

const Review = sequelize.define('Review', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  bookingId: {
    type: DataTypes.UUID,
    allowNull: false,
    field: 'booking_id',
  },
  clientId: {
    type: DataTypes.UUID,
    allowNull: false,
    field: 'client_id',
  },
  serviceProviderId: {
    type: DataTypes.UUID,
    allowNull: false,
    field: 'service_provider_id',
  },
  rating: {
    type: DataTypes.DECIMAL(3, 2),
    allowNull: false,
    validate: {
      min: 1.0,
      max: 5.0,
    },
  },
  comment: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  images: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: [],
  },
}, {
  tableName: 'reviews',
  timestamps: true,
  underscored: true,
  indexes: [
    {
      fields: ['booking_id'],
    },
    {
      fields: ['client_id'],
    },
    {
      fields: ['service_provider_id'],
    },
    {
      fields: ['rating'],
    },
    {
      fields: ['created_at'],
    },
  ],
});

// Associations
const User = require('../user/user.model');
const Booking = require('../booking/booking.model');

Review.belongsTo(User, { as: 'client', foreignKey: 'clientId' });
Review.belongsTo(User, { as: 'serviceProvider', foreignKey: 'serviceProviderId' });
Review.belongsTo(Booking, { as: 'booking', foreignKey: 'bookingId' });

module.exports = Review; 