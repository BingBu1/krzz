
/* =========================================
-------- Plugin Datas and Headers ----------
========================================= */

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <reapi>
#include <kr_core>

// You dont have to install them. Just make sure these .inc is exist at "include" folder
#define LIBRARY_ZP "zp50_core"
// #include <zombieplague>

#define LIBRARY_MD "metadrawer"
// #include <metadrawer> // -> https://gamebanana.com/mods/39420
// #include <md_csohud> // -> https://youtu.be/i8i4FNWI9Vg

#define PLUGIN "Hecate II Umbra"
#define VERSION "2.0"
#define AUTHOR "Asdian"

// Data Config
#define P_CHAINSR "models/p_chainsr.mdl"
#define V_CHAINSR "models/v_chainsr.mdl"
#define W_CHAINSR "models/w_chainsr.mdl"

#define MF_W "sprites/muzzleflash270.spr"
#define MODEL_W_OLD "models/w_ak47.mdl"

new const SOUND_FIRE[][] =
{
	"weapons/chainsr-1.wav",
	"weapons/chainsr_exp.wav",
	"weapons/chainsr_smoke.wav"
}

#define CSW_CHAINSR CSW_AK47
#define weapon_chainsr "weapon_ak47"
#define weapon_spr "weapon_chainsr"

#define WEAPON_CODE 18012023
#define WEAPON_EVENT "events/ak47.sc"

// Weapon Config
#define DAMAGE 4000
#define ACCURACY -1 // 0 - 100 ; -1 Default
#define CLIP 20
#define BPAMMO 999
#define SPEED 1.6
#define RECOIL 0.75
#define RELOAD_TIME 3.5

#define SHADOW_DAMAGE 1000.0
#define SHADOW_DAMAGEZB 2120.0
#define SHADOW_RANGE 512.0

#define BLAST_RANGE 175.0
#define BLAST_KNOCK 120.0

#define CHAINSR_MFNAME "chainsr_mf"
#define CHAINSR_SHDWNAME "chainsr_ent"

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_Base, g_Clip[33], g_OldWeapon[33], Float:g_Recoil[33][3], g_Attacking[33], g_Aim_Mode[33]
new g_Event_Base, g_SmokePuff_SprId, g_Dprd
new g_cachde_mf, Float:g_cache_frame_mf, g_cache_trail, spr_blood_spray, spr_blood_drop, g_cache_skill[2], g_cachde_mf2

// supports custom flag
new g_defFlag

// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

new const SpecialModels[][] =
{
	"models/ef_chainsr_sniper.mdl",
	"models/ef_scorpion_hole.mdl"
}

// cache
new const TRACER_ENTITY[][] = { "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target" 
}


/* =========================================
----- End of Plugin Datas and Headers ------
========================================= */

/* =========================================
---------- Plugin Core Function ------------
========================================= */
public event_roundstart(){
	g_Had_Base = 0
	arrayset(g_PlayerWeapon , 0 , sizeof g_PlayerWeapon)
}

public plugin_init()
{
	new plid = register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	
	// Event
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_StartFrame, "fw_StartFrame")
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_chainsr, "fw_Item_Deploy_Post", 1)
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy , "m_DefaultDeploy")
	RegisterHam(Ham_Item_AddToPlayer, weapon_chainsr, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_chainsr, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_chainsr, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_chainsr, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_chainsr, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_chainsr, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_TraceAttack, "hostage_entity", "fw_TraceAttack_Player")
	RegisterHam(Ham_Player_PreThink, "player", "fw_Player_PreThink");
	RegisterHam(Ham_Think, "env_sprite", "fw_MF_Think")
	RegisterHam(Ham_Think, "info_target", "Fw_ChainsrEnt_Think")
	
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack_World")
	
	// Cache
	// if (LibraryExists(LIBRARY_ZP, LibType_Library)) g_Dprd = zp_register_extra_item(PLUGIN, 10, ZP_TEAM_HUMAN | ZP_TEAM_SURVIVOR)
	// else register_clcmd("umbra", "Get_Base")
	
	// if (LibraryExists(LIBRARY_MD, LibType_Library)) md_loadimage("sprites/chainsr_aim_bg2.tga")
	register_clcmd(weapon_spr, "hook_weapon")
	register_clcmd("umbra", "admingive")
	BulidCrashGunWeapon("暗影狙击", W_CHAINSR, "Get_Base", plid)
}

public admingive(id){
	if(is_user_admin(id)){
		Get_Base(id)
	}
}
public hook_weapon(id) {
	engclient_cmd(id, weapon_chainsr)
}

