#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <hamsandwich>
#include <fakemeta_util>
#include <engine>
#include <cstrike>
#include <kr_core>
#include <props>
#include <xs>

#define Had_Weapon(%0,%1)					bool: (get_entvar(%0, var_impulse) == %1)
#define Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));

#define GetWeaponClip(%0)					get_member(%0, m_Weapon_iClip)
#define SetWeaponClip(%0,%1)				set_member(%0, m_Weapon_iClip, %1)
#define GetWeaponAmmoType(%0)				get_member(%0, m_Weapon_iPrimaryAmmoType)
#define GetWeaponAmmo2Type(%0)				get_member(%0, m_Weapon_iSecondaryAmmoType)
#define GetWeaponAmmo(%0,%1)				get_member(%0, m_rgAmmo, %1)
#define SetWeaponAmmo(%0,%1,%2)				set_member(%0, m_rgAmmo, %1, %2)

#define CLIP 36
#define Max_bpammo 180
#define WaeponIDs 10000 + 7
#define cost 18.0

#define V_MODEL "models/Bing_Kr_res/Kr_Waepon/v_anniv24gunkata_hand.mdl"
#define W_MODEL "models/Bing_Kr_res/Kr_Waepon/w_anniv24gunkata.mdl"
#define P_MODEL "models/Bing_Kr_res/Kr_Waepon/p_anniv24gunkata.mdl"
#define DefWModule "models/w_elite.mdl"

#define weapon_gunkata "weapon_elite"
#define Weapon_Name "weapon_gunkata"
#define WaeponCode WEAPON_ELITE
#define FireCoolDown 0.07

#define Expspr "sprites/thanatos5_explode2.spr"

#define FireDamage 300
#define ExpDamage 1500.0

#define SetWeaponSkillCount(%1,%2) set_prop_int(%1 , "Skill_cut" , %2)
#define GetWeaponSkillCount(%1) get_prop_int(%1 , "Skill_cut")
#define SetSkillNextAnimTimer(%1,%2) set_prop_float(%1 , "Skl_Nt" , %2)
#define GetSkillNextAnimTimer(%1) get_prop_float(%1 , "Skl_Nt")

#define TaskId 10010

enum _:kataAnim{
    idle,
    idle2,
    shoot,
    shoot_last,
    shoot2,
    shoot2_last,
    reload,
    reload2,
    draw,
    draw2,
    skill_01,
    skill_02,
    skill_03,
    skill_04,
    skill_05,
    skill_last,
}

enum
{
	HIT_NONE,
	HIT_ENEMY,
	HIT_WALL
};

new HasWaepon , WpnShootCount[33] , ShootState[33]

new FW_OnFreeEntPrivateData

new HookChain:gl_HookChain_IsPenetrableEntity_Post

new ClientSounds[][] ={
    "weapons/gunkata_reload.wav",
    "weapons/gunkata_reload2.wav",
    "weapons/gunkata_draw.wav",
    "weapons/gunkata_draw2.wav",
    "weapons/gunkata_skill_last.wav",
    "weapons/gunkata_skill_last_exp.wav", // 5
    "weapons/gunkata_skill_01.wav", // 6
    "weapons/gunkata_skill_02.wav",
    "weapons/gunkata_skill_03.wav",
    "weapons/gunkata_skill_04.wav",
    "weapons/gunkata_skill_05.wav",
}

new EmitSound[][]={
    "weapons/gunkata-1.wav"
}

new ExpSprId


public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle){
    new wpn = get_member(Player , m_pActiveItem)
    if(is_nullent(wpn))
        return FMRES_IGNORED
    if(!is_user_alive(Player) || !Had_Weapon(wpn, WaeponIDs)) {
        return FMRES_IGNORED
    }
    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 2.0)
    return FMRES_IGNORED
}

public plugin_init(){
    register_plugin("深渊", "1.0", "Bing")
    RegisterHookChain(RG_CreateWeaponBox , "m_CreateWaeponBox_Post" , true)
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy , "m_DefaultDeploy")
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultReload , "m_DefaultReload")
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "m_AddPlayerItem")
    
    // RegisterHookChain(RG_CBasePlayerWeapon_KickBack, "m_KickBack")

    register_forward(FM_UpdateClientData , "fw_UpdateClientData_Post" , 1)

    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")

    RegisterHam(Ham_Weapon_PrimaryAttack , weapon_gunkata , "m_PrimaryAttack")
    RegisterHam(Ham_Weapon_WeaponIdle , weapon_gunkata , "m_WeaponIdel_Pre")
    RegisterHam(Ham_Item_AddToPlayer, weapon_gunkata, "Ham_CWeapon_AddToPlayer_Post", true);
    RegisterHam(Ham_Spawn, weapon_gunkata, "Ham_CWeapon_Spawn_Post", true);
    RegisterHam(Ham_Item_PostFrame, weapon_gunkata, "Ham_CWeapon_PostFrame_Pre")	
    DisableHookChain(gl_HookChain_IsPenetrableEntity_Post = RegisterHookChain(RG_IsPenetrableEntity, "RG_IsPenetrableEntity_Post", true));

    register_srvcmd("Give_kata", "GiveHeroGunFunc")
    register_concmd(Weapon_Name, "hook_weapon")
}

