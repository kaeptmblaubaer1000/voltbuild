components = {}

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
	end
	for i,comp in ipairs(components.each_with_method(inv,"after_effects")) do
		comp.after_effects(pos)
	end
end

function components.register_abm(table)
	local register_action = table.action
	table.action = function (pos,node,active_object_count,active_object_count_wider)
		components.abm_wrapper(pos,node,active_object_count,active_object_count_wider,register_action)
	end
	minetest.register_abm(table)
end

minetest.register_craftitem("voltbuild:overclock", {
	description = "Overclock component",
	inventory_image = "voltbuild_overclock.png",
	voltbuild = {component=1,
		produce_effect= function (int)
			return 2*int
		end
		,cost_effect= function(int)
			return math.max(2*int,20)
		end},
	stack_max = 1,
})

minetest.register_craft({
	output = "voltbuild:overclock",
	recipe = {{"default:bronze_ingot","voltbuild:hv_cable0_000000","default:bronze_ingot"},
		{"","voltbuild:circuit","voltbuild:energy_crystal"}}
})

minetest.register_craftitem("voltbuild:halt", {
	description = "Halt component",
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
