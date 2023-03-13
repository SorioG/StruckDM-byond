
world
	fps = 50
	icon_size = 32

	view = 6
	maxx = 900
	maxy = 900
	New()
		..()
		player = new(locate(60,60,1))

	turf = /turf/grass
	mob = /mob/viewer


var/mob/player/player
var/list/player_states = icon_states('player.dmi')

var/list/unused_states = list("zombie","zombie_punch","zombie_death","zombie_hurt","zombie_blind","floating","tf1","tf2","tf1_swimming",
								"tf2_stand","tf2_punch","holding","drink","swordgod_pick")

mob
	viewer
		density = 0
		verb/load_skin(I as icon)
			player.icon = I

		verb/load_default_skin()
			player.icon = 'player.dmi'

		verb/start_walking()
			walk_rand(player)
			player.is_walking = 1

		verb/stop_walking()
			walk(player,0)
			player.is_walking = 0

		verb/teleport_start()
			player.Move(locate(60,60,1))

		verb/set_state(S as null|anything in player_states)
			if (!S)
				player.icon_state = ""
			else
				player.icon_state = S

		verb/show_output()
			winshow(usr, "window1")
			usr << output(null, "window1.output1")

		verb/random_color()
			player.color = rgb(rand(0,255),rand(0,255),rand(0,255))

		verb/no_color()
			player.color = null

		proc/TeleportLoop()
			spawn while(1)
				loc = player.loc
				sleep(1)

		verb/test_skin()
			show_output()
			var/list/skin_states = icon_states(player.icon)

			var/pass = 0
			var/fail = 0
			var/list/expecting_states = list()

			usr << "Looking for unnecessary states..."
			for (var/M in skin_states)
				if (M == "") continue
				if (unused_states.Find(M)) continue
				if (player_states.Find(M))
					pass += 1
				else
					fail += 1
					expecting_states.Add(M)

			if (length(expecting_states))
				usr << "StruckDM Does not use these states: [expecting_states.Join(", ")]"
				usr << "Please remove these states to save some space."
			else
				usr << "This skin does not have any unnecessary states."

			usr << "[pass] Passed, [fail] Failed"

			usr << ""
			usr << "Looking for existing states..."
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
				usr << "Your skin does not have states that StruckDM requires: [expecting_states.Join(", ")]"
				usr << "It is possible that your skin will start confusing other players, and also things that use these states."
				if (length(used_states))
					usr << "<b>The only ones used are: [used_states.Join(", ")]"
				usr << "Please add these states StruckDM requires, so that would be a perfect skin."
			else
				usr << "This skin is using all of states StruckDM requires."

			usr << "[pass] Passed, [fail] Failed"

		New()
			..()
			verbs += typesof(/pactions/verb)
			TeleportLoop()

		Login()
			..()
			client.eye = player
			client.perspective = EYE_PERSPECTIVE

atom/proc
	play_sound(s)
		var/sound/S = sound(s)

		var/mob/M
		for (M in hearers(10, src))
			if (M in hearers(3, src))
				S.volume = 100
			else if (M in hearers(5, src))
				S.volume = 50
			else if (M in hearers(9, src))
				S.volume = 30
			else
				S.volume = 0

			M << S

mob
	step_size = 8
	var/is_swimming = 0
	var/is_frozen = 0
	player
		icon = 'player.dmi'
		var/is_walking = 0

		proc/WalkLoop()
			spawn while(1)
				if (is_walking)
					walk_rand(src)
				sleep(30)

		New()
			..()
			WalkLoop()

	proc/Freeze()
		if (is_frozen) return
		//if (health < 1) return
		flick("frozen_start", src)
		icon_state = "frozen"
		//can_move = 0
		//frozen_time = 10
		is_frozen = 1

	proc/Unfreeze()
		if (!is_frozen) return
		//if (health < 1) return
		flick("frozen_broken", src)
		icon_state = ""
		//can_move = 1
		is_frozen = 0
		play_sound('q009/explosion.ogg')

	proc/HitEffect()
		var/oldcolor = color
		color = "white"
		animate(src, color=oldcolor, time=5)

	proc/Death()
		HitEffect()

		if (player.is_swimming)
			flick("swimming_death",src)
			icon_state = "swimming_corpse"
		else
			if (!is_frozen)
				flick("death",src)
				icon_state = "corpse"
			//else if (reason == DEATH_FIRE)
				//player.icon_state = "death_fire"
			else if (is_frozen)
				flick("frozen_death", src)
				icon_state = "frozen_corpse"
			//var/id = rand(10,37)

		play_sound('punches/hit05.mp3.mp3')

	proc/FreezeBreak()
		flick("frozen_break", src)
		//var/id = rand(1,9)
		play_sound('punches/hit05.mp3.mp3')

turf
	icon = 'turfs.dmi'
	grass
		icon_state = "grass"

		New()
			..()
			if (prob(5)) icon_state = "grass2"
