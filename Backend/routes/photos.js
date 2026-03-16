const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config(); // ⚠️ Charger .env

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.ANON_KEY;
if (!supabaseUrl || !supabaseKey) throw new Error('Supabase URL ou KEY manquant');

const supabase = createClient(supabaseUrl, supabaseKey);

// ── Helpers ───────────────────────────────────
const parseFloat2 = (v) => {
  const n = parseFloat(v);
  return isNaN(n) ? null : n;
};

// GET /photos/adventure?adventure_id=
router.get('/adventure', async (req, res) => {
  const adventure_id = parseInt(req.query.adventure_id);
  if (isNaN(adventure_id)) return res.status(400).json({ error: 'adventure_id invalide' });

  const { data, error } = await supabase
    .from('photos')
    .select(`
      id, image_url, latitude, longitude, description, created_at, poi_id, adventure_id,
      users!inner(id, username, avatar_url),
      adventures!inner(name),
      poi(id, name, badge_name, badge_description, rarity, category)
    `)
    .eq('adventure_id', adventure_id)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('[GET /photos/adventure]', error);
    return res.status(500).json({ error: 'Erreur serveur' });
  }
  res.json(data);
});

// GET /photos
router.get('/', async (_req, res) => {
  const { data, error } = await supabase
    .from('photos')
    .select(`
      id, image_url, latitude, longitude, description, created_at, poi_id, adventure_id,
      users!inner(id, username, avatar_url),
      adventures!inner(name),
      poi(id, name, badge_name, badge_description, rarity, category)
    `)
    .order('created_at', { ascending: false })
    .limit(500);

  if (error) {
    console.error('[GET /photos]', error);
    return res.status(500).json({ error: 'Erreur serveur' });
  }
  res.json(data);
});

// POST /photos
router.post('/', async (req, res) => {
  const { user_id, adventure_id, image_url, description, latitude, longitude, poi_id } = req.body;

  const uid = parseInt(user_id);
  const aid = parseInt(adventure_id);
  const pid = poi_id ? parseInt(poi_id) : null;
  const lat = latitude != null ? parseFloat(latitude) : null;
  const lng = longitude != null ? parseFloat(longitude) : null;

  if (isNaN(uid) || isNaN(aid) || !image_url || typeof image_url !== 'string') {
    return res.status(400).json({ error: 'user_id, adventure_id et image_url sont requis' });
  }
  if (!image_url.startsWith('https://')) {
    return res.status(400).json({ error: 'image_url doit être une URL HTTPS' });
  }
  if (lat !== null && (isNaN(lat) || lat < -90 || lat > 90))
    return res.status(400).json({ error: 'latitude invalide' });
  if (lng !== null && (isNaN(lng) || lng < -180 || lng > 180))
    return res.status(400).json({ error: 'longitude invalide' });

  const desc = description && typeof description === 'string'
    ? description.trim().substring(0, 500)
    : null;

  const { data, error } = await supabase
    .from('photos')
    .insert([{ user_id: uid, adventure_id: aid, image_url, description: desc, latitude: lat, longitude: lng, poi_id: pid }])
    .select('id')
    .single();

  if (error) {
    console.error('[POST /photos]', error);
    return res.status(500).json({ error: 'Erreur serveur' });
  }

  res.status(201).json({ id: data.id, user_id: uid, adventure_id: aid });
});

module.exports = router;