#include <amxmodx>
#include <kr_core>
#include <hamsandwich>
#include <reapi>
#include <engine>
#include <Npc_Manager>
#include <xp_module>
#include <cstrike>
#include <fakemeta_util>
#include <props>
#include <xs>

#define Max_Npcs 50
#define SeeMax 200
//=======================================
new Kr_Npc[Max_Npcs][Npc_Register]
new Kr_NpcName[Max_Npcs][32]
new Kr_NpcLevel[Max_Npcs]
new Aiid

new Kr_NpcOnCreate , Kr_NpcDoAttack , Kr_NpcDoSkill

public plugin_init(){
    register_plugin("Npc管理" , "1.0" , "Bing")
    register_clcmd("say /npc" , "npcMenu")
    register_clcmd("say npc" , "npcMenu")
    
    RegisterHam(Ham_Think, "hostage_entity", "Ai_Think")
    //RegisterHam(Ham_Think, "hostage_entity", "Ai_Think_Post" , true)

    RegisterHam(Ham_TakeDamage, "hostage_entity", "Ai_DamgePost", 1)

    plugin_forward() // 初始化回调函数
}

public plugin_forward(){
    Kr_NpcOnCreate = CreateMultiForward("NpcOnCreate" , ET_IGNORE , FP_CELL)
    Kr_NpcDoAttack = CreateMultiForward("NpcDoAttack" , ET_IGNORE , FP_CELL , FP_CELL)
    Kr_NpcDoSkill = CreateMultiForward("NpcOnSkill" , ET_IGNORE , FP_CELL , FP_CELL)
}

public plugin_end(){

}

public client_disconnected(i){
    RemoveMasterNpc(i)
}

public RemoveMasterNpc(id){
    new ent = -1
    while(ent = rg_find_ent_by_class(ent , "hostage_entity")){
        if(GetNpcFakeTeam(ent) == CS_TEAM_T){
            new master = get_prop_int(ent , var_master)
            if(master == id){
                rg_remove_entity(ent)
            }
        }
    }
}

public plugin_natives(){
    register_native("NpcRegister" , "native_NpcRegister")
    register_native("NpcSetNameAndLevel" , "native_NpcSetNameAndLevel")
    register_native("NpcSetTinkRate" , "native_NpcSetTinkRate")
    register_native("NpcSendAnim" , "SendAnim" , 1)
    register_native("NpcTakeDamge" , "native_NpcTakeDamge" , 1)
}


public npcMenu(id){
    new userlv = GetXp(id)
    new const canbuyFormat[] = "\r[%s] %d 等级 \y%f大洋"
    new const nocanbuyFormat[] = "\d[%s] %d 等级 \y%f大洋"
    new menuid = menu_create("购买抗日伙伴" , "NpcBuyMenu")
    for(new i = 0 ; i < Aiid; i++){
        static name[32] , infonum[7]
        if(userlv > Kr_NpcLevel[i]){
            formatex(name , charsmax(name) , canbuyFormat , Kr_NpcName[i] , Kr_NpcLevel[i] , Kr_Npc[i][Npc_Money])
        }else{
            formatex(name , charsmax(name) , nocanbuyFormat ,  Kr_NpcName[i] , Kr_NpcLevel[i] , Kr_Npc[i][Npc_Money])
        }
        num_to_str(i , infonum , 6)
        menu_additem(menuid , name , infonum)
    }
    menu_display(id , menuid)
}

public NpcBuyMenu(id,menu,item){
    if(item == MENU_EXIT || !is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_CT){
        menu_destroy(menu)
        return
    }
    new SelNpcid , idBuff[7] ,access
    menu_item_getinfo(menu , item , access , idBuff , 6)
    SelNpcid = str_to_num(idBuff)
    CreateNpc(id , SelNpcid)
}

public NPC_Killed(this , killer){
    new Team = GetNpcFakeTeam(this)
    if(Team == CS_TEAM_CT)
        return
    new Npcid = get_prop_int(this , var_npcid)
    SendAnim(this , Kr_Npc[Npcid][Npc_Death_seqid] , 68)
    return
}

