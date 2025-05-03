// Add these lines to the state declarations in AdminPage.js
const [settings, setSettings] = useState({
  devEmail: '',
  eveClientId: '',
  eveClientSecret: '',
  autoRefreshInterval: 30
});

// Add this to the loadAdminData function
const settingsResponse = await api.get('/api/admin/settings');
setSettings(settingsResponse.data);

// Add this handler function
const handleSaveSettings = async () => {
  try {
    await api.post('/api/admin/settings', settings);
    setMessage({
      text: 'System settings saved successfully',
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