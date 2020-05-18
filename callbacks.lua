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



-- Leaving the arena

function arena_lib.on_eliminate(mod, func)
  arena_lib.mods[mod].on_eliminate = func
end



function arena_lib.on_kick(mod, func)
  arena_lib.mods[mod].on_kick = func
end



function arena_lib.on_quit(mod, func)
  arena_lib.mods[mod].on_quit = func
end
