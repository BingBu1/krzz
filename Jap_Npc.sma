#include <cstrike>
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <props>
#include <fakemeta_util>
#include <xs>
#include <reapi>
#include <hamsandwich>
#include <engine_stocks>
#include <Jap_Npcconst>
#include <kr_core>
#include <roundrule>
#include <sypb>
#include <animation>

#define Jp_defname "日本暴民"
#define UpdateFakeClientTaskId 114514
#define CheckList 0x1b

#define Max_heal 200.0 //最大血量随难度增长50级见顶
#define Max_DamageReduction 0.65 //最大减伤50% 50级见顶一难度增加0.01
#define Max_Damage 45.0

#define HULL_MIN Float:{-10.0,-10.0,0.0}
#define HULL_MAX Float:{10.0,10.0,62.0}

#define var_BeAttackStopTime "s_timer"

new Jp_Name[][]={
	Jp_defname,
	"日本人妻",
	"日本自卫队",
	"747细菌专家",
	"日本女优",
	"日本逃兵",
	"日本武装部队",
	"日本装甲部队"
}

new const Jp_Model [][]={
	"models/rainych/krzz/Japanese4.mdl",
	"models/rainych/krzz/tank.mdl",
	"models/rainych/krzz/tank_died.mdl",
}

new Jp_Attacksound [][]={
	"rainych/krzz/kill_player2.wav",
	"rainych/krzz/kill_player2_gl.wav",
	"rainych/krzz/kill_player1.wav",
	"rainych/krzz/kill_player1_gl.wav"
}

new Jp_Glbodys[]={
	2,5,
}

new  jp_Attack_anim[] = {
	97,119,96,95,93
}
new  jp_beAttack_anim[] = {
	1,19,23,123,114
}

new Modelid[sizeof Jp_Model]

new FakeClient

new Jpnpc_forwards[Jp_FOWARD]

new Float:CurrentLeavelHeal,Float:CurrentLeavelDamageReduction

new CloseAi , KillMoney

new Array:NpcList

new DeadMsg

public plugin_init()
{
	register_plugin("日本人npc", "1.0", "Bing")

	register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
	register_logevent("EventRoundEnd", 2, "1=Round_End")

	RegisterHam(Ham_TakeDamage, "hostage_entity", "HOSTAGE_TakeDamage")
	RegisterHam(Ham_TakeDamage, "hostage_entity", "HOSTAGE_TakeDamage_Post", true)
	RegisterHam(Ham_Think, "hostage_entity", "fw_HostageThink")
	RegisterHam(Ham_Think, "hostage_entity", "fw_HostageThink_Post" , true)
	RegisterHam(Ham_Use, "hostage_entity", "HOSTAGE_Use")
	RegisterHam(Ham_Touch , "hostage_entity", "fw_HostageTouch")

	register_message(get_user_msgid("StatusValue"), "message_statusvalue")	

	bind_pcvar_num(register_cvar("Kr_Close_JpNpc_Ai" , "0") , CloseAi) 
	bind_pcvar_num(register_cvar("Kr_KillMoney" , "50") , KillMoney) 	

	CreateFakeClient()

	FakeClientTask() //执行一次
	NpcList = ArrayCreate()
	DeadMsg = get_user_msgid("DeathMsg")
	// set_task(1.0, "CreateFakeClient", 0)

	InitFowrad()
}

public InitFowrad(){
	Jpnpc_forwards[JP_NpcCreatePre] = CreateMultiForward("NPC_CreatePre",ET_STOP,FP_CELL)
	Jpnpc_forwards[JP_NpcCreatePost] = CreateMultiForward("NPC_CreatePost",ET_STOP,FP_CELL)
	Jpnpc_forwards[JP_NpcThinkPre] = CreateMultiForward("NPC_ThinkPre",ET_STOP,FP_CELL)
	Jpnpc_forwards[Jp_NpcThinkPost] = CreateMultiForward("NPC_ThinkPost",ET_STOP,FP_CELL)
	Jpnpc_forwards[Jp_NpcKilled] = CreateMultiForward("NPC_Killed",ET_STOP,FP_CELL,FP_CELL)
	Jpnpc_forwards[Jp_NpcKillPlayer] = CreateMultiForward("NPC_KillPlayer",ET_STOP,FP_CELL,FP_CELL)

	Jpnpc_forwards[Jp_NpcOnDamagePre] = CreateMultiForward("Npc_OnDamagePre",ET_STOP,FP_CELL,FP_CELL,FP_FLOAT)
	Jpnpc_forwards[Jp_NpcOnDamagePost] = CreateMultiForward("Npc_OnDamagePost",ET_STOP,FP_CELL,FP_CELL,FP_FLOAT)
}	

public plugin_end(){
	for(new i = 0 ; i < sizeof Jpnpc_forwards ; i++){
		DestroyForward(Jpnpc_forwards[Jp_FOWARD:i])
	}
	new iEntity = -1
	while ((iEntity = find_ent_by_class(iEntity, "hostage_entity")) > 0) {
		rg_remove_entity(iEntity)
	}
	ArrayDestroy(NpcList)
}

public plugin_precache()
{
	for(new i = 0; i < sizeof(Jp_Model); i++)
		Modelid[i] = precache_model(Jp_Model[i])
	
	for (new i = 0; i < sizeof Jp_Attacksound; i++)
		UTIL_Precache_Sound(Jp_Attacksound[i])

	precache_sound("hostage/hos1.wav")
	precache_sound("hostage/hos2.wav")
	precache_sound("hostage/hos3.wav")
	precache_sound("hostage/hos4.wav")
	precache_sound("hostage/hos5.wav")
	precache_model("sprites/smoke.spr")
	precache_model("models/hostage.mdl")
}

