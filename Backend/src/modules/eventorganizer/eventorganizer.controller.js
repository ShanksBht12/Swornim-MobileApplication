const eventOrganizerSvc = require("./eventorganizer.service");
const cloudinarySvc = require("../../services/cloudinary.service");
const { deleteFile } = require("../../utilities/helpers");

class EventOrganizerController {
  async createProfile(req, res, next) {
    try {
      const userId = req.loggedInUser.id;
      const existing = await eventOrganizerSvc.getByUserId(userId);
      if (existing) {
        if (req.file) deleteFile(req.file.path);
        return res.status(409).json({
          data: null,
          message: "Event organizer profile already exists",
          status: "CONFLICT",
          options: null,
        });
      }
      const data = { ...req.body, userId };
      if (req.file) {
        const uploadResult = await cloudinarySvc.fileUpload(req.file.path, "eventorganizers/profiles/");
        data.image = uploadResult.url;
        data.imagePublicId = uploadResult.publicId;
        deleteFile(req.file.path);
      }
      const profile = await eventOrganizerSvc.createEventOrganizer(data);
      res.status(201).json({
        data: profile,
        message: "Event organizer profile created successfully",
        status: "CREATED",
        options: null,
      });
    } catch (error) {
      if (req.file) deleteFile(req.file.path);
      next(error);
    }
  }

  async getProfile(req, res, next) {
    try {
      const userId = req.loggedInUser.id;
      const profile = await eventOrganizerSvc.getByUserId(userId);
      if (!profile) {
        return res.status(404).json({
          data: null,
          message: "Event organizer profile not found",
          status: "NOT_FOUND",
          options: null,
        });
      }
      res.json({
        data: profile,
        message: "Event organizer profile fetched successfully",
        status: "OK",
        options: null,
      });
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const userId = req.loggedInUser.id;
      const updateData = req.body;
      if (req.file) {
        const uploadResult = await cloudinarySvc.fileUpload(req.file.path, "eventorganizers/profiles/");
        updateData.image = uploadResult.url;
        updateData.imagePublicId = uploadResult.publicId;
        deleteFile(req.file.path);
      }
      const profile = await eventOrganizerSvc.updateEventOrganizer(userId, updateData);
      res.json({
        data: profile,
        message: "Event organizer profile updated successfully",
        status: "OK",
        options: null,
      });
    } catch (error) {
      if (req.file) deleteFile(req.file.path);
      next(error);
    }
  }

  async deleteProfile(req, res, next) {
    try {
      const userId = req.loggedInUser.id;
      await eventOrganizerSvc.deleteEventOrganizer(userId);
      res.json({
        data: null,
        message: "Event organizer profile deleted successfully",
        status: "OK",
        options: null,
      });
    } catch (error) {
      next(error);
    }
  }

  async addPortfolioImage(req, res, next) {
    try {
      const userId = req.loggedInUser.id;
      const eventOrganizer = await eventOrganizerSvc.getByUserId(userId);
      if (!eventOrganizer) {
        if (req.file) deleteFile(req.file.path);
        return res.status(404).json({
          data: null,
          message: "Event organizer profile not found",
          status: "NOT_FOUND",
          options: null,
        });
      }
      if (!req.file) {
        return res.status(400).json({
          data: null,
          message: "No portfolio image provided",
          status: "NO_IMAGE_PROVIDED",
          options: null,
        });
      }
      const uploadResult = await cloudinarySvc.fileUpload(req.file.path, "eventorganizers/portfolio/");
      deleteFile(req.file.path);
      // Add the new image URL to the portfolio array
      const portfolio = Array.isArray(eventOrganizer.portfolio) ? [...eventOrganizer.portfolio] : [];
      portfolio.push(uploadResult.url);
      await eventOrganizer.update({ portfolio });
      res.json({
        data: eventOrganizer,
        message: "Portfolio image added successfully",
        status: "OK",
        options: null,
      });
    } catch (error) {
      if (req.file) deleteFile(req.file.path);
      next(error);
    }
  }
}

module.exports = new EventOrganizerController(); 