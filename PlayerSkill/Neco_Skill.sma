#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>



public plugin_init(){
    new plid = register_plugin("角色技能-猫姬" , "1.0" , "Bing")
    RegPlayerSkill(plid , "NecoSKill" , "NecoArc" , 1.0)
}

public plugin_precache(){

    UTIL_Precache_Sound("kr_sound/necoact-Skill.wav")
}

// 猫姬技能
public NecoSKill(id){
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了猫姬技能:暂定" , username)
    UTIL_EmitSound_ByCmd(0 , "kr_sound/necoact-Skill.wav")
}