public plugin_natives(){
	register_native("CreateJpNpc", "native_CreateJpNpc")
	register_native("ReSpawnJpNpc", "native_ReSpawn")
	register_native("ChangeFakeName", "native_ChangeFakeClientName")
	register_native("GetIsNpc", "native_GetIsNpc")
	register_native("Npc_GetName","native_Npc_GetName")
	register_native("GetFakeClient","native_GetFakeClient")
	register_native("KrGetFakeTeam" , "getnpc_FakeTeam" , 1)
	register_native("GetNpcList" , "KrGetNpcList" , 1)
	register_native("ExecNpcKillCallBack" , "native_ExecNpcKillCallBack")
	register_native("GetLvDamageReduction" , "native_GetLvDamageReduction")
}

public native_ExecNpcKillCallBack(){
	ExecuteForward(Jpnpc_forwards[Jp_NpcKillPlayer] , _ , get_param(1) , get_param(2))
}

public Float:native_GetLvDamageReduction(){
	return ClacLvDamageReduction()
}

Float:ClacLvDamageReduction(){
	new const Float:TARGET_LEVEL = 500.0;
	new const Float:LEVEL_COEFFICIENT = Max_DamageReduction / TARGET_LEVEL;
	return floatmin(float(Getleavel()) * LEVEL_COEFFICIENT, Max_DamageReduction);
}

public OnLevelChange_Post(Lv){
	CurrentLeavelHeal = floatmin(100.0 + float(Getleavel()) + 1.0, Max_heal)
	CurrentLeavelDamageReduction = ClacLvDamageReduction()
}

public message_statusvalue(msg_id, msg_dest, id){
	new flag = get_msg_arg_int(1)
	new value = get_msg_arg_int(2)
	new msgid = get_user_msgid("StatusText")

	if(flag == 3){
		new target, _pitch;
		get_user_aiming(id, target, _pitch, 9999)
		if (is_nullent(target))
			return 0
		new classname[33]
		get_entvar(target,var_classname, classname,charsmax(classname))
		if(equal(classname , "hostage_entity")){
			new Float:heal = get_entvar(target, var_health)
			set_msg_arg_int(2, get_msg_argtype(2), floatround(heal))
		}
	}
	if(flag == 1){
		switch(value){
			case 2 : set_msg_arg_int(2, get_msg_argtype(2), 0)
			case 3 :{
				new target, _pitch;
				get_user_aiming(id, target, _pitch, 9999)
				if (is_nullent(target))
					return 0
				if(GetIsNpc(target)){
					new CsTeams:team = KrGetFakeTeam(target)
					new CsTeams:player_team = cs_get_user_team(id)
					new bool:isSameTeam = (player_team == team)
					message_begin(MSG_ONE, msgid, .player = id)
					write_byte(0) // 一般第一个参数是 style/color
					switch(player_team){
						case CS_TEAM_T:{
							write_string( isSameTeam ? "1 [同志] %h: %i3" : "1 [鬼子] %h: %i3")
						}
						case CS_TEAM_CT:{
							write_string( isSameTeam ? "1 [太君] %h: %i3" : "1 [敌人] %h: %i3")
						}
					}
					message_end()
					return PLUGIN_CONTINUE
				}
			}
			case 0:{
				message_begin(MSG_ONE, msgid, .player = id)
				write_byte(0)
				write_string("")
				message_end()
			}
		}
	}
	return 0
}	

public event_roundstart(){
	// remove_entity_name("hostage_entity")
	new iEntity = -1
	while ((iEntity = find_ent_by_class(iEntity, "hostage_entity")) > 0) {
		rg_remove_entity(iEntity)
	}
	CurrentLeavelHeal = floatmin(100.0 + float(Getleavel()), Max_heal)
	CurrentLeavelDamageReduction = ClacLvDamageReduction()
	ChangeFakeClientName(0)
	FakeClientTask()
	set_task(1.0,"FakeClientTask", UpdateFakeClientTaskId, "", 0, "b")
}

public CheckNpcList() {
    // 倒序遍历，从最后一个元素开始
    for (new i = ArraySize(NpcList) - 1; i >= 0; i--) {
        new ent = ArrayGetCell(NpcList, i);
        // 1. 如果实体无效或为宿主实体，删除
        if (is_nullent(ent)
            || !FClassnameIs(ent, "hostage_entity")
            || get_entvar(ent, var_deadflag) == DEAD_DEAD) {
            ArrayDeleteItem(NpcList, i);
        }
    }
}


public EventRoundEnd(){
    remove_task(UpdateFakeClientTaskId)
    // remove_task(CheckList)
}

public native_ChangeFakeClientName(plugin_id, num_params){
	new id = get_param(1)
	ChangeFakeClientName(id)
}

public ChangeFakeClientName(Changeid){
	if(!FakeClient)
		return false
	if (Changeid >= 0 && Changeid < sizeof Jp_Name){
		set_user_info(FakeClient, "name" , Jp_Name[Changeid])
	}
	return true
}

