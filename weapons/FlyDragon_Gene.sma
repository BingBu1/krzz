#include <amxmodx>
#include <kr_core>
#include <reapi>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <props>
#include <xs>

#define Task_id 5112
#define SkillTask_id 191921
#define SetEntFireing(%1,%2) set_prop_int(%1 , "fireing" , %2) 
#define GetEntFireing(%1) get_prop_int(%1 , "fireing")
#define SetEntFireMaster(%1,%2) set_prop_int(%1 , "mst_f" , %2) 
#define GetEntFireMaster(%1) get_prop_int(%1 , "mst_f")
#define SetEntFireTimer(%1,%2) set_prop_float(%1 , "firetm" , %2) 
#define GetEntFireTimer(%1) get_prop_float(%1 , "firetm")
#define SetEntFireDmgTimer(%1,%2) set_prop_float(%1 , "firedmg" , %2) 
#define GetEntFireDmgTimer(%1) get_prop_float(%1 , "firedmg")
#define SetEntFireTouch(%1,%2) set_prop_float(%1 , "firtoc" , %2) 
#define GetEntFireTouch(%1) get_prop_float(%1 , "firtoc")

enum dragon_Anim{
    slow_Fly,
    Fast_Fly = 3,
    Sprint_Attack = 74
}

new model_res[][]={
    "models/Bing_Kr_res/Kr_Waepon/v_mouth.mdl",
    "models/Bing_Kr_res/Kr_Skill/ef_poison02.mdl", //1
    "models/Bing_Kr_res/Kr_Skill/poison.spr", // 2
    "models/Bing_Kr_res/Kr_Skill/dione_poison.mdl", // 3
    "models/player/HC_DRAGON/HC_DRAGON.mdl",
}

new sound[][]={
    "kr_sound/cso_angra/angra_zbs_fly2.wav",
    "kr_sound/zbs_poison_spit.wav", // 1
}

new bool:IsDragon[33] , Weaponid

new Float:Cd_1[33], Float:Cd_2[33], Float:Cd_3[33] , UseSkillIng[33]

new Fire_Spr ,laserbeam , poiosn_spr ,g_Explosion ,Float:FireDmage_Cd

public plugin_init(){
    register_plugin("Las Plagas寄生-Ⅰ型" , "1.0" , "Bing")

    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy , "m_DefaultDeploy")
    RegisterHookChain(RG_CBasePlayer_Spawn,"PlayerSpawn_Post",true)

    register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
    register_event("DeathMsg", "event_player_death", "a")	
    register_event( "HLTV", "new_round_event", "a", "1=0", "2=0" );
    RegisterHam(Ham_Think, "hostage_entity", "Ent_Fire_Think")
    RegisterHam(Ham_Think, "player", "Ent_Fire_Think")

    register_clcmd("radio1" , "Skill1")
    register_clcmd("radio2" , "Skill2")
    register_clcmd("radio3" , "Skill3")

    bind_pcvar_float(register_cvar("FireDmage_Cd" , "0.2" , FCVAR_SERVER) , FireDmage_Cd) 

    Weaponid = BulidWeaponMenu("Las Plagas寄生-Ⅰ型" , 15.0 )
}

public plugin_precache(){
    for(new i = 0 ; i < sizeof model_res ; i++)
        precache_model(model_res[i])
    for(new i = 0 ; i < sizeof sound ; i++)
        UTIL_Precache_Sound(sound[i])

    poiosn_spr = precache_model(model_res[2])
    Fire_Spr = precache_model("sprites/fire.spr")
    laserbeam = precache_model("sprites/laserbeam.spr")
    g_Explosion = precache_model("sprites/zerogxplode.spr")
}


public new_round_event(){
    arrayset(IsDragon , 0 , sizeof IsDragon)
    arrayset(UseSkillIng , 0 , sizeof UseSkillIng)
    arrayset(Cd_1 , 0.0 , sizeof Cd_1)
    arrayset(Cd_2 , 0.0 , sizeof Cd_2)
    arrayset(Cd_3 , 0.0 , sizeof Cd_3)
}

public PlayerSpawn_Post(this){
    if(!is_nullent(this) && !is_user_alive(this)){
        return HC_CONTINUE
    }
    UnDragon(this)
    return HC_CONTINUE
}

