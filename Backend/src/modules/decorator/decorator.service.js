const Decorator = require("./decorator.model");
const User = require("../user/user.model");
const { UserStatus } = require("../../config/constants");
const { Op } = require("sequelize");
const cloudinarySvc = require("../../services/cloudinary.service");

class DecoratorService {
  async createDecorator(data) {
    try {
      if (data.profileImage && data.profileImage.path) {
        const uploadResult = await cloudinarySvc.fileUpload(data.profileImage.path, "decorators/profiles/");
        data.profileImage = uploadResult.url;
        data.profileImagePublicId = uploadResult.publicId;
      }
      const decorator = await Decorator.create(data);
      return decorator;
    } catch (exception) {
      throw exception;
    }
  }

  async getSingleRowByFilter(filter) {
    try {
      const decorator = await Decorator.findOne({
        where: filter,
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
      });
      return decorator;
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

      if (search) {
        whereClause[Op.or] = [
          { businessName: { [Op.iLike]: `%${search}%` } },
          { description: { [Op.iLike]: `%${search}%` } },
        ];
      }

      if (specializations.length > 0) {
        whereClause.specializations = {
          [Op.overlap]: specializations,
        };
      }

      if (minRating > 0) {
        whereClause.rating = {
          [Op.gte]: minRating,
        };
      }

      if (minPrice !== null || maxPrice !== null) {
        whereClause.packageStartingPrice = {};
        if (minPrice !== null) {
          whereClause.packageStartingPrice[Op.gte] = minPrice;
        }
        if (maxPrice !== null) {
          whereClause.packageStartingPrice[Op.lte] = maxPrice;
        }
      }

      if (location) {
        whereClause.location = {
          [Op.contains]: { city: location },
        };
      }

      if (isAvailable !== null) {
        whereClause.isAvailable = isAvailable;
      }

      const { count, rows } = await Decorator.findAndCountAll({
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
        decorators: rows,
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
      const [updatedCount] = await Decorator.update(updateData, {
        where: filter,
      });
      return updatedCount;
    } catch (exception) {
      throw exception;
    }
  }

  async deleteSingleRowByFilter(filter) {
    try {
      const deletedCount = await Decorator.destroy({
        where: filter,
      });
      return deletedCount;
    } catch (exception) {
      throw exception;
    }
  }

  async getDecoratorWithUser(decoratorId) {
    try {
      const decorator = await Decorator.findOne({
        where: { id: decoratorId },
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
      });
      return decorator;
    } catch (exception) {
      throw exception;
    }
  }

  async updateDecoratorProfile(decoratorId, updateData) {
    try {
      const decorator = await this.getSingleRowByFilter({ id: decoratorId });
      if (!decorator) {
        throw {
          code: 404,
          status: "DECORATOR_NOT_FOUND",
          message: "Decorator not found",
        };
      }
      if (updateData.image && updateData.image.path) {
        if (decorator.imagePublicId) {
          await cloudinarySvc.deleteFile(decorator.imagePublicId);
        }
        const uploadResult = await cloudinarySvc.fileUpload(updateData.image.path, "decorators/profiles/");
        updateData.image = uploadResult.url;
        updateData.imagePublicId = uploadResult.publicId;
      }
      await decorator.update(updateData);
      return decorator;
    } catch (exception) {
      throw exception;
    }
  }

  async getTopRatedDecorators(limit = 10) {
    try {
      const decorators = await Decorator.findAll({
        where: { userStatus: UserStatus.ACTIVE },
        order: [["rating", "DESC"]],
        limit,
      });
      return decorators;
    } catch (exception) {
      throw exception;
    }
  }

  async getAvailableDecorators() {
    try {
      const decorators = await Decorator.findAll({
        where: { isAvailable: true, userStatus: UserStatus.ACTIVE },
      });
      return decorators;
    } catch (exception) {
      throw exception;
    }
  }

  async addPortfolioImage(decoratorId, file) {
    try {
      const decorator = await this.getSingleRowByFilter({ id: decoratorId });
      if (!decorator) {
        throw {
          code: 404,
          status: "DECORATOR_NOT_FOUND",
          message: "Decorator not found",
        };
      }

      // Handle file upload if it's a file object
      if (file && file.path) {
        const uploadResult = await cloudinarySvc.fileUpload(file.path, "decorators/portfolio/");
        const imageUrl = uploadResult.url;
        console.log('SERVICE DEBUG: About to add portfolio image:', imageUrl);
        console.log('SERVICE DEBUG: Current portfolio before adding:', decorator.portfolio);
        
        decorator.addPortfolioImage(imageUrl);
        await decorator.save();
        await decorator.reload(); // Ensure you get the latest data
        
        console.log('SERVICE DEBUG: portfolio after adding:', decorator.portfolio);
        console.log('SERVICE DEBUG: Full decorator data:', decorator.toJSON());
        
        return decorator;
      } else {
        throw {
          code: 400,
          status: "INVALID_FILE",
          message: "No valid file provided",
        };
      }
    } catch (exception) {
      throw exception;
    }
  }

  async removePortfolioImage(decoratorId, imageUrl) {
    try {
      const decorator = await this.getSingleRowByFilter({ id: decoratorId });
      if (!decorator) {
        throw {
          code: 404,
          status: "DECORATOR_NOT_FOUND",
          message: "Decorator not found",
        };
      }
      decorator.removePortfolioImage(imageUrl);
      return true;
    } catch (exception) {
      throw exception;
    }
  }

  _toFrontend(decorator) {
    if (!decorator) return null;
    return {
      ...decorator.toJSON(),
      portfolioImages: decorator.portfolio || [],
    };
  }
}

module.exports = new DecoratorService(); 