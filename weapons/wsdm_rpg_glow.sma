#include <amxmodx>
#include <cstrike>
#include <cswm>
#include <fakemeta>
#include <fakemeta_util>
#include <reapi>
#include <hamsandwich>
#include <engine_stocks>
#include <engine>
#include <vector>
#include <xs>

#include <kr_core>
#include <xp_module>

new const DAMAGE_ENTITY_NAME[] = "trigger_hurt"

#define AMXX_VERSION_STR "1.0"

#define m_pPlayer 41

// Rocket information
#define ROCKET_SPEED	1000		// Rocket fly speed
#define ROCKET_RADIUS	300.0	// Rocket explosion radius
#define ROCKET_DAMAGE	650.0	// Rocket explosion damage (in center)
#define REACTION_SPEED	0.0		// How fast the rocket should react
#define TRACK_SMOOTH 1.0       // 趋向目标的平滑程度

// Entity data
new ENTITY_NAME[] = "wpn_rpgrocket"

// Models
new P_MODEL[] = "models/p_rpg.mdl"
new V_MODEL[] = "models/v_rpg_glow.mdl"
new W_MODEL[] = "models/w_rpg.mdl"

// Rocket model and sound
new ROCKET_MDL[] = "models/rpgrocket.mdl"
new ROCKET_SOUND[] = "weapons/rocketfire1.wav"

new const ROCKET_TRAIL[][] = {{224, 224, 255}, {251, 0, 6}}

new Waeponid,g_Trail,g_Explosion,m_info_target

// new ishaveprg[33]

new weaponidmenu

#define cost 150.0

#define MaxClip 3

enum Rpg
{
	anim_idle,
	anim_fidget,
	anim_reload,
	anim_fire,
	anim_holster1,
	anim_draw1,
	anim_holster2,
	anim_draw2,
	anim_idle2,
	anim_fidget2
};

public plugin_init()
{
	new plid= register_plugin("WeaponTest", AMXX_VERSION_STR, "Bing")

    register_forward(FM_Touch, "m_Touch")

	register_clcmd("giverpg","Getrpg")

	// RegisterHam(Ham_AddPlayerItem, "player", "OnPlayerPickupWeapon", 1)

	weaponidmenu = BulidWeaponMenu("幽灵火箭筒", cost)

	BulidCrashGunWeapon("幽灵火箭筒", W_MODEL , "FreeGive", plid)
}

public ItemSel_Post(id, items, Float:cost1){
    if(items == weaponidmenu){
        Getrpg(id)
    }
}

public FreeGive(id){
	new Wpn = GiveWeaponByID(id, Waeponid)
}

public Getrpg(id){
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
    SubAmmoPak(id , cost)
	FreeGive(id)
}

// public OnPlayerPickupWeapon(id, item){
// 	new classname[32]
// 	if(!pev_valid(item))
// 		return
// 	get_entvar(item, var_classname, classname, charsmax(classname))
// 	if(!equal(classname , ENTITY_NAME))return
// 	ishaveprg[id] = 1
// }

public CreateWeaponFunc(){

   Waeponid = CreateWeapon("rpg",2, ENTITY_NAME)
   BuildWeaponModels(Waeponid,V_MODEL,P_MODEL,W_MODEL)
   new ammo = CreateAmmo(30,5,30)
   SetAmmoName(ammo,"Rocket")
   BuildWeaponDeploy(Waeponid, anim_idle, 1.0)
   BuildWeaponMaxSpeed(Waeponid , 215.0)
   BuildWeaponFlags(Waeponid, WFlag_NoHUD)
   BuildWeaponReload(Waeponid, anim_reload, 61.0 / 30.0)
   BuildWeaponFireSound(Waeponid, ROCKET_SOUND)
   BuildWeaponAmmunition(Waeponid, MaxClip , ammo)
   BuildWeaponPrimaryAttack(Waeponid, 1.5, 0.0, 0.0, anim_fire)
   RegisterWeaponForward(Waeponid, WForward_PrimaryAttackPre, "PrimaryAttackPre")
   RegisterWeaponForward(Waeponid, WForward_PrimaryAttackPrePost, "PrimaryAttackPost")
   RegisterWeaponForward(Waeponid, WForward_DeployPost, "DeployPost")
}

