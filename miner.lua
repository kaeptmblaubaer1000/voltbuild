miner = {}
voltbuild.metadata_check.pipe = function (pos,listname,stack,maxtier)
	if stack:get_name() == "voltbuild:mining_pipe" then
		return stack:get_count()
	else
		return 0
	end
end
voltbuild.metadata_check.drill = function (pos,listname,stack,maxtier)
	if stack:get_name() == "voltbuild:mining_drill" or stack:get_name() == "voltbuild:diamond_drill" or stack:get_name() == "voltbuild:mining_drill_discharged" or stack:get_name() == "voltbuild:diamond_drill_discharged" then
		return stack:get_count()
	else
		return 0
	end
end
voltbuild.metadata_check.scanner = function (pos,listname,stack,maxtier)
	if stack:get_name() == "voltbuild:od_scanner" or stack:get_name() == "voltbuild:ov_scanner" then
		return stack:get_count()
	else
		return 0
	end
end

minetest.register_node("voltbuild:mining_pipe",{description="Mining pipe",
	groups={cracky=2},
	drawtype = "nodebox",
	node_box = {
			type = "fixed",
			fixed = {{-2/16,-8/16,-2/16,2/16,8/16,2/16}}
		},
	tiles={"itest_mining_pipe.png"},
	paramtype = "light",
})

minetest.register_node("voltbuild:miner", {
	description = "Miner",
	tiles = {"itest_electric_furnace_side.png", "itest_electric_furnace_side.png", "itest_electric_furnace_side.png", "itest_electric_furnace_side.png", "itest_electric_furnace_side.png", "itest_electric_furnace_front.png"},
	groups = {energy=1, energy_consumer=1, cracky=2},
	sounds = default.node_sound_stone_defaults(),
	voltbuild = {max_psize = 32,
		max_energy = 10000,max_tier=1,max_stress=2000,active=true},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_int("stime",0)
		local inv = meta:get_inventory()
		inv:set_size("pipe", 1)
		inv:set_size("drill",1)
		inv:set_size("scanner",1)
		meta:set_string("formspec", consumers.get_formspec(pos)..
				"list[current_name;pipe;2,1;1,1;]"..
				"list[current_name;drill;4,1;1,1;]"..
				"list[current_name;scanner;4,3;1,1;]")
		consumers.on_construct(pos)
	end,
	can_dig = voltbuild.can_dig,
	allow_metadata_inventory_put = voltbuild.allow_metadata_inventory_put,
	allow_metadata_inventory_move = voltbuild.allow_metadata_inventory_move,
})

function miner.eject_item(pos,item)
	for _,d in ipairs(adjlist) do
		local npos = addVect(d,pos)
		local nname = minetest.env:get_node(npos).name
		if nname == "default:chest" then
			local meta = minetest.env:get_meta(npos)
			local inv = meta:get_inventory()
			if inv:room_for_item("main",item) then
				inv:add_item("main",item)
				return
			end
		end
	end
	local droppos = {x=pos.x,y=pos.y+1,z=pos.z}
	local obj = minetest.env:add_item(droppos,item)
	if obj ~= nil then
		obj:setvelocity({x=(math.random()-0.5),y=math.random()+1,z=(math.random()-0.5)})
	end
end

function miner.dig_towards_ore(tpos,radius)
	local lpos,lname
	for x=-radius,radius do
	for z=-radius,radius do
		if z~=0 or x~=0 then
			lpos = {x=tpos.x+x,y=tpos.y,z=tpos.z+z}
			lname = minetest.env:get_node(lpos).name
			if voltbuild.registered_ores[lname] then return lpos end
		end
	end
	end
	return tpos
end

