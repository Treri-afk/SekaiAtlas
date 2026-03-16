const express = require('express');
const app     = express();
const port    = process.env.PORT || 3000;

// ── Sécurité de base ─────────────────────────
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));

// Désactive le header X-Powered-By (cache la techno)
app.disable('x-powered-by');

// ── Routes ───────────────────────────────────
app.use('/users',   require('./routes/users'));
app.use('/friends', require('./routes/friends'));
app.use('/aventure',require('./routes/aventure'));
app.use('/photos',  require('./routes/photos'));
app.use('/poi',     require('./routes/poi'));
app.use('/badges',  require('./routes/badges'));

// ── Health check ─────────────────────────────
app.get('/', (_, res) => res.json({ status: 'ok' }));

// ── Erreur 404 globale ────────────────────────
app.use((_, res) => res.status(404).json({ error: 'Route introuvable' }));

// ── Erreur 500 globale ────────────────────────
app.use((err, _req, res, _next) => {
  console.error('[server]', err);
  res.status(500).json({ error: 'Erreur interne du serveur' });
});

app.listen(port, () => console.log(`✓ API en écoute sur le port ${port}`));