public Ai_DamgePost(this, idinflictor, idattacker, Float:damage, damagebits){
    if(GetNpcFakeTeam(this) == CS_TEAM_CT)
        return
    if(get_entvar(this , var_health)  <= 0.0){
        new Npcid = get_prop_int(this , var_npcid)
        new Float:Deadtime = Kr_Npc[Npcid][Npc_DeadRemoveTime]
        new Float:RemoveTime = get_gametime() + Deadtime
        set_prop_float(this , var_deadtime ,  RemoveTime)
        SetThink(this , "Ai_Think")
        set_entvar(this , var_nextthink , get_gametime() + 0.2)
    }else {
        new iSeq = LookupActivity(this , 26)
        if(iSeq != -1){
            SendAnim(this ,iSeq , 26)
            set_prop_int(this , var_seqanim , Npc_FLINCH)
            set_prop_float(this , var_flFlinchTime , get_gametime() + 0.75)
        }
    }
    return
}



public CreateNpc(other , SelNpcid){
    new Float:WatchOrigin[3]
    new Float:zeroVec[3] = {0.0, 0.0, 0.0}
    GetWatchEnd(other , WatchOrigin , 200.0)
    new npc = CreateJpNpc(0 , CS_TEAM_T , WatchOrigin , zeroVec , 0)
    if(is_nullent(npc)){
        log_amx("[提醒] 创建抗日伙伴失败")
        return npc
    }
    log_amx("Moduleid %d heal :%f" , Kr_Npc[SelNpcid][Npc_Module] , Kr_Npc[SelNpcid][Npc_Heal])
    set_entvar(npc , var_modelindex , Kr_Npc[SelNpcid][Npc_Module])
    set_entvar(npc , var_sequence , Kr_Npc[SelNpcid][Npc_Idel_seqid])
    set_entvar(npc , var_health , Kr_Npc[SelNpcid][Npc_Heal])
    set_entvar(npc , var_max_health , Kr_Npc[SelNpcid][Npc_Heal])
    set_entvar(npc , var_nextthink , get_gametime() + 0.1)
    set_entvar(npc , var_origin , WatchOrigin)

    set_prop_int(npc , var_npcid , SelNpcid)
    set_prop_int(npc , var_master , other)
    set_prop_int(npc , var_state , NpcState_FollowMaster)
    set_prop_float(npc , var_deadtime , 0.0)
    set_prop_int(npc , var_thinkstate , Npc_Thinking)
    set_prop_int(npc , var_seqanim , Npc_IDLE)
    set_prop_float(npc , var_flFlinchTime , get_gametime())
    set_prop_float(npc , var_lastattack , get_gametime())
    set_prop_float(npc , var_skillcd , get_gametime())
    set_prop_float(npc , var_nextSerNpc , get_gametime())
    set_prop_float(npc , var_LastSeeTime , get_gametime())
    set_prop_int(npc , var_LastSee , 0)

    if(CheckStuck(npc)){
        rg_remove_entity(npc)
        client_print(other , print_center ,"此处不能放置Npc,请重新放置")
        npcMenu(other)
        return -1
    }
    SetAnimEventHandle(npc, "HandleAnimEvent")
    ExecuteForward(Kr_NpcOnCreate , _ , npc)
    return npc
}

public HandleAnimEvent(const id, event, const event_option[], len_option){

}

public native_NpcRegister(id , nums){
    if(Aiid >= Max_Npcs){
        log_amx("[提醒] Npc注册数量已达上限%d" , Max_Npcs)
        return -1
    }
    new oldid = Aiid
    Kr_Npc[Aiid][Npc_Heal] = get_param_f(1)
    Kr_Npc[Aiid][Npc_Module] = get_param(2)
    Kr_Npc[Aiid][Npc_AttackDistance] = get_param_f(3)
    Kr_Npc[Aiid][Npc_AttackRate] = get_param_f(4)
    Kr_Npc[Aiid][Npc_AttackDamge] = get_param_f(5)
    Kr_Npc[Aiid][Npc_AttackRange] = get_param_f(6)
    Kr_Npc[Aiid][Npc_Idel_seqid] = get_param(7)
    Kr_Npc[Aiid][Npc_Walk_seqid] = get_param(8)
    Kr_Npc[Aiid][Npc_Run_seqid] = get_param(9)
    Kr_Npc[Aiid][Npc_Attack_seqid] = get_param(10)
    Kr_Npc[Aiid][Npc_Death_seqid] = get_param(11)
    Kr_Npc[Aiid][Npc_DeadRemoveTime] = get_param(12)
    Kr_Npc[Aiid][Npc_Money] = get_param_f(13)
    Kr_Npc[Aiid][NpcMode] = get_param(14)
    Kr_Npc[Aiid][Npc_ThinkRate] = 0.1
    Aiid++
    return oldid
}

