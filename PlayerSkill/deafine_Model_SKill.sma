#include <amxmodx>
#include <PlayerSkill>
#include <cstrike>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>

new bool:MaxSpeed[33]
new bool:Money_add[33]
new Array:FindPlayer

public plugin_init(){
    new plid = register_plugin("角色技能-基础模型" , "1.0" , "Bing")
    RegPlayerSkill(plid , "Ra_skill" , "rainych_krall1" , 0.0)
    RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed , "m_MaxSpeed")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    FindPlayer = ArrayCreate()
}

public plugin_precache(){
    // UTIL_Precache_Sound("kr_sound/LaoDa_Skill.wav")
}

public plugin_end(){
    ArrayClear(FindPlayer)
}

public event_roundstart(){
    arrayset(MaxSpeed , 0 , sizeof MaxSpeed)
    arrayset(Money_add , 0 , sizeof Money_add)
}

public client_putinserver(id){
    MaxSpeed[id] = false
    Money_add[id] = false
}

// 猫姬技能
public Ra_skill(id){
    new bodyid = get_entvar(id , var_body)
    switch(bodyid){
        case 1 , 2 , 3 : GetAmmo(id)
        case 4 , 5 : Givebulletproof(id)
        case 6 , 7 , 8 : Givebulletproof(id) , GetAmmo(id)
        case 9 , 10 , 11 ,12: SpeedRun(id)
        case 13 : MoneyAdd(id)
        case 14 : GodMode(id)
    }
}

public GetAmmo(id){
    new wpn = get_member(id, m_pActiveItem)
    if(wpn <= 0)
        return
    new MaxAmmo = rg_get_iteminfo(wpn,ItemInfo_iMaxAmmo1)
    new WeaponIdType:wpnid = WeaponIdType:rg_get_iteminfo(wpn, ItemInfo_iId)
    if(wpnid == WEAPON_KNIFE || wpnid == WEAPON_HEGRENADE ||
        wpnid == WEAPON_FLASHBANG || wpnid == WEAPON_SMOKEGRENADE){
        m_print_color(id, "!g[冰布提醒]!y此武器不支持使用技能")
        return;
    }
    MaxAmmo /= 2
    new orbpammo = rg_get_user_bpammo(id,wpnid)
    rg_set_user_bpammo(id,wpnid, orbpammo + MaxAmmo)
    client_print(id , print_center , "你使用技能补充了弹药")
    SetSkillCd(id , 60.0)
}

public Givebulletproof(id){
    rg_set_user_armor(id , 100 , ARMOR_VESTHELM)
    client_print(id , print_center , "你使用技能补充了防弹衣")
    SetSkillCd(id , 60.0)
}

public SpeedRun(id){
    rg_set_user_armor(id , 100 , ARMOR_VESTHELM)
    client_print(id , print_center , "你使用了急速狂奔,接下来30秒内移速剧增")
    MaxSpeed[id] = true
    set_task(30.0 , "CloseSpeed" , id + 600)
    SetSkillCd(id , 40.0)
}

public CloseSpeed(id){
    id -= 600
    if(is_user_connected(id)){
        MaxSpeed[id] = false
    }
}

public m_MaxSpeed(const this){
    if(MaxSpeed[this]){
        new wpn = get_member(this , m_pActiveItem)
        if(is_entity(wpn)){
            set_entvar(this , var_maxspeed , 600.0)
            return HC_SUPERCEDE
        }
    }
    return HC_CONTINUE
}

public MoneyAdd(const this){
    new username[32]
    get_user_name(this , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]%s使用了老蒋技能 : 优势在我" , username)
    m_print_color(0 , "!g[冰布提示]%s接下来1分钟内击杀收益增加25。" , username)
    Money_add[this] = true
    set_task(60.0 , "CloseMoney" , this + 6000)
    SetSkillCd(this , 150.0)
}

public GodMode(const this){
    new username[32]
    get_user_name(this , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]%s使用了毛爷爷技能 : 人民的军队" , username)
    SetSkillCd(this , 100.0)

    SkillFindPlayer(this)
    new size = ArraySize(FindPlayer)
    for(new i = 0 ; i < size ; i++){
        new player = ArrayGetCell(FindPlayer , i)
        set_entvar(player , var_takedamage , DAMAGE_NO)
        set_task(10.0 , "UnGod" , player + 1212)
    }
}

public SkillFindPlayer(const playerid){
    ArrayClear(FindPlayer)
    new ent = -1
    new Float:Origin[3]
    get_entvar(playerid , var_origin , Origin)
    new m_team = get_member(playerid , m_iTeam)
    while((ent = find_ent_in_sphere(ent , Origin , 300.0)) > 0){
        if(ExecuteHam(Ham_IsPlayer , ent) && is_user_alive(ent)){
            if(get_member(ent , m_iTeam) != m_team)
                continue
            ArrayPushCell(FindPlayer , ent)
            if(playerid == ent){
                m_print_color(ent , "你激励了无数将士,接下来10秒内你不会受到任何伤害。")
                client_print(ent , print_center ,"你激励了无数将士,接下来10秒内你不会受到任何伤害。")
                continue
            }
            m_print_color(ent , "毛爷爷的话语鼓励你,你无畏发起冲锋,接下来10秒内你不会受到任何伤害。")
            client_print(ent , print_center ,"毛爷爷的话语鼓励你,你无畏发起冲锋,接下来10秒内你不会受到任何伤害。")
        }
    }
}

public UnGod(id){
    new player = id -1212
    set_entvar(player , var_takedamage , DAMAGE_YES)
}

public CloseMoney(id){
    id -= 6000
    Money_add[id] = false
}

public NPC_Killed(this , killer){
    if(ExecuteHam(Ham_IsPlayer , killer) && Money_add[killer]){
        cs_set_user_money(killer , cs_get_user_money(killer) + 25)
    }
}