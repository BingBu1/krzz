#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <kr_core>
#include <xp_module>
// #include <zombieplague>

#define FLAG_ACESS 	ADMIN_RCON

/*================================================================================
[Task e Defines do Boss]
=================================================================================*/
#define LIGHTZ_MODEL "models/CSO_Lightzombie/lightzombieboss.mdl"
#define BOMB_MODDEL "models/CSO_Lightzombie/lightzombieboss_bomb.mdl"
#define ATTACK_TENTACLE1 "models/CSO_Lightzombie/ef_tentacle_sign.mdl"
#define ATTACK_TENTACLE2 "models/CSO_Lightzombie/ef_tentacle.mdl"
new const LIGHTZ_HPSPR[] = "sprites/CSO_Lightzombie/LightZombie_Boss_HP.spr"


#define LIGHTZ_CLASS "LightZombie"
#define LIGHTZ_HEALTH 200000.0 		// HP BOSS

#define HEALTH_OFFSET 0.0		// Don't Edit 

#define ROUND_START "CSO_LightZombie/Round_boss/Scenario_Ready.mp3"
#define ROUND_MUSIC "CSO_LightZombie/Round_boss/Scenario_Fight_v2.mp3"
#define ROUND_WIN "CSO_LightZombie/death_win_humans.wav"

/*================================================================================
[Sons e Animse e States]
=================================================================================*/
new const CSO_Lightzombie[17][] = 
{
	"CSO_LightZombie/appear.wav",
	"CSO_LightZombie/appear_end.wav",
	"CSO_LightZombie/laugh.wav",
	"CSO_LightZombie/zbs_attack1.wav",
	"CSO_LightZombie/zbs_attack2.wav",
	"CSO_LightZombie/zbs_bomb_nuke.wav",
	"CSO_LightZombie/zbs_bomb_nuke_after.wav",
	"CSO_LightZombie/zbs_bomb_nuke_after_idle1.wav",
	"CSO_LightZombie/zbs_bomb_nuke_after_end.wav",
	"CSO_LightZombie/zombi_bomb_crazy.wav",
	"CSO_LightZombie/zombi_bomb_jump.wav",
	"CSO_LightZombie/zombi_bomb_jump_idle.wav",
	"CSO_LightZombie/zombi_bomb_normal1.wav",
	"CSO_LightZombie/zombi_bomb_normal2.wav",
	"CSO_LightZombie/death.wav",	
	"CSO_LightZombie/walk1.wav",
	"CSO_LightZombie/walk2.wav"
}
enum
{
	ANIM_DUMMY = 0,
	ANIM_APPEAR,
	ANIM_APPEAR_END,
	ANIM_IDLE,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_INVISIBILITY,
	ANIM_DEATH,
	ANIM_ATTACK1,
	ANIM_ATTACK3,
	ANIM_ATTACK2,
	ANIM_BOMB_NUKE,
	ANIM_BOMB_NUKE_IDLE,
	ANIM_BOMB_NUKE_EXPLOSION,
	ANIM_BOMB_NUKE_CRAZY,
	ANIM_BOMB_NUKE_END,
	ANIM_ATK_BOMB_NORMAL,
	ANIM_ATK_BOMB_NORMAL2,
	ANIM_BOMB_JUMP,
	ANIM_BOMB_JUMP_IDLE,
	ANIM_BOMB_JUMP_END,
	ANIM_BOMB_CRAZY_START,
	ANIM_BOMB_CRAZY_LOOP,
	ANIM_BOMB_CRAZY_LOOP2,
	ANIM_BOMB_CRAZY_LOOP3,
	ANIM_BOMB_CRAZY_END
}
enum 
{
	STATE_APPEAR = 0,
	STATE_APPEAR_IDLE,
	STATE_APPEAR_JUMP,
	STATE_APPEAR_END,
	STATE_IDLE,
	STATE_SEARCHING,
	STATE_CHASE,
	STATE_ATTACK1,
	STATE_ATTACK2,
	STATE_ATTACK3,
	STATE_BOMB_NUKE,
	STATE_JUMP,
	STATE_JUMP_FLY,
	STATE_JUMP_END,
	STATE_ATK_BOMB_NORMAL1,
	STATE_ATK_BOMB_NORMAL2,
	STATE_INVISIVILITY,
	STATE_BOMB_CRAZY,
	STATE_TENTACLES,
	STATE_DEATH
}
/*================================================================================
[Defines do NPC]
=================================================================================*/
#define TASK_APPEAR 1
#define TASK_ATTACKS 2
#define TASK_ATTACK_SPECIAl 3
#define TASK_ATTACK_IVISIVEL 4
#define TASK_DEATH 5

/*================================================================================
[Cvars do boss]
=================================================================================*/
new boss_state, Lightz_Ent, g_FootStep, bool: y_start_npc, bool: Boss_Create_Fix, bool: Fix_Config_Server
new Float: Time1, Float: Time2, Float: Time3, Float: Time4, Float: Time5, bool: invisibilidade

//Adicionais
new g_MsgScreenShake, Camera, Cut1, g_MaxPlayers, exp_spr_id, m_iBlood[2], y_hpbar, Bomba, bool:Fix_Death_Boss
new g_damagedealt[33], cvar_dmg_ap_allow, cvar_ammodamage//, cvar_ammo_quantity, cvar_ammo_killed

/*================================================================================
[Plugin Init]
=================================================================================*/
public plugin_init() 
{
	register_plugin("Light Zombie Fix","4.6.2","Skill Von Dragon")	
		
	// register_think(LIGHTZ_CLASS, "Fw_Lightz_Think")
	register_touch("Bomb_Zomibe_1", "*", "Bomb_1_Touch")
	
	//System Ammor Packs
	cvar_dmg_ap_allow = register_cvar("zp_lightz_dmg_ap_reward_allow", "1")		// Ganhar Ammo Packs Por Dano
	cvar_ammodamage = register_cvar("zp_lightz_dmg_for_reward", "1000") 			// Dmg Necessario Para Ganhar Ammo Packs
	// cvar_ammo_quantity  = register_cvar("zp_lightz_reward_ap_quantity", "2") 		// Quantia de Ammo Packs que ira ganhar por dano	
	// cvar_ammo_killed = register_cvar("zp_lightz_kill_reward_ap_quantity", "1000")	// Quantia de Ammo Packs que ira ganhar ao matar o Boss
	
	// set_task(30.0, "Creator_Plugin", 100, _, _, "b")
		
	g_MaxPlayers = get_maxplayers()
	g_MsgScreenShake = get_user_msgid("ScreenShake")

	RegisterHam(Ham_Killed, "info_target", "Lightz_Killed")
	RegisterHam(Ham_TakeDamage, "info_target", "fw_Lightz_Tracer_DMG", 1)
	RegisterHam(Ham_TakeDamage, "info_target", "fw_Lightz_Tracer_DMG_Pre")
}

public plugin_natives(){
	register_native("Create_Boss_Boom" , "native_Create_Boss_Boom")
}

public native_Create_Boss_Boom(id , nums){
	new Float:SpawnOrigin[3]
	get_array_f(1 , SpawnOrigin , 3)
	Game_Start(SpawnOrigin)
}


