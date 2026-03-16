const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.ANON_KEY;
if (!supabaseUrl || !supabaseKey) throw new Error('Supabase URL ou KEY manquant');

const supabase = createClient(supabaseUrl, supabaseKey);

// GET /badges/user?user_id=
router.get('/user', async (req, res) => {
  const user_id = parseInt(req.query.user_id);
  if (isNaN(user_id)) return res.status(400).json({ error: 'user_id invalide' });

  try {
    const { data, error } = await supabase
      .from('user_badges')
      .select(`
        id,
        unlocked_at,
        poi:poi_id (
          id, name, badge_name, badge_description, category, rarity
        )
      `)
      .eq('user_id', user_id)
      .order('unlocked_at', { ascending: false });

    if (error) throw error;

    // Aplatir la réponse
    const result = data
      .filter(ub => ub.poi) // ignorer les entrées avec poi null (poi supprimé)
      .map(ub => ({
        id:                ub.id,
        unlocked_at:       ub.unlocked_at,
        poi_id:            ub.poi.id,
        name:              ub.poi.name,
        badge_name:        ub.poi.badge_name,
        badge_description: ub.poi.badge_description,
        category:          ub.poi.category,
        rarity:            ub.poi.rarity,
      }));

    res.json(result);
  } catch (err) {
    console.error('[GET /badges/user]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// POST /badges
router.post('/', async (req, res) => {
  const user_id = parseInt(req.body.user_id);
  const poi_id  = parseInt(req.body.poi_id);

  if (isNaN(user_id) || isNaN(poi_id)) {
    return res.status(400).json({ error: 'user_id et poi_id doivent être des entiers valides' });
  }

  try {
    // Vérifier si déjà débloqué
    const { data: existing, error: checkError } = await supabase
      .from('user_badges')
      .select('id')
      .eq('user_id', user_id)
      .eq('poi_id', poi_id)
      .limit(1);

    if (checkError) throw checkError;
    if (existing && existing.length > 0)
      return res.json({ success: true, already_unlocked: true });

    // Insérer le badge
    const { data, error: insertError } = await supabase
      .from('user_badges')
      .insert([{ user_id, poi_id }])
      .select('id')
      .single();

    if (insertError) throw insertError;

    res.json({ success: true, already_unlocked: false, id: data.id });
  } catch (err) {
    console.error('[POST /badges]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;