public plugin_precache(){
	
	precache_model(P_MODEL)
	precache_model(V_MODEL)
	precache_model(W_MODEL)
	
	precache_model(ROCKET_MDL)
	precache_sound(ROCKET_SOUND)
	
	g_Trail = precache_model("sprites/smoke.spr")
	g_Explosion = precache_model("sprites/zerogxplode.spr")

	m_info_target = engfunc(EngFunc_AllocString, "info_target")
	CreateWeaponFunc()
}

public DeployPost(EntityID){
    new id = get_pdata_cbase(EntityID, m_pPlayer)
    play_weapon_anim(id, anim_draw1)
	rg_set_iteminfo(EntityID , ItemInfo_iMaxClip , MaxClip)
}

public m_Touch(toucher, touched){
	new classname[32]
	if(!pev_valid(toucher))
		return FMRES_IGNORED
	get_entvar(toucher, var_classname, classname, sizeof(classname))
	if(!equal(classname , "Rpg_rock"))return FMRES_IGNORED
	
	
	static Float:fOrigin[3], iOrigin[3]
	pev(toucher, pev_origin, fOrigin)
			
	iOrigin[0] = floatround(fOrigin[0])
	iOrigin[1] = floatround(fOrigin[1])
	iOrigin[2] = floatround(fOrigin[2])

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin)
	write_byte(TE_EXPLOSION)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_short(g_Explosion)
	write_byte(30)
	write_byte(15)
	write_byte(0)
	message_end()

	new attacker = pev(toucher, pev_owner)
	
	rg_dmg_radius(fOrigin , attacker , attacker ,ROCKET_DAMAGE , 300.0 , CLASS_PLAYER , DMG_GENERIC)
	// rg_radius_damage(fOrigin, attacker, attacker, ROCKET_DAMAGE, 300.0, DMG_GENERIC)
	 //RadiusDamageEx(fOrigin,300.0,200.0,attacker,attacker,DMG_BLAST,RDFlag_Knockback)

	if(pev_valid(touched)){
		// Check if the touched entity is breakable, if so, break it :)
		pev(touched, pev_classname, classname, 31)
		if(equal(classname, "func_breakable"))
			dllfunc(DLLFunc_Use, touched, toucher)
	}
	set_entvar(toucher,	var_flags,FL_KILLME)
	return FMRES_IGNORED
}
public PrimaryAttackPre(EntityID){
	new id = get_pdata_cbase(EntityID, m_pPlayer);
	new Float:origin[3]
	get_position(id,20.0,20.0,-10.0,origin)
	CreateRpg(id,origin)
	get_position(id,20.0,-20.0,-10.0,origin)
	CreateRpg(id,origin)
	get_position(id,20.0,0.0,30.0,origin)
	CreateRpg(id,origin)

}

public PrimaryAttackPost(Wpn){
	set_member(Wpn , m_Weapon_flNextPrimaryAttack , 0.8)
}