public plugin_precache(){
    precache_model(V_MODEL)
    precache_model(W_MODEL)
    precache_model(P_MODEL)

    ExpSprId = precache_model(Expspr)
    for(new i = 0 ; i < sizeof ClientSounds ; i++){
        UTIL_Precache_Sound(ClientSounds[i])
    }
    for(new i = 0 ; i < sizeof EmitSound ; i++){
        precache_sound(EmitSound[i])
    }
    precache_generic("sprites/weapon_gunkata.txt")
    precache_generic("sprites/ZombieDarkness/640hud18.spr")
    precache_generic("sprites/ZombieDarkness/640hud176.spr")
}

public hook_weapon(id){
    engclient_cmd(id , weapon_gunkata)
}

public client_disconnected(id){
    UnSet_BitVar(HasWaepon, id)
    WpnShootCount[id] = 0
    ShootState[id] = 0
}

public event_roundstart(){
    HasWaepon = 0
    arrayset(WpnShootCount , 0 , sizeof WpnShootCount)
    arrayset(ShootState , 0 , sizeof ShootState)
}

public OnEntityRemoved(const ent){
    new classname[32]
    get_entvar(ent, var_classname, classname, charsmax(classname))
    if(equal(classname, weapon_gunkata)){
        new playerid = get_member(ent, m_pPlayer)
        if(is_nullent(playerid)){
            return
        }
        UnSet_BitVar(HasWaepon, playerid)
        rg_give_item(playerid, weapon_gunkata)//发放源武器
        if (HasWaepon == 0){
            unregister_forward(FM_OnFreeEntPrivateData, FW_OnFreeEntPrivateData)
        }
    }
}

public m_CreateWaeponBox_Post(const weaponent, const owner, modelName[], Float:origin[3], Float:angles[3], Float:velocity[3], Float:lifeTime, bool:packAmmo){
    if(!owner || !weaponent){
        return HC_CONTINUE
    }
    new weaponbox = GetHookChainReturn(ATYPE_INTEGER)
    new classname[32]
    get_entvar(weaponbox,var_classname,classname,charsmax(classname))
    if(!equal(classname , "weaponbox")){
        return HC_CONTINUE
    }

    if(equal(modelName , DefWModule) && Get_BitVar(HasWaepon , owner)){
        UnSet_BitVar(HasWaepon, owner)
        set_entvar(weaponent, var_impulse, WaeponIDs)
        engfunc(EngFunc_SetModel , weaponbox, W_MODEL)
    }
    return HC_CONTINUE
}

public m_DefaultDeploy(const this, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal){
    new classname[32]
    get_entvar(this, var_classname, classname, charsmax(classname))
    if(!equal(classname , weapon_gunkata)){
        return
    }
    new playerid = get_member(this, m_pPlayer)
    if(Get_BitVar(HasWaepon, playerid)){
        new Anim = GetWpnAnim(playerid)
        SetHookChainArg(4, ATYPE_INTEGER, Anim == 0 ? draw : draw2)
        SetHookChainArg(2,ATYPE_STRING, V_MODEL)
        SetHookChainArg(3,ATYPE_STRING, P_MODEL)
        SetWeaponSkillCount(this , 0)
    }
}

public m_DefaultReload(const this, iClipSize, iAnim, Float:fDelay){
    new playerid = get_member(this, m_pPlayer)
    new WeaponIdType:Wpnid = WeaponIdType:rg_get_iteminfo(this , ItemInfo_iId)
    if(!Get_BitVar(HasWaepon, playerid) || Wpnid != WaeponCode){
        return
    }
    new Anim = random_num(reload , reload2)
    SetHookChainArg(3 , ATYPE_INTEGER , Anim)
    SetHookChainArg(4 , ATYPE_FLOAT , 2.03)
    WpnShootCount[playerid] = 0
    ShootState[playerid] = 0

}

public Ham_CWeapon_AddToPlayer_Post(iWpn, id){
    new playerid = get_member(iWpn, m_pPlayer)
    new WeaponIdType:Wpnid = WeaponIdType:rg_get_iteminfo(iWpn , ItemInfo_iId)
    if (is_nullent(iWpn) || !Get_BitVar(HasWaepon, playerid) || Wpnid != WaeponCode)
    	return

    new szWeaponName[32]
    rg_get_iteminfo(iWpn, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName))

    message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id)
    write_string(szWeaponName)
    write_byte(GetWeaponAmmoType(iWpn))
    write_byte(rg_get_iteminfo(iWpn, ItemInfo_iMaxAmmo1))
    write_byte(GetWeaponAmmo2Type(iWpn))
    write_byte(rg_get_iteminfo(iWpn, ItemInfo_iMaxAmmo2))
    write_byte(rg_get_iteminfo(iWpn, ItemInfo_iSlot))
    write_byte(rg_get_iteminfo(iWpn, ItemInfo_iPosition))
    write_byte(rg_get_iteminfo(iWpn, ItemInfo_iId))
    write_byte(rg_get_iteminfo(iWpn, ItemInfo_iFlags))
    message_end()
}

