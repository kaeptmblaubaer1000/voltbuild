components = {}

voltbuild.metadata_check.components = function (pos,listname,stack,maxtier)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	if get_item_field(stack:get_name(),"component") == 1 then
		if stack:peek_item()["on_placement"] then
			stack:peek_item()["on_placement"](pos)
		end
		return 1
	end
	return 0
end

voltbuild.metadata_check_move.components = function (pos,to_list,stack,maxtier,from_list,from_index,to_index,count,player)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	if get_item_field(stack:get_name(),"component") == 1 then
		if to_list ~= "components" then
			if stack:peek_item()["on_removal"] then
				stack:peek_item()["on_removal"](pos)
			end
		end
		return 1
	end
	return 0
end

function components.each_with_method(component_inv,method_name)
	local ret_comps = {}
	for i=1,component_inv:get_size("components") do
		component_stack = component_inv:get_stack("components",i)
		if not component_stack:is_empty() then
			local ret_comp = component_stack:peek_item():get_definition()["voltbuild"]
			if ret_comp and ret_comp[method_name] then
				table.insert(ret_comps,ret_comp)
			end
		end
	end
	return ret_comps
end


function components.abm_wrapper(pos,node,active_object_count,active_object_count_wider,abm)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	local run_abm = true
	for i,comp in ipairs(components.each_with_method(inv,"can_run")) do
		if not comp.can_run(pos) then
			run_abm = false
			break
		end
	end
	for i,comp in ipairs(components.each_with_method(inv,"before_effects")) do
		comp.before_effects(pos)
	end
	if run_abm then
		for i,comp in ipairs(components.each_with_method(inv,"run_before_effects")) do
			comp.run_before_effects(pos)
		end
		abm(pos,node,active_object_count,active_object_count_wider)
		for i,comp in ipairs(components.each_with_method(inv,"run_after_effects")) do
			comp.run_after_effects(pos)
		end
	else
		for i,comp in ipairs(components.each_with_method(inv,"not_run_effects")) do
			comp.run_before_effects(pos)
		end
	end
	for i,comp in ipairs(components.each_with_method(inv,"after_effects")) do
		comp.after_effects(pos)
	end
	local stress = meta:get_int("stress")
	local max_stress = minetest.registered_nodes[node.name]["voltbuild"]["max_stress"]
	if stress >= max_stress then
		voltbuild.blast(pos)
	end
end

if voltbuild.upgrade then
	function components.register_abm(table)
		local register_action = table.action
		table.action = function (pos,node,active_object_count,active_object_count_wider)
			local meta = minetest.env:get_meta(pos)
			if meta:get_string("energy") ~= "" then
				local max_energy
				local current_max = meta:get_int("max_energy")
				if minetest.registered_nodes[node.name]["voltbuild"] then
					max_energy = minetest.registered_nodes[node.name]["voltbuild"]["max_energy"]
				end
				if max_energy and max_energy < meta:get_int("energy") then
					meta:set_int("energy",math.min(meta:get_int("energy"),max_energy))
				end
				if current_max ~= 0 and current_max > max_energy then
					meta:set_string("max_energy","")
				end
				if meta:get_string("max_psize") ~= "" then
					meta:set_string("max_psize","")
				end
			end
			components.abm_wrapper(pos,node,active_object_count,active_object_count_wider,register_action)
		end
		minetest.register_abm(table)
	end
else
	function components.register_abm(table)
		local register_action = table.action
		table.action = function (pos,node,active_object_count,active_object_count_wider)
			components.abm_wrapper(pos,node,active_object_count,active_object_count_wider,register_action)
		end
		minetest.register_abm(table)
	end
end

