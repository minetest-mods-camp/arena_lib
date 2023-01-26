-- I had no idea how to do it, so this is how Minetest handles global callbacks :D
local function make_registration()
  local t = {}
  local registerfunc = function(func)
    t[#t+1] = func
  end
  return t, registerfunc
end



----------------------------------------------
--------------------GLOBAL--------------------
----------------------------------------------

arena_lib.registered_on_enable, arena_lib.register_on_enable = make_registration()
arena_lib.registered_on_disable, arena_lib.register_on_disable = make_registration()
arena_lib.registered_on_prejoin_queue, arena_lib.register_on_prejoin_queue = make_registration()
arena_lib.registered_on_join_queue, arena_lib.register_on_join_queue = make_registration()
arena_lib.registered_on_leave_queue, arena_lib.register_on_leave_queue = make_registration()
arena_lib.registered_on_load, arena_lib.register_on_load = make_registration()
arena_lib.registered_on_start, arena_lib.register_on_start = make_registration()
arena_lib.registered_on_celebration, arena_lib.register_on_celebration = make_registration()
arena_lib.registered_on_end, arena_lib.register_on_end = make_registration()
arena_lib.registered_on_join, arena_lib.register_on_join = make_registration()
arena_lib.registered_on_eliminate, arena_lib.register_on_eliminate = make_registration()
arena_lib.registered_on_quit, arena_lib.register_on_quit = make_registration()





----------------------------------------------
-----------------PER MINIGAME-----------------
----------------------------------------------

-- Arena management

function arena_lib.on_enable(mod, func)
  arena_lib.mods[mod].on_enable = func
end



function arena_lib.on_disable(mod, func)
  arena_lib.mods[mod].on_disable = func
end



-- Queues

function arena_lib.on_prejoin_queue(mod, func)
  arena_lib.mods[mod].on_prejoin_queue = func
end



function arena_lib.on_join_queue(mod, func)
  arena_lib.mods[mod].on_join_queue = func
end



function arena_lib.on_leave_queue(mod, func)
  arena_lib.mods[mod].on_leave_queue = func
end



-- Arena phases

function arena_lib.on_load(mod, func)
  arena_lib.mods[mod].on_load = func
end



function arena_lib.on_start(mod, func)
 arena_lib.mods[mod].on_start = func
end



function arena_lib.on_join(mod, func)
 arena_lib.mods[mod].on_join = func
end



function arena_lib.on_celebration(mod, func)
 arena_lib.mods[mod].on_celebration = func
end



function arena_lib.on_end(mod, func)
  arena_lib.mods[mod].on_end = func
end



-- Events taking place inside the arena

function arena_lib.on_death(mod, func)
  arena_lib.mods[mod].on_death = func
end



function arena_lib.on_respawn(mod, func)
  arena_lib.mods[mod].on_respawn = func
end



function arena_lib.on_change_spectated_target(mod, func)
  arena_lib.mods[mod].on_change_spectated_target = func
end



function arena_lib.on_time_tick(mod, func)
  arena_lib.mods[mod].on_time_tick = func
end



function arena_lib.on_timeout(mod, func)
  arena_lib.mods[mod].on_timeout = func
end


-- Leaving the arena

function arena_lib.on_eliminate(mod, func)
  arena_lib.mods[mod].on_eliminate = func
end



function arena_lib.on_prequit(mod, func)
  arena_lib.mods[mod].on_prequit = func
end



function arena_lib.on_quit(mod, func)
  arena_lib.mods[mod].on_quit = func
end





----------------------------------------------
------------------DEPRECATED------------------
----------------------------------------------

function arena_lib.on_kick(mod, func)
  arena_lib.mods[mod].on_kick = func
end



function arena_lib.on_disconnect(mod, func)
  arena_lib.mods[mod].on_disconnect = func
end
