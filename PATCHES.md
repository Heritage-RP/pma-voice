# Patches

Upstream: https://github.com/AvarianKnight/pma-voice (main)

Fork of pma-voice for the core of Heritage-RP/PRODUCTION-SERVER. Every patch is generic: a server sets its own values
through convars or other resources (Heritage-RP/PRODUCTION-SERVER docs/dev/forks.md).

| Patch | Kind | Upstream | Files |
|---|---|---|---|
| `addCallCheck(fn)` / `removeCallCheck()`: a check run before a client changes its own call channel (`pma-voice:setPlayerCall`); a refused change is dropped before anything is sent (PRODUCTION-SERVER#318, used by hrp-voice) | generic | candidate | `server/module/phone.lua`, `docs/server-setters/addCallCheck.md`, `README.md` |
| Tests: `tests/run.sh` runs `tests/lua/*_spec.lua` in Lua 5.4 through docker (`just test`) | generic | no | `tests/**` |
| Documentation of the fork | generic | no | `PATCHES.md` |