public plugin_precache()
{
	precache_model(P_CHAINSR)
	precache_model(V_CHAINSR)
	precache_model(W_CHAINSR)
	
	new i
	for(i = 0; i < sizeof(SOUND_FIRE); i++) precache_sound(SOUND_FIRE[i])
	for(i = 0; i < sizeof(SpecialModels); i++) precache_model(SpecialModels[i])
	
	new Txt[32]; format(Txt, 31, "sprites/%s.txt", weapon_spr)
	engfunc(EngFunc_PrecacheGeneric, Txt)
	
	precache_generic("sprites/640hud225.spr")
	precache_generic("sprites/640hud7.spr")

	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_cachde_mf = precache_model(MF_W)
	g_cache_frame_mf = float(engfunc(EngFunc_ModelFrames, g_cachde_mf))
	g_cache_trail = precache_model("sprites/laserbeam.spr")
	
	g_cachde_mf2 = precache_model("sprites/ef_chainsr_shadowshoot1.spr") // mf_sniper
	g_cache_skill[0] = precache_model("sprites/ef_chainsr_skill.spr")
	g_cache_skill[1] = precache_model("sprites/ef_chainsr_skill2.spr")
	
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	spr_blood_drop = precache_model("sprites/blood.spr")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
	register_native("CreateBlast" , "native_CreateBlast")
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZP) || equal(module, LIBRARY_MD))
		return PLUGIN_HANDLED;
    
	return PLUGIN_CONTINUE;
}

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public NPC_Killed(this , killer){
	new iEntity = get_member(killer, m_pActiveItem)
	if (!pev_valid(iEntity) || get_member(iEntity,m_iId) != CSW_CHAINSR || !Get_BitVar(g_Had_Base, killer))
		return
	if(g_Attacking[killer]) {
		set_entvar(this,var_iuser3, 0)
		Summon_GojoSatoru_Pre(killer, this)
		Summon_GojoSatoru_Pre(killer, this)
	}
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64], id, iVic, iEntity
	id = get_msg_arg_int(1)
	iVic = get_msg_arg_int(2)
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	iEntity = get_member(id, m_pActiveItem)
	
	if (strcmp(szWeapon, "ak47"))
		return PLUGIN_CONTINUE
		
	if (!pev_valid(iEntity) || get_member(iEntity,m_iId) != CSW_CHAINSR || !Get_BitVar(g_Had_Base, id))
		return PLUGIN_CONTINUE
	
	// initiate !!
	if(g_Attacking[id]) Summon_GojoSatoru_Pre(id, iVic)
	set_msg_arg_string(4, "chainsr")
	return PLUGIN_CONTINUE
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name)) g_Event_Base = get_orig_retval()		
}

public client_putinserver(id)
{
        Safety_Connected(id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}
 
public Register_HamBot(id)
{
	Register_SafetyFuncBot(id)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")	
}

#if AMXX_VERSION_NUM >= 183
public client_disconnected(id)  Safety_Disconnected(id)
#else
public client_disconnect(id)  Safety_Disconnected(id)
#endif

// public zp_extra_item_selected(i, d) if(d == g_Dprd) Get_Base(i)
// public zp_user_infected_post(i) Remove_Base(i)
// public zp_user_humanized_post(i) if (LibraryExists(LIBRARY_ZP, LibType_Library) && zp_get_user_survivor(i)) Remove_Base(i)
/* =========================================
------- End of Plugin Core Function --------
========================================= */

/* =========================================
----------- Weapon Core Function -----------
========================================= */
public Get_Base(id)
{
	g_Aim_Mode[id] = 0
	
	// save your custom flag
	new iFlag = get_member(id, m_iHideHUD)
	g_defFlag |= iFlag
	
	rg_drop_items_by_slot(id , InventorySlotType:PRIMARY_WEAPON_SLOT);
	new wpnent = rg_give_item(id , weapon_chainsr , GT_DROP_AND_REPLACE)
	Set_BitVar(g_Had_Base, id)
	
	// Clip, Ammo, Deploy
	set_member(wpnent , m_Weapon_iClip , CLIP)
	rg_set_user_bpammo(id , CSW_CHAINSR , BPAMMO)
	ExecuteHamB(Ham_Item_Deploy , wpnent)
}

public Remove_Base(id)
{
	UnSet_BitVar(g_Had_Base, id)
	g_Aim_Mode[id] = 0
	set_member(id, m_iHideHUD, g_defFlag)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(weapon_chainsr)
	write_byte(2)
	write_byte(90)
	write_byte(15)
	write_byte(7)
	write_byte(0)
	write_byte(1)
	write_byte(CSW_CHAINSR)
	write_byte(0)
	message_end()
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_CHAINSR && g_OldWeapon[id] != CSW_CHAINSR) && Get_BitVar(g_Had_Base, id))
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_CHAINSR && g_OldWeapon[id] == CSW_CHAINSR) && Get_BitVar(g_Had_Base, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_CHAINSR)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
	} else if(CSWID != CSW_CHAINSR && g_OldWeapon[id] == CSW_CHAINSR) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_CHAINSR)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_CHAINSR)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW)
	} else {
		set_member(id, m_iHideHUD, g_defFlag)
	
		static ent, iFlame
		ent = fm_get_user_weapon_entity(id, CSW_CHAINSR)
		iFlame = find_ent_by_class(id, "chainsr_mf")
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 	
		if(pev_valid(iFlame) && pev(iFlame, pev_iuser1)) set_pev(iFlame, pev_effects, pev(iFlame, pev_effects) | EF_NODRAW)
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_CHAINSR && Get_BitVar(g_Had_Base, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_CHAINSR || !Get_BitVar(g_Had_Base, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event_Base)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	emit_sound(invoker, CHAN_WEAPON, SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, random_num(95,120))
	return FMRES_SUPERCEDE
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, MODEL_W_OLD))
	{
		static weapon
		weapon = find_ent_by_owner(-1, weapon_chainsr, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, W_CHAINSR)
			Remove_Base(iOwner)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public m_DefaultDeploy(const this, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal){
    new playerid = get_member(this, m_pPlayer)
    if(Get_BitVar(g_Had_Base, playerid)){
        SetHookChainArg(3,ATYPE_STRING, P_CHAINSR)
    }
}

public fw_Item_Deploy_Post(Ent)
{
	static id; id = get_member(Ent, m_pPlayer)//get_pdata_cbase(Ent, m_pPlayer, OFFSET_WEAPON)
	
	if(get_member(id, m_pActiveItem) != Ent)
		return
	if(!is_connected(id) || !is_alive(id))
		return
	if(!Get_BitVar(g_Had_Base, id))
		return
	
	set_pev(id, pev_viewmodel2, V_CHAINSR)
	set_pev(id, pev_weaponmodel2, P_CHAINSR)
	
	Set_WeaponAnim(id, 4)
	Additonal_DeploySettings(Ent, id)
	set_nextattack(Ent, id, 1.25)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(Get_BitVar(g_Had_Base, id) ? "weapon_chainsr" : weapon_chainsr)
	write_byte(2)
	write_byte(90)
	write_byte(15)
	write_byte(7)
	write_byte(0)
	write_byte(1)
	write_byte(CSW_CHAINSR)
	write_byte(0)
	message_end()
}

public Additonal_DeploySettings(ent, id)
{
	static iFlame
	iFlame = find_ent_by_class(id, "chainsr_mf")
	
	if(pev_valid(iFlame) && pev(iFlame, pev_iuser1))
		set_pev(iFlame, pev_effects, pev(iFlame, pev_effects) &~ EF_NODRAW)
	
	g_Aim_Mode[id] = 0
	//set_pdata_int(id, m_iFOV, 90, OFFSET_PLAYER)
	set_member(id, m_iFOV, 90)
	
	set_pev(ent, pev_iuser1, 0)
	set_pev(ent, pev_iuser4, 0)
	
	// if (LibraryExists(LIBRARY_MD, LibType_Library))
	// 	mdcsohud_regwpnhud(id, CSW_CHAINSR, weapon_spr)
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == WEAPON_CODE)
	{
		Set_BitVar(g_Had_Base, id)
		set_pev(Ent, pev_impulse, 0)
	}
	
	return HAM_IGNORED	
}

