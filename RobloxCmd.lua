local function msgBar(text, t)
	local _msg = Instance.new("Hint", game.Workspace)
	_msg.Text = text
	wait(t or 3)
	_msg:Destroy()
end

local commands = {
	msg = function(...)
		msgBar(table.concat({...}, " "))
	end,
	suicide = function(...)
		msgBar("*suicide mode*", 1)
		game.Players.MultRob.Character:BreakJoints()
	end,
}

game.Players.MultRob.Chatted:connect(function(msg)
	if msg:sub(1, 2) ~= "##" then return end
	local parts = {}
	for match in string.gmatch(msg:sub(3), "[^ ]+") do
		table.insert(parts, match)
	end
	local cmd = parts[1]
	if commands[cmd] then
		commands[cmd](unpack(parts, 2))
	end
end)
