
local players_jumping = {} --KEY: player, VALUE: boolean

--Hopefully waiting on https://github.com/minetest/minetest/issues/9626, in the meanwhile..
--[[minetest.register_globalstep(function(dtime)

  for pl_name, id in pairs(arena_lib.get_players_in_game()) do

    local pl = minetest.get_player_by_name(pl_name)

    if pl:get_player_control().aux1 then
      arena_lib.on_AUX1_pressed(pl)
    end

    -- L'handler del salto non è perfetto ed è stata aperta una issue qui: https://github.com/minetest/minetest/issues/9631
    -- preferisco tenerlo disattivato al momento piuttosto che computare cose inutili
    --[[
    if pl:get_player_control().jump and pl:get_hp() > 0 and not players_jumping[pl_name] then

      local pos = pl:get_pos()
      local pos_feet = {x = pos.x, y = pos.y-0.501, z = pos.z}
      local drawtype = minetest.registered_nodes[minetest.get_node(pos_feet).name]["drawtype"]

      if drawtype ~= "normal" and drawtype ~= "glasslike" and drawtype ~= "nodebox" then return end
      players_jumping[pl_name] = true

      arena_lib.on_jump(pl)

      minetest.after(0.2, function()
        players_jumping[pl_name] = false
      end)
    end

  end
end)]]



function arena_lib.on_AUX1_pressed(pl)
  --Override me
end



function arena_lib.on_jump(player)
  --Override me
end



function arena_lib.register_player_inputs(p_name)
  players_jumping[p_name] = false
end



--[[function arena_lib.is_player_jumping(p_name)
  if players_jumping[p_name] then return true
  else return false
  end
end]]
