local function addZero(hex, bytes)
	return string.rep("0", (bytes*2)-hex:len())..hex
end

local function hex2ascii(hex, reverseBytes)
	local ascii = ""
	for i = 1, hex:len()/2 do
		ascii = (not reverseBytes and ascii or "") .. string.char(tonumber("0x"..hex:sub((i-1) * 2 + 1, (i-1) * 2 + 1)..hex:sub(i * 2, i * 2))) .. (reverseBytes and ascii or "")
	end
	return ascii
end

local function dec2hex(n)
	local hex = "0123456789abcdef"
	local h = ""
	while n > 0 do
		local rest = n % 16 + 1
		h = hex:sub(rest, rest) .. h
		n = math.floor(n / 16)
	end
	return h
end

local tArgs = {...}
if #tArgs < 1 then
	print("Usage: table2bmp <file>")
	return
end

local function makeHeader(width, height)
	local header1 = "BM"
	local header2 = ""
	local header3 = ""
	header2 = header2 .. hex2ascii("0000000036000000") -- idk
	header2 = header2 .. hex2ascii("28000000") -- idk
	header2 = header2 .. hex2ascii(addZero(dec2hex(width), 4), true) .. hex2ascii(addZero(dec2hex(height), 4), true) -- width+height
	header2 = header2 .. hex2ascii("0100") -- useless as crap
	header2 = header2 .. hex2ascii("1800") -- bit depth
	header2 = header2 .. hex2ascii("00000000") -- compressi- no.
--	header3 = header3 .. hex2ascii("00000000") -- nope, not compressed. BUT windows image viewer refuses to display odd number w/h
	header3 = header3 .. hex2ascii("00000000") -- pixels per meter - facepalm.
	header3 = header3 .. hex2ascii("00000000") -- pixels per meter - facepunch.
	header3 = header3 .. hex2ascii("00000000") -- color table, not used.
	header3 = header3 .. hex2ascii("00000000") -- color table, not used!
	return header1, header2, header3 -- we r finished :D but wai return 2 parts of the header? BECAUSE WE NEED THEM
end

local function makeBitmap(width, height, pixels)
	local header1, header2, header3 = makeHeader(width, height)
	local bmpPixels = ""
	local bmp
	for r = #pixels, 1, -1 do
		for c = 1, #pixels[r] do
			bmpPixels = bmpPixels .. hex2ascii(pixels[r][c], true)
		end
		if (width * 3) % 4 > 0 then
			bmpPixels = bmpPixels .. string.rep(string.char(0), 4 - (width * 3) % 4)
		end
	end
	bmp = header1 .. hex2ascii(addZero(dec2hex(header1:len()+4+header2:len()+4+header3:len()+bmpPixels:len()), 4), true) .. header2 .. hex2ascii(addZero(dec2hex(bmpPixels:len()), 4), true) .. header3 .. bmpPixels
	return bmp
end

local file = io.open(tArgs[1], "r")
local serialized = file:read("*a")
file:close()
local ok, err = loadstring("return "..serialized, "serialize")
if not ok then
	print("Error serializing file")
	if err then
		print(err)
		print("(fix this error to continue)")
	end
	return
end
local data, error = ok()
if not data then
	print("Error reading data")
	if error then
		print(error)
	end
	return
end
local bmp = makeBitmap(#data[1], #data, data)
local file = io.open(tArgs[1]..".bmp", "wb")
file:write(bmp)
file:close()
print("File saved as "..tArgs[1]..".bmp")