public client_putinserver(id){
    UnDragon(id)
}

public event_player_death() {
    new victim = read_data(2) // 死亡的玩家 ID
    UnDragon(victim)
}

public ItemSel_Post(id , items , Float:cost){
    if(items == Weaponid){
        BuyDragon(id , cost)
    }
}

public NPC_KillPlayer(this , killer){
    UnDragon(this)
}

public BuyDragon(id , Float:cost){
    new bool:CanBuy
#if defined Usedecimal
	CanBuy = Dec_cmp(id , cost , ">=")
#else
	new Float:ammopak = GetAmmoPak(id)
	CanBuy = (ammopak >= cost)
#endif
    if(!CanBuy){
        m_print_color(id , "!g[冰桑提示] 您的大洋不足以购买")
        return
    }
    if(IsDragon[id]){
        m_print_color(id , "!g[冰桑提示] 你已被病毒侵染无法再次使用。")
        return
    }
    IsDragon[id] = true
    SubAmmoPak(id , cost)
    rg_set_user_model(id , "HC_DRAGON")
    rg_remove_all_items(id)
    rg_give_item(id , "weapon_knife")
    engclient_cmd(id , "weapon_knife")
    set_entvar(id , var_viewmodel , model_res[0])
    set_entvar(id , var_weaponmodel , "")
    set_entvar(id , var_movetype , MOVETYPE_FLY)
    set_entvar(id , var_health , 10.0)
    set_entvar(id , var_fuser3 , 300.0)
    DisableMenu(id)

    set_task(1.0 , "Hud_Skill" , id + Task_id , .flags = "b")
}

public Event_CurWeapon(id){
    if(!IsDragon[id])
        return
    new WeaponId = read_data(2)
    if(WeaponId != CSW_KNIFE){
        rg_drop_items_by_slot(id , PRIMARY_WEAPON_SLOT)
        rg_drop_items_by_slot(id , PISTOL_SLOT)
        engclient_cmd(id, "weapon_knife") // 强制切换回刀
    }
        
}

public m_DefaultDeploy(const this, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal){
    new playerid = get_member(this, m_pPlayer)
    if(!IsDragon[playerid])
        return HC_CONTINUE
    SetHookChainArg(3 , ATYPE_STRING, "")
    SetHookChainArg(2 , ATYPE_STRING, model_res[0])
    return HC_CONTINUE
}

public Hud_Skill(id){
    new playerid = id - Task_id
    if(!is_valid_ent(playerid))
        remove_task(id)
    set_hudmessage(200, 0 , 0 , 0.8 , 0.8)
    new HudText[]= "状态: Las Plagas寄生^n吐息(Z): %s^n毒液喷射(x): %s^n自爆(C): %s^n"
    new Buff[100] , Cd1_T[20] , Cd2_T[20] , Cd3_T[20]
    GetSkillText(Cd_1[playerid] , Cd1_T , charsmax(Cd1_T)),
    GetSkillText(Cd_2[playerid] , Cd2_T , charsmax(Cd2_T)),
    GetSkillText(Cd_3[playerid] , Cd3_T , charsmax(Cd3_T))
    formatex(Buff , charsmax(Buff) , HudText , 
        Cd1_T , Cd2_T , Cd3_T
    )
    show_hudmessage(playerid , Buff)
}

GetSkillText(Float:Cd , OutPut[] ,len){
    if(get_gametime() > Cd){
        copy(OutPut , len , "已就绪")
        return
    }
    formatex(OutPut , len , "冷却%0.f秒" , Cd - get_gametime())
}

public Skill1(id){
    if(!IsDragon[id])
        return PLUGIN_CONTINUE
    if(get_gametime() > Cd_1[id]){
        set_task(0.2 , "Skill1_Task" , id + SkillTask_id , .flags = "b")
        set_task(10.0 , "Skill1_Task_End" , id + SkillTask_id)
        Cd_1[id] = get_gametime() + 20.0
        return PLUGIN_HANDLED
    }
    m_print_color(id , "!t你的技能还未准备完成")
    return PLUGIN_HANDLED
}

