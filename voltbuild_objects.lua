voltbuild.size_spec ="size[8,9]"
voltbuild.charge_spec = "list[current_name;charge;2,1;1,1;]"
voltbuild.discharge_spec = "list[current_name;discharge;2,3;1,1;]"
voltbuild.player_inventory_spec = "list[current_player;main;0,5;8,4;]"
voltbuild.production_spec = "list[current_name;src;2,1;1,1;]list[current_name;dst;5,1;2,2;]"

function voltbuild.get_percent(pos)
	local meta = minetest.env:get_meta(pos)
	local node = minetest.env:get_node(pos)
	return(meta:get_int("energy")/get_node_field(node.name,meta,"max_energy")*100)
end

function voltbuild.chargebar_spec (pos)
	return("image[3,2;2,1;itest_charge_bg.png^[lowpart:".. voltbuild.get_percent(pos)..":itest_charge_fg.png^[transformR270]]]")
end

function voltbuild.vertical_chargebar_spec (pos)
	return("image[2,2;1,1;itest_charge_bg.png^[lowpart:".. voltbuild.get_percent(pos)..":itest_charge_fg.png]]")
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
	end
	return 0
end
