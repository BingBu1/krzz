#include <amxmodx>
#include <amxmisc>
#include <kr_core>
#include <sqlx>
#include <xp_module>
#include <hamsandwich>

new Handle:g_SqlTuple
new Handle:g_SqlConnection

enum MarkData{
    _:Data_MarkName[32],
    Float:Data_cost,
    bool:Is_Has
}

new KillMarkModel[][] = {
    "sprites/KillMark/killmark_22s4CT.spr",
    "sprites/KillMark/killmark_25s1TR.spr",
    "sprites/KillMark/killmark_24s1CT.spr"
}

new MarkName[][MarkData] = {
    {
        "冰魂雪魄(Vip)",99999.0
    },
    {
        "小熊记录" , 2000.0
    },
    {
        "热情包子" , 1500.0
    },
}

new KillMarkUse[33]
new HasKillMark[33][sizeof MarkName][MarkData]
new Array:KillMarkSpr

public plugin_init(){
    register_plugin("击杀特效" , "1.0" , "冰桑")

    register_clcmd("say /killmark" , "KillMarkMenu")
    register_clcmd("say killmark" , "KillMarkMenu")
    register_clcmd("say test" , "testmodel")
}

public testmodel(id){
    rg_set_user_model(id , "fly_head")
}

public plugin_precache(){
    KillMarkSpr = ArrayCreate()
    for(new i = 0 ; i < sizeof KillMarkModel ; i++){
        ArrayPushCell(KillMarkSpr , precache_model(KillMarkModel[i]))
    }
    precache_model("models/player/fly_head/fly_head.mdl")
}

public client_putinserver(id){
    if(is_user_bot(id) || !GetSqlIsInit())
        return
    QueryMark(id)
}

public client_disconnected(id){
    KillMarkUse[id] = 0
    for(new i = 0 ; i < sizeof MarkName ; i++){
        HasKillMark[id][i][Is_Has] = false
    }
}

public KillMarkMenu(id){
    new menu = menu_create("击杀图标" , "BuyMarkHandle")
    new bool:IsHas
    for(new i = 0 ; i < sizeof MarkName ; i ++){
        new itemNames[64]
        if(HasKillMark[id][i][Is_Has]){ // 将 i 转换为对应的标志位
            formatex(itemNames , charsmax(itemNames) , "%s\r[已拥有]" , MarkName[i][Data_MarkName])
            IsHas = true
        }else{
            formatex(itemNames , charsmax(itemNames) , "%s[%.0f大洋]" , MarkName[i][Data_MarkName] , MarkName[i][Data_cost])
        }
        menu_additem(menu , itemNames , IsHas ? "1" : "0")
        IsHas = false
    }
    menu_display(id , menu)
}

public BuyMarkHandle(id , menu , item){
    if(item == MENU_EXIT){
        menu_destroy(menu)
        return
    }
    new access_ , infobuf[10]
    menu_item_getinfo(menu , item , access_ , infobuf , charsmax(infobuf))
    new bool:IsHas = bool:str_to_num(infobuf)
    BuyKillMark(id , item , IsHas)
    menu_destroy(menu)
    return
}

public BuyKillMark(id , item , bool:IsHave){
    if(IsHave){
        new steamid[32]
        KillMarkUse[id] = item
        m_print_color(id , "!g[冰布提示]!切换成功现在图标为%s" , MarkName[item][Data_MarkName])
        get_user_authid(id, steamid, charsmax(steamid))
        ChangeLastUse(item , steamid)
        return
    }
    if(item == 0 && !is_user_admin(id)){
        m_print_color(id , "!g[冰布提示]!y此物品不允许购买。")
        return
    }
    new Float:BuyCost = MarkName[item][Data_cost]
    new bool:HasAmmoToBuy
#if defined Usedecimal
    HasAmmoToBuy = Dec_cmp(id , BuyCost , ">")
#else
    new Float:HasCost = GetAmmoPak(id)
    HasAmmoToBuy = (HasCost > BuyCost)
#endif
    if(!HasAmmoToBuy){
        m_print_color(id , "!g[冰布提示]!y你的大洋不足以购买")
        return
    }
    SubAmmoPak(id , BuyCost)
    KillMarkUse[id] = item
    HasKillMark[id][item][Is_Has] = true
    m_print_color(id , "!g[冰布提示]!y购买成功现在你已拥有%s" , MarkName[item][Data_MarkName])
    UpdataMark(id , item)
}

