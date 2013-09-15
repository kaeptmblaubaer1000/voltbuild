generators={}

generators.charge = voltbuild.charge_item


function generators.send(pos,energy)
	local sent = send_packet_alldirs(pos,energy)
	if sent==0 then
		local meta = minetest.env:get_meta(pos)
		local node = minetest.env:get_node(pos)
		local e = meta:get_int("energy")
		local m = get_node_field(node.name,meta,"max_energy")
		meta:set_int("energy",math.min(m,e+energy))
	end
end

function generators.produce(pos,energy)
	if energy <= 0 then return end
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory();
	local heat_generated = meta:get_int("pressure_rate")
	local heat = meta:get_int("pressure")
	for i=1, inv:get_size("components") do
		local component_stack = inv:get_stack("components",i)
		if not component_stack:is_empty() then
			component = component_stack:peek_item():get_definition()
			if component.voltbuild.produce_effect and component.voltbuild.cost_effect then
				energy = component.voltbuild.produce_effect(energy)
				heat = heat+component.voltbuild.cost_effect(heat_generated)
			end
		end
	end
	meta:set_int("pressure",heat+heat_generated)
	local rem = generators.charge(pos,energy)
	if rem > 0 then
		generators.send(pos,rem)
	end
end

function generators.on_construct(pos)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size("charge", 1)
	meta:set_int("pressure",0)
	meta:set_int("max_pressure",100)
	meta:set_int("pressure_rate",0)
	voltbuild.on_construct(pos)
end

generators.can_dig = voltbuild.can_dig

generators.inventory = voltbuild.inventory


function generators.get_formspec(pos)
	formspec = voltbuild.common_spec..
	voltbuild.charge_spec..
	voltbuild.chargebar_spec(pos)..
	voltbuild.pressurebar_spec(pos)
	return formspec
end

dofile(modpath.."/generator.lua")
dofile(modpath.."/solarpanel.lua")
dofile(modpath.."/windmill.lua")
dofile(modpath.."/watermill.lua")