public HOSTAGE_Use(id , idcaller , idactivator , user_type , Float:value){
	new Float:NextChange , Float:CurrentGametime
	CurrentGametime = get_gametime()
	if(!prop_exists(id, "NextChange")){
		return HAM_SUPERCEDE;
	}
	NextChange = get_prop_float(id, "NextChange")
	if(CurrentGametime >= NextChange && cs_get_user_team(idcaller) == CS_TEAM_CT){
		set_prop_float(id, "NextChange", CurrentGametime + 1.0)
		client_print(idcaller, print_center, "因为你冒犯太君被打了一巴掌。")
		user_slap(idcaller,1)
		return HAM_SUPERCEDE;
	}
	return HAM_SUPERCEDE;
}
public RemoveGib(ent){
	rg_remove_entity(ent)
}
//this == vis受害者
public HOSTAGE_TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits){
	new rets
	ExecuteForward(Jpnpc_forwards[Jp_NpcOnDamagePre], rets , this, idattacker, damage)

	if(rets >= PLUGIN_HANDLED){
		return HAM_SUPERCEDE
	}

	new CsTeams:CurTeam = KrGetFakeTeam(this)
 	new bool:Attacker_IsPlayer = bool:ExecuteHam(Ham_IsPlayer , idattacker)
	if(Attacker_IsPlayer && bool:is_user_alive(idattacker) == false)
		return HAM_SUPERCEDE
	if(Attacker_IsPlayer && cs_get_user_team(idattacker)== CurTeam){
		//相同阵营不要伤害
		return HAM_SUPERCEDE
	}

	new Float:newdamage = damage
	new HumanRule = _:GetHunManRule()
	new RiJunRule = _:GetRiJunRule()
	if(CurTeam == CS_TEAM_CT){
		new Float:vel[3]
		get_entvar(this, var_velocity, vel)
		newdamage = damage * (1.0 - CurrentLeavelDamageReduction)
		if(HumanRule == _:HUMAN_RULE_Depleted_Uranium && CurrentLeavelDamageReduction > 0.1){
			newdamage = damage * (1.0 - (CurrentLeavelDamageReduction - 0.1))
		}
		if((vel[0] == 0.0 && vel[1] == 0.0 && vel[2] == 0.0) || !cs_get_hostage_foll(this)){
			newdamage *= 0.5 //如果不动再减伤0.5
		}
		if(RiJunRule == _:JAP_RULE_Damage_Reduction){
			newdamage *= 0.95
		}
		SetHamParamFloat(4, newdamage)
		damage = newdamage
	}
	new Float:Hp , Currentsequence
	new CsTeams:FakeTeam = CurTeam

	get_entvar(this, var_health, Hp)
	new Float:AttackEndHeal = Hp - newdamage

	Currentsequence = get_entvar(this, var_sequence)
	set_entvar(this, var_health, AttackEndHeal)
	if(RiJunRule == _:JAP_RULE_Gyokusai_Charge && AttackEndHeal <= 0.0 && get_entvar(this , var_iuser4) == 0){
		set_entvar(this , var_health , 50.0)
		set_entvar(this , var_iuser4 , 1)
		AttackEndHeal = 50.0
	}
	if(AttackEndHeal <= 0.0){
		// if(UTIL_RandFloatEvents(0.02)){
		// 	new head_gib = rg_spawn_head_gib(this)
		// 	SetThink(head_gib , "RemoveGib")
		// 	set_entvar(head_gib, var_nextthink , get_gametime() + 2.0)
		// }
		set_entvar(this , var_iuser4 , 0)
		OnKill(this)
		// ExecuteHam(Ham_TakeDamage, this , 0,  0 , 0, damagebits)
		set_entvar(this , var_deadflag, DEAD_DEAD)
		return HAM_SUPERCEDE;
	}

	if(FakeTeam == CS_TEAM_CT){
		new bool:CanBeStop = bool:getnpc_CanBeStop(this)
		new Float:vec[3]
		if(RiJunRule == _:JAP_RULE_Stimulants && UTIL_RandFloatEvents(0.5)){
			//不被定身
			CanBeStop = true
		}
		if(Hp - damage > 0.0 && !is_in_anim(jp_Attack_anim, sizeof jp_Attack_anim , Currentsequence)
		&& CanBeStop == false){
			play_anim(this , jp_beAttack_anim[random_num(0,4)], 9999.0)
		}
		if(CanBeStop == false){
			vec[0] = 0.0;
			vec[1] = 0.0;
			vec[2] = 0.0;
			set_entvar(this, var_velocity, vec)
			if(get_entvar(this , var_iuser4) != 1){
				set_prop_float(this ,var_BeAttackStopTime , get_gametime() + 0.75)
			}
		}
		new think = getnpc_BeAttackInThink(this)
		if(think == 0){
			setnpc_BeAttackInThink(this, 1)
		}
		new foll = cs_get_hostage_foll(this)
		new fool_isPlayer = ExecuteHam(Ham_IsPlayer , foll)
		if(is_entity(idinflictor) && GetIsNpc(idinflictor) && KrGetFakeTeam(idinflictor) == CS_TEAM_T){
			setnpc_Attacker(this, idinflictor)
			PropagateHate(this , idinflictor)
		}else if(fool_isPlayer && is_user_connected(idattacker) && is_user_alive(idattacker)){
			setnpc_Attacker(this, idattacker)
		}
		cs_set_hostage_foll(this)
	}
	return HAM_SUPERCEDE
}

public HOSTAGE_TakeDamage_Post(this, idinflictor, idattacker, Float:damage, damagebits){
	if(ExecuteHam(Ham_IsPlayer , idattacker) && get_member(idattacker , m_iTeam) != TEAM_CT){
		ExecuteForward(Jpnpc_forwards[Jp_NpcOnDamagePost], _ , this, idattacker, damage)
	}
	new Float:Hp
	Hp = get_entvar(this,var_health)
	if(Hp <= 0.0 || get_entvar(this , var_deadflag)){
		ExecuteForward(Jpnpc_forwards[Jp_NpcKilled], _ , this, idattacker)
		if(ExecuteHam(Ham_IsPlayer , idattacker) && !is_user_bot(idattacker)){
			cs_set_user_money(idattacker, cs_get_user_money(idattacker) + KillMoney)
			new frag = get_entvar(idattacker , var_frags)
			set_entvar(idattacker , var_frags , frag + 5)
			SendScoreInfo(idattacker, frag)
			SendDeathMessage(FakeClient, idattacker)
		}
		// DelSelf(this)
	}
}

