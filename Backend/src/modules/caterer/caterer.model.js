const { DataTypes } = require("sequelize");
const sequelize = require("../../config/database.config");
const { UserStatus } = require("../../config/constants");

const Caterer = sequelize.define(
  "Caterer",
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
    cuisineTypes: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      field: "cuisine_types",
    },
    serviceTypes: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      field: "service_types",
    },
    pricePerPerson: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.0,
      field: "price_per_person",
    },
    minGuests: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 10,
      field: "min_guests",
    },
    maxGuests: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 500,
      field: "max_guests",
    },
    menuItems: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      field: "menu_items",
    },
    dietaryOptions: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      field: "dietary_options",
    },
    offersEquipment: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: "offers_equipment",
    },
    offersWaiters: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: "offers_waiters",
    },
    availableDates: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      field: "available_dates",
    },
    experienceYears: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      field: "experience_years",
    },
    portfolio: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
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
    tableName: "caterers",
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
Caterer.prototype.canAcceptBookings = function () {
  return this.isActive && this.isAvailable && this.userStatus === UserStatus.ACTIVE;
};

Caterer.prototype.updateRating = function (newRating, totalReviews) {
  this.rating = newRating;
  this.totalReviews = totalReviews;
};

Caterer.prototype.addSpecialization = function (specialization) {
  if (!this.cuisineTypes.includes(specialization)) {
    this.cuisineTypes.push(specialization);
  }
};

Caterer.prototype.removeSpecialization = function (specialization) {
  this.cuisineTypes = this.cuisineTypes.filter(spec => spec !== specialization);
};

Caterer.prototype.addPortfolioImage = function (imageUrl) {
  console.log('MODEL DEBUG: Adding portfolio image:', imageUrl, 'Current:', this.portfolio);
  if (typeof imageUrl === 'string' && imageUrl && !this.portfolio.includes(imageUrl)) {
    this.portfolio.push(imageUrl);
    this.changed('portfolio', true); // Ensure Sequelize saves the change
  }
};

Caterer.prototype.removePortfolioImage = function (imageUrl) {
  this.portfolio = this.portfolio.filter(img => img !== imageUrl);
};

Caterer.prototype.setLocation = function (locationData) {
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

module.exports = Caterer; 