const catererRouter = require("express").Router();
const catererCtrl = require("./caterer.controller");
const auth = require("../../middlewares/auth.middleware");
const bodyValidator = require("../../middlewares/validator.middleware");
const uploader = require("../../middlewares/uploader.middleware");
const { UserType } = require("../../config/constants");
const {
  CreateCatererDTO,
  UpdateCatererDTO,
  SearchCaterersDTO,
  AddPortfolioImageDTO,
  RemovePortfolioImageDTO,
} = require("./caterer.validator");

// Public routes
catererRouter.get("/search", bodyValidator(SearchCaterersDTO, "query"), catererCtrl.searchCaterers);
catererRouter.get("/top-rated", catererCtrl.getTopRatedCaterers);
catererRouter.get("/available", catererCtrl.getAvailableCaterers);
catererRouter.get("/:catererId", catererCtrl.getCatererProfile);

// Protected routes - Caterer only
catererRouter.post(
  "/profile",
  auth([UserType.CATERER]),
  uploader.single("profileImage"),
  bodyValidator(CreateCatererDTO),
  catererCtrl.createCaterer
);

catererRouter.get(
  "/profile/me",
  auth([UserType.CATERER]),
  catererCtrl.getMyCatererProfile
);

catererRouter.put(
  "/profile",
  auth([UserType.CATERER]),
  uploader.single("profileImage"),
  bodyValidator(UpdateCatererDTO),
  catererCtrl.updateCatererProfile
);

// Portfolio image management
catererRouter.post(
  "/portfolio/images",
  auth([UserType.CATERER]),
  uploader.single("portfolioImage"),
  bodyValidator(AddPortfolioImageDTO),
  catererCtrl.addPortfolioImage
);

catererRouter.delete(
  "/portfolio/images",
  auth([UserType.CATERER]),
  bodyValidator(RemovePortfolioImageDTO),
  catererCtrl.removePortfolioImage
);

module.exports = catererRouter; 