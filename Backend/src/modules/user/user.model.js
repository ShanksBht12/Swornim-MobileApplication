const { DataTypes } = require("sequelize");
const sequelize = require("../../config/database.config");
const { UserType, UserStatus } = require("../../config/constants");

const User = sequelize.define(
  "User",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
    },
    phone: {
      type: DataTypes.STRING(20),
      allowNull: false,
    },
    password: {
      type: DataTypes.STRING(255),
      allowNull: false,
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
    userType: {
      type: DataTypes.ENUM(
        UserType.CLIENT,
        UserType.PHOTOGRAPHER,
        UserType.MAKEUP_ARTIST,
        UserType.DECORATOR,
        UserType.VENUE,
        UserType.CATERER,
        UserType.EVENT_ORGANIZER
      ),
      allowNull: false,
      defaultValue: UserType.CLIENT,
      field: "user_type",
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
    isEmailVerified: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: "is_email_verified",
    },
    resetToken: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: "reset_token",
    },
    resetTokenExpiry: {
      type: DataTypes.DATE,
      allowNull: true,
      field: "reset_token_expiry",
    },
    emailVerificationToken: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: "email_verification_token",
    },
    emailVerificationTokenExpiry: {
      type: DataTypes.DATE,
      allowNull: true,
      field: "email_verification_token_expiry",
    },
    lastLoginAt: {
      type: DataTypes.DATE,
      allowNull: true,
      field: "last_login_at",
    },
  },
  {
    tableName: "users",
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ["email"],
      },
      {
        fields: ["user_type"],
      },
      {
        fields: ["user_status"],
      },
    ],
  }
);

// Instance methods
User.prototype.canLogin = function () {
  return this.isActive && this.isEmailVerified;
};

User.prototype.isPasswordResetTokenValid = function () {
  return (
    this.resetToken &&
    this.resetTokenExpiry &&
    this.resetTokenExpiry > new Date()
  );
};

User.prototype.isEmailVerificationTokenValid = function () {
  return (
    this.emailVerificationToken &&
    this.emailVerificationTokenExpiry &&
    this.emailVerificationTokenExpiry > new Date()
  );
};

User.prototype.canAccessServiceProviderFeatures = function () {
  return this.userType !== UserType.CLIENT && this.isActive;
};

User.prototype.getUserRoleDisplayName = function () {
  const roleNames = {
    [UserType.CLIENT]: "Client",
    [UserType.PHOTOGRAPHER]: "Photographer",
    [UserType.MAKEUP_ARTIST]: "Makeup Artist",
    [UserType.DECORATOR]: "Decorator",
    [UserType.VENUE]: "Venue Owner",
    [UserType.CATERER]: "Caterer",
  };
  return roleNames[this.userType] || this.userType;
};

User.prototype.clearPasswordResetToken = function () {
  this.resetToken = null;
  this.resetTokenExpiry = null;
};

User.prototype.clearEmailVerificationToken = function () {
  this.emailVerificationToken = null;
  this.emailVerificationTokenExpiry = null;
};

module.exports = User;
