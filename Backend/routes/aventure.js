const express = require("express");
const router = express.Router();
const db = require("../database/db");

// Retourne toutes les aventures
router.get("/", (req, res) => {
    db.query("SELECT * FROM adventures", (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

// Retourne toutes les aventures d'un utilisateur
router.get("/user", (req, res) => {
    const { user_id } = req.query;
    const sql = `
        SELECT a.*
        FROM adventures a
        JOIN adventure_participants ap ON a.id = ap.adventure_id
        WHERE ap.user_id = ?
    `;
    db.query(sql, [user_id], (err, results) => {
        if (err) return res.status(500).json(err);
        res.json(results);
    });
});

// Retourne l'aventure en cours d'un utilisateur
router.get("/running", (req, res) => {
    const { user_id } = req.query;

    // Étape 1 : récupérer l'aventure en cours
    const adventureSql = `
        SELECT a.id, a.name, a.description, a.creator_id, a.created_at, a.is_running
        FROM adventures a
        JOIN adventure_participants ap ON ap.adventure_id = a.id
        WHERE a.is_running = 1 AND ap.user_id = ?
        LIMIT 1
    `;

    db.query(adventureSql, [user_id], (err, adventures) => {
        if (err) return res.status(500).json({ message: err.message });

        // Aucune aventure → liste vide (évite le JSON_OBJECT null)
        if (adventures.length === 0) return res.json([]);

        const adventure = adventures[0];

        // Étape 2 : récupérer les participants
        const playersSql = `
            SELECT u.id, u.username, u.avatar_url AS image
            FROM adventure_participants ap
            JOIN users u ON u.id = ap.user_id
            WHERE ap.adventure_id = ?
        `;

        db.query(playersSql, [adventure.id], (err, players) => {
            if (err) return res.status(500).json({ message: err.message });

            // Même format qu'avant → aucun changement côté Dart
            res.json([{
                result: { adventure, players }
            }]);
        });
    });
});

// Créer une aventure
router.post("/", (req, res) => {
    const { creator_id, name, description, participant_ids } = req.body;

    console.log('body reçu :', req.body);

    if (!creator_id || !name) {
        return res.status(400).json({ error: "Champs manquants (creator_id, name)" });
    }

    const insertAdventureSql = `
        INSERT INTO adventures (name, description, creator_id, created_at, is_running)
        VALUES (?, ?, ?, NOW(), 1)
    `;

    db.query(insertAdventureSql, [name, description || null, creator_id], (err, result) => {
        if (err) return res.status(500).json({ message: err.message });

        const adventure_id = result.insertId;
        const allParticipants = [...new Set([creator_id, ...(participant_ids || [])])];

        const insertParticipantsSql = `
            INSERT INTO adventure_participants (adventure_id, user_id, joined_at)
            VALUES ?
        `;
        const values = allParticipants.map(uid => [adventure_id, uid, new Date()]);

        db.query(insertParticipantsSql, [values], (err) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json({ success: true, adventure_id, participant_count: allParticipants.length });
        });
    });
});

// Retourne les participants d'une aventure
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

// Terminer une aventure
router.patch("/:id/terminate", (req, res) => {
    const { id } = req.params;
    db.query(
        "UPDATE adventures SET is_running = 0 WHERE id = ?",
        [id],
        (err) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json({ success: true });
        }
    );
});

module.exports = router;