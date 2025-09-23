#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <engine>
#include <xp_module>
#include <kr_core>
#include <props>
#include <xs>
#include <animation>

#define var_Attack "at1"
#define var_charingState "state"
#define var_Charge "cha"
#define var_lastbutton "lab"
#define var_NextCtime "ctim"
#define GetNextAttackCTime(%1) get_member(%1 , m_Weapon_flAccuracy)
#define SetNextAttackCTime(%1,%2) set_member(%1 , m_Weapon_flAccuracy , %2)
#define GetAttackNum(%1) get_prop_int(%1 , var_Attack)
#define SetAttackNum(%1,%2) set_prop_int(%1 , var_Attack , %2)
#define GetCharge(%1) get_prop_float(%1 , var_Charge)
#define SetCharge(%1,%2) set_prop_float(%1 , var_Charge , %2)
#define GetStatus(%1) get_prop_int(%1,var_charingState)
#define SetStatus(%1,%2) set_prop_int(%1,var_charingState,%2)
#define GetLastbutton(%1) get_prop_int(%1,var_lastbutton)
#define SetLastbutton(%1,%2) set_prop_int(%1,var_lastbutton,%2)

#define knf_cost 200.0

new ResModel [][]={
    "models/v_divinespear_new.mdl",
    "models/p_divinespear.mdl",
    "models/ef_divinespear.mdl",
    "models/ef_divinespear_cyclone_small.mdl",//3
    "models/ef_divinespear_cyclone_big.mdl",//4

	"sprites/laserbeam.spr", //5
	"sprites/ef_divinespear_explo.spr", // 6
}

new Res_sounds[][]={
	"weapons/divinespear/divinespear_draw.wav", // 0
	"weapons/divinespear/divinespear_attack1.wav", // 1
	"weapons/divinespear/divinespear_attack2.wav", // 2
	"weapons/divinespear/divinespear_attack3.wav", // 3
	"weapons/divinespear/divinespear_attack4.wav", // 4
	"weapons/katana_hitwall.wav", 				//5
	"weapons/divinespear/divinespear_charging_start.wav",//6
	"weapons/divinespear/divinespear_charging_end.wav",//7
	"weapons/dualsword_stab1_hit.wav",//8
	"weapons/divinespear/divinespear_throw.wav",//9
	"weapons/divinespear/divinespear_exp.wav",//10
	"weapons/divinespear/divinespear_win1.wav",//11
	"weapons/divinespear/divinespear_win2.wav",//12

}

new Res_idelSound[][]={
	"weapons/divinespear/divinespear_idle.wav", //0
	"weapons/divinespear/divinespear_idle2.wav", //1 
	"weapons/divinespear/divinespear_idle2_2.wav",// 2
}

enum
{
	HIT_NONE,
	HIT_ENEMY,
	HIT_WALL
};

enum v_sequence{
    idel,
    attack_1,
    attack_2,
    attack_3,
    attack_4,
    draw,
    slash,
    charging_start,
    charging_loop,
    charging_shoot,
    charging_end,
    end_shoot,
    throw
}

enum status{
	s_start = 0,
	s_loop,
	s_end,
	s_dononting,
}

new handleNewRound, HC_AddPlayerItem, HC_DefaultDeploy, HAM_Item_PostFrame
new Message_WeaponListID
new const Weapon_DefinitionID = 1919145
new iTotalPlayerUseWeapon
new FW_EmitSound, FW_UpdateClientData, FW_OnFreeEntPrivateData;
new Weapon_EntityID[33]
new iBloodPrecacheID[2]

new LineSpr , ExpSpr

new wpnid

native Get_Divinespear(id , Float:AmmoCost = 0.0)

public plugin_init()
{
	register_plugin("万钧神威", "1.0", "冰桑");

	register_clcmd("knife_divinespear", "Hook_Knife");
	
	register_clcmd("gd", "FreeGive");

	// disable_event(handleNewRound = register_event("HLTV", "OnNewRound", "a", "1=0", "2=0"))

	DisableHookChain(HC_AddPlayerItem = RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "CBasePlayer_AddPlayerItem", false));
	DisableHookChain(HC_DefaultDeploy = RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy", false));
	// RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", true);
	// RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed");

	DisableHamForward(HAM_Item_PostFrame = RegisterHam(Ham_Item_PostFrame, "weapon_knife", "Item_PostFrame", false));
	
	Message_WeaponListID = get_user_msgid("WeaponList");

	wpnid = BulidWeaponMenu("万钧神威", knf_cost)
	
}

public ItemSel_Post(id, items, Float:cost){
	if(items == wpnid){
		Get_Divinespear(id , cost)
	}
}

public plugin_precache(){
    for(new i = 0 ; i < sizeof ResModel ; i++){
		if( i == 5){
			LineSpr = precache_model(ResModel[i])
			continue
		}
		else if(i == 6){
			ExpSpr = precache_model(ResModel[i])
			continue
		}
		precache_model(ResModel[i])
    }
    for(new i = 0 ; i < sizeof Res_sounds ; i++){
        UTIL_Precache_Sound(Res_sounds[i])
    }
    for(new i = 0 ; i < sizeof Res_idelSound ; i++){
        precache_sound(Res_idelSound[i])
    }
	iBloodPrecacheID[0] = precache_model("sprites/bloodspray.spr");
	iBloodPrecacheID[1] = precache_model("sprites/blood.spr");
}

