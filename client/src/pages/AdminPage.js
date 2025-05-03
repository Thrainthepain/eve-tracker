// This is a consolidated version of the AdminPage with all the necessary imports and state

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import api from '../services/api';

// Material UI
import {
  Box,
  Grid,
  Paper,
  Typography,
  Tabs,
  Tab,
  Button,
  TextField,
  Switch,
  FormControlLabel,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  CircularProgress,
  IconButton,
  Alert,
  Divider,
  Select,
  MenuItem,
  InputLabel,
  FormControl,
  FormHelperText
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import SaveIcon from '@mui/icons-material/Save';
import PersonIcon from '@mui/icons-material/Person';
import AppsIcon from '@mui/icons-material/Apps';
import BrushIcon from '@mui/icons-material/Brush';
import SettingsIcon from '@mui/icons-material/Settings';
import RefreshIcon from '@mui/icons-material/Refresh';

// CodeMirror for CSS editing
import { Controlled as CodeMirror } from 'react-codemirror2';
import 'codemirror/lib/codemirror.css';
import 'codemirror/theme/material.css';
import 'codemirror/mode/css/css';

const AdminPage = () => {
  const { user, authenticated } = useAuth();
  const { updateCustomCss } = useTheme();
  const navigate = useNavigate();
  
  const [tab, setTab] = useState(0);
  const [loading, setLoading] = useState(true);
  const [characters, setCharacters] = useState([]);
  const [externalApps, setExternalApps] = useState([]);
  const [cssCode, setCssCode] = useState('');
  const [newAppDialog, setNewAppDialog] = useState(false);
  const [newApp, setNewApp] = useState({
    name: '',
    description: '',
    menuTitle: '',
    route: '',
    componentPath: '',
    icon: 'apps'
  });
  const [message, setMessage] = useState({ text: '', type: '' });
  
  // Added settings state for system configuration
  const [settings, setSettings] = useState({
    devEmail: '',
    eveClientId: '',
    eveClientSecret: '',
    autoRefreshInterval: 30,
    websiteName: '',
    serverProtocol: 'http',
    serverDomain: 'localhost',
    serverSubdomain: '',
    sslMode: 'skip',
    letsencryptEmail: ''
  });
  
  useEffect(() => {
    if (!authenticated || !user?.isAdmin) {
      navigate('/dashboard');
    } else {
      loadAdminData();
    }
  }, [authenticated, user]);
  
  const loadAdminData = async () => {
    try {
      setLoading(true);
      
      // Load characters
      const charactersResponse = await api.get('/api/admin/characters');
      setCharacters(charactersResponse.data);
      
      // Load external apps
      const appsResponse = await api.get('/api/admin/external-apps');
      setExternalApps(appsResponse.data);
      
      // Load CSS theme
      const cssResponse = await api.get('/api/admin/theme/css');
      setCssCode(cssResponse.data.css || '/* Custom CSS Theme */\n\n');
      
      // Load system settings
      const settingsResponse = await api.get('/api/admin/settings');
      setSettings(settingsResponse.data);
    } catch (error) {
      console.error('Failed to load admin data:', error);
      setMessage({
        text: 'Failed to load admin data. Please try again.',
        type: 'error'
      });
    } finally {
      setLoading(false);
    }
  };
  
  const handleTabChange = (event, newValue) => {
    setTab(newValue);
  };
  
  const handleToggleAdmin = async (characterId) => {
    try {
      const character = characters.find(c => c._id === characterId);
      const response = await api.put(`/api/admin/characters/${characterId}/admin`, {
        isAdmin: !character.isAdmin
      });
      
      // Update character in state
      setCharacters(characters.map(c => 
        c._id === characterId ? { ...c, isAdmin: !c.isAdmin } : c
      ));
      
      setMessage({
        text: `Admin status updated for ${character.name}`,
        type: 'success'
      });
    } catch (error) {
      console.error('Failed to update admin status:', error);
      setMessage({
        text: 'Failed to update admin status. Please try again.',
        type: 'error'
      });
    }
  };
  
  const handleToggleApp = async (appId) => {
    try {
      const app = externalApps.find(a => a._id === appId);
      const response = await api.put(`/api/admin/external-apps/${appId}/toggle`);
      
      // Update app in state
      setExternalApps(externalApps.map(a => 
        a._id === appId ? { ...a, enabled: !a.enabled } : a
      ));
      
      setMessage({
        text: `${app.name} has been ${!app.enabled ? 'enabled' : 'disabled'}`,
        type: 'success'
      });
    } catch (error) {
      console.error('Failed to toggle app status:', error);
      setMessage({
        text: 'Failed to update app status. Please try again.',
        type: 'error'
      });
    }
  };
  
  const handleSaveCss = async () => {
    try {
      await api.post('/api/admin/theme/css', { css: cssCode });
      updateCustomCss(cssCode);
      
      setMessage({
        text: 'Custom CSS theme has been saved and applied',
        type: 'success'
      });
    } catch (error) {
      console.error('Failed to save CSS theme:', error);
      setMessage({
        text: 'Failed to save CSS theme. Please try again.',
        type: 'error'
      });
    }
  };
  
  const handleNewAppSubmit = async () => {
    try {
      const response = await api.post('/api/admin/external-apps', newApp);
      setExternalApps([...externalApps, response.data]);
      setNewAppDialog(false);
      setNewApp({
        name: '',
        description: '',
        menuTitle: '',
        route: '',
        componentPath: '',
        icon: 'apps'
      });
      
      setMessage({
        text: 'New external app has been added successfully',
        type: 'success'
      });
    } catch (error) {
      console.error('Failed to add external app:', error);
      setMessage({
        text: 'Failed to add external app. Please check your inputs and try again.',
        type: 'error'
      });
    }
  };
  
  const handleAppInputChange = (e) => {
    const { name, value } = e.target;
    setNewApp({ ...newApp, [name]: value });
  };
  
  // New handler for saving system settings
  const handleSaveSettings = async () => {
    try {
      await api.post('/api/admin/settings', settings);
      
      setMessage({
        text: 'System settings saved successfully. Changes will take effect after server restart.',
        type: 'success'
      });
    } catch (error) {
      console.error('Failed to save settings:', error);
      setMessage({
        text: 'Failed to save settings. Please try again.',
        type: 'error'
      });
    }
  };
  
  // New handler for server restart
  const handleRestartServer = async () => {
    try {
      setMessage({
        text: 'Sending restart signal to server...',
        type: 'info'
      });
      
      await api.post('/api/admin/restart-server');
      
      setMessage({
        text: 'Server is restarting. The page will refresh in 15 seconds.',
        type: 'success'
      });
      
      // Refresh the page after 15 seconds
      setTimeout(() => {
        window.location.reload();
      }, 15000);
    } catch (error) {
      console.error('Failed to restart server:', error);
      setMessage({
        text: 'Failed to restart server. Please try again or restart manually.',
        type: 'error'
      });
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
            <Typography variant="h4">Admin Dashboard</Typography>
          </Box>
          
          {message.text && (
            <Alert 
              severity={message.type} 
              sx={{ mb: 2 }}
              onClose={() => setMessage({ text: '', type: '' })}
            >
              {message.text}
            </Alert>
          )}
        </Grid>
        
        <Grid item xs={12}>
          <Paper sx={{ p: 2 }}>
            <Tabs value={tab} onChange={handleTabChange} variant="fullWidth">
              <Tab icon={<PersonIcon />} label="Characters" />
              <Tab icon={<AppsIcon />} label="External Apps" />
              <Tab icon={<BrushIcon />} label="Theme Customization" />
              <Tab icon={<SettingsIcon />} label="System Settings" />
            </Tabs>
            
            <Box sx={{ p: 2 }}>
              {tab === 0 && (
                <TableContainer>
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableCell>Character Name</TableCell>
                        <TableCell>Corporation</TableCell>
                        <TableCell>Last Login</TableCell>
                        <TableCell>Last Update</TableCell>
                        <TableCell>Admin</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {characters.map((character) => (
                        <TableRow key={character._id}>
                          <TableCell>{character.name}</TableCell>
                          <TableCell>{character.corporation_name || character.corporation_id}</TableCell>
                          <TableCell>{new Date(character.lastLogin).toLocaleString()}</TableCell>
                          <TableCell>{new Date(character.lastUpdate).toLocaleString()}</TableCell>
                          <TableCell>
                            <FormControlLabel
                              control={
                                <Switch
                                  checked={character.isAdmin}
                                  onChange={() => handleToggleAdmin(character._id)}
                                  color="primary"
                                />
                              }
                              label={character.isAdmin ? "Admin" : "User"}
                            />
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              )}
              
              {tab === 1 && (
                <Box>
                  <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
                    <Button 
                      variant="contained" 
                      color="primary" 
                      startIcon={<AddIcon />}
                      onClick={() => setNewAppDialog(true)}
                    >
                      Add External App
                    </Button>
                  </Box>
                  
                  <TableContainer>
                    <Table>
                      <TableHead>
                        <TableRow>
                          <TableCell>Name</TableCell>
                          <TableCell>Menu Title</TableCell>
                          <TableCell>Route</TableCell>
                          <TableCell>Status</TableCell>
                          <TableCell>Created By</TableCell>
                          <TableCell>Actions</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {externalApps.map((app) => (
                          <TableRow key={app._id}>
                            <TableCell>{app.name}</TableCell>
                            <TableCell>{app.menuTitle}</TableCell>
                            <TableCell>{app.route}</TableCell>
                            <TableCell>
                              <FormControlLabel
                                control={
                                  <Switch
                                    checked={app.enabled}
                                    onChange={() => handleToggleApp(app._id)}
                                    color="primary"
                                  />
                                }
                                label={app.enabled ? "Enabled" : "Disabled"}
                              />
                            </TableCell>
                            <TableCell>{app.createdBy?.name || 'System'}</TableCell>
                            <TableCell>
                              <IconButton color="primary">
                                <EditIcon />
                              </IconButton>
                              <IconButton color="error">
                                <DeleteIcon />
                              </IconButton>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </Box>
              )}
              
              {tab === 2 && (
                <Box>
                  <Typography variant="h6" sx={{ mb: 2 }}>Custom CSS Theme</Typography>
                  <Typography variant="body2" sx={{ mb: 2 }}>
                    Customize the appearance of the website by editing the CSS below.
                  </Typography>
                  
                  <Box sx={{ mb: 2, border: '1px solid #ddd' }}>
                    <CodeMirror
                      value={cssCode}
                      options={{
                        mode: 'css',
                        theme: 'material',
                        lineNumbers: true,
                        lineWrapping: true
                      }}
                      onBeforeChange={(editor, data, value) => {
                        setCssCode(value);
                      }}
                    />
                  </Box>
                  
                  <Button 
                    variant="contained" 
                    color="primary" 
                    startIcon={<SaveIcon />}
                    onClick={handleSaveCss}
                  >
                    Save and Apply
                  </Button>
                </Box>
              )}
              
              {tab === 3 && (
                <Box>
                  <Typography variant="h6" sx={{ mb: 2 }}>System Settings</Typography>
                  <Typography variant="body2" sx={{ mb: 4 }}>
                    Configure system-wide settings for the EVE Online Character Tracker.
                  </Typography>
                  
                  <Grid container spacing={3}>
                    <Grid item xs={12}>
                      <Typography variant="subtitle1" sx={{ mb: 1 }}>General Settings</Typography>
                      <Divider sx={{ mb: 2 }} />
                    </Grid>
                    
                    <Grid item xs={12} md={6}>
                      <TextField
                        label="Website Name"
                        fullWidth
                        value={settings.websiteName || ''}
                        onChange={(e) => setSettings({...settings, websiteName: e.target.value})}
                      />
                    </Grid>
                    
                    <Grid item xs={12} md={6}>
                      <TextField
                        label="Auto-Refresh Interval (minutes)"
                        type="number"
                        fullWidth
                        value={settings.autoRefreshInterval || 30}
                        onChange={(e) => setSettings({...settings, autoRefreshInterval: e.target.value})}
                      />
                    </Grid>
                    
                    <Grid item xs={12}>
                      <Typography variant="subtitle1" sx={{ mb: 1, mt: 2 }}>Server Configuration</Typography>
                      <Divider sx={{ mb: 2 }} />
                    </Grid>
                    
                    <Grid item xs={12} md={4}>
                      <FormControl fullWidth>
                        <InputLabel id="protocol-select-label">Protocol</InputLabel>
                        <Select
                          labelId="protocol-select-label"
                          value={settings.serverProtocol || 'http'}
                          label="Protocol"
                          onChange={(e) => setSettings({...settings, serverProtocol: e.target.value})}
                        >
                          <MenuItem value="http">HTTP</MenuItem>
                          <MenuItem value="https">HTTPS</MenuItem>
                        </Select>
                        <FormHelperText>
                          {settings.serverProtocol === 'https' ? 'SSL certificate required' : 'No encryption'}
                        </FormHelperText>
                      </FormControl>
                    </Grid>
                    
                    <Grid item xs={12} md={4}>
                      <TextField
                        label="Domain"
                        fullWidth
                        value={settings.serverDomain || ''}
                        onChange={(e) => setSettings({...settings, serverDomain: e.target.value})}
                        helperText="e.g., example.com"
                      />
                    </Grid>
                    
                    <Grid item xs={12} md={4}>
                      <TextField
                        label="Subdomain (optional)"
                        fullWidth
                        value={settings.serverSubdomain || ''}
                        onChange={(e) => setSettings({...settings, serverSubdomain: e.target.value})}
                        helperText="e.g., eve for eve.example.com"
                      />
                    </Grid>

                    <Grid item xs={12}>
                      <Box sx={{ p: 2, bgcolor: 'background.paper', borderRadius: 1 }}>
                        <Typography variant="body2">
                          Full URL: <strong>{settings.serverProtocol || 'http'}://{settings.serverSubdomain ? `${settings.serverSubdomain}.` : ''}{settings.serverDomain || 'localhost'}</strong>
                        </Typography>
                      </Box>
                    </Grid>
                    
                    <Grid item xs={12}>
                      <Typography variant="subtitle1" sx={{ mb: 1, mt: 2 }}>EVE Developer Information</Typography>
                      <Divider sx={{ mb: 2 }} />
                    </Grid>
                    
                    <Grid item xs={12} md={6}>
                      <TextField
                        label="Developer Email (EVE API Contact)"
                        fullWidth
                        type="email"
                        value={settings?.devEmail || ''}
                        onChange={(e) => setSettings({...settings, devEmail: e.target.value})}
                        helperText="Email address registered with the EVE Developer Portal"
                        required
                      />
                    </Grid>
                    
                    <Grid item xs={12} md={6}>
                      <TextField
                        label="EVE ESI Callback URL"
                        fullWidth
                        value={`${settings.serverProtocol || 'http'}://${settings.serverSubdomain ? `${settings.serverSubdomain}.` : ''}${settings.serverDomain || 'localhost'}/api/auth/callback`}
                        disabled
                        helperText="Use this URL in your EVE Developer Portal"
                      />
                    </Grid>
                    
                    <Grid item xs={12} md={6}>
                      <TextField
                        label="EVE ESI Client ID"
                        fullWidth
                        value={settings?.eveClientId || ''}
                        onChange={(e) => setSettings({...settings, eveClientId: e.target.value})}
                      />
                    </Grid>
                    
                    <Grid item xs={12} md={6}>
                      <TextField
                        label="EVE ESI Client Secret"
                        fullWidth
                        type="password"
                        value={settings?.eveClientSecret || ''}
                        onChange={(e) => setSettings({...settings, eveClientSecret: e.target.value})}
                      />
                    </Grid>
                    
                    {settings.serverProtocol === 'https' && (
                      <>
                        <Grid item xs={12}>
                          <Typography variant="subtitle1" sx={{ mb: 1, mt: 2 }}>SSL Configuration</Typography>
                          <Divider sx={{ mb: 2 }} />
                        </Grid>
                        
                        <Grid item xs={12} md={6}>
                          <FormControl fullWidth>
                            <InputLabel id="ssl-mode-label">SSL Mode</InputLabel>
                            <Select
                              labelId="ssl-mode-label"
                              value={settings.sslMode || 'skip'}
                              label="SSL Mode"
                              onChange={(e) => setSettings({...settings, sslMode: e.target.value})}
                            >
                              <MenuItem value="letsencrypt">Let's Encrypt (Automatic)</MenuItem>
                              <MenuItem value="custom">Custom Certificates</MenuItem>
                              <MenuItem value="skip">Skip Configuration</MenuItem>
                            </Select>
                          </FormControl>
                        </Grid>
                        
                        {settings.sslMode === 'letsencrypt' && (
                          <Grid item xs={12} md={6}>
                            <TextField
                              label="Email for Let's Encrypt"
                              fullWidth
                              type="email"
                              value={settings?.letsencryptEmail || ''}
                              onChange={(e) => setSettings({...settings, letsencryptEmail: e.target.value})}
                              required
                            />
                          </Grid>
                        )}
                      </>
                    )}
                    
                    <Grid item xs={12}>
                      <Button 
                        variant="contained" 
                        color="primary" 
                        startIcon={<SaveIcon />}
                        onClick={handleSaveSettings}
                      >
                        Save Settings
                      </Button>
                      
                      <Button 
                        variant="outlined" 
                        color="secondary" 
                        startIcon={<RefreshIcon />}
                        onClick={handleRestartServer}
                        sx={{ ml: 2 }}
                      >
                        Apply Changes (Restart Server)
                      </Button>
                    </Grid>
                  </Grid>
                </Box>
              )}
            </Box>
          </Paper>
        </Grid>
      </Grid>
      
      {/* New App Dialog */}
      <Dialog open={newAppDialog} onClose={() => setNewAppDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>Add External App</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} md={6}>
              <TextField
                name="name"
                label="App Name"
                fullWidth
                required
                value={newApp.name}
                onChange={handleAppInputChange}
              />
            </Grid>
            
            <Grid item xs={12} md={6}>
              <TextField
                name="menuTitle"
                label="Menu Title"
                fullWidth
                required
                value={newApp.menuTitle}
                onChange={handleAppInputChange}
              />
            </Grid>
            
            <Grid item xs={12}>
              <TextField
                name="description"
                label="Description"
                fullWidth
                multiline
                rows={2}
                value={newApp.description}
                onChange={handleAppInputChange}
              />
            </Grid>
            
            <Grid item xs={12} md={6}>
              <TextField
                name="route"
                label="Route Path"
                fullWidth
                required
                value={newApp.route}
                onChange={handleAppInputChange}
                helperText="Example: /external/myapp"
              />
            </Grid>
            
            <Grid item xs={12} md={6}>
              <TextField
                name="icon"
                label="Icon Name"
                fullWidth
                value={newApp.icon}
                onChange={handleAppInputChange}
                helperText="Material icon name (default: apps)"
              />
            </Grid>
            
            <Grid item xs={12}>
              <TextField
                name="componentPath"
                label="Component Path"
                fullWidth
                required
                value={newApp.componentPath}
                onChange={handleAppInputChange}
                helperText="Path to the component file relative to /external-apps"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewAppDialog(false)}>Cancel</Button>
          <Button 
            onClick={handleNewAppSubmit} 
            variant="contained" 
            color="primary"
            disabled={!newApp.name || !newApp.menuTitle || !newApp.route || !newApp.componentPath}
          >
            Add App
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default AdminPage;