public CreateRpg(ids , Float:Sp_Origin[3]){
	new id = ids
	new rocket = engfunc(EngFunc_CreateNamedEntity, m_info_target)
	if(!rocket || !is_valid_ent(rocket))
		return PLUGIN_CONTINUE
	set_pev(rocket , pev_classname , "Rpg_rock")
	engfunc(EngFunc_SetModel, rocket, ROCKET_MDL)

	set_pev(rocket , pev_movetype , MOVETYPE_FLY)
	set_entvar(rocket, var_owner, id)
	//entity_set_edict(rocket , EV_ENT_owner , id)
	
	set_pev(rocket, pev_solid, SOLID_BBOX)

	set_pev(rocket, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(rocket, pev_maxs, Float:{1.0, 1.0, 1.0})

	new Float:fAngles[3], Float:fOrigin[3]
	// get_entvar(id , var_v_angle, fAngles)
	pev(id , pev_v_angle,fAngles)
	fAngles[0] *= -1.0
	// Set the origin and view
	set_pev(rocket, pev_origin, Sp_Origin)
	set_pev(rocket, pev_angles, fAngles)
	set_pev(rocket, pev_v_angle, fAngles)

	SetThink(rocket, "Rockthink")
	set_pev(rocket , pev_nextthink , get_gametime()+0.1)

	new Float:fVel[3]
	velocity_by_aim(id, ROCKET_SPEED, fVel)	
	set_pev(rocket, pev_velocity, fVel)
	// Add trail
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)	// Temp entity type
	write_short(rocket)		// entity
	write_short(g_Trail)	// sprite index
	write_byte(25)	// life time in 0.1's
	write_byte(5)	// line width in 0.1's
	write_byte(ROCKET_TRAIL[0][0])	// red (RGB)
	write_byte(ROCKET_TRAIL[0][1])	// green (RGB)
	write_byte(ROCKET_TRAIL[0][2])	// blue (RGB)
	write_byte(255)	// brightness 0 invisible, 255 visible
	message_end()
	
	// Play fire sound
	emit_sound(rocket, CHAN_WEAPON, ROCKET_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)
	return rocket
}




public Rockthink(ent){
	if(is_nullent(ent))return

	new attacker = get_entvar(ent, var_owner)
	if(!is_user_alive(attacker)){
		engfunc(EngFunc_RemoveEntity , ent)
		return;
	}
	new target = Find_near_ent(ent)
	if(target <= 0){
		set_entvar(ent, var_nextthink, get_gametime() + 0.05)
		return
	}
		
	new Float:vel[3],Float:org[3],Float:targetorg[3],Float:dir[3]
	get_entvar(ent, var_velocity, vel)
	get_entvar(ent, var_origin, org)
	get_entvar(target, var_origin, targetorg)
	targetorg[2] += 30.0

	xs_vec_sub(targetorg, org, dir)
	xs_vec_normalize(dir, dir)

	// 当前速度转为单位方向
    new Float:curdir[3]
    xs_vec_normalize(vel, curdir)

	new Float:newdir[3]
	xs_vec_lerp(curdir, dir, TRACK_SMOOTH, newdir)
	xs_vec_normalize(newdir, newdir)

	

	new Float:new_vel[3]
	xs_vec_mul_scalar(newdir, float(ROCKET_SPEED), new_vel)
	set_entvar(ent, var_velocity, new_vel)

	set_entvar(ent, var_nextthink, get_gametime() + floatround(0.1,0.3))
}

public Find_near_ent(id){
	new Float:min_dist = ROCKET_RADIUS + 1000.0
	new ent = NULLENT
	new retv = NULLENT
	new Float:org[3]
	get_entvar(id, var_origin, org)
	while(ent = find_ent_by_class(ent , "hostage_entity")){
		if(get_entvar(ent, var_takedamage) == DAMAGE_NO || get_entvar(ent, var_deadflag) == DEAD_DEAD)
			continue
		if(KrGetFakeTeam(ent) == CS_TEAM_T)
			continue
		new Float:target_org[3]
		get_entvar(ent, var_origin, target_org)
		new Float:hitorigin[3]
		new hitent = fm_trace_line(id, org, target_org, hitorigin)
		if(hitent != ent)
			continue
		new Float:dist= vector_distance(org, target_org)
		if(dist < min_dist){
			min_dist = dist
			retv = ent
		}
	}

	return retv
}

