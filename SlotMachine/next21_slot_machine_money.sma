#include <amxmodx>
#include <slotmachine>
#include <reapi>
#include <kr_core>
#include <xp_module>
#include <props>

new const PLUGIN[] =    "Slot Machine Money"
new const VERSION[] =   "0.1"
new const AUTHOR[] =    "Psycrow"
new PlayerBetAmmo[MAX_PLAYERS + 1 ]
new PlayerUseAmmo[MAX_PLAYERS + 1 ]

new IsInPvp[MAX_PLAYERS + 1]
new PvpAdd[MAX_PLAYERS + 1]

#define BET						100

new const GAME_PRIZES[] =
{
	2,
	3,
	3,
	5,
	5,
	10
}

new g_msgBlinkAcct

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("next21_slot_machine.txt")
    register_clcmd("say /machine" , "CreatemachineMenu")
    register_clcmd("say machine" , "CreatemachineMenu")
    register_clcmd("PvPMachine" , "PvpCheck")
    register_clcmd("Change_Bet" , "Change_Bet")
    g_msgBlinkAcct = get_user_msgid("BlinkAcct")
}

public plugin_precache(){
    UTIL_Precache_Sound("kr_sound/dushen.wav")
}

public client_putinserver(id){
    PlayerBetAmmo[id] = 10
    IsInPvp[id] = 0
    PvpAdd[id] = 0
    PlayerUseAmmo[id] = 0
}

public client_disconnected(id){
    PlayerBetAmmo[id] = 0
    IsInPvp[id] = 0
    PvpAdd[id] = 0
    PlayerUseAmmo[id] = 0
}

public CreatemachineMenu(const id){
    new Menu = menu_create("下注金额" , "DisMenu")
    new Buff[40]
    formatex(Buff , charsmax(Buff) , "\y修改下注金额[当前\r%d\y大洋]" , PlayerBetAmmo[id])
    menu_additem(Menu , Buff)
    menu_additem(Menu , "\y赌王对赌")
    menu_display(id , Menu)
}

public DisMenu(id , menu , item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    switch (item){
        case 0 : ChangeBet(id)
        case 1 : CreatePvP(id)
    }
    menu_destroy(menu)
    return
}

ChangeBet(id){
    client_cmd(id , "messagemode Change_Bet")
    m_print_color(id , "!g注意最大下注不得超过888")
}

CreatePvP(id){
    new Menus = menu_create("对赌菜单","PvPSel")
    new players = get_maxplayers()
    new info[8]
    for(new i = 1 ; i < players ; i++){
        if( i == id )continue
        if(!is_user_connected(i))continue
        new name[32]
        get_user_name(i , name , 31)
        num_to_str(i, info, charsmax(info))
        menu_additem(Menus , name , info)
    }
    menu_display(id,Menus)
}

PvPTargetCreateMenu(id , target , cost){
    new Tile[64] , name[32]

    get_user_name(id , name , charsmax(name))

    formatex(Tile , charsmax(Tile) , "%s向你发出了对赌邀请(押注%d)" , name , cost)
    new Menus = menu_create(Tile, "PvP_Accept")
    new info[10]
    num_to_str(id , info , charsmax(info))
    menu_additem(Menus , "接受" , info)
    menu_additem(Menus , "拒绝" , info)

    menu_display(target, Menus , .time = 30)
    set_prop_int(target , "appactid" , id)
    set_prop_int(target , "appactcost" , cost)
}

public PvP_Accept(id , menu ,item){
    if(item == MENU_EXIT || item == MENU_TIMEOUT){
        new player = get_prop_int(id , "appactid")
        m_print_color(player , "!g[冰布提示]对面拒绝了你的邀请")
        menu_destroy(menu)
        set_prop_int(id , "appactid" , 0)
        set_prop_int(id , "appactcost" , 0)
        return
    }
    new acces , info[8] , playerid, name[32]
    menu_item_getinfo(menu , item , acces, info , charsmax(info) , name ,charsmax(name))
    playerid = str_to_num(info)
    new cost = get_prop_int(id , "appactcost")
    switch(item){
        case 0: StartPvP_Machine(playerid , id , cost)
        case 1: {
            m_print_color(playerid , "!g[冰布提示]对面拒绝了你的邀请已返回赌注")
            AddAmmoPak(playerid , float(cost))
        }
    }
    set_prop_int(id , "appactid" , 0)
    set_prop_int(id , "appactcost" , 0)
    return
}

