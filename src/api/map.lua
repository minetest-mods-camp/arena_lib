----------------------------------------------------------
-- stop people from editing the map if can_build is false
local old_is_protected = minetest.is_protected

function minetest.is_protected(pos, name)
  local arena = arena_lib.get_arena_by_player(name)

  if arena and arena.in_game then
    local mod = arena_lib.get_mod_by_player(name)
    if not arena_lib.mods[mod].can_build then
      return true
    end
  end

  return old_is_protected(pos, name)
end
----------------------------------------------------------





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

function arena_lib.is_player_in_region(arena, p_name)
    if not arena then return end

    if not arena.pos1 then
      minetest.log("[ARENA_LIB] Attempt to check whether a player is inside an arena region (" .. arena.name .. "), when the arena has got no region declared")
      return end

    local v1, v2  = vector.sort(arena.pos1, arena.pos2)
    local region  = VoxelArea:new({MinEdge=v1, MaxEdge=v2})
    local p_pos   = minetest.get_player_by_name(p_name):get_pos()

    return region:containsp(p_pos)
  end