--[[
	█████   ████   █████████   ███████████    ████           ████
	▒▒███   ███▒   ███▒▒▒▒▒███ ▒█▒▒▒███▒▒▒█   ▒▒███          ▒▒███
	▒███  ███    ▒███    ▒███ ▒   ▒███  ▒     ▒███   ██████  ▒███
	▒███████     ▒███████████     ▒███        ▒███  ███▒▒███ ▒███
	▒███▒▒███    ▒███▒▒▒▒▒███     ▒███        ▒███ ▒███ ▒███ ▒███
	▒███ ▒▒███   ▒███    ▒███     ▒███        ▒███ ▒███ ▒███ ▒███
	█████ ▒▒████ █████   █████    █████    ██ █████▒▒██████  █████
	▒▒▒▒▒   ▒▒▒▒ ▒▒▒▒▒   ▒▒▒▒▒    ▒▒▒▒▒    ▒▒ ▒▒▒▒▒  ▒▒▒▒▒▒  ▒▒▒▒▒

    -- Made by Nikoleto Scripts, if you encounter issues, open a ticket in the Discord server.
    GitHub: https://github.com/nikoladhima
    Discord: https://discord.gg/DsGCKtxxEN / @nikoleto._
]]

if workspace.DistributedGameTime < 3 then
	task.wait(3 - workspace.DistributedGameTime)
end

local function LoadScript(Path, CurrentFileName, ...)
	local Success, Result = xpcall(function(...)
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/KAT.lol/main/" .. Path .. "?q=" .. tostring(tick())))(...)
	end, function(Error)
		return debug.traceback("LoadScript Error: " .. tostring(Error), 2)
	end, ...)

	if not Success then
		return {
			Failed = true,
			Value = Result
		}
	end

	if type(Result) == "table" and Result["Failed"] then
		error("[KAT.lol/" .. CurrentFileName .. " | ERROR] Failed to load " .. Path .. ", Result: " .. tostring(Result["Value"]), 2)
	end

	return Result
end

local Result = LoadScript("src/Init.luau", "Loader.lua", {
	["Start"] = tick(),
	["Version"] = "1.1.1",
	["LoadScript"] = LoadScript
})

if type(Result) == "table" and Result["Failed"] then
    error("[KAT.lol] Fatal load error:\n" .. tostring(Result["Value"]), 0)
end
