#include <amxmodx>
#include <reapi>
#include <props>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <regex>
#include <kr_core>
#include <xp_module>
#include <CrashWeapon>
#include <roundrule>
#include <VipManager>

enum EventInfo {
    _:EventName[32],          // 事件名称（调试用）
    Float:EventProbability, // 独立触发概率
    _:EventPriority,          // 事件优先级（数值越大优先级越高）
    _:EventHandler[32]   // 事件处理函数
}

new Events[][EventInfo] ={
    {"武器",        0.005,  5,      "RandWeapons"},
    {"杂志",        0.10,  3,      "RandSexMagazine"},
    {"武功",        0.05,  2,      "RandKongFu"},
    {"金钱",        0.05,  1,      "RandMoney"},
    {"屎",          0.30, 5,      "RandShit"},
    {"手雷",        0.15, 4,      "RandGrenade"},
    {"武器补给",     0.10, 4,      "RandAmmo"},
    {"长跳包",       0.08, 4,      "RandLongJump"},
    {"护甲",        0.10, 4,      "RandKevlar"},
    {"水旋涡",        0.10, 5,      "RandWater"},
}

#define CrashSound "misc/alsy_getmoney.wav"
#define ShitSound  "CrashGun/Shit.wav"
#define MoneySound  "CrashGun/zq_money.wav"
#define SexSound  "CrashGun/zq_sqzz.wav"
#define KongFuSound  "CrashGun/zq_wgmj.wav"

new blastspr

new Has_KongFu[33],Float:KongFu_AttackMul[33]

new const Float:BookAttack[] = 
{
    0.01,0.02,0.03,0.1
}

new const MoneyNums[] = 
{
    10000,40000,90000,200000
}

new Array:GunNames,Array:GunCallBack,Array:GunWModule,Array:GunPlid

#define W_Shit "models/Bing_Kr_res/kr_CrashGun/shit_2.mdl"
#define W_KongFuBook "models/Bing_Kr_res/kr_CrashGun/books_2.mdl"
#define W_Sex "models/Bing_Kr_res/kr_CrashGun/avs.mdl"
#define W_Money "models/Bing_Kr_res/kr_CrashGun/money.mdl"
#define W_HeGrende "models/w_hegrenade.mdl"
#define W_kevlar "models/w_kevlar.mdl"
#define W_WeaponBox "models/w_weaponbox.mdl"
#define W_LongJump "models/w_longjump.mdl"
#define W_Water "models/ef_m3dragonm_sign.mdl"

new CrashModels[][]={
    W_Shit,
    W_KongFuBook,
    W_Sex,
    W_Money,
    W_kevlar,
    W_HeGrende,
    W_WeaponBox,
    W_LongJump,
    W_Water
}

new Float:Weapon_EventProbability

public plugin_init(){
    register_plugin("砸枪", "1.0", "Bing")

    RegisterHam(Ham_Touch, "weaponbox", "Touch_waepon")
    RegisterHam(Ham_TakeDamage, "player", "TakeDamge_Pre")
    RegisterHam(Ham_TakeDamage, "hostage_entity", "TakeDamge_Pre")

    bind_pcvar_float(register_cvar("CrashWaepon_EventProbability","0.08" , FCVAR_SERVER), Weapon_EventProbability)

    register_concmd("KR_CrashWaepon_EventProbability", "ChangWaeponProbility")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
}

public ChangWaeponProbility(){
    new argc = read_argc()
    if(argc == 2){
        new buff [7]
        new Float:newEventProbability
        read_args(buff , 6)
        newEventProbability = str_to_float(buff)
        Events[0][EventProbability] = newEventProbability
    }  
}

public ChangWaeponProbility2(Float:New){
    Events[0][EventProbability] = New
}

public SetWaeponProbility(Float:New){
    Events[0][EventProbability] = New
}

public ResetWaeponProbility(){
    Events[0][EventProbability] = Weapon_EventProbability
}

public TakeDamge_Pre(this, idinflictor, idattacker, Float:damage, damagebits){
    if(is_user_alive(idattacker) && Has_KongFu[idattacker] && this != idattacker){
        SetHamParamFloat(4 , damage + damage * KongFu_AttackMul[idattacker])
    }
    return HAM_IGNORED
}