public native_NpcSetNameAndLevel(id , nums){
    new id = get_param(1)
    get_string(2 ,Kr_NpcName[id] , charsmax(Kr_NpcName[]))
    new level = get_param(3)
    Kr_NpcLevel[id] = level
}

public native_NpcSetTinkRate(id , nums){
    new id = get_param(1)
    Kr_Npc[id][Npc_ThinkRate] = get_param_f(2)
}

public Ai_Think(npc_id){
    new FakeTeam = GetNpcFakeTeam(npc_id)
    if(FakeTeam == CS_TEAM_CT)
        return HAM_IGNORED
    new Float:GameTime = get_gametime()
    new npc_regid = get_prop_int(npc_id , var_npcid)
    if(get_entvar(npc_id , var_health) <= 0.0 || get_entvar(npc_id , var_deadflag) == DEAD_DEAD){
        new Float:DeadTime = get_prop_float(npc_id , var_deadtime)
        SetThink(npc_id , "Ai_Think")
        set_entvar(npc_id , var_nextthink , GameTime + 1.0)
        if(DeadTime > 0.0 && GameTime > get_prop_float(npc_id , var_deadtime))
            rg_remove_entity(npc_id)
        return HAM_SUPERCEDE
    }
    if(NeedRemoveSelf(npc_id))
        rg_remove_entity(npc_id)

    new Float:NextThink = Kr_Npc[npc_regid][Npc_ThinkRate]
    new master = get_prop_int(npc_id , var_master)
    set_entvar(npc_id , var_nextthink , GameTime + NextThink)
    new NpcState = get_prop_int(npc_id, var_state)
    new m_AttackEnt
    m_AttackEnt = FindNearAttackNpc(npc_id)

    if(m_AttackEnt <= 0 && NpcState == NpcState_FollowMaster){
        cs_set_hostage_foll(npc_id , master)
        return HAM_IGNORED
    }else if(m_AttackEnt <= 0 && NpcState == NpcState_Idel ){
        cs_set_hostage_foll(npc_id)
        return HAM_IGNORED
    }
    cs_set_hostage_foll(npc_id , m_AttackEnt)
    if(!is_valid_ent(m_AttackEnt) || get_entvar(m_AttackEnt , var_deadflag) == DEAD_DEAD){
        cs_set_hostage_foll(npc_id , master)
    }
    new Float:V_Angle[3],Float:TargetOrigin[3],Float:fOrigin[3]
    get_entvar(m_AttackEnt , var_v_angle , V_Angle)
    get_entvar(m_AttackEnt , var_origin , TargetOrigin)
    get_entvar(npc_id , var_origin , fOrigin)
    new Float:disance = fm_distance_to_boxent(npc_id , m_AttackEnt)
    if(disance <= Kr_Npc[npc_regid][Npc_AttackDistance]){
        new Float:last = get_prop_float(npc_id , var_lastattack)
        new Float:skilltime = get_prop_float(npc_id , var_skillcd)
        new NpcLoadMode = Kr_Npc[npc_regid][NpcMode]

        if(GameTime > last){
            new Float:vDir[3] ,  Float:AttackOrig[3] , Float:vecVelocity[3] , Float:NewAngle[3]
            new Float:NextAttackTime = GameTime + Kr_Npc[npc_regid][Npc_AttackRate]
            xs_vec_sub(TargetOrigin, fOrigin, vDir)
		    xs_vec_normalize(vDir, vDir)
		    xs_vec_add(fOrigin, vDir, AttackOrig)
            Stock_GetSpeedVector(fOrigin , TargetOrigin , 0.01 , vecVelocity)
            vector_to_angle(vecVelocity , NewAngle)
            if(NewAngle[0] > 90.0) NewAngle[0] = -(360.0 - NewAngle[0]);
            NewAngle[0] = 0.0
            set_entvar(npc_id , var_angles , NewAngle)
            ExecuteForward(Kr_NpcDoAttack , _ , npc_id , m_AttackEnt)
            SendAnim(npc_id , Kr_Npc[npc_regid][Npc_Attack_seqid] , 0)
            set_member(npc_id , m_fSequenceFinished , 0)
            set_prop_int(npc_id , var_seqanim , Npc_Attack)
            set_prop_float(npc_id , var_lastattack ,NextAttackTime)
        }
        if(GameTime > skilltime){
            ExecuteForward(Kr_NpcDoSkill , _ , npc_id , m_AttackEnt) // 需要自己在回调设置skillcd
        }
        if(NpcLoadMode == NpcMode_Ranged){
            StudioFrameAdvance(npc_id)
            return HAM_SUPERCEDE
        }
        return HAM_IGNORED
    }else{
        cs_set_hostage_foll(npc_id , master)
    }
    return HAM_IGNORED
}

