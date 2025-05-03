This guide explains how to customize the appearance and styling of your EVE Online Character Tracker installation. The application supports extensive theming through custom CSS.

Method 1: Admin Dashboard (Recommended)

Log in as an administrator
Navigate to the Admin Dashboard
Select the "Theme Customization" tab
Edit the CSS in the provided code editor
Click "Save and Apply" to update the theme immediately
Method 2: Direct File Edit

Locate the file at client/public/custom.css in your installation directory
Edit the file using any text editor
Save the file
Restart the frontend container or refresh your browser
bash
docker-compose restart frontend
Basic Customization
Changing Colors
The simplest customization is changing the color scheme:

CSS
/* Main colors */
:root {
  --primary-color: #1a237e;    /* Deep blue */
  --secondary-color: #ff4081;  /* Pink accent */
  --background-dark: #121212;  /* Dark background */
  --background-light: #f5f5f5; /* Light background */
  --text-light: #ffffff;       /* White text */
  --text-dark: #212121;        /* Dark text */
}
Changing Fonts
You can change the default font:

CSS
body {
  font-family: 'Roboto', sans-serif;
}

h1, h2, h3, h4, h5, h6 {
  font-family: 'Orbitron', sans-serif; /* Sci-fi style headers */
}
Note: If using custom web fonts, you'll need to include them in your HTML or use web-available fonts.

CSS Variables
The application uses CSS variables (custom properties) for consistent theming. Modify these variables to change multiple elements at once:

CSS
:root {
  /* Colors */
  --primary-color: #1a237e;
  --secondary-color: #ff4081;
  --background-dark: #121212;
  --background-light: #f5f5f5;
  --text-light: #ffffff;
  --text-dark: #212121;
  
  /* Layout */
  --header-height: 64px;
  --sidebar-width: 250px;
  --card-border-radius: 8px;
  
  /* Effects */
  --card-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}
Custom Images
Background Images
You can set a custom background for the entire application:

CSS
body {
  background-image: url('https://images.eveonline.com/Corporation/98000001_1024.png');
  background-size: cover;
  background-attachment: fixed;
  background-position: center;
  background-repeat: no-repeat;
}
Local Images
To use local images:

Place your images in the client/public/images/ directory
Reference them in your CSS:
CSS
.header-logo {
  background-image: url('/images/my-corporation-logo.png');
}
EVE Online Images
You can use EVE Online's image server for official assets:

CSS
/* Character portraits */
.character-portrait-large {
  background-image: url('https://images.evetech.net/characters/[CHARACTER_ID]/portrait?size=256');
}

/* Corporation logos */
.corporation-logo {
  background-image: url('https://images.evetech.net/corporations/[CORPORATION_ID]/logo?size=128');
}

/* Alliance logos */
.alliance-logo {
  background-image: url('https://images.evetech.net/alliances/[ALLIANCE_ID]/logo?size=128');
}

/* Ship/item thumbnails */
.ship-thumbnail {
  background-image: url('https://images.evetech.net/types/[TYPE_ID]/icon?size=64');
}
Replace [CHARACTER_ID], [CORPORATION_ID], etc. with the actual IDs.

Component Specific Styling
Header
CSS
.MuiAppBar-root {
  background-color: var(--primary-color);
  height: var(--header-height);
}

.MuiToolbar-root {
  display: flex;
  justify-content: space-between;
}

