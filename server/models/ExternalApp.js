const mongoose = require('mongoose');

const ExternalAppSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true
  },
  description: {
    type: String,
    required: true
  },
  enabled: {
    type: Boolean,
    default: true
  },
  icon: {
    type: String,
    default: 'apps'
  },
  menuTitle: {
    type: String,
    required: true
  },
  route: {
    type: String,
    required: true,
    unique: true
  },
  componentPath: {
    type: String,
    required: true
  },
  permissions: {
    type: [String],
    default: []
  },
  config: {
    type: Object,
    default: {}
  },
  version: {
    type: String,
    default: '1.0.0'
  },
  author: {
    type: String
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Character'
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('ExternalApp', ExternalAppSchema);