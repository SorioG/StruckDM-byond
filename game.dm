/*
	====	StruckDM	====

	Multiplayer Deathmatch Game
	Made with BYOND

	This game has bots, gamemodes, maps, and other things added on the code.
*/


world
	fps = 50
	icon_size = 32

	name = "StruckDM"

	view = 8

	mob = /mob/spectator
	turf = /turf/void

client
	perspective = EYE_PERSPECTIVE
	var/teleporting = 0
	var/killcam = 1
	var/sound/deathsound

	verb/credits()
		usr << "=== Credits ==="
		usr << "Music - Eric Taylors Free-Music Pack - Attribution 4.0 International (CC BY 4.0)"

	verb/howtoplay()
		usr << "<b>=== How to play? ==="

		usr << "<b>-- Gameplay --"
		usr << "Arrow Keys - Move the player (you know the drill)"
		usr << "Space - Primary Attack"
		usr << "P - Secondary Attack"
		usr << "1-9 - Switch to another item (Numpads will also work)"
		usr << "R - Keep Sprinting until the key is unpressed"

		usr << "<b>-- Emotes --"
		usr << "Ctrl+1 - Wave your hand"
		usr << "Ctrl+2 - A Little Dance"
		usr << "Ctrl+3 - Think"
		usr << "Ctrl+4 - Laugh out loud"
		usr << "Ctrl+5 - Lift your arm"
		usr << "Ctrl+6 - Show off your diamonds"
		usr << "Ctrl+7 - Show a arrow (which points to where your direction is)"

	verb/Toggle_Music()
		set category = "Settings"

		music_enabled = !music_enabled

		if (!music_enabled)
			src << sound(null)
		else
			src << load_resource(current_music, -1)
			src << sound(current_music, 1)

	verb/Toggle_Killcam()
		set category = "Settings"

		killcam = !killcam

		if (!killcam)
			src << "<b>Killcam is disabled - You will no longer see who killed you"
		else
			src << "<b>Killcam is enabled - You can now see who killed you"

	verb/Server_Info()
		src << "<b>Server Info"
		src << "This server is using StruckDM version [STRUCKDM_VERSION]"
		if (world.system_type == MS_WINDOWS)
			src << "This server is running on Windows"
		else if (world.system_type == UNIX)
			src << "This server is running on Linux"

	verb/Set_Skin(I as null|icon)
		set category = "Skin"

		skin = I

		if (skin)
			src << "Your skin is now [I]."
		else
			src << "Your skin is now default."

		if (istype(mob, /mob/living/player))
			if (skin)
				mob.icon = skin
			else
				mob.icon = 'player.dmi'

	proc/save_data()
		var/save_path = "playerdata/[ckey]"

		var/savefile/F = new(save_path)
		F["version"] << STRUCKDM_VERSION
		F["skin"] << skin
		F["music_enabled"] << music_enabled
		F["deaths"] << c_deaths
		F["kills"] << c_kills
		F["killcam"] << killcam

	proc/load_data()
		var/save_path = "playerdata/[ckey]"

		if (!length(file(save_path))) return

		var/savefile/F = new(save_path)
		var/version
		F["version"] >> version
		if (version != STRUCKDM_VERSION)
			src << "<b>Your Player Data was outdated for this server."
			src << "This might be possible that the game was updated, ignoring it for now to prevent player data corruption."
			src << "This message wont show up again unless the game is updated."
			return
		F["skin"] >> skin
		F["music_enabled"] >> music_enabled
		F["deaths"] >> c_deaths
		F["kills"] >> c_kills
		F["killcam"] >> killcam

	verb/Player_Status()
		src << "== Player Status =="
		src << "You killed [c_kills] player\s on this server"
		src << "You died [c_deaths] time\s on this server"

	verb/Skin_Tutorial()
		set category = "Skin"

		src << browse('skintutorial.html')

	verb/Test_Skin()
		set category = "Skin"

		if (isnull(skin))
			usr << "Please execute this command on custom skins. (You don't have the skin set)"
			return

		var/list/skin_states = icon_states(skin)
		var/list/player_states = icon_states('player.dmi')


		var/pass = 0
		var/fail = 0
		var/list/expecting_states = list()

		src << "<b>Looking for unnecessary states..."
		for (var/M in skin_states)
			if (M == "") continue
			if (unused_states.Find(M)) continue
			if (player_states.Find(M))
				pass += 1
			else
				fail += 1
				expecting_states.Add(M)

		if (length(expecting_states))
			src << "StruckDM Does not use these states: [expecting_states.Join(", ")]"
			src << "Please remove these states to save some space."
		else
			src << "This skin does not have any unnecessary states."

		src << "[pass] Passed, [fail] Failed"

		src << ""
		src << "<b>Looking for existing states..."
		pass = 0
		fail = 0
		var/list/used_states = list()

		expecting_states = list()
		for (var/M in player_states)
			if (M == "") continue
			if (unused_states.Find(M)) continue
			if (skin_states.Find(M))
				pass += 1
				used_states.Add(M)
			else
				fail += 1
				expecting_states.Add(M)

		if (length(expecting_states))
			src << "Your skin does not have states that StruckDM requires: [expecting_states.Join(", ")]"
			src << "It is possible that your skin will start confusing other players, and also things that use these states."
			if (length(used_states))
				src << "<b>The only ones used are: [used_states.Join(", ")]"
				src << "Please add these states StruckDM requires, so that would be a perfect skin."
		else
			src << "This skin is using all of states StruckDM requires."

		src << "[pass] Passed, [fail] Failed"