public Ai_Think_Post(npc_id){
    new Float:Vel[3]
    get_entvar(npc_id , var_velocity , Vel)
    new Float:Speed = xs_vec_len(Vel)
    if(get_entvar(npc_id ,var_deadflag) == DEAD_DEAD || GetNpcFakeTeam(npc_id) == CS_TEAM_CT)
        return
    new npc_regid = get_prop_int(npc_id , var_npcid)
    new Float:NextThink = Kr_Npc[npc_regid][Npc_ThinkRate]
    set_entvar(npc_id , var_nextthink , get_gametime() + NextThink)
    new SequenceFinished = get_member(npc_id , m_fSequenceFinished)
    if(!SequenceFinished && get_prop_int(npc_id , var_seqanim) == Npc_Attack){
        return
    }
    if(Speed > 135.0){
        new Seq = LookupActivity(npc_id , 4) //ACT_RUN
        set_prop_int(npc_id , var_seqanim , Npc_Run)
        if(Seq != -1){
            SendAnim(npc_id , Seq , 4)
            return
        }
        SendAnim(npc_id , Kr_Npc[get_prop_int(npc_id , var_npcid)][Npc_Run_seqid] , 4)
    }else{
        if(Speed > 0.0){
            new Seq = LookupActivity(npc_id , 3) //ACT_WALK
            set_prop_int(npc_id , var_seqanim , Npc_Walk)
            if(Seq != -1){
                SendAnim(npc_id , Seq , 3)
                return
            }
            SendAnim(npc_id , Kr_Npc[get_prop_int(npc_id , var_npcid)][Npc_Walk_seqid] , 3)
        }else{
            new Seq = LookupActivity(npc_id , 1) //ACT_IDLE
            set_prop_int(npc_id , var_seqanim , Npc_IDLE)
            if(Seq != -1){
                SendAnim(npc_id , Seq , 1)
                return
            }
            SendAnim(npc_id , Kr_Npc[get_prop_int(npc_id , var_npcid)][Npc_Idel_seqid] , 1)
        }
    }
    return
}

public native_NpcTakeDamge(npcid , targetid , Float:Damge){
    new RegNpcid = get_prop_int(npcid , var_npcid)
    new master = get_prop_int(npcid , var_master)
    if(Damge <= 0.0){
        Damge = Kr_Npc[RegNpcid][Npc_AttackDamge]
    }
    ExecuteHamB(Ham_TakeDamage , targetid , npcid , master , Damge , DMG_BULLET)
}

//================= stock函数 =====================
stock GetNpcFakeTeam(id){
    if(!prop_exists(id, "FakeTeam")){
		return 0
	}
	new FakeTeam = get_prop_int(id, "FakeTeam")
	return FakeTeam
}

