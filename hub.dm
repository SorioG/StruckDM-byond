// Make the game available on Hub, so the servers will appear on the list

world
	hub = "SorioG.StruckDM"
	hub_password = "5UzhiEEssjJh60cT"

world/New()
	..()
	StatusLoop()

var/server_name = "StruckDM"
proc/StatusLoop()
	spawn while(1)
		sleep(20)
		var/st = ""
		st += "[server_name] | "
		st += "Gamemode: [GM.name] | "
		var/bot_count = 0
		var/mob/living/player/bot/B
		for (B in world)
			bot_count++
		if (bot_count)
			st += "Bots: [bot_count]"
		else
			st += "Bots: No Bots "

		world.status = st
