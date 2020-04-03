---
--- Link these functions to your mod through some commands, ie. /yourmod info arena_name
---



function arena_lib.print_arenas(sender)

  local n = 0
  for id, arena in pairs(arena_lib.arenas) do
    n = n+1
    minetest.chat_send_player(sender, "ID: " .. id .. ", nome: " .. arena.name )
  end

  minetest.chat_send_player(sender, "Arene totali: " .. n )

end



function arena_lib.print_arena_info(sender, arena_name)
  local arena_ID, arena = arena_lib.get_arena_by_name(arena_name)
  if arena == nil then  minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Quest'arena non esiste!")) return end

  local p_count = 0
  local names = ""
  for pl, stats in pairs(arena.players) do
    p_count = p_count +1
    names = names .. " " .. pl
  end

  local spawners_count = 0
  local spawners_pos = ""
  for spawn_id, spawn_pos in pairs(arena.spawn_points) do
    spawners_count = spawners_count + 1
    spawners_pos = spawners_pos .. " " .. minetest.pos_to_string(spawn_pos)
  end

  minetest.chat_send_player(sender, [[
    ]] .. "Nome: " .. minetest.colorize("#eea160", arena_name ) .. [[
    ]] .. "ID: " .. arena_ID .. [[
    ]] .. "Abilitata: " .. tostring(arena.enabled) .. [[
    ]] .. "Giocatori minimi: " .. arena.min_players .. [[
    ]] .. "Giocatori massimi: " .. arena.max_players .. [[
    ]] .. "Giocatori dentro: " .. p_count .. " ( ".. names .. " )" .. [[
    ]] .. "Kill per la vittoria: " .. arena.kill_cap .. [[
    ]] .. "In coda: " .. tostring(arena.in_queue) .. [[
    ]] .. "In caricamento: " .. tostring(arena.in_loading) .. [[
    ]] .. "In partita: " .. tostring(arena.in_game) .. [[
    ]] .. "In celebrazione: " .. tostring(arena.in_celebration) .. [[
    ]] .. "Spawn points: " .. spawners_count .. " ( " .. spawners_pos .. " )" )
end



function arena_lib.print_arena_stats(sender, arena_name)

  local arena_ID, arena = arena_lib.get_arena_by_name(arena_name)
  if arena == nil then  minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Quest'arena non esiste!")) return end

  if not arena.in_game and not arena.in_celebration then minetest.chat_send_player(name, minetest.colorize("#e6482e", "[!] Nessuna partita in corso!")) return end

  for pl, stats in pairs(arena.players) do
    minetest.chat_send_player(sender, "Player: " .. pl .. ", kills: " .. stats.kills .. ", deaths: " .. stats.deaths .. ", killstreak: " .. stats.killstreak)
  end

end