public Ham_CWeapon_Spawn_Post(iWpn) {
    if (is_nullent(iWpn) || !Had_Weapon(iWpn, WaeponIDs))
    	return;

    set_member(iWpn, m_Weapon_iDefaultAmmo, Max_bpammo);

    rg_set_iteminfo(iWpn, ItemInfo_pszName, Weapon_Name);
    rg_set_iteminfo(iWpn, ItemInfo_iMaxClip, CLIP);
    rg_set_iteminfo(iWpn, ItemInfo_iMaxAmmo1, Max_bpammo);
}

public m_WeaponIdel_Pre(const this){
    new playerid = get_member(this, m_pPlayer)
    new WeaponIdType:Wpnid = WeaponIdType:rg_get_iteminfo(this , ItemInfo_iId)
    if(!Get_BitVar(HasWaepon, playerid) || Wpnid != WaeponCode){
        return HAM_IGNORED
    }
    if (get_member(this, m_Weapon_flTimeWeaponIdle) > 0.0)
		return HAM_IGNORED;
    new Anim = GetWpnAnim(playerid)
    new SendAnim = Anim == 0 ? idle : idle2
    Stock_SendWeaponAnim(playerid , this , SendAnim)
    set_member(this, m_Weapon_flTimeWeaponIdle, 6.03);
    return HAM_SUPERCEDE;
}

public m_AddPlayerItem (const this, const pItem){
    if(is_nullent(this)){
        return HC_CONTINUE
    }
    if(get_entvar(pItem,var_impulse) == WaeponIDs){
        Set_BitVar(HasWaepon, this)
        SetWeaponSkillCount(pItem , 0)
        SetSkillNextAnimTimer(pItem , get_gametime())
        FW_OnFreeEntPrivateData = register_forward(FM_OnFreeEntPrivateData, "OnEntityRemoved", false)
    }
    return HC_CONTINUE
}

public FreeGive(id){
    server_cmd("give_kata %d" , id)
}

public GiveHeroGunFunc(){
    new argc = read_argc()
    if(argc >= 2){
        new id = read_argv_int(1)
        if(!is_user_connected(id) || !is_user_alive(id)){
            log_amx("给予深渊武器失败,玩家不在线或未存活")
            return
        }
        new wpn = rg_give_custom_item(id , weapon_gunkata , GT_DROP_AND_REPLACE, WaeponIDs)
        if(!wpn)
            return
        Set_BitVar(HasWaepon, id)
        rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
        rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
        set_member(wpn, m_Weapon_iClip, CLIP)
        rg_set_user_bpammo(id,WEAPON_M249,Max_bpammo)
        SetWeaponSkillCount(wpn , 0)
        engclient_cmd(id , weapon_gunkata)
        return
    }
    log_amx("给予深渊武器失败,无效的参数")
}

public m_PrimaryAttack_Post(this){
    new Player = get_member(this , m_pPlayer)
    if(!Get_BitVar(HasWaepon , Player))
        return HAM_IGNORED
    return HAM_IGNORED
}

public m_PrimaryAttack(this){
    new Player = get_member(this , m_pPlayer)
    if(!Get_BitVar(HasWaepon , Player))
        return HAM_IGNORED
    if(get_member(Player , m_flNextAttack) > 0.0){
        return HAM_SUPERCEDE
    }
    new Cilp = get_member(this , m_Weapon_iClip)
    if(!Cilp){
        ExecuteHam(Ham_Weapon_PlayEmptySound, this);
        set_member(this, m_Weapon_flNextPrimaryAttack, 0.2);
        return HAM_SUPERCEDE;
    }
    Gun_Shot(Player , this , Cilp)
    return HAM_SUPERCEDE
}


