const photographerRouter = require("express").Router();
const photographerCtrl = require("./photographer.controller");
const auth = require("../../middlewares/auth.middleware");
const bodyValidator = require("../../middlewares/validator.middleware");
const uploader = require("../../middlewares/uploader.middleware");
const { UserType } = require("../../config/constants");
const {
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
} = require("./photographer.validator");

// Public routes
photographerRouter.get("/search", bodyValidator(SearchPhotographersDTO, "query"), photographerCtrl.searchPhotographers);

photographerRouter.get("/top-rated", photographerCtrl.getTopRatedPhotographers);

photographerRouter.get("/available", photographerCtrl.getAvailablePhotographers);

photographerRouter.get("/:photographerId", photographerCtrl.getPhotographerProfile);

// Protected routes - Photographer only
photographerRouter.post(
  "/profile",
  auth([UserType.PHOTOGRAPHER]),
  uploader.single("profileImage"),
  bodyValidator(CreatePhotographerDTO),
  photographerCtrl.createPhotographer
);

photographerRouter.get(
  "/profile/me",
  auth([UserType.PHOTOGRAPHER]),
  photographerCtrl.getMyPhotographerProfile
);

photographerRouter.put(
  "/profile",
  auth([UserType.PHOTOGRAPHER]),
  uploader.single("profileImage"),
  bodyValidator(UpdatePhotographerDTO),
  photographerCtrl.updatePhotographerProfile
);

photographerRouter.patch(
  "/availability",
  auth([UserType.PHOTOGRAPHER]),
  bodyValidator(UpdateAvailabilityDTO),
  photographerCtrl.updateAvailability
);

photographerRouter.patch(
  "/hourly-rate",
  auth([UserType.PHOTOGRAPHER]),
  bodyValidator(UpdateHourlyRateDTO),
  photographerCtrl.updateHourlyRate
);

photographerRouter.post(
  "/specializations",
  auth([UserType.PHOTOGRAPHER]),
  bodyValidator(AddSpecializationDTO),
  photographerCtrl.addSpecialization
);

photographerRouter.delete(
  "/specializations",
  auth([UserType.PHOTOGRAPHER]),
  bodyValidator(RemoveSpecializationDTO),
  photographerCtrl.removeSpecialization
);

photographerRouter.post(
  "/portfolio/images",
  auth([UserType.PHOTOGRAPHER]),
  uploader.single("portfolioImage"),
  bodyValidator(AddPortfolioImageDTO),
  photographerCtrl.addPortfolioImage
);

photographerRouter.delete(
  "/portfolio/images",
  auth([UserType.PHOTOGRAPHER]),
  bodyValidator(RemovePortfolioImageDTO),
  photographerCtrl.removePortfolioImage
);

photographerRouter.delete(
  "/profile",
  auth([UserType.PHOTOGRAPHER]),
  photographerCtrl.deletePhotographerProfile
);

module.exports = photographerRouter; 