obj/item
	machinegun
		name = "Machine GUN"
		icon_state = "machinegun"

		var/is_using = 0

		New()
			..()
			AttackLoop()

		proc/AttackLoop()
			spawn while(1)
				var/mob/living/P = loc

				if (istype(P))
					if (P.holding == src && P.health > 0 && !P.is_swimming && !P.is_frozen)
						if (is_using)
							P.play_sound('fse/Machine+Gun+4.wav')
							//flick("mg_shoot", P)
							P.icon_state = "mg_shoot"

							var/mob/living/M

							for (M in orange(3, P))
								if (M.health > 1)
									M.play_sound('fse/electricshock.wav')
								M.Damage(10, P, , src)


					else
						if (P.icon_state == "mg_shoot")
							P.icon_state = ""
						is_using = 0
				else
					is_using = 0

				if (is_using)
					sleep(0.9)
				else
					sleep(1)

		LeftAttack(mob/living/player)
			is_using = !is_using
			if (!is_using)
				player.icon_state = ""

		KillMessage(mob/living/player, mob/living/victim)
			return "[player] machine killed [victim]"

		BotCanAttack(mob/living/player/bot/B)
			if (B.has_enemy_nearby())
				if (!is_using)
					return 1
				else
					return 3
			else
				if (is_using && prob(40))
					return 1
				else
					return 3

	flamethrower
		name = "Flamethrower"
		icon_state = "flamethrower"

		var/is_using = 0

		LeftAttack(mob/living/player)
			if (is_using) return
			is_using = 1

			var/has_hit = 0

			var/mob/living/M

			for (M in orange(1, player))
				if (M.health < 1) continue
				has_hit = 1
				M.Damage(10, player, ,src)

			if (has_hit)
				flick("flamethrower2", player)
				player.icon_state = "flamethrower"
			else
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
				is_using = 0

		KillMessage(mob/living/player, mob/living/victim)
			return "[player] slapped off [victim] using the flamethrower"

	soda
		icon_state = "soda"
		var/is_used = 0

		BotCanAttack(mob/living/player/bot/B)
			return 1


		BotCanHold(mob/living/player/bot/B)
			if (B.health < B.max_health - 20)
				return 2
			else
				return 0


		LeftAttack(mob/living/player)
			if (is_used) return
			is_used = 1
			flick("soda_drink", player)
			player.play_sound('fse2/Drink/Drink_06.wav')
			var/hv = rand(30,100)
			player.health += hv
			player << "<b>You gained [hv] health"
			ohearers(,player) << "<i>[player] gained [hv] health using soda"

			spawn(5)
				player.holding = null
				del(src)

	rayfreeze
		icon_state = "rayfreeze"
		name = "Ray Freeze"

		LeftAttack(mob/living/player)
			var/list/lsounds = list('fse/laser1.mp3','fse/laser2.mp3','fse/laser3.mp3','fse/laser4.mp3','fse/laser5.mp3',
									'fse/laser6.mp3','fse/laser7.mp3','fse/laser8.mp3','fse/laser9.mp3')
			player.play_sound(pick(lsounds))
			flick("rayfreeze", player)

			var/mob/living/M

			for (M in orange(1, player))
				if (M.health < 1) continue
				M.Damage(10, player, ,src)
				M.Freeze()

	itemstealer
		icon_state = "itemstealer"
		name = "Item Stealer"

		LeftAttack(mob/living/player)
			flick("punch", player)
			var/mob/living/M

			for (M in orange(1, player))
				if (M.health < 1) continue

				if (M.holding)
					var/obj/item/stolen = M.holding
					if (stolen.PlayerPick(player))
						if (stolen.Move(player))
							player.holding = stolen
							player.play_sound('taco-bell-bong-sfx.mp3')

							M.Damage(10, player, ,src)
							M.holding = null
							if (M.health > 0)
								flick("hurt", M)
							src.Move(null)
							M << "<b>[player] just stole your [stolen]!"
							spawn(30)
								del(src)
				else
					player.play_sound('sfx_sounds_error3.wav')
					player << "<b>[M] is not holding anything."
					flick("hurt", player)

		KillMessage(mob/living/player, mob/living/victim)
			return "[victim] had enough with [player]'s stealing abilties"

		BotCanAttack(mob/living/player/bot/B)
			if (B.target)
				if (B.target.holding)
					return 1
				else
					return 3
			else
				return 3

		BotCanHold(mob/living/player/bot/B)
			if (B.target)
				if (B.target.holding)
					return 2
				else
					return 0
			else
				return 0

	bow
		icon_state = "bowarrow"

		var/ammo = 200

		BotCanAttack(mob/living/player/bot/B)
			var/mob/living/M

			for (M in oview(6, B))
				if (!B.is_enemy(M)) continue
				if (M.health < 1 || M.is_dead) continue // Make sure the player is not dead.
				if (prob(30))
					B.dir = get_dir(B, M)
					walk(B, 0)
					return 1

			return 3

		LeftAttack(mob/living/player)
			if (ammo < 1) return player:punch()
			player.play_sound('bow/shoot.ogg')
			flick("punch", player)
			ammo--
			new/obj/bowarrow(player.loc,player,src)

			if (ammo < 1)
				icon_state = "bow"

		KillMessage(mob/living/player, mob/living/victim)
			return "[player] hit [victim] using a bow"

	rocketphone
		icon_state = "phone"
		name = "Rocket Phone"

		var/watching = 0
		var/obj/rocket/R

		BotCanAttack(mob/living/player/bot/B)
			if (isnull(R))
				return 1
			else
				return 0

		RightAttack(mob/living/player)
			watching = !watching
			if (watching && istype(R))
				player.client.eye = R
			else
				player.client.eye = player

		LeftAttack(mob/living/player)
			if (!isnull(R)) return player:punch()
			player.play_sound('fse2/Phone/Phone2.wav')
			flick("emote5", player)
			player << "[src]: \"Launching the rocket...\""
			R = new(player.loc, player, src)

		KillMessage(mob/living/player, mob/living/victim)
			if (player == victim)
				return "[player] lasered \himself"
			else
				return "[victim] was lasered out by [player]'s rocket"


		Del()
			if (!isnull(R))
				if (game_time > 0)
					explode(R.loc, 60, , , 1)
				del(R)
			..()

	antirocket
		icon_state = "antirocket-item"
		name = "Anti-Rocket"

		LeftAttack(mob/living/player)
			player.play_sound('Kitchen_18.wav')
			new/obj/antirocket(player.loc, player)
			player.holding = null
			del(src)

		BotCanAttack(mob/living/player/bot/B)
			return 1

		BotCanHold(mob/living/player/bot)
			return 2

	antirocket
		icon_state = "antirocket-item"
		name = "Anti-Rocket"

		LeftAttack(mob/living/player)
			player.play_sound('Kitchen_18.wav')
			new/obj/antirocket(player.loc, player)
			player.holding = null
			del(src)

		BotCanAttack(mob/living/player/bot/B)
			return 1

		BotCanHold(mob/living/player/bot)
			return 2

	antiheli
		icon_state = "antiheli-item"
		name = "Anti-Helicopter"

		LeftAttack(mob/living/player)
			player.play_sound('Kitchen_18.wav')
			new/obj/antiheli(player.loc, player)
			player.holding = null
			del(src)

		BotCanAttack(mob/living/player/bot/B)
			return 1

		BotCanHold(mob/living/player/bot)
			return 2

	helicopter
		icon_state = "helicopter"

		var/obj/helicopter/R

		BotCanAttack(mob/living/player/bot/B)
			if (isnull(R))
				return 1
			else
				return 0

		/*
		RightAttack(mob/living/player)
			watching = !watching
			if (watching && istype(R))
				player.client.eye = R
			else
				player.client.eye = player
		*/

		LeftAttack(mob/living/player)
			if (!isnull(R)) return player:punch()
			player.play_sound('fse2/Phone/Phone2.wav')
			//flick("emote5", player)
			player << "[src]: \"Launching the helicopter...\""
			R = new(player.loc, player, src)

		KillMessage(mob/living/player, mob/living/victim)
			if (player == victim)
				return "[player] lasered \himself"
			else
				return "[victim] was lasered out by [player]'s helicopter"

		Del()
			if (!isnull(R))
				if (game_time > 0)
					explode(R.loc, 60, , , 1)
				del(R)
			..()

	mine
		icon_state = "mine-item"

		LeftAttack(mob/living/player)
			player.play_sound('Kitchen_18.wav')
			new/obj/mine(player.loc, player, src)
			player.holding = null
			del(src)

		BotCanAttack(mob/living/player/bot/B)
			return 1

		BotCanHold(mob/living/player/bot)
			return 2

