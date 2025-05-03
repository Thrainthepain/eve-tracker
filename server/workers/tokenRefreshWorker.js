const schedule = require('node-schedule');
const Character = require('../models/Character');
const eveSSO = require('../auth/eveSso');
const logger = require('../utils/logger');

class TokenRefreshWorker {
  constructor() {
    this.job = null;
  }

  start() {
    logger.info('Starting token refresh worker');
    
    // Run every 15 minutes
    this.job = schedule.scheduleJob('*/15 * * * *', async () => {
      try {
        await this.refreshTokens();
      } catch (error) {
        logger.error('Error in token refresh worker:', error);
      }
    });
    
    // Run immediately on startup
    this.refreshTokens().catch(error => {
      logger.error('Error in initial token refresh:', error);
    });
  }

  stop() {
    if (this.job) {
      this.job.cancel();
      logger.info('Token refresh worker stopped');
    }
  }

  async refreshTokens() {
    const startTime = Date.now();
    logger.info('Starting scheduled token refresh check');
    
    try {
      // Find characters whose tokens will expire in the next 30 minutes
      const expiryThreshold = new Date(Date.now() + 30 * 60 * 1000);
      const characters = await Character.find({
        tokenExpiry: { $lt: expiryThreshold, $gt: new Date() }
      });
      
      logger.info(`Found ${characters.length} characters needing token refresh`);
      
      // Refresh tokens for each character
      for (const character of characters) {
        try {
          logger.info(`Refreshing token for character: ${character.name} (${character.characterId})`);
          await eveSSO.refreshToken(character.characterId);
          logger.info(`Successfully refreshed token for: ${character.name}`);
        } catch (error) {
          logger.error(`Error refreshing token for ${character.name}:`, error);
        }
        
        // Small delay between refreshes
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      
      const duration = (Date.now() - startTime) / 1000;
      logger.info(`Completed token refresh cycle in ${duration.toFixed(2)}s`);
    } catch (error) {
      logger.error('Failed to refresh tokens:', error);
    }
  }
}

module.exports = new TokenRefreshWorker();