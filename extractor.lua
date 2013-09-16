voltbuild.recipes.extracting = {}
extractor_recipes = voltbuild.recipes.extracting
extractor = {}

function extractor.register_extractor_recipe(string1,string2)
	voltbuild.register_machine_recipe(string1,string2,"extracting")
end
extractor.get_craft_result = voltbuild.get_craft_result


minetest.register_node("voltbuild:extractor", {
	description = "Extractor",
	tiles = {"itest_extractor_side.png", "itest_extractor_side.png", "itest_extractor_side.png", "itest_extractor_side.png", "itest_extractor_side.png", "itest_extractor_front.png"},
	paramtype2 = "facedir",
	groups = {energy=1, energy_consumer=1, cracky=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
	cooking_method = "extracting",
	tube={insert_object=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:add_item("src",stack)
		end,
		can_insert=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:room_for_item("src",stack)

		end,
		input_inventory="dst"},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_int("max_energy",800)
		meta:set_int("max_psize",32)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
		meta:set_string("formspec", consumers.get_formspec(pos)..
				voltbuild.production_spec..
				consumers.get_progressbar(0,1,
					"itest_extractor_progress_bg.png",
					"itest_extractor_progress_fg.png"))
		consumers.on_construct(pos)
	end,
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("src") and inv:is_empty("dst") and
			consumers.can_dig(pos,player)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "dst" then
			return 0
		elseif listname == "src" then
			return stack:get_count()
		end
		return consumers.inventory(pos, listname, stack, 1)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		if to_list == "dst" then
			return 0
		elseif to_list == "src" then
			return stack:get_count()
		end
		return consumers.inventory(pos, to_list, stack, 1)
	end,
})

minetest.register_node("voltbuild:extractor_active", {
	description = "Extractor",
	tiles = {"itest_extractor_side.png", "itest_extractor_side.png", "itest_extractor_side.png", "itest_extractor_side.png", "itest_extractor_side.png", "itest_extractor_front_active.png"},
	paramtype2 = "facedir",
	drop = "voltbuild:extractor",
	groups = {energy=1, energy_consumer=1, cracky=2, not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
	cooking_method = "extracting",
	tube={insert_object=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:add_item("src",stack)
		end,
		can_insert=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:room_for_item("src",stack)

		end,
		input_inventory="dst"},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_int("max_energy",800)
		meta:set_int("max_psize",32)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
		meta:set_string("formspec", consumers.get_formspec(pos)..
				voltbuild.production_spec)
		consumers.on_construct(pos)
	end,
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("src") and inv:is_empty("dst") and
			consumers.can_dig(pos,player)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "dst" then
			return 0
		elseif listname == "src" then
			return stack:get_count()
		end
		return consumers.inventory(pos, listname, stack, 1)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		if to_list == "dst" then
			return 0
		elseif to_list == "src" then
			return stack:get_count()
		end
		return consumers.inventory(pos, to_list, stack, 1)
	end,
})

minetest.register_abm({
	nodenames = {"voltbuild:extractor","voltbuild:extractor_active"},
	interval = 1.0,
	chance = 1,
	action=function (pos,node,active_object_count,active_object_count_wider)
		components.abm_wrapper(pos,node,active_object_count,active_object_count_wider,voltbuild.production_abm)
	end,
})
