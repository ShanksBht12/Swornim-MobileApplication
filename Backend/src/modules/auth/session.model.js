const { DataTypes } = require("sequelize");
const sequelize = require("../../config/database.config");

const Session = sequelize.define(
  "Session",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "users",
        key: "id",
      },
      field: "user_id",
    },
    accessTokenActual: {
      type: DataTypes.TEXT,
      allowNull: false,
      field: "access_token_actual",
    },
    accessTokenMasked: {
      type: DataTypes.STRING(255),
      allowNull: false,
      field: "access_token_masked",
    },
    refreshTokenActual: {
      type: DataTypes.TEXT,
      allowNull: false,
      field: "refresh_token_actual",
    },
    refreshTokenMasked: {
      type: DataTypes.STRING(255),
      allowNull: false,
      field: "refresh_token_masked",
    },
    userSessionData: {
      type: DataTypes.TEXT,
      allowNull: true,
      field: "user_session_data",
    },
    isActive: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      field: "is_active",
    },
    expiresAt: {
      type: DataTypes.DATE,
      allowNull: false,
      field: "expires_at",
    },
  },
  {
    tableName: "user_sessions",
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ["access_token_masked"],
      },
      {
        unique: true,
        fields: ["refresh_token_masked"],
      },
      {
        fields: ["user_id"],
      },
    ],
  }
);

module.exports = Session;