public fw_HostageThink_Post(id){
	if(KrGetFakeTeam(id) == CS_TEAM_CT)	
		set_entvar(id , var_nextthink , get_gametime() + 0.1)
}

public fw_HostageThink(id){
	new rets
	ExecuteForward(Jpnpc_forwards[JP_NpcThinkPre], rets, id)
	if(rets >= PLUGIN_HANDLED)
		return HAM_IGNORED
	new Faketeam = getnpc_FakeTeam(id)
	if(CloseAi && Faketeam == _:CS_TEAM_CT){
		StudioFrameAdvance(id)
		cs_set_hostage_foll(id)
		return HAM_SUPERCEDE
	}
	if(Faketeam == _:CS_TEAM_T){
		return HAM_IGNORED
	}

	new Float:NpcHeal = get_entvar(id, var_health)
	new Float:StopTime = get_prop_float(id , var_BeAttackStopTime)
	if(StopTime > get_gametime()){
		ExecuteForward(Jpnpc_forwards[Jp_NpcThinkPost], _ , id)
		return HAM_SUPERCEDE
	}
	if(NpcHeal <= 0.0){
		return HAM_IGNORED
	}

	new Beattackstatus = getnpc_BeAttackInThink(id)
	// set_pdata_float(id , 0x62 , 0.0) //去除恐惧
	if(Beattackstatus == 1){
		setnpc_BeAttackInThink(id, 2)
		new Currentsequence = get_entvar(id, var_sequence)
		if(NpcHeal > 0.0 && is_in_anim(jp_beAttack_anim , sizeof jp_beAttack_anim , Currentsequence)){
			set_entvar(id , var_sequence, 13)
			set_member(id , m_Activity , ACT_IDLE)
		}
	}else if (Beattackstatus == 2){
		setnpc_BeAttackInThink(id, 0)
		if(NpcHeal > 0.0){
			new Attacker = getnpc_Attacker(id)
			if(GetIsNpc(Attacker) && get_entvar(Attacker , var_deadflag) != DEAD_DEAD && KrGetFakeTeam(Attacker) == CS_TEAM_T){
				cs_set_hostage_foll(id, Attacker)
			}
			else if(Attacker && is_user_alive(Attacker) && is_user_connected(Attacker) && cs_get_user_team(Attacker) == CS_TEAM_T){
				cs_set_hostage_foll(id, Attacker)
			}
		}
	}

	new Float:reanim = get_prop_float(id , "reainmtime")
	new Currentsequence = get_entvar(id, var_sequence)
	new bool:isinanim = is_in_anim(jp_Attack_anim, sizeof jp_Attack_anim, Currentsequence)

	if(get_gametime() > reanim && isinanim){
		new idel = LookupActivity(id , 1)
		play_anim(id, idel , 9999.0)
	}

	new owner = cs_get_hostage_foll(id)
	new bool:ownerValid = false

	if(owner > 0){
		if(GetIsNpc(owner)){
			ownerValid = (get_entvar(owner , var_deadflag) == DEAD_NO)
		}else{
			new owner_team = get_member(owner , m_iTeam)
			ownerValid = (is_valid_ent(owner) && is_user_alive(owner) && owner_team == _:TEAM_TERRORIST)
		}
	}

	if(!ownerValid)
		cs_set_hostage_foll(id)


	new target
	if(ownerValid)
		target = FindNearHuman(id , owner)
	else
		target = FindNearHuman(id ,0)
	

	if(target > 0){
		cs_set_hostage_foll(id, target)
		if(fm_get_entity_distance(id,target) <= 210.0){
			RibenNormlAttack(id,target)
		}
	}
	ExecuteForward(Jpnpc_forwards[Jp_NpcThinkPost], _ ,id)
	return HAM_IGNORED
}

public DelSelf(id){
	rg_remove_entity(id)
}

public OnKill(id){
	new hit = get_member(id , m_LastHitGroup)
	SetDeadAct(id , hit)
	set_entvar(id , var_deadflag , DEAD_DEAD)
	set_entvar(id , var_nextthink , -1.0)
	set_entvar(id , var_movetype , MOVETYPE_NONE)
	set_entvar(id , var_solid , SOLID_NOT)
	set_entvar(id , var_takedamage , DAMAGE_NO)
	set_entvar(id , var_health , 0.0)
	set_entvar(id , var_max_health , 0.0)
	engfunc(EngFunc_SetSize , Float:{0.0,0.0,0.0} , Float:{0.0,0.0,0.0})
}

public SetDeadAct(id , hitGroup){
	switch(hitGroup){
		case HITGROUP_GENERIC,HITGROUP_LEFTARM,HITGROUP_RIGHTARM,HITGROUP_LEFTLEG,HITGROUP_RIGHTLEG :{
			SetActivity(  id , ACT_DIESIMPLE)
		}
		case HITGROUP_HEAD:{
			SetActivity(  id , ACT_DIE_HEADSHOT)
		}
		case HITGROUP_CHEST:{
			SetActivity(  id , ACT_DIE_CHESTSHOT)
		}
		case HITGROUP_STOMACH:{
			SetActivity(  id , ACT_DIE_GUTSHOT)
		}
	}
}

