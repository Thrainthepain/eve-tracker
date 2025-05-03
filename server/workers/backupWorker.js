// Update the constructor
constructor() {
  this.job = null;
  this.backupDir = path.join(__dirname, '../../backups');
  this.retentionDays = config.backupRetentionDays;
  
  // Parse backup time
  const [hour, minute] = config.backupTime.split(':').map(Number);
  this.backupHour = hour || 2;
  this.backupMinute = minute || 0;
}

// Update the start method to use the configured time
async start() {
  logger.info(`Starting backup worker (time: ${this.backupHour}:${this.backupMinute.toString().padStart(2, '0')} UTC, retention: ${this.retentionDays} days)`);
  
  // Create backup directory if it doesn't exist
  try {
    await fs.mkdir(this.backupDir, { recursive: true });
  } catch (error) {
    logger.error('Failed to create backup directory:', error);
  }
  
  // Run at configured time every day
  this.job = schedule.scheduleJob(`${this.backupMinute} ${this.backupHour} * * *`, async () => {
    try {
      await this.performBackup();
      await this.cleanupOldBackups();
    } catch (error) {
      logger.error('Error in backup worker:', error);
    }
  });
}