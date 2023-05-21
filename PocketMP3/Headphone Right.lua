--Function for receiving file name
function getCmd()
	local event, side, channel, replyChannel, message, distance
	repeat
		event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
	until channel == inChn
	return message
end

--Function for switching modem attachment
function swapMod()
	pocket.equipBack()
	print ("Swapped to "..peripheral.getNames())
	return
end

--Table Name Function
function getSong(name)
	return pl.songTbl[name.."Right"]
end

--Main Function
while true do
	--Setup Modem
	local modem = peripheral.find("modem") or error("No modem attached", 0)
	modem.open(91)
	local pl = require("songs.StereoSongs")
	local file = getSong(getCmd())
	modem.close()
	
	--Switch to Speaker Module
	swapMod()
	local speaker = peripheral.find("speaker")
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
		while not speaker.playAudio(buffer) do
			os.pullEvent("speaker_audio_empty")
		end
	end

	handle.close()
	
	--Switch to Modem
	swapMod()
end