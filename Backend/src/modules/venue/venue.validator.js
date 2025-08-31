const Joi = require("joi");

const CreateVenueDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).required(),
  image: Joi.string().uri().optional(),
  description: Joi.string().max(1000).optional(),
  capacity: Joi.number().integer().min(0).required(),
  pricePerHour: Joi.number().positive().required(),
  amenities: Joi.array().items(Joi.string()).optional(),
  images: Joi.array().items(Joi.string().uri()).optional(),
  venueTypes: Joi.array().items(Joi.string().valid('wedding', 'conference', 'party', 'exhibition', 'other')).min(1).required(),
  location: Joi.object({
    name: Joi.string().required(),
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    address: Joi.string().required(),
    city: Joi.string().required(),
    state: Joi.string().optional(),
    country: Joi.string().required(),
  }).required(),
});

const UpdateVenueDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).optional().empty(''),
  image: Joi.string().uri().optional().empty(''),
  description: Joi.string().max(1000).optional().empty(''),
  capacity: Joi.number().integer().min(0).optional().empty('').messages({
    "number.base": "Capacity must be a number",
    "number.integer": "Capacity must be an integer",
    "number.min": "Capacity must be at least 0",
  }),
  pricePerHour: Joi.number().positive().optional().empty('').messages({
    "number.base": "Price per hour must be a number",
    "number.positive": "Price per hour must be positive",
  }),
  amenities: Joi.array().items(Joi.string()).optional(),
  images: Joi.array().items(Joi.string().uri()).optional(),
  venueTypes: Joi.array().items(Joi.string().valid('wedding', 'conference', 'party', 'exhibition', 'other')).min(1).optional(),
  location: Joi.object({
    name: Joi.string().optional().empty(''),
    latitude: Joi.number().min(-90).max(90).optional().empty('').messages({
      "number.base": "Latitude must be a number",
      "number.min": "Latitude must be between -90 and 90",
      "number.max": "Latitude must be between -90 and 90",
    }),
    longitude: Joi.number().min(-180).max(180).optional().empty('').messages({
      "number.base": "Longitude must be a number",
      "number.min": "Longitude must be between -180 and 180",
      "number.max": "Longitude must be between -180 and 180",
    }),
    address: Joi.string().optional().empty(''),
    city: Joi.string().optional().empty(''),
    state: Joi.string().optional().empty(''),
    country: Joi.string().optional().empty(''),
  }).optional(),
  isAvailable: Joi.boolean().optional(),
});

const SearchVenuesDTO = Joi.object({
  search: Joi.string().optional(),
  amenities: Joi.array().items(Joi.string()).optional(),
  minRating: Joi.number().min(0).max(5).optional(),
  maxPrice: Joi.number().positive().optional(),
  minPrice: Joi.number().positive().optional(),
  location: Joi.string().optional(),
  isAvailable: Joi.boolean().optional(),
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  sortBy: Joi.string().valid("rating", "pricePerHour", "createdAt", "businessName").optional(),
  sortOrder: Joi.string().valid("ASC", "DESC").optional(),
});

const AddPortfolioImageDTO = Joi.object({
  imageUrl: Joi.string().uri().optional(),
}).or('imageUrl').messages({
  'object.missing': 'Either imageUrl or portfolioImage file is required',
}).unknown(true); // Allow unknown fields (e.g., Multer file)

const RemovePortfolioImageDTO = Joi.object({
  imageUrl: Joi.string().uri().required(),
});

module.exports = {
  CreateVenueDTO,
  UpdateVenueDTO,
  SearchVenuesDTO,
  AddPortfolioImageDTO,
  RemovePortfolioImageDTO,
}; 