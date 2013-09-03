minetest.register_node( "voltbuild:stone_with_uranium", {
	description = "Uranium Ore",
	tiles = { "default_stone.png^itest_mineral_uranium.png" },
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = 'voltbuild:uranium_lump',
}) 

minetest.register_node( "voltbuild:stone_with_tin", {
	description = "Tin Ore",
	tiles = { "default_stone.png^itest_mineral_tin.png" },
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = 'voltbuild:tin_lump',
}) 

minetest.register_craftitem( "voltbuild:tin_lump", {
	description = "Tin lump",
	inventory_image = "itest_tin_lump.png",
})

minetest.register_craftitem( "voltbuild:uranium_lump", {
	description = "Uranium lump",
	inventory_image = "itest_uranium_lump.png",
})

minetest.register_craftitem( "voltbuild:tin_ingot", {
	description = "Tin ingot",
	inventory_image = "itest_tin_ingot.png",
})

minetest.register_node( "voltbuild:tin_block", {
	description = "Tin block",
	groups={cracky=2},
	tiles={"itest_tin_block.png"},
})

minetest.register_craft({
	output = "voltbuild:tin_block",
	recipe = {{"voltbuild:tin_ingot","voltbuild:tin_ingot","voltbuild:tin_ingot"},
		{"voltbuild:tin_ingot","voltbuild:tin_ingot","voltbuild:tin_ingot"},
		{"voltbuild:tin_ingot","voltbuild:tin_ingot","voltbuild:tin_ingot"}}
})

minetest.register_craft({
	output = "voltbuild:tin_ingot 9",
	recipe = {{"voltbuild:tin_block"}}
})

minetest.register_craft({
	type = "cooking",
	output = "voltbuild:tin_ingot",
	recipe = "voltbuild:tin_lump"
})

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "voltbuild:stone_with_tin",
	wherein        = "default:stone",
	clust_scarcity = 12*12*12,
	clust_num_ores = 4,
	clust_size     = 3,
	height_min     = -63,
	height_max     = -16,
})

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "voltbuild:stone_with_tin",
	wherein        = "default:stone",
	clust_scarcity = 9*9*9,
	clust_num_ores = 5,
	clust_size     = 3,
	height_min     = -31000,
	height_max     = -64,
	flags          = "absheight",
})

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "voltbuild:stone_with_tin",
	wherein        = "default:stone",
	clust_scarcity = 8*8*8,
	clust_num_ores = 5,
	clust_size     = 3,
	height_min     = -31000,
	height_max     = -64,
	flags          = "absheight",
})

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "default:stone_with_copper",
	wherein        = "default:stone",
	clust_scarcity = 8*8*8,
	clust_num_ores = 5,
	clust_size     = 3,
	height_min     = -31000,
	height_max     = -64,
	flags          = "absheight",
})

minetest.register_ore({
	ore_type       = "scatter",
	ore            = "voltbuild:stone_with_uranium",
	wherein        = "default:stone",
	clust_scarcity = 9*9*9,
	clust_num_ores = 1,
	clust_size     = 1,
	height_min     = -31000,
	height_max     = -64,
	flags          = "absheight",
})


minetest.register_alias("moreores:mineral_tin","voltbuild:stone_with_tin")
minetest.register_alias("moreores:tin_lump","voltbuild:tin_lump")
minetest.register_alias("moreores:tin_ingot","voltbuild:tin_ingot")
minetest.register_alias("moreores:tin_block","voltbuild:tin_block")