public Gun_Shot(Playerid , p_Gun , Clip){
    static Float:vecSrc[3], Float:vecAiming[3]
    Stock_GetEyePosition(Playerid, vecSrc);
    Stock_GetAiming(Playerid, vecAiming);

    EnableHookChain(gl_HookChain_IsPenetrableEntity_Post)
    rg_fire_bullets3(Playerid, Playerid, vecSrc, vecAiming, 0.0, 8192.0, 5, BULLET_PLAYER_556MM, FireDamage, 0.9, false, get_member(Playerid, random_seed));
    DisableHookChain(gl_HookChain_IsPenetrableEntity_Post)

    set_member(p_Gun , m_Weapon_iClip , Clip - 1)

    rg_set_animation(Playerid, PLAYER_ATTACK1);


    WpnShootCount[Playerid]++

    emit_sound(Playerid, CHAN_WEAPON, EmitSound[0], VOL_NORM, ATTN_NORM, 0, random_num(95,120))

    if(!CalcShootStatue(Playerid)){
        Stock_SendWeaponAnim(Playerid, p_Gun, GetWpnAnim(Playerid) == 0 ? shoot : shoot2);
        SetFireCoolDown(p_Gun , 0.1 , 2.0)
    }else{
        Stock_SendWeaponAnim(Playerid, p_Gun, GetWpnAnim(Playerid) == 0 ? shoot2_last : shoot_last);
        SetFireCoolDown(p_Gun , 0.53 , 2.0)
    }
}
native CreateBlast(const id)
public Ham_CWeapon_PostFrame_Pre(ent)
{
    static id; id = get_entvar(ent, var_owner)
    if(!is_user_connected(id) || !is_user_alive(id))
    	return HAM_IGNORED
    if (is_nullent(ent) || !Had_Weapon(ent, WaeponIDs)){
        new player = get_member(ent , m_pPlayer)
        ShootState[player] = 0
        return HAM_IGNORED
    }

    new player = get_member(ent , m_pPlayer)
    new button = get_entvar(player ,var_button)
    new Float:NextAttack = get_member(ent , m_Weapon_flNextSecondaryAttack)

    if(ShootState[player] == 2 && NextAttack  <= 0.0){
        new LastAmmo = rg_get_user_bpammo(player , WaeponCode)
        if(LastAmmo >= 0){
            new SubAmmo = CLIP <= LastAmmo ? CLIP : LastAmmo
            rg_set_user_bpammo(player , WaeponCode , LastAmmo - SubAmmo)
            set_member(ent , m_Weapon_iClip , SubAmmo)
        }
        UTIL_EmitSound_ByCmd2(player , ClientSounds[5] , 500.0)
        Do_Damage(player , 500.0 , 300.0 , 360.0 , 1200.0 , 400.0 , 0.0)
        ShootState[player] = 0
        SetFireCoolDown(ent , 0.3 , 1.0)
        set_task(0.7 , "ReDeploy" , TaskId + ent)
        CreateBlast(player)
        return HAM_IGNORED
    }

    if(button & IN_ATTACK2 &&  NextAttack <= 0.0){
    	SecFire(player , ent)
        if(ShootState[player] != 2)
            set_task(0.7 , "ReDeploy" , TaskId + ent)
    }

    return HAM_IGNORED
}

public ReDeploy(id){
    id -= TaskId
    new Player = get_member(id , m_pPlayer)
    if(!is_user_connected(Player) || !is_user_alive(Player) || !Had_Weapon(id, WaeponIDs))
        return
    new IsReloading = get_member(id , m_Weapon_fInReload)
    if(!IsReloading){
        ExecuteHam(Ham_Item_Deploy , id)
    }
}

SecFire(const Player , const iWpn){
    new iClip = get_member(iWpn , m_Weapon_iClip)
    if(iClip <= 0)
        return
    remove_task(TaskId + iWpn)
    new Float:PlayerOrg[3]

    new FireCount = GetWeaponSkillCount(iWpn)

    if(FireCount >= 5){
        SetWeaponSkillCount(iWpn , 0)
        FireCount = 0
    }

    get_entvar(Player , var_origin , PlayerOrg)

    // rg_dmg_radius(PlayerOrg , Player , Player , 300.0 , 500.0 , CLASS_PLAYER , 0)
    //const clientIndex, const Float:Damage_Range, const Float:Damage, const Float:Point_Dis, const Float:Knockback, const Float:KnockUp, const Float:Painshock
    Do_Damage(Player , 350.0 , 50.0 , 360.0 , 50.0 , 0.0 , 100.0)
    
    SetFireCoolDown(iWpn , 0.1 , 2.0)

    set_member(iWpn , m_Weapon_iClip , iClip - 1)

    WpnShootCount[Player]++

    CalcShootStatue(Player)

    if(iClip - 1 <= 0){
        SetFireCoolDown(iWpn , 0.76 , 1.35)
        SetWeaponSkillCount(iWpn , 0)
        Stock_SendWeaponAnim(Player , iWpn , skill_last)
        ShootState[Player] = 2
        return
    }

    if(get_gametime() > GetSkillNextAnimTimer(iWpn)){
        SetWeaponSkillCount(iWpn , FireCount + 1)
        Stock_SendWeaponAnim(Player , iWpn , FireCount + skill_01)
        switch(FireCount){
            case 0 , 1:{
                UTIL_EmitSound_ByCmd2(Player , ClientSounds[6 + FireCount] , 500.0)
                SetSkillNextAnimTimer(iWpn , get_gametime() + 0.48)
            } 
            case 2 .. 5:{
                UTIL_EmitSound_ByCmd2(Player , ClientSounds[6 + FireCount] , 500.0)
                SetSkillNextAnimTimer(iWpn , get_gametime() + 0.7)
            }  
        }
    }
}

public m_KickBack(const this, Float:up_base, Float:lateral_base, Float:up_modifier, Float:lateral_modifier, Float:p_max, Float:lateral_max, direction_change){
    new player = get_member(this, m_pPlayer)
    if(!is_user_connected(player) || !Get_BitVar(HasWaepon, player)){
        return HC_CONTINUE
    }
    return HC_CONTINUE
}