public fw_Item_PostFrame(ent)
{
	static id; id = get_entvar(ent, var_owner)
	if(!is_connected(id) || !is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
		
	static Float:flNextAttack; flNextAttack = get_member(id,m_flNextAttack)//get_pdata_float(id, m_flNextAttack, OFFSET_PLAYER)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_CHAINSR)
	
	static iClip; iClip = get_member(ent,m_Weapon_iClip)
	static fInReload; fInReload = get_member(ent,m_Weapon_fInReload)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		// set_pdata_int(ent, m_iClip, iClip + temp1, OFFSET_WEAPON)
		set_member(ent, m_Weapon_iClip, iClip + temp1)
		cs_set_user_bpammo(id, CSW_CHAINSR, bpammo - temp1)		
		set_member(ent, m_Weapon_fInReload, 0)
	}		
	
	// WE_CHAINSR(id, ent, iClip,bpammo,pev(id, pev_button))
	return HAM_IGNORED
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_connected(id) || !is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_CHAINSR)
	static iClip; iClip = get_member(ent,m_Weapon_iClip)//get_pdata_int(ent, m_iClip, OFFSET_WEAPON)
		
	if(BPAmmo <= 0 || iClip >= CLIP)
		return HAM_SUPERCEDE
	
	g_Clip[id] = iClip
	return HAM_IGNORED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_connected(id) || !is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	if(g_Clip[id] == -1)
		return HAM_IGNORED
	set_member(ent,m_Weapon_iClip,g_Clip[id])
	set_member(ent,m_Weapon_fInReload,1)
	// set_pdata_int(ent, m_iClip, g_Clip[id], OFFSET_WEAPON)
	// set_pdata_int(ent, m_fInReload, 1, OFFSET_WEAPON)
	
	Set_WeaponAnim(id, 3)
	set_nextattack(ent, id, RELOAD_TIME)
	
	g_Aim_Mode[id] = 0
	set_pev(ent, pev_iuser1, 0)
	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	return HAM_IGNORED
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_CHAINSR || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
			
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)

	SetHamParamFloat(3, float(DAMAGE))
	
	static Wpn; Wpn = get_member(Attacker, m_pActiveItem)
	if(pev_valid(Wpn)) set_pev(Wpn, pev_vuser1, flEnd);
	return HAM_IGNORED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_CHAINSR || !Get_BitVar(g_Had_Base, Attacker))
		return HAM_IGNORED

	SetHamParamFloat(3, float(DAMAGE))
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = get_entvar(Ent, var_owner)
	if(!is_connected(id) || !is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED
	
	static iClip;
	iClip = get_member(Ent, m_Weapon_iClip)//get_pdata_int(Ent, m_iClip, OFFSET_WEAPON)
	
	g_Attacking[id] = iClip ? 1 : 0;
	g_Clip[id] = iClip
	set_entvar(id, var_punchangle, g_Recoil[id])
	
	if(iClip){
		MakeMuzzleFlash(id, Ent, 1, 0, MF_W, 0.03)
	}
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = get_entvar(Ent, var_owner)
	if(!is_connected(id) || !is_alive(id) || is_nullent(Ent))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED
	if(!g_Clip[id] || !g_Attacking[id])
		return HAM_IGNORED
		
	static Float:Push[3]
	get_entvar(id, var_punchangle, Push)
	xs_vec_sub(Push, g_Recoil[id], Push)
	xs_vec_mul_scalar(Push, RECOIL, Push)
	xs_vec_add(Push, g_Recoil[id], Push)
	set_entvar(id, var_punchangle, Push)
	
	// Acc
	static Accena; Accena = ACCURACY
	if(Accena != -1)
	{
		static Float:Accuracy
		Accuracy = (float(100 - ACCURACY) * 1.5) / 100.0

		// set_pdata_float(Ent, m_flAccuracy, Accuracy, OFFSET_WEAPON);
		set_member(Ent,m_Weapon_flAccuracy,Accuracy)
	}
	
	Additional_ATK_Settings(id, Ent)
	g_Attacking[id] = 0
	return HAM_IGNORED
}

