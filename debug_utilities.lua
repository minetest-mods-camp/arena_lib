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

  -- concateno nomi giocatori
  local names = ""
  for pl, stats in pairs(arena.players) do
    names = names .. " " .. pl
  end

  -- calcolo stato arena
  local status
  if arena.in_queue then
    status = S("in queue")
  elseif arena.in_loading then
    status = S("loading")
  elseif arena.in_game then
    status = S("in game")
  elseif arena.in_celebration then
    status = S("celebrating")
  else
    status = S("waiting")
  end

  -- calcolo cartello
  local sign_pos
  if arena.sign.x ~= nil then
    sign_pos = minetest.pos_to_string(arena.sign)
  else
    sign_pos = "---"
  end

  -- calcolo coordinate spawn point
  local spawners_count = 0
  local spawners_pos = ""
  for spawn_id, spawn_pos in pairs(arena.spawn_points) do
    spawners_count = spawners_count + 1
    spawners_pos = spawners_pos .. " " .. minetest.pos_to_string(spawn_pos) .. " "
  end

  -- calcolo eventuale timer
  local timer = ""
  if arena.timer then
    if arena.timer_current then
      timer = S("Timer: ") .. arena.timer .. " (" .. S("current: ") .. arena.timer_current .. ")\n"
    else
      timer = S("Timer: ") .. arena.timer .. " (" .. S("current: ") .. "--- )\n"
    end
  end

  --calcolo proprietà
  local properties = ""
  for property, _ in pairs(mod_ref.properties) do
    properties = properties .. property .. " = " .. arena[property] .. "; "
  end

  --calcolo proprietà temporanee
  local temp_properties = ""
  if arena.in_game == true then
    for temp_property, _ in pairs(mod_ref.temp_properties) do
      temp_properties = temp_properties .. temp_property .. " = " .. arena[temp_property] .. "; "
    end
  else
    for temp_property, _ in pairs(mod_ref.temp_properties) do
      temp_properties = temp_properties .. temp_property .. "; "
    end
  end

  minetest.chat_send_player(sender,
    minetest.colorize("#cfc6b8", "====================================") .. "\n" ..
    minetest.colorize("#eea160", S("Name: ")) .. minetest.colorize("#cfc6b8", arena_name ) .. "\n" ..
    minetest.colorize("#eea160", "ID: ") .. minetest.colorize("#cfc6b8", arena_ID) .. "\n" ..
    minetest.colorize("#eea160", S("Players required: ")) .. minetest.colorize("#cfc6b8", arena.min_players) .. "\n" ..
    minetest.colorize("#eea160", S("Players supported: ")) .. minetest.colorize("#cfc6b8", arena.max_players) .. "\n" ..
    minetest.colorize("#eea160", S("Players inside: ")) .. minetest.colorize("#cfc6b8", arena.players_amount .. " ( ".. names .. " )") .. "\n" ..
    minetest.colorize("#eea160", S("Enabled: ")) .. minetest.colorize("#cfc6b8", tostring(arena.enabled)) .. "\n" ..
    minetest.colorize("#eea160", S("Status: ")) .. minetest.colorize("#cfc6b8", status) .. "\n" ..
    minetest.colorize("#eea160", S("Sign: ")) .. minetest.colorize("#cfc6b8", sign_pos) .. "\n" ..
    minetest.colorize("#eea160", S("Spawn points: ")) .. minetest.colorize("#cfc6b8", spawners_count .. " ( " .. spawners_pos .. " )") .. "\n" ..
    timer ..
    minetest.colorize("#eea160", S("Properties: ")) .. minetest.colorize("#cfc6b8", properties) .. "\n" ..
    minetest.colorize("#eea160", S("Temp properties: ")) .. minetest.colorize("#cfc6b8", temp_properties)
  )

end



function arena_lib.print_arena_stats(sender, mod, arena_name)

  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)
  if arena == nil then  minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!"))) return end

  if not arena.in_game and not arena.in_celebration then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No ongoing game!"))) return end

  for pl_name, stats in pairs(arena.players) do

    -- calcolo proprietà del giocatore
    local p_properties = ""
    for k, v in pairs(arena_lib.mods[mod].player_properties) do
      p_properties = p_properties .. ",  " .. k .. ": " .. tostring(stats[k])
    end

    minetest.chat_send_player(sender,
      S("Player: ") .. pl_name ..
      S(",  kills: ") .. stats.kills ..
      S(",  deaths: ") .. stats.deaths ..
      p_properties)
  end

end
