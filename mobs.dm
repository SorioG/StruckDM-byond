var/const
	DEATH_GENERAL = 1
	DEATH_FIRE = 2
	DEATH_FROZEN = 3
	//DEATH_FIRE = 4
	DEATH_VOID = 4

mob
	var/deaths = 0
	var/kills = 0
	var/list/spectators = list()
	var/team = TEAM_NONE
	var/damage_extra = 0
	var/obj/item/holding
	var/is_undamagable = 0
	var/death_reason = DEATH_GENERAL
	var/list/inventory[9]
	var/is_frozen = 0
	var/obj/item/last_hit_item = null
	var/mob/living/killed_by
	var/killer_spectating = 0
	var/combo_count = 0
	var/is_killing = 0
	var/is_idle = 0
	var/is_swimming = 0
	var/is_blind = 0

	proc/is_afk(seconds=50)
		if (client)
			return (client.inactivity/10) >= seconds
		else
			return 0

	Cross(mob/living/L)
		if (!istype(L)) return ..()

		if (is_teammate(L)) return 1
		return ..()

	New()
		..()
		for (var/i = 1, i < 9, i++)
			inventory[i] = null

	Enter(obj/item/I)
		for (var/i = 1, i < 9, i++)
			if (isnull(inventory[i]))
				inventory[i] = I
				return 1
		return 0
	Exited(obj/item/I)
		for (var/i = 1, i < 9, i++)
			if (inventory[i] == I)
				if (holding == I)
					holding = null
				inventory[i] = null

	proc/is_enemy(mob/M)
		//if (M.is_undamagable) return 0
		if (M.team == TEAM_NONE) return 1
		if (team == TEAM_NONE) return 1

		if (M.team != team) return 1

		return 0

	proc/is_teammate(mob/M)
		if (M.team == TEAM_NONE) return 0
		if (team == TEAM_NONE) return 0

		if (M.team == team) return 1

		return 0

	spectator
		invisibility = 101
		density = 0
		step_size = 32
		var/mob/living/spectating
		var/spec_mode = 0
		var/spec_cine_time = 100

		Login()
			if (!loc) loc = rand_loc(current_map)

		New()
			..()
			spawn while(1)
				sleep(1)
				Tick()

		proc/Tick()
			if (spectating)
				loc = spectating.loc


			if (spec_mode == 1)
				if (spectating)
					if (spectating.killed_by)
						watch_mob(spectating.killed_by)
					else
						if (spectating.health < 1)
							watch_mob(rand_player_alive())
				else
					watch_mob(rand_player_alive())
			else if (spec_mode == 2)
				spec_cine_time--
				if (spec_cine_time < 1)
					watch_mob(rand_player())
					spec_cine_time = 30
			else if (spec_mode == 3)
				var/choose_player = 0
				if (!spectating)
					choose_player = 1

				if (spectating)
					if (!spectating.is_killing)
						choose_player = 1

				if (choose_player)
					var/list/players = get_players()
					var/mob/living/player/P
					for (P in players)
						if (P.is_killing && rand(0,1))
							watch_mob(P)
							break

					if (!spectating)
						watch_mob(rand_player_alive())

		verb/join()
			var/mob/P = new/mob/living/player(rand_loc(current_map))
			P.name = name
			P.gender = gender
			if (isicon(client.skin))
				P.icon = client.skin
			client.eye = P
			P.key = key

		proc/watch_mob(mob/M)
			if (!ismob(M)) return
			if (spectating)
				spectating.spectators -= src
				src << 'fse2/Camera/Camera_02.wav'
			else
				src << 'fse2/Camera/Camera_01.wav'
			client.eye = M
			M.spectators += src
			spectating = M


		proc/unwatch()
			if (!spectating) return
			spectating.spectators -= src
			client.eye = src
			spectating = null
			src << 'fse2/Camera/Camera_02.wav'

		verb/Spectate(mob/M as null|mob in world)
			set category = "Spectator"

			if (!M && spectating)
				src << "<b>You're no longer watching [spectating]"
				spec_mode = 0
				unwatch()
				return
			if (!M) return
			if (istype(M,/mob/living/player))
				spec_mode = 0
				watch_mob(M)
				src << "<b>You're now watching [spectating]"
			else
				src << "<b>[M] is not a player or a bot"

		verb/Spectate_Killer_to_Killer()
			set category = "Spectator"

			watch_mob(rand_player_alive())
			spec_mode = 1

		verb/Spectate_Cinematic()
			set category = "Spectator"

			watch_mob(rand_player())
			spec_cine_time = 30
			spec_mode = 2

		verb/Spectate_Kill_Only()
			set category = "Spectator"

			spec_mode = 3

	Logout()
		del(src)
	living
		var/health = 100
		var/max_health = 100
		var/is_dead = 0
		var/respawn_time = 20
		var/is_damaging = 0

		var/drowning_time = 100
		var/can_move = 1

		var/blind_time = 5
		var/frozen_time = 5
		var/blind_state = "blind"
		var/normal_state = ""
		var/frozen_start_state = "frozen_start"
		var/frozen_state = "frozen"
		var/frozen_broken_state = "frozen_broken"
		//var/image/shadow_image
		//var/can_use_shadow = 1

		animate_movement = SLIDE_STEPS

		proc/AddCombo()

		proc/Blindfold(v=1)
			if (v && !is_dead)
				blind_time = 5
				sight |= BLIND
				icon_state = blind_state
				can_move = 0
				is_blind = 1
				//src << "<b>You have been blindfolded!"
			else
				sight &= ~BLIND
				if (!is_dead) icon_state = normal_state
				can_move = 1
				is_blind = 0

		proc/Freeze()
			if (is_frozen) return
			if (health < 1) return
			flick(frozen_start_state, src)
			icon_state = frozen_state
			can_move = 0
			frozen_time = 10
			is_frozen = 1
			if (client)
				animate(client, color="cyan", time=6)
		proc/Unfreeze()
			if (!is_frozen) return
			if (health < 1) return
			flick(frozen_broken_state, src)
			icon_state = normal_state
			can_move = 1
			is_frozen = 0
			play_sound('sounds/q009/explosion.ogg')
			if (client)
				animate(client, color=null, time=2)

		proc/BlindLoop()
			spawn while(1)
				if (is_blind)
					blind_time--
					if (blind_time < 1)
						Blindfold(0)
				sleep(10)

		proc/FrozenLoop()
			spawn while(1)
				if (is_frozen)
					frozen_time--
					if (frozen_time < 1)
						Unfreeze()
				sleep(10)

		Move()
			if (health < 1) return
			if (!can_move) return
			return ..()

		proc/DamageEffect()
			if (is_damaging) return
			is_damaging = 1
			var/oldcolor = color
			color = "white"
			animate(src, color=oldcolor, time=5)
			is_damaging = 0

		proc/Respawn()

		proc/Death(mob/killer, reason, obj/item/hold)

		proc/Hit(mob/killer, obj/item/hold)

		proc/CanRespawn()
			return 1

		proc/Damage(d, mob/killer, reason=DEATH_GENERAL, obj/item/hold)
			if (!d) return
			if (health < 1) return
			if (ismob(killer) && !is_enemy(killer)) return
			if (is_undamagable) return
			health -= d
			if (ismob(killer) && killer.damage_extra)
				health -= killer.damage_extra
			DamageEffect()

			if (health < 1)
				health = 0
				is_dead = 1
				Blindfold(0)
				Death(killer, reason, hold)

				spawn(respawn_time)
					if (CanRespawn())
						is_dead = 0
						Respawn()
			else
				Hit(killer, hold)

		proc/LeftAttack()

		proc/RightAttack()

		proc/VoidLoop()
			spawn while(1)
				if (isturf(loc))
					if (istype(loc, /turf/void) && health > 0)
						Damage(health, null, DEATH_VOID)
				sleep(1)

		New()
			..()
			BlindLoop()
			FrozenLoop()
			VoidLoop()
			/*
			if (can_use_shadow)
				shadow_image = image('turfs.dmi', icon_state="shadow")
				shadow_image
				underlays += shadow_image
			*/
	living/dummy
		icon = 'player.dmi'

		respawn_time = 30
		name = "Dummy"
		var/starting_loc

		New(loc)
			..()
			starting_loc = loc
			color = rgb(rand(0,255),rand(0,255),rand(0,255))

		Respawn()
			if (health > 0) return
			icon_state = ""
			health = max_health
			density = 1
			step_x = 0
			step_y = 0
			is_swimming = 0
			loc = starting_loc
			is_undamagable = 0
			holding = null


			var/obj/item/I
			for (I in contents)
				del(I)
			alpha = 255

		Death(mob/killer, obj/item/holding)
			if (is_swimming)
				flick("swimming_death",src)
				icon_state = "swimming_corpse"
			else
				flick("death",src)
				icon_state = "corpse"
			//var/id = rand(10,37)
			play_sound('sounds/punches/hit33.mp3.mp3')
			if (rand(0,1) && is_swimming)
				play_sound('water/splash_04.ogg')
			density = 0
			damage_extra = 0

			var/obj/item/I

			for (I in contents)
				if (client)
					if (client.adm_nodrop) break
				I.loc = locate(rand(x-3, x+3),rand(y-3, y+3),z)

		Hit(mob/killer, obj/item/holding)
			if (is_swimming)
				flick("swimming_hurt", src)
			else
				flick("hurt",src)
			step(src, turn(dir, 90), 3)
			//var/id = rand(10,37)
			//play_sound(file("sounds/punches/hit[id].mp3.mp3"))
			if (rand(0,1) && is_swimming)
				play_sound(file("sounds/water/splash_0[rand(1,9)].ogg"))
	living/player
		icon = 'player.dmi'
		respawn_time = 60
		var/image/afk_image

		AddCombo()
			combo_count++

			/*
			if (combo_count >= 10)
				world << 'beep-02.wav'
			*/

			/*
			if (combo_count == 10)
				GM.KillComboStarted(src)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] killed 10 players without dying!<br>"

			if (combo_count == 20)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] killed 20 players without dying!<br>"

			if (combo_count == 30)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] killed 30 players without dying!<br>"
			*/

			if (combo_count == 40)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] killed 40 players without dying!<br>"

			if (combo_count == 50)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] killed 50 players without dying!<br>"

			if (combo_count == 60)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] killed 60 players without dying!<br>"

			if (combo_count == 70)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] killed 70 players without dying!<br>"

			if (combo_count == 80)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] killed 80 players without dying!<br>"

			if (combo_count == 100)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] is on killing spree!<br>"

			if (combo_count == 300)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] is god-like!<br>"

			if (combo_count == 1000)
				if (GM.KillComboChange(src, combo_count) == 1) return
				world << "<h2><font color=cyan>[src] is unstoppable!<br>"

		proc/AFKLoop()
			spawn while(1)

				if (is_afk())
					if (!is_idle)
						overlays += afk_image
						is_idle = 1
						//world << "<b><font color=red>[src] is now AFK"
					alpha = 100
				else
					if (is_idle)
						overlays -= afk_image
						is_idle = 0
						//world << "<b><font color=red>[src] is no longer AFK"
						alpha = 255

				sleep(1)

		proc/DrownLoop()
			spawn while(1)
				if (is_swimming)
					drowning_time--

					if (drowning_time < 1)
						if (health > 0)
							play_sound(pick('water/bubble_01.ogg','water/bubble_02.ogg','water/bubble_03.ogg'))
							Damage(20)
				else
					drowning_time = 8
				sleep(10)

		proc/KillingLoop()
			spawn while(1)
				is_killing = 0
				sleep(30)

		proc/SpectateLoop()
			spawn while(1)
				if (dead_spectating && health < 1 && !isnull(client))
					sight = 0

					if (health > 0)
						is_dead = 0
						continue

					var/mob/living/P = rand_player_alive()

					if (P)
						client.eye = P
					sleep(30)
				else if (dead_spectating && !isnull(client))
					is_dead = 0
					client.eye = src
					dead_spectating = 0

				sleep(1)

		var/dead_spectating = 0

		Damage(d, mob/killer, reason=DEATH_GENERAL, obj/item/hold)
			if (killer)
				if (!GM.CanKill(killer, src)) return
				if (!is_enemy(killer)) return
			..()

		New()
			..()
			color = rgb(rand(0,255),rand(0,255),rand(0,255))
			GM.PlayerSpawn(src)
			DrownLoop()
			KillingLoop()
			SpectateLoop()
			afk_image = image('gamemode_icons.dmi', icon_state="afk")
			afk_image.appearance_flags = RESET_COLOR
			afk_image.pixel_y = 5
			AFKLoop()

		CanRespawn()
			var/crvalue = GM.CanRespawn(src)
			if (crvalue == 1)
				return 1

			if (crvalue == 0)
				dead_spectating = 1
				return 0

			if (crvalue == -1)
				dead_spectating = 0
				return 0

			return 1

		Login()
			..()
			GM.PlayerJoin(src)

		Death(mob/living/killer, reason, obj/item/hold)
			killed_by = killer
			last_hit_item = hold
			if (combo_count >= 30)
				var/kcvalue = GM.KillComboRuined(src, killer)
				//src << 'missed.wav'
				if (istype(killer) && killer != src)
					if (kcvalue != 2)
						world << 'applause8.wav'
					if (kcvalue == 0)
						world << "<h2><font color=cyan>[killer] has ruined [src]'s killing spree.<br>"
						world << "<b>[src]'s kill combo: [combo_count]<br>"
			combo_count = 0
			GM.PlayerDeath(src, killer, reason)
			deaths += 1
			if (client)
				client.c_deaths += 1
			sight |= (BLIND|SEE_SELF)
			if (is_frozen)
				reason = DEATH_FROZEN

			if (is_swimming || reason == DEATH_VOID)
				flick("swimming_death",src)
				icon_state = "swimming_corpse"
			else
				if (reason == DEATH_GENERAL)
					flick("death",src)
					icon_state = "corpse"
				if (reason == DEATH_FIRE)
					icon_state = "death_fire"
				if (reason == DEATH_FROZEN)
					flick("frozen_death",src)
					icon_state = "frozen_corpse"
			//var/id = rand(10,37)
			play_sound('sounds/punches/hit33.mp3.mp3')
			if (rand(0,1) && is_swimming)
				play_sound('sounds/water/splash_05.ogg')
			density = 0
			damage_extra = 0
			is_killing = 0
			spawn(20)
				if (health > 0) return
				killer_spectating = 1
				if (client)
					if (client.killcam)
						if (ismob(killer) && killer != src)
							if (health > 0) return
							client.eye = killer
							sight = 0

				/*
				var/mob/spectator/S
				for (S in spectators)
					if (killer != src && istype(killer, /mob/living/player))
						S.client?.eye = killer
				*/
				//animate(src, alpha=0, time=5)

				if (ismob(killer) && killer != src)
					if (client)
						if (client.killcam)
							if (health > 0) return
							src << "<h2><font color=red>You have been killed by [killer]<br>"
							if (reason == DEATH_GENERAL)
								if (istype(last_hit_item))
									src << "<font color=red>Cause of Death: \the [last_hit_item]"
								else
									src << "<font color=red>Cause of Death: Punch"
							if (reason == DEATH_FIRE)
								src << "<font color=red>Cause of Death: Burnt down"
							if (reason == DEATH_FROZEN)
								if (istype(last_hit_item))
									src << "<font color=red>Cause of Death: \a [last_hit_item] while frozen"
								else
									src << "<font color=red>Cause of Death: Punch while frozen"
								//src << "<font color=red>Cause of Death: While Frozen"

			spawn(respawn_time)
				killer_spectating = 0


			holding = null

			var/obj/item/I

			for (I in contents)
				if (GM.can_drop_items)
					I.loc = locate(rand(x-3, x+3),rand(y-3, y+3),z)
				else
					I.loc = null
					spawn(20) del(I)

			for (var/i = 1, i < 9, i++)
				inventory[i] = null

			if (killer == src)
				if (killmessage_enabled)
					if (GM.KillMessage(src, src))
						world << "<b><font color=red>[GM.KillMessage(killer, src)]"
					else if (istype(last_hit_item))
						world << "<b><font color=red>[last_hit_item.KillMessage(src, src)]"
					else
						world << "<b><font color=red>[src] killed \himself"
			else if (ismob(killer))
				if (killmessage_enabled)
					if (GM.KillMessage(killer, src))
						world << "<b><font color=red>[GM.KillMessage(killer, src)]"
					else if (istype(last_hit_item))
						world << "<b><font color=red>[last_hit_item.KillMessage(killer, src)]"
					else if (reason == DEATH_GENERAL)
						if (is_swimming)
							world << "<b><font color=red>[killer] has drowned [src]"
						else
							world << "<b><font color=red>[killer] killed [src]"
					else if (reason == DEATH_FIRE)
						world << "<b><font color=red>[src] was burnt out by [killer]"
					else if (reason == DEATH_FROZEN)
						world << "<b><font color=red>[src]'s ice cube was broken by [killer]"

				killer:AddCombo()
				killer.kills += 1
				if (killer.client)
					killer.client.c_kills += 1

					if (!(killer in orange(,src)))
						// Off-Screen Kill
						var/oldcolor = killer.client.color
						killer.client.color = color
						animate(killer.client, color=oldcolor, time=3)
				killer.is_killing = 0
			else
				if (killmessage_enabled)
					if (reason == DEATH_GENERAL)
						if (is_swimming)
							var/list/dmsg = list("[src] had too much fun on [src.loc]","[src] has drowned","[src] can't get out on [src.loc]")
							world << "<b><font color=red>[pick(dmsg)]"
						else
							world << "<b><font color=red>[src] died"
					else if (reason == DEATH_FIRE)
						world << "<b><font color=red>[src] burnt to death"
					else if (reason == DEATH_FROZEN)
						world << "<b><font color=red>[src] freezed to death"
					else if (reason == DEATH_VOID)
						world << "<b><font color=red>[src] got stuck on [loc]"


		Respawn()
			if (health > 0) return
			killed_by = null
			last_hit_item = null
			icon_state = ""
			health = max_health
			density = 1
			dead_spectating = 0
			step_x = 0
			step_y = 0
			is_swimming = 0
			loc = rand_loc(z)
			holding = null
			is_undamagable = 0
			can_move = 1
			Blindfold(0)
			is_frozen = 0
			sprint(0)
			killer_spectating = 0
			if (client)
				client.eye = src
				client.color = null
			var/mob/spectator/S
			for (S in spectators)
				S.client?.eye = src
			var/obj/item/I
			for (I in contents)
				del(I)

			for (var/i = 1, i < 9, i++)
				inventory[i] = null
			alpha = 255
			sight = 0
			GM.PlayerSpawn(src)

		Hit(mob/living/killer, obj/item/hold)
			last_hit_item = hold

			if (is_swimming)
				flick("swimming_hurt", src)
			else if (is_frozen)
				flick("frozen_hurt", src)
			else
				flick("hurt",src)
			step(src, turn(dir, 90), 3)
			//var/id = rand(10,37)
			play_sound(file("sounds/punches/hit32.mp3.mp3"))
			if (rand(0,1) && is_swimming)
				play_sound('sounds/water/splash_05.ogg')

			GM.PlayerHit(killer, src)

			if (istype(killer))
				killer.is_killing = 1

		verb/sprint(mode as num)
			set name = ".sprint"
			set instant = 1

			if (health < 1) return
			if (is_swimming)
				step_size = 8
				return

			if (mode)
				step_size = 15
				if (!is_frozen) icon_state = "sprint"
			else
				step_size = 8
				if (!is_frozen) icon_state = ""

		verb/attack(mode as num)
			set name = ".attack"
			set instant = 1

			if (health < 1) return
			if (!GM.CanAttack(src)) return
			if (isnull(loc)) return

			if (is_frozen)
				flick("frozen_break", src)
				frozen_time--
				//var/id = rand(1,9)
				play_sound('sounds/punches/hit05.mp3.mp3')
				if (frozen_time < 1)
					Unfreeze()
				return

			if (mode)
				RightAttack()
			else
				LeftAttack()

		verb/slot(inv as num)
			set name = ".slot"
			set instant = 1

			if (health < 1) return

			if (!isnull(inventory[inv]))
				holding = inventory[inv]
			else
				holding = null

			src << 'weapswitch.ogg'

			var/mob/spectator/S
			for (S in spectators)
				S << 'weapswitch.ogg'

		verb/leave()
			if (!client) return

			var/mob/spectator/S = new(loc)
			S.name = name
			S.gender = gender
			client.eye = S
			S.key = key

		LeftAttack()
			if (health < 1) return

			if (holding && !is_swimming)
				holding:LeftAttack(src)
			else
				punch()

		RightAttack()
			if (health < 1) return

			if (holding && !is_swimming)
				holding:RightAttack(src)

		proc/punch()
			// Just Punch!
			if (is_swimming)
				flick("swimming_punch", src)
			else
				flick("punch", src)
			if (rand(0,1) && is_swimming)
				play_sound('sounds/water/splash_07.ogg')

			var/has_damaged = 0
			var/mob/living/M
			for (M in oview(1, src))
				M.Damage(rand(10,18), src)
				has_damaged = 1

			if (has_damaged)
				play_sound('sfx_damage_hit10.wav')

		verb/emote(e as num)
			set name = ".emote"
			set instant = 1

			if (health < 1) return
			if (e > 7) return
			if (is_swimming)
				flick("swimming_emote", src)
				return
			if (is_frozen)
				return

			flick("emote[e]", src)

			if (e == 1)
				hearers(src) << "<i>[src] waves</i>"
			else if (e == 2)
				hearers(src) << "<i>[src] does a little dance</i>"
			else if (e == 3)
				hearers(src) << "<i>[src] thinks about something</i>"
			else if (e == 4)
				hearers(src) << "<i>[src] laughs out loud</i>"
			else if (e == 5)
				hearers(src) << "<i>[src] lifts \his arm</i>"
			else if (e == 6)
				hearers(src) << "<i>[src] shows off \his diamonds</i>"
			else if (e == 7)
				hearers(src) << "<i>[src] points to \his direction</i>"

		bot
			var/mob/living/target
			var/taken_damage = 0
			gender = PLURAL

			proc/has_enemy_nearby()
				var/mob/living/M

				for (M in oview(2,src))
					if (M.health < 1) continue
					if (!is_enemy(M)) continue
					if (!GM.CanKill(src, M)) continue
					return 1

				return 0

			proc/pick_enemy_nearby()
				var/mob/living/M

				for (M in oview(2,src))
					if (M.health < 1) continue
					if (!is_enemy(M)) continue
					if (!GM.CanKill(src, M)) continue
					return M

				return null

			emote()
				if (!bot_do_emotes) return
				..()

			Hit()
				..()
				if (!taken_damage)
					taken_damage = 1
					spawn(30)
						taken_damage = 0

			proc/has_taken_damage()
				return taken_damage

			Death()
				..()
				target = null

			New()
				..()
				name = "\[BOT][pick(bot_names)]"
				GM.PlayerJoin(src)

				spawn while(1)
					if (bot_difficulty == BOT_EASY)
						sleep(rand(10,50))
					else if (bot_difficulty == BOT_MEDIUM)
						sleep(rand(5,10))
					else if (bot_difficulty == BOT_HARD)
						sleep(rand(1,5))
					else if (bot_difficulty == BOT_INSANE)
						sleep(2)
					if (health < 1) continue
					AITick()

			proc/choose_item()
				//var/obj/item/I
				//var/index = 1
				var/should_choose = 0

				for (var/index=1, index<9, index++)
					var/obj/item/e = inventory[index]
					if (istype(e))
						var/hold_value = e.BotCanHold(src)
						if (hold_value == 1 && prob(30))
							should_choose = 1
						else if (hold_value == 2)
							should_choose = 1

					if (should_choose)
						slot(index)
						break

			proc/AITick()
				if (GM.AITick(src)) return

				if (is_frozen)
					if (bot_difficulty == BOT_HARD || bot_difficulty == BOT_INSANE)
						attack(0)
					return

				if (ismob(target))
					if (target.is_dead)
						if (bot_do_emotes && rand(0,1))
							emote(rand(1,7))
							sleep(20)

				target = pick_enemy_nearby()
				var/will_attack = 1

				var/obj/item/I

				for (I in oview(4,src))
					if (prob(50))
						walk_to(src, I)
						sprint(0)
						sleep(10)

				if (istype(holding))
					var/avalue = holding.BotCanAttack(src)
					if (avalue == 1)
						will_attack = 0
						attack(0)
					else if (avalue == 2)
						will_attack = 0
						attack(1)
					else if (avalue == 3)
						will_attack = 0

				if (prob(50))
					choose_item()
				/*
				else
					if (prob(10)) slot(rand(1,9))
				*/

				if (istype(loc, /turf/water))
					var/turf/E
					var/turf/found

					for (E in orange(,src))
						if (!E.density)
							found = E
							break

					if (!found)
						walk(src, pick(NORTH,SOUTH,EAST,WEST))
					else
						if (prob(10))
							walk(src, pick(NORTH,SOUTH,EAST,WEST))
						else
							walk_to(src, found)
					return

				if (target)
					if (prob(10))
						walk_rand(src)
					else
						walk_towards(src,target)

					if (will_attack)
						attack(0)
				else
					if (prob(5))
						walk(src,0)
						if (bot_do_emotes)
							if (rand(0,1))
								emote(rand(1,3))
								sleep(20)
					else
						walk_rand(src)

					if (prob(10))
						sprint(rand(0,1))



