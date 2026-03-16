const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.ANON_KEY;
if (!supabaseUrl || !supabaseKey) throw new Error('Supabase URL ou KEY manquant');

const supabase = createClient(supabaseUrl, supabaseKey);

// GET /adventures
router.get('/', async (_req, res) => {
  try {
    const { data, error } = await supabase.from('adventures').select('*');
    if (error) throw error;
    res.json(data);
  } catch (err) {
    console.error('[GET /adventures]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// GET /adventures/user?user_id=
router.get('/user', async (req, res) => {
  const user_id = parseInt(req.query.user_id);
  if (isNaN(user_id)) return res.status(400).json({ error: 'user_id invalide' });

  try {
    const { data, error } = await supabase
      .from('adventure_participants')
      .select('adventures(*)')
      .eq('user_id', user_id);

    if (error) throw error;

    const adventures = data.map(d => d.adventures).filter(Boolean);
    res.json(adventures);
  } catch (err) {
    console.error('[GET /adventures/user]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// GET /adventures/running?user_id=
// ⚠️ Le filtre sur colonne embeddée (.eq('adventures.is_running', true)) ne fonctionne
// pas avec le client JS Supabase — on récupère toutes les aventures du user et on filtre en JS.
router.get('/running', async (req, res) => {
  const user_id = parseInt(req.query.user_id);
  if (isNaN(user_id)) return res.status(400).json({ error: 'user_id invalide' });

  try {
    // Étape 1 : récupérer toutes les aventures du user
    const { data: participations, error: advError } = await supabase
      .from('adventure_participants')
      .select('adventures(*)')
      .eq('user_id', user_id);

    if (advError) throw advError;

    // Filtrer côté JS sur is_running
    const running = participations
      .map(p => p.adventures)
      .filter(a => a && a.is_running === true);

    if (running.length === 0) return res.json([]);

    const adventure = running[0];

    // Étape 2 : récupérer les participants de cette aventure
    const { data: participants, error: partError } = await supabase
      .from('adventure_participants')
      .select('users(id, username, avatar_url)')
      .eq('adventure_id', adventure.id);

    if (partError) throw partError;

    const players = participants.map(p => p.users).filter(Boolean);

    res.json([{ result: { adventure, players } }]);
  } catch (err) {
    console.error('[GET /adventures/running]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// POST /adventures
router.post('/', async (req, res) => {
  const { creator_id, name, description, participant_ids } = req.body;
  if (!creator_id || !name)
    return res.status(400).json({ error: 'Champs manquants (creator_id, name)' });

  try {
    // Créer l'aventure
    const { data: adventure, error: insertAdvError } = await supabase
      .from('adventures')
      .insert([{ name, description: description || null, creator_id, is_running: true }])
      .select('id')
      .single();

    if (insertAdvError) throw insertAdvError;

    const adventure_id    = adventure.id;
    const allParticipants = [...new Set([creator_id, ...(participant_ids || [])])];

    // Ajouter les participants
    const { error: insertPartError } = await supabase
      .from('adventure_participants')
      .insert(allParticipants.map(uid => ({ adventure_id, user_id: uid })));

    if (insertPartError) throw insertPartError;

    res.json({ success: true, adventure_id, participant_count: allParticipants.length });
  } catch (err) {
    console.error('[POST /adventures]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// GET /adventures/participants?adventure_id=
router.get('/participants', async (req, res) => {
  const adventure_id = parseInt(req.query.adventure_id);
  if (isNaN(adventure_id))
    return res.status(400).json({ error: 'adventure_id manquant' });

  try {
    const { data, error } = await supabase
      .from('adventure_participants')
      .select('users(id, username, avatar_url)')
      .eq('adventure_id', adventure_id);

    if (error) throw error;

    const participants = data.map(d => d.users).filter(Boolean);
    res.json(participants);
  } catch (err) {
    console.error('[GET /adventures/participants]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// PATCH /adventures/:id/terminate
router.patch('/:id/terminate', async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ error: 'id invalide' });

  try {
    const { error } = await supabase
      .from('adventures')
      .update({ is_running: false })
      .eq('id', id);

    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    console.error('[PATCH /adventures/:id/terminate]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;