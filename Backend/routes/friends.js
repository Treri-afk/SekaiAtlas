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