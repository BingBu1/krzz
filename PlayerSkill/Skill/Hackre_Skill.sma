#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <cstrike>
#include <hamsandwich>
#include <props>

new Float:g_OldDamageValue

public plugin_init(){
    new plid = register_plugin("角色技能-黑客" , "1.0" , "Bing")
    RegPlayerSkill(plid , "HackerSkill" , "anonim_player" , 160.0)
}

// 猫姬技能
public HackerSkill(id){
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了黑客技能:你被开户了" , username)
    ChangeMonster(id)
    if(g_OldDamageValue <= 0.0){
        g_OldDamageValue = GetLvDamageReduction()
        SetLvDamageReduction(g_OldDamageValue - 0.2)
        set_task(60.0 , "ReSkillDamge")
    }
}

public ReSkillDamge(){
    SetLvDamageReduction(g_OldDamageValue)
    g_OldDamageValue = 0.0
}

public ChangeMonster(id){

    new CsTeams:team = cs_get_user_team(id)
    new ent = -1
    new Change_1,Change_2
    new name[32]
    get_user_name(id , name , charsmax(name))
    while((ent = rg_find_ent_by_class(ent , "hostage_entity" , true)) > 0){
        if(GetIsNpc(ent) && KrGetFakeTeam(ent) == team)
            continue
        if(is_tank(ent) && prop_exists(ent , "attackfire")){
            set_prop_float(ent, "attackfire" , get_gametime() + 60.0)
            Change_1++
        }
        if(prop_exists(ent , "CanStop")){
            set_prop_int(ent , "CanStop" , 0)
            Change_2++
        }        
    }
    m_print_color(0 , "%s瘫痪了%d个坦克,并关闭了%d个精英的反疼痛装置" , name , Change_1 , Change_2)
}
