// Extra Gamemodes for StruckDM

// BOMB RUN GAMEMODE
obj/bombrun
	bomb
		icon = 'gamemode_icons.dmi'
		icon_state = "bomb"

		New()
			..()

			pixel_y = 100
			play_sound(pick('ren.ogg','ren2.ogg','ren3.ogg'))

			spawn()
				for (var/i=0, i<100, i++)
					pixel_y--
					sleep(0.01)

				play_sound(pick('glauncher.ogg','glauncher2.ogg','glauncher3.ogg'))

				spawn(50)
					explode(loc, 100, take_fire=1)
					del(src)

obj/missile
	icon = 'gamemode_icons.dmi'
	icon_state = "bomb"

	New()
		..()

		pixel_y = 50

		spawn()
			for (var/i=0, i<50, i++)
				pixel_y--
				sleep(0.01)

			play_sound(pick('glauncher.ogg','glauncher2.ogg','glauncher3.ogg'))

			spawn(50)
				explode(loc, 100, take_fire=1)
				del(src)



// CAPTURE THE FLAG GAMEMODE
obj/ctf
	flag
		var/team = TEAM_NONE
		icon = 'gamemode_icons.dmi'
		icon_state = "flag"
		var/image/img
		var/image/img_taken
		var/mob/living/player/holder
		var/starting_loc
		var/is_standing = 1

		New(loc, team=TEAM_RED)
			..()
			img = image('gamemode_icons.dmi', icon_state="flag")
			img.color = get_team_name(team)
			img.appearance_flags = RESET_COLOR
			img_taken = image('gamemode_icons.dmi', icon_state="flag_taken", loc=loc)
			color = get_team_name(team)
			starting_loc = loc
			src.team = team

		proc/take_flag(mob/living/player/P)
			if (holder) return 0 // Someone is already holding it (this will fix some bugs)
			if (P.team == team) return 0 // Players on the same team as flag is not allowed to take it.
			if (P.health < 1) return 0 // Dead Players are not allowed to take it aswell.
			holder = P

			holder.underlays += img
			loc = null

			/*

			if (is_standing)
				var/mob/living/player/EX
				for (EX in get_team_players(team))
					if (EX.client)
						EX.client.images += img_taken

			*/

			is_standing = 0

			return 1

		proc/drop_flag()
			if (!holder) return

			loc = holder.loc
			holder.underlays -= img
			holder = null

		proc/remove_taken_flag()
			if (is_standing) return
			is_standing = 1
			/*
			var/mob/living/player/EX
			for (EX in get_team_players(team))
				if (EX.client)
					EX.client.images -= img_taken
			*/

obj/ctf
	taken_hud
		icon = 'gamemode_icons.dmi'
		icon_state="flag_taken"
		alpha = 0

		screen_loc = "1,1"
		var/client/viewer
		var/obj/ctf/flag/viewer_flag
		New(loc,client/C)
			..()
			viewer = C
			viewer_flag = GM:get_team_flag(viewer.mob.team)
			C.screen += src
			HUDLoop()

		proc/HUDLoop()
			spawn while(1)
				if (!istype(viewer.mob, /mob/living/player))
					viewer.screen -= src
					del(src)
					break

				if (!isnull(viewer_flag))
					if (viewer_flag.is_standing)
						alpha = 0
					else
						alpha = 255

				sleep(1)

