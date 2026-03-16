const express = require('express');
const router  = express.Router();
const db      = require('../database/db');

// GET /badges/user?user_id=
router.get('/user', (req, res) => {
  const user_id = parseInt(req.query.user_id);
  if (isNaN(user_id)) return res.status(400).json({ error: 'user_id invalide' });

  const sql = `
    SELECT ub.id, ub.unlocked_at,
      p.id AS poi_id, p.name, p.badge_name, p.badge_description, p.category, p.rarity
    FROM user_badges ub
    JOIN poi p ON p.id = ub.poi_id
    WHERE ub.user_id = ?
    ORDER BY ub.unlocked_at DESC
  `;

  db.query(sql, [user_id], (err, results) => {
    if (err) { console.error('[GET /badges/user]', err); return res.status(500).json({ error: 'Erreur serveur' }); }
    res.json(results);
  });
});

// POST /badges
router.post('/', (req, res) => {
  const user_id = parseInt(req.body.user_id);
  const poi_id  = parseInt(req.body.poi_id);

  if (isNaN(user_id) || isNaN(poi_id)) {
    return res.status(400).json({ error: 'user_id et poi_id doivent être des entiers valides' });
  }

  db.query(
    'SELECT id FROM user_badges WHERE user_id = ? AND poi_id = ?',
    [user_id, poi_id],
    (err, results) => {
      if (err) { console.error('[POST /badges] check', err); return res.status(500).json({ error: 'Erreur serveur' }); }
      if (results.length > 0) return res.json({ success: true, already_unlocked: true });

      db.query(
        'INSERT INTO user_badges (user_id, poi_id) VALUES (?, ?)',
        [user_id, poi_id],
        (err, r) => {
          if (err) { console.error('[POST /badges] insert', err); return res.status(500).json({ error: 'Erreur serveur' }); }
          res.json({ success: true, already_unlocked: false, id: r.insertId });
        }
      );
    }
  );
});

module.exports = router;