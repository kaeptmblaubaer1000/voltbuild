wind_speed = 15

minetest.register_node("voltbuild:windmill",{description="Windmill",
	groups={energy=1,cracky=2},
	tiles={"itest_windmill_top.png", "itest_windmill_top.png", "itest_windmill_side.png"},
	voltbuild = {max_energy=500,max_tier=1,max_stress=2000,
		energy_produce=function(pos)
			local alt = pos.y
			if alt > 200 then alt = 200 end
			local meta=minetest.env:get_meta(pos)
			local prod=wind_speed*(alt-meta:get_int("obstacles"))
			if prod<=0 then
				local energy = meta:get_int("energy")
				local use = math.min(energy,5)
				return use,energy-use
			else 
				meta:set_int("energyf",meta:get_int("energyf")+prod%750)
				if meta:get_int("energyf") >= 300 then
					meta:set_int("energyf",meta:get_int("energyf")-750)
					return (math.floor(prod/100))+1
				else
					return math.floor(prod/100)
				end
			end
		end},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_int("energyf",0)
		meta:set_int("obstacles",200)
		meta:set_string("formspec", generators.get_formspec(pos)..
				"image["..voltbuild.image_location.."voltbuild_wind_symbol.png]")
		generators.on_construct(pos)
	end,
	can_dig = generators.can_dig,
	allow_metadata_inventory_put = voltbuild.allow_metadata_inventory_put,
	allow_metadata_inventory_move = voltbuild.allow_metadata_inventory_move,
})

components.register_abm({
	nodenames={"voltbuild:windmill"},
	interval=1.0,
	chance=1,
	action = function(pos, node, active_object_count, active_objects_wider)
		local alt = pos.y
		if alt > 200 then alt = 200 end
		local meta=minetest.env:get_meta(pos)
		local prod=wind_speed*(alt-meta:get_int("obstacles"))
		local prod_energy, leftover = minetest.registered_nodes[node.name]["voltbuild"]["energy_produce"](pos)
		if leftover then
			meta:set_int("energy",leftover)
		end
		generators.produce(pos,prod_energy)
		if prod >= 2050 then
			local stress = meta:get_int("stress")
			meta:set_int("stress",stress+(math.random(1,((prod-2050)+10))))
		end
		meta:set_string("formspec",generators.get_formspec(pos)..
				"image["..voltbuild.image_location.."voltbuild_wind_symbol.png]")
	end
})

--counts obstacles around the windmill, so not meant to be run as a components abm
minetest.register_abm({
	nodenames={"voltbuild:windmill"},
	interval=20,
	chance=1,
	action = function(pos, node, active_object_count, active_objects_wider)
		local obstacles = 0
		for x = pos.x-4,pos.x+4 do
		for y = pos.y-2,pos.y+4 do
		for z = pos.z-4,pos.z+4 do
			local n = minetest.env:get_node({x=x,y=y,z=z})
			if n.name ~= "air" and n.name ~= "ignore" then
				obstacles = obstacles + 1
			end
		end
		end
		end
		local meta = minetest.env:get_meta(pos)
		meta:set_int("obstacles",obstacles)
		math.randomseed(os.time())
		wind_speed =  math.random(0,15)
	end
})
