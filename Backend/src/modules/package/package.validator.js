const Joi = require('joi');

const CreatePackageDTO = Joi.object({
  serviceProviderId: Joi.string().uuid().required(),
  serviceType: Joi.string().required(),
  name: Joi.string().min(2).max(255).required(),
  description: Joi.string().max(1000).optional(),
  basePrice: Joi.number().positive().required(),
  durationHours: Joi.number().integer().positive().required(),
  features: Joi.array().items(Joi.string()).optional(),
  isActive: Joi.boolean().optional(),
});

const UpdatePackageDTO = Joi.object({
  name: Joi.string().min(2).max(255).optional(),
  description: Joi.string().max(1000).optional(),
  basePrice: Joi.number().positive().optional(),
  durationHours: Joi.number().integer().positive().optional(),
  features: Joi.array().items(Joi.string()).optional(),
  isActive: Joi.boolean().optional(),
});

module.exports = {
  CreatePackageDTO,
  UpdatePackageDTO,
}; 