itest_world_upgrade = minetest.setting_getbool("voltbuild_itest_world_upgrade") or false

modpath = minetest.get_modpath("voltbuild")
moreores_path = minetest.get_modpath("moreores")

voltbuild = {}
voltbuild.registered_ores = {}

function voltbuild.register_ore(name,value)
	voltbuild.registered_ores[name]=value
end

function voltbuild_create_infotext(name)
	return(string.gsub(string.sub(name,string.find(name,":")+1),"_"," "))
end

function voltbuild_hacky_swap_node(pos,name)
	local node = minetest.env:get_node(pos)
	local meta = minetest.env:get_meta(pos)
	if node.name == name then
		return
	end
	node.name = name
	local meta0 = meta:to_table()
	minetest.env:set_node(pos,node)
	meta = minetest.env:get_meta(pos)
	meta:from_table(meta0)
	meta:set_string("infotext",voltbuild_create_infotext(node.name))
end

function addVect(pos1,pos2)
	return {x=pos1.x+pos2.x,y=pos1.y+pos2.y,z=pos1.z+pos2.z}
end

function param22dir(param2)
	if param2==0 then
		return {x=1,y=0,z=0}
	elseif param2==1 then
		return {x=0,y=0,z=-1}
	elseif param2==2 then
		return {x=-1,y=0,z=0}
	else
		return {x=0,y=0,z=1}
	end
end

function get_node_field(name,meta,key,pos)
	if meta == nil then meta = minetest.env:get_meta(pos) end
	if name == nil then name = minetest.env:get_node(pos).name end
	if meta:get_string(key) ~= "" then return meta:get_int(key) end
	if minetest.registered_nodes[name] and
		minetest.registered_nodes[name].voltbuild and
		minetest.registered_nodes[name].voltbuild[key] then
			return minetest.registered_nodes[name].voltbuild[key]
	end
	return minetest.get_item_group(name,key)
end

function get_node_field_float(name,meta,key,pos)
	if meta == nil then meta = minetest.env:get_meta(pos) end
	if name == nil then name = minetest.env:get_node(pos).name end
	if meta:get_string(key) ~= "" then return meta:get_float(key) end
	if minetest.registered_nodes[name] and
		minetest.registered_nodes[name].voltbuild and
		minetest.registered_nodes[name].voltbuild[key] then
			return minetest.registered_nodes[name].voltbuild[key]
	end
	return 0
end

function get_item_field(name,key)
	if minetest.registered_items[name] and
		minetest.registered_items[name].voltbuild and
		minetest.registered_items[name].voltbuild[key] then
			return minetest.registered_items[name].voltbuild[key]
	end
	return minetest.get_item_group(name,key)
end

function is_fuel_no_lava(stack)
	return (minetest.get_craft_result({method="fuel",width=1,items={stack}}).time ~= 0)
		and (string.find(stack:get_name(),"lava")==nil)
end

function clone_node(name)
	node2={}
	node=minetest.registered_nodes[name]
	for k,v in pairs(node) do
		node2[k]=v
	end
	return node2
end

dofile(modpath.."/builtin.lua")
dofile(modpath.."/mapgen.lua")
dofile(modpath.."/voltbuild_objects.lua")
dofile(modpath.."/components.lua")
dofile(modpath.."/iron_furnace.lua")
dofile(modpath.."/energy_transport.lua")
dofile(modpath.."/cables.lua")
dofile(modpath.."/charge.lua")
dofile(modpath.."/generators.lua")
dofile(modpath.."/storage.lua")
dofile(modpath.."/consumers.lua")
dofile(modpath.."/craft.lua")
if itest_world_upgrade then
	dofile(modpath.."/itest_upgrade_compat.lua")
	print("voltbuild is using one way upgrade")
end

print("voltbuild loaded!")
