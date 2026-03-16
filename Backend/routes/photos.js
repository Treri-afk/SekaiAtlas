const express = require('express');
const router  = express.Router();
const db      = require('../database/db');

const SELECT_PHOTOS = `
  SELECT
    ph.id, ph.image_url, ph.latitude, ph.longitude,
    ph.description, ph.created_at, ph.poi_id, ph.adventure_id,
    u.id         AS user_id,
    u.username,
    u.avatar_url,
    a.name       AS adventure_name,
    p.name       AS poi_name,
    p.badge_name,
    p.badge_description,
    p.rarity     AS poi_rarity,
    p.category   AS poi_category
  FROM photos ph
  JOIN users u       ON u.id = ph.user_id
  JOIN adventures a  ON a.id = ph.adventure_id
  LEFT JOIN poi p    ON p.id = ph.poi_id
`;

// GET /photos/adventure?adventure_id=
router.get('/adventure', (req, res) => {
  const adventure_id = parseInt(req.query.adventure_id);
  if (isNaN(adventure_id)) return res.status(400).json({ error: 'adventure_id invalide' });

  db.query(
    SELECT_PHOTOS + ' WHERE ph.adventure_id = ? ORDER BY ph.created_at DESC',
    [adventure_id],
    (err, results) => {
      if (err) { console.error('[GET /photos/adventure]', err); return res.status(500).json({ error: 'Erreur serveur' }); }
      res.json(results);
    }
  );
});

// GET /photos
router.get('/', (_req, res) => {
  db.query(
    SELECT_PHOTOS + ' ORDER BY ph.created_at DESC LIMIT 500',
    (err, results) => {
      if (err) { console.error('[GET /photos]', err); return res.status(500).json({ error: 'Erreur serveur' }); }
      res.json(results);
    }
  );
});

// POST /photos
router.post('/', (req, res) => {
  const { user_id, adventure_id, image_url, description, latitude, longitude, poi_id } = req.body;

  // Validation
  const uid = parseInt(user_id);
  const aid = parseInt(adventure_id);
  const pid = poi_id ? parseInt(poi_id) : null;
  const lat = latitude  != null ? parseFloat(latitude)  : null;
  const lng = longitude != null ? parseFloat(longitude) : null;

  if (isNaN(uid) || isNaN(aid) || !image_url || typeof image_url !== 'string') {
    return res.status(400).json({ error: 'user_id, adventure_id et image_url sont requis' });
  }
  if (!image_url.startsWith('https://')) {
    return res.status(400).json({ error: 'image_url doit être une URL HTTPS' });
  }
  if (lat !== null && (isNaN(lat) || lat < -90  || lat > 90))  return res.status(400).json({ error: 'latitude invalide' });
  if (lng !== null && (isNaN(lng) || lng < -180 || lng > 180)) return res.status(400).json({ error: 'longitude invalide' });

  const desc = description && typeof description === 'string'
    ? description.trim().substring(0, 500)
    : null;

  db.query(
    'INSERT INTO photos (user_id, adventure_id, image_url, description, latitude, longitude, poi_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())',
    [uid, aid, image_url, desc, lat, lng, pid ?? null],
    (err, result) => {
      if (err) { console.error('[POST /photos]', err); return res.status(500).json({ error: 'Erreur serveur' }); }
      res.status(201).json({ id: result.insertId, user_id: uid, adventure_id: aid });
    }
  );
});

module.exports = router;