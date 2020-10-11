if not minetest.get_modpath("parties") then return end

local S = minetest.get_translator("arena_lib")





parties.register_on_pre_party_invite(function(sender, p_name)

  -- se il party leader è in coda
  if arena_lib.is_player_in_queue(sender) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't perform this action while in queue!")))
    return false end

  -- se il party leader è in gioco
  if arena_lib.is_player_in_arena(sender) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't perform this action while in game!")))
    return false end

  return true
end)



parties.register_on_pre_party_join(function(party_leader, p_name)

  -- se il party leader è in coda
  if arena_lib.is_player_in_queue(party_leader) then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The party leader must not be in queue to perform this action!")))
    return false end

  -- se il party leader è in gioco
  if arena_lib.is_player_in_arena(party_leader) then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The party leader must not be in game to perform this action!")))
    return false end

  local arena = arena_lib.get_arena_by_player(p_name)

  if not arena then return true end

  -- se l'invitato è in coda
  if arena.in_queue then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You can't perform this action while in queue!")))
    return false end

  -- se l'invitato è l'unico rimasto in partita ed è in celebrazione
  if arena.players_amount == 1 and arena.in_celebration then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You can't perform this action if you're the only one left!")))
    return false end

  return true
end)



parties.register_on_party_join(function(party_leader, p_name)

  --se è in arena, lo rimuovo
  if arena_lib.is_player_in_arena(p_name) then
    arena_lib.remove_player_from_arena(p_name, 3)
  end

end)
