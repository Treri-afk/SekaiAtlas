const express = require("express");
const router  = express.Router();
const db      = require("../database/db");

router.get("/adventure", (req, res) => {
    const { adventure_id } = req.query;
    if (!adventure_id) return res.status(400).json({ error: "adventure_id manquant" });

    const sql = `
        SELECT
          p.id,
          p.image_url,
          p.latitude,
          p.longitude,
          p.description,
          p.created_at,
          p.poi_id,
          u.id        AS user_id,
          u.username,
          u.avatar_url,
          poi.name    AS poi_name,
          poi.badge_name,
          poi.badge_description,
          poi.rarity  AS poi_rarity,
          poi.category AS poi_category
        FROM photos p
        JOIN users u ON u.id = p.user_id
        LEFT JOIN poi ON poi.id = p.poi_id
        WHERE p.adventure_id = ?
        ORDER BY p.created_at DESC
    `;
    db.query(sql, [adventure_id], (err, results) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json(results);
    });
});

router.get("/", (req, res) => {
  const sql = `
    SELECT 
      ph.*,
      u.username,
      a.name AS adventure_name,
      p.badge_name,
      p.badge_description,
      p.name AS poi_name,
      p.rarity AS poi_rarity,
      p.category AS poi_category
    FROM photos ph
    JOIN users u ON u.id = ph.user_id
    JOIN adventures a ON a.id = ph.adventure_id
    LEFT JOIN poi p ON p.id = ph.poi_id
    ORDER BY ph.created_at DESC
  `;

  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(results);
  });
});

router.post("/", (req, res) => {
    const { user_id, adventure_id, image_url, description, latitude, longitude, poi_id } = req.body;

    if (!user_id || !adventure_id || !image_url) {
        return res.status(400).json({ error: "user_id, adventure_id et image_url sont requis" });
    }

    const sql = `
        INSERT INTO photos (user_id, adventure_id, image_url, description, latitude, longitude, poi_id, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    `;

    db.query(sql, [
        user_id,
        adventure_id,
        image_url,
        description ?? null,
        latitude    ?? null,
        longitude   ?? null,
        poi_id      ?? null
    ], (err, result) => {
        if (err) return res.status(500).json({ message: err.message });
        res.status(201).json({
            id: result.insertId,
            user_id,
            adventure_id,
            image_url,
            description: description ?? null,
            latitude:    latitude    ?? null,
            longitude:   longitude   ?? null,
            poi_id:      poi_id      ?? null
        });
    });
});

module.exports = router;