#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta>
#define CC_COLORS_TYPE CC_COLORS_SHORT
#include <cromchat>
#include <fun>

new menu_treino[3], menu_max_pl[4], menu_jail_time[4]
new name[33];

new bool:menu_respawn, bool:menu_bala, bool:menu_ff
new bool:treino, bool:on_2
new Float:jail_sec

new modo_treino, treino_pl, jail_time, bot_hp
const JAIL_TASK = (1<<0)

public plugin_init() {
   register_plugin("db: Modo Treino", "3.0", "-LeQuiM-")

//Modo Treino
   modo_treino = register_cvar("db_treino", "1", FCVAR_SERVER)
   treino_pl = register_cvar("db_treino_pl", "4", FCVAR_SERVER)
   jail_time = register_cvar("db_treino_jail_time", "8.3", FCVAR_SERVER)
   bot_hp = register_cvar("db_bot_hp", "6969", FCVAR_SERVER)
   set_cvar_num("mp_infinite_ammo", 0)

   register_event("TeamInfo", "modoTreino", "a")
   register_concmd("menu_modotreino", "menu_modotreino", ADMIN_KICK)
   register_clcmd("say /treino", "menu_modotreino", ADMIN_KICK)

   treino = false

//Open Jail
   register_concmd("open_jail", "openJail", ADMIN_KICK, "Abrir/Fechar Jaula em mapas de Surf")

// Ganhar HP ao Matar
   register_event("DeathMsg", "deathEvent", "a")
}

