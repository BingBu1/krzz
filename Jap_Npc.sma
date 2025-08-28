#include <cstrike>
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <props>
#include <fun>
#include <fakemeta_util>
#include <xs>
#include <reapi>
#include <hamsandwich>
#include <engine_stocks>
#include <Jap_Npcconst>
#include <kr_core>
#include <roundrule>
#include <sypb>

#define Jp_defname "日本暴民"
#define UpdateFakeClientTaskId 114514

#define Max_heal 200.0 //最大血量随难度增长50级见顶
#define Max_DamageReduction 0.65 //最大减伤50% 50级见顶一难度增加0.01
#define Max_Damage 30.0

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
	"rainych/krzz/kill_player1_gl.wav",
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

new FakeClient

new Jpnpc_forwards[Jp_FOWARD]

new Float:CurrentLeavelHeal,Float:CurrentLeavelDamageReduction

new CloseAi

new Array:NpcList

public plugin_init()
{
	register_plugin("日本人npc", "1.0", "Bing")
	
	register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
	register_logevent("EventRoundEnd", 2, "1=Round_End")
	
	RegisterHam(Ham_TakeDamage, "hostage_entity", "HOSTAGE_TakeDamage")
	RegisterHam(Ham_TakeDamage, "hostage_entity", "HOSTAGE_TakeDamage_Post", 1)
	RegisterHam(Ham_Think, "hostage_entity", "fw_HostageThink")
	RegisterHam(Ham_Think, "hostage_entity", "fw_HostageThink_Post" , 1)
	RegisterHam(Ham_Use, "hostage_entity", "HOSTAGE_Use")
    RegisterHam(Ham_Touch , "hostage_entity", "fw_HostageTouch")
	
	register_message(get_user_msgid("StatusValue"), "message_statusvalue")

	bind_pcvar_num(register_cvar("Close_JpNpc_Ai" , "0") , CloseAi) 

	CreateFakeClient()
	NpcList = ArrayCreate()
	// set_task(1.0, "CreateFakeClient", 0)

	InitFowrad()
}

public InitFowrad(){
	Jpnpc_forwards[JP_NpcCreatePre] = CreateMultiForward("NPC_CreatePre",ET_STOP,FP_CELL)
	Jpnpc_forwards[JP_NpcCreatePost] = CreateMultiForward("NPC_CreatePost",ET_STOP,FP_CELL)
	Jpnpc_forwards[JP_NpcThinkPre] = CreateMultiForward("NPC_ThinkPre",ET_STOP,FP_CELL)
	Jpnpc_forwards[Jp_NpcThinkPost] = CreateMultiForward("NPC_ThinkPost",ET_STOP,FP_CELL)
	Jpnpc_forwards[Jp_NpcKilled] = CreateMultiForward("NPC_Killed",ET_STOP,FP_CELL,FP_CELL)

	Jpnpc_forwards[Jp_NpcOnDamagePre] = CreateMultiForward("Npc_OnDamagePre",ET_STOP,FP_CELL,FP_CELL,FP_FLOAT)
	Jpnpc_forwards[Jp_NpcOnDamagePost] = CreateMultiForward("Npc_OnDamagePost",ET_STOP,FP_CELL,FP_CELL,FP_FLOAT)
}	

public plugin_end(){
	for(new i = 0 ; i < sizeof Jpnpc_forwards ; i++){
		DestroyForward(Jpnpc_forwards[i])
	}
	new iEntity = -1
    while ((iEntity = find_ent_by_class(iEntity, "hostage_entity")) > 0) {
		rg_remove_entity(iEntity)
    }
	ArrayDestroy(NpcList)
}

