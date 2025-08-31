const router = require("express").Router();
const authRoutes = require("../modules/auth/auth.router"); // adjust path as needed
const catererRouter = require("../modules/caterer/caterer.router");
const decoratorRouter = require("../modules/decorator/decorator.router");
const makeupArtistRouter = require("../modules/makeupartist/makeupartist.router");
const photographerRoutes = require("../modules/photographer/photographer.router");
const userRouter = require("../modules/user/user.router");
const venueRouter = require("../modules/venue/venue.router");
const packageModuleRouter = require('../routes/package.routes');
const bookingModuleRouter = require('../modules/booking/booking.routes');
const paymentRouter = require('../modules/payment/payment.routes');
const reviewRouter = require('../modules/review/review.router');
const eventOrganizerRouter = require("../modules/eventorganizer/eventorganizer.router");
const eventRouter = require("../modules/event/event.router");
const eventTicketBookingRoutes = require('../modules/event_ticket_booking/event_ticket_booking.routes');

// Add logging middleware
router.use((req, res, next) => {
  console.log('=== ROUTER REQUEST ===');
  console.log('Method:', req.method);
  console.log('URL:', req.url);
  console.log('Path:', req.path);
  console.log('=====================');
  next();
});

router.use("/auth", authRoutes);
router.use("/photographers", photographerRoutes);
router.use("/users", userRouter);
router.use("/makeup-artists", makeupArtistRouter);
router.use('/caterers',catererRouter)
router.use('/decorators',decoratorRouter)
router.use('/venues', venueRouter);
router.use('/packages', packageModuleRouter);
router.use('/bookings', bookingModuleRouter);
router.use('/payments', paymentRouter);
router.use('/reviews', reviewRouter);
router.use('/event-organizers', eventOrganizerRouter);
// Mount eventTicketBookingRoutes BEFORE eventRouter to ensure /events/bookings and similar are handled correctly
router.use('/events', eventTicketBookingRoutes);
router.use('/events', eventRouter);
module.exports = router;
