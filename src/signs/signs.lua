local S = minetest.get_translator("arena_lib")
local FS = minetest.formspec_escape

local function add_sign() end
local function remove_sign() end
local function update_sign() end
local function in_game_txt() end
local function get_infobox_formspec() end



arena_lib.register_entrance_type("arena_lib", "sign", {
  name = S("Sign"),

  editor_settings = {
    name = S("Signs"),
    icon = "arenalib_editor_signs.png",
    description = S("One sign per arena"),
    tools = {
      "arena_lib:sign_add",
      "arena_lib:sign_remove",
      "",
      "arena_lib:sign"
    }
  },

  on_add = function(sender, mod, arena, pos) return add_sign(sender, mod, arena, pos) end,
  on_remove = function(mod, arena) remove_sign(mod, arena) end,
  on_load = function(arena) update_sign(arena) end,
  on_update = function(arena) update_sign(arena) end,

  debug_output = function(entrance) return minetest.pos_to_string(entrance) end
})



signs_lib.register_sign("arena_lib:sign", {
  description = S("Arena sign"),
  tiles = {
    { name = "arenalib_sign.png", backface_culling = true},
    "arenalib_sign_edge.png"
    },
  inventory_image = "arenalib_sign_icon.png",
  default_color = "8",
  entity_info = "standard",
  sounds = minetest.global_exists("default") and default.node_sound_wood_defaults() or nil,
  groups = {cracky = 3, oddly_breakable_by_hand = 3},
  allow_widefont = true,
  chars_per_line = 40,
  horiz_scaling = 0.95,
  vert_scaling = 1.38,
  number_of_lines = 5,

  -- forza carattere espanso
  on_construct = function(pos)
    minetest.get_meta(pos):set_int("widefont", 1)
    end,

    -- cartello indistruttibile se c'è un'arena assegnata
  on_dig = function(pos, node, digger)
    if minetest.get_meta(pos):get_int("arenaID") ~= 0 then return end

    minetest.node_dig(pos,node,digger)
  end,

  -- click dx apre la finestra d'informazioni
  on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if minetest.get_meta(pos):get_int("arenaID") == 0 then return end

    local mod = minetest.get_meta(pos):get_string("mod")
    local arenaID = minetest.get_meta(pos):get_int("arenaID")

    minetest.show_formspec(clicker:get_player_name(), "arena_lib:infobox", get_infobox_formspec(mod, arenaID, clicker))
  end,


  on_punch = function(pos, node, puncher, pointed_thing)
    local arenaID = minetest.get_meta(pos):get_int("arenaID")
    if arenaID == 0 then return end

    local mod = minetest.get_meta(pos):get_string("mod")
    local arena = arena_lib.mods[mod].arenas[arenaID]
    local p_name = puncher:get_player_name()

    if not arena then return end -- nel caso qualche cartello dovesse impallarsi, si può rompere senza far crashare

    -- se il cartello è stato spostato tipo con WorldEdit, lo aggiorno alla nuova posizione (e se c'è una partita in corso, la interrompo)
    if not vector.equals(arena.entrance, pos) then
      local arena_name = arena.name
      arena_lib.force_arena_ending(mod, arena, "ARENA_LIB")
      arena_lib.disable_arena("", mod, arena_name)
      remove_sign("", mod, arena)
      add_sign("", mod, arena, pos)
      arena_lib.enable_arena("", mod, arena_name)
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Uh-oh, it looks like this sign has been misplaced: well, fixed, hit it again!")))
      return end

    -- se si è già in coda nella stessa arena, esci, sennò prova ad aggiungere il giocatore
    if arena_lib.is_player_in_queue(p_name, mod) and arena_lib.get_queueID_by_player(p_name) == arenaID then
      arena_lib.remove_player_from_queue(p_name)
    else
      if arena.in_game then
        arena_lib.join_arena(mod, p_name, arenaID)
      else
        arena_lib.join_queue(mod, arena, p_name)
      end
    end
  end
})





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function add_sign(sender, mod, arena, pos)

  if not pos or type(pos) ~= "table" then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
    return end

  -- se non ha trovato niente, esco
  if minetest.get_node(pos).name ~= "arena_lib:sign" then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] That's not an arena_lib sign!")))
    return end

  local id = arena_lib.get_arena_by_name(mod, arena.name) -- TODO 6.0 sostituire con arena.ID

  -- salvo il nome della mod e l'ID come metadato nel cartello
  minetest.get_meta(pos):set_string("mod", mod)
  minetest.get_meta(pos):set_int("arenaID", id)

  return pos
