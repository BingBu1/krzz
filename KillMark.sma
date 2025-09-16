#include <amxmodx>
#include <amxmisc>
#include <kr_core>
#include <sqlx>
#include <xp_module>

new Handle:g_SqlTuple
new Handle:g_SqlConnection
new IsSqlLoad

enum KillMarkFlags( <<= 1 ){
    Mark_None,
    Mark_AdminSpr = 1,
    Mark_BearCamera,
}

enum MarkData{
    _:Data_MarkName[32],
    Float:Data_cost
}

new KillMarkModel[][] = {
    "sprites/KillMark/killmark_25s2TR.spr",
    "sprites/KillMark/killmark_25s1TR.spr"
}

new MarkName[][MarkData] = {
    {
        "管理专用-非售品",99999.0
    },
    {
        "小熊记录" , 2000.0
    },
}

new KillMarkUse[33]
new HasKillMark[33]
new Flags[KillMarkFlags]
new KillMarkSpr

public plugin_init(){
    register_plugin("击杀特效" , "1.0" , "冰桑")

    register_clcmd("say /killmark" , "KillMarkMenu")
    register_clcmd("say killmark" , "KillMarkMenu")

    InitFlag()
}

public InitFlag(){
    for(new i = 0 ; i < sizeof Flags ; i++){
        Flags[i] = 1 << i;
    }
}

public plugin_precache(){
    KillMarkSpr = ArrayCreate()
    for(new i = 0 ; i < sizeof KillMarkModel ; i++){
        ArrayPushCell(KillMarkSpr , precache_model(KillMarkModel[i]))
    }
}

public client_putinserver(id){
    if(is_user_bot(id) || !IsSqlLoad)
        return
    QueryMark(id)
}

public client_disconnected(id){
    KillMarkUse[id] = 0
    HasKillMark[id] = 0
}

public KillMarkMenu(id){
    new menu = menu_create("击杀图标" , "BuyMarkHandle")
    for(new i = 0 ; i < sizeof MarkName ; i ++){
        new itemNames[64]
        if(HasKillMark[id] & (1 << i)){ // 将 i 转换为对应的标志位
            formatex(itemNames , charsmax(itemNames) , "%s\r[已拥有]" , MarkName[i][Data_MarkName])
        }else{
            formatex(itemNames , charsmax(itemNames) , "%s[%.0f大洋]" , MarkName[i][Data_MarkName] , MarkName[i][Data_cost])
        }
        menu_additem(menu , itemNames)
    }
    menu_display(id , menu)
}

public BuyMarkHandle(id , menu , item){

}


public QueryMark(id){
    new steamid[32], query[256], data[1]
    data[0] = id
    get_user_authid(id, steamid, charsmax(steamid))
    log_amx("KillMark 进入查询 : %s",steamid)
    formatex(query, charsmax(query),
    "SELECT killmark last_use \
    FROM killmark_purchases WHERE steamid = '%s'",
    steamid)
    SQL_ThreadQuery(g_SqlTuple, "QueryKillMark", query, data ,sizeof data)
}

public QueryKillMark(FailState,Handle:Query,Error[],Errcode,Data[],DataSize , Float:QueryTime){
    if(FailState == TQUERY_CONNECT_FAILED)
    {
        log_amx("链接数据库失败 [%d] %s", Errcode, Error)
    }
    else if(FailState == TQUERY_QUERY_FAILED)
    {
        log_amx("查询失败 [%d] %s", Errcode, Error)
    }
    new id = Data[0]
    if(!SQL_NumResults(Query)){
        HasKillMark[id] = 0
        KillMarkUse[id] = 0
    }else{
        new qKillMarkInx = SQL_FieldNameToNum(Query , "killmark")
        new q_use = SQL_FieldNameToNum(Query , "last_use")
        new KillMarkNames[64]
        while (SQL_MoreResults(Query)){
            SQL_ReadResult(Query , qKillMarkInx , KillMarkNames , charsmax(KillMarkNames))
            GetHasKillMark(id ,KillMarkNames)
            KillMarkUse[id] = SQL_ReadResult(Query , q_use)
			SQL_NextRow(Query)
		}
    }
    if(is_user_admin(id)){
        HasKillMark[id] |= Mark_AdminSpr
    }
}

public GetHasKillMark(id , MarkName[]){
    for(new i = 0 ; i < sizeof KillMarkModel ; i++){
        if(strfind(KillMarkModel[i] , MarkName) != -1){
            HasKillMark[id] |= Flags[i]
        }
    }
}


public SqlInitOk(Handle:sqlHandle, Handle:ConnectHandle){
    g_SqlTuple = sqlHandle
    g_SqlConnection = ConnectHandle
    log_amx("回调初始化数据库成功")
    IsSqlLoad = true
}

public NPC_Killed(this , killer){
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