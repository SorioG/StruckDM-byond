obj/item
	proc/LeftAttack(mob/living/player) // Primary Attack (Called when the player presses space or a bot wants to attack)
	proc/RightAttack(mob/living/player) // Secondary Attack (Called when the player presses P or a bot wants to use secondary attack)
	proc/PlayerPick(mob/living/player)
		// 1 - Move to player's inventory, 0 - Do not pick
		return 1
	proc/BotCanAttack(mob/living/player/bot)
		/*
		Return Values:
		3 - Don't let the bot attack by itself
		2 - Force the bot to do a secondary attack (this calls RightAttack)
		1 - Force the bot to use this item
		0 - Let the bot attack by itself

		Note: May differ from Bot's AI
		*/
		return 0
	proc/BotCanHold(mob/living/player/bot)
		/*
		Return Values:
		2 - Force the bot to hold this item
		1 - Let the bot hold this item by itself
		0 - Don't let the bot hold this item

		Note: May differ from Bot's AI
		*/

		return 1
	proc/KillMessage(mob/living/player, mob/living/victim)
		// Changes the kill message, this could be useful for things that needs the correct message for the killer, victim is the same player if it's a suicide.
		// Default: [player] killed [victim]
		return "[player] killed [victim]"

	New()
		..()
		DespawnLoop()
		PickUpLoop()

	var/despawn_time = 20
	proc/DespawnLoop()
		spawn while(1)
			if (!ismob(loc))
				despawn_time--
				if (despawn_time < 1)
					del(src)
			else
				despawn_time = initial(despawn_time)
			sleep(10)
	proc/PickUpLoop()
		spawn while(1)
			if (!ismob(loc))
				var/mob/living/player/P
				for (P in view(0, src))
					if (PlayerPick(P))
						if (Move(P))
							P.holding = src
					break
			sleep(1)