public m_FireBullets3(pEntity, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread, Float:flDistance, iPenetration, iBulletType, iDamage, Float:flRangeModifier, pevAttacker, bool:bPistol, shared_rand){
    if(!is_user_connected(pEntity) || !Get_BitVar(HasWaepon, pEntity) || get_user_weapon(pEntity) != CSW_M249){
        return HC_CONTINUE
    }
    SetHookChainArg(8 , ATYPE_INTEGER , FireDamage)
    return HC_CONTINUE
}

public RG_IsPenetrableEntity_Post(Float:vecStart[3], Float:vecEnd[3], id, pHit)
{
	static iPointContents
	iPointContents = engfunc(EngFunc_PointContents, vecEnd);

	if (iPointContents == CONTENTS_SKY)
		return;
	if (pHit && is_nullent(pHit) || (get_entvar(pHit, var_flags) & FL_KILLME) || !ExecuteHam(Ham_IsBSPModel, pHit))
		return;

	Stock_GunshotDecalTrace(pHit, vecEnd);

	if (iPointContents == CONTENTS_WATER)
		return;

	static Float: vecPlaneNormal[3]; global_get(glb_trace_plane_normal, vecPlaneNormal);
	xs_vec_mul_scalar(vecPlaneNormal, random_float(25.0, 30.0), vecPlaneNormal);

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecEnd);
	write_byte(TE_STREAK_SPLASH);
	engfunc(EngFunc_WriteCoord, vecEnd[0]);
	engfunc(EngFunc_WriteCoord, vecEnd[1]);
	engfunc(EngFunc_WriteCoord, vecEnd[2]);
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[0]);
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[1]);
	engfunc(EngFunc_WriteCoord, vecPlaneNormal[2]);
	write_byte(4);
	write_short(random_num(10, 20));
	write_short(3);
	write_short(64);
	message_end();
}


stock CreateExp(const id , Float:Origin[3]){
    message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
    write_byte(TE_EXPLOSION)
    engfunc(EngFunc_WriteCoord, Origin[0])
    engfunc(EngFunc_WriteCoord, Origin[1])
    engfunc(EngFunc_WriteCoord, Origin[2])
    write_short(ExpSprId)	// sprite index
    write_byte(20)	// scale in 0.1's
    write_byte(10)	// framerate
    write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS)	// flags
    message_end()   
    
    rg_dmg_radius(Origin , id , id , ExpDamage , 350.0 , CLASS_PLAYER , DMG_BULLET)
    // rg_radius_damage(Origin, id, id, ExpDamage, 350.0, DMG_BULLET)
}

stock GetWatchEnd(player , Float:OutEndOrigin[3]){
    new Float:hitorigin[3]
    new Float:StartOrigin[3],Float:EndOrigin[3],Float:Eyes[3]
    new Float:angles[3], Float:fwd[3];
    get_entvar(player, var_origin , StartOrigin)
    get_entvar(player, var_view_ofs, Eyes)
    xs_vec_add(StartOrigin, Eyes, StartOrigin)
    get_entvar(player, var_v_angle, angles)
    engfunc(EngFunc_MakeVectors, angles)
    global_get(glb_v_forward, fwd)
    xs_vec_mul_scalar(fwd, 8192.0, EndOrigin)
    xs_vec_add(StartOrigin,EndOrigin,EndOrigin)
    new hitent = fm_trace_line(player,StartOrigin,EndOrigin,hitorigin)
    xs_vec_copy(hitorigin, OutEndOrigin)
    return hitent
}

stock rg_radius_damage(const Float:origin[3], attacker, inflictor, Float:damage, Float:radius, dmg_bits)
{
    new ent = -1
    new Float:target_origin[3]
    new Float:distance, Float:final_damage

    while ((ent = find_ent_in_sphere(ent, origin, radius)) != 0)
    {
        if(ent == attacker) continue
        if(!is_valid_ent(ent)) continue
        if(get_entvar(ent, var_takedamage) == DAMAGE_NO) continue

        new deadflag
        get_entvar(ent, var_deadflag, deadflag)
        if(deadflag != DEAD_NO) continue

        // 如果有自定义 NPC 阵营，最好也在这里屏蔽友军
        if(is_user_alive(ent) && cs_get_user_team(ent) == cs_get_user_team(attacker))
            continue

        get_entvar(ent, var_origin, target_origin)
        distance = vector_distance(origin, target_origin)

        // 距离越远伤害越低
        final_damage = damage * (1.0 - (distance / radius))
        if(final_damage <= 0.0) continue

        // 设置 inflictor 正确归属
        set_entvar(ent, var_dmg_inflictor, inflictor)

        ExecuteHamB(Ham_TakeDamage, ent, inflictor, attacker, final_damage, dmg_bits)
    }
}