client/Topic(href)
	if (href == "skindownload")
		usr << ftp('player.dmi')
	else ..()

var/hd_limit = 1

var/list/unused_states = list("zombie","zombie_punch","zombie_death","zombie_hurt","zombie_blind","floating","tf1","tf2","tf1_swimming",
								"tf2_stand","tf2_punch","holding","drink","swordgod_pick")

mob
	step_size = 8
	verb/say(t as text)
		if (!t) return // No empty messages are allowed here

		// Some of easter eggs idk
		if (findtext(t, "fart"))
			world << 'meme/fartme.wav'
		else
			world << 'beep-02.wav'
		if (istype(src, /mob/spectator))
			world << "<b>(SPECTATOR) [src]:</b> [html_encode(t)]"
		else
			world << "<b>([uppertext(get_team_name(team))]) [src]:</b> [html_encode(t)]"

obj
	var/cleanup = 0
	step_size = 8

	hackgood
		icon = 'turfs.dmi'
		icon_state = "pc"
		name = "PC"

		density = 1

		Click()
			if (!istype(usr, /mob/living/player)) return
			usr.play_sound('Hammer Hit.wav')
			var/code = input("Enter the cheat code")

			if (code == "HackGood")
				usr:health = 90000
				usr:damage_extra = 50
			else if (code == "Teleport")
				usr.client.view = 200
				usr.client.teleporting = 1
			else if (code == "HD")
				if (!hd_limit) return usr:Damage(usr:health)
				hd_limit = 0
				var/mob/living/player/P
				for (P in get_players())
					if (P == usr) continue
					P.Damage(P.health, usr)
			else if (code == "Dima")
				usr:health += 200
				usr:damage_extra += 20
				usr << "You got 200 health and 20 extra damage"
				//usr:emote(6)
			else
				usr.loc = rand_loc(usr.z)

var/allow_step_sounds = 0

