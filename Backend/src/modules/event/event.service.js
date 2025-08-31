const Event = require('./event.model');
const { Op } = require('sequelize');

class EventService {
  async createEvent(data) {
    return await Event.create(data);
  }

  async getEventById(id) {
    return await Event.findByPk(id);
  }

  async getEventsByOrganizer(organizerId, filters = {}) {
    const where = { organizerId };
    if (filters.status) where.status = filters.status;
    if (filters.eventType) where.eventType = filters.eventType;
    if (filters.visibility) where.visibility = filters.visibility;
    return await Event.findAll({ where, order: [['eventDate', 'DESC']] });
  }

  async updateEvent(id, data) {
    const event = await Event.findByPk(id);
    if (!event) return null;
    await event.update(data);
    return event;
  }

  async deleteEvent(id) {
    const event = await Event.findByPk(id);
    if (!event) return null;
    await event.destroy();
    return true;
  }

  async searchEvents({ eventType, location, fromDate, toDate, status, visibility, q, limit = 20, offset = 0 }) {
    const where = {};
    if (eventType) where.eventType = eventType;
    if (status) where.status = status;
    if (visibility) where.visibility = visibility;
    if (fromDate) where.eventDate = { [Op.gte]: fromDate };
    if (toDate) where.eventDate = { ...(where.eventDate || {}), [Op.lte]: toDate };
    if (q) {
      where[Op.or] = [
        { title: { [Op.iLike]: `%${q}%` } },
        { description: { [Op.iLike]: `%${q}%` } },
      ];
    }
    if (location) {
      where['location'] = { [Op.contains]: { name: location } };
    }
    return await Event.findAll({ where, limit, offset, order: [['eventDate', 'ASC']] });
  }
}

module.exports = new EventService(); 