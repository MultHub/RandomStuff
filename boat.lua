local tArgs = {...}

print("boat v0.2")
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

local events = {
	connect = {},
	disconnect = {},
	chat = {},
}
local configDefaults = {
	connectMessage = "* %s has joined the chat",
	disconnectMessage = "* %s has left the chat",
	unknownCommandMessage = "* Unrecognised command: /%s",
	chatMessage = "<%s> %s",
}
local config = {}
serverEnv = {}
local reloadPlugins
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
	["reload"] = function(tUser)
		reloadPlugins()
		send("* "..tUser.sUsername.." has reloaded the server")
		send("* Reload complete.", tUser.nUserID)
	end,
	["events"] = function(tUser)
		send("* Registered events:", tUser.nUserID)
		for eventName, eventList in pairs(events) do
			send("  - "..eventName..":", tUser.nUserID)
			for name in pairs(eventList) do
				send("    - "..name, tUser.nUserID)
			end
		end
	end,
}
function serverEnv.setCommand(name, func)
	if name == "help" then return end
	tCommands[name] = func
end
function serverEnv.getCommand(name)
	return tCommands[name]
end
function serverEnv.setEvent(event, name, func)
	events[event][name] = func
end
function serverEnv.getEvent(event, name)
	return events[event][name]
end
function serverEnv.setConfig(key, value)
	config[key] = value
end
function serverEnv.getConfig(key)
	return config[key]
end
setmetatable(serverEnv, {__index=getfenv()})
reloadPlugins = function()
	for i, v in pairs(events) do
		events[i] = {}
	end
	for i, v in pairs(configDefaults) do
		config[i] = v
	end
	for i, v in pairs(fs.list(sPluginPath)) do
		if fs.isDir(fs.combine(sPluginPath, v)) then
			-- found a valid plugin
			if fs.exists(fs.combine(sPluginPath, v) .. "/main.lua") then
				local fn, fnErr = loadfile(fs.combine(sPluginPath, v) .. "/main.lua", "plugin \"" .. v .. "\"")
				if not fn then
					printError("Plugin \""..v.."\" crashed!")
					printError(fnErr)
				else
					local pluginEnv = {
						getPath = function()
							return fs.combine(sPluginPath, v)
						end,
					}
					setmetatable(pluginEnv, {__index = serverEnv})
					pcall(setfenv(fn, pluginEnv))
				end
			end
		end
	end
end
reloadPlugins()
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
						for i, v in pairs(events.disconnect) do
							v(tUsers[nUserID])
						end
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
						send( config.connectMessage:format(sUsername) )
						for i, v in pairs(events.connect) do
							v(tUsers[nUserID])
						end
						ping( nUserID )
					end
				else
					-- Something else from existing client
					local nUserID = tMessage.nUserID
					local tUser = tUsers[ nUserID ]
					if tUser and tUser.nID == nSenderID then
						if tMessage.sType == "logout" then
							send( config.disconnectMessage:format(tUser.sUsername) )
							for i, v in pairs(events.disconnect) do
								v(tUsers[nUserID])
							end
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
										send( config.unknownCommandMessage:format(sCommand), tUser.nUserID )
									end
								else
									send( config.chatMessage:format(tUser.sUsername, sMessage) )
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
