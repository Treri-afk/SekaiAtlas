const express = require('express');
const router = express.Router();
const db = require("../database/db");

// GET /poi — tous les POI
router.get('/', (req, res) => {
  db.query('SELECT * FROM poi', (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(results);
  });
});

// GET /poi/nearby?latitude=35.6586&longitude=139.7454 — POI proches d'une position
router.get('/nearby', (req, res) => {
  const { latitude, longitude } = req.query;

  if (!latitude || !longitude) {
    return res.status(400).json({ error: 'latitude et longitude requis' });
  }

  // Calcule la distance en mètres entre la position et chaque POI
  // et retourne uniquement ceux dans le rayon radius_meters
  const sql = `
    SELECT *,
      (6371000 * ACOS(
        COS(RADIANS(?)) * COS(RADIANS(latitude)) *
        COS(RADIANS(longitude) - RADIANS(?)) +
        SIN(RADIANS(?)) * SIN(RADIANS(latitude))
      )) AS distance_meters
    FROM poi
    HAVING distance_meters <= radius_meters
    ORDER BY distance_meters ASC
  `;

  db.query(sql, [latitude, longitude, latitude], (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(results);
  });
});

// GET /poi/:id — un POI par son id
router.get('/:id', (req, res) => {
  const { id } = req.params;

  db.query('SELECT * FROM poi WHERE id = ?', [id], (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    if (results.length === 0) return res.status(404).json({ message: 'POI non trouvé' });
    res.json(results[0]);
  });
});

module.exports = router;