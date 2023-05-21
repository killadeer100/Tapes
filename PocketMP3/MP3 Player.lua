local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.open(90)

--Get Input
args = {...}
local outMsg = args[1]
modem.transmit(91, 90, outMsg)