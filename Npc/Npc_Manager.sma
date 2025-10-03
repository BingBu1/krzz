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

#define Max_SpawnNpc 50
#define Max_NpcReg 50
#define SeeMax 200
#define Hostage_m_block 0x1eb
//=======================================
new Kr_Npc[Max_NpcReg][Npc_Register]
new Kr_NpcName[Max_NpcReg][32]
new Kr_NpcLevel[Max_NpcReg]
new Aiid
new Float:FullThink , Float:ClearTrie

new Kr_NpcOnCreate , Kr_NpcDoAttack , Kr_NpcDoSkill , Kr_CreateNpcNums

new Trie:CaCheSee

public plugin_init(){
    register_plugin("Npc管理" , "1.0" , "Bing")
    register_clcmd("say /npc" , "npcMenu")
    register_clcmd("say npc" , "npcMenu")
    register_clcmd("say /npccommand" , "NpcCommand")
    register_clcmd("say npccommand" , "NpcCommand")
    register_clcmd("say command" , "NpcCommand")
    register_clcmd("say /command" , "NpcCommand")
    
    RegisterHam(Ham_Think, "hostage_entity", "Ai_Think")
    RegisterHam(Ham_Think, "hostage_entity", "Ai_Think_Post" , true)

    RegisterHam(Ham_TakeDamage, "hostage_entity", "Ai_DamgePost", 1)
    RegisterHam(Ham_TakeDamage, "hostage_entity", "Ai_DamgePre")

    register_logevent("EventRoundEnd", 2, "1=Round_End")

    plugin_forward() // 初始化回调函数
    CaCheSee = TrieCreate()
}

public plugin_forward(){
    Kr_NpcOnCreate = CreateMultiForward("NpcOnCreate" , ET_IGNORE , FP_CELL ,FP_CELL)
    Kr_NpcDoAttack = CreateMultiForward("NpcDoAttack" , ET_IGNORE , FP_CELL , FP_CELL)
    Kr_NpcDoSkill = CreateMultiForward("NpcOnSkill" , ET_IGNORE , FP_CELL , FP_CELL)
}

public plugin_end(){
    TrieDestroy(CaCheSee)
}

public EventRoundEnd(){
    TrieDestroy(CaCheSee)
    CaCheSee = TrieCreate()
    Kr_CreateNpcNums = 0
}

public client_disconnected(i){
    RemoveMasterNpc(i)
}

public RemoveMasterNpc(id){
    new ent = -1
    while((ent = rg_find_ent_by_class(ent , "hostage_entity")) > 0){
        if(GetNpcFakeTeam(ent) == _:CS_TEAM_T){
            new master = get_prop_int(ent , var_master)
            if(master == id){
                rg_remove_entity(ent)
            }
        }
    }
}

public plugin_natives(){
    register_native("NpcRegister" , "native_NpcRegister")
    register_native("CreateNpcByTeam" , "native_CreateNpcByTeam")
    register_native("NpcSetNameAndLevel" , "native_NpcSetNameAndLevel")
    register_native("SetNpcHasSkill" , "native_SetNpcHasSkill")
    register_native("GetNpcHasSkill" , "native_GetNpcHasSkill")
    register_native("NpcSetTinkRate" , "native_NpcSetTinkRate")
    register_native("NpcSendAnim" , "SendAnim" , 1)
    register_native("NpcTakeDamge" , "native_NpcTakeDamge" , 1)
}


public NpcCommand(id){
    new menuid = menu_create("Npc命令" , "CommandAll")
    menu_additem(menuid , "全部跟随我")
    menu_additem(menuid , "全部停下")
    menu_display(id , menuid)
}

public CommandAll(id,menu,item){
    if(item == MENU_EXIT || !is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_CT){
        menu_destroy(menu)
        return
    }
    switch(item){
        case 0 :{
            FollowAllNpc(id)
        }
        case 1:{
            StopAllNpc(id)
        }
    }
}

