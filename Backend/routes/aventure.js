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

router.post("/", (req, res) => {
    const { creator_id, name, description, participant_ids } = req.body;

    console.log('body reçu :', req.body);

    if (!creator_id || !name) {
        return res.status(400).json({ error: "Champs manquants (creator_id, name)" });
    }

    // 1. Créer l'aventure
    const insertAdventureSql = `
        INSERT INTO adventures (name, description, creator_id, created_at, is_running)
        VALUES (?, ?, ?, NOW(), 1)
    `;

    db.query(insertAdventureSql, [name, description || null, creator_id], (err, result) => {
        if (err) return res.status(500).json({ message: err.message });

        const adventure_id = result.insertId;

        // 2. Construire la liste des participants
        // On part des IDs sélectionnés + le créateur (sans doublons)
        const allParticipants = [...new Set([creator_id, ...(participant_ids || [])])];

        const insertParticipantsSql = `
            INSERT INTO adventure_participants (adventure_id, user_id, joined_at)
            VALUES ?
        `;

        const values = allParticipants.map(user_id => [adventure_id, user_id, new Date()]);

        db.query(insertParticipantsSql, [values], (err) => {
            if (err) return res.status(500).json({ message: err.message });

            res.json({
                success: true,
                adventure_id,
                participant_count: allParticipants.length,
            });
        });
    });
});

router.get("/participants", (req, res) => {
    const { adventure_id } = req.query;
    if (!adventure_id) return res.status(400).json({ error: "adventure_id manquant" });
    const sql = `
        SELECT u.id, u.username, u.avatar_url AS image
        FROM adventure_participants ap
        JOIN users u ON u.id = ap.user_id
        WHERE ap.adventure_id = ?
    `;
    db.query(sql, [adventure_id], (err, results) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json(results);
    });
});

module.exports = router;