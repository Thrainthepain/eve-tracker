const express = require('express');
const router = express.Router();
const ExternalApp = require('../models/ExternalApp');
const authMiddleware = require('../middleware/auth');
const fs = require('fs').promises;
const path = require('path');

// Get all enabled external apps
router.get('/', async (req, res) => {
  try {
    const apps = await ExternalApp.find({ enabled: true }).select('-config');
    res.json(apps);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get external app by ID
router.get('/:id', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const app = await ExternalApp.findById(req.params.id);
    if (!app) {
      return res.status(404).json({ message: 'External app not found' });
    }
    
    if (!app.enabled) {
      return res.status(403).json({ message: 'This external app is currently disabled' });
    }
    
    res.json(app);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Register an external app (admin only)
router.post('/', authMiddleware.isAdmin, async (req, res) => {
  try {
    const { name, description, menuTitle, route, componentPath, icon } = req.body;
    
    // Check if the component file exists
    const componentFullPath = path.join(__dirname, '../../external-apps', componentPath);
    try {
      await fs.access(componentFullPath);
    } catch (err) {
      return res.status(400).json({ message: 'Component file does not exist' });
    }
    
    // Check if route is already taken
    const existingApp = await ExternalApp.findOne({ route });
    if (existingApp) {
      return res.status(400).json({ message: 'Route already in use by another app' });
    }
    
    const newApp = new ExternalApp({
      name,
      description,
      menuTitle,
      route,
      componentPath,
      icon: icon || 'apps',
      createdBy: req.user.id
    });
    
    await newApp.save();
    res.status(201).json(newApp);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update external app settings (admin only)
router.put('/:id', authMiddleware.isAdmin, async (req, res) => {
  try {
    const { name, description, menuTitle, icon, enabled, config } = req.body;
    
    const app = await ExternalApp.findById(req.params.id);
    if (!app) {
      return res.status(404).json({ message: 'External app not found' });
    }
    
    if (name) app.name = name;
    if (description) app.description = description;
    if (menuTitle) app.menuTitle = menuTitle;
    if (icon) app.icon = icon;
    if (enabled !== undefined) app.enabled = enabled;
    if (config) app.config = { ...app.config, ...config };
    
    await app.save();
    res.json(app);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get external app data for a specific character
router.get('/:id/character/:characterId', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const { id, characterId } = req.params;
    
    // Verify the user owns this character
    if (req.user.characterId !== characterId && !req.user.isAdmin) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    const app = await ExternalApp.findById(id);
    if (!app || !app.enabled) {
      return res.status(404).json({ message: 'External app not found or disabled' });
    }
    
    // Get character data
    const Character = require('../models/Character');
    const character = await Character.findOne({ characterId });
    
    if (!character) {
      return res.status(404).json({ message: 'Character not found' });
    }
    
    // Return app-specific data for this character
    const appData = character.customData[app._id] || {};
    
    res.json(appData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Save external app data for a character
router.post('/:id/character/:characterId', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const { id, characterId } = req.params;
    const { data } = req.body;
    
    // Verify the user owns this character
    if (req.user.characterId !== characterId && !req.user.isAdmin) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    const app = await ExternalApp.findById(id);
    if (!app || !app.enabled) {
      return res.status(404).json({ message: 'External app not found or disabled' });
    }
    
    // Get character and update custom data
    const Character = require('../models/Character');
    const character = await Character.findOne({ characterId });
    
    if (!character) {
      return res.status(404).json({ message: 'Character not found' });
    }
    
    if (!character.customData) {
      character.customData = {};
    }
    
    character.customData[app._id] = data;
    await character.save();
    
    res.json({ message: 'External app data saved' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;