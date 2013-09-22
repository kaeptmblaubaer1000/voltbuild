voltbuild.recipes.grinding= {}
macerator_recipes = voltbuild.recipes.grinding
macerator = {}

function macerator.register_macerator_recipe(string1,string2)
	voltbuild.register_machine_recipe(string1,string2,"grinding")
end
macerator.get_craft_result=voltbuild.get_craft_result

minetest.register_node("voltbuild:macerator", {
	description = "Macerator",
	tiles = {"itest_macerator_side.png", "itest_macerator_side.png", "itest_macerator_side.png",
		"itest_macerator_side.png", "itest_macerator_side.png", "itest_macerator_front.png"},
	paramtype2 = "facedir",
	groups = {energy=1, energy_consumer=1, cracky=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
	voltbuild = {max_tier=1,energy_cost=2,max_stress=2000},
	cooking_method="grinding",
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
					"itest_macerator_progress_bg.png",
					"itest_macerator_progress_fg.png"))
		consumers.on_construct(pos)
	end,
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("src") and inv:is_empty("dst") and
			consumers.can_dig(pos,player)
	end,
	allow_metadata_inventory_put = voltbuild.allow_metadata_inventory_put,
	allow_metadata_inventory_move = voltbuild.allow_metadata_inventory_move,
})

minetest.register_node("voltbuild:macerator_active", {
	description = "Macerator",
	tiles = {"itest_macerator_side.png", "itest_macerator_side.png", "itest_macerator_side.png",
		"itest_macerator_side.png", "itest_macerator_side.png", "itest_macerator_front_active.png"},
	paramtype2 = "facedir",
	drop = "voltbuild:macerator",
	groups = {energy=1, energy_consumer=1, cracky=2, not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
	voltbuild = {max_tier=1,energy_cost=2,max_stress=2000},
	cooking_method="grinding",
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
	allow_metadata_inventory_put = voltbuild.allow_metadata_inventory_put,
	allow_metadata_inventory_move = voltbuild.allow_metadata_inventory_move,
})

components.register_abm({
	nodenames = {"voltbuild:macerator","voltbuild:macerator_active"},
	interval = 1.0,
	chance = 1,
	action=voltbuild.production_abm
})
