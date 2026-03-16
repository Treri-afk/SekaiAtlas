const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.ANON_KEY;
if (!supabaseUrl || !supabaseKey) throw new Error('Supabase URL ou KEY manquant');

const supabase = createClient(supabaseUrl, supabaseKey);

// GET /friends/friend?user_id=
router.get('/friend', async (req, res) => {
  const user_id = parseInt(req.query.user_id);
  if (isNaN(user_id)) return res.status(400).json({ error: 'user_id invalide' });

  try {
    // ── Côté user_id : je suis l'initiateur, l'ami est friend_id
    const { data: asUser, error: e1 } = await supabase
      .from('users_friend')
      .select('friend:users!users_friend_friend_id_fkey(id, username, avatar_url, friend_code)')
      .eq('user_id', user_id);

    if (e1) throw e1;

    // ── Côté friend_id : quelqu'un m'a ajouté, je suis l'ami
    const { data: asFriend, error: e2 } = await supabase
      .from('users_friend')
      .select('friend:users!users_friend_user_id_fkey(id, username, avatar_url, friend_code)')
      .eq('friend_id', user_id);

    if (e2) throw e2;

    // Aplatir et dédupliquer par id
    const all = [
      ...asUser.map(r => r.friend),
      ...asFriend.map(r => r.friend),
    ].filter(Boolean);

    const seen = new Set();
    const result = all.filter(u => {
      if (seen.has(u.id)) return false;
      seen.add(u.id);
      return true;
    });

    res.json(result);
  } catch (err) {
    console.error('[GET /friends/friend]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// POST /friends
router.post('/', async (req, res) => {
  const user_id     = parseInt(req.body.user_id);
  const friend_code = req.body.friend_code?.toString().trim().toUpperCase();

  if (isNaN(user_id) || !friend_code) {
    return res.status(400).json({ error: 'user_id et friend_code sont requis' });
  }

  try {
    // Chercher l'utilisateur avec ce friend_code
    const { data: users, error: findError } = await supabase
      .from('users')
      .select('id')
      .eq('friend_code', friend_code)
      .limit(1);

    if (findError) throw findError;
    if (!users || users.length === 0)
      return res.status(404).json({ error: 'Aucun utilisateur trouvé avec ce code ami' });

    const friend_id = users[0].id;

    if (friend_id === user_id)
      return res.status(400).json({ error: 'Vous ne pouvez pas vous ajouter vous-même' });

    // Vérifier si la relation existe déjà dans les deux sens
    const { data: existing, error: existError } = await supabase
      .from('users_friend')
      .select('id')
      .or(
        `and(user_id.eq.${user_id},friend_id.eq.${friend_id}),and(user_id.eq.${friend_id},friend_id.eq.${user_id})`
      );

    if (existError) throw existError;
    if (existing && existing.length > 0)
      return res.status(409).json({ error: 'Vous êtes déjà amis' });

    // Insérer la relation
    const { error: insertError } = await supabase
      .from('users_friend')
      .insert([{ user_id, friend_id }]);

    if (insertError) throw insertError;

    res.json({ success: true, friend_id });
  } catch (err) {
    console.error('[POST /friends]', err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;