const { Sequelize } = require("sequelize");
const { DatabaseConfig } = require("./config");

const sequelize = new Sequelize(
  DatabaseConfig.database,
  DatabaseConfig.username,
  DatabaseConfig.password,
  {
    host: DatabaseConfig.host,
    port: DatabaseConfig.port,
    dialect: DatabaseConfig.dialect,
    logging: false,
    define: {
      timestamps: true,
      underscored: true,
    },
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000,
    },
  }
);

sequelize
  .authenticate()
  .then(() => {
    console.log("✅ Database connection has been established successfully.");
  })
  .catch((error) => {
    console.error("Unable to connect to the database:", error);
  });

module.exports = sequelize;

// Import model associations AFTER exporting sequelize to avoid circular dependency
require("./model.associations");

// Removed initializeDatabase and sequelize.sync({ alter: true }) to prevent automatic schema sync.
// Migrations should handle all schema changes.
