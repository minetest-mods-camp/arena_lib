local S = minetest.get_translator("arena_lib")

local function get_bgm_formspec() end
local function file_exists() end
local function calc_gain() end
local function calc_pitch() end

local audio_currently_playing = {}     -- KEY p_name; VALUE sound handle



minetest.register_tool("arena_lib:customise_bgm", {

    description = S("Background music"),
    inventory_image = "arenalib_customise_bgm.png",
    groups = {not_in_creative_inventory = 1},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local mod         = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name  = user:get_meta():get_string("arena_lib_editor.arena")
      local id, arena   = arena_lib.get_arena_by_name(mod, arena_name)

      minetest.show_formspec(user:get_player_name(), "arena_lib:bgm", get_bgm_formspec(arena))
    end
})





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function get_bgm_formspec(arena)
  local bgm = ""
  local bgm_title = ""
  local bgm_author = ""
  local bgm_volume = 100
  local bgm_pitch = 50

  if arena.bgm then
    bgm = arena.bgm.track
    bgm_title = arena.bgm.title or ""
    bgm_author = arena.bgm.author or ""
    bgm_volume = arena.bgm.gain * 100
    bgm_pitch = arena.bgm.pitch * 50
  end

  local formspec = {
    "formspec_version[4]",
    "size[7,7.5]",
    "bgcolor[;neither]",
    "style_type[image_button;border=false;bgimg=blank.png]",
    -- area attributi
    "container[0.5,0.5]",
    "label[0,0;" .. S("Audio file") .. "]",
    "field[0,0.41;6,0.6;bgm;;" .. bgm .. "]",
    "hypertext[-0.05,0.13;6,0.3;audio_info;<style size=12 font=mono color=#b7aca3>(" .. S("leave empty to remove the current track") .. ")</style>]",
    "container[0,1.35]",
    "label[0,0;" .. S("Title") .. "]",
    "field[0,0.2;2.99,0.6;title;;" .. bgm_title .. "]",
    "label[3,0;" .. S("Author") .. "]",
    "field[3,0.2;3,0.6;author;;" .. bgm_author .. "]",
    "container_end[]",
    "container_end[]",
    -- area ritocchi
    "container[0.5,3.5]",
    "label[0,0;" .. S("Volume") .. "]",
    "label[0,0.41;0]",
    "label[5.64,0.41;100]",
    "scrollbaroptions[max=100;smallstep=1;largestep=10;arrows=hide]",
    "scrollbar[0.4,0.3;5.2,0.2;;gain;" .. bgm_volume .. "]",
    "label[0,1;" .. S("Pitch") .. "]",
    "label[0,1.41;0]",
    "label[5.9,1.41;2]",
    "scrollbar[0.4,1.3;5.2,0.2;;pitch;" .. bgm_pitch .. "]",
    "container[2.55,2.1]",
    "image_button[0,0;0.4,0.4;arenalib_tool_bgm_test.png;play;]",
    "image_button[0.5,0;0.4,0.4;arenalib_tool_bgm_test_stop.png;stop;]",
    "container_end[]",
    "container_end[]",
    "button[2.75,6.7;1.5,0.5;apply;" .. S("Apply") .."]",
    "field_close_on_enter[bgm;false]",
    "field_close_on_enter[gain;false]",
    "field_close_on_enter[pitch;false]"
  }

  return table.concat(formspec, "")
end



function file_exists(name, mod, p_name)
  local bgm_dir = minetest.get_worldpath() .. "/arena_lib/BGM/"
  local content = minetest.get_dir_list(bgm_dir, false)

  local function iterate_dirs(dir)
    for _, f_name in pairs(minetest.get_dir_list(dir, false)) do
      local file = io.open(dir .. "/" .. name .. ".ogg", "r")
      if file then
        io.close(file)
        return true
      end
    end

    for _, subdir in pairs(minetest.get_dir_list(dir, true)) do
       if iterate_dirs(dir .. "/" .. subdir) then
         return true
       end
    end
  end

  local exists = iterate_dirs(bgm_dir)

  --v------------------ LEGACY UPDATE, to remove in 7.0 -------------------v (insieme a 'mod' e 'p_name' come parametro)
  if not exists then
    local deprecated_file = io.open(minetest.get_modpath(mod) .. "/sounds/" .. name .. ".ogg", "r")
    if deprecated_file then
      deprecated_file:close()
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", "[arena_lib] loading sounds from the minigame folder is deprecated and it'll be removed in future versions: put it into the world folder instead!"))
      exists = true
    end
  end
  --^------------------ LEGACY UPDATE, to remove in 7.0 -------------------^

  return exists
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

    if not file_exists(fields.bgm, mod, p_name) then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] File not found!")))
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
    local title       = fields.title ~= "" and minetest.formspec_escape(fields.title) or nil
    local author      = fields.author ~= "" and minetest.formspec_escape(fields.author) or nil

    arena_lib.set_bgm(p_name, mod, arena_name, fields.bgm, title, author, calc_gain(fields.gain), calc_pitch(fields.pitch), true)

    if audio_currently_playing[p_name] then
      minetest.sound_stop(audio_currently_playing[p_name])
      audio_currently_playing[p_name] = nil
    end

    minetest.close_formspec(p_name, "arena_lib:bgm")
  end
end)
