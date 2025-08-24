#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <kr_core>
#include <reapi>
#include <xp_module>



public plugin_init(){
    register_plugin("大洋兑换系统", "1.0", "Bing")

    register_clcmd("say /ammomenu", "CreateMenu")
    register_clcmd("Money", "MoneyCallback")
}

public CreateMenu(id){
    new Menus = menu_create("大洋兑换系统\r(5w = 1大洋 兑换有20%手续费)","AmmoHandle")
    menu_additem(Menus,"金钱兑换大洋")
    menu_additem(Menus,"将当前金钱全部兑换")
    menu_display(id, Menus)
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
    cost = floatround(float(cost) * 0.8)
    new m_money = cs_get_user_money(id)
    if(m_money < 50000 || m_money < cost){
        m_print_color(id, "!g[冰布提示]您无法兑换可能是金钱不足或不足5w")
        return
    }
    new Float:ammopak = GetAmmoPak(id)
    new Float:get = float(cost) / 50000.0
    ammopak += get
    SetAmmo(id, ammopak)
    cs_set_user_money(id, m_money - cost)
    m_print_color(id, "!g[冰布提示]您兑换了%f块大洋", get)
}

public AllMoneyToAmmo(id){
    new m_money = cs_get_user_money(id)
    if(m_money < 50000){
        m_print_color(id, "!g[冰布提示]兑换大洋最低需要5w金钱")
        return
    }
    m_money = floatround(float(m_money) * 0.8)
    new Float:ammopak = GetAmmoPak(id)
    new Float:get = float(m_money) / 50000.0
    Float:ammopak += get
    SetAmmo(id, ammopak)
    cs_set_user_money(id, 0)
    m_print_color(id, "!g[冰布提示]您兑换了%f块大洋", get)
}
