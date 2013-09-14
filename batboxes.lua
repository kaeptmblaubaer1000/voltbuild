minetest.register_node("voltbuild:batbox",{description="BatBox",
	groups={energy=1, cracky=2, energy_consumer=1},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	tiles={"itest_batbox_side.png", "itest_batbox_side.png", "itest_batbox_output.png", "itest_batbox_side.png", "itest_batbox_side.png", "itest_batbox_side.png"},
	voltbuild = {max_energy = 40000,
		max_psize = 32},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_string("formspec", storage.get_formspec(pos))
		storage.on_construct(pos)
	end,
	can_dig = storage.can_dig,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return storage.inventory(pos, listname, stack, 1)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		return storage.inventory(pos, to_list, stack, 1)
	end,
})

minetest.register_abm({
	nodenames={"voltbuild:batbox"},
	interval=1.0,
	chance=1,
	action = function(pos, node, active_object_count, active_objects_wider)
		local senddir = param22dir(node.param2)
		for i=1,20 do
			storage.charge(pos)
			storage.send(pos,32,senddir)
			storage.discharge(pos)
		end
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",storage.get_formspec(pos))
	end
})

minetest.register_node("voltbuild:mfe_unit",{description="MFE Unit",
	groups={energy=1, cracky=2, energy_consumer=1},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	tiles={"itest_mfe_side.png", "itest_mfe_side.png", "itest_mfe_output.png", "itest_mfe_side.png", "itest_mfe_side.png", "itest_mfe_side.png"},
	voltbuild = {max_energy = 600000,
		max_psize = 128},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_string("formspec", storage.get_formspec(pos))
		storage.on_construct(pos)
	end,
	can_dig = storage.can_dig,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return storage.inventory(pos, listname, stack, 2)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		return storage.inventory(pos, to_list, stack, 2)
	end,
})

minetest.register_abm({
	nodenames={"voltbuild:mfe_unit"},
	interval=1.0,
	chance=1,
	action = function(pos, node, active_object_count, active_objects_wider)
		local senddir = param22dir(node.param2)
		for i=1,20 do
			storage.charge(pos)
			storage.send(pos,128,senddir)
			storage.discharge(pos)
		end
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",storage.get_formspec(pos))
	end
})

minetest.register_node("voltbuild:mfs_unit",{description="MFS Unit",
	groups={energy=1, cracky=2, energy_consumer=1},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	tiles={"itest_mfsu_side.png", "itest_mfsu_side.png", "itest_mfsu_output.png", "itest_mfsu_side.png", "itest_mfsu_side.png", "itest_mfsu_side.png"},
	voltbuild = {max_energy = 10000000,
		max_psize = 512},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_string("formspec", storage.get_formspec(pos))
		storage.on_construct(pos)
	end,
	can_dig = storage.can_dig,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return storage.inventory(pos, listname, stack, 3)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		return storage.inventory(pos, to_list, stack, 3)
	end,
})

minetest.register_abm({
	nodenames={"voltbuild:mfs_unit"},
	interval=1.0,
	chance=1,
	action = function(pos, node, active_object_count, active_objects_wider)
		local senddir = param22dir(node.param2)
		for i=1,20 do
			storage.charge(pos)
			storage.send(pos,512,senddir)
			storage.discharge(pos)
		end
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",storage.get_formspec(pos))
	end
})

