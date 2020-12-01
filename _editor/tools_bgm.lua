local S = minetest.get_translator("arena_lib")

local function get_bgm_formspec() end
local function calc_gain() end
local function calc_pitch() end

local audio_currently_playing = {}     -- KEY p_name; VALUE sound handle
local bgm_tools = {
  "arena_lib:bgm_set",
  "",
  "",
  "",
  "",
  "",
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}



minetest.register_tool("arena_lib:bgm_set", {

    description = S("Set BGM"),
    inventory_image = "arenalib_editor_bgm.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local mod         = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name  = user:get_meta():get_string("arena_lib_editor.arena")
      local id, arena   = arena_lib.get_arena_by_name(mod, arena_name)

      minetest.show_formspec(user:get_player_name(), "arena_lib:bgm", get_bgm_formspec(arena))
    end
})



function arena_lib.give_bgm_tools(player)
  player:get_inventory():set_list("main", bgm_tools)
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function get_bgm_formspec(arena)


  local arena_bgm = ""
  local arena_volume = 100
  local arena_pitch = 50

  if arena.bgm then
    arena_bgm = arena.bgm.track
    arena_volume = arena.bgm.gain * 100
    arena_pitch = arena.bgm.pitch * 50
  end

  local formspec = {
    "formspec_version[4]",
    "size[7,7]",
    "bgcolor[;neither]",
    "style_type[image_button;border=false;bgimg=blank.png]",
    "label[0.5,0.5;" .. S("Audio file") .. "]",
    "field[0.5,0.8;6,0.6;bgm;;" .. arena_bgm .. "]",
    "label[0.5,2.2;" .. S("Volume") .. "]",
    "label[0.22,2.61;0]",
    "label[6.55,2.61;100]",
    "scrollbaroptions[max=100;smallstep=1;largestep=10;arrows=hide]",
    "scrollbar[0.5,2.5;6,0.2;;gain;" .. arena_volume .. "]",
    "label[0.5,3.2;" .. S("Pitch") .. "]",
    "label[0.22,3.61;0]",
    "label[6.68,3.61;2]",
    "scrollbar[0.5,3.5;6,0.2;;pitch;" .. arena_pitch .. "]",
    "container[3.05,4.3]",
    "image_button[0,0;0.4,0.4;arenalib_tool_bgm_test.png;play;]",
    "image_button[0.5,0;0.4,0.4;arenalib_tool_bgm_test_stop.png;stop;]",
    "container_end[]",
    "button[2.75,6.2;1.5,0.5;apply;Apply]",
    "field_close_on_enter[bgm;false]",
    "field_close_on_enter[gain;false]",
    "field_close_on_enter[pitch;false]"
  }

  return table.concat(formspec, "")
end



function calc_gain(field)
  return minetest.explode_scrollbar_event(field).value / 100
end



function calc_pitch(field)
  return minetest.explode_scrollbar_event(field).value / 50
end


----------------------------------------------
---------------GESTIONE CAMPI-----------------
----------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)

  if formname ~= "arena_lib:bgm" then return end

  local p_name = player:get_player_name()

  -- se premo su icona "riproduci", riproduco audio
  if fields.play then

    local mod = player:get_meta():get_string("arena_lib_editor.mod")

    if not io.open(minetest.get_modpath(mod) .. "/sounds/" .. fields.bgm .. ".ogg", "r") then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] This audio track doesn't exist!")))
      return end

    if audio_currently_playing[p_name] then
      minetest.sound_stop(audio_currently_playing[p_name])
    end

    audio_currently_playing[p_name] = minetest.sound_play(fields.bgm, {
      to_player = p_name,
      gain      = calc_gain(fields.gain),
      pitch     = calc_pitch(fields.pitch),
      loop = true
    })

  -- se abbandono o premo stop, l'eventuale audio si interrompe
  elseif fields.stop or fields.quit then
    if audio_currently_playing[p_name] then
      minetest.sound_stop(audio_currently_playing[p_name])
      audio_currently_playing[p_name] = nil
    end

  -- applico il tutto
  elseif fields.apply then

    local mod         = player:get_meta():get_string("arena_lib_editor.mod")
    local arena_name  = player:get_meta():get_string("arena_lib_editor.arena")
    local id, arena   = arena_lib.get_arena_by_name(mod, arena_name)

    -- se il campo è vuoto, rimuovo la musica di sottofondo
    if fields.bgm == "" then
      arena_lib.set_bgm(p_name, mod, arena_name, nil, _, _ , true)
    -- se non esiste il file audio, annullo
    elseif not io.open(minetest.get_modpath(mod) .. "/sounds/" .. fields.bgm .. ".ogg", "r") then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] This audio track doesn't exist!")))
      return
    -- sennò applico la traccia indicata
    else
      arena_lib.set_bgm(p_name, mod, arena_name, fields.bgm, calc_gain(fields.gain), calc_pitch(fields.pitch), true)
    end

    if audio_currently_playing[p_name] then
      minetest.sound_stop(audio_currently_playing[p_name])
      audio_currently_playing[p_name] = nil
    end

    minetest.close_formspec(p_name, "arena_lib:bgm")
  end
end)
