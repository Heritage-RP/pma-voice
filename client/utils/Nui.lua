local uiReady = promise.new()
function sendUIMessage(message)
	Citizen.Await(uiReady)
	SendNUIMessage(message)
end

RegisterNUICallback("uiReady", function(data, cb)
	uiReady:resolve(true)

	cb('ok')
end)

-- Another resource may hide the voice UI for a while (a screen without information), on top of voice_enableUi.
local uiHidden = false

--- Whether the voice UI is drawn: the voice_enableUi convar and no setUiHidden(true).
function uiShown()
	return GetConvarInt("voice_enableUi", 1) == 1 and not uiHidden
end

exports('setUiHidden', function(hidden)
	uiHidden = hidden == true
	CreateThread(function()
		sendUIMessage({ uiEnabled = uiShown() })
	end)
end)