public Additional_ATK_Settings(id, ent)
{
	Set_WeaponAnim(id, random_num(1,2))
	set_nextattack(ent, id, SPEED)
	set_member(id, m_iHideHUD, g_defFlag)
	
	// csbtedhan + kord12.7
	new Float:originF[3], Float:aimoriginF[3]
	get_entvar(ent, var_vuser1, aimoriginF)
	Stock_Get_Postion(id, 40.0, get_cvar_num("cl_righthand")?7.5:-7.5, -7.0, originF)
	
	for(new i = 0; i < min(floatround(vector_distance(originF, aimoriginF)*0.1), 10) ; i++)
	{
		new iBeam = rg_create_entity("beam");
		set_entvar(iBeam, var_classname, "beam");
		set_entvar(iBeam, var_flags, get_entvar(iBeam, var_flags) | FL_CUSTOMENTITY);
		set_entvar(iBeam, var_rendercolor, Float:{240.0, 240.0, 0.0})
		set_entvar(iBeam, var_renderamt, 255.0)
		set_entvar(iBeam, var_body, 0)
		set_entvar(iBeam, var_frame, 0.0)
		set_entvar(iBeam, var_animtime, 0.0)
		set_entvar(iBeam, var_model, "sprites/laserbeam.spr");
		set_entvar(iBeam, var_modelindex, g_cache_trail)
		set_entvar(iBeam, var_scale, 20.0)
		
		set_entvar(iBeam, var_rendermode, (get_entvar(iBeam, var_rendermode) & 0x0F) | 0x40 & 0xF0)
		set_entvar(iBeam, var_origin, originF)
		set_entvar(iBeam, var_angles, aimoriginF)
		set_entvar(iBeam, var_sequence, (get_entvar(iBeam, var_sequence) & 0x0FFF) | ((0 & 0xF) << 12))
		set_entvar(iBeam, var_skin, (get_entvar(iBeam, var_skin) & 0x0FFF) | ((0 & 0xF) << 12))
		Beam_RelinkBeam(iBeam);
		
		set_entvar(iBeam, var_dmgtime, get_gametime()+ 0.9)
		set_entvar(iBeam, var_fuser1, 0.7)
		set_entvar(iBeam, var_iuser1, 2023)
	}
}

public fw_Player_PreThink(id)
{
	if(!is_connected(id) || !is_alive(id))
		return
	if(!IsAlive(id) || get_user_weapon(id) != CSW_CHAINSR)
	{
		// if (LibraryExists(LIBRARY_MD, LibType_Library))
		// 	md_removedrawing(id, 1, 11)
		return 
	}
	if(!Get_BitVar(g_Had_Base, id))
		return
		
	new iEnt = get_member(id, m_pActiveItem)
	if(!pev_valid(iEnt)) return 
	
	new Float:fTimer; pev(iEnt, pev_fuser3, fTimer)
	new iRel = pev(iEnt, pev_iuser4)
	
	if(fTimer && fTimer < get_gametime())
	{
		if(iRel == 1)
		{
			CSR_Blast(id)
			
			set_pev(iEnt, pev_iuser4, 2)
			set_pev(iEnt, pev_fuser3, get_gametime() + RELOAD_TIME)
		}
		
		if(iRel == 2)
		{
			set_pev(iEnt, pev_iuser4, 0)
			set_pev(iEnt, pev_fuser3, 0.0)
		}
	}
	
	if(get_member(iEnt, m_Weapon_fInReload) && !iRel)
	{
		// if (LibraryExists(LIBRARY_MD, LibType_Library))
		// {
		// 	set_pev(id, pev_viewmodel2, V_CHAINSR)
		// 	md_removedrawing(id, 1, 11)
		// }
		
		set_pev(iEnt, pev_iuser4, 1)
		set_pev(iEnt, pev_fuser3, get_gametime() + 0.65)
	}
} 
/* =========================================
------- End of Weapon Core Function --------
========================================= */

