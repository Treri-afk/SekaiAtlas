const express = require('express');
const router  = express.Router();
const db      = require('../database/db');
const crypto  = require('crypto');

// ─────────────────────────────────────────────
//  HELPER — génère un code ami unique (6 cars, ex: "A3K9ZX")
// ─────────────────────────────────────────────
const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans 0/O/I/1 pour lisibilité

function generateCode(length = 6) {
  let code = '';
  const bytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    code += CHARS[bytes[i] % CHARS.length];
  }
  return code;
}

async function generateUniqueFriendCode() {
  return new Promise((resolve, reject) => {
    const tryGenerate = () => {
      const code = generateCode(6);
      db.query(
        'SELECT id FROM users WHERE friend_code = ?',
        [code],
        (err, results) => {
          if (err) return reject(err);
          if (results.length === 0) return resolve(code); // code libre
          tryGenerate(); // collision — réessaye
        }
      );
    };
    tryGenerate();
  });
}

// ─────────────────────────────────────────────
//  GET /users/id?user_id=
// ─────────────────────────────────────────────
router.get('/id', (req, res) => {
  const { user_id } = req.query;
  db.query('SELECT * FROM users WHERE id = ?', [user_id], (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    if (results.length === 0) return res.status(404).json({ message: 'Utilisateur non trouvé' });
    res.json(results[0]);
  });
});

// ─────────────────────────────────────────────
//  GET /users/provider?provider_id=
// ─────────────────────────────────────────────
router.get('/provider', (req, res) => {
  const { provider_id } = req.query;
  db.query('SELECT * FROM users WHERE provider_id = ?', [provider_id], (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    if (results.length === 0) return res.status(404).json({ message: 'Utilisateur non trouvé' });
    res.json(results[0]);
  });
});

// ─────────────────────────────────────────────
//  POST /users — crée un utilisateur ou le retourne s'il existe déjà
// ─────────────────────────────────────────────
router.post('/', async (req, res) => {
  const { username, avatar_url, provider, provider_id } = req.body;

  if (!username || !provider || !provider_id) {
    return res.status(400).json({ error: 'username, provider et provider_id sont requis' });
  }

  try {
    // ── 1. Vérifie si le compte existe déjà ──
    const existing = await new Promise((resolve, reject) => {
      db.query(
        'SELECT * FROM users WHERE provider_id = ?',
        [provider_id],
        (err, results) => err ? reject(err) : resolve(results)
      );
    });

    if (existing.length > 0) {
      // Compte déjà créé — retourne simplement l'utilisateur existant
      return res.status(200).json(existing[0]);
    }

    // ── 2. Nouveau compte — génère un code ami unique ──
    const friendCode = await generateUniqueFriendCode();

    // ── 3. Insère l'utilisateur avec son code ami ──
    const result = await new Promise((resolve, reject) => {
      db.query(
        `INSERT INTO users (username, avatar_url, provider, provider_id, friend_code, created_at)
         VALUES (?, ?, ?, ?, ?, NOW())`,
        [username, avatar_url ?? '', provider, provider_id, friendCode],
        (err, r) => err ? reject(err) : resolve(r)
      );
    });

    const newUser = await new Promise((resolve, reject) => {
      db.query(
        'SELECT * FROM users WHERE id = ?',
        [result.insertId],
        (err, rows) => err ? reject(err) : resolve(rows[0])
      );
    });

    return res.status(201).json(newUser);

  } catch (err) {
    console.error('[POST /users]', err);
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;