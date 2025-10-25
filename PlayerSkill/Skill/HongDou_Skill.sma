#include <amxmodx>
#include <PlayerSkill>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <kr_core>
#include <hamsandwich>

new Array:FindPlayer , HookChain:PostThinkHandle
new bool:InSkill , Float:SkillTimer

new CmdEndHandle
public plugin_init(){
    new plid = register_plugin("角色技能-红豆" , "1.0" , "Bing")
    RegPlayerSkill(plid , "hongdou_SKill" , "hongdou" , 200.0)
    PostThinkHandle = RegisterHookChain(RG_CBasePlayer_PostThink , "PostThink_Pre")
    DisableHookChain(PostThinkHandle)
    FindPlayer = ArrayCreate()
}

public plugin_precache(){
    // UTIL_Precache_Sound("kr_sound/LaoDa_Skill.wav")
}

public plugin_end(){
    ArrayDestroy(FindPlayer)
}


public hongdou_SKill(id){
    if(InSkill){
        SetSkillCd(id , 0.0)
        m_print_color(id , "!g[冰布提示]!t已有相同效果技能正在释放请等待")
        return
    }
    new username[32]
    get_user_name(id , username , charsmax(username))
    m_print_color(0 , "!g[冰布提示]!t%s释放了红豆技能:本职的工作" , username)
    SkillFindPlayer(id)
    InSkill = true
    SkillTimer = get_gametime() + 30.0
    EnableHookChain(PostThinkHandle)
    // CmdEndHandle = register_forward(FM_CmdEnd , "CmdEnd_Pre")
    
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
            m_print_color(ent , "你受到了红豆的鼓励，接下来30秒射速加快并无限子弹。")
            client_print(ent , print_center ,"你受到了红豆的鼓励，接下来30秒射速加快并无限子弹。")
        }
    }
}

public PostThink_Pre(const playerid){
    if(InSkill){
        if(get_gametime() > SkillTimer){
            // unregister_forward(FM_CmdEnd , CmdEndHandle)
            DisableHookChain(PostThinkHandle)
            ArrayClear(FindPlayer)
            InSkill = false
        }
        new Float:frametimer
        global_get(glb_frametime, frametimer) 
        if(ArrayFindValue(FindPlayer , playerid) != -1){
            FireTimerHalving(playerid , frametimer)
        }
    }
}

public CmdEnd_Pre(const playerid){

}

FireTimerHalving(const Player , Float:frametimer){
    for(new i = 0 ; i < MAX_ITEM_TYPES; i++){
        new PPlayetItem = get_member(Player , m_rgpPlayerItems , i)
        while(PPlayetItem > 0){
            new Float:flNextPrimaryAttack = get_member(PPlayetItem , m_Weapon_flNextPrimaryAttack)
            new Float:flNextSecondaryAttack = get_member(PPlayetItem , m_Weapon_flNextSecondaryAttack)
            flNextPrimaryAttack = floatmax(flNextPrimaryAttack - frametimer, -1.0)
            flNextSecondaryAttack = floatmax(flNextSecondaryAttack - frametimer, -0.001)
            set_member(PPlayetItem , m_Weapon_flNextPrimaryAttack , flNextPrimaryAttack)
            set_member(PPlayetItem , m_Weapon_flNextSecondaryAttack , flNextSecondaryAttack)
            PPlayetItem = get_member(PPlayetItem , m_pNext)
        }
    }
    new Float:NextAttack = get_member(Player , m_flNextAttack)
    NextAttack = floatmax(NextAttack - frametimer , -0.001)
    set_member(Player , m_flNextAttack , NextAttack)
    new CurrentWeapon = get_member(Player , m_pActiveItem)
    if(CurrentWeapon > 0){
        new Slot = rg_get_iteminfo(CurrentWeapon , ItemInfo_iSlot)
        if(Slot <= 1){
            new MaxClip = rg_get_iteminfo(CurrentWeapon , ItemInfo_iMaxClip)
            set_member(CurrentWeapon , m_Weapon_iClip , MaxClip)
        }
    }
}

