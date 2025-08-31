module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('event_ticket_bookings', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.literal('uuid_generate_v4()'),
        primaryKey: true,
        allowNull: false,
      },
      eventId: {
        type: Sequelize.UUID,
        allowNull: false,
      },
      userId: {
        type: Sequelize.UUID,
        allowNull: false,
      },
      ticketType: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      quantity: {
        type: Sequelize.INTEGER,
        allowNull: false,
      },
      pricePerTicket: {
        type: Sequelize.FLOAT,
        allowNull: false,
      },
      totalAmount: {
        type: Sequelize.FLOAT,
        allowNull: false,
      },
      paymentStatus: {
        type: Sequelize.ENUM('pending', 'paid', 'failed', 'refunded'),
        defaultValue: 'pending',
        allowNull: false,
      },
      bookingStatus: {
        type: Sequelize.ENUM('confirmed', 'cancelled', 'refunded'),
        defaultValue: 'confirmed',
        allowNull: false,
      },
      qrCode: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      specialRequests: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      ticketHolderDetails: {
        type: Sequelize.JSONB,
        allowNull: true,
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('NOW()'),
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('NOW()'),
      },
    });
  },
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('event_ticket_bookings');
  },
}; 