public plugin_precache()
{
	for(new i = 0; i < sizeof(Jp_Model); i++){
		 precache_model(Jp_Model[i])
	}
	for (new i = 0; i < sizeof Jp_Attacksound; i++){
		UTIL_Precache_Sound(Jp_Attacksound[i])
	}
    precache_sound("hostage/hos1.wav")
	precache_sound("hostage/hos2.wav")
	precache_sound("hostage/hos3.wav")
	precache_sound("hostage/hos4.wav")
	precache_sound("hostage/hos5.wav")
    precache_model("sprites/smoke.spr")
	precache_model("models/hostage.mdl")
	// precache_model("models/hostageA.mdl")
	// precache_model("models/hostageB.mdl")
	// precache_model("models/hostageC.mdl")
	// precache_model("models/hostageD.mdl")
}

public plugin_natives(){
	register_native("CreateJpNpc", "native_CreateJpNpc")
	register_native("ChangeFakeName", "native_ChangeFakeClientName")
	register_native("GetIsNpc", "native_GetIsNpc")
	register_native("Npc_GetName","native_Npc_GetName")
	register_native("GetFakeClient","native_GetFakeClient")
	register_native("KrGetFakeTeam" , "getnpc_FakeTeam" , 1)
	register_native("GetNpcList" , "KrGetNpcList" , 1)
}

public OnLevelChange_Post(Lv){
	CurrentLeavelHeal = floatmin(100.0 + float(Getleavel()) + 1.0, Max_heal)
	CurrentLeavelDamageReduction = floatmin(float(Getleavel()) * 0.02, Max_DamageReduction)
}

public message_statusvalue(msg_id, msg_dest, id){
	if(!is_user_connected(id))
		return 0
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
		if(value == 2){
			//设置参数2禁用昵称
			set_msg_arg_int(2, get_msg_argtype(2), 0)
		}else if(value == 3){
			new target, _pitch;
    		get_user_aiming(id, target, _pitch, 9999)
    		if (is_nullent(target))
				return 0
			new classname[33]
			new newname[33]

			get_entvar(target,var_classname, classname,charsmax(classname))
			if(equal(classname , "hostage_entity")){
				new team = getnpc_FakeTeam(target)
				new player_team = cs_get_user_team(id)
				message_begin(MSG_ONE, msgid,.player=id)
    		    write_byte(0) // 一般第一个参数是 style/color
				if(player_team == CS_TEAM_T){
					if(team != player_team){
						write_string("1 [鬼子] %h: %i3")
					}else{
						write_string("1 [同志] %h: %i3")
					}
				}else if (player_team == CS_TEAM_CT){
					if(team != player_team){
						write_string("1 [敌人] %h: %i3")
					}else{
						write_string("1 [太君] %h: %i3")
					}
				}
				
    			message_end()
				return PLUGIN_CONTINUE
			}
		}else if( value == 0){
			message_begin(MSG_ONE, msgid, .player = id)
    		write_byte(0)
    		write_string("")
    		message_end()
		}
	}
	
	return 0
}	

public event_roundstart(){
	// remove_entity_name("hostage_entity")
	new iEntity = -1
    while ((iEntity = find_ent_by_class(iEntity, "hostage_entity")) > 0)
    {
        if (pev_valid(iEntity))
        {
            set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME)
        }
    }
	CurrentLeavelHeal = floatmin(100.0 + float(Getleavel()) + 1.0, Max_heal)
	CurrentLeavelDamageReduction = floatmin(float(Getleavel()) * 0.02, Max_DamageReduction)
	ChangeFakeClientName(0)
    FakeClientTask()
    set_task(1.0,"FakeClientTask",UpdateFakeClientTaskId,"",0,"b")
	ArrayClear(NpcList)
}

