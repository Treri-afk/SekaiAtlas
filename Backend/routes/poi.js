const express = require('express');
const router  = express.Router();
const db      = require('../database/db');

// ── Helpers ───────────────────────────────────
const parseFloat2 = (v) => {
  const n = parseFloat(v);
  return isNaN(n) ? null : n;
};

// GET /poi
router.get('/', (_req, res) => {
  db.query(
    'SELECT id, name, description, latitude, longitude, prefecture_code, category, rarity, badge_name, badge_description, radius_meters FROM poi',
    (err, results) => {
      if (err) { console.error('[GET /poi]', err); return res.status(500).json({ error: 'Erreur serveur' }); }
      res.json(results);
    }
  );
});

// GET /poi/nearby?latitude=&longitude=
router.get('/nearby', (req, res) => {
  const lat = parseFloat2(req.query.latitude);
  const lng = parseFloat2(req.query.longitude);

  if (lat === null || lng === null) {
    return res.status(400).json({ error: 'latitude et longitude doivent être des nombres valides' });
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return res.status(400).json({ error: 'Coordonnées hors limites' });
  }

  const sql = `
    SELECT id, name, badge_name, badge_description, category, rarity, radius_meters,
      ROUND(
        6371000 * ACOS(
          LEAST(1, COS(RADIANS(?)) * COS(RADIANS(latitude)) *
          COS(RADIANS(longitude) - RADIANS(?)) +
          SIN(RADIANS(?)) * SIN(RADIANS(latitude)))
        )
      ) AS distance_meters
    FROM poi
    HAVING distance_meters <= radius_meters
    ORDER BY distance_meters ASC
  `;

  db.query(sql, [lat, lng, lat], (err, results) => {
    if (err) { console.error('[GET /poi/nearby]', err); return res.status(500).json({ error: 'Erreur serveur' }); }
    res.json(results);
  });
});

// GET /poi/:id
router.get('/:id', (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ error: 'id invalide' });

  db.query(
    'SELECT id, name, description, latitude, longitude, category, rarity, badge_name, badge_description, radius_meters FROM poi WHERE id = ?',
    [id],
    (err, results) => {
      if (err) { console.error('[GET /poi/:id]', err); return res.status(500).json({ error: 'Erreur serveur' }); }
      if (results.length === 0) return res.status(404).json({ error: 'POI non trouvé' });
      res.json(results[0]);
    }
  );
});

module.exports = router;