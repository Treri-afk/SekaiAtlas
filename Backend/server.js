require('dotenv').config({ path: '../.env' });
const express = require('express');
const { createClient } = require('@supabase/supabase-js');

const app  = express();
const port = process.env.PORT || 3000;

// ── Supabase ─────────────────────────
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.ANON_KEY
);

// rend supabase accessible dans les routes
app.use((req, res, next) => {
  req.supabase = supabase;
  next();
});

// ── Sécurité de base ─────────────────
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));

// Désactive le header X-Powered-By
app.disable('x-powered-by');

// ── Routes ───────────────────────────
app.use('/users',   require('./routes/users'));
app.use('/friends', require('./routes/friends'));
app.use('/adventures', require('./routes/adventures'));
app.use('/photos',  require('./routes/photos'));
app.use('/poi',     require('./routes/poi'));
app.use('/badges',  require('./routes/badges'));

// ── Health check ─────────────────────
app.get('/', (_, res) => res.json({ status: 'ok' }));

// ── 404 ──────────────────────────────
app.use((_, res) => res.status(404).json({ error: 'Route introuvable' }));

// ── 500 ──────────────────────────────
app.use((err, _req, res, _next) => {
  console.error('[server]', err);
  res.status(500).json({ error: 'Erreur interne du serveur' });
});

// ── Start ────────────────────────────
app.listen(port, () => console.log(`✓ API en écoute sur le port ${port}`));