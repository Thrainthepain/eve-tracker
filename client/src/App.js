import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import axios from 'axios';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import CircularProgress from '@mui/material/CircularProgress';
import Box from '@mui/material/Box';

// Components
import Header from './components/layout/Header';
import Sidebar from './components/layout/Sidebar';
import Footer from './components/layout/Footer';
import Dashboard from './pages/Dashboard';
import CharacterPage from './pages/CharacterPage';
import AdminPage from './pages/AdminPage';
import LoginPage from './pages/LoginPage';
import NotFoundPage from './pages/NotFoundPage';
import ExternalAppPage from './pages/ExternalAppPage';

// Context
import { AuthProvider } from './context/AuthContext';
import { ThemeProvider as CustomThemeProvider } from './context/ThemeContext';
import { ExternalAppsProvider } from './context/ExternalAppsContext';

// API
import api from './services/api';

const App = () => {
  const [loading, setLoading] = useState(true);
  const [externalApps, setExternalApps] = useState([]);
  
  useEffect(() => {
    // Load external apps
    const loadExternalApps = async () => {
      try {
        const response = await api.get('/api/external-apps');
        setExternalApps(response.data.filter(app => app.enabled));
      } catch (error) {
        console.error('Failed to load external apps:', error);
      } finally {
        setLoading(false);
      }
    };
    
    loadExternalApps();
  }, []);
  
  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        <CircularProgress />
      </Box>
    );
  }
  
  return (
    <CustomThemeProvider>
      <AuthProvider>
        <ExternalAppsProvider apps={externalApps}>
          <Router>
            <div className="app">
              <Header />
              <div className="main-container">
                <Sidebar />
                <main className="content">
                  <Routes>
                    <Route path="/" element={<LoginPage />} />
                    <Route path="/dashboard" element={<Dashboard />} />
                    <Route path="/character" element={<CharacterPage />} />
                    <Route path="/admin" element={<AdminPage />} />
                    {externalApps.map(app => (
                      <Route 
                        key={app._id} 
                        path={app.route} 
                        element={<ExternalAppPage app={app} />} 
                      />
                    ))}
                    <Route path="*" element={<NotFoundPage />} />
                  </Routes>
                </main>
              </div>
              <Footer />
            </div>
          </Router>
        </ExternalAppsProvider>
      </AuthProvider>
    </CustomThemeProvider>
  );
};

export default App;