public plugin_natives(){
    register_native("Get_Divinespear", "Native_Get_Divinespear")
}

public Hook_Knife(id){
    engclient_cmd(id, "weapon_knife");
	return PLUGIN_HANDLED;
}

public FreeGive(id){
	if(!is_user_admin(id))
		return
    Get_Divinespear(id , 0.0)
}

public EmitSound(const clientIndex, const iChannel, const szSound[])
{
	if(szSound[14] == 'd' && szSound[15] == 'e' && szSound[16] == 'p') 
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

public UpdateClientData(const clientIndex, sendweapons, cd_handle)
{
    if (Weapon_EntityID[clientIndex] <= 0)
       	return FMRES_IGNORED;

    set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001);     
    return FMRES_HANDLED;
}

public OnEntityRemoved(const entityIndex)
{
	if(get_entvar(entityIndex, var_impulse) == Weapon_DefinitionID)
	{
		new clientIndex = get_member(entityIndex, m_pPlayer);

		message_begin(MSG_ONE_UNRELIABLE, Message_WeaponListID, _, clientIndex); 
		write_string("weapon_knife");
		write_byte(-1);
		write_byte(-1);
		write_byte(-1);
		write_byte(-1);
		write_byte(2);
		write_byte(1);
		write_byte(CSW_KNIFE);
		write_byte(0);
		message_end();

		if(--iTotalPlayerUseWeapon <= 0)
		{
			DisableHookChain(HC_DefaultDeploy);
			DisableHamForward(HAM_Item_PostFrame);

			unregister_forward(FM_EmitSound, FW_EmitSound, false);
			unregister_forward(FM_UpdateClientData, FW_UpdateClientData, true);
			unregister_forward(FM_OnFreeEntPrivateData, FW_OnFreeEntPrivateData, false);
		}

		remove_task(entityIndex+Weapon_DefinitionID);
		if(entityIndex == Weapon_EntityID[clientIndex]){
			Weapon_EntityID[clientIndex] = NULLENT;
		}
	}
}

public Native_Get_Divinespear(iPlugin, iParams)
{
	new clientIndex = get_param(1);
    new Float:buy_cost = get_param_f(2)
	new Float:ammos = GetAmmoPak(clientIndex)
	if(ammos < buy_cost){
		m_print_color(clientIndex, "!g[冰布提示]大洋不足以购买此武器")
		return
	}
	SubAmmoPak(clientIndex , buy_cost)
	if(clientIndex > 0 && clientIndex <= MAX_PLAYERS)
	{
		EnableHookChain(HC_AddPlayerItem);
		rg_give_custom_item(clientIndex, "weapon_knife", GT_REPLACE, Weapon_DefinitionID);
		DisableHookChain(HC_AddPlayerItem);
		engclient_cmd(clientIndex, "weapon_knife");
	}	
}

public CBasePlayer_AddPlayerItem(const clientIndex, const iWeaponEntityID)
{
	message_begin(MSG_ONE_UNRELIABLE, Message_WeaponListID, _, clientIndex); 
	write_string("knife_divinespear");
	write_byte(-1);
	write_byte(-1);
	write_byte(-1);
	write_byte(-1);
	write_byte(2);
	write_byte(1);
	write_byte(CSW_KNIFE);
	write_byte(0);
	message_end();

	if(++iTotalPlayerUseWeapon == 1)
	{
		EnableHookChain(HC_DefaultDeploy);
		EnableHamForward(HAM_Item_PostFrame);

		FW_EmitSound = register_forward(FM_EmitSound, "EmitSound", false);
		FW_UpdateClientData = register_forward(FM_UpdateClientData, "UpdateClientData", true);
		FW_OnFreeEntPrivateData = register_forward(FM_OnFreeEntPrivateData, "OnEntityRemoved", false);
	}

	return HC_CONTINUE;
}

public CBasePlayerWeapon_DefaultDeploy(const iWeaponEntityID, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[], const skiplocal) 
{
	new clientIndex = get_member(iWeaponEntityID, m_pPlayer); 
   	if(get_entvar(iWeaponEntityID, var_impulse) == Weapon_DefinitionID)
	{
		SetHookChainArg(2, ATYPE_STRING, ResModel[0]); 
		SetHookChainArg(3, ATYPE_STRING, ResModel[1]); 
		SetHookChainArg(4, ATYPE_INTEGER, draw); 
		SetHookChainArg(5, ATYPE_STRING, "knife"); 

		// set_task(1.0, "Task_Idle", iWeaponEntityID+Weapon_DefinitionID);
		
		Weapon_EntityID[clientIndex] = iWeaponEntityID; 

		RequestFrame("Refresh_ViewModel", clientIndex);
		SetAttackNum(iWeaponEntityID , 0)
		SetStatus(iWeaponEntityID , 0)
		SetLastbutton(clientIndex , 0)
		SetCharge(iWeaponEntityID , get_gametime())
		UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[0])
	}else if(Weapon_EntityID[clientIndex] > 0) {
		SetThink(Weapon_EntityID[clientIndex], "");
		remove_task(Weapon_EntityID[clientIndex]+Weapon_DefinitionID);
		Weapon_EntityID[clientIndex] = 0; 
	}
    return HC_CONTINUE;
}

public CWeapon__Holster_Post(const pItem){
	if(get_entvar(pItem, var_impulse) != Weapon_DefinitionID)	
		return
	static pPlayer; pPlayer = get_member(pItem , m_pPlayer)
	emit_sound(pPlayer, CHAN_WEAPON, Res_idelSound[0], VOL_NORM, ATTN_NONE, 0, PITCH_NORM);
}

