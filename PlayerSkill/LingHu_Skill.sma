#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>

new bool:IsLingHu[33]

public plugin_init(){
    register_plugin("角色技能-灵狐" , "1.0" , "Bing")
    RegisterHam(Ham_TakeDamage , "hostage_entity" , "H_Damge_Pre")
}

public client_disconnected(id){
    IsLingHu[id] = false
}


public OnModelChange(id , name[]){
    if(!strcmp(name ,"linghu_yellow")){
        IsLingHu[id] = true
        return
    }
    IsLingHu[id] = false
}

public H_Damge_Pre(const this , const inflictor , const attacker , Float:Damage , dmg_bits){
    if(!ExecuteHam(Ham_IsPlayer , attacker))
        return HAM_IGNORED
    if(IsLingHu[attacker]){
        SetHamParamFloat(4 , Damage * 1.5)
    }
    return HAM_IGNORED
}
