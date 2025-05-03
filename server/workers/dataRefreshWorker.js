const schedule = require('node-schedule');
const Character = require('../models/Character');
const eveEsiService = require('../services/eveEsiService');
const config = require('../../config/config');
const logger = require('../utils/logger');

class DataRefreshWorker {
  constructor() {
    this.refreshInterval = config.dataRefreshInterval || 30; // minutes
    this.job = null;
  }

  start() {
    logger.info(`Starting data refresh worker (interval: ${this.refreshInterval} minutes)`);
    
    // Schedule job to run based on the configured interval
    this.job = schedule.scheduleJob(`*/${this.refreshInterval} * * * *`, async () => {
      try {
        await this.refreshAllCharacters();
      } catch (error) {
        logger.error('Error in data refresh worker:', error);
      }
    });
    
    // Run immediately on startup
    this.refreshAllCharacters().catch(error => {
      logger.error('Error in initial data refresh:', error);
    });
  }

  stop() {
    if (this.job) {
      this.job.cancel();
      logger.info('Data refresh worker stopped');
    }
  }

  async refreshAllCharacters() {
    const startTime = Date.now();
    logger.info('Starting scheduled data refresh for all characters');
    
    try {
      // Get all characters with valid tokens
      const characters = await Character.find({
        tokenExpiry: { $gt: new Date() }
      });
      
      logger.info(`Found ${characters.length} characters to update`);
      
      // Process characters sequentially to avoid rate limiting
      for (const character of characters) {
        try {
          logger.info(`Updating data for character: ${character.name} (${character.characterId})`);
          await eveEsiService.updateCharacterData(character.characterId);
          logger.info(`Successfully updated character: ${character.name}`);
        } catch (error) {
          logger.error(`Error updating character ${character.name}:`, error);
          // Continue with next character even if one fails
        }
        
        // Small delay between characters to prevent API rate limiting
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
      
      const duration = (Date.now() - startTime) / 1000;
      logger.info(`Completed data refresh cycle in ${duration.toFixed(2)}s`);
    } catch (error) {
      logger.error('Failed to refresh character data:', error);
    }
  }
}

module.exports = new DataRefreshWorker();