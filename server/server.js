// Add this near the top of the existing server.js file:
const workerManager = require('./workers/workerManager');
const logger = require('./utils/logger');

// Add this after MongoDB connection is established:
mongoose.connect(config.mongoUri)
  .then(() => {
    logger.info('MongoDB Connected');
    // Start background workers after successful database connection
    workerManager.startAll();
  })
  .catch(err => logger.error('MongoDB Connection Error:', err));

// Add this for graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received. Shutting down gracefully...');
  workerManager.stopAll();
  server.close(() => {
    logger.info('HTTP server closed');
    mongoose.connection.close(false, () => {
      logger.info('MongoDB connection closed');
      process.exit(0);
    });
  });
});

// Store the server instance
const server = app.listen(PORT, () => logger.info(`Server running on port ${PORT}`));