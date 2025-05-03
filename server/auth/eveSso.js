// In the existing eveSso.js file, update the OAuth2Strategy setup to include developerEmail
// This would be in the initialize function where the OAuth2Strategy is configured

passport.use('evesso', new OAuth2Strategy({
  authorizationURL: 'https://login.eveonline.com/v2/oauth/authorize',
  tokenURL: 'https://login.eveonline.com/v2/oauth/token',
  clientID: config.eveClientId,
  clientSecret: config.eveClientSecret,
  callbackURL: `${config.serverUrl}/api/auth/callback`,
  // Adding developer email to OAuth configuration
  developerEmail: config.devEmail, 
  scope: [
    'publicData', 
    'esi-wallet.read_character_wallet.v1',
    'esi-characters.read_standings.v1',
    'esi-skills.read_skills.v1',
    'esi-assets.read_assets.v1',
    'esi-corporations.read_corporation_membership.v1'
    // Add more scopes as needed
  ].join(' ')
}, async (accessToken, refreshToken, params, profile, done) => {
  // ... rest of the function remains the same