public Refresh_ViewModel(const clientIndex)
{
	new weaponEntity = Weapon_EntityID[clientIndex]
	if(weaponEntity > 0)
	{
		set_entvar(clientIndex, var_viewmodel, ResModel[0]);
		set_entvar(clientIndex, var_weaponmodel, ResModel[1]);

		Weapon_Animation(clientIndex, v_sequence:draw);

		SetThink(weaponEntity, "Think_Buttons");
		set_entvar(weaponEntity, var_nextthink, get_gametime() + 1.0); 
	}
}

public Think_Buttons(iWeaponEntityID){
	static clientIndex; clientIndex = get_member(iWeaponEntityID, m_pPlayer); 
	static Button; Button = get_entvar(clientIndex, var_button); 
	static LastButton;LastButton = GetLastbutton(clientIndex)
	static Float:Time; Time = get_gametime(); 
	static iTotalSlash, iTotalStab;
	set_entvar(iWeaponEntityID, var_nextthink, Time + 0.1);
	if(Button & IN_ATTACK && !(Button & IN_ATTACK2)){
		remove_task(iWeaponEntityID + Weapon_DefinitionID);
		AttackInAttack1(clientIndex , iWeaponEntityID);
		SetLastbutton(clientIndex , Button | IN_ATTACK)
	}
	else if(Button & IN_RELOAD){
		remove_task(iWeaponEntityID + Weapon_DefinitionID);
		Throw(clientIndex , iWeaponEntityID)
		SetLastbutton(clientIndex , Button | IN_RELOAD)
		set_entvar(iWeaponEntityID, var_nextthink, Time + 0.35);
	}else if(Button & IN_ATTACK2 && Button & IN_ATTACK && !(LastButton & IN_ATTACK)){
		remove_task(iWeaponEntityID + Weapon_DefinitionID);
		Attack_c(clientIndex , iWeaponEntityID)
	}
	else if(Button & IN_ATTACK2){
		remove_task(iWeaponEntityID + Weapon_DefinitionID);
		AttackInAttack2(clientIndex , iWeaponEntityID)
		SetLastbutton(clientIndex , Button | IN_ATTACK2)
	}
	else if(!(Button & IN_ATTACK2) && LastButton & IN_ATTACK2){
		remove_task(iWeaponEntityID + Weapon_DefinitionID);
		Attack2Release(clientIndex , iWeaponEntityID);
		SetLastbutton(clientIndex , 0)
		set_entvar(iWeaponEntityID, var_nextthink, Time + 0.75);
	}
}

public Throw(clientIndex , iWeaponEntityID){
	new Float:origin[3]
	Weapon_Animation(clientIndex , throw)
	get_position(clientIndex, 20.0, 0, 0, origin)
	CreateThrow(clientIndex , origin)
	UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[9])
	set_task(0.5 , "PriAttackEnd" , iWeaponEntityID + Weapon_DefinitionID)
}

public AttackInAttack2(clientIndex , iWeaponEntityID){
	new m_status = GetStatus(iWeaponEntityID)
	new Float:ChargeTime = GetCharge(iWeaponEntityID)
	new Float:GameTime = get_gametime()
	switch(m_status){
		case s_start:{
			SetCharge(iWeaponEntityID , GameTime + (7.0 / 30.0))
			SetStatus(iWeaponEntityID , s_loop)
			Weapon_Animation(clientIndex , charging_start)
			UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[6])
		}
		case s_loop:{
			if(ChargeTime > GameTime)
				return
			Weapon_Animation(clientIndex , charging_loop)
			SetCharge(iWeaponEntityID , GameTime + 3.0)
			SetStatus(iWeaponEntityID , s_end)

		}
		case s_end:{
			emit_sound(clientIndex , CHAN_WEAPON , Res_idelSound[2], 0.6, 0.4, 0, 94 + random_num(0, 55))
			if(ChargeTime > GameTime)
				return
			UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[7])
			Weapon_Animation(clientIndex , charging_end)
			SetStatus(iWeaponEntityID , s_dononting)
		}
		case s_dononting:{
			emit_sound(clientIndex , CHAN_WEAPON , Res_idelSound[1], 0.6, 0.4, 0, 94 + random_num(0, 55))
		}
	}
	set_task(1.0 , "PriAttackEnd" , iWeaponEntityID + Weapon_DefinitionID)
}

public Attack_c(clientIndex , iWeaponEntityID){
	new Float:timeNextAttaack = GetNextAttackCTime(iWeaponEntityID)
	if(get_gametime() < timeNextAttaack)
		return
	SetNextAttackCTime(iWeaponEntityID , get_gametime() + 10.5)
	Weapon_Animation(clientIndex , charging_shoot)
	Create_cyclone(clientIndex , true)
	UTIL_EmitSound_ByCmd(0 , Res_sounds[12])
}

