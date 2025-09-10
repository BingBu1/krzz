#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <kr_core>
#include <reapi>
#include <xp_module>

#define MaxItem 255

new Waeponid
new WeaponName[MaxItem][64]
new Float:WeaponCost[MaxItem]
new IsReSpawn[33]

new WpnForwad , OnCreateIteam_

new BuyAmmo,GiveHeal,NpcMenu

new menuname[64]
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
    BuyAmmo = BulidWeaponMenu("购买弹药", 0.04)
    GiveHeal = BulidWeaponMenu("军医治疗", 0.04)
}


public plugin_natives(){
    register_native("BulidWeaponMenu","native_BulidWeaponMenu")
    register_native("ChangeMenuName","native_ChangeMenuName")
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
    menu_display(id, menuid)
}

public CreateWeaponMenu(id){
    if(get_user_team(id) == CS_TEAM_CT)
        return;
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
        case 0:{
            //抗日武器
            CreateWeaponMenu(id)
        }
        case 1:{
            //大洋系统
            client_cmd(id,"say /ammomenu")
        }
        case 2:{
            //重返战场
            ReSpawn(id)
        }
        case 3:{
            //更改模型
            client_cmd(id, "say /changemodle")
        }
        case 4: {
            //下一张地图
            client_cmd(id, "say nextmap")
        }
        case 5:{
            //剩余时间
            client_cmd(id, "say timeleft")
        }
        case 6:{
            //难度调整
            client_cmd(id, "say /lv")
        }
        case 7:{
            //当前时间
            client_cmd(id, "say thetime")
        }
        case 8:{
            //武器菜单
            client_cmd(id, "say givewpn")
        }
        case 9:{
            //购买下局规则
            client_cmd(id, "say /buyrule")
        }
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
    new Float:nowammos = GetAmmoPak(id)
    if(nowammos >= buycost){
        ExecuteForward(WpnForwad, _, id, infoid, buycost)
        SetWpnMul(id, buycost)
    }else{
        m_print_color(id, "!g[冰布提醒]!y你的大洋不够。")
    }
    menu_destroy(menu)
}

public ReSpawn(id){
    if(is_user_alive(id)){
        m_print_color(id, "!g[冰布提示]!t你还活着不需要复活！！")
        return;
    }
    if(is_nullent(id)){
        return;
    }
    if(IsReSpawn[id] == 2 ){
        m_print_color(id, "!g[冰布提示]!t每局最多重生两次")
    }
    ExecuteHamB(Ham_CS_RoundRespawn, id)
    new name[32]
    get_user_name(id, name,31)
    m_print_color(0, "!g[冰布提示]!t%s抗日战士康复出院，已重返战场。", name)
    IsReSpawn[id]++
}

public AddAmmo(id){
    new wpn = get_member(id, m_pActiveItem)
    if(!wpn)
        return
    new MaxAmmo = rg_get_iteminfo(wpn,ItemInfo_iMaxAmmo1)
    new wpnid = rg_get_iteminfo(wpn, ItemInfo_iId)
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
        new w_ent = rg_give_item(id, "weapon_hegrenade")
    }else{
        set_member(id ,m_rgAmmo , hegrenade_num + 1 , 12)
    }
    
 
    new Float:buycost = WeaponCost[BuyAmmo]
    new Float:nowammos= GetAmmoPak(id)
    SetAmmo(id, nowammos - buycost)
}

public ItemSel_Post(id,item,Float:cost){
    new Float:m_Ammo = GetAmmoPak(id)
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
}

public GiveHeal_f(id){
    new Float:m_Ammo = GetAmmoPak(id)
    new Float:BuyCost = WeaponCost[GiveHeal]
    if(m_Ammo > BuyCost){
        new Float:C_Heal = get_entvar(id , var_health)
        new currAddHp = 10.0
        if(C_Heal >= 100.0){
            m_print_color(id, "!g[提示] 您很健康不需要治疗")
            return
        }
        SetAmmo(id, m_Ammo - BuyCost)
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
    new Float:buycost = WeaponCost[BuyAmmo]
    new Float:nowammos= GetAmmoPak(id)
    if(nowammos >= buycost){
        AddAmmo(id)
    }else{
        m_print_color(id, "!g[冰布提醒]!y你的大洋不够。")
    }
}