StartPvP_Machine(id , target , cost){
    new name1[32],name2[32]
    get_user_name(id , name1 , charsmax(name1))
    get_user_name(target , name2 , charsmax(name2))
    m_print_color(0 , "!g[冰布提示]!t%s向%s开启了对赌押注%d，30秒内老虎机累计中奖大洋最多的获胜",
        name1 , name2 , cost
    )

    new PvpEnt =  rg_create_entity("info_target")
    if(PvpEnt <= 0){
        m_print_color(0 ,"!g[赌局]赌局异常，已退还押注金额")
        return
    }
    IsInPvp[id] = true
    IsInPvp[target] = true
    SubAmmoPak(id , float(cost))
    SubAmmoPak(target , float(cost))
    set_entvar(PvpEnt , var_iuser1 , id)
    set_entvar(PvpEnt , var_iuser2 , target)
    set_entvar(PvpEnt , var_health , float(cost))
    set_entvar(PvpEnt , var_nextthink , get_gametime() + 30.0)
    SetThink(PvpEnt , "PvPEndCall")
}

public PvPEndCall(ent){
    new Pvp1 = get_entvar(ent , var_iuser1)
    new Pvp2 = get_entvar(ent , var_iuser2)
    new PvpCost = floatround(get_entvar(ent , var_health))
    new Float:fPvpCost = float(PvpCost)
    new Float:EndPvpCost
    new name1[32] , name2[32]
    get_user_name(Pvp1 , name1 , charsmax(name1))
    get_user_name(Pvp2 , name2 , charsmax(name2))
    EndPvpCost = (fPvpCost * 2) * 0.8
    if(!is_user_connected(Pvp1) || !IsInPvp[Pvp1]){
        m_print_color(0 , "!g[赌局提示]由于%s离线，判处%s赢得赌局获得%f押注金额(已扣除手续费)" , name1 ,name2, EndPvpCost)
        AddAmmoPak(Pvp2 , EndPvpCost)
    }
    if(!is_user_connected(Pvp2) || !IsInPvp[Pvp2]){
        m_print_color(0 , "!g[赌局提示]由于%s离线，判处%s赢得赌局获得%f押注金额(已扣除手续费)" , name2, name1 , EndPvpCost)
        AddAmmoPak(Pvp1 , EndPvpCost)
    }

    if(PvpAdd[Pvp1] > PvpAdd[Pvp2] && IsInPvp[Pvp1] && IsInPvp[Pvp2]){
        m_print_color(0 , "!g[赌局提示]%s赢得赌局获得%f押注金额(已扣除手续费)" , name1 , EndPvpCost)
        AddAmmoPak(Pvp1 , EndPvpCost)
    }else if(PvpAdd[Pvp2] > PvpAdd[Pvp1] && IsInPvp[Pvp1] && IsInPvp[Pvp2]) {
        m_print_color(0 , "!g[赌局提示]%s赢得赌局获得%f押注金额(已扣除手续费)" , name2 , EndPvpCost)
        AddAmmoPak(Pvp2 , EndPvpCost)
    }else if(PvpAdd[Pvp2] == PvpAdd[Pvp1] && IsInPvp[Pvp1] && IsInPvp[Pvp2]){
        m_print_color(0 , "!g[赌局提示]%s与%s居然打成了平局，返回各位赌注！" , name1 , name2)
        AddAmmoPak(Pvp1 , fPvpCost)
        AddAmmoPak(Pvp2 , fPvpCost)
    }
    UTIL_EmitSound_ByCmd(0 , "kr_sound/dushen.wav")

    PvpAdd[Pvp1] = 0
    PvpAdd[Pvp2] = 0
    IsInPvp[Pvp1] = 0
    IsInPvp[Pvp2] = 0
    rg_remove_entity(ent)
}