public EventRoundEnd(){
    remove_task(UpdateFakeClientTaskId)
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
	ExecuteForward(Jpnpc_forwards[Jp_NpcOnDamagePre],rets,this,idattacker,damage)

	if(rets == PLUGIN_HANDLED){
		return HAM_SUPERCEDE
	}
	if(is_user_alive(idattacker) == false || (cs_get_user_team(idattacker) == CS_TEAM_CT && KrGetFakeTeam(this) == CS_TEAM_CT))
		return HAM_SUPERCEDE
	
	if(KrGetFakeTeam(this) == CS_TEAM_T && cs_get_user_team(idattacker) == CS_TEAM_T)
		return HAM_SUPERCEDE
	
	new Float:vel[3]
	get_entvar(this, var_velocity,vel)
	new Float:newdamage = damage - damage * CurrentLeavelDamageReduction
	if(vel[0] <= 0.0 && vel[0] <= 0.0 &&vel[0] <= 0.0 && cs_get_hostage_foll(this) == 0){
		newdamage *= 0.5 //如果不动再减伤0.5
	}
	if(GetRiJunRule() == JAP_RULE_Damage_Reduction){
		newdamage = newdamage - newdamage * 0.05
	}
	SetHamParamFloat(4, newdamage)
	damage = newdamage

	new FakeTeam = get_prop_int(this, "FakeTeam")
	new Float:Hp , Currentsequence
	get_entvar(this, var_health, Hp)
	get_entvar(this,var_sequence, Currentsequence)
	set_entvar(this, var_health, Hp - damage)
	
	if(Hp - damage <= 0.0){
		new rets
		new newbits = damagebits
		if(UTIL_RandFloatEvents(0.2)){
			newbits |= DMG_ALWAYSGIB
			SetHamParamInteger(5, newbits)
			new head_gib = rg_spawn_head_gib(this)
			SetThink(head_gib , "RemoveGib")
			set_entvar(head_gib, var_nextthink , get_gametime() + 2.0)
		}
		ExecuteHam(Ham_TakeDamage, this , 0,  0 , 0, newbits)
		ExecuteForward(Jpnpc_forwards[Jp_NpcKilled],rets,this,idattacker)
		new finder = ArrayFindValue(NpcList , this) 
		if(finder != -1){
			ArrayDeleteItem(NpcList , finder)
		}
		set_entvar(this , var_deadflag, DEAD_DEAD)
		return HAM_SUPERCEDE;
	}

	if(FakeTeam == CS_TEAM_CT){
		new CanBeStop = getnpc_CanBeStop(this)
		if(GetRiJunRule() == JAP_RULE_Stimulants && UTIL_RandFloatEvents(0.5)){
			//不被定身
			CanBeStop = true
		}
		if(Hp - damage > 0.0 && !is_in_anim(jp_Attack_anim, sizeof jp_Attack_anim , Currentsequence)
		&& CanBeStop == 0){
			play_anim(this , jp_beAttack_anim[random_num(0,4)], 9999.0)
		}
		new Float:vec[3];
		if(CanBeStop == 0){
			vec[0] = 0.0;
			vec[1] = 0.0;
			vec[2] = 0.0;
			set_entvar(this, var_velocity, vec)
			set_entvar(this, var_nextthink, get_gametime() + 0.75)
		}
		setnpc_BeAttackInThink(this, 1)
		new foll = cs_get_hostage_foll(this)
		if(foll && is_user_connected(foll) && is_user_alive(foll)){
			setnpc_Attacker(this, foll)
		}else{
			if(idinflictor > 0  && KrGetFakeTeam(idinflictor) == CS_TEAM_T){
				setnpc_Attacker(this, idinflictor)
			}else if(is_user_connected(idattacker) && is_user_alive(idattacker)){
				setnpc_Attacker(this, idattacker)
			}
		}
		cs_set_hostage_foll(this)
	}
	return HAM_SUPERCEDE
}

public HOSTAGE_TakeDamage_Post(this, idinflictor, idattacker, Float:damage, damagebits){
	if(is_user_alive(idattacker) == false || cs_get_user_team(idattacker) == CS_TEAM_CT)
		return HAM_SUPERCEDE
	if(getnpc_FakeTeam(this) != CS_TEAM_CT)
		return HAM_SUPERCEDE
	ExecuteForward(Jpnpc_forwards[Jp_NpcOnDamagePost],_,this,idattacker,damage)
	new Float:Hp , Currentsequence
	pev(this,pev_health, Hp)
	if(Hp <= 0.0){
		cs_set_user_money(idattacker, cs_get_user_money(idattacker)+50)
		new frag = get_user_frags(idattacker) + 5
		set_user_frags(idattacker , frag)
		SendScoreInfo(idattacker, frag)
		SendDeathMessage(FakeClient,idattacker)
		DelSelf(this)
	}
}

