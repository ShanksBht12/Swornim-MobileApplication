const sequelize = require('./src/config/database.config');

async function runMigration() {
  try {
    console.log('Starting migration...');
    console.log('Database connection established');
    
    // Import and run the migration
    const migration = require('./migrations/20250106000000-enhance-booking-flow.js');
    console.log('Migration file loaded successfully');
    
    if (typeof migration.up === 'function') {
      console.log('Running migration up function...');
      await migration.up(sequelize.getQueryInterface(), sequelize.Sequelize);
      console.log('Migration completed successfully!');
    } else {
      console.log('Migration file does not have an up function');
    }
    
  } catch (error) {
    console.error('Migration failed:', error);
    console.error('Error stack:', error.stack);
  } finally {
    try {
      await sequelize.close();
      console.log('Database connection closed');
    } catch (closeError) {
      console.error('Error closing database connection:', closeError);
    }
    process.exit(0);
  }
}

runMigration(); 