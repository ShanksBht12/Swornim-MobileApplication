const { DataTypes } = require("sequelize");
const sequelize = require("../../config/database.config");
const { UserType, UserStatus } = require("../../config/constants");

const Photographer = sequelize.define(
  "Photographer",
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
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    hourlyRate: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.0,
      field: "hourly_rate",
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
    experience: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },
    specializations: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
    },
    portfolioImages: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
      field: "portfolio_images",
    },
    profileImage: {
      type: DataTypes.STRING(500),
      allowNull: true,
      field: "profile_image",
    },
    profileImagePublicId: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: "profile_image_public_id",
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
    tableName: "photographers",
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
Photographer.prototype.canAcceptBookings = function () {
  return this.isActive && this.isAvailable && this.userStatus === UserStatus.ACTIVE;
};

Photographer.prototype.updateRating = function (newRating, totalReviews) {
  this.rating = newRating;
  this.totalReviews = totalReviews;
};

Photographer.prototype.addSpecialization = function (specialization) {
  if (!this.specializations.includes(specialization)) {
    this.specializations.push(specialization);
  }
};

Photographer.prototype.removeSpecialization = function (specialization) {
  this.specializations = this.specializations.filter(spec => spec !== specialization);
};

Photographer.prototype.addPortfolioImage = function (imageUrl) {
  console.log('MODEL DEBUG: Adding portfolio image:', imageUrl, 'Current:', this.portfolioImages);
  if (typeof imageUrl === 'string' && imageUrl && !this.portfolioImages.includes(imageUrl)) {
    this.portfolioImages.push(imageUrl);
    this.changed('portfolioImages', true); // Ensure Sequelize saves the change
  }
};

Photographer.prototype.removePortfolioImage = function (imageUrl) {
  this.portfolioImages = this.portfolioImages.filter(img => img !== imageUrl);
};

Photographer.prototype.setLocation = function (locationData) {
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

module.exports = Photographer; 