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
	kill = function(target)
		if not target then msgBar("STOP FAILING MULT", 1) return end
		if not game.Players[target] then msgBar("STOP FAILING MULT", 1) return end
		game.Players[target].Character:BreakJoints()
		msgBar("lel i just killed "..target)
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