public Skill2(id){
    if(!IsDragon[id])
        return PLUGIN_CONTINUE
    if(get_gametime() > Cd_2[id]){
        Cd_2[id] = get_gametime() + 10.0
        CreatePoison(id)
    }
    m_print_color(id , "!t你的技能还未准备完成")
    return PLUGIN_HANDLED
}

public Skill3(id){
    if(!IsDragon[id])
        return PLUGIN_CONTINUE
    new Float:fOrigin[3]
    get_entvar(id , var_origin , fOrigin)
    set_entvar(id , var_effects , EF_NODRAW)
    rg_spawn_random_gibs(id , 5 , false)
    MakeBoom(fOrigin)
    rg_dmg_radius(fOrigin , id , id , 3000.0 , 500.0 , CLASS_PLAYER , DMG_SLASH | DMG_ALWAYSGIB)
    user_kill(id)
    return PLUGIN_HANDLED
}

public Skill1_Task(id){
    new playerid = id - SkillTask_id
    if(!is_user_alive(playerid) || !is_user_connected(playerid))
        remove_task(id)
    CreateSmock(playerid)
}

public Skill1_Task_End(id){
    remove_task(id)
}

CreateSmock(id){
    new Float:StartVec[3] , Float:view_ofs[3]
    get_entvar(id , var_origin , StartVec)
    get_entvar(id , var_view_ofs , view_ofs)
    xs_vec_add(StartVec , view_ofs , StartVec)

    new Spr_ent = rg_create_entity("info_target")
    if(is_nullent(Spr_ent))
        return
    new Float:fVel[3]
    velocity_by_aim(id, 800, fVel)
    set_entvar(Spr_ent, var_velocity, fVel)	
    set_entvar(Spr_ent , var_origin , StartVec)
    set_entvar(Spr_ent , var_rendermode , kRenderTransAdd)
    set_entvar(Spr_ent , var_renderamt , 255.0)
    // set_entvar(Spr_ent , var_rendercolor , Float:{255.0 , 0.0 ,0.0})
    set_entvar(Spr_ent , var_scale , 3.0)
    set_entvar(Spr_ent , var_movetype , MOVETYPE_FLY)
    set_entvar(Spr_ent , var_solid , SOLID_TRIGGER)
    set_entvar(Spr_ent , var_owner , id)
    SetThink(Spr_ent , "Fire_Think")
    SetTouch(Spr_ent , "Fire_Touch")
    set_entvar(Spr_ent , var_nextthink , get_gametime() + 0.03)
    set_entvar(Spr_ent , var_fuser1 , get_gametime() + 5.0)
    engfunc(EngFunc_SetModel , Spr_ent , "sprites/fire.spr")
    set_size(Spr_ent , Float:{-50.0 , -50.0, -10.0} , Float:{50.0, 50.0, 10.0})
    SetEntFireTouch(Spr_ent , get_gametime())
}

public Fire_Think(ent){
    new Float:GameTime = get_gametime()
    if(GameTime > get_entvar(ent ,var_fuser1)){
        SetThink(ent , "KillSelf")
        set_entvar(ent , var_nextthink , GameTime + 0.03)
        return
    }
    new Float:flFrame
    get_entvar(ent, var_frame, flFrame);
    flFrame = (flFrame >= 14.0) ? 0.0 : flFrame + 1.0;
    set_entvar(ent, var_frame, flFrame);
    set_entvar(ent , var_nextthink , GameTime + 0.03)
}

public Fire_Touch(this , betouch){
    new master = get_entvar(this , var_owner)
    new m_team = get_member(master , m_iTeam)
    if(ExecuteHam(Ham_IsPlayer , betouch) && get_member(betouch , m_iTeam) == m_team)
        return
    if(KrGetFakeTeam(betouch) == CsTeams:m_team)
        return
    if(!prop_exists(betouch , "fireing") || !GetEntFireing(betouch)){
        new Float:GameTime = get_gametime()
        SetEntFireing(betouch , true)
        SetEntFireMaster(betouch , master)
        SetEntFireTimer(betouch , GameTime + 10.0)
        SetEntFireDmgTimer(betouch , GameTime + FireDmage_Cd)
    }
    if(get_gametime() > GetEntFireTouch(this)){
        // new Float:fOrigin[3]
        // new master = get_entvar(ent , var_master)
        // get_entvar(ent , var_origin , fOrigin)
        ExecuteHamB(Ham_TakeDamage , betouch , master ,master ,80.0 , DMG_GENERIC)
        // rg_dmg_radius(fOrigin , master , master , 200.0 , 50.0 , CLASS_PLAYER , DMG_GENERIC)
        SetEntFireTouch(this , get_gametime () + 0.1)
    }
}

