#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <reapi>
#include <kr_core>
#include <xp_module>

enum LastUseModelData{
    bool:Use_ed,
    _:Use_Model[32]
}

enum ModelSoundData{
    _:ModelName_Sound[32],
    _:SoundName_Sound[64]
}

enum StartBgm{
    Hero_CrossFire,
    Lv_CrossFire,
    Vip_CrossFire,
    LV_JINZHENGEN,
    neco_Sel
}

enum ModelLvNames{
    _:Lv,
    _:ModelNames[32],
    _:SetModelName[32],
    _:IsVip
}

new BgmStart[StartBgm][]= {
    "corssfire_bgm/N_Hero_CrossFire.wav",
    "corssfire_bgm/N_Lv_CrossFire.wav",
    "corssfire_bgm/N_Vip_CrossFire.wav",
    "kr_sound/jinzhengen.wav",
    "kr_sound/necoact-start.wav",
}

new PreModules [][]= {
    "models/player/linghu_red/linghu_red.mdl",
    "models/player/linghu_yellow/linghu_yellow.mdl",
    "models/player/FOX_BL/FOX_BL.mdl",
    "models/player/pujing/pujing.mdl",
    "models/player/jinzhengen/jinzhengen.mdl",
    "models/player/NecoArc/NecoArc.mdl",
    "models/player/kobelaoda/kobelaoda.mdl",
    "models/player/hongdou/hongdou.mdl",
    "sprites/wrbot/cn.spr"
}

new g_ModelData[][ModelLvNames] = {
    {   0, "小八路"        },//1
    {  50, "老八路"        },//2
    { 100, "士兵"          },//3
    { 150, "男军官"        },//4
    { 200, "女军官"        },//5
    { 250, "黄皮八路"      }, // 6
    { 300, "黄皮男军官"    }, //7
    { 350, "黄皮女军官"    }, //8
    { 400, "特警"          }, //9
    { 450, "黑皮男军官"    }, //10
    { 500, "黑皮女军官"    }, //11
    { 550, "海军"          }, //12
    { 600, "老蒋"          }, //13
    { 650, "毛爷爷"        },//14
    { 700, "灵狐者"  ,"linghu_yellow" },//15
    { 750, "普京"    ,"pujing"      },//16
    { 850, "kobe牢大","kobelaoda"      },//17
    {1000, "金正恩"   ,"jinzhengen"     },//18
    {   0, "猫姬-管理模型" , "NecoArc" ,2},//19
    {   0, "红豆(Vip或管理)" , "hongdou" ,1},//20
};

//设置模型开场音乐
new ModelSounds[][ModelSoundData]={
    {"linghu_yellow", "corssfire_bgm/N_Lv_CrossFire.wav"},
    {"jinzhengen", "kr_sound/jinzhengen.wav"}, // 假设的音乐路径
    {"NecoArc", "kr_sound/necoact-start.wav"},
    {"kobelaoda", "kr_sound/LaoDa_Start.wav"},
}

new hero[33]
new Jp_PlayerModule[]= "models/player/rainych_krall1/rainych_krall1.mdl"
new LastUseModel[MAX_PLAYERS +1 ][LastUseModelData]
new VipModelSize
public plugin_init(){
    register_plugin("设置玩家模型", "1.0", "Bing")
    RegisterHookChain(RG_CBasePlayer_Spawn,"PlayerSpawn_Post",true)
    RegisterHookChain(RG_CBasePlayer_RoundRespawn,"PlayerSpawn_Post",true)
    RegisterHookChain(RG_CBasePlayer_DropPlayerItem,"DropItems",true)
    RegisterHookChain(RG_CBasePlayer_MakeBomber,"MakeBoom",true)

    RegisterHam(Ham_Item_AddToPlayer, "weapon_c4", "fw_Item_AddToPlayer_Post", 1)

    register_forward(FM_AddToFullPack , "Fw_AddToFullPack_Post" , 1)

    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")

    register_clcmd("say /changemodle" , "CreateMoudleMenu")

    GetVipModelSize()
}

public GetVipModelSize(){
    for(new i = 0 ; i < sizeof g_ModelData; i++){
        if(g_ModelData[i][IsVip] > 0)
            VipModelSize++
    }
}

public client_putinserver(id){
    LastUseModel[id][Use_ed] = false
}

public client_disconnected(id){
    LastUseModel[id][Use_ed] = false
}