stock FindNearAttackNpc(npc){
    new ent = -1
    new target = -1

    new Float:Dis = 0.0 , Float:fOrigin[3] , Float:m_Origin[3]
    
    new regid = get_prop_int(npc , var_npcid)
    new Float:AttackDisacne = Kr_Npc[regid][Npc_AttackDistance] + 100.0

    new folent = cs_get_hostage_foll(npc)
    new Float:NextSer = get_prop_float(npc , var_nextSerNpc)
    
    if(get_gametime() < NextSer && GetIsNpc(folent) && get_entvar(folent , var_deadflag) != DEAD_DEAD){
        return folent
    }
    set_prop_float(npc , var_nextSerNpc , get_gametime() + 1.0)
    get_entvar(npc , var_origin , m_Origin)

    new Array:NpcHandle = GetNpcList()
    new size = ArraySize(NpcHandle)
    new npcteam = GetNpcFakeTeam(npc)

    for(new i = 0 ; i < size ; i++){
        new ent = ArrayGetCell(NpcHandle , i)
        if(is_nullent(ent))continue
        if(ent == npc || GetNpcFakeTeam(ent) == npcteam) continue
        if(get_entvar(ent , var_deadflag) == DEAD_DEAD)continue
        get_entvar(ent , var_origin , fOrigin)
        if(vector_distance(fOrigin , m_Origin) > AttackDisacne)continue

        new bool:see = Stock_CanSee(npc , ent)
        if(see == false)continue
        
        new Float:TmpDis = get_distance(fOrigin , m_Origin)
        if(TmpDis < Dis || Dis <= 0.0){
            target = ent
            Dis = TmpDis
        }
    }
    return target
}

stock NeedRemoveSelf(npcid){
    if(GetNpcFakeTeam(npcid) == CS_TEAM_CT)
        return false
    new master = get_prop_int(npcid , var_master)
    if(is_user_connected(master))
        return false
    return true
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

stock bool:Stock_CanSee(entindex1, entindex2){
    if (!is_nullent(entindex1) || !is_nullent(entindex2))
		return false

	return TraceCanSee(entindex1 , entindex2)
}

stock TraceCanSee(entindex1, entindex2){

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
	return false
}


stock GetWatchEnd(player , Float:OutEndOrigin[3] , Float:Distance){
    new Float:hitorigin[3]
    new Float:StartOrigin[3],Float:EndOrigin[3],Float:Eyes[3]
    new Float:angles[3], Float:fwd[3];
    get_entvar(player, var_origin , StartOrigin)
    get_entvar(player, var_view_ofs, Eyes)
    xs_vec_add(StartOrigin, Eyes, StartOrigin)
    get_entvar(player, var_v_angle, angles)
    engfunc(EngFunc_MakeVectors, angles)
    global_get(glb_v_forward, fwd)
    xs_vec_mul_scalar(fwd, Distance, EndOrigin)
    xs_vec_add(StartOrigin,EndOrigin,EndOrigin)
	fm_trace_line(player, StartOrigin, EndOrigin, hitorigin)
    xs_vec_copy(hitorigin, OutEndOrigin)
}


stock CheckStuck(iNpcEntity){
    new Float:fOrigin[3]
    get_entvar(iNpcEntity , var_origin , fOrigin)
    engfunc(EngFunc_TraceMonsterHull, iNpcEntity, fOrigin, fOrigin, DONT_IGNORE_MONSTERS, iNpcEntity, 0)
    if(get_tr2(0 , TR_StartSolid) && get_tr2(0 , TR_AllSolid) && !get_tr2(0, TR_InOpen)){
        return true
    }
    return false
}

stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

public SendAnim(iEntity, iAnim , ACT)
{
	if(get_member(iEntity , m_Activity) == ACT)
		return
    if(get_prop_int(iEntity , var_seqanim) == Npc_FLINCH && get_gametime() < get_prop_float(iEntity , var_flFlinchTime)){
        set_prop_int(iEntity, var_seqanim , Npc_FLINCH)
        return //播放受击
    }
    new seq = get_entvar(iEntity , var_sequence)
    if(seq != iAnim){
        new is_loop = GetSeqFlags(iEntity) & STUDIO_LOOPING
        new flag , Float:flFrameRate , Float:GroundSpeed
        set_member(iEntity , m_fSequenceLoops , is_loop)
	    set_entvar(iEntity, var_sequence, iAnim)
	    set_entvar(iEntity, var_animtime, get_gametime())
        new seqanim = get_prop_int(iEntity , var_seqanim)
	    if(seqanim != Npc_Walk && seqanim != Npc_Run){
            set_entvar(iEntity, var_frame, 0.0)
        }
	    set_entvar(iEntity, var_framerate, 1.0)
        GetSequenceInfo(iEntity, flag , flFrameRate, GroundSpeed)
        set_member(iEntity , m_flFrameRate , flFrameRate)
        set_member(iEntity , m_flGroundSpeed , GroundSpeed)
        set_member(iEntity , m_Activity , ACT)
        ResetSequenceInfo(iEntity)
        StudioFrameAdvance(iEntity)
    }
}