local tArgs = {...}

print("boat v0.1")
local function printUsage()
	print("Usage: boat <hostname> [pluginDir]")
end

local sOpenedModem = nil
local function openModem()
	for n,sModem in ipairs( peripheral.getNames() ) do
		if peripheral.getType( sModem ) == "modem" then
			if not rednet.isOpen( sModem ) then
				rednet.open( sModem )
				sOpenedModem = sModem
			end
			return true
		end
	end
	printError("No modems found")
	return false
end

local function closeModem()
	if sOpenedModem ~= nil then
		rednet.close( sOpenedModem )
		sOpenedModem = nil
	end
end

-- Get hostname
local sHostname = tArgs[1]
if sHostname == nil then
	printUsage()
	return
end
local sPluginPath = tArgs[2]
if not sPluginPath then
	sPluginPath = fs.combine(shell.dir(), "plugins")
end
-- Host server
if not openModem() then
	return
end
rednet.host( "chat", sHostname )
print( "0 users connected." )
local tUsers = {}
local nUsers = 0
function send( sText, nUserID )
	if nUserID then
		local tUser = tUsers[ nUserID ]
		if tUser then
			rednet.send( tUser.nID, {
				sType = "text",
				nUserID = nUserID,
				sText = sText,
			}, "chat" )
		end
	else
		for nUserID, tUser in pairs( tUsers ) do
			rednet.send( tUser.nID, {
				sType = "text",
				nUserID = nUserID,
				sText = sText,
			}, "chat" )
		end
	end
end
	-- Setup ping pong
local tPingPongTimer = {}
function ping( nUserID )
	local tUser = tUsers[ nUserID ]
	rednet.send( tUser.nID, {
		sType = "ping to client",
		nUserID = nUserID,
	}, "chat" )

	local timer = os.startTimer( 15 )
	tUser.bPingPonged = false
	tPingPongTimer[ timer ] = nUserID
end

function printUsers()
	local x,y = term.getCursorPos()
	term.setCursorPos( 1, y - 1 )
	term.clearLine()
	if nUsers == 1 then
		print( nUsers .. " user connected." )
	else
		print( nUsers .. " users connected." )
	end
end

if not fs.exists(sPluginPath) then
	fs.makeDir(sPluginPath)
end

-- Handle messages
local ok, err = pcall( function()
	parallel.waitForAny( function()
		while true do
			local sEvent, timer = os.pullEvent( "timer" )
			local nUserID = tPingPongTimer[ timer ]
			if nUserID and tUsers[ nUserID ] then
				local tUser = tUsers[ nUserID ]
				if tUser then
					if not tUser.bPingPonged then
						send( "* "..tUser.sUsername.." has timed out" )
						tUsers[ nUserID ] = nil
						nUsers = nUsers - 1
						printUsers()
					else
						ping( nUserID )
					end
				end
			end
		end
	end,
	function()
		while true do
			local serverEnv = {}
			local tCommands
			tCommands = {
				["me"] = function( tUser, sContent )
					if string.len(sContent) > 0 then
						send( "* "..tUser.sUsername.." "..sContent )
					else
						send( "* Usage: /me [words]", tUser.nUserID )
					end
				end,
				["nick"] = function( tUser, sContent )
					if string.len(sContent) > 0 then
						local sOldName = tUser.sUsername
						tUser.sUsername = sContent
						send( "* "..sOldName.." is now known as "..tUser.sUsername )
					else
						send( "* Usage: /nick [nickname]", tUser.nUserID )
					end
				end,
				["list"] = function( tUser, sContent )
					send( "* Connected Users:", tUser.nUserID )
					local sUsers = "*"
					for nUserID, tUser in pairs( tUsers ) do
						sUsers = sUsers .. " " .. tUser.sUsername
					end
					send( sUsers, tUser.nUserID )
				end,
				["help"] = function( tUser, sContent )
					send( "* Available commands:", tUser.nUserID )
					local sCommands = "*"
					for sCommand, fnCommand in pairs( tCommands ) do
						sCommands = sCommands .. " /" .. sCommand
					end
					send( sCommands.." /logout", tUser.nUserID )
				end,
				["plugins"] = function(tUser)
					local tPlugins = fs.list(sPluginPath)
					send("* Plugins ("..#tPlugins.."): "..table.concat(tPlugins, ", "), tUser.nUserID)
				end,
			}
			function serverEnv.setCommand(name, func)
				if name == "help" then return end
				tCommands[name] = func
			end
			function serverEnv.getCommand(name)
				return tCommands[name]
			end
			setmetatable(serverEnv, {__index=getfenv()})
			for i, v in pairs(fs.list(sPluginPath)) do
				if fs.isDir(fs.combine(sPluginPath, v)) then
					-- found a valid plugin
					if fs.exists(fs.combine(sPluginPath, v) .. "/main.lua") then
						local fn, fnErr = loadfile(fs.combine(sPluginPath, v) .. "/main.lua", "plugin \"" .. v .. "\"")
						if not fn then
							printError("Plugin \""..v.."\" crashed!")
							printError(fnErr)
						else
							pcall(setfenv(fn, serverEnv))
						end
					end
				end
			end

			local nSenderID, tMessage = rednet.receive( "chat" )
			if type( tMessage ) == "table" then
				if tMessage.sType == "login" then
					-- Login from new client
					local nUserID = tMessage.nUserID
					local sUsername = tMessage.sUsername
					if nUserID and sUsername then
						tUsers[ nUserID ] = {
							nID = nSenderID,
							nUserID = nUserID,
							sUsername = sUsername,
						}
						nUsers = nUsers + 1
						printUsers()
						send( "* "..sUsername.." has joined the chat" )
						ping( nUserID )
					end

				else
					-- Something else from existing client
					local nUserID = tMessage.nUserID
					local tUser = tUsers[ nUserID ]
					if tUser and tUser.nID == nSenderID then
						if tMessage.sType == "logout" then
							send( "* "..tUser.sUsername.." has left the chat" )
							tUsers[ nUserID ] = nil
							nUsers = nUsers - 1
							printUsers()
						elseif tMessage.sType == "chat" then
							local sMessage = tMessage.sText
							if sMessage then
								local sCommand = string.match( sMessage, "^/([a-z]+)" )
								if sCommand then
									local fnCommand = tCommands[ sCommand ]
									if fnCommand then
										local sContent = string.sub( sMessage, string.len(sCommand)+3 )
										fnCommand( tUser, sContent )
									else
										send( "* Unrecognised command: /"..sCommand, tUser.nUserID )
									end
								else
									send( "<"..tUser.sUsername.."> "..tMessage.sText )
								end
							end

						elseif tMessage.sType == "ping to server" then
							rednet.send( tUser.nID, {
								sType = "pong to client",
								nUserID = nUserID,
							}, "chat" )

						elseif tMessage.sType == "pong to server" then
							tUser.bPingPonged = true

						end
					end
				end
			end
		end
	end )
end )
if not ok then
	printError(err)
end
-- Unhost server
for nUserID, tUser in pairs( tUsers ) do
	rednet.send( tUser.nID, {
		sType = "kick",
		nUserID = nUserID,
	}, "chat" )
end
rednet.unhost( "chat" )
closeModem()