public event_roundstart(){
    new ent = NULLENT
    while((ent = find_ent_by_class(ent,"mbox")) > 0){
        rg_remove_entity(ent)
    }
    arrayset(Has_KongFu,0,sizeof Has_KongFu)
    arrayset(KongFu_AttackMul,0.0,sizeof KongFu_AttackMul)
    new Human_Rules:Rule  = GetHunManRule()
    ChangWaeponProbility2(Weapon_EventProbability)
    if(Rule == HUMAN_RULE_Lucky){
        ChangWaeponProbility2(0.2)
    }
}

public plugin_precache(){
    UTIL_Precache_Sound(CrashSound)
    UTIL_Precache_Sound(ShitSound)
    UTIL_Precache_Sound(MoneySound)
    UTIL_Precache_Sound(KongFuSound)
    UTIL_Precache_Sound(SexSound)
    blastspr = precache_model("sprites/steam1.spr")

    for(new i = 0 ; i < sizeof CrashModels ; i++){
        precache_model(CrashModels[i])
    }
}

public plugin_natives(){
    register_native("BulidCrashGunWeapon","native_BulidCrashGunWeapon")
    register_native("GiveWeaponByNames","native_GiveWeaponByName")
    register_native("RandGiveWeapon","native_RandGiveWeapon")
}

public Touch_waepon(this, other){
    new classname[32]
    // new classname2[32]
    new Float:Org[3]
    get_entvar(other , var_classname, classname , charsmax(classname))
    // get_entvar(other , var_classname, classname2)
    //判断前两个字节快速筛选
    if(classname[0] == 'w' && classname[1] == 'e' && equal(classname , "weaponbox")){
        new id = get_entvar(this , var_owner)
        new flags = get_entvar(this, var_flags) & FL_ONGROUND
        new flags2 = get_entvar(other,var_flags) & FL_ONGROUND
        new bool:cantouch = (flags && flags2)
        if(!CheckWeaponBoxCanCrush(this) || !cantouch)
            return HAM_IGNORED
        remove_weaponbox_pakitem(this)
        rg_remove_entity(this)
        get_entvar(this, var_origin, Org)
        UTIL_EmitSound_ByCmd2(id , CrashSound, 300.0)
        create_effect(Org)
        CreateItem(id, Org)
    }
    return HAM_IGNORED
}

stock remove_weaponbox_pakitem(boxid){
    for(new i = 0 ; i < 6; i++){
        new Items = get_member(boxid, m_WeaponBox_rgpPlayerItems, i)
        if(Items != -1){
            rg_remove_entity(Items)
        }
    }
}

public CheckWeaponBoxCanCrush(boxid){
    for(new i = 0 ; i < 6; i++){
        new Items = get_member(boxid, m_WeaponBox_rgpPlayerItems, i)
        if(Items != -1){
            new WeaponIdType:wpnid = get_member(Items, m_iId)
            if(wpnid == WEAPON_C4){
                return false
            }
        }
    }
    return true
}


public CreateTouchEnt(onwer,Float:org[3]){
    new ent = rg_create_entity("info_target")
    if(ent == -1)
        return ent
    set_entvar(ent, var_origin, org)
    set_entvar(ent, var_solid, SOLID_TRIGGER)
    set_entvar(ent, var_movetype, MOVETYPE_TOSS)
    set_entvar(ent, var_classname, "mbox")
    entity_set_size(ent, Float:{0.0,0.0,0.0}, Float:{0.0,0.0,0.0})
    return ent
}

stock bool:RandFloatEvents(Float:Probability){
    if(Probability >=1.0)
        return true
    new Float:randnum = random_float(0.0,1.0)
    if(randnum <= Probability)
        return true
    return false
}

// 概率分发器函数（核心！）
stock bool:HandleProbabilityEvent(Float:prob, &Float:accumulator, Float:rand) {
    // 当前事件区间：[accumulator, accumulator+prob)
    if(rand < accumulator + prob) {
        // 命中当前事件区间！
        accumulator += prob;  // 更新累积值（避免浮点误差）
        return true;
    }
    // 未命中，更新累积值继续检测
    accumulator += prob;
    return false;
}

