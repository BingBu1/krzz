#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <kr_core>
#include <reapi>
#include <engine>
#include <xp_module>

#define MaxItem 255

new Waeponid
new WeaponName[MaxItem][64]
new Float:WeaponCost[MaxItem]
// new IsReSpawn[33]

new WpnForwad , OnCreateIteam_

new BuyAmmo,GiveHeal,NpcMenu,KillMarkMenu

new menuname[64] , bool:CanUseMenu[33]
public plugin_init(){
    register_plugin("抗日菜单", "1.0", "Bing")

    register_clcmd("say menu", "CreateMenu")
    register_clcmd("chooseteam ", "OpenMenu")
    register_clcmd("say /buy_cn", "CreateWeaponMenu")
    register_clcmd("say /buy_ammo", "Buy_Ammo")

    WpnForwad = CreateMultiForward("ItemSel_Post",ET_STOP,FP_CELL,FP_CELL,FP_FLOAT)
    OnCreateIteam_ = CreateMultiForward("OnCreateIteam",ET_STOP,FP_ARRAY , FP_CELL)
}

public plugin_precache(){
    NpcMenu = BulidWeaponMenu("抗日伙伴", 0.0)
    KillMarkMenu = BulidWeaponMenu("击杀图标", 0.0)
    BuyAmmo = BulidWeaponMenu("购买弹药", 0.04)
    GiveHeal = BulidWeaponMenu("军医治疗", 0.04)
}


public plugin_natives(){
    register_native("BulidWeaponMenu","native_BulidWeaponMenu")
    register_native("ChangeMenuName","native_ChangeMenuName")
    register_native("DisableMenu","native_DisableMenu")
    register_native("EnableMenu","native_EnableMenu")
    // register_native("OnBuySubAmmo","native_OnBuySubAmmo")
}

//const weaponname , cost
public native_BulidWeaponMenu(plid,nums){
    if(Waeponid > MaxItem)
        return 0
    new oldid = Waeponid
    WeaponCost[Waeponid] = get_param_f(2)
    get_string(1, WeaponName[Waeponid], charsmax(WeaponName[]))

    Waeponid++
    return oldid
}

// public native_AmmoCanBuy(plid , nums){
//     new id = get_param(1)
//     new  = get_param_f(2)
//     new WeaponCost = WeaponCost[Waeponid]
//     SubAmmoPak(id , WeaponCost)
// }

public OpenMenu(id){
    CreateMenu(id)
    return PLUGIN_HANDLED
}

public CreateMenu(id){
    new menuid = menu_create("抗日菜单", "menuHandle")
    menu_additem(menuid, "抗日武器", "0")
    menu_additem(menuid, "大洋兑换系统", "1")
    menu_additem(menuid, "重返战场", "2")
    menu_additem(menuid, "更换模型", "3")
    menu_additem(menuid, "购买下局规则", "9")
    menu_additem(menuid, "重新打开选择武器菜单", "8")
    menu_additem(menuid, "下一张地图", "4")
    menu_additem(menuid, "剩余时间", "5")
    menu_additem(menuid, "难度调整", "6")
    menu_additem(menuid, "当前时间", "7")
    menu_additem(menuid, "我卡关了", "10")
    menu_additem(menuid, "老虎机设置", "11")
    menu_additem(menuid, "切换视角", "12")
    menu_additem(menuid, "查询掉难度情况", "13")
    menu_display(id, menuid)
}

public ChangeCamMenu(id){
    if(is_user_alive(id) && is_user_connected(id)){
        new menuid = menu_create("人称切换", "ChangeCamHandle")
        menu_additem(menuid , "第三人称")
        menu_additem(menuid , "第一人称")
        menu_display(id ,menuid)
    }
}

public ChangeCamHandle(id , menu , item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    switch(item){
        case 0 :{
            SetCam(id , CAMERA_3RDPERSON)
        }
        case 1 :{
            SetCam(id , CAMERA_NONE)
        }
    }
}

