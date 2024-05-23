#include <extdll.h>

#include "angelscript.h"
#include "asext_api.h"
#include "angelscriptlib.h"

#include <meta_api.h>

#include "CPlayerMove.h"

#include <cfloat>

#ifndef DBL_MAX
#define DBL_MAX 2.2250738585072014e-308
#endif //!DBL_MAX

angelhook_t g_AngelHook;

uint32 SC_SERVER_DECL CASEngineFuncs_CRC32(void* pthis, SC_SERVER_DUMMYARG CString* szBuffer){
	CRC32_t crc;
	CRC32_INIT(&crc);
	CRC32_PROCESS_BUFFER(&crc, (void*)szBuffer->c_str(), szBuffer->length());
	return CRC32_FINAL(crc);
}

bool SC_SERVER_DECL CASEngineFuncs_ClassMemcpy(void* pthis, SC_SERVER_DUMMYARG void* _src, int srctypeid, void* _dst, int dsttypeid) {
	if (srctypeid != dsttypeid)
		return false;
	asIScriptObject* src = *static_cast<asIScriptObject**>(_src);
	asIScriptObject* dst = *static_cast<asIScriptObject**>(_dst);
	if (!src || !dst)
		return false;
	dst->CopyFrom(src);
	return true;
}

double SC_SERVER_DECL CASEngineFuncs_TimeDifference(void* _ThisInstance, SC_SERVER_DUMMYARG uint64_t _Start, uint64_t _End) {
	if (_End > _Start) {
		return (_End - _Start) / 1000.0;
	} else {
		return -((_Start - _End) / 1000.0);
	}
	
	return DBL_MIN;
}