public CreateItem(ownerid , Float:org[3]){
    new ent = CreateTouchEnt(ownerid, org)
    if(ent == -1)
        return
    // new Float:rand = random_float(0.0, 1.0)
    // new Float:accumulator = 0.0;  // 概率累积器
    new Array:eventArray = ArrayCreate()
    new Array:PriSomeEvent = ArrayCreate()
    new bool:istrigger
    //随机触发，如多次触发加入动态列表
    for(new i = 0;i  < sizeof Events;i++){
        if(random_float(0.0, 1.0) <= Events[i][EventProbability]) {
            ArrayPushCell(eventArray , i)
            istrigger = true
        }
    }

    if(!istrigger){
        new name[32]
        get_user_name(ownerid, name, 31)
        m_print_color(0, "!g[砸枪提示]!t苦命的%s什么都没砸出来", name)
        rg_remove_entity(ent)
        return
    }
    //如果触发概率>1个那么取优先级最高的
    new HigeProb = -1 , evnum = ArraySize(eventArray)
    for(new i = 0; i < evnum ; i++){
        new id = ArrayGetCell(eventArray, i) //触发到的事件
        new Pri = Events[id][EventPriority]
        if(Pri > HigeProb){
            HigeProb = Pri
        }
    }

    //如果有相同数据
    for(new i = 0; i < evnum ; i++){
        new id = ArrayGetCell(eventArray, i)
        new Pri = Events[id][EventPriority]
        if(Pri == HigeProb){
            ArrayPushCell(PriSomeEvent , id)
        }
    }

    evnum = ArraySize(PriSomeEvent)
    new funcid
    if(evnum == 1){
        funcid  = get_func_id(Events[ArrayGetCell(PriSomeEvent, 0)][EventHandler])
    }else{
        new TrigerEvent = random_num(0 , evnum - 1)
        funcid  = get_func_id(Events[ArrayGetCell(PriSomeEvent,TrigerEvent)][EventHandler])
    }
    
    callfunc_begin_i(funcid)
    callfunc_push_int(ent)
    callfunc_push_int(ownerid)
    callfunc_end()

    SetTouch(ent, "Touch_Boxs")

    set_prop_float(ent , "picktime", get_gametime() + 2.0)

    ArrayDestroy(PriSomeEvent)
    ArrayDestroy(eventArray)
}

public RandKongFu(boxid , owner){
    new rand = random_num(0,100)
    new body
    new name[32]
    get_user_name(owner, name, 31)
    switch(rand){
        case 0 .. 50:{
            m_print_color(0, "!g[砸枪提示]!t%s砸出一本武林秘籍(攻击力提升1%)", name)
            body = 1
        }
        case 51 .. 81:{
            m_print_color(0, "!g[砸枪提示]!t%s砸出两本武林秘籍(攻击力提升2%)", name)
            body = 2
        }
        case 82 .. 94:{
            m_print_color(0, "!g[砸枪提示]!t%s砸出三本武林秘籍(攻击力提升3%)", name)
            body = 3
        }
        case 95 .. 100:{
            m_print_color(0, "!g[砸枪提示]!t%s砸出神秘黄金武林秘籍(攻击力提升10%)", name)
            body = 4
        }
    }
    engfunc(EngFunc_SetModel, boxid, W_KongFuBook)
    set_prop_string(boxid, "callback", "KongFuTouch_Boxs")
    set_prop_int(boxid, "Bookid" ,body - 1)
    set_entvar(boxid, var_body, body)
    SetTouch(boxid,"Touch_Boxs")
}

public RandMoney(boxid , owner){
    new rand = random_num(0,100)
    new body
    new name[32]
    get_user_name(owner, name, 31)
    switch(rand){
        case 0 .. 50:{
            m_print_color(0, "!g[砸枪提示]!t爱财的%s砸出一枚银元(10000元)", name)
            body = 1
        }
        case 51 .. 81:{
            m_print_color(0, "!g[砸枪提示]!t爱财的%s砸出一枚金元宝(40000元)", name)
            body = 2
        }
        case 82 .. 94:{
            m_print_color(0, "!g[砸枪提示]!t爱财的%s砸出一袋子RMB(90000元)", name)
            body = 3
        }
        case 95 .. 100:{
            m_print_color(0, "!g[砸枪提示]!t爱财的%s砸出一箱子RMB发财了(200000元)", name)
            body = 4
        }
    }
    engfunc(EngFunc_SetModel, boxid, W_Money)
    set_prop_string(boxid, "callback", "MoneyTouch_Boxs")
    set_prop_int(boxid, "Moneyid" ,body - 1)
    set_entvar(boxid, var_body, body)
    SetTouch(boxid,"Touch_Boxs")
}

