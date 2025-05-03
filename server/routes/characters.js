const express = require('express');
const router = express.Router();
const Character = require('../models/Character');
const authMiddleware = require('../middleware/auth');
const eveEsiService = require('../services/eveEsiService');

// Get current character data
router.get('/me', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const character = await Character.findById(req.user.id);
    if (!character) {
      return res.status(404).json({ message: 'Character not found' });
    }
    res.json(character);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get character wallet
router.get('/me/wallet', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const walletData = await eveEsiService.getCharacterWallet(req.user.characterId);
    res.json(walletData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get character assets
router.get('/me/assets', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const assetsData = await eveEsiService.getCharacterAssets(req.user.characterId);
    res.json(assetsData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get character skills
router.get('/me/skills', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const skillsData = await eveEsiService.getCharacterSkills(req.user.characterId);
    res.json(skillsData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get character standings
router.get('/me/standings', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const standingsData = await eveEsiService.getCharacterStandings(req.user.characterId);
    res.json(standingsData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update character custom data
router.put('/me/custom-data', authMiddleware.isAuthenticated, async (req, res) => {
  try {
    const character = await Character.findById(req.user.id);
    if (!character) {
      return res.status(404).json({ message: 'Character not found' });
    }
    
    character.customData = {
      ...character.customData,
      ...req.body
    };
    
    await character.save();
    res.json(character.customData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;