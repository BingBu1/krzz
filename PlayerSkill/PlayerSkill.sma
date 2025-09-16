#include <amxmodx>
#include <kr_core>
#include <engine>
#include <fakemeta>
#include <animation>
#include <hamsandwich>
#include <PlayerSkill>

new Trie:SkillReg

new Float:SkillCd[33]

new SkillId

public plugin_init(){
    new plid = register_plugin("角色技能" , "1.0" , "Bing")
    
    SkillReg = TrieCreate()

    register_clcmd("radio3" , "SkillOn")

    register_logevent( "round_start_event", 2, "1=Round_Start" );
}

public plugin_natives(){
    register_native("RegPlayerSkill" , "native_RegPlayerSkill")
}

public round_start_event(){
    arrayset(SkillCd , 0 , sizeof SkillCd)
}

public plugin_end(){
    TrieDestroy(SkillReg)
}

public GetSkillId(id){
    new modelName[32]
    get_user_info(id, "model", modelName, charsmax(modelName))
    new Size = TrieGetSize(SkillReg)
    for(new i = 0 ; i < Size; i++){
        new key[10]
        new SkillData[SKillStruct]
        num_to_str(i , key , charsmax(key))
        TrieGetArray(SkillReg , key , SkillData , sizeof(SkillData))
        if(!strcmp(SkillData[SkillModelNames] , modelName))
            return i
    }
    return -1
}

public GetSKillData(keynum , DataBuff[SKillStruct] , len){
    new key[10]
    num_to_str(keynum , key , charsmax(key))
    TrieGetArray(SkillReg , key , DataBuff , len)
}

public SkillOn(id){
    new skillid = GetSkillId(id)
    if(skillid == -1)
        return PLUGIN_HANDLED
    static SkillFuns[64]
    if(get_gametime() < SkillCd[id]){
        m_print_color(id , "你的技能还在冷却，剩余%0.f秒" , SkillCd[id] - get_gametime())
        return PLUGIN_HANDLED
    }

    new SkillData[SKillStruct]
    GetSKillData(skillid , SkillData , sizeof SkillData)
    SkillCd[id] = get_gametime() + SkillData[SkillCoolDown]
    new funcid = get_func_id(SkillData[SkillCallBack], SkillData[SkillPlugin_id])
    callfunc_begin_i(funcid , SkillData[SkillPlugin_id])
    callfunc_push_int(id)
    callfunc_end()

    return PLUGIN_HANDLED
}

public native_RegPlayerSkill(id , nums){
    new SKillData[SKillStruct]
    new key[10]
    new old_Skillid = SkillId
    num_to_str(SkillId , key , charsmax(key))
    SKillData[SkillPlugin_id] = get_param(1)
    get_string(2 , SKillData[SkillCallBack] , charsmax(SKillData[SkillCallBack]))
    get_string(3 , SKillData[SkillModelNames] , charsmax(SKillData[SkillModelNames]))
    SKillData[SkillCoolDown] = get_param_f(4)
    TrieSetArray(SkillReg , key , SKillData , sizeof SKillData)
    SkillId++
    return SkillId
}

public GetPlayerSkillFun(SkillId:skillid , output[] , len){
    new key[10]
    num_to_str(skillid , key , charsmax(key))
    TrieGetString(SkillReg , key , output , len)
}

