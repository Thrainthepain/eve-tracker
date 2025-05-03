const dataRefreshWorker = require('./dataRefreshWorker');
const tokenRefreshWorker = require('./tokenRefreshWorker');
const dbMaintenanceWorker = require('./dbMaintenanceWorker');
const backupWorker = require('./backupWorker');
const logger = require('../utils/logger');

class WorkerManager {
  constructor() {
    this.workers = [
      { name: 'Data Refresh Worker', worker: dataRefreshWorker },
      { name: 'Token Refresh Worker', worker: tokenRefreshWorker },
      { name: 'Database Maintenance Worker', worker: dbMaintenanceWorker },
      { name: 'Backup Worker', worker: backupWorker }
    ];
    this.running = false;
  }

  startAll() {
    if (this.running) {
      logger.warn('Workers are already running');
      return;
    }
    
    logger.info('Starting all workers...');
    
    for (const { name, worker } of this.workers) {
      try {
        logger.info(`Starting ${name}`);
        worker.start();
      } catch (error) {
        logger.error(`Failed to start ${name}:`, error);
      }
    }
    
    this.running = true;
    logger.info('All workers started');
  }

  stopAll() {
    if (!this.running) {
      logger.warn('Workers are not running');
      return;
    }
    
    logger.info('Stopping all workers...');
    
    for (const { name, worker } of this.workers) {
      try {
        logger.info(`Stopping ${name}`);
        worker.stop();
      } catch (error) {
        logger.error(`Failed to stop ${name}:`, error);
      }
    }
    
    this.running = false;
    logger.info('All workers stopped');
  }

  getStatus() {
    return {
      running: this.running,
      workers: this.workers.map(w => w.name)
    };
  }
}

module.exports = new WorkerManager();