gamemode
	teamdm/ctf
		name = "Capture the Flag"
		music_list = list('anotherpart_techno.mp3')
		var/list/team_score = list(0,0,0,0)
		var/list/flags = list()
		var/list/huds = list()

		proc/is_already_holding(mob/living/player/P)
			var/obj/ctf/flag/F
			for (F in flags)
				if (F.holder == P) return 1

			return 0

		proc/get_team_flag(team=TEAM_RED)
			var/obj/ctf/flag/F
			for (F in flags)
				if (F.team == team) return F

			return null

		GamemodeStart()
			..()
			team_score = list(0,0,0,0)

		BeforeStart()
			// Initialize 4 flags on the gamemode
			flags = list()
			flags += new/obj/ctf/flag(rand_loc(current_map), TEAM_RED)
			flags += new/obj/ctf/flag(rand_loc(current_map), TEAM_BLUE)
			flags += new/obj/ctf/flag(rand_loc(current_map), TEAM_YELLOW)
			flags += new/obj/ctf/flag(rand_loc(current_map), TEAM_GREEN)

		GamemodeEnd()
			var/ld = "<b>Team Leaderboard</b><br>"
			ld += "<b><font color=red>Team Red | Flags Captured: [team_score[1]]</font></b><br>"
			ld += "<b><font color=blue>Team Blue | Flags Captured: [team_score[2]]</font></b><br>"
			ld += "<b><font color=yellow>Team Yellow | Flags Captured: [team_score[3]]</font></b><br>"
			ld += "<b><font color=green>Team Green | Flags Captured: [team_score[4]]</font></b><br>"
			world << browse(ld)
			// Delete all of the flags, so this should make it temporary
			var/obj/ctf/flag/F
			for (F in flags)
				var/mob/living/player/P
				for (P in get_players())
					P.underlays -= F.img

				del(F)

			var/obj/ctf/taken_hud/TH

			for (TH in huds)
				TH.viewer.screen -= TH
				del(TH)

		PlayerDeath(mob/living/player/victim, mob/living/player/killer)
			..()
			// Make the victim drop the flag
			var/obj/ctf/flag/F
			for (F in flags)
				victim.underlays -= F.img
				if (F.holder == victim)
					F.drop_flag()

		PlayerSpawn(mob/living/player/P)
			// Make them stay on the same location as flag on spawn
			if (P.team == TEAM_NONE)
				P.team = pick(allowed_teams)

			var/obj/ctf/flag/F
			for (F in flags)
				if (F.team == P.team)
					P.loc = F.starting_loc
					break

		PlayerJoin(mob/living/player/P)
			..()
			PlayerSpawn(P)
			if (P.client)
				var/obj/ctf/taken_hud/hud = new(null,P.client)
				huds += hud

		// Make the bots follow the rules of a gamemode
		AITick(mob/living/player/bot/B)
			. = 0
			var/obj/ctf/flag/F
			for (F in flags)
				if (F.holder == B)
					if (prob(0.2))
						return 0
					else
						if (!istype(B.target, /obj/ctf/flag) || !B.target)
							var/obj/ctf/flag/FX
							B.target = null
							for (FX in flags)
								if (FX.team != B.team) continue
								B.target = FX
								break

						var/obj/ctf/flag/X = B.target

						if (prob(30) || !B.target)
							B.sprint(0)
							walk_rand(B)
						else
							B.sprint(rand(0,1))
							if (X.holder && X.holder != B)
								B.sprint(1)
								walk_to(B, X.holder)
							else
								walk_to(B, B.target)

						if (B.has_enemy_nearby())
							B.attack(0)
						. = 1

			for (F in oview(5, B))
				if (F.team == B.team)
					if (!F.is_standing && !prob(30))
						B.sprint(0)
						walk_to(B, F)
						. = 1
				else
					if (prob(40))
						if (F.holder)
							B.sprint(rand(0,1))
							walk_to(B, F.holder)
						else
							B.sprint(rand(0,1))
							if (prob(25))
								walk_to(B, F)
								sleep(10)
							else
								walk_rand(B)
						. = 1

		GameTick()
			var/obj/ctf/flag/F
			for (F in flags)
				if (!F.loc && !F.holder)
					F.loc = F.starting_loc

				var/mob/living/player/P
				for (P in oview(0, F))
					if (F.holder) break
					if (!P.team) continue

					if (!F.is_standing)
						if (P.team == F.team)
							F.loc = F.starting_loc
							F.is_standing = 1

					if (P.team != F.team)
						if (!is_already_holding(P))
							if (F.take_flag(P))
								//get_team_players(F.team) << "<b><font color=red>[P] took your team's flag!"
								world << "<b><font color=green>[P] has taken team [get_team_name(F.team)]'s flag"

				if (F.holder)
					if (F.holder.team == F.team)
						F.drop_flag()
						F.loc = F.starting_loc
						//F.is_standing = 1
						F.remove_taken_flag()
					else
						var/obj/ctf/flag/FX
						for (FX in view(0, F.holder))
							if (!istype(FX)) continue
							if (FX.team != F.holder.team) continue
							world << "<b><font color=green>[F.holder] has captured team [get_team_name(F.team)]'s flag"
							//get_team_players(F.team) << "<b><font color=red>[F.holder] captured your team's flag!"
							team_score[get_team_index(F.holder.team)] += 1
							F.drop_flag()
							F.loc = F.starting_loc
							//F.is_standing = 1
							F.remove_taken_flag()
							break

	zombies
		name = "Zombies"
		maps = list(3,1,4)
		var/zombies_killed = 0
		var/has_started = 0
		var/start_timer = 10
		var/difficulty = 1
		var/diff_name = ""
		music_list = list('deadcave.mp3','technogoober.wav','anotherpart_techno.mp3')

		GamemodeStart()
			zombies_killed = 0
			has_started = 0
			difficulty = rand(1,/*4*/3)
			var/d = ""

			if (difficulty == 1)
				d = "Easy"
			else if (difficulty == 2)
				d = "Medium"
			else if (difficulty == 3)
				d = "Hard"
			else
				d = "Insane"

			diff_name = d

			start_timer = rand(1,30)

		PlayerSpawn(mob/living/player)
			player.team = TEAM_RED
			/*
			if (player.gm_zombies_lives < 1)
				player.is_undamagable = 1
				player.alpha = 10
			*/
		PlayerJoin(mob/living/player)
			player.gm_zombies_lives = 3
			player.team = TEAM_RED

		CanAttack(mob/living/player/p)
			//if (!has_started) return 0
			if (p.gm_zombies_lives < 1) return 0
			return 1

		CanRespawn(mob/living/player/p)
			if (p.gm_zombies_lives < 1) return 0
			return 1

		PlayerDeath(mob/living/player)
			player.gm_zombies_lives -= 1
			if (player.gm_zombies_lives > 0)
				player << "<b>Lives Left: [player.gm_zombies_lives]"
			else
				world << "<b><font color=red>[player]: Game Over!"

		GamemodeEnd()
			world << "<b>Zombies Killed: [zombies_killed]"
			var/mob/living/player/P
			for (P in get_players())
				P.alpha = 255

			var/mob/living/zombie/Z

			for (Z in world)
				if (!istype(Z)) continue
				del(Z)

		GameTick()
			if (prob(90) && has_started)
				new/mob/living/zombie(rand_loc(current_map, use_playerspawn=0))

			if (!has_started)
				start_timer--
				if (start_timer < 1)
					world << "<b>Zombies incoming!"
					world << "<b>Difficulty: [diff_name]"
					has_started = 1

			var/mob/living/player/P
			var/alive_players = 0
			for (P in get_players())
				if (P.gm_zombies_lives > 0) alive_players++

			if (alive_players < 1)
				game_time = 0

	itemmayhem
		name = "Item Mayhem"
		music_list = list('anotherpart_techno.mp3')
		can_spawn_items = 0
		can_drop_items = 0

		proc/give_random_item(mob/living/player)
			var/success = 0
			while (!success)
				var/typ = pick(typesof(/obj/item))
				var/obj/item/I

				if (typ != /obj/item)
					I = new typ()

					if (I.PlayerPick(player))
						if (I.Move(player))
							player.holding = I
							success = 1

					if (!success)
						del(I)

			if (success)
				player << "You have: [player.holding]"

		PlayerSpawn(mob/living/player)
			give_random_item(player)

		/*
		PlayerDeath(mob/living/player/victim, mob/living/player/killer)
			if (istype(killer))
				/*
				var/obj/item/I
				for (I in killer.contents)
					del(I)
				*/

				killer.holding = null

				give_random_item(killer)
		*/

		GameTick()
			var/mob/living/player/P
			for (P in get_alive_players())
				if (!P.inventory[1])
					give_random_item(P)

	itemmayhem_oneitem
		name = "One Item Deathmatch"
		music_list = list('anotherpart_techno.mp3')
		var/chosen_item
		can_spawn_items = 0
		can_drop_items = 0
		var/cant_pick = 0
		// Some useless things below here
		var/list/except_types = list(/obj/item/jumppass, /obj/item/soda, /obj/item/bullet, /obj/item/bullet/mega, /obj/item/antirocket, /obj/item/antiheli)

		BeforeStart()
			cant_pick = 0
			get_item()

		proc/give_item(mob/living/player)
			var/success = 0
			var/obj/item/I

			I = new chosen_item()

			if (I.PlayerPick(player))
				if (I.Move(player))
					player.holding = I
					success = 1

			if (!success)
				cant_pick = 1
				del(I)

		proc/get_item()
			var/success = 0
			while (!success)
				var/typ = pick(typesof(/obj/item))

				if (typ != /obj/item)
					if (except_types.Find(typ)) continue
					chosen_item = typ
					success = 1

			var/obj/item/I = new chosen_item()
			world << "Chosen Item: [I]"
			del(I)

		PlayerSpawn(mob/living/player)
			give_item(player)

		/*
		PlayerDeath(mob/living/player/victim, mob/living/player/killer)
			if (istype(killer))
				/*
				var/obj/item/I
				for (I in killer.contents)
					del(I)
				*/

				killer.holding = null

				give_random_item(killer)
		*/

		GameTick()
			if (cant_pick)
				get_item()
				cant_pick = 0

			var/mob/living/player/P
			for (P in get_alive_players())
				if (!P.inventory[1])
					give_item(P)

	lastmanalive
		name = "Last Stickman Alive"
		music_list = list('anotherpart_techno.mp3')
		var/mob/living/player/last_alive

		CanRespawn(mob/living/player/p)
			return 0

		GameTick()
			var/mob/living/player/P

			var/alive_players = 0
			for (P in get_alive_players())
				alive_players++
				last_alive = P

			if (alive_players < 2)
				game_time = 0

		GamemodeEnd()
			if (last_alive)
				var/mob/living/player/P

				var/alive_players = 0
				for (P in get_alive_players())
					alive_players++
					last_alive = P

				if (alive_players < 2)
					world << "<b>Winner: [last_alive]"

		bombrun
			name = "Bomb Run"

			GameTick()
				var/mob/living/player/P = rand_player_alive()
				if (P)
					new/obj/bombrun/bomb(P.loc)

				..()

	tag
		name = "Tag"

		var/tag_time = 20
		var/max_tag_time = 30
		var/list/died_players = list()
		var/has_first_tagger = 1

		GameTick()
			tag_time--

			if (!istype(tagger))
				tagger = rand_player_alive()
				tag_time = max_tag_time
				if (has_first_tagger)
					world << "<b>[tagger] is a first tagger!"
					has_first_tagger = 0
					tagger.color = "yellow"
				else
					world << "<b>[tagger] is now a tagger."
					tagger.color = "yellow"
			else
				tagger.color = "yellow"

			if (tag_time < 10)
				tagger << 'applause.wav'

			if (tag_time < 1)
				world << "<b>[tagger] took too long to tag"
				died_players.Add(tagger)
				tagger.Damage(tagger.health)

			var/mob/living/player/P

			var/alive_players = 0
			for (P in get_alive_players())
				alive_players++

			if (alive_players < 2)
				game_time = 0

		var/mob/living/player/tagger

		CanRespawn(mob/living/player/player)
			if (died_players.Find(player)) return 0
			return 1

		GamemodeStart()
			tag_time = max_tag_time
			died_players = list()
			has_first_tagger = 1

			tagger = rand_player_alive()
			if (tagger)
				world << "<b>[tagger] is a first tagger!"
				has_first_tagger = 0

		CanKill(mob/living/player/killer, mob/living/player/victim)
			if (tagger == killer) return 1
			return 0

		PlayerHit(mob/living/player/killer, mob/living/player/victim)
			if (tagger == killer)
				world << "<font color=cyan>[killer] tagged [victim]"
				tagger = victim
				tagger.color = "yellow"
				victim.Freeze()
				killer.color = "cyan"
				//tag_time = max_tag_time

		PlayerSpawn(mob/living/player)
			player.color = "cyan"

		PlayerDeath(mob/living/player/victim, mob/living/player/killer, reason)
			if (tagger == victim)
				tagger = rand_player_alive()
				world << "<b>[tagger] is now a tagger."
				tag_time = max_tag_time
				tagger.color = "yellow"

	// a tycoon-like gamemode
	factory
		name = "Factory"
		maps = list(4,2,1)

		PlayerJoin(mob/living/player/P)
			if (length(get_players()) == 1)
				P << "<b>You're playing Factory alone! to make this harder, we made robbers to always spawn."
				P << "<b>Kill any more robbers as fast as you can before you make your factory bankrupt"
				P << "<b>Let your factory reach to the maximum level to beat the game"


		GamemodeStart()
			game_time = 500


		PlayerSpawn(mob/living/player)
			spawn_factory(player)

			var/obj/facgm/factory/F = find_factory(player)
			if (F)
				player.loc = F.loc

		CanKill(mob/living/player/killer, mob/living/player/victim)
			if (istype(victim, /mob/living/fac_guest)) return 0
			if (istype(victim, /mob/living/fac_police)) return 0
			return ..()

		PlayerDeath(mob/living/player, mob/living/killer)
			var/obj/facgm/factory/F = find_factory(player)
			if (F)
				var/lm = rand(5,10)
				if (!killer || killer == player)
					player << "<b>You lost [lm] money for dying"
					F.money -= lm
					F.fmoney.play_sound('Money_36.wav')
					flick("fac_money_stole", F.fmoney)
					hearers(F) << "<i>[player] lost [lm] money"
					player << 'sfx_sounds_error13.wav'

				if (killer)
					if (killer != player)
						var/le = rand(1,F.money - (20 * F.level))
						if (le < 1)
							le = rand(1,10)
						killer << "<b>You gained [le] money for killing [player]"
						var/obj/facgm/factory/KF = find_factory(killer)
						if (KF)
							KF.fmoney.AddMoney(le)
							var lx = rand(1,F.xp + 5)
							KF.xp += lx
							F.xp -= lx
							if (F.xp < 1)
								F.xp = 0
							F.money -= le
							F.fmoney.play_sound('Money_36.wav')
							flick("fac_money_stole", F.fmoney)
							player << "<b>You paid [le] money to [killer] for being killed"
							hearers(F) << "<i>[player] paid [le] money to [killer]"
							player << 'sfx_sounds_error13.wav'


		proc/find_factory(mob/player)
			var/obj/facgm/factory/F

			for (F in world)
				if (F.owner == player)
					return F
			return null

		proc/spawn_factory(mob/player)
			if (find_factory(player)) return

			return new/obj/facgm/factory(rand_loc(current_map), player)

		BeforeEnd()
			var/obj/facgm/factory/F

			for (F in world)
				del(F)

			var/mob/living/fac_guest/FG

			for (FG in world)
				del(FG)

			var/mob/living/fac_robber/FR

			for (FR in world)
				del(FR)

			var/mob/living/fac_police/FP

			for (FP in world)
				del(FP)

		CanRespawn(mob/player)
			var/obj/facgm/factory/F = find_factory(player)
			if (F)
				if (F.bankrupt) return 0

			return 1

		GameTick()
			if (prob(50))
				new/mob/living/fac_guest(rand_loc(current_map))
			else if (prob(30) || length(get_players()) == 1)
				new/mob/living/fac_robber(rand_loc(current_map))

			var/obj/facgm/factory/P

			var/alive_players = 0
			for (P in world)
				if (!P.bankrupt)
					if (length(get_players()) == 1)
						if (P.level >= P.max_level)
							continue
					alive_players++

			if (alive_players < 1)
				game_time = 0

		// Factory Gamemode with Teams
		teamfactory
			name = "Team Factory"
			var/list/allowed_teams = list(TEAM_RED, TEAM_BLUE, TEAM_YELLOW, TEAM_GREEN)

			PlayerJoin(mob/living/player/P)
				if (P.team == TEAM_NONE)
					P.team = pick(allowed_teams)
				P.color = get_team_name(P.team)
				..()

			PlayerSpawn(mob/living/player)
				spawn_factory(player)

				var/obj/facgm/factory/F = find_factory(player)
				if (F)
					player.loc = F.loc
					F.color = player.color

			PlayerDeath(mob/living/player, mob/living/killer)
				..()


