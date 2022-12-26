local S = minetest.get_translator("arena_lib")

local function assign_team() end



function arena_lib.get_and_add_joining_players(mod_ref, arena, p_name)
  local p_team_ID

  -- determino eventuale squadra giocatore
  if arena.teams_enabled then
    p_team_ID = assign_team(mod_ref, arena, p_name)
  end

  local players_to_add = {}

  -- potrei avere o un giocatore o un intero gruppo da aggiungere. Quindi per evitare mille if, metto a prescindere il/i giocatore/i in una tabella per iterare in alcune operazioni successive
  if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then
    for k, v in pairs(parties.get_party_members(p_name)) do
      players_to_add[k] = v
    end
  else
    table.insert(players_to_add, p_name)
  end

  -- aggiungo il giocatore
  for _, pl_name in pairs(players_to_add) do
    arena.players[pl_name] = {kills = 0, deaths = 0, teamID = p_team_ID}
    arena.players_and_spectators[pl_name] = true
  end

  -- aumento il conteggio di giocatori in partita
  arena.players_amount = arena.players_amount + #players_to_add
  if arena.teams_enabled then
    arena.players_amount_per_team[p_team_ID] = arena.players_amount_per_team[p_team_ID] + #players_to_add
  end

  return players_to_add
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function assign_team(mod_ref, arena, p_name)

  local assigned_team_ID = 1

  for i = 1, #arena.teams do
    if arena.players_amount_per_team[i] < arena.players_amount_per_team[assigned_team_ID] then
      assigned_team_ID = i
    end
  end

  local p_team = arena.teams[assigned_team_ID].name

  if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then
    for _, pl_name in pairs(parties.get_party_members(p_name)) do
      minetest.chat_send_player(pl_name, mod_ref.prefix .. S("You've joined team @1", minetest.colorize("#eea160", p_team)))
    end
  else
    minetest.chat_send_player(p_name, mod_ref.prefix .. S("You've joined team @1", minetest.colorize("#eea160", p_team)))
  end

  return assigned_team_ID
end
