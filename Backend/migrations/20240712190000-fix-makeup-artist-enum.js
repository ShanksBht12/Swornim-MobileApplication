module.exports = {
  up: async (queryInterface, Sequelize) => {
    // 1. Add the new value to the ENUM
    await queryInterface.sequelize.query(`ALTER TYPE enum_users_user_type ADD VALUE IF NOT EXISTS 'makeup_artist';`);
    // 2. Update all existing users to use the new value
    await queryInterface.sequelize.query(`UPDATE users SET user_type = 'makeup_artist' WHERE user_type = 'makeupArtist';`);
  },
  down: async (queryInterface, Sequelize) => {
    // No down migration: removing ENUM values is non-trivial and not supported in most PostgreSQL versions
  }
}; 