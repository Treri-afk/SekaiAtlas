const express = require("express");
const router = express.Router();
const db = require("../database/db");


//récupère toute les relations de la table
router.get("/", (req, res) => {

  db.query("SELECT * FROM users_friend", (err, results) => {

    if (err) {
      return res.status(500).json(err);
    }

    res.json(results);

  });

});

router.post("/", (req, res) => {
    const { user_id, friend_code } = req.body;

    console.log('body reçu :', req.body);

    if (!user_id || !friend_code) {
        return res.status(400).json({ error: "Champs manquants" });
    }

    // Vérifie si un utilisateur avec ce friend_code existe
    const checkSql = `SELECT id FROM users WHERE friend_code = ?`;

    db.query(checkSql, [friend_code], (err, results) => {
        if (err) return res.status(500).json({ message: err.message });

        if (results.length === 0) {
            return res.status(404).json({ error: "Aucun utilisateur trouvé avec ce code ami" });
        }

        const friend_id = results[0].id;

        // Vérifie qu'on n'est pas déjà ami
        const alreadyFriendSql = `
            SELECT id FROM users_friend 
            WHERE (user_id = ? AND friend_id = ?) 
            OR (user_id = ? AND friend_id = ?)
        `;

        db.query(alreadyFriendSql, [user_id, friend_id, friend_id, user_id], (err, existing) => {
            if (err) return res.status(500).json({ message: err.message });

            if (existing.length > 0) {
                return res.status(409).json({ error: "Vous êtes déjà amis" });
            }

            // Crée la relation
            const insertSql = `
                INSERT INTO users_friend (user_id, friend_id, created_at)
                VALUES (?, ?, NOW())
            `;

            db.query(insertSql, [user_id, friend_id], (err, insertResults) => {
                if (err) return res.status(500).json({ message: err.message });
                res.json({ success: true, friend_id: friend_id });
            });
        });
    });
});

//récupère les relations d'un individue spécifique, retourne les users en entier directement utilisable 
router.get("/friend", (req, res) => {
  const { user_id } = req.query;

  const sql = `
    SELECT u.*
    FROM users_friend f
    JOIN users u 
      ON (u.id = f.user_id OR u.id = f.friend_id)
    WHERE (? IN (f.user_id, f.friend_id)) AND u.id != ?
  `;

  db.query(sql, [user_id, user_id], (err, results) => {
    if (err) return res.status(500).json(err);

    res.json(results);
  });
});

module.exports = router;