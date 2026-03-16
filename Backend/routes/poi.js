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

// GET /poi
router.get('/', async (_req, res) => {
  const { data, error } = await supabase
    .from('poi')
    .select('id, name, description, latitude, longitude, prefecture_code, category, rarity, badge_name, badge_description, radius_meters');

  if (error) {
    console.error('[GET /poi]', error);
    return res.status(500).json({ error: 'Erreur serveur' });
  }
  res.json(data);
});

// GET /poi/nearby?latitude=&longitude=
router.get('/nearby', async (req, res) => {
  const lat = parseFloat2(req.query.latitude);
  const lng = parseFloat2(req.query.longitude);

  if (lat === null || lng === null) {
    return res.status(400).json({ error: 'latitude et longitude doivent être des nombres valides' });
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return res.status(400).json({ error: 'Coordonnées hors limites' });
  }

  // Supabase/Postgres ne supporte pas directement ACOS(COS...) dans l'API JS
  // On peut utiliser `rpc` pour appeler une fonction SQL ou faire le calcul côté JS
  const { data, error } = await supabase
    .from('poi')
    .select('id, name, badge_name, badge_description, category, rarity, radius_meters, latitude, longitude');

  if (error) {
    console.error('[GET /poi/nearby]', error);
    return res.status(500).json({ error: 'Erreur serveur' });
  }

  // Calcul distance en JS
  const R = 6371000; // rayon de la Terre en mètres
  const toRad = (deg) => (deg * Math.PI) / 180;

  const nearby = data
    .map((poi) => {
      const dLat = toRad(poi.latitude - lat);
      const dLng = toRad(poi.longitude - lng);
      const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat)) * Math.cos(toRad(poi.latitude)) * Math.sin(dLng / 2) ** 2;
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      const distance = R * c;
      return { ...poi, distance_meters: Math.round(distance) };
    })
    .filter((poi) => poi.distance_meters <= poi.radius_meters)
    .sort((a, b) => a.distance_meters - b.distance_meters);

  res.json(nearby);
});

// GET /poi/:id
router.get('/:id', async (req, res) => {
  const id = parseInt(req.params.id);
  if (isNaN(id)) return res.status(400).json({ error: 'id invalide' });

  const { data, error } = await supabase
    .from('poi')
    .select('id, name, description, latitude, longitude, category, rarity, badge_name, badge_description, radius_meters')
    .eq('id', id)
    .single();

  if (error) {
    console.error('[GET /poi/:id]', error);
    return res.status(500).json({ error: 'Erreur serveur' });
  }

  if (!data) return res.status(404).json({ error: 'POI non trouvé' });
  res.json(data);
});

module.exports = router;