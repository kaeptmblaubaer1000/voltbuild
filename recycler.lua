recycler_blacklist = {}
recycler = {}
voltbuild.recipes.recycle = {}
--any item not specifically declared as a recycle recipe is
--automatically turned into scrap 1/8th of the time.
voltbuild.recipes.recycle.__index = function (table,key)
	if math.random(1,8)==1 then
		return "voltbuild:scrap"
	end
	return "air"
end
setmetatable(voltbuild.recipes.recycle,voltbuild.recipes.recycle)

function recycler.register_blacklist(name)
	recycler_blacklist[string1]=true
end

minetest.register_node("voltbuild:recycler", {
	description = "recycler",
	tiles = {"itest_recycler_side.png", "itest_recycler_side.png", "itest_recycler_side.png",
		"itest_recycler_side.png", "itest_recycler_side.png", "itest_recycler_front.png"},
	paramtype2 = "facedir",
	groups = {energy=1, energy_consumer=1, cracky=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
	cooking_method = "recycle",
	voltbuild = {max_tier=1,energy_cost=2,max_stress=2000},
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
		meta:set_int("max_psize",64)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
		meta:set_string("formspec", consumers.get_formspec(pos)..
				voltbuild.production_spec..
				consumers.get_progressbar(0,1,
					"itest_recycler_progress_bg.png",
					"itest_recycler_progress_fg.png"))
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

minetest.register_node("voltbuild:recycler_active", {
	description = "recycler",
	tiles = {"itest_recycler_side.png", "itest_recycler_side.png", "itest_recycler_side.png",
		"itest_recycler_side.png", "itest_recycler_side.png", "itest_recycler_front_active.png"},
	paramtype2 = "facedir",
	drop = "voltbuild:recycler",
	groups = {energy=1, energy_consumer=1, cracky=2, not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
	cooking_method = "recycle",
	voltbuild = {max_tier=1,energy_cost=2,max_stress=2000},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("energy",0)
		meta:set_int("max_energy",800)
		meta:set_int("max_psize",64)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
		meta:set_string("formspec", consumers.get_formspec(pos)..
				voltbuild.production_spec)
		consumers.on_construct(pos)
	end,
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
	nodenames = {"voltbuild:recycler","voltbuild:recycler_active"},
	interval = 1.0,
	chance = 1,
	action = voltbuild.production_abm,
})
