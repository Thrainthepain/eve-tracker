// Add this route to the existing api.js file

// Get website configuration
router.get('/config', (req, res) => {
  res.json({
    websiteName: config.websiteName,
    serverDomain: config.serverDomain,
    // Include any other public configuration that the frontend needs
  });
});