public UpdataMark(id , BuyMarkid){
    new steamid[32], querystr[256], data[1],name[32]
    data[0] = id
    get_user_name(id , name ,charsmax(name))
    get_user_authid(id, steamid, charsmax(steamid))
    log_amx("%s购买了击杀图标, 执行Sql", name)
    new Handle:query_H = SQL_PrepareQuery(g_SqlConnection , "SET NAMES 'utf8'")
    if (!SQL_Execute(query_H)){
        new error[255]
        SQL_QueryError(query_H, error, charsmax(error))
        log_error(AMX_ERR_NOTFOUND , error)
    }
    formatex(querystr, charsmax(querystr),
    "INSERT INTO killmark_purchases(steamid, killmark, last_use) VALUES \
    ('%s', '%s' , %d)",
    steamid , MarkName[BuyMarkid][Data_MarkName] , BuyMarkid)
    query_H = SQL_PrepareQuery(g_SqlConnection , querystr)
    if (!SQL_Execute(query_H)){
        new error[255]
        SQL_QueryError(query_H, error, charsmax(error))
        log_error(AMX_ERR_NOTFOUND , error)
    }
}

public ChangeLastUse(UseId , SteamId[]){
    new Handle:QueryHandle = SQL_PrepareQuery(g_SqlConnection , "UPDATE killmark_purchases SET last_use = %d WHERE steamid = '%s'", UseId , SteamId)
    if (!SQL_Execute(QueryHandle)){
        new error[255]
        SQL_QueryError(QueryHandle, error, charsmax(error))
        log_error(AMX_ERR_NOTFOUND , error)
    }
}

public QueryMark(id){
    new steamid[32], query[256], data[1]
    data[0] = id
    get_user_authid(id, steamid, charsmax(steamid))
    log_amx("KillMark 进入查询 : %s",steamid)
    formatex(query, charsmax(query),
    "SELECT * FROM killmark_purchases WHERE steamid = '%s'", steamid)
    SQL_ThreadQuery(g_SqlTuple, "QueryKillMark", query, data ,sizeof data)
}

public QueryKillMark(FailState, Handle:Query, Error[], Errcode, Data[], DataSize , Float:QueryTime){
    if(FailState != TQUERY_SUCCESS){
        log_amx("查询失败 [%d] %s", Errcode, Error)
        return
    }
    new id = Data[0]
    if(!SQL_NumResults(Query)){
        KillMarkUse[id] = 0
    }else{

        new KillMarkNames[64]
        while (SQL_MoreResults(Query)){
            new qKillMarkInx = SQL_FieldNameToNum(Query , "killmark")
            new q_use = SQL_FieldNameToNum(Query , "last_use")
            SQL_ReadResult(Query , qKillMarkInx , KillMarkNames , charsmax(KillMarkNames))
            GetHasKillMark(id ,KillMarkNames)
            KillMarkUse[id] = SQL_ReadResult(Query , q_use)
            SQL_NextRow(Query)
		}
    }
    if(is_user_admin(id)){
         HasKillMark[id][0][Is_Has] = true
    }
}

public GetHasKillMark(id , QueryName[]){
    for(new i = 0 ; i < sizeof MarkName ; i++){
        if(!strcmp(MarkName[i][Data_MarkName] , QueryName)){
           HasKillMark[id][i][Is_Has] = true
        }
    }
}


public SqlInitOk(Handle:sqlHandle, Handle:ConnectHandle){
    g_SqlTuple = sqlHandle
    g_SqlConnection = ConnectHandle
    log_amx("回调初始化数据库成功")
}

public NPC_Killed(this , killer){
    if(!ExecuteHam(Ham_IsPlayer , killer))
        return
    return
    new Usering = KillMarkUse[killer]
    if(is_user_admin(killer)){
        new AdminMark = ArrayGetCell(KillMarkSpr , Usering)
        CreateKillSpr( AdminMark , this)
    }
    else if(Usering != 0){
        new UserMark = ArrayGetCell(KillMarkSpr , Usering)
        CreateKillSpr( UserMark , this)
    }
}


public CreateKillSpr(sprid , DeadEnt){
    new Float:fOrigin[3] , iOrigin[3]
    get_entvar(DeadEnt , var_origin , fOrigin)
    iOrigin[0] = floatround(fOrigin[0])
    iOrigin[1] = floatround(fOrigin[1])
    iOrigin[2] = floatround(fOrigin[2])
    message_begin(0 , SVC_TEMPENTITY)
    write_byte(TE_SPRITE)
    write_coord(iOrigin[0])
    write_coord(iOrigin[1])
    write_coord(iOrigin[2] + 35)
    write_short(sprid)
    write_byte(1) // scale
    write_byte(200) // alpha
    message_end()
}