## addCallCheck

## Description

Adds a check run before a client changes its own call channel through the `pma-voice:setPlayerCall` net event (the
`setPlayerCall` export, called by server resources, is never checked). A refused change is dropped before anything is
sent: the client is not added to the call, the other members are not told, and the client is reset to its current call.

One check per resource: calling it again replaces the previous one; it is removed when the resource stops, or with
`removeCallCheck()`. A check that errors refuses the change.

## Parameters

* **function**: called with `(source, callChannel, currentCallChannel)`, must return `true` to allow the change.


```lua
-- Example for addCallCheck: call channels 900000 and up are reserved to the server
exports['pma-voice']:addCallCheck(function(source, callChannel, currentCallChannel)
	return callChannel < 900000 and currentCallChannel < 900000
end)
```
