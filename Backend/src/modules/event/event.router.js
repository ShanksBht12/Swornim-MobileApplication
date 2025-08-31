const router = require('express').Router();
const eventCtrl = require('./event.controller');
const auth = require('../../middlewares/auth.middleware');
const bodyValidator = require('../../middlewares/validator.middleware');
const uploader = require('../../middlewares/uploader.middleware');

const eventUploadFields = uploader.fields([
  { name: 'image', maxCount: 1 },
  { name: 'gallery', maxCount: 10 },
]);

// Organizer-only routes
router.post('/', auth.requireServiceProvider(), eventUploadFields, bodyValidator(require('./event.validator').CreateEventDTO), eventCtrl.createEvent);
router.get('/my', auth.requireServiceProvider(), eventCtrl.getMyEvents);
router.put('/:id', auth.requireServiceProvider(), eventUploadFields, bodyValidator(require('./event.validator').UpdateEventDTO), eventCtrl.updateEvent);
router.delete('/:id', auth.requireServiceProvider(), eventCtrl.deleteEvent);
router.patch('/:id', auth.requireServiceProvider(), eventUploadFields, bodyValidator(require('./event.validator').UpdateEventDTO), eventCtrl.patchEvent);

// Public routes
router.get('/search', eventCtrl.searchEvents);
router.get('/:id', eventCtrl.getEventById);

module.exports = router; 