#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <hamsandwich>
#include <fakemeta>
#include <kr_core>
#include <xp_module>


#define Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));

#define CLIP 50
#define Max_bpammo 200
#define WaeponIDs 10000
#define cost 0.1

#define V_MODEL "models/v_mp5_1.mdl"
#define W_MODEL "models/w_mp5_1.mdl"
#define P_MODEL "models/p_mp5_1.mdl"
#define DefWModule "models/w_mp5.mdl"

#define ssym "weapon_mp5navy"

new HasWaepon

new FW_OnFreeEntPrivateData

new Weaponid


public plugin_init(){
    new plid = register_plugin("速杀阴魔", "1.0", "Bing")
    RegisterHookChain(RG_CreateWeaponBox , "m_CreateWaeponBox_Post" , true)
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy , "m_DefaultDeploy")
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "m_AddPlayerItem")
    register_event("HLTV", "event_roundstart", "a", "1=0", "2=0")
    
    RegisterHam(Ham_TraceAttack,"player","m_TraceAttack")
    RegisterHam(Ham_TraceAttack,"hostage_entity","m_TraceAttack")
    register_clcmd("say /buy_ssym", "BuySSym")
    Weaponid = BulidWeaponMenu("速杀阴魔", cost)
    BulidCrashGunWeapon("速杀银魔", W_MODEL , "FreeGive", plid)
}

public plugin_precache(){
    precache_model(V_MODEL)
    precache_model(W_MODEL)
    precache_model(P_MODEL)
}

public client_disconnected(id){
    UnSet_BitVar(HasWaepon, id)
}

public ItemSel_Post(id, items, Float:cost1){
    if(items == Weaponid){
        BuySSym(id)
    }
}

public m_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits){
    if(!is_user_connected(Attacker)){
        return HAM_IGNORED
    }
    
    if(Get_BitVar(HasWaepon, Attacker) && get_user_weapon(Attacker) == CSW_MP5NAVY){
        SetHamParamFloat(3, Damage * 1.5)//速杀 1.5x
    }
}
public event_roundstart(){
    HasWaepon = 0
}

public OnEntityRemoved(const ent){
    new classname[32]
    get_entvar(ent, var_classname, classname, charsmax(classname))
    if(equal(classname, ssym)){
        new playerid = get_member(ent, m_pPlayer)
        if(is_nullent(playerid)){
            return
        }
        UnSet_BitVar(HasWaepon, playerid)
        rg_give_item(playerid, ssym)//发放源武器
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
    new wpn = get_member(owner, m_pActiveItem)
    if(equal(modelName , DefWModule) && Get_BitVar(HasWaepon , owner)){
        set_entvar(weaponent, var_impulse, WaeponIDs)
        UnSet_BitVar(HasWaepon, owner)
        engfunc(EngFunc_SetModel , weaponbox, W_MODEL)
    }
}

public m_DefaultDeploy(const this, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal){
    new classname[32]
    get_entvar(this, var_classname, classname, charsmax(classname))
    if(!equal(classname , ssym)){
        return
    }
    // new wpn = get_member(get_member(this, m_pPlayer), m_pActiveItem)
    new playerid = get_member(this, m_pPlayer)
    if(Get_BitVar(HasWaepon, playerid)){
        SetHookChainArg(2,ATYPE_STRING, V_MODEL)
        SetHookChainArg(3,ATYPE_STRING, P_MODEL)
    }
}

public m_AddPlayerItem (const this, const pItem){
    if(is_nullent(this)){
        return HC_CONTINUE
    }
    if(get_entvar(pItem,var_impulse) == WaeponIDs){
        Set_BitVar(HasWaepon, this)
        set_entvar(pItem, var_impulse, 0)
        FW_OnFreeEntPrivateData = register_forward(FM_OnFreeEntPrivateData, "OnEntityRemoved", false)
    }
    return HC_CONTINUE
}

public FreeGive(id){
    new wpn = rg_give_custom_item(id , ssym , GT_DROP_AND_REPLACE, WaeponIDs)
    Set_BitVar(HasWaepon, id)
    rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
    rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
    set_member(wpn, m_Weapon_iClip, CLIP)
    rg_set_user_bpammo(id,WEAPON_MP5N,Max_bpammo)
    client_print(id, print_center, "购买成功！攻击力+1.5倍")
}

public BuySSym(id){
    if(access(id ,ADMIN_KICK)){
        //管理员直接获取
        goto GetWpn
    }
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
GetWpn:
    new wpn = rg_give_custom_item(id , ssym , GT_DROP_AND_REPLACE, WaeponIDs)
    Set_BitVar(HasWaepon, id)
    rg_set_iteminfo(wpn,ItemInfo_iMaxClip, CLIP)
    rg_set_iteminfo(wpn, ItemInfo_iMaxAmmo1, Max_bpammo)
    set_member(wpn, m_Weapon_iClip, CLIP)
    rg_set_user_bpammo(id,WEAPON_MP5N,Max_bpammo)
    client_print(id, print_center, "购买成功！攻击力+1.5倍")
}
