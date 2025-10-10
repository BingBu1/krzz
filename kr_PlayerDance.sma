#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <reapi>

new const p_model[] = "models/simen_dac_b10.mdl"

new AvtEnt[33] , AnimEnt[33] , bool:InDoingEmo[33]

public plugin_init(){
    register_plugin("抗日跳舞" , "1.0" , "Bing")
    register_clcmd("cheer", "Open_EmoMenu")

    // register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
}

public plugin_precache(){
    precache_model(p_model)
}

public fw_AddToFullPack_Post(es_handle, e , ent, host, hostflags, player, pSet)
{
	if(!is_user_alive(host) && !pev_valid(ent))
		return FMRES_IGNORED
	if(AnimEnt[host] != ent)
		return FMRES_IGNORED
			
	set_es(es_handle, ES_Effects, get_es(es_handle, ES_Effects) | EF_NODRAW)
	return FMRES_IGNORED
}

public Open_EmoMenu(id){
    if(!is_user_alive(id))
        return
    new menu = menu_create("舞蹈菜单" , "OnEmoSel")
    menu_additem(menu , "测试表情1")
    menu_additem(menu , "测试表情2")
    menu_additem(menu , "测试表情3")
    menu_additem(menu , "测试表情4")
    menu_additem(menu , "测试表情5")
    menu_display(id, menu)
}

public OnEmoSel(id , menu , item){
    if(item == MENU_EXIT || !is_user_alive(id)){
        menu_destroy(menu)
        return
    }
    set_view(id , CAMERA_3RDPERSON)
    Start_Dance(id , item)
    return
}

Start_Dance(id , selitem){
    Do_Reset_Emotion(id)
    InDoingEmo[id] = true
    SetEnt_Invisible(id , true)
    Create_AvtEnt(id)
    CreateAnimEnt(id)
    if(!Check_Avalible(id))
        return
    Do_Set_Emotion(id , selitem)
}



Create_AvtEnt(id){
    static PlayerModelPath[256] ,UsersModelName[32]
    if(is_valid_ent(AvtEnt[id])){
        return
    }      
    new ent = rg_create_entity("info_target")
    if(is_nullent(ent))
        return
    AvtEnt[id] = ent
    set_entvar(ent , var_classname , "avatar")
    set_entvar(ent , var_owner , id)
    set_entvar(ent , var_movetype , MOVETYPE_FOLLOW)
    set_entvar(ent , var_solid , SOLID_NOT)

    fm_cs_get_user_model(id , UsersModelName , charsmax(UsersModelName))
    formatex(PlayerModelPath , charsmax(PlayerModelPath) , "models/player/%s/%s.mdl", UsersModelName, UsersModelName)
    engfunc(EngFunc_SetModel, ent, PlayerModelPath)	

    set_entvar(ent , var_body , get_entvar(id , var_body))
    set_entvar(ent , var_skin , get_entvar(id , var_skin))

    set_entvar(ent , var_renderamt , get_entvar(id , var_renderamt))
    new Float:Color[3]; get_entvar(id , var_rendercolor , Color)
    set_entvar(ent , var_rendercolor , Color)
    set_entvar(ent , var_renderfx , get_entvar(id , var_renderfx))
    set_entvar(ent , var_rendermode , get_entvar(id , var_rendermode))
    SetEnt_Invisible(ent , false)
}

CreateAnimEnt(id){
    if(is_valid_ent(AnimEnt[id]))
        return
    new ent = rg_create_entity("info_target")
    if(is_nullent(ent))
        return
    AnimEnt[id] = ent
    set_entvar(ent , var_classname , "AnimEnt")
    set_entvar(ent , var_owner , id)
    set_entvar(ent , var_movetype , MOVETYPE_TOSS)

    engfunc(EngFunc_SetModel , ent , p_model)
    engfunc(EngFunc_SetSize, ent, {-16.0, -16.0, 0.0}, {16.0, 16.0, 72.0})

    set_entvar(ent , var_solid , SOLID_BBOX)
    engfunc(EngFunc_DropToFloor , ent)
    set_entity_visibility(ent , false)
    set_entvar(ent , var_nextthink , get_gametime() + 0.1)
    SetThink(ent , "AnimThink")
}

public AnimThink(ent){
    new owner = get_entvar(ent , var_owner)
    if(!is_user_alive(owner))
        return
    new Float:Angles[3],Float:Angles2[3]
    get_entvar(owner , var_angles , Angles)
    get_entvar(ent , var_angles , Angles2)
    Angles[0] = 0.0 , Angles[2] = 0.0
    if(Angles[1] != Angles2[1]){
        set_entvar(ent , var_angles , Angles)
    }
    set_entvar(ent , var_nextthink , get_gametime() + 0.05)
    if(get_entvar(ent , var_effects) & EF_NODRAW){
        SetEnt_Invisible(ent , false)
    }
}


bool:Check_Avalible(id){
    if(!is_valid_ent(AvtEnt[id]) || !is_valid_ent(AnimEnt[id])){
        Do_Reset_Emotion(id)
        return false
    }
    return true
}

Do_Set_Emotion(id , Emoid){
    static Float:Origin[3], Float:Angles[3], Float:Velocity[3]
    get_entvar(id , var_origin ,Origin)
    get_entvar(id , var_angles ,Angles)
    get_entvar(id , var_velocity ,Velocity)

    Origin[2] -= 36.0
    set_entvar(AnimEnt[id] , var_origin , Origin)

    Angles[0] = 0.0, Angles[2] = 0.0
    set_entvar(AnimEnt[id] , var_angles , Angles)
    set_entvar(AnimEnt[id] , var_velocity , Velocity)

    set_entvar(AvtEnt[id] , var_aiment , AnimEnt[id])
    set_entvar(AvtEnt[id] , var_origin , Origin)
    Set_Entity_Anim(AnimEnt[id] , Emoid , 1)
}

Do_Reset_Emotion(id){
    if(!is_user_connected(id) || !InDoingEmo[id])
        return
    SetEnt_Invisible(id , false)
    if(is_entity(AvtEnt[id]))rg_remove_entity(AvtEnt[id])
    if(is_entity(AnimEnt[id]))rg_remove_entity(AnimEnt[id])
    AnimEnt[id] = AvtEnt[id] = 0
    InDoingEmo[id] = false
}

stock SetEnt_Invisible(id , bool:IsInvisible = true){
    new eff = get_entvar(id , var_effects)
    eff = IsInvisible ? eff | EF_NODRAW : eff & ~EF_NODRAW
    set_entvar(id , var_effects , eff)
}

stock fm_cs_get_user_model(id, Model[], Len)
{
	if(!is_user_connected(id))
		return
		
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", Model, Len)
}

stock Set_Entity_Anim(ent, Anim, ResetFrame)
{
	if(!is_valid_ent(ent))
		return
		
	set_entvar(ent, var_animtime, get_gametime())
	set_entvar(ent, var_framerate, 1.0)
	set_entvar(ent, var_sequence, Anim)
	if(ResetFrame) set_entvar(ent, var_frame, 0)
}