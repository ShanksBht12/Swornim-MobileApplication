const Joi = require("joi");
const { UserType } = require("../../config/constants");

const UpdateUserProfileDTO = Joi.object({
  name: Joi.string().min(2).max(255).optional(),
  phone: Joi.string().min(10).max(20).optional(),
  userType: Joi.string()
    .valid(...Object.values(UserType))
    .optional()
    .messages({
      "any.only": "Invalid user type",
    }),
});

const GetUsersDTO = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  userType: Joi.string()
    .valid(...Object.values(UserType))
    .optional(),
  userStatus: Joi.string().optional(),
  search: Joi.string().optional(),
  orderBy: Joi.string()
    .valid("name", "email", "createdAt", "updatedAt")
    .default("createdAt"),
  orderDirection: Joi.string().valid("ASC", "DESC").default("DESC"),
});

module.exports = {
  UpdateUserProfileDTO,
  GetUsersDTO,
};
