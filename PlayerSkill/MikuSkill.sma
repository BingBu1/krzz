#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>

new bool:InSkill , Float:SkillTimer
new HamHook:DamgeHandle , HamHook:PostDamageHandle
new SkillMaster
public plugin_init(){
    new plid = register_plugin("角色技能-初音" , "1.0" , "Bing")
    RegPlayerSkill(plid , "Miku_Skill" , "Miku" , 360.0)
    DamgeHandle = RegisterHam(Ham_TakeDamage , "hostage_entity" , "Dmage_pre")
    // PostDamageHandle = RegisterHam(Ham_TakeDamage , "hostage_entity" , "Dmage_post" , 1)
    DisableHamForward(DamgeHandle)
    // DisableHamForward(PostDamageHandle)
}


public Dmage_pre(this , inf , attacker , Float:Damage , dmg_bit){
    if(!InSkill || get_gametime() > SkillTimer){
        CloseSkill()
    }
    if(!is_user_connected(SkillMaster) || !is_user_alive(SkillMaster))
        return HAM_IGNORED
    new Float:SkillHeal = get_entvar(SkillMaster , var_health)
    new Float:MewDamage = Damage * 1.5
    MewDamage += SkillHeal * 0.5
    SetHamParamFloat(4 , MewDamage)
    return HAM_IGNORED
}

// public Dmage_post(this , inf , attacker , Float:Damage , dmg_bit){
//     if(!InSkill || get_gametime() > SkillTimer){
//         CloseSkill()
//     }
//     if(!is_user_connected(SkillMaster) || !is_user_alive(SkillMaster))
//         return HAM_IGNORED
//     new Float:Health = get_entvar(this , var_health)
//     if(Health <= 0.0)
//         return HAM_IGNORED
//     new Float:SkillHeal = get_entvar(SkillMaster , var_health)
//     // DisableHamForward(PostDamageHandle)
//     // // ExecuteHamB(Ham_TakeDamage , this , SkillMaster , SkillMaster , SkillHeal * 1.5 , DMG_GENERIC)
//     // EnableHamForward(PostDamageHandle)
//     return HAM_IGNORED
// }

public Miku_Skill(id){
    if(InSkill){
        SetSkillCd(id , 0.0)
        m_print_color(id , "!g[冰布提示]!t已有相同效果技能正在释放请等待")
        return
    }
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了初音技能: 虚拟歌姬的支援" , username)
    InSkill = true
    SkillTimer = get_gametime() + 35.0
    SkillMaster = id
    set_task(35.0 , "CloseSkill")
    EnableHamForward(DamgeHandle)
    EnableHamForward(PostDamageHandle)
    PlayerSkillBuff()
}

PlayerSkillBuff(){
    new name[32]
    get_user_name(SkillMaster , name , charsmax(name))
    for(new i = 1 ; i < MaxClients ; i++){
        if(is_user_bot(i) || !is_user_connected(i))
            continue
        if(is_user_alive(i)){
            set_entvar(i , var_health , 500.0)
        }else{
            ExecuteHam(Ham_CS_RoundRespawn , i)
        }
        client_print(i , print_center , "%s的技能支援了你。" , name)
    }
    m_print_color(0 , "%s释放了技能,接下来60秒内地方获得150%易伤,和%s150%生命附伤" , name ,name)
}

public CloseSkill(){
    InSkill = false
    SkillTimer = 0.0
    SkillMaster = 0
    DisableHamForward(DamgeHandle)
    // DisableHamForward(PostDamageHandle)
}