const Joi = require("joi");

const CreateEventOrganizerDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).required(),
  image: Joi.string().uri().optional().allow(null, ""),
  description: Joi.string().optional().allow(null, ""),
  rating: Joi.number().min(0).max(5).optional(),
  totalReviews: Joi.number().integer().min(0).optional(),
  isAvailable: Joi.boolean().optional(),
  eventTypes: Joi.array().items(Joi.string()).optional(),
  services: Joi.array().items(Joi.string()).optional(),
  packageStartingPrice: Joi.number().min(0).required(),
  hourlyConsultationRate: Joi.number().min(0).required(),
  portfolio: Joi.array().items(Joi.string().uri()).optional(),
  experienceYears: Joi.number().integer().min(0).optional(),
  maxEventSize: Joi.number().integer().min(1).optional(),
  preferredVendors: Joi.array().items(Joi.string()).optional(),
  contactEmail: Joi.string().email().optional().allow(null, ""),
  contactPhone: Joi.string().optional().allow(null, ""),
  offersVendorCoordination: Joi.boolean().optional(),
  offersVenueBooking: Joi.boolean().optional(),
  offersFullPlanning: Joi.boolean().optional(),
  availableDates: Joi.array().items(Joi.string()).optional(),
  location: Joi.object({
    name: Joi.string().optional().allow(null, ""),
    latitude: Joi.number().optional(),
    longitude: Joi.number().optional(),
    address: Joi.string().optional().allow(null, ""),
    city: Joi.string().optional().allow(null, ""),
    state: Joi.string().optional().allow(null, ""),
    country: Joi.string().optional().allow(null, ""),
  }).optional(),
});

const UpdateEventOrganizerDTO = CreateEventOrganizerDTO.fork([
  "businessName",
  "packageStartingPrice",
  "hourlyConsultationRate"
], (schema) => schema.optional());

module.exports = {
  CreateEventOrganizerDTO,
  UpdateEventOrganizerDTO,
}; 