/* =========================================
---------- Entities and Specials -----------
========================================= */
public fw_StartFrame() // csbtedhan
{
	new iEnt = -1
	while((iEnt = find_ent_by_class(iEnt, "beam")) > 0)
	{
		if(!is_valid_ent(iEnt) || pev(iEnt, pev_iuser1) != 2023)
			continue;
		
		new Float:dmgtime, Float:color[3], Float:stay
		pev(iEnt,pev_dmgtime, dmgtime)
		pev(iEnt,pev_fuser1, stay)
		pev(iEnt,pev_rendercolor, color)
		
		if(dmgtime - get_gametime() < stay)
		{
			color[0] = floatmax(0.0, color[0] - 16.0)
			color[1] = floatmax(0.0, color[1] - 16.0)
			color[2] = floatmax(0.0, color[2] - 16.0)
			set_pev(iEnt,pev_rendercolor, color)
		}
		
		if(dmgtime <= get_gametime())
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
	}
}

public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, CHAINSR_MFNAME))
	{
		static Float:fFrame, Float:fFrameMax,iWpn,iType, Float:fNext
		pev(ent, pev_frame, fFrame)
		iWpn = pev(ent, pev_iuser4)
		iType = pev(ent, pev_iuser1)
		pev(ent, pev_fuser1, fNext)
		
		if(!iType)
		{
			if(!pev_valid(iWpn))
				return
			
			fFrameMax = g_cache_frame_mf
			
			fFrame += 1.0
			set_pev(ent, pev_frame, fFrame)
			
			if(fFrame >= fFrameMax || !iWpn)
			{
				set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
				return
			}
			set_pev(ent, pev_nextthink, get_gametime() + fNext)
		} else {
			fFrameMax = float(engfunc(EngFunc_ModelFrames, pev(ent, pev_modelindex)))
			
			fFrame += 1.0
			set_pev(ent, pev_frame, fFrame)
			
			set_pev(ent, pev_nextthink, get_gametime() + fNext)
			
			if(fFrame >= fFrameMax)
			{
				set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
				return
			}
		}
		return
	}
}

public Fw_ChainsrEnt_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
		
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, CHAINSR_SHDWNAME))
		return
	
	new iOwner
	iOwner = pev(iEnt, pev_owner)
	
	if(!is_connected(iOwner) || !is_alive(iOwner) || !Get_BitVar(g_Had_Base,iOwner))
	{
		remove_entity(iEnt)
		return
	}
	
	new iMode
	iMode = pev(iEnt, pev_iuser1)
	
	if(iMode == 1) set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME) // blast
	else if(iMode == 2) // shadow
	{
		static Float:fTimeRemove, Float:fRenderMount; 
		pev(iEnt, pev_ltime, fTimeRemove)
		pev(iEnt, pev_renderamt, fRenderMount)
		
		static Float:fFrame, Float:vOrig[3]
		pev(iEnt, pev_frame, fFrame)
		pev(iEnt, pev_origin, vOrig)
		
		fFrame += 1.0
		set_pev(iEnt, pev_frame, fFrame)
		
		fRenderMount -= 2.0
		set_pev(iEnt,pev_renderamt,fRenderMount)
		
		if(fRenderMount <= 0.0)
		{
			set_pev(iEnt, pev_iuser1, 0)
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return
		}
		
		set_pev(iEnt, pev_nextthink, get_gametime()+0.01)
	} else { // null
		static Float:vOrig[3], pEntity
		pev(iEnt, pev_origin, vOrig)
		pEntity = pev(iEnt, pev_iuser2)
		if(is_entity(pEntity) == false){
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return;
		}
		Summon_GojoSatoru(iOwner, pEntity, vOrig)
		client_cmd(iOwner, "spk %s", SOUND_FIRE[2])
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrig, 0);
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, vOrig[0])
		engfunc(EngFunc_WriteCoord, vOrig[1])
		engfunc(EngFunc_WriteCoord, vOrig[2] + 1.0)
		write_short(g_cache_skill[0])
		write_byte(7)
		write_byte(25)
		write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES)
		message_end()
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrig, 0);
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, vOrig[0])
		engfunc(EngFunc_WriteCoord, vOrig[1])
		engfunc(EngFunc_WriteCoord, vOrig[2] + 80.0)
		write_short(g_cache_skill[1])
		write_byte(15)
		write_byte(25)
		write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES)
		message_end()
		
		if(pEntity && IsAlive(pEntity)) 
		{
			static Float:vOrig2[3]; pev(pEntity, pev_origin, vOrig2)
			SpawnBlood(vOrig2, get_member(pEntity, m_bloodColor), random_num(30, 50))
			client_cmd(iOwner, "spk %s", SOUND_FIRE[0])
			
			new Float:iHealth, Float:fDmg
			iHealth = get_entvar(pEntity , var_health)
			if (LibraryExists(LIBRARY_ZP, LibType_Library)) fDmg = SHADOW_DAMAGEZB
			else fDmg = SHADOW_DAMAGE
			ExecuteHamB(Ham_TakeDamage, pEntity, iOwner, iOwner, fDmg, DMG_BULLET)
			set_entvar(pEntity,var_iuser3, 0)
			if(iHealth <= fDmg)
			{
				new iHitGroup = get_member(pEntity,m_LastHitGroup)
				Summon_GojoSatoru_Pre(iOwner, pEntity)
			} 
		}
		
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
	}
}

