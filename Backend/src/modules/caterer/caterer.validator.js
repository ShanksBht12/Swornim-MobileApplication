const Joi = require("joi");

const CreateCatererDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).required(),
  image: Joi.string().uri().optional(),
  description: Joi.string().max(1000).optional(),
  cuisineTypes: Joi.array().items(Joi.string()).min(1).required(),
  serviceTypes: Joi.array().items(Joi.string()).min(1).required(),
  pricePerPerson: Joi.number().positive().required(),
  minGuests: Joi.number().integer().min(1).optional(),
  maxGuests: Joi.number().integer().min(1).optional(),
  menuItems: Joi.array().items(Joi.string()).optional(),
  dietaryOptions: Joi.array().items(Joi.string()).optional(),
  offersEquipment: Joi.boolean().optional(),
  offersWaiters: Joi.boolean().optional(),
  availableDates: Joi.array().items(Joi.string()).optional(),
  experienceYears: Joi.number().integer().min(0).optional(),
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

const UpdateCatererDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).optional().empty(''),
  image: Joi.string().uri().optional().empty(''),
  description: Joi.string().max(1000).optional().empty(''),
  cuisineTypes: Joi.array().items(Joi.string()).optional(),
  serviceTypes: Joi.array().items(Joi.string()).optional(),
  pricePerPerson: Joi.number().positive().optional().empty('').messages({
    "number.base": "Price per person must be a number",
    "number.positive": "Price per person must be positive",
  }),
  minGuests: Joi.number().integer().min(1).optional().empty('').messages({
    "number.base": "Min guests must be a number",
    "number.integer": "Min guests must be an integer",
    "number.min": "Min guests must be at least 1",
  }),
  maxGuests: Joi.number().integer().min(1).optional().empty('').messages({
    "number.base": "Max guests must be a number",
    "number.integer": "Max guests must be an integer",
    "number.min": "Max guests must be at least 1",
  }),
  menuItems: Joi.array().items(Joi.string()).optional(),
  dietaryOptions: Joi.array().items(Joi.string()).optional(),
  offersEquipment: Joi.boolean().optional(),
  offersWaiters: Joi.boolean().optional(),
  availableDates: Joi.array().items(Joi.string()).optional(),
  experienceYears: Joi.alternatives().try(
    Joi.number().integer().min(0),
    Joi.string().pattern(/^\d+(\.\d+)?$/).custom((value, helpers) => {
      const num = parseInt(value);
      if (isNaN(num) || num < 0) {
        return helpers.error('any.invalid');
      }
      return num;
    })
  ).optional().empty('').messages({
    "number.base": "Experience years must be a number",
    "number.integer": "Experience years must be an integer",
    "number.min": "Experience years must be at least 0",
    "any.invalid": "Experience years must be a valid number",
  }),
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

const SearchCaterersDTO = Joi.object({
  search: Joi.string().optional(),
  cuisineTypes: Joi.array().items(Joi.string()).optional(),
  minRating: Joi.number().min(0).max(5).optional(),
  maxPrice: Joi.number().positive().optional(),
  minPrice: Joi.number().positive().optional(),
  location: Joi.string().optional(),
  isAvailable: Joi.boolean().optional(),
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  sortBy: Joi.string().valid("rating", "pricePerPerson", "createdAt", "businessName").optional(),
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
  CreateCatererDTO,
  UpdateCatererDTO,
  SearchCaterersDTO,
  AddPortfolioImageDTO,
  RemovePortfolioImageDTO,
}; 