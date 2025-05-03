const axios = require('axios');
const Character = require('../models/Character');
const Corporation = require('../models/Corporation');
const eveSSO = require('../auth/eveSso');

class EveEsiService {
  constructor() {
    this.baseUrl = 'https://esi.evetech.net/latest';
    this.datasource = 'tranquility';
  }

  async getHeaders(characterId) {
    try {
      const character = await Character.findOne({ characterId });
      
      if (!character) {
        throw new Error('Character not found');
      }
      
      // Check token expiry and refresh if needed
      if (new Date() >= character.tokenExpiry) {
        const newToken = await eveSSO.refreshToken(characterId);
        return {
          'Authorization': `Bearer ${newToken}`,
          'Content-Type': 'application/json'
        };
      }
      
      return {
        'Authorization': `Bearer ${character.accessToken}`,
        'Content-Type': 'application/json'
      };
    } catch (error) {
      throw new Error(`Failed to get headers: ${error.message}`);
    }
  }

  async getServerStatus() {
    try {
      const response = await axios.get(`${this.baseUrl}/status/?datasource=${this.datasource}`);
      return response.data;
    } catch (error) {
      throw new Error(`Failed to get server status: ${error.message}`);
    }
  }

  async getCharacterInfo(characterId) {
    try {
      const response = await axios.get(`${this.baseUrl}/characters/${characterId}/?datasource=${this.datasource}`);
      return response.data;
    } catch (error) {
      throw new Error(`Failed to get character info: ${error.message}`);
    }
  }

  async getCharacterWallet(characterId) {
    try {
      const headers = await this.getHeaders(characterId);
      const response = await axios.get(
        `${this.baseUrl}/characters/${characterId}/wallet/?datasource=${this.datasource}`,
        { headers }
      );
      
      // Get wallet journal
      const journalResponse = await axios.get(
        `${this.baseUrl}/characters/${characterId}/wallet/journal/?datasource=${this.datasource}`,
        { headers }
      );
      
      // Save wallet data to character
      const character = await Character.findOne({ characterId });
      character.wallet = {
        balance: response.data,
        transactions: journalResponse.data.slice(0, 100) // Store last 100 transactions
      };
      character.lastUpdate = new Date();
      await character.save();
      
      return {
        balance: response.data,
        transactions: journalResponse.data
      };
    } catch (error) {
      throw new Error(`Failed to get character wallet: ${error.message}`);
    }
  }

  async getCharacterAssets(characterId) {
    try {
      const headers = await this.getHeaders(characterId);
      const response = await axios.get(
        `${this.baseUrl}/characters/${characterId}/assets/?datasource=${this.datasource}`,
        { headers }
      );
      
      // Save assets data to character
      const character = await Character.findOne({ characterId });
      character.assets = response.data;
      character.lastUpdate = new Date();
      await character.save();
      
      return response.data;
    } catch (error) {
      throw new Error(`Failed to get character assets: ${error.message}`);
    }
  }

  async getCharacterSkills(characterId) {
    try {
      const headers = await this.getHeaders(characterId);
      const response = await axios.get(
        `${this.baseUrl}/characters/${characterId}/skills/?datasource=${this.datasource}`,
        { headers }
      );
      
      // Save skills data to character
      const character = await Character.findOne({ characterId });
      character.skills = response.data;
      character.lastUpdate = new Date();
      await character.save();
      
      return response.data;
    } catch (error) {
      throw new Error(`Failed to get character skills: ${error.message}`);
    }
  }

  async getCharacterStandings(characterId) {
    try {
      const headers = await this.getHeaders(characterId);
      const response = await axios.get(
        `${this.baseUrl}/characters/${characterId}/standings/?datasource=${this.datasource}`,
        { headers }
      );
      
      // Save standings data to character
      const character = await Character.findOne({ characterId });
      character.standings = response.data;
      character.lastUpdate = new Date();
      await character.save();
      
      return response.data;
    } catch (error) {
      throw new Error(`Failed to get character standings: ${error.message}`);
    }
  }

  async getCorporationInfo(corporationId) {
    try {
      const response = await axios.get(`${this.baseUrl}/corporations/${corporationId}/?datasource=${this.datasource}`);
      
      // Update or create corporation in database
      let corporation = await Corporation.findOne({ corporationId });
      
      if (!corporation) {
        corporation = new Corporation({
          corporationId,
          name: response.data.name,
          ticker: response.data.ticker,
          alliance_id: response.data.alliance_id,
          member_count: response.data.member_count,
          tax_rate: response.data.tax_rate,
          ceo_id: response.data.ceo_id,
          description: response.data.description
        });
      } else {
        corporation.name = response.data.name;
        corporation.ticker = response.data.ticker;
        corporation.alliance_id = response.data.alliance_id;
        corporation.member_count = response.data.member_count;
        corporation.tax_rate = response.data.tax_rate;
        corporation.ceo_id = response.data.ceo_id;
        corporation.description = response.data.description;
        corporation.lastUpdate = new Date();
      }
      
      await corporation.save();
      
      return response.data;
    } catch (error) {
      throw new Error(`Failed to get corporation info: ${error.message}`);
    }
  }

  async updateCharacterData(characterId) {
    try {
      // Update all character data
      const walletData = await this.getCharacterWallet(characterId);
      const assetsData = await this.getCharacterAssets(characterId);
      const skillsData = await this.getCharacterSkills(characterId);
      const standingsData = await this.getCharacterStandings(characterId);
      
      // Get character for corporation info
      const character = await Character.findOne({ characterId });
      
      // Update corporation info
      await this.getCorporationInfo(character.corporation_id);
      
      return {
        wallet: walletData,
        assets: assetsData,
        skills: skillsData,
        standings: standingsData
      };
    } catch (error) {
      throw new Error(`Failed to update character data: ${error.message}`);
    }
  }
}

module.exports = new EveEsiService();