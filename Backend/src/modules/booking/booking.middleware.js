const Booking = require('./booking.model');
const User = require('../user/user.model');
const ServicePackage = require('../package/package.model');

const checkBookingOwnership = async (req, res, next) => {
  try {
    const bookingId = req.params.id;
    const loggedInUserId = req.user.id;

    if (!bookingId) {
      return res.status(400).json({ message: "Booking ID is required." });
    }

    const booking = await Booking.findByPk(bookingId, {
        include: [
            { model: User, as: 'client', attributes: ['id', 'name', 'email'] },
            { model: User, as: 'serviceProvider', attributes: ['id', 'name', 'email'] },
            { model: ServicePackage, as: 'package', attributes: ['id', 'name', 'basePrice'] }
        ]
    });

    if (!booking) {
      return res.status(404).json({ message: "Booking not found." });
    }

    // Attach booking to request for later use in controller
    req.booking = booking;

    const isClient = booking.clientId === loggedInUserId;
    const isServiceProvider = booking.serviceProviderId === loggedInUserId;

    if (isClient || isServiceProvider) {
      return next();
    }

    return res.status(403).json({ message: "You are not authorized to perform this action on this booking." });

  } catch (error) {
    next(error);
  }
};

module.exports = {
  checkBookingOwnership
}; 