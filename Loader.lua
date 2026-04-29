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

local Loader = {
	["Start"] = tick(),
	["Version"] = "1.0.0U",
	["Init"] = function(self)
		function self:LoadScript(Path: string, TargetFileName: string, ...: any): table
			local Success, Result = xpcall(function(...)
				loadstring(game:HttpGet("https://raw.githubusercontent.com/nikoladhima/KAT.lol/refs/heads/main/" .. Path))(...)
			end, function(Error)
				debug.traceback("LoadScript Error: " .. tostring(Error), 2)
				task.spawn(error, "LoadScript Error: " .. tostring(Error), 2)
			end, ...)

			if not Success then
				return {
					["Failed"] = true,
					["Value"] = Result
				}
			end

			if type(Result) == "table" and Result["Failed"] then
				error("[KAT.lol/" .. Path .. " | ERROR] Failed to load " .. TargetFileName .. ", Result: " .. tostring(Result["Value"]), 2)
			end
		end

		local Result = self:LoadScript("Init.luau", "Loader.lua", self)
		if type(Result) == "table" and Result["Failed"] then
			error("[KAT.lol/Loader | ERROR] Failed to load Init.luau: " .. tostring(Result["Value"]), 2)
		end
	end
}

return Loader:Init()