obj/mine
	cleanup = 1
	icon = 'weapons.dmi'
	icon_state = "mine"

	var/mob/living/owner
	var/obj/item/holding

	New(loc, mob/owner, obj/item/hold)
		..()
		src.owner = owner
		color = owner.color
		src.holding = hold
		Loop()

	proc/Explode()
		explode(loc, 30, owner, holding, 1)
		var/oldloc = loc
		loc = null

		var/obj/O

		for (O in range(2, oldloc))
			if (istype(O, /obj/antirocket) || istype(O, /obj/antiheli) || istype(O, /obj/mine))
				explode(O.loc, 30, owner, holding, 1)
				del(O)

		spawn(10) del(src)

	proc/Loop()
		spawn while(1)
			var/mob/living/M

			for (M in orange(1, src))
				if (!M.is_enemy(owner)) continue
				if (M.health < 1 || M.is_dead) continue
				if (M == owner) continue
				Explode()
				break

			sleep(1)

obj/antirocket
	cleanup = 1
	icon = 'weapons.dmi'
	icon_state = "antirocket"

	var/mob/living/owner

	New(loc, mob/owner)
		..()
		src.owner = owner
		color = owner.color

obj/antiheli
	cleanup = 1
	icon = 'weapons.dmi'
	icon_state = "antiheli"

	var/mob/living/owner

	New(loc, mob/owner)
		..()
		src.owner = owner
		color = owner.color