public CreateWeaponMenu(id){
    if(get_user_team(id) == _:CS_TEAM_CT)
        return;
    if(!CanUseMenu[id]){
        m_print_color(id , "!g[冰布提示]!t你无法使用商店，你可能已成为汉奸或被寄生。")
        return ;
    }
    new wpnmenuid = menu_create("抗日菜单", "WpnMenuHandle")
    new const FormatText[][]={
        "%s (\r价格: %.2f大洋\y)",
        "%s"
    }
    for(new i = 0;i < Waeponid; i++){
        static info[5]
        if(WeaponCost[i] <= 0.0){
            formatex(menuname, charsmax(menuname), FormatText[1] , WeaponName[i])
        }else{
            formatex(menuname, charsmax(menuname), FormatText[0] , WeaponName[i]
            , WeaponCost[i])
        }
        
        num_to_str(i, info , charsmax(info))

        new handle = PrepareArray(menuname,charsmax(menuname) , 1)
        ExecuteForward(OnCreateIteam_ , _ , handle , charsmax(menuname))

        menu_additem(wpnmenuid, menuname,info)
    }
    menu_display(id, wpnmenuid)
}

public native_ChangeMenuName(pluginid , nums){
    get_string(1 , menuname , charsmax(menuname))
}

public native_DisableMenu(pluginid , nums){
    CanUseMenu[get_param(1)] = false
}

public native_EnableMenu(pluginid , nums){
    CanUseMenu[get_param(1)] = true
}

public menuHandle(id,menu,item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    new acc , info[10] , name[32]
    if(!menu_item_getinfo(menu, item, acc, info, charsmax(info), name, charsmax(name))){
        log_amx("获取菜单info失败")
    }
    new infoid = str_to_num(info)
    switch(infoid){
        case 0: CreateWeaponMenu(id)//抗日武器
        case 1: client_cmd(id,"say /ammomenu")//大洋系统
        case 2: ReSpawnPlayer(id)//重返战场
        case 3: if(CanUseMenu[id])client_cmd(id, "say /changemodle")//更改模型
        case 4: client_cmd(id, "say nextmap")//下一张地图
        case 5: client_cmd(id, "say timeleft")//剩余时间
        case 6: client_cmd(id, "say /lv") //难度调整
        case 7: client_cmd(id, "say thetime")//当前时间
        case 8: client_cmd(id, "say givewpn") //武器菜单
        case 9: client_cmd(id, "say /buyrule") //购买下局规则
        case 10: LvCheck(id) //查询是否卡关
        case 11: client_cmd(id, "say /machine") //老虎机
        case 12: ChangeCamMenu(id) //切换视角
        case 13 : client_cmd(id  , "kr_checklv")//查询掉难度
    }
    menu_destroy(menu)
}

public SetWpnMul(id , Float:BuyCost){
    new BuyWpn = get_member(id , m_pActiveItem)
    if(BuyWpn <= 0)
        return
    if(BuyCost >= 18.0){
        SetWpnXpMul(BuyWpn , 2.0)
    }
    if(BuyCost >= 80.0){
        SetWpnXpMul(BuyWpn , 3.0)
    }
    new Float:Mulxp = GetPlayerMul(id)
    m_print_color(id, "!g【冰布提醒】购买武器成功!您当前积分加成%d倍。" , floatround(Mulxp))
}

public WpnMenuHandle(id,menu,item){
    if(item == MENU_EXIT || !is_user_alive(id)){
        menu_destroy(menu)
        return
    }
    new acc , info[10] , name[32]
    if(!menu_item_getinfo(menu, item, acc, info, charsmax(info), name, charsmax(name))){
        log_amx("获取菜单info失败 行数:%d", __LINE__)
    }
    new infoid = str_to_num(info)
    new Float:buycost = WeaponCost[infoid]
    new bool:IsHaveBuyAmmo
#if defined Usedecimal
    IsHaveBuyAmmo = Dec_cmp(id , buycost , ">=")
#else
    new Float:nowammos = GetAmmoPak(id)
    IsHaveBuyAmmo = (nowammos >= buycost)
#endif
    
    if(IsHaveBuyAmmo){
        ExecuteForward(WpnForwad, _, id, infoid, buycost)
        SetWpnMul(id, buycost)
    }else{
        m_print_color(id, "!g[冰布提醒]!y你的大洋不够。")
    }
    menu_destroy(menu)
}

public ReSpawnPlayer(id){
    if(is_user_alive(id)){
        m_print_color(id, "!g[冰布提示]!t你还活着不需要复活！！")
        return;
    }
    if(get_member(id , m_iTeam) == TEAM_CT){
        m_print_color(id, "!g[冰布提示]!t汉奸无法使用复活")
        return
    }
    new bool:IsHaveBuyAmmo
    const Float:buycost = 2.0
#if defined Usedecimal
    IsHaveBuyAmmo = Dec_cmp(id , buycost , ">=")
#else
    new Float:nowammos = GetAmmoPak(id)
    IsHaveBuyAmmo = (nowammos >= buycost)
#endif
    if(!IsHaveBuyAmmo){
        m_print_color(id, "!g[冰布提示]!y你没有足够的大洋进行复活")
        return
    }
    ExecuteHamB(Ham_CS_RoundRespawn, id)
    new name[32]
    get_user_name(id, name,31)
    m_print_color(0, "!g[冰布提示]!t%s抗日战士康复出院，已重返战场。", name)
    SubAmmoPak(id , 2.0)
}

