const express = require("express");
const router = express.Router();
const db = require("../database/db");


//retourne toutes les aventures
router.get("/", (req, res) => {

  db.query("SELECT * FROM adventures", (err, results) => {

    if (err) {
      return res.status(500).json(err);
    }

    res.json(results);

  });

});

//retourne toutes les aventures d'un utilisateur
router.get("/user", (req, res) =>{
    const { user_id } = req.query;

    const sql = `SELECT a.*
                FROM adventures a
                JOIN adventure_participants ap 
                ON a.id = ap.adventure_id
                WHERE ap.user_id = ?;`;
    db.query(sql, [user_id], (err, results) => {
    if (err) return res.status(500).json(err);

    res.json(results);
  });
})

//retourne l'aventure en cours d'un utilisateur
router.get("/running", (req, res) => {
    const { user_id } = req.query;

    const sql = `
        SELECT JSON_OBJECT(
            'adventure', JSON_OBJECT(
                'id', a.id,
                'name', a.name,
                'description', a.description,
                'creator_id', a.creator_id,
                'created_at', a.created_at,
                'is_running', a.is_running
            ),
            'players', JSON_ARRAYAGG(
                JSON_OBJECT(
                    'id', u.id,
                    'username', u.username,
                    'image', u.avatar_url
                )
            )
        ) AS result
        FROM adventures a
        JOIN adventure_participants ap ON ap.adventure_id = a.id
        JOIN users u ON u.id = ap.user_id
        WHERE a.is_running = 1
        AND EXISTS (
            SELECT 1
            FROM adventure_participants ap2
            WHERE ap2.adventure_id = a.id
            AND ap2.user_id = ?
        )
        GROUP BY a.id
    `;

    db.query(sql, [user_id], (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});



module.exports = router;