stock Stock_SendWeaponAnim(id, iWpn, iAnim) 
{
	static iBody; iBody = get_entvar(iWpn, var_body);
	set_entvar(id, var_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, .player = id);
	write_byte(iAnim);
	write_byte(iBody);
	message_end();

	if (get_entvar(id, var_iuser1))
		return;

	static i, iCount, pSpectator, aSpectators[MAX_PLAYERS];
	get_players(aSpectators, iCount, "bch");

	for (i = 0; i < iCount; i++)
	{
		pSpectator = aSpectators[i];

		if (get_entvar(pSpectator, var_iuser1) != OBS_IN_EYE)
			continue;
		if (get_entvar(pSpectator, var_iuser2) != id)
			continue;

		set_entvar(pSpectator, var_weaponanim, iAnim);

		message_begin(MSG_ONE, SVC_WEAPONANIM, .player = pSpectator);
		write_byte(iAnim);
		write_byte(iBody);
		message_end();
	}
}

stock Stock_GetEyePosition(id, Float:vecEyeLevel[3])
{
	static Float: vecOrigin[3]; get_entvar(id, var_origin, vecOrigin);
	static Float: vecViewOfs[3]; get_entvar(id, var_view_ofs, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecEyeLevel);
}

stock Stock_GetAiming(id, Float:vecAiming[3]) 
{
	static Float: vecViewAngle[3]; get_entvar(id, var_v_angle, vecViewAngle);
	static Float: vecPunchAngle[3]; get_entvar(id, var_punchangle, vecPunchAngle);

	xs_vec_add(vecViewAngle, vecPunchAngle, vecViewAngle);
	angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming);
}

stock GetWpnAnim(Player){
    return ShootState[Player]
}

stock bool:CalcShootStatue(Playerid){
    if(WpnShootCount[Playerid] % 3 == 0){
        ShootState[Playerid] = !ShootState[Playerid] ? 1 : 0 
        WpnShootCount[Playerid] = 0
        return true
    }
    return false
}

stock SetFireCoolDown(Wpn , Float:CoolDown , Float:nextIdle = 0.0 , Float:NextAttack = 0.0){
    set_member(Wpn , m_Weapon_flNextPrimaryAttack , CoolDown)
    set_member(Wpn , m_Weapon_flNextSecondaryAttack , CoolDown)
    new Player = get_member(Wpn , m_pPlayer)
    set_member(Player , m_flNextAttack ,  NextAttack)
    if(nextIdle > 0.0){
        SetNextIdel(Wpn , nextIdle)
    }else{
        SetNextIdel(Wpn , CoolDown)
    }
}

stock SetNextIdel(Wpn , Float:CoolDown){
    set_member(Wpn , m_Weapon_flTimeWeaponIdle , CoolDown)
}

stock Stock_GunshotDecalTrace(pEntity, Float:vecOrigin[3])
{	
	new iDecalId = Stock_DamageDecal(pEntity);
	if (iDecalId == -1)
		return;

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(pEntity);
	write_byte(iDecalId);
	message_end();
}

stock Stock_DamageDecal(const pEntity)
{
	new iRenderMode = get_entvar(pEntity, var_rendermode);
	if (iRenderMode == kRenderTransAlpha)
		return -1;

	static iGlassDecalId; if (!iGlassDecalId) iGlassDecalId = engfunc(EngFunc_DecalIndex, "{bproof1");
	if (iRenderMode != kRenderNormal)
		return iGlassDecalId;

	static iShotDecalId; if (!iShotDecalId) iShotDecalId = engfunc(EngFunc_DecalIndex, "{shot1");
	return (iShotDecalId - random_num(0, 4));
}

