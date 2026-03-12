const express = require("express");
const router = express.Router();
const db = require("../database/db");

router.get("/", (req, res) => {

  db.query("SELECT * FROM users", (err, results) => {

    if (err) {
      return res.status(500).json(err);
    }

    res.json(results);

  });

});

router.post("/", (req, res) => {
  // Récupère les paramètres depuis le body
  const { provider, provider_id, username, avatar_url } = req.body;

  const sql = `
    INSERT INTO users (provider, provider_id, username, avatar_url, created_at)
    VALUES (?, ?, ?, ?, NOW())
  `;

  db.query(sql, [provider, provider_id, username, avatar_url], (err, results) => {
    if (err) {
      return res.status(500).json(err);
    }

    // results.insertId contient l'ID du nouvel utilisateur
    res.json({ success: true, userId: results.insertId });
  });
});

module.exports = router;