// FACTORY GAMEMODE
obj/facgm
	icon = 'gamemode_icons.dmi'
	factory
		icon_state = "factory_lvl1"

		var/mob/living/player/owner
		var/money = 200
		var/bankrupt = 0
		var/level = 1
		var/max_level = 5
		var/rates = 0
		var/xp = 0
		var/max_xp = 5

		var/obj/facgm/facmoney/fmoney

		New(loc, mob/owner)
			..()
			src.owner = owner
			color = owner.color
			MakeThings()
			Loop()
			LevelLoop()

		proc/MakeThings()
			fmoney = new(locate(x-1, y, z), src)

		proc/Populate()
			if (level == 3)
				new/mob/living/fac_police(loc, src)

		proc/LevelLoop()
			spawn while(1)
				if (bankrupt) break
				if (xp >= max_xp)
					if (level < max_level)
						level += 1
						max_xp += 5 * level
						xp = 0
						owner << "<b>Your factory has leveled up to [level]!"
						hearers(,src) << "<i>[owner]'s factory has leveled up to [level]"
						money += 500
						play_sound('sfx_sounds_powerup3.wav')
						owner.play_sound('sfx_sounds_fanfare3.wav')
						Populate()
				sleep(1)

		proc/Loop()
			spawn while(1)
				icon_state = "factory_lvl[level]"
				name = "[owner]'s Factory"
				if (money < 1 || !istype(owner))
					if (!bankrupt)
						money = 0
						bankrupt = 1
						explode(loc, take_fire=1)
						color = "gray"
						if (owner)
							world << "<b><font color=red>[owner]'s Factory is now bankrupt"
							owner.Damage(owner.health)
							owner << 'sfx_sounds_error5.wav'
							if (owner.client)
								owner.client.eye = src
								owner.sight = 0
						else
							spawn(30)
								del(src)
				sleep(1)

		Del()
			del(fmoney)

			..()


	facmoney
		name = "Factory Money"
		icon_state = "fac_money"

		var/obj/facgm/factory/fac

		New(loc, obj/factory)
			..()
			src.fac = factory
			Loop()
			MaptextLoop()

		proc/MaptextLoop()
			spawn while(1)
				//maptext = "Money: [fac.money]"
				//maptext_width = 200
				if (fac.bankrupt)
					icon_state = "fac_money_br"
					break
				sleep(1)

		proc/AddMoney(money)
			play_sound('Money_20.wav')
			if (!money)
				money = rand(10,50)
			fac.money += money
			flick("fac_money_get", src)

		proc/Loop()
			spawn while(1)
				if (fac.bankrupt) break
				if (prob(5 * fac.level))
					AddMoney()
				sleep(10)

