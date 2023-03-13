
admin/verb
	AddBot(count=1 as num)
		set category = "Admin"
		set desc = "Adds AI-controlled players to the server"

		for (var/i = 0, i < count, i++)
			new/mob/living/player/bot(rand_loc(usr.z))
		world << "<i>[count] Bots are now added to the server"
	RemoveAllBots()
		set category = "Admin"
		set desc = "Removes all of the bots"

		var/mob/living/player/bot/B
		for (B in world)
			del(B)
		world << "<i>All of the bots are now removed"
	ToggleBotDoEmote()
		set category = "Admin"

		bot_do_emotes = !bot_do_emotes

		if (bot_do_emotes)
			world << "<i>Bots on this server can now use emotes"
		else
			world << "<i>Bots on this server will not be able to use emotes"
	ToggleGamemodeEndless()
		set category = "Admin"
		set desc = "Don't let the game lose the time."

		gm_endless = !gm_endless

		if (gm_endless)
			world << "<i>The gamemode will no longer time out"
		else
			world << "<i>The gamemode will time out"
	SetBotDifficulty(diff as anything in admin_bot_difficulty)
		set category = "Admin"

		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		bot_difficulty = admin_bot_difficulty[diff]

		world << "<i>Bot Difficulty is now set to [diff]"

	EndGame()
		set category = "Admin"
		set desc = "Forces the game to end."

		if (usr.client.connection == "telnet")
			usr << "<b>Ending the game forcefully."

		gm_force_ending = 1
		game_time = 0

	ForceGamemode(typ as null|anything in gamemodes)
		set category = "Admin"
		set desc = "Make the server always use the chosen gamemode."

		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		if (!typ)
			forced_gamemode = null
			world << "<i>The gamemode is no longer forced."
		else
			forced_gamemode = typ
			world << "<i>[forced_gamemode.name] is now forced to use on the server"

	GiveMeItem(typ as anything in typesof(/obj/item))
		set category = "Admin"

		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		var/obj/item/I = new typ()
		if (I.PlayerPick(usr))
			if (I.Move(usr))
				usr.holding = I
		else
			del(I)
	Teleport()
		set category = "Admin"

		if (usr.client.teleporting) return
		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		usr.client.view = 500
		usr.client.teleporting = 1

		usr << "<b>Click to where you want to teleport"
	TestingMap()
		set category = "Admin"
		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		usr.loc = rand_loc(9)

	CheckStatus()
		set category = "Admin"

		usr << world.status

	ToggleNoDrop()
		set category = "Admin"
		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		usr.client.adm_nodrop = !usr.client.adm_nodrop

		if (usr.client.adm_nodrop)
			usr << "<i>Your items wont drop when killed or by itself"
		else
			usr << "<i>Your items will drop now"

	Explode(atom/victim as mob|turf|obj)
		set category = "Admin"
		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		if (ismob(victim) || isobj(victim))
			explode(victim.loc, 30)
		else
			explode(victim, 30)

	ExplodeAndTakeFire(atom/victim as mob|turf|obj)
		set category = "Admin"
		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		if (ismob(victim) || isobj(victim))
			explode(victim.loc, 30, take_fire=1)
		else
			explode(victim, 30, take_fire=1)

	Kill(mob/living/victim as mob in world)
		set category = "Admin"
		set desc = "Kills the player"

		/*
		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return
		*/

		if (istext(victim))
			var/mob/living/M

			for (M in world)
				if (lowertext(M.name) == victim)
					victim = M
					break

			if (!(ismob(victim) || isobj(victim)))
				return

		if (!istype(victim)) return
		if (usr.client.connection == "telnet")
			usr << "<b>Killed [victim]."

		victim.Damage(victim.health)
		victim << "<i>[usr] killed you."

	ToggleGodmode()
		set category = "Admin"
		set desc = "Make yourself undamagable to others"

		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		usr.is_undamagable = !usr.is_undamagable

		if (usr.is_undamagable)
			usr << "<b>You will no longer take damage"
		else
			usr << "<b>You will now take damage"

	Bring(mob/living/victim as mob in world)
		set category = "Admin"
		set desc = "Teleports the player/npc to your location"

		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		victim.loc = usr.loc

	TeleportToCurrentMap()
		set category = "Admin"

		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		usr.Move(rand_loc(current_map))

	Boot(mob/living/victim as mob in world, reason as null|text)
		set category = "Admin"
		set desc = "Remove the player from the server"

		if (victim == usr)
			usr << "<b>Don't even try booting yourself."
			return

		if (istext(victim))
			var/mob/M

			for (M in world)
				if (lowertext(M.name) == victim)
					victim = M
					break

			if (!(ismob(victim) || isobj(victim)))
				return

		if (victim.client)
			victim << "<b><font color=red>You have been booted by [usr]"
			if (reason)
				victim << "<font color=red>Reason: [reason]"
			usr << "Booted [victim] from the server."
			del(victim)
		else
			usr << "<b>[victim] is not a player."

	Snap(atom/victim as mob|obj in world)
		set category = "Admin"
		set desc = "Removes the NPC/Object in the world, Can also be used with bots"

		if (victim == usr)
			usr << "<b>Don't even try removing yourself."
			return

		if (istext(victim))
			var/atom/M

			for (M in world)
				if (lowertext(M.name) == victim)
					victim = M
					break

			if (!(ismob(victim) || isobj(victim)))
				return

		if (ismob(victim) && victim:client)
			usr << "<b>[victim] is a player, please use Boot or Ban instead."
			return

		usr << "<b>Removed [victim] from the existence."
		victim.play_sound('q009/explosion.ogg')
		ohearers(victim) << "<i>[usr] removed [victim] from the existence"

		del(victim)

	Ban(mob/living/victim as mob in world, reason as null|text)
		set category = "Admin"
		set desc = "Ban the player from the server"

		if (victim == usr)
			usr << "<b>Don't even try banning yourself."
			return

		if (istext(victim))
			var/mob/M

			for (M in world)
				if (lowertext(M.name) == victim)
					victim = M
					break

			if (!(ismob(victim) || isobj(victim)))
				return

		if (victim.client)
			victim << "<b><font color=red>You have been banned by [usr]"
			if (reason)
				victim << "<font color=red>Reason: [reason]"
			usr << "Banned [victim] from the server."
			banned_keys.Add(victim.key)
			del(victim)
		else
			usr << "<b>[victim] is not a player."

	Unban(key as text)
		set category = "Admin"
		set desc = "Unban the player from the server"

		banned_keys.Remove(key)

		usr << "<b>Unbanned [key] from the server."

	Freeze(mob/living/victim as mob in world)
		set category = "Admin"

		if (istext(victim))
			var/mob/M

			for (M in world)
				if (lowertext(M.name) == victim)
					victim = M
					break

			if (!(ismob(victim) || isobj(victim)))
				return

		if (usr.client.connection == "telnet")
			usr << "<b>Freezed [victim]."

		victim.Freeze()
		victim << "<i>[usr] freezed you"

	Set_Bot_Skin(I as null|icon)
		set category = "Admin"

		if (usr.client.connection == "telnet")
			usr << "<b>This command is unusable on RCON"
			return

		var/mob/living/player/bot/B
		for (B in world)
			if (I)
				B.icon = I
			else
				B.icon = 'player.dmi'


