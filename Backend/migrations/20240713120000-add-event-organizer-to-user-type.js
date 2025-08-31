'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Add 'event_organizer' to the enum_users_user_type enum
    await queryInterface.sequelize.query(
      "ALTER TYPE enum_users_user_type ADD VALUE IF NOT EXISTS 'event_organizer';"
    );
  },
  down: async (queryInterface, Sequelize) => {
    // No down migration for enum value removal in Postgres
  }
}; 