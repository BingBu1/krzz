#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <reapi>
#include <kr_core>
#include <xp_module>
new Jp_PlayerModule[]= "models/player/rainych_krall1/rainych_krall1.mdl"
enum StartBgm{
    Hero_CrossFire,
    Lv_CrossFire,
    Vip_CrossFire
}
new BgmStart[StartBgm][]= {
    "corssfire_bgm/N_Hero_CrossFire.wav",
    "corssfire_bgm/N_Lv_CrossFire.wav",
    "corssfire_bgm/N_Vip_CrossFire.wav"
}

new linghu [][]= {
    "models/player/linghu_red/linghu_red.mdl",
    "models/player/linghu_yellow/linghu_yellow.mdl",
    "models/player/FOX_BL/FOX_BL.mdl"
}

new modelNames[][]={
    "小八路",
    "老八路",
    "士兵",
    "男军官",
    "女军官",
    "黄皮八路",
    "黄皮男军官",
    "黄皮女军官",
    "特警",
    "黑皮男军官",
    "黑皮女军官",
    "海军",
    "老蒋",
    "毛爷爷",
    "灵狐者"
}

new hero[33]

public plugin_init(){
    register_plugin("设置玩家模型", "1.0", "Bing")
    RegisterHookChain(RG_CBasePlayer_Spawn,"PlayerSpawn_Post",true)
    RegisterHookChain(RG_CBasePlayer_RoundRespawn,"PlayerSpawn_Post",true)
    RegisterHookChain(RG_CBasePlayer_DropPlayerItem,"DropItems",true)
    RegisterHookChain(RG_CBasePlayer_MakeBomber,"MakeBoom",true)
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")

    register_clcmd("say /changemodle" , "CreateMoudleMenu")
}

public plugin_precache(){
    precache_model(Jp_PlayerModule)
    for(new i = 0 ; i < sizeof linghu ; i++){
        precache_model(linghu[i])
    }   
    for(new i = 0 ; i < sizeof BgmStart ; i++){
        UTIL_Precache_Sound(BgmStart[i])
    }   
}

public plugin_natives(){
    register_native("Make_Hero", "native_MakeHero")
}

public event_roundstart(){
    arrayset(hero , 0 , sizeof(hero))
}

public PlayerSpawn_Post(this){
    if(!is_nullent(this) && !is_user_alive(this)){
        return HC_CONTINUE
    }
    if(cs_get_user_team(this) == CS_TEAM_T && !is_user_bot(this) && !hero[this]){
        SetModuleByLv(this)
    }else if(hero[this]){
        rg_set_user_model(this, "linghu_red")
        return HC_CONTINUE
    }
    return HC_CONTINUE
}

public MakeBoom(const this){
    m_print_color(this, "!g[提示]你被选为抗日英雄,拥有特殊武器以及特殊模型。带领大家走向胜利吧。")
    MakeHero(this)
}

public native_MakeHero(id, nums){
    new ids = get_param(1)
    if(!is_user_connected(ids) || !is_user_alive(ids) || hero[ids]){
        return
    }
    MakeHero(ids)
}

public MakeHero(const id){
    hero[id] = true
    rg_set_user_model(id, "linghu_red")
    set_task(0.5,"GiveHeroWeapon",id)
}

public GiveHeroWeapon(id){
    new Rand = random_num(0,1)
    if(!Rand){
        GiveWeaponByNames("暗影狙击", id)
    }else {
        amxclient_cmd(id , "giveherogun")
    }
    
    set_entvar(id, var_health, 500.0) // 500血
    UTIL_EmitSound_ByCmd2(id, BgmStart[Hero_CrossFire], 300.0 )
}

public DropItems(const this, const pszItemName[]){
    if(!is_user_connected(this))
        return
    new body = get_entvar(this, var_body)
    if(body == 0 && !hero[this] || cs_get_user_team(this) == CS_TEAM_CT){
        SetModuleByLv(this)
    }
}

public SetModuleByLv(this){
    client_cmd(this , "cl_minmodels 0")
    new lv = GetLv(this)
    new setlv = (lv / 50) + 1
    new team = get_user_team(this)
    switch(team){
        case CS_TEAM_T:{
            if(setlv > 14){
                SetOtherModule(this,setlv)
                return;
            }
            rg_set_user_model(this, "rainych_krall1")
            set_entvar(this, var_body , setlv)
        }
        case CS_TEAM_CT:{
            setlv = min(setlv, 14)
            setlv = max(setlv, 1)
            setlv += 14
            min(setlv, 19)
            rg_set_user_model(this, "rainych_krall1")
            set_entvar(this, var_body , setlv)
        }
    }
}

public SetOtherModule(this , divlv){
    if(divlv == 15){
        rg_set_user_model(this, "rainych_krall1")
        UTIL_EmitSound_ByCmd2(this, BgmStart[Lv_CrossFire], 300.0 )
    }
}

public CreateMoudleMenu(id){
    new menu = menu_create("更改模型", "moduleHandle")
    new player_lv = GetLv(id)
    for(new i = 0 ; i < sizeof modelNames;i++){
        new buff[50],info[10]
        new module_lv = i * 50
        if(player_lv < module_lv){
            format(buff, charsmax(buff), "\d%s\r(%d级)", modelNames[i], module_lv)
        }else{
            format(buff, charsmax(buff), "\y%s\r(%d级)", modelNames[i], module_lv)
        }
        
        num_to_str(i,info,9)
        menu_additem(menu, buff,info)
    }
    menu_display(id,menu)
}

public moduleHandle(id, menu, item){
    if(item == MENU_EXIT || !is_user_alive(id)){
        menu_destroy(menu)
        return
    }
    new acc,info[10],name[50]
    menu_item_getinfo(menu, item, acc, info, 9, name, 49)
    new infonum = str_to_num(info)
    SelMenuByid(id, infonum)
    menu_destroy(menu)
}

public SelMenuByid(id, selid){
    new lv = GetLv(id)
    new setlv = lv / 50
    if(selid > setlv){
        m_print_color(id, "!g[冰布提示]!y您的等级不足以切换模型")
        return
    }
    rg_set_user_model(id, "rainych_krall1")
    set_entvar(id, var_body , selid + 1)
    new username[32]
    get_user_name(id,username,31)
    m_print_color(0, "!g[冰布提示]!y%s更换了模型 !y(你可以输入指令/changemodle来打开菜单)",username)
}
