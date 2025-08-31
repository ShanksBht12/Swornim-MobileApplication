const Venue = require("./venue.model");
const User = require("../user/user.model");
const { UserStatus } = require("../../config/constants");
const { Op } = require("sequelize");
const cloudinarySvc = require("../../services/cloudinary.service");

class VenueService {
  async createVenue(data) {
    try {
      if (data.image && data.image.path) {
        const uploadResult = await cloudinarySvc.fileUpload(data.image.path, "venues/images/");
        data.image = uploadResult.url;
        data.imagePublicId = uploadResult.publicId;
      }
      const venue = await Venue.create(data);
      return venue;
    } catch (exception) {
      throw exception;
    }
  }

  async getSingleRowByFilter(filter) {
    try {
      const venue = await Venue.findOne({
        where: filter,
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
      });
      return venue;
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
        amenities = [],
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

      if (amenities.length > 0) {
        whereClause.amenities = {
          [Op.overlap]: amenities,
        };
      }

      if (minRating > 0) {
        whereClause.rating = {
          [Op.gte]: minRating,
        };
      }

      if (minPrice !== null || maxPrice !== null) {
        whereClause.pricePerHour = {};
        if (minPrice !== null) {
          whereClause.pricePerHour[Op.gte] = minPrice;
        }
        if (maxPrice !== null) {
          whereClause.pricePerHour[Op.lte] = maxPrice;
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

      const { count, rows } = await Venue.findAndCountAll({
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
        venues: rows,
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
      const [updatedCount] = await Venue.update(updateData, {
        where: filter,
      });
      return updatedCount;
    } catch (exception) {
      throw exception;
    }
  }

  async deleteSingleRowByFilter(filter) {
    try {
      const deletedCount = await Venue.destroy({
        where: filter,
      });
      return deletedCount;
    } catch (exception) {
      throw exception;
    }
  }

  async getVenueWithUser(venueId) {
    try {
      const venue = await Venue.findOne({
        where: { id: venueId },
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "name", "email", "phone", "profileImage", "userType"],
          },
        ],
      });
      return venue;
    } catch (exception) {
      throw exception;
    }
  }

  async updateVenueProfile(venueId, updateData) {
    try {
      const venue = await this.getSingleRowByFilter({ id: venueId });
      if (!venue) {
        throw {
          code: 404,
          status: "VENUE_NOT_FOUND",
          message: "Venue not found",
        };
      }
      if (updateData.image && updateData.image.path) {
        if (venue.imagePublicId) {
          await cloudinarySvc.deleteFile(venue.imagePublicId);
        }
        const uploadResult = await cloudinarySvc.fileUpload(updateData.image.path, "venues/images/");
        updateData.image = uploadResult.url;
        updateData.imagePublicId = uploadResult.publicId;
      }
      await venue.update(updateData);
      return venue;
    } catch (exception) {
      throw exception;
    }
  }

  async getTopRatedVenues(limit = 10) {
    try {
      const venues = await Venue.findAll({
        where: { userStatus: UserStatus.ACTIVE },
        order: [["rating", "DESC"]],
        limit,
      });
      return venues;
    } catch (exception) {
      throw exception;
    }
  }

  async getAvailableVenues() {
    try {
      const venues = await Venue.findAll({
        where: { isAvailable: true },
      });
      return venues;
    } catch (exception) {
      throw exception;
    }
  }

  async addPortfolioImage(venueId, file) {
    try {
      const venue = await this.getSingleRowByFilter({ id: venueId });
      if (!venue) {
        throw {
          code: 404,
          status: "VENUE_NOT_FOUND",
          message: "Venue not found",
        };
      }

      // Handle file upload if it's a file object
      if (file && file.path) {
        const uploadResult = await cloudinarySvc.fileUpload(file.path, "venues/portfolio/");
        const imageUrl = uploadResult.url;
        console.log('SERVICE DEBUG: About to add portfolio image:', imageUrl);
        console.log('SERVICE DEBUG: Current images before adding:', venue.images);
        
        venue.addPortfolioImage(imageUrl);
        await venue.save();
        await venue.reload(); // Ensure you get the latest data
        
        console.log('SERVICE DEBUG: images after adding:', venue.images);
        console.log('SERVICE DEBUG: Full venue data:', venue.toJSON());
        
        return venue;
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

  async removePortfolioImage(venueId, imageUrl) {
    try {
      const venue = await this.getSingleRowByFilter({ id: venueId });
      if (!venue) {
        throw {
          code: 404,
          status: "VENUE_NOT_FOUND",
          message: "Venue not found",
        };
      }
      venue.removePortfolioImage(imageUrl);
      return true;
    } catch (exception) {
      throw exception;
    }
  }

  _toFrontend(venue) {
    if (!venue) return null;
    return {
      ...venue.toJSON(),
      portfolioImages: venue.portfolio || [],
    };
  }
}

module.exports = new VenueService(); 