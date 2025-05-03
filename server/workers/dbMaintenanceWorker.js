const schedule = require('node-schedule');
const mongoose = require('mongoose');
const logger = require('../utils/logger');
const config = require('../../config/config');

class DbMaintenanceWorker {
  constructor() {
    this.job = null;
  }

  start() {
    logger.info('Starting database maintenance worker');
    
    // Run at 3:00 AM every day
    this.job = schedule.scheduleJob('0 3 * * *', async () => {
      try {
        await this.performMaintenance();
      } catch (error) {
        logger.error('Error in database maintenance worker:', error);
      }
    });
  }

  stop() {
    if (this.job) {
      this.job.cancel();
      logger.info('Database maintenance worker stopped');
    }
  }

  async performMaintenance() {
    logger.info('Starting scheduled database maintenance');
    
    try {
      // Clean up expired sessions
      const db = mongoose.connection.db;
      const sessions = db.collection('sessions');
      const result = await sessions.deleteMany({
        "expires": { $lt: new Date() }
      });
      
      logger.info(`Removed ${result.deletedCount} expired sessions`);
      
      // Add other maintenance tasks as needed:
      // - Cleanup temporary data
      // - Archive old logs
      // - Optimize indexes
      
      // Run compact command on collections if needed
      // await db.command({ compact: 'characters' });
      
      logger.info('Database maintenance completed successfully');
    } catch (error) {
      logger.error('Database maintenance failed:', error);
      throw error;
    }
  }
}

module.exports = new DbMaintenanceWorker();