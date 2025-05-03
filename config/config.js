// Environment variables configuration
require('dotenv').config();

module.exports = {
  port: process.env.PORT || 5000,
  mongoUri: process.env.MONGO_URI || 'mongodb://localhost:27017/eve-tracker',
  clientUrl: process.env.CLIENT_URL || 'http://localhost:3000',
  serverUrl: process.env.SERVER_URL || 'http://localhost:5000',
  eveClientId: process.env.EVE_CLIENT_ID,
  eveClientSecret: process.env.EVE_CLIENT_SECRET,
  sessionSecret: process.env.SESSION_SECRET || 'keyboard cat',
  nodeEnv: process.env.NODE_ENV || 'development',
  dataRefreshInterval: parseInt(process.env.DATA_REFRESH_INTERVAL || 30), // minutes
  websiteName: process.env.WEBSITE_NAME || 'EVE Character Tracker',
  serverProtocol: process.env.SERVER_PROTOCOL || 'http',
  serverDomain: process.env.SERVER_DOMAIN || 'localhost',
  serverSubdomain: process.env.SERVER_SUBDOMAIN || '',
  fullDomain: process.env.FULL_DOMAIN || 'localhost',
  devEmail: process.env.DEV_EMAIL || '',
  sslMode: process.env.SSL_MODE || 'skip',
  letsencryptEmail: process.env.LETSENCRYPT_EMAIL || '',
  // Worker settings
  backupRetentionDays: parseInt(process.env.BACKUP_RETENTION_DAYS || 7),
  backupTime: process.env.BACKUP_TIME || '2:00',
  tokenRefreshInterval: parseInt(process.env.TOKEN_REFRESH_INTERVAL || 15), // minutes
  dbMaintenanceTime: process.env.DB_MAINTENANCE_TIME || '3:00',
};