/*
	Gamemodes used for handling any of their logics.

*/

// v DON'T TOUCH
var/sound/current_music
var/current_map = 1
var/gamemode/GM
var/gamemode/forced_gamemode
var/gm_endless = 0
var/list/gamemodes = list()
var/gm_force_ending = 0
// ^ DON'T TOUCH

gamemode
	var/name = "" // Name of the gamemode, This is required to show up on server status and a gamemode info.
	var/list/maps = list(1,2,4,7) // The list of z locations, leave the list empty for all maps.
	var/list/music_list = list('background_beat.mp3') // The list of music, This must be a vaild sound file that BYOND supports, leave it empty for no music.
	var/can_spawn_items = 1 // Allows the game to spawn items
	var/can_drop_items = 1 // Allows dead players to drop items

	// Called when the player joins (also called on each player when starting)
	proc/PlayerJoin(mob/living/player/P)

	// Called when the player (victim) dies or gets killed by other player/NPC (killer)
	// Reason can be a cause of the death, the vaild values are here below:
	// DEATH_GENERAL (1) - A Normal Death
	// DEATH_FIRE (2) - Death by fire
	// DEATH_FROZEN (3) - Died while frozen
	proc/PlayerDeath(mob/living/player/victim, mob/living/player/killer, reason)

	// Called when the player respawns or on each player for starting the gamemode
	proc/PlayerSpawn(mob/living/player/P)

	// Called on every tick (this won't be called if nobody is playing on the server)
	proc/GameTick()

	// Called when the gamemode has started
	proc/GamemodeStart()

	// Called when the gamemode has ended
	proc/GamemodeEnd()

	// Called before the start of gamemode
	proc/BeforeStart()

	// Called before the end of gamemode
	proc/BeforeEnd()

	// Called on initialization (when the server has started)
	proc/Init()

	// Called on every tick for bots, Return 0 to use the Default AI, Return 1 to do nothing.
	// This is useful if you want the bots to respect the gamemode.
	proc/AITick(mob/living/player/bot/B)
		return 0


	// Called when the game needs to check if the player is allowed to kill the victim
	// Bots also call this for some reason.
	// Return 1 to allow, Return 0 to disallow
	proc/CanKill(mob/living/player/killer, mob/living/player/victim)
		return 1

	// Called when the player tries to attack.
	// 1 - Make the player attack
	// 0 - Do nothing
	proc/CanAttack(mob/living/player/p)
		return 1

	// Same as item's KillMessage proc, but for gamemodes (see items.dm)
	proc/KillMessage(mob/living/player/player, mob/living/player/victim)
		// Any Text - Use the custom kill message, 0 - Don't use custom kill message
		return 0

	// Called when someone has ruined the killing spree.
	// player - The player who started the killing spree
	// killer - The player who ruined the killing spree (null if player has died without the killer)
	proc/KillComboRuined(mob/living/player/player, mob/living/player/killer)
		/*
		Return Values:
		2 - Don't show the message and don't play clapping sound
		1 - Don't show the message and play clapping sound
		0 - Show the message and play clapping sound
		*/
		return 0

	// Called when the player has started the killing spree.
	// (Usually happens when the player has more 10 kills without dying)
	proc/KillComboStarted(mob/living/player/player)

	// Called every time player has reached the combo count
	proc/KillComboChange(mob/living/player/player, combo_count)
		/*
		Return Values:
		1 - Don't show the message
		0 - Show the message
		*/
		return 0

	// Called when the player needs to respawn
	proc/CanRespawn(mob/living/player/player)
		/*
		Return Values:
		-1 - Don't respawn (The player wont start spectating)
		0 - Don't respawn (After that, the player will start spectating random players)
		1 - Respawn
		*/
		return 1

	// Called when the player takes damage
	// killer - The player who did this damage
	// victim - The player who took the damage
	proc/PlayerHit(mob/living/player/killer, mob/living/player/victim)



// Gamemode Manager

var/bots_to_spawn = 0
var/gm_state = GM_STARTING
var/game_time = 100
var/const
	GM_STARTING = 10
	GM_GAMEPLAY = 11
	GM_ENDING = 22