obj/item
	icon = 'weapons.dmi'
	sword
		name = "Sword"
		icon_state = "sword"

		LeftAttack(mob/living/player)
			flick("sword_swing", player)
			player.play_sound('8bit_gunloop_explosion.wav')
			var/mob/living/E
			for (E in oview(3, player))
				E.Damage(rand(30, 34), player, DEATH_GENERAL, src)

		KillMessage(mob/living/player, mob/living/victim)
			return "[player] flinged [victim]'s head"
	gun
		var/bullet = 20
		var/max_bullet = 1
		var/bullet_reload = 20
		var/is_reloading = 0
		name = "Gun"
		icon_state = "gun"
		var/shoot_state = "gun_shoot"
		var/reload_state = "gun_reload"

		LeftAttack(mob/living/player)
			if (bullet < 1)
				/*
				if (max_bullet < 1)
					player.holding = null
				*/
				Reload(player)
				return
			bullet--
			flick(shoot_state, player)
			//player.play_sound(pick('pistol.ogg','pistol2.ogg','pistol3.ogg'))
			player.play_sound('Gun+Silencer.wav')
			var/mob/living/E
			for (E in oview(3, player))
				E.Damage(rand(30, 40), player, DEATH_GENERAL, src)

		proc/Reload(mob/living/player)
			if (max_bullet < 1)
				if (player.client)
					if (!player.client.adm_nodrop)
						//player.play_sound('outofammo.ogg')
						player.play_sound('Gun+Empty.wav')
						player:punch()
						return
				else
					//player.play_sound('outofammo.ogg')
					player.play_sound('Gun+Empty.wav')
					player:punch()
					return
			if (is_reloading) return
			is_reloading = 1
			player.play_sound('Gun+Cock.wav')
			flick(reload_state, player)

			sleep(10)
			bullet = bullet_reload
			max_bullet--
			is_reloading = 0

		KillMessage(mob/living/player, mob/living/victim)
			return "[player]'s gun bullet goes through [victim]'s body"

		mega
			icon_state = "gunmega"
			bullet_reload = 40
			bullet = 40
			max_bullet = 30
			reload_state = "gun_reload_mega"
			shoot_state = "gun_shoot_mega"

			LeftAttack(mob/living/player)
				if (bullet < 1)
					Reload(player)
					return
				bullet--
				flick(shoot_state, player)
				player.play_sound(pick('minigun.ogg','minigun2.ogg','minigun3.ogg'))
				var/mob/living/E
				for (E in oview(4, player))
					E.Damage(rand(50, 70), player, DEATH_GENERAL, src)

	bullet
		icon_state = "bullet"

		PlayerPick(mob/living/player)
			if (istype(player.holding, /obj/item/gun))
				if (istype(player.holding, /obj/item/gun/mega)) return
				player.holding:max_bullet += 1
				del(src)
				return 0
			return 0

		mega
			icon_state = "bullet_mega"

			PlayerPick(mob/living/player)
				if (istype(player.holding, /obj/item/gun/mega))
					player.holding:max_bullet += 1
					del(src)
					return 0
				return 0

	jumppass
		// weird
		icon_state = "jumppass"
		name = "Jump Pass"
		desc = "Use it and you're going to another location!"
		var/is_jumping = 0

		LeftAttack(mob/living/player)
			if (is_jumping) return
			if (player.client)
				if (!player.client.adm_nodrop)
					player.holding = null
			else
				player.holding = null
			is_jumping = 1
			player.icon_state = "gojump"
			player.can_move = 0
			player.play_sound(pick('jumppad.ogg','jumppad2.wav'))
			sleep(3)
			flick("jump", player)
			player.icon_state = ""
			player.loc = rand_loc(player.z)
			sleep(2)
			is_jumping = 0
			player.can_move = 1
			if (player.client)
				if (!player.client.adm_nodrop)
					del(src)
			else
				del(src)

	blindbomb
		icon_state = "blindgrenade"
		name = "Blind Bomb"
		var/is_thrown = 0

		PlayerPick(mob/living/player)
			if (is_thrown) return 0
			return ..()

		LeftAttack(mob/living/player)
			player.holding = null
			player.play_sound(pick('glauncher.ogg','glauncher2.ogg','glauncher3.ogg'))
			is_thrown = 1

			Move(player.loc)

			spawn(20)
				play_sound(pick('grenade.ogg','grenade2.ogg','grenade3.ogg'))

				var/mob/living/E
				for (E in range(3, src))
					//if (E == player) continue // Except the owner because they used this item
					E.Damage(30, player, DEATH_GENERAL, src)
					if (E.health > 0) E.Blindfold(1)

				var/turf/T
				for (T in range(3, src))
					if (!T.density)
						T.color = "black"
						T.Cleanup()

				src.loc = null
				spawn(30)
					del(src)

		KillMessage(mob/living/player, mob/living/victim)
			if (victim == player)
				return "[player] had too much about the blind bomb"
			else
				return "[victim] is too tired of vision by [player]"

	fbomb
		icon_state = "fgrenade"
		name = "Freeze Bomb"
		var/is_thrown = 0

		PlayerPick(mob/living/player)
			if (is_thrown) return 0
			return ..()

		LeftAttack(mob/living/player)
			player.holding = null
			player.play_sound(pick('glauncher.ogg','glauncher2.ogg','glauncher3.ogg'))
			is_thrown = 1

			Move(player.loc)

			spawn(20)
				play_sound(pick('minigun.ogg','minigun2.ogg','minigun3.ogg'))

				var/mob/living/E
				for (E in range(3, src))
					//if (E == player) continue // Except the owner because they used this item
					E.Damage(30, player, DEATH_GENERAL, src)
					if (E.health > 0) E.Freeze()

				var/turf/T
				for (T in range(3, src))
					if (!T.density)
						T.color = "cyan"
						T.Cleanup()

				src.loc = null
				spawn(30)
					del(src)

		KillMessage(mob/living/player, mob/living/victim)
			if (victim == player)
				return "[player] had too much about the freeze bomb"
			else
				return "[victim] is colded out by [player]"


	grenade
		icon_state = "grenade"
		name = "Grenade"
		var/is_thrown = 0

		PlayerPick(mob/living/player)
			if (is_thrown) return 0
			return ..()

		LeftAttack(mob/living/player)
			player.holding = null
			player.play_sound(pick('glauncher.ogg','glauncher2.ogg','glauncher3.ogg'))
			is_thrown = 1

			Move(player.loc)

			spawn(20)
				/*
				new/obj/explode(src.loc)

				var/mob/living/E
				for (E in range(8, src))
					//if (E == player) continue // Except the owner because they used this item
					E.Damage(rand(30,50), player, DEATH_GENERAL, src)
				*/

				explode(src.loc, 30, player, src, 1)

				var/obj/O

				for (O in orange(8, src))
					if (istype(O, /obj/antirocket) || istype(O, /obj/antiheli) || istype(O, /obj/mine) || istype(O, /obj/item/grenade))
						explode(O.loc, 30, player, src, 1)
						del(O)


				src.loc = null
				spawn(30)
					del(src)

		KillMessage(mob/living/player, mob/living/victim)
			if (victim == player)
				return "[player] had too much about the grenade"
			else
				return "[victim] got exploded by [player]'s grenade"