public fw_HostageThink_Post(id){
	set_entvar(id , var_nextthink , get_gametime() + 0.1)
}

public fw_HostageThink(id){
	new rets
	ExecuteForward(Jpnpc_forwards[JP_NpcThinkPre],rets,id)
	if(rets == 1)
		return HAM_IGNORED
	if(CloseAi){
		cs_set_hostage_foll(id)
		return HAM_SUPERCEDE
	}
	new Beattackstatus = getnpc_BeAttackInThink(id)
	new Faketeam = getnpc_FakeTeam(id)
	if(Faketeam != CS_TEAM_CT){
		return HAM_IGNORED
	}
	new Float:NpcHeal = get_entvar(id, var_health)
	
	if(NpcHeal <= 0.0){
		return HAM_IGNORED
	}
	if(Beattackstatus == 1){
		setnpc_BeAttackInThink(id, 2)
		if(NpcHeal > 0.0){
			set_entvar(id,var_sequence, 13)
		}
		return HAM_IGNORED
	}else if (Beattackstatus == 2){
		setnpc_BeAttackInThink(id, 0)
		if(NpcHeal > 0.0){
			new Attacker = getnpc_Attacker(id)
			if(GetIsNpc(Attacker) && get_entvar(Attacker , var_deadflag) != DEAD_DEAD && KrGetFakeTeam(Attacker) == CS_TEAM_T){
				cs_set_hostage_foll(id, Attacker)
			}
			else if(Attacker && is_user_alive(Attacker) && is_user_connected(Attacker) && get_user_team(Attacker) == CS_TEAM_T){
				cs_set_hostage_foll(id, Attacker)
			}
		}
	}
	if(Faketeam == CS_TEAM_CT){
		new Float:reanim = get_prop_float(id,"reainmtime")
		new Currentsequence = get_entvar(id, var_sequence)
		new isinanim = is_in_anim(jp_Attack_anim, sizeof jp_Attack_anim, Currentsequence)
		if(get_gametime() > reanim && isinanim){
			play_anim(id, 13 , 9999.0)
		}
		new owner = cs_get_hostage_foll(id)
		//如果追随目标已死挂机
		if(owner && GetIsNpc(owner) && get_entvar(owner , var_deadflag) == DEAD_DEAD){
			cs_set_hostage_foll(id)
		}else if(!owner || get_entvar(owner , var_deadflag) == DEAD_DEAD || !is_user_connected(owner)){
			cs_set_hostage_foll(id)
		}

		new target = FindNearhuman(id)
	
		if(target > 0){
			cs_set_hostage_foll(id, target)
		}
		if(target > 0 && fm_get_entity_distance(id,target) <= 210.0){
			RibenNormlAttack(id,target)
		}
	}
	ExecuteForward(Jpnpc_forwards[Jp_NpcThinkPost],rets,id)
    return HAM_IGNORED
}

public DelSelf(id){
	rg_remove_entity(id)
}