.app-title {
  font-weight: bold;
  letter-spacing: 1px;
}
Sidebar
CSS
.sidebar {
  width: var(--sidebar-width);
  background: linear-gradient(to bottom, var(--primary-color), #303f9f);
  color: var(--text-light);
}

.sidebar-item {
  padding: 12px 24px;
  border-left: 3px solid transparent;
}

.sidebar-item.active {
  border-left: 3px solid var(--secondary-color);
  background-color: rgba(255, 255, 255, 0.1);
}
Cards
CSS
.MuiCard-root {
  border-radius: var(--card-border-radius);
  overflow: hidden;
  box-shadow: var(--card-shadow);
  transition: transform 0.2s, box-shadow 0.2s;
}

.MuiCard-root:hover {
  transform: translateY(-3px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
}
Tables
CSS
.MuiTable-root {
  background-color: rgba(10, 20, 30, 0.8);
  color: #e0e0e0;
}

.MuiTableHead-root {
  background-color: rgba(26, 35, 126, 0.7);
}

.MuiTableRow-root:nth-of-type(odd) {
  background-color: rgba(30, 40, 50, 0.4);
}
Responsive Design
Ensure your UI works on different screen sizes:

CSS
/* For tablets */
@media (max-width: 960px) {
  :root {
    --sidebar-width: 200px;
  }
  
  .dashboard-grid {
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  }
}

/* For mobile phones */
@media (max-width: 600px) {
  :root {
    --header-height: 56px;
    --sidebar-width: 0;
  }
  
  .sidebar {
    position: fixed;
    z-index: 1000;
    transform: translateX(-100%);
    transition: transform 0.3s ease;
  }
  
  .sidebar.open {
    transform: translateX(0);
    width: 240px;
  }
  
  .mobile-menu-button {
    display: block;
  }
}
Advanced Techniques
Glass Morphism Effect
Create modern frosted glass effects:

CSS
.glass-card {
  background-color: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}
Data-driven Styling
Use data attributes to apply different styles conditionally:

CSS
/* Apply different styles based on faction */
.faction-card[data-faction="amarr"] {
  background-image: url('https://images.eveonline.com/Alliance/500003_64.png');
  border-color: #FFD700;
}

.faction-card[data-faction="caldari"] {
  background-image: url('https://images.eveonline.com/Alliance/500001_64.png');
  border-color: #4682B4;
}

/* Apply styles based on security status */
.system-security[data-security="high"] {
  color: #2E8B57;
}

.system-security[data-security="low"] {
  color: #FF8C00;
}

.system-security[data-security="null"] {
  color: #FF4500;
}
Custom Animations
Add animations for more dynamic interfaces:

CSS
/* Pulse effect for notifications */
@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
}

.notification-badge {
  animation: pulse 1.5s infinite;
}

/* Fade in elements */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.dashboard-card {
  animation: fadeIn 0.3s ease-out;
}
Example Themes
Dark EVE Theme
CSS
:root {
  --primary-color: #1a1a2e;
  --secondary-color: #0f3460;
  --accent-color: #e94560;
  --background-dark: #0a0a0e;
  --background-light: #16213e;
  --text-light: #e7e7e7;
  --text-dark: #b0b0b0;
}

body {
  background-color: var(--background-dark);
  color: var(--text-light);
  font-family: 'Roboto', sans-serif;
}

.MuiAppBar-root {
  background-color: var(--primary-color) !important;
}

.MuiDrawer-paper {
  background-color: var(--background-light);
}

.MuiCard-root {
  background-color: var(--background-light);
  color: var(--text-light);
  border-left: 3px solid var(--accent-color);
}

.MuiButton-containedPrimary {
  background-color: var(--accent-color) !important;
}

Corporation-branded Theme
CSS
:root {
  --corp-primary: #1C2331;
  --corp-secondary: #3F51B5;
  --corp-accent: #00C851;
  --corp-dark: #0e1318;
  --corp-light: #e0e0e0;
}

body {
  background-image: url('/images/corporation-background.jpg');
  background-size: cover;
  background-attachment: fixed;
}

.MuiAppBar-root {
  background-color: var(--corp-primary) !important;
}

.app-logo {
  background-image: url('/images/corp-logo.png');
  width: 40px;
  height: 40px;
  background-size: contain;
  margin-right: 15px;
}

.MuiCard-root {
  border-top: 4px solid var(--corp-accent);
}

.dashboard-header {
  color: var(--corp-accent);
  text-transform: uppercase;
  letter-spacing: 2px;
  text-shadow: 0 2px 4px rgba(0,0,0,0.5);
}

Troubleshooting
CSS Not Applying
If your custom CSS isn't applying correctly:

Check that the file path is correct
Verify the CSS syntax for errors
Try using the browser's developer tools to inspect elements and check for style conflicts
Add !important to override stubborn styles:
CSS
.dashboard {
  background-color: blue !important;
}
Responsive Issues
If your layout breaks on mobile:

Test on different screen sizes using browser developer tools
Ensure you have appropriate media queries
Use flexible units (%, rem, em) instead of fixed units (px) where appropriate
Images Not Displaying
If custom images aren't showing:

Check that the file path is correct
Verify that the image file exists and is accessible
Check for CORS issues if using external images
Common Element Selectors
Here's a quick reference of common element selectors in the application:

.app-container - Main application wrapper
.MuiAppBar-root - Top navigation bar
.sidebar - Navigation sidebar
.MuiCard-root - Card components
.MuiButton-root - Buttons
.MuiTable-root - Tables
.dashboard-widget - Dashboard widgets
.character-profile - Character profile sections
.eve-data-display - EVE data display sections
Additional Resources
If you need help with CSS in general, these resources might be useful:

MDN Web Docs CSS Reference
CSS-Tricks
W3Schools CSS Tutorial
For EVE Online specific design inspiration:

The official EVE Online website
The EVE Online Developer Portal
For further assistance with customizing your EVE Online Character Tracker, please visit the project's GitHub repository or contact support.