obj/helicopter
	icon = 'weapons.dmi'
	icon_state = "helicopter"

	var/mob/living/owner
	var/obj/item/holding
	var/is_launched = 0
	var/ammo = 100
	var/lifetime = 200

	step_size = 20

	proc/Damage(d, mob/owner)
		lifetime -= d
		play_sound('hit01.mp3.mp3')
		var/oldcolor = color
		color = "white"
		animate(src, color=oldcolor, time=2)

	New(loc,mob/owner,obj/holding)
		..()
		src.owner = owner
		src.holding = holding
		owner.loc = null
		if (owner.client)
			owner.client.eye = src

		owner.is_undamagable = 1
		owner.invisibility = 101

		color = owner.color
		Loop()
		SoundLoop()

	proc/Shoot()
		ammo--
		flick("helicopter_shoot", src)
		play_sound(pick('pistol.ogg','pistol2.ogg','pistol3.ogg'))

		var/mob/living/M

		for (M in orange(3, src))
			M.Damage(10, owner, hold=holding)

		var/obj/helicopter/E

		for (E in orange(3, src))
			E.Damage(10, owner)

		//if (prob(20))
			//explode(loc, 30, owner, holding)

		if (ammo < 1)
			explode(loc, 90, owner, holding, 1)
			del(src)

	proc/SoundLoop()
		spawn while(1)
			if (is_launched)
				play_sound('sfx_vehicle_helicopterloop1.wav')
			sleep(4)

	proc/Loop()
		spawn while(1)
			if (!is_launched)
				sleep(10)
				flick("helicopter_start", src)
				icon_state = "helicopter_fly"
				is_launched = 1
				sleep(20)

			lifetime--
			//owner.loc = src.loc

			var/mob/living/M
			var/mob/living/found

			for (M in orange(8, src))
				if (!M.is_enemy(owner)) continue
				if (M.health < 1 || M.is_dead) continue
				if (owner == M) continue
				found = M
				break

			var/obj/helicopter/R

			for (R in orange(5, src))
				if (!isnull(R.owner))
					if (!R.owner.is_enemy(owner)) continue
				found = R
				break

			if (!found)
				if (rand(0,1))
					walk(src, pick(NORTH,SOUTH,EAST,WEST))
			else
				walk(src, get_dir(src, found))
				if (rand(0,1))
					Shoot()
				/*
				if (!(found in orange(3, src)))
					dir = get_dir(src, found)
				*/

			var/obj/antiheli/AR

			for (AR in orange(2, src))

				if (AR.owner && owner)
					if (!AR.owner.is_enemy(owner)) continue
					//if (AR.owner == owner) continue

				explode(AR.loc, 60, , 1)
				owner.is_undamagable = 0
				var/obj/O

				for (O in orange(2, AR))
					if (istype(O, /obj/antirocket) || istype(O, /obj/antiheli) || istype(O, /obj/mine))
						explode(O.loc, 30, , , 1)
						del(O)
				owner.Damage(owner.health, AR.owner)
				del(AR)
				del(src)
				break

			if (lifetime < 1)
				explode(loc, 90, owner, holding, 1)
				del(src)
				break

			sleep(1)

	Del()
		if (owner)
			owner.loc = src.loc
			if (owner.client)
				owner.client.eye = owner
			owner.is_undamagable = 0
			owner.invisibility = 0
		..()

