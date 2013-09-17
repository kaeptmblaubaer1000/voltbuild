voltbuild.size_spec ="size[8,9]"
voltbuild.charge_spec = "list[current_name;charge;2,1;1,1;]"
voltbuild.discharge_spec = "list[current_name;discharge;2,3;1,1;]"
voltbuild.player_inventory_spec = "list[current_player;main;0,5;8,4;]"
voltbuild.production_spec = "list[current_name;src;2,1;1,1;]list[current_name;dst;5,1;2,2;]"
voltbuild.components_spec = "list[current_name;components;0,0;1,4;]"
voltbuild.common_spec = voltbuild.size_spec..
		voltbuild.player_inventory_spec..
		voltbuild.components_spec
voltbuild.image_location = "2,2;1,1;"
voltbuild.fuel_location = "2,3;1,1"
voltbuild.recipes = {}

function voltbuild.get_percent(pos)
	local meta = minetest.env:get_meta(pos)
	local node = minetest.env:get_node(pos)
	return(meta:get_int("energy")/get_node_field(node.name,meta,"max_energy")*100)
end

function voltbuild.chargebar_spec (pos)
	return("image[3,2;2,1;itest_charge_bg.png^[lowpart:".. 
	voltbuild.get_percent(pos)..
	":itest_charge_fg.png^[transformR270]")
end

function voltbuild.vertical_chargebar_spec (pos)
	return("image["..voltbuild.image_location..
		"itest_charge_bg.png^[lowpart:".. 
		voltbuild.get_percent(pos)..
		":itest_charge_fg.png]")
end

function voltbuild.pressurebar_spec (pos)
	local meta = minetest.env:get_meta(pos)
	local pressure = meta:get_int("pressure")
	local maxp = meta:get_int("max_pressure")
	local percent = math.min(((pressure/maxp)*100),100)
	if percent > 90 then
		return ("image[1,2;1,1;itest_charge_bg.png^itest_charge_fg.png^[crack:1:9]")
	end
	if percent > 75 then
		return ("image[1,2;1,1;itest_charge_bg.png^[crack:1:2")
	end
	return ("image[1,2;1,1;itest_charge_bg.png^[lowpart:"..
		percent..
		":itest_charge_fg.png]")
end

function voltbuild.charge_item(pos,energy)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	local chr = inv:get_stack("charge",1)
	if chr:is_empty() then return energy end
	chr = chr:to_table()
	if chr == nil then return energy end
	if chr.count ~= 1 then return energy end -- Don't charge stacks
	local name = chr.name
	local max_charge = get_item_field(name, "max_charge")
	local max_speed = get_item_field(name, "max_speed")
	local c = charge.get_charge(chr)
	local u = math.min(max_charge-c,energy,max_speed)
	charge.set_charge(chr,c+u)
	charge.set_wear(chr,c+u,max_charge)
	inv:set_stack("charge",1,ItemStack(chr))
	return energy-u
end

function voltbuild.discharge_item(pos)
	local meta = minetest.env:get_meta(pos)
	local node = minetest.env:get_node(pos)
	local energy = meta:get_int("energy")
	local max_energy = get_node_field(node.name,meta,"max_energy")
	local m = max_energy-energy
	local inv = meta:get_inventory()
	local discharge = inv:get_stack("discharge",1)
	if charge.single_use(discharge) then
		prod = get_item_field(discharge:get_name(), "singleuse_energy")
		if max_energy-energy>= prod then
			discharge:take_item()
			inv:set_stack("discharge",1,discharge)
			meta:set_int("energy",energy+prod)
		end
	end
	discharge = discharge:to_table()
	if discharge == nil then return end
	if discharge.count ~= 1 then return end -- Don't discharge stacks
	local name = discharge.name
	local max_speed = get_item_field(name, "max_speed")
	local max_charge = get_item_field(name, "max_charge")
	local c = charge.get_charge(discharge)
	local u = math.min(c,max_speed,m)
	charge.set_charge(discharge,c-u)
	charge.set_wear(discharge,c-u,max_charge)
	inv:set_stack("discharge",1,ItemStack(discharge))
	meta:set_int("energy",energy+u)
