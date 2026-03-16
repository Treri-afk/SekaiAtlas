const express = require('express');
const router = express.Router();
const db = require("../database/db");
// GET /badges/user?user_id=6 — tous les badges d'un utilisateur
router.get('/user', (req, res) => {
  const { user_id } = req.query;

  const sql = `
    SELECT ub.*, p.name, p.badge_name, p.badge_description, p.category, p.rarity
    FROM user_badges ub
    JOIN poi p ON p.id = ub.poi_id
    WHERE ub.user_id = ?
    ORDER BY ub.unlocked_at DESC
  `;

  db.query(sql, [user_id], (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(results);
  });
});

// POST /badges — crée un badge si pas déjà débloqué
router.post('/', (req, res) => {
  const { user_id, poi_id } = req.body;

  if (!user_id || !poi_id) {
    return res.status(400).json({ error: 'user_id et poi_id requis' });
  }

  // Vérifie si le badge existe déjà
  db.query(
    'SELECT id FROM user_badges WHERE user_id = ? AND poi_id = ?',
    [user_id, poi_id],
    (err, results) => {
      if (err) return res.status(500).json({ message: err.message });

      if (results.length > 0) {
        return res.json({ success: true, already_unlocked: true });
      }

      db.query(
        'INSERT INTO user_badges (user_id, poi_id) VALUES (?, ?)',
        [user_id, poi_id],
        (err, insertResults) => {
          if (err) return res.status(500).json({ message: err.message });
          res.json({ success: true, already_unlocked: false, id: insertResults.insertId });
        }
      );
    }
  );
});


module.exports = router;