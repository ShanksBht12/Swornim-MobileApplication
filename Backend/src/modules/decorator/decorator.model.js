const { DataTypes } = require("sequelize");
const sequelize = require("../../config/database.config");
const { UserStatus } = require("../../config/constants");

const Decorator = sequelize.define(
  "Decorator",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      field: "user_id",
      references: {
        model: "users",
        key: "id",
      },
    },
    businessName: {
      type: DataTypes.STRING(255),
      allowNull: false,
      field: "business_name",
    },
    image: {
      type: DataTypes.STRING(512),
      allowNull: true,
    },
    imagePublicId: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: "image_public_id",
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    specializations: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
    },
    themes: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
    },
    packageStartingPrice: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.0,
      field: "package_starting_price",
    },
    hourlyRate: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.0,
      field: "hourly_rate",
    },
    portfolio: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
    },
    experienceYears: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      field: "experience_years",
    },
    offersFlowerArrangements: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: "offers_flower_arrangements",
    },
    offersLighting: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: "offers_lighting",
    },
    offersRentals: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: "offers_rentals",
    },
    availableItems: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      field: "available_items",
    },
    availableDates: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      field: "available_dates",
    },
    rating: {
      type: DataTypes.DECIMAL(3, 2),
      allowNull: false,
      defaultValue: 0.0,
    },
    totalReviews: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      field: "total_reviews",
    },
    isAvailable: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      field: "is_available",
    },
    location: {
      type: DataTypes.JSON,
      allowNull: true,
    },
    userStatus: {
      type: DataTypes.ENUM(
        UserStatus.PENDING,
        UserStatus.APPROVED,
        UserStatus.ACTIVE,
        UserStatus.SUSPENDED,
        UserStatus.REJECTED,
        UserStatus.INACTIVE
      ),
      allowNull: false,
      defaultValue: UserStatus.PENDING,
      field: "user_status",
    },
    isActive: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      field: "is_active",
    },
  },
  {
    tableName: "decorators",
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ["user_id"],
      },
      {
        fields: ["business_name"],
      },
      {
        fields: ["user_status"],
      },
      {
        fields: ["is_available"],
      },
      {
        fields: ["rating"],
      },
    ],
  }
);

// Instance methods
Decorator.prototype.canAcceptBookings = function () {
  return this.isActive && this.isAvailable && this.userStatus === UserStatus.ACTIVE;
};

Decorator.prototype.updateRating = function (newRating, totalReviews) {
  this.rating = newRating;
  this.totalReviews = totalReviews;
};

Decorator.prototype.addSpecialization = function (specialization) {
  if (!this.specializations.includes(specialization)) {
    this.specializations.push(specialization);
  }
};

Decorator.prototype.removeSpecialization = function (specialization) {
  this.specializations = this.specializations.filter(spec => spec !== specialization);
};

Decorator.prototype.addPortfolioImage = function (imageUrl) {
  console.log('MODEL DEBUG: Adding portfolio image:', imageUrl, 'Current:', this.portfolio);
  if (typeof imageUrl === 'string' && imageUrl && !this.portfolio.includes(imageUrl)) {
    this.portfolio.push(imageUrl);
    this.changed('portfolio', true); // Ensure Sequelize saves the change
  }
};

Decorator.prototype.removePortfolioImage = function (imageUrl) {
  this.portfolio = this.portfolio.filter(img => img !== imageUrl);
};

Decorator.prototype.setLocation = function (locationData) {
  this.location = {
    name: locationData.name,
    latitude: locationData.latitude,
    longitude: locationData.longitude,
    address: locationData.address,
    city: locationData.city,
    state: locationData.state,
    country: locationData.country,
  };
};

module.exports = Decorator; 