#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <cstrike>
#include <hamsandwich>

new g_Explosion

public plugin_init(){
    new plid = register_plugin("角色技能-牢大" , "1.0" , "Bing")
    RegPlayerSkill(plid , "LaodaSkill" , "kobelaoda" , 360.0)
}

public plugin_precache(){
    UTIL_Precache_Sound("kr_sound/LaoDa_Skill.wav")
    g_Explosion = precache_model("sprites/zerogxplode.spr")
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
    const Float:MaxHeal = 320.0
    for(new i = 1 ; i < MaxClients ; i++){
        if(!is_user_connected(i) || !is_user_alive(id))
            continue
        if(cs_get_user_team(i) == CS_TEAM_CT)
            continue
        new Float:Health = get_entvar(i , var_health)
        if(Health > MaxHeal)
            continue
        if(i == id){
            Health += 15.0
            m_print_color(id , "!t你治愈了你自己+15hp")
        }else {
            Health += 15.0
            client_print(i , print_center , "牢大帮你治疗了10滴血快说谢谢牢大")
        }
        if(Health > MaxHeal)
            Health = MaxHeal
        set_entvar(i , var_health , Health)
    }
    apacheBoom(id)
}

public apacheBoom(id){
    new ent = -1
    while((ent = rg_find_ent_by_class(ent , "apache")) > 0){
        new Float:Origin[3]
        get_entvar(ent , var_origin , Origin)
        MakeBigBoom(Origin)
        rg_dmg_radius(Origin , id , id , 1500.0 , 1000.0 , CLASS_PLAYER , DMG_GENERIC)
    }
}

public MakeBigBoom(Float:Origin[3]){
    new iOrigin[3]
    FVecIVec(Origin , iOrigin)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin)
    write_byte(TE_EXPLOSION)
    write_coord(iOrigin[0])
    write_coord(iOrigin[1])
    write_coord(iOrigin[2])
    write_short(g_Explosion)
    write_byte(200)
    write_byte(15)
    write_byte(0)
    message_end()
}

public Close(id){
    remove_task(id)
}
