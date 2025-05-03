// Replace the existing system settings tab with this updated version

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