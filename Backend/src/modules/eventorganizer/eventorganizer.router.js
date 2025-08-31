const express = require("express");
const auth = require("../../middlewares/auth.middleware");
const bodyValidator = require("../../middlewares/validator.middleware");
const { UserType } = require("../../config/constants");
const eventOrganizerCtrl = require("./eventorganizer.controller");
const { CreateEventOrganizerDTO, UpdateEventOrganizerDTO } = require("./eventorganizer.validator");
const uploader = require("../../middlewares/uploader.middleware");

const router = express.Router();

// Create profile
router.post(
  "/profile",
  auth([UserType.EVENT_ORGANIZER]),
  uploader.single("profileImage"),
  bodyValidator(CreateEventOrganizerDTO),
  eventOrganizerCtrl.createProfile
);

// Get profile (by user)
router.get(
  "/profile/me",
  auth([UserType.EVENT_ORGANIZER]),
  eventOrganizerCtrl.getProfile
);

// Get profile (legacy or direct)
router.get(
  "/profile",
  auth([UserType.EVENT_ORGANIZER]),
  eventOrganizerCtrl.getProfile
);

// Update profile
router.put(
  "/profile",
  auth([UserType.EVENT_ORGANIZER]),
  uploader.single("profileImage"),
  bodyValidator(UpdateEventOrganizerDTO),
  eventOrganizerCtrl.updateProfile
);

// Delete profile
router.delete(
  "/profile",
  auth([UserType.EVENT_ORGANIZER]),
  eventOrganizerCtrl.deleteProfile
);

router.post(
  "/portfolio/images",
  auth([UserType.EVENT_ORGANIZER]),
  uploader.single("portfolioImage"),
  eventOrganizerCtrl.addPortfolioImage
);

module.exports = router; 