const Joi = require("joi");
const { UserType } = require("../../config/constants");

const RegisterUserDTO = Joi.object({
  name: Joi.string().min(2).max(255).required().messages({
    "string.min": "Name must be at least 2 characters long",
    "string.max": "Name must not exceed 255 characters",
    "any.required": "Name is required",
  }),

  email: Joi.string().email().required().messages({
    "string.email": "Please provide a valid email address",
    "any.required": "Email is required",
  }),

  phone: Joi.string().min(10).max(20).required().messages({
    "string.min": "Phone number must be at least 10 digits",
    "string.max": "Phone number must not exceed 20 digits",
    "any.required": "Phone number is required",
  }),

  password: Joi.string()
    .min(8)
    .pattern(new RegExp("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[\\W_]).{8,}$"))
    .required()
    .messages({
      "string.min": "Password must be at least 8 characters long",
      "string.pattern.base":
        "Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character",
      "any.required": "Password is required",
    }),

  confirmPassword: Joi.string().valid(Joi.ref("password")).required().messages({
    "any.only": "Passwords do not match",
    "any.required": "Confirm password is required",
  }),

  userType: Joi.string()
    .valid(...Object.values(UserType))
    .default(UserType.CLIENT)
    .messages({
      "any.only": "Invalid user type selected",
    }),
});

const LoginUserDTO = Joi.object({
  email: Joi.string().email().required().messages({
    "string.email": "Please provide a valid email address",
    "any.required": "Email is required",
  }),

  password: Joi.string().min(1).required().messages({
    "string.min": "Password is required",
    "any.required": "Password is required",
  }),
});

const ForgotPasswordDTO = Joi.object({
  email: Joi.string().email().required().messages({
    "string.email": "Please provide a valid email address",
    "any.required": "Email is required",
  }),
});

const ResetPasswordDTO = Joi.object({
  token: Joi.string().required().messages({
    "any.required": "Reset token is required",
  }),

  password: Joi.string()
    .min(8)
    .pattern(new RegExp("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[\\W_]).{8,}$"))
    .required()
    .messages({
      "string.min": "Password must be at least 8 characters long",
      "string.pattern.base":
        "Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character",
      "any.required": "Password is required",
    }),

  confirmPassword: Joi.string().valid(Joi.ref("password")).required().messages({
    "any.only": "Passwords do not match",
    "any.required": "Confirm password is required",
  }),
});

const ChangePasswordDTO = Joi.object({
  currentPassword: Joi.string().required().messages({
    "any.required": "Current password is required",
  }),

  newPassword: Joi.string()
    .min(8)
    .pattern(new RegExp("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[\\W_]).{8,}$"))
    .required()
    .messages({
      "string.min": "Password must be at least 8 characters long",
      "string.pattern.base":
        "Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character",
      "any.required": "New password is required",
    }),

  confirmPassword: Joi.string()
    .valid(Joi.ref("newPassword"))
    .required()
    .messages({
      "any.only": "Passwords do not match",
      "any.required": "Confirm password is required",
    }),
});

const RefreshTokenDTO = Joi.object({
  refreshToken: Joi.string().required().messages({
    "any.required": "Refresh token is required",
  }),
});

const VerifyEmailDTO = Joi.object({
  token: Joi.string().required().messages({
    "any.required": "Verification token is required",
  }),
});

module.exports = {
  RegisterUserDTO,
  LoginUserDTO,
  ForgotPasswordDTO,
  ResetPasswordDTO,
  ChangePasswordDTO,
  RefreshTokenDTO,
  VerifyEmailDTO,
};