public native_CreateJpNpc(plugin_id, num_params){
	new id = get_param(1)
	new FakeTeam = get_param(2)
	new body = get_param(5)
	new Float:origin[3]
	new Float:angles[3]
	new origin_str[32]
	get_array_f(3, origin, 3)
	get_array_f(4, angles, 4)

	new ent = rg_create_entity("hostage_entity")
	if(!pev_valid(ent)){
		server_print("创建人质实体失败")
		return -1
	}
	new rets
	ExecuteForward(Jpnpc_forwards[JP_NpcCreatePre] , rets , ent)
	if(rets == PLUGIN_HANDLED)
		return ent

	format(origin_str,31,"%i %i %i",floatround(origin[0]),floatround(origin[1]),floatround(origin[2]))
	DispatchKeyValue(ent,"model",Jp_Model[0])
	DispatchKeyValue(ent,"origin",origin_str)
	dllfunc(DLLFunc_Spawn, ent)
	new Float:val[3] = {0.0, 0.0, -10.0}
	set_entvar(ent, var_velocity, val)
	set_entvar(ent, var_origin, origin)
	set_entvar(ent, var_max_health, CurrentLeavelHeal)
	set_entvar(ent, var_health, CurrentLeavelHeal)
    // set_entvar(ent, var_classname, "hostage_entity")
    set_entvar(ent, var_body, body)
	set_prop_float(ent, "NextChange", get_gametime())
	set_prop_float(ent, "nextattack", get_gametime())
	set_prop_float(ent, "reainmtime", get_gametime())
	set_prop_int(ent, "FakeTeam", FakeTeam)
	set_prop_int(ent, "BeAttackInThink", 0)
	set_prop_int(ent, "Attacker",0)
	set_prop_int(ent, "IsNpc",1)
	ExecuteForward(Jpnpc_forwards[JP_NpcCreatePost] , rets , ent)
	ArrayPushCell(NpcList , ent)
	return ent
}