stock Do_Damage(const clientIndex, const Float:Damage_Range, const Float:Damage, const Float:Point_Dis, const Float:Knockback, const Float:KnockUp, const Float:Painshock)
{
    new Hit_Type, KnifeEntityID, Float:vOwnerPosition[3], Float:vVictimPosition[3], Float:vTargetPosition[3]; 
    Get_Position(clientIndex, 0.0, 0.0, 0.0, vOwnerPosition, Float:{0.0, 0.0, 0.0}, false, Float:{0.0, 0.0, 0.0}, false);
    KnifeEntityID = get_member(clientIndex , m_pActiveItem);
    for(new victimIndex = 1 ; victimIndex < MaxClients ; victimIndex++)
	{
		if( victimIndex == clientIndex)
			continue;
		if(!is_user_connected(victimIndex))
			continue;
		if(!rg_is_player_can_takedamage(victimIndex, clientIndex))
			continue;
		Get_Position(victimIndex, 0.0, 0.0, 0.0, vVictimPosition, Float:{0.0, 0.0, 0.0}, false, Float:{0.0, 0.0, 0.0}, false);
		if(get_distance_f(vOwnerPosition, vVictimPosition) > Damage_Range)
			continue;
		if(!Compare_Target_And_Entity_Angle(clientIndex, victimIndex, Point_Dis))
			continue;
		if(!Can_See(clientIndex, victimIndex))
			continue;

		if(!Hit_Type) Hit_Type = HIT_ENEMY; 

		if(Damage > 0.0) FakeTraceAttack(clientIndex, victimIndex, KnifeEntityID, Damage, DMG_BULLET);
		if(Painshock > 0.0) set_member(victimIndex , m_flVelocityModifier , Painshock)
		if(Knockback > 0.0 || KnockUp > 0.0) Hook_Entity(victimIndex, vOwnerPosition, Knockback, KnockUp, true);	
	}

    new Find_E = -1

    while((Find_E = rg_find_ent_by_class(Find_E, "hostage_entity")) > 0){
    	if(get_entvar(Find_E, var_takedamage) == DAMAGE_NO || get_entvar(Find_E,var_deadflag) == DEAD_DEAD)
    		continue;
    	
    	Get_Position(Find_E, 0.0, 0.0, 0.0, vVictimPosition, Float:{0.0, 0.0, 0.0}, false, Float:{0.0, 0.0, 0.0}, false)
    	if(get_distance_f(vOwnerPosition, vVictimPosition) > Damage_Range)
    		continue;
    	if(!Compare_Target_And_Entity_Angle(clientIndex, Find_E, Point_Dis))
    		continue;
    	if(!Can_See(clientIndex, Find_E))
    		continue;
    	if(!Hit_Type) Hit_Type = HIT_ENEMY; 

    	if(Damage > 0.0) FakeTraceAttack(clientIndex, Find_E, KnifeEntityID, Damage, DMG_BULLET);
    	if(Painshock > 0.0) set_pdata_float(Find_E, 108, Painshock, 5);
    	if(Knockback > 0.0 || KnockUp > 0.0) Hook_Entity(Find_E, vOwnerPosition, Knockback, KnockUp, true);	
    }

    Get_Position(clientIndex, Damage_Range, 0.0, 0.0, vTargetPosition, Float:{0.0, 0.0, 0.0}, false, vOwnerPosition, true);
    engfunc(EngFunc_TraceLine, vOwnerPosition, vTargetPosition, DONT_IGNORE_MONSTERS, clientIndex, 0);
    new Enemy = get_tr2(0, TR_pHit); 
    if(!is_nullent(Enemy) && get_entvar(Enemy, var_takedamage) == DAMAGE_YES)
    {
    	if(!Hit_Type) Hit_Type = HIT_ENEMY; 
    	ExecuteHamB(Ham_TakeDamage, Enemy, KnifeEntityID, clientIndex, Damage, DMG_SLASH);
    } else if(!Hit_Type) {
    	new Float:End_Origin[3]; get_tr2(0, TR_vecEndPos, End_Origin);
    	if(floatround(get_distance_f(vTargetPosition, End_Origin)) && !is_user_alive(Enemy)) Hit_Type = HIT_WALL; 
    }

    return Hit_Type;
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

stock Get_Position(const iEntityIndex, const Float:fForwardAdd, const Float:fRightAdd, const Float:fUpAdd, Float:vPosition[3], const Float:vCustomAngle[3], const bool:WorkCustomAngle, const Float:vCustomOrigin[3], const bool:WorkCustomOrigin)
{
	static Float:vEntityAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3];
	
	if(WorkCustomOrigin) {
		vPosition = vCustomOrigin;
	} else {
		get_entvar(iEntityIndex, var_origin, vPosition);
		get_entvar(iEntityIndex, var_view_ofs, vUp);
		xs_vec_add(vPosition, vUp, vPosition);
	}
	
	if(!WorkCustomAngle)
	{
		if(iEntityIndex > MAX_PLAYERS) get_entvar(iEntityIndex, var_angles, vEntityAngle);
		else get_entvar(iEntityIndex, var_v_angle, vEntityAngle);
	} else {
		vEntityAngle = vCustomAngle;
	}

	if(fForwardAdd != 0.0) angle_vector(vEntityAngle, ANGLEVECTOR_FORWARD, vForward);
	if(fRightAdd != 0.0) angle_vector(vEntityAngle, ANGLEVECTOR_RIGHT, vRight);
	if(fUpAdd != 0.0) angle_vector(vEntityAngle, ANGLEVECTOR_UP, vUp);
	
	vPosition[0] += vForward[0] * fForwardAdd + vRight[0] * fRightAdd + vUp[0] * fUpAdd;
	vPosition[1] += vForward[1] * fForwardAdd + vRight[1] * fRightAdd + vUp[1] * fUpAdd;
	vPosition[2] += vForward[2] * fForwardAdd + vRight[2] * fRightAdd + vUp[2] * fUpAdd;
}    

stock bool:Can_See(const clientIndex, const targetIndex)
{
	new flags = get_entvar(clientIndex, var_flags);
	if (flags & EF_NODRAW || flags & FL_NOTARGET)
	{
		return false;
	}

	new Float:lookerOrig[3];
	new Float:targetBaseOrig[3];
	new Float:targetOrig[3];
	new Float:temp[3];

	get_entvar(clientIndex, var_origin, lookerOrig);
	get_entvar(clientIndex, var_view_ofs, temp);
	xs_vec_add(lookerOrig, temp, lookerOrig);

	get_entvar(targetIndex, var_origin, targetBaseOrig);
	get_entvar(targetIndex, var_view_ofs, temp);
	xs_vec_add(targetBaseOrig, temp, targetOrig);

	engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, IGNORE_MONSTERS, clientIndex, 0);
	if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
	{
		return false;
	} 
	else 
	{
		new Float:flFraction;
		get_tr2(0, TraceResult:TR_flFraction, flFraction);
		if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == targetIndex))
		{
			return true;
		}
		else
		{
			targetOrig = targetBaseOrig;
			engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, IGNORE_MONSTERS, clientIndex, 0); 
			get_tr2(0, TraceResult:TR_flFraction, flFraction);
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == targetIndex))
			{
				return true;
			}
			else
			{
				targetOrig = targetBaseOrig;
				targetOrig[2] -= 17.0;
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, IGNORE_MONSTERS, clientIndex, 0); 
				get_tr2(0, TraceResult:TR_flFraction, flFraction);
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == targetIndex))
				{
					return true;
				}
			}
		}
	}
	return false;
}