obj/rocket
	icon = 'weapons.dmi'
	icon_state = "rocket"
	var/is_falling = 1
	var/mob/living/owner
	var/obj/item/holding
	var/rocket_time = 900
	var/is_launching = 1

	proc/Damage(d, mob/owner)
		rocket_time -= d
		play_sound('hit01.mp3.mp3')
		var/oldcolor = color
		color = "white"
		animate(src, color=oldcolor, time=2)

	step_size = 30

	New(loc,mob/owner,obj/holding)
		..()
		src.owner = owner
		src.holding = holding
		color = owner.color
		alpha = 0
		Loop()
		SoundLoop()

	proc/SoundLoop()
		spawn while(1)
			play_sound('sfx_vehicle_plainloop.wav')
			sleep(10)

	proc/Loop()
		spawn while(1)
			if (!istype(owner))
				del(src)
				break
			if (is_launching)
				animate(src, alpha=255, time=3)
				sleep(3)
				is_launching = 0
			rocket_time--

			var/mob/living/M
			var/mob/living/found

			for (M in orange(8, src))
				if (!M.is_enemy(owner)) continue
				if (M.health < 1 || M.is_dead) continue
				if (owner == M) continue
				found = M
				break

			var/obj/rocket/R

			for (R in orange(5, src))
				if (!R.owner.is_enemy(owner)) continue
				found = R
				break

			if (found && !prob(10))
				if (istype(found, /obj/rocket))
					walk(src, get_dir(src, found))
					if (rand(0,1))
						Shoot()
				else
					walk_towards(src, M)
					if (rand(0,1))
						Shoot()
					if (prob(5))
						Missile()
			else
				if (rand(0,1))
					walk(src, pick(NORTH,SOUTH,EAST,WEST))

			var/obj/antirocket/AR
			var/is_impact = 0

			for (AR in orange(2, src))
				if (AR.owner && owner)
					if (!AR.owner.is_enemy(owner)) continue
					if (AR.owner == owner) continue
				explode(AR.loc, 60, , , 1)
				is_impact = 1
				if (AR.owner)
					world << "<b><font color=red>[AR.owner]'s anti-rocket has destroyed [owner]'s rocket"
					if (AR.owner.client)
						AR.owner.client.color = owner.color
						animate(AR.owner.client, color=null, time=3)
						AR.owner.kills++
						AR.owner.AddCombo()
				var/obj/O

				for (O in orange(2, AR))
					if (istype(O, /obj/antirocket) || istype(O, /obj/antiheli) || istype(O, /obj/mine))
						explode(O.loc, 30, owner, holding, 1)
						del(O)
				del(AR)
				rocket_time = 0
				break

			if (rocket_time == 300)
				owner << "Rocket Ally: \"The rocket is almost destroyed..\""
				owner.play_sound('fse2/Phone/Phone2.wav')

			if (rocket_time < 1)
				explode(loc, 60, owner, holding, 1)
				if (!is_impact)
					world << "<b><font color=red>[owner]'s rocket got destroyed"
				owner.play_sound('fse2/Phone/Phone2.wav')
				del(src)
				break
			sleep(1)

	proc/Shoot()
		play_sound('sfx_wpn_laser11.wav')
		flick("rocket_shoot", src)

		var/mob/living/M

		for (M in orange(3, src))
			M.Damage(40, owner, hold=holding)

		var/obj/rocket/R

		for (R in orange(3, src))
			R.Damage(40, owner)

	proc/Missile()
		play_sound('sfx_wpn_missilelaunch.wav')
		new/obj/missile(loc)

obj/bowarrow
	icon = 'weapons.dmi'
	icon_state = "arrow"
	var/is_falling = 1
	var/mob/living/owner
	var/obj/item/holding
	cleanup = 1

	animate_movement = SLIDE_STEPS

	step_size = 10
	density = 0

	New(loc,mob/owner,obj/holding)
		..()
		src.owner = owner
		src.dir = owner.dir
		step_x = owner.step_x
		step_y = owner.step_y
		src.holding = holding
		Loop()

	proc/Loop()
		spawn while(1)
			if (is_falling)
				is_falling = step(src,dir)


				var/mob/living/M

				for (M in view(0,src))
					if (M == owner) continue
					M.Damage(40, owner, hold=holding)
					is_falling = 0
					break


				if (loc:density)
					is_falling = 0

				if (!is_falling)
					play_sound(pick('bow/arrowHit01.wav','bow/arrowHit02.wav','bow/arrowHit03.wav','bow/arrowHit04.wav',
								'bow/arrowHit05.wav','bow/arrowHit06.wav','bow/arrowHit07.wav','bow/arrowHit08.wav'))



					for (M in view(0,src))
						M.Damage(20, owner, hold=holding)

					sleep(20)
					del(src)
			sleep(0.1)