end

function voltbuild.can_dig(pos,player)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	local inv_table = meta:to_table()["inventory"]
	for listname in pairs(inv_table) do
		if listname ~= "main" then
			if not inv:is_empty(listname) then
				return false
			end
		end
	end
	return true
end

function voltbuild.inventory(pos,listname,stack,maxtier)
	if listname=="charge" or listname=="discharge" then
		local chr = get_item_field(stack:get_name(),"charge_tier")
		if chr>0 and chr<=maxtier then
			return stack:get_count()
		end
		return 0
	elseif listname=="components" then
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		if get_item_field(stack:get_name(),"component") == 1 then
			return 1
		end
		return 0
	end
	return 0
end

function voltbuild.on_construct(pos)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size("components",4)
	meta:set_int("pressure",0)
end

function voltbuild.allow_metadata_inventory_put(pos, listname, index, stack, player)
	local meta = minetest:get_meta(pos)
	local max_tier = meta:get_int("max_tier")
	storage.inventory(pos,listname,stack,max_tier)
end
function voltbuild.allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	local max_tier = meta:get_int("max_tier")
	return storage.inventory(pos, to_list, stack, max_tier)
end

function voltbuild.register_machine_recipe(string1,string2,cooking_type)
	voltbuild.recipes[cooking_type][string1]=string2
end

function voltbuild.get_craft_result(c)
	local input = c.items[1]
	local output = voltbuild.recipes[c.method][input:get_name()]
	input:take_item()
	return {item = ItemStack(output), time = 20},{items = {input}}
end

function voltbuild.production_abm (pos,node, active_object_count, active_object_count_wider)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		local cooking_method = minetest.registered_nodes[node.name]["cooking_method"]
		
		local speed = 1
		
		if meta:get_string("stime") == "" then
			meta:set_float("stime", 0.0)
		end
		
		local state = false
		
		for i = 1,20 do
			local srclist = inv:get_list("src")
			local produced = nil
			local afterproduction
		
			if srclist then
				produced, afterproduction = voltbuild.get_craft_result({method = cooking_method,
					width = 1, items = srclist})
			end
			
			if produced.item:is_empty() then
				state = false
				break
			end
		
			local energy = meta:get_int("energy")
			if energy >= 2 then
				if produced and produced.item then
					state = true
					meta:set_int("energy",energy-2)
					meta:set_float("stime", meta:get_float("stime") + 1)
					if meta:get_float("stime")>=20*speed*produced.time then
						meta:set_float("stime",0)
						if inv:room_for_item("dst",produced.item) then
							inv:add_item("dst", produced.item)
							inv:set_stack("src", 1, afterproduction.items[1])
						else
							meta:set_int("energy",energy) -- Don't waste energy
							meta:set_float("stime",20*speed*produced.time)
							state = false
						end
					end
				else
					state = false
				end
			end
			consumers.discharge(pos)
		end
		local srclist = inv:get_list("src")
		local produced = nil
		local afterproduction
	
		if srclist then
			produced, afterproduction = voltbuild.get_craft_result({method = cooking_method,
				width = 1, items = srclist})
		end
		local progress = meta:get_float("stime")
		local maxprogress = 1
		if produced and produced.time then
			maxprogress = 20*speed*produced.time
		end
		if inv:is_empty("src") then state = false end
		local active = string.find(node.name,"_active")
		local base_node_name = nil
		if active then
			base_node_name = string.sub(node.name,1,active-1)
		else
			base_node_name = node.name
		end
		if state then
			hacky_swap_node(pos,base_node_name.."_active")
		else
			hacky_swap_node(pos,base_node_name)
		end
		meta:set_string("formspec", consumers.get_formspec(pos)..
				voltbuild.production_spec..
				consumers.get_progressbar(progress,maxprogress,
					"itest_extractor_progress_bg.png",
					"itest_extractor_progress_fg.png"))
end

dofile(modpath.."/components.lua")
