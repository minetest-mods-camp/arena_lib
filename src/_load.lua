local function load_world_folder()
  local wrld_dir = minetest.get_worldpath() .. "/arena_lib"
  local content = minetest.get_dir_list(wrld_dir)

  if not next(content) then
    local modpath = minetest.get_modpath("arena_lib")
    local src_dir = modpath .. "/IGNOREME"

    minetest.cpdir(src_dir, wrld_dir)
    os.remove(wrld_dir .. "/README.md")
    os.remove(wrld_dir .. "/BGM/.gitkeep")
    os.remove(wrld_dir .. "/Thumbnails/.gitkeep")

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
        -- NOT REALLY DYNAMIC MEDIA, since it's run when the server launches and there are no players online
        -- it's just to load these tracks from the world folder (so that `sound_play` recognises them without the full path)
        minetest.dynamic_add_media({filepath = dir .. "/" .. f_name}, function(name) end)
      end
      for _, subdir in pairs(minetest.get_dir_list(dir, true)) do
        iterate_dirs(dir .. "/" .. subdir)
      end
    end

    -- non si possono aggiungere contenuti dinamici all'avvio del server
    minetest.after(0.1, function()
      iterate_dirs(wrld_dir .. "/BGM")
      iterate_dirs(wrld_dir .. "/Thumbnails")
    end)
  end
end

load_world_folder()