/*================================================================================
[Plugin Precache]
=================================================================================*/
public plugin_precache()
{
	//Preacache do Lightz 
	engfunc(EngFunc_PrecacheModel, LIGHTZ_MODEL)
	engfunc(EngFunc_PrecacheModel, BOMB_MODDEL)
	engfunc(EngFunc_PrecacheModel, LIGHTZ_HPSPR)
	precache_model(ATTACK_TENTACLE1)
	precache_model(ATTACK_TENTACLE2)

	precache_model("models/CSO_Lightzombie/camera.mdl")
				
	//Precache dos Sons do Lightz
	for(new i = 0; i < sizeof(CSO_Lightzombie); i++)
		UTIL_Precache_Sound(CSO_Lightzombie[i])
		
	//Precache Music Round 
	// engfunc(EngFunc_PrecacheSound, ROUND_START)	
	// engfunc(EngFunc_PrecacheSound, ROUND_MUSIC)			
	// engfunc(EngFunc_PrecacheSound, ROUND_WIN)	
	UTIL_Precache_Sound(ROUND_WIN)
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
	exp_spr_id = precache_model("sprites/zerogxplode.spr")
}
/*================================================================================
[Round Boss]
=================================================================================*/
public Round_boss(id)
{
	new data[1]
	data[0] = id
	PlaySound(0, ROUND_START)
	set_task(19.0, "Round_Music_Boss")
	// set_task(21.0, "Camera_boss")
	set_task(1.0, "Game_Start",_,data,1)
	Camera = 0
}
public Round_Music_Boss() 
{
	PlaySound(0, ROUND_MUSIC)
	set_task(113.0, "Round_Music_Boss", 1000, _, _, "b")
}
/*================================================================================
[Criar Camera do Boss]
=================================================================================*/
public Camera_boss()
{
	if(pev_valid(Cut1)) remove_entity(Cut1)	
	
	new Float:Origin[3], Float:Angles[3]

	// Watching Ent
	static Watch; Watch = create_entity("info_target")
	
	if(Camera == 0)
	{
		Origin[0] = 1212.364624
		Origin[1] = -355.708923
		Origin[2] = 347.099670
	}
	else
	{
		Origin[0] = 4.827874
		Origin[1] = -294.803100
		Origin[2] = 276.031250
	}
	Angles[1] = 0.0

	set_pev(Watch, pev_classname, "Cut1")
	engfunc(EngFunc_SetModel, Watch, "models/CSO_Lightzombie/camera.mdl")
	
	set_pev(Watch, pev_origin, Origin)
	set_pev(Watch, pev_angles, Angles)
	set_pev(Watch, pev_v_angle, Angles)
	entity_set_int(Watch, EV_INT_rendermode, kRenderTransTexture)
	entity_set_float(Watch, EV_FL_renderamt, 0.0)	
	set_pev(Watch, pev_solid, SOLID_TRIGGER)
	set_pev(Watch, pev_movetype, MOVETYPE_FLY)	
	
	Cut1 = Watch
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		attach_view(i, Watch)
		client_cmd(i, "hud_draw 0")
	}
}
/*================================================================================
[Criar Boss]
=================================================================================*/
public Game_Start(Float:Sp_Origin[3])
{
	// new spawnerid = id[0]
	if(pev_valid(Lightz_Ent))
		engfunc(EngFunc_RemoveEntity, Lightz_Ent)
	
	new Lightz, Float:Angles[3] 
	Lightz = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(Lightz)) 
		return
	
	Lightz_Ent = Lightz

	set_pev(Lightz,pev_origin,Sp_Origin)	

	Angles[1] = 180.0
	
	set_pev(Lightz, pev_angles, Angles)
	set_pev(Lightz, pev_v_angle, Angles)		
			
	// Setar Configura��o
	set_pev(Lightz, pev_classname, LIGHTZ_CLASS)
	engfunc(EngFunc_SetModel, Lightz, LIGHTZ_MODEL)
	set_pev(Lightz, pev_modelindex, engfunc(EngFunc_ModelIndex, LIGHTZ_MODEL))
			
	set_pev(Lightz, pev_gamestate, 1)
	set_pev(Lightz, pev_solid, SOLID_BBOX)
	set_pev(Lightz, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Lightz , pev_flags , FL_MONSTER)
	
	// Setar Tamanho do Lightz
	new Float:maxs[3] = {70.0, 70.0, 160.0}
	new Float:mins[3] = {-70.0, -70.0, 0.0}	
	entity_set_size(Lightz, mins, maxs)	
	
	// Setar Vida do Lightz Boss // E o Dano Tambem 	
	set_pev(Lightz, pev_takedamage, DAMAGE_YES)
	set_pev(Lightz, pev_health, HEALTH_OFFSET + LIGHTZ_HEALTH)
	
	// Setar o boss e criar o spawn
	Set_EntAnim(Lightz, ANIM_IDLE, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[0])	
	set_pev(Lightz, pev_skin, 3)	
	boss_state = STATE_APPEAR	
	
	if(!y_start_npc)
	{
		y_start_npc = true
		invisibilidade = false
		Fix_Death_Boss = false
	}	
	y_hpbar = create_entity("env_sprite")
	set_pev(y_hpbar, pev_scale, 0.6)
	set_pev(y_hpbar, pev_owner, Lightz)
	engfunc(EngFunc_SetModel, y_hpbar, LIGHTZ_HPSPR)	
	
	set_task(0.1, "Code_Hp", Lightz+2000, _, _, "b")
					
	set_pev(Lightz, pev_nextthink, get_gametime() + 1.0)	
	engfunc(EngFunc_DropToFloor, Lightz)

	SetThink(Lightz , "Fw_Lightz_Think")
}
public Code_Hp(Lightz)
{
	Lightz -= 2000
	
	if(!pev_valid(Lightz))
	{
		remove_task(Lightz+2000)
		return
	}
	static Float:Origin[3], Float:Lightz_hp
	pev(Lightz, pev_origin, Origin)
	Origin[2] += 300.0	
	engfunc(EngFunc_SetOrigin, y_hpbar, Origin)
	pev(Lightz, pev_health, Lightz_hp)
	if(LIGHTZ_HEALTH < (Lightz_hp - 0.0))
	{
		set_pev(y_hpbar, pev_frame, 100.0)
	}
	else
	{
		set_pev(y_hpbar, pev_frame, 0.0 + ((((Lightz_hp - 0.0) - 1 ) * 100) / LIGHTZ_HEALTH))
	}

}
/*================================================================================
[Criar Sangue Ao Levar Tiro]
=================================================================================*/
public fw_Lightz_Tracer_DMG(victim, inflictor, attacker, Float:damage, damagebits)
{
	new classname [32]
	get_entvar(victim , var_classname , classname , charsmax(classname))
	if(strcmp(classname , LIGHTZ_CLASS))
		return HAM_IGNORED
	static Float:Origin[3]
	fm_get_aimorigin(attacker, Origin)
	
	if(!invisibilidade)
	{
		create_blood(Origin)		
	}		
	if(get_pcvar_num(cvar_dmg_ap_allow))
	{
		// Store damage dealt
		g_damagedealt[attacker] += floatround(damage)
			
		// Reward ammo packs for every [ammo damage] dealt
		while (g_damagedealt[attacker] > get_pcvar_num(cvar_ammodamage))
		{
			g_damagedealt[attacker] = 0
			AddAmmoPak(attacker , 0.02)
		}
	}
	return HAM_IGNORED
}

public fw_Lightz_Tracer_DMG_Pre(victim, inflictor, attacker, Float:damage, damagebits){
	new classname [32]
	get_entvar(victim , var_classname , classname , charsmax(classname))
	if(strcmp(classname , LIGHTZ_CLASS))
		return HAM_IGNORED
	new Float:DamgeSub = GetLvDamageReduction()
	new Float:NewDamage = damage * (1.0 - DamgeSub)
	SetHamParamFloat( 4 , NewDamage)
	return HAM_IGNORED
}

/*------------------------------------------------------------------------------------------
Ham Killed do Boss
--------------------------------------------------------------------------------------------*/
public Lightz_Killed(Lightz, attacker)
{
	if(!is_valid_ent(Lightz))
		return HAM_IGNORED
	new classname [32]
	get_entvar(Lightz , var_classname , classname , charsmax(classname))
	if(strcmp(classname , LIGHTZ_CLASS))
		return HAM_IGNORED
	if(!Fix_Death_Boss)
	{	
		StopSound() 
		new name[32]; get_user_name(attacker, name, 31)		
		Fix_Death_Boss = true
		new Float:DeadOrigin[3]
		get_entvar(Lightz , var_origin , DeadOrigin)
		CreateLoot_Cso(DeadOrigin)
		m_print_color(0 , "!g[冰布提示]!t日军生化武器已被挫败，请尽快拾取战利品")
	}
	return HAM_SUPERCEDE
}