public RandSexMagazine(boxid , owner){
    new rand = random_num(0, 10)
    new body
    new name[32]
    get_user_name(owner, name, 31)
    switch(rand)
    {
        case 0 .. 5:{
            m_print_color(0, "!g[砸枪提示]!t好色的%s砸出来一本■■杂志(看完回复5Hp)", name)
            body = random_num(1 , 10)
            rand = 0
        }
        case 6 ..7:{
            m_print_color(0, "!g[砸枪提示]!t好色的%s砸出来两本本■■杂志(看完回复10Hp)", name)
            body = random_num(11 , 20)
            rand = 1
        }
        case 8 .. 10:{
            m_print_color(0, "!g[砸枪提示]!t无敌好色的%s砸出来三本■■杂志(看完回复18Hp)", name)
            body = random_num(21 , 30)
            rand = 2
        }
    }
    engfunc(EngFunc_SetModel, boxid, W_Sex)
    set_prop_string(boxid, "callback", "SexTouch_Boxs")
    set_prop_int(boxid, "Sexid" ,rand)
    set_entvar(boxid, var_body, body)
    SetTouch(boxid,"Touch_Boxs")
}

public RandWeapons(boxid , owner){
    new weaponnums = ArraySize(GunNames)
    if(!weaponnums)
        return
    new rand = random_num(0 , weaponnums - 1)
    new gunname[32],WolrdName[256],CallBack[32],name[32]
    ArrayGetString(GunNames,rand,gunname,charsmax(gunname))
    ArrayGetString(GunWModule,rand,WolrdName,charsmax(WolrdName))
    ArrayGetString(GunCallBack,rand,CallBack,charsmax(CallBack))
    new plid = ArrayGetCell(GunPlid,rand)
    if(equal(gunname,"暗影狙击")){
        RandWeapons(boxid, owner)
        return
    }
    set_prop_string(boxid, "callback", "WpnTouch_Boxs")
    set_prop_string(boxid, "wpncallback",CallBack)
    set_prop_int(boxid, "plid",plid)
    get_user_name(owner,name,31)
    m_print_color(0,"!g[砸枪提示]!t好命的%s砸出了一把武器名为(%s)", name, gunname)
    engfunc(EngFunc_SetModel, boxid, WolrdName)
    SetTouch(boxid,"Touch_Boxs")
}

public RandShit(boxid , owner){
    new name[MAX_NAME_LENGTH]
    new bool:is_gold = RandFloatEvents(0.02)//20%金石
    set_prop_string(boxid, "callback", "ShitTouch_Boxs")

    get_user_name(owner,name,charsmax(name))
    if(is_gold == false){
        if(IsPlayerVip(owner)){
            rg_remove_entity(boxid)
            m_print_color(0,"!g[砸枪提示]!t悲催的的%s砸出了一坨屎,但VIP使用钞能力让扫地大妈清理掉了。", name)
            return
        }
        m_print_color(0,"!g[砸枪提示]!t悲催的的%s砸出了一坨屎", name)
    }else{
        m_print_color(0,"!g[砸枪提示]!t八方来财的%s砸出了一坨24K金屎,痛并快乐。(10w金钱)", name)
    }
    engfunc(EngFunc_SetModel, boxid, W_Shit)
    set_entvar(boxid, var_body, is_gold)
    set_prop_int(boxid, "shitid" ,is_gold)
    SetTouch(boxid,"Touch_Boxs")
}

public RandGrenade(boxid , owner){
    new name[32]
    get_user_name(owner, name, 31)
    engfunc(EngFunc_SetModel, boxid, W_HeGrende)
    set_prop_string(boxid, "callback", "HeGrende_Touch")
    m_print_color(0,"!g[砸枪提示]!t%s砸出了一颗手雷", name)
}

public RandAmmo(boxid , owner){
    new name[32]
    get_user_name(owner, name, 31)
    engfunc(EngFunc_SetModel, boxid, W_WeaponBox)
    set_prop_string(boxid, "callback", "Ammo_Touch")
    m_print_color(0,"!g[砸枪提示]!t%s砸出了武器补给", name)
}

public RandLongJump(boxid , owner){
    new name[32]
    get_user_name(owner, name, 31)
    engfunc(EngFunc_SetModel, boxid, W_LongJump)
    set_prop_string(boxid, "callback", "LongJump_Touch")
    m_print_color(0,"!g[砸枪提示]!t%s砸出了长跳包", name)
}

public RandKevlar(boxid , owner){
    new name[32]
    get_user_name(owner, name, 31)
    engfunc(EngFunc_SetModel, boxid, W_kevlar)
    set_prop_string(boxid, "callback", "Kevlar_Touch")
    m_print_color(0,"!g[砸枪提示]!t%s砸出了护甲补给", name)
}