public native_CreateJpNpc(plugin_id, num_params){
	new FakeTeam = get_param(2)
	new body = get_param(5)
	new IsNpcCreate = get_param(6) // 是否为Npc创建
	new Float:origin[3]
	new Float:angles[3]
	static origin_str[32]
	get_array_f(3, origin, 3)
	get_array_f(4, angles, 4)

	new ent = rg_create_entity("hostage_entity")
	if(is_nullent(ent)){
		log_error(AMX_ERR_NONE , "创建人质实体失败")
		return -1
	}
	if(FakeTeam == _:CS_TEAM_CT && !IsNpcCreate){
		new rets
		ExecuteForward(Jpnpc_forwards[JP_NpcCreatePre] , rets , ent)
		if(rets >= PLUGIN_HANDLED)
			return ent
	}
	
	formatex(origin_str, charsmax(origin_str) ,"%i %i %i",
		floatround(origin[0]), floatround(origin[1]), floatround(origin[2]))

	DispatchKeyValue(ent,"model", Jp_Model[0])
	DispatchKeyValue(ent,"origin", origin_str)
	dllfunc(DLLFunc_Spawn, ent)
	new Float:val[3] = {0.0, 0.0, -200.0}
	set_entvar(ent, var_velocity, val)
	set_entvar(ent, var_origin, origin)
	set_entvar(ent, var_max_health, CurrentLeavelHeal)
	set_entvar(ent, var_health, CurrentLeavelHeal)
	set_entvar(ent, var_body, body)
	set_prop_int(ent, "FakeTeam", FakeTeam)
	set_prop_int(ent, "BeAttackInThink", 0)
	set_prop_int(ent, "Attacker",0)
	set_prop_int(ent, "IsNpc",true)

	set_prop_float(ent, "NextChange", get_gametime())
	set_prop_float(ent, "nextattack", get_gametime())
	set_prop_float(ent, "reainmtime", get_gametime())
	set_prop_float(ent, var_BeAttackStopTime , get_gametime())

	if(FakeTeam == _:CS_TEAM_CT && !IsNpcCreate){
		ExecuteForward(Jpnpc_forwards[JP_NpcCreatePost] , _ , ent)
	}
	// ArrayPushCell(NpcList , ent)
	return ent
}

public native_ReSpawn(id , nums){
	new Jpid = get_param(1)
	new Float:fOrigin[3]
	get_array_f(2 , fOrigin , sizeof fOrigin)
	new Float:val[3] = {0.0, 0.0, -200.0}
	set_entvar(Jpid, var_velocity, val)
	set_entvar(Jpid, var_origin, fOrigin)
	set_entvar(Jpid , var_modelindex , Modelid[0])
	set_entvar(Jpid, var_max_health, CurrentLeavelHeal)
	set_entvar(Jpid, var_health, CurrentLeavelHeal)
	set_entvar(Jpid , var_movetype , MOVETYPE_STEP)
	set_entvar(Jpid , var_solid , SOLID_SLIDEBOX)
	set_entvar(Jpid , var_takedamage , DAMAGE_YES)
	set_entvar(Jpid , var_deadflag , DEAD_NO)
	set_entvar(Jpid , var_effects , get_entvar(Jpid , var_effects) & ~EF_NODRAW)
	set_entvar(Jpid , var_nextthink , get_gametime() + 0.1)

	set_prop_float(Jpid , var_BeAttackStopTime , get_gametime())
	set_prop_float(Jpid, "NextChange", get_gametime())
	set_prop_float(Jpid, "nextattack", get_gametime())
	set_prop_float(Jpid, "reainmtime", get_gametime())

	set_prop_int(Jpid , "istank" , false)
	set_prop_int(Jpid , "CanStop" , false)

	SetActivity(Jpid , ACT_IDLE)

	// engfunc(EngFunc_SetModel , Jpid , Jp_Model[0])
	engfunc(EngFunc_SetSize , Jpid , HULL_MIN , HULL_MAX)
	// engfunc(EngFunc_SetOrigin , Jpid , fOrigin)
	ExecuteForward(Jpnpc_forwards[JP_NpcCreatePost] , _ , Jpid)
}

stock FVectorToiVecotr(Float:fOrigin[3] , out[3]){
	out[0] = floatround(fOrigin[0])
	out[1] = floatround(fOrigin[1])
	out[2] = floatround(fOrigin[2])
}

public native_GetIsNpc(P_id,nums){
	new id = get_param(1)
	if(is_nullent(id) || !is_valid_ent(id))
		return false
	if(!prop_exists(id, "IsNpc")){
		return false
	}
	new isnpc = get_prop_int(id,"IsNpc")
	return isnpc
}

public setnpc_nextattack(id, Float:nextattack){
	if(!prop_exists(id, "nextattack")){
		return
	}
	set_prop_float(id, "nextattack", nextattack)
}

public setnpc_NextChange(id, Float:NextChange){
	if(!prop_exists(id, "NextChange")){
		return
	}
	set_prop_float(id, "NextChange", NextChange)
}

public setnpc_FakeTeam(id, FakeTeam){
	if(!prop_exists(id, "FakeTeam")){
		return
	}
	set_prop_int(id, "FakeTeam", FakeTeam)
}

public setnpc_Attacker(id, Attacker){
	if(!prop_exists(id, "Attacker")){
		return
	}
	set_prop_int(id, "Attacker", Attacker)
}

public setnpc_frag(id, frag){
	if(!prop_exists(id, "frag")){
		return
	}
	set_prop_int(id, "frag", frag)
}

public setnpc_BeAttackInThink(id, BeAttackInThink){
	if(!prop_exists(id, "BeAttackInThink")){
		return
	}
	set_prop_int(id, "BeAttackInThink", BeAttackInThink)
}

public getnpc_BeAttackInThink(id){
	if(!prop_exists(id, "BeAttackInThink")){
		return 0
	}
	new BeAttackInThink = get_prop_int(id, "BeAttackInThink")
	return BeAttackInThink
}