public npcMenu(id) {
    new userlv = GetLv(id)
    new const canbuyFormat[] = "%s(\y%.0f大洋)(%d级) "
    new const nocanbuyFormat[] = "\d%s(\y%.0f大洋)(%d级)"
    new menuid = menu_create("购买抗日伙伴" , "NpcBuyMenu")

    // 创建一个临时数组来存储索引
    new sortIndex[Max_NpcReg]
    for (new i = 0; i < Aiid; i++) {
        sortIndex[i] = i
    }

    // 简单的冒泡排序 (按等级升序)
    for (new i = 0; i < Aiid - 1; i++) {
        for (new j = i + 1; j < Aiid; j++) {
            if (Kr_NpcLevel[sortIndex[i]] > Kr_NpcLevel[sortIndex[j]]) {
                new tmp = sortIndex[i]
                sortIndex[i] = sortIndex[j]
                sortIndex[j] = tmp
            }
        }
    }

    // 按照排序后的顺序添加菜单
    for (new k = 0; k < Aiid; k++) {
        new i = sortIndex[k]   // 真实的 Aiid
        static name[64], infonum[7]

        if (userlv >= Kr_NpcLevel[i]) {
            formatex(name, charsmax(name), canbuyFormat, Kr_NpcName[i], Kr_Npc[i][Npc_Money], Kr_NpcLevel[i])
        } else {
            formatex(name, charsmax(name), nocanbuyFormat, Kr_NpcName[i], Kr_Npc[i][Npc_Money], Kr_NpcLevel[i])
        }

        num_to_str(i, infonum, charsmax(infonum)) // infonum 保持 Aiid 对应
        menu_additem(menuid, name, infonum)
    }

    menu_display(id, menuid)
}

// public npcMenu(id){
//     new userlv = GetLv(id)
//     new const canbuyFormat[] = "%s(\y%.0f大洋)(%d级) "
//     new const nocanbuyFormat[] = "\d%s(\y%.0f大洋)(%d级)"
//     new menuid = menu_create("购买抗日伙伴" , "NpcBuyMenu")
//     for(new i = 0 ; i < Aiid; i++){
//         static name[32] , infonum[7]
//         if(userlv > Kr_NpcLevel[i]){
//             formatex(name , charsmax(name) , canbuyFormat , Kr_NpcName[i] , Kr_Npc[i][Npc_Money], Kr_NpcLevel[i] )
//         }else{
//             formatex(name , charsmax(name) , nocanbuyFormat ,  Kr_NpcName[i] , Kr_Npc[i][Npc_Money],Kr_NpcLevel[i] )
//         }
//         num_to_str(i , infonum , 6)
//         menu_additem(menuid , name , infonum)
//     }
//     menu_display(id , menuid)
// }

public NpcBuyMenu(id, menu, item){
    if(item == MENU_EXIT || !is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_CT){
        menu_destroy(menu)
        return
    }
    new SelNpcid , idBuff[7] ,access
    menu_item_getinfo(menu , item , access , idBuff , 6)
    SelNpcid = str_to_num(idBuff)
    
    new lv = GetLv(id)
    new Float:NeedAmmo = Kr_Npc[SelNpcid][Npc_Money]
    new bool:IsHaveBuyAmmo
#if defined Usedecimal
    IsHaveBuyAmmo = Dec_cmp(id , NeedAmmo , ">=")
#else
    new Float:Ammo = GetAmmoPak(id)
    IsHaveBuyAmmo = (Ammo >= NeedAmmo)
#endif
    if(!IsHaveBuyAmmo){
        m_print_color(id , "[提示] !t 大洋不足。")
        menu_destroy(menu)
        return
    }
    
    if(lv < Kr_NpcLevel[SelNpcid]){
        m_print_color(id , "[提示] !t 你的等级不足以召唤，以后会推出跨级体验(多消耗大洋)")
        menu_destroy(menu)
        return
    }
    
    if(CreateNpc(id , SelNpcid) > 0)
        SubAmmoPak(id , NeedAmmo)

    menu_destroy(menu)
    return
}

