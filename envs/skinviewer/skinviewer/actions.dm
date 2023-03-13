
pactions/verb
	JumpPass()
		set category = "Actions"
		set desc = "When Jump Pass Item is used"

		player.icon_state = "gojump"
		player.play_sound(pick('jumppad.ogg','jumppad2.wav'))
		sleep(3)
		flick("jump", player)
		player.icon_state = ""

	Hurt()
		set category = "Actions"
		if (player.is_swimming)
			flick("swimming_hurt", player)
		else if (player.is_frozen)
			flick("frozen_hurt", player)
		else
			flick("hurt",player)
		step(player, turn(player.dir, 90), 3)

		player.HitEffect()

	Frozen()
		set category = "Actions"
		player.Freeze()
		sleep(10)
		player.Unfreeze()

	Death()
		set category = "Actions"
		player.Death()
		sleep(60)
		player.icon_state = ""

	FrozenDeath()
		set category = "Actions"
		player.Freeze()
		sleep(10)
		player.Death()
		sleep(60)
		player.is_frozen = 0
		player.icon_state = ""

	Sprint()
		set category = "Actions"
		player.icon_state = "sprint"
		player.step_size = 15
		player.is_walking = 1
		walk_rand(player)
		sleep(20)
		walk(player,0)
		player.is_walking = 0
		player.icon_state = ""
		player.step_size = 8

	FrozenBreak()
		set category = "Actions"
		player.Freeze()
		sleep(5)
		for (var/i=0, i<10, i++)
			player.dir = pick(NORTH,SOUTH,EAST,WEST)
			player.FreezeBreak()
			sleep(3)
		player.Unfreeze()

	Sword()
		set category = "Actions"
		flick("sword_swing", player)
		player.play_sound('8bit_gunloop_explosion.wav')

	Gun()
		set category = "Actions"
		flick("gun_shoot", player)
		//player.play_sound(pick('pistol.ogg','pistol2.ogg','pistol3.ogg'))
		player.play_sound('Gun+Silencer.wav')

	GunReload()
		set category = "Actions"
		player.play_sound('Gun+Cock.wav')
		flick("gun_reload", player)

	MegaGunReload()
		set category = "Actions"
		player.play_sound('Gun+Cock.wav')
		flick("gun_reload_mega", player)

	MegaGun()
		set category = "Actions"
		flick("gun_shoot_mega", player)
		player.play_sound(pick('minigun.ogg','minigun2.ogg','minigun3.ogg'))

	CTF_Flag()
		set category = "Actions"
		var/image/img = image('gamemode_icons.dmi', icon_state="flag")
		img.color = pick("red","blue","yellow","green")
		img.appearance_flags = RESET_COLOR
		player.underlays += img
		sleep(20)
		player.underlays -= img

	Flamethrower()
		set category = "Actions"
		player.icon_state = "flamethrower"
		player.play_sound('flamestrike.wav')

		for (var/i=0, i<8, i++)
			var/gloc = locate(player.x + rand(-3,3), player.y + rand(-3,3), player.z)
			if (player in view(0, gloc))
				// Don't spawn fire near the player
			else
				new/obj/fire(gloc)

		spawn(3)
			if (player.icon_state == "flamethrower")
				player.icon_state = ""

	FlamethrowerHit()
		set category = "Actions"
		Flamethrower()
		player.icon_state = ""
		flick("flamethrower2", player)

	Soda()
		set category = "Actions"
		flick("soda_drink", player)
		player.play_sound('fse/sip.mp3')

	Rayfreeze()
		set category = "Actions"
		player.play_sound(pick('fse/laser1.mp3','fse/laser2.mp3','fse/laser3.mp3','fse/laser4.mp3','fse/laser5.mp3','fse/laser6.mp3','fse/laser7.mp3','fse/laser8.mp3','fse/laser9.mp3'))
		flick("rayfreeze", player)

	Emote(e as num)
		set category = "Actions"
		if (e > 7 || e < 1)
			alert("That emote does not exist.")
			return
		flick("emote[e]", player)

		var/msg
		if (e == 1)
			msg = "[usr] waves"
		else if (e == 2)
			msg = "[usr] does a little dance"
		else if (e == 3)
			msg = "[usr] thinks about something"
		else if (e == 4)
			msg = "[usr] laughs out loud"
		else if (e == 5)
			msg = "[usr] lifts \his arm"
		else if (e == 6)
			msg = "[usr] shows off \his diamonds"
		else if (e == 7)
			msg = "[usr] points to \his direction"

		if (msg)
			alert(msg)