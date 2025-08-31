const Joi = require('joi');

const EVENT_TYPES = [
  'concert', 'musicFestival', 'dancePerformance', 'comedy_show', 'theater', 'cultural_show',
  'wedding', 'birthday', 'anniversary', 'graduation',
  'corporate', 'conference', 'seminar', 'workshop', 'product_launch',
  'sports_event', 'charity_event', 'exhibition', 'trade_show',
  'festival_celebration', 'religious_ceremony', 'party', 'other'
];

const EVENT_STATUS = ['draft', 'published', 'ongoing', 'completed', 'cancelled'];
const EVENT_VISIBILITY = ['public', 'private', 'inviteOnly'];

const CreateEventDTO = Joi.object({
  title: Joi.string().min(2).max(255).required(),
  description: Joi.string().min(5).max(5000).required(),
  eventType: Joi.string().valid(...EVENT_TYPES).required(),
  status: Joi.string().valid(...EVENT_STATUS).optional(),
  visibility: Joi.string().valid(...EVENT_VISIBILITY).optional(),
  eventDate: Joi.date().iso().required(),
  eventEndDate: Joi.date().iso().optional().allow(null),
  eventTime: Joi.string().optional().allow(null, ''),
  eventEndTime: Joi.string().optional().allow(null, ''),
  location: Joi.object({
    name: Joi.string().optional().allow(null, ''),
    latitude: Joi.number().optional(),
    longitude: Joi.number().optional(),
  }).optional().allow(null),
  venue: Joi.string().optional().allow(null, ''),
  expectedGuests: Joi.number().integer().min(0).optional(),
  ticketPrice: Joi.number().min(0).optional().allow(null),
  isTicketed: Joi.boolean().optional(),
  maxCapacity: Joi.number().integer().min(0).optional().allow(null),
  imageUrl: Joi.string().uri().optional().allow(null, ''),
  gallery: Joi.array().items(Joi.string().uri()).optional(),
  tags: Joi.array().items(Joi.string()).optional(),
  metadata: Joi.object().optional(),
  contactEmail: Joi.string().email().optional(),
  contactPhone: Joi.string().optional(),
});

const UpdateEventDTO = Joi.object({
  title: Joi.string().min(2).max(255).optional(),
  description: Joi.string().min(5).max(5000).optional(),
  eventType: Joi.string().valid(...EVENT_TYPES).optional(),
  status: Joi.string().valid(...EVENT_STATUS).optional(),
  visibility: Joi.string().valid(...EVENT_VISIBILITY).optional(),
  eventDate: Joi.date().iso().optional(),
  eventEndDate: Joi.date().iso().optional().allow(null),
  eventTime: Joi.string().optional().allow(null, ''),
  eventEndTime: Joi.string().optional().allow(null, ''),
  location: Joi.object({
    name: Joi.string().optional().allow(null, ''),
    latitude: Joi.number().optional(),
    longitude: Joi.number().optional(),
  }).optional().allow(null),
  venue: Joi.string().optional().allow(null, ''),
  expectedGuests: Joi.number().integer().min(0).optional(),
  ticketPrice: Joi.number().min(0).optional().allow(null),
  isTicketed: Joi.boolean().optional(),
  maxCapacity: Joi.number().integer().min(0).optional().allow(null),
  imageUrl: Joi.string().uri().optional().allow(null, ''),
  gallery: Joi.array().items(Joi.string().uri()).optional(),
  tags: Joi.array().items(Joi.string()).optional(),
  metadata: Joi.object().optional(),
  contactEmail: Joi.string().email().optional(),
  contactPhone: Joi.string().optional(),
});

module.exports = {
  CreateEventDTO,
  UpdateEventDTO,
}; 