public NPC_Killed(this , killer){
    new Team = GetNpcFakeTeam(this)
    if(Team == _:CS_TEAM_CT || !prop_exists(this , var_npcid))
        return
    new Npcid = get_prop_int(this , var_npcid)
    set_entvar(this, var_sequence ,  Kr_Npc[Npcid][Npc_Death_seqid])
    set_entvar(this, var_frame, 0.0)
    // SendAnim(this , , ACT_DIE_CHESTSHOT)
    return
}

public Ai_DamgePost(this, idinflictor, idattacker, Float:damage, damagebits){
    if(GetNpcFakeTeam(this) == _:CS_TEAM_CT)
        return
    if(get_entvar(this , var_health) <= 0.0){
        Kr_CreateNpcNums--
        new Npcid = get_prop_int(this , var_npcid)
        new Float:Deadtime = Kr_Npc[Npcid][Npc_DeadRemoveTime]
        new Float:RemoveTime = get_gametime() + Deadtime
        set_prop_float(this , var_deadtime ,  RemoveTime)
        SetThink(this , "Ai_Think")
        set_entvar(this , var_nextthink , get_gametime() + 0.2)
    }else{
        SendAnim(this , 0 , 0)
    }
    return
}

public Ai_DamgePre(this, idinflictor, idattacker, Float:damage, damagebits){
    if(GetNpcFakeTeam(this) == _:CS_TEAM_CT)
        return
    new Npcid = get_prop_int(this , var_npcid)
    new Npc_Mode:NpcLoadMode = Npc_Mode:Kr_Npc[Npcid][NpcMode]
    if(NpcLoadMode == NpcMode_Warrior){
        new Float:newdamge = damage * (1.0 - GetLvDamageReduction())
        SetHamParamFloat(4 , newdamge)
    }
}

public native_CreateNpcByTeam(nums , id){
    new Npcid = get_param(1)
    new NpcTeam = get_param(2)
    new Float:fOrigin[3]
    get_array_f(3 , fOrigin , sizeof fOrigin)
    new Npc = CreateNpc(0 , Npcid , CsTeams:NpcTeam)
    engfunc(EngFunc_SetOrigin , Npc , fOrigin)
    return Npc
}

stock CreateNpc(other , SelNpcid , CsTeams:NpcTeam = CS_TEAM_T){
    if(Kr_CreateNpcNums >= Max_SpawnNpc && other > 0 && NpcTeam == CS_TEAM_T){
        m_print_color(other , "!t[提示]NPC已达最大上限50，不可生成。")
        return -1
    }
    new Float:WatchOrigin[3]
    new Float:zeroVec[3] = {0.0, 0.0, 0.0}
    new npc = 0
    if(NpcTeam == CS_TEAM_T){
        GetWatchEnd(other , WatchOrigin , 200.0)
        npc = CreateJpNpc(0 , _:NpcTeam , WatchOrigin , zeroVec , 0 , true)
    }else{
        npc = CreateJpNpc(0 , _:NpcTeam , zeroVec , zeroVec , 0 , true)
    }
    
    if(is_nullent(npc)){
        log_amx("[提醒] 创建抗日伙伴失败")
        return npc
    }
    set_entvar(npc , var_modelindex , Kr_Npc[SelNpcid][Npc_Module])
    set_entvar(npc , var_sequence , Kr_Npc[SelNpcid][Npc_Idel_seqid])
    set_entvar(npc , var_health , Kr_Npc[SelNpcid][Npc_Heal])
    set_entvar(npc , var_max_health , Kr_Npc[SelNpcid][Npc_Heal])
    set_entvar(npc , var_nextthink , get_gametime() + 0.1)
    set_entvar(npc , var_origin , WatchOrigin)

    //因为setmember没有被迫自己写
    set_pdata_int(npc , Hostage_m_block , true)

    set_prop_int(npc , var_npcid , SelNpcid)
    set_prop_int(npc , var_master , other)
    set_prop_int(npc , var_state , _:NpcState_FollowMaster)
    set_prop_float(npc , var_deadtime , 0.0)
    set_prop_int(npc , var_thinkstate , _:Npc_Thinking)
    set_prop_int(npc , var_seqanim , _:Npc_IDLE)
    set_prop_float(npc , var_flFlinchTime , get_gametime())
    set_prop_float(npc , var_lastattack , get_gametime())
    set_prop_float(npc , var_skillcd , get_gametime())
    set_prop_float(npc , var_nextSerNpc , get_gametime())
    set_prop_float(npc , var_LastSeeTime , get_gametime())
    set_prop_float(npc , var_NextFullThink , get_gametime())
    set_prop_int(npc , var_LastSee , 0)

    if(CheckStuck(npc) && other > 0 && NpcTeam == CS_TEAM_T){
        rg_remove_entity(npc)
        client_print(other , print_center ,"此处不能放置Npc,请重新放置")
        npcMenu(other)
        return -1
    }
    SetUse(npc , "OnUse")
    ExecuteForward(Kr_NpcOnCreate , _ , npc , SelNpcid)
    Kr_CreateNpcNums++
    return npc
}

