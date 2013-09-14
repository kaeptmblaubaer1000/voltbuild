consumers={}

consumers.discharge = voltbuild.discharge_item


function consumers.get_progressbar(v,mv,bg,fg)
	local percent = v/mv*100
	local bar="image[3,2;2,1;"..bg.."^[lowpart:"..
			percent..":"..fg.."^[transformR270]"
	return bar
end

function consumers.on_construct(pos)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size("discharge", 1)
end

consumers.can_dig = voltbuild.can_dig

consumers.inventory = voltbuild.inventory

function consumers.get_formspec(pos)
	formspec = voltbuild.size_spec..
	voltbuild.discharge_spec..
	voltbuild.player_inventory_spec..
	voltbuild.vertical_chargebar_spec(pos)
	return formspec
end

dofile(modpath.."/electric_furnace.lua")
dofile(modpath.."/macerator.lua")
dofile(modpath.."/extractor.lua")
dofile(modpath.."/compressor.lua")
dofile(modpath.."/recycler.lua")

dofile(modpath.."/miner.lua")
