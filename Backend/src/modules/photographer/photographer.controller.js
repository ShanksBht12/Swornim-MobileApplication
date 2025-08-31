const photographerSvc = require("./photographer.service");
const userSvc = require("../user/user.service");
const { deleteFile, safeUserData } = require("../../utilities/helpers");
const { UserType } = require("../../config/constants");
const { updateServiceProviderProfile } = require("../serviceProviderProfile.service");

class PhotographerController {
  async createPhotographer(req, res, next) {
    try {
      // Check if user already has a photographer profile
      const existingPhotographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });
      if (existingPhotographer) {
        // Delete uploaded file if photographer profile already exists
        if (req.file) {
          deleteFile(req.file.path);
        }
        throw {
          code: 409,
          status: "PHOTOGRAPHER_PROFILE_EXISTS",
          message: "Photographer profile already exists for this user",
        };
      }

      // Check if user is a photographer
      if (req.loggedInUser.userType !== UserType.PHOTOGRAPHER) {
        // Delete uploaded file if user type is invalid
        if (req.file) {
          deleteFile(req.file.path);
        }
        throw {
          code: 403,
          status: "INVALID_USER_TYPE",
          message: "Only photographers can create photographer profiles",
        };
      }

      // Transform photographer data
      const photographerData = {
        ...req.body,
        userId: req.loggedInUser.id,
      };

      // Handle profile image upload
      console.log('File upload debug:', {
        hasFile: !!req.file,
        fileInfo: req.file ? {
          fieldname: req.file.fieldname,
          originalname: req.file.originalname,
          mimetype: req.file.mimetype,
          size: req.file.size,
          path: req.file.path
        } : null
      });
      
      if (req.file) {
        photographerData.profileImage = req.file;
      }

      // Create photographer profile
      const photographer = await photographerSvc.createPhotographer(photographerData);

      // Get photographer with user data
      const photographerWithUser = await photographerSvc.getPhotographerWithUser(photographer.id);

