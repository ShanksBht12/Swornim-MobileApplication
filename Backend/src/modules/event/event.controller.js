const eventService = require('./event.service');
const { CreateEventDTO, UpdateEventDTO } = require('./event.validator');
const cloudinarySvc = require('../../services/cloudinary.service');
const { deleteFile } = require('../../utilities/helpers');
const EventTicketBooking = require('../event_ticket_booking/event_ticket_booking.model');
const { Op } = require('sequelize');

async function handleGalleryUpload(files) {
  if (!files || !Array.isArray(files) || files.length === 0) return [];
  const urls = [];
  for (const file of files) {
    if (file && file.path) {
      const uploadResult = await cloudinarySvc.fileUpload(file.path, 'events/gallery/');
      urls.push(uploadResult.url);
      deleteFile(file.path);
    }
  }
  return urls;
}

// Helper to calculate available tickets for an event
async function getAvailableTickets(eventId, maxCapacity) {
  const sold = await EventTicketBooking.sum('quantity', {
    where: {
      event_id: eventId, // FIXED: use event_id (snake_case)
      status: { [Op.notIn]: ['cancelled', 'refunded'] },
    },
  });
  return maxCapacity - (sold || 0);
}

class EventController {
  async createEvent(req, res, next) {
    try {
      console.log('[DEBUG] Entered createEvent handler');
      let value = req.body;
      // Validate body (ignore file for now)
      const { error } = CreateEventDTO.validate(value);
      if (error) {
        console.log('[DEBUG] Validation error:', error.details[0].message);
        return res.status(400).json({ error: error.details[0].message });
      }
      value.organizerId = req.loggedInUser.id;
      // Handle main image upload
      if (req.files && req.files['image'] && req.files['image'][0]) {
        console.log('[DEBUG] About to upload main image');
        const file = req.files['image'][0];
        const uploadResult = await cloudinarySvc.fileUpload(file.path, 'events/images/');
        value.imageUrl = uploadResult.url;
        value.imagePublicId = uploadResult.publicId;
        deleteFile(file.path);
        console.log('[DEBUG] Main image uploaded:', value.imageUrl);
      }
      // Handle gallery upload
      if (req.files && req.files['gallery']) {
        console.log('[DEBUG] About to upload gallery images');
        const galleryUrls = await handleGalleryUpload(req.files['gallery']);
        value.gallery = galleryUrls;
        console.log('[DEBUG] Gallery images uploaded:', galleryUrls);
      }
      console.log('[DEBUG] About to save event to DB');
      const event = await eventService.createEvent(value);
      console.log('[DEBUG] Event saved to DB:', event && event.id ? event.id : event);
      const availableTickets = await getAvailableTickets(event.id, event.maxCapacity);
      res.status(201).json({ data: { ...event.toJSON(), availableTickets }, message: 'Event created successfully' });
    } catch (err) {
      console.error('[ERROR] in createEvent:', err);
      if (req.files) {
        if (req.files['image']) req.files['image'].forEach(f => deleteFile(f.path));
        if (req.files['gallery']) req.files['gallery'].forEach(f => deleteFile(f.path));
      }
      next(err);
    }
  }

  async getEventById(req, res, next) {
    try {
      const event = await eventService.getEventById(req.params.id);
      if (!event) return res.status(404).json({ error: 'Event not found' });
      const availableTickets = await getAvailableTickets(event.id, event.maxCapacity);
      res.json({ data: { ...event.toJSON(), availableTickets } });
    } catch (err) {
      next(err);
    }
  }

  async getMyEvents(req, res, next) {
    try {
      const organizerId = req.loggedInUser.id;
      const { status, eventType, visibility } = req.query;
      const events = await eventService.getEventsByOrganizer(organizerId, { status, eventType, visibility });
      const eventsWithAvailability = await Promise.all(events.map(async (event) => {
        const availableTickets = await getAvailableTickets(event.id, event.maxCapacity);
        return { ...event.toJSON(), availableTickets };
      }));
      res.json({ data: eventsWithAvailability });
    } catch (err) {
      next(err);
    }
  }