public Fw_AddToFullPack_Post(const es, e, ent, HOST, hostflags, player, set){
    if(player)
        return FMRES_IGNORED
    if(FClassnameIs(ent , "HeroSpr")){
        new Float:PlayerOrigin[3]
        new master = get_entvar(ent ,var_owner)
        if( !is_user_connected(master) || cs_get_user_team(master) == CS_TEAM_CT){
            rg_remove_entity(ent)
            hero[master] = false
            return FMRES_IGNORED
        }
        if(!is_user_alive(master)){
            set_es(es , ES_Effects , EF_NODRAW)
            return FMRES_IGNORED
        }
        get_entvar(master , var_origin , PlayerOrigin)
        PlayerOrigin[2] += 72.0
        engfunc(EngFunc_SetOrigin, ent, PlayerOrigin)
        set_es( es, ES_MoveType, MOVETYPE_FOLLOW )
        set_es( es, ES_RenderMode, kRenderNormal)
        set_es( es, ES_RenderAmt, 220)
        set_es( es, ES_Origin, PlayerOrigin);
    }
    return FMRES_IGNORED
}

public fw_Item_AddToPlayer_Post(iWpn, id){
    set_member(id , m_bHasC4 , 0) //防止压缩器闪退
    if(get_entvar(id ,var_body) == 1 && !hero[id]){
        SetModuleByLv(id , false)
    }
}

public plugin_precache(){
    precache_model(Jp_PlayerModule)
    for(new i = 0 ; i < sizeof PreModules ; i++){
        precache_model(PreModules[i])
    }   
    for(new i = 0 ; i < sizeof BgmStart ; i++){
        UTIL_Precache_Sound(BgmStart[StartBgm:i])
    }   
    for(new i = 0 ; i < sizeof ModelSounds ; i++){
        UTIL_Precache_Sound(ModelSounds[i][SoundName_Sound])
    }   
}

public plugin_natives(){
    register_native("Make_Hero", "native_MakeHero")
}

public event_roundstart(){
    arrayset(hero , 0 , sizeof(hero))
    remove_entity_name("HeroSpr")
}

public PlayerSpawn_Post(this){
    if(is_nullent(this) || !is_user_alive(this)){
        return HC_CONTINUE
    }
    if(!is_user_bot(this) && !hero[this]){
        SetModuleByLv(this , true)
    }else if(hero[this]){
        rg_set_user_model(this, "linghu_red")
        return HC_CONTINUE
    }
    return HC_CONTINUE
}

