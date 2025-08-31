const Joi = require("joi");

const CreatePhotographerDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).required().messages({
    "string.min": "Business name must be at least 2 characters long",
    "string.max": "Business name must not exceed 255 characters",
    "any.required": "Business name is required",
  }),

  description: Joi.string().max(1000).optional().messages({
    "string.max": "Description must not exceed 1000 characters",
  }),

  hourlyRate: Joi.number().positive().required().messages({
    "number.base": "Hourly rate must be a number",
    "number.positive": "Hourly rate must be positive",
    "any.required": "Hourly rate is required",
  }),

  experience: Joi.string().max(50).optional().messages({
    "string.max": "Experience must not exceed 50 characters",
  }),

  specializations: Joi.array().items(Joi.string()).min(1).required().messages({
    "array.min": "At least one specialization is required",
    "any.required": "Specializations are required",
  }),

  location: Joi.object({
    name: Joi.string().required().messages({
      "any.required": "Location name is required",
    }),
    latitude: Joi.number().min(-90).max(90).required().messages({
      "number.base": "Latitude must be a number",
      "number.min": "Latitude must be between -90 and 90",
      "number.max": "Latitude must be between -90 and 90",
      "any.required": "Latitude is required",
    }),
    longitude: Joi.number().min(-180).max(180).required().messages({
      "number.base": "Longitude must be a number",
      "number.min": "Longitude must be between -180 and 180",
      "number.max": "Longitude must be between -180 and 180",
      "any.required": "Longitude is required",
    }),
    address: Joi.string().required().messages({
      "any.required": "Address is required",
    }),
    city: Joi.string().required().messages({
      "any.required": "City is required",
    }),
    state: Joi.string().optional(),
    country: Joi.string().required().messages({
      "any.required": "Country is required",
    }),
  }).required().messages({
    "any.required": "Location is required",
  }),

  profileImage: Joi.any().optional(),
});

const UpdatePhotographerDTO = Joi.object({
  businessName: Joi.string().min(2).max(255).optional().empty(''),
  description: Joi.string().max(1000).optional().empty(''),
  hourlyRate: Joi.number().positive().optional().empty('').messages({
    "number.base": "Hourly rate must be a number",
    "number.positive": "Hourly rate must be positive",
  }),
  experience: Joi.string().max(50).optional().empty(''),
  specializations: Joi.array().items(Joi.string()).optional(),
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
  isAvailable: Joi.boolean().required().messages({
    "any.required": "Availability status is required",
  }),
});

const UpdateHourlyRateDTO = Joi.object({
  hourlyRate: Joi.number().positive().required().messages({
    "number.base": "Hourly rate must be a number",
    "number.positive": "Hourly rate must be positive",
    "any.required": "Hourly rate is required",
  }),
});

const AddSpecializationDTO = Joi.object({
  specialization: Joi.string().min(1).max(100).required().messages({
    "string.min": "Specialization must not be empty",
    "string.max": "Specialization must not exceed 100 characters",
    "any.required": "Specialization is required",
  }),
});

const RemoveSpecializationDTO = Joi.object({
  specialization: Joi.string().min(1).max(100).required().messages({
    "string.min": "Specialization must not be empty",
    "string.max": "Specialization must not exceed 100 characters",
    "any.required": "Specialization is required",
  }),
});

const AddPortfolioImageDTO = Joi.object({
  imageUrl: Joi.string().uri().optional().messages({
    "string.uri": "Please provide a valid image URL",
  }),
}).or('imageUrl').messages({
  'object.missing': 'Either imageUrl or portfolioImage file is required',
}).unknown(true); // Allow unknown fields (e.g., Multer file)

const RemovePortfolioImageDTO = Joi.object({
  imageUrl: Joi.string().uri().required().messages({
    "string.uri": "Please provide a valid image URL",
    "any.required": "Image URL is required",
  }),
});

const SearchPhotographersDTO = Joi.object({
  search: Joi.string().optional(),
  specializations: Joi.array().items(Joi.string()).optional(),
  minRating: Joi.number().min(0).max(5).optional().messages({
    "number.min": "Minimum rating must be at least 0",
    "number.max": "Minimum rating must not exceed 5",
  }),
  maxPrice: Joi.number().positive().optional().messages({
    "number.positive": "Maximum price must be positive",
  }),
  minPrice: Joi.number().positive().optional().messages({
    "number.positive": "Minimum price must be positive",
  }),
  location: Joi.string().optional(),
  isAvailable: Joi.boolean().optional(),
  page: Joi.number().integer().min(1).optional().messages({
    "number.base": "Page must be a number",
    "number.integer": "Page must be an integer",
    "number.min": "Page must be at least 1",
  }),
  limit: Joi.number().integer().min(1).max(100).optional().messages({
    "number.base": "Limit must be a number",
    "number.integer": "Limit must be an integer",
    "number.min": "Limit must be at least 1",
    "number.max": "Limit must not exceed 100",
  }),
  sortBy: Joi.string().valid("rating", "hourlyRate", "createdAt", "businessName").optional().messages({
    "any.only": "Sort by must be one of: rating, hourlyRate, createdAt, businessName",
  }),
  sortOrder: Joi.string().valid("ASC", "DESC").optional().messages({
    "any.only": "Sort order must be ASC or DESC",
  }),
});

const UpdateRatingDTO = Joi.object({
  rating: Joi.number().min(0).max(5).required().messages({
    "number.base": "Rating must be a number",
    "number.min": "Rating must be at least 0",
    "number.max": "Rating must not exceed 5",
    "any.required": "Rating is required",
  }),
  totalReviews: Joi.number().integer().min(0).required().messages({
    "number.base": "Total reviews must be a number",
    "number.integer": "Total reviews must be an integer",
    "number.min": "Total reviews must be at least 0",
    "any.required": "Total reviews is required",
  }),
});

module.exports = {
  CreatePhotographerDTO,
  UpdatePhotographerDTO,
  UpdateAvailabilityDTO,
  UpdateHourlyRateDTO,
  AddSpecializationDTO,
  RemoveSpecializationDTO,
  AddPortfolioImageDTO,
  RemovePortfolioImageDTO,
  SearchPhotographersDTO,
  UpdateRatingDTO,
}; 