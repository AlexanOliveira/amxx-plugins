#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cromchat>

#define FPS_MAX 131

new illegal[33];
new fps_limiter

public plugin_init(){
   register_plugin("db: FPS Limiter", "2.0", "-LeQuiM-");
   RegisterHam(Ham_Spawn, "player", "plrSpawned", 1);

   fps_limiter = register_cvar("db_fps", "0")
}

public plrSpawned(id) if(!is_user_bot(id)) set_task(5.0, "checkfpstask", id+256, _, _, "b");

public client_putinserver(id) illegal[id] = 0;

public checkfpstask(taskid){
	new id = taskid - 256;


	if (get_pcvar_num(fps_limiter) == 0)
	   return
	else if (is_user_alive(id)) {
	   query_client_cvar(id, "developer", "checkdev")
	   query_client_cvar(id, "fps_override", "checkover")
	   query_client_cvar(id, "fps_max", "checkfps")
	}else
	   remove_task(taskid);
}

new dev;
new over;

public checkdev(id, const cvar[], const value[]) { dev = str_to_num(value);}
public checkover(id, const cvar[], const value[]) { over = str_to_num(value);}

public checkfps(id, const cvar[], const value[]) {
   new Float:fps = str_to_float(value);
   if(fps > FPS_MAX) {
       if ((dev > 0) || (over > 0)) {
          illegal[id]++;
          if(illegal[id] > 3) {
             new name[32]; get_user_name(id, name, 31);
             client_cmd(id, "fps_override 0")
             client_cmd(id, "developer 0")
             client_print_color(0, print_team_red, "^4db-info: ^3%s ^1foi ^3kickado ^1por usar FPS maior que^4 131", name, FPS_MAX)
             server_cmd("kick #%d FPS maior que 131!", get_user_userid(id), FPS_MAX)
          } else {
             client_cmd(id, "fps_override 0")
             client_cmd(id, "developer 0")
             client_print_color(id, print_team_red, "^4db-info: ^1Não é permitido usar FPS maior que^4 131^1 - se alterar novamente será ^3kickado!", FPS_MAX)
          }
       }
   }
}

