#include <amxmodx>
#include <reapi>
#include <kr_core>
#include <props>
#include <fakemeta>

new WallModuleName[] = "models/Kr_wall/new_wall.mdl"
new Current_judian
// new Array:CreateWalls

public plugin_init(){
	register_plugin("抗日Wall", "1.0", "Bing")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
}

public plugin_precache(){
    precache_model(WallModuleName)
}

public event_roundstart(){
    new ent = -1
    while(ent = rg_find_ent_by_class(ent,"riben_wall")){
        set_entvar(ent,var_effects,0)
        set_entvar(ent,var_solid,SOLID_BBOX)
        ReSize(ent)
    }
}

public plugin_natives(){
    register_native("CreateWall","native_CreateWall")
}

public native_CreateWall(id,nums){
    new setbody = get_param(1)
    new Float:Origin[3],Float:angles[3]
    get_array_f(2,Origin,sizeof Origin)
    get_array_f(3,angles,sizeof angles)
    new delon = get_param(4)
    new ent = rg_create_entity("info_target")
    if(!ent)
        return 0
    set_entvar(ent, var_classname, "riben_wall")
    set_entvar(ent, var_solid, SOLID_BBOX)
    set_entvar(ent, var_movetype, MOVETYPE_FLY)
    set_entvar(ent, var_body, setbody)
    set_entvar(ent, var_angles, angles)
    set_entvar(ent ,var_origin, Origin)

    set_entvar(ent, var_nextthink , get_gametime() + 0.5)

    SetThink(ent,"riben_wall_think")

    engfunc(EngFunc_SetModel,ent, WallModuleName)
    set_prop_int(ent , "judian_remove" , delon)

    new Float:mins[3] = {-200.0, -8.0, -100.0},
    Float:maxs[3] = {200.0, 8.0, 100.0}
    if(angles[1] == 0.0 || angles[1] == 180.0){
        new Float:newmin[3],Float:newmax[3]
        newmin[0] = mins[1],newmin[1] = mins[0],
        newmin[2] = mins[2]

        newmax[0] = maxs[1],newmax[1] = maxs[0],
        newmax[2] = maxs[2]
        engfunc(EngFunc_SetSize, ent , newmin , newmax)
    }else{
        engfunc(EngFunc_SetSize, ent , mins , maxs)
    }
    return ent
}

// public On_judian_Change_Post(judian){
//     Current_judian = judian
// }

public riben_wall_think(id){
    new delon = get_prop_int(id,"judian_remove")
    new JUdianNums = GetJuDianNum()
    if(delon == 0 && JUdianNums == 8){
        set_entvar(id,var_effects,EF_NODRAW)
        set_entvar(id,var_solid,SOLID_NOT)
        engfunc(EngFunc_SetSize,id,Float:{0.0,0.0,0.0}, Float:{0.0,0.0,0.0})
    }else if(delon == JUdianNums && JUdianNums != 0){
        set_entvar(id,var_effects,EF_NODRAW)
        set_entvar(id,var_solid,SOLID_NOT)
        engfunc(EngFunc_SetSize,id,Float:{0.0,0.0,0.0}, Float:{0.0,0.0,0.0})
    }
    set_entvar(id, var_nextthink , get_gametime() + 0.5)
}

public ReSize(id){
    new Float:angles[3]
    new Float:mins[3] = {-200.0, -8.0, -100.0},
    Float:maxs[3] = {200.0, 8.0, 100.0}
    get_entvar(id,var_angles,angles)
    if(angles[1] == 0.0 || angles[1] == 180.0){
        new Float:newmin[3],Float:newmax[3]
        newmin[0] = mins[1],newmin[1] = mins[0],
        newmin[2] = mins[2]

        newmax[0] = maxs[1],newmax[1] = maxs[0],
        newmax[2] = maxs[2]
        engfunc(EngFunc_SetSize, id , newmin , newmax)
    }else{
        engfunc(EngFunc_SetSize, id , mins , maxs)
    }
}
