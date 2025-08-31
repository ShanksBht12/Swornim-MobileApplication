const Joi = require("joi");

const CreateMakeupArtistDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).required(),
  description: Joi.string().max(1000).optional(),
  specializations: Joi.array().items(Joi.string()).min(1).required(),
  brands: Joi.array().items(Joi.string()).optional(),
  sessionRate: Joi.number().positive().required(),
  bridalPackageRate: Joi.number().positive().required(),
  portfolio: Joi.array().items(Joi.string().uri()).optional(),
  experienceYears: Joi.number().integer().min(0).optional(),
  offersHairServices: Joi.boolean().optional(),
  travelsToClient: Joi.boolean().optional(),
  availableDates: Joi.array().items(Joi.string()).optional(),
  location: Joi.object({
    name: Joi.string().required(),
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    address: Joi.string().required(),
    city: Joi.string().required(),
    state: Joi.string().optional(),
    country: Joi.string().required(),
  }).required(),
  profileImage: Joi.any().optional(),
});

const UpdateMakeupArtistDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).optional().empty(''),
  description: Joi.string().max(1000).optional().empty(''),
  specializations: Joi.array().items(Joi.string()).optional(),
  brands: Joi.array().items(Joi.string()).optional(),
  sessionRate: Joi.number().positive().optional().empty('').messages({
    "number.base": "Session rate must be a number",
    "number.positive": "Session rate must be positive",
  }),
  bridalPackageRate: Joi.number().positive().optional().empty('').messages({
    "number.base": "Bridal package rate must be a number",
    "number.positive": "Bridal package rate must be positive",
  }),
  portfolio: Joi.array().items(Joi.string().uri()).optional(),
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
  offersHairServices: Joi.boolean().optional(),
  travelsToClient: Joi.boolean().optional(),
  availableDates: Joi.array().items(Joi.string()).optional(),
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
  profileImage: Joi.any().optional(),
});

const UpdateAvailabilityDTO = Joi.object({
  isAvailable: Joi.boolean().required(),
});

const AddPortfolioImageDTO = Joi.object({
  imageUrl: Joi.string().uri().optional(),
}).or('imageUrl').messages({
  'object.missing': 'Either imageUrl or portfolioImage file is required',
}).unknown(true); // Allow unknown fields (e.g., Multer file)

const RemovePortfolioImageDTO = Joi.object({
  imageUrl: Joi.string().uri().required(),
});

const SearchMakeupArtistsDTO = Joi.object({
  search: Joi.string().optional(),
  specializations: Joi.array().items(Joi.string()).optional(),
  minRating: Joi.number().min(0).max(5).optional(),
  maxPrice: Joi.number().positive().optional(),
  minPrice: Joi.number().positive().optional(),
  location: Joi.string().optional(),
  isAvailable: Joi.boolean().optional(),
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  sortBy: Joi.string().valid("rating", "sessionRate", "createdAt", "businessName").optional(),
  sortOrder: Joi.string().valid("ASC", "DESC").optional(),
});

module.exports = {
  CreateMakeupArtistDTO,
  UpdateMakeupArtistDTO,
  UpdateAvailabilityDTO,
  AddPortfolioImageDTO,
  RemovePortfolioImageDTO,
  SearchMakeupArtistsDTO,
}; 