public RandWater(boxid, owner){
    new name[32]
    get_user_name(owner, name, 31)
    engfunc(EngFunc_SetModel, boxid, W_Water)
    m_print_color(0,"!g[砸枪提示]!t哦不！！%s砸出了水旋涡快跑！！", name)
    SetThink(boxid , "Water_Think")
    set_entvar(boxid , var_nextthink , get_gametime() + 0.1)
    set_entvar(boxid , var_fuser1 , get_gametime() + 3.0)
}

public create_effect(Float:_origin[3]){
	new origin[3]
	FVecIVec(_origin, origin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin)
	write_byte(TE_EXPLOSION)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_short(blastspr)
	write_byte(30)
	write_byte(24)
	write_byte(0)
	message_end()
	return 0
}

public Touch_Boxs(this, other){
    new funcname[32]
    if(!prop_exists(this, "callback"))
        return
    if(bool:ExecuteHamB(Ham_IsPlayer, other) == false)
        return
    if(cs_get_user_team(other) != CS_TEAM_T || !is_user_connected(other))
        return
    get_prop_string(this, "callback",funcname,31)
    new funcid = get_func_id(funcname)
    callfunc_begin_i(funcid)
    callfunc_push_int(this)
    callfunc_push_int(other)
    callfunc_end()
    return
}

public WpnTouch_Boxs(this, other){
    new callback[32]
    get_prop_string(this,"wpncallback",callback,31)
    new plid = get_prop_int(this,"plid")
    new funcid = get_func_id(callback, plid)
    if(!CheckCanPick(this))
        return
    new pItem = get_member( other, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT );
    if(!is_nullent(pItem)){
        return
    }
    callfunc_begin_i(funcid,plid)
    callfunc_push_int(other) // 玩家
    callfunc_end()
    rg_remove_entity(this)
}

public ShitTouch_Boxs(this, other){
    if(!CheckCanPick(this))
        return
    new shitid = get_prop_int(this, "shitid")
    if(shitid == 0){
        ExecuteHam(Ham_TakeDamage , other , 0 , 0 , 10.0 , DMG_CRUSH)
    }else{
        new money = cs_get_user_money(other) + 100000
        ExecuteHam(Ham_TakeDamage , other , 0 , 0 , 10.0 , DMG_CRUSH)
        cs_set_user_money(other, money)
    }

    UTIL_EmitSound_ByCmd(other, ShitSound)
    rg_remove_entity(this)
}

public HeGrende_Touch(this , other){
    if(!CheckCanPick(this))
        return
    new hegrenade_num = get_member(other , m_rgAmmo , 12)
    if(hegrenade_num == 0){
        rg_give_item(other, "weapon_hegrenade")
    }else{
        set_member(other ,m_rgAmmo , hegrenade_num + 1 , 12)
    }
    rg_remove_entity(this)
}

public LongJump_Touch(this , other){
    if(!CheckCanPick(this))
        return
    // set_member(other , m_fLongJump , 1)
    new LongJump = rg_create_entity("item_longjump")
    if(is_nullent(LongJump)){
        rg_remove_entity(this)
        return
    }
    new Float:Origin[3]
    get_entvar(this , var_origin , Origin)
    set_entvar(LongJump , var_origin , Origin)
    ExecuteHam(Ham_Spawn , LongJump)
    rg_remove_entity(this)
}

public Kevlar_Touch(this , other){
    if(!CheckCanPick(this))
        return
    rg_set_user_armor(other , 100 , ARMOR_KEVLAR)
    rg_remove_entity(this)
}

public Ammo_Touch(this , other){
    if(!CheckCanPick(this))
        return
    new wpn = get_member(other, m_pActiveItem)
    if(wpn <= 0)
        return
    new MaxAmmo = rg_get_iteminfo(wpn , ItemInfo_iMaxAmmo1)
    new WeaponIdType:wpnid = WeaponIdType:rg_get_iteminfo(wpn, ItemInfo_iId)
    if(wpnid == WEAPON_KNIFE || wpnid == WEAPON_HEGRENADE ||
        wpnid == WEAPON_FLASHBANG || wpnid == WEAPON_SMOKEGRENADE){
        m_print_color(other, "!g[冰布提醒]!y此武器无法拾取次弹药。")
        return;
    }
    MaxAmmo /= 2
    new orbpammo = rg_get_user_bpammo(other,wpnid)
    rg_set_user_bpammo(other,wpnid, orbpammo + MaxAmmo)
    rg_remove_entity(this)
}

