#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <cswm>
#include <reapi>
#include <cstrike>
#include <xs>
#include <xp_module>
#include <kr_core>

#pragma semicolon 1
#pragma compress 1
#define m_pPlayer 41
#define cost 0.1
const Float:OICW_ShootDelay = 3.0;
new Projectile_OICW;

new String:Weapon_sound[5][64] = {
    "weapons/oicw_move_grenade.wav", 
    "weapons/oicw_move_carbine.wav", 
    "weapons/oicw_foley3.wav", 
    "weapons/oicw_foley2.wav", 
    "weapons/oicw_foley1.wav"
};
new Weaponid,g_Trail;
new weaponidmenu;

public plugin_init()
{
	new plid = register_plugin("[Weapon] Rifle OICW", "1.6", "Ghost");
    weaponidmenu = BulidWeaponMenu("尖端勇士OICW", cost);
    BulidCrashGunWeapon("尖端勇士OICW", "models/CSWM/OICW/W.mdl" , "FreeGive", plid);
}

public FreeGive(id){
    GiveWeaponByID(id, Weaponid);
}

public ItemSel_Post(id, items, Float:cost1){
    if(items == weaponidmenu){
        GiveWpn(id);
    }
}

public GiveWpn(id){
    new Float:ammopak = GetAmmoPak(id);
    if(ammopak < cost){
        m_print_color(id , "!g[冰桑提示] 您的大洋不足以购买");
        return;
    }
    SetAmmo(id , ammopak - cost);
    GiveWeaponByID(id, Weaponid);
}

public plugin_precache()
{
    // ��������
    Weaponid = CreateWeapon("oicw", Rifle, "OICW");

    // ����ģ��
    BuildWeaponModels(Weaponid, "models/CSWM/OICW/V.mdl", "models/CSWM/OICW/P.mdl", "models/CSWM/OICW/W.mdl");

    // ���������Ĳ���ʱ�䡢���������ص�
    BuildWeaponDeploy(Weaponid, 5, 37.0 / 30);
    BuildWeaponPrimaryAttack(Weaponid, 0.09, 1.1, 0.6);
    BuildWeaponReload(Weaponid, 4, 101.0 / 30);
    BuildWeaponFireSound(Weaponid, "weapons/oicw-1.wav");
    BuildWeaponAmmunition(Weaponid, 30, Ammo_556Nato);

    // �����������б�
    BuildWeaponList(Weaponid, "weapon_oicw");

    // ���ø���������
    // BuildWeaponSecondaryAttack(Weapon, A2_Switch, 9, 40.0 / 30, 10, 40.0 / 30, 6, 0, 0.0, 0, 0.0, 0, 0.0, 0.0, 0.0, 0.0, "weapons/oicw_grenade_shoot1.wav");
	BuildWeaponSecondaryAttack(Weaponid, A2_Switch,
    9, 1.33,  // �л���ģʽA����Ϊ9��ʱ��1.33��
    10, 1.33, // �л���ģʽB����Ϊ10��ʱ��1.33��
    6,        // idle����
    0, 0.0,   // draw��������ʱ��
    0, 0.0,   // shoot��������ʱ��
    0, 0.0,   // reload��������ʱ��
    0.0,      // �л��ӳ�
    0.0,      // �л��˺�
    0.0,      // ������
    "weapons/oicw_grenade_shoot1.wav"  // ���ŵ�����
);

    // ����������־
    BuildWeaponFlags(Weaponid, WFlag_SwitchMode_NoText);

    // ע������ǰ��ص�
    RegisterWeaponForward(Weaponid, WForward_PrimaryAttackPre, "OICW_PrimaryAttackPre");
    RegisterWeaponForward(Weaponid, WForward_HolsterPost, "OICW_HolsterPost");

    // ������Ч��Դ
    for (new i = 0; i < 5; i++){
        precache_sound(Weapon_sound[i]);  // ���ӷֺţ�ȷ����ȷ
    }

    // ���ض������Դ
    precache_generic("sprites/CSWM/640hud7.spr");
    precache_generic("sprites/CSWM/640hud79.spr");

    g_Trail = precache_model("sprites/smoke.spr");

    // // ���������������б�
    // BuildWeaponList(Weaponid,"weapon_oicw");

    // ����Ͷ����
    Projectile_OICW = CreateProjectile("models/CSWM/OICW/S.mdl", 0.7, 1000.0, "OnOicwTouch", 2.5); // Ͷ���ﴴ��
}


