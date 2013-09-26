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
			ret_comp = component_stack:peek_item():get_definition()["voltbuild"]
			if ret_comp[method_name] then
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
		minetest.env:set_node(pos,{name = "air"})
	end
end

function components.register_abm(table)
	local register_action = table.action
	table.action = function (pos,node,active_object_count,active_object_count_wider)
		components.abm_wrapper(pos,node,active_object_count,active_object_count_wider,register_action)
	end
	minetest.register_abm(table)
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
			local energy_cost = minetest.registered_nodes[node.name]["voltbuild"]["energy_cost"]
			local energy_produce = minetest.registered_nodes[node.name]["voltbuild"]["energy_produce"]
			local energy_release = minetest.registered_nodes[node.name]["voltbuild"]["energy_release"]
			local energy = meta:get_int("energy")
			local energy_cost_effect = properties.voltbuild.energy_cost_effect
			local pay_cost = false
			if energy_cost  then
				local clock_energy_cost = energy_cost_effect(energy_cost)
				if energy > energy_cost + clock_energy_cost then
					meta:set_int("energy",energy-clock_energy_cost)
					pay_cost = true
				end
			elseif energy_produce then
				local energy_produce_effect = properties.voltbuild.energy_produce_effect
				if type(energy_produce) == "function" then
					local energy_p,leftover_energy = energy_produce(pos)
					generators.produce(pos,energy_produce_effect(energy_p))
					if leftover_energy then
						leftover_energy = energy_p+leftover_energy-energy_produce_effect(energy_p)
						meta:set_int("energy",leftover_energy)
					end
				elseif type(energy_produce) == "number" then
					generators.produce(pos,energy_produce_effect(energy_produce))
				end
				pay_cost = true
			elseif energy_release then
				if type(energy_release) == "function" then
					local energy_release_effect = properties.voltbuild.energy_release_effect
					local energy_p, leftover_energy,dir = energy_release(pos)
					local sent = send_packet(pos,dir,energy_release_effect(energy_p))
					if sent then
						leftover_energy = energy_p+leftover_energy-energy_release_effect(energy_p)
						meta:set_int("energy",leftover_energy)
					end
				end
				pay_cost = true
			end
			if pay_cost then
				local stress = meta:get_int("stress")
				local stress_cost_effect = properties.voltbuild.stress_cost_effect
				meta:set_int("stress",stress_cost_effect(stress))
				if meta:get_string("stime") ~= "" then
					local stime = meta:get_float("stime")
					local speed = minetest.registered_nodes[node.name]["voltbuild"]["speed"] or 1.0
					local clock_effect = properties.voltbuild.clock_effect
					meta:set_float("stime",stime+clock_effect(speed))
				end
			end
		end
	end
	minetest.register_craftitem(name,properties)
end

do 
local function overclock_effect(x)
	return x
end
components.register_clockitem("voltbuild:overclock", {
	description = "Overclock",
	inventory_image = "voltbuild_overclock.png",
	voltbuild = {component=1,
		energy_cost_effect = overclock_effect,
		energy_produce_effect = overclock_effect,
		energy_release_effect = overclock_effect,
		stress_cost_effect = function(stress)
			return stress+20
		end,
		clock_effect = overclock_effect},
	stack_max = 1,
})
end

minetest.register_craft({
	output = "voltbuild:overclock",
	recipe = {{"default:bronze_ingot","voltbuild:hv_cable0_000000","default:bronze_ingot"},
		{"","voltbuild:circuit","voltbuild:energy_crystal"}}
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
		{"","voltbuild:circuit","voltbuild:re_battery"}}
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
