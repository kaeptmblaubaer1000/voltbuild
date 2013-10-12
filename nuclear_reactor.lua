dofile(modpath.."/automata.lua")
nuclear = {}
nuclear.neighbors = {}
nuclear.radbar_location =  "0,4;1,1"
nuclear.stressbar_location =  "1,4;1,1"
nuclear.chargebar_location =  "2,4;1,1"
nuclear.inventory_width = 7
nuclear.max_radiation = 100

nuclear.neighbor_left = function (index,width,size)
	if (index%width ~= 1 and index > 0 and index <= size) then
		return (index-1)
	end
	return nil
end
nuclear.neighbor_right = function (index,width,size)
	if (index%width ~= 0 and index > 0 and index < size)then 
		return (index+1)
	end
	return nil
end
nuclear.neighbor_top = function (index,width,size)
	if (index-width > 0 and index-width <= size) then
		return(index-width)
	end
	return nil
end
nuclear.neighbor_bottom = function (index,width,size)
	if (index+width > 0 and index+width <= size) then
		return(index+width)
	end
	return nil
end
nuclear.get_neighbors = function (index,inventory)
	local width = inventory:get_width("nuclear")
	local size = inventory:get_size("nuclear")
	local neighbors = {}
	table.insert(neighbors,nuclear.neighbor_left(index,width,size))
	table.insert(neighbors,nuclear.neighbor_right(index,width,size))
	table.insert(neighbors,nuclear.neighbor_top(index,width,size))
	table.insert(neighbors,nuclear.neighbor_bottom(index,width,size))
	return neighbors
end

nuclear.get_steam_neighbors = function (index,inventory)
	local width = inventory:get_width("nuclear")
	local size = inventory:get_size("nuclear")
	local neighbors = {}
	table.insert(neighbors,nuclear.neighbor_left(index,width,size))
	table.insert(neighbors,nuclear.neighbor_right(index,width,size))
	table.insert(neighbors,nuclear.neighbor_top(index,width,size))
	return neighbors
end

nuclear.neighbors.automata_rads = function (index,inventory)
	local width = inventory:get_width("nuclear")
	local size = inventory:get_size("nuclear")
	local neighbors = nuclear.get_neighbors(index,inventory)
	local checked_neighbors = {}
	local neigh = nil
	local key = nil
	for key,neigh in pairs(neighbors) do
		local name = inventory:get_stack("nuclear",neigh):get_name()
		if name ~= "voltbuild:radioactive_shielding" and name ~= "voltbuild:shielded_reactor_wiring" then
			table.insert(checked_neighbors,neigh)
		end
	end

	return checked_neighbors
end

nuclear.neighbors.automata_heat = function (index,inventory)
	local width = inventory:get_width("nuclear")
	local size = inventory:get_size("nuclear")
	local neighbors = nuclear.get_steam_neighbors(index,inventory)
	local checked_neighbors = {}
	local key = nil
	for key,neigh in pairs(neighbors) do
		if inventory:get_stack("nuclear",neigh):get_name() ~= "voltbuild:casing" then
			table.insert(checked_neighbors,neigh)
		end
	end

	return checked_neighbors
end

nuclear.neighbors.automata_energy = function (index,inventory)
	local width = inventory:get_width("nuclear")
	local size = inventory:get_size("nuclear")
	local neighbors = nuclear.get_neighbors(index,inventory)
	local checked_neighbors = {}
	local neigh = nil
	local key = nil
	for key,neigh in pairs(neighbors) do
		local name = inventory:get_stack("nuclear",neigh):get_name()
		if name == "voltbuild:reactor_wiring" or name == "voltbuild:shielded_reactor_wiring" then
			table.insert(checked_neighbors,neigh)
		end
	end

	return checked_neighbors
end

minetest.register_craftitem("voltbuild:radioactive_shielding", {
	description = "Radioactive Shielding",
	inventory_image = "voltbuild_radioactive_shielding.png",
	voltbuild = {nuclear=1},
})