public Attack2Release(clientIndex , iWeaponEntityID){
	new m_status = GetStatus(iWeaponEntityID)
	switch(m_status){
		case s_start , s_loop , s_end:{
			//执行右键攻击
			new Float:timeNextAttaack = get_gametime() + (41.0 / 30.0)
			Weapon_Animation(clientIndex , slash)
			new Hit = Do_Damage(clientIndex, 300.0, 500.0, 360.0, 0.0, 0.0, 0.0);
			switch(Hit)
			{
				case HIT_WALL:	UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[5])
				case HIT_ENEMY:	UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[8])
			}
			set_entvar(iWeaponEntityID, var_nextthink, timeNextAttaack);
			set_task(timeNextAttaack + 0.1 ,"PriAttackEnd" , iWeaponEntityID + Weapon_DefinitionID)
			SetStatus(iWeaponEntityID , s_start)
		}
		case s_dononting:{
			//释放旋风
			new Float:timeNextAttaack = get_gametime() + (19.0 / 30.0)
			Weapon_Animation(clientIndex , end_shoot)
			Create_cyclone(clientIndex)
			UTIL_EmitSound_ByCmd(0 , Res_sounds[11])
			set_task(timeNextAttaack + 0.1 ,"PriAttackEnd" , iWeaponEntityID + Weapon_DefinitionID)
			SetStatus(iWeaponEntityID , s_start)
		}
	}
}

public AttackInAttack1(clientIndex , iWeaponEntityID){
	new num = GetAttackNum(iWeaponEntityID);
	new seq = attack_1 + num
	if(seq >= attack_4){
		SetAttackNum(iWeaponEntityID , 0)
	}else{
		SetAttackNum(iWeaponEntityID , num + 1)
	}
	Weapon_Animation(clientIndex, seq);
	set_task(0.55 ,"PriAttackEnd" , iWeaponEntityID + Weapon_DefinitionID)
	UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[1 + num])
	new Hit = Do_Damage(clientIndex, 300.0, 150.0, 90.0, 0.0, 0.0, 0.0);
	switch(Hit)
	{
		case HIT_WALL:	UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[5])
		case HIT_ENEMY:	UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[8])
	}
	set_entvar(iWeaponEntityID, var_nextthink, get_gametime() + 0.45);
}

public PriAttackEnd(iWeaponEntityID){
	set_task(1.0 , "GoIdel" , iWeaponEntityID)
	iWeaponEntityID -= Weapon_DefinitionID
	if(is_nullent(iWeaponEntityID)){
		remove_task(iWeaponEntityID + Weapon_DefinitionID)
	}
	new clientIndex = get_entvar(iWeaponEntityID, var_owner);
	Weapon_Animation(clientIndex, draw);
	UTIL_EmitSound_ByCmd(clientIndex , Res_sounds[0])
}

public GoIdel(iWeaponEntityID){
	iWeaponEntityID -= Weapon_DefinitionID
	if(is_nullent(iWeaponEntityID)){
		remove_task(iWeaponEntityID + Weapon_DefinitionID)
	}
	new clientIndex = get_entvar(iWeaponEntityID, var_owner);
	if(is_user_alive(clientIndex) && GetAttackNum(iWeaponEntityID))
		SetAttackNum(iWeaponEntityID , 0)
	SetStatus(iWeaponEntityID , 0)
	SetCharge(iWeaponEntityID , get_gametime())
	SetLastbutton(clientIndex , 0)
	Weapon_Animation(clientIndex, idel);
}


