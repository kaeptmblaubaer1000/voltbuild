charge = {}

function charge.set_wear(stack,charge,max_charge)
	local n = 65536 - math.floor(charge/max_charge*65535)
	stack.wear = n
end

function charge.get_charge(stack)
	if tonumber(stack.metadata) == nil then return 0 end
	return tonumber(stack.metadata)
end

function charge.set_charge(stack,charge)
	stack.metadata = tostring(charge)
	if minetest.registered_items[stack.name] and minetest.registered_items[stack.name].voltbuild and minetest.registered_items[stack.name].voltbuild.cnames then
		local cn = minetest.registered_items[stack.name].voltbuild.cnames
		local m = -1
		local n = stack.name
		for _,i in ipairs(cn) do
			if i[1] <= charge and i[1] > m then
				m = i[1]
				n = i[2]
			end
		end
		stack.name = n
	end
end

function charge.single_use(stack)
	return get_item_field(stack:get_name(),"single_use")>0
end

minetest.register_tool("voltbuild:re_battery",{
	description = "RE Battery",
	inventory_image = "itest_re_battery.png",
	voltbuild = {max_charge = 240,
		max_speed = 100,
		charge_tier = 1},
	tool_capabilities =
		{max_drop_level=0,
		groupcaps={fleshy={times={}, uses=1, maxlevel=0}}}
})

minetest.register_tool("voltbuild:energy_crystal",{
	description = "Energy crystal",
	inventory_image = "itest_energy_crystal.png",
	voltbuild = {max_charge = 10000,
		max_speed = 250,
		charge_tier = 2},
	tool_capabilities =
		{max_drop_level=0,
		groupcaps={fleshy={times={}, uses=1, maxlevel=0}}}
}) 

minetest.register_tool("voltbuild:lapotron_crystal",{
	description = "Lapotron crystal",
	inventory_image = "itest_lapotron_crystal.png",
	voltbuild = {max_charge = 100000,
		max_speed = 600,
		charge_tier = 3},
	tool_capabilities =
		{max_drop_level=0,
		groupcaps={fleshy={times={}, uses=1, maxlevel=0}}}
}) 

minetest.register_craftitem("voltbuild:single_use_battery",{
	description = "Single use battery",
	inventory_image = "itest_single_use_battery.png",
	voltbuild = {single_use = 1,
		singleuse_energy = 12,
		charge_tier = 1}
})

local drill_properties = {
	description = "Mining drill",
	inventory_image = "voltbuild_mining_drill.png",
	voltbuild = {max_charge = 180,
		max_speed = 5,
		charge_tier = 1,
		cnames = {{0,"voltbuild:mining_drill_discharged"},
			{1,"voltbuild:mining_drill"}}},
	tool_capabilities =
		{max_drop_level=0,
		-- Uses are specified, but not used since there is a after_use function
		groupcaps={cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=22, maxlevel=2}}},
	after_use = function (itemstack, user, pointed_thing)
		local stack = itemstack:to_table()
		local chr = charge.get_charge(stack)
		local max_charge = get_item_field(stack.name, "max_charge")
		nchr = math.max(0,chr-1)
		charge.set_charge(stack,nchr)
		charge.set_wear(stack,nchr,max_charge)
		return ItemStack(stack)
	end
}
minetest.register_tool("voltbuild:mining_drill",drill_properties)
drill_properties.after_use=nil
minetest.register_tool("voltbuild:mining_drill_discharged",drill_properties)

