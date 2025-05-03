// Add this as a new tab in the AdminPage.js file

// Add a new tab icon/label in the Tabs component:
<Tab icon={<WorkIcon />} label="Background Tasks" />

// Add this to the imports at the top
import WorkIcon from '@mui/icons-material/Work';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import RestartAltIcon from '@mui/icons-material/RestartAlt';

// Add this new state
const [workers, setWorkers] = useState({
  running: false,
  workers: []
});

// Add this to loadAdminData()
const workersResponse = await api.get('/api/admin/workers');
setWorkers(workersResponse.data);

// Add this handler
const handleRunWorkerTask = async (task) => {
  try {
    setMessage({
      text: `Running task: ${task}...`,
      type: 'info'
    });
    
    await api.post(`/api/admin/workers/${task}/run`);
    
    setMessage({
      text: `Task ${task} completed successfully`,
      type: 'success'
    });
  } catch (error) {
    console.error(`Failed to run task ${task}:`, error);
    setMessage({
      text: `Failed to run task ${task}`,
      type: 'error'
    });
  }
};

// Add this handler
const handleRestartWorkers = async () => {
  try {
    setMessage({
      text: 'Restarting background workers...',
      type: 'info'
    });
    
    await api.post('/api/admin/workers/restart');
    
    // Refresh worker status
    const workersResponse = await api.get('/api/admin/workers');
    setWorkers(workersResponse.data);
    
    setMessage({
      text: 'Background workers restarted successfully',
      type: 'success'
    });
  } catch (error) {
    console.error('Failed to restart workers:', error);
    setMessage({
      text: 'Failed to restart background workers',
      type: 'error'
    });
  }
};

// Add this new tab content
{tab === 4 && (
  <Box>
    <Typography variant="h6" sx={{ mb: 2 }}>Background Tasks</Typography>
    <Typography variant="body2" sx={{ mb: 4 }}>
      Manage automatic background tasks and scheduled processes.
    </Typography>
    
    <Paper sx={{ p: 2, mb: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="subtitle1">Worker Status</Typography>
        <Button 
          variant="outlined" 
          color="primary" 
          startIcon={<RestartAltIcon />}
          onClick={handleRestartWorkers}
        >
          Restart All Workers
        </Button>
      </Box>
      <Box sx={{ ml: 2 }}>
        <Typography variant="body2" sx={{ mb: 1 }}>
          Status: <Chip 
            color={workers.running ? "success" : "error"} 
            label={workers.running ? "Running" : "Stopped"} 
            size="small" 
          />
        </Typography>
        <Typography variant="body2" sx={{ mb: 1 }}>
          Active Workers:
        </Typography>
        <List dense>
          {workers.workers.map((worker, index) => (
            <ListItem key={index}>
              <ListItemIcon>
                <WorkIcon fontSize="small" />
              </ListItemIcon>
              <ListItemText primary={worker} />
            </ListItem>
          ))}
        </List>
      </Box>
    </Paper>
    
    <Typography variant="subtitle1" sx={{ mb: 2 }}>Run Tasks Manually</Typography>
    
    <Grid container spacing={2}>
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Typography variant="h6">Refresh Character Data</Typography>
            <Typography variant="body2" sx={{ mb: 2, color: 'text.secondary' }}>
              Update all character information from EVE ESI
            </Typography>
          </CardContent>
          <CardActions>
            <Button 
              startIcon={<PlayArrowIcon />} 
              size="small" 
              onClick={() => handleRunWorkerTask('refresh-data')}
            >
              Run Now
            </Button>
          </CardActions>
        </Card>
      </Grid>
      
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Typography variant="h6">Refresh Tokens</Typography>
            <Typography variant="body2" sx={{ mb: 2, color: 'text.secondary' }}>
              Update EVE SSO authentication tokens
            </Typography>
          </CardContent>
          <CardActions>
            <Button 
              startIcon={<PlayArrowIcon />} 
              size="small" 
              onClick={() => handleRunWorkerTask('refresh-tokens')}
            >
              Run Now
            </Button>
          </CardActions>
        </Card>
      </Grid>
      
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Typography variant="h6">Database Maintenance</Typography>
            <Typography variant="body2" sx={{ mb: 2, color: 'text.secondary' }}>
              Clean up and optimize database
            </Typography>
          </CardContent>
          <CardActions>
            <Button 
              startIcon={<PlayArrowIcon />} 
              size="small" 
              onClick={() => handleRunWorkerTask('db-maintenance')}
            >
              Run Now
            </Button>
          </CardActions>
        </Card>
      </Grid>
      
      <Grid item xs={12} sm={6} md={3}>
        <Card>
          <CardContent>
            <Typography variant="h6">Create Backup</Typography>
            <Typography variant="body2" sx={{ mb: 2, color: 'text.secondary' }}>
              Create a database backup immediately
            </Typography>
          </CardContent>
          <CardActions>
            <Button 
              startIcon={<PlayArrowIcon />} 
              size="small" 
              onClick={() => handleRunWorkerTask('backup')}
            >
              Run Now
            </Button>
          </CardActions>
        </Card>
      </Grid>
    </Grid>
  </Box>
)}