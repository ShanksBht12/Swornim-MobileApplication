const userRouter = require("express").Router();
const userCtrl = require("./user.controller");
const auth = require("../../middlewares/auth.middleware");
const bodyValidator = require("../../middlewares/validator.middleware");
const { UpdateUserProfileDTO, GetUsersDTO } = require("./user.validator");
const uploader = require("../../middlewares/uploader.middleware");

// Get dashboard data
userRouter.get("/dashboard", auth(), userCtrl.getDashboardData);

// Get all users (with pagination and filtering)
userRouter.get(
  "/",
  auth(),
  bodyValidator(GetUsersDTO, "query"),
  userCtrl.getAllUsers
);

// Get user by ID
userRouter.get("/:id", auth(), userCtrl.getUserById);

// Update user profile
userRouter.put(
  "/:id",
  auth(),
  uploader.single("profileImage"),
  bodyValidator(UpdateUserProfileDTO),
  userCtrl.updateUser
);

// Delete user
userRouter.delete("/:id", auth(), userCtrl.deleteUser);

module.exports = userRouter;