local reactor_wiring = {
	description = "Reactor Wiring",
	inventory_image = "voltbuild_reactor_wiring.png",
	voltbuild = {nuclear=1},
	automata = {step = function(automata_name,automata_pos,index)
		local meta = minetest.env:get_meta(automata_pos)
		local inv = meta:get_inventory()
		if automata_name == "automata_energy" then
			local neighbors = nuclear.neighbors[automata_name](index,inv)
			local energy = meta:get_int(automata_name..index)/(#neighbors+1)
			local key = nil
			for key,neighbor in pairs(neighbors) do
				--prevents rolling over to negative by using previous value with
				--max
				meta:set_int(automata_name..neighbor,math.max(meta:get_int(automata_name..neighbor)+energy,meta:get_int(automata_name..neighbor)))
			end
			if #neighbors > 0 then
				meta:set_int(automata_name..index,energy)
			end
		end
	end
	},
}

minetest.register_craftitem("voltbuild:reactor_wiring",reactor_wiring) 
reactor_wiring.description = "Shielded Reactor Wiring"
reactor_wiring.inventory_image = "voltbuild_shielded_reactor_wiring.png"
minetest.register_craftitem("voltbuild:shielded_reactor_wiring",reactor_wiring) 

minetest.register_craftitem("voltbuild:casing", {
	description = "Reactor Heat Casing",
	inventory_image = "voltbuild_casing.png",
	voltbuild = {nuclear=1},
})

minetest.register_craftitem("voltbuild:nuclear_reaction_chamber", {
	description = "Reaction Chamber",
	inventory_image = "voltbuild_reaction_chamber.png",
	voltbuild = {nuclear=1},
	automata = {step = function(automata_name,automata_pos,index)
		local meta = minetest.env:get_meta(automata_pos)
		local inv = meta:get_inventory()
		local uranium = inv:get_stack("nuclear_fuel",1)
		if not uranium:is_empty() then
			local stime = meta:get_float("stime")
			local neighbors = nuclear.neighbors[automata_name](index,inv)
			local num_neighbors = #neighbors
			local key = nil
			for key,neighbor in pairs(neighbors) do
				local n_val = meta:get_int(automata_name..neighbor)
				if automata_name == "automata_rads" then
					--math.min prevents c style int from going too
					--high that it rolls over to negative
					meta:set_int(automata_name..neighbor,math.min(n_val+1,nuclear.max_radiation))
				elseif automata_name == "automata_heat" then
					if n_val+(100/num_neighbors) < 2000 then
						meta:set_int(automata_name..neighbor,n_val+(100/num_neighbors))
					else
						meta:set_int("stress",meta:get_int("stress")+100/num_neighbors)
					end
				elseif automata_name == "automata_energy" then
					--prevents rolling over to negative by using previous 
					--value with max
					meta:set_float("stime",meta:get_float("stime")+0.1)
					meta:set_int(automata_name..neighbor,math.max(n_val+128/num_neighbors,n_val))
					while meta:get_float("stime") > meta:get_float("fburntime") do
						local leftover = inv:get_stack("nuclear_fuel",1)
						leftover:take_item()
						inv:set_stack("nuclear_fuel",1,leftover)
						meta:set_float("stime",meta:get_float("stime")-meta:get_float("fburntime"))
					end
					if meta:get_float("stime") < 0.0 then
						meta:set_float("stime",0.0)
					end
				end
			end
			if next(neighbors) == nil then
				if automata_name == "automata_heat" then
					meta:set_int("stress",meta:get_int("stress")+100)
				elseif automata_name == "automata_rads" then
					meta:set_int("automata_rads"..index,math.min(meta:get_int("automata_rads"..index)+1,nuclear.max_radiation))
				elseif automata_name == "automata_energy" then
					meta:set_float("stime",meta:get_float("stime")+0.1)
					while meta:get_float("stime") > meta:get_float("fburntime") do
						local leftover = inv:get_stack("nuclear_fuel",1)
						leftover:take_item()
						inv:set_stack("nuclear_fuel",1,leftover)
						meta:set_float("stime",meta:get_float("stime")-meta:get_float("fburntime"))
					end
					if meta:get_float("stime") < 0.0 then
						meta:set_float("stime",0.0)
					end
				end
			end
		end
	end},
})

--nuclear_reactor has a custom formspec for it's special customizability
nuclear.get_formspec = function(pos)
	local meta = minetest.env:get_meta(pos)
	local rad_percent = math.min((meta:get_int("rads")/nuclear.max_radiation)*100,100)
	local stress_percent = math.min((meta:get_int("stress")/minetest.registered_nodes["voltbuild:nuclear_reactor"]["voltbuild"]["max_stress"])*100,100)
	local energy_percent = voltbuild.get_percent(pos)
	local formspec = "size[10,10]"..
	"list[current_player;main;1,6;8,4;]"..
	"list[current_name;components;0,1;2,3;]"..
	"list[current_name;nuclear_fuel;2,3;1,1;]"..
	"list[current_name;nuclear;3,0;"..nuclear.inventory_width..",5;]"..
	"image["..nuclear.radbar_location..";itest_charge_bg.png^[lowpart:"..rad_percent..":voltbuild_rads_bar.png]"..
	"image["..nuclear.stressbar_location..";itest_charge_bg.png^[lowpart:"..stress_percent..":voltbuild_stress_bar.png]"..
	"image["..nuclear.chargebar_location..";itest_charge_bg.png^[lowpart:"..energy_percent..":itest_charge_fg.png]"
	return formspec
end

voltbuild.metadata_check.nuclear_fuel = function (pos,listname,stack,maxtier)
	if stack:get_name() == "voltbuild:uranium_lump" then
		return stack:get_count()
	end
	return 0
end

voltbuild.metadata_check.nuclear = function (pos,listname,stack,maxtier)
	local meta = minetest.env:get_meta(pos)
	local item = minetest.registered_items[stack:get_name()]
	local nuclear = nil
	if item and item.voltbuild then
		nuclear = item.voltbuild.nuclear
	end
	if nuclear and nuclear == 1 then
		return stack:get_count()
	end
	return 0
end


minetest.register_node("voltbuild:nuclear_reactor", {
	description="Nuclear Reactor",
	tiles = {"voltbuild_nuclear_reactor.png","voltbuild_nuclear_reactor.png",
		"voltbuild_nuclear_reactor.png","voltbuild_nuclear_reactor.png",
		"voltbuild_nuclear_reactor.png","voltbuild_nuclear_reactor.png"},
	paramtype2 = "facedir",
	groups = {energy=1, cracky=2},
	voltbuild = {max_energy=4000,max_tier=1,max_stress=2000,energy_produce=10},
	tube={insert_object=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:add_item("nuclear_fuel",stack)
		end,
		can_insert=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return (voltbuild.allow_metadata_inventory_put(pos,"nuclear_fuel",
				nil,stack,nil) and
				inv:room_for_item("nuclear_fuel",stack))

		end,},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		local node = minetest.env:get_node(pos)
		meta:set_string("infotext",voltbuild_create_infotext(node.name))
		meta:set_string("formspec",nuclear.get_formspec(pos))
		meta:set_int("rads",0)
		local inv = meta:get_inventory()
		inv:set_size("components",6)
		inv:set_size("nuclear_fuel",1)
		inv:set_size("nuclear",35)
		inv:set_width("nuclear",nuclear.inventory_width)
		automata:new(pos,"nuclear","automata_rads")
		automata:new(pos,"nuclear","automata_heat")
		automata:new(pos,"nuclear","automata_energy")
	end,
	can_dig = voltbuild.can_dig,
	allow_metadata_inventory_put = voltbuild.allow_metadata_inventory_put,
	allow_metadata_inventory_move = voltbuild.allow_metadata_inventory_move,
	on_blast = function(pos,intensity)
		local meta = minetest.env:get_meta(pos)
		local rads = meta:get_int("rads")
		local xVect,yVect,zVect
		local blast_size = 20
		local objects = minetest.get_objects_inside_radius(pos,blast_size)
		local manip = minetest.get_voxel_manip()
		local air = minetest.get_content_id("air")
		local min_edge,max_edge= manip:read_from_map({x=pos.x-20,y=pos.y-20,z=pos.z-20},{x=pos.x+20,y=pos.y+20,z=pos.z+20})
		local area = VoxelArea:new({MinEdge=min_edge,MaxEdge=max_edge})
		local data = manip:get_data()
		for xVect=pos.x-blast_size,pos.x+blast_size do
			local yLimit = math.max(blast_size-math.abs(pos.x-xVect),1)
			for yVect=pos.y-yLimit,pos.y+yLimit do
				local zLimit = math.max(blast_size-math.abs(pos.x-xVect)-math.abs(pos.y-yVect),1)
				for zVect=pos.z-zLimit,pos.z+zLimit do
					if xVect ~= pos.x or yVect ~= pos.y or zVect ~= pos.z then
						local p = {x=xVect,y=yVect,z=zVect}
						local node = minetest.env:get_node(p)
						local destroy = minetest.registered_nodes[node.name]["on_blast"]
						local immortal = minetest.registered_nodes[node.name]["groups"]["immortal"]
						if node.name == "ignore" or node.name == "air" then
						elseif destroy then
							destroy(p,10)
						elseif immortal then
						else
							local ind = area:indexp(p)
							data[ind] = air
						end
					else
						local ind = area:indexp(pos)
						data[ind] = air
					end
				end
			end
		end
		manip:set_data(data)
		manip:write_to_map()
		manip:update_map()
		local object=nil
		local key = nil
		for  key,object in pairs(objects) do
			if object.set_hp then
				object:set_hp(0)
			end
		end
	end
})

local propagate_units = function (automata_name,pos,unit_max)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	for i=1,inv:get_size("nuclear") do
		local unit = meta:get_int(automata_name..i)
		if unit > 0 then
			local neigh = nil
			local neighbors = nuclear.neighbors[automata_name](i,inv)
			local unit_spread = math.floor(unit/(#neighbors+1))
			for key,neigh in pairs(neighbors) do
				if unit_max then
					meta:set_int(automata_name..neigh,math.min(meta:get_int(automata_name..neigh)+unit_spread,unit_max))
				else
					meta:set_int(automata_name..neigh,meta:get_int(automata_name..neigh)+unit_spread)
				end
			end
			meta:set_int(automata_name..i,meta:get_int(automata_name..i)-(unit_spread*#neighbors))
		end
	end
end

components.register_abm({
	nodenames={"voltbuild:nuclear_reactor"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.env:get_meta(pos)
		local i = nil
		local inv = meta:get_inventory()
		if meta:get_string("stime") == "" then
			meta:set_float("stime",0.0)
		end
		if meta:get_string("fburntime") == "" then
			meta:set_float("fburntime", 10.0)
		elseif meta:get_float("fburntime") ~= 10.0 then
			meta:set_float("fburntime", 10.0)
		end
		automata:get(pos,"nuclear","automata_rads"):step()
		automata:get(pos,"nuclear","automata_heat"):step()
		automata:get(pos,"nuclear","automata_energy"):step()
		propagate_units("automata_rads",pos,nuclear.max_radiation)
		propagate_units("automata_heat",pos)
		--energy comes out at approximately the bottom middle
		local energy = meta:get_int("automata_energy"..(inv:get_size("nuclear")-math.floor(nuclear.inventory_width/2)))
		meta:set_int("automata_energy"..(inv:get_size("nuclear")-math.floor(nuclear.inventory_width/2)),0)
		if energy > 2048 then
			while energy > 2048 do
				generators.produce(pos,math.min(energy,2048))
				energy = energy-2048
			end
		else
			generators.produce(pos,energy)
		end
		--set stress of nuclear reactor for steam that reaches the top
		for i=1,nuclear.inventory_width do
			meta:set_int("stress",math.min(meta:get_int("stress")+meta:get_int("automata_heat"..i),2000))
			meta:set_int("automata_heat"..i,0)
		end
		--set stress of nuclear reactor for large steam buildup
		for i=1,inv:get_size("nuclear") do
			local heat = meta:get_int("automata_heat"..i)
			if heat > 200 then
				meta:set_int("stress",meta:get_int("stress")+(heat-200))
				meta:set_int("automata_heat"..i,200)
			end
		end
		--set rads of nuclear reactor for radiation that reaches the edges
		--the top row
		for i=1,nuclear.inventory_width do
			meta:set_int("rads",math.min(meta:get_int("rads")+meta:get_int("automata_rads"..i),nuclear.max_radiation))
			meta:set_int("automata_rads"..i,0)
		end
		--bottom row
		for i=inv:get_size("nuclear")-nuclear.inventory_width+1,inv:get_size("nuclear") do
			meta:set_int("rads",math.min(meta:get_int("rads")+meta:get_int("automata_rads"..i),nuclear.max_radiation))
			meta:set_int("automata_rads"..i,0)
		end
		--left column
		for i=1,inv:get_size("nuclear"),nuclear.inventory_width do
			meta:set_int("rads",math.min(meta:get_int("rads")+meta:get_int("automata_rads"..i),nuclear.max_radiation))
			meta:set_int("automata_rads"..i,0)
		end
		--right column
		for i=nuclear.inventory_width,inv:get_size("nuclear"),nuclear.inventory_width do
			meta:set_int("rads",math.min(meta:get_int("rads")+meta:get_int("automata_rads"..i),nuclear.max_radiation))
			meta:set_int("automata_rads"..i,0)
		end
		local rad_percent = math.min((meta:get_int("rads")/nuclear.max_radiation),1)
		if rad_percent > 0.25 then
			local objects = minetest.get_objects_inside_radius(pos,math.ceil(rad_percent*9))
			local k = nil
			local object = nil
			for k,object in pairs(objects) do
				if object:get_hp() then
					object:set_hp(object:get_hp()-1)
				end
			end
		end
		--slowly have radiation fade away when there's no uranium in it
		if inv:get_stack("nuclear_fuel",1):is_empty() then
			meta:set_int("rads",math.max(meta:get_int("rads")-1,0))
		end
		meta:set_string("formspec",nuclear.get_formspec(pos))
	end,
})
