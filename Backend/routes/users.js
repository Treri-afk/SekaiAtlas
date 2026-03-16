const express = require('express');
const router  = express.Router();
const crypto  = require('crypto');

// ─────────────────────────────────────────────
// HELPER — génère un code ami unique
// ─────────────────────────────────────────────
const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function generateCode(length = 6) {
  let code = '';
  const bytes = crypto.randomBytes(length);

  for (let i = 0; i < length; i++) {
    code += CHARS[bytes[i] % CHARS.length];
  }

  return code;
}

async function generateUniqueFriendCode(supabase) {
  while (true) {
    const code = generateCode(6);

    const { data, error } = await supabase
      .from('users')
      .select('id')
      .eq('friend_code', code)
      .limit(1);

    if (error) throw error;

    if (!data || data.length === 0) {
      return code;
    }
  }
}

// ─────────────────────────────────────────────
// GET /users/id?user_id=
// ─────────────────────────────────────────────
router.get('/id', async (req, res) => {
  const { user_id } = req.query;

  const { data, error } = await req.supabase
    .from('users')
    .select('*')
    .eq('id', user_id)
    .single();

  if (error) {
    if (error.code === 'PGRST116')
      return res.status(404).json({ message: 'Utilisateur non trouvé' });

    return res.status(500).json({ message: error.message });
  }

  res.json(data);
});

// ─────────────────────────────────────────────
// GET /users/provider?provider_id=
// ─────────────────────────────────────────────
router.get('/provider', async (req, res) => {
  const { provider_id } = req.query;

  const { data, error } = await req.supabase
    .from('users')
    .select('*')
    .eq('provider_id', provider_id)
    .single();

  if (error) {
    if (error.code === 'PGRST116')
      return res.status(404).json({ message: 'Utilisateur non trouvé' });

    return res.status(500).json({ message: error.message });
  }

  res.json(data);
});

// ─────────────────────────────────────────────
// POST /users
// ─────────────────────────────────────────────
router.post('/', async (req, res) => {
  const { username, avatar_url, provider, provider_id } = req.body;

  if (!username || !provider || !provider_id) {
    return res.status(400).json({
      error: 'username, provider et provider_id sont requis'
    });
  }

  try {

    // ── 1. Vérifie si l'utilisateur existe déjà
    const { data: existing, error: findError } = await req.supabase
      .from('users')
      .select('*')
      .eq('provider_id', provider_id)
      .limit(1);

    if (findError) throw findError;

    if (existing && existing.length > 0) {
      return res.status(200).json(existing[0]);
    }

    // ── 2. Génère un code ami
    const friendCode = await generateUniqueFriendCode(req.supabase);

    // ── 3. Insère l'utilisateur
    const { data: inserted, error: insertError } = await req.supabase
      .from('users')
      .insert([
        {
          username,
          avatar_url: avatar_url ?? '',
          provider,
          provider_id,
          friend_code: friendCode,
          created_at: new Date()
        }
      ])
      .select()
      .single();

    if (insertError) throw insertError;

    return res.status(201).json(inserted);

  } catch (err) {
    console.error('[POST /users]', err);
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;