public Remove_boss(Lightz)
{
	Lightz -= TASK_DEATH
	if(!pev_valid(Lightz))
		return
	
	PlaySound(0, ROUND_WIN)
	engfunc(EngFunc_RemoveEntity, Lightz_Ent)
	remove_entity(y_hpbar)		

	Boss_Create_Fix = false
	server_cmd("endround 1")

	remove_task(Lightz+TASK_DEATH)
}
//Nunca Remover (Isso Evita bugs ao boss morrer)
public Restart_Map_antibug()
{
	server_cmd("amx_map zs_light_zombie_boss")
}
/*================================================================================
[Think do Boss]
=================================================================================*/
public Fw_Lightz_Think(Lightz)
{
	if(!pev_valid(Lightz))
		return
		
	if(boss_state == STATE_DEATH) 
		return
	
	if(pev(Lightz, pev_health) - HEALTH_OFFSET <= 0.0)
	{	
		boss_state = STATE_DEATH
		set_pev(Lightz, pev_solid, SOLID_NOT)	
		set_pev(Lightz, pev_movetype, MOVETYPE_NONE)
		set_pev(Lightz, pev_skin, 1)
		set_rendering(Lightz, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
		
		Set_EntAnim(Lightz, ANIM_DEATH, 1.0, 1)
		PlaySound(0, CSO_Lightzombie[14])
		
		//Remover Boss		
		set_task(10.0, "Remove_boss", Lightz+TASK_DEATH)
		
		y_start_npc = false
		invisibilidade = false
		Fix_Death_Boss = false
		Fix_Config_Server = false
		
		remove_task(Lightz+TASK_APPEAR)
		remove_task(Lightz+TASK_ATTACKS)
		remove_task(Lightz+TASK_ATTACK_SPECIAl)
		remove_task(Lightz+TASK_ATTACK_IVISIVEL)
		remove_task(1000)
		remove_task(2000)
		
		return  
	}

	if(get_gametime() - Time4 > Time5)
	{
		static RandomNum
		RandomNum = random_num(0, 4)
		switch(RandomNum)
		{
			case 0: 
			{
				if(!invisibilidade)
				{
					Attack_1_Special(Lightz+TASK_ATTACK_SPECIAl) 
				}
			}
			case 1: 
			{
				Attack_2_Special(Lightz+TASK_ATTACK_SPECIAl)
			}
			case 2: 
			{
				Attack_3_Special(Lightz+TASK_ATTACK_SPECIAl) 
			}
			case 3:
			{
				Attack_4_Special(Lightz+TASK_ATTACK_SPECIAl) 
			}
			case 4: 
			{
				Attack_5_Special(Lightz+TASK_ATTACK_SPECIAl) 
			}
		}
		Time4 = random_float(1.0, 6.0)
		Time5 = get_gametime()
	}
	
	// Set Next Think
	set_pev(Lightz, pev_nextthink, get_gametime() + 0.01)	
		
	switch(boss_state)
	{	
		case STATE_IDLE:
		{
			if(get_gametime() - 5.0 > Time1)
			{
				Set_EntAnim(Lightz, ANIM_IDLE, 1.0, 1)		
				Time1 = get_gametime()
			}
			if(get_gametime() - 1.0 > Time2)
			{
				boss_state = STATE_SEARCHING
				Time2 = get_gametime()
			}	
		}	
		case STATE_SEARCHING:
		{
			static Victim;
			Victim = FindClosetEnemy(Lightz, 1)
	
			if(is_user_alive(Victim))
			{
				set_pev(Lightz, pev_enemy, Victim)
				boss_state = STATE_CHASE
			} 
			else 
			{
				set_pev(Lightz, pev_enemy, 0)
				boss_state = STATE_IDLE
			}
		}	
		case STATE_CHASE:
		{
			static Enemy; Enemy = pev(Lightz, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)	
						
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, Lightz) <= 250.0)
				{	
					static Random_Attacks;
					Random_Attacks = random_num(0, 2)
	
					MM_Aim_To(Lightz, EnemyOrigin)
					
					switch(Random_Attacks)
					{
						case 0: Attack_1_Start(Lightz+TASK_ATTACKS)
						case 1: Attack_2_Start(Lightz+TASK_ATTACKS)
						case 2: Attack_3_Start(Lightz+TASK_ATTACKS)
					}													
				} 
				else 
				{
					if(pev(Lightz, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
										
						static Float:OriginAhead[3]									
						MM_Aim_To(Lightz, EnemyOrigin) 
						get_position(Lightz, 300.0, 0.0, 0.0, OriginAhead)						
						hook_ent2(Lightz, OriginAhead, 260.0)	
						
						Set_EntAnim(Lightz, ANIM_RUN, 1.0, 0)
												
						if(get_gametime() - 0.4 > Time3)
						{
							if(g_FootStep != 15) g_FootStep = 15
							else g_FootStep = 16
				
							PlaySound(0, CSO_Lightzombie[g_FootStep == 15 ? 15 : 16])							
							Time3 = get_gametime()
						}			
					}					
				}
			}			 
			else 
			{
				boss_state = STATE_SEARCHING
			}				
			set_pev(Lightz, pev_nextthink, get_gametime() + 0.1)
		}
		case STATE_APPEAR:
		{
			boss_state = STATE_IDLE
			return
			// static Float:Target[3], Float:Origin[3]
			
			// pev(Lightz, pev_origin, Origin)
			// Target[0] = 1896.908691
			// Target[1] = -368.895904
			// Target[2] = 276.031250
			// if(pev(Lightz, pev_movetype) == MOVETYPE_PUSHSTEP)
			// {
			// 	if(get_distance_f(Target, Origin) > 90.0)
			// 	{
			// 		MM_Aim_To(Lightz, Target)
			// 		hook_ent2(Lightz, Target, 200.0)
			// 		Set_EntAnim(Lightz, ANIM_WALK, 1.0, 0)
					
			// 		if(get_gametime() - 0.5 > Time3)
			// 		{
			// 			if(g_FootStep != 15) g_FootStep = 15
			// 			else g_FootStep = 16
				
			// 			PlaySound(0, CSO_Lightzombie[g_FootStep == 15 ? 15 : 16])
			// 			Time3 = get_gametime()
			// 		}
			// 	}
			// 	else 
			// 	{			
			// 		boss_state = STATE_APPEAR_IDLE
			// 		Set_EntAnim(Lightz, ANIM_IDLE, 1.0, 1)
			// 		Scene_Appear_Jump(Lightz+TASK_APPEAR)											
			// 	}
			// }				
		}	
		case STATE_APPEAR_JUMP:
		{
			boss_state = STATE_IDLE
			// static Float:Target[3], Float:Origin[3]
			
			// pev(Lightz, pev_origin, Origin)
			// Target[0] = 1117.921630
			// Target[1] = -348.132019
			// Target[2] = 979.544006
			// if(pev(Lightz, pev_movetype) == MOVETYPE_PUSHSTEP)
			// {
			// 	if(get_distance_f(Target, Origin) > 90.0)
			// 	{
			// 		MM_Aim_To(Lightz, Target)
			// 		hook_ent2(Lightz, Target, 550.0)
			// 	}
			// 	else 
			// 	{		
			// 		boss_state = STATE_APPEAR_END
			// 		set_task(0.4, "Boss_NoClip", Lightz+TASK_APPEAR)							
			// 	}
			// }				
		}
		case STATE_APPEAR_END:
		{
			boss_state = STATE_IDLE
			// static Float:Target[3], Float:Origin[3]
			
			// pev(Lightz, pev_origin, Origin)
			// Target[0] = 407.670867
			// Target[1] = -356.090850
			// Target[2] = 276.031250
			// if(pev(Lightz, pev_movetype) == MOVETYPE_PUSHSTEP)
			// {
			// 	if(get_distance_f(Target, Origin) > 90.0)
			// 	{
			// 		MM_Aim_To(Lightz, Target)
			// 		hook_ent2(Lightz, Target, 300.0)
			// 		KickBack()
			// 	}
			// 	else 
			// 	{	
			// 		boss_state = STATE_APPEAR_IDLE
			// 		Scene_Jump_End(Lightz+TASK_APPEAR)									
			// 	}
			// }				
		}
	}			
}
/*================================================================================
[Cena de Entrada do NPC]
=================================================================================*/
public Boss_NoClip(Lightz)
{
	Lightz -= TASK_APPEAR
	
	if(!pev_valid(Lightz))
		return
		
	set_pev(Lightz, pev_movetype, MOVETYPE_NOCLIP)
	
	set_task(0.6, "Boss_Step", Lightz+TASK_APPEAR)		
}
public Boss_Step(Lightz)
{
	Lightz -= TASK_APPEAR
	
	if(!pev_valid(Lightz))
		return

	set_pev(Lightz, pev_movetype, MOVETYPE_PUSHSTEP)
}
public Scene_Appear_Jump(Lightz)
{
	Lightz -= TASK_APPEAR
	
	if(!pev_valid(Lightz))
		return

	set_pev(Lightz, pev_movetype, MOVETYPE_NONE)	
	set_pev(Lightz, pev_body, 1)		
	Set_EntAnim(Lightz, ANIM_BOMB_JUMP, 1.0, 1)
	
	PlaySound(0, CSO_Lightzombie[5])
	
	set_task(1.25, "Scene_Jump_Exp", Lightz+TASK_APPEAR)
}
public Scene_Jump_Exp(Lightz)
{
	Lightz -= TASK_APPEAR
	
	if(!pev_valid(Lightz))
		return
	static Float:Origin[3]		
	pev(Lightz, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(exp_spr_id)	// sprite index
	write_byte(45)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(0)	// flags
	message_end()
	
	PlaySound(0, CSO_Lightzombie[6])
	set_pev(Lightz, pev_body, 0)
	set_task(0.1, "Scene_Appear_Jump_Loop", Lightz+TASK_APPEAR)	
}
public Scene_Appear_Jump_Loop(Lightz)
{
	Lightz -= TASK_APPEAR
	
	if(!pev_valid(Lightz))
		return
	
	set_pev(Lightz, pev_movetype, MOVETYPE_PUSHSTEP)
	Set_EntAnim(Lightz, ANIM_APPEAR, 1.0, 1)	
	boss_state = STATE_APPEAR_JUMP
	
	Camera = 1
	set_task(1.0, "Camera_boss")
}
//Jump END
public Scene_Jump_End(Lightz) 
{
	Lightz -= TASK_APPEAR
	
	if(!pev_valid(Lightz))
		return
	
	set_pev(Lightz, pev_skin, 0)
	Set_EntAnim(Lightz, ANIM_APPEAR_END, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[1])
	
	set_task(0.8, "Scene_End_Remove", Lightz+TASK_APPEAR)		
}
public Scene_End_Remove(Lightz)
{
	Lightz -= TASK_APPEAR
	
	if(!pev_valid(Lightz))
		return
		
	remove_task(Lightz+TASK_APPEAR)
	boss_state = STATE_SEARCHING
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		attach_view(i, i)
		client_cmd(i, "hud_draw 1")
	}
	if(pev_valid(Cut1)) remove_entity(Cut1)	
}
/*================================================================================
[Ataque (1)]
=================================================================================*/
public Attack_1_Start(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return

	if(boss_state == STATE_IDLE || boss_state == STATE_SEARCHING || boss_state == STATE_CHASE)
	{
		Attack1_Loop(Lightz+TASK_ATTACKS)
		boss_state = STATE_ATTACK1
	}			
}
public Attack1_Loop(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return
		
	set_pev(Lightz, pev_movetype, MOVETYPE_NONE)
	Set_EntAnim(Lightz, ANIM_ATTACK1, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[3])
	
	set_task(0.9, "DMG_Attack1", Lightz+TASK_ATTACKS)
	set_task(1.6, "Remover_Attaques_Padroes", Lightz+TASK_ATTACKS)	
}
public DMG_Attack1(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(Lightz, i) <= 340.0)
		{
			ExecuteHamB(Ham_TakeDamage, i, 0, i, 120.0, DMG_BLAST)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
			Make_PlayerShake(i)
		}
	}
}
/*================================================================================
[Ataque (2)]
=================================================================================*/
public Attack_2_Start(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return

	if(boss_state == STATE_IDLE || boss_state == STATE_SEARCHING || boss_state == STATE_CHASE)
	{
		Attack2_Loop(Lightz+TASK_ATTACKS)
		boss_state = STATE_ATTACK2
	}			
}
public Attack2_Loop(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return

	set_pev(Lightz, pev_movetype, MOVETYPE_NONE)		
	Set_EntAnim(Lightz, ANIM_ATTACK2, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[4])
	
	set_task(1.0, "DMG_Attack2", Lightz+TASK_ATTACKS)
	set_task(2.0, "Remover_Attaques_Padroes", Lightz+TASK_ATTACKS)	
}
public DMG_Attack2(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(Lightz, i) <= 340.0)
		{
			ExecuteHamB(Ham_TakeDamage, i, 0, i, 180.0, DMG_BLAST)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
			Make_PlayerShake(i)
		}
	}
}
/*================================================================================
[Ataque (3)]
=================================================================================*/
public Attack_3_Start(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return

	if(boss_state == STATE_IDLE || boss_state == STATE_SEARCHING || boss_state == STATE_CHASE)
	{
		Attack3_Loop(Lightz+TASK_ATTACKS)
		boss_state = STATE_ATTACK3
	}			
}
public Attack3_Loop(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return

	set_pev(Lightz, pev_movetype, MOVETYPE_NONE)		
	Set_EntAnim(Lightz, ANIM_ATTACK3, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[3])
	
	set_task(0.5, "DMG_Attack3", Lightz+TASK_ATTACKS)
	set_task(1.0, "Remover_Attaques_Padroes", Lightz+TASK_ATTACKS)	
}
public DMG_Attack3(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(Lightz, i) <= 340.0)
		{
			ExecuteHamB(Ham_TakeDamage, i, 0, i, 250.0, DMG_BLAST)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
			Make_PlayerShake(i)
		}
	}
}
/*================================================================================
[Public Para Remover os Ataques Padr�es do BOSS]
=================================================================================*/
public Remover_Attaques_Padroes(Lightz)
{
	Lightz -= TASK_ATTACKS
	
	if(!pev_valid(Lightz))
		return
		
	set_pev(Lightz, pev_movetype, MOVETYPE_PUSHSTEP)		
	remove_task(Lightz+TASK_ATTACKS)
	boss_state = STATE_SEARCHING
	
	set_pev(Lightz, pev_skin, 0)
}
/*================================================================================
[Ataque Especial (1)	//Ficar Invisivel
=================================================================================*/
public Attack_1_Special(Lightz) 
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return

	if(boss_state == STATE_IDLE || boss_state == STATE_SEARCHING || boss_state == STATE_CHASE)
	{
		set_pev(Lightz, pev_movetype, MOVETYPE_NONE)
		Attack1_Special_Loop(Lightz+TASK_ATTACK_SPECIAl)
		boss_state = STATE_INVISIVILITY
	}
}
public Attack1_Special_Loop(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return
		
	set_pev(Lightz, pev_skin, 4)
	Set_EntAnim(Lightz, ANIM_INVISIBILITY, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[2])
	
	invisibilidade = true
	
	set_rendering(Lightz, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 150)
	set_rendering(y_hpbar, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 150)
	set_task(0.5, "Deixar_bossInvi1", Lightz+TASK_ATTACK_IVISIVEL)
	set_task(0.7, "Deixar_bossInvi2", Lightz+TASK_ATTACK_IVISIVEL)	
}
public Deixar_bossInvi1(Lightz)
{
	Lightz -= TASK_ATTACK_IVISIVEL
	
	if(!pev_valid(Lightz))
		return
	
	set_rendering(Lightz, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 100)
	set_rendering(y_hpbar, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 100)
}
public Deixar_bossInvi2(Lightz)
{
	Lightz -= TASK_ATTACK_IVISIVEL
	
	if(!pev_valid(Lightz))
		return
	
	set_rendering(Lightz, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	set_rendering(y_hpbar, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	Set_EntAnim(Lightz, ANIM_IDLE, 1.0, 1)	
	set_pev(Lightz, pev_skin, 0)
		
	set_task(1.5, "Remover_Ataques_Especiais", Lightz+TASK_ATTACK_SPECIAl)
	set_task(12.0, "Tirar_invi1", Lightz+TASK_ATTACK_IVISIVEL)	
}
public Tirar_invi1(Lightz)
{
	Lightz -= TASK_ATTACK_IVISIVEL
	
	if(!pev_valid(Lightz))
		return
	
	set_task(0.5, "Tirar_invi2", Lightz+TASK_ATTACK_IVISIVEL)	
	set_rendering(Lightz, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 50)
	set_rendering(y_hpbar, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 50)
}
public Tirar_invi2(Lightz)
{
	Lightz -= TASK_ATTACK_IVISIVEL
	
	if(!pev_valid(Lightz))
		return
	
	set_task(0.5, "Tirar_invi3", Lightz+TASK_ATTACK_IVISIVEL)	
	set_rendering(Lightz, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 150)
	set_rendering(y_hpbar, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 150)
}
public Tirar_invi3(Lightz)
{
	Lightz -= TASK_ATTACK_IVISIVEL
	
	if(!pev_valid(Lightz))
		return

	set_rendering(Lightz, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
	set_rendering(y_hpbar, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
	remove_task(Lightz+TASK_ATTACK_IVISIVEL)	
	invisibilidade = false
}
/*================================================================================
[Ataque Especial (2)	//Jogar Bomba
=================================================================================*/
public Attack_2_Special(Lightz) 
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return

	if(boss_state == STATE_IDLE || boss_state == STATE_SEARCHING || boss_state == STATE_CHASE)
	{
		set_pev(Lightz, pev_movetype, MOVETYPE_NONE)
		Attack2_Special_Loop(Lightz+TASK_ATTACK_SPECIAl)
		boss_state = STATE_ATK_BOMB_NORMAL1
	}
}
public Attack2_Special_Loop(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return
		
	set_pev(Lightz, pev_body, 1)
	Set_EntAnim(Lightz, ANIM_ATK_BOMB_NORMAL, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[12])
	Bomba = 0
	
	set_task(0.5, "Spawn_Bombs", Lightz+TASK_ATTACK_SPECIAl)
	set_task(1.0, "Remover_Ataques_Especiais", Lightz+TASK_ATTACK_SPECIAl)	
}
/*================================================================================
[Ataque Especial (3)	//Chutar Bomba
=================================================================================*/
public Attack_3_Special(Lightz) 
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return

	if(boss_state == STATE_IDLE || boss_state == STATE_SEARCHING || boss_state == STATE_CHASE)
	{
		set_pev(Lightz, pev_movetype, MOVETYPE_NONE)
		Attack3_Special_Loop(Lightz+TASK_ATTACK_SPECIAl)
		boss_state = STATE_ATK_BOMB_NORMAL2
	}
}
public Attack3_Special_Loop(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return
		
	set_pev(Lightz, pev_body, 1)
	Set_EntAnim(Lightz, ANIM_ATK_BOMB_NORMAL2, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[13])	
	Bomba = 1
	
	set_task(0.5, "Spawn_Bombs", Lightz+TASK_ATTACK_SPECIAl)
	set_task(1.0, "Remover_Ataques_Especiais", Lightz+TASK_ATTACK_SPECIAl)	
}
/*================================================================================
[Ataque Especial (4)	//Ficar louca
=================================================================================*/
public Attack_4_Special(Lightz) 
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return

	if(boss_state == STATE_IDLE || boss_state == STATE_SEARCHING || boss_state == STATE_CHASE)
	{
		set_pev(Lightz, pev_movetype, MOVETYPE_NONE)
		Attack4_Special_Loop(Lightz+TASK_ATTACK_SPECIAl)
		boss_state = STATE_BOMB_CRAZY
	}
}
public Attack4_Special_Loop(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return
		
	Set_EntAnim(Lightz, ANIM_BOMB_CRAZY_START, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[9])

	set_task(3.0, "Attack4_Special_2Lopp", Lightz+TASK_ATTACK_SPECIAl)
	set_task(3.5, "Bombs_Random_Exps", Lightz)
	set_task(5.0, "Bombs_Random_Exps", Lightz)
	set_task(6.0, "Attack4_Special_3Lopp", Lightz+TASK_ATTACK_SPECIAl)
}
public Attack4_Special_2Lopp(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return
			
	Set_EntAnim(Lightz, ANIM_BOMB_CRAZY_LOOP, 1.0, 1)
}
public Attack4_Special_3Lopp(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	if(!pev_valid(Lightz))
		return
		
	Set_EntAnim(Lightz, ANIM_BOMB_CRAZY_LOOP2, 1.0, 1)
	set_pev(Lightz, pev_skin, 2)
	
	set_task(1.0, "Attack4_Special_4Lopp", Lightz+TASK_ATTACK_SPECIAl)
}
public Attack4_Special_4Lopp(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return

	Set_EntAnim(Lightz, ANIM_BOMB_CRAZY_LOOP3, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[7])
	
	set_task(2.0, "loop_sound")
	set_task(4.0, "loop_sound2")
	set_task(6.0, "Attack4_Special_5Lopp", Lightz+TASK_ATTACK_SPECIAl)
}
public loop_sound() PlaySound(0, CSO_Lightzombie[7])
public loop_sound2() PlaySound(0, CSO_Lightzombie[7])
public Attack4_Special_5Lopp(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return
		
	Set_EntAnim(Lightz, ANIM_BOMB_CRAZY_END, 1.0, 1)
	set_task(1.0, "Remover_Ataques_Especiais", Lightz+TASK_ATTACK_SPECIAl)
}
public Bombs_Random_Exps(ent)
{
	static Float:RanOrigin[10][3]
	static Float:fOrigin[3]
	get_entvar(ent , var_origin , fOrigin)
	for(new i = 0; i < 10; i++)
	{
		RanOrigin[i][0] = fOrigin[0]+ random_float(-380.0, 380.0)
		RanOrigin[i][1] = fOrigin[1] + random_float(-380.0, 380.0)
		RanOrigin[i][2] = fOrigin[2] + 20.0
		
		Create_explosions(ent, RanOrigin[i])
	}
}
public Create_explosions(ent, Float:Origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(exp_spr_id)
	write_byte(50)
	write_byte(30)
	write_byte(0)  
	message_end()	
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 340.0)
		{
			ExecuteHamB(Ham_TakeDamage, i, 0, i, 150.0, DMG_BLAST)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
			Make_PlayerShake(i)
		}
	}
}
/*================================================================================
[Ataque Especial (5)	//Invocar Bomba
=================================================================================*/
public Attack_5_Special(Lightz) 
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return

	if(boss_state == STATE_IDLE || boss_state == STATE_SEARCHING || boss_state == STATE_CHASE)
	{
		set_pev(Lightz, pev_movetype, MOVETYPE_NONE)
		Attack5_Special_Loop(Lightz+TASK_ATTACK_SPECIAl)
		boss_state = STATE_BOMB_NUKE
	}
}
public Attack5_Special_Loop(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl

	if(!pev_valid(Lightz))
		return
		
	Set_EntAnim(Lightz, ANIM_BOMB_NUKE, 1.0, 1)
	PlaySound(0, CSO_Lightzombie[5])
	
	set_task(1.0, "Attack5_Special_idle", Lightz+TASK_ATTACK_SPECIAl)
	set_task(2.0, "make_bombs", Lightz+TASK_ATTACK_SPECIAl)
	set_task(5.0, "Attack5_Special_Exp", Lightz+TASK_ATTACK_SPECIAl)	
}
public Attack5_Special_idle(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return
	
	Set_EntAnim(Lightz, ANIM_BOMB_NUKE_IDLE, 1.0, 1)	
}
public Attack5_Special_Exp(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return
		
	Set_EntAnim(Lightz, ANIM_BOMB_NUKE_EXPLOSION, 1.0, 1)	
	set_pev(Lightz, pev_skin, 2)
	PlaySound(0, CSO_Lightzombie[6])	

	set_task(1.0, "Attack5_Special_Crazy", Lightz+TASK_ATTACK_SPECIAl)
}
public Attack5_Special_Crazy(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return

	Set_EntAnim(Lightz, ANIM_BOMB_NUKE_CRAZY, 1.0, 1)	
	PlaySound(0, CSO_Lightzombie[7])
	set_task(2.0, "Sound_Idle_Nuke")
	set_task(4.0, "Attack5_Special_End", Lightz+TASK_ATTACK_SPECIAl)
}
public Sound_Idle_Nuke() PlaySound(0, CSO_Lightzombie[7])
public Attack5_Special_End(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return

	Set_EntAnim(Lightz, ANIM_BOMB_NUKE_END, 1.0, 1)	
	PlaySound(0, CSO_Lightzombie[8])	
	set_pev(Lightz, pev_skin, 0)
	
	set_task(1.0, "Remover_Ataques_Especiais", Lightz+TASK_ATTACK_SPECIAl)
}
public make_bombs(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return
		
	static Float:Origin[3], Float:beam_origin[30][3], Float:Angles[3]
	
	entity_get_vector(Lightz, EV_VEC_origin, Origin)
	entity_get_vector(Lightz, EV_VEC_v_angle, Angles)

	// 1st
	beam_origin[0][0] = Origin[0]
	beam_origin[0][1] = Origin[1] + 100.0
	beam_origin[0][2] = Origin[2]
	
	// 2nd
	beam_origin[1][0] = Origin[0]
	beam_origin[1][1] = Origin[1] + 200.0
	beam_origin[1][2] = Origin[2]

	// 3rd 
	beam_origin[2][0] = Origin[0]
	beam_origin[2][1] = Origin[1] + 300.0
	beam_origin[2][2] = Origin[2]

	// 4th 
	beam_origin[3][0] = Origin[0]
	beam_origin[3][1] = Origin[1] + 400.0
	beam_origin[3][2] = Origin[2]

	// 5th 
	beam_origin[4][0] = Origin[0]
	beam_origin[4][1] = Origin[1] + 500.0
	beam_origin[4][2] = Origin[2]

	// 6th 
	beam_origin[5][0] = Origin[0] + 100.0
	beam_origin[5][1] = Origin[1] + 100.0
	beam_origin[5][2] = Origin[2]

	// 7th 
	beam_origin[6][0] = Origin[0] + 200.0
	beam_origin[6][1] = Origin[1] + 200.0
	beam_origin[6][2] = Origin[2]

	// 8th 
	beam_origin[7][0] = Origin[0] + 300.0
	beam_origin[7][1] = Origin[1] + 300.0
	beam_origin[7][2] = Origin[2]
	
	// 9th 
	beam_origin[8][0] = Origin[0] + 400.0
	beam_origin[8][1] = Origin[1] + 400.0
	beam_origin[8][2] = Origin[2]
	
	// 10th 
	beam_origin[9][0] = Origin[0] + 500.0
	beam_origin[9][1] = Origin[1] + 500.0
	beam_origin[9][2] = Origin[2]
	
	// 11th 
	beam_origin[10][0] = Origin[0] - 100.0
	beam_origin[10][1] = Origin[1] + 100.0
	beam_origin[10][2] = Origin[2]

	// 12th 
	beam_origin[11][0] = Origin[0] - 200.0
	beam_origin[11][1] = Origin[1] + 200.0
	beam_origin[11][2] = Origin[2]

	// 13th 
	beam_origin[12][0] = Origin[0] - 300.0
	beam_origin[12][1] = Origin[1] + 300.0
	beam_origin[12][2] = Origin[2]

	// 14th 
	beam_origin[13][0] = Origin[0] - 400.0
	beam_origin[13][1] = Origin[1] + 400.0
	beam_origin[13][2] = Origin[2]
	
	// 15th 
	beam_origin[14][0] = Origin[0] - 500.0
	beam_origin[14][1] = Origin[1] + 500.0
	beam_origin[14][2] = Origin[2]
	
	// II
	
	// 1st
	beam_origin[15][0] = Origin[0]
	beam_origin[15][1] = Origin[1] - 100.0
	beam_origin[15][2] = Origin[2]
	
	// 2nd
	beam_origin[16][0] = Origin[0]
	beam_origin[16][1] = Origin[1] - 200.0
	beam_origin[16][2] = Origin[2]

	// 3rd 
	beam_origin[17][0] = Origin[0]
	beam_origin[17][1] = Origin[1] - 300.0
	beam_origin[17][2] = Origin[2]

	// 4th 
	beam_origin[18][0] = Origin[0]
	beam_origin[18][1] = Origin[1] - 400.0
	beam_origin[18][2] = Origin[2]

	// 5th 
	beam_origin[19][0] = Origin[0]
	beam_origin[19][1] = Origin[1] - 500.0
	beam_origin[19][2] = Origin[2]

	// 6th 
	beam_origin[20][0] = Origin[0] - 100.0
	beam_origin[20][1] = Origin[1] - 100.0
	beam_origin[20][2] = Origin[2]

	// 7th 
	beam_origin[21][0] = Origin[0] - 200.0
	beam_origin[21][1] = Origin[1] - 200.0
	beam_origin[21][2] = Origin[2]

	// 8th 
	beam_origin[22][0] = Origin[0] - 300.0
	beam_origin[22][1] = Origin[1] - 300.0
	beam_origin[22][2] = Origin[2]
	
	// 9th 
	beam_origin[23][0] = Origin[0] - 400.0
	beam_origin[23][1] = Origin[1] - 400.0
	beam_origin[23][2] = Origin[2]
	
	// 10th 
	beam_origin[24][0] = Origin[0] - 500.0
	beam_origin[24][1] = Origin[1] - 500.0
	beam_origin[24][2] = Origin[2]
	
	// 11th 
	beam_origin[25][0] = Origin[0] + 100.0
	beam_origin[25][1] = Origin[1] - 100.0
	beam_origin[25][2] = Origin[2]

	// 12th 
	beam_origin[26][0] = Origin[0] + 200.0
	beam_origin[26][1] = Origin[1] - 200.0
	beam_origin[26][2] = Origin[2]

	// 13th 
	beam_origin[27][0] = Origin[0] + 300.0
	beam_origin[27][1] = Origin[1] - 300.0
	beam_origin[27][2] = Origin[2]

	// 14th 
	beam_origin[28][0] = Origin[0] + 400.0
	beam_origin[28][1] = Origin[1] - 400.0
	beam_origin[28][2] = Origin[2]
	
	// 15th 
	beam_origin[29][0] = Origin[0] + 500.0
	beam_origin[29][1] = Origin[1] - 500.0
	beam_origin[29][2] = Origin[2]
	
	for(new i; i < 30; i++) 
	{
		make_bombs_lightz(beam_origin[i], Angles)
	}
}
public make_bombs_lightz(Float:Origin[3], Float:Angles[3])
{
	new ent = create_entity("info_target")
	
	Origin[2] += 5.0	
	entity_set_origin(ent, Origin)
	entity_set_vector(ent, EV_VEC_v_angle, Angles)	
	entity_set_string(ent,EV_SZ_classname, "Bomb_Nuke_Make")
	entity_set_model(ent, ATTACK_TENTACLE1)
	entity_set_int(ent, EV_INT_solid, SOLID_NOT)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE)
		
	new Float:maxs[3] = {1.0,1.0,1.0}
	new Float:mins[3] = {-1.0,-1.0,-1.0}
	entity_set_size(ent, mins, maxs)
	Set_EntAnim(ent, 0, 1.0, 1)
	
	set_task(2.0, "Spawns_Bombs_Nukes", ent)
	
	drop_to_floor(ent)
}
public Spawns_Bombs_Nukes(ent)
{
	entity_set_model(ent, BOMB_MODDEL)
	entity_set_string(ent,EV_SZ_classname, "Bomb_Nuke_Make2")
	
	new Float:maxs[3] = {26.0,26.0,36.0}
	new Float:mins[3] = {-26.0,-26.0,-36.0}
	entity_set_size(ent, mins, maxs)
	Set_EntAnim(ent, 0, 1.0, 1)
	
	set_task(1.0, "Bombs_Explosion", ent)
}
public Bombs_Explosion(ent)
{
	if(!pev_valid(ent))
		return

	static Float:Origin[3];
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(exp_spr_id)
	write_byte(50)
	write_byte(30)
	write_byte(0)  
	message_end()	
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 190.0)
		{
			ExecuteHamB(Ham_TakeDamage, i, 0, i, 90.0, DMG_BLAST)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
			Make_PlayerShake(i)
		}
	}
	remove_entity(ent)
}
/*================================================================================
[Public Da Bomba]
=================================================================================*/
public Spawn_Bombs(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	if(!pev_valid(Lightz))
		return	
		
	static Float:StartOrigin[1][3], Float:TargetOrigin[1][3]
	if(Bomba == 0)
	{
		get_position(Lightz, 90.0, 60.0, 80.0, StartOrigin[0]); get_position(Lightz, 120.0 * 4.0, -30.0 * 3.0, 90.0, TargetOrigin[0])
	}
	else if(Bomba == 1)
	{
		get_position(Lightz, 90.0, 60.0, 30.0, StartOrigin[0]); get_position(Lightz, 120.0 * 4.0, -30.0 * 3.0, 60.0, TargetOrigin[0])
	}
	for(new i = 0; i < 1; i++)
		Create_Bomb(Lightz, StartOrigin[i], TargetOrigin[i])
}
public Create_Bomb(Lightz, Float:Origin[3], Float:Target[3])
{
	static Bomb; Bomb = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	
	if(!pev_valid(Bomb)) 
		return
		
	static Float:Vector[3];
	pev(Lightz, pev_angles, Vector)
	pev(Lightz, pev_angles, Vector)
		
	engfunc(EngFunc_SetOrigin, Bomb, Origin)
	set_pev(Bomb, pev_angles, Vector)
		
	// Set Config
	set_pev(Bomb, pev_gamestate, 1)
	set_pev(Bomb, pev_classname, "Bomb_Zomibe_1")	
	engfunc(EngFunc_SetModel, Bomb, BOMB_MODDEL)	
	set_pev(Bomb, pev_solid, SOLID_TRIGGER)
	set_pev(Bomb, pev_movetype, MOVETYPE_FLY)
		
	// Set Size
	new Float:maxs[3] = {5.0, 5.0, 5.0}
	new Float:mins[3] = {-5.0, -5.0, -5.0}
	entity_set_size(Bomb, mins, maxs)

	set_pev(Bomb, pev_nextthink, get_gametime() + 0.75)	
	Set_EntAnim(Bomb, 0, 1.0, 1)

	// Target
	hook_ent2(Bomb, Target, 1000.0)
	MM_Aim_To(Bomb, Target)
	
	set_pev(Bomb, pev_nextthink, get_gametime() + random_float(2.0, 3.0))	
}
public Bomb_1_Touch(ent, Touched)
{
	if(!pev_valid(ent))
		return
		
	if(Touched == Lightz_Ent)
		return
		
	static Classname[32]; pev(Touched, pev_classname, Classname, 31)
	if(equal(Classname, "Bomb_Zomibe_1")) return
	
	static Float:Origin[3];
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(exp_spr_id)
	write_byte(50)
	write_byte(30)
	write_byte(0)  
	message_end()	
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(ent, i) <= 340.0)
		{
			ExecuteHamB(Ham_TakeDamage, i, 0, i, 150.0, DMG_BLAST)	
			shake_screen(i)
			ScreenFade(i, 2, {140, 0, 0}, 120)	
			Make_PlayerShake(i)
		}
	}
	remove_entity(ent)
}
/*================================================================================
[Public Para Remover os Ataques Especiais do BOSS]
=================================================================================*/
public Remover_Ataques_Especiais(Lightz)
{
	Lightz -= TASK_ATTACK_SPECIAl
	
	if(!pev_valid(Lightz))
		return
		
	set_pev(Lightz, pev_movetype, MOVETYPE_PUSHSTEP)		
	remove_task(Lightz+TASK_ATTACK_SPECIAl)
	boss_state = STATE_SEARCHING
	
	set_pev(Lightz, pev_skin, 0)
}
/*================================================================================
[Stocks do Boss]
=================================================================================*/
stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
public FindClosetEnemy(Cronobotics, can_see)
{
	new Float:maxdistance = 4980.0
	new indexid = 0	
	new Float:current_dis = maxdistance

	for(new i = 1 ;i <= g_MaxPlayers; i++)
	{
		if(can_see)
		{
			if(is_user_alive(i) && can_see_fm(Cronobotics, i) && entity_range(Cronobotics, i) < current_dis)
			{
				current_dis = entity_range(Cronobotics, i)
				indexid = i
			}
		} else {
			if(is_user_alive(i) && entity_range(Cronobotics, i) < current_dis)
			{
				current_dis = entity_range(Cronobotics, i)
				indexid = i
			}			
		}
	}	
	
	return indexid
}

