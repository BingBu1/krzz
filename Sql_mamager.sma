#include <amxmodx>
#include <reapi>
#include <kr_core>
#include <props>
#include <fakemeta>
#include <sqlx>
#include <xp_module>

new forwardfunction
new Handle:g_SqlTuple, Handle:g_SqlConnection

new IsSqlLoad
public plugin_init(){
    register_plugin("Sql管理", "1.0", "Bing")
    forwardfunction = CreateMultiForward("SqlInitOk", ET_STOP, FP_CELL, FP_CELL)
    SqlInit()
}

public plugin_natives(){
    register_native("GetSqlIsInit" , "native_GetSqlIsInit")
}

public SqlInit(){
    new Err[512],errcode
    g_SqlTuple = SQL_MakeDbTuple("frp-dog.com:49163", "amxx", "amxxsql", "amxx_sql")
    g_SqlConnection = SQL_Connect(g_SqlTuple, errcode, Err, charsmax(Err))
    SQL_SetCharset(g_SqlTuple , "utf8")
    if(Empty_Handle == g_SqlConnection){
        log_amx("[错误码%d]管理器Sql初始化失败。%s",errcode,Err)
        return
    }
    server_print("数据库初始化成功.")
    ExecuteForward(forwardfunction,_, g_SqlTuple, g_SqlConnection)
    IsSqlLoad = true
}

public plugin_end(){
    if(!IsSqlLoad)
        return
    SQL_FreeHandle(g_SqlTuple)
    SQL_FreeHandle(g_SqlConnection)
}

public native_GetSqlIsInit(){
    return IsSqlLoad
}