var/list/fac_guest_names = list("Meker","Manny","Larry","Jake","Mike","Rick")
var/list/fac_robb_names = list("Bad Guy","Robbery","Robber","Fake Lawsuit","Karen")

mob/living
	fac_guest
		icon = 'gamemode_icons.dmi'
		icon_state = "fac_guest"
		is_undamagable = 1
		var/trust_points = 100
		blind_state = "fac_guest_blind"
		normal_state = "fac_guest"
		frozen_state = "fguest_frozen"
		frozen_start_state = "fguest_froze_start"
		frozen_broken_state = "fguest_froze_broke"
		var/obj/facgm/factory/target
		var/rate_level = 1
		var/special = 0
		is_enemy()
			return 0

		Freeze()
			if (!is_frozen)
				trust_points -= rand(10,30)
				hearers(,src) << "<i>[src] has lost some trust"
			..()

		Blindfold(v)
			if (v && !is_blind)
				trust_points -= rand(10,30)
				hearers(,src) << "<i>[src] has lost some trust"
			..()

		var/list/used_factories = list()

		New()
			..()
			trust_points = rand(30,80)
			name = pick(fac_guest_names)
			special = prob(5)
			if (special)
				world << "<b><font color=green>[src] the special guest has entered the factory!"
				color = "yellow"
				trust_points = rand(80,100)
			alpha = 0
			animate(src, alpha=255, time=5)
			spawn while(1)
				sleep(rand(1,10))
				AITick()

		proc/Tell(mob/player, msg)
			player.play_sound('Phone2.wav')
			player << "<b>[src]:</b> [msg]"

		proc/AITick()
			if (is_blind) return
			if (is_frozen) return
			trust_points--
			if (trust_points < 1)
				//world << "<i>[src] left the factory"
				if (special)
					world << "<b><font color=green>[src] the special guest has left the factory"
				walk(src, 0)
				animate(src, alpha=0, time=5)
				sleep(5)
				del(src)
				return

			/*
			if (prob(6))
				// Forget about things lol
				used_factories = list()
			*/


			if (!target)
				target = find_factory()

			var/obj/facgm/factory/F = target

			if (target && !used_factories.Find(target))
				if (target.bankrupt)
					target = null
					return

				walk_to(src, F)
				sleep(rand(10,20))
				var/v = rand(1,3)
				if (isnull(target)) return
				if (v == 1)
					flick("fac_guest_think", src)
				else if (v == 2)
					var/list/msgs = list("This factory is giving me good things, i like it!", "Nice thing we got here.",
										"Ahem, Need some donation?","Better not lose so many money.","Good progress.")
					flick("fac_guest_give", src)
					var/moni = rand(5,100)
					if (special)
						moni = rand(100,600)
					F.fmoney.AddMoney(moni)
					trust_points += rand(10,30)
					if (!special)
						used_factories.Add(F)
					Tell(F.owner, pick(msgs))
					F.owner << "<i>[src] gave you [moni] money"
					F.rates++
					if (special)
						F.xp += rand(8,20)
					else
						F.xp += rand(1,5)
					target = null
					if (prob(5))
						trust_points = 0
				else if (v == 3)
					if (!prob(10 * F.level))
						v = rand(1,2)
						return
					var/list/msgs = list("I would give a rate on it later.", "Oh, nice, but i would rather see other ones.",
										"You know, there's a better factory in this place here. but i would think of that.",
										"Weak Factories = Need Better One")
					flick("fac_guest_nvm", src)
					used_factories.Add(F)
					if (special)
						trust_points -= rand(20,90)
					else
						trust_points -= rand(5,20)
					Tell(F.owner, pick(msgs))
					target = null
			else
				if (!prob(30))
					walk_rand(src)
				else
					walk(src,0)

		proc/find_factory()
			var/obj/facgm/factory/F

			for (F in orange(15, src))
				if (F.bankrupt) continue
				if (special)
					if (prob(50 * F.level))
						return F
				else
					if (prob(20 * F.level))
						return F
			return null

	fac_robber
		icon = 'gamemode_icons.dmi'
		icon_state = "fac_robber"
		name = "Robber"
		var/rate_level = 1
		//is_undamagable = 1

		step_size = 16

		Freeze()
			return

		Unfreeze()
			return

		Blindfold()
			return

		Death(mob/living/player/killer)
			var/gamemode/factory/FG = GM
			var/obj/facgm/factory/F
			if (istype(killer))
				F = FG.find_factory(killer)
			else if (istype(killer, /mob/living/fac_police))
				F = killer?:fac

			if (istype(F))
				var/moni = rand(20,100)
				F.fmoney.AddMoney(moni)
				F.owner << "<b>You gained [moni] money for killing [src] the robber"
			spawn()
				animate(src, alpha=0, time=5)
				sleep(5)
				del(src)

		Hit()
			play_sound('sfx_sounds_impact11.wav')

		New()
			..()
			name = pick(fac_robb_names)
			rate_level = rand(1,40)
			alpha = 0
			animate(src, alpha=255, time=5)
			spawn while(1)
				sleep(rand(1,5))
				AITick()

		proc/find_factory()
			var/obj/facgm/factory/F

			for (F in orange(10, src))
				if (F.bankrupt) continue
				if (prob(5 * F.level))
					return F
				if (F.rates >= rate_level)
					return F
			return null

		proc/AITick()
			var/obj/facgm/factory/F = find_factory()

			var/mob/living/fac_police/P

			for (P in orange(5, src))
				// Retreat!
				walk_away(src, P)
				return

			if (F)
				walk_to(src, F)
				sleep(5)
				if (isnull(F)) return
				if (rand(0,1))
					world << "<b><font color=red>[F.owner]'s money has been stolen by [src]!"
					F.owner << 'sfx_sounds_error5.wav'
					F.play_sound(pick('sfx_sounds_negative1.wav','sfx_sounds_negative2.wav'))
					F.money -= rand(100, 300) * F.level
					walk(src, 0)
					animate(src, alpha=0, time=5)
					sleep(5)
					del(src)
			else
				walk_rand(src)

	fac_police
		icon = 'gamemode_icons.dmi'
		icon_state = "police"
		is_undamagable = 1


		name = "Police"

		step_size = 18

		New(loc, factory)
			..()
			fac = factory
			Loop()

		Freeze()
			return

		Unfreeze()
			return

		Blindfold()
			return

		var/mob/living/fac_robber/target

		is_enemy()
			return 0

		var/obj/facgm/factory/fac

		proc/Loop()
			spawn while(1)
				sleep(5)
				AITick()

		LeftAttack()
			flick("police_shoot", src)
			play_sound('sfx_weapon_shotgun1.wav')

			var/mob/living/fac_robber/R

			for (R in orange(6, src))
				R.Damage(30)

		proc/AITick()
			var/mob/living/fac_robber/R

			if (!fac || fac.bankrupt)
				del(src)
				return

			if (!target)
				for (R in orange(8, src))
					if (rand(0,1))
						target = R

			if (target)
				if (!(target in orange(8, src)))
					target = null
					return
				walk_to(src, target)
				LeftAttack()
			else
				if (!(fac in orange(2, src)))
					if (prob(20))
						loc = fac.loc
						walk(src, 0)
					else
						walk_rand(src)
				else
					walk_to(src, fac)

