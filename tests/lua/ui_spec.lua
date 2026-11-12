-- client/utils/Nui.lua with FiveM stubs: setUiHidden hides the voice UI on top of voice_enableUi.
-- Run from the resource folder: docker run --rm -v "$PWD":/w -w /w nickblah/lua:5.4 lua tests/lua/ui_spec.lua

local failures = 0
local function check(name, cond)
	if cond then io.write('ok   ', name, '\n') else failures = failures + 1; io.write('FAIL ', name, '\n') end
end

local function load(enableUi)
	local env = { messages = {}, exports = {}, callbacks = {} }
	_G.promise = { new = function() return {} end }
	_G.Citizen = { Await = function() end }
	_G.SendNUIMessage = function(message) env.messages[#env.messages + 1] = message end
	_G.RegisterNUICallback = function(name, fn) env.callbacks[name] = fn end
	_G.CreateThread = function(fn) fn() end
	_G.GetConvarInt = function(name, fallback) if name == 'voice_enableUi' then return enableUi end return fallback end
	_G.exports = function(name, fn) env.exports[name] = fn end
	dofile('client/utils/Nui.lua')
	env.last = function() return env.messages[#env.messages] end
	return env
end

do
	local env = load(1)
	check('shown by default', uiShown() == true)
	env.exports.setUiHidden(true)
	check('setUiHidden(true) hides it and tells the UI', uiShown() == false and env.last().uiEnabled == false)
	env.exports.setUiHidden(false)
	check('setUiHidden(false) shows it again', uiShown() == true and env.last().uiEnabled == true)
	env.exports.setUiHidden('yes')
	check('anything but true shows it', uiShown() == true)
end

do
	local env = load(0)
	env.exports.setUiHidden(false)
	check('voice_enableUi 0 still wins', uiShown() == false and env.last().uiEnabled == false)
end

if failures > 0 then os.exit(1) end
