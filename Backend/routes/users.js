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

// GET /users/user?user_id=1
router.get("/id", (req, res) => {
  const { user_id } = req.query;

  db.query("SELECT * FROM users WHERE id = ?", [user_id], (err, results) => {
    if (err) return res.status(500).json(err);

    if (results.length === 0) return res.status(404).json({ message: "User not found" });

    res.json(results[0]);
  });
});

// GET /users/provider?provider_id=xxx
router.get("/provider", (req, res) => {
  const { provider_id } = req.query;

  db.query("SELECT * FROM users WHERE provider_id = ?", [provider_id], (err, results) => {
    if (err) return res.status(500).json(err);

    if (results.length === 0) return res.status(404).json({ message: "User not found" });

    res.json(results[0]);
  });
});

router.post("/", (req, res) => {
  const { provider, provider_id, username, avatar_url } = req.body;

  console.log('provider_id reçu :', provider_id);

  if (!provider || !provider_id || !username) {
    return res.status(400).json({ error: "Champs manquants" });
  }

  const checkSql = `SELECT id FROM users WHERE provider_id = ?`;

  db.query(checkSql, [provider_id], (err, results) => {
    if (err) {
      console.error('Erreur SQL check :', err);
      return res.status(500).json({ message: err.message });
    }

    console.log('Résultat check :', results); // ← dis moi ce que ça affiche

    if (results.length > 0) {
      console.log('Utilisateur existant, pas de création');
      return res.json({ success: true, userId: results[0].id, created: false });
    }

    console.log('Nouvel utilisateur, création...');
    const insertSql = `
      INSERT INTO users (provider, provider_id, username, avatar_url, created_at)
      VALUES (?, ?, ?, ?, NOW())
    `;

    db.query(insertSql, [provider, provider_id, username, avatar_url], (err, insertResults) => {
      if (err) {
        console.error('Erreur SQL insert :', err);
        return res.status(500).json({ message: err.message });
      }
      res.json({ success: true, userId: insertResults.insertId, created: true });
    });
  });
});
module.exports = router;