public native_GetIsNpc(P_id,nums){
	new id = get_param(1)
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

public getnpc_NextChange(id){
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

public getnpc_nextattack(id){
	if(!prop_exists(id, "nextattack")){
		return 0.0
	}
	new Float:nextattack = get_prop_float(id, "nextattack")
	return nextattack
}

public FakeClientTask(){
    if(FakeClient && is_entity(FakeClient) && is_user_bot(FakeClient)){
        cs_set_user_team(FakeClient, CS_TEAM_CT);
        new Float:origin[3] = {8188.0, 8188.0, 8188.0};

        engfunc(EngFunc_SetOrigin, FakeClient, origin);

        set_pev(FakeClient, pev_effects, pev(FakeClient, pev_effects) | EF_NODRAW);
        //server_print("FakeClient: flag %d", pev(FakeClient, pev_effects))
		set_pev(FakeClient, pev_solid, SOLID_NOT);
		set_pev(FakeClient, pev_movetype, MOVETYPE_NOCLIP);
		return;
    }
}

public CreateFakeClient(){
	FakeClient = engfunc(EngFunc_CreateFakeClient, Jp_defname)
	if(!pev_valid(FakeClient)){
		server_print("FakeClient创建失败")
		return
	} 
	engfunc(EngFunc_FreeEntPrivateData, FakeClient)
	new szMsg[128]
	dllfunc(DLLFunc_ClientConnect, FakeClient,Jp_defname, "127.0.0.1", szMsg)
	dllfunc(DLLFunc_ClientPutInServer, FakeClient)
	cs_set_user_team(FakeClient, CS_TEAM_CT)
	set_entvar(FakeClient,pev_takedamage,DAMAGE_NO)
	set_prop_int(FakeClient,"IsFake", 1)
}

public fw_HostageTouch(this , other){
    if(is_user_connected(other) && is_user_alive(other) && is_valid_ent(other)){
        if(get_user_team(other) == CS_TEAM_CT)
			return HAM_IGNORED
		new Float:origin[3], Float:other_origin[3];
    	new Float:vPush[2];
    	new Float:this_velocity[3];
        new const Float:PushForce = 50.0
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

    }
	return HAM_IGNORED
}

public is_in_anim(anims[],animssize,sequence){
	for(new i = 0; i < animssize; i++){
		if(anims[i] == sequence){
			return true
		}
	}
	return false
}

public play_anim(id , anim , Float:PlayTimer){
	set_pev(id, pev_sequence, anim)
	set_pev(id, pev_frame, 0.0)
	set_pev(id, pev_framerate, 1.0)
	set_pev(id, pev_animtime, get_gametime())
	set_prop_float(id,"reainmtime",get_gametime()+PlayTimer)
}

public SendDeathMessage(vim,attacker){
	static msgs_Deathmsg
	if(!msgs_Deathmsg){
		msgs_Deathmsg = get_user_msgid("DeathMsg")
	}
	new waeponname [32]
	new wpnid = cs_get_user_weapon(attacker)
	if(wpnid){
		get_weaponname(wpnid,waeponname,charsmax(waeponname))
	}else{
		copy(waeponname , 31 , "没有武器")
	}
	
	replace_all(waeponname, charsmax(waeponname), "weapon_", "")
	message_begin(MSG_BROADCAST, msgs_Deathmsg)
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
	write_short(cs_get_user_team(id)) 
	message_end()
}

public FindNearhuman(ent){
	new FakeTeam = getnpc_FakeTeam(ent)
	new Float:Currentlen , Float:origin[3] , Float:playerorigin[3]
	new Float:disstance = 0.0
	new target
	get_entvar(ent, var_origin, origin)
	for(new i = 1; i <= MaxClients; i++){
		if(!is_user_alive(i) || IsFakeClient(i))
			continue
		if(FakeTeam == get_user_team(i))
			continue
		get_entvar(i, var_origin, playerorigin)
		Currentlen = vector_distance(origin, playerorigin)
		if(Currentlen >= 2000.0)
			continue
		if(disstance <= 0.0 || Currentlen < disstance){
			disstance = Currentlen
			target = i
		}
	}
	new npc 
	//npc = FindNearAttackNpc(ent)
	return npc > 0 ? npc : target
}

public RibenNormlAttack(this ,beattack){
	new Float:origin[3],Float:Playerorigin[3];
	new Float:AttackTimeer = getnpc_nextattack(this)

	if(AttackTimeer > get_gametime())
		return;

	setnpc_nextattack(this, get_gametime() + random_float(1.5, 2.7))
	get_entvar(this, var_origin, origin)
	get_entvar(beattack, var_origin, Playerorigin)
	new Float:distance = vector_distance(origin, Playerorigin)
	new const Float:AttackDisance = GetRiJunRule() != JAP_RULE_Blade_Enhancement ?  90.0 : 100.0
	if(distance >= AttackDisance){
		if((distance - AttackDisance) < 5.0){
			//空了
			new soundnum = Npc_Isgirl(this) ? 1 : 0
			UTIL_EmitSound_ByCmd2(this, Jp_Attacksound[soundnum], 300.0)
			play_anim(this, jp_Attack_anim[random_num(0,4)], 1.0)
		}
		return;
	}
	play_anim(this, jp_Attack_anim[random_num(0,4)], 1.0)
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)

	new Float:damage = 5.0 + float(Getleavel()) //基础攻击力
	new judian = GetJuDianNum()
	damage = random_float(damage , damage + float(judian))
	damage = floatmin(damage, Max_Damage) //最大不要超过50
	if(GetRiJunRule() == JAP_RULE_Lethal_Critical_Strike && UTIL_RandFloatEvents(0.05)){
		damage *= 1.5
	}
	ExecuteHamB(Ham_TakeDamage, beattack, GetFakeClient(), GetFakeClient(), damage, DMG_CRUSH)
	if(GetIsNpc(beattack)){
		return
	}
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
	if(!is_user_alive(beattack)){
		new soundnum = AttackToDieMan
		new g_msgDeathMsg = get_user_msgid("DeathMsg");
		message_begin(MSG_BROADCAST, g_msgDeathMsg);
		write_byte(FakeClient);
		write_byte(beattack);
		write_byte(0);
		write_string("日本带派大脚");
		message_end();
		if(Npc_Isgirl(this)){
			soundnum = AttackToDieGl
		}
		UTIL_EmitSound_ByCmd2(this, Jp_Attacksound[soundnum], 300.0)
	}
	new sound = 0
	if(Npc_Isgirl(this)){
		sound = 1
	}
	UTIL_EmitSound_ByCmd2(this, Jp_Attacksound[sound], 300.0)
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
stock HasPlayerNpc(player){

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
        if(Stock_CanSee(npc , ent) == false)
            continue
        get_entvar(ent , var_origin , fOrigin)
        new Float:TmpDis = get_distance(fOrigin , m_Origin)
        if(Dis <= 0.0 || TmpDis < Dis){
            target = ent
            Dis = TmpDis
        }
    }
    return target
}