public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}
public MM_Aim_To(ent, Float:Origin[3]) 
{
	if(!pev_valid(ent))	
		return
		
	static Float:Vec[3], Float:Angles[3]
	pev(ent, pev_origin, Vec)
	
	Vec[0] = Origin[0] - Vec[0]
	Vec[1] = Origin[1] - Vec[1]
	Vec[2] = Origin[2] - Vec[2]
	engfunc(EngFunc_VecToAngles, Vec, Angles)
	Angles[0] = Angles[2] = 0.0 
	
	set_pev(ent, pev_angles, Angles)
	set_pev(ent, pev_v_angle, Angles)
}
stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle)
	vAngle[0] = 0.0
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward)
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}
/*------------------------------------------------------------------------------------------
Ler Anima��es
--------------------------------------------------------------------------------------------*/
stock Set_EntAnim(ent, anim, Float:framerate, resetframe)
{
	if(!pev_valid(ent))
		return
	
	if(!resetframe)
	{
		if(pev(ent, pev_sequence) != anim)
		{
			set_pev(ent, pev_animtime, get_gametime())
			set_pev(ent, pev_framerate, framerate)
			set_pev(ent, pev_sequence, anim)
		}
	} 
	else 
	{
		set_pev(ent, pev_animtime, get_gametime())
		set_pev(ent, pev_framerate, framerate)
		set_pev(ent, pev_sequence, anim)
	}
}
stock shake_screen(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}
stock ScreenFade(id, Timer, Colors[3], Alpha) {	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}
stock Knockback_Player(id, Float:CenterOrigin[3], Float:Power, Increase_High)
{
	if(!is_user_alive(id)) return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(id, pev_origin, EntOrigin)
	distance_f = get_distance_f(EntOrigin, CenterOrigin)
	fl_Time = distance_f / Power
		
	fl_Velocity[0] = (EntOrigin[0]- CenterOrigin[0]) / fl_Time
	fl_Velocity[1] = (EntOrigin[0]- CenterOrigin[1]) / fl_Time
	if(Increase_High)
		fl_Velocity[2] = (((EntOrigin[0]- CenterOrigin[2]) / fl_Time) + random_float(10.0, 50.0) * 1.5)
	else
		fl_Velocity[2] = ((EntOrigin[0]- CenterOrigin[2]) / fl_Time) + random_float(1.5, 3.5)
	
	set_pev(id, pev_velocity, fl_Velocity)
}
public Make_PlayerShake(id)
{
	if(!id) 
	{
		message_begin(MSG_BROADCAST, g_MsgScreenShake)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	} else {
		if(!is_user_connected(id))
			return
			
		message_begin(MSG_BROADCAST, g_MsgScreenShake, _, id)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	}
}
stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}
stock fm_get_aimorigin(index, Float:origin[3])
{
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);
	
	new Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);
	
	return 1;
}  
public KickBack()
{
	static Float:Origin[3]
	Origin[0] = 0.0
	Origin[1] = 0.0
	Origin[2] = 800.0

	Check_Knockback(Origin, 0)
}
public Check_Knockback(Float:Origin[3], Damage)
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		fuck_ent(i, Origin, 5000.0)
	}
}
stock fuck_ent(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (EntOrigin[0]- VicOrigin[0]) / fl_Time
	fl_Velocity[1] = (EntOrigin[1]- VicOrigin[1]) / fl_Time
	fl_Velocity[2] = (EntOrigin[2]- VicOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}
stock client_printcolor(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg,190,input,3);
	replace_all(msg,190,"/g","^4");// green
	replace_all(msg,190,"/n","^1");// normal
	replace_all(msg,190,"/t","^3");// team
    
	if (id) players[0] = id; else get_players(players,count,"ch");
	for (new i=0;i<count;i++)
	if (is_user_connected(players[i]))
	{
		message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
		write_byte(players[i]);
		write_string(msg);
		message_end();
	}
}
stock StopSound() 
{
	client_cmd(0, "mp3 stop; stopsound")
}
public Creator_Plugin()
{	
	set_hudmessage(0, 255, 0, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	show_hudmessage(0, "Plugin LightZombie Editado Por: Skill Von Dragon^nMapa Convertido Por: [P]erfec[T][S]cr[@]s[H]")
}
/*------------------------------------------------------------------------------------------
Menu Light Zombie Boss
--------------------------------------------------------------------------------------------*/
public Lightz_menu(id)
{
	if (get_user_flags(id) & FLAG_ACESS)
	{
     	new menu = menu_create("\yMenu Light Zombie Boss", "lightz_boss_handle")
     	
     	menu_additem(menu, "Spawn Light Zombie Boss", "1", 0)
     	menu_additem(menu, "Poderes do Light Zombie", "2", 0)
     	menu_additem(menu, "Reviver os Jogadores", "3", 0)
     	menu_additem(menu, "Configurar o Servidor", "4", 0) 
     	menu_additem(menu, "Remover o Boss", "5", 0)  
     	menu_additem(menu, "MAX HP \r[SOMENTE FUNDADORES]", "6", 0)      	
     	
     	menu_setprop(menu, MPROP_EXITNAME, "Sair")
     	menu_display(id, menu, 0) 
     }
     	else
     {
     	client_printcolor(id, "/g[ZP]/nLamento mais voce nao tem acesso a este comando")
     }    
}
public lightz_boss_handle(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new key = str_to_num(data)

	switch(key)
	{
		case 1:
		{
			if(!Boss_Create_Fix)
			{
				Round_boss(id)
				Boss_Create_Fix = true
				client_printcolor(0, "/g[ZP]/nO Boss foi invocado...Tenha um Bom Jogo")
			}
			else 
			{
				client_printcolor(id, "/g[ZP]/nO Boss ja foi invocado apenas aguarde ok :/....")
			}
		}
		case 2:
		{
			if(y_start_npc)
			{
				Lightz_menu_Poderes(id)
				client_printcolor(id, "/g[ZP]/nNeste menu voce encontra os poderes especiais deste boss")
			}
			else
			{
				client_printcolor(id, "/g[ZP]/nO Boss ainda nao esta no mapa")
			}
		}
		case 3:
		{
			for (new id = 1; id <= get_maxplayers(); id++){
				rg_round_respawn(id)
				}
 			client_print(id, print_center, "Todos os Players Foram Revividos")
			Lightz_menu(id)
		}
		case 4:
		{	
			if(!Fix_Config_Server)
			{				
				set_cvar_num("zp_delay", 9999)
				set_cvar_num("mp_roundtime", 9)
				server_cmd("sv_restartround 5")
				server_cmd("mp_timelimit 9999.0")
		 		client_print(id, print_center, "O Servidor Foi Configurado..")	
		 		client_printcolor(id, "/g[ZP]/nRound Time /n[/g9/n]")
		 		client_printcolor(id, "/g[ZP]/nZP_DELAY /n[/g99999/n]")
		 		client_printcolor(id, "/g[ZP]/nMP_TIMELIMIT /n[/g99999/n]")
		 		Lightz_menu(id)
		 		Fix_Config_Server = true
		 	}
		 	else
		 	{
		 		client_print(id, print_center, "A configuracao so pode ser ativada uma vez")	 		
		 	}
		}
		case 5:
		{
			if(y_start_npc)
			{
				remove_task(Lightz_Ent+TASK_APPEAR)
				remove_task(Lightz_Ent+TASK_ATTACKS)
				remove_task(Lightz_Ent+TASK_ATTACK_SPECIAl)
				remove_task(Lightz_Ent+TASK_ATTACK_IVISIVEL)
				remove_task(1000)
				remove_task(2000)
				engfunc(EngFunc_RemoveEntity, Lightz_Ent)
				remove_entity(y_hpbar)		
				client_printcolor(id, "/g[ZP]/nVoce Removeu o Boss Light Zombie")
				server_cmd("sv_restartround 5")
			}
			else
	 		{
	 			client_print(id, print_center, "O boss Ainda nao apareceu no mapa aguarde")
	 		}
		}
		case 6:
		{
			set_user_health(id, get_user_health(id) + 50000)
			client_printcolor(id, "/g[ZP]/nVoce Adicionou 50000 de vida para voce")
			Lightz_menu(id)
		}	
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public Lightz_menu_Poderes(id)
{
	if (get_user_flags(id) & FLAG_ACESS)
	{
     	new menu = menu_create("\yLight Zombie Boss \rPoderes", "lightz_boss_poderes_handle")
     	
     	menu_additem(menu, "Ficar Invisivel", "1", 0)
     	menu_additem(menu, "Jogar Bomba \r(1)", "2", 0)
     	menu_additem(menu, "Jogar Bomba \r(2)", "3", 0)
     	menu_additem(menu, "Invocar Bombas", "4", 0) 
     	menu_additem(menu, "Ficar Louca", "5", 0)     	
     	
     	menu_setprop(menu, MPROP_EXITNAME, "Sair")
     	menu_display(id, menu, 0) 
     }
     	else
     {
     	client_printcolor(id, "/g[ZP]/nLamento mais voce nao tem acesso a este comando")
     }    
}
public lightz_boss_poderes_handle(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new key = str_to_num(data)

	switch(key)
	{
		case 1:
		{
			if(!invisibilidade)
			{
				Attack_1_Special(Lightz_Ent+TASK_ATTACK_SPECIAl) 
				Lightz_menu_Poderes(id)
			}
		}
		case 2: 
		{
			Attack_2_Special(Lightz_Ent+TASK_ATTACK_SPECIAl)
			Lightz_menu_Poderes(id)
		}
		case 3: 
		{
			Attack_3_Special(Lightz_Ent+TASK_ATTACK_SPECIAl)
			Lightz_menu_Poderes(id)
		}
		case 4: 
		{
			Attack_5_Special(Lightz_Ent+TASK_ATTACK_SPECIAl)
			Lightz_menu_Poderes(id)
		}
		case 5: 
		{
			Attack_4_Special(Lightz_Ent+TASK_ATTACK_SPECIAl)	
			Lightz_menu_Poderes(id)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
