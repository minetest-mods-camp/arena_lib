--
-- la HUD si divide in due tipi: "broadcast", quella in alto, e "hotbar", quella
-- sopra la hotbar. Oltre che essere usata nativamente da arena_lib, può essere
-- richiamata e sovrascritta da qualsiasi altra mod, per esempio per annunci
-- in partita. HUD_hide prende anche "all" come tipo, per nasconderli entrambi
--


local player_huds = {}    -- KEY: p_name, INDEX: {HUD_BG_ID, HUD_TXT_ID}



function arena_lib.HUD_add(player)

  local HUD_BROADCAST_IMG = player:hud_add({
    hud_elem_type = "image",
    position  = { x = 0.5, y = 0.2},
    text      = "",
    scale     = { x = 25, y = 2},
    number    = 0xFFFFFF,
  })

  local HUD_BROADCAST_TXT = player:hud_add({
    hud_elem_type = "text",
    position  = { x = 0.5, y = 0.2},
    text      = "",
    scale     = { x = 1, y = 1},
    number    = 0xFFFFFF,
  })

  local HUD_HOTBAR_IMG = player:hud_add({
    hud_elem_type = "image",
    position  = { x = 0.5, y = 1},
    offset = {x = 0, y = -105},
    text      = "",
    scale     = { x = 25, y = 1.5},
    number    = 0xFFFFFF,
  })

  local HUD_HOTBAR_TXT = player:hud_add({
    hud_elem_type = "text",
    position  = { x = 0.5, y = 1},
    offset = {x = 0, y = -105},
    text      = "",
    scale     = { x = 1, y = 1},
    number    = 0xFFFFFF,
  })

  player_huds[player:get_player_name()] = {HUD_BROADCAST_IMG, HUD_BROADCAST_TXT, HUD_HOTBAR_IMG, HUD_HOTBAR_TXT}
end



function arena_lib.HUD_send_msg(HUD_type, p_name, msg, duration, sound)

  local player = minetest.get_player_by_name(p_name)
  local p_HUD = player_huds[p_name]

  -- controllo il tipo di HUD
  if HUD_type == "broadcast" then
    player:hud_change(p_HUD[1], "text", "arenalib_hud_bg.png")
    player:hud_change(p_HUD[2], "text", msg)
  elseif HUD_type == "hotbar" then
    player:hud_change(p_HUD[3], "text", "arenalib_hud_bg2.png")
    player:hud_change(p_HUD[4], "text", msg)
  end

  -- riproduco eventuale suono
  if sound then
    minetest.sound_play(sound, {
      to_player = p_name
    })
  end

  -- se duration non è specificata, permane all'infinito
  if duration then
    minetest.after(duration, function()
      if minetest.get_player_by_name(p_name) == nil then return end
      -- se è stato aggiornato il messaggio, interrompo questo timer e lascio il controllo a quello nuovo
      if HUD_type == "broadcast" and player:hud_get(p_HUD[2]).text ~= msg or
        HUD_type == "hotbar" and player:hud_get(p_HUD[4]).text ~= msg then
        return end

      arena_lib.HUD_hide(HUD_type, p_name)
    end)
  end

end



function arena_lib.HUD_send_msg_all(HUD_type, arena, msg, duration, sound)
  for pl_name, _ in pairs(arena.players) do

    local pl = minetest.get_player_by_name(pl_name)
    local pl_HUD = player_huds[pl_name]

    -- controllo il tipo di HUD
    if HUD_type == "broadcast" then
      pl:hud_change(pl_HUD[1], "text", "arenalib_hud_bg.png")
      pl:hud_change(pl_HUD[2], "text", msg)
    elseif HUD_type == "hotbar" then
      pl:hud_change(pl_HUD[3], "text", "arenalib_hud_bg2.png")
      pl:hud_change(pl_HUD[4], "text", msg)
    end

    -- riproduco eventuale suono
    if sound then
      minetest.sound_play(sound, {
        to_player = pl_name
      })
    end

    -- se duration non è specificata, permane all'infinito
    if duration then
      minetest.after(duration, function()
        if minetest.get_player_by_name(pl_name) == nil then return end
        -- se è stato aggiornato il messaggio, interrompo questo timer e lascio il controllo a quello nuovo
        if HUD_type == "broadcast" and pl:hud_get(pl_HUD[2]).text ~= msg or
          HUD_type == "hotbar" and pl:hud_get(pl_HUD[4]).text ~= msg then
          return end

        arena_lib.HUD_hide(HUD_type, pl_name)
      end)
    end

  end
end



function arena_lib.HUD_hide(HUD_type, player_or_arena)

  -- la funzione può prendere sia un giocatore che una tabella di giocatori.
  -- Controllo quale dei due è stato usato
  if type(player_or_arena) == "string" then

    local player = minetest.get_player_by_name(player_or_arena)
    local p_HUD = player_huds[player_or_arena]

    if HUD_type == "broadcast" then
      player:hud_change(p_HUD[1], "text", "")
      player:hud_change(p_HUD[2], "text", "")
    elseif HUD_type == "hotbar" then
      player:hud_change(p_HUD[3], "text", "")
      player:hud_change(p_HUD[4], "text", "")
    elseif HUD_type == "all" then
      player:hud_change(p_HUD[1], "text", "")
      player:hud_change(p_HUD[2], "text", "")
      player:hud_change(p_HUD[3], "text", "")
      player:hud_change(p_HUD[4], "text", "")
    end

  elseif type(player_or_arena) == "table" then

    for pl_name, _ in pairs(player_or_arena.players) do

      local pl = minetest.get_player_by_name(pl_name)
      local pl_HUD = player_huds[pl_name]

      if HUD_type == "broadcast" then
        pl:hud_change(pl_HUD[1], "text", "")
        pl:hud_change(pl_HUD[2], "text", "")
      elseif HUD_type == "hotbar" then
        pl:hud_change(pl_HUD[3], "text", "")
        pl:hud_change(pl_HUD[4], "text", "")
      elseif HUD_type == "all" then
        pl:hud_change(pl_HUD[1], "text", "")
        pl:hud_change(pl_HUD[2], "text", "")
        pl:hud_change(pl_HUD[3], "text", "")
        pl:hud_change(pl_HUD[4], "text", "")
      end
    end
  end

end