end



function remove_sign(mod, arena)

  minetest.load_area(arena.entrance)

  local sign_meta = minetest.get_meta(arena.entrance)
  local id = arena_lib.get_arena_by_name(mod, arena.name) -- TODO 6.0 sostituire con arena.ID

  -- se il cartello non è stato spostato lo rimuovo, sennò evito di far sparire il blocco che c'è ora
  -- (può capitare se qualcuno sposta un'area con WorldEdit). Le altre condizioni assicurano poi che si stia
  -- cancellando il cartello giusto, nel caso qualcuno con WorldEdit ne abbia spostato un altro appartenente
  -- a un'arena diversa nella stessa posizione
  if minetest.get_node(arena.entrance).name == "arena_lib:sign" and sign_meta:get_string("mod") == mod and
                                                                    sign_meta:get_int("arenaID") == id then
    minetest.set_node(arena.entrance, {name = "air"})
  end
end



function update_sign(arena)

  local p_count = 0
  local t_count = #arena.teams

  -- non uso il getter perché dovrei richiamare 2 funzioni (ID e count)
  for pl, stats in pairs(arena.players) do
    p_count = p_count +1
  end

  signs_lib.update_sign(arena.entrance, {text = [[
    ]] .. "\n\n" .. [[
    ]] .. arena.name .. "\n" .. [[
    ]] .. p_count .. "/".. arena.max_players * t_count .. "\n" .. [[
    ]] .. in_game_txt(arena) .. "\n" .. [[

    ]]})
end



function in_game_txt(arena)
  local txt

  -- it's not possible to translate them => https://gitlab.com/VanessaE/signs_lib/-/issues/9
  if not arena.enabled then txt = "#dWIP"
  elseif arena.in_queue then txt = "#2Queueing"
  elseif arena.in_celebration then txt = "#4Terminating"
  elseif arena.in_loading then txt = "#4Loading"
  elseif arena.in_game then txt = "#4In progress"
  else txt = "#3Waiting" end

  return txt
end



function get_infobox_formspec(mod, arenaID, player)

  player:get_meta():set_string("arenalib_infobox_mod", mod)
  player:get_meta():set_int("arenalib_infobox_arenaID", arenaID)

  local arena = arena_lib.mods[mod].arenas[arenaID]
  local bgm_info

  if arena.bgm then
    local title = arena.bgm.title or "???"
    local author = arena.bgm.author or "???"
    bgm_info = title .. " - " .. author
  else
    bgm_info = "---"
  end

  local formspec = {
    "formspec_version[4]",
    "size[7.1,5]",
    "no_prepend[]",
    "bgcolor[;neither]",
    "style_type[image_button;border=false;bgimg=blank.png]",
    "background[0,0;1,1;arenalib_infobox.png;true]",
    -- immagini
    "image[1,0.7;1,1;arenalib_infobox_name.png]",
    "image[1,1.7;1,1;arenalib_tool_settings_nameauthor.png]",
    "image[1,3.1;1,1;arenalib_customise_bgm.png]",
    "image_button[5.9,0.7;0.5,0.5;arenalib_infobox_quit.png;close;]",
    "image_button[4.7,0.45;1,1;arenalib_infobox_spectate.png;spectate;]",
    -- scritte
    "hypertext[2.4,1.1;4,1;name;<style size=20 font=mono color=#5a5353>" .. FS(arena.name) .. "</style>]",
    "hypertext[2.4,2.15;4,1;name;<style size=20 font=mono color=#5a5353>" .. FS(arena.author) .. "</style>]",
    "hypertext[2.4,3.15;4,1;name;<global valign=middle><style size=20 font=mono color=#5a5353>" .. FS(bgm_info) .. "</style>]",
  }

  return table.concat(formspec, "")
end



------------------------------------------------
---------------GESTIONE CAMPI-----------------
----------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)

  if formname ~= "arena_lib:infobox" then return end

  if fields.close then
    minetest.close_formspec(player:get_player_name(), formname)
    player:get_meta():set_string("arenalib_infobox_mod", "")
    player:get_meta():set_int("arenalib_infobox_arenaID", 0)

  elseif fields.spectate then
    local mod = player:get_meta():get_string("arenalib_infobox_mod")
    local arenaID = player:get_meta():get_int("arenalib_infobox_arenaID")
    local p_name = player:get_player_name()

    if arena_lib.is_player_in_queue(p_name) then
      arena_lib.remove_player_from_queue(p_name)
    end

    arena_lib.join_arena(mod, p_name, arenaID, true)
  end
end)