public Ent_Fire_Think(ent){
    if(!prop_exists(ent , "fireing") || !GetEntFireing(ent))
        return HAM_IGNORED
    new Float:GameTime = get_gametime()
    if(GameTime > GetEntFireTimer(ent)){
        SetEntFireing(ent , false)
        SetEntFireTimer(ent , GameTime)
        return HAM_IGNORED
    }
    if(GameTime > GetEntFireDmgTimer(ent)){
        new master = GetEntFireMaster(ent)
        SetEntFireDmgTimer(ent , GameTime + FireDmage_Cd)
        CreateSpr(Fire_Spr , ent)
        ExecuteHamB(Ham_TakeDamage , ent , master ,master , 150.0 , DMG_GENERIC)
    }
    return HAM_IGNORED
}

public KillSelf(id){
    rg_remove_entity(id)
}

stock UnDragon(id){
    if(!is_valid_ent(id) || !is_user_connected(id) || !is_entity(id))
        return
    set_entvar(id , var_fuser3 , 0.0)
    IsDragon[id] = false
    Cd_1[id] = 0.0
    Cd_2[id] = 0.0
    Cd_3[id] = 0.0
    UseSkillIng[id] = 0
    EnableMenu(id)
    remove_task(id + Task_id)
}


CreatePoison(id){
    if(!is_valid_ent(id) || !is_user_connected(id) || !is_entity(id))
        return
    new Float:StartVec[3] , Float:view_ofs[3]
    get_entvar(id , var_origin , StartVec)
    get_entvar(id , var_view_ofs , view_ofs)
    xs_vec_add(StartVec , view_ofs , StartVec)

    new Spr_ent = rg_create_entity("info_target")
    if(is_nullent(Spr_ent))
        return
    new Float:fVel[3],Float:fAngles[3]
    velocity_by_aim(id, 800, fVel)
    get_entvar(id, var_v_angle, fAngles)
    fAngles[0] *= -1.0
    set_entvar(Spr_ent,var_angles, fAngles)
    set_entvar(Spr_ent, var_velocity, fVel)	
    set_entvar(Spr_ent , var_origin , StartVec)
    set_entvar(Spr_ent , var_rendermode , kRenderTransAdd)
    set_entvar(Spr_ent , var_renderamt , 255.0)
    set_entvar(Spr_ent , var_movetype , MOVETYPE_FLY)
    set_entvar(Spr_ent , var_solid , SOLID_BBOX)
    set_entvar(Spr_ent , var_framerate , 1.0)
    set_entvar(Spr_ent , var_owner , id)
    SetTouch(Spr_ent , "poison_Touch")
    engfunc(EngFunc_SetModel , Spr_ent , model_res[3])
    set_size(Spr_ent , Float:{-1.0 , -1.0, -1.0} , Float:{1.0, 1.0, 1.0})
    SetEntFireing(Spr_ent , false)
}

public poison_Touch(this , Toucher){
    new master = get_entvar(this , var_owner)
    if(!is_user_connected(master)){
        rg_remove_entity(this)
        return
    }
    new Float:fOrigin[3]
    get_entvar(this , var_origin , fOrigin)
    CreateSpr(poiosn_spr ,  this , 25)
    UTIL_EmitSound_ByCmd2(this , sound[1] , 600.0)
    engfunc(EngFunc_SetModel , this , model_res[1])
    rg_dmg_radius(fOrigin , master , master , 300.0 , 350.0 , CLASS_PLAYER , DMG_POISON)
    set_entvar(this , var_nextthink , get_gametime() + 0.1)
    set_entvar(this , var_fuser1 , get_gametime() + 5.0)
    set_entvar(this , var_angles , Float:{0.0,0.0,0.0})
    set_size(this , Float:{0.0,0.0,0.0} , Float:{0.0,0.0,0.0})
    SetThink(this , "poison_think")
    SetEntFireDmgTimer(this , get_gametime() + 0.1)
    SetTouch(this , "")
}