public Item_PostFrame(const entityIndex)
{	
	if(Weapon_EntityID[get_member(entityIndex, m_pPlayer)] > 0) 
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public Throwtouch(ent , touched){
	new Float:fOrigin[3]
	get_entvar(ent , var_origin , fOrigin)
	new master = get_entvar(ent , var_owner)
	rg_dmg_radius(fOrigin , master , master , 350.0 , 450.0 , CLASS_PLAYER , DMG_GENERIC)
	CreateSpr(ExpSpr , ent)
	rg_remove_entity(ent)
	UTIL_EmitSound_ByCmd3(fOrigin , Res_sounds[10] , 600.0)
}

public Throwthink(ent){
	if(is_nullent(ent))return

	new attacker = get_entvar(ent, var_owner)
	if(!is_user_alive(attacker)){
		engfunc(EngFunc_RemoveEntity , ent)
		return;
	}
	new target = Find_near_ent(ent)
	if(target <= 0){
		set_entvar(ent, var_nextthink, get_gametime() + 0.1)
		return
	}
		
	new Float:vel[3],Float:org[3],Float:targetorg[3],Float:dir[3]
	get_entvar(ent, var_velocity, vel)
	get_entvar(ent, var_origin, org)
	get_entvar(target, var_origin, targetorg)

	xs_vec_sub(targetorg, org, dir)
	xs_vec_normalize(dir, dir)

	// 当前速度转为单位方向
    new Float:curdir[3]
    xs_vec_normalize(vel, curdir)

	new Float:newdir[3]
	xs_vec_lerp(curdir, dir, 0.5, newdir)
	xs_vec_normalize(newdir, newdir)

	new Float:new_angles[3]
	vector_to_angle(newdir, new_angles)   // 把方向向量转换成角度 (pitch, yaw, roll)
	set_entvar(ent, var_angles, new_angles)
	

	new Float:new_vel[3]
	xs_vec_mul_scalar(newdir, 1000.0, new_vel)
	set_entvar(ent, var_velocity, new_vel)

	set_entvar(ent, var_nextthink, get_gametime() + 0.15)
}

public cyclone_think(this){
	new Float:fOrigin[3] , ent = -1
	new Float:fVel[3]
	get_entvar(this , var_origin , fOrigin)
	new owner = get_entvar(this , var_owner)
	if(get_gametime() > get_entvar(this , var_fuser1)){
		rg_remove_entity(this)
		return
	}
	new owner_team = get_member(owner , m_iTeam)
	get_entvar(this , var_velocity , fVel)
	fVel[2] += 100.0
	while((ent = find_ent_in_sphere(ent , fOrigin , 100.0)) > 0){
		if(get_entvar(ent , var_deadflag) == DEAD_DEAD)continue
		if(ent == owner || ent == this)continue
		if(get_entvar(ent , var_effects) & EF_NODRAW)continue
		if(ExecuteHam(Ham_IsPlayer , ent) && get_member(ent , m_iTeam) == owner_team)continue
		new Flag = get_entvar(ent , var_flags)
		if(Flag & FL_MONSTER || Flag & FL_CLIENT){
			if(is_valid_ent(ent) && get_entvar(ent , var_iuser2) != this){
				ExecuteHamB(Ham_TakeDamage , ent , this , owner , 1000.0 , DMG_BULLET)
				set_entvar(ent , var_iuser2 , this)
				set_entvar(ent , var_velocity , fVel)
			}else if(is_valid_ent(ent) && get_entvar(ent , var_iuser2) == this){
				ExecuteHamB(Ham_TakeDamage , ent , this , owner , 50.0 , DMG_BULLET)
				set_entvar(ent , var_velocity , fVel)
			}
		}
	}
	set_entvar(this , var_nextthink , get_gametime() + 0.1)
}

public cycloneBig_think(this){
	new Float:fOrigin[3] , ent = -1
	new Float:fVel[3]
	get_entvar(this , var_origin , fOrigin)
	new owner = get_entvar(this , var_owner)
	if(get_gametime() > get_entvar(this , var_fuser1)){
		rg_remove_entity(this)
		return
	}
	new owner_team = get_member(owner , m_iTeam)
	while((ent = find_ent_in_sphere(ent , fOrigin , 300.0)) > 0){
		if(get_entvar(ent , var_deadflag) == DEAD_DEAD)continue
		if(ent == owner || ent == this)continue
		if(get_entvar(ent , var_effects) & EF_NODRAW)continue
		if(get_entvar(ent , var_owner) == owner)continue
		if(ExecuteHam(Ham_IsPlayer , ent) && get_member(ent , m_iTeam) == owner_team)continue
		get_entvar(ent , var_velocity , fVel)
		fVel[0] = 0.0
		fVel[1] = 0.0
		fVel[2] = 50.0
		new Flag = get_entvar(ent , var_flags)
		if(Flag & FL_MONSTER || Flag & FL_CLIENT){
			if(is_valid_ent(ent) && get_entvar(ent , var_iuser2) != this){
				ExecuteHamB(Ham_TakeDamage , ent , this , owner , 1500.0 , DMG_BULLET)
				set_entvar(ent , var_iuser2 , this)
				set_entvar(ent , var_velocity , fVel)
			}else if(is_valid_ent(ent) && get_entvar(ent , var_iuser2) == this){
				ExecuteHamB(Ham_TakeDamage , ent , this , owner , 60.0 , DMG_BULLET)
				set_entvar(ent , var_velocity , fVel)
			}
		}
	}
	set_entvar(this , var_nextthink , get_gametime() + 0.1)
}

/**
 * Stock 
 */

stock Create_cyclone(clientIndex , IsBig = false){
	new Float:Sp_Origin[3]
	get_position(clientIndex, 20.0, 0, 0, Sp_Origin)
	new Throw = rg_create_entity("env_sprite")
	if(is_nullent(Throw))
		return PLUGIN_CONTINUE
	set_entvar(Throw , var_classname , "ef_cyclone")
	engfunc(EngFunc_SetModel, Throw, IsBig ? ResModel[4] : ResModel[3])

	set_entvar(Throw , var_movetype , MOVETYPE_NOCLIP)
	set_entvar(Throw, var_solid, SOLID_TRIGGER)
	set_entvar(Throw, var_owner, clientIndex)

	set_entvar(Throw, var_mins, Float:{-1.0, -1.0, -1.0})
	set_entvar(Throw, var_maxs, Float:{1.0, 1.0, 1.0})

	new Float:fAngles[3], Float:fOrigin[3]
	// get_entvar(id , var_v_angle, fAngles)
	get_entvar(clientIndex , var_v_angle, fAngles)
	fAngles[0] *= -1.0
	// Set the origin and view
	set_entvar(Throw, var_origin, Sp_Origin)
	// set_entvar(Throw, var_angles, fAngles)
	// set_entvar(Throw, var_v_angle, fAngles)
	set_entvar(Throw , var_rendermode , kRenderTransAdd)
	set_entvar(Throw , var_renderamt , 255.0)
	set_entvar(Throw , var_fuser1 , get_gametime() + (IsBig ? 10.0 : 6.0))
	set_entvar(Throw, var_framerate, 1.0)

	IsBig ? SetThink(Throw, "cycloneBig_think") : SetThink(Throw, "cyclone_think")

	set_entvar(Throw , var_nextthink , get_gametime() + 0.1)

	new Float:fVel[3]
	if(!IsBig){
		velocity_by_aim(clientIndex, 50, fVel)	
		set_entvar(Throw, var_velocity, fVel)
	}
}

stock CreateThrow(clientIndex , Float:Sp_Origin[3]){
	new Throw = rg_create_entity("info_target")
	if(is_nullent(Throw))
		return PLUGIN_CONTINUE
	set_entvar(Throw , var_classname , "ef_Throw")
	engfunc(EngFunc_SetModel, Throw, ResModel[2])

	set_entvar(Throw , var_movetype , MOVETYPE_FLY)
	set_entvar(Throw, var_owner, clientIndex)
	
	set_entvar(Throw, var_solid, SOLID_BBOX)

	set_entvar(Throw, var_mins, Float:{-1.0, -1.0, -1.0})
	set_entvar(Throw, var_maxs, Float:{1.0, 1.0, 1.0})

	new Float:fAngles[3], Float:fOrigin[3]
	// get_entvar(id , var_v_angle, fAngles)
	get_entvar(clientIndex , var_v_angle, fAngles)
	fAngles[0] *= -1.0
	// Set the origin and view
	set_entvar(Throw, var_origin, Sp_Origin)
	set_entvar(Throw, var_angles, fAngles)
	set_entvar(Throw, var_v_angle, fAngles)

	SetThink(Throw, "Throwthink")
	SetTouch(Throw, "Throwtouch")

	set_entvar(Throw , var_nextthink , get_gametime() + 0.1)

	new Float:fVel[3]
	velocity_by_aim(clientIndex, 1000, fVel)	
	set_entvar(Throw, var_velocity, fVel)
	// Add trail
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)	// Temp entity type
	write_short(Throw)		// entity
	write_short(LineSpr)	// sprite index
	write_byte(25)	// life time in 0.1's
	write_byte(5)	// line width in 0.1's
	write_byte(255)	// red (RGB)
	write_byte(215)	// green (RGB)
	write_byte(0)	// blue (RGB)
	write_byte(255)	// brightness 0 invisible, 255 visible
	message_end()
	return Throw
}

