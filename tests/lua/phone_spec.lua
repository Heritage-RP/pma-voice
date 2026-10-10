-- server/module/phone.lua with FiveM stubs: call checks run before a client joins a call (addCallCheck).
-- Run from the resource folder: docker run --rm -v "$PWD":/w -w /w nickblah/lua:5.4 lua tests/lua/phone_spec.lua

local failures = 0
local function check(name, cond)
	if cond then io.write('ok   ', name, '\n') else failures = failures + 1; io.write('FAIL ', name, '\n') end
end

local function load()
	local env = { sent = {}, net = {}, events = {}, exports = {}, invoking = 'hrp-voice', logs = {} }
	_G.voiceData, _G.callData = {}, {}
	_G.logger = setmetatable({}, { __index = function(_, level)
		return function(fmt, ...) env.logs[#env.logs + 1] = { level, fmt:format(...) } end
	end })
	_G.GetConvarInt = function(_, fallback) return fallback end
	_G.GetInvokingResource = function() return env.invoking end
	_G.GetCurrentResourceName = function() return 'pma-voice' end
	_G.Player = function() return { state = {} } end
	_G.defaultTable = function() return { radio = 0, call = 0, lastRadio = 0, lastCall = 0 } end
	_G.TriggerClientEvent = function(name, target, ...) env.sent[#env.sent + 1] = { name, target, ... } end
	_G.RegisterNetEvent = function(name, fn) env.net[name] = fn end
	_G.AddEventHandler = function(name, fn) env.events[name] = fn end
	_G.exports = function(name, fn) env.exports[name] = fn end
	dofile('server/module/phone.lua')
	-- a client sends the net event (source is a global inside the handler)
	env.request = function(player, channel)
		env.invoking = nil
		_G.source = player
		env.net['pma-voice:setPlayerCall'](channel)
		_G.source = nil
	end
	env.sentTo = function(name, target)
		for _, event in ipairs(env.sent) do
			if event[1] == name and event[2] == target then return event end
		end
	end
	return env
end

local STAFF_CHANNEL = 900007

do
	local env = load()
	env.request(3, 1234)
	check('no check: a client joins its call', voiceData[3].call == 1234 and callData[1234][3] == true)
end

do
	local env = load()
	-- someone (the target) is in the staff channel, listened to by a staff member
	env.invoking = 'hrp-voice'
	env.exports.setPlayerCall(7, STAFF_CHANNEL)
	env.exports.setPlayerCall(2, STAFF_CHANNEL)
	env.sent = {}
	local calls = {}
	env.exports.addCallCheck(function(source, channel, current)
		calls[#calls + 1] = { source, channel, current }
		return channel < 900000
	end)

	env.request(5, STAFF_CHANNEL)
	check('refused: not added to the call', voiceData[5].call == 0 and callData[STAFF_CHANNEL][5] == nil)
	check('refused: members not told', env.sentTo('pma-voice:addPlayerToCall', 7) == nil
		and env.sentTo('pma-voice:addPlayerToCall', 2) == nil)
	check('refused: member list not sent', env.sentTo('pma-voice:syncCallData', 5) == nil)
	local reset = env.sentTo('pma-voice:clSetPlayerCall', 5)
	check('refused: client told its call is unchanged', reset ~= nil and reset[3] == 0)
	check('check receives source, channel and current call', calls[1][1] == 5 and calls[1][2] == STAFF_CHANNEL
		and calls[1][3] == 0)

	env.request(5, 42)
	check('allowed by the check: joins the call', voiceData[5].call == 42 and callData[42][5] == true)

	env.invoking = 'hrp-voice'
	env.exports.setPlayerCall(5, STAFF_CHANNEL)
	check('server export is never checked', voiceData[5].call == STAFF_CHANNEL)
end

do
	local env = load()
	env.exports.addCallCheck(function() error('boom') end)
	env.request(4, 10)
	check('a failing check refuses', voiceData[4].call == 0)
	local logged = false
	for _, entry in ipairs(env.logs) do
		if entry[1] == 'error' and entry[2]:find('hrp%-voice') then logged = true end
	end
	check('a failing check is logged', logged)
end

do
	local env = load()
	env.exports.addCallCheck(function() return false end)
	env.events.onResourceStop('hrp-voice')
	env.request(4, 10)
	check('check removed when its resource stops', voiceData[4].call == 10)

	env.invoking = 'hrp-voice'
	env.exports.addCallCheck(function() return false end)
	env.exports.removeCallCheck()
	env.request(6, 11)
	check('removeCallCheck removes the check of the invoking resource', voiceData[6].call == 11)
end

do
	local env = load()
	env.exports.addCallCheck(function() return 1 end)
	env.request(8, 12)
	check('only `true` allows', voiceData[8].call == 0)

	local ok = pcall(env.exports.addCallCheck, 'nope')
	check('rejects a non-function check', not ok)
end

do
	local env = load()
	env.exports.addCallCheck(function() return false end)
	env.request(9, 'abc')
	check('invalid channel: still a warning, not a check', voiceData[9].call == 0 and #env.logs >= 1)
end

if failures > 0 then
	io.write(failures, ' failure(s)\n')
	os.exit(1)
end
io.write('all passed\n')
