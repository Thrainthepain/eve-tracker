const mongoose = require('mongoose');

const CharacterSchema = new mongoose.Schema({
  characterId: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  corporation_id: {
    type: String,
    required: true
  },
  corporation_name: {
    type: String
  },
  alliance_id: {
    type: String
  },
  alliance_name: {
    type: String
  },
  accessToken: {
    type: String,
    required: true
  },
  refreshToken: {
    type: String,
    required: true
  },
  tokenExpiry: {
    type: Date,
    required: true
  },
  scopes: {
    type: [String],
    required: true
  },
  isAdmin: {
    type: Boolean,
    default: false
  },
  lastLogin: {
    type: Date,
    default: Date.now
  },
  lastUpdate: {
    type: Date,
    default: Date.now
  },
  assets: {
    type: Object,
    default: {}
  },
  wallet: {
    type: Object,
    default: {
      balance: 0,
      transactions: []
    }
  },
  skills: {
    type: Object,
    default: {}
  },
  standings: {
    type: Object,
    default: {}
  },
  customData: {
    type: Object,
    default: {}
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Character', CharacterSchema);