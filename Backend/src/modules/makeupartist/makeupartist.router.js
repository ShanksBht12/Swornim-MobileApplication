const makeupArtistRouter = require("express").Router();
const makeupArtistCtrl = require("./makeupartist.controller");
const auth = require("../../middlewares/auth.middleware");
const bodyValidator = require("../../middlewares/validator.middleware");
const uploader = require("../../middlewares/uploader.middleware");
const { UserType } = require("../../config/constants");
const {
  CreateMakeupArtistDTO,
  UpdateMakeupArtistDTO,
  UpdateAvailabilityDTO,
  AddPortfolioImageDTO,
  RemovePortfolioImageDTO,
  SearchMakeupArtistsDTO,
} = require("./makeupartist.validator");

// Public routes
makeupArtistRouter.get("/search", bodyValidator(SearchMakeupArtistsDTO, "query"), makeupArtistCtrl.searchMakeupArtists);
makeupArtistRouter.get("/top-rated", makeupArtistCtrl.getTopRatedMakeupArtists);
makeupArtistRouter.get("/available", makeupArtistCtrl.getAvailableMakeupArtists);
makeupArtistRouter.get("/:makeupArtistId", makeupArtistCtrl.getMakeupArtistProfile);

// Protected routes - MakeupArtist only
makeupArtistRouter.post(
  "/profile",
  auth([UserType.MAKEUP_ARTIST]),
  uploader.single("profileImage"),
  bodyValidator(CreateMakeupArtistDTO),
  makeupArtistCtrl.createMakeupArtist
);

makeupArtistRouter.get(
  "/profile/me",
  auth([UserType.MAKEUP_ARTIST]),
  makeupArtistCtrl.getMyMakeupArtistProfile
);

makeupArtistRouter.put(
  "/profile",
  auth([UserType.MAKEUP_ARTIST]),
  uploader.single("profileImage"),
  bodyValidator(UpdateMakeupArtistDTO),
  makeupArtistCtrl.updateMakeupArtistProfile
);

// Portfolio image management
makeupArtistRouter.post(
  "/portfolio/images",
  auth([UserType.MAKEUP_ARTIST]),
  uploader.single("portfolioImage"),
  bodyValidator(AddPortfolioImageDTO),
  makeupArtistCtrl.addPortfolioImage
);

makeupArtistRouter.delete(
  "/portfolio/images",
  auth([UserType.MAKEUP_ARTIST]),
  bodyValidator(RemovePortfolioImageDTO),
  makeupArtistCtrl.removePortfolioImage
);

module.exports = makeupArtistRouter; 