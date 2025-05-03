// Add these imports at the top of the AdminPage.js file
import { 
  // ...existing imports
  Select, 
  MenuItem, 
  InputLabel,
  FormControl,
  FormHelperText
} from '@mui/material';
import RefreshIcon from '@mui/icons-material/Refresh';

// Update the settings state in the AdminPage component
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

// Add a restart server handler
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
}

// Update the handleSaveSettings function to include all new fields
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