public getnpc_Attacker(id){
	if(!prop_exists(id, "Attacker")){
		return 0
	}
	new Attacker = get_prop_int(id, "Attacker")
	return Attacker
}

public getnpc_FakeTeam(id){
	if(!prop_exists(id, "FakeTeam")){
		return 0
	}
	new FakeTeam = get_prop_int(id, "FakeTeam")
	return FakeTeam
}

public getnpc_frag(id){
	if(!prop_exists(id, "frag")){
		return 0
	}
	new frag = get_prop_int(id, "frag")
	return frag
}

public Float:getnpc_NextChange(id){
	if(!prop_exists(id, "NextChange")){
		return 0.0
	}
	new Float:NextChange = get_prop_float(id, "NextChange")
	return NextChange
}

public getnpc_CanBeStop(id){
	if(!prop_exists(id, "CanStop")){
		return false
	}
	new CanStop = get_prop_int(id, "CanStop")
	return CanStop
}

public IsFakeClient(id){
	new isfake = prop_exists(id, "IsFake")
	if(!isfake)
		return false
	new isfakeclient = get_prop_int(id, "IsFake")
	if(isfakeclient == 1)
		return true
	else
		return false
}

public Float:getnpc_nextattack(id){
	if(!prop_exists(id, "nextattack")){
		return 0.0
	}
	new Float:nextattack = get_prop_float(id, "nextattack")
	return nextattack
}

public FakeClientTask(){
    if(FakeClient && is_entity(FakeClient) && is_user_bot(FakeClient)){
		cs_set_user_team(FakeClient, CS_TEAM_CT);
		new Float:origin[3] = {8188.0, 8188.0, 8188.0}

		engfunc(EngFunc_SetOrigin, FakeClient, origin)

		set_entvar(FakeClient, var_effects,  EF_NODRAW);
		set_entvar(FakeClient, var_solid, SOLID_NOT);
		set_entvar(FakeClient, var_movetype, MOVETYPE_NOCLIP);
		return;
    }
}

public CreateFakeClient(){
	FakeClient = engfunc(EngFunc_CreateFakeClient, Jp_defname)
	if(!pev_valid(FakeClient)){
		log_error(AMX_ERR_NONE , "FakeClient创建失败")
		return
	} 
	new szMsg[128]
	engfunc(EngFunc_FreeEntPrivateData, FakeClient)
	dllfunc(DLLFunc_ClientConnect, FakeClient, Jp_defname, "127.0.0.1", szMsg)
	dllfunc(DLLFunc_ClientPutInServer, FakeClient)
	cs_set_user_team(FakeClient, CS_TEAM_CT)
	set_entvar(FakeClient , var_takedamage, DAMAGE_NO)
	set_entvar(FakeClient , var_effects , EF_NODRAW)
	set_entvar(FakeClient , var_solid , SOLID_NOT)
	set_entvar(FakeClient , var_movetype , MOVETYPE_NOCLIP)
	set_prop_int(FakeClient,"IsFake", 1)
}

public fw_HostageTouch(this , other){
	new CsTeams:thisteam =  KrGetFakeTeam(this)
	new touch_IsPlayer = ExecuteHam(Ham_IsPlayer , other)
	if(!touch_IsPlayer && KrGetFakeTeam(other) != thisteam && GetIsNpc(other)){
		RibenNormlAttack(this , other , true)
	}else if(touch_IsPlayer && cs_get_user_team(other) != thisteam){
		RibenNormlAttack(this , other , true)
	}
	new Float:this_velocity[3]
	new const Float:PushForce = 50.0
	new Float:other_origin[3]
	new Float:origin[3]
	get_entvar(this, var_origin, origin)
	get_entvar(other, var_origin, other_origin)
	get_entvar(this, var_velocity, this_velocity)
	new Float:dir[3];

	dir[0] = origin[0] - other_origin[0];
	dir[1] = origin[1] - other_origin[1];
	dir[2] = 0.0; // 忽略高度	

	new Float:length = vector_length(dir);
	if (length < 1.0)
	    return HAM_IGNORED;	

	xs_vec_normalize(dir, dir); // 单位向量
	xs_vec_mul_scalar(dir, PushForce, dir); // 推力大小

	//这里之前没声明Float结果碰一下就飞了下次注意

	new Float:velocity[3];
	get_entvar(this, var_velocity, velocity);
	xs_vec_add(velocity, dir, velocity);
	set_entvar(this, var_velocity, velocity);	
	return HAM_IGNORED
}

public bool:is_in_anim(anims[],animssize,sequence){
	for(new i = 0; i < animssize; i++){
		if(anims[i] == sequence)return true
	}
	return false
}

public play_anim(id , anim , Float:PlayTimer){
	set_pev(id, pev_sequence, anim)
	set_pev(id, pev_frame, 0.0)
	set_pev(id, pev_framerate, 1.0)
	set_pev(id, pev_animtime, get_gametime())
	set_prop_float(id, "reainmtime", get_gametime() + PlayTimer)
}

public SendDeathMessage(vim,attacker){
	new waeponname [32]
	new wpnid = cs_get_user_weapon(attacker)
	if(wpnid){
		get_weaponname(wpnid, waeponname, charsmax(waeponname))
	}else{
		copy(waeponname , 31 , "NoWeapon")
	}
	
	replace_all(waeponname, charsmax(waeponname), "weapon_" , "")
	message_begin(MSG_BROADCAST, DeadMsg)
	write_byte(attacker)
	write_byte(vim)
	write_byte(0)
	write_string(waeponname)
	message_end()
}

