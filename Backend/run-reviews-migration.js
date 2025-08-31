const sequelize = require('./src/config/database.config');

async function runReviewsMigration() {
  try {
    console.log('Starting reviews table migration...');
    console.log('Database connection established');
    
    // Import and run the reviews migration
    const migration = require('./migrations/20250106000001-create-reviews-table.js');
    console.log('Reviews migration file loaded successfully');
    
    if (typeof migration.up === 'function') {
      console.log('Running reviews migration up function...');
      await migration.up(sequelize.getQueryInterface(), sequelize.Sequelize);
      console.log('Reviews migration completed successfully!');
    } else {
      console.log('Reviews migration file does not have an up function');
    }
    
  } catch (error) {
    console.error('Reviews migration failed:', error);
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

runReviewsMigration();