proc/explode(loc, damage, mob/killer, obj/item/hold, take_fire)
	var/obj/explode/e = new(loc)
	if (damage)
		var/mob/living/L
		for (L in range(e, 4))
			L.Damage(damage, killer, , hold)

	if (take_fire && isturf(loc))
		var/x = loc:x
		var/y = loc:y
		var/z = loc:z

		for(var/i=0,i<rand(5,20),i++)
			new/obj/fire(locate(x + rand(-3, 3), y + rand(-3, 3), z))

obj/explode
	icon = 'turfs.dmi'
	icon_state = "explode"
	mouse_opacity = 0
	New()
		..()
		play_sound(pick('Explosion+8.wav','Explosion+3.wav','Torpedo+Explosion.wav'))
		flick("explode",src)
		icon_state = "transparent"
		spawn(20) del(src)

obj/fire
	icon = 'turfs.dmi'
	icon_state = "fire"
	mouse_opacity = 0
	New(loc)
		..()


		var/turf/T = loc
		if (isturf(T) && T.density)
			// ILLEGAL
			del(src)
			return

		SoundLoop()
		DamageLoop()

		spawn(200) del(src)

	proc/SoundLoop()
		spawn while(1)
			sleep(12)
			//play_sound('fse/fire-04-loop.wav')

	proc/DamageLoop()
		spawn while(1)
			var/mob/living/M

			for (M in range(0, src))
				M.Damage(10, ,DEATH_FIRE)
				M.play_sound('fse/flamestrike.wav')

			sleep(5)

obj/spike
	icon = 'turfs.dmi'
	icon_state = "spike"
	New()
		..()
		SpikeLoop()
	proc/SpikeLoop()
		spawn while(1)
			var/mob/living/P
			for (P in view(0, src))
				P.Damage(5)
			sleep(5)

	icespike
		icon_state = "spike_ice"

obj/mapitems
	invisibility = 101
	density = 0
	mouse_opacity = 0

	playerspawn
		icon = 'weapons.dmi'
		icon_state = "playerspawn"

obj/hud
	appearance_flags = NO_CLIENT_COLOR

	item_hud
		var/client/C
		screen_loc = "SOUTH,EAST"

		New(loc, client/C)
			..()
			src.C = C
			Loop()

		proc/Loop()
			spawn while(1)
				if (istype(C.mob, /mob/living/player))
					if (C.mob.killer_spectating && C.mob.killed_by != C.mob)
						if (istype(C.mob.killed_by))
							if (!isnull(C.mob.last_hit_item) && C.killcam)
								icon = C.mob.last_hit_item.icon
								icon_state = C.mob.last_hit_item.icon_state
								name = "[C.mob.last_hit_item.name] (Killer: [C.mob.killed_by.name])"
							else
								icon = null
								name = ""

						else
							icon = null
							name = ""
					else
						if (!isnull(C.mob.holding))
							icon = C.mob.holding.icon
							icon_state = C.mob.holding.icon_state
							name = C.mob.holding.name
						else
							icon = null
							name = ""

				else if (istype(C.mob, /mob/spectator))
					if (!isnull(C.mob:spectating))
						var/mob/living/watching = C.mob:spectating
						if (watching.killer_spectating && watching.killed_by != watching)
							if (istype(watching.killed_by))
								if (!isnull(watching.last_hit_item))
									icon = watching.last_hit_item.icon
									icon_state = watching.last_hit_item.icon_state
									name = "[watching.last_hit_item.name] (Killer: [watching.killed_by.name])"
								else
									icon = null
									name = ""
							else
								icon = null
								name = ""
						else
							if (!isnull(watching.holding))
								icon = watching.holding.icon
								icon_state = watching.holding.icon_state
								name = watching.holding.name
							else
								icon = null
								name = ""
					else
						icon = null
				else
					icon = null

				sleep(1)

	health_hud
		name = "Health"
		icon = 'gamemode_icons.dmi'
		icon_state = "heart"

		var/client/C
		screen_loc = "NORTH,WEST"

		New(loc, client/C)
			..()
			src.C = C
			Loop()

		proc/Loop()
			spawn while(1)
				if (!isnull(C.mob))
					if (istype(C.mob, /mob/living/player))
						maptext = "<font color=white>[C.mob:health]"
						invisibility = 0
					else if (istype(C.mob, /mob/spectator))
						if (!isnull(C.mob:spectating))
							var/mob/living/watching = C.mob:spectating
							invisibility = 0
							maptext = "<font color=white>[watching.health]"
						else
							invisibility = 101
					else
						invisibility = 101

				sleep(1)