function components.register_clockitem(name, properties)
	properties.voltbuild.run_before_effects = function(pos)
		local node = minetest.get_node(pos)
		local meta = minetest.env:get_meta(pos)
		local active = string.find(node.name,"_active") or 
			minetest.registered_nodes[node.name]["voltbuild"]["active"]
		if active == nil then
			if meta:get_string("active") ~= "" then
				active = meta:get_int("active")
			end
		end
		if active and active ~= 0 then
			local speed = minetest.registered_nodes[node.name]["voltbuild"]["speed"] or 1.0
			local operation_time = minetest.registered_nodes[node.name]["voltbuild"]["optime"]
			local fuel_time = minetest.registered_nodes[node.name]["voltbuild"]["fueltime"]
			local clock_speed_effect = properties.voltbuild.clock_speed_effect
			local clock_optime_effect = properties.voltbuild.clock_optime_effect
			local clock_fueltime_effect = properties.voltbuild.clock_fueltime_effect
			if type(speed)== "function" then
				speed = clock_speed_effect(speed(pos))
			else
				speed = clock_speed_effect(speed)
			end
			if operation_time then
				if clock_optime_effect then
					if type(operation_time)== "function" then
						if meta:get_string("optime_prev") ~= "" then
							operation_time = clock_optime_effect(meta:get_float("optime"))
							if operation_time then
								meta:set_float("optime_prev",meta:get_float("optime"))
								meta:set_float("optime",operation_time)
							end
						else
							operation_time = clock_optime_effect(operation_time(pos))
							if operation_time then
								meta:set_float("optime_prev",-1.0)
								meta:set_float("optime",operation_time)
							end
						end
					else
						if meta:get_string("optime_prev") ~= "" then
							operation_time = clock_optime_effect(meta:get_float("optime"))
							meta:set_float("optime_prev",meta:get_float("optime"))
						else
							operation_time = clock_optime_effect(operation_time)
							meta:set_float("optime_prev",-1.0)
						end
						meta:set_float("optime",operation_time)
					end
				end
			end
			if fuel_time then
				if clock_fueltime_effect then
					if type(fuel_time)== "function" then
						if meta:get_string("fueltime") ~= "" then
							fuel_time = clock_fueltime_effect(meta:get_float("fueltime"))
							meta:set_float("ftime_prev",meta:get_float("fueltime"))
						else
							fuel_time = clock_fueltime_effect(fuel_time(pos))
							meta:set_float("ftime_prev",-1.0)
						end
					else
						if meta:get_string("ftime_prev") ~= "" then
							fuel_time = clock_fueltime_effect(meta:get_float("fueltime"))
							meta:set_float("ftime_prev",meta:get_float("fueltime"))
						else
							fuel_time = clock_fueltime_effect(fuel_time)
							meta:set_float("ftime_prev",-1.0)
						end
					end
					meta:set_float("fueltime",fuel_time)
				end
			end
			local stress = meta:get_int("stress")
			local stress_cost_effect = properties.voltbuild.stress_cost_effect
			meta:set_int("stress",stress_cost_effect(stress))
			if meta:get_string("stime") ~= "" then
				local stime = meta:get_float("stime")
				meta:set_float("stime",stime+speed)
			end
		end
	end
	properties.voltbuild.run_after_effects = function(pos)
		local meta = minetest.env:get_meta(pos)
		local clock_optime_effect = properties.voltbuild.clock_optime_effect
		if clock_optime_effect then
			if meta:get_string("optime") ~= "" then
				meta:set_string("optime","")
				meta:set_string("optime_prev","")
			end
			if meta:get_string("fueltime") ~= "" then
				meta:set_string("fueltime","")
				meta:set_string("ftime_prev","")
			end
		end
	end
	minetest.register_craftitem(name,properties)
end

components.register_clockitem("voltbuild:overclock", {
	description = "Overclock",
	inventory_image = "voltbuild_overclock.png",
	voltbuild = {component=1,
		stress_cost_effect = function(stress)
			return stress+20
		end,
		clock_speed_effect = function (x)
			return x
		end},
	stack_max = 1,
})

minetest.register_craft({
	output = "voltbuild:overclock",
	recipe = {{"default:bronze_ingot","voltbuild:hv_cable0_000000","default:bronze_ingot"},
		{"voltbuild;energy_crystal","voltbuild:circuit","voltbuild:energy_crystal"}}
})

minetest.register_craftitem("voltbuild:halt", {
	description = "Halt",
	inventory_image = "voltbuild_halt.png",
	voltbuild = {component=1,
		can_run = function(pos)
			return false
		end},
	stack_max = 1,
})

minetest.register_craft({
	output = "voltbuild:halt",
	recipe = {{"default:gold_ingot","voltbuild:splitter_cable_000000","default:gold_ingot"},
		{"voltbuild:re_battery","voltbuild:circuit","voltbuild:re_battery"}}
})

minetest.register_craftitem("voltbuild:fan",{
	description = "Fan",
	inventory_image = "voltbuild_fan.png",
	voltbuild = {component=1,
		after_effects = function(pos)
			local meta = minetest.env:get_meta(pos)
			local stress = meta:get_int("stress")
			meta:set_int("stress",math.max(stress-20,0))
		end},
	stack_max = 1,
})

minetest.register_craft({
	output = "voltbuild:fan",
	recipe = {{"voltbuild:refined_iron_ingot","voltbuild:refined_iron_ingot","voltbuild:refined_iron_ingot"},
		{"voltbuild:windmill","voltbuild:batbox",""},
		{"voltbuild:refined_iron_ingot","voltbuild:refined_iron_ingot","voltbuild:refined_iron_ingot"}},
})
