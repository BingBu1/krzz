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
    "models/player/gordon/gordon.mdl",
    "models/player/Miku/Miku.mdl",
    "sprites/wrbot/cn.spr"
}

new PrePlayerModel [][] = {
    "ramenchan_",
    "lemonfeijibei",
    "bing_sidalin"
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
    { 800, "灵狐者"  ,"linghu_yellow" },//15
    { 950, "普京"    ,"pujing"      },//16
    { 1100, "kobe牢大","kobelaoda"      },//17
    { 1250, "金正恩"   ,"jinzhengen"     },//18
    { 1400, "斯大林"   ,"bing_sidalin"     },//18
    { 1700 , "戈登弗里曼" , "gordon"},
    {   0, "猫姬-管理模型" , "NecoArc" ,2},
    {   0, "红豆(Vip)" , "hongdou" ,1},
    {   800, "初音未来(Vip)" , "Miku" ,1},
};

//设置模型开场音乐
new ModelSounds[][ModelSoundData]={
    {"linghu_yellow", "corssfire_bgm/N_Lv_CrossFire.wav"},
    {"jinzhengen", "kr_sound/jinzhengen.wav"}, // 假设的音乐路径
    {"NecoArc", "kr_sound/necoact-start.wav"},
    {"kobelaoda", "kr_sound/LaoDa_Start.wav"},
}

new hero[33] , Float:ChangeModelsCd[33]
new Jp_PlayerModule[]= "models/player/rainych_krall1/rainych_krall1.mdl"
new LastUseModel[MAX_PLAYERS +1 ][LastUseModelData]
new VipModelSize
new ChangeModel_Hanle
new Handle:g_SqlTuple
new Trie:g_PlayerModelMap

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

    ChangeModel_Hanle = CreateMultiForward("OnModelChange" , ET_STOP , FP_CELL ,FP_STRING)

    GetVipModelSize()

    g_PlayerModelMap = TrieCreate()
}

public SqlInitOk(Handle:sqlHandle , Handle:ConnectHandle){
    g_SqlTuple = sqlHandle
    QueryPlayerModel()
    server_print("定制玩家sql回调完成")
}

public QueryPlayerModel(){
    new querystr[] = "SELECT * FROM PlayerModel"
    SQL_ThreadQuery(g_SqlTuple, "QueryPlayerModelHandle", querystr)
}

