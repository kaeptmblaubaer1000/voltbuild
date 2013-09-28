minetest.register_node("voltbuild:watermill",{description="Watermill",
	groups={energy=1,cracky=2},
	tiles={"itest_watermill_top.png", "itest_watermill_top.png", "itest_watermill_side.png"},
	voltbuild = {max_energy=500,max_tier=1,max_stress=2000,
		energy_produce= function (pos)
		local meta=minetest.env:get_meta(pos)
		local prod = 0
		for x = pos.x-1, pos.x+1 do
		for y = pos.y-1, pos.y+1 do
		for z = pos.z-1, pos.z+1 do
			local n = minetest.env:get_node({x=x,y=y,z=z})
			if n.name == "default:water_source" or n.name == "default:water_flowing" then
				prod = prod+1
			end
		end
		end
		end
		if prod==0 then
			local energy = meta:get_int("energy")
			local use = math.min(energy,3)
			return use, energy-use
		else
			meta:set_int("energyf",meta:get_int("energyf")+prod%100)
			if meta:get_int("energyf") >= 100 then
				meta:set_int("energyf",meta:get_int("energyf")-100)
				return ((math.floor(prod/2)*2)+1)
			else
				return ((math.floor(prod/2))*2)
			end
		end
		end},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_int("energyf",0)
		meta:set_string("formspec", generators.get_formspec(pos)..
				"image["..voltbuild.image_location.."voltbuild_water.png]")
		generators.on_construct(pos)
	end,
	can_dig = generators.can_dig,
	allow_metadata_inventory_put = voltbuild.allow_metadata_inventory_put,
	allow_metadata_inventory_move = voltbuild.allow_metadata_inventory_move,
})

components.register_abm({
	nodenames={"voltbuild:watermill"},
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
				"image["..voltbuild.image_location.."voltbuild_water.png]")
	end
})
