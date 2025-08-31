const { DataTypes } = require("sequelize");
const sequelize = require("../../config/database.config");

const EventOrganizer = sequelize.define(
  "EventOrganizer",
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
      type: DataTypes.STRING(500),
      allowNull: true,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    rating: {
      type: DataTypes.FLOAT,
      allowNull: true,
      defaultValue: 0.0,
    },
    totalReviews: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0,
      field: "total_reviews",
    },
    isAvailable: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      field: "is_available",
    },
    eventTypes: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: false,
      defaultValue: [],
      field: "event_types",
    },
    services: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: false,
      defaultValue: [],
    },
    packageStartingPrice: {
      type: DataTypes.FLOAT,
      allowNull: false,
      field: "package_starting_price",
    },
    hourlyConsultationRate: {
      type: DataTypes.FLOAT,
      allowNull: false,
      field: "hourly_consultation_rate",
    },
    portfolio: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: false,
      defaultValue: [],
    },
    experienceYears: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      field: "experience_years",
    },
    maxEventSize: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1000,
      field: "max_event_size",
    },
    preferredVendors: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: false,
      defaultValue: [],
      field: "preferred_vendors",
    },
    contactEmail: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: "contact_email",
    },
    contactPhone: {
      type: DataTypes.STRING(50),
      allowNull: true,
      field: "contact_phone",
    },
    offersVendorCoordination: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      field: "offers_vendor_coordination",
    },
    offersVenueBooking: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      field: "offers_venue_booking",
    },
    offersFullPlanning: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      field: "offers_full_planning",
    },
    availableDates: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      allowNull: false,
      defaultValue: [],
      field: "available_dates",
    },
    location: {
      type: DataTypes.JSON,
      allowNull: true,
    },
  },
  {
    tableName: "event_organizers",
    timestamps: true,
    underscored: true,
  }
);

module.exports = EventOrganizer; 