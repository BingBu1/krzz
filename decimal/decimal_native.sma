#include <amxmodx>
#include <bigint>

#define Decamil_MapStr "%d_Dec"

#define GetKey(%1,%2) formatex(%1 , charsmax(%1) , Decamil_MapStr , %2)

public plugin_init(){
    register_plugin("高精度小数封装" , "1.0" , "Bing")
}

public plugin_natives(){
    register_native("Dec_cmp" , "native_decimal_Cmp")
}

public native_decimal_Cmp(key[] , Float:CmpValue , chars[]){
    new id = get_param(1)
    new cmpChar[5]
    get_string(3 , cmpChar , 4)
    new Key[20]
    GetKey(Key , id)
    return decimal_Cmp(Key , get_param_f(2) , cmpChar) 
}