public play_weapon_anim(id, numara)
{
    set_entvar(id, var_weaponanim, numara);
    message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
    write_byte(numara)
    write_byte(get_entvar(id, var_body))
    message_end()
}
/*
 * radius_damage - ��һ���뾶��Χ�ڵ�����ʵ����ɱ�ը�˺�
 * 
 * @origin     ��ը���ĵ����� (float���飬����3)
 * @attacker   �˺�������ʵ����������һ�ʵ�壩
 * @inflictor  �˺���Դʵ��������ͨ���Ǳ�ըʵ�壩
 * @damage     ��ը����˺�ֵ����������Խ�����˺�Խ�ߣ�
 * @radius     ��ը�뾶�������÷�Χʵ�岻���˺�
 * @dmg_bits   �˺����ͱ�־��ͨ��Ϊ DMG_BLAST
 * 
 * ˵����
 * - ��������ұ�ը����һ���뾶�ڵ�����ʵ�塣
 * - ����ʵ���뱬ը���ĵľ��룬����ݼ��˺�������ԽԶ���˺�ԽС����
 * - ��ÿ������������ʵ����� `TakeDamage`��ʵ�ֱ�ը�˺���
 */
stock rg_radius_damage(const Float:origin[3], attacker, inflictor, Float:damage, Float:radius, dmg_bits)
{
    new ent = -1
    new Float:target_origin[3]
    new Float:distance
    new Float:final_damage
	new Float:Origin_[3]
	new Float:Heal;
	//server_print("%f %f %f rg_radius_damage in put" , origin[0],origin[1],origin[2]);
	// get_entvar(inflictor, var_origin, Origin_)

    while ((ent = find_ent_in_sphere(ent, origin, radius)) != 0)
    {
        if (!is_valid_ent(ent)) continue
		if(pev(ent,pev_takedamage) == DAMAGE_NO) continue

		new deadflag
		pev(ent , pev_deadflag,deadflag)
		
		if(deadflag != DEAD_NO) continue

        get_entvar(ent, var_origin, target_origin)
        distance = vector_distance(origin, target_origin)

        // ���Եݼ��˺���ԽԶԽ�ͣ�
        final_damage = damage * (1.0 - (distance / radius))
        if (final_damage <= 0.0) continue;

		if(ent == attacker) continue;

		if(is_user_alive(ent) && cs_get_user_team(ent) == cs_get_user_team(attacker))continue;

		get_entvar(ent , var_health , Heal);

		new kill = Heal - final_damage;
		set_pev(ent, pev_dmg_inflictor, attacker)
		ExecuteHamB(Ham_TakeDamage, ent, inflictor, attacker, final_damage, dmg_bits)
    }
}


stock xs_vec_lerp(const Float:a[3], const Float:b[3], Float:factor, Float:out[3]) {
    for (new i = 0; i < 3; i++) {
        out[i] = a[i] + (b[i] - a[i]) * factor
    }
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

fake_damage(attacker, victim, Float:takedamage, damagetype)
{
	// Used quite often :D
	static entity, temp[16], wpnname[64]
	
	entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, DAMAGE_ENTITY_NAME))
	if (entity)
	{
		// Set the damage inflictor
		set_pev(victim, pev_dmg_inflictor, attacker)
		
		// Takedamages only do half damage per attack (damage is damage per second, and it's triggered in 0.5 second intervals).
		// Compensate for that.
		formatex(temp, 15, "%f", takedamage*2)
		set_keyvalue(entity, "dmg", temp, DAMAGE_ENTITY_NAME)
		
		formatex(temp, 15, "%i", damagetype)
		set_keyvalue(entity, "damagetype", temp, DAMAGE_ENTITY_NAME)
		
		set_keyvalue(entity, "origin", "8192 8192 8192", DAMAGE_ENTITY_NAME)
		dllfunc(DLLFunc_Spawn, entity)
		
		// set_pev(entity, pev_classname, wpnname)
		set_pev(entity, pev_owner, attacker)
		dllfunc(DLLFunc_Touch, entity, victim)
		set_pev(entity, pev_flags, FL_KILLME)
		
		// Make sure the damage inflictor is not overwritten by the entity
		set_pev(victim, pev_dmg_inflictor, attacker)
		
		return 1
	}
	
	return 0
}

public set_keyvalue(entity, key[], data[], const classname[])
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, data)
	set_kvd(0, KV_fHandled, 0)
	dllfunc(DLLFunc_KeyValue, entity, 0)
}
