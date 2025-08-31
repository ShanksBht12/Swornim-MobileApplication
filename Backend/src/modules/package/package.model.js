const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database.config');

const ServicePackage = sequelize.define('ServicePackage', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  serviceProviderId: {
    type: DataTypes.UUID,
    allowNull: false,
    field: 'service_provider_id',
    references: {
      model: 'users',
      key: 'id',
    },
  },
  serviceType: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'service_type',
  },
  name: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  basePrice: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    field: 'base_price',
  },
  durationHours: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'duration_hours',
  },
  features: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: [],
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
    field: 'is_active',
  },
  createdAt: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'created_at',
    defaultValue: DataTypes.NOW,
  },
  updatedAt: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'updated_at',
    defaultValue: DataTypes.NOW,
  },
});

module.exports = ServicePackage; 