public SendScoreInfo(id , frag){
	static msgs_ScoreInfo
	if(!msgs_ScoreInfo){
		msgs_ScoreInfo = get_user_msgid("ScoreInfo")
	}
	message_begin(MSG_BROADCAST, msgs_ScoreInfo)
	write_byte(id)
	write_short(frag)
	write_short(cs_get_user_deaths(id))
	write_short(0)
	write_short(_:cs_get_user_team(id)) 
	message_end()
}

public FindNearHuman(ent, CurrentFollow) {
    new CsTeams:FakeTeam = KrGetFakeTeam(ent);
    new Float:CurrentLen, Float:origin[3], Float:playerOrigin[3], Float:targetOrigin[3];
    new Float:MinDistance = 999999.0;
    new target = -1;

    // 获取实体位置
    get_entvar(ent, var_origin, origin);

    // 如果已有目标，就以它为基准距离
    if (CurrentFollow > 0) {
        get_entvar(CurrentFollow, var_origin, targetOrigin);
        MinDistance = vector_distance(origin, targetOrigin);
        target = CurrentFollow;
    }

    for (new i = 1; i <= MaxClients; i++) {
        if (!is_user_alive(i) || IsFakeClient(i))
            continue;

        if (FakeTeam == cs_get_user_team(i))
            continue;

        get_entvar(i, var_origin, playerOrigin);
        CurrentLen = vector_distance(origin, playerOrigin);

        if (CurrentLen >= 2000.0)
            continue;

        if (CurrentLen < MinDistance) {
            MinDistance = CurrentLen;
            target = i;
        }
    }
    return target;
}


stock RibenNormlAttack(this ,beattack , bool:touched = false){
	new Float:origin[3],Float:Playerorigin[3];
	new Float:AttackTimeer = Float:getnpc_nextattack(this)
	if(AttackTimeer > get_gametime())
		return;
	new Float:AttackCd = random_float(1.5, 2.7)
	new Japanese_Army_Rules:Rule = GetRiJunRule()
	if(Rule == JAP_RULE_Lethal_Rhythm){
		AttackCd =  random_float(0.5, 0.8)
	}
	// new bool:IsAttackNpc = GetIsNpc(beattack)

	setnpc_nextattack(this, get_gametime() + AttackCd)
	get_entvar(this, var_origin, origin)
	get_entvar(beattack, var_origin, Playerorigin)
	new Float:distance = vector_distance(origin, Playerorigin)
	new const Float:AttackDisance = GetRiJunRule() != JAP_RULE_Blade_Enhancement ?  100.0 : 110.0
	if(distance >= AttackDisance){
		if((distance - AttackDisance) < 5.0){
			//空了
			new soundnum = (Npc_Isgirl(this) ? 1 : 0)
			UTIL_EmitSound_ByCmd2(this, Jp_Attacksound[soundnum], 600.0)
			play_anim(this, jp_Attack_anim[random_num(0,4)], 1.0)
		}
		return;
	}
	play_anim(this, jp_Attack_anim[random_num(0,4)], 1.0)
	set_msg_block(DeadMsg, BLOCK_ONCE)

	new lvaddDamge = Getleavel() / 10
	new Float:damage = 5.0 + ( float(lvaddDamge) )//基础攻击力
	new judian = GetJuDianNum()
	damage = random_float(damage , damage + float(judian))
	damage = floatmin(damage, Max_Damage) //最大不要超过45 400级达到顶峰
	if(Rule == JAP_RULE_Lethal_Critical_Strike && UTIL_RandFloatEvents(0.05)){
		damage *= 1.5
	}else if(Rule == JAP_RULE_Desperate_Counterattack){
		new Float:Health = get_entvar(this , var_health)
		if(Health < 50.0)
			damage = 100.0
	}

	if(GetIsNpc(beattack) && KrGetFakeTeam(beattack) == KrGetFakeTeam(this)){
		return
	}

	if(!touched && !Ez_CanSee(this , beattack)){
		return
	}

	if(get_entvar(beattack , var_takedamage) != DAMAGE_NO)
		ExecuteHamB(Ham_TakeDamage, beattack, GetFakeClient(), GetFakeClient(), damage, DMG_CRUSH)

	set_msg_block(DeadMsg, BLOCK_NOT)
	if(get_entvar(beattack , var_deadflag) == DEAD_DEAD){
		new soundnum = _:AttackToDieMan
		new g_msgDeathMsg = DeadMsg;
		message_begin(MSG_BROADCAST, g_msgDeathMsg);
		write_byte(FakeClient);
		write_byte(beattack);
		write_byte(0);
		write_string("日本带派大脚");
		message_end();
		if(Npc_Isgirl(this)){
			soundnum = _:AttackToDieGl
		}
		UTIL_EmitSound_ByCmd2(this, Jp_Attacksound[soundnum], 600.0)
		ExecuteForward(Jpnpc_forwards[Jp_NpcKillPlayer] , _ , beattack , this)
	}
	new sound = _:AttackMan
	if(Npc_Isgirl(this)){
		sound = _:AttackGl
	}
	UTIL_EmitSound_ByCmd2(this, Jp_Attacksound[sound], 600.0)
}

public Npc_Isgirl(id){
	new classname[32]
	get_entvar(id, var_classname, classname, charsmax(classname))
	if(!equal(classname, "hostage_entity")){
		return false
	}
	new nowbody
	nowbody = get_entvar(id, var_body)
	for(new i = 0; i < sizeof Jp_Glbodys; i++){
		if(nowbody == Jp_Glbodys[i]){
			return true
		}
	}
	return false;
}

public native_Npc_GetName(id,num){
	new bodyid = get_param(1)
	new size = get_param(3)
	set_string(2, Jp_Name[bodyid] , size)
	return 1
}