public MakeMuzzleFlash(id, iEnt, body, typ, mdl[], Float:fNext)
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, mdl, CHAINSR_MFNAME, SOLID_NOT,fNext)
	set_pev(iMuz, pev_body, body)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.07)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
	
	if(typ)
	{
		set_pev(iMuz, pev_framerate, 1.0)
		set_pev(iMuz, pev_modelindex, engfunc(EngFunc_ModelIndex, mdl))
	}
	
	set_pev(iMuz, pev_iuser1, typ)
	set_pev(iMuz, pev_iuser4, iEnt)
	set_pev(iMuz, pev_fuser1, fNext)
	set_pev(iMuz, pev_owner, id)
	dllfunc(DLLFunc_Spawn, iMuz)
}

public native_CreateBlast(ids , nums){
	new id = get_param(1)
	new Float:vecOrigin[3];
	pev(id, pev_origin, vecOrigin)
	
	vecOrigin[2] -= 5.0
	
	new iEnt = Stock_CreateEntityBase(id, "info_target", 0, SpecialModels[1], CHAINSR_SHDWNAME, SOLID_NOT,0.2)
	set_pev(iEnt, pev_origin, vecOrigin)
	set_pev(iEnt, pev_frame, 0.0)
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, 1.0)
	set_pev(iEnt, pev_sequence, 1)
	engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_iuser1, 1);
	set_pev(iEnt, pev_scale, 1.0);
	
}

public CSR_Blast(id)
{
	new Float:vecOrigin[3];
	pev(id, pev_origin, vecOrigin)
	
	vecOrigin[2] -= 5.0
	
	new iEnt = Stock_CreateEntityBase(id, "info_target", 0, SpecialModels[1], CHAINSR_SHDWNAME, SOLID_NOT,0.2)
	set_pev(iEnt, pev_origin, vecOrigin)
	set_pev(iEnt, pev_frame, 0.0)
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, 1.0)
	set_pev(iEnt, pev_sequence, 1)
	engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_iuser1, 1);
	set_pev(iEnt, pev_scale, 1.0);
	
	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, BLAST_RANGE)) != 0)
	{
		if (!is_entity(pEntity))
			continue;
		if (id == pEntity)
			continue;
		if (!is_alive(pEntity) || !can_damage(id, pEntity))
			continue;
		
		Stock_Fake_KnockBack(id, pEntity, BLAST_KNOCK)
	}
	
	emit_sound(id, CHAN_VOICE, SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public Summon_GojoSatoru_Pre(id, vic)
{
	new Float:vEntOrigin[3]
	pev(vic, pev_origin, vEntOrigin)
	
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(iEnt, pev_classname, CHAINSR_SHDWNAME)
	set_pev(iEnt, pev_origin, vEntOrigin)
	// engfunc(EngFunc_SetModel, iEnt, "models/w_usp.mdl")
	set_pev(iEnt, pev_nextthink, get_gametime() + 1.0)
	set_pev(iEnt, pev_iuser1, 0)
	fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	set_pev(iEnt, pev_owner, id)
	
	new pEntity = Stock_Find_SubVic(id, iEnt, vEntOrigin, SHADOW_RANGE)	
	if(pEntity && IsAlive(id) && IsAlive(pEntity)){
		set_pev(iEnt, pev_iuser2, pEntity)
		set_pev(pEntity, pev_iuser3 , 1)
	}
	else{
		set_pev(iEnt, pev_iuser2, -1)
	}
}

stock Summon_GojoSatoru(id, vic, Float:fAtkOrig[3])
{
	new Float:fRes[3], Float:fVicOrig[3], Float:vecVelocity[3], Float:vAngle[3]
	
	if(vic == -1)
	{
		xs_vec_copy(fAtkOrig, fRes)
		vAngle[1] = random_float(0.0, 315.0)
	} else {
		pev(vic, pev_origin, fVicOrig)
		pev(vic, pev_v_angle, vAngle)
		
		new Float:vDir[3]
		xs_vec_sub(fVicOrig, fAtkOrig, vDir)
		xs_vec_normalize(vDir, vDir)
		xs_vec_add(fAtkOrig, vDir, fRes)
		
		Stock_GetSpeedVector(fRes, fVicOrig, 0.01, vecVelocity);
		vector_to_angle(vecVelocity, vAngle)
		if(vAngle[0] > 90.0) vAngle[0] = -(360.0 - vAngle[0]);
	}
	
	new iEfx = Stock_CreateEntityBase(id, "info_target", MOVETYPE_NONE, SpecialModels[0], CHAINSR_SHDWNAME, SOLID_NOT, 0.0)
	set_pev(iEfx, pev_origin, fRes)
	set_pev(iEfx, pev_rendermode, kRenderTransTexture)
	set_pev(iEfx, pev_renderamt, 255.0)
	set_pev(iEfx, pev_angles, vAngle);
	set_pev(iEfx, pev_animtime, get_gametime())
	set_pev(iEfx, pev_sequence, (vic > 0) ? 1 : 0)
	set_pev(iEfx, pev_framerate, 1.0)
	set_pev(iEfx, pev_iuser1, 2)
	if(vic > 0) set_pev(iEfx, pev_velocity, vecVelocity);
	set_pev(iEfx, pev_nextthink, get_gametime())
	engfunc(EngFunc_SetSize, iEfx, Float:{-0.1, -0.1, -0.1}, Float:{0.1, 0.1, 0.1})
	drop_to_floor(iEfx)
	
	if(vic > 0) 
	{
		static Float:origin[3], Float:angles[3], Float:hope[3]
		engfunc(EngFunc_GetAttachment, iEfx, 0, hope, 0);
		pev(iEfx, pev_angles, angles);
		pev(iEfx, pev_origin, origin);
		
		hope[0] -= origin[0];
		hope[1] -= origin[1];
		
		new Float:x, Float:y, Float:c, Float:s;
		x = hope[0];
		y = hope[1];
		c = floatcos(angles[1], degrees);
		s = floatsin(angles[1], degrees);
		hope[0] = x * c - y * s;
		hope[1] = y * c + x * s;
		
		hope[0] += origin[0];
		hope[1] += origin[1];
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, hope, 0);
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, hope[0])
		engfunc(EngFunc_WriteCoord, hope[1])
		engfunc(EngFunc_WriteCoord, hope[2] - 12.0)
		write_short(g_cachde_mf2)
		write_byte(1)
		write_byte(27)
		write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES)
		message_end()
	}
}
stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}

