local function load_world_folder()
  local wrld_dir = minetest.get_worldpath() .. "/arena_lib"
  local bgm_dir = wrld_dir .. "/BGM"

  local content = minetest.get_dir_list(wrld_dir)
  local modpath = minetest.get_modpath("arena_lib")

  if not next(content) then
    local src_dir = modpath .. "/IGNOREME"
    minetest.cpdir(src_dir, wrld_dir)
    os.remove(wrld_dir .. "/README.md")

    --v------------------ LEGACY UPDATE, to remove in 7.0 -------------------v
    local old_settings = io.open(modpath .. "/SETTINGS.lua", "r")

    if old_settings then
      minetest.safe_file_write(wrld_dir .. "/SETTINGS.lua", old_settings:read("*a"))
      old_settings:close()
      os.remove(modpath .. "/SETTINGS.lua")
    end
    --^------------------ LEGACY UPDATE, to remove in 7.0 -------------------^

  else
    -- aggiungi musiche come contenuti dinamici per non appesantire il server
    local function iterate_dirs(dir)
      for _, f_name in pairs(minetest.get_dir_list(dir, false)) do
        minetest.dynamic_add_media({filepath = dir .. "/" .. f_name}, function(name) end)
      end
      for _, subdir in pairs(minetest.get_dir_list(dir, true)) do
        iterate_dirs(dir .. "/" .. subdir)
      end
    end

    -- non si possono aggiungere contenuti dinamici all'avvio del server
    minetest.after(0.1, function()
      iterate_dirs(bgm_dir)
    end)
  end
end

load_world_folder()