var/list/admin_bot_difficulty = list("Easy"=BOT_EASY, "Medium"=BOT_MEDIUM, "Hard"=BOT_HARD, "Insane"=BOT_INSANE)
var/list/admin_keys = list()
var/list/banned_keys = list()

var/server_motd

/*
client
	control_freak = CONTROL_FREAK_MACROS
*/

client/var
	music_enabled = 0
	is_admin = 0
	adm_nodrop = 0
	icon/skin
	c_kills = 0
	c_deaths = 0

	rcon_loggedin = 0

client/New()
	if (connection == "telnet")
		if (!rcon_enabled) return
		var/mob/consoleadmin/CA = new
		CA.name = "Telnet [address]"
		CA.key = key
		return ..()
	if (banned_keys.Find(key))
		return

	..()
	if (world.host == key || admin_keys.Find(key))
		verbs += typesof(/admin/verb)
		is_admin = 1

	if (server_motd)
		src << server_motd

	load_data()

	world << "<b><font color=green>[src] joined the game"
	if (current_music && music_enabled)
		src << load_resource(current_music, -1)
		src << sound(current_music, 1)

	screen += new/obj/hud/item_hud(null,src)
	screen += new/obj/hud/health_hud(null,src)



client/Del()
	if (connection == "seeker")
		world << "<b><font color=green>[src] left the game"

		save_data()
	else if (connection == "telnet")
		world.log << "\[RCON\] [address] disconnected."

	..()

client/Command(cmd as text)
	if (connection == "telnet")
		var/list/arge = splittext(cmd, " ")
		if (!length(arge)) return

		if (lowertext(arge[1]) == "exit")
			del(src)
			return

		if (rcon_loggedin)
			if (lowertext(arge[1]) == "say")
				var/et = jointext(arge, " ", 2)
				if (!et) return
				world << "<b>RCON:</b> [html_encode(et)]"
			else
				//var/et = splittext(arge, " ", 2)
				if (hascall(src, arge[1]))
					var/list/eargs = arge.Copy()
					eargs.Cut(1,2)
					call(src,arge[1])(arglist(eargs))
				else
					src << "Invaild Command: <b>[arge[1]]</b>"
		else
			if (lowertext(arge[1]) == "login")
				var/et = jointext(arge, " ", 2)
				if (et == rcon_pass)
					src << "Vaild Password, Logged in."
					rcon_loggedin = 1
					world.log << "\[RCON\] [address] logged in with a vaild password"
				else
					src << "Invaild Password."
			else
				src << "You can't use any of the commands without being logged in."

	else ..()

// Remote Admin
var/rcon_pass = "changeme123"
var/rcon_enabled = 0

mob/consoleadmin
	Logout()
		del(src)

	Login()
		client.is_admin = 1
		client.verbs += typesof(/admin/verb)
		src << "=== [server_name] Remote Console ==="
		src << "To login, enter this command \"login \<password\>\""
		src << "To quit, enter this command \"exit\""

		world.log << "\[RCON\] [client.address] connected."
