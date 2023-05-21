local modem = peripheral.find("modem") or error("No modem attached", 0)
local speaker = peripheral.find("speaker")

--Function for receiving file name
function getCmd(inChn)
	local event, side, channel, replyChannel, message, distance
	repeat
		event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
	until channel == inChn
	return message
end

--Table Name Function
function getSong(name)
	return pl.songTbl[name.."Right"]
end

--Main Function
while true do
	modem.open(91)
	pl = require("songs.StereoSongs")
	local file = getSong(getCmd(91))
	
	local handle, err
	if http and file:match("^https?://") then
		print("Downloading...")
		handle, err = http.get{ url = file, binary = true }
	else
		handle, err = fs.open(file, "rb")
	end

	if not handle then
		printError("Could not play audio:")
		error(err, 0)
	end

	print("Playing " .. file)
	
	repeat
		os.queueEvent("fakeEvent")
		os.pullEvent()
	until ((os.time()*1000) % 500) == 0

	local decoder = require "cc.audio.dfpwm".make_decoder()
	while true do
		local chunk = handle.read(16 * 1024)
		if not chunk then
			os.sleep(5)
			break
		end

		os.queueEvent("fakeEvent")
		os.pullEvent()

		local buffer = decoder(chunk)
		while not speaker.playAudio(buffer, 0.50) do
			os.pullEvent("speaker_audio_empty")
		end
	end

	handle.close()
end