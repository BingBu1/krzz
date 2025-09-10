#include <amxmodx>
#include <slotmachine>
#include <reapi>
#include <kr_core>
#include <xp_module>

new const PLUGIN[] =    "Slot Machine Money"
new const VERSION[] =   "0.1"
new const AUTHOR[] =    "Psycrow"
new PlayerBetAmmo[MAX_PLAYERS + 1 ]

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
    register_clcmd("Change_Bet" , "Change_Bet")
    g_msgBlinkAcct = get_user_msgid("BlinkAcct")
}

public client_putinserver(id){
    PlayerBetAmmo[id] = 10
}

public client_disconnected(id){
    PlayerBetAmmo[id] = 0
}

public CreatemachineMenu(const id){
    new Menu = menu_create("下注金额" , "DisMenu")
    new Buff[40]
    formatex(Buff , charsmax(Buff) , "修改下注金额[^3当前%d大洋]" , PlayerBetAmmo[id])
    menu_additem(Menu , Buff)
    menu_display(id , Menu)
}

public DisMenu(id , menu , item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    if(item == 0){
        ChangeBet(id)
    }
    menu_destroy(menu)
    return
}

ChangeBet(id){
    client_cmd(id , "messagemode Change_Bet")
    m_print_color(id , "!g注意最大下注不得超过100")
}

public Change_Bet(id){
    new argc = read_argc()
    if(argc < 2){
        m_print_color(id ,"!g[冰布提示]!t 错误的参数，请重新输入只包含数字")
        return
    }
    new Bit = read_argv_int(1)
    if(Bit > 100){
        m_print_color(id ,"!g[冰布提示]!t 大洋押注最大不得大于100")
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
    new AddPak = PlayerBetAmmo[iPlayer] * Win
    AddAmmoPak(iPlayer , float(AddPak))
    new name[32]
    get_user_name(iPlayer , name , charsmax(name))
    client_print_color(0 , print_team_default , "%L" , iPlayer ,"WIN_AMMO" , name , AddPak , Win)

}

public client_slot_machine_spin(const iPlayer)
{
    new Float:Ammo = GetAmmoPak(iPlayer)
    if(floatround(Ammo) < PlayerBetAmmo[iPlayer]){
        client_print_color(iPlayer , print_team_default , "%L" , iPlayer)
        m_print_color(iPlayer , "%L" , iPlayer, "NOT_ENOUGH_AMMO")
        return PLUGIN_HANDLED
    }
    SubAmmoPak(iPlayer , float(PlayerBetAmmo[iPlayer]))
    // if (get_member(iPlayer, m_iAccount) < BET)
    // {
	// 	message_begin(MSG_ONE, g_msgBlinkAcct, .player = iPlayer)
	// 	write_byte(2)
	// 	message_end()

	// 	client_print_color(iPlayer, print_team_default, "^4[%s] %L",
    //         PLUGIN, iPlayer, "NOT_ENOUGH_MONEY")

	// 	return PLUGIN_HANDLED
    // }

    // rg_add_account(iPlayer, -BET)
    return PLUGIN_CONTINUE
}
