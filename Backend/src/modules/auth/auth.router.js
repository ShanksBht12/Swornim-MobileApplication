const authRouter = require("express").Router();
const authCtrl = require("./auth.controller");
const auth = require("../../middlewares/auth.middleware");
const bodyValidator = require("../../middlewares/validator.middleware");
const uploader = require("../../middlewares/uploader.middleware");
const {
  RegisterUserDTO,
  LoginUserDTO,
  ForgotPasswordDTO,
  ResetPasswordDTO,
  ChangePasswordDTO,
  RefreshTokenDTO,
  VerifyEmailDTO,
} = require("./auth.validator");

// Public routes
authRouter.post(
  "/register",
  uploader.single("profileImage"),
  bodyValidator(RegisterUserDTO),
  authCtrl.registerUser
);

authRouter.post("/login", bodyValidator(LoginUserDTO), authCtrl.loginUser);

authRouter.post(
  "/refresh-token",
  bodyValidator(RefreshTokenDTO),
  authCtrl.refreshToken
);

authRouter.post(
  "/forgot-password",
  bodyValidator(ForgotPasswordDTO),
  authCtrl.forgotPassword
);

authRouter.post(
  "/reset-password",
  bodyValidator(ResetPasswordDTO),
  authCtrl.resetPassword
);

// Email verification routes
// GET route for clicking the link in email (no validation middleware needed)
authRouter.get("/verify-email", authCtrl.verifyEmail);

// POST route for API calls
authRouter.post(
  "/verify-email",
  bodyValidator(VerifyEmailDTO),
  authCtrl.verifyEmail
);

authRouter.post(
  "/resend-verification",
  bodyValidator(ForgotPasswordDTO), // Reusing for email validation
  authCtrl.resendVerificationEmail
);

// Protected routes
authRouter.get("/profile", auth(), authCtrl.getProfile);

authRouter.post("/logout", auth(), authCtrl.logoutUser);

authRouter.post("/logout-all", auth(), authCtrl.logoutAllSessions);

authRouter.post(
  "/change-password",
  auth(),
  bodyValidator(ChangePasswordDTO),
  authCtrl.changePassword
);

module.exports = authRouter;