public SexTouch_Boxs(this,other){
    if(!CheckCanPick(this))
        return
    new sexid = get_prop_int(this, "Sexid")
    new Float:c_heal
    if(sexid == 0){
        c_heal = get_entvar(other, var_health)
        set_entvar(other,var_health, c_heal + 5.0)
    }else if(sexid == 1){
        c_heal = get_entvar(other, var_health)
        set_entvar(other,var_health, c_heal + 10.0)
    }else{
        c_heal = get_entvar(other, var_health)
        set_entvar(other,var_health, c_heal + 18.0)
    }
    rg_remove_entity(this)
    UTIL_EmitSound_ByCmd(other, SexSound)
}

public KongFuTouch_Boxs(this,other){
    new Float:picktime = get_prop_float(this, "picktime")
    if(get_gametime() < picktime)
        return
    new bookid = get_prop_int(this, "Bookid")
    Has_KongFu[other] = true
    if(BookAttack[bookid] > KongFu_AttackMul[other]){
        KongFu_AttackMul[other] = BookAttack[bookid]
    }
    rg_remove_entity(this)
    UTIL_EmitSound_ByCmd(other, KongFuSound)
}

public MoneyTouch_Boxs(this,other){
    new Float:picktime = get_prop_float(this, "picktime")
    if(get_gametime() < picktime)
        return
    new Moneyid = get_prop_int(this, "Moneyid")
    new C_Money = cs_get_user_money(other)
    cs_set_user_money(other, C_Money + MoneyNums[Moneyid])
    rg_remove_entity(this)
    UTIL_EmitSound_ByCmd(other, MoneySound)
}

public Water_Think(ent){
    new Float:Origin[3]
    get_entvar(ent , var_origin , Origin)
    rg_dmg_radius(Origin ,ent ,ent , 15.0 , 100.0 , CLASS_NONE , DMG_FREEZE)
    if(get_gametime() > get_entvar(ent , var_fuser1)){
        rg_remove_entity(ent)
        return
    }
    set_entvar(ent ,var_nextthink , get_gametime() + 0.9)
}

//(GunName[],WorldModel[],GiveFunc[],Plid)
public native_BulidCrashGunWeapon(id,nums){
    if(!GunNames){
        GunNames = ArrayCreate(64)
        GunCallBack = ArrayCreate(64)
        GunWModule = ArrayCreate(256)
        GunPlid = ArrayCreate()
    }
    new GunName[32],GiveFunc[32],WorldModel[256],Plid
    get_string(1,GunName,31)
    get_string(2,WorldModel,255)
    get_string(3,GiveFunc,31)
    Plid = get_param(4)
    ArrayPushString(GunNames,GunName)
    ArrayPushString(GunCallBack, GiveFunc)
    ArrayPushString(GunWModule, WorldModel)
    ArrayPushCell(GunPlid,Plid)
}

public native_GiveWeaponByName(id,nums){
    new GunName[32],ArrayGun[32]
    get_string(1,GunName,31)
    new playerid = get_param(2)
    new nums = ArraySize(GunNames)
    for(new i = 0 ; i < nums;i++){
        ArrayGetString(GunNames,i,ArrayGun,31);
        if(equal(GunName,ArrayGun)){
            new GiveFunc[32],plid
            plid = ArrayGetCell(GunPlid,i)
            ArrayGetString(GunCallBack,i,GiveFunc,31)
            new funcid = get_func_id(GiveFunc,plid)
            callfunc_begin_i(funcid,plid)
            callfunc_push_int(playerid) // 玩家
            callfunc_end()
        }
    }
}

public native_RandGiveWeapon(id , nums){
    new playerid = get_param(1)
    new giveid = random_num(0, ArraySize(GunNames) - 1)
    new GiveFunc[32],plid
    ArrayGetString(GunCallBack,giveid,GiveFunc,31)
    plid = ArrayGetCell(GunPlid,giveid)
    new funcid = get_func_id(GiveFunc,plid)
    callfunc_begin_i(funcid,plid)
    callfunc_push_int(playerid) // 玩家
    callfunc_end()
}

public plugin_end(){
    ArrayDestroy(GunNames)
    ArrayDestroy(GunCallBack)
    ArrayDestroy(GunWModule)
    ArrayDestroy(GunPlid)
}

stock CheckCanPick(boxid){
    new Float:picktime = get_prop_float(boxid, "picktime")
    if(get_gametime() < picktime)
        return false
    return true
}
