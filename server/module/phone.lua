--- removes a player from the call for everyone in the call.
---@param source number the player to remove from the call
---@param callChannel number the call channel to remove them from
function removePlayerFromCall(source, callChannel)
	logger.verbose('[call] Removed %s from call %s', source, callChannel)

	callData[callChannel] = callData[callChannel] or {}
	for player, _ in pairs(callData[callChannel]) do
		TriggerClientEvent('pma-voice:removePlayerFromCall', player, source)
	end
	callData[callChannel][source] = nil
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].call = 0
end

--- adds a player to a call
---@param source number the player to add to the call
---@param callChannel number the call channel to add them to
function addPlayerToCall(source, callChannel)
	logger.verbose('[call] Added %s to call %s', source, callChannel)
	-- check if the channel exists, if it does set the varaible to it
	-- if not create it (basically if not callData make callData)
	callData[callChannel] = callData[callChannel] or {}
	for player, _ in pairs(callData[callChannel]) do
		-- don't need to send to the source because they're about to get sync'd!
		if player ~= source then
			TriggerClientEvent('pma-voice:addPlayerToCall', player, source)
		end
	end
	callData[callChannel][source] = true
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].call = callChannel
	TriggerClientEvent('pma-voice:syncCallData', source, callData[callChannel])
end

--- set the players call channel
---@param source number the player to set the call off
---@param _callChannel number the channel to set the player to (or 0 to remove them from any call channel)
function setPlayerCall(source, _callChannel)
	if GetConvarInt('voice_enableCalls', 1) ~= 1 then return end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local isResource = GetInvokingResource()
	local plyVoice = voiceData[source]
	local callChannel = tonumber(_callChannel)
	if not callChannel then
		-- only full error if its sent from another server-side resource
		if isResource then
			error(("'callChannel' expected 'number', got: %s"):format(type(_callChannel)))
		else
			return logger.warn("%s sent a invalid call, 'callChannel' expected 'number', got: %s", source,
				type(_callChannel))
		end
	end
	if isResource then
		-- got set in a export, need to update the client to tell them that their call
		-- changed
		TriggerClientEvent('pma-voice:clSetPlayerCall', source, callChannel)
	end

	Player(source).state.callChannel = callChannel

	if callChannel ~= 0 and plyVoice.call == 0 then
		addPlayerToCall(source, callChannel)
	elseif callChannel == 0 then
		removePlayerFromCall(source, plyVoice.call)
	elseif plyVoice.call > 0 then
		removePlayerFromCall(source, plyVoice.call)
		addPlayerToCall(source, callChannel)
	end
end

exports('setPlayerCall', setPlayerCall)

-- resource name -> check, see addCallCheck
local callChecks = {}

--- adds a check run before a client changes its own call channel through the `pma-voice:setPlayerCall` net event
--- (the server-side `setPlayerCall` export is trusted and never checked). One check per resource, removed when it stops.
---@param cb function called with (source, callChannel, currentCallChannel), must return true to allow the change
function addCallCheck(cb)
	local cbType = type(cb)
	if cbType ~= 'function' and (cbType ~= 'table' or not cb.__cfx_functionReference) then
		error(("'cb' expected 'function' got '%s'"):format(cbType))
	end
	local resource = GetInvokingResource() or GetCurrentResourceName()
	callChecks[resource] = cb
	logger.info('%s added a call check', resource)
end

exports('addCallCheck', addCallCheck)

--- removes the call check of the invoking resource
function removeCallCheck()
	local resource = GetInvokingResource() or GetCurrentResourceName()
	callChecks[resource] = nil
	logger.info('%s removed its call check', resource)
end

exports('removeCallCheck', removeCallCheck)

AddEventHandler('onResourceStop', function(resource)
	callChecks[resource] = nil
end)

--- whether every call check allows `source` to move from `current` to `callChannel`; a failing check refuses
---@return boolean allowed
---@return string|nil resource the resource whose check refused
function canSetPlayerCall(source, callChannel, current)
	for resource, check in pairs(callChecks) do
		local ok, allowed = pcall(check, source, callChannel, current)
		if not ok then
			logger.error('call check of %s failed: %s', resource, allowed)
			return false, resource
		end
		if allowed ~= true then
			return false, resource
		end
	end
	return true
end

RegisterNetEvent('pma-voice:setPlayerCall', function(callChannel)
	local src = source
	local channel = tonumber(callChannel)
	if channel then
		voiceData[src] = voiceData[src] or defaultTable(src)
		local current = voiceData[src].call
		local allowed, resource = canSetPlayerCall(src, channel, current)
		if not allowed then
			-- refused before anything is sent: nobody is told of the attempt, the client keeps its current call
			logger.verbose('[call] %s refused call %s (check of %s)', src, channel, resource)
			TriggerClientEvent('pma-voice:clSetPlayerCall', src, current)
			return
		end
	end
	setPlayerCall(src, callChannel)
end)
