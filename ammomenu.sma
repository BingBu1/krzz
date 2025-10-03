#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <kr_core>
#include <reapi>
#include <xp_module>
#include <amxmodx>
#include <engine>
#include <props>


public plugin_init(){
    register_plugin("大洋兑换系统", "1.0", "Bing")

    register_clcmd("say /ammomenu", "CreateMenu")
    register_clcmd("Money", "MoneyCallback")
    register_clcmd("GiveMoney", "GivePlayerMoney")
}

public CreateMenu(id){
    new Menus = menu_create("大洋兑换系统\r(5w = 1大洋 兑换有50%手续费)","AmmoHandle")
    menu_additem(Menus,"金钱兑换大洋")
    menu_additem(Menus,"将当前金钱全部兑换")
    menu_additem(Menus,"大洋转账")
    menu_display(id, Menus)
}

public CreateGiveAmmoMenu(id){
    new Menus = menu_create("大洋转账系统\r(有20%手续费)","GiveAmmo")
    new players = get_maxplayers()
    new info[8]
    for(new i = 1 ; i < players ; i++){
        if( i == id )continue
        if(!is_user_alive(i) || !is_valid_ent(i))continue
        new name[32]
        get_user_name(i , name , 31)
        num_to_str(i, info, charsmax(info))
        menu_additem(Menus , name , info)
    }
    menu_display(id,Menus)
}

public GiveAmmo(id,menu,item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    new bool:IsHasAmmo
    const Float:MIN_TRANSFER = 2100.0
#if defined Usedecimal
    IsHasAmmo = Dec_cmp(id , MIN_TRANSFER , ">")
#else
    new Float:ammo = GetAmmoPak(id)
    IsHasAmmo = (ammo > MIN_TRANSFER)
#endif
    if(!IsHasAmmo){
        menu_destroy(menu)
        m_print_color(id, "!g[冰布提示]转账最少需要2100大洋。" )
        return
    }
    new acces , info[8] , playerid, name[32]
    menu_item_getinfo(menu , item , acces, info , charsmax(info) , name ,charsmax(name))
    playerid = str_to_num(info)

    client_cmd(id, "messagemode GiveMoney")
    m_print_color(id, "!g[冰布提示]请输入你要给予%s的数量!t(20%%手续费)" , name)

    
    set_prop_int(id , "gv" , playerid)
    menu_destroy(menu)
}

public GivePlayerMoney(id){
    if(!prop_exists(id , "gv")){
        m_print_color(id, "!g[冰布提示]未知错误，Prop is null")
        return
    }
    new giveid = get_prop_int(id , "gv")
    if(giveid > 33 || !is_valid_ent(giveid) || !is_user_connected(giveid)){
        m_print_color(id, "!g[冰布提示]错误，您要转账的对象不属于人类或者已离线不存在服务器")
        return
    }
    new money[32]
    read_argv(1, money, charsmax(money))
    new Float:giveammo = str_to_float(money)
    new bool:IsHaveAmmo
#if defined Usedecimal
    IsHaveAmmo = Dec_cmp(id , giveammo , ">")
#else
    new Float:hasmoney = GetAmmoPak(id)
    IsHaveAmmo = (hasmoney > giveammo)
#endif
    
    if(!IsHaveAmmo){
        m_print_color(id, "!g[冰布提示]你的大洋不够")
        return
    }
    new name[32],name2[32],Float:EndGive
    EndGive = giveammo * 0.8
    SubAmmoPak(id , giveammo)
    AddAmmoPak(giveid , EndGive)
    
    get_user_name(id , name , 31)
    get_user_name(giveid , name2 , 31)
    m_print_color(0, "!t[注意!!!]!g土豪!t%s!g转账给!t%s!g%f大洋!!t(已扣除手续费)" , name , name2 ,EndGive  )
    m_print_color(giveid, "!g[冰布提示]你收到了!t%s!g转给你的!t%f!g大洋实际收款!t%f。" ,name , giveammo , EndGive)
}

public AmmoHandle(id,menu,item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    switch(item){
        case 0 :{
            GetAmmoToMoney(id)
        }
        case 1:{
            AllMoneyToAmmo(id)
        }
        case 2:{
            CreateGiveAmmoMenu(id)
        }
    }
    menu_destroy(menu)
}

public GetAmmoToMoney(id){
    new m_money = cs_get_user_money(id)
    if(m_money < 50000){
        m_print_color(id, "!g[冰布提示]兑换大洋最低需要5w金钱")
        return
    }
    client_cmd(id, "messagemode Money")
    m_print_color(id, "!g[冰布提示]请输入你要兑换的数量!t(20%手续费)")
}

public MoneyCallback(id){
    new money[32]
    read_argv(1,money,charsmax(money))
    new cost = str_to_num(money)
    cost = floatround(float(cost) * 0.5)
    new m_money = cs_get_user_money(id)
    if(m_money < 50000 || m_money < cost){
        m_print_color(id, "!g[冰布提示]您无法兑换可能是金钱不足或不足5w")
        return
    }
    new Float:get = float(cost) / 50000.0
    AddAmmoPak(id, get)
    cs_set_user_money(id, m_money - cost)
    m_print_color(id, "!g[冰布提示]您兑换了%.2f块大洋", get)
}

public AllMoneyToAmmo(id){
    new m_money = cs_get_user_money(id)
    if(m_money < 50000){
        m_print_color(id, "!g[冰布提示]兑换大洋最低需要5w金钱")
        return
    }
    m_money = floatround(float(m_money) * 0.5)
    new Float:get = float(m_money) / 50000.0
    AddAmmoPak(id, get)
    cs_set_user_money(id, 0)
    m_print_color(id, "!g[冰布提示]您兑换了%.2f块大洋", get)
}