template <typename T>
void RegisteRefObject(CASDocumentation* pASDoc, const char* szName) {
	asSFuncPtr reg;
	reg = asMETHOD(T, AddRef);
	ASEXT_RegisterObjectBehaviourEx(pASDoc, "AddRef", szName, asBEHAVE_ADDREF, "void AddRef()", &reg, asCALL_THISCALL);
	reg = asMETHOD(T, Release);
	ASEXT_RegisterObjectBehaviourEx(pASDoc, "Release", szName, asBEHAVE_RELEASE, "void Release()", &reg, asCALL_THISCALL);
}
template <typename T>
void RegisteGCObject(CASDocumentation* pASDoc, const char* szName) {
	RegisteRefObject<T>(pASDoc, szName);
	asSFuncPtr reg;
	reg = asMETHOD(T, SetGCFlag);
	ASEXT_RegisterObjectBehaviourEx(pASDoc, "Set GC Flag", szName, asBEHAVE_SETGCFLAG, "void SetGCFlag()", &reg, asCALL_THISCALL);
	reg = asMETHOD(T, GetGCFlag);
	ASEXT_RegisterObjectBehaviourEx(pASDoc, "Get GC Flag", szName, asBEHAVE_GETGCFLAG, "bool GetGCFlag() const", &reg, asCALL_THISCALL);
	reg = asMETHOD(T, GetRefCount);
	ASEXT_RegisterObjectBehaviourEx(pASDoc, "Get reference count", szName, asBEHAVE_GETREFCOUNT, "int GetRefCount() const", &reg, asCALL_THISCALL);
	reg = asMETHOD(T, EnumReferences);
	ASEXT_RegisterObjectBehaviourEx(pASDoc, "Enumerate references held by this class", szName, asBEHAVE_ENUMREFS, "void EnumReferences(int& in)", &reg, asCALL_THISCALL);
	reg = asMETHOD(T, ReleaseReferences);
	ASEXT_RegisterObjectBehaviourEx(pASDoc, "Release all references held by this class", szName, asBEHAVE_RELEASEREFS, "void ReleaseReferences(int& in)", &reg, asCALL_THISCALL);
}
/// <summary>
/// Regiter
/// </summary>
#define REGISTE_OBJMETHODEX(r, d, e, c, m, cc, mm, call) r=asMETHOD(cc,mm);ASEXT_RegisterObjectMethodEx(d,e,c,m,&r,call)
#define REGISTE_OBJMETHODPREX(r, d, e, c, m, cc, mm, pp, rr, call) r=asMETHODPR(cc,mm, pp, rr);ASEXT_RegisterObjectMethodEx(d,e,c,m,&r,call)
void RegisterAngelScriptMethods(){
	ASEXT_RegisterDocInitCallback([](CASDocumentation* pASDoc) {
		//Regist HealthInfo type
		ASEXT_RegisterObjectType(pASDoc, "Entity takehealth info", "HealthInfo", 0, asOBJ_REF | asOBJ_NOCOUNT);
		ASEXT_RegisterObjectProperty(pASDoc, "Who get healing?", "HealthInfo", "CBaseEntity@ pEntity", offsetof(healthinfo_t, pEntity));
		ASEXT_RegisterObjectProperty(pASDoc, "Recover amount.", "HealthInfo", "float flHealth", offsetof(healthinfo_t, flHealth));
		ASEXT_RegisterObjectProperty(pASDoc, "Recover dmg type.", "HealthInfo", "int bitsDamageType", offsetof(healthinfo_t, bitsDamageType));
		ASEXT_RegisterObjectProperty(pASDoc, "If health_cap is non-zero, won't add more than health_cap. Returns true if it took damage, false otherwise.", "HealthInfo", "int health_cap", offsetof(healthinfo_t, health_cap));
		//Class
		asSFuncPtr reg;
		ASEXT_RegisterObjectType(pASDoc, "User command", "CUserCmd", 0, asOBJ_REF | asOBJ_NOCOUNT);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get interpolation msec", "CUserCmd", "int16 GetLerpMsec()", CUserCmd, GetLerpMsec, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get duration of command (in msec)", "CUserCmd", "int8 GetMsec()", CUserCmd, GetMsec, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get viewangles", "CUserCmd", "Vector GetViewangles()", CUserCmd, GetViewangles, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get forwardmove", "CUserCmd", "float GetForwardMove()", CUserCmd, GetForwardMove, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get sidemove", "CUserCmd", "float GetSideMove()", CUserCmd, GetSideMove, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get upmove", "CUserCmd", "float GetUpMove()", CUserCmd, GetUpMove, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get lightlevel", "CUserCmd", "int8 GetLightLevel()", CUserCmd, GetLightlevel, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get buttons", "CUserCmd", "uint16 GetButtons()", CUserCmd, GetButtons, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get impulse", "CUserCmd", "int8 GetImpulse()", CUserCmd, GetImpulse, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get weaponselect", "CUserCmd", "int8 GetWeaponSelect()", CUserCmd, GetWeaponSelect, asCALL_THISCALL);

		ASEXT_RegisterObjectType(pASDoc, "Shared player move", "CPlayerMove", 0, asOBJ_REF | asOBJ_NOCOUNT);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get usercmd", "CPlayerMove", "CUserCmd@ GetUserCmd()", CPlayerMove, GetUserCmd, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get usercmd", "CPlayerMove", "int GetPlayerIndex()", CPlayerMove, GetPlayerIndex, asCALL_THISCALL);
		REGISTE_OBJMETHODEX(reg, pASDoc, "Get usercmd", "CPlayerMove", "uint64 GetEpochTimeMillis()", CPlayerMove, GetEpochTimeMillis, asCALL_THISCALL);

		ASEXT_RegisterObjectMethod(pASDoc, "Get time difference", "CEngineFuncs", "double TimeDifference(uint64 _Start, uint64 _End)", (void*)CASEngineFuncs_TimeDifference, asCALL_THISCALL);

		//Regist New Method
		ASEXT_RegisterObjectMethod(pASDoc,
			"Caculate CRC32 for a string", "CEngineFuncs", "uint32 CRC32(const string& in szBuffer)",
			(void*)CASEngineFuncs_CRC32, asCALL_THISCALL);
		ASEXT_RegisterObjectMethod(pASDoc,
			"copy class, If src and dst are different type, return false.\nIf not class ref, crash game.", "CEngineFuncs", "bool ClassMemcpy(?& in src, ?& in dst)",
			(void*)CASEngineFuncs_ClassMemcpy, asCALL_THISCALL);
	});
}
#undef REGISTE_OBJMETHODEX
#undef REGISTE_OBJMETHODPREX