components.register_abm({
	nodenames = {"voltbuild:miner"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		consumers.discharge(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",consumers.get_formspec(pos)..
				"list[current_name;pipe;2,1;1,1;]"..
				"list[current_name;drill;4,1;1,1;]"..
				"list[current_name;scanner;4,3;1,1;]")
		local inv = meta:get_inventory()
		local drill = inv:get_stack("drill",1)
		if drill:is_empty() then
			local tpos = {x=pos.x,y=pos.y-1,z=pos.z}
			local name = minetest.env:get_node(tpos).name
			while name == "voltbuild:mining_pipe" do
				tpos = {x=tpos.x,y=tpos.y-1,z=tpos.z}
				name = minetest.env:get_node(tpos).name
			end
			if name == "ignore" then return end
			tpos = {x=tpos.x,y=tpos.y+1,z=tpos.z}
			local name = minetest.env:get_node(tpos).name
			if name~="voltbuild:mining_pipe" then return end
			minetest.env:set_node(tpos,{name="air"})
			miner.eject_item(pos,ItemStack("voltbuild:mining_pipe"))
			return
		end
		local pipe = inv:get_stack("pipe",1)
		if pipe:is_empty() then return end
		local ntime
		local e = 0
		if drill:get_name() == "voltbuild:mining_drill" or drill:get_name() == "voltbuild:mining_drill_discharged" then
			ntime = 4
			e = e + 450
		elseif drill:get_name() == "voltbuild:diamond_drill" or drill:get_name() == "voltbuild:diamond_drill_discharged" then
			ntime = 1
			e = e + 900
		end
		local scanner = inv:get_stack("scanner",1)
		local radius
		if scanner:get_name() == "voltbuild:od_scanner" then
			radius = 2
			e = e + 70
		elseif scanner:get_name() == "voltbuild:ov_scanner" then
			radius = 4
			e = e + 180
		else
			radius = 0
		end
		local stime = meta:get_int("stime")
		meta:set_int("stime",stime+1)
		if stime >= ntime-1 then
			meta:set_int("stime",0)
			local energy = meta:get_int("energy")
			if energy < e then
				meta:set_int("stime",stime)
				return
			end

			local tpos = {x=pos.x,y=pos.y-1,z=pos.z}
			local name = minetest.env:get_node(tpos).name
			while name == "voltbuild:mining_pipe" do
				tpos = {x=tpos.x,y=tpos.y-1,z=tpos.z}
				name = minetest.env:get_node(tpos).name
			end
			if name == "ignore" then
				meta:set_int("stime",stime)
				return
			end
			
			meta:set_int("energy",energy-e)
			todig = miner.dig_towards_ore(tpos,radius)
			local tname = minetest.env:get_node(todig).name
			local itemstacks = minetest.get_node_drops(tname,"default:pick_mese")
			for _, item in ipairs(itemstacks) do
				miner.eject_item(pos,item)
			end
			minetest.env:set_node(todig,{name = "air"})
			if todig.x==tpos.x and todig.y==tpos.y and todig.z==tpos.z then
				minetest.env:set_node(tpos,{name="voltbuild:mining_pipe"})
				pipe:take_item()
				inv:set_stack("pipe",1,pipe)
			end
		end
		meta:set_string("formspec",consumers.get_formspec(pos)..
				"list[current_name;pipe;2,1;1,1;]"..
				"list[current_name;drill;4,1;1,1;]"..
				"list[current_name;scanner;4,3;1,1;]")
	end,
})

voltbuild.register_ore("default:stone_with_coal", 1)
voltbuild.register_ore("default:stone_with_iron", 4)
voltbuild.register_ore("default:stone_with_mese", 24)
voltbuild.register_ore("default:stone_with_gold", 3)
voltbuild.register_ore("default:stone_with_diamond", 5)
voltbuild.register_ore("default:mese", 216)
voltbuild.register_ore("default:stone_with_copper", 2)
voltbuild.register_ore("voltbuild:stone_with_tin", 2)
voltbuild.register_ore("voltbuild:stone_with_uranium", 4)

voltbuild.register_ore("moreores:mineral_tin", 2)
voltbuild.register_ore("moreores:mineral_copper", 2)
voltbuild.register_ore("moreores:mineral_gold", 3)
voltbuild.register_ore("moreores:mineral_mithril", 5)

voltbuild.register_ore("technic:mineral_uranium", 4)
voltbuild.register_ore("technic:mineral_chromium", 4)
voltbuild.register_ore("technic:mineral_zinc", 2)