stock Find_near_ent(id){
	new Float:min_dist = 300.0 + 1000.0
	new ent = NULLENT
	new retv = NULLENT
	new Float:org[3]
	get_entvar(id, var_origin, org)
	while(ent = rg_find_ent_by_class(ent , "hostage_entity")){
		if(get_entvar(ent, var_takedamage) == DAMAGE_NO || get_entvar(ent, var_deadflag) == DEAD_DEAD)
			continue
		if(KrGetFakeTeam(ent) == CS_TEAM_T)
			continue
		new Float:target_org[3]
		get_entvar(ent, var_origin, target_org)
		new Float:hitorigin[3]
		new hitent = fm_trace_line(id, org, target_org, hitorigin)
		if(hitent != ent)
			continue
		new Float:dist = vector_distance(org, target_org)
		if(dist < min_dist){
			min_dist = dist
			retv = ent
		}
	}

	return retv
}

stock fm_trace_line(ignoreent, const Float:start[3], const Float:end[3], Float:ret[3]) {
	engfunc(EngFunc_TraceLine, start, end, ignoreent == -1 ? 1 : 0, ignoreent, 0);

	new ent = get_tr2(0, TR_pHit);
	get_tr2(0, TR_vecEndPos, ret);

	return pev_valid(ent) ? ent : 0;
}

stock xs_vec_lerp(const Float:a[3], const Float:b[3], Float:factor, Float:out[3]) {
    for (new i = 0; i < 3; i++) {
        out[i] = a[i] + (b[i] - a[i]) * factor
    }
}

stock Weapon_Animation(const clientIndex, const iSequence) 
{
	// if(get_entvar(clientIndex, var_weaponanim) == iSequence)
	// 	return
	set_entvar(clientIndex, var_weaponanim, iSequence);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, clientIndex);
	write_byte(iSequence);
	write_byte(0);
	message_end();	
}

