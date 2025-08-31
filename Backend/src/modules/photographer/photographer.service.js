const Photographer = require("./photographer.model");
const User = require("../user/user.model");
const { UserStatus } = require("../../config/constants");
const { Op } = require("sequelize");
const cloudinarySvc = require("../../services/cloudinary.service");

class PhotographerService {
  async createPhotographer(data) {
    try {
      console.log('Service createPhotographer debug:', {
        hasProfileImage: !!data.profileImage,
        profileImagePath: data.profileImage?.path,
        profileImageField: data.profileImage?.fieldname
      });
      
      // Handle image upload if present
      if (data.profileImage && data.profileImage.path) {
        console.log('Uploading to Cloudinary...');
        const uploadResult = await cloudinarySvc.fileUpload(data.profileImage.path, "photographers/profiles/");
        console.log('Cloudinary upload result:', uploadResult);
        data.profileImage = uploadResult.url;
        data.profileImagePublicId = uploadResult.publicId;
      }

      const photographer = await Photographer.create(data);
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async getSingleRowByFilter(filter) {
    try {
      const photographer = await Photographer.findOne({
        where: filter,
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
      });
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async getAllRowsByFilter(filter = {}, options = {}) {
    try {
      const {
        page = 1,
        limit = 10,
        sortBy = "createdAt",
        sortOrder = "DESC",
        search = "",
        specializations = [],
        minRating = 0,
        maxPrice = null,
        minPrice = null,
        location = "",
        isAvailable = null,
      } = options;

      const offset = (page - 1) * limit;
      const whereClause = { ...filter };

      // Search functionality
      if (search) {
        whereClause[Op.or] = [
          { businessName: { [Op.iLike]: `%${search}%` } },
          { description: { [Op.iLike]: `%${search}%` } },
        ];
      }

      // Specializations filter
      if (specializations.length > 0) {
        whereClause.specializations = {
          [Op.overlap]: specializations,
        };
      }

      // Rating filter
      if (minRating > 0) {
        whereClause.rating = {
          [Op.gte]: minRating,
        };
      }

      // Price range filter
      if (minPrice !== null || maxPrice !== null) {
        whereClause.hourlyRate = {};
        if (minPrice !== null) {
          whereClause.hourlyRate[Op.gte] = minPrice;
        }
        if (maxPrice !== null) {
          whereClause.hourlyRate[Op.lte] = maxPrice;
        }
      }

      // Location filter
      if (location) {
        whereClause.location = {
          [Op.contains]: { city: location },
        };
      }

      // Availability filter
      if (isAvailable !== null) {
        whereClause.isAvailable = isAvailable;
      }

      const { count, rows } = await Photographer.findAndCountAll({
        where: whereClause,
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
        order: [[sortBy, sortOrder]],
        limit: parseInt(limit),
        offset: parseInt(offset),
      });

      return {
        photographers: rows,
        totalCount: count,
        currentPage: parseInt(page),
        totalPages: Math.ceil(count / limit),
        hasNextPage: page * limit < count,
        hasPrevPage: page > 1,
      };
    } catch (exception) {
      throw exception;
    }
  }

  async updateSingleRowByFilter(updateData, filter) {
    try {
      const [updatedCount] = await Photographer.update(updateData, {
        where: filter,
      });
      return updatedCount;
    } catch (exception) {
      throw exception;
    }
  }

  async deleteSingleRowByFilter(filter) {
    try {
      const deletedCount = await Photographer.destroy({
        where: filter,
      });
      return deletedCount;
    } catch (exception) {
      throw exception;
    }
  }

  async getPhotographerWithUser(photographerId) {
    try {
      console.log('DEBUG: getPhotographerWithUser called with photographerId:', photographerId);
      const photographer = await Photographer.findOne({
        where: { id: photographerId },
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
      });
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async updatePhotographerProfile(photographerId, updateData) {
    try {
      const photographer = await this.getSingleRowByFilter({ id: photographerId });
      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_NOT_FOUND",
          message: "Photographer not found",
        };
      }

      // Handle image upload if present
      if (updateData.profileImage && updateData.profileImage.path) {
        // Delete old image from Cloudinary if exists
        if (photographer.profileImagePublicId) {
          await cloudinarySvc.deleteFile(photographer.profileImagePublicId);
        }
        
        const uploadResult = await cloudinarySvc.fileUpload(updateData.profileImage.path, "photographers/profiles/");
        updateData.profileImage = uploadResult.url;
        updateData.profileImagePublicId = uploadResult.publicId;
      }

      await photographer.update(updateData);
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async updateAvailability(photographerId, isAvailable) {
    try {
      const result = await this.updateSingleRowByFilter(
        { isAvailable },
        { id: photographerId }
      );
      return result > 0;
    } catch (exception) {
      throw exception;
    }
  }

  async updateHourlyRate(photographerId, hourlyRate) {
    try {
      const result = await this.updateSingleRowByFilter(
        { hourlyRate },
        { id: photographerId }
      );
      return result > 0;
    } catch (exception) {
      throw exception;
    }
  }

  async addSpecialization(photographerId, specialization) {
    try {
      const photographer = await this.getSingleRowByFilter({ id: photographerId });
      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_NOT_FOUND",
          message: "Photographer not found",
        };
      }

      photographer.addSpecialization(specialization);
      await photographer.save();
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async removeSpecialization(photographerId, specialization) {
    try {
      const photographer = await this.getSingleRowByFilter({ id: photographerId });
      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_NOT_FOUND",
          message: "Photographer not found",
        };
      }

      photographer.removeSpecialization(specialization);
      await photographer.save();
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async addPortfolioImage(photographerId, imageUrl) {
    try {
      const photographer = await this.getSingleRowByFilter({ id: photographerId });
      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_NOT_FOUND",
          message: "Photographer not found",
        };
      }

      // Handle file upload if it's a file object
      if (imageUrl && imageUrl.path) {
        const uploadResult = await cloudinarySvc.fileUpload(imageUrl.path, "photographers/portfolio/");
        imageUrl = uploadResult.url; // Ensure this is a string
      }

      console.log('SERVICE DEBUG: About to add portfolio image:', imageUrl);
      photographer.addPortfolioImage(imageUrl);
      await photographer.save();
      await photographer.reload(); // Ensure you get the latest data
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async removePortfolioImage(photographerId, imageUrl) {
    try {
      const photographer = await this.getSingleRowByFilter({ id: photographerId });
      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_NOT_FOUND",
          message: "Photographer not found",
        };
      }

      photographer.removePortfolioImage(imageUrl);
      await photographer.save();
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async updateRating(photographerId, newRating, totalReviews) {
    try {
      const photographer = await this.getSingleRowByFilter({ id: photographerId });
      if (!photographer) {
        throw {
          code: 404,
          status: "PHOTOGRAPHER_NOT_FOUND",
          message: "Photographer not found",
        };
      }

      photographer.updateRating(newRating, totalReviews);
      await photographer.save();
      return photographer;
    } catch (exception) {
      throw exception;
    }
  }

  async getTopRatedPhotographers(limit = 10) {
    try {
      const photographers = await Photographer.findAll({
        where: {
          isActive: true,
          userStatus: UserStatus.ACTIVE,
          rating: { [Op.gt]: 0 },
        },
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
        order: [["rating", "DESC"]],
        limit: parseInt(limit),
      });
      return photographers;
    } catch (exception) {
      throw exception;
    }
  }

  async getAvailablePhotographers() {
    try {
      const photographers = await Photographer.findAll({
        where: {
          isActive: true,
          isAvailable: true,
          userStatus: UserStatus.ACTIVE,
        },
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
        order: [["rating", "DESC"]],
      });
      return photographers;
    } catch (exception) {
      throw exception;
    }
  }
}

module.exports = new PhotographerService(); 