local diamond_drill = {
	description = "Diamond drill",
	inventory_image = "voltbuild_diamond_drill.png",
	voltbuild = {max_charge = 240,
		max_speed = 10,
		charge_tier = 1,
		cnames = {{0,"voltbuild:diamond_drill_discharged"},
			{2,"voltbuild:diamond_drill"}}},
	tool_capabilities =
		{max_drop_level=0,
		-- Uses are specified, but not used since there is a after_use function
		groupcaps={cracky = {times={[1]=2.0, [2]=1.0, [3]=0.50}, uses=4, maxlevel=3}}},
	after_use = function (itemstack, user, pointed_thing)
		local stack = itemstack:to_table()
		local chr = charge.get_charge(stack)
		local max_charge = get_item_field(stack.name, "max_charge")
		nchr = math.max(0,chr-2)
		charge.set_charge(stack,nchr)
		charge.set_wear(stack,nchr,max_charge)
		return ItemStack(stack)
	end
}
minetest.register_tool("voltbuild:diamond_drill",diamond_drill)
diamond_drill.after_use = nil
minetest.register_tool("voltbuild:diamond_drill_discharged",diamond_drill)


minetest.register_tool("voltbuild:od_scanner",{
	description = "OD Scanner",
	inventory_image = "voltbuild_od_scanner.png",
	voltbuild = {max_charge = 360,
		max_speed = 10,
		charge_tier = 1},
	tool_capabilities =
		{max_drop_level=0,
		groupcaps={}},
	on_place = function(itemstack, user, pointed_thing)
		local stack = itemstack:to_table()
		if charge.get_charge(stack) < 2 then return itemstack end -- Not enough energy
		local chr = charge.get_charge(stack)
		local max_charge = get_item_field(stack.name, "max_charge")
		charge.set_charge(stack, chr - 2)
		charge.set_wear(stack, chr - 2, max_charge)
		local pos = user:getpos()
		local y = 0
		local nnodes = 0
		local total_ores = 0
		local shall_break = false
		while true do
			for x = -2, 2 do
			for z = -2, 2 do
				local npos = {x=pos.x+x, y=pos.y+y, z=pos.z+z}
				local nnode = minetest.env:get_node(npos)
				if nnode.name == "ignore" then
					shall_break = true
				else
					nnodes = nnodes + 1 -- Number of nodes scanned
					if voltbuild.registered_ores[nnode.name] then
						total_ores = total_ores + 1
					end
				end
			end
			end
			if shall_break then break end
			y = y - 1 -- Look the next level down
		end
		minetest.chat_send_player(user:get_player_name(), "Ore density: "..math.floor(total_ores / nnodes * 1000), false)
		return ItemStack(stack)
	end
})

minetest.register_tool("voltbuild:ov_scanner",{
	description = "OV Scanner",
	inventory_image = "voltbuild_ov_scanner.png",
	voltbuild = {max_charge = 480,
		max_speed = 20,
		charge_tier = 1},
	tool_capabilities =
		{max_drop_level=0,
		groupcaps={}},
	on_place = function(itemstack, user, pointed_thing)
		local stack = itemstack:to_table()
		if charge.get_charge(stack) < 4 then return itemstack end -- Not enough energy
		local chr = charge.get_charge(stack)
		local max_charge = get_item_field(stack.name, "max_charge")
		charge.set_charge(stack, chr - 4)
		charge.set_wear(stack, chr - 4, max_charge)
		local pos = user:getpos()
		local y = 0
		local nnodes = 0
		local total_value = 0
		local shall_break = false
		while true do
			for x = -4, 4 do
			for z = -4, 4 do
				local npos = {x=pos.x+x, y=pos.y+y, z=pos.z+z}
				local nnode = minetest.env:get_node(npos)
				if nnode.name == "ignore" then
					shall_break = true
				else
					nnodes = nnodes + 1 -- Number of nodes scanned
					if voltbuild.registered_ores[nnode.name] then
						total_value = total_value + voltbuild.registered_ores[nnode.name]
					end
				end
			end
			end
			if shall_break then break end
			y = y - 1 -- Look the next level down
		end
		minetest.chat_send_player(user:get_player_name(), "Ore value: "..math.floor(total_value / nnodes * 1000), false)
		return ItemStack(stack)
	end
})

-- Add power to mesecons
mcon = clone_node("mesecons:wire_00000000_off")
mcon.voltbuild = {single_use = 1, singleuse_energy = 60}
minetest.register_node(":mesecons:wire_00000000_off",mcon)