public OnUse(const ent, const activator, const caller, USE_TYPE:useType, Float:value){

}

public native_NpcRegister(id , nums){
    if(Aiid >= Max_NpcReg){
        log_amx("[提醒] Npc注册数量已达上限%d" , Max_NpcReg)
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
    Kr_Npc[Aiid][Npc_DeadRemoveTime] = get_param_f(12)
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

public native_SetNpcHasSkill(id , nums){
    new Npcid = get_param(1)
    new HasSkill = get_param(2)
    Kr_Npc[Npcid][Npc_HasSkill] = HasSkill
}

public native_GetNpcHasSkill(id , nums){
    new Npcid = get_param(1)
    return Kr_Npc[Npcid][Npc_HasSkill]
}

public native_NpcSetTinkRate(id , nums){
    new id = get_param(1)
    Kr_Npc[id][Npc_ThinkRate] = get_param_f(2)
}

public Ai_Think(npc_id){
    new FakeTeam = GetNpcFakeTeam(npc_id)
    //跳过默认NPC
    if(FakeTeam == _:CS_TEAM_CT && !prop_exists(npc_id , var_npcid))
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
    
    StudioFrameAdvance(npc_id)
    // DispatchAnimEvent(npc_id, 0.1)

    FullThink = get_prop_float(npc_id , var_NextFullThink)
    if(FullThink > GameTime)
        return HAM_SUPERCEDE
    set_prop_float(npc_id , var_NextFullThink , GameTime + 0.1)
    set_pdata_float(npc_id , 477 , 0.0) //解除原thinkfull

    new master = get_prop_int(npc_id , var_master)
    new NpcState = get_prop_int(npc_id, var_state)
    new m_AttackEnt
    new Npc_Mode:NpcLoadMode = Npc_Mode:Kr_Npc[npc_regid][NpcMode]

    m_AttackEnt = FakeTeam == _:CS_TEAM_T ? FindNearAttackNpc(npc_id , NpcLoadMode) : FindNearHuman(npc_id , cs_get_hostage_foll(npc_id))

    if(m_AttackEnt <= 0 && NpcState == _:NpcState_FollowMaster){
        new folling = cs_get_hostage_foll(npc_id)
        if(folling != master){
            cs_set_hostage_foll(npc_id , master)
        }
        return HAM_IGNORED
    }else if(m_AttackEnt <= 0 && NpcState == _:NpcState_Idel ){
        cs_set_hostage_foll(npc_id)
        return HAM_IGNORED
    }
    cs_set_hostage_foll(npc_id , m_AttackEnt)
    if(get_entvar(m_AttackEnt , var_deadflag) || is_nullent(m_AttackEnt)){
        cs_set_hostage_foll(npc_id , master)
        return HAM_IGNORED
    }
    new Float:V_Angle[3],Float:TargetOrigin[3],Float:fOrigin[3]
    get_entvar(m_AttackEnt , var_v_angle , V_Angle)
    get_entvar(m_AttackEnt , var_origin , TargetOrigin)
    get_entvar(npc_id , var_origin , fOrigin)
    new Float:disance = fm_distance_to_boxent(npc_id , m_AttackEnt)
    
    if(disance <= Kr_Npc[npc_regid][Npc_AttackDistance] && is_entity(m_AttackEnt)){
        new Float:last = get_prop_float(npc_id , var_lastattack)
        new Float:skilltime = get_prop_float(npc_id , var_skillcd)
        new bool:HasSKill = GetNpcHasSkill(npc_regid)
        if(HasSKill && GameTime > skilltime){
            ExecuteForward(Kr_NpcDoSkill , _ , npc_id , m_AttackEnt) // 需要自己在回调设置skillcd
        }
        else if(GameTime > last){
            new Float:vDir[3] ,  Float:AttackOrig[3] , Float:vecVelocity[3] , Float:NewAngle[3]
            new Float:NextAttackTime = GameTime + Kr_Npc[npc_regid][Npc_AttackRate]
            xs_vec_sub(TargetOrigin, fOrigin, vDir)
            xs_vec_normalize(vDir, vDir)
            xs_vec_add(fOrigin, vDir, AttackOrig)
            Stock_GetSpeedVector(fOrigin , TargetOrigin , 0.01 , vecVelocity)
            vector_to_angle(vecVelocity , NewAngle)
            if(NewAngle[0] > 90.0) NewAngle[0] = -(360.0 - NewAngle[0])
            NewAngle[0] = 0.0
            set_entvar(npc_id , var_angles , NewAngle)
            ExecuteForward(Kr_NpcDoAttack , _ , npc_id , m_AttackEnt)
            SendAnim(npc_id , Kr_Npc[npc_regid][Npc_Attack_seqid] , _:ACT_SPECIAL_ATTACK1)
            set_member(npc_id , m_fSequenceFinished , 0)
            set_prop_int(npc_id , var_seqanim , _:Npc_Attack)
            set_prop_float(npc_id , var_lastattack ,NextAttackTime)
        }
        if(NpcLoadMode == NpcMode_Ranged){
            return HAM_SUPERCEDE
        }
        return HAM_IGNORED
    }else if((NpcLoadMode == NpcMode_Warrior && disance >= 600.0) || NpcLoadMode == NpcMode_Ranged){
        if(NpcState == _:NpcState_FollowMaster){
            cs_set_hostage_foll(npc_id , master)
        }
    }
    return HAM_IGNORED
}

public Ai_Think_Post(npc_id){
    if(get_entvar(npc_id ,var_deadflag) == DEAD_DEAD || GetNpcFakeTeam(npc_id) == _:CS_TEAM_CT)
        return
    
    // new npc_regid = get_prop_int(npc_id , var_npcid)
    // new Float:NextThink = Kr_Npc[npc_regid][Npc_ThinkRate]
    set_entvar(npc_id , var_nextthink , get_gametime() + 0.03)

    new SequenceFinished = get_member(npc_id , m_fSequenceFinished)
    if(!SequenceFinished && get_prop_int(npc_id , var_seqanim) == _:Npc_Attack){
        return
    }

    new Float:Vel[3]
    get_entvar(npc_id , var_velocity , Vel)
    new Float:Speed = xs_vec_len(Vel)

    if(Speed > 135.0){
        new Seq = LookupActivity(npc_id , 4) //ACT_RUN
        set_prop_int(npc_id , var_seqanim , _:Npc_Run)
        if(Seq != -1){
            SendAnim(npc_id , Seq , 4)
            return
        }
        SendAnim(npc_id , Kr_Npc[get_prop_int(npc_id , var_npcid)][Npc_Run_seqid] , 4)
    }else{
        if(Speed > 0.0){
            new Seq = LookupActivity(npc_id , 3) //ACT_WALK
            set_prop_int(npc_id , var_seqanim , _:Npc_Walk)
            if(Seq != -1){
                SendAnim(npc_id , Seq , 3)
                return
            }
            SendAnim(npc_id , Kr_Npc[get_prop_int(npc_id , var_npcid)][Npc_Walk_seqid] , 3)
        }else{
            new Seq = LookupActivity(npc_id , 1) //ACT_IDLE
            set_prop_int(npc_id , var_seqanim , _:Npc_IDLE)
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

stock FindNearAttackNpc(npc , Npc_Mode:Mode){
    new ent = -1
    new target = -1

    new Float:Dis = 999999.0 , Float:fOrigin[3] , Float:m_Origin[3] , Float:TmpDis
    
    // new regid = get_prop_int(npc , var_npcid)
    // new Float:AttackDisacne = Kr_Npc[regid][Npc_AttackDistance] + 100.0

    new folent = cs_get_hostage_foll(npc)
    new Float:NextSer = get_prop_float(npc , var_nextSerNpc)
    
    if(get_gametime() < NextSer && GetIsNpc(folent) && get_entvar(folent , var_deadflag) != DEAD_DEAD){
        return folent
    }
    set_prop_float(npc , var_nextSerNpc , get_gametime() + random_float(0.2,0.5))
    get_entvar(npc , var_origin , m_Origin)

    // new Array:NpcHandle = GetNpcList()
    // new size = ArraySize(NpcHandle)
    new npcteam = GetNpcFakeTeam(npc)
    while ((ent = rg_find_ent_by_class(ent , "hostage_entity") ) > 0){
        if(is_nullent(ent))continue
        if(ent == npc || GetNpcFakeTeam(ent) == npcteam) continue
        if(get_entvar(ent , var_deadflag) == DEAD_DEAD)continue

        get_entvar(ent , var_origin , fOrigin)
        
        TmpDis = fm_distance_to_boxent(npc , ent)
        if((TmpDis < Dis && get_entvar(ent , var_deadflag) == DEAD_NO)){
            target = ent
            Dis = TmpDis
        }
    }
    if(target == -1){
        set_prop_float(npc , var_nextSerNpc , get_gametime() + random_float(0.5,1.5))
        return -1
    }
    if(Mode == NpcMode_Ranged || Mode == NpcMode_Warrior){
        //只对最近敌人进行可视判断
        new iterations = 0;
        const MAX_ITER = 5;
        new TrHit = 0
        new bool:ret = Stock_CanSee(npc , target , TrHit)
        if(ret){
            return target
        }
        else if(TrHit > 0 && GetIsNpc(TrHit) && KrGetFakeTeam(TrHit) == _:CS_TEAM_T) {
            new observer = TrHit
            while(iterations < MAX_ITER){
                ret = Stock_CanSee(observer , target , TrHit)
                if(ret)
                    return target
                if(TrHit <= 0 || !GetIsNpc(TrHit))
                    break
                if(KrGetFakeTeam(TrHit) == _:CS_TEAM_CT)
                    return TrHit
                observer = TrHit
                iterations++
            }
        }
        return -1  
    }
    return target
}

stock NeedRemoveSelf(npcid){
    if(GetNpcFakeTeam(npcid) == _:CS_TEAM_CT)
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

stock ClearTries(Float:Timer){
    new Float:Time = Timer
    if(ClearTrie > Time)
        return
    ClearTrie = Time + 10.0
    TrieDestroy(CaCheSee)
    CaCheSee = TrieCreate()
}

stock bool:Stock_CanSee(entindex1, entindex2 , &TrHit){
    if (is_nullent(entindex1) || is_nullent(entindex2))
    	return false
    static buff[10]
    new data[Npc_Cache]
    new Float:GameTime = get_gametime()
    ClearTries(GameTime)
    formatex(buff , 9 , "%d_%d" , entindex1, entindex2)
    if(TrieKeyExists(CaCheSee , buff)){
        TrieGetArray(CaCheSee , buff , data , sizeof(data))
        if(GameTime < data[NpcCache_NextSeeTime]){
            return data[NpcCache_CanSee] //缓存
        }
    }
    new bool:IsSee = TraceCanSee(entindex1 , entindex2 , TrHit)
    data[NpcCache_Ent1] = entindex1
    data[NpcCache_Ent2] = entindex2
    data[NpcCache_CanSee] = IsSee
    data[NpcCache_NextSeeTime] = GameTime + random_float(0.35,0.5)
    TrieSetArray(CaCheSee , buff , data , sizeof data)
    return IsSee
}

stock bool:TraceCanSee(entindex1, entindex2 , &TrHit){

	new flags = get_entvar(entindex1, var_flags)
	TrHit = 0
	if (flags & EF_NODRAW){
        return false
    }
	
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
		TrHit = get_tr2(0, TraceResult:TR_pHit)
		if (flFraction == 1.0 ||  TrHit == entindex2){
             return true
        }
		else
		{
			for(i = 0; i < 3; i++) targetOrig[i] = targetBaseOrig[i]
			engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			TrHit = get_tr2(0, TraceResult:TR_pHit)
			if (flFraction == 1.0 || TrHit == entindex2){
                return true
            }
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2] - 17.0
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				TrHit = get_tr2(0, TraceResult:TR_pHit)
				if (flFraction == 1.0 ||  TrHit == entindex2)
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
    if(get_tr2(0 , TR_StartSolid) || get_tr2(0 , TR_AllSolid) || !get_tr2(0, TR_InOpen)){
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
        if(seqanim != _:Npc_Walk && seqanim != _:Npc_Run){
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

stock StopAllNpc(id){
    new ent = -1
    while((ent = rg_find_ent_by_class(ent , "hostage_entity")) > 0){
        if(is_nullent(ent))continue
        if(KrGetFakeTeam(ent) == _:CS_TEAM_CT)continue
        if(get_entvar(ent , var_deadflag) == DEAD_DEAD)continue
        if(get_prop_int(ent , var_master) != id)continue
        set_prop_int(ent , var_state , _:NpcState_Idel)
    }
}

stock FollowAllNpc(id){
    new ent = -1
    while((ent = rg_find_ent_by_class(ent , "hostage_entity")) > 0){
        if(is_nullent(ent))continue
        if(KrGetFakeTeam(ent) == _:CS_TEAM_CT)continue
        if(get_entvar(ent , var_deadflag) == DEAD_DEAD)continue
        if(get_prop_int(ent , var_master) != id)continue
        set_prop_int(ent , var_state , _:NpcState_FollowMaster)
    }
}

stock FindNearHuman(ent, CurrentFollow = 0) {
    new FakeTeam = KrGetFakeTeam(ent);
    new Float:CurrentLen, Float:origin[3], Float:playerOrigin[3], Float:targetOrigin[3];
    new Float:MinDistance = 999999.0;
    new target = -1;
    new TrHit
    // 获取实体位置
    get_entvar(ent, var_origin, origin);

    // 如果已有目标，就以它为基准距离
    if (CurrentFollow > 0 && is_user_alive(CurrentFollow)) {
        get_entvar(CurrentFollow, var_origin, targetOrigin);
        MinDistance = vector_distance(origin, targetOrigin);
        target = CurrentFollow;
    }

    for (new i = 1; i <= MaxClients; i++) {
        if (!is_user_alive(i) || is_user_bot(i))
            continue;

        if (FakeTeam == get_user_team(i))
            continue;
        if( !TraceCanSee(ent , i , TrHit))
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