      res.status(201).json({
        data: photographerWithUser,
        message: "Photographer profile created successfully",
        status: "CREATED",
        options: null,
      });
    } catch (exception) {
      // Clean up uploaded file on error
      if (req.file) {
        deleteFile(req.file.path);
      }
      next(exception);
    }
  }

  async getPhotographerProfile(req, res, next) {
    try {
      const { photographerId } = req.params;
      console.log('DEBUG: photographerId param received:', photographerId); // <--- Added logging

      const photographer = await photographerSvc.getPhotographerWithUser(photographerId);
      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_NOT_FOUND",
          message: "Photographer not found",
        };
      }

      res.json({
        data: photographer,
        message: "Photographer profile retrieved successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async getMyPhotographerProfile(req, res, next) {
    try {
      const photographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });
      console.log(photographer);
      console.log(req.loggedInUser.id);
      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_PROFILE_NOT_FOUND",
          message: "Photographer profile not found",
        };
      }

      const photographerWithUser = await photographerSvc.getPhotographerWithUser(photographer.id);

      res.json({
        data: photographerWithUser,
        message: "Photographer profile retrieved successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async updatePhotographerProfile(req, res, next) {
    try {
      const updated = await updateServiceProviderProfile({
        model: require("./photographer.model"),
        profileFieldNames: { image: 'profileImage', publicId: 'profileImagePublicId' },
        cloudinaryDir: "photographers/profiles/",
        getWithUser: require("./photographer.service").getPhotographerWithUser,
        userId: req.loggedInUser.id,
        updateData: req.body,
        file: req.file,
      });
      res.json({
        data: updated,
        message: "Photographer profile updated successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      if (req.file) deleteFile(req.file.path);
      next(exception);
    }
  }

  async searchPhotographers(req, res, next) {
    try {
      const searchOptions = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 10,
        search: req.query.search || "",
        specializations: req.query.specializations ? req.query.specializations.split(",") : [],
        minRating: parseFloat(req.query.minRating) || 0,
        maxPrice: req.query.maxPrice ? parseFloat(req.query.maxPrice) : null,
        minPrice: req.query.minPrice ? parseFloat(req.query.minPrice) : null,
        location: req.query.location || "",
        isAvailable: req.query.isAvailable !== undefined ? req.query.isAvailable === "true" : null,
        sortBy: req.query.sortBy || "rating",
        sortOrder: req.query.sortOrder || "DESC",
      };

      const result = await photographerSvc.getAllRowsByFilter({}, searchOptions);

      res.json({
        data: result,
        message: "Photographers retrieved successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async getTopRatedPhotographers(req, res, next) {
    try {
      const limit = parseInt(req.query.limit) || 10;
      const photographers = await photographerSvc.getTopRatedPhotographers(limit);

      res.json({
        data: photographers,
        message: "Top rated photographers retrieved successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async getAvailablePhotographers(req, res, next) {
    try {
      const photographers = await photographerSvc.getAvailablePhotographers();

      res.json({
        data: photographers,
        message: "Available photographers retrieved successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async updateAvailability(req, res, next) {
    try {
      const photographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });

      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_PROFILE_NOT_FOUND",
          message: "Photographer profile not found",
        };
      }

      const success = await photographerSvc.updateAvailability(photographer.id, req.body.isAvailable);

      if (!success) {
        throw {
          code: 500,
          status: "UPDATE_FAILED",
          message: "Failed to update availability",
        };
      }

      const updatedPhotographer = await photographerSvc.getPhotographerWithUser(photographer.id);

      res.json({
        data: updatedPhotographer,
        message: "Availability updated successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async updateHourlyRate(req, res, next) {
    try {
      const photographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });

      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_PROFILE_NOT_FOUND",
          message: "Photographer profile not found",
        };
      }

      const success = await photographerSvc.updateHourlyRate(photographer.id, req.body.hourlyRate);

      if (!success) {
        throw {
          code: 500,
          status: "UPDATE_FAILED",
          message: "Failed to update hourly rate",
        };
      }

      const updatedPhotographer = await photographerSvc.getPhotographerWithUser(photographer.id);

      res.json({
        data: updatedPhotographer,
        message: "Hourly rate updated successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async addSpecialization(req, res, next) {
    try {
      const photographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });

      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_PROFILE_NOT_FOUND",
          message: "Photographer profile not found",
        };
      }

      const updatedPhotographer = await photographerSvc.addSpecialization(
        photographer.id,
        req.body.specialization
      );

      const photographerWithUser = await photographerSvc.getPhotographerWithUser(updatedPhotographer.id);

      res.json({
        data: photographerWithUser,
        message: "Specialization added successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async removeSpecialization(req, res, next) {
    try {
      const photographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });

      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_PROFILE_NOT_FOUND",
          message: "Photographer profile not found",
        };
      }

      const updatedPhotographer = await photographerSvc.removeSpecialization(
        photographer.id,
        req.body.specialization
      );

      const photographerWithUser = await photographerSvc.getPhotographerWithUser(updatedPhotographer.id);

      res.json({
        data: photographerWithUser,
        message: "Specialization removed successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async addPortfolioImage(req, res, next) {
    try {
      console.log('DEBUG: req.loggedInUser:', req.loggedInUser);
      const photographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });
      console.log('DEBUG: photographer found:', photographer);
      console.log('DEBUG: req.file:', req.file);
      console.log('DEBUG: req.body:', req.body);

      if (!photographer) {
        // Delete uploaded file if photographer profile not found
        if (req.file) {
          deleteFile(req.file.path);
        }
        throw {
          code: 404,
          status: "PHOTOGRAPHER_PROFILE_NOT_FOUND",
          message: "Photographer profile not found",
        };
      }

      // Handle portfolio image upload
      const imageData = req.file || req.body.imageUrl;

      const updatedPhotographer = await photographerSvc.addPortfolioImage(
        photographer.id,
        imageData
      );

      const photographerWithUser = await photographerSvc.getPhotographerWithUser(updatedPhotographer.id);

      res.json({
        data: photographerWithUser,
        message: "Portfolio image added successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      // Clean up uploaded file on error
      if (req.file) {
        deleteFile(req.file.path);
      }
      next(exception);
    }
  }

  async removePortfolioImage(req, res, next) {
    try {
      const photographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });

      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_PROFILE_NOT_FOUND",
          message: "Photographer profile not found",
        };
      }

      const updatedPhotographer = await photographerSvc.removePortfolioImage(
        photographer.id,
        req.body.imageUrl
      );

      const photographerWithUser = await photographerSvc.getPhotographerWithUser(updatedPhotographer.id);

      res.json({
        data: photographerWithUser,
        message: "Portfolio image removed successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async deletePhotographerProfile(req, res, next) {
    try {
      const photographer = await photographerSvc.getSingleRowByFilter({
        userId: req.loggedInUser.id,
      });
      console.log(photographer);

      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_PROFILE_NOT_FOUND",
          message: "Photographer profile not found",
        };
      }

      const deletedCount = await photographerSvc.deleteSingleRowByFilter({ id: photographer.id });

      if (deletedCount === 0) {
        throw {
          code: 500,
          status: "DELETE_FAILED",
          message: "Failed to delete photographer profile",
        };
      }

      res.json({
        data: null,
        message: "Photographer profile deleted successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }
}

module.exports = new PhotographerController(); 