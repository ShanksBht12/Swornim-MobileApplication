const EventOrganizer = require("./eventorganizer.model");

class EventOrganizerService {
  async createEventOrganizer(data) {
    try {
      const eventOrganizer = await EventOrganizer.create(data);
      return eventOrganizer;
    } catch (error) {
      throw error;
    }
  }

  async getByUserId(userId) {
    try {
      return await EventOrganizer.findOne({ where: { userId } });
    } catch (error) {
      throw error;
    }
  }

  async updateEventOrganizer(userId, updateData) {
    try {
      const eventOrganizer = await this.getByUserId(userId);
      if (!eventOrganizer) throw { code: 404, message: "Event organizer profile not found" };
      await eventOrganizer.update(updateData);
      return eventOrganizer;
    } catch (error) {
      throw error;
    }
  }

  async deleteEventOrganizer(userId) {
    try {
      const eventOrganizer = await this.getByUserId(userId);
      if (!eventOrganizer) throw { code: 404, message: "Event organizer profile not found" };
      await eventOrganizer.destroy();
      return true;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = new EventOrganizerService(); 