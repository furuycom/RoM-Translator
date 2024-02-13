local lib,name,path = ...
local me = {
	children = {},
	exports = {},
}
local py_lib, py_timer, py_string, py_table, py_num, py_hash, py_color, py_hook, py_callback, py_item = pylib.GetLibraries()
me.GetText = function(key, default)
	return py_table.GetTableVar(me, key, default or key)
end

me.CreateLoca = function(default, repl)
	for a,b in pairs(default) do
		if type(repl[a])=="table" then
			repl[a] = me.CreateLoca(default[a], repl[a])
		else
			repl[a] = repl[a] or b
		end
	end
	return repl
end

me._Init = function ()
	local dir = string.match(me:GetTablePath(),"^(.-)[^/]+$")
	local fn_def, err1 = loadfile(dir.."default.lua")
	local fn_lang, err2 = loadfile(dir..GetLanguage():lower():sub(1,2)..".lua")
	local default = {}
	if fn_def then
		default = fn_def()
	end
	local lang = {}
	if fn_lang then
		lang = fn_lang()
	end
	
	lang = me.CreateLoca(default, lang)
	for a,b in pairs(lang) do
		me[a] = b
	end
end
lib.CreateTable(me,name,path, lib)
