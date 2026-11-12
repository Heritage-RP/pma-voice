## setUiHidden

## Description

Hides the voice UI (proximity range, talking and radio state) until called again with `false`, on top of the
`voice_enableUi` convar: a resource that clears the screen of information (a cinematic view) calls it. The voice itself
is untouched.

## Parameters

* **hidden**: `true` hides the UI, `false` shows it again (when `voice_enableUi` is 1)

```lua
exports['pma-voice']:setUiHidden(true)
exports['pma-voice']:setUiHidden(false)
```
