// Update the settings API in admin.js to handle worker settings

// Get system settings
router.get('/settings', authMiddleware.isAuthenticated, isAdmin, async (req, res) => {
  try {
    res.json({
      devEmail: config.devEmail,
      eveClientId: config.eveClientId ? '********' : '',
      eveClientSecret: config.eveClientSecret ? '********' : '',
      autoRefreshInterval: config.dataRefreshInterval,
      websiteName: config.websiteName,
      serverProtocol: config.serverProtocol,
      serverDomain: config.serverDomain,
      serverSubdomain: config.serverSubdomain,
      sslMode: config.sslMode,
      letsencryptEmail: config.letsencryptEmail,
      // Worker settings
      dataRefreshInterval: config.dataRefreshInterval,
      backupRetentionDays: config.backupRetentionDays,
      backupTime: config.backupTime,
      tokenRefreshInterval: config.tokenRefreshInterval,
      dbMaintenanceTime: config.dbMaintenanceTime
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update system settings - add these in the existing function
updateEnvValue('DATA_REFRESH_INTERVAL', dataRefreshInterval);
updateEnvValue('BACKUP_RETENTION_DAYS', backupRetentionDays);
updateEnvValue('BACKUP_TIME', backupTime);
updateEnvValue('TOKEN_REFRESH_INTERVAL', tokenRefreshInterval);
updateEnvValue('DB_MAINTENANCE_TIME', dbMaintenanceTime);