  async updateEvent(req, res, next) {
    try {
      let value = req.body;
      const { error } = UpdateEventDTO.validate(value);
      if (error) return res.status(400).json({ error: error.details[0].message });
      // Handle main image upload
      if (req.files && req.files['image'] && req.files['image'][0]) {
        const file = req.files['image'][0];
        const uploadResult = await cloudinarySvc.fileUpload(file.path, 'events/images/');
        value.imageUrl = uploadResult.url;
        value.imagePublicId = uploadResult.publicId;
        deleteFile(file.path);
      }
      // Handle gallery upload
      if (req.files && req.files['gallery']) {
        const galleryUrls = await handleGalleryUpload(req.files['gallery']);
        value.gallery = galleryUrls;
      }
      const event = await eventService.updateEvent(req.params.id, value);
      if (!event) return res.status(404).json({ error: 'Event not found' });
      const availableTickets = await getAvailableTickets(event.id, event.maxCapacity);
      res.json({ data: { ...event.toJSON(), availableTickets }, message: 'Event updated successfully' });
    } catch (err) {
      if (req.files) {
        if (req.files['image']) req.files['image'].forEach(f => deleteFile(f.path));
        if (req.files['gallery']) req.files['gallery'].forEach(f => deleteFile(f.path));
      }
      next(err);
    }
  }

  async deleteEvent(req, res, next) {
    try {
      const deleted = await eventService.deleteEvent(req.params.id);
      if (!deleted) return res.status(404).json({ error: 'Event not found' });
      res.json({ message: 'Event deleted successfully' });
    } catch (err) {
      next(err);
    }
  }

  async searchEvents(req, res, next) {
    console.log('=== searchEvents controller called ===');
    try {
      const { eventType, location, fromDate, toDate, status, visibility, q, limit, offset } = req.query;
      const events = await eventService.searchEvents({ eventType, location, fromDate, toDate, status, visibility, q, limit: Number(limit) || 20, offset: Number(offset) || 0 });
      console.log('Events found:', events.length);
      const eventsWithAvailability = await Promise.all(events.map(async (event) => {
        const availableTickets = await getAvailableTickets(event.id, event.maxCapacity);
        console.log('Event:', event.id, 'maxCapacity:', event.maxCapacity, 'availableTickets:', availableTickets);
        return { ...event.toJSON(), availableTickets };
      }));
      res.json({ results: eventsWithAvailability });
    } catch (err) {
      next(err);
    }
  }

  async patchEvent(req, res, next) {
    try {
      let value = req.body;
      const { error } = UpdateEventDTO.validate(value);
      if (error) return res.status(400).json({ error: error.details[0].message });
      // Handle main image upload
      if (req.files && req.files['image'] && req.files['image'][0]) {
        const file = req.files['image'][0];
        const uploadResult = await cloudinarySvc.fileUpload(file.path, 'events/images/');
        value.imageUrl = uploadResult.url;
        value.imagePublicId = uploadResult.publicId;
        deleteFile(file.path);
      }
      // Handle gallery upload
      if (req.files && req.files['gallery']) {
        const galleryUrls = await handleGalleryUpload(req.files['gallery']);
        value.gallery = galleryUrls;
      }
      const event = await eventService.updateEvent(req.params.id, value);
      if (!event) return res.status(404).json({ error: 'Event not found' });
      const availableTickets = await getAvailableTickets(event.id, event.maxCapacity);
      res.json({ data: { ...event.toJSON(), availableTickets }, message: 'Event updated successfully' });
    } catch (err) {
      if (req.files) {
        if (req.files['image']) req.files['image'].forEach(f => deleteFile(f.path));
        if (req.files['gallery']) req.files['gallery'].forEach(f => deleteFile(f.path));
      }
      next(err);
    }
  }
}

module.exports = new EventController(); 