proc/handle_svar(list/cargs)
	var/name = cargs[1]
	if (findtext(name,"#",1,2)) return

	if (length(cargs) > 1)
		var/value = cargs[2]

		if (name == "num_bots")
			var/nval = text2num(value)
			if (nval)
				bots_to_spawn = nval
				world.log << "Adding [nval] bot\s to the server"

		else if (name == "gm_endless")
			var/nval = text2num(value)
			if (nval == 1)
				gm_endless = 1
				world.log << "Making the game endless"

		else if (name == "bot_do_emotes")
			var/nval = text2num(value)
			if (nval == 1)
				bot_do_emotes = 1

		else if (name == "bot_difficulty")
			var/nval = text2num(value)
			if (nval == 0)
				bot_difficulty = BOT_EASY
			if (nval == 1)
				bot_difficulty = BOT_MEDIUM
			if (nval == 2)
				bot_difficulty = BOT_HARD
			if (nval == 3)
				bot_difficulty = BOT_INSANE

		else if (name == "gm_force")
			if (value == "off") return

			var/nval = jointext(cargs, " ", 2)

			var/gamemode/GA

			for (GA in gamemodes)
				if (lowertext(GA.name) == lowertext(nval))
					forced_gamemode = GA
					world.log << "Forcing the gamemode \"[GA.name]\" to be used on the server"
					break

		else if (name == "admin_key")
			admin_keys.Add(value)
			world.log << "Adding \"[value]\" as a admin"

		else if (name == "server_motd")
			server_motd = jointext(cargs, " ", 2)

		else if (name == "motd_file")
			if (!length(file(value)))
				world.log << "MOTD File \"[value]\" does not exist."
			else
				world.log << "Loading File \"[value]\" to be used as MOTD"
				server_motd = file2text(value)

		else if (name == "server_name")
			server_name = jointext(cargs, " ", 2)

		else if (name == "killmessages")
			var/nval = text2num(value)
			if (nval == 0)
				killmessage_enabled = 0
				world.log << "Disabling Kill Messsages..."

		else if (name == "rcon_enabled")
			var/nval = text2num(value)
			if (nval == 1)
				rcon_enabled = 1
				world.log << "RCON is enabled, and is now allowing telnet connections."

		else if (name == "rcon_password")
			rcon_pass = jointext(cargs, " ", 2)

		else
			world.log << "Invaild Setting \"[name]\", edit serverconfig.txt to remove this warning"

var/killmessage_enabled = 1

world/New()
	world.log << "Starting StruckDM Server version [STRUCKDM_VERSION]"

	var/typ
	for (typ in typesof(/gamemode))
		if (typ == /gamemode) continue // We don't need the useless one.
		var/gamemode/g = new typ()
		world.log << "Initializing Gamemode \"[g.name]\"..."
		g.Init()
		gamemodes.Add(g)

	var/cfile = "serverconfig.txt"
	if (!length(file(cfile)))
		fcopy('serverconfig.default.txt', cfile)
	var/list/vcmds = splittext(file2text(cfile),regex(@"(\r\n|\r|\n)"))

	for (var/vcmd in vcmds)
		var/list/cargs = splittext(vcmd," ")

		if (length(cargs))
			handle_svar(cargs)


	GameModeLoop()
	..()

proc/GameModeLoop()
	spawn while(1)
		// Check if the players are on the game, if not, pause the timer.
		var/mob/living/player/P
		var/is_playing = 0

		for (P in get_players())
			is_playing = 1
			break

		if (gm_state == GM_STARTING)
			if (forced_gamemode)
				GM = forced_gamemode
			else
				GM = pick(gamemodes)
			hd_limit = 1
			var/obj/item/I
			for (I in world)
				del(I)

			var/obj/explode/EX
			for (EX in world)
				del(EX)

			var/obj/fire/FIR
			for (FIR in world)
				del(FIR)

			var/obj/O
			for (O in world)
				if (O.cleanup)
					del(O)



			GM.BeforeStart()
			if (length(GM.music_list))
				current_music = pick(GM.music_list)
			else
				current_music = null

			if (length(GM.maps))
				current_map = pick(GM.maps)
			else
				current_map = rand(1,world.maxz)

			for (P in get_players())
				P.step_x = 0
				P.step_y = 0
				P.density = 1
				P.loc = rand_loc(current_map)
				P.team = TEAM_NONE
				P.deaths = 0
				P.kills = 0
				P.is_swimming = 0
				P.dead_spectating = 0
				P.icon_state = P.normal_state
				P.health = P.max_health
				P.sight = 0
				P.color = rgb(rand(0,255),rand(0,255),rand(0,255))
				P.is_frozen = 0
				P.Blindfold(0)
				if (P.client)
					P.client.eye = P
					P.client.color = null
				if (P.health < 1 || P.is_dead)
					P.Respawn()
					GM.PlayerSpawn(P)
				else
					GM.PlayerSpawn(P)


			for (P in get_players())
				GM.PlayerJoin(P)

			var/mob/spectator/S
			for (S in world)
				S.loc = rand_loc(current_map)

			game_time = 100
			gm_state = GM_GAMEPLAY
			world << sound(null)
			if (current_music)
				var/client/C
				for (C)
					if (C.music_enabled)
						C << load_resource(current_music, -1)
						C << sound(current_music, 1)


			if (bots_to_spawn)
				for (var/i = 0, i < bots_to_spawn, i++)
					new/mob/living/player/bot(rand_loc(current_map))
				bots_to_spawn = 0

			GM.GamemodeStart()
		else if (gm_state == GM_GAMEPLAY)
			if (is_playing)
				if (!gm_endless) game_time--

				if (game_time < 10 && !gm_force_ending)
					world << 'sounds/hit/Hit.wav'

				gm_force_ending = 0

				if (rand(0,1) && GM.can_spawn_items)
					var/typ = pick(typesof(/obj/item))

					if (typ != /obj/item)
						new typ(rand_loc(current_map, use_playerspawn=0))

			if (game_time < 1)
				GM.BeforeEnd()
				gm_state = GM_STARTING
				GM.GamemodeEnd()
			else if (is_playing)
				spawn GM.GameTick()
				sleep(10)

		sleep(1)

