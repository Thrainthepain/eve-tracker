import React from 'react';
import { Link as RouterLink } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useTheme } from '../../context/ThemeContext';
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  Box,
  IconButton,
  Menu,
  MenuItem,
  Avatar,
  Divider
} from '@mui/material';
import { Brightness4, Brightness7, AccountCircle } from '@mui/icons-material';
import api from '../../services/api';

const Header = () => {
  const { user, authenticated, logout } = useAuth();
  const { darkMode, toggleTheme } = useTheme();
  const [anchorEl, setAnchorEl] = React.useState(null);
  const [websiteName, setWebsiteName] = React.useState('EVE Character Tracker');
  
  React.useEffect(() => {
    // Fetch website configuration
    const fetchConfig = async () => {
      try {
        const response = await api.get('/api/config');
        if (response.data.websiteName) {
          setWebsiteName(response.data.websiteName);
        }
      } catch (error) {
        console.error('Failed to fetch site configuration', error);
      }
    };
    
    fetchConfig();
  }, []);

  const handleMenu = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = () => {
    handleClose();
    logout();
  };

  return (
    <AppBar position="static" color="primary">
      <Toolbar>
        <Typography 
          variant="h6" 
          component={RouterLink} 
          to={authenticated ? '/dashboard' : '/'} 
          sx={{ 
            flexGrow: 1, 
            textDecoration: 'none',
            color: 'inherit'
          }}
        >
          {websiteName}
        </Typography>
        
        {authenticated ? (
          <Box display="flex" alignItems="center">
            <IconButton 
              color="inherit" 
              onClick={toggleTheme} 
              sx={{ mr: 1 }}
            >
              {darkMode ? <Brightness7 /> : <Brightness4 />}
            </IconButton>
            
            <Button 
              color="inherit" 
              onClick={handleMenu}
              startIcon={
                <Avatar 
                  sx={{ width: 30, height: 30 }}
                  alt={user.name}
                  src={`https://images.evetech.net/characters/${user.characterId}/portrait?size=64`}
                />
              }
            >
              {user.name}
            </Button>
            <Menu
              anchorEl={anchorEl}
              open={Boolean(anchorEl)}
              onClose={handleClose}
            >
              <MenuItem component={RouterLink} to="/character" onClick={handleClose}>
                Character Profile
              </MenuItem>
              {user.isAdmin && (
                <MenuItem component={RouterLink} to="/admin" onClick={handleClose}>
                  Admin Panel
                </MenuItem>
              )}
              <Divider />
              <MenuItem onClick={handleLogout}>Logout</MenuItem>
            </Menu>
          </Box>
        ) : (
          <Box>
            <Button 
              color="inherit" 
              component={RouterLink} 
              to="/"
            >
              Login with EVE SSO
            </Button>
          </Box>
        )}
      </Toolbar>
    </AppBar>
  );
};

export default Header;