const express = require('express');
const router  = express.Router();
const db      = require('../database/db');

// GET /friends/friend?user_id=
router.get('/friend', (req, res) => {
  const user_id = parseInt(req.query.user_id);
  if (isNaN(user_id)) return res.status(400).json({ error: 'user_id invalide' });

  const sql = `
    SELECT u.id, u.username, u.avatar_url, u.friend_code
    FROM users_friend f
    JOIN users u ON (u.id = f.user_id OR u.id = f.friend_id)
    WHERE ? IN (f.user_id, f.friend_id) AND u.id != ?
  `;

  db.query(sql, [user_id, user_id], (err, results) => {
    if (err) { console.error('[GET /friends/friend]', err); return res.status(500).json({ error: 'Erreur serveur' }); }
    res.json(results);
  });
});

// POST /friends
router.post('/', (req, res) => {
  const user_id     = parseInt(req.body.user_id);
  const friend_code = req.body.friend_code?.toString().trim().toUpperCase();

  if (isNaN(user_id) || !friend_code) {
    return res.status(400).json({ error: 'user_id et friend_code sont requis' });
  }
  if (!/^[A-Z0-9]{4,10}$/.test(friend_code)) {
    return res.status(400).json({ error: 'Format de code ami invalide' });
  }

  db.query('SELECT id FROM users WHERE friend_code = ?', [friend_code], (err, results) => {
    if (err) { console.error('[POST /friends] check code', err); return res.status(500).json({ error: 'Erreur serveur' }); }
    if (results.length === 0) return res.status(404).json({ error: 'Aucun utilisateur trouvé avec ce code ami' });

    const friend_id = results[0].id;

    if (friend_id === user_id) {
      return res.status(400).json({ error: 'Vous ne pouvez pas vous ajouter vous-même' });
    }

    db.query(
      'SELECT id FROM users_friend WHERE (user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)',
      [user_id, friend_id, friend_id, user_id],
      (err, existing) => {
        if (err) { console.error('[POST /friends] check existing', err); return res.status(500).json({ error: 'Erreur serveur' }); }
        if (existing.length > 0) return res.status(409).json({ error: 'Vous êtes déjà amis' });

        db.query(
          'INSERT INTO users_friend (user_id, friend_id, created_at) VALUES (?, ?, NOW())',
          [user_id, friend_id],
          (err) => {
            if (err) { console.error('[POST /friends] insert', err); return res.status(500).json({ error: 'Erreur serveur' }); }
            res.json({ success: true, friend_id });
          }
        );
      }
    );
  });
});

// GET /friends — admin uniquement, retiré en prod
// router.get('/', ...)

module.exports = router;