public poison_think(this){
    new master = get_entvar(this , var_owner)
    if(!is_user_connected(master) || get_gametime() > get_entvar(this , var_fuser1)){
        rg_remove_entity(this)
        return
    }
    if(get_gametime() > GetEntFireDmgTimer(this)){
        new Float:fOrigin[3]
        get_entvar(this , var_origin , fOrigin)
        rg_dmg_radius(fOrigin , master , master , 180.0 , 275.0 , CLASS_PLAYER , DMG_POISON)
        SetEntFireDmgTimer(this , get_gametime() + 0.1)
    }
    set_entvar(this , var_nextthink , get_gametime() + 0.1)
}



stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock CreateSpr(sprid , DeadEnt , scale = 15){
    new Float:fOrigin[3] , iOrigin[3]
    get_entvar(DeadEnt , var_origin , fOrigin)
    iOrigin[0] = floatround(fOrigin[0])
    iOrigin[1] = floatround(fOrigin[1])
    iOrigin[2] = floatround(fOrigin[2])
    message_begin(0 , SVC_TEMPENTITY)
    write_byte(TE_SPRITE)
    write_coord(iOrigin[0])
    write_coord(iOrigin[1])
    write_coord(iOrigin[2] + 35 )
    write_short(sprid)
    write_byte(scale) // scale
    write_byte(200) // alpha
    message_end()
}

stock draw_bbox_lines(ent, color[3] , Float:duration) {
    if(!pev_valid(ent)) return;

    new Float:absmin[3], Float:absmax[3];
    pev(ent, pev_absmin, absmin);
    pev(ent, pev_absmax, absmax);
    
    // 计算8个顶点
    new Float:points[8][3];
    for(new i = 0; i < 8; i++) {
        points[i][0] = (i & 1) ? absmax[0] : absmin[0];
        points[i][1] = (i & 2) ? absmax[1] : absmin[1];
        points[i][2] = (i & 4) ? absmax[2] : absmin[2];
    }
    
    // 绘制12条边
    draw_line(laserbeam,points[0], points[1], color, duration); // 底边1
    draw_line(laserbeam,points[0], points[2], color, duration); // 底边2
    draw_line(laserbeam,points[3], points[1], color, duration); // 底边3
    draw_line(laserbeam,points[3], points[2], color, duration); // 底边4
    
    draw_line(laserbeam,points[4], points[5], color, duration); // 顶边1
    draw_line(laserbeam,points[4], points[6], color, duration); // 顶边2
    draw_line(laserbeam,points[7], points[5], color, duration); // 顶边3
    draw_line(laserbeam,points[7], points[6], color, duration); // 顶边4
    
    draw_line(laserbeam,points[0], points[4], color, duration); // 竖边1
    draw_line(laserbeam,points[1], points[5], color, duration); // 竖边2
    draw_line(laserbeam,points[2], points[6], color, duration); // 竖边3
    draw_line(laserbeam,points[3], points[7], color, duration); // 竖边4
}

stock draw_line(spr,Float:start[3], Float:end[3], color[3], Float:life) {
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    write_coord_f(start[0]);
    write_coord_f(start[1]);
    write_coord_f(start[2]);
    write_coord_f(end[0]);
    write_coord_f(end[1]);
    write_coord_f(end[2]);
    write_short(spr); // 光束精灵
    write_byte(0); // 起始帧
    write_byte(0); // 帧率
    write_byte(floatround(life * 10.0)); // 持续时间 (帧)
    write_byte(5); // 线宽
    write_byte(0); // 噪声
    write_byte(color[0]); // R
    write_byte(color[1]); // G
    write_byte(color[2]); // B
    write_byte(200); // 亮度
    write_byte(0); // 滚动速度
    message_end();
}

public MakeBoom(Float:iOrigin[3]){
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_EXPLOSION)
    write_coord_f(iOrigin[0])
    write_coord_f(iOrigin[1])
    write_coord_f(iOrigin[2])
    write_short(g_Explosion)
    write_byte(90)
    write_byte(15)
    write_byte(0)
    message_end()
}