stock Beam_RelinkBeam(const iBeamEntity)
{
	new Float:flOrigin[3],Float:flStartPos[3],Float:flEndPos[3];
	new Float:flMins[3],Float:flMaxs[3];
	
	get_entvar(iBeamEntity, var_origin, flOrigin);
	get_entvar(iBeamEntity, var_origin, flStartPos);
	get_entvar(iBeamEntity, var_angles, flEndPos);
	
	flMins[0] = floatmin(flStartPos[0], flEndPos[0]);
	flMins[1] = floatmin(flStartPos[1], flEndPos[1]);
	flMins[2] = floatmin(flStartPos[2], flEndPos[2]);
	
	flMaxs[0] = floatmax(flStartPos[0], flEndPos[0]);
	flMaxs[1] = floatmax(flStartPos[1], flEndPos[1]);
	flMaxs[2] = floatmax(flStartPos[2], flEndPos[2]);
	
	xs_vec_sub(flMins, flOrigin, flMins);
	xs_vec_sub(flMaxs, flOrigin, flMaxs);
	
	set_entvar(iBeamEntity, var_mins, flMins);
	set_entvar(iBeamEntity, var_maxs, flMaxs);
	
	engfunc(EngFunc_SetSize, iBeamEntity, flMins, flMaxs);
	engfunc(EngFunc_SetOrigin, iBeamEntity, flOrigin);
}
/* ========================================
------- End of Entities and Specials ------
=========================================== */

/* ======================================
------------------- Stocks --------------
========================================= */
stock Stock_DeathMsg(id, victim, szWhat[], isHS = 0)
{
	fm_set_user_frags(id, get_user_frags(id) + 1)

	//Update killers scorboard with new info
	message_begin(MSG_ALL,get_user_msgid("ScoreInfo"))
	write_byte(id)
	write_short(get_user_frags(id))
	write_short(get_user_deaths(id))
	write_short(1)
	write_short(get_user_team(id))
	message_end()

	//Update victims scoreboard with correct info
	message_begin(MSG_ALL,get_user_msgid("ScoreInfo"))
	write_byte(victim)
	write_short(get_user_frags(victim))
	write_short(get_user_deaths(victim))
	write_short(0)
	write_short(get_user_team(victim))
	message_end()

	message_begin(MSG_ALL, get_user_msgid("DeathMsg"),{0,0,0},0)
	write_byte(id)
	write_byte(victim)
	write_byte(isHS)
	write_string(szWhat)
	message_end()
}

stock Stock_Get_Postion(id,Float:forw,Float:right, Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
} 

stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

