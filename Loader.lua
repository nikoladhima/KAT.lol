--[[
    KAT.lol | Official Loader
    This script is Open Source and intended for learning and personal use.

    -- Made by Nikoleto Scripts
    GitHub: https://github.com/nikoladhima
    Discord: https://discord.gg/DwRT2nH93D
]]

if workspace.DistributedGameTime < 3 then
	task.wait(3 - workspace.DistributedGameTime)
end

local function LoadScript(Path: string, CurrentFileName: string, TargetFileName: string, ...: any): table
	local Success, Result = xpcall(function(...)
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/KAT.lol/refs/heads/main/" .. Path))(...)
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
		error("[KAT.lol/" .. CurrentFileName .. " | ERROR] Failed to load " .. TargetFileName .. ", Result: " .. tostring(Result["Value"]), 2)
	end

	return Result
end

local Result = LoadScript("src/Init.luau", "Loader.lua", "src/Init.luau", {
	["Start"] = tick(),
	["Version"] = "1.0.0U",
	["LoadScript"] = LoadScript
})

if type(Result) == "table" and Result["Failed"] then
    error("[KAT.lol] Fatal load error:\n" .. tostring(Result.Value), 0)
end