// ZOMBIES GAMEMODE
var/list/zombie_names = list("Larry","Brain","Zombie","WindowsVista","PlantEater","BRAINS","BSOD","Infection","Zombified")

mob/living
	var
		gm_zombies_lives = 3
	zombie
		icon = 'player.dmi'
		icon_state = "zombie"
		respawn_time = 1000
		var/mob/living/target
		name = "Zombie"
		team = TEAM_GREEN
		var/difficulty = 1

		Blindfold(v=1)
			if (v && !is_dead)
				blind_time = 5
				sight |= BLIND
				icon_state = "zombie_blind"
				can_move = 0
				is_blind = 1
			else
				sight &= ~BLIND
				if (!is_dead) icon_state = ""
				can_move = 1
				is_blind = 0

		Freeze()
			return

		Unfreeze()
			return

		New()
			..()
			name = pick(zombie_names)
			difficulty = GM:difficulty
			spawn while(1)
				if (GM:difficulty == 1)
					sleep(rand(10,30))
				else if (GM:difficulty == 2)
					sleep(rand(5,10))
				else if (GM:difficulty == 3)
					sleep(rand(1,5))
				else
					sleep(rand(0.2,0.9))
				AITick()

		Hit(mob/killer)
			flick("zombie_hurt",src)
			step(src, turn(dir, 90), 3)
			//var/id = rand(10,37)
			play_sound('punches/hit33.mp3.mp3')

		Death(mob/killer)
			icon_state = "zombie_death"
			//var/id = rand(10,37)
			play_sound('punches/hit33.mp3.mp3')
			density = 0
			spawn(20)
				del(src)


			if (ismob(killer) && killer != src)
				if (istype(killer, /mob/living/zombie)) return
				world << "<b><font color=green>[killer] killed [src]"
				killer.kills += 1
				GM:zombies_killed += 1

		proc/AITick()
			target = null
			var/mob/living/M

			for (M in oview(2,src))
				if (M.health < 1) continue
				if (!is_enemy(M)) continue
				target = M
				break

			if (target)
				walk_to(src, target)
				LeftAttack()
			else
				walk_rand(src)

		LeftAttack()
			if (health < 1) return
			flick("zombie_punch", src)

			var/mob/living/M
			for (M in oview(0, src))
				if (difficulty == 1)
					M.Damage(rand(10,20), src)
				if (difficulty == 2)
					M.Damage(rand(30,40), src)
				if (difficulty == 3)
					M.Damage(rand(50,90), src)
				if (difficulty == 4)
					M.Damage(rand(80,90), src)