stock bool:can_damage(id1, id2)
{
	new flg = get_entvar(id2 , var_flags)
	if(flg & FL_MONSTER && GetIsNpc(id2)){
		new team = KrGetFakeTeam(id2)
		if(!FClassnameIs(id1 , "player"))
			return false
		new team2 = cs_get_user_team(id1)
		return team != team2
	}
		

	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return true
		
	// Check team
	return(get_member(id1, m_iTeam) != get_member(id2, m_iTeam))
}

public Stock_Fake_KnockBack(id, iVic, Float:iKb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}	

stock IsAlive(pEntity)
{
	if (pEntity < 1)
		return 0;

	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0.0);
}

stock IsPlayer(pEntity)
{
	if (pEntity <= 0 || !IsAlive(pEntity))
		return 0;

	return ExecuteHam(Ham_Classify, pEntity) == 2;
}

/**
 * 	By csbtedhan
 * id == playerid
 * ent == createent
 */
stock Stock_Find_SubVic(const id, ent, Float:origin[3], Float:fRange)
{
	new enemys, Float:dist, Float:distmin, Float:originT[3]
	
	for(new target = 0; target < get_maxplayers(); target++)
	{
		if (id == target || !IsPlayer(target) || get_entity_flags(target) & FL_NOTARGET || ent == target)
			continue;
		if(!can_damage(ent, target) || !can_damage(id, target))
			continue
			
		dist = entity_range(ent, target)
		
		if(dist > fRange)
			continue;
			
		pev(target, pev_origin, originT)
		originT[2] += 15.0

		if ((!distmin || dist <= distmin) && Stock_CanSee(ent, target))
		{
			distmin = dist
			enemys = target
		}
	}

	new target = -1
	while((target = find_ent_in_sphere(target, origin, fRange)) != 0)
	{
		if (id == target || ent == target || is_nullent(target) )
			continue;
		if(!can_damage(id, target))
			continue
		if(get_entvar(target,var_deadflag) == DEAD_DEAD || get_entvar(target,var_takedamage) == DAMAGE_NO)
			continue
		if(get_entvar(target,var_iuser3) == 1)
			continue
		dist = entity_range(ent, target)
		pev(target, pev_origin, originT)
		originT[2]+= 20.0

		if ((!distmin || dist <= distmin) && Stock_isClearLine(origin, originT))
		{
			distmin = dist
			enemys = target
		}	
	}
	return enemys
}

stock Stock_isClearLine(Float:ent_origin[3], Float:target_origin[3])
{
	new Float:hit_origin[3]
	trace_line(-1, ent_origin, target_origin, hit_origin)						

	if (!vector_distance(hit_origin, target_origin)) return 1;
	return 0;
}

stock bool:Stock_CanSee(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		
		if (flags & EF_NODRAW)
			return false
		
		new Float:lookerOrig[3],Float:targetBaseOrig[3],Float:targetOrig[3],Float:temp[3]

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
		
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater)) return false
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) return true
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) return true
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
						return true
				}
			}
		}
	}
	return false
}

stock SpawnBlood(const Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount == 0)
		return

	if (!iColor)
		return

	iAmount *= 2
	if(iAmount > 255) iAmount = 255
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(iColor)
	write_byte(min(max(3, iAmount / 10), 16))
	message_end()
}

stock Stock_Drop_Slot(id,iSlot)
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++)
	{
		new slot = Stock_Get_Wpn_Slot(weapons[i]);
		if (iSlot == slot)
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock Stock_Get_Wpn_Slot(iWpn)
{
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

	if(PRIMARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 1
	else if(SECONDARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 2
	else if(iWpn==CSW_KNIFE) return 3
	else if(iWpn == CSW_HEGRENADE) return 4
	else if(iWpn == CSW_C4) return 5
	return 6 //FLASHBANG SMOKEBANG
}

stock Set_WeaponAnim(id, anim, iCheck=0)
{
	if(iCheck && pev(id, pev_weaponanim) == anim)
		return;

	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock set_nextattack(weapon, player, Float:nextTime, Float:nextIdle = 0.0)
{
	if(is_nullent(weapon))	
		return
	
	static Float:fTime
	if(nextIdle == 0.0) fTime = (nextTime + 0.5)
	else fTime = nextIdle
	
	set_member(weapon, m_Weapon_flNextPrimaryAttack, nextTime)
	set_member(weapon, m_Weapon_flNextSecondaryAttack, nextTime)
	if(nextIdle != -1.0) set_member(weapon, m_Weapon_flTimeWeaponIdle, fTime)
	set_member(player, m_flNextAttack, nextTime)
}

stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	new Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

stock Make_BulletSmoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}
/* ======================================
------------- End of Stocks -------------
========================================= */

/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Safety_Killed_Post", 1)
}

public Safety_Connected(id)
{
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_CurWeapon(id)
{
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0

	return 1
}

public is_alive(id)
{
	if(!is_connected(id))
		return 0
	if(!Get_BitVar(g_IsAlive, id))
		return 0
		
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}
/* ===============================
--------- END OF SAFETY  ---------
=================================*/