stock Do_Damage(const clientIndex, const Float:Damage_Range, const Float:Damage, const Float:Point_Dis, const Float:Knockback, const Float:KnockUp, const Float:Painshock)
{
	new Hit_Type, KnifeEntityID = Weapon_EntityID[clientIndex], Float:vOwnerPosition[3], Float:vVictimPosition[3], Float:vTargetPosition[3]; 
	Get_Position(clientIndex, 0.0, 0.0, 0.0, vOwnerPosition, Float:{0.0, 0.0, 0.0}, false, Float:{0.0, 0.0, 0.0}, false);

	for(new victimIndex = 1 ; victimIndex < MaxClients ; victimIndex++)
	{
		if( victimIndex == clientIndex)
			continue;
		if(!is_user_connected(victimIndex))
			continue;
		if(!rg_is_player_can_takedamage(victimIndex, clientIndex))
			continue;
		Get_Position(victimIndex, 0.0, 0.0, 0.0, vVictimPosition, Float:{0.0, 0.0, 0.0}, false, Float:{0.0, 0.0, 0.0}, false);
		if(get_distance_f(vOwnerPosition, vVictimPosition) > Damage_Range)
			continue;
		if(!Compare_Target_And_Entity_Angle(clientIndex, victimIndex, Point_Dis))
			continue;
		if(!Can_See(clientIndex, victimIndex))
			continue;

		if(!Hit_Type) Hit_Type = HIT_ENEMY; 

		if(Damage > 0.0) FakeTraceAttack(clientIndex, victimIndex, KnifeEntityID, Damage, DMG_BULLET);
		if(Painshock > 0.0) set_pdata_float(victimIndex, 108, Painshock, 5);
		if(Knockback > 0.0 || KnockUp > 0.0) Hook_Entity(victimIndex, vOwnerPosition, Knockback, KnockUp, true);	
	}

	new Find_E = -1

	while(Find_E = rg_find_ent_by_class(Find_E, "hostage_entity")){
		if(get_entvar(Find_E, var_takedamage) == DAMAGE_NO || get_entvar(Find_E,var_deadflag) == DEAD_DEAD)
			continue;
		
		Get_Position(Find_E, 0.0, 0.0, 0.0, vVictimPosition, Float:{0.0, 0.0, 0.0}, false, Float:{0.0, 0.0, 0.0}, false)
		if(get_distance_f(vOwnerPosition, vVictimPosition) > Damage_Range)
			continue;
		if(!Compare_Target_And_Entity_Angle(clientIndex, Find_E, Point_Dis))
			continue;
		if(!Can_See(clientIndex, Find_E))
			continue;
		if(!Hit_Type) Hit_Type = HIT_ENEMY; 

		if(Damage > 0.0) FakeTraceAttack(clientIndex, Find_E, KnifeEntityID, Damage, DMG_BULLET);
		if(Painshock > 0.0) set_pdata_float(Find_E, 108, Painshock, 5);
		if(Knockback > 0.0 || KnockUp > 0.0) Hook_Entity(Find_E, vOwnerPosition, Knockback, KnockUp, true);	
	}

	Get_Position(clientIndex, Damage_Range, 0.0, 0.0, vTargetPosition, Float:{0.0, 0.0, 0.0}, false, vOwnerPosition, true);
	engfunc(EngFunc_TraceLine, vOwnerPosition, vTargetPosition, DONT_IGNORE_MONSTERS, clientIndex, 0);
	new Enemy = get_tr2(0, TR_pHit); 
	if(!is_nullent(Enemy) && get_entvar(Enemy, var_takedamage) == DAMAGE_YES)
	{
		if(!Hit_Type) Hit_Type = HIT_ENEMY; 
		ExecuteHamB(Ham_TakeDamage, Enemy, KnifeEntityID, clientIndex, Damage, DMG_SLASH);
	} else if(!Hit_Type) {
		new Float:End_Origin[3]; get_tr2(0, TR_vecEndPos, End_Origin);
		if(floatround(get_distance_f(vTargetPosition, End_Origin)) && !is_user_alive(Enemy)) Hit_Type = HIT_WALL; 
	}

	return Hit_Type;
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
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

stock Get_Position(const iEntityIndex, const Float:fForwardAdd, const Float:fRightAdd, const Float:fUpAdd, Float:vPosition[3], const Float:vCustomAngle[3], const bool:WorkCustomAngle, const Float:vCustomOrigin[3], const bool:WorkCustomOrigin)
{
	static Float:vEntityAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3];
	
	if(WorkCustomOrigin) {
		vPosition = vCustomOrigin;
	} else {
		get_entvar(iEntityIndex, var_origin, vPosition);
		get_entvar(iEntityIndex, var_view_ofs, vUp);
		xs_vec_add(vPosition, vUp, vPosition);
	}
	
	if(!WorkCustomAngle)
	{
		if(iEntityIndex > MAX_PLAYERS) get_entvar(iEntityIndex, var_angles, vEntityAngle);
		else get_entvar(iEntityIndex, var_v_angle, vEntityAngle);
	} else {
		vEntityAngle = vCustomAngle;
	}

	if(fForwardAdd != 0.0) angle_vector(vEntityAngle, ANGLEVECTOR_FORWARD, vForward);
	if(fRightAdd != 0.0) angle_vector(vEntityAngle, ANGLEVECTOR_RIGHT, vRight);
	if(fUpAdd != 0.0) angle_vector(vEntityAngle, ANGLEVECTOR_UP, vUp);
	
	vPosition[0] += vForward[0] * fForwardAdd + vRight[0] * fRightAdd + vUp[0] * fUpAdd;
	vPosition[1] += vForward[1] * fForwardAdd + vRight[1] * fRightAdd + vUp[1] * fUpAdd;
	vPosition[2] += vForward[2] * fForwardAdd + vRight[2] * fRightAdd + vUp[2] * fUpAdd;
}    

stock bool:Can_See(const clientIndex, const targetIndex)
{
	new flags = pev(clientIndex, pev_flags);
	if (flags & EF_NODRAW || flags & FL_NOTARGET)
	{
		return false;
	}

	new Float:lookerOrig[3];
	new Float:targetBaseOrig[3];
	new Float:targetOrig[3];
	new Float:temp[3];

	get_entvar(clientIndex, var_origin, lookerOrig);
	get_entvar(clientIndex, var_view_ofs, temp);
	xs_vec_add(lookerOrig, temp, lookerOrig);

	get_entvar(targetIndex, var_origin, targetBaseOrig);
	get_entvar(targetIndex, var_view_ofs, temp);
	xs_vec_add(targetBaseOrig, temp, targetOrig);

	engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, IGNORE_MONSTERS, clientIndex, 0);
	if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
	{
		return false;
	} 
	else 
	{
		new Float:flFraction;
		get_tr2(0, TraceResult:TR_flFraction, flFraction);
		if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == targetIndex))
		{
			return true;
		}
		else
		{
			targetOrig = targetBaseOrig;
			engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, IGNORE_MONSTERS, clientIndex, 0); 
			get_tr2(0, TraceResult:TR_flFraction, flFraction);
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == targetIndex))
			{
				return true;
			}
			else
			{
				targetOrig = targetBaseOrig;
				targetOrig[2] -= 17.0;
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, IGNORE_MONSTERS, clientIndex, 0); 
				get_tr2(0, TraceResult:TR_flFraction, flFraction);
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == targetIndex))
				{
					return true;
				}
			}
		}
	}
	return false;
}