public OICW_PrimaryAttackPre(EntityID)
{
    
	if (!GetWeaponEntityData(EntityID, WED_INA2))
		return CSWM_IGNORED;
	
	if (!CanPrimaryAttack(EntityID))
		return CSWM_SUPERCEDE;
	
	SetNextAttack(EntityID, OICW_ShootDelay, true);
	new ProjectileID = ShootProjectileContact(get_pdata_cbase(EntityID, m_pPlayer), Projectile_OICW);
	new Float:AVelocity[3];
	entity_get_vector(ProjectileID, EV_VEC_avelocity, AVelocity);
	AVelocity[0] = random_float(-100.0, -250.0);
	entity_set_vector(ProjectileID, EV_VEC_avelocity, AVelocity);
    entity_set_float(ProjectileID,EV_FL_friction,1.0);
	SendWeaponAnim(EntityID, 7);
	emit_sound(EntityID, CHAN_VOICE, "weapons/oicw_grenade_shoot1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	new args[1];
    args[0] = ProjectileID;
    set_task(2.5,"OICW_Projetile",0,args,1);//��ը

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);	// Temp entity type
	write_short(ProjectileID);		// entity
	write_short(g_Trail);	// sprite index
	write_byte(25);	// life time in 0.1's
	write_byte(5);	// line width in 0.1's
	write_byte(random_num(100,255));	// red (RGB)
	write_byte(random_num(100,255));	// green (RGB)
	write_byte(random_num(100,255));	// blue (RGB)
	write_byte(255);	// brightness 0 invisible, 255 visible
	message_end();
    
    return CSWM_SUPERCEDE;
}

public OICW_HolsterPost(EntityID)
{
	SetWeaponEntityData(EntityID, WED_INA2, 0);
}

public OICW_Projetile(args[])
{
    new EntityID = args[0];//��idΪCreateEnt����pvdate���������Ի�ȡ����

	entity_set_vector(EntityID, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
	
	new Float:Origin[3];

	entity_get_vector(EntityID, EV_VEC_origin, Origin);
    new player = pev(EntityID,pev_owner);
    rg_radius_damage(Origin,player,player,100.0,255.0,DMG_GENERIC);
	// RadiusDamageEx(Origin,256.0,100.0,player,player,DMG_GRENADE,RDFlag_Knockback | RDFlag_IgnoreSelf);
	CreateExplosion(Origin, 0);
	remove_entity(EntityID);
}

public OnOicwTouch(ter){
    //������Other��ײ��������
    if(is_valid_ent(ter)){
        new Float:vec[3],classname[32];
        new rendermode;
        get_entvar(ter,var_velocity,vec);
        new flags;
        get_entvar(ter,var_flags,flags);
        //�ڵ������
        if(flags & FL_ONGROUND){
            xs_vec_mul_scalar(vec,0.8,vec);
            set_entvar(ter,var_velocity,vec);
        }else{
            //��ײ���������ǵ���
            xs_vec_mul_scalar(vec,0.9,vec);
            set_entvar(ter,var_velocity,vec);
        }
    }
}

stock rg_radius_damage(const Float:origin[3], attacker, inflictor, Float:damage, Float:radius, dmg_bits)
{
    new ent = -1;
    new Float:target_origin[3];
    new Float:distance;
    new Float:final_damage;
	new Float:Origin_[3];
	new Float:Heal;
	// get_entvar(inflictor, var_origin, Origin_)

    while ((ent = find_ent_in_sphere(ent, origin, radius)) != 0)
    {
        if (!is_valid_ent(ent)) continue;
		if(pev(ent,pev_takedamage) == DAMAGE_NO) continue;

		new deadflag;
		pev(ent , pev_deadflag, deadflag);
		
		if(deadflag != DEAD_NO) continue;

        get_entvar(ent, var_origin, target_origin);
        distance = vector_distance(origin, target_origin);

        // ���Եݼ��˺���ԽԶԽ�ͣ�
        final_damage = damage * (1.0 - (distance / radius));
        if (final_damage <= 0.0) continue;

		if(ent == attacker) continue;

		if(is_user_alive(ent) && cs_get_user_team(ent) == cs_get_user_team(attacker))continue;

		get_entvar(ent , var_health , Heal);

		new kill = Heal - final_damage;
		set_pev(ent, pev_dmg_inflictor, attacker);
		ExecuteHamB(Ham_TakeDamage, ent, inflictor, attacker, final_damage, dmg_bits);
    }
}