stock bool:Compare_Target_And_Entity_Angle(const entityIndex, const targetIndex, const Float:ViewDis)
{
	new Float:Origin[3]; get_entvar(entityIndex, var_origin, Origin);
	new Float:Angles[3]; get_entvar(entityIndex, var_v_angle, Angles);
	new Float:Target[3]; get_entvar(targetIndex, var_origin, Target);
	new Float:Radians = floatatan2(Target[1] - Origin[1], Target[0] - Origin[0], radian);
	new Float:GoalAngles[3]; GoalAngles[1] = Radians * (180 / 3.14);
    	
	new Float:Distance = 180.0 - floatabs(floatabs(GoalAngles[1] - Angles[1]) - 180.0);
	if(Distance <= ViewDis) return true;
	return false;
}

stock FakeTraceAttack(const iAttacker, const iVictim, const iInflictor, Float:fDamage, const iDamageType)
{
	new iTarget, iHitGroup = HIT_GENERIC; 
	new Float:vAttackerAngle[3]; get_entvar(iAttacker, var_v_angle, vAttackerAngle);
	new Float:vAttackerOrigin[3]; Get_Position(iAttacker, 0.0, 0.0, 0.0, vAttackerOrigin, vAttackerAngle, true, Float:{0.0, 0.0, 0.0}, false);
	new Float:vTargetOrigin[3]; Get_Position(iAttacker, 8192.0, 0.0, 0.0, vTargetOrigin, vAttackerAngle, true, vAttackerOrigin, true);

	engfunc(EngFunc_TraceLine, vAttackerOrigin, vTargetOrigin, DONT_IGNORE_MONSTERS, iAttacker, 0); 

	iTarget = get_tr2(0, TR_pHit);
	iHitGroup = get_tr2(0, TR_iHitgroup);
	get_tr2(0, TR_vecEndPos, vTargetOrigin);

	if(iTarget != iVictim) 
	{
		iTarget = iVictim;
		iHitGroup = HIT_STOMACH;
		get_entvar(iVictim, var_origin, vTargetOrigin);
	}

	fDamage *= Damage_Multiplier(iHitGroup);
	if(!Compare_Target_And_Entity_Angle(iTarget, iAttacker, 90.0)) fDamage *= 3.0;
	set_member(iTarget, m_LastHitGroup, iHitGroup);
	ExecuteHamB(Ham_TakeDamage, iTarget, iInflictor, iAttacker, fDamage, iDamageType);
}

stock Float:Damage_Multiplier(const iBody)
{
	new Float:X;
	switch (iBody)
	{
		case 1: X = 4.0;
		case 2: X = 2.0;
		case 3: X = 1.25;
		default: X = 1.0;
	}
	return X;
}

stock Spawn_Blood(const Float:Origin[3], const iBody, const iScale)
{
	new Blood_Scale;
	switch (iBody)
	{
		case HIT_HEAD: Blood_Scale = iScale+8; 
		case HIT_CHEST, HIT_STOMACH: Blood_Scale = iScale+3;
		default: Blood_Scale = iScale;
	}

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_short(iBloodPrecacheID[0]);
	write_short(iBloodPrecacheID[1]);
	write_byte(247);
	write_byte(Blood_Scale);
	message_end();
}    

stock Hook_Entity(const Entity, const Float:TargetOrigin[3], Float:Knockback, Float:KnockUp, bool:Mode)
{
	new Float:EntityOrigin[3];
	new Float:EntityVelocity[3];
	if(KnockUp == 0.0) get_entvar(Entity, var_velocity, EntityVelocity);
	get_entvar(Entity, var_origin, EntityOrigin);

	new Float:Distance; Distance = get_distance_f(EntityOrigin, TargetOrigin);
	new Float:Time; Time = Distance / Knockback;

	new Float:V1[3], Float:V2[3];
	if(Mode) V1 = EntityOrigin, V2 = TargetOrigin; // Konumdan İttirme 
	else V2 = EntityOrigin, V1 = TargetOrigin; // Konuma Çekme

	EntityVelocity[0] = (V1[0] - V2[0]) / Time;
	EntityVelocity[1] = (V1[1] - V2[1]) / Time;
	if(KnockUp > 0.0) EntityVelocity[2] = KnockUp;
	else if(KnockUp < 0.0) EntityVelocity[2] = (V1[2] - V2[2]) / Time;

	set_entvar(Entity, var_velocity, EntityVelocity);
}    