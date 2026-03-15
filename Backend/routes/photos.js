const express = require("express");
const router = express.Router();
const db = require("../database/db");



// routes/photos.js
router.get("/adventure", (req, res) => {
    const { adventure_id } = req.query;

    if (!adventure_id) {
        return res.status(400).json({ error: "adventure_id manquant" });
    }

    const sql = `
        SELECT p.id, p.image_url, p.created_at,
               u.id AS user_id, u.username, u.avatar_url
        FROM photos p
        JOIN users u ON u.id = p.user_id
        WHERE p.adventure_id = ?
        ORDER BY p.created_at DESC
    `;

    db.query(sql, [adventure_id], (err, results) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json(results);
    });
});


module.exports = router;