// MENU
public menu_modotreino(id) {
	if(!has_flag(id, "c")) {
		client_print(id, print_center, "db-info: você não possui acesso")
		client_cmd(id, "spk ^"access denied^"")
		return PLUGIN_HANDLED
	}

	new menu = menu_create("\rdb: \rModo Treino Menu  \yby -LeQuiM-^n", "menu_modotreino_handler")

	switch(menu_treino[id]) {
	   case 0: menu_additem(menu, "\yModo Treino  ^t^t[\rON\y]")
		case 1: menu_additem(menu, "\yModo Treino  ^t^t[\dOFF\y]")
		case 2: menu_additem(menu, "\yModo Treino  ^t^t[\rSEMPRE ON\y]")
	}

	switch(menu_respawn) {
		case 0: menu_additem(menu, "\wRespawn       ^t^t\y[\rON\y]")
		case 1: menu_additem(menu, "\wRespawn       ^t^t\y[\dOFF\y]")
	}

	switch(menu_bala) {
		case 0: menu_additem(menu, "\wBala Inifita^t^t^t^t \y[\rON\y]")
		case 1: menu_additem(menu, "\wBala Inifita^t^t^t^t \y[\dOFF\y]")
	}

	switch(menu_ff) {
		case 0: menu_additem(menu, "\wFriendly Fire^t^t \y[\rON\y]")
		case 1: menu_additem(menu, "\wFriendly Fire^t^t \y[\dOFF\y]")
	}

	switch(menu_max_pl[id]) {
		case 0: menu_additem(menu, "\wMax. Players^t^t^t\y[\r 4 \y]")
		case 1: menu_additem(menu, "\wMax. Players^t^t^t\y[\r 6 \y]")
		case 2: menu_additem(menu, "\wMax. Players^t^t^t\y[\r 8 \y]")
		case 3: menu_additem(menu, "\wMax. Players^t^t^t\y[\r10\y]")
	}

	switch(menu_jail_time[id]) {
		case 0: menu_additem(menu, "\wAbrir Jaula    ^t^t\y[\r5 seg\y]")
		case 1: menu_additem(menu, "\wAbrir Jaula    ^t^t\y[\r10 seg\y]")
		case 2: menu_additem(menu, "\wAbrir Jaula    ^t^t\y[\r15 seg\y]")
		case 3: menu_additem(menu, "\wAbrir Jaula    ^t^t\y[\dOFF\y]")
	}
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

new n_bala, n_ff, n_resp, n_round, n_fade

public menu_modotreino_handler(id, menu, item) {
   get_user_name(id, name, 31);

   if (item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	} else if (item == 0) {
   	switch(menu_treino[id]) {
   		case 0: {
            menu_treino[id]++
            set_pcvar_num(modo_treino, 0)
            modoTreino()
         } case 1: {
            menu_treino[id]++
            set_pcvar_num(modo_treino, 2)
            modoTreino()

         } case 2: {
            menu_treino[id] = 0
            set_pcvar_num(modo_treino, 1)
            modoTreino()
         }
   	}
	} else if (item == 1) {
   	switch(menu_respawn) {
   		case 0: {
            menu_respawn++
            n_resp=-1
            n_round=-1
            n_fade=-1
            set_cvar_num("mp_forcerespawn", 0)
            set_cvar_num("mp_round_infinite", 0)
            set_cvar_num("mp_fadetoblack", 0)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rRespawn !npara !rDesativado", name)
         } case 1: {
            menu_respawn--
            n_resp=3
            n_round=1
            n_fade=2
            set_cvar_num("mp_forcerespawn", 3)
            set_cvar_num("mp_round_infinite", 1)
            set_cvar_num("mp_fadetoblack", 2)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rRespawn !npara !gAtivado", name)
         }
   	}
	} else if (item == 2) {
   	switch(menu_bala) {
   		case 0: {
            menu_bala++
            n_bala=-1
            set_cvar_num("mp_infinite_ammo", 2)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rBala Infinita !npara !rDesativado", name)
         } case 1: {
            menu_bala--
            n_bala=1
            set_cvar_num("mp_infinite_ammo", 1)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rBala Infinita !npara !gAtivado", name)
         }
   	}
	} else if (item == 3) {
   	switch(menu_ff) {
   		case 0: {
            menu_ff++
            n_ff=-1
            set_cvar_num("mp_friendlyfire", 0)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rFriendly Fire !npara !rDesativado", name)
         } case 1: {
            menu_ff--
            n_ff=1
            set_cvar_num("mp_friendlyfire", 1)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rFriendly Fire !npara !gAtivado", name)
         }
   	}
	} else if (item == 4) {
   	switch(menu_max_pl[id]) {
   		case 0: {
            menu_max_pl[id]++
            set_pcvar_num(treino_pl, 6)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rMax. de Players !npara !g6", name)
         } case 1: {
            menu_max_pl[id]++
            set_pcvar_num(treino_pl, 8)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rMax. de Players !npara !g8", name)
         } case 2: {
            menu_max_pl[id]++
            set_pcvar_num(treino_pl, 10)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rMax. de Players !npara !g10", name)
         } case 3: {
            menu_max_pl[id] = 0
            set_pcvar_num(treino_pl, 4)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rMax. de Players !npara !g4", name)
         }
   	}
	} else if (item == 5) {
      switch(menu_jail_time[id]) {
      	case 0: {
            menu_jail_time[id]++
            set_pcvar_float(jail_time, 13.3)
            change_task(JAIL_TASK, 13.3)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rTempo da Jaula !npara !g10 seg", name)
         } case 1: {
            menu_jail_time[id]++
            set_pcvar_float(jail_time, 18.3)
            change_task(JAIL_TASK, 18.3)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rTempo da Jaula !npara !g15 seg", name)
         } case 2: {
            menu_jail_time[id]++
            remove_task(JAIL_TASK)
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rTempo da Jaula !npara !rDesativado", name)
         } case 3: {
            menu_jail_time[id] = 0
            set_pcvar_float(jail_time, 8.3)
            set_task(8.3, "open_jail", JAIL_TASK, _, _, "b")
            client_print_color(0, print_chat, "!gdb-treino: !n%s alterou !rTempo da Jaula !npara !g5 seg", name)
         }
      }
   }
   menu_destroy(menu)
   menu_modotreino(id)
   return PLUGIN_HANDLED
}


public modoTreino() {
   static xPlayers[32]
   new n_TR, n_CT
   new min_pl = get_pcvar_num(treino_pl)
   new n_pl, id

   jail_sec = get_pcvar_float(jail_time)

   //Ganhar colete no começo do Round
   get_players(xPlayers, n_pl, "a")
   for (id = 0; id < n_pl; id++) {
      if (is_user_bot(xPlayers[id])) set_user_health(xPlayers[id], get_pcvar_num(bot_hp))
      give_item(xPlayers[id], "item_assaultsuit")
	}

   get_players(xPlayers, n_TR, "ce", "TERRORIST")
   get_players(xPlayers, n_CT, "ce", "CT")

   // DESATIVAR TREINO
   if ((n_TR += n_CT) >= min_pl && get_pcvar_num(modo_treino) != 2 || get_pcvar_num(modo_treino) == 0) {
      if (!treino) return

      set_cvar_num("mp_infinite_ammo", 2)
      set_cvar_num("mp_friendlyfire", 0)
      set_cvar_num("mp_forcerespawn", 0)
      set_cvar_num("mp_round_infinite", 0)
      set_cvar_num("mp_fadetoblack", 0)

      set_cvar_num("mp_scoreboard_showhealth", 5)
      unpause("ac", "statsx.amxx")
      unpause("ac", "reconnect_features.amxx")
      pause("ac", "db_checkpoint_treino.amxx")

      remove_task(JAIL_TASK)

      set_hudmessage(255/*Red*/, 0/*Green*/, 0/*Blue*/, -1.0/*x*/, 0.7/*y*/, 0/*fx*/, 0.0/*fx time*/, 4.0/*hold time*/, 0.5/*fade in*/, 1.0/*fade out*/, -1/*chan*/)
      show_hudmessage(0, "Modo Treino D E S A T I V A D O ^n^n^nBala Infinita: [  ] Ativada  ^t^t^t[X] Desativada ^n   Respawn:   [  ] Ativado  ^t^t^t[X] Desativado ^n    Jaula:     [  ] Liberada ^t^t^t[X] Bloqueada", min_pl)
      show_hudmessage(0, "Modo Treino D E S A T I V A D O ^n^n^nBala Infinita: [  ] Ativada  ^t^t^t[X] Desativada ^n   Respawn:   [  ] Ativado  ^t^t^t[X] Desativado ^n    Jaula:     [  ] Liberada ^t^t^t[X] Bloqueada", min_pl)
      if (get_pcvar_num(modo_treino) == 0)
         client_print_color(0, print_chat, "!gdb-treino: !nModo Treino !rDesativado !npor %s", name)
      else
         client_print_color(0, print_chat, "!gdb-treino: !nPartida com!g %i+ !njogadores. !rModo Treino: !wDesativado!", min_pl);

      on_2 = false
      treino = false
   // ATIVAR TREINO
   } else {
      if (treino) return

      set_cvar_num("mp_infinite_ammo", (n_bala < 0 ? 0 : 1))
      set_cvar_num("mp_friendlyfire", (n_ff < 0 ? 0 : 1))
      set_cvar_num("mp_forcerespawn", (n_resp < 0 ? 0 : 3))
      set_cvar_num("mp_round_infinite", (n_round < 0 ? 0 : 1))
      set_cvar_num("mp_fadetoblack", (n_fade < 0 ? 0 : 2))

      set_cvar_num("mp_scoreboard_showhealth", 4)
      pause("ac", "statsx.amxx")
      pause("ac", "reconnect_features.amxx")
      unpause("ac", "db_checkpoint_treino.amxx")

      if (task_exists(JAIL_TASK)) remove_task(JAIL_TASK)

      set_task(jail_sec, "open_jail", JAIL_TASK, _, _, "b")

      if (get_pcvar_num(modo_treino) == 2) {
         if (on_2) return
         client_print_color(0, print_chat, "!gdb-treino: !nModo Treino !gAtivado !npor %s", name)
         on_2 = true
      } else {
         set_hudmessage(25/*Red*/, 255/*Green*/, 25/*Blue*/, -1.0/*x*/, 0.7/*y*/, 0/*fx*/, 0.0/*fx time*/, 4.0/*hold time*/, 0.5/*fade in*/, 1.0/*fade out*/, -1/*chan*/)
         show_hudmessage(0, "Modo Treino A T I V A D O ^n^n^nBala Infinita: [X] Ativada  ^t^t^t[  ] Desativada ^n   Respawn:   [X] Ativado  ^t^t^t[  ] Desativado ^n    Jaula:     [X] Liberada ^t^t^t[  ] Bloqueada", min_pl)
         show_hudmessage(0, "Modo Treino A T I V A D O ^n^n^nBala Infinita: [X] Ativada  ^t^t^t[  ] Desativada ^n   Respawn:   [X] Ativado  ^t^t^t[  ] Desativado ^n    Jaula:     [X] Liberada ^t^t^t[  ] Bloqueada", min_pl)
         client_print_color(0, print_chat, "!gdb-treino: !nPartida com menos de!r %d !njogadores. !rModo Treino: !gAtivado!", min_pl)
      }

      get_players(xPlayers, n_pl)
      for (id = 0; id < n_pl; id++) {
			if (!is_user_alive(xPlayers[id]) && get_user_team(xPlayers[id]) != 3 && get_user_team(xPlayers[id]) != 0) ExecuteHamB(Ham_CS_RoundRespawn, xPlayers[id])
		}
      treino = true
   }
}

// Ganhar HP ao matar //
public deathEvent() {
   static i_killer
   new i_vict[33]

   get_user_name(read_data(1), name, 31)
   get_user_name(read_data(2), i_vict, 31)

   if (!treino || equali(name, i_vict)) return

   i_killer = read_data(1)

   set_pev(i_killer, pev_health, pev(i_killer, pev_health) + (read_data(3) ? 35.0 : 20.0))

   set_dhudmessage(25/*Red*/, 255/*Green*/, 25/*Blue*/, -1.0/*x*/, 0.35/*y*/, 0/*fx*/, 0.0/*fx time*/, 2.5/*hold time*/, 0.5/*fade in*/, 1.0/*fade out*/)

   new iHp = get_user_health(i_killer)

   if (iHp > 255) {
      set_user_health(i_killer, 255)
      client_print_color(0, print_chat, "!gdb-treino: !n%s alcançou a vida Maxima: !g255 HP!", name)
   } else if (read_data(3)) {
      show_dhudmessage(i_killer, "HeadShot: +35 HP")
      client_print_color(0, print_chat, "!gdb-treino: !n%s ganhou !g+35 HP !npor matar com !rHeadShot!", name)
   } else {
      show_dhudmessage(i_killer, "Kill: +20 HP")
      client_print_color(0, print_chat, "!gdb-treino: !n%s ganhou !g+20 HP !npor !rmatar !num Player!", name)
   }
}

// Abrir Jaula de tempo em tempo //
new entlist[][] = {"func_button", "trigger_multiple", "trigger_once"}
new bool:open_adm = false

public openJail(id) {
	open_adm = true
	open_jail()
	return PLUGIN_HANDLED
}

public open_jail_cmd(id, level, cid) {
   if(!cmd_access(id, level, cid, 0))
   return PLUGIN_HANDLED

   new map[32]
   get_mapname(map,31)

   if(!equali(map, "surf", 4)) {
      client_print_color(id, print_chat, "!rdb-treino: {!nMapa atual não começa com 'surf'\r}")
      return PLUGIN_HANDLED
   } else if(!open_jail()) {
      client_print_color(0, print_chat, "!rdb-treino: {!nMapa não possui Jaula para abrir\r}")
   }
   return PLUGIN_HANDLED
}

new msg
public open_jail() {
   new ent, target[32], ent2
   for(new i = 0; i < sizeof entlist; i++) {
      ent = 0
      ent2 = 0
      while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", entlist[i]))) {
         if(pev_valid(ent)) {
            //dllfunc(DLLFunc_Touch,ent,id)
            pev(ent,pev_target,target,31)
            while((ent2 = engfunc(EngFunc_FindEntityByString, ent2, "targetname", target))) {
               dllfunc(DLLFunc_Use, ent2)

               if (get_playersnum() <= 2 || open_adm) {open_adm = false; return PLUGIN_HANDLED;}
               msg++
               if (get_pcvar_float(jail_time) < 10.0) {
                  if (msg % 2 == 0) {client_print_color(0, print_chat, "!gdb-treino: !rLive !nacionado - Jaula foi !gaberta!"); msg = 0;}
               } else {
                  client_print_color(0, print_chat, "!gdb-treino: !rLive !nacionado - Jaula foi !gaberta!"); msg = 0
               }
               return PLUGIN_HANDLED
            }
         }
      }
   }
   return PLUGIN_CONTINUE
}
