#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>

public plugin_init(){
    new plid = register_plugin("角色技能-牢大" , "1.0" , "Bing")
    RegPlayerSkill(plid , "LaodaSkill" , "kobelaoda" , 60.0)
}

public plugin_precache(){
    UTIL_Precache_Sound("kr_sound/LaoDa_Skill.wav")
}

// 猫姬技能
public LaodaSkill(id){
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了牢大技能:孩子们想我吗" , username)
    UTIL_EmitSound_ByCmd(0 , "kr_sound/LaoDa_Skill.wav")
    set_task(1.0 , "HealthAll" , id + 645 , .flags = "b")
    set_task(10.5 , "Close" , id + 645)
}

public HealthAll(id){
    id -=645
    for(new i = 1 ; i < MaxClients ; i++){
        if(!is_user_connected(i) || !is_user_alive(id))
            continue
        if(get_user_team(i) == CS_TEAM_CT)
            continue
        new Float:Health = get_entvar(i , var_health)
        if(i == id){
            Health += 5.0
            m_print_color(id , "!t你治愈了你自己+5hp")
        }else {
            Health += 10.0
            client_print(i , print_center , "牢大帮你治疗了10滴血快说谢谢牢大")
        }
        set_entvar(i , var_health , Health)
    }
}

public Close(id){
    remove_task(id)
}
