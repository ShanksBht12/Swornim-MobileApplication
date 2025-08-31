const Joi = require('joi');

const validateReviewData = (data, isUpdate = false) => {
  const schema = Joi.object({
    bookingId: isUpdate ? Joi.string().uuid().optional() : Joi.string().uuid().required().messages({
      "string.base": "Booking ID must be a string",
      "string.guid": "Booking ID must be a valid UUID",
      "any.required": "Booking ID is required",
    }),
    serviceProviderId: isUpdate ? Joi.string().uuid().optional() : Joi.string().uuid().required().messages({
      "string.base": "Service provider ID must be a string",
      "string.guid": "Service provider ID must be a valid UUID",
      "any.required": "Service provider ID is required",
    }),
    rating: Joi.number().min(1).max(5).required().messages({
      "number.base": "Rating must be a number",
      "number.min": "Rating must be at least 1",
      "number.max": "Rating must be at most 5",
      "any.required": "Rating is required",
    }),
    comment: Joi.string().min(10).max(1000).required().messages({
      "string.base": "Comment must be a string",
      "string.min": "Comment must be at least 10 characters long",
      "string.max": "Comment must be at most 1000 characters long",
      "any.required": "Comment is required",
    }),
    images: Joi.array().items(Joi.string().uri()).optional().messages({
      "array.base": "Images must be an array",
      "string.uri": "Image URLs must be valid URIs",
    }),
  });

  return schema.validate(data);
};

module.exports = {
  validateReviewData,
}; 