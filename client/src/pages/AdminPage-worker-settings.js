// Add this inside the System Settings tab of AdminPage.js
// Look for the existing Grid container in tab === 3

<Grid item xs={12}>
  <Typography variant="subtitle1" sx={{ mb: 1, mt: 2 }}>Background Task Settings</Typography>
  <Divider sx={{ mb: 2 }} />
</Grid>

<Grid item xs={12} md={4}>
  <TextField
    label="Data Refresh Interval (minutes)"
    type="number"
    fullWidth
    value={settings.dataRefreshInterval || 30}
    onChange={(e) => setSettings({...settings, dataRefreshInterval: e.target.value})}
    helperText="How often to refresh character data from EVE ESI"
  />
</Grid>

<Grid item xs={12} md={4}>
  <TextField
    label="Backup Retention (days)"
    type="number"
    fullWidth
    value={settings.backupRetentionDays || 7}
    onChange={(e) => setSettings({...settings, backupRetentionDays: e.target.value})}
    helperText="How many days to keep database backups"
  />
</Grid>

<Grid item xs={12} md={4}>
  <FormControl fullWidth>
    <InputLabel id="backup-time-label">Backup Time</InputLabel>
    <Select
      labelId="backup-time-label"
      value={settings.backupTime || '2:00'}
      label="Backup Time"
      onChange={(e) => setSettings({...settings, backupTime: e.target.value})}
    >
      <MenuItem value="0:00">12:00 AM (Midnight)</MenuItem>
      <MenuItem value="2:00">2:00 AM</MenuItem>
      <MenuItem value="4:00">4:00 AM</MenuItem>
      <MenuItem value="6:00">6:00 AM</MenuItem>
    </Select>
    <FormHelperText>When to run daily backups (UTC)</FormHelperText>
  </FormControl>
</Grid>