public PvpCheck(id){
    new money[32]
    read_argv(1,money,charsmax(money))
    new cost = str_to_num(money)
    if(cost <= 0){
        m_print_color(id , "!g[冰布提示]你下的赌注不能小于等于0")
        return 
    }
    new PvPTarget = get_prop_int(id , "pvp")
    set_prop_int(id , "pvp" , 0)
    new bool:CanPvpA , bool:CanPvpB
#if !defined Usedecimal
    new PvpA_Ammo = GetAmmoPak(id)
    new PVpB_Ammo = GetAmmoPak(PvPTarget)
    CanPvpA = (floatround(PvpA_Ammo) > (cost + 100))
    CanPvpB = (floatround(PVpB_Ammo) > (cost + 100))
#else
    CanPvpA =  Dec_cmp(id , float(cost + 100), ">")
    CanPvpB = Dec_cmp(PvPTarget , float(cost + 100), ">")
#endif
    if(!CanPvpA){
        m_print_color(id , "!g[冰布提示]你的余额不足以完成对赌。")
        return 
    }
    if(!CanPvpB){
        m_print_color(id , "!g[冰布提示]对方的余额不足以完成对赌。")
        return 
    }
    PvPTargetCreateMenu(id ,PvPTarget , cost)
    m_print_color(id , "!g[冰布提示]已发出对赌邀请请等待回应")
}

public PvPSel(id , menu , item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    new acces , info[8] , playerid, name[32]
    menu_item_getinfo(menu , item , acces, info , charsmax(info) , name ,charsmax(name))
    playerid = str_to_num(info)
    if(is_user_bot(playerid)){
        m_print_color(id , "!g[冰布提示]你不能与BOT对赌")
        return
    }
    client_cmd(id, "messagemode PvPMachine")

    m_print_color(id, "!g[冰布提示]请输入你要押注%s的数量" , name)

    set_prop_int(id , "pvp" , playerid)
}

public Change_Bet(id){
    new argc = read_argc()
    if(argc < 2){
        m_print_color(id ,"!g[冰布提示]!t 错误的参数，请重新输入只包含数字")
        return
    }
    new Bit = read_argv_int(1)
    if(Bit > 888){
        m_print_color(id ,"!g[冰布提示]!t 大洋押注最大不得大于888")
        return
    }
    if(Bit <= 0){
        m_print_color(id ,"!g[冰布提示]!t 大洋押注最低不得低于1")
        return
    }
    PlayerBetAmmo[id] = Bit
}

public client_slot_machine_win(const iPlayer, const iPrize)
{
    new Win =  GAME_PRIZES[iPrize]
    new AddPak = PlayerUseAmmo[iPlayer] * Win
    AddAmmoPak(iPlayer , float(AddPak))
    new name[32]
    get_user_name(iPlayer , name , charsmax(name))
    client_print_color(0 , print_team_default , "%L" , iPlayer , "WIN_AMMO" , name , AddPak , Win)
    if(IsInPvp[iPlayer]){
        PvpAdd[iPlayer] += AddPak
        m_print_color(iPlayer , "!g[赌局]!t你已经累计%d" , PvpAdd[iPlayer])
    }
}

public client_slot_machine_spin(const iPlayer)
{
    new Float:NeedAmmo = float(PlayerBetAmmo[iPlayer])
    new bool:HasAmooToSlot
#if !defined Usedecimal
    new Float:Ammo = GetAmmoPak(iPlayer)
    HasAmooToSlot = (Ammo >= NeedAmmo)
#else
    HasAmooToSlot = Dec_cmp(iPlayer , NeedAmmo , ">=")
#endif
    if(!HasAmooToSlot){
        message_begin(MSG_ONE, g_msgBlinkAcct, .player = iPlayer)
        write_byte(2)
        message_end()
        m_print_color(iPlayer , "%L" , iPlayer, "NOT_ENOUGH_AMMO")
        return PLUGIN_HANDLED
    }
    SubAmmoPak(iPlayer , float(PlayerBetAmmo[iPlayer]))
    PlayerUseAmmo[iPlayer] = PlayerBetAmmo[iPlayer]
    return PLUGIN_CONTINUE
}
