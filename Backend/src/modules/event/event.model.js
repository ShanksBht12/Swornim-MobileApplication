const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database.config');

const EVENT_TYPES = [
  'concert', 'musicFestival', 'dancePerformance', 'comedy_show', 'theater', 'cultural_show',
  'wedding', 'birthday', 'anniversary', 'graduation',
  'corporate', 'conference', 'seminar', 'workshop', 'product_launch',
  'sports_event', 'charity_event', 'exhibition', 'trade_show',
  'festival_celebration', 'religious_ceremony', 'party', 'other'
];

const EVENT_STATUS = ['draft', 'published', 'ongoing', 'completed', 'cancelled'];
const EVENT_VISIBILITY = ['public', 'private', 'inviteOnly'];

const Event = sequelize.define('Event', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  organizerId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'users', key: 'id' },
    field: 'organizer_id',
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  eventType: {
    type: DataTypes.ENUM(...EVENT_TYPES),
    allowNull: false,
    field: 'event_type',
  },
  status: {
    type: DataTypes.ENUM(...EVENT_STATUS),
    allowNull: false,
    defaultValue: 'draft',
  },
  visibility: {
    type: DataTypes.ENUM(...EVENT_VISIBILITY),
    allowNull: false,
    defaultValue: 'private',
  },
  eventDate: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'event_date',
  },
  eventEndDate: {
    type: DataTypes.DATE,
    field: 'event_end_date',
  },
  eventTime: {
    type: DataTypes.STRING(10),
    field: 'event_time',
  },
  eventEndTime: {
    type: DataTypes.STRING(10),
    field: 'event_end_time',
  },
  location: {
    type: DataTypes.JSONB,
    allowNull: true,
  },
  venue: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  expectedGuests: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'expected_guests',
  },
  ticketPrice: {
    type: DataTypes.DECIMAL(10,2),
    field: 'ticket_price',
  },
  isTicketed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    field: 'is_ticketed',
  },
  maxCapacity: {
    type: DataTypes.INTEGER,
    field: 'max_capacity',
  },
  imageUrl: {
    type: DataTypes.STRING(500),
    field: 'image_url',
  },
  gallery: {
    type: DataTypes.ARRAY(DataTypes.STRING),
    defaultValue: [],
  },
  tags: {
    type: DataTypes.ARRAY(DataTypes.STRING),
    defaultValue: [],
  },
  metadata: {
    type: DataTypes.JSONB,
    defaultValue: {},
  },
  contactEmail: {
    type: DataTypes.STRING(255),
    field: 'contact_email',
    allowNull: true,
  },
  contactPhone: {
    type: DataTypes.STRING(32),
    field: 'contact_phone',
    allowNull: true,
  },
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
    field: 'created_at',
  },
  updatedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
    field: 'updated_at',
  },
}, {
  tableName: 'events',
  underscored: true,
});

module.exports = Event; 