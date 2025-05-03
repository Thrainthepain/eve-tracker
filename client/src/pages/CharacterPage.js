import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';

// Material UI
import {
  Box,
  Grid,
  Paper,
  Typography,
  Button,
  Tabs,
  Tab,
  CircularProgress,
  Card,
  CardContent,
  CardHeader,
  List,
  ListItem,
  ListItemText,
  Divider,
  Avatar,
  Chip
} from '@mui/material';
import RefreshIcon from '@mui/icons-material/Refresh';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import InventoryIcon from '@mui/icons-material/Inventory';
import SchoolIcon from '@mui/icons-material/School';
import PeopleIcon from '@mui/icons-material/People';

// Custom components
import AssetsList from '../components/character/AssetsList';
import SkillsList from '../components/character/SkillsList';
import WalletTransactions from '../components/character/WalletTransactions';
import StandingsList from '../components/character/StandingsList';
import CharacterInfo from '../components/character/CharacterInfo';

const CharacterPage = () => {
  const { user, authenticated } = useAuth();
  const navigate = useNavigate();
  
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState(0);
  const [character, setCharacter] = useState(null);
  const [updating, setUpdating] = useState(false);
  
  useEffect(() => {
    if (!authenticated) {
      navigate('/');
    } else {
      loadCharacterData();
    }
  }, [authenticated]);
  
  const loadCharacterData = async () => {
    try {
      setLoading(true);
      const response = await api.get('/api/characters/me');
      setCharacter(response.data);
    } catch (error) {
      console.error('Failed to load character data:', error);
    } finally {
      setLoading(false);
    }
  };
  
  const handleTabChange = (event, newValue) => {
    setTab(newValue);
  };
  
  const handleRefresh = async () => {
    try {
      setUpdating(true);
      await api.get('/api/update/character');
      await loadCharacterData();
    } catch (error) {
      console.error('Failed to update character data:', error);
    } finally {
      setUpdating(false);
    }
  };
  
  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '80vh' }}>
        <CircularProgress />
      </Box>
    );
  }
  
  return (
    <Box sx={{ padding: 3 }}>
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
            <Typography variant="h4">Character Management</Typography>
            <Button 
              variant="contained" 
              color="primary" 
              startIcon={<RefreshIcon />}
              onClick={handleRefresh}
              disabled={updating}
            >
              {updating ? 'Updating...' : 'Refresh Data'}
            </Button>
          </Box>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <CharacterInfo character={character} />
        </Grid>
        
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 2 }}>
            <Tabs value={tab} onChange={handleTabChange} variant="fullWidth">
              <Tab icon={<AccountBalanceWalletIcon />} label="Wallet" />
              <Tab icon={<InventoryIcon />} label="Assets" />
              <Tab icon={<SchoolIcon />} label="Skills" />
              <Tab icon={<PeopleIcon />} label="Standings" />
            </Tabs>
            
            <Box sx={{ p: 2 }}>
              {tab === 0 && (
                <Box>
                  <Card sx={{ mb: 2 }}>
                    <CardHeader title="Wallet Balance" />
                    <CardContent>
                      <Typography variant="h4" color="primary">
                        {character.wallet?.balance?.toLocaleString()} ISK
                      </Typography>
                    </CardContent>
                  </Card>
                  <WalletTransactions transactions={character.wallet?.transactions || []} />
                </Box>
              )}
              
              {tab === 1 && (
                <AssetsList assets={character.assets || []} />
              )}
              
              {tab === 2 && (
                <SkillsList skills={character.skills || {}} />
              )}
              
              {tab === 3 && (
                <StandingsList standings={character.standings || []} />
              )}
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default CharacterPage;