public MakeBoom(const this){
    set_member(this , m_bHasC4 , false)
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

public MakeHeroSpr(id){
    new spr = rg_create_entity("env_sprite")
    if(is_nullent(spr) || spr <= 0)
        return -1
    set_entvar(spr , var_classname , "HeroSpr")
    set_entvar(spr, var_renderamt, 255.0)
    set_entvar(spr, var_frame, 0.0)
    set_entvar(spr, var_animtime, get_gametime())
    set_entvar(spr , var_scale , 0.5)
    set_entvar(spr , var_owner , id)
    
    engfunc(EngFunc_SetModel , spr , "sprites/wrbot/cn.spr")
    return spr
}

public MakeHero(const id){
    hero[id] = true
    rg_set_user_model(id, "linghu_red")
    MakeHeroSpr(id)
    set_task(0.5,"GiveHeroWeapon",id)
}

public GiveHeroWeapon(id){
    if(!is_user_connected(id) || !is_user_alive(id))
        return
    new Rand = random_num(0,1)
    if(!Rand){
        GiveWeaponByNames("暗影狙击", id)
    }else {
        server_cmd("giveherogun %d" , id)
    }
    
    set_entvar(id, var_health, 500.0) // 500血
    UTIL_EmitSound_ByCmd2(id, BgmStart[Hero_CrossFire], 300.0 )
}

public DropItems(const this, const pszItemName[]){
    if(!is_user_connected(this))
        return
    new body = get_entvar(this, var_body)
    if(body == 0 && !hero[this]){
        SetModuleByLv(this , false)
    }
}

public SetModuleByLv(this , bool:playsound){
    client_cmd(this , "cl_minmodels 0")
    new lv = GetLv(this)
    new setlv = (lv / 50) + 1
    new team = get_user_team(this)
    new const maxDiv = sizeof g_ModelData
    switch(team){
        case CS_TEAM_T:{
            if(setlv <= 14){
                rg_set_user_model(this, "rainych_krall1")
                set_entvar(this, var_body , setlv)
                return
            }
            if(LastUseModel[this][Use_ed]){
                rg_set_user_model(this , LastUseModel[this][Use_Model])
                if(playsound){
                    PlayBgm(this)
                }
                return
            }
            setlv = min(setlv , maxDiv - VipModelSize)
            SetOtherModule(this , setlv, playsound)
        }
        case CS_TEAM_CT:{
            setlv = clamp(setlv , 1 , 14)
            setlv += 14
            setlv = min(setlv, 19)
            rg_set_user_model(this, "rainych_krall1")
            set_entvar(this, var_body , setlv)
        }
    }
}

public PlayBgm(this){
    new modelName[32]
    get_user_info(this, "model", modelName, charsmax(modelName))
    for(new i = 0 ; i < sizeof ModelSounds ; i++){
        if(!strcmp(ModelSounds[i][ModelName_Sound] , modelName)){
            UTIL_EmitSound_ByCmd2(this, ModelSounds[i][SoundName_Sound], 600.0)
            return
        }
    }
}

public SetOtherModule(this , divlv , bool:PlayerSound){
    new lv = GetLv(this)
    new model_inx = divlv - 1
    new SetName[32]
    new modellv = GetModeleLv(model_inx)

    if(lv < modellv)
        return false
    if(!CanSetThisModel(model_inx , this)){
        m_print_color(this , "你不能使用此模型")
        return false
    }
    GetModeleSetName(model_inx , SetName , charsmax(SetName))
    server_print("Index %d , Name %s" , model_inx , SetName)
    rg_set_user_model(this , SetName)
    if(PlayerSound == true){
        PlayBgm(this)
    } 
    return true
    // if(divlv >= 15){
    //     rg_set_user_model(this, "linghu_yellow")
    // }
    // if(divlv >= 16){
    //     rg_set_user_model(this, "pujing")
    // }
    // if(modellv == 1000 && lv >= 1000){
    //     rg_set_user_model(this, "jinzhengen")
    // }
    // if(modellv == 850 && lv >= 850){
    //     rg_set_user_model(this, "kobelaoda")
    // }
    // if(modellv == 0 && is_user_admin(this)){
    //     rg_set_user_model(this, "NecoArc")
    // }  
}

public bool:CanSetThisModel(index , userid){
    if(g_ModelData[index][IsVip] == 0)
        return true
    new __flags = get_user_flags(userid);
    if(g_ModelData[index][IsVip] == 1){ // vip admin
        if(access(userid , ADMIN_KICK))
            return true
        
        if(__flags & ADMIN_RESERVATION){
            return true
        }
    }else if(g_ModelData[index][IsVip] == 2){
        if(access(userid , ADMIN_KICK))
            return true
    }
    return false
}

public GetModeleLv(modinx){
    if(modinx >= sizeof g_ModelData){
        return g_ModelData[sizeof g_ModelData - 1 ][Lv]
    }
    if(modinx >= 0){
        return g_ModelData[modinx][Lv]
    }
    return 99999
}

public GetModeleSetName(modinx , ModelBuff[] , len){
    if(modinx >= sizeof g_ModelData){
        copy(ModelBuff , len , g_ModelData[sizeof g_ModelData - 1 ][SetModelName])
        return
    }
    if(modinx >= 0){
        copy(ModelBuff , len , g_ModelData[modinx][SetModelName])
        return
    }
    return
}

public CreateMoudleMenu(id){
    if(get_member(id , m_iTeam) == TEAM_CT){
        m_print_color(id , "!g[冰布提示]!y你是汉奸无法更换模型")
        return
    }
    new menu = menu_create("更改模型", "moduleHandle")
    new player_lv = GetLv(id)
    for(new i = 0 ; i < sizeof g_ModelData; i++){
        new buff[50],info[10]
        new module_lv = GetModeleLv(i)
        if(player_lv < module_lv){
            formatex(buff, charsmax(buff), "\d%s\r(%d级)", g_ModelData[i][ModelNames], module_lv)
        }else{
            formatex(buff, charsmax(buff), "\y%s\r(%d级)", g_ModelData[i][ModelNames], module_lv)
        }
        
        num_to_str(i, info , charsmax(info))
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
    new modelLv = GetModeleLv(selid)
    const MAX_STANDARD_MODEL_ID = 13
    if(modelLv > lv){
        m_print_color(id, "!g[冰布提示]!y您的等级不足以切换模型")
        return
    }
    if(selid <= MAX_STANDARD_MODEL_ID){
        rg_set_user_model(id, "rainych_krall1")
        set_entvar(id, var_body , selid + 1)
    }else{
        if(!SetOtherModule(id , selid + 1 , true)){
            return
        }
        get_user_info(id, "model", LastUseModel[id][Use_Model], 31)
        LastUseModel[id][Use_ed] = true
    }
    new username[32]
    get_user_name(id,username,31)
    m_print_color(0, "!g[冰布提示]!y%s更换了模型 !y(你可以输入指令/changemodle来打开菜单)",username)
}