public QueryPlayerModelHandle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize , Float:QueryTime){
    if(FailState != TQUERY_SUCCESS){
        log_amx("查询失败 [%d] %s", Errcode, Error)
        return
    }
    if(!SQL_NumResults(Query)){
        return
    }
    new steamid[64] , modelname[33]
    while (SQL_MoreResults(Query)){
        new q_steamid = SQL_FieldNameToNum(Query , "steamid")
        new q_modelname = SQL_FieldNameToNum(Query , "modelname")
        SQL_ReadResult(Query , q_steamid , steamid , charsmax(steamid))
        SQL_ReadResult(Query , q_modelname , modelname , charsmax(modelname))
        TrieSetString(g_PlayerModelMap , steamid , modelname)
        server_print("steamid %s modelname %s" , steamid , modelname)
        SQL_NextRow(Query)
	}
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

public plugin_precache(){
    precache_model(Jp_PlayerModule)
    for(new i = 0 ; i < sizeof PreModules ; i++){
        precache_model(PreModules[i])
    }   
    for(new i = 0 ; i < sizeof PrePlayerModel ; i++){
        UTIL_ChaChePlayerModel(PrePlayerModel[i])
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
        ExecuteForward(ChangeModel_Hanle , _ , this , "linghu_red")
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
    ExecuteForward(ChangeModel_Hanle , _ , id , "linghu_red")
    set_task(0.5,"GiveHeroWeapon",id)
}

public GiveHeroWeapon(id){
    if(!is_user_connected(id) || !is_user_alive(id))
        return
    new Rand = random_num(0,1)
    server_cmd("give_kata %d" , id)
    if(!Rand){
        GiveWeaponByNames("暗影狙击", id)
    }else {
        server_cmd("giveherogun %d" , id)
    }
    
    set_entvar(id, var_health, 500.0) // 500血
    UTIL_EmitSound_ByCmd2(id, BgmStart[Hero_CrossFire], 300.0 )
}

public DropItems(const this, const pszItemName[]){
    if(!is_user_connected(this) || hero[this] || GetMenuIsDisable(this))
        return
    new body = get_entvar(this, var_body)
    new modelName[32]
    get_user_info(this, "model", modelName, charsmax(modelName))
    if(body == 0 && !strcmp(modelName , "rainych_krall1")){
        new setbody = GetLv(this) / 50 + 1
        set_entvar(this, var_body , setbody)
    }
}

public fw_Item_AddToPlayer_Post(iWpn, id){
    set_member(id , m_bHasC4 , 0) //防止压缩器闪退
    if(hero[id])
        return HAM_IGNORED
    if(get_entvar(id ,var_body) == 1){
        SetModuleByLv(id , false)
    }
    return HAM_IGNORED
}

public SetModuleByLv(this , bool:playsound){
    client_cmd(this , "cl_minmodels 0") //强制关闭统一模型
    new lv = GetLv(this)
    new setlv = GetModelIndexByLv(lv)
    new team = get_user_team(this)
    new const maxDiv = sizeof g_ModelData
    switch(team){
        case CS_TEAM_T:{
            if(setlv <= 14){
                rg_set_user_model(this, "rainych_krall1")
                set_entvar(this, var_body , setlv)
                ExecuteForward(ChangeModel_Hanle , _ , this ,"rainych_krall1")
                return
            }
            if(LastUseModel[this][Use_ed]){
                rg_set_user_model(this , LastUseModel[this][Use_Model])
                if(playsound){
                    PlayBgm(this)
                }
                ExecuteForward(ChangeModel_Hanle , _ , this ,LastUseModel[this][Use_Model])
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
            ExecuteForward(ChangeModel_Hanle , _ , this ,"rainych_krall1")
            set_entvar(this, var_body , setlv)
        }
    }
}

// 根据当前等级返回最合适的模型索引（g_ModelData 下标 +1）
public GetModelIndexByLv(lv)
{
    new bestIndex = 0
    for (new i = 0; i < sizeof g_ModelData; i++)
    {
        if (lv >= g_ModelData[i][Lv])
            bestIndex = i
        else
            break
    }
    return bestIndex + 1 // +1 因为 SetOtherModule 期望的是 1-based
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
    if(access(this , ADMIN_RCON)){
        lv += 10000
    }
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
    ExecuteForward(ChangeModel_Hanle , _ , this ,SetName)
    return true
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
    if(access(id , ADMIN_RCON)){
        lv += 10000
    }
    if(modelLv > lv){
        m_print_color(id, "!g[冰布提示]!y您的等级不足以切换模型")
        return
    }
    if(get_gametime() < ChangeModelsCd[id]){
        m_print_color(id, "!g[冰布提示]!t切换角色还在冷却中剩余%.0f秒" , ChangeModelsCd[id] - get_gametime())
        return
    }
    if(selid <= MAX_STANDARD_MODEL_ID){
        rg_set_user_model(id, "rainych_krall1")
        set_entvar(id, var_body , selid + 1)
        ExecuteForward(ChangeModel_Hanle , _ , id , "rainych_krall1")
        ChangeModelsCd[id] = get_gametime() + 30.0
    }else{
        if(!SetOtherModule(id , selid + 1 , true)){
            return
        }
        get_user_info(id, "model", LastUseModel[id][Use_Model], 31)
        LastUseModel[id][Use_ed] = true
        ChangeModelsCd[id] = get_gametime() + 30.0
    }
    new username[32]
    get_user_name(id,username,31)
    m_print_color(0, "!g[冰布提示]!y%s更换了模型 !y(你可以输入指令/changemodle来打开菜单)",username)
}

public OnModelChange(id , name[]){
    new steamid[32]
    get_user_authid(id , steamid , charsmax(steamid))
    if(TrieKeyExists(g_PlayerModelMap , steamid)){
        new modelname[32]
        TrieGetString(g_PlayerModelMap , steamid , modelname , charsmax(modelname))
        rg_set_user_model(id , modelname)
    }
}

stock UTIL_ChaChePlayerModel(name[]){
    new ModelPath[256]
    formatex(ModelPath , 255 , "models/player/%s/%s.mdl" , name , name)
    precache_model(ModelPath)
}