#define CREATE_AS_HOOK(item, des, tag, name, arg) g_AngelHook.item=ASEXT_RegisterHook(des,StopMode_CALL_ALL,2,ASFlag_MapScript|ASFlag_Plugin,tag,name,arg)
void RegisterAngelScriptHooks(){
	CREATE_AS_HOOK(pPlayerUserInfoChanged, "Pre call before a player info changed", "Player", "PlayerUserInfoChanged", "CBasePlayer@ pClient, string szInfoBuffer, uint&out uiFlag");
	CREATE_AS_HOOK(pPlayerPostTakeDamage, "Pre call before a player took damage", "Player", "PlayerPostTakeDamage", "DamageInfo@ info");
	CREATE_AS_HOOK(pPlayerTakeHealth, "Pre call before a player took health", "Player", "PlayerTakeHealth", "HealthInfo@ info");
	CREATE_AS_HOOK(pPlayerCallMedic, "Pre call before a player call medic", "Player", "PlayerCallMedic", "CBasePlayer@ pPlayer");
	CREATE_AS_HOOK(pPlayerCallGrenade, "Pre call before a player call grenade", "Player", "PlayerCallGrenade", "CBasePlayer@ pPlayer");

	CREATE_AS_HOOK(pEntitySpawn, "Post call after a Entity spawn", "Entity", "EntitySpawn", "CBaseEntity@ pEntity");
	CREATE_AS_HOOK(pEntityIRelationship, "Pre call before checking relation", "Entity", "IRelationship", "CBaseEntity@ pEntity, CBaseEntity@ pOther, bool param, int& out newValue");

	CREATE_AS_HOOK(pMonsterSpawn, "Post call after a monster spawn", "Monster", "MonsterSpawn", "CBaseMonster@ pEntity");
	CREATE_AS_HOOK(pMonsterTraceAttack, "Pre call before a monster trace attack", "Monster", "MonsterTraceAttack", "CBaseMonster@ pMonster, entvars_t@ pevAttacker, float flDamage, Vector vecDir, const TraceResult& in ptr, int bitDamageType");
	CREATE_AS_HOOK(pMonsterTakeDamage, "Pre call before a monster took damage", "Monster", "MonsterTakeDamage", "DamageInfo@ info");
	CREATE_AS_HOOK(pMonsterPostTakeDamage, "Post call before a monster took damage", "Monster", "MonsterPostTakeDamage", "DamageInfo@ info");
	CREATE_AS_HOOK(pMonsterKilled, "Pre call before a monster died", "Monster", "MonsterKilled", "CBaseMonster@ pMonster, entvars_t@ pevAttacker, int iGib");

	CREATE_AS_HOOK(pBreakableTraceAttack, "Pre call before a breakable trace attack","Entity", "BreakableTraceAttack", "CBaseEntity@ pBreakable, entvars_t@ pevAttacker, float flDamage, Vector vecDir, const TraceResult& in ptr, int bitDamageType");
	CREATE_AS_HOOK(pBreakableKilled, "Pre call before a breakable died", "Entity", "BreakableDie", "CBaseEntity@ pBreakable, entvars_t@ pevAttacker, int iGib");
	CREATE_AS_HOOK(pBreakableTakeDamage, "Pre call before a breakable took damage", "Entity", "BreakableTakeDamage", "DamageInfo@ info");

	CREATE_AS_HOOK(pGrappleCheckMonsterType, "Pre call before Weapon Grapple checking monster type", "Weapon", "GrappleGetMonsterType", "CBaseEntity@ pThis, CBaseEntity@ pEntity, uint& out flag");
	CREATE_AS_HOOK(pSendScoreInfo, "Pre call before sending hud info to edict", "Player", "SendScoreInfo", "CBasePlayer@ pPlayer, edict_t@ pTarget, int iTeamID, string szTeamName, uint& out flag");
	CREATE_AS_HOOK(pClientExecutedCommand, "Called before a client executes a command.", "Player", "ClientCommand", "edict_t@ _Edict, uint& out _CancelOriginalCall");
	CREATE_AS_HOOK(pMessageBegin, "Called before a server message was sent to a client.", "Network", "MessageBegin", "int _MsgDestination, int _MsgType, Vector _Origin, edict_t@ _Edict, uint& out _CancelOriginalCall");
	CREATE_AS_HOOK(pPM_Move, "Called before PM_Move was called.", "Player", "PM_Move", "CPlayerMove@ _PlayerMove, int _Server, uint& out _CancelOriginalCall");
	CREATE_AS_HOOK(pPost_PM_Move, "Called after PM_Move was called.", "Player", "Post_PM_Move", "CPlayerMove@ _PlayerMove, int _Server");
}
#undef CREATE_AS_HOOK

void CloseAngelScriptsItem() {
}