turf
	icon = 'turfs.dmi'
	var/list/step_sounds = list()

	proc/Cleanup()
		set waitfor = 0
		sleep(20)
		if (color)
			animate(src, color=null, time=10)


	Click()
		..()
		if (usr.client.teleporting)
			usr.client.view = world.view
			usr.loc = src
			usr.play_sound('8bit_gunloop_explosion.wav')
			usr.client.teleporting = 0

	Exited(mob/living/player/P, atom/newloc)
		if (!istype(P)) return ..()
		if (length(step_sounds) && prob(20))
			if (allow_step_sounds)
				P.play_sound(pick(step_sounds))
		..()

	grass
		icon_state = "grass"
		step_sounds = list('Fantozzi-SandL1.ogg','Fantozzi-SandL2.ogg','Fantozzi-SandL3.ogg','Fantozzi-SandR1.ogg','Fantozzi-SandR2.ogg','Fantozzi-SandR3.ogg')
		bottom
			icon_state = "grassbottom"

		New()
			..()
			if (istype(src, /turf/grass/bottom)) return

			if (icon_state == "grass")
				if (prob(5)) icon_state = "grass2"
			var/turf/bottom = locate(x, y-1, z)

			if (bottom.type == /turf || bottom.type == /turf/void || bottom.type == /turf/water)
				new/turf/grass/bottom(locate(x, y-1, z))

	stone
		icon_state = "stone"
		step_sounds = list('Fantozzi-StoneL1.ogg','Fantozzi-StoneL2.ogg','Fantozzi-StoneL3.ogg','Fantozzi-StoneR1.ogg','Fantozzi-StoneR2.ogg','Fantozzi-StoneR3.ogg')
	void
		density = 1
	water
		icon_state = "water"
		density = 1

		waterfall
			icon_state = "waterfall"

			New()
				..()
				WLoop()

			proc/WLoop()
				spawn while(1)
					play_sound('water/loop_water_01.ogg')
					sleep(20)


		Enter(mob/living/player/P)
			if (!istype(P)) return ..()

			return 1

		Entered(mob/living/player/P, atom/oldloc)
			if (!istype(P)) return
			//if (istype(P.loc, /turf/water)) return

			if (prob(20) || !P.is_swimming)
				var/list/swimsound = list('water/splash_01.ogg','water/splash_02.ogg','water/splash_03.ogg','water/splash_04.ogg',
											'water/splash_05.ogg','water/splash_06.ogg','water/splash_07.ogg','water/splash_08.ogg',
											'water/splash_09.ogg','water/splash_10.ogg','water/splash_11.ogg','water/splash_12.ogg')
				P.play_sound(pick(swimsound))

			P.sprint(0)
			P.is_swimming = 1
			P.icon_state = "swimming"


		Exited(mob/living/player/P, atom/newloc)
			if (!istype(P)) return
			if (istype(newloc, /turf/water)) return

			P.is_swimming = 0
			P.icon_state = ""

		lava
			icon_state = "lava"

			Entered(mob/living/player/P, atom/oldloc)
				..()
				if (istype(P))
					P.drowning_time = 0

/*
sound/var
	atom/emitter
*/

atom/proc
	play_sound(s)
		var/mob/M
		for (M in hearers(20, src))
			if (!M.client) continue // to prevent lag

			var/sound/S = sound(s)
			//var/dist = get_dist(M, src)

			if (M:is_swimming)
				S.environment = 22
			else if (M:is_blind || M:is_frozen)
				S.environment = 24
			else if (istype(M.loc, /turf/stone))
				S.environment = 5
			else if (istype(M.loc, /turf/grass))
				S.environment = 15
			else
				S.environment = 0
			S.y = M.pixel_y - pixel_y
			S.x = M.x - x
			S.z = M.y - y
			S.priority = 5
			//S.emitter = src

			/*
			if (M in hearers(3, src))
				S.volume = 100
			else if (M in hearers(5, src))
				S.volume = 50
			else if (M in hearers(9, src))
				S.volume = 30
			else
				S.volume = 0
			*/

			M << S


var/const
	TEAM_NONE = 0
	TEAM_RED = 1
	TEAM_BLUE = 2
	TEAM_YELLOW = 3
	TEAM_GREEN = 4