var/bot_do_emotes = 0
var/list/bot_names = list("NotABot","Scifi","Daniel","Jake","Mike","Botty","Hacker",
							"Ranny","Frost","XLaser","ThisBotStinks","DiamondLover","EmoteAbuser",
							"WaterCool","JustPunch","i'm a bot","XRay","StickBot","BotTheBYONDFan","KillMe",
							"Meincarft","Terrarrr","Socks","ItemAbuser","LivingHell","Larry","Programmer",
							"Tux","Linuxing","Oops!","HitMePow","MyEnemy","Alt+F4")
var/bot_difficulty = BOT_EASY

var/const
	BOT_EASY = 1
	BOT_MEDIUM = 2
	BOT_HARD = 3
	BOT_INSANE = 4


proc/rand_loc(z=1, attempts, list/except_list=list(), use_playerspawn=0)
	var/x
	var/y
	var/blocked = 1
	var/tries = attempts
	var/turf/res

	if (use_playerspawn)
		var/obj/mapitems/playerspawn/PS
		var/list/playerspawns = list()


		for (res in block(locate(1,1,z),locate(rand(1,world.maxx),rand(1,world.maxy), z)))
			for (PS in view(0, res))
				if (!istype(PS)) continue
				playerspawns += PS

		if (length(playerspawns))
			PS = pick(playerspawns)
			return PS.loc


	while (blocked)
		if (tries < 1 && attempts > 0) break
		x = rand(1, world.maxx)
		y = rand(1, world.maxy)
		res = locate(x, y, z)
		if (except_list.Find(res.type)) continue
		blocked = res.density
		tries -= 1

	return res

proc/rand_player()
	var/list/players = get_players()
	if (!length(players))
		return null
	else
		return pick(players)

proc/rand_player_alive()
	var/list/players = get_alive_players()
	if (!length(players))
		return null
	else
		return pick(players)