proc/get_players()
	var/mob/living/player/P
	var/list/plrs = list()
	for (P in world)
		plrs.Add(P)

	return plrs

proc/get_team_players(team=TEAM_NONE)
	var/mob/living/player/P
	var/list/plrs = list()
	for (P in world)
		if (P.team != team) continue
		plrs.Add(P)

	return plrs

proc/get_alive_players()
	var/mob/living/player/P
	var/list/plrs = list()
	for (P in world)
		if (P.health < 1) continue
		plrs.Add(P)

	return plrs

proc/get_team_name(team=TEAM_NONE)
	if (team == TEAM_RED)
		return "red"
	if (team == TEAM_BLUE)
		return "blue"
	if (team == TEAM_YELLOW)
		return "yellow"
	if (team == TEAM_GREEN)
		return "green"
	if (team == TEAM_NONE)
		return "ffa"

	return "unknown"

proc/get_team_index(team=TEAM_NONE)
	if (team == TEAM_RED)
		return 1
	if (team == TEAM_BLUE)
		return 2
	if (team == TEAM_YELLOW)
		return 3
	if (team == TEAM_GREEN)
		return 4
	if (team == TEAM_NONE)
		return 0

	return -1

mob/Stat()
	/*
	This is a waste of time when joining the server or trying to test the game.

	if (statpanel("Players"))
		stat("Players:")
		var/mob/living/player/P
		for (P in get_players())
			stat("[P.name] | Deaths: [P.deaths] | Kills: [P.kills]")

		stat("Spectators:")
		var/mob/spectator/S
		for (S in world)
			if (S.spectating)
				stat("[S.name] (watching [S.spectating.name])")
			else
				stat(S.name)
	*/
	if (!isnull(GM)) // To fix error when starting a single player game
		if (statpanel("Gamemode"))
			stat("Current Gamemode", GM.name)
			if (gm_endless)
				stat("Time Left", "(Endless Mode Active)")
			else
				stat("Time Left", game_time)

// StruckDM Gamemodes
gamemode
	deathmatch
		name = "Deathmatch"
	teamdm
		name = "Team Deathmatch"
		var/list/team_kills = list(0,0,0,0)
		var/list/team_deaths = list(0,0,0,0)
		var/list/allowed_teams = list(TEAM_RED, TEAM_BLUE, TEAM_YELLOW, TEAM_GREEN)

		PlayerJoin(mob/living/player/P)
			// Make the new player join on a random team, and tell they're on this team and show the teammates.
			if (P.team == TEAM_NONE)
				P.team = pick(allowed_teams)
			P.color = get_team_name(P.team)
			P << "<b><font color=[get_team_name(P.team)]>You're on team [get_team_name(P.team)]"
			P << "<b>Your teammates:"
			var/mob/living/player/mates
			for (mates in get_players())
				if (mates.team == P.team && P != mates)
					P << mates

		PlayerDeath(mob/living/player/victim, mob/living/player/killer)
			team_deaths[get_team_index(victim.team)] += 1

			if (killer)
				if (killer == victim) return // This does not count due to a self kill
				team_kills[get_team_index(killer.team)] += 1

		GamemodeStart()
			// Reset deaths and kills to a zero number
			team_kills = list(0,0,0,0)
			team_deaths = list(0,0,0,0)

		GamemodeEnd()
			// After the gamemode ends, we will show the leaderboard to everyone.
			var/ld = "<b>Team Leaderboard</b><br>"
			ld += "<b><font color=red>Team Red | Kills: [team_kills[1]] | Deaths: [team_deaths[1]]</font></b><br>"
			ld += "<b><font color=blue>Team Blue | Kills: [team_kills[2]] | Deaths: [team_deaths[2]]</font></b><br>"
			ld += "<b><font color=yellow>Team Yellow | Kills: [team_kills[3]] | Deaths: [team_deaths[3]]</font></b><br>"
			ld += "<b><font color=green>Team Green | Kills: [team_kills[4]] | Deaths: [team_deaths[4]]</font></b><br>"
			world << browse(ld)

		twoteams
			// Same as Team Deathmatch, but only 2 teams are used.
			name = "Team Deathmatch (2 Teams)"
			allowed_teams = list(TEAM_RED, TEAM_BLUE)

			GamemodeEnd()
				// After the gamemode ends, we will show the leaderboard to everyone.
				var/ld = "<b>Team Leaderboard</b><br>"
				ld += "<b><font color=red>Team Red | Kills: [team_kills[1]] | Deaths: [team_deaths[1]]</font></b><br>"
				ld += "<b><font color=blue>Team Blue | Kills: [team_kills[2]] | Deaths: [team_deaths[2]]</font></b><br>"
				world << browse(ld)