public native_GetFakeClient(){
	return FakeClient
}

public Array:KrGetNpcList(){
	return NpcList
}

stock bool:Stock_CanSee(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (!is_nullent(entindex1) && !is_nullent(entindex1))
	{
		new flags = get_entvar(entindex1, var_flags)
		
		if (flags & EF_NODRAW)
			return false
		
		new Float:lookerOrig[3],Float:targetBaseOrig[3],Float:targetOrig[3],Float:temp[3],i
		get_entvar(entindex1, var_origin, lookerOrig)
		get_entvar(entindex1, var_view_ofs, temp)

		for(i = 0; i < 3; i++) lookerOrig[i] += temp[i]
		
		get_entvar(entindex2, var_origin, targetBaseOrig)
		get_entvar(entindex2, var_view_ofs, temp)
		for(i = 0; i < 3; i++) targetOrig[i] = targetBaseOrig[i] + temp[i]
		
		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater)) return false
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) return true
			else
			{
				for(i = 0; i < 3; i++) targetOrig[i] = targetBaseOrig[i]
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

stock FindNearAttackNpc(npc){
    new ent = -1
    new Float:Dis = 0.0 , Float:fOrigin[3] , Float:m_Origin[3]
    new target = -1
    get_entvar(npc , var_origin , m_Origin)
	new CurnpcTeam = KrGetFakeTeam(npc)
    while(ent = rg_find_ent_by_class(ent , "hostage_entity" , true)){
        new Team = KrGetFakeTeam(ent)
        if(ent == npc || Team == CurnpcTeam)
            continue
        if(get_entvar(ent , var_deadflag) == DEAD_DEAD || get_entvar(ent , var_solid) == SOLID_NOT)
            continue
        get_entvar(ent , var_origin , fOrigin)
        new Float:TmpDis = fm_boxents_distance(npc , ent)
        if(Dis <= 0.0 || TmpDis < Dis){
            target = ent
            Dis = TmpDis
        }
    }
    return target
}
/**
 * 传播仇恨
 */
stock PropagateHate(const BeAttackNpc , const Attacker){
	if(GetIsNpc(BeAttackNpc) == false)
		return
	static Float:NextPropaTime
	if(get_gametime() < NextPropaTime)
		return
	NextPropaTime = get_gametime() + 2.0

	new ent = -1
	new Float:m_Origin[3]
	get_entvar(BeAttackNpc , var_origin , m_Origin)
	new CsTeams:CurnpcTeam = KrGetFakeTeam(BeAttackNpc)
	while((ent = rg_find_ent_by_class(ent , "hostage_entity" , true)) > 0){
		new CsTeams:Team = KrGetFakeTeam(ent)
		if(ent == BeAttackNpc || Team != CurnpcTeam)
		    continue
		if(get_entvar(ent , var_deadflag) == DEAD_DEAD || get_entvar(ent , var_solid) == SOLID_NOT)
			continue
		setnpc_BeAttackInThink(ent , 1)
		setnpc_Attacker(ent , Attacker)
	}
}

stock UpdateHealBar(ent){
	return
	new spr = get_entvar(ent , var_impulse)

    if(!spr)
        return

    new Float:PlayerOrigin[3] , Float:Health ,Float:MaxHealth
    get_entvar(ent , var_origin , PlayerOrigin)
    
    Health = get_entvar(ent , var_health)
    MaxHealth = get_entvar(ent , var_max_health)

    PlayerOrigin[2] += 72.0
	engfunc(EngFunc_SetOrigin, spr, PlayerOrigin)
    // set_entvar(spr , var_origin , PlayerOrigin)
    new Float:ratio = (Health / MaxHealth) * 99.0
    if(ratio < 0.0) ratio = 0.0
    set_entvar(spr , var_frame , ratio)
}


stock SetActivity(this, Activity: act){
	new Activity:m_act = get_member(this , m_Activity)
	if(m_act != act){
		new sequence = LookupActivity(this , _:act)
		if(get_entvar(this , var_sequence) != sequence){
			if((m_act != ACT_WALK && m_act != ACT_RUN) || (act != ACT_WALK && act != ACT_RUN)){
				set_entvar(this , var_frame , 0.0)
			}
			set_entvar(this , var_sequence , sequence)
		}
		set_member(this , m_Activity , act)
		ResetSequenceInfo(this)
	}
}

stock UpdateHostagePos(){
	new ent = -1
	while((ent = rg_find_ent_by_class(ent , "player" , true))){
		if(is_nullent(ent))
			continue
		if(!ExecuteHam(Ham_IsPlayer , ent))
			continue
			
	}
}

stock bool:Ez_CanSee(ent1 , ent2){
	if (is_nullent(ent1) || is_nullent(ent2))
		return false
 	new Float:Ent1Origin[3] , Float:Ent2Origin[3] ,Float:Temp[3]
 	get_entvar(ent1 , var_origin ,Ent1Origin)
 	get_entvar(ent2 , var_origin ,Ent2Origin)
 	get_entvar(ent1, var_view_ofs, Temp)
 	xs_vec_add(Ent1Origin , Temp , Ent1Origin)
 	get_entvar(ent2, var_view_ofs, Temp)
 	xs_vec_add(Ent2Origin , Temp , Ent2Origin)

	if (get_entvar(ent1, var_flags) & EF_NODRAW || get_entvar(ent2, var_flags) & EF_NODRAW)
		return false
	engfunc(EngFunc_TraceLine, Ent1Origin, Ent2Origin, 0, ent1, 0)
	if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater)) return false
	else {
	    if(get_tr2(0, TraceResult:TR_pHit) == ent2){
	        return true
	    }
	}
	return false
}