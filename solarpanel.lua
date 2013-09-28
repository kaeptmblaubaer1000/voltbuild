minetest.register_node("voltbuild:solar_panel",{description="Solar panel",
	groups={energy=1,cracky=2},
	tiles={"itest_solar_panel_top.png", "itest_solar_panel_side.png", "itest_solar_panel_side.png"},
	voltbuild = {max_energy=500,max_tier=1,max_stress=2000, active=true,
		energy_produce = function (pos)
			local l=minetest.env:get_node_light({x=pos.x, y=pos.y+1, z=pos.z})
			local meta=minetest.env:get_meta(pos)
			if l<15 then
				local energy = meta:get_int("energy")
				local use = math.min(energy,2)
				return use,energy-use
			else
				return l
			end
		end},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_string("formspec", generators.get_formspec(pos)..
				"image["..voltbuild.image_location.."itest_sun.png]")
		generators.on_construct(pos)
	end,
	can_dig = generators.can_dig,
	allow_metadata_inventory_put =  voltbuild.allow_metadata_inventory_put,
	allow_metadata_inventory_move = voltbuild.allow_metadata_inventory_move,
})

components.register_abm({
	nodenames={"voltbuild:solar_panel"},
	interval=1.0,
	chance=1,
	action = function(pos, node, active_object_count, active_objects_wider)
		local meta = minetest.env:get_meta(pos)
		local energy,leftover = minetest.registered_nodes[node.name]["voltbuild"]["energy_produce"](pos)
		if leftover then
			meta:set_int("energy",leftover)
		end
		generators.produce(pos,energy)
		meta:set_string("formspec",generators.get_formspec(pos)..
				"image["..voltbuild.image_location.."itest_sun.png]")
	end
})