public AddAmmo(id){
    new wpn = get_member(id, m_pActiveItem)
    if(!wpn)
        return
    new MaxAmmo = rg_get_iteminfo(wpn,ItemInfo_iMaxAmmo1)
    new WeaponIdType:wpnid = WeaponIdType:rg_get_iteminfo(wpn, ItemInfo_iId)
    if(wpnid == WEAPON_KNIFE || wpnid == WEAPON_HEGRENADE ||
        wpnid == WEAPON_FLASHBANG || wpnid == WEAPON_SMOKEGRENADE){
        m_print_color(id, "!g[冰布提醒]!y此武器不支持购买弹药")
        return;
    }
    MaxAmmo /= 2
    new orbpammo = rg_get_user_bpammo(id,wpnid)
    rg_set_user_bpammo(id,wpnid, orbpammo + MaxAmmo)

    new hegrenade_num = get_member(id , m_rgAmmo , 12)
    if(hegrenade_num == 0){
        rg_give_item(id, "weapon_hegrenade")
    }else{
        set_member(id ,m_rgAmmo , hegrenade_num + 1 , 12)
    }
 
    new Float:buycost = WeaponCost[BuyAmmo]
    SubAmmoPak(id, buycost)
}

public ItemSel_Post(id,item,Float:cost){
    if(item == BuyAmmo){
        AddAmmo(id)
        return
    }
    if(item == GiveHeal){
        GiveHeal_f(id)
        return
    }
    if(item == NpcMenu){
        client_cmd(id , "say npc")
        return
    }
    if(item == KillMarkMenu){
        client_cmd(id , "say /killmark")
        return
    }
}

public GiveHeal_f(id){
    new bool:IsHaveBuyAmmo
    new Float:BuyCost = WeaponCost[GiveHeal]
#if defined Usedecimal
    IsHaveBuyAmmo = Dec_cmp(id , BuyCost , ">=")
#else
    new Float:nowammos = GetAmmoPak(id)
    IsHaveBuyAmmo = (nowammos >= BuyCost)
#endif
    if(IsHaveBuyAmmo){
        new Float:C_Heal = get_entvar(id , var_health)
        if(C_Heal >= 100.0){
            m_print_color(id, "!g[提示] 您很健康不需要治疗")
            return
        }
        SubAmmoPak(id, BuyCost)
        if(C_Heal + 10.0 > 100.0){
            set_entvar(id , var_health, 100.0)
            return
        }
        set_entvar(id , var_health, C_Heal + 10.0)
        return
    }
    m_print_color(id, "!g[提示] 您的大洋不足以购买")
}

public Buy_Ammo(id){
    new Float:BuyCost = WeaponCost[BuyAmmo]
    new bool:IsHaveBuyAmmo
#if defined Usedecimal
    IsHaveBuyAmmo = Dec_cmp(id , BuyCost , ">=")
#else
    new Float:nowammos = GetAmmoPak(id)
    IsHaveBuyAmmo = (nowammos >= BuyCost)
#endif
    if(!IsHaveBuyAmmo){
        m_print_color(id, "!g[冰布提醒]!y你的大洋不够。")
        return
    }
    AddAmmo(id)
}

LvCheck(id){
    new ent = -1
    new JpNums = 0
    while((ent = rg_find_ent_by_class(ent , "hostage_entity",true)) > 0){
        if(get_entvar(ent , var_deadflag) == DEAD_DEAD) continue
        if(KrGetFakeTeam(ent) == CS_TEAM_T) continue
        JpNums++
    }
    if(JpNums == 0 && GetCurrentNpcs() > 0){
        server_cmd("Kr_EndRound")
        m_print_color(id , "!g[冰布提示]!y检测到卡关，以强制进入下一关卡")
        return
    }
    m_print_color(id , "!g[冰布提示]!y经过检测并未发现卡关")
}

public SetCam(id, Cam){
    if(is_user_alive(id) && is_user_connected(id)){
        set_view(id,Cam)
    }
}