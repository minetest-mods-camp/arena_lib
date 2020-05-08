---
--- Link these functions to your mod through some commands, ie. /yourmod info arena_name
---
local S = minetest.get_translator("arena_lib")


function arena_lib.print_arenas(sender, mod)

  local n = 0
  for id, arena in pairs(arena_lib.mods[mod].arenas) do
    n = n+1
    minetest.chat_send_player(sender, "ID: " .. id .. ", " .. S("name: ") .. arena.name )
  end

  minetest.chat_send_player(sender, S("Total arenas: ") .. n )

end



function arena_lib.print_arena_info(sender, mod, arena_name)
  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)
  if arena == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
  return end

  local mod_ref = arena_lib.mods[mod]

  -- calcolo cartello
  local sign_pos
  if arena.sign.x ~= nil then
    sign_pos = arena.sign
  else
    sign_pos = {}
  end

  -- calcolo giocatori
  local p_count = 0
  local names = ""
  for pl, stats in pairs(arena.players) do
    p_count = p_count +1
    names = names .. " " .. pl
  end

  -- calcolo coordinate spawn point
  local spawners_count = 0
  local spawners_pos = ""
  for spawn_id, spawn_pos in pairs(arena.spawn_points) do
    spawners_count = spawners_count + 1
    spawners_pos = spawners_pos .. " " .. minetest.pos_to_string(spawn_pos)
  end

  --calcolo proprietà
  local properties = {}
  for property, _ in pairs(mod_ref.properties) do
    properties[property] = arena[property]
  end

  --calcolo proprietà temporanee
  local temp_properties = {}
  for temp_property, _ in pairs(mod_ref.temp_properties) do
    temp_properties[temp_property] = arena[temp_property]
  end

  minetest.chat_send_player(sender, [[
    ]] .. S("Name: ") .. minetest.colorize("#eea160", arena_name ) .. [[
    ]] .. "ID: " .. arena_ID .. [[
    ]] .. S("Enabled: ") .. tostring(arena.enabled) .. [[
    ]] .. S("Sign: ") .. minetest.serialize(sign_pos) .. [[
    ]] .. S("Players required: ") .. arena.min_players .. [[
    ]] .. S("Players supported: ") .. arena.max_players .. [[
    ]] .. S("Players inside: ") .. p_count .. " ( ".. names .. " )" .. [[
    ]] .. S("Kills to win: ") .. arena.kill_cap .. [[
    ]] .. S("In queue: ") .. tostring(arena.in_queue) .. [[
    ]] .. S("Loading: ") .. tostring(arena.in_loading) .. [[
    ]] .. S("In game: ") .. tostring(arena.in_game) .. [[
    ]] .. S("Celebrating: ") .. tostring(arena.in_celebration) .. [[
    ]] .. S("Spawn points: ") .. spawners_count .. " ( " .. spawners_pos .. " )" .. [[
    ]] .. S("Properties: ") .. minetest.serialize(properties) .. [[
    ]] .. S("Temp properties: ") .. minetest.serialize(temp_properties))
end



function arena_lib.print_arena_stats(sender, mod, arena_name)

  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)
  if arena == nil then  minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!"))) return end

  if not arena.in_game and not arena.in_celebration then minetest.chat_send_player(name, minetest.colorize("#e6482e", S("[!] No ongoing game!"))) return end

  for pl, stats in pairs(arena.players) do
    minetest.chat_send_player(sender, S("Player: ") .. pl .. S(", kills: ") .. stats.kills .. S(", deaths: ") .. stats.deaths)
  end

end
