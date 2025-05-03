const mongoose = require('mongoose');

const CorporationSchema = new mongoose.Schema({
  corporationId: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  ticker: {
    type: String
  },
  alliance_id: {
    type: String
  },
  alliance_name: {
    type: String
  },
  ceo_id: {
    type: String
  },
  member_count: {
    type: Number
  },
  description: {
    type: String
  },
  tax_rate: {
    type: Number
  },
  assets: {
    type: Object,
    default: {}
  },
  wallet: {
    type: Object,
    default: {}
  },
  customData: {
    type: Object,
    default: {}
  },
  lastUpdate: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Corporation', CorporationSchema);