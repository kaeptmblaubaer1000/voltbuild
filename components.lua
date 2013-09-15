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