stock bool:Compare_Target_And_Entity_Angle(const entityIndex, const targetIndex, const Float:ViewDis)
{
	new Float:Origin[3]; get_entvar(entityIndex, var_origin, Origin);
	new Float:Angles[3]; get_entvar(entityIndex, var_v_angle, Angles);
	new Float:Target[3]; get_entvar(targetIndex, var_origin, Target);
	new Float:Radians = floatatan2(Target[1] - Origin[1], Target[0] - Origin[0], radian);
	new Float:GoalAngles[3]; GoalAngles[1] = Radians * (180 / 3.14);
    	
	new Float:Distance = 180.0 - floatabs(floatabs(GoalAngles[1] - Angles[1]) - 180.0);
	if(Distance <= ViewDis) return true;
	return false;
}

FakeTraceAttack(const iAttacker, const iVictim, const iInflictor, Float:fDamage, const iDamageType)
{
	new iTarget, iHitGroup = HIT_GENERIC; 
	new Float:vAttackerAngle[3]; get_entvar(iAttacker, var_v_angle, vAttackerAngle);
	new Float:vAttackerOrigin[3]; Get_Position(iAttacker, 0.0, 0.0, 0.0, vAttackerOrigin, vAttackerAngle, true, Float:{0.0, 0.0, 0.0}, false);
	new Float:vTargetOrigin[3]; Get_Position(iAttacker, 8192.0, 0.0, 0.0, vTargetOrigin, vAttackerAngle, true, vAttackerOrigin, true);

	engfunc(EngFunc_TraceLine, vAttackerOrigin, vTargetOrigin, DONT_IGNORE_MONSTERS, iAttacker, 0); 

	iTarget = get_tr2(0, TR_pHit);
	iHitGroup = get_tr2(0, TR_iHitgroup);
	get_tr2(0, TR_vecEndPos, vTargetOrigin);

	if(iTarget != iVictim) 
	{
		iTarget = iVictim;
		iHitGroup = HIT_STOMACH;
		get_entvar(iVictim, var_origin, vTargetOrigin);
	}

	fDamage *= Damage_Multiplier(iHitGroup);
	if(!Compare_Target_And_Entity_Angle(iTarget, iAttacker, 90.0)) fDamage *= 3.0;
	set_member(iTarget, m_LastHitGroup, iHitGroup);
	Spawn_Blood(vTargetOrigin, iHitGroup, 7);
	ExecuteHamB(Ham_TakeDamage, iTarget, iInflictor, iAttacker, fDamage, iDamageType);
}

Float:Damage_Multiplier(const iBody)
{
	new Float:X;
	switch (iBody)
	{
		case 1: X = 4.0;
		case 2: X = 2.0;
		case 3: X = 1.25;
		default: X = 1.0;
	}
	return X;
}

Spawn_Blood(const Float:Origin[3], const iBody, const iScale)
{
	new Blood_Scale;
	switch (iBody)
	{
		case HIT_HEAD: Blood_Scale = iScale+8; 
		case HIT_CHEST, HIT_STOMACH: Blood_Scale = iScale+3;
		default: Blood_Scale = iScale;
	}

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_short(iBloodPrecacheID[0]);
	write_short(iBloodPrecacheID[1]);
	write_byte(247);
	write_byte(Blood_Scale);
	message_end();
}    

Hook_Entity(const Entity, const Float:TargetOrigin[3], Float:Knockback, Float:KnockUp, bool:Mode)
{
	new Float:EntityOrigin[3];
	new Float:EntityVelocity[3];
	if(KnockUp == 0.0) get_entvar(Entity, var_velocity, EntityVelocity);
	get_entvar(Entity, var_origin, EntityOrigin);

	new Float:Distance; Distance = get_distance_f(EntityOrigin, TargetOrigin);
	new Float:Time; Time = Distance / Knockback;

	new Float:V1[3], Float:V2[3];
	if(Mode) V1 = EntityOrigin, V2 = TargetOrigin; // Konumdan İttirme 
	else V2 = EntityOrigin, V1 = TargetOrigin; // Konuma Çekme

	EntityVelocity[0] = (V1[0] - V2[0]) / Time;
	EntityVelocity[1] = (V1[1] - V2[1]) / Time;
	if(KnockUp > 0.0) EntityVelocity[2] = KnockUp;
	else if(KnockUp < 0.0) EntityVelocity[2] = (V1[2] - V2[2]) / Time;

	set_entvar(Entity, var_velocity, EntityVelocity);
}    

public CreateSpr(sprid , DeadEnt){
    new Float:fOrigin[3] , iOrigin[3]
    get_entvar(DeadEnt , var_origin , fOrigin)
    iOrigin[0] = floatround(fOrigin[0])
    iOrigin[1] = floatround(fOrigin[1])
    iOrigin[2] = floatround(fOrigin[2])
    message_begin(0 , SVC_TEMPENTITY)
    write_byte(TE_SPRITE)
    write_coord(iOrigin[0])
    write_coord(iOrigin[1])
    write_coord(iOrigin[2] + 35 )
    write_short(sprid)
    write_byte(15) // scale
    write_byte(200) // alpha
    message_end()
}