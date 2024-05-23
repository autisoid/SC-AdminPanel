/*
    xWhitey's Admin Panel (Sven Co-op) source file
    Authors of the code: xWhitey, wootguy (some help, got it at Discord.), Sven Co-op community (/incognico/ "Nico", "twilightzone server" scripts, and of course KernCore for his BuyMenu!).
    Big thanks are related to Zode's AFBase (https://github.com/Zode/AFBase) for its "entmover", also its code showed me how to colorize titles and items of a CCustomTextMenu.
    Special thanks to: sushibanana, Mesa, kolokola777, frizzy, "777 GTA ONLINE LEVEL CHANGE 777", SV BOY, ilyadud21 "vorbis" and Scar for helping me with ideas of various functional!
    Special people, who assisted me with various code samples: ScriptedSnark, Troll338cz ("Use entity under crosshair" code)
    Feel free to PM me @ Discord: @tyabus if I forgot to mention somebody.
    Do not delete this comment block. Respect others' work!
*/

/*
    Some info about the code written here:
    I (xWhitey) used so called "Hungarian Notation" to write most of the code. If not so, this means I used some of code written by somebody OR my very old code.
    The code style used here is mixed: Plan9, re3's code style (GTA III reverse-engineered) and Java-like code style.
    The code written here made to be fastest as it can be. I (xWhitey) am not so good in AngelScript, so it may be a bit slow. (for e.g various loops, the server may lag if there's are many admins and somebody has opened adminpanel)
    Note: g_a_lpszAllowedSteamIDs containing five admins doesn't lag the server, so let's guess five admins is a good number to have.
*/

#include "CCustomTextMenu"

/* Global configuration variables */
//Note: the plugin is not meant to work if there are no admins in g_a_lpszAllowedSteamIDs.
array<string> g_a_lpszAllowedSteamIDs;

//01/11/2023 - Make some things in the menu available only for the server owner. ~ xWhitey
//Note!
string g_lpszTheOwner = "Make me valid!";

string g_lpszColorYellow = "\\y"; //We use that for titles, yellow color
string g_lpszColorRed = "\\r"; //We use that for coloring numbers before an item in a menu. (1:, 2: and so far). Red color
string g_lpszColorReset = "\\w"; //White color

bool g_bLoggingEnabled = false;
/* Global configuration variables end */

dictionary g_dictIPAddresses;
array<CBasePlayer@> g_a_lpBots;

/* Menus (declarations) */
string g_lpszMainMenu_Title = "Constantium's Admin Menu\n";
array<string> g_a_lpszMainMenuTaglines = { "Such tasty.", "Feeling horrible.", "Despair.", "Big boi.", "I do as I please.", 
    "Commit (suicide?)", ":D", "It's here!", "Kewl message OwO", "Get fascinated!", 
    "Huh, didn't guess anything clever here.", "Isn't this a dream, is it?", "That feeling of anarchy... Nah, it doesn't exist.", 
    "Hannahmontana.", "Fuck feds!", "shaza lala", "Poke.", "Let's do that quickly..." };
CCustomTextMenu@ g_lpMainMenu = null;

string g_lpszBotManagementMenu_Title = "Bot management";
string g_lpszBotManagementMenu_CreateBot = "Create bot";
string g_lpszBotManagementMenu_RemoveBot = "Remove bot";
CCustomTextMenu@ g_lpBotManagementMenu = null;
CCustomTextMenu@ g_lpBotManagementMenu_RemoveBot = null;

string g_lpszPlayerManagementMenu_Title = "Player management";

string g_lpszPlayerManagementMenu_KickPlayers = "Kick player(s)";
string g_lpszPlayerManagementMenu_KickPlayers_KickSpecifiedPlayer = "Kick specified player";
string g_lpszPlayerManagementMenu_KickPlayers_KickEveryPlayer = "Kick every player";

string g_lpszPlayerManagementMenu_FreezePlayers = "Freeze/unfreeze player(s)";
string g_lpszPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayer = "Freeze/unfreeze specified player";
string g_lpszPlayerManagementMenu_FreezePlayers_FreezeEveryPlayer = "Freeze/unfreeze every player";

string g_lpszPlayerManagementMenu_BanPlayers = "Ban player(s)";
string g_lpszPlayerManagementMenu_BanPlayers_BanSpecifiedPlayer = "Ban specified player";
string g_lpszPlayerManagementMenu_BanPlayers_BanEveryPlayer = "Ban every player";

string g_lpszPlayerManagementMenu_GiveHealth = "Give health";
string g_lpszPlayerManagementMenu_GiveArmor = "Give armor";
string g_lpszPlayerManagementMenu_GiveScore = "Give score";
string g_lpszPlayerManagementMenu_GiveSth_ChooseMode = "Choose mode";
string g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Add = "Add";
string g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Set = "Set";
string g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Presets = "Presets";
CCustomTextMenu@ g_lpPlayerManagementMenu = null;
CCustomTextMenu@ g_lpPlayerManagementMenu_GiveSth = null;
CCustomTextMenu@ g_lpPlayerManagementMenu_GiveSth_ChooseMode = null;
CCustomTextMenu@ g_lpPlayerManagementMenu_GiveSth_Presets = null;

CCustomTextMenu@ g_lpPlayerManagementMenu_FreezePlayersMenu = null;
CCustomTextMenu@ g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu = null;

//Available only for server owner.
CCustomTextMenu@ g_lpPlayerManagementMenu_BanPlayersMenu = null;
CCustomTextMenu@ g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu = null;
CCustomTextMenu@ g_lpPlayerManagementMenu_KickPlayersMenu = null;
CCustomTextMenu@ g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu = null;

enum EListeningMode {
    kNone = -1,
    kExplosion,
    kFakeNickname,
    kGivingSth,
    kSendingMessageAsAPlayer,
    kListeningForBanDuration,
    kListeningForReason,
    kListeningForKickReason,
    kListeningForBotName,
    kListeningForGravityValue,
    kListeningForTargetname,
    kListeningForClassname,
    kAllyExplosion,
    kSettingSizeOfSth
}

//Cheats stuff
class CConstantCheatConsumer {
    EHandle m_hTheConsumer;
    bool m_bNoclip = false;
    bool m_bSpeedhack = false;
    float m_flGravity = 1.0f;
    
    CConstantCheatConsumer() {}
    
    CConstantCheatConsumer(EHandle _Consumer) {
        m_hTheConsumer = _Consumer;
        m_bNoclip = false;
        m_flGravity = 1.0f;
    }

    bool CanCheatsBeApplied() {
        if (m_hTheConsumer) {
            CBaseEntity@ ent = m_hTheConsumer;
            return ent.IsAlive() && (m_bNoclip || m_bSpeedhack || m_flGravity != 1.0f);
        }
        
        return false;
    }
}

array<CConstantCheatConsumer@> g_alpConstantCheatConsumers;

class CAdminEntityMoverData {
    bool m_bHoldingFirstAttack;
    bool m_bHoldingSecondAttack;
    string m_lpszPreviousWeapon;
    
    CAdminEntityMoverData() {
        m_bHoldingFirstAttack = false;
        m_bHoldingSecondAttack = false;
        m_lpszPreviousWeapon = "";
    }
}

CScheduledFunction@ g_lpfnEntMoverImpl_EntThink = null;

enum EGivingSthTitle {
    kInvalidTitle = 0,
    kGiveHealth,
    kGiveArmor,
    kGiveScore
}

enum EGiveSthMode {
    kInvalid = -1,
    kAdd,
    kSet
}

class CAdminData {
    string m_lpszSteamID = "";
    bool m_bListeningForValueInChat = false;
    EHandle m_hCurrentVictim;
    EListeningMode m_eListeningMode = kNone;
    int m_iGiveSthValue = 0;
    array<EHandle> m_aSpawnedCheckpoints;
    string m_lpszPrefix = "";
    int m_iPrefixColor = -1;
    EHandle m_hTeleportVictim;
    EGivingSthTitle m_eGivingWhat;
    EGiveSthMode m_ePlayerMgmt_GiveSth_Mode = kInvalid;
    
    //Teleport stuff
    Vector m_vecSavedPosition = Vector(0.0f, 0.0f, 0.0f);
    EHandle m_hSavedEntity;
    
    //GodMode stuff
    bool m_bGodMode = false;
    
    //Ban stuff
    string m_lpszDuration = "";
    string m_lpszVictimSteamID = "";
    
    //EntMover stuff
    CAdminEntityMoverData@ m_lpEntityMoverData = null;
    
    //Mind Control
    bool m_bMindControllingSomebody = false;
    EHandle m_hMindControlVictim;
    
    CAdminData(const string& in _SteamID) {
        m_lpszSteamID = _SteamID;
        @m_lpEntityMoverData = CAdminEntityMoverData();
    }
}

EGivingSthTitle AP_UTIL_GiveSthModeToEnumValue(const string& in _Title) {
    if (_Title == g_lpszPlayerManagementMenu_GiveHealth)
        return kGiveHealth;
    else if (_Title == g_lpszPlayerManagementMenu_GiveArmor)
        return kGiveArmor;
    else if (_Title == g_lpszPlayerManagementMenu_GiveScore)
        return kGiveScore;
    
    return kInvalidTitle;
}

array<CAdminData@> g_a_lpAdmins;

CAdminData@ AP_UTIL_GetAdminDataBySteamID(const string& in _SteamID) {
    if (g_a_lpAdmins.length() == 0) return null; //save some computing powerz
    
    for (uint idx = 0; idx < g_a_lpAdmins.length(); idx++) {
        CAdminData@ theData = g_a_lpAdmins[idx];
        
        if (theData.m_lpszSteamID == _SteamID) return theData;
    }

    return null;
}

string g_lpszEntityManagementMenu_Title = "Entity management";
string g_lpszEntityManagementMenu_SpawnEntities = "Spawn entities";
string g_lpszEntityManagementMenu_SpawnEntities_ChooseRelationshipTitle = "Choose relationship";
string g_lpszEntityManagementMenu_SpawnEntities_SpawnAllies = "Spawn allies";
string g_lpszEntityManagementMenu_SpawnEntities_SpawnEnemies = "Spawn enemies";
string g_lpszEntityManagementMenu_DeleteEntities = "Delete entities";
string g_lpszEntityManagementMenu_UseEntityUnderCrosshair = "Use entity under crosshair";
string g_lpszEntityManagementMenu_DeleteEntitiesChooseCondition = "Choose condition";
string g_lpszEntityManagementMenu_DeleteEntitiesCondition1UnderCrosshair = "Condition 1 ~ Under crosshair";
string g_lpszEntityManagementMenu_DeleteEntitiesCondition2ByClassname = "Condition 2 ~ By classname";
string g_lpszEntityManagementMenu_CreateCheckpoint = "Create checkpoint";
string g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition = "Choose position";
string g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition_AtCamera = "At current position";
string g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition_AtCrosshair = "At crosshair";
string g_lpszEntityManagementMenu_ActivateLastCreatedCheckpoint = "Activate last created checkpoint";
string g_lpszEntityManagementMenu_CreateExplosionAtCrosshair = "Create explosion at crosshair";
string g_lpszEntityManagementMenu_CreateAllyExplosionAtCrosshair = "Create ally explosion at crosshair";

//Teleport stuff - 10/12/2023 - xWhitey.
string g_lpszEntityManagementMenu_Teleport_Title = "Teleport";
string g_lpszEntityManagementMenu_Teleport_SaveCurrentPosition = "Save current position";
string g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToCrosshair = "Teleport a player to crosshair";
string g_lpszEntityManagementMenu_Teleport_SaveEntityAtCrosshair = "Save entity at crosshair (to teleport it later)";
string g_lpszEntityManagementMenu_Teleport_TeleportSavedEntityToCrosshair = "Teleport saved entity to crosshair";
string g_lpszEntityManagementMenu_Teleport_TeleportSavedEntityToSavedPosition = "Teleport saved entity to saved position";
string g_lpszEntityManagementMenu_Teleport_TeleportYourselfToAPlayer = "Teleport yourself to a player";
string g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToAPlayer = "Teleport a player to a player";
string g_lpszEntityManagementMenu_UseEntityByTargetname_Title = "Use entity by targetname";
string g_lpszEntityManagementMenu_Teleport_TeleportAllEntitiesByClassnameToCurrentPosition = "Teleport all entities by classname to current position";

//Cheats menu - 02/11/2023 ~ xWhitey
string g_lpszCheatsMenu_Title = "Cheats menu";
string g_lpszCheatsMenu_ToggleNoclip = "Toggle noclip";
string g_lpszCheatsMenu_GiveSuit = "Give suit";
string g_lpszCheatsMenu_Impulse101 = "impulse 101";
string g_lpszCheatsMenu_GiveEverything = "Give everything";
string g_lpszCheatsMenu_InfiniteAmmo = "Infinite ammo";
CCustomTextMenu@ g_lpCheatsMenu = null;

array<string> g_a_lpszCheatsMenu_Impulse101Arms = {
    "weapon_crowbar",
    "weapon_9mmhandgun",
    "weapon_357",
    "weapon_9mmAR",
    "weapon_crossbow",
    "weapon_shotgun",
    "weapon_rpg",
    "weapon_gauss",
    "weapon_egon",
    "weapon_hornetgun",
    "weapon_uziakimbo",
    "weapon_medkit",
    "weapon_pipewrench",
    "weapon_grapple",
    "weapon_sniperrifle",
    "weapon_m249",
    "weapon_m16",
    "weapon_sporelauncher",
    "weapon_eagle",
    "weapon_displacer"
};

array<string> g_a_lpszCheatsMenu_GiveEverythingArms = {
    "weapon_crowbar",
    "weapon_9mmhandgun",
    "weapon_357",
    "weapon_9mmAR",
    "weapon_crossbow",
    "weapon_shotgun",
    "weapon_rpg",
    "weapon_gauss",
    "weapon_egon",
    "weapon_hornetgun",
    "weapon_handgrenade",
    "weapon_tripmine",
    "weapon_satchel",
    "weapon_snark",
    "weapon_uziakimbo",
    "weapon_medkit",
    "weapon_pipewrench",
    "weapon_grapple",
    "weapon_sniperrifle",
    "weapon_m249",
    "weapon_m16",
    "weapon_sporelauncher",
    "weapon_eagle",
    "weapon_displacer"
};

//Logging - 01/11/2023 ~ Alter Ego ~ xWhitey.
void AP_AlterEgo_Log(const string& in _Text, bool _Reserved = false) {
    if (!g_bLoggingEnabled) return;

    //if (_OwnerOnly) {
        for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
            CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex(idx);
            if (player is null or !player.IsConnected()) continue;
                
            string szSteamID = g_EngineFuncs.GetPlayerAuthId(player.edict());
            if (szSteamID == g_lpszTheOwner) {
                g_PlayerFuncs.SayText(player, "[AlterEgo] " + _Text + "\n");
                
                break;
            }
        }
    
        return;
    //}

    /*array<CBasePlayer@> aPlayersToBeNotified;
    for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
        CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex(idx);
        if (player is null or !player.IsConnected()) continue;
            
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(player.edict());
        if (AP_IsPlayerAllowedToOpenPanel(szSteamID)) aPlayersToBeNotified.insertLast(player);
    }

    for (uint idx = 0; idx < aPlayersToBeNotified.length(); idx++) {
        g_PlayerFuncs.SayText(aPlayersToBeNotified[idx], "[AlterEgo] " + _Text + "\n");
    }*/
}

/* Entity management ~ Spawn entities ~ Entity list */
array<EHandle> g_a_hAllyRobos;

class CSpawningEntitySubclass {
    string m_lpszName = "";
    int m_iWeapons = 1;
    int m_iSkin = 0;
    int m_iBody = -1;
    
    CSpawningEntitySubclass(const string& in _Name, int _Weapons) {
        m_lpszName = _Name;
        m_iWeapons = _Weapons;
    }
}
    
class CSpawningEntityData {
    string m_lpszEntityClassName = "";
    array<CSpawningEntitySubclass@> m_a_lpSubclasses;
    CCustomTextMenu@ m_lpSubSpawnMenu = null;
    bool m_bAlly = false;
    bool m_bForceAlly = false;
    bool m_bForceEnemy = false;
    
    CSpawningEntityData(const string& in _ClassName, bool _bForceAlly = false, bool _bForceEnemy = false) {
        m_lpszEntityClassName = _ClassName;
        AddSubclass("Default");
        m_bAlly = m_bForceAlly = _bForceAlly;
        m_bForceEnemy = _bForceEnemy;
    }
    
    void AddSubclass(const string& in _Name, int _Weapons = 1) {
        m_a_lpSubclasses.insertLast(CSpawningEntitySubclass(m_lpszEntityClassName + " ~ " + _Name, _Weapons));
    }
    
    void AddSubclassWithSkinAndBody(const string& in _Name, int _Weapons, int _Skin, int _Body) {
        CSpawningEntitySubclass@ subclass = CSpawningEntitySubclass(m_lpszEntityClassName + " ~ " + _Name, _Weapons);
        subclass.m_iSkin = _Skin;
        subclass.m_iBody = _Body;
        m_a_lpSubclasses.insertLast(@subclass);
    }
    
    CSpawningEntitySubclass@ GetSubclassByName(const string& in _Name) {
        for (uint idx = 0; idx < m_a_lpSubclasses.length(); idx++) {
            if (m_a_lpSubclasses[idx].m_lpszName == _Name) return m_a_lpSubclasses[idx];
        }
        
        return null;
    }
    
    void GenerateTextMenu() {
        if (m_lpSubSpawnMenu is null) {
            @m_lpSubSpawnMenu = CCustomTextMenu(g_tCustomTextMenuCB(this.SpawnCB));
            
            int count = 1;
            int page = 0;
        
            int iMaxEntriesPerPage = m_a_lpSubclasses.length() <= 9 ? 9 : 7;
                
            for (uint idx = 0; idx < m_a_lpSubclasses.length(); idx++) {
                string entry = m_a_lpSubclasses[idx].m_lpszName;
                if (count < iMaxEntriesPerPage) {
                    if (idx != m_a_lpSubclasses.length() - 1) {
                        m_lpSubSpawnMenu.AddItem((entry), any(page));
                    } else {
                        m_lpSubSpawnMenu.AddItem((entry), any(page));
                    }
                    count++;
                } else {
                    m_lpSubSpawnMenu.AddItem((entry), any(page));
                    count = 1;
                    page++;
                }
            }
            
            m_lpSubSpawnMenu.SetTitle(("Spawn " + m_lpszEntityClassName));
            
            m_lpSubSpawnMenu.Register();
        }
    }
    
    void SpawnCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
        if (_Item !is null) {
            string szChoice = (_Item.m_lpszText);
            int page;
            _Item.m_pUserData.retrieve(page);
            
            CSpawningEntitySubclass@ subclass = GetSubclassByName(szChoice);
            if (subclass is null) {
                g_PlayerFuncs.SayText(_Player, "[SM] [DEBUG] Something went wrong in SpawnCB of entity " + m_lpszEntityClassName + "\n");
            
                return;
            }
            
            Vector vecNewEntityPos = AP_UTIL_GetEyePosRayCastResult(_Player);
            CBaseEntity@ ent = g_EntityFuncs.Create(m_lpszEntityClassName, Vector(0, 0, 0), Vector(0, 0, 0), true, null);
            float yaw = _Player.pev.angles[1];
            float back = AP_UTIL_Degree2Radians(yaw - 180.0f);
            Vector newPos = Vector(vecNewEntityPos.x + cos(back) * 50.0f, vecNewEntityPos.y + sin(back) * 50.0f, vecNewEntityPos.z);
            vecNewEntityPos = newPos;
            Vector upwards = Vector(newPos.x, newPos.y, newPos.z + 35.0f);
            if (!AP_UTIL_IsPointSafe(upwards)) {
                vecNewEntityPos.z -= 75.0f;
            }
            Vector downwards = Vector(newPos.x, newPos.y, newPos.z - 35.0f);
            if (!AP_UTIL_IsPointSafe(downwards)) {
                vecNewEntityPos.z += 75.0f;
            }
            g_EntityFuncs.SetOrigin(ent, vecNewEntityPos);
            if (m_bAlly && !m_bForceEnemy) {
                ent.SetPlayerAlly(true);
                ent.SetPlayerAllyDirect(true);
            }
            if (m_bForceEnemy) {
                ent.SetPlayerAlly(false);
                ent.SetPlayerAllyDirect(false);
            }
            ent.pev.weapons = subclass.m_iWeapons;
            ent.pev.skin = subclass.m_iSkin;
            ent.pev.body = subclass.m_iBody;
            g_EntityFuncs.DispatchSpawn(ent.edict());
            if (m_bAlly && !m_bForceEnemy) { //just to be sure
                ent.SetPlayerAlly(true);
                ent.SetPlayerAllyDirect(true);
            }
            if (m_bForceEnemy) {
                ent.SetPlayerAlly(false);
                ent.SetPlayerAllyDirect(false);
            }
            g_EntityFuncs.DispatchKeyValue(ent.edict(), 'solid', 3); //NOTICE: Probably useless
            AP_AlterEgo_Log(string(_Player.pev.netname) + " has spawned a " + m_lpszEntityClassName + (ent.IsPlayerAlly() ? " (ally)" : " (enemy)"));
            if (m_lpszEntityClassName == "monster_robogrunt" and m_bAlly) g_a_hAllyRobos.insertLast(EHandle(ent));
            if (m_lpSubSpawnMenu !is null) {
                m_lpSubSpawnMenu.Open(0, page, _Player);
            }
        }
    }
}

array<CSpawningEntityData@> g_a_lpEntityManagementMenu_SpawnEntities_EntityList;
array<string> g_a_lpszEntityManagementMenu_SpawnEntities_NoExtrasEntityList = { "monster_barnacle", "monster_ichthyosaur", 
    "monster_snark", "monster_alien_grunt", "monster_pitdrone", "monster_zombie", "monster_gonome", "monster_apache", "monster_bigmomma", "monster_babygarg", 
    "monster_gargantua", "monster_kingpin", "monster_alien_voltigore", "monster_alien_slave", "monster_alien_tor", "monster_headcrab", "monster_alien_babyvoltigore",
    "monster_alien_controller", "monster_babycrab", "monster_blkop_osprey", "monster_blkop_apache", "monster_bodyguard", "monster_bullchicken",
    "monster_cleansuit_scientist", "monster_cockroach", "monster_gman", "monster_houndeye", "monster_human_assassin", "monster_hwgrunt", "monster_leech", 
    "monster_male_assassin", "monster_miniturret", "monster_osprey", "monster_rat", "monster_sentry", "monster_shockroach", "monster_shocktrooper",
    "monster_sqknest", "monster_stukabat", "monster_turret", "monster_zombie_barney", "monster_zombie_soldier" };

void AP_SpawnEntities_InitializeList() {
    CSpawningEntityData@ roboGrunt = null;
    @roboGrunt = CSpawningEntityData("monster_robogrunt");
    roboGrunt.AddSubclass("MP5 + HG", 3);
    roboGrunt.AddSubclass("MP5 with grenade launcher", 4);
    roboGrunt.AddSubclass("MP5 with grenade launcher + HG", 6);
    roboGrunt.AddSubclass("Shotgun", 8);
    roboGrunt.AddSubclass("Shotgun + HG", 10);
    roboGrunt.AddSubclass("RPG", 64);
    roboGrunt.AddSubclass("RPG + HG", 66);
    roboGrunt.AddSubclass("Sniper rifle", 128);
    roboGrunt.AddSubclass("Sniper rifle + HG", 130);
    roboGrunt.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@roboGrunt);
    
    CSpawningEntityData@ humanGrunt = null;
    @humanGrunt = CSpawningEntityData("monster_human_grunt");
    humanGrunt.AddSubclass("MP5 + HG", 3);
    humanGrunt.AddSubclass("MP5 with grenade launcher", 4);
    humanGrunt.AddSubclass("MP5 with grenade launcher + HG", 6);
    humanGrunt.AddSubclass("Shotgun", 8);
    humanGrunt.AddSubclass("Shotgun + HG", 10);
    humanGrunt.AddSubclass("RPG", 64);
    humanGrunt.AddSubclass("RPG + HG", 66);
    humanGrunt.AddSubclass("Sniper rifle", 128);
    humanGrunt.AddSubclass("Sniper rifle + HG", 130);
    humanGrunt.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@humanGrunt);
    
    CSpawningEntityData@ humanGruntAlly = null;
    @humanGruntAlly = CSpawningEntityData("monster_human_grunt_ally", true);
    humanGruntAlly.AddSubclass("None", 32);
    humanGruntAlly.AddSubclass("MP5 + HG", 3);
    humanGruntAlly.AddSubclass("MP5 with grenade launcher", 4);
    humanGruntAlly.AddSubclass("MP5 with grenade launcher + HG", 6);
    humanGruntAlly.AddSubclass("Shotgun", 8);
    humanGruntAlly.AddSubclass("Shotgun + HG", 10);
    humanGruntAlly.AddSubclass("SAW", 16);
    humanGruntAlly.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@humanGruntAlly);
    
    CSpawningEntityData@ humanMedicAlly = null;
    @humanMedicAlly = CSpawningEntityData("monster_human_medic_ally", true);
    humanMedicAlly.AddSubclass("None", 0);
    humanMedicAlly.AddSubclass("Desert Eagle", 1);
    humanMedicAlly.AddSubclass("9mm Handgun", 2);
    humanMedicAlly.AddSubclass("Hypodermic Needle", 4);
    humanMedicAlly.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@humanMedicAlly);
    
    CSpawningEntityData@ humanTorchAlly = null;
    @humanTorchAlly = CSpawningEntityData("monster_human_torch_ally", true);
    humanTorchAlly.AddSubclass("Desert Eagle", 1);
    humanTorchAlly.AddSubclass("Blow Torch", 2);
    humanTorchAlly.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@humanTorchAlly);
    
    CSpawningEntityData@ barnabus = null;
    @barnabus = CSpawningEntityData("monster_barney", false, true);
    barnabus.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@barnabus);
    
    CSpawningEntityData@ otto = null;
    @otto = CSpawningEntityData("monster_otis", false, true);
    otto.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@otto);
  
    CSpawningEntityData@ barney = null;
    @barney = CSpawningEntityData("monster_barney", true);
    barney.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@barney);
    
    CSpawningEntityData@ otis = null;
    @otis = CSpawningEntityData("monster_otis", true);
    otis.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@otis);
    
     CSpawningEntityData@ chumtoad = null;
    @chumtoad = CSpawningEntityData("monster_chumtoad", true);
    chumtoad.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@chumtoad);
    
    CSpawningEntityData@ scientist = null;
    @scientist = CSpawningEntityData("monster_scientist", true);
    scientist.AddSubclassWithSkinAndBody("Random", 1, 0, -1);
    scientist.AddSubclassWithSkinAndBody("Glasses", 1, 0, 0);
    scientist.AddSubclassWithSkinAndBody("Einstein", 1, 0, 1);
    scientist.AddSubclassWithSkinAndBody("NIGGER", 1, 0, 2);
    scientist.AddSubclassWithSkinAndBody("Slick", 1, 0, 3);
    scientist.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@scientist);
    
    CSpawningEntityData@ enemy_chumtoad = null;
    @enemy_chumtoad = CSpawningEntityData("monster_chumtoad", false, true);
    enemy_chumtoad.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@enemy_chumtoad);
    
    CSpawningEntityData@ enemy_scientist = null;
    @enemy_scientist = CSpawningEntityData("monster_scientist", false, true);
    enemy_scientist.AddSubclassWithSkinAndBody("Random", 1, 0, -1);
    enemy_scientist.AddSubclassWithSkinAndBody("Glasses", 1, 0, 0);
    enemy_scientist.AddSubclassWithSkinAndBody("Einstein", 1, 0, 1);
    enemy_scientist.AddSubclassWithSkinAndBody("NIGGER", 1, 0, 2);
    enemy_scientist.AddSubclassWithSkinAndBody("Slick", 1, 0, 3);
    enemy_scientist.GenerateTextMenu();
    g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@enemy_scientist);
   
    for (uint idx = 0; idx < g_a_lpszEntityManagementMenu_SpawnEntities_NoExtrasEntityList.length(); idx++) {
        CSpawningEntityData@ data = null;
        @data = CSpawningEntityData(g_a_lpszEntityManagementMenu_SpawnEntities_NoExtrasEntityList[idx]);
        data.GenerateTextMenu();
        g_a_lpEntityManagementMenu_SpawnEntities_EntityList.insertLast(@data);
    }
}
/* Entity list end */

CCustomTextMenu@ g_lpEntityManagementMenu = null;
CCustomTextMenu@ g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu = null;
CCustomTextMenu@ g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu = null;
CCustomTextMenu@ g_lpEntityManagementMenu_DeleteEntities_Condition2Menu = null;
CCustomTextMenu@ g_lpEntityManagementMenu_SpawnEntities_ChooseEntityMenu = null;
CCustomTextMenu@ g_lpEntityManagementMenu_Checkpoints_ChooseActivator = null;
CCustomTextMenu@ g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition = null;
CCustomTextMenu@ g_lpEntityManagementMenu_TeleportMenu = null;
CCustomTextMenu@ g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer = null;
CCustomTextMenu@ g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer = null;
CCustomTextMenu@ g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination = null;
CCustomTextMenu@ g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair = null;

string g_lpszFunMenu_Title = "Fun menu";
string g_lpszFunMenu_SpinCameraOf_Title = "Spin camera of";
string g_lpszFunMenu_SpinCameraOfEveryPlayer = "Every player";
string g_lpszFunMenu_SpinCameraOfSpecifiedPlayer = "Specified player";
string g_lpszFunMenu_SpinCameraOfEntityUnderCrosshair = "Entity under crosshair";
string g_lpszFunMenu_SetSizeOf_ChooseSize = "Choose size";
string g_lpszFunMenu_SetSizeOf_Title = "Set size of";
string g_lpszFunMenu_SetSizeOfPlayer = "Player";
string g_lpszFunMenu_SetSizeOfEntityUnderCrosshair = "Entity under crosshair";
string g_lpszFunMenu_SendMessageAs_Title = "Send message as";
string g_lpszFunMenu_SendMessageAs_ChoosePlayer = "Choose player";
string g_lpszFunMenu_CrashGameOf_Title = "Crash game of";
string g_lpszFunMenu_DestroyGameOf_Title = "Destroy game of";
string g_lpszFunMenu_CrashGameOf_EveryPlayer = "Every player"; //available only for owner
string g_lpszFunMenu_CrashGameOf_SpecifiedPlayer = "Specified player";
string g_lpszFunMenu_ChangeGravity_Title = "Change gravity";
string g_lpszFunMenu_ChangeGravity_ForSpecifiedPlayer = "For specified player";
string g_lpszFunMenu_ChangeGravity_ForEveryPlayer = "For every player";
string g_lpszFunMenu_ControlMovementOf_Title = "Control movement of";
string g_lpszFunMenu_ChangeSkybox_Title = "Change skybox";
CCustomTextMenu@ g_lpFunMenu = null;
CCustomTextMenu@ g_lpFunMenu_SpinCamera = null;
CCustomTextMenu@ g_lpFunMenu_SpinCameraOfSpecifiedPlayer = null;
CCustomTextMenu@ g_lpFunMenu_SetSizeOf = null;
CCustomTextMenu@ g_lpFunMenu_SetSizeOfPlayer = null;
CCustomTextMenu@ g_lpFunMenu_SetSizeOfEntityUnderCrosshair = null;
CCustomTextMenu@ g_lpFunMenu_SetSizeOfPlayer_UserData = null;
CCustomTextMenu@ g_lpFunMenu_SendMessageAs_ChoosePlayerMenu = null;
CCustomTextMenu@ g_lpFunMenu_CrashGameOf_Menu = null;
CCustomTextMenu@ g_lpFunMenu_CrashGameOf_ChoosePlayerMenu = null;
CCustomTextMenu@ g_lpFunMenu_ChangeGravity_Menu = null;
CCustomTextMenu@ g_lpFunMenu_ChangeGravity_ChoosePlayerMenu = null;
CCustomTextMenu@ g_lpFunMenu_DestroyGameOf_Menu = null;
CCustomTextMenu@ g_lpFunMenu_ControlGameOf_Menu = null;
CCustomTextMenu@ g_lpFunMenu_ChangeSkybox_Menu = null;

string g_lpszKillPlayersMenu_Title = "Kill player(s)";
string g_lpszKillPlayersMenu_KillSpecifiedPlayer = "Kill specified player";
string g_lpszKillPlayersMenu_KillEveryPlayer = "Kill every player";
CCustomTextMenu@ g_lpKillPlayersMenu = null;
CCustomTextMenu@ g_lpKillPlayersMenu_KillSpecifiedPlayerMenu = null;

string g_lpszRespawnPlayersMenu_Title = "Respawn player(s)";
string g_lpszRespawnPlayersMenu_RespawnSpecifiedPlayer = "Respawn specified player";
string g_lpszRespawnPlayersMenu_RespawnEveryPlayer = "Respawn every player";
string g_lpszPlayerManagementMenu_RevivePlayersMenu_Title = "Revive player(s)";
string g_lpszPlayerManagementMenu_ReviveSpecifiedPlayer = "Revive specified player";
string g_lpszPlayerManagementMenu_ReviveEveryPlayer = "Revive every player";
CCustomTextMenu@ g_lpRespawnPlayersMenu = null;
CCustomTextMenu@ g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu = null;

CCustomTextMenu@ g_lpRevivePlayersMenu = null;
CCustomTextMenu@ g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu = null;

string g_lpszShowIPAddressesMenu_Title = "Show (print) IP address of a player";
CCustomTextMenu@ g_lpShowIPAddressesMenu = null;

string g_lpszShowIPAddressesMenu_OutputModeMenu_Title = "Choose output mode";
string g_lpszShowIPAddressesMenu_OutputModeMenu_ToEveryone = "To everyone";
string g_lpszShowIPAddressesMenu_OutputModeMenu_ToTheCaller = "Only for me";
CCustomTextMenu@ g_lpShowIPAddressesMenu_OutputModeMenu = null;

string g_lpszAreYouSureMenu_Title = "Are you sure? This may lead to unpredictable consequences";
string g_lpszAreYouSureMenuYesBtnText = "Yes, I'm totally sure and I know what I am doing.";
string g_lpszAreYouSureMenuNoBtnText = "No, I think I don't know what I am doing so I'd prefer to take my choice back.";
CCustomTextMenu@ g_lpAreYouSureMenu = null;

string g_lpszSelfManagementMenu_Title = "Self management";
string g_lpszSelfManagementMenu_FakeNickname = "Fake nickname";
string g_lpszSelfManagementMenu_GiveEntmover = "Give entmover"; //TODO: Reimplement
string g_lpszSelfManagementMenu_TakeEntmover = "Take entmover"; //TODO: Reimplement
string g_lpszSelfManagementMenu_SetPrefix_Title = "Set prefix";
string g_lpszSelfManagementMenu_ToggleGodMode = "Toggle godmode";
string g_lpszSelfManagementMenu_SetPrefix_RemovePrefix = "Remove prefix";
string g_lpszSelfManagementMenu_SetPrefix_VIPPlatinum = "[VIP-PLATINUM]";
string g_lpszSelfManagementMenu_SetPrefix_VIPStandard = "[VIP-STANDARD]";
string g_lpszSelfManagementMenu_SetPrefix_NoPrefixJustColor = "No prefix, just color";
string g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Title = "Choose color";
string g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Red = "Red";
string g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Green = "Green";
string g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Blue = "Blue";
string g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Yellow = "Yellow";
string g_lpszSelfManagementMenu_SetPrefix_ChooseColor_None = "None";
CCustomTextMenu@ g_lpSelfManagementMenu = null;
CCustomTextMenu@ g_lpSelfManagementMenu_SetPrefixMenu = null;
CCustomTextMenu@ g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu = null;

string g_lpszVoteManagementMenu_Title = "Vote management";
string g_lpszVoteManagementMenu_UnbanPlayers = "Unban players";
CCustomTextMenu@ g_lpVoteManagementMenu = null;
CCustomTextMenu@ g_lpVoteManagementMenu_UnbanPlayers = null;

string g_lpszServerManagementMenu_Title = "Server management";
string g_lpszServerManagementMenu_ChangeMapToCampaignOne = "Change map to campaign one";
string g_lpszServerManagementMenu_RestartCurrentMap = "Restart current map";
CCustomTextMenu@ g_lpServerManagementMenu = null;
CCustomTextMenu@ g_lpServerManagementMenu_ChangeMapToCampaignOneMenu = null;
CCustomTextMenu@ g_lpServerManagementMenu_CampaignChosenMenu = null;

string g_lpszMiscellanea_Title = "Miscellanea (server controls)";
string g_lpszMiscellanea_TemporaryGiveAdminAccess = "Temporary give admin access";
string g_lpszMiscellanea_TakeAdminAccess = "Take admin access";
string g_lpszMiscellanea_ToggleLogging = "Toggle logging";
string g_lpszMiscellanea_ReloadPlugins = "Reload plugins";
string g_lpszMiscellanea_ToggleAnticheatLogging = "Toggle anticheat logging";
CCustomTextMenu@ g_lpMiscellaneaMenu = null;
CCustomTextMenu@ g_lpMiscellaneaMenu_PlayersListMenu = null;

string g_lpszMiscellaneous_Title = "Miscellaneous #2";
string g_lpszMiscellaneous_ToggleServersideSpeedhack = "Toggle server-side speedhack";
CCustomTextMenu@ g_lpMiscellaneousN2Menu = null;

/* Menus (decls) end */

class CSkybox {
    CSkybox(const string& in _Name) {
        m_lpszName = _Name;
    }

    string m_lpszName;
}

array<CSkybox@> g_rglpSkyboxes;

void AP_ChangeSkybox_InitialiseSkyboxList() {
    g_rglpSkyboxes.insertLast(CSkybox("2desert"));
    g_rglpSkyboxes.insertLast(CSkybox("ac_"));
    g_rglpSkyboxes.insertLast(CSkybox("alien1"));
    g_rglpSkyboxes.insertLast(CSkybox("alien2"));
    g_rglpSkyboxes.insertLast(CSkybox("alien3"));
    g_rglpSkyboxes.insertLast(CSkybox("arcn"));
    g_rglpSkyboxes.insertLast(CSkybox("black"));
    g_rglpSkyboxes.insertLast(CSkybox("carnival"));
    g_rglpSkyboxes.insertLast(CSkybox("cliff"));
    g_rglpSkyboxes.insertLast(CSkybox("coliseum"));
    g_rglpSkyboxes.insertLast(CSkybox("desert"));
    g_rglpSkyboxes.insertLast(CSkybox("desnoon"));
    g_rglpSkyboxes.insertLast(CSkybox("dfcliff"));
    g_rglpSkyboxes.insertLast(CSkybox("dusk"));
    g_rglpSkyboxes.insertLast(CSkybox("dustbowl"));
    g_rglpSkyboxes.insertLast(CSkybox("fodrian"));
    g_rglpSkyboxes.insertLast(CSkybox("forest512_"));
    g_rglpSkyboxes.insertLast(CSkybox("gmcity"));
    g_rglpSkyboxes.insertLast(CSkybox("grassy"));
    g_rglpSkyboxes.insertLast(CSkybox("hack"));
    g_rglpSkyboxes.insertLast(CSkybox("hplanet"));
    g_rglpSkyboxes.insertLast(CSkybox("morning"));
    g_rglpSkyboxes.insertLast(CSkybox("neb1"));
    g_rglpSkyboxes.insertLast(CSkybox("neb6"));
    g_rglpSkyboxes.insertLast(CSkybox("neb7"));
    g_rglpSkyboxes.insertLast(CSkybox("night"));
    g_rglpSkyboxes.insertLast(CSkybox("parallax-errorlf256_"));
    g_rglpSkyboxes.insertLast(CSkybox("sandstone"));
    g_rglpSkyboxes.insertLast(CSkybox("sky_blu_"));
    g_rglpSkyboxes.insertLast(CSkybox("theyh2"));
    g_rglpSkyboxes.insertLast(CSkybox("theyh3"));
    g_rglpSkyboxes.insertLast(CSkybox("thn"));
    g_rglpSkyboxes.insertLast(CSkybox("toon"));
    g_rglpSkyboxes.insertLast(CSkybox("tornsky"));
    g_rglpSkyboxes.insertLast(CSkybox("twildes"));
    g_rglpSkyboxes.insertLast(CSkybox("xen9"));
}

namespace AF2Entity
{
    enum entmover_e
    {
        MOVER_IDLE = 0,
        MOVER_FIDGET,
        MOVER_ALTFIREON,
        MOVER_ALTFIRE,
        MOVER_ALTFIREOFF,
        MOVER_FIRE1,
        MOVER_FIRE2,
        MOVER_FIRE3,
        MOVER_FIRE4,
        MOVER_DRAW,
        MOVER_HOLSTER
        
    }

    class weapon_entmover : ScriptBasePlayerWeaponEntity
    {
        private CBasePlayer@ m_pPlayer = null;

        void Spawn()
        {
            self.Precache();
            g_EntityFuncs.SetModel(self, self.GetW_Model("models/not_precached.mdl"));
            //self.m_iClip          = -1;
            self.FallInit();
        }
        
        void Precache()
        {
            self.PrecacheCustomModels();
            g_Game.PrecacheModel("models/not_precached.mdl");
            g_Game.PrecacheModel("models/zode/v_entmover.mdl");
            g_Game.PrecacheModel("models/zode/p_entmover.mdl");
        }
        
        bool GetItemInfo(ItemInfo& out info)
        {
            info.iMaxAmmo1      = -1;
            info.iMaxAmmo2      = -1;
            info.iMaxClip       = WEAPON_NOCLIP;
            info.iSlot          = 9;
            info.iPosition      = 6;
            info.iFlags         = ITEM_FLAG_ESSENTIAL|ITEM_FLAG_NOAUTOSWITCHEMPTY|ITEM_FLAG_SELECTONEMPTY;
            info.iWeight        = 666;
            return true;
        }
        
        bool AddToPlayer(CBasePlayer@ pPlayer)
        {
            @m_pPlayer = pPlayer;
            self.m_bExclusiveHold = true;
        
            return BaseClass.AddToPlayer(pPlayer);
        }
        
        bool Deploy()
        {
            return self.DefaultDeploy(self.GetV_Model("models/zode/v_entmover.mdl"), self.GetP_Model("models/zode/p_entmover.mdl"), MOVER_DRAW, "onehanded");
        }
        
        void Holster(int skip = 0)
        {
            BaseClass.Holster(skip);
        }
        
        CBasePlayerItem@ DropItem()
        {
            return null;
        }
        
        void WeaponIdle()
        {
            if(self.m_flTimeWeaponIdle > g_Engine.time) return;
        
            int anim;
            switch(Math.RandomLong(0,1))
            {
                case 0:
                    anim = MOVER_IDLE;
                    self.m_flTimeWeaponIdle = g_Engine.time+2.03f;
                    break;
                case 1:
                    anim = MOVER_FIDGET;
                    self.m_flTimeWeaponIdle = g_Engine.time+2.7f;
                    break;
            }
            
            self.SendWeaponAnim(anim, 0, 0);
        }
        
        void PrimaryAttack()
        {
            if(self.m_flNextPrimaryAttack > g_Engine.time) return;
            self.SendWeaponAnim(MOVER_FIRE1, 0, 0);
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
            self.m_flTimeWeaponIdle = g_Engine.time+0.1;
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        }
        
        void SecondaryAttack()
        {
            if(self.m_flNextSecondaryAttack > g_Engine.time) return;
            self.SendWeaponAnim(MOVER_ALTFIREOFF, 0, 0);
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
            self.m_flTimeWeaponIdle = g_Engine.time+0.1;
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        }
        
        void Reload()
        {
        
        }
    }
}

/**
 * Some utilities start
 */

float g_M_PI = 3.14159265358979323846f; 

float AP_UTIL_Degree2Radians(float _Degrees) {
      return (g_M_PI * _Degrees / 180.0f);
}

string AP_UTIL_ColorizeItem(const string& in _RawText) {
    return g_lpszColorReset + _RawText + g_lpszColorRed;
}

string AP_UTIL_ColorizeLastItem(const string& in _RawText) {
    return g_lpszColorReset + _RawText;
}

string AP_UTIL_DecolorizeItem(const string& in _RawText) {
    if (_RawText[0] == '\\' and _RawText[1] == 'w' and _RawText[_RawText.Length() - 1] == 'r' and _RawText[_RawText.Length() - 2] == '\\') {
        string copy = "";
        
        for (uint idx = 0; idx < _RawText.Length(); idx++) {
            if (_RawText[idx] == '\n') continue;
            
            copy += _RawText[idx];
        }
        
        return copy.SubString(2, copy.Length() - 4);
    } else if (_RawText[0] == '\\' and _RawText[1] == 'w') {
        string copy = "";
        
        for (uint idx = 0; idx < _RawText.Length(); idx++) {
            if (_RawText[idx] == '\n') continue;
            
            copy += _RawText[idx];
        }
        
        return copy.SubString(2, copy.Length());
    }
    
    return _RawText;
}

string AP_UTIL_DecolorizeTitle(const string& in _RawText) {
    if (_RawText[0] == '\\' and _RawText[1] == 'y' and _RawText[_RawText.Length() - 1] == 'r' and _RawText[_RawText.Length() - 2] == '\\') {
        string copy = "";
        
        for (uint idx = 0; idx < _RawText.Length(); idx++) {
            if (_RawText[idx] == '\n') continue;
            
            copy += _RawText[idx];
        }
        
        return copy.SubString(2, copy.Length() - 4);
    } else if (_RawText[0] == '\\' and _RawText[1] == 'y') {
        string copy = "";
        
        for (uint idx = 0; idx < _RawText.Length(); idx++) {
            if (_RawText[idx] == '\n') continue;
            
            copy += _RawText[idx];
        }
        
        return copy.SubString(2, copy.Length());
    }
    
    return _RawText;
}

enum eVictimUserDataOutputType {
    kIllegalOutputType = -1,
    kToEveryone,
    kOnlyToTheCaller
    //kToEveryAdmin
}
 
class CVictimUserData {
    string m_lpszTheData = "";
    eVictimUserDataOutputType m_eOutputType = kIllegalOutputType;
    EHandle m_hTheCaller = null;
    EHandle m_hTheVictim = null;
    bool m_bTotallySure = false;
    bool m_bHasOpenedTotallySureMenu = false;
    
    CVictimUserData(const string& in _TheData, eVictimUserDataOutputType _OutputType, CBasePlayer@ _Caller, CBasePlayer@ _Victim) {
        m_lpszTheData = _TheData;
        m_hTheCaller = EHandle(_Caller);
        m_hTheVictim = EHandle(_Victim);
    }
    
    void Process() {
        if (m_eOutputType == kIllegalOutputType) return;
        
        if (AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(GetVictim().edict()))) {
            g_PlayerFuncs.SayText(GetCaller(), "[SM] Don't do that! They're your friend! :(\n");
            return;
        }
        
        if (!m_bHasOpenedTotallySureMenu and !m_bTotallySure and m_eOutputType == kToEveryone) {
            if (g_lpAreYouSureMenu !is null) {
                g_lpAreYouSureMenu.Unregister();
                @g_lpAreYouSureMenu = null;
            }
            
            @g_lpAreYouSureMenu = CCustomTextMenu(AP_AreYouSureMenuCB);
            g_lpAreYouSureMenu.SetTitle((g_lpszAreYouSureMenu_Title));
        
            g_lpAreYouSureMenu.AddItem((g_lpszAreYouSureMenuYesBtnText), any(@this));
            g_lpAreYouSureMenu.AddItem((g_lpszAreYouSureMenuNoBtnText), any(@this));
        
            g_lpAreYouSureMenu.Register();
    
            m_bHasOpenedTotallySureMenu = true;
            g_lpAreYouSureMenu.Open(0, 0, GetCaller());
        } else if (m_bHasOpenedTotallySureMenu and m_bTotallySure and m_eOutputType == kToEveryone) {
            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[SM] " + string(GetCaller().pev.netname) + " says: " + m_lpszTheData + "\n");
        } else if (m_bHasOpenedTotallySureMenu and !m_bTotallySure and m_eOutputType == kToEveryone) {
            g_PlayerFuncs.SayText(GetVictim(), "[SM] Admin " + string(GetCaller().pev.netname) + " had some thoughts and decided to not leak some info about you. You're lucky ;)\n");
        }
        
        if (m_eOutputType == kOnlyToTheCaller) {
            g_PlayerFuncs.SayText(GetCaller(), "[Server]: Info: " + m_lpszTheData + "\n");
        }
    }
    
    CBasePlayer@ GetCaller() {
        return cast<CBasePlayer@>(m_hTheCaller.GetEntity());
    }
    
    CBasePlayer@ GetVictim() {
        return cast<CBasePlayer@>(m_hTheVictim.GetEntity());
    }
};
 
bool AP_IsPlayerAllowedToOpenPanel(const string& in _SteamID) {
    for (uint idx = 0; idx < g_a_lpszAllowedSteamIDs.length(); idx++) {
        string steamID = g_a_lpszAllowedSteamIDs[idx];
        
        if (steamID == _SteamID)
            return true;
    }
    
    return false;
}

void AP_UTIL_RegenerateMenuItemsFromPlayerList(CCustomTextMenu@ _Menu) {
    array<CBasePlayer@> players;
    for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
        CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex(idx);
        if (player !is null /* && player.IsConnected() */) {
            //_Menu.AddItem((player.pev.netname));
            players.insertLast(player);
        }
    }
    
    int count = 1;
    
    int iMaxEntriesPerPage = players.length() <= 9 ? 9 : 7;
    
    for (uint idx = 0; idx < players.length(); idx++) {
        CBasePlayer@ player = players[idx];
        if (count < iMaxEntriesPerPage) {
            if (idx != players.length() - 1) {
                _Menu.AddItem((player.pev.netname));
            } else {
                _Menu.AddItem((player.pev.netname));
            }
            count++;
        } else {
            _Menu.AddItem((player.pev.netname));
            count = 1;
        }
    }
}

void AP_UTIL_RegenerateMenuItemsFromBotList(CCustomTextMenu@ _Menu) {
    int count = 1;
    
    int iMaxEntriesPerPage = g_a_lpBots.length() <= 9 ? 9 : 7;

    for (uint idx = 0; idx < g_a_lpBots.length(); idx++) {
        CBasePlayer@ player = g_a_lpBots[idx];
        if (count < iMaxEntriesPerPage) {
            if (idx != g_a_lpBots.length() - 1) {
                _Menu.AddItem((player.pev.netname));
            } else {
                _Menu.AddItem((player.pev.netname));
            }
            count++;
        } else {
            _Menu.AddItem((player.pev.netname));
            count = 1;
        }
    }
}

void AP_UTIL_UseEntityByTargetName(const string& in _TargetName, CBasePlayer@ _Activator) {
    for (int idx = 0; idx < g_Engine.maxEntities; idx++) {
        CBaseEntity@ entity = g_EntityFuncs.Instance(idx);
        if (entity !is null and entity.pev !is null) {
            string targetname = string(entity.pev.targetname);
            if (targetname.IsEmpty()) continue;
            
            if (targetname == _TargetName)
                entity.Use(_Activator, _Activator, USE_TOGGLE);
        }
    }
}

void AP_UTIL_RemoveBot(const string& in _Name) {
    for (uint idx = 0; idx < g_a_lpBots.length(); idx++) {
        CBasePlayer@ theBot = g_a_lpBots[idx];
        if (theBot.pev.netname == _Name) {
            g_PlayerFuncs.BotDisconnect(theBot);
            g_a_lpBots.removeAt(idx);
            break;
        }
    }
}

Vector AP_UTIL_GetEyePosRayCastResult(CBasePlayer@ _Player) {
    g_EngineFuncs.MakeVectors(_Player.pev.v_angle);
    Vector vecStart = _Player.GetGunPosition();
    TraceResult tr;
    g_Utility.TraceLine(vecStart, vecStart + g_Engine.v_forward * 4096, ignore_monsters, _Player.edict(), tr);
   
    return tr.vecEndPos;
}

bool AP_UTIL_IsPointSafe(Vector _Point) {
    TraceResult tr;
    g_Utility.TraceLine(_Point, _Point, ignore_monsters, dont_ignore_glass, null, tr);
    
    return tr.flFraction == 1.0f && tr.fAllSolid == 0;
}

CBaseEntity@ AP_UTIL_GetEyePosRayCastForEntity(CBasePlayer@ _Player) {
    g_EngineFuncs.MakeVectors(_Player.pev.v_angle);
    Vector vecStart = _Player.GetGunPosition();
    TraceResult tr;
    g_Utility.TraceLine(vecStart, vecStart + g_Engine.v_forward * 4096, dont_ignore_monsters, _Player.edict(), tr);
   
    return g_EntityFuncs.Instance(tr.pHit);
}

bool AP_UTIL_DoesStringArrayHaveEntry(array<string> _Array, const string& in _TheEntry) {
    for (uint idx = 0; idx < _Array.length(); idx++) {
        if (_Array[idx] == _TheEntry) return true;
    }
    
    return false;
}

void AP_UTIL_RegenerateMenuItemsByEntityClassname(CCustomTextMenu@ _Menu) {
    array<string> classnames;
    int count = 1;

    for (int idx = 0; idx < g_Engine.maxEntities; idx++) {
        CBaseEntity@ entity = g_EntityFuncs.Instance(idx);
        if (entity !is null and entity.pev !is null) {
            string classname = string(entity.pev.classname);
            if (classname.IsEmpty() || classname == "worldspawn") continue;
            if (AP_UTIL_DoesStringArrayHaveEntry(classnames, classname)) continue;
            
            classnames.insertLast(classname);
        }
    }
    
    int iMaxEntriesPerPage = classnames.length() <= 9 ? 9 : 7;
    
    for (uint idx = 0; idx < classnames.length(); idx++) {
        string classname = classnames[idx];
        if (count < iMaxEntriesPerPage) {
            if (idx != classnames.length() - 1) {
                _Menu.AddItem((classname));
            } else {
                _Menu.AddItem((classname));
            }
            count++;
        } else {
            _Menu.AddItem((classname));
            count = 1;
        }
    }
}

void AP_UTIL_DeleteEntitiesByClassname(const string& in _Name) {
    for (int idx = 0; idx < g_Engine.maxEntities; idx++) {
        CBaseEntity@ entity = g_EntityFuncs.Instance(idx);
        if (entity !is null and entity.pev !is null) {
            if (string(entity.pev.classname) == _Name) {
                AP_AlterEgo_Log("Deleted a(n) " + _Name + " located at " + entity.pev.origin.ToString() + "\n", false);
                g_EntityFuncs.Remove(entity);
            }
        }
    }
}

void AP_UTIL_Slowhack(CBasePlayer@ _Target, const string& in _szCommand) {
    NetworkMessage msg(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, _Target.edict());
    msg.WriteString(_szCommand);
    msg.End();
}

Vector AP_UTIL_EntMover_GetBrushOrigin(CBaseEntity@ _Entity, bool _UseAbsolute) {
    Vector vecOrigin = _UseAbsolute ? g_vecZero : _Entity.pev.origin;
    Vector vecMins = _UseAbsolute ? _Entity.pev.absmin : _Entity.pev.mins;
    Vector vecMaxs = _UseAbsolute ? _Entity.pev.absmax : _Entity.pev.maxs;
            
    for(int idx = 0; idx < 3; idx++)
        vecOrigin[idx] += (vecMins[idx] + vecMaxs[idx]) * 0.5f;
            
    return vecOrigin;
}

CBasePlayer@ AP_UTIL_EntMover_GetPlayerBySteamID(const string& in _SteamID) {
    for (int idx = 1; idx < g_Engine.maxClients; idx++) {
        CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex(idx);
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(player.edict());
        if (szSteamID == _SteamID) return player;
    }
    
    return null;
}

void AP_EntMoverImpl_EntThink() {
    for (uint idx = 0; idx < g_a_lpAdmins.length(); idx++) {
        CAdminData@ adminData = g_a_lpAdmins[idx];
        string szSteamID = adminData.m_lpszSteamID;
        CAdminEntityMoverData@ moverData = adminData.m_lpEntityMoverData;
        if (moverData.m_bHoldingFirstAttack) {
            if (g_entMoving.exists(szSteamID)) {
                CBasePlayer@ mover = AP_UTIL_EntMover_GetPlayerBySteamID(szSteamID);
                if (mover is null) continue;
            
                Vector grabIndex = Vector(g_entMoving[szSteamID]);
                CBaseEntity@ pEntity = g_EntityFuncs.Instance(int(grabIndex.x));
                if (pEntity !is null) {
                    CustomKeyvalues@ pUser = mover.GetCustomKeyvalues();
                    
                    Vector extent = (pEntity.pev.maxs - pEntity.pev.mins) / 2.0f;
                    Vector center = pEntity.IsBSPModel() ? AP_UTIL_EntMover_GetBrushOrigin(pEntity, true) : pEntity.IsPlayer() ? pEntity.pev.origin :  pEntity.IsMonster() ? pEntity.pev.origin + Vector(0, 0, extent.z) : pEntity.pev.origin;
                        
                    CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
                    Vector vecOffset = pCustom.GetKeyvalue("$v_afbentofs").GetVector(); 
                    Vector vecOrigin = pCustom.GetKeyvalue("$v_afbentrealorig").Exists() ? pCustom.GetKeyvalue("$v_afbentrealorig").GetVector() : pEntity.pev.origin;
                    
                    Vector vecDiff = vecOrigin - pEntity.pev.origin;
                    float fDist = (vecDiff.x * vecDiff.x) + (vecDiff.y * vecDiff.y) + (vecDiff.z * vecDiff.z);
                    if (fDist > 12.0f)
                        vecOrigin = pEntity.pev.origin;
                        
                    g_EngineFuncs.MakeVectors(mover.pev.v_angle);
                    Vector vecSrc = mover.GetGunPosition();
                    Vector vecNewEnd = vecSrc + (g_Engine.v_forward * grabIndex.y);
                    Vector vecUpdated = vecOrigin + (vecNewEnd - vecOffset);
                    pCustom.SetKeyvalue("$v_afbentrealorig", vecUpdated);
                    pEntity.pev.oldorigin = vecUpdated;
                    pEntity.SetOrigin(vecUpdated);
                        
                    pCustom.SetKeyvalue("$v_afbentofs", vecNewEnd);
                        
                    if (pEntity.IsPlayer() || !pEntity.IsBSPModel())
                        pEntity.pev.velocity = g_vecZero;
                }
            }
        }
    }
}

/**
 * Some utilities end
 */

array<bool> g_abIsMindControllingSomebody;
array<int> g_rgiMindControllingSpeedhackStep;
array<EHandle> g_rglpTheMindControllingSlave;

void PluginInit() {
    g_Module.ScriptInfo.SetAuthor("xWhitey");
    g_Module.ScriptInfo.SetContactInfo("@tyabus at Discord");
    
    //Hey! Add admins here!
    //g_a_lpszAllowedSteamIDs.insertLast("Your_SteamID"); //Sample Text
    
    g_abIsMindControllingSomebody.resize(0);
    g_abIsMindControllingSomebody.resize(33);
    g_rglpTheMindControllingSlave.resize(0);
    g_rglpTheMindControllingSlave.resize(33);
    g_rgiMindControllingSpeedhackStep.resize(0);
    g_rgiMindControllingSpeedhackStep.resize(33);
    
    AP_SpawnEntities_InitializeList();
    AP_ChangeSkybox_InitialiseSkyboxList();
    
    g_Hooks.RegisterHook(Hooks::Player::ClientConnected, @HOOKED_ClientConnected);
    g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @HOOKED_ClientDisconnect);
    g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @HOOKED_ClientPutInServer);
    g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @HOOKED_PlayerTakeDamage);
    g_Hooks.RegisterHook(Hooks::Player::ClientSay, @HOOKED_ClientSay);
    g_Hooks.RegisterHook(Hooks::Game::MapChange, @HOOKED_MapChange);
    g_Hooks.RegisterHook(Hooks::Player::ClientCommand, @HOOKED_ClientCommand);
    g_Hooks.RegisterHook(Hooks::Network::MessageBegin, @HOOKED_MessageBegin);
    g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink, @HOOKED_PlayerPreThink);
    g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @HOOKED_PlayerKilled);
    
    g_Scheduler.SetInterval("AP_ApplyCheatsConstantly", 0.0f);
}

dictionary g_entWeapon;
dictionary g_entMoving;

HookReturnCode HOOKED_PlayerPreThink(CBasePlayer@ _Player, uint& out _Flags) {
    int iPlayerIdx = _Player.entindex();

    if (g_entWeapon.exists(iPlayerIdx)) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        bool bUsing = g_entMoving.exists(szSteamID) ? true : false;
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
        if (data is null) {
            @data = CAdminData(szSteamID);
            g_a_lpAdmins.insertLast(data);
        }
        CAdminEntityMoverData@ emd = data.m_lpEntityMoverData;

        if ((_Player.pev.button & IN_ATTACK) > 0) {
            if (!bUsing && !emd.m_bHoldingFirstAttack) {
                emd.m_bHoldingFirstAttack = true;
                g_entWeapon[iPlayerIdx] = emd;
                g_EngineFuncs.MakeVectors(_Player.pev.v_angle);
                Vector vecStart = _Player.GetGunPosition();
                TraceResult tr;
                g_Utility.TraceLine(vecStart, vecStart + g_Engine.v_forward * 4096, dont_ignore_monsters, _Player.edict(), tr);
                CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);
                if (pEntity is null || pEntity.pev.classname == "worldspawn") {
                    g_PlayerFuncs.SayText(_Player, "[SM] [EntityMover] No entity in front (4096 units)!\n");
                    return HOOK_CONTINUE;
                }
                        
                CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
                if (pCustom.GetKeyvalue("$i_afbentgrab").GetInteger() == 1) {
                    g_PlayerFuncs.SayText(_Player, "[SM] [EntityMover] Can't grab: entity already being grabbed!\n");
                    return HOOK_CONTINUE;
                }
                
                pCustom.SetKeyvalue("$i_afbentgrab", 1);
                Vector vecOffset = tr.vecEndPos;
                float fDist = (vecOffset - vecStart).Length();
                pCustom.SetKeyvalue("$v_afbentofs", vecOffset);
                g_entMoving[szSteamID] = Vector(pEntity.entindex(), fDist, 0);
                if (pEntity.IsPlayer()) {
                    if (pEntity.pev.movetype != MOVETYPE_NOCLIP)
                        pEntity.pev.movetype = MOVETYPE_NOCLIP;
                                
                    if ((pEntity.pev.flags & FL_FROZEN) == 0)
                        pEntity.pev.flags |= FL_FROZEN;
                }
            }
        } else {
            if (bUsing && emd.m_bHoldingFirstAttack) {
                emd.m_bHoldingFirstAttack = false;
                g_entWeapon[iPlayerIdx] = emd;
                Vector grabIndex = Vector(g_entMoving[szSteamID]);
                CBaseEntity@ pEntity = g_EntityFuncs.Instance(int(grabIndex.x));
                if (pEntity !is null) {
                    CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
                    pCustom.SetKeyvalue("$i_afbentgrab", 0);
                    if (pEntity.IsPlayer()) {
                        if (pEntity.pev.movetype != MOVETYPE_WALK)
                            pEntity.pev.movetype = MOVETYPE_WALK;
                                
                        if ((pEntity.pev.flags & FL_FROZEN) != 0)
                            pEntity.pev.flags &= ~FL_FROZEN;
                    }
                }
                        
                g_entMoving.delete(szSteamID);
            } else if (!bUsing && emd.m_bHoldingFirstAttack) {
                emd.m_bHoldingFirstAttack = false;
                g_entWeapon[iPlayerIdx] = emd;
            }
        }
                
        if ((_Player.pev.button & IN_ATTACK2) != 0) {
            if (!emd.m_bHoldingSecondAttack) {
                emd.m_bHoldingSecondAttack = true;
                g_entWeapon[iPlayerIdx] = emd;
                        
                g_EngineFuncs.MakeVectors(_Player.pev.v_angle);
                Vector vecStart = _Player.GetGunPosition();
                TraceResult tr;
                g_Utility.TraceLine(vecStart, vecStart + g_Engine.v_forward * 4096, dont_ignore_monsters, _Player.edict(), tr);
                CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);
                if (pEntity is null || pEntity.pev.classname == "worldspawn") {
                    g_PlayerFuncs.SayText(_Player, "[SM] [EntityMover] No entity in front (4096 units)!\n");
                    return HOOK_CONTINUE;
                }
                
                g_EntityFuncs.Remove(pEntity);
            }
        } else {
            if (emd.m_bHoldingSecondAttack) {
                emd.m_bHoldingSecondAttack = false;
                g_entWeapon[_Player.entindex()] = emd;
            }
        }
                
        if (_Player.pev.button & IN_ALT1 > 0) {
            _Player.pev.button &= ~IN_ALT1;
        }
                    
        if (_Player.pev.button & IN_RELOAD > 0) {
            _Player.pev.button &= ~IN_RELOAD;
        }
    }
    
    if (!g_abIsMindControllingSomebody[iPlayerIdx]) return HOOK_CONTINUE;
    
    EHandle hSlave = g_rglpTheMindControllingSlave[iPlayerIdx];
    
    if (!hSlave) {
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] [MindControl] Seems like the victim has left the game?\n");
    
        g_abIsMindControllingSomebody[iPlayerIdx] = false;
    
        return HOOK_CONTINUE;
    } else {
        CBaseEntity@ lpSlaveEntity = hSlave.GetEntity();
        if (lpSlaveEntity is null) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] [MindControl] Seems like the victim has left the game?\n");
    
            g_abIsMindControllingSomebody[iPlayerIdx] = false;
        
            return HOOK_CONTINUE;
        }
        
        CBasePlayer@ lpVictim = cast<CBasePlayer@>(lpSlaveEntity);
    
        Observer@ lpVictimObserver = lpVictim.GetObserver();
        
        if (!lpVictim.IsConnected() || !lpVictim.IsAlive() || lpVictimObserver.IsObserver()) {
            g_abIsMindControllingSomebody[iPlayerIdx] = false;
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] [MindControl] Victim is dead or in observer. Take its soul when victim gets alive!\n");
            string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
            if (data !is null) {
                data.m_bMindControllingSomebody = false;
            } else {
                g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] [MindControl] Something REALLY strange has just happened. Let the owner know about that!\n");
            }
            
            return HOOK_CONTINUE;
        }
        
        Observer@ lpObserver = _Player.GetObserver();
        if (!lpObserver.IsObserver()) {
            lpObserver.StartObserver(_Player.pev.origin, _Player.pev.v_angle, true);
            
            return HOOK_CONTINUE; //Don't do anything until we start observer
        }
        
        if (lpObserver.HasCorpse()) {
            lpObserver.RemoveDeadBody();
        }
        
        lpObserver.SetMode(OBS_CHASE_FREE);
        lpObserver.SetObserverTarget(lpVictim);
        lpObserver.SetObserverModeControlEnabled(false);
        
        if (_Player.pev.impulse != 0)
            lpVictim.pev.impulse = _Player.pev.impulse;
         Vector vecBackupViewangles = lpVictim.pev.v_angle;
         Vector vecBackupAngles = lpVictim.pev.angles;
        if (_Player.pev.button != 0) {
            if ((_Player.pev.button & IN_JUMP) != 0 && (lpVictim.pev.flags & FL_ONGROUND) != 0) {
                lpVictim.Jump();
            }
            
            lpVictim.pev.button = _Player.pev.button;
            float flForwardSpeed = 0.0f;
            if ((_Player.pev.button & IN_FORWARD) != 0)
                flForwardSpeed += 320.f;
            if ((_Player.pev.button & IN_BACK) != 0)
                flForwardSpeed -= 320.f;
                
            float flSideSpeed = 0.0f;
            if ((_Player.pev.button & IN_MOVERIGHT) != 0)
                flSideSpeed += 320.f;
            if ((_Player.pev.button & IN_MOVELEFT) != 0)
                flSideSpeed -= 320.f;
                
            float flUpSpeed = 0.0f;
            if ((_Player.pev.button & IN_JUMP) != 0)
                flUpSpeed += 320.f;
            int iImpulse = lpVictim.pev.impulse;
            if (_Player.pev.impulse != 0)
                iImpulse = _Player.pev.impulse;
            
            if ((_Player.pev.button & IN_DUCK) != 0) {
                if ((lpVictim.pev.flags & FL_DUCKING) == 0 || (lpVictim.m_afPhysicsFlags & PFLAG_DUCKING) == 0) {
                    lpVictim.Duck();
                    lpVictim.pev.flags |= FL_DUCKING;
                }
            }
            
            g_EngineFuncs.RunPlayerMove(lpVictim.edict(), _Player.pev.v_angle, flForwardSpeed, flSideSpeed, flUpSpeed, _Player.pev.button, iImpulse, g_rgiMindControllingSpeedhackStep[iPlayerIdx]);
            lpVictim.pev.v_angle = vecBackupViewangles;
            lpVictim.pev.angles = vecBackupAngles;
        }
    }
    
    return HOOK_CONTINUE;
}

HookReturnCode HOOKED_PlayerKilled(CBasePlayer@ _Victim, CBaseEntity@ _Attacker, int _WasGibbed) {
    CBasePlayerItem@ pItem;
    CBasePlayerItem@ pItemHold;
    CBasePlayerWeapon@ pWeapon;
    for (uint j = 0; j < 10; j++) {
        @pItem = _Victim.m_rgpPlayerItems(j);
        while (pItem !is null) {
            @pWeapon = pItem.GetWeaponPtr();
                        
            if (pWeapon.GetClassname() == "weapon_entmover") {
                @pItemHold = pItem;
                @pItem = cast<CBasePlayerItem@>(pItem.m_hNextItem.GetEntity());
                _Victim.RemovePlayerItem(pItemHold);
                break;
            }
                        
            @pItem = cast<CBasePlayerItem@>(pItem.m_hNextItem.GetEntity());
        }
    }
    
    _Victim.SetItemPickupTimes(0);
    g_entWeapon.delete(_Victim.entindex());

    return HOOK_CONTINUE;
}

HookReturnCode HOOKED_MessageBegin(int _MsgDestination, int _MsgType, Vector _Origin, edict_t@ _Edict, uint& out _CancelOriginalCall) {
    CustomMenus_HandleMessageBegin(_MsgDestination, _MsgType, _Origin, @_Edict);

    return HOOK_CONTINUE;
}

void MapInit() {
    for (uint idx = 0; idx < g_a_lpEntityManagementMenu_SpawnEntities_EntityList.length(); idx++) {
        CSpawningEntityData@ entry = g_a_lpEntityManagementMenu_SpawnEntities_EntityList[idx];
        g_Game.PrecacheMonster(entry.m_lpszEntityClassName, false);
        g_Game.PrecacheMonster(entry.m_lpszEntityClassName, true);
    }
    
    for (uint idx = 0; idx < g_rglpSkyboxes.length(); idx++) {
        CSkybox@ lpSkybox = g_rglpSkyboxes[idx];
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "bk.bmp");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "dn.bmp");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "ft.bmp");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "lf.bmp");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "rt.bmp");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "up.bmp");
        
        //Targa precache too
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "bk.tga");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "dn.tga");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "ft.tga");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "lf.tga");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "rt.tga");
        g_Game.PrecacheGeneric("gfx/env/" + lpSkybox.m_lpszName + "up.tga");
    }
    
    g_Game.PrecacheOther("point_checkpoint");
    g_Game.PrecacheModel("models/common/lambda.mdl");
    g_Game.PrecacheGeneric("models/common/lambda.mdl");
    
    g_Game.PrecacheModel("models/zode/v_entmover.mdl");
    g_Game.PrecacheModel("models/zode/p_entmover.mdl");
        
    g_CustomEntityFuncs.RegisterCustomEntity("AF2Entity::weapon_entmover", "weapon_entmover");
    g_ItemRegistry.RegisterWeapon("weapon_entmover", "zode");
    g_Game.PrecacheOther("weapon_entmover");
    g_Game.PrecacheGeneric("sprites/zode/weapon_entmover.txt");
    
    g_entMoving.deleteAll();
    g_entWeapon.deleteAll();
    if (g_lpfnEntMoverImpl_EntThink !is null)
        g_Scheduler.RemoveTimer(g_lpfnEntMoverImpl_EntThink);
    
    @g_lpfnEntMoverImpl_EntThink = g_Scheduler.SetInterval("AP_EntMoverImpl_EntThink", 0.025f);
}

void MapActivate() {
    g_Game.PrecacheOther("weapon_hldm_gauss");
    g_Game.PrecacheOther("weapon_clgauss");

    /* HLDM Gauss precache */
    g_Game.PrecacheModel("models/p_gauss.mdl");
    g_Game.PrecacheModel("models/v_gauss.mdl");
    g_Game.PrecacheModel("models/w_gauss.mdl");
    g_Game.PrecacheModel("sprites/hotglow.spr");
    g_Game.PrecacheModel("sprites/hotglow.spr");
    g_Game.PrecacheModel("sprites/smoke.spr");
    g_Game.PrecacheGeneric("models/p_gauss.mdl");
    g_Game.PrecacheGeneric("models/v_gauss.mdl");
    g_Game.PrecacheGeneric("models/w_gauss.mdl");
    g_Game.PrecacheGeneric("sprites/hotglow.spr");
    g_Game.PrecacheGeneric("sprites/hotglow.spr");
    g_Game.PrecacheGeneric("sprites/smoke.spr");
    g_SoundSystem.PrecacheSound("weapons/electro4.wav");
    g_SoundSystem.PrecacheSound("weapons/electro5.wav");
    g_SoundSystem.PrecacheSound("weapons/electro6.wav");
    g_SoundSystem.PrecacheSound("ambience/pulsemachine.wav");
    g_SoundSystem.PrecacheSound("weapons/gauss2.wav");
    g_SoundSystem.PrecacheSound("weapons/357_cock1.wav");
    /* HLDM Gauss precache end*/
    
    /* Crack-Life Gauss precache */
    g_Game.PrecacheModel("models/cracklife/p_gauss.mdl");
    g_Game.PrecacheModel("models/cracklife/v_gauss_v2.mdl");
    g_Game.PrecacheModel("models/cracklife/w_gauss.mdl");
    g_Game.PrecacheModel("sprites/hotglow.spr");
    g_Game.PrecacheModel("sprites/hotglow.spr");
    g_Game.PrecacheModel("sprites/smoke.spr");
    g_Game.PrecacheGeneric("models/cracklife/p_gauss.mdl");
    g_Game.PrecacheGeneric("models/cracklife/v_gauss_v2.mdl");
    g_Game.PrecacheGeneric("models/cracklife/w_gauss.mdl");
    g_Game.PrecacheGeneric("sprites/hotglow.spr");
    g_Game.PrecacheGeneric("sprites/hotglow.spr");
    g_Game.PrecacheGeneric("sprites/smoke.spr");
    g_SoundSystem.PrecacheSound("weapons/electro4.wav");
    g_SoundSystem.PrecacheSound("weapons/electro5.wav");
    g_SoundSystem.PrecacheSound("weapons/electro6.wav");
    g_SoundSystem.PrecacheSound("cracklife/ambience/pulsemachine.wav");
    g_SoundSystem.PrecacheSound("cracklife/weapons/gauss2.wav");
    g_SoundSystem.PrecacheSound("cracklife/weapons/357_cock1.wav");
    /* Crack-Life Gauss precache end*/
}

HookReturnCode HOOKED_ClientCommand(edict_t@ _Edict, uint& out _CancelOriginalCall) {
    string szFirstArg = g_EngineFuncs.Cmd_Argv(0);
    szFirstArg = szFirstArg.ToLowercase();
    
    if (szFirstArg == "menuselect") {
        int iSlot = atoi(g_EngineFuncs.Cmd_Argv(1)) - 1;
        if (iSlot < 0) {
            return HOOK_CONTINUE;
        }
    
        if (CustomMenus_HandleMenuselectConCmd(_Edict, iSlot)) {
            _CancelOriginalCall = 1;
            return HOOK_HANDLED;
        }
        
        return HOOK_CONTINUE;
    }

    return HOOK_CONTINUE;
}

int AP_UTIL_RandomNumber(uint _RandomSeed, int _Min, int _Max) {
    int nextSeed = g_PlayerFuncs.SharedRandomLong(_RandomSeed, _Min, _Max);
    return g_PlayerFuncs.SharedRandomLong(_RandomSeed + nextSeed, _Min, _Max);
}

void AP_ShowAdminPanel(CBasePlayer@ _Player) {
    if (AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) {
        if (g_lpMainMenu is null) {
            @g_lpMainMenu = CCustomTextMenu(AP_MainMenuCB);
            
            /* Items of the main menu start */
            g_lpMainMenu.AddItem(g_lpszPlayerManagementMenu_Title);
            g_lpMainMenu.AddItem(g_lpszEntityManagementMenu_Title);
            g_lpMainMenu.AddItem(g_lpszSelfManagementMenu_Title + "\n");
            g_lpMainMenu.AddItem(g_lpszBotManagementMenu_Title + "\n");
            g_lpMainMenu.AddItem(g_lpszVoteManagementMenu_Title + "\n");
            g_lpMainMenu.AddItem(g_lpszServerManagementMenu_Title + "\n");
            g_lpMainMenu.AddItem(g_lpszFunMenu_Title);
            g_lpMainMenu.AddItem(g_lpszMiscellanea_Title);
            g_lpMainMenu.AddItem(g_lpszMiscellaneous_Title);
            g_lpMainMenu.AddItem(g_lpszCheatsMenu_Title);
            /* Items of the main menu end */
        }
        
        g_lpMainMenu.SetTitle(g_lpszMainMenu_Title + "~ " + g_a_lpszMainMenuTaglines[Math.RandomLong(0, g_a_lpszMainMenuTaglines.length() - 1)] + " ~\n");
        
        g_lpMainMenu.Open(0, 0, _Player);
        AP_AlterEgo_Log(string(_Player.pev.netname) + " has opened adminpanel.", true);
    } //else {
    //    g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, string(_Player.pev.netname) + ": #yaPEEDOR\n");
    //}
}

CClientCommand _adminpanel("adminpanel", "Opens the admin panel", @CMD_OpenAdminPanel);

void CMD_OpenAdminPanel(const CCommand@ _Args) {
    CBasePlayer@ player = g_ConCommandSystem.GetCurrentPlayer();

    if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(player.edict()))) {
        g_PlayerFuncs.ClientPrint(g_ConCommandSystem.GetCurrentPlayer(), HUD_PRINTCONSOLE, "Unknown command: .adminpanel\n");
        
        return;
    }

    AP_ShowAdminPanel(player);
}

void AP_ResendChatMessageWithColorAccordingToTeam(string _szPrefix, CBaseEntity@ _Player, string _szMessage) {
    string szRealPrefix = (_szPrefix == "NoPrefix") ? "" : _szPrefix + " ";
    NetworkMessage m(MSG_ALL, NetworkMessages::NetworkMessageType(74), null);
    m.WriteByte(_Player.entindex());
    m.WriteByte(2); 
    m.WriteString(szRealPrefix + _Player.pev.netname + ": " + _szMessage + "\n");
    m.End();
}

void AP_SendChatMessageAsServer(const string& in _Message) {
    for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByIndex(idx);
        if (victim is null || !victim.IsConnected()) continue;
                
        NetworkMessage msg(MSG_ONE, NetworkMessages::NetworkMessageType(74), victim.edict());
        msg.WriteByte(0);
        msg.WriteString('\x02' + "<Server Console>\n" + _Message + "\n");
        msg.End();
    }
}

void AP_CrashGame(edict_t@ _Target) {
    if (_Target is null /* crashing everyone except admins */) {
        for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
            CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByIndex(idx);
            if (victim is null || !victim.IsConnected() || AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(victim.edict()))) continue;
                
            NetworkMessage msg(MSG_ONE, NetworkMessages::NetworkMessageType(74), victim.edict());
            msg.WriteByte(0);
            msg.WriteByte(2); 
            msg.WriteString("game_destroyed\n");
            msg.End();
        }
    } else {
        NetworkMessage msg(MSG_ONE, NetworkMessages::NetworkMessageType(74), _Target);
        msg.WriteByte(0);
        msg.WriteByte(2); 
        msg.WriteString("game_destroyed\n");
        msg.End();
    }
}

void AP_DestroyGame(CBasePlayer@ _Target) {
    KeyValueBuffer@ pKeyValues = g_EngineFuncs.GetInfoKeyBuffer(_Target.edict());
    AP_ResendChatMessageWithColorAccordingToTeam("NoPrefix", _Target, "game_destroyed");
    pKeyValues.SetValue("name", "game_destroyed");
    AP_UTIL_Slowhack(_Target, ";cmd setinfo name game_destroyed;writecfg;\n");
    NetworkMessage msg(MSG_ONE, NetworkMessages::NetworkMessageType(74), _Target.edict());
    msg.WriteByte(0);
    msg.WriteByte(2); 
    msg.WriteString("game_destroyed\n");
    msg.End();
}

array<CScheduledFunction@> g_a_lpfnRoboExplosions;

void AP_AllyRobo_Detonate(CBaseEntity@ _Entity) {
    if (_Entity is null) return;

    //g_EntityFuncs.Remove(_Entity);
    _Entity.SetPlayerAlly(false);
    _Entity.SetPlayerAllyDirect(false);
    _Entity.SetClassification(CLASS_BARNACLE);
    _Entity.pev.takedamage = DAMAGE_YES;
    CBaseEntity@ worldspawn = g_EntityFuncs.Instance(0);
    _Entity.TakeDamage(worldspawn.pev, worldspawn.pev, 2048, DMG_BLAST);
    //g_EntityFuncs.CreateExplosion(_Entity.pev.origin, _Entity.pev.angles, null, 200, true);
    CScheduledFunction@ last = g_a_lpfnRoboExplosions[g_a_lpfnRoboExplosions.length() - 1];
    if (last !is null) {
        g_Scheduler.RemoveTimer(last);
        g_a_lpfnRoboExplosions.removeLast();
    }
}

HookReturnCode HOOKED_PlayerTakeDamage(DamageInfo@ _Info) {
    CBaseEntity@ victim = @_Info.pVictim;
    
    if (victim is null or !victim.IsPlayer())
        return HOOK_CONTINUE;
        
    CBasePlayer@ plr = cast<CBasePlayer@>(victim);
    CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(plr.edict()));
    if (data is null) return HOOK_CONTINUE;
    
    if (data.m_bGodMode) {
        if (plr.pev.health <= _Info.flDamage) {
            _Info.bitsDamageType |= DMG_NEVERGIB;
            _Info.bitsDamageType &= ~DMG_ALWAYSGIB;
            _Info.bitsDamageType &= ~DMG_GIB_CORPSE;
            plr.pev.takedamage = DAMAGE_NO;
            plr.pev.flags |= FL_GODMODE;
            plr.pev.health = plr.pev.health + _Info.flDamage;
            plr.pev.flags &= ~FL_GODMODE;
            plr.pev.takedamage = DAMAGE_YES;
        }
    }
    
    return HOOK_CONTINUE;
}

bool CF_UTIL_DoesStringPersistOnlyFromSpaces(const string& in _RawText) {
    if (_RawText[0] != ' ') return false;
    
    bool bPersistsOnlyFromSpaces = true;
    for (uint idx = 1; idx < _RawText.Length(); idx++) {
        if (_RawText[idx] != ' ') {
            bPersistsOnlyFromSpaces = false;
            break;
        }
    }
    
    return bPersistsOnlyFromSpaces;
}

void CF_ResendChatMessageWithColorAccordingToTeam(CBaseEntity@ _Player, string _szMessage) {
    if (_szMessage.Length() == 0 || CF_UTIL_DoesStringPersistOnlyFromSpaces(_szMessage)) return;
    
    string szName = string(_Player.pev.netname);
    string szLogString = szName + " said: " + _szMessage + "\n";
    
    g_EngineFuncs.ServerPrint(szLogString);
    g_Log.PrintF(szLogString);
    
    NetworkMessage m(MSG_ALL, NetworkMessages::NetworkMessageType(74), null);
    m.WriteByte(_Player.entindex());
    //m.WriteByte(2);
    m.WriteString("" + szName + ": " + _szMessage + "\n");
    m.End();
}

void AP_UTIL_TeleportEntitiesByClassnameIntoPoint(const string& in _Classname, Vector _Origin) {
    for (int idx = 0; idx < g_Engine.maxEntities; idx++) {
        CBaseEntity@ entity = g_EntityFuncs.Instance(idx);
        if (entity !is null and entity.pev !is null) {
            if (string(entity.pev.classname) == _Classname) {
                g_EntityFuncs.SetOrigin(entity, _Origin);
            }
        }
    }
}

HookReturnCode HOOKED_ClientSay(SayParameters@ _Params) {
    const CCommand@ args = _Params.GetArguments();
    if (args.ArgC() > 0 and args[0].ToLowercase().Find("!detonate") == 0) {
        if (g_a_hAllyRobos.length() == 0) return HOOK_CONTINUE;
        
        EHandle robo = g_a_hAllyRobos[g_a_hAllyRobos.length() - 1];
        g_a_hAllyRobos.removeLast();
        if (!robo.IsValid()) return HOOK_CONTINUE;
        
        CBaseEntity@ roboEnt = robo.GetEntity();
        CScheduledFunction@ func = g_Scheduler.SetTimeout("AP_AllyRobo_Detonate", 0.05f, @roboEnt);
        g_a_lpfnRoboExplosions.insertLast(@func);
    
        return HOOK_CONTINUE;
    }
    if (args.ArgC() >= 1 and (args[0].Find("/ac") == 0 or args[0].Find("/adminchat") == 0)) {
        CBasePlayer@ sender = _Params.GetPlayer();
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(sender.edict()))) return HOOK_CONTINUE;
        _Params.ShouldHide = true;
        if (_Params.GetCommand() == "/ac" || _Params.GetCommand() == "/adminchat" || _Params.GetCommand() == "/ac " || _Params.GetCommand() == "/adminchat " /* note spaces after commands */) {
            g_PlayerFuncs.ClientPrint(sender, HUD_PRINTTALK, "Usage: " + args[0] + " <message> - Send a message into admin chat.\n");
        
            return HOOK_HANDLED;
        }
        
        array<CBasePlayer@> aPlayersToBeNotified;
        for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
            CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex(idx);
            if (player is null or !player.IsConnected()) continue;
            
            string szSteamID = g_EngineFuncs.GetPlayerAuthId(player.edict());
            if (AP_IsPlayerAllowedToOpenPanel(szSteamID)) aPlayersToBeNotified.insertLast(player);
        }
        
        for (uint idx = 0; idx < aPlayersToBeNotified.length(); idx++) {
            g_PlayerFuncs.SayText(aPlayersToBeNotified[idx], "[AdminChat] " + sender.pev.netname + " says: " + _Params.GetCommand().SubString(args[0].Length() + 1 /* space after command */) + "\n");
        }
        
        return HOOK_HANDLED;
    }
    
    if (args.ArgC() > 0 and args[0].Find("!adminpanel") == 0) {
        CBasePlayer@ player = _Params.GetPlayer();
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(player.edict()))) return HOOK_CONTINUE;
        _Params.ShouldHide = true;
        AP_ShowAdminPanel(player);
        
        return HOOK_HANDLED;
    }
    
    if (args.ArgC() > 0 && args[0].Find(">") == 0) {
        _Params.ShouldHide = true;
        CBasePlayer@ player = _Params.GetPlayer();
            
        int oldClassify = player.Classify();
            
        player.SetClassification(19);
        player.SendScoreInfo();
        player.SetClassification(oldClassify);
        AP_ResendChatMessageWithColorAccordingToTeam("NoPrefix", player, _Params.GetCommand());
        g_Scheduler.SetTimeout("AP_Prefixes_RevertScoreboardColor", 0.1f, EHandle(player));
            
        return HOOK_HANDLED;
    }
    
    bool bTryResendingChatMessage = false;
    
    CAdminData@ theData = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Params.GetPlayer().edict()));
    
    CBasePlayer@ thePlayer = _Params.GetPlayer();
    
    if (theData !is null && theData.m_eListeningMode == kNone && !theData.m_bListeningForValueInChat && AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(thePlayer.edict())) && theData.m_lpszPrefix != "" && !_Params.ShouldHide && args[0].Find("/") == String::INVALID_INDEX) {
        _Params.ShouldHide = true;
        
        AP_ResendChatMessageWithColorAccordingToTeam(theData.m_lpszPrefix, thePlayer, _Params.GetCommand());
        
        if (theData.m_iPrefixColor != -1) {
            int oldClassify = thePlayer.Classify();
            
            thePlayer.SetClassification(theData.m_iPrefixColor);
            thePlayer.SendScoreInfo();
            thePlayer.SetClassification(oldClassify);
            g_Scheduler.SetTimeout("AP_Prefixes_RevertScoreboardColor", 0.1f, EHandle(thePlayer));
        }
        
        return HOOK_HANDLED;
    }
    
    if (theData is null or !theData.m_bListeningForValueInChat or theData.m_eListeningMode == kNone) {
        bTryResendingChatMessage = true;
        
        //return HOOK_CONTINUE;
    }
    
    
    if (theData !is null and theData.m_bMindControllingSomebody and args[0].Find(".stop") == 0) {
        _Params.ShouldHide = true;
        theData.m_bMindControllingSomebody = false;
            
        if (theData.m_hMindControlVictim) {
            g_abIsMindControllingSomebody[thePlayer.entindex()] = false;
            CBaseEntity@ lpVictim = theData.m_hMindControlVictim.GetEntity();
            g_PlayerFuncs.SayText(thePlayer, "[SM] [MindControl] Stopped controlling \"" + string(lpVictim.pev.netname) + "\"\n");
        } else {
            g_PlayerFuncs.SayText(thePlayer, "[SM] [MindControl] Well.. Seems like the victim has left the game. :D\n");
        }
        
        return HOOK_HANDLED;
    }
    
    if (theData !is null and theData.m_bMindControllingSomebody and args[0].Find(".speedstep") == 0) {
        _Params.ShouldHide = true;
        
        if (args.ArgC() < 2) {
            g_PlayerFuncs.SayText(thePlayer, "[SM] [MindControl] Usage: .speedstep <step> - Adjust movement speed of the current victim. Only integers are accepted.\n");
        
            return HOOK_HANDLED;
        }
        
        if (theData.m_hMindControlVictim) {
            g_rgiMindControllingSpeedhackStep[thePlayer.entindex()] = atoi(args[1]);
            g_PlayerFuncs.SayText(thePlayer, "[SM] [MindControl] Changed movement speed step to " + args[1] + "\n");
        } else {
            g_PlayerFuncs.SayText(thePlayer, "[SM] [MindControl] Well.. Seems like the victim has left the game. :D\n");
        }
        
        return HOOK_HANDLED;
    }
    
    if (theData !is null and theData.m_bMindControllingSomebody and args[0].Find(".drop") == 0) {
        _Params.ShouldHide = true;
            
        if (theData.m_hMindControlVictim) {
            CBaseEntity@ lpVictim = theData.m_hMindControlVictim.GetEntity();
            CBasePlayer@ lpVictimPlr = cast<CBasePlayer@>(lpVictim);
            
            EHandle hActiveItem = lpVictimPlr.m_hActiveItem;
            if (!hActiveItem) return HOOK_HANDLED;
            CBaseEntity@ lpActiveItem = hActiveItem.GetEntity();
            CBasePlayerWeapon@ lpWeapon = cast<CBasePlayerWeapon@>(lpActiveItem);
            lpWeapon.DropItem();
        } else {
            g_PlayerFuncs.SayText(thePlayer, "[SM] [MindControl] Well.. Seems like the victim has left the game. :D\n");
        }
        
        return HOOK_HANDLED;
    }
    
    if (!bTryResendingChatMessage) {
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kListeningForClassname) {
            _Params.ShouldHide = true;
            
            AP_UTIL_TeleportEntitiesByClassnameIntoPoint(_Params.GetCommand(), thePlayer.pev.origin);
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
        
            return HOOK_HANDLED;
        }
        
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kSettingSizeOfSth) {
            _Params.ShouldHide = true;
            
            if (!theData.m_hCurrentVictim) {
                g_PlayerFuncs.SayText(thePlayer, "[SM] Uh oh... Something went really wrong...\n");
            
                return HOOK_HANDLED;
            }
            
            float flSize = atof(args[0]);
            
            CBaseEntity@ lpEntity = theData.m_hCurrentVictim.GetEntity();
            
            lpEntity.pev.size.x = flSize;
            lpEntity.pev.size.y = flSize;
            lpEntity.pev.size.z = flSize;
            lpEntity.pev.scale = flSize;
            
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
        
            return HOOK_HANDLED;
        }
    
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kListeningForTargetname) {
            _Params.ShouldHide = true;
            
            AP_UTIL_UseEntityByTargetName(_Params.GetCommand(), thePlayer);
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
        
            return HOOK_HANDLED;
        }
        
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kListeningForGravityValue) {
            _Params.ShouldHide = true;
            
            string szTheValue = args[0];
            
            if (!theData.m_hCurrentVictim) {
                g_EngineFuncs.ServerCommand("sv_gravity " + szTheValue + "\n");
                g_EngineFuncs.ServerExecute();
                theData.m_bListeningForValueInChat = false;
                theData.m_eListeningMode = kNone;
                
                g_PlayerFuncs.ClientPrint(thePlayer, HUD_PRINTTALK, "[SM] Successfully set sv_gravity to \"" + szTheValue + "\"\n");
            } else {
                CBaseEntity@ target = theData.m_hCurrentVictim.GetEntity();
                bool bConsumerAlradyExists = false;
                for (uint idx = 0; idx < g_alpConstantCheatConsumers.length(); idx++) {
                    if (g_alpConstantCheatConsumers[idx].CanCheatsBeApplied()) {
                        CBaseEntity@ ent = g_alpConstantCheatConsumers[idx].m_hTheConsumer;
                        if (ent.entindex() == target.entindex()) {
                            g_alpConstantCheatConsumers[idx].m_flGravity = atof(szTheValue) / 800.f;
                            bConsumerAlradyExists = true;
                            break;
                        }
                    }
                }
                    
                if (!bConsumerAlradyExists) {
                    CConstantCheatConsumer haxxor(EHandle(target));
                    haxxor.m_flGravity = atof(szTheValue) / 800.f;
                    g_alpConstantCheatConsumers.insertLast(haxxor);
                }
                
                g_PlayerFuncs.ClientPrint(thePlayer, HUD_PRINTTALK, "[SM] Successfully set gravity of player \"" + theData.m_hCurrentVictim.GetEntity().pev.netname + "\" to \"" + szTheValue + "\"\n");
                theData.m_bListeningForValueInChat = false;
                theData.m_eListeningMode = kNone;
            }
            
            return HOOK_HANDLED;
        }
        
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kListeningForBanDuration) {
            _Params.ShouldHide = true;
            
            if (args[0] == "cancel") {
                g_PlayerFuncs.SayText(thePlayer, "[SM] Gotcha. Won't ban this player.\n");
                theData.m_eListeningMode = kNone;
            
                return HOOK_HANDLED;
            }
            
            theData.m_lpszDuration = args[0];
            g_PlayerFuncs.SayText(thePlayer, "[SM] Type ban reason into chat.\n");
            g_PlayerFuncs.SayText(thePlayer, "[SM] Type \"cancel\" to undo ban process.\n");
            theData.m_eListeningMode = kListeningForReason;
            
            return HOOK_HANDLED;
        }
        
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kListeningForReason) {
            _Params.ShouldHide = true;
            
            if (args[0] == "cancel") {
                g_PlayerFuncs.SayText(thePlayer, "[SM] Gotcha. Won't ban this player.\n");
                theData.m_bListeningForValueInChat = false;
                theData.m_eListeningMode = kNone;
            
                return HOOK_HANDLED;
            }
            
            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[SM] SteamID " + theData.m_lpszVictimSteamID + " was banned from this server.\n");
            
            g_EngineFuncs.ServerCommand("kick #" + theData.m_lpszVictimSteamID + " \"" + _Params.GetCommand() + "\"\n");
            g_EngineFuncs.ServerCommand("wait\n");
            int dur = atoi(theData.m_lpszDuration);
            if (dur != 2147483647) //left a way to kick a player from server without banning them, but also outputting kewl message about ban. :sunglasses: ~ xWhitey
                g_EngineFuncs.ServerCommand("banid " + theData.m_lpszDuration + " " + theData.m_lpszVictimSteamID + "\n");
            g_EngineFuncs.ServerCommand("wait\n");
            g_EngineFuncs.ServerCommand("writeid\n");
            g_EngineFuncs.ServerExecute();
            
            theData.m_lpszDuration = "";
            theData.m_lpszVictimSteamID = "";
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
            
            return HOOK_HANDLED;
        }
        
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kListeningForKickReason) {
            _Params.ShouldHide = true;
            
            if (args[0] == "cancel") {
                g_PlayerFuncs.SayText(thePlayer, "[SM] Gotcha. Won't kick this player.\n");
                theData.m_bListeningForValueInChat = false;
                theData.m_eListeningMode = kNone;
            
                return HOOK_HANDLED;
            }
            
            g_EngineFuncs.ServerCommand("kick #" + theData.m_lpszVictimSteamID + " \"" + _Params.GetCommand() + "\"\n");
            g_EngineFuncs.ServerExecute();
            
            theData.m_lpszDuration = "";
            theData.m_lpszVictimSteamID = "";
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
            
            return HOOK_HANDLED;
        }
        
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kListeningForBotName) {
            _Params.ShouldHide = true;
            
            CBasePlayer@ bot = g_PlayerFuncs.CreateBot(_Params.GetCommand());
            if (bot is null) {
                g_PlayerFuncs.SayText(thePlayer, "[SM] Couldn't create a bot. (Possible reasons: reached maxplayers OR the name is already taken)\n");
                return HOOK_HANDLED;
            }
            g_a_lpBots.insertLast(@bot);
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
        
            return HOOK_HANDLED;
        }
        
        if (theData !is null and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kSendingMessageAsAPlayer and theData.m_hCurrentVictim.GetEntity() !is null) {
            _Params.ShouldHide = true;
            CBasePlayer@ victim = cast<CBasePlayer@>(theData.m_hCurrentVictim.GetEntity());
            
            AP_UTIL_Slowhack(victim, "cmd say \"" + _Params.GetCommand() + "\"");
            
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
            theData.m_hCurrentVictim = null;
            
            return HOOK_HANDLED;
        }
        
        if (theData.m_hCurrentVictim.GetEntity() is null and args.ArgC() > 0 and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kExplosion) { //explosion
            _Params.ShouldHide = true;
            float value = atof(args[0]);
            
            g_EntityFuncs.CreateExplosion(AP_UTIL_GetEyePosRayCastResult(thePlayer), thePlayer.pev.angles, null, int(value), true);
            
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
            
            return HOOK_HANDLED;
        }
        
        if (theData.m_hCurrentVictim.GetEntity() is null and args.ArgC() > 0 and theData.m_bListeningForValueInChat and theData.m_eListeningMode == kAllyExplosion) { //explosion
            _Params.ShouldHide = true;
            float value = atof(args[0]);
            
            g_EntityFuncs.CreateExplosion(AP_UTIL_GetEyePosRayCastResult(thePlayer), thePlayer.pev.angles, thePlayer.edict(), int(value), true);
            
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
            
            return HOOK_HANDLED;
        }
        
        if (theData.m_bListeningForValueInChat and 
            theData.m_hCurrentVictim.GetEntity() !is null and theData.m_eListeningMode == kGivingSth and args.ArgC() > 0) {
            _Params.ShouldHide = true;
            float value = atof(args[0]);
            
            if (theData.m_eGivingWhat == kGiveHealth) {
                if (theData.m_ePlayerMgmt_GiveSth_Mode == kInvalid) {
                    theData.m_hCurrentVictim = null;
                    theData.m_bListeningForValueInChat = false;
                    theData.m_eListeningMode = kNone;
                    
                    return HOOK_HANDLED;
                }
            
                CBasePlayer@ pl = cast<CBasePlayer@>(theData.m_hCurrentVictim.GetEntity());
                if (theData.m_ePlayerMgmt_GiveSth_Mode == kAdd)
                    pl.TakeHealth(value, 0, 2147483647);
                else if (theData.m_ePlayerMgmt_GiveSth_Mode == kSet)
                    pl.pev.health = value;
            } else if (theData.m_eGivingWhat == kGiveArmor) {
                if (theData.m_ePlayerMgmt_GiveSth_Mode == kInvalid) {
                    theData.m_hCurrentVictim = null;
                    theData.m_bListeningForValueInChat = false;
                    theData.m_eListeningMode = kNone;
                    
                    return HOOK_HANDLED;
                }
            
                CBasePlayer@ pl = cast<CBasePlayer@>(theData.m_hCurrentVictim.GetEntity());
                if (theData.m_ePlayerMgmt_GiveSth_Mode == kAdd)
                    pl.TakeArmor(value, 0, 2147483647);
                else if (theData.m_ePlayerMgmt_GiveSth_Mode == kSet)
                    pl.pev.armorvalue = value;
            } else if (theData.m_eGivingWhat == kGiveScore) {
                if (theData.m_ePlayerMgmt_GiveSth_Mode == kInvalid) {
                    theData.m_hCurrentVictim = null;
                    theData.m_bListeningForValueInChat = false;
                    theData.m_eListeningMode = kNone;
                    
                    return HOOK_HANDLED;
                }
            
                CBasePlayer@ pl = cast<CBasePlayer@>(theData.m_hCurrentVictim.GetEntity());
                if (theData.m_ePlayerMgmt_GiveSth_Mode == kAdd)
                    pl.AddPoints(int(value), true);
                else if (theData.m_ePlayerMgmt_GiveSth_Mode == kSet)
                    pl.pev.frags = value;
            }
            theData.m_ePlayerMgmt_GiveSth_Mode = kInvalid;
            theData.m_hCurrentVictim = null;
            theData.m_bListeningForValueInChat = false;
            theData.m_eListeningMode = kNone;
            
            return HOOK_HANDLED;
        }
        
        if (theData.m_eListeningMode == kFakeNickname and theData.m_bListeningForValueInChat and args.ArgC() >= 1) {
            _Params.ShouldHide = true;
                
            thePlayer.pev.netname = _Params.GetCommand();
            theData.m_eListeningMode = kNone;
            theData.m_bListeningForValueInChat = false;
            g_PlayerFuncs.SayText(thePlayer, "[SM] Successfully set your fake name to \"" + _Params.GetCommand() + "\"\n");
                
            return HOOK_HANDLED;
        }
    }
    
    if (bTryResendingChatMessage) {
        if (_Params.ShouldHide) return HOOK_CONTINUE;
        if (args[0].Find("/") == 0) return HOOK_CONTINUE;
        
        _Params.ShouldHide = true;
        CF_ResendChatMessageWithColorAccordingToTeam(_Params.GetPlayer(), _Params.GetCommand());
    }
    
    return HOOK_CONTINUE;
}

void AP_Prefixes_RevertScoreboardColor(EHandle _hPlayer) {
    CBasePlayer@ thePlayer = cast<CBasePlayer@>(_hPlayer.GetEntity());
    if (thePlayer is null or !thePlayer.IsConnected()) {
        return;
    }
    
    thePlayer.SendScoreInfo();
}

HookReturnCode HOOKED_ClientPutInServer(CBasePlayer@ _Player) {
    string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
    
    g_dictIPAddresses[szSteamID] = string(g_dictIPAddresses[_Player.pev.netname]);
    
    if (g_dictIPAddresses.exists(_Player.pev.netname))
        g_dictIPAddresses.delete(_Player.pev.netname);

    return HOOK_CONTINUE;
}

HookReturnCode HOOKED_ClientDisconnect(CBasePlayer@ _Player) {
    string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
    
    if (g_dictIPAddresses.exists(szSteamID))
        g_dictIPAddresses.delete(szSteamID);
        
    for (uint idx = 0; idx < g_a_lpAdmins.length(); idx++) {
        if (szSteamID == g_a_lpAdmins[idx].m_lpszSteamID) {
            g_a_lpAdmins.removeAt(idx);
            break;
        }
    }

    return HOOK_CONTINUE;
}

HookReturnCode HOOKED_ClientConnected(edict_t@ _ThePlayer, const string& in _PlayerName, const string& in _IPAddress, bool& out _bDisallowJoin, string& out _RejectReason) {
    //g_dictIPAddresses[g_EngineFuncs.GetPlayerAuthId(_ThePlayer)] = _IPAddress;
    g_dictIPAddresses[_PlayerName] = _IPAddress;
    
    return HOOK_CONTINUE;
}

HookReturnCode HOOKED_MapChange() {
    g_a_lpBots.resize(0);
    g_a_hAllyRobos.resize(0);
    g_alpConstantCheatConsumers.resize(0);
    g_abIsMindControllingSomebody.resize(0);
    g_abIsMindControllingSomebody.resize(33);
    g_rglpTheMindControllingSlave.resize(0);
    g_rglpTheMindControllingSlave.resize(33);
    g_rgiMindControllingSpeedhackStep.resize(0);
    g_rgiMindControllingSpeedhackStep.resize(33);
    
    for (uint idx = 0; idx < g_a_lpAdmins.length(); idx++) {
        g_a_lpAdmins[idx].m_bMindControllingSomebody = false;
    }

    return HOOK_CONTINUE;
}

/**
 * Implementation of menus start 
 */
 
void AP_MainMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText.EndsWith("\n") ? _Item.m_lpszText.SubString(0, _Item.m_lpszText.Length() - 1) : _Item.m_lpszText);
        
        AP_AlterEgo_Log(string(_Player.pev.netname) + " has opened " + szChoice + " menu.", true);
        
        if (szChoice == g_lpszPlayerManagementMenu_Title) {
            if (g_lpPlayerManagementMenu is null) {
                @g_lpPlayerManagementMenu = CCustomTextMenu(AP_PlayerManagementMenuCB);
            
                /* Player management menu items start */
                //Page 1
                g_lpPlayerManagementMenu.AddItem((g_lpszKillPlayersMenu_Title));
                g_lpPlayerManagementMenu.AddItem((g_lpszRespawnPlayersMenu_Title));
                g_lpPlayerManagementMenu.AddItem((g_lpszPlayerManagementMenu_RevivePlayersMenu_Title));
                g_lpPlayerManagementMenu.AddItem((g_lpszPlayerManagementMenu_GiveHealth));
                g_lpPlayerManagementMenu.AddItem((g_lpszPlayerManagementMenu_GiveArmor));
                g_lpPlayerManagementMenu.AddItem((g_lpszPlayerManagementMenu_GiveScore));
                g_lpPlayerManagementMenu.AddItem((g_lpszShowIPAddressesMenu_Title + "\n"));
                //Page 2
                g_lpPlayerManagementMenu.AddItem((g_lpszPlayerManagementMenu_KickPlayers));
                g_lpPlayerManagementMenu.AddItem((g_lpszPlayerManagementMenu_BanPlayers));
                g_lpPlayerManagementMenu.AddItem((g_lpszPlayerManagementMenu_FreezePlayers));
                /* Player management menu items end */
                
                g_lpPlayerManagementMenu.SetTitle((g_lpszPlayerManagementMenu_Title));
                
                g_lpPlayerManagementMenu.Register();
            }
            
            g_lpPlayerManagementMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_Title) {
            if (g_lpFunMenu is null) {
                @g_lpFunMenu = CCustomTextMenu(AP_FunMenuCB);
                g_lpFunMenu.SetTitle((g_lpszFunMenu_Title));
                
                /* Fun menu items start */
                g_lpFunMenu.AddItem((g_lpszFunMenu_SpinCameraOf_Title));
                g_lpFunMenu.AddItem((g_lpszFunMenu_SetSizeOf_Title));
                g_lpFunMenu.AddItem((g_lpszFunMenu_SendMessageAs_Title));
                g_lpFunMenu.AddItem((g_lpszFunMenu_CrashGameOf_Title));
                g_lpFunMenu.AddItem((g_lpszFunMenu_ChangeGravity_Title));
                g_lpFunMenu.AddItem((g_lpszFunMenu_DestroyGameOf_Title));
                g_lpFunMenu.AddItem((g_lpszFunMenu_ControlMovementOf_Title));
                g_lpFunMenu.AddItem((g_lpszFunMenu_ChangeSkybox_Title));
                /* Fun menu items end */
                
                g_lpFunMenu.Register();
            }
            
            g_lpFunMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszBotManagementMenu_Title) {
            if (g_lpBotManagementMenu is null) {
                @g_lpBotManagementMenu = CCustomTextMenu(AP_BotManagementMenuCB);
                g_lpBotManagementMenu.SetTitle((g_lpszBotManagementMenu_Title));
                
                /* Bot management menu items start */
                g_lpBotManagementMenu.AddItem((g_lpszBotManagementMenu_CreateBot));
                g_lpBotManagementMenu.AddItem((g_lpszBotManagementMenu_RemoveBot));
                /* Bot management menu items end */
                
                g_lpBotManagementMenu.Register();
            }
            
            g_lpBotManagementMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_Title) {
            if (g_lpEntityManagementMenu is null) {
                @g_lpEntityManagementMenu = CCustomTextMenu(AP_EntityManagementMenuCB);
                g_lpEntityManagementMenu.SetTitle((g_lpszEntityManagementMenu_Title));
                
                /* Entity management menu items start */
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_SpawnEntities);
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_DeleteEntities);
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_UseEntityUnderCrosshair);
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_CreateExplosionAtCrosshair);
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_CreateCheckpoint);
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_ActivateLastCreatedCheckpoint);
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_Teleport_Title);
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_UseEntityByTargetname_Title);
                g_lpEntityManagementMenu.AddItem(g_lpszEntityManagementMenu_CreateAllyExplosionAtCrosshair);
                /* Entity management menu items end */
                
                g_lpEntityManagementMenu.Register();
            }
            
            g_lpEntityManagementMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszSelfManagementMenu_Title) {
            if (g_lpSelfManagementMenu is null) {
               @g_lpSelfManagementMenu = CCustomTextMenu(AP_SelfManagementMenuCB);
                g_lpSelfManagementMenu.SetTitle((g_lpszSelfManagementMenu_Title));
                
                /* Self management menu items start */
                g_lpSelfManagementMenu.AddItem((g_lpszSelfManagementMenu_FakeNickname));
                g_lpSelfManagementMenu.AddItem((g_lpszSelfManagementMenu_GiveEntmover));
                g_lpSelfManagementMenu.AddItem((g_lpszSelfManagementMenu_TakeEntmover));
                g_lpSelfManagementMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_Title));
                g_lpSelfManagementMenu.AddItem((g_lpszSelfManagementMenu_ToggleGodMode));
                /* Self management menu items end */
                
                g_lpSelfManagementMenu.Register();
            }
            
            g_lpSelfManagementMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszServerManagementMenu_Title) {
            if (g_lpServerManagementMenu is null) {
                @g_lpServerManagementMenu = CCustomTextMenu(AP_ServerManagementMenuCB);
                g_lpServerManagementMenu.SetTitle((g_lpszServerManagementMenu_Title));
                
                /* Server management menu items start */
                g_lpServerManagementMenu.AddItem((g_lpszServerManagementMenu_ChangeMapToCampaignOne));
                g_lpServerManagementMenu.AddItem((g_lpszServerManagementMenu_RestartCurrentMap));
                /* Server management menu items end */
                
                g_lpServerManagementMenu.Register();
            }
            
            g_lpServerManagementMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszCheatsMenu_Title) {
            if (g_lpCheatsMenu is null) {
                @g_lpCheatsMenu = CCustomTextMenu(AP_CheatsMenuCB);
                g_lpCheatsMenu.SetTitle((g_lpszCheatsMenu_Title));
                
                /* Cheats management menu items start */
                g_lpCheatsMenu.AddItem((g_lpszCheatsMenu_ToggleNoclip));
                g_lpCheatsMenu.AddItem((g_lpszCheatsMenu_GiveSuit));
                g_lpCheatsMenu.AddItem((g_lpszCheatsMenu_Impulse101));
                g_lpCheatsMenu.AddItem((g_lpszCheatsMenu_GiveEverything));
                g_lpCheatsMenu.AddItem((g_lpszCheatsMenu_InfiniteAmmo));
                /* Cheats management menu items end */
                
                g_lpCheatsMenu.Register();
            }
           
            g_lpCheatsMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszMiscellanea_Title) {
            if (g_lpMiscellaneaMenu is null) {
                @g_lpMiscellaneaMenu = CCustomTextMenu(AP_MiscellaneaMenuCB);
                g_lpMiscellaneaMenu.SetTitle(g_lpszMiscellanea_Title);
            
                /* Miscellanea menu items start */
                g_lpMiscellaneaMenu.AddItem(g_lpszMiscellanea_TemporaryGiveAdminAccess);
                g_lpMiscellaneaMenu.AddItem(g_lpszMiscellanea_TakeAdminAccess);
                g_lpMiscellaneaMenu.AddItem(g_lpszMiscellanea_ToggleLogging);
                g_lpMiscellaneaMenu.AddItem(g_lpszMiscellanea_ToggleAnticheatLogging);
                /* Miscellanea menu items end */
            }
            
            g_lpMiscellaneaMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszMiscellaneous_Title) {
            if (g_lpMiscellaneousN2Menu is null) {
                @g_lpMiscellaneousN2Menu = CCustomTextMenu(AP_MiscellaneousMenuCB);
                g_lpMiscellaneousN2Menu.SetTitle(g_lpszMiscellaneous_Title);
            
                /* Miscellaneous #2 menu items start */
                g_lpMiscellaneousN2Menu.AddItem(g_lpszMiscellaneous_ToggleServersideSpeedhack);
                /* Miscellaneous #2 menu items end */
            }
            
            g_lpMiscellaneousN2Menu.Open(0, 0, _Player);
        }
    }
}

void AP_MiscellaneousMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = _Item.m_lpszText;
        
        if (szChoice == g_lpszMiscellaneous_ToggleServersideSpeedhack) {
            bool bConsumerAlradyExists = false;
            for (uint idx = 0; idx < g_alpConstantCheatConsumers.length(); idx++) {
                if (g_alpConstantCheatConsumers[idx].CanCheatsBeApplied()) {
                    CBaseEntity@ ent = g_alpConstantCheatConsumers[idx].m_hTheConsumer;
                    if (ent.entindex() == _Player.entindex()) {
                        g_alpConstantCheatConsumers[idx].m_bSpeedhack = !g_alpConstantCheatConsumers[idx].m_bSpeedhack;
                        bConsumerAlradyExists = true;
                        break;
                    }
                }
            }
                
            if (!bConsumerAlradyExists) {
                CConstantCheatConsumer haxxor(EHandle(_Player));
                haxxor.m_bSpeedhack = true;
                g_alpConstantCheatConsumers.insertLast(haxxor);
            }
                
            g_PlayerFuncs.SayText(_Player, "[SM] Turned speedhack " + (bConsumerAlradyExists ? "off.\n" : "on.\n"));
        }
    }
}

void AP_MiscellaneaMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        if (szSteamID != g_lpszTheOwner) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] You do not have enough permissions to use this menu.\n");
        
            return;
        }
        
        string szChoice = _Item.m_lpszText;
        
        if (szChoice == g_lpszMiscellanea_TemporaryGiveAdminAccess) {
            if (g_lpMiscellaneaMenu_PlayersListMenu !is null) {
                g_lpMiscellaneaMenu_PlayersListMenu.Unregister();
                @g_lpMiscellaneaMenu_PlayersListMenu = null;
            }
        
            @g_lpMiscellaneaMenu_PlayersListMenu = CCustomTextMenu(AP_MiscellaneaMenu_GiveTemporaryAdminAccessCB);
            g_lpMiscellaneaMenu_PlayersListMenu.SetTitle((g_lpszMiscellanea_Title + " \\r->\\y " + g_lpszMiscellanea_TemporaryGiveAdminAccess));
             
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpMiscellaneaMenu_PlayersListMenu);
            
            g_lpMiscellaneaMenu_PlayersListMenu.Register();
            
            g_lpMiscellaneaMenu_PlayersListMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszMiscellanea_TakeAdminAccess) {
            if (g_lpMiscellaneaMenu_PlayersListMenu !is null) {
                g_lpMiscellaneaMenu_PlayersListMenu.Unregister();
                @g_lpMiscellaneaMenu_PlayersListMenu = null;
            }
        
            @g_lpMiscellaneaMenu_PlayersListMenu = CCustomTextMenu(AP_MiscellaneaMenu_TakeAdminAccessCB);
            g_lpMiscellaneaMenu_PlayersListMenu.SetTitle((g_lpszMiscellanea_Title + " \\r->\\y " + g_lpszMiscellanea_TakeAdminAccess));
             
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpMiscellaneaMenu_PlayersListMenu);
            
            g_lpMiscellaneaMenu_PlayersListMenu.Register();
            
            g_lpMiscellaneaMenu_PlayersListMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszMiscellanea_ToggleLogging) {
            g_bLoggingEnabled = !g_bLoggingEnabled;
        } else if (szChoice == g_lpszMiscellanea_ReloadPlugins) {
            g_EngineFuncs.ServerCommand("as_reloadplugins");
            g_EngineFuncs.ServerExecute();
        } else if (szChoice == g_lpszMiscellanea_ToggleAnticheatLogging) {
            AP_UTIL_Slowhack(_Player, ";.__anticheat__ toggleVerbose\n");
        }
    }
}

void AP_MiscellaneaMenu_GiveTemporaryAdminAccessCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        if (szSteamID != g_lpszTheOwner) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] You do not have enough permissions to open this menu.\n");
        
            return;
        }
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ receiver = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (receiver is null) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Something went wrong...\n");
            
            return;
        }
        
        string szReceiverSteamID = g_EngineFuncs.GetPlayerAuthId(receiver.edict());
        
        if (AP_IsPlayerAllowedToOpenPanel(szReceiverSteamID)) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Receiver is already an admin!\n");
        } else {
            g_a_lpszAllowedSteamIDs.insertLast(szReceiverSteamID);
        }
   }
}

void AP_MiscellaneaMenu_TakeAdminAccessCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        if (szSteamID != g_lpszTheOwner) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] You do not have enough permissions to open this menu.\n");
        
            return;
        }
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ receiver = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (receiver is null) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Something went wrong...\n");
            
            return;
        }
        
        string szReceiverSteamID = g_EngineFuncs.GetPlayerAuthId(receiver.edict());
        
        if (!AP_IsPlayerAllowedToOpenPanel(szReceiverSteamID)) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Receiver is not an admin!\n");
        } else {
            for (uint idx = 0; idx < g_a_lpszAllowedSteamIDs.length(); idx++) {
                if (g_a_lpszAllowedSteamIDs[idx] == szReceiverSteamID)
                    g_a_lpszAllowedSteamIDs.removeAt(idx);
            }
        }
    }
}

void GameEnd(const string&in _NextMap) {
    g_EngineFuncs.ServerCommand("mp_nextmap_cycle " + _NextMap + "\n");
    CBaseEntity@ endEnt = g_EntityFuncs.CreateEntity("game_end");
    endEnt.Use(null, null, USE_TOGGLE);
}

void SendSpeakSoundStuffTextMsg(const string& in _szSoundName) {
    string strMsg = "spk \"" + _szSoundName + "\"";
    
    NetworkMessage msg(MSG_ALL, NetworkMessages::SVC_STUFFTEXT, null);
    msg.WriteString(strMsg);
    msg.End();
}

void AP_ServerManagementMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;

        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszServerManagementMenu_ChangeMapToCampaignOne) {
            if (g_lpServerManagementMenu_ChangeMapToCampaignOneMenu is null) {
                @g_lpServerManagementMenu_ChangeMapToCampaignOneMenu = CCustomTextMenu(AP_ServerManagementMenu_ChangeMapToCampaignOneCB);
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.SetTitle((g_lpszServerManagementMenu_Title + " \\r->\\y " + g_lpszServerManagementMenu_ChangeMapToCampaignOne));
                
                /* Server management \\r->\\y Change map to campaign one menu items start */
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.AddItem(("dynamic_mapvote\n"));
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.AddItem(("Half-Life"));
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.AddItem(("Half-Life: Blue Shift"));
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.AddItem(("Half-Life: Opposing Force"));
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.AddItem(("Half-Life: Decay\n"));
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.AddItem(("Crack-Life"));
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.AddItem(("QuickSurvivalGames"));
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.AddItem(("They Hunger"));
                /* Server management \\r->\\y Change map to campaign one menu items end */
                
                g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.Register();
            }
            
            g_lpServerManagementMenu_ChangeMapToCampaignOneMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszServerManagementMenu_RestartCurrentMap) {
            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[SM] Server was forced to restart current map.\n");
            SendSpeakSoundStuffTextMsg("vox/loading environment on to your computer");
            GameEnd(g_Engine.mapname);
        }
    }
}

void AP_ServerManagementMenu_ChangeMapToCampaignOneCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;

        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == "dynamic_mapvote") {
            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[SM] Server was forced to change the map to \"dynamic_mapvote\".\n");
            SendSpeakSoundStuffTextMsg("vox/loading environment on to your computer");
            GameEnd("dynamic_mapvote");
        
            return;
        }
        
        if (szChoice == "Half-Life") {
            if (g_lpServerManagementMenu_CampaignChosenMenu !is null) {
                g_lpServerManagementMenu_CampaignChosenMenu.Unregister();
                @g_lpServerManagementMenu_CampaignChosenMenu = null;
            }
        
            if (g_lpServerManagementMenu_CampaignChosenMenu is null) {
                @g_lpServerManagementMenu_CampaignChosenMenu = CCustomTextMenu(AP_ServerManagementMenu_CampaignChosenCB);
            
                //Page 1
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_t00"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c00"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c01_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c01_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c02_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c02_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c03"));
                //Page 2
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c04"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c05_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c05_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c05_a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c06"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c07_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c07_a2"));
                //Page 3
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c08_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c08_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c09"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c10"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c11_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c11_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c11_a3"));
                //Page 4
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c11_a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c11_a5"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c12"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c13_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c13_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c13_a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c13_a4"));
                //Page 5
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c14"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c15"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c16_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c16_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c16_a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c16_a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c17"));
                //Page 6
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("hl_c18"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + "Half-Life"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.Register();
            }
            
            g_lpServerManagementMenu_CampaignChosenMenu.Open(0, 0, _Player);
        } else if (szChoice == "Half-Life: Blue Shift") {
            if (g_lpServerManagementMenu_CampaignChosenMenu !is null) {
                g_lpServerManagementMenu_CampaignChosenMenu.Unregister();
                @g_lpServerManagementMenu_CampaignChosenMenu = null;
            }
            
            if (g_lpServerManagementMenu_CampaignChosenMenu is null) {
                @g_lpServerManagementMenu_CampaignChosenMenu = CCustomTextMenu(AP_ServerManagementMenu_CampaignChosenCB);
            
                //Page 1
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_tram1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_tram2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_tram3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_security1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_security2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_maint"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_elevator"));
                //Page 2
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_canal1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_canal1b"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_canal2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_canal3\n"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard3a"));
                //Page 3
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard3b"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard4a"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard5"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_yard5a"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_teleport1"));
                //Page 4
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_xen1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_xen2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_xen3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_xen4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_xen5"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_xen6\n"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_teleport2"));
                //Page 5
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_power1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_power2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("ba_outro"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + "Half-Life: Blue Shift"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.Register();
            }
            
            g_lpServerManagementMenu_CampaignChosenMenu.Open(0, 0, _Player);
        } else if (szChoice == "Half-Life: Opposing Force") {
            if (g_lpServerManagementMenu_CampaignChosenMenu !is null) {
                g_lpServerManagementMenu_CampaignChosenMenu.Unregister();
                @g_lpServerManagementMenu_CampaignChosenMenu = null;
            }
            
            if (g_lpServerManagementMenu_CampaignChosenMenu is null) {
                @g_lpServerManagementMenu_CampaignChosenMenu = CCustomTextMenu(AP_ServerManagementMenu_CampaignChosenCB);
            
                //Page 1
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of0a0"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of1a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of1a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of1a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of1a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of1a5"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of1a5b"));
                //Page 2
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of1a6"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of2a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of2a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of2a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of2a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of2a5"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of2a6"));
                //Page 3
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of3a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of3a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of3a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of3a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of3a5"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of3a6"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of4a1"));
                //Page 4
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of4a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of4a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of4a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of4a5"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of5a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of5a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of5a3"));
                //Page 5
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of5a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of6a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of6a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of6a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of6a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of6a4b"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of6a5"));
                //Page 7
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("of7a0"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + "Half-Life: Opposing Force"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.Register();
            }
            
            g_lpServerManagementMenu_CampaignChosenMenu.Open(0, 0, _Player);
        } else if (szChoice == "Half-Life: Decay") {
            if (g_lpServerManagementMenu_CampaignChosenMenu !is null) {
                g_lpServerManagementMenu_CampaignChosenMenu.Unregister();
                @g_lpServerManagementMenu_CampaignChosenMenu = null;
            }
            
            if (g_lpServerManagementMenu_CampaignChosenMenu is null) {
                @g_lpServerManagementMenu_CampaignChosenMenu = CCustomTextMenu(AP_ServerManagementMenu_CampaignChosenCB);
            
                //Page 1
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_accident1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_accident2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_hazard"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_uplink"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_dampen"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_dorms"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_signal"));
                //Page 2
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_focus"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_lasers"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_fubar"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_outro"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("dy_alien"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + "Half-Life: Decay"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.Register();
            }
            
            g_lpServerManagementMenu_CampaignChosenMenu.Open(0, 0, _Player);
        } else if (szChoice == "Crack-Life") {
            if (g_lpServerManagementMenu_CampaignChosenMenu !is null) {
                g_lpServerManagementMenu_CampaignChosenMenu.Unregister();
                @g_lpServerManagementMenu_CampaignChosenMenu = null;
            }
            
            if (g_lpServerManagementMenu_CampaignChosenMenu is null) {
                @g_lpServerManagementMenu_CampaignChosenMenu = CCustomTextMenu(AP_ServerManagementMenu_CampaignChosenCB);
            
                //Page 1
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c00"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c01_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c01_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c02_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c02_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c03"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c04"));
                //Page 2
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c05_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c05_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c05_a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c06"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c07_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c07_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c08_a1"));
                //Page 3
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c08_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c09"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c10"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c11_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c11_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c11_a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c11_a4"));
                //Page 4
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c11_a5"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c12"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c13_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c13_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c13_a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c13_a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c14"));
                //Page 5
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c15"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c16_a1"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c16_a2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c16_a3"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c16_a4"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c17"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("cl_c18"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + "Crack-Life"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.Register();
            }
            
            g_lpServerManagementMenu_CampaignChosenMenu.Open(0, 0, _Player);
        } else if (szChoice == "QuickSurvivalGames") {
            if (g_lpServerManagementMenu_CampaignChosenMenu !is null) {
                g_lpServerManagementMenu_CampaignChosenMenu.Unregister();
                @g_lpServerManagementMenu_CampaignChosenMenu = null;
            }
            
            if (g_lpServerManagementMenu_CampaignChosenMenu is null) {
                @g_lpServerManagementMenu_CampaignChosenMenu = CCustomTextMenu(AP_ServerManagementMenu_CampaignChosenCB);
            
                //Page 1
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("qsg_fdust2x2"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("qsg_crossfire-src"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + "QuickSurvivalGames"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.Register();
            }
            
            g_lpServerManagementMenu_CampaignChosenMenu.Open(0, 0, _Player);
        } else if (szChoice == "They Hunger") {
            if (g_lpServerManagementMenu_CampaignChosenMenu !is null) {
                g_lpServerManagementMenu_CampaignChosenMenu.Unregister();
                @g_lpServerManagementMenu_CampaignChosenMenu = null;
            }
            
            if (g_lpServerManagementMenu_CampaignChosenMenu is null) {
                @g_lpServerManagementMenu_CampaignChosenMenu = CCustomTextMenu(AP_ServerManagementMenu_CampaignChosenCB);
            
                //Page 1
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep1_00"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep1_01"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep1_02"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep1_03"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep1_04"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep1_05\n"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep2_00"));
                //Page 2
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep2_01"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep2_02"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep2_03"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep2_04\n"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep3_00"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep3_01"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep3_02"));
                //Page 3
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep3_03"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep3_04"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep3_05"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep3_06"));
                g_lpServerManagementMenu_CampaignChosenMenu.AddItem(("th_ep3_07"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + "They Hunger"));
                
                g_lpServerManagementMenu_CampaignChosenMenu.Register();
            }
            
            g_lpServerManagementMenu_CampaignChosenMenu.Open(0, 0, _Player);
        }
    }
}

void AP_ServerManagementMenu_CampaignChosenCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;

        string szChoice = (_Item.m_lpszText);
        
        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[SM] Server was forced to change the map to \"" + szChoice + "\".\n");
        SendSpeakSoundStuffTextMsg("vox/loading environment on to your computer");
        GameEnd(szChoice);
    }
}

/* Constant cheat applier */
void AP_ApplyCheatsConstantly() {
    for (uint idx = 0; idx < g_alpConstantCheatConsumers.length(); idx++) {
        CBasePlayer@ plr = cast<CBasePlayer@>(g_alpConstantCheatConsumers[idx].m_hTheConsumer.GetEntity());
        if (plr is null)
            continue;
            
        plr.pev.gravity = g_alpConstantCheatConsumers[idx].m_flGravity;
            
        if (g_alpConstantCheatConsumers[idx].m_bNoclip)
            plr.pev.movetype = MOVETYPE_NOCLIP;
        if (g_alpConstantCheatConsumers[idx].m_bSpeedhack) {
            float flForwardSpeed = 0.0f;
            if ((plr.pev.button & IN_FORWARD) != 0)
                flForwardSpeed += 320.f;
            if ((plr.pev.button & IN_BACK) != 0)
                flForwardSpeed -= 320.f;
                
            float flSideSpeed = 0.0f;
            if ((plr.pev.button & IN_MOVERIGHT) != 0)
                flSideSpeed += 320.f;
            if ((plr.pev.button & IN_MOVELEFT) != 0)
                flSideSpeed -= 320.f;
            
            if ((plr.pev.button & IN_RUN) != 0) {
                flForwardSpeed = (flForwardSpeed) * 1.0f / 3.0f;
                flSideSpeed = (flSideSpeed) * 1.0f / 3.0f;
            }
            g_EngineFuncs.RunPlayerMove(plr.edict(), plr.pev.angles, flForwardSpeed, flSideSpeed, 0.0f, plr.pev.button, plr.pev.impulse, 127);
        }
    }
}

//Credits: wootguy
void AP_UTIL_Cheats_GiveItem(CBasePlayer@ _Player, array<string>@ _Args) {
    bool bValidItem = false;
    bool bIsAmmo = _Args[0].Find("ammo_") == 0;
    if (_Args[0].Find("weapon_") == 0) bValidItem = true;
    if (bIsAmmo) bValidItem = true;
    if (_Args[0].Find("item_") == 0) bValidItem = true;
    
    if (bValidItem and @_Player.HasNamedPlayerItem(_Args[0]) == @null)  {
        if (bIsAmmo) {
            dictionary keys;
            keys["origin"] = _Player.pev.origin.ToString();
            CBaseEntity@ item = g_EntityFuncs.CreateEntity(_Args[0], keys, false);
            item.pev.spawnflags |= SF_NORESPAWN;
            g_EntityFuncs.DispatchSpawn(item.edict());
            item.Touch(_Player);
        } else {
            _Player.GiveNamedItem(_Args[0], 0, 0);
        }
    }
}

//Credits: wootguy
void AP_UTIL_Cheats_GiveAmmoCapped(CBasePlayer@ _Player, int _AmmoIdx, string _Item, int _Count) {
    for (int i = 0; i < _Count; i++) {
        if (_Player.m_rgAmmo(_AmmoIdx) < _Player.GetMaxAmmo(_AmmoIdx)) {
            array<string> args = { _Item };
            AP_UTIL_Cheats_GiveItem(_Player, args);
        }
    }
}

void AP_CheatsMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;

        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszCheatsMenu_ToggleNoclip) {
            bool bConsumerAlradyExists = false;
            for (uint idx = 0; idx < g_alpConstantCheatConsumers.length(); idx++) {
                if (g_alpConstantCheatConsumers[idx].CanCheatsBeApplied()) {
                    CBaseEntity@ ent = g_alpConstantCheatConsumers[idx].m_hTheConsumer;
                    if (ent.entindex() == _Player.entindex()) {
                        g_alpConstantCheatConsumers[idx].m_bNoclip = !g_alpConstantCheatConsumers[idx].m_bNoclip;
                        ent.pev.movetype = MOVETYPE_WALK;
                        bConsumerAlradyExists = true;
                        break;
                    }
                }
            }
            
            if (!bConsumerAlradyExists) {
                CConstantCheatConsumer haxxor(EHandle(_Player));
                haxxor.m_bNoclip = true;
                g_alpConstantCheatConsumers.insertLast(haxxor);
            }
            
            g_PlayerFuncs.SayText(_Player, "[SM] Turned noclip " + (bConsumerAlradyExists ? "off.\n" : "on.\n"));
            
            g_lpCheatsMenu.Open(0, _Listener.m_iCurrentPage, _Player);
        } else if (szChoice == g_lpszCheatsMenu_GiveSuit) {
            _Player.SetHasSuit(!_Player.HasSuit());
            
            g_lpCheatsMenu.Open(0, _Listener.m_iCurrentPage, _Player);
        } else if (szChoice == g_lpszCheatsMenu_Impulse101) {
            bool bIsCrackLife = false;
            bool bIsAllowed = false; //unused
            string mapname = g_Engine.mapname;
            if (mapname.Find("cracklife_") == 0 || mapname.Find("cl_") == 0) {
                bIsCrackLife = true;
                bIsAllowed = true;
            }
            
            if (mapname.Find("hl_") == 0 || mapname.Find("dy_") == 0 || mapname.Find("qsg_") == 0) {
                bIsAllowed = true;
            }
        
            _Player.SetItemPickupTimes(0);
            for (uint idx = 0; idx < g_a_lpszCheatsMenu_Impulse101Arms.length(); idx++) {
                string szName = g_a_lpszCheatsMenu_Impulse101Arms[idx];
                //if (szName == "weapon_gauss" && !bIsAllowed) continue;
                
                if (szName == "weapon_uziakimbo")
                    szName = "weapon_uzi";
                if (szName == "weapon_gauss" && bIsCrackLife) {
                    szName = "weapon_clgauss";
                }
                    
                if (_Player.HasNamedPlayerItem(szName) is null) {
                    array<string> args = { g_a_lpszCheatsMenu_Impulse101Arms[idx] };
                    AP_UTIL_Cheats_GiveItem(_Player, args);
                }
            }
            
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("buckshot"), "ammo_buckshot", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("556"), "ammo_556", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("m40a1"), "ammo_762", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("argrenades"), "ammo_ARgrenades", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("357"), "ammo_357", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("9mm"), "ammo_9mmAR", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("9mm"), "ammo_9mmclip", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("sporeclip"), "ammo_sporeclip", 5);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("uranium"), "ammo_gaussclip", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("rockets"), "ammo_rpgclip", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("bolts"), "ammo_crossbow", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("trip mine"), "weapon_tripmine", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("satchel charge"), "weapon_satchel", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("hand grenade"), "weapon_handgrenade", 1);
            AP_UTIL_Cheats_GiveAmmoCapped(_Player, g_PlayerFuncs.GetAmmoIndex("snarks"), "weapon_snark", 1);
            
            if (_Player.pev.armorvalue < _Player.pev.armortype) {
                array<string> args = {"item_battery"};
                AP_UTIL_Cheats_GiveItem(_Player, args);
            }
            
            g_lpCheatsMenu.Open(0, _Listener.m_iCurrentPage, _Player);
        } else if (szChoice == g_lpszCheatsMenu_GiveEverything) {
            bool bIsQSG = false;
            bool bIsCrackLife = false;
            bool bIsAllowed = false; //unused
            string mapname = g_Engine.mapname;
            if (mapname.Find("qsg_") == 0) {
                bIsQSG = true;
                bIsAllowed = true;
                //if (szSteamID != g_lpszTheOwner) {
                //    g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Only server owner is allowed to give everything in QSG.\n");
                //
                //    return;
                //}
            }
            if (mapname.Find("cracklife_") == 0 || mapname.Find("cl_") == 0) {
                bIsCrackLife = true;
                bIsAllowed = true;
            }
            
            if (mapname.Find("hl_") == 0 || mapname.Find("dy_") == 0 || bIsQSG) {
                bIsAllowed = true;
            }
        
            string szActiveItem;
            if (_Player.m_hActiveItem.GetEntity() !is null)
                szActiveItem = _Player.m_hActiveItem.GetEntity().pev.classname;

            _Player.SetItemPickupTimes(0);
            
            for (uint idx = 0; idx < g_a_lpszCheatsMenu_GiveEverythingArms.length(); idx++) {
                string szName = g_a_lpszCheatsMenu_GiveEverythingArms[idx];
                //if (szName == "weapon_gauss" && !bIsAllowed) continue;
                
                if (szName == "weapon_gauss" && bIsCrackLife) {
                    szName = "weapon_clgauss";
                }
                
                array<string> args = { szName };
                AP_UTIL_Cheats_GiveItem(_Player, args);
            }
            
            if (!bIsQSG) {
                for (int idx = 0; idx < 64; idx++) {
                    _Player.m_rgAmmo(idx, 1000000);
                }
            }
                
            if (szActiveItem.Length() > 0)
                _Player.SelectItem(szActiveItem);
                
            g_lpCheatsMenu.Open(0, _Listener.m_iCurrentPage, _Player);
        } else if (szChoice == g_lpszCheatsMenu_InfiniteAmmo) {
            bool bIsQSG = false;
            string mapname = g_Engine.mapname;
            if (mapname.Find("qsg") == 0) {
                bIsQSG = true;
            }
            if (!bIsQSG) {
                for (int idx = 0; idx < 64; idx++) {
                    _Player.m_rgAmmo(idx, 1000000);
                }
            }
            
            g_lpCheatsMenu.Open(0, _Listener.m_iCurrentPage, _Player);
        }
    }
}

void AP_SelfManagementMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;

        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszSelfManagementMenu_FakeNickname) {
            CAdminData@ adminData = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
            if (adminData is null) {
                @adminData = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
                g_a_lpAdmins.insertLast(adminData);
            }
            
            adminData.m_bListeningForValueInChat = true;
            adminData.m_eListeningMode = kFakeNickname;
            
            g_PlayerFuncs.SayText(_Player, "[SM] Type the name you want to have (it won't affect your real ingame name) into chat.\n");
        } else if (szChoice == g_lpszSelfManagementMenu_GiveEntmover) {
            CAdminData@ adminData = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
            if (adminData is null) {
                @adminData = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
                g_a_lpAdmins.insertLast(adminData);
            }
            
            CAdminEntityMoverData@ data = adminData.m_lpEntityMoverData;
            
            CBasePlayerWeapon@ activeItem = cast<CBasePlayerWeapon@>(_Player.m_hActiveItem.GetEntity());
            if (activeItem !is null) {
                data.m_lpszPreviousWeapon = activeItem.pev.classname;
            }
            
            _Player.GiveNamedItem("weapon_entmover", 0, 9999);
            _Player.SelectItem("weapon_entmover");
            
            g_entWeapon[_Player.entindex()] = data;
            
            g_lpSelfManagementMenu.Open(0, _Listener.m_iCurrentPage, _Player);
        } else if (szChoice == g_lpszSelfManagementMenu_TakeEntmover) {
            CAdminData@ adminData = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
            if (adminData is null) {
                @adminData = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
                g_a_lpAdmins.insertLast(adminData);
            }
            
            CAdminEntityMoverData@ data = adminData.m_lpEntityMoverData;
            
            CBasePlayerItem@ pItem;
            CBasePlayerItem@ pItemHold;
            CBasePlayerWeapon@ pWeapon;
            for (uint j = 0; j < 10; j++) {
                @pItem = _Player.m_rgpPlayerItems(j);
                while (pItem !is null) {
                    @pWeapon = pItem.GetWeaponPtr();
                        
                    if (pWeapon.GetClassname() == "weapon_entmover") {
                        @pItemHold = pItem;
                        @pItem = cast<CBasePlayerItem@>(pItem.m_hNextItem.GetEntity());
                        _Player.RemovePlayerItem(pItemHold);
                        break;
                    }
                        
                    @pItem = cast<CBasePlayerItem@>(pItem.m_hNextItem.GetEntity());
                }
            }
                
            _Player.SelectItem(data.m_lpszPreviousWeapon);
            
            _Player.SetItemPickupTimes(0);
            g_entWeapon.delete(_Player.entindex());
            
            g_lpSelfManagementMenu.Open(0, _Listener.m_iCurrentPage, _Player);
        } else if (szChoice == g_lpszSelfManagementMenu_SetPrefix_Title) {
            if (g_lpSelfManagementMenu_SetPrefixMenu is null) {
                @g_lpSelfManagementMenu_SetPrefixMenu = CCustomTextMenu(AP_SelfManagementMenu_SetPrefixCB);
                g_lpSelfManagementMenu_SetPrefixMenu.SetTitle((g_lpszSelfManagementMenu_Title + " \\r->\\y " + g_lpszSelfManagementMenu_SetPrefix_Title));
                
                /* Self management \\r->\\y Set prefix menu items start */
                g_lpSelfManagementMenu_SetPrefixMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_RemovePrefix));
                g_lpSelfManagementMenu_SetPrefixMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_VIPStandard));
                g_lpSelfManagementMenu_SetPrefixMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_VIPPlatinum));
                g_lpSelfManagementMenu_SetPrefixMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_NoPrefixJustColor));
                /* Self management \\r->\\y Set prefix menu items end */
                
                g_lpSelfManagementMenu_SetPrefixMenu.Register();
            }
            
            g_lpSelfManagementMenu_SetPrefixMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszSelfManagementMenu_ToggleGodMode) {
            CAdminData@ adminData = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
            if (adminData is null) {
                @adminData = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
                g_a_lpAdmins.insertLast(adminData);
            }
            
            bool bWasOn = adminData.m_bGodMode;
            adminData.m_bGodMode = !adminData.m_bGodMode;
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Turned godmode " + (bWasOn ? "off.\n" : "on.\n"));
        }
    }
}

void AP_SelfManagementMenu_SetPrefixCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
        
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        if (szChoice == g_lpszSelfManagementMenu_SetPrefix_RemovePrefix) {
            data.m_lpszPrefix = "";
            data.m_iPrefixColor = -1;
        
            return;
        }
        
        data.m_lpszPrefix = (szChoice == g_lpszSelfManagementMenu_SetPrefix_NoPrefixJustColor) ? "NoPrefix" : szChoice;
        
        if (g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu is null) {
            @g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu = CCustomTextMenu(AP_SelfManagementMenu_SetPrefix_ChooseColorCB);
            g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu.SetTitle((g_lpszSelfManagementMenu_Title + " \\r->\\y " + g_lpszSelfManagementMenu_SetPrefix_Title + " \\r->\\y " + g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Title));
                
            /* Self management \\r->\\y Set prefix \\r->\\y Choose color menu items start */
            g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_ChooseColor_None));
            g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Red));
            g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Green));
            g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Blue));
            g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu.AddItem((g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Yellow));
            /* Self management \\r->\\y Set prefix \\r->\\y Choose color menu items end */
                
            g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu.Register();
        }
        
        g_lpSelfManagementMenu_SetPrefixMenu_ChooseColorMenu.Open(0, 0, _Player);
    }
}

void AP_SelfManagementMenu_SetPrefix_ChooseColorCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;

        string szChoice = (_Item.m_lpszText);
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
        
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        if (szChoice == g_lpszSelfManagementMenu_SetPrefix_ChooseColor_None) {
            data.m_iPrefixColor = -1;
        } else if (szChoice == g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Red) {
            data.m_iPrefixColor = 17;
        } else if (szChoice == g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Green) {
            data.m_iPrefixColor = 19;
        } else if (szChoice == g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Blue) {
            data.m_iPrefixColor = 16;
        } else if (szChoice == g_lpszSelfManagementMenu_SetPrefix_ChooseColor_Yellow) {
            data.m_iPrefixColor = 18;
        }
    }
}

void AP_EntityManagementMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;

        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszEntityManagementMenu_SpawnEntities) {
            if (g_lpEntityManagementMenu_SpawnEntities_ChooseEntityMenu is null) {
                @g_lpEntityManagementMenu_SpawnEntities_ChooseEntityMenu = CCustomTextMenu(AP_EntityManagementMenu_ChooseEntity);
            
                /* Entity management ~ Spawn entities menu items start */
                //ODOR: This was something different inb4. - xWhitey
                g_lpEntityManagementMenu_SpawnEntities_ChooseEntityMenu.AddItem((g_lpszEntityManagementMenu_SpawnEntities_SpawnAllies));
                g_lpEntityManagementMenu_SpawnEntities_ChooseEntityMenu.AddItem((g_lpszEntityManagementMenu_SpawnEntities_SpawnEnemies));
                /* Entity management ~ Spawn entities menu items end */
                
                g_lpEntityManagementMenu_SpawnEntities_ChooseEntityMenu.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_SpawnEntities + " \\r->\\y " + g_lpszEntityManagementMenu_SpawnEntities_ChooseRelationshipTitle));
                
                g_lpEntityManagementMenu_SpawnEntities_ChooseEntityMenu.Register();
            }
            
            g_lpEntityManagementMenu_SpawnEntities_ChooseEntityMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_DeleteEntities) {
            if (g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu is null) {
                @g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu = CCustomTextMenu(AP_EntityManagementMenu_DeleteEntities_ChooseConditionCB);
                g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_DeleteEntities + " \\r->\\y " + g_lpszEntityManagementMenu_DeleteEntitiesChooseCondition));
                
                /* Entity management ~ Delete entities ~ Choose condition menu items start */
                g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu.AddItem((g_lpszEntityManagementMenu_DeleteEntitiesCondition1UnderCrosshair));
                g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu.AddItem((g_lpszEntityManagementMenu_DeleteEntitiesCondition2ByClassname));
                /* Entity management ~ Delete entities ~ Choose condition menu items end */
                
                g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu.Register();
            }
            
            g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_UseEntityUnderCrosshair) {
            g_lpEntityManagementMenu.Open(0, _Listener.m_iCurrentPage, _Player);
            
             CBaseEntity@ entity = AP_UTIL_GetEyePosRayCastForEntity(_Player);
            
            if (entity is null || entity.pev.classname == "worldspawn") {
                g_PlayerFuncs.SayText(_Player, "[SM] No entities found in 4096 units after your eye position.\n");
                return;
            }
            
            entity.Use(_Player, _Player, USE_TOGGLE);
        } else if (szChoice == g_lpszEntityManagementMenu_CreateExplosionAtCrosshair) {
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
            if (data is null) {
                @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
                g_a_lpAdmins.insertLast(data);
            }
        
            data.m_bListeningForValueInChat = true;
            data.m_eListeningMode = kExplosion;
            
            g_PlayerFuncs.SayText(_Player, "[SM] Type the strength of explosion into chat.\n");
        } else if (szChoice == g_lpszEntityManagementMenu_CreateCheckpoint) {
            if (g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition is null) {
                @g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition = CCustomTextMenu(AP_EntityManagementMenu_CreateCheckpoint_ChoosePositionCB);
            
                g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition.AddItem((g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition_AtCamera));
                g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition.AddItem((g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition_AtCrosshair));
                
                g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_CreateCheckpoint + " \\r->\\y " + g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition));
                
                g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition.Register();
            }
            
            g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_ActivateLastCreatedCheckpoint) {
            if (g_lpEntityManagementMenu_Checkpoints_ChooseActivator !is null) {
                g_lpEntityManagementMenu_Checkpoints_ChooseActivator.Unregister();
                @g_lpEntityManagementMenu_Checkpoints_ChooseActivator = null;
            }
            
            if (g_lpEntityManagementMenu_Checkpoints_ChooseActivator is null) {
                @g_lpEntityManagementMenu_Checkpoints_ChooseActivator = CCustomTextMenu(AP_EntityManagementMenu_Checkpoints_ChooseActivatorCB);
            
                AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpEntityManagementMenu_Checkpoints_ChooseActivator);
                
                g_lpEntityManagementMenu_Checkpoints_ChooseActivator.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_ActivateLastCreatedCheckpoint));
                
                g_lpEntityManagementMenu_Checkpoints_ChooseActivator.Register();
            }
            
            g_lpEntityManagementMenu_Checkpoints_ChooseActivator.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_Teleport_Title) {
            if (g_lpEntityManagementMenu_TeleportMenu is null) {
                 @g_lpEntityManagementMenu_TeleportMenu = CCustomTextMenu(AP_EntityManagementMenu_TeleportCB);
            
                g_lpEntityManagementMenu_TeleportMenu.AddItem((g_lpszEntityManagementMenu_Teleport_SaveCurrentPosition));
                g_lpEntityManagementMenu_TeleportMenu.AddItem((g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToCrosshair));
                g_lpEntityManagementMenu_TeleportMenu.AddItem((g_lpszEntityManagementMenu_Teleport_SaveEntityAtCrosshair));
                g_lpEntityManagementMenu_TeleportMenu.AddItem((g_lpszEntityManagementMenu_Teleport_TeleportSavedEntityToCrosshair));
                g_lpEntityManagementMenu_TeleportMenu.AddItem((g_lpszEntityManagementMenu_Teleport_TeleportSavedEntityToSavedPosition));
                g_lpEntityManagementMenu_TeleportMenu.AddItem((g_lpszEntityManagementMenu_Teleport_TeleportYourselfToAPlayer));
                g_lpEntityManagementMenu_TeleportMenu.AddItem((g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToAPlayer));
                g_lpEntityManagementMenu_TeleportMenu.AddItem((g_lpszEntityManagementMenu_Teleport_TeleportAllEntitiesByClassnameToCurrentPosition));
                
                g_lpEntityManagementMenu_TeleportMenu.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_Teleport_Title));
                
                g_lpEntityManagementMenu_TeleportMenu.Register();
            }
           
            g_lpEntityManagementMenu_TeleportMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_UseEntityByTargetname_Title) {
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
            if (data is null) {
                @data = CAdminData(szSteamID);
                g_a_lpAdmins.insertLast(data);
            }
            
            data.m_bListeningForValueInChat = true;
            data.m_eListeningMode = kListeningForTargetname;
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Type the targetname.\n");
        } else if (szChoice == g_lpszEntityManagementMenu_CreateAllyExplosionAtCrosshair) {
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
            if (data is null) {
                @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
                g_a_lpAdmins.insertLast(data);
            }
        
            data.m_bListeningForValueInChat = true;
            data.m_eListeningMode = kAllyExplosion;
            
            g_PlayerFuncs.SayText(_Player, "[SM] Type the strength of explosion into chat.\n");
        }
    }
}

void AP_EntityManagementMenu_TeleportCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        if (szChoice == g_lpszEntityManagementMenu_Teleport_SaveCurrentPosition) {
            data.m_vecSavedPosition = _Player.pev.origin;
            g_PlayerFuncs.SayText(_Player, "[SM] Saved your position (X: " + string(_Player.pev.origin.x) + ", Y: " + string(_Player.pev.origin.y) + ", Z: " + string(_Player.pev.origin.z) + ") to your data.\n");
            
            if (g_lpEntityManagementMenu_TeleportMenu !is null)
                g_lpEntityManagementMenu_TeleportMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_Teleport_TeleportYourselfToAPlayer) {
            if (g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer !is null) {
                g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer.Unregister();
                @g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer = null;
            }
            
            if (g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer is null) {
                @g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer = CCustomTextMenu(AP_EntityManagementMenu_Teleport_TeleportYourselfToAPlayerCB);
            
                AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer);
                
                g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_Teleport_TeleportYourselfToAPlayer));
                
                g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer.Register();
            }
            
            g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_Teleport_SaveEntityAtCrosshair) {
            if (g_lpEntityManagementMenu_TeleportMenu !is null)
                g_lpEntityManagementMenu_TeleportMenu.Open(0, 0, _Player);
                
            CBaseEntity@ entity = AP_UTIL_GetEyePosRayCastForEntity(_Player);
            
            if (entity is null || entity.pev.classname == "worldspawn") {
                g_PlayerFuncs.SayText(_Player, "[SM] No entities found in 4096 units after your eye position.\n");
                return;
            }
            
            data.m_hSavedEntity = EHandle(entity);
        } else if (szChoice == g_lpszEntityManagementMenu_Teleport_TeleportSavedEntityToCrosshair) {
            if (g_lpEntityManagementMenu_TeleportMenu !is null)
                g_lpEntityManagementMenu_TeleportMenu.Open(0, 0, _Player);
                
            if (data.m_hSavedEntity.GetEntity() is null) {
                g_PlayerFuncs.SayText(_Player, "[SM] You must save an entity in order to teleport something.\n");
                return;
            }
            
            Vector vecNewEntityPos = AP_UTIL_GetEyePosRayCastResult(_Player);
            float yaw = _Player.pev.angles[1];
            float back = AP_UTIL_Degree2Radians(yaw - 180.0f);
            Vector newPos = Vector(vecNewEntityPos.x + cos(back) * 25.0f, vecNewEntityPos.y + sin(back) * 25.0f, vecNewEntityPos.z);
            vecNewEntityPos = newPos;
            Vector upwards = Vector(newPos.x, newPos.y, newPos.z + 35.0f);
            if (!AP_UTIL_IsPointSafe(upwards)) {
                vecNewEntityPos.z -= 35.0f;
            }
            Vector downwards = Vector(newPos.x, newPos.y, newPos.z - 35.0f);
            if (!AP_UTIL_IsPointSafe(downwards)) {
                vecNewEntityPos.z += 35.0f;
            }
            
            g_EntityFuncs.SetOrigin(data.m_hSavedEntity.GetEntity(), vecNewEntityPos);
        } else if (szChoice == g_lpszEntityManagementMenu_Teleport_TeleportSavedEntityToSavedPosition) {
            if (g_lpEntityManagementMenu_TeleportMenu !is null)
                g_lpEntityManagementMenu_TeleportMenu.Open(0, 0, _Player);
                
            if (data.m_hSavedEntity.GetEntity() is null) {
                g_PlayerFuncs.SayText(_Player, "[SM] You must save an entity in order to teleport something.\n");
                return;
            }
            
            if (data.m_vecSavedPosition.x == 0.0f and data.m_vecSavedPosition.y == 0.0f and data.m_vecSavedPosition.z == 0.0f) {
                g_PlayerFuncs.SayText(_Player, "[SM] You must save your position in order to teleport something.\n");
                return;
            }
            
            g_EntityFuncs.SetOrigin(data.m_hSavedEntity.GetEntity(), data.m_vecSavedPosition);
        } else if (szChoice == g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToAPlayer) {
            if (g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer !is null) {
                g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer.Unregister();
                @g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer = null;
            }
            
            if (g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer is null) {
                @g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer = CCustomTextMenu(AP_EntityManagementMenu_Teleport_TeleportAPlayerToAPlayer_Stage1CB);
            
                AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer);
                
                g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToAPlayer + " \\r->\\y " /* for mass grep */ + "Choose victim"));
                
                g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer.Register();
            }
            
            g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToCrosshair) {
            if (g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair !is null) {
                g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair.Unregister();
                @g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair = null;
            }
        
            if (g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair is null) {
                 @g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair = CCustomTextMenu(AP_EntityManagementMenu_Teleport_TeleportAPlayerToCrosshairCB);
            
                AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair);
                
                g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToCrosshair));
                
                g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair.Register();
            }
           
            g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair.Open(0, 0, _Player);
        } else if (szChoice == g_lpszEntityManagementMenu_Teleport_TeleportAllEntitiesByClassnameToCurrentPosition) {
            data.m_bListeningForValueInChat = true;
            data.m_eListeningMode = kListeningForClassname;
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Specify the classname.\n");
        }
    }
}

void AP_EntityManagementMenu_Teleport_TeleportAPlayerToCrosshairCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null or !victim.IsConnected()) {
            g_PlayerFuncs.SayText(_Player, "[SM] [DEBUG] Victim is null/not connected!\n");
        
            return;
        }
        
        Vector vecNewEntityPos = AP_UTIL_GetEyePosRayCastResult(_Player);
        float yaw = _Player.pev.angles[1];
        float back = AP_UTIL_Degree2Radians(yaw - 180.0f);
        Vector newPos = Vector(vecNewEntityPos.x + cos(back) * 45.0f, vecNewEntityPos.y + sin(back) * 45.0f, vecNewEntityPos.z);
        vecNewEntityPos = newPos;
        Vector upwards = Vector(newPos.x, newPos.y, newPos.z + 55.0f);
        if (!AP_UTIL_IsPointSafe(upwards)) {
            vecNewEntityPos.z -= 55.0f;
        }
        Vector downwards = Vector(newPos.x, newPos.y, newPos.z - 55.0f);
        if (!AP_UTIL_IsPointSafe(downwards)) {
            vecNewEntityPos.z += 55.0f;
        }
            
        g_EntityFuncs.SetOrigin(victim, vecNewEntityPos);
            
        if (g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair !is null)
            g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayerToCrosshair.Open(0, _Listener.m_iCurrentPage, _Player);
    }
}

void AP_EntityManagementMenu_Teleport_TeleportYourselfToAPlayerCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null or !victim.IsConnected()) {
            g_PlayerFuncs.SayText(_Player, "[SM] [DEBUG] Victim is null/not connected!\n");
        
            return;
        }
        
        g_EntityFuncs.SetOrigin(_Player, victim.pev.origin);
        
        if (g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer !is null)
            g_lpEntityManagementMenu_TeleportMenu_TeleportToAPlayer.Open(0, 0, _Player);
    }
}

void AP_EntityManagementMenu_Teleport_TeleportAPlayerToAPlayer_Stage1CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null or !victim.IsConnected()) {
            g_PlayerFuncs.SayText(_Player, "[SM] [DEBUG] Victim is null/not connected!\n");
        
            return;
        }
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        data.m_hTeleportVictim = EHandle(victim);
        
        if (g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination !is null) {
            g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination.Unregister();
            @g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination = null;
        }
        
        if (g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination is null) {
            @g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination = CCustomTextMenu(AP_EntityManagementMenu_Teleport_TeleportAPlayerToAPlayer_Stage2CB);
            
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination);
                
            g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_Teleport_TeleportAPlayerToAPlayer + " \\r->\\y " /* for mass grep */ + "Choose destination"));
                
            g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination.Register();
        }

        g_lpEntityManagementMenu_TeleportMenu_TeleportAPlayer_ChooseDestination.Open(0, 0, _Player);
    }
}

void AP_EntityManagementMenu_Teleport_TeleportAPlayerToAPlayer_Stage2CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ destination = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (destination is null or !destination.IsConnected()) {
            g_PlayerFuncs.SayText(_Player, "[SM] [DEBUG] Destination is null/not connected!\n");
        
            return;
        }
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        if (data.m_hTeleportVictim.GetEntity() is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] [DEBUG] AP_EntityManagementMenu_Teleport_TeleportAPlayerToAPlayer_Stage2CB: Should not reach here!\n");
        
            return;
        }
        
        g_EntityFuncs.SetOrigin(data.m_hTeleportVictim.GetEntity(), destination.pev.origin);
        data.m_hTeleportVictim = null;
    }
}

void AP_EntityManagementMenu_CreateCheckpoint_ChoosePositionCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition_AtCamera or szChoice == g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition_AtCrosshair) {
            Vector vecNewEntityPos = szChoice == g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition_AtCrosshair ? AP_UTIL_GetEyePosRayCastResult(_Player) : _Player.pev.origin;
            if (szChoice == g_lpszEntityManagementMenu_CreateCheckpoint_ChoosePosition_AtCrosshair) {
                float yaw = _Player.pev.angles[1];
                float back = AP_UTIL_Degree2Radians(yaw - 180.0f);
                Vector newPos = Vector(vecNewEntityPos.x + cos(back) * 25.0f, vecNewEntityPos.y + sin(back) * 25.0f, vecNewEntityPos.z);
                vecNewEntityPos = newPos;
                Vector upwards = Vector(newPos.x, newPos.y, newPos.z + 35.0f);
                if (!AP_UTIL_IsPointSafe(upwards)) {
                    vecNewEntityPos.z -= 35.0f;
                }
                Vector downwards = Vector(newPos.x, newPos.y, newPos.z - 35.0f);
                if (!AP_UTIL_IsPointSafe(downwards)) {
                    vecNewEntityPos.z += 35.0f;
                }
            }
            CBaseEntity@ ent = g_EntityFuncs.Create("point_checkpoint", vecNewEntityPos, Vector(0, 0, 0), false, _Player.edict());
            g_EntityFuncs.DispatchSpawn(ent.edict());
            
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            if (data is null) {
                @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
                g_a_lpAdmins.insertLast(data);
            }
                
            data.m_aSpawnedCheckpoints.insertLast(EHandle(ent));
            if (g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition !is null)
                g_lpEntityManagementMenu_CreateCheckpoint_ChoosePosition.Open(0, _Listener.m_iCurrentPage, _Player);
        }
    }
}

void AP_EntityManagementMenu_Checkpoints_ChooseActivatorCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ activator = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (activator is null or !activator.IsConnected()) return;
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
        
        //SAFETY: cannot happen, we're being called in an evaluated ctx
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        if (data.m_aSpawnedCheckpoints.length() == 0) {
            g_PlayerFuncs.SayText(_Player, "[SM] You haven't created a checkpoint yet!\n");
        
            return;
        }
        
        CBaseEntity@ lastCP /* checkpoint, not the one you've thought */ = data.m_aSpawnedCheckpoints[data.m_aSpawnedCheckpoints.length() - 1];
        data.m_aSpawnedCheckpoints.removeLast();
        lastCP.Touch(activator);
        
        g_lpEntityManagementMenu_Checkpoints_ChooseActivator.Open(0, _Listener.m_iCurrentPage, _Player);
    }
}

void AP_EntityManagementMenu_ChooseEntity(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        bool bAlly = false;
        
        if (szChoice == g_lpszEntityManagementMenu_SpawnEntities_SpawnAllies) {
            bAlly = true;
        } else if (szChoice == g_lpszEntityManagementMenu_SpawnEntities_SpawnEnemies) { //I KNOW THIS IS NOT NEEDED. I JUST WANT TO HANDLE ALL THE CONDITIONS. - xWhitey
            bAlly = false;
        }
        
        if (g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu !is null) {
            g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu.Unregister();
            @g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu = null;
        }
        
        @g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu = CCustomTextMenu(AP_EntityManagementMenu_SpawnEntities_RelationshipChosenCB);
        
        int count = 1;
        int page = 0;
    
        //Dynamic generation of the entity list. - xWhitey
        int iMaxEntriesPerPage = g_a_lpEntityManagementMenu_SpawnEntities_EntityList.length() <= 9 ? 9 : 7;
            
        for (uint idx = 0; idx < g_a_lpEntityManagementMenu_SpawnEntities_EntityList.length(); idx++) {
            CSpawningEntityData@ data = g_a_lpEntityManagementMenu_SpawnEntities_EntityList[idx];
            if (data.m_bForceAlly && !bAlly) continue;
            if (data.m_bForceEnemy && bAlly) continue;
            data.m_bAlly = bAlly;
            string entry = data.m_lpszEntityClassName;
            if (count < iMaxEntriesPerPage) {
                if (idx != g_a_lpEntityManagementMenu_SpawnEntities_EntityList.length() - 1) {
                    g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu.AddItem((entry), any(@data));
                } else {
                    g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu.AddItem((entry), any(@data));
                }
                count++;
            } else {
                g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu.AddItem((entry), any(@data));
                count = 1;
                page++;
            }
        }
        
        g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_SpawnEntities + " \\r->\\y " + szChoice));
        g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu.Register();
        g_lpEntityManagementMenu_SpawnEntites_RelationshipChosenMenu.Open(0, 0, _Player);
    }
}

void AP_EntityManagementMenu_SpawnEntities_RelationshipChosenCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        CSpawningEntityData@ data;
        _Item.m_pUserData.retrieve(@data);
        
        if (data !is null and data.m_lpSubSpawnMenu !is null) {
            data.m_lpSubSpawnMenu.Open(0, 0, _Player);
        } else {
            g_PlayerFuncs.SayText(_Player, "[SM] [DEBUG] Something went wrong while opening this menu. Did you forget to call GenerateTextMenu?\n");
        }
    }
}

void AP_EntityManagementMenu_DeleteEntities_ChooseConditionCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;

        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszEntityManagementMenu_DeleteEntitiesCondition1UnderCrosshair) {
            g_lpEntityManagementMenu_DeleteEntities_ChooseConditionMenu.Open(0, _Listener.m_iCurrentPage, _Player);
            
            CBaseEntity@ entity = AP_UTIL_GetEyePosRayCastForEntity(_Player);
            
            if (entity is null || entity.pev.classname == "worldspawn") {
                g_PlayerFuncs.SayText(_Player, "[SM] No entities found in 4096 units after your eye position.\n");
                return;
            }
            
            g_EntityFuncs.Remove(entity);
        } else if (szChoice == g_lpszEntityManagementMenu_DeleteEntitiesCondition2ByClassname) {
            if (g_lpEntityManagementMenu_DeleteEntities_Condition2Menu !is null) {
                g_lpEntityManagementMenu_DeleteEntities_Condition2Menu.Unregister();
                @g_lpEntityManagementMenu_DeleteEntities_Condition2Menu = null;
            }
        
            if (g_lpEntityManagementMenu_DeleteEntities_Condition2Menu is null) {
                @g_lpEntityManagementMenu_DeleteEntities_Condition2Menu = CCustomTextMenu(AP_EntityManagementMenu_DeleteEntities_Condition2CB);
            
                AP_UTIL_RegenerateMenuItemsByEntityClassname(@g_lpEntityManagementMenu_DeleteEntities_Condition2Menu);
                
                g_lpEntityManagementMenu_DeleteEntities_Condition2Menu.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_DeleteEntities + " \\r->\\y " + g_lpszEntityManagementMenu_DeleteEntitiesChooseCondition + " \\r->\\y " + g_lpszEntityManagementMenu_DeleteEntitiesCondition2ByClassname));
                
                g_lpEntityManagementMenu_DeleteEntities_Condition2Menu.Register();
            }
            
            g_lpEntityManagementMenu_DeleteEntities_Condition2Menu.Open(0, 0, _Player);
        }
    }
}

void AP_EntityManagementMenu_DeleteEntities_Condition2CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;

        string szChoice = (_Item.m_lpszText);
        AP_UTIL_DeleteEntitiesByClassname(szChoice);
        
        if (g_lpEntityManagementMenu_DeleteEntities_Condition2Menu !is null) {
            g_lpEntityManagementMenu_DeleteEntities_Condition2Menu.Unregister();
            @g_lpEntityManagementMenu_DeleteEntities_Condition2Menu = null;
        }
        
        if (g_lpEntityManagementMenu_DeleteEntities_Condition2Menu is null) {
            @g_lpEntityManagementMenu_DeleteEntities_Condition2Menu = CCustomTextMenu(AP_EntityManagementMenu_DeleteEntities_Condition2CB);
            
            AP_UTIL_RegenerateMenuItemsByEntityClassname(@g_lpEntityManagementMenu_DeleteEntities_Condition2Menu);
                
            g_lpEntityManagementMenu_DeleteEntities_Condition2Menu.SetTitle((g_lpszEntityManagementMenu_Title + " \\r->\\y " + g_lpszEntityManagementMenu_DeleteEntities + " \\r->\\y " + g_lpszEntityManagementMenu_DeleteEntitiesChooseCondition + " \\r->\\y " + g_lpszEntityManagementMenu_DeleteEntitiesCondition2ByClassname));
                
            g_lpEntityManagementMenu_DeleteEntities_Condition2Menu.Register();
        }
            
        g_lpEntityManagementMenu_DeleteEntities_Condition2Menu.Open(0, 0, _Player);
    }
}

void AP_BotManagementMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        if (szSteamID != g_lpszTheOwner) {
            g_PlayerFuncs.SayText(_Player, "[SM] You don't have enough rights to do that action.\n");
        
            return;
        }

        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszBotManagementMenu_CreateBot) {
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
            if (data is null) {
                @data = CAdminData(szSteamID);
                g_a_lpAdmins.insertLast(data);
            }
            
            data.m_bListeningForValueInChat = true;
            data.m_eListeningMode = kListeningForBotName;
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Type the name for the bot.\n");
        } else if (szChoice == g_lpszBotManagementMenu_RemoveBot) {
            if (g_a_lpBots.length() == 0) return;
            if (g_lpBotManagementMenu_RemoveBot !is null) {
                g_lpBotManagementMenu_RemoveBot.Unregister();
                @g_lpBotManagementMenu_RemoveBot = null;
            }
            
            if (g_lpBotManagementMenu_RemoveBot is null) {
                @g_lpBotManagementMenu_RemoveBot = CCustomTextMenu(AP_BotManagementMenu_RemoveBotCB);
                AP_UTIL_RegenerateMenuItemsFromBotList(@g_lpBotManagementMenu_RemoveBot);
                
                g_lpBotManagementMenu_RemoveBot.SetTitle((g_lpszBotManagementMenu_Title + " \\r->\\y " + g_lpszBotManagementMenu_RemoveBot));
                
                g_lpBotManagementMenu_RemoveBot.Register();
            }
            
            g_lpBotManagementMenu_RemoveBot.Open(0, 0, _Player);
        }
    }
}

void AP_BotManagementMenu_RemoveBotCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;

        AP_UTIL_RemoveBot((_Item.m_lpszText));
    }
}

void AP_PlayerManagementMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = (_Item.m_lpszText);
    
        if (szChoice == g_lpszShowIPAddressesMenu_Title) {
            if (g_lpShowIPAddressesMenu !is null) {
                g_lpShowIPAddressesMenu.Unregister();
                @g_lpShowIPAddressesMenu = null;
            }
             
            @g_lpShowIPAddressesMenu = CCustomTextMenu(AP_ShowIPAddressesMenuCB);
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpShowIPAddressesMenu);
            
            g_lpShowIPAddressesMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszShowIPAddressesMenu_Title));
            
            g_lpShowIPAddressesMenu.Register();
        
            g_lpShowIPAddressesMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszKillPlayersMenu_Title) {
            if (g_lpKillPlayersMenu is null) {
                @g_lpKillPlayersMenu = CCustomTextMenu(AP_KillPlayersMenuCB);
                g_lpKillPlayersMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszKillPlayersMenu_Title));

                g_lpKillPlayersMenu.AddItem((g_lpszKillPlayersMenu_KillSpecifiedPlayer));
                g_lpKillPlayersMenu.AddItem((g_lpszKillPlayersMenu_KillEveryPlayer));
                
                g_lpKillPlayersMenu.Register();
            }
            
            g_lpKillPlayersMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszRespawnPlayersMenu_Title) {
            if (g_lpRespawnPlayersMenu is null) {
                @g_lpRespawnPlayersMenu = CCustomTextMenu(AP_RespawnPlayersMenuCB);
                g_lpRespawnPlayersMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszRespawnPlayersMenu_Title));

                g_lpRespawnPlayersMenu.AddItem((g_lpszRespawnPlayersMenu_RespawnSpecifiedPlayer));
                g_lpRespawnPlayersMenu.AddItem((g_lpszRespawnPlayersMenu_RespawnEveryPlayer));
                
                g_lpRespawnPlayersMenu.Register();
            }
        
            g_lpRespawnPlayersMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_GiveHealth || szChoice == g_lpszPlayerManagementMenu_GiveArmor || szChoice == g_lpszPlayerManagementMenu_GiveScore) {
            if (g_lpPlayerManagementMenu_GiveSth !is null) {
                g_lpPlayerManagementMenu_GiveSth.Unregister();
                @g_lpPlayerManagementMenu_GiveSth = null;
            }
            
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
            if (data is null) {
                @data = CAdminData(szSteamID);
                g_a_lpAdmins.insertLast(data);
            }
            
            data.m_eGivingWhat = AP_UTIL_GiveSthModeToEnumValue(szChoice);
             
            @g_lpPlayerManagementMenu_GiveSth = CCustomTextMenu(AP_PlayerManagementMenu_GiveSthCB);

            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpPlayerManagementMenu_GiveSth);
            
            g_lpPlayerManagementMenu_GiveSth.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + szChoice));
            
            g_lpPlayerManagementMenu_GiveSth.Register();
        
            g_lpPlayerManagementMenu_GiveSth.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_RevivePlayersMenu_Title) {
            if (g_lpRevivePlayersMenu is null) {
                @g_lpRevivePlayersMenu = CCustomTextMenu(AP_PlayerManagementMenu_RevivePlayersMenuCB);

                g_lpRevivePlayersMenu.AddItem((g_lpszPlayerManagementMenu_ReviveSpecifiedPlayer));
                g_lpRevivePlayersMenu.AddItem((g_lpszPlayerManagementMenu_ReviveEveryPlayer));
                
                //AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpRevivePlayersMenu);
                
                g_lpRevivePlayersMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + szChoice));
                
                g_lpRevivePlayersMenu.Register();
            }
            
            g_lpRevivePlayersMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_KickPlayers) {
            if (g_lpPlayerManagementMenu_KickPlayersMenu is null) {
                @g_lpPlayerManagementMenu_KickPlayersMenu = CCustomTextMenu(AP_PlayerManagementMenu_KickPlayersMenuCB);

                g_lpPlayerManagementMenu_KickPlayersMenu.AddItem((g_lpszPlayerManagementMenu_KickPlayers_KickSpecifiedPlayer));
                g_lpPlayerManagementMenu_KickPlayersMenu.AddItem((g_lpszPlayerManagementMenu_KickPlayers_KickEveryPlayer));
                
                //AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpRevivePlayersMenu);
                
                g_lpPlayerManagementMenu_KickPlayersMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + szChoice));
                
                g_lpPlayerManagementMenu_KickPlayersMenu.Register();
            }
            
            g_lpPlayerManagementMenu_KickPlayersMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_FreezePlayers) {
            if (g_lpPlayerManagementMenu_FreezePlayersMenu is null) {
                @g_lpPlayerManagementMenu_FreezePlayersMenu = CCustomTextMenu(AP_PlayerManagementMenu_FreezePlayersMenuCB);

                g_lpPlayerManagementMenu_FreezePlayersMenu.AddItem((g_lpszPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayer));
                g_lpPlayerManagementMenu_FreezePlayersMenu.AddItem((g_lpszPlayerManagementMenu_FreezePlayers_FreezeEveryPlayer));
                
                //AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpRevivePlayersMenu);
                
                g_lpPlayerManagementMenu_FreezePlayersMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + szChoice));
                
                g_lpPlayerManagementMenu_FreezePlayersMenu.Register();
            }
            
            g_lpPlayerManagementMenu_FreezePlayersMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_BanPlayers) {
            if (g_lpPlayerManagementMenu_BanPlayersMenu is null) {
                @g_lpPlayerManagementMenu_BanPlayersMenu = CCustomTextMenu(AP_PlayerManagementMenu_BanPlayersMenuCB);

                g_lpPlayerManagementMenu_BanPlayersMenu.AddItem((g_lpszPlayerManagementMenu_BanPlayers_BanSpecifiedPlayer));
                g_lpPlayerManagementMenu_BanPlayersMenu.AddItem((g_lpszPlayerManagementMenu_BanPlayers_BanEveryPlayer));
                
                //AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpRevivePlayersMenu);
                
                g_lpPlayerManagementMenu_BanPlayersMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + szChoice));
                
                g_lpPlayerManagementMenu_BanPlayersMenu.Register();
            }
            
            g_lpPlayerManagementMenu_BanPlayersMenu.Open(0, 0, _Player);
        }
    }
}

void AP_PlayerManagementMenu_KickPlayersMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszPlayerManagementMenu_KickPlayers_KickSpecifiedPlayer) {
            if (g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu !is null) {
                g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu.Unregister();
                @g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu = null;
            }
             
            @g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu = CCustomTextMenu(AP_PlayerManagementMenu_KickSpecifiedPlayerCB);
            
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu);
            
            g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszPlayerManagementMenu_KickPlayers + " \\r->\\y " + szChoice));
            
            g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu.Register();
        
            g_lpPlayerManagementMenu_KickPlayers_KickSpecifiedPlayerMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_KickPlayers_KickEveryPlayer) {
            if (szSteamID != g_lpszTheOwner) {
                g_PlayerFuncs.SayText(_Player, "[SM] You don't have enough rights to do that action.\n");
            
                return;
            }
            
            for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
                CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByIndex(idx);
                if (victim is null || victim == _Player) continue;
                
                g_EngineFuncs.ServerCommand("kick #" + g_EngineFuncs.GetPlayerAuthId(victim.edict()) + " \"Kicked.\"\n");
                g_EngineFuncs.ServerExecute();
            }
        }
    }
}

void AP_PlayerManagementMenu_KickSpecifiedPlayerCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        
        if (victim is null or !victim.IsConnected()) {
            g_PlayerFuncs.SayText(_Player, "[SM] Victim is not connected yet!\n");
        
            return;
        }
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        data.m_bListeningForValueInChat = true;
        data.m_lpszVictimSteamID = g_EngineFuncs.GetPlayerAuthId(victim.edict());
        data.m_eListeningMode = kListeningForKickReason;
        g_PlayerFuncs.SayText(_Player, "[SM] Type kick reason into chat.\n");
        g_PlayerFuncs.SayText(_Player, "[SM] Type \"cancel\" to undo kick process.\n");
    }
}

void AP_PlayerManagementMenu_BanPlayersMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        if (szSteamID != g_lpszTheOwner) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] You do not have enough permissions to open this menu.\n");
        
            return;
        }
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszPlayerManagementMenu_BanPlayers_BanSpecifiedPlayer) {
            if (g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu !is null) {
                g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu.Unregister();
                @g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu = null;
            }
             
            @g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu = CCustomTextMenu(AP_PlayerManagementMenu_BanSpecifiedPlayerCB);
            
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu);
            
            g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszPlayerManagementMenu_BanPlayers + " \\r->\\y " + szChoice));
            
            g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu.Register();
        
            g_lpPlayerManagementMenu_BanPlayers_BanSpecifiedPlayerMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_BanPlayers_BanEveryPlayer) {
            //TODO: impl, ask for choice
            //TODO: like when leaking a player's ip to everyone
        }
    }
}

void AP_PlayerManagementMenu_BanSpecifiedPlayerCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        
        if (victim is null or !victim.IsConnected()) {
            g_PlayerFuncs.SayText(_Player, "[SM] Victim is not connected yet!\n");
        
            return;
        }
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        data.m_bListeningForValueInChat = true;
        data.m_lpszVictimSteamID = g_EngineFuncs.GetPlayerAuthId(victim.edict());
        data.m_eListeningMode = kListeningForBanDuration;
        g_PlayerFuncs.SayText(_Player, "[SM] Type ban duration into chat.\n");
        g_PlayerFuncs.SayText(_Player, "[SM] Type \"cancel\" to undo ban process.\n");
    }
}

void AP_PlayerManagementMenu_FreezePlayersMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayer) {
            if (g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu !is null) {
                g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu.Unregister();
                @g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu = null;
            }
             
            @g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu = CCustomTextMenu(AP_PlayerManagementMenu_FreezeSpecifiedPlayerCB);
            
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu);
            
            g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszPlayerManagementMenu_FreezePlayers + " \\r->\\y " + szChoice));
            
            g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu.Register();
        
            g_lpPlayerManagementMenu_FreezePlayers_FreezeSpecifiedPlayerMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_FreezePlayers_FreezeEveryPlayer) {
            for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
                CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByIndex(idx);
                if (victim is null) continue;
                
                if ((victim.pev.flags & FL_FROZEN) != 0) victim.pev.flags &= ~FL_FROZEN; else victim.pev.flags |= FL_FROZEN;
            }
        }
    }
}

void AP_PlayerManagementMenu_FreezeSpecifiedPlayerCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        
        if (victim is null or !victim.IsConnected()) {
            g_PlayerFuncs.SayText(_Player, "[SM] Victim is not connected yet!\n");
        
            return;
        }
        
        if ((victim.pev.flags & FL_FROZEN) != 0) victim.pev.flags &= ~FL_FROZEN; else victim.pev.flags |= FL_FROZEN;
    }
}

void AP_PlayerManagementMenu_RevivePlayersMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszPlayerManagementMenu_ReviveSpecifiedPlayer) {
            if (g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu !is null) {
                g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu.Unregister();
                @g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu = null;
            }
             
            @g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu = CCustomTextMenu(AP_PlayerManagementMenu_ReviveSpecifiedPlayerCB);
            
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu);
            
            g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszPlayerManagementMenu_RevivePlayersMenu_Title + " \\r->\\y " + szChoice));
            
            g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu.Register();
        
            g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszPlayerManagementMenu_ReviveEveryPlayer) {
            for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
                CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByIndex(idx);
                if (victim !is null && victim.IsConnected() && !victim.IsAlive()) victim.EndRevive(0.0f);
            }
            
            g_lpRevivePlayersMenu.Open(0, 0, _Player);
        }
    }
}

void AP_PlayerManagementMenu_ReviveSpecifiedPlayerCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        g_lpRevivePlayersMenu_ReviveSpecifiedPlayerMenu.Open(0, _Listener.m_iCurrentPage, _Player);
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        
        if (victim is null or !victim.IsConnected() or victim.IsAlive()) {
            g_PlayerFuncs.SayText(_Player, "[SM] Victim is alive!\n");
        
            return;
        }
        
        victim.EndRevive(0.0f);
    }
}

void AP_PlayerManagementMenu_GiveSthCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
        if (data is null) {
            //FIXME
            //g_PlayerFuncs.SayText(_Player, "[SM] How did you get into that menu without being an admin?\n");
            
            //return;
            
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        string szChoice = (_Item.m_lpszText);
        data.m_hCurrentVictim = EHandle(g_PlayerFuncs.FindPlayerByName(szChoice));
        
        if (g_lpPlayerManagementMenu_GiveSth_ChooseMode !is null) {
            g_lpPlayerManagementMenu_GiveSth_ChooseMode.Unregister();
            @g_lpPlayerManagementMenu_GiveSth_ChooseMode = null;
        }
             
        @g_lpPlayerManagementMenu_GiveSth_ChooseMode = CCustomTextMenu(AP_PlayerManagementMenu_GiveSth_ChooseModeCB);
            
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + g_lpszPlayerManagementMenu_GiveSth_ChooseMode));
        
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.AddItem((g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Add));
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.AddItem((g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Set));
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.AddItem((g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Presets), any(_Menu.GetTitle()));
            
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.Register();
        
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.Open(0, 0, _Player);
    }
}

void AP_PlayerManagementMenu_GiveSth_ChooseModeCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        if (szChoice == g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Add || szChoice == g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Set) {
            if (szChoice == g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Add) {
                data.m_ePlayerMgmt_GiveSth_Mode = kAdd;
            } else if (szChoice == g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Set) {
                data.m_ePlayerMgmt_GiveSth_Mode = kSet;
            }
            
            if (data.m_iGiveSthValue != 0) {
                string title = (g_lpPlayerManagementMenu_GiveSth.GetTitle());
                float value = float(data.m_iGiveSthValue);
        
                if (title == g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszPlayerManagementMenu_GiveHealth) {
                    if (data.m_ePlayerMgmt_GiveSth_Mode == kInvalid) {
                        data.m_hCurrentVictim = null;
                        
                        return;
                    }
                
                    CBasePlayer@ pl = cast<CBasePlayer@>(data.m_hCurrentVictim.GetEntity());
                    if (data.m_ePlayerMgmt_GiveSth_Mode == kAdd)
                        pl.TakeHealth(value, 0, 2147483647);
                    else if (data.m_ePlayerMgmt_GiveSth_Mode == kSet)
                        pl.pev.health = value;
                } else if (title == g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszPlayerManagementMenu_GiveArmor) {
                    if (data.m_ePlayerMgmt_GiveSth_Mode == kInvalid) {
                        data.m_hCurrentVictim = null;
                        
                        return;
                    }
                
                    CBasePlayer@ pl = cast<CBasePlayer@>(data.m_hCurrentVictim.GetEntity());
                    if (data.m_ePlayerMgmt_GiveSth_Mode == kAdd)
                        pl.TakeArmor(value, 0, 2147483647);
                    else if (data.m_ePlayerMgmt_GiveSth_Mode == kSet)
                        pl.pev.armorvalue = value;
                } else if (title == g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszPlayerManagementMenu_GiveScore) {
                    if (data.m_ePlayerMgmt_GiveSth_Mode == kInvalid) {
                        data.m_hCurrentVictim = null;
                        
                        return;
                    }
                
                    CBasePlayer@ pl = cast<CBasePlayer@>(data.m_hCurrentVictim.GetEntity());
                    if (data.m_ePlayerMgmt_GiveSth_Mode == kAdd)
                        pl.AddPoints(int(value), true);
                    else if (data.m_ePlayerMgmt_GiveSth_Mode == kSet)
                        pl.pev.frags = value;
                }
                data.m_ePlayerMgmt_GiveSth_Mode = kInvalid;
                data.m_hCurrentVictim = null;
                data.m_iGiveSthValue = 0;
            
                return;
            }
            
            data.m_bListeningForValueInChat = true;
            data.m_eListeningMode = kGivingSth;
        
            g_PlayerFuncs.SayText(_Player, "[SM] Type the value to give into chat.\n");
        } else if (szChoice == g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Presets) {
            if (g_lpPlayerManagementMenu_GiveSth_Presets !is null) {
                g_lpPlayerManagementMenu_GiveSth_Presets.Unregister();
                @g_lpPlayerManagementMenu_GiveSth_Presets = null;
            }
             
            @g_lpPlayerManagementMenu_GiveSth_Presets = CCustomTextMenu(AP_PlayerManagementMenu_GiveSth_PresetsCB);
            
            g_lpPlayerManagementMenu_GiveSth_Presets.SetTitle(((_Menu.GetTitle()) + " \\r->\\y " + g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Presets));

            string szOriginalTitle = "";
            _Item.m_pUserData.retrieve(szOriginalTitle);

            g_lpPlayerManagementMenu_GiveSth_Presets.AddItem(("1"), any(szOriginalTitle));
            g_lpPlayerManagementMenu_GiveSth_Presets.AddItem(("10"), any(szOriginalTitle));
            g_lpPlayerManagementMenu_GiveSth_Presets.AddItem(("100"), any(szOriginalTitle));
            g_lpPlayerManagementMenu_GiveSth_Presets.AddItem(("500"), any(szOriginalTitle));
            g_lpPlayerManagementMenu_GiveSth_Presets.AddItem(("1000"), any(szOriginalTitle));
            g_lpPlayerManagementMenu_GiveSth_Presets.AddItem(("10000"), any(szOriginalTitle));
            g_lpPlayerManagementMenu_GiveSth_Presets.AddItem(("Max"), any(szOriginalTitle));
            
            g_lpPlayerManagementMenu_GiveSth_Presets.Register();
        
            g_lpPlayerManagementMenu_GiveSth_Presets.Open(0, 0, _Player);
        } else {
            data.m_hCurrentVictim = null;
            data.m_ePlayerMgmt_GiveSth_Mode = kInvalid;
        }
    }
}

void AP_PlayerManagementMenu_GiveSth_PresetsCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szOriginalTitle = "";
        _Item.m_pUserData.retrieve(szOriginalTitle);
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
        
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        string szChoice = (_Item.m_lpszText);
        
        data.m_iGiveSthValue = szChoice == "Max" ? 2147483647 : atoi(szChoice);
        
        if (g_lpPlayerManagementMenu_GiveSth_ChooseMode !is null) {
            g_lpPlayerManagementMenu_GiveSth_ChooseMode.Unregister();
            @g_lpPlayerManagementMenu_GiveSth_ChooseMode = null;
        }
             
        @g_lpPlayerManagementMenu_GiveSth_ChooseMode = CCustomTextMenu(AP_PlayerManagementMenu_GiveSth_ChooseModeCB);
            
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.SetTitle(szOriginalTitle);
        
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.AddItem((g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Add));
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.AddItem((g_lpszPlayerManagementMenu_GiveSth_ChooseMode_Set));
            
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.Register();
        
        g_lpPlayerManagementMenu_GiveSth_ChooseMode.Open(0, 0, _Player);
    }
}
        
void AP_KillPlayersMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszKillPlayersMenu_KillSpecifiedPlayer) {
            if (g_lpKillPlayersMenu_KillSpecifiedPlayerMenu !is null) {
                g_lpKillPlayersMenu_KillSpecifiedPlayerMenu.Unregister();
                @g_lpKillPlayersMenu_KillSpecifiedPlayerMenu = null;
            }
             
            @g_lpKillPlayersMenu_KillSpecifiedPlayerMenu = CCustomTextMenu(AP_KillPlayersMenu_KillSpecifiedPlayerCB);
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpKillPlayersMenu_KillSpecifiedPlayerMenu);
            
            g_lpKillPlayersMenu_KillSpecifiedPlayerMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszKillPlayersMenu_Title + " \\r->\\y " + g_lpszKillPlayersMenu_KillSpecifiedPlayer));
            
            g_lpKillPlayersMenu_KillSpecifiedPlayerMenu.Register();
        
            g_lpKillPlayersMenu_KillSpecifiedPlayerMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszKillPlayersMenu_KillEveryPlayer) {
            for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
                CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByIndex(idx);
                if (victim !is null && victim.IsConnected()) {
                    bool wasAlive = victim.IsAlive();
            
                    if (wasAlive) {
                        victim.AddPoints(1, true);
                        victim.Killed(victim.pev, GIB_ALWAYS);
                        victim.m_iDeaths = victim.m_iDeaths - 1;
                    }
        
                    victim.GetObserver().StartObserver(victim.pev.origin, victim.pev.v_angle, true);
                
                    if (!wasAlive && victim.GetObserver().HasCorpse()) {
                        victim.GetObserver().RemoveDeadBody();
                    }
                }
            }
            
            g_lpKillPlayersMenu.Open(0, 0, _Player);
        }
    }
}

void AP_RespawnPlayersMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszRespawnPlayersMenu_RespawnSpecifiedPlayer) {
            if (g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu !is null) {
                g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu.Unregister();
                @g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu = null;
            }
             
            @g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu = CCustomTextMenu(AP_RespawnPlayersMenu_RespawnSpecifiedPlayerCB);
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu);
            
            g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszRespawnPlayersMenu_Title + " \\r->\\y " + g_lpszRespawnPlayersMenu_RespawnSpecifiedPlayer));
            
            g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu.Register();
        
            g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszRespawnPlayersMenu_RespawnEveryPlayer) {
            for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
                CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByIndex(idx);
                if (victim !is null && victim.IsConnected()) {
                    if (!victim.IsAlive()) g_PlayerFuncs.RespawnPlayer(victim, true, true);
                }
            }
            
            g_lpRespawnPlayersMenu.Open(0, 0, _Player);
        }
    }
}

void AP_RespawnPlayersMenu_RespawnSpecifiedPlayerCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_KillPlayersMenu_KillSpecifiedPlayerCB...\n");
            return;
        }
        if (!victim.IsAlive()) g_PlayerFuncs.RespawnPlayer(victim, true, true);
    
        g_lpRespawnPlayersMenu_RespawnSpecifiedPlayerMenu.Open(0, _Listener.m_iCurrentPage, _Player);
    }
}

void AP_KillPlayersMenu_KillSpecifiedPlayerCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_KillPlayersMenu_KillSpecifiedPlayerCB...\n");
            return;
        }
        bool wasAlive = victim.IsAlive();
            
        if (wasAlive) {
            victim.AddPoints(1, true);
            victim.Killed(victim.pev, GIB_ALWAYS);
            victim.m_iDeaths = victim.m_iDeaths - 1;
        }
        
        victim.GetObserver().StartObserver(victim.pev.origin, victim.pev.v_angle, true);
                
        if (!wasAlive && victim.GetObserver().HasCorpse()) {
            victim.GetObserver().RemoveDeadBody();
        }
        
        g_lpKillPlayersMenu_KillSpecifiedPlayerMenu.Open(0, _Listener.m_iCurrentPage, _Player);
    }
}

void AP_FunMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszFunMenu_SetSizeOf_Title) {
            if (g_lpFunMenu_SetSizeOf is null) {
                @g_lpFunMenu_SetSizeOf = CCustomTextMenu(AP_FunMenu_SetSizeOf_CB);
                g_lpFunMenu_SetSizeOf.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_SetSizeOf_Title));
                 
                g_lpFunMenu_SetSizeOf.AddItem((g_lpszFunMenu_SetSizeOfPlayer));
                g_lpFunMenu_SetSizeOf.AddItem((g_lpszFunMenu_SetSizeOfEntityUnderCrosshair));
                 
                g_lpFunMenu_SetSizeOf.Register();
            }
            
            g_lpFunMenu_SetSizeOf.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_SpinCameraOf_Title) {
            if (g_lpFunMenu_SpinCamera is null) {
                @g_lpFunMenu_SpinCamera = CCustomTextMenu(AP_FunMenu_SpinCamera_CB);
                g_lpFunMenu_SpinCamera.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_SpinCameraOf_Title));
                 
                g_lpFunMenu_SpinCamera.AddItem((g_lpszFunMenu_SpinCameraOfSpecifiedPlayer));
                g_lpFunMenu_SpinCamera.AddItem((g_lpszFunMenu_SpinCameraOfEveryPlayer));
                g_lpFunMenu_SpinCamera.AddItem((g_lpszFunMenu_SpinCameraOfEntityUnderCrosshair));
                 
                g_lpFunMenu_SpinCamera.Register();
            }
            
            g_lpFunMenu_SpinCamera.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_SendMessageAs_Title) {
            if (g_lpFunMenu_SendMessageAs_ChoosePlayerMenu !is null) {
                g_lpFunMenu_SendMessageAs_ChoosePlayerMenu.Unregister();
                @g_lpFunMenu_SendMessageAs_ChoosePlayerMenu = null;
            }
             
            @g_lpFunMenu_SendMessageAs_ChoosePlayerMenu = CCustomTextMenu(AP_FunMenu_SendMessageAs_CB);
             
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpFunMenu_SendMessageAs_ChoosePlayerMenu);
            
            g_lpFunMenu_SendMessageAs_ChoosePlayerMenu.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_SendMessageAs_Title));
             
            g_lpFunMenu_SendMessageAs_ChoosePlayerMenu.Register();
        
            g_lpFunMenu_SendMessageAs_ChoosePlayerMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_CrashGameOf_Title) {
             if (g_lpFunMenu_CrashGameOf_Menu is null) {
                //g_lpFunMenu_CrashGameOf_Menu.Unregister();
                //@g_lpFunMenu_CrashGameOf_Menu = null;
                @g_lpFunMenu_CrashGameOf_Menu = CCustomTextMenu(AP_FunMenu_CrashGameOf_CB);
             
                g_lpFunMenu_CrashGameOf_Menu.AddItem(g_lpszFunMenu_CrashGameOf_SpecifiedPlayer);
                g_lpFunMenu_CrashGameOf_Menu.AddItem(g_lpszFunMenu_CrashGameOf_EveryPlayer);
                
                g_lpFunMenu_CrashGameOf_Menu.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_CrashGameOf_Title));
                 
                g_lpFunMenu_CrashGameOf_Menu.Register();
            }
        
            g_lpFunMenu_CrashGameOf_Menu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_ChangeGravity_Title) {
            if (g_lpFunMenu_ChangeGravity_Menu is null) {
                @g_lpFunMenu_ChangeGravity_Menu = CCustomTextMenu(AP_FunMenu_ChangeGravity_CB);
                
                g_lpFunMenu_ChangeGravity_Menu.AddItem(g_lpszFunMenu_ChangeGravity_ForSpecifiedPlayer);
                g_lpFunMenu_ChangeGravity_Menu.AddItem(g_lpszFunMenu_ChangeGravity_ForEveryPlayer);
                
                g_lpFunMenu_ChangeGravity_Menu.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_ChangeGravity_Title));
                 
                g_lpFunMenu_ChangeGravity_Menu.Register();
            }
            
            g_lpFunMenu_ChangeGravity_Menu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_DestroyGameOf_Title) {
            if (g_lpFunMenu_DestroyGameOf_Menu !is null) {
                g_lpFunMenu_DestroyGameOf_Menu.Unregister();
                @g_lpFunMenu_DestroyGameOf_Menu = null;
            }
        
            if (g_lpFunMenu_DestroyGameOf_Menu is null) {
                @g_lpFunMenu_DestroyGameOf_Menu = CCustomTextMenu(AP_FunMenu_DestroyGameOf_CB);
             
                AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpFunMenu_DestroyGameOf_Menu);
                
                g_lpFunMenu_DestroyGameOf_Menu.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_DestroyGameOf_Title));
                 
                g_lpFunMenu_DestroyGameOf_Menu.Register();
            }
        
            g_lpFunMenu_DestroyGameOf_Menu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_ControlMovementOf_Title) {
            if (g_lpFunMenu_ControlGameOf_Menu !is null) {
                g_lpFunMenu_ControlGameOf_Menu.Unregister();
                @g_lpFunMenu_ControlGameOf_Menu = null;
            }
        
            if (g_lpFunMenu_ControlGameOf_Menu is null) {
                @g_lpFunMenu_ControlGameOf_Menu = CCustomTextMenu(AP_FunMenu_ControlGameOf_CB);
             
                AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpFunMenu_ControlGameOf_Menu);
                
                g_lpFunMenu_ControlGameOf_Menu.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_ControlMovementOf_Title));
                 
                g_lpFunMenu_ControlGameOf_Menu.Register();
            }
        
            g_lpFunMenu_ControlGameOf_Menu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_ChangeSkybox_Title) {
            //if (g_lpFunMenu_ChangeSkybox_Menu !is null) {
            //    g_lpFunMenu_ChangeSkybox_Menu.Unregister();
            //    @g_lpFunMenu_ChangeSkybox_Menu = null;
            //}
        
            if (g_lpFunMenu_ChangeSkybox_Menu is null) {
                @g_lpFunMenu_ChangeSkybox_Menu = CCustomTextMenu(AP_FunMenu_ChangeSkybox_CB);
             
                for (uint idx = 0; idx < g_rglpSkyboxes.length(); idx++) {
                    CSkybox@ lpSkybox = g_rglpSkyboxes[idx];
                    g_lpFunMenu_ChangeSkybox_Menu.AddItem(lpSkybox.m_lpszName);
                }
                
                g_lpFunMenu_ChangeSkybox_Menu.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_ChangeSkybox_Title));
                 
                g_lpFunMenu_ChangeSkybox_Menu.Register();
            }
        
            g_lpFunMenu_ChangeSkybox_Menu.Open(0, 0, _Player);
        }
    }
}

void AP_FunMenu_ChangeSkybox_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBaseEntity@ lpChanger = g_EntityFuncs.Create("trigger_changesky", Vector(0, 0, 0), Vector(0, 0, 0), true, null);
        g_EntityFuncs.DispatchKeyValue(lpChanger.edict(), "skyname", szChoice);
        g_EntityFuncs.DispatchKeyValue(lpChanger.edict(), "flags", 1 /* All players */);
        g_EntityFuncs.DispatchSpawn(lpChanger.edict());
        lpChanger.Use(_Player, _Player, USE_TOGGLE);
    }
}

void AP_FunMenu_ControlGameOf_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_FunMenu_DestroyGameOf_CB...\n");
            return;
        }
        
        if (victim is _Player) {
            g_PlayerFuncs.SayText(_Player, "[SM] You are controlling yourself already, silly! =)\n");
            return;
        }
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
        if (data is null) {
            @data = CAdminData(szSteamID);
            g_a_lpAdmins.insertLast(data);
        }
        
        if (data.m_bMindControllingSomebody) {
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] [MindControl] You're controlling somebody already. Detach from them first!\n");
            
            return;
        }
        
        //if (g_abIsMindControllingSomebody[victim.entindex()]) {
        //    g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] [MindControl] The victim is already being controlled by some evil admin!\n");
        //    
        //    return;
        //}
        
        int iPlayerIdx = _Player.entindex();
        
        data.m_bMindControllingSomebody = true;
        data.m_hMindControlVictim = EHandle(victim);
        g_rglpTheMindControllingSlave[iPlayerIdx] = EHandle(victim);
        g_abIsMindControllingSomebody[iPlayerIdx] = EHandle(victim);
        g_rgiMindControllingSpeedhackStep[iPlayerIdx] = 2;
        
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] [MindControl] Controlling \"" + string(victim.pev.netname) + "\" from now. Type \".stop\" into chat to stop controlling.\n");
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] [MindControl] Type \".speedstep <step>\" to adjust movement step to suit your needs.\n");
    }
}

void AP_FunMenu_DestroyGameOf_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_FunMenu_DestroyGameOf_CB...\n");
            return;
        }
        
        AP_DestroyGame(victim);
    }
}

void AP_FunMenu_ChangeGravity_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = _Item.m_lpszText;
        
        if (szChoice == g_lpszFunMenu_ChangeGravity_ForSpecifiedPlayer) { 
            if (g_lpFunMenu_ChangeGravity_ChoosePlayerMenu !is null) {
                g_lpFunMenu_ChangeGravity_ChoosePlayerMenu.Unregister();
                @g_lpFunMenu_ChangeGravity_ChoosePlayerMenu = null;
            }
             
            @g_lpFunMenu_ChangeGravity_ChoosePlayerMenu = CCustomTextMenu(AP_FunMenu_ChangeGravityOfSpecifiedPlayer_CB);
             
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpFunMenu_ChangeGravity_ChoosePlayerMenu);
            
            g_lpFunMenu_ChangeGravity_ChoosePlayerMenu.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_ChangeGravity_Title + " \\r->\\y " + g_lpszFunMenu_ChangeGravity_ForSpecifiedPlayer));
             
            g_lpFunMenu_ChangeGravity_ChoosePlayerMenu.Register();
        
            g_lpFunMenu_ChangeGravity_ChoosePlayerMenu.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_ChangeGravity_ForEveryPlayer) {
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
            if (data is null) {
                @data = CAdminData(szSteamID);
                g_a_lpAdmins.insertLast(data);
            }
            
            data.m_bListeningForValueInChat = true;
            data.m_eListeningMode = kListeningForGravityValue;
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Type the new gravity value into chat.\n");
        }
    }
}

void AP_FunMenu_ChangeGravityOfSpecifiedPlayer_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_FunMenu_ChangeGravityOfSpecifiedPlayer_CB...\n");
            return;
        }
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
        if (data is null) {
            @data = CAdminData(szSteamID);
            g_a_lpAdmins.insertLast(data);
        }
        
        data.m_bListeningForValueInChat = true;
        data.m_eListeningMode = kListeningForGravityValue;
        data.m_hCurrentVictim = EHandle(victim);
        g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Type the new gravity value into chat.\n");
    }
}

void AP_FunMenu_CrashGameOf_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = _Item.m_lpszText;
        
        if (szChoice == g_lpszFunMenu_CrashGameOf_EveryPlayer) {
            if (szSteamID != g_lpszTheOwner) {
                g_PlayerFuncs.SayText(_Player, "[SM] You don't have enough rights to do that action.\n");
            
                return;
            }
            
            AP_CrashGame(null);
        } else if (szChoice == g_lpszFunMenu_CrashGameOf_SpecifiedPlayer) {
            if (g_lpFunMenu_CrashGameOf_ChoosePlayerMenu !is null) {
                g_lpFunMenu_CrashGameOf_ChoosePlayerMenu.Unregister();
                @g_lpFunMenu_CrashGameOf_ChoosePlayerMenu = null;
            }
             
            @g_lpFunMenu_CrashGameOf_ChoosePlayerMenu = CCustomTextMenu(AP_FunMenu_CrashGameOfSpecifiedPlayer_CB);
             
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpFunMenu_CrashGameOf_ChoosePlayerMenu);
            
            g_lpFunMenu_CrashGameOf_ChoosePlayerMenu.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_CrashGameOf_Title + " \\r->\\y " + g_lpszFunMenu_CrashGameOf_SpecifiedPlayer));
             
            g_lpFunMenu_CrashGameOf_ChoosePlayerMenu.Register();
        
            g_lpFunMenu_CrashGameOf_ChoosePlayerMenu.Open(0, 0, _Player);
        }
    }
}

void AP_FunMenu_CrashGameOfSpecifiedPlayer_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        if (!AP_IsPlayerAllowedToOpenPanel(szSteamID)) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_FunMenu_CrashGameOfSpecifiedPlayer_CB...\n");
            return;
        }
        
        if (szSteamID != g_lpszTheOwner && AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(victim.edict()))) {
            g_PlayerFuncs.SayText(_Player, "[SM] Don't do that! They're your friend! :(\n");
            return;
        }
        
        AP_CrashGame(victim.edict());
    }
}

void AP_FunMenu_SendMessageAs_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_FunMenu_SendMessageAs_CB...\n");
            return;
        }
        
        CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
        if (data is null) {
            @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
            g_a_lpAdmins.insertLast(data);
        }
        
        data.m_bListeningForValueInChat = true;
        data.m_eListeningMode = kSendingMessageAsAPlayer;
        data.m_hCurrentVictim = EHandle(victim);
        
        g_PlayerFuncs.SayText(_Player, "[SM] Type the message you want to send as \"" + victim.pev.netname + "\".\n");
    }
}

void AP_FunMenu_SpinCamera_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszFunMenu_SpinCameraOfSpecifiedPlayer) {
            if (g_lpFunMenu_SpinCameraOfSpecifiedPlayer !is null) {
                g_lpFunMenu_SpinCameraOfSpecifiedPlayer.Unregister();
                @g_lpFunMenu_SpinCameraOfSpecifiedPlayer = null;
            }
             
            @g_lpFunMenu_SpinCameraOfSpecifiedPlayer = CCustomTextMenu(AP_FunMenu_SpinCameraOfSpecifiedPlayer_CB);
             
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpFunMenu_SpinCameraOfSpecifiedPlayer);
            
            g_lpFunMenu_SpinCameraOfSpecifiedPlayer.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_SpinCameraOf_Title + " \\r->\\y " + g_lpszFunMenu_SpinCameraOfSpecifiedPlayer));
             
            g_lpFunMenu_SpinCameraOfSpecifiedPlayer.Register();
        
            g_lpFunMenu_SpinCameraOfSpecifiedPlayer.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_SpinCameraOfEveryPlayer) {
            for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
                CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByIndex(idx);
                if (victim !is null && victim.IsConnected()) {
                    if (victim.pev.punchangle.y != 0.0f && victim.pev.punchangle.z != 0.0f && victim.IsAlive()) {
                        victim.pev.velocity.z -= 1000.0f;
                    } else {
                        victim.pev.velocity.z += 1000.0f;
                    }
                    victim.pev.velocity[Math.RandomLong(0, 1)] += 1000.0f;
                
                    victim.pev.punchangle.y += 1080.0f;
                    victim.pev.punchangle.z += 1080.0f;
                }
            }
            
            g_lpFunMenu_SpinCamera.Open(0, _Listener.m_iCurrentPage, _Player);
        } else if (szChoice == g_lpszFunMenu_SpinCameraOfEntityUnderCrosshair) {
            CBaseEntity@ entity = AP_UTIL_GetEyePosRayCastForEntity(_Player);
            
            if (entity is null || entity.pev.classname == "worldspawn") {
                g_PlayerFuncs.SayText(_Player, "[SM] No entities found in 4096 units after your eye position.\n");
                return;
            }
            
            if (entity.pev.punchangle.y != 0.0f && entity.pev.punchangle.z != 0.0f && entity.IsAlive()) {
                entity.pev.velocity.z -= 1000.0f;
            } else {
                entity.pev.velocity.z += 1000.0f;
            }
            entity.pev.velocity[Math.RandomLong(0, 1)] += 1000.0f;
            
            entity.pev.punchangle.y += 1080.f;
            entity.pev.punchangle.z += 1080.f;
            
            g_lpFunMenu_SpinCamera.Open(0, _Listener.m_iCurrentPage, _Player);
        }
    }
}

void AP_FunMenu_SpinCameraOfSpecifiedPlayer_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_FunMenu_SpinCameraOfSpecifiedPlayer_CB...\n");
            return;
        }
        
        if (victim.pev.punchangle.y != 0.0f && victim.pev.punchangle.z != 0.0f && victim.IsAlive()) {
            victim.pev.velocity.z -= 1000.0f;
        } else {
            victim.pev.velocity.z += 1000.0f;
        }
        victim.pev.velocity[Math.RandomLong(0, 1)] += 1000.0f;
        
        victim.pev.punchangle.y += 1080.0f;
        victim.pev.punchangle.z += 1080.0f;
        
        g_lpFunMenu_SpinCameraOfSpecifiedPlayer.Open(0, _Listener.m_iCurrentPage, _Player);
    }
}

void AP_FunMenu_SetSizeOf_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        
        if (szChoice == g_lpszFunMenu_SetSizeOfPlayer) {
            if (g_lpFunMenu_SetSizeOfPlayer !is null) {
                g_lpFunMenu_SetSizeOfPlayer.Unregister();
                @g_lpFunMenu_SetSizeOfPlayer = null;
            }
             
            @g_lpFunMenu_SetSizeOfPlayer = CCustomTextMenu(AP_FunMenu_SetSizeOfPlayer_CB);
             
            AP_UTIL_RegenerateMenuItemsFromPlayerList(@g_lpFunMenu_SetSizeOfPlayer);
            
            g_lpFunMenu_SetSizeOfPlayer.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_SetSizeOf_Title + " \\r->\\y " + g_lpszFunMenu_SetSizeOfPlayer));
             
            g_lpFunMenu_SetSizeOfPlayer.Register();
        
            g_lpFunMenu_SetSizeOfPlayer.Open(0, 0, _Player);
        } else if (szChoice == g_lpszFunMenu_SetSizeOfEntityUnderCrosshair) {
            CBaseEntity@ entity = AP_UTIL_GetEyePosRayCastForEntity(_Player);
            
            if (entity is null || entity.pev.classname == "worldspawn") {
                g_PlayerFuncs.SayText(_Player, "[SM] No entities found in 4096 units after your eye position.\n");
                return;
            }
            
            if (g_lpFunMenu_SetSizeOfPlayer_UserData !is null) {
                g_lpFunMenu_SetSizeOfPlayer_UserData.Unregister();
                @g_lpFunMenu_SetSizeOfPlayer_UserData = null;
            }
             
            @g_lpFunMenu_SetSizeOfPlayer_UserData = CCustomTextMenu(AP_FunMenu_SetSizeOfPlayer_UserDataChosen_CB);
            g_lpFunMenu_SetSizeOfPlayer_UserData.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_SetSizeOf_Title + " \\r->\\y " + g_lpszFunMenu_SetSizeOfEntityUnderCrosshair + " \\r->\\y " + g_lpszFunMenu_SetSizeOf_ChooseSize));
             
            g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("0.1x"), any(@entity));
            g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("0.5x"), any(@entity));
            g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("1x"), any(@entity));
            g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("2x"), any(@entity));
            g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("5x"), any(@entity));
            g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("10x"), any(@entity));
            g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("Custom"), any(@entity));
             
            g_lpFunMenu_SetSizeOfPlayer_UserData.Register();
        
            g_lpFunMenu_SetSizeOfPlayer_UserData.Open(0, 0, _Player);
        }
    }
}

void AP_FunMenu_SetSizeOfPlayer_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        CBaseEntity@ casted = victim;
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_FunMenu_SetSizeOfPlayer_CB...\n");
            return;
        }
        
        if (g_lpFunMenu_SetSizeOfPlayer_UserData !is null) {
            g_lpFunMenu_SetSizeOfPlayer_UserData.Unregister();
            @g_lpFunMenu_SetSizeOfPlayer_UserData = null;
        }
             
        @g_lpFunMenu_SetSizeOfPlayer_UserData = CCustomTextMenu(AP_FunMenu_SetSizeOfPlayer_UserDataChosen_CB);
        g_lpFunMenu_SetSizeOfPlayer_UserData.SetTitle((g_lpszFunMenu_Title + " \\r->\\y " + g_lpszFunMenu_SetSizeOf_Title + " \\r->\\y " + g_lpszFunMenu_SetSizeOfPlayer + " \\r->\\y " + g_lpszFunMenu_SetSizeOf_ChooseSize));
             
        g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("0.1x"), any(@casted));
        g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("0.5x"), any(@casted));
        g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("1x"), any(@casted));
        g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("2x"), any(@casted));
        g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("5x"), any(@casted));
        g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("10x"), any(@casted));
        g_lpFunMenu_SetSizeOfPlayer_UserData.AddItem(("Custom"), any(@casted));
             
        g_lpFunMenu_SetSizeOfPlayer_UserData.Register();
        
        g_lpFunMenu_SetSizeOfPlayer_UserData.Open(0, 0, _Player);
    }
}

void AP_FunMenu_SetSizeOfPlayer_UserDataChosen_CB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        string szChoice = (_Item.m_lpszText);
        CBaseEntity@ victim = null;
        _Item.m_pUserData.retrieve(@victim);
        
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_FunMenu_SetSizeOfPlayer_UserDataChosen_CB...\n");
            return;
        }
        
        if (szChoice == "1x") {
            Vector vecTheSize = Vector(1.0f, 1.0f, 1.0f);
            victim.pev.size = vecTheSize;
            victim.pev.scale = 1.0f;
        } else if (szChoice == "2x") {
            victim.pev.size.x = 2.0f;
            victim.pev.size.y = 2.0f;
            victim.pev.size.z = 2.0f;
            victim.pev.scale = 2.0f;
        } else if (szChoice == "5x") {
            victim.pev.size.x = 5.0f;
            victim.pev.size.y = 5.0f;
            victim.pev.size.z = 5.0f;
            victim.pev.scale = 5.0f;
        } else if (szChoice == "10x") {
            victim.pev.size.x = 10.0f;
            victim.pev.size.y = 10.0f;
            victim.pev.size.z = 10.0f;
            victim.pev.scale = 10.0f;
        } else if (szChoice == "0.1x") {
            victim.pev.size.x = 0.1f;
            victim.pev.size.y = 0.1f;
            victim.pev.size.z = 0.1f;
            victim.pev.scale = 0.1f;
        } else if (szChoice == "0.5x") {
            victim.pev.size.x = 0.5f;
            victim.pev.size.y = 0.5f;
            victim.pev.size.z = 0.5f;
            victim.pev.scale = 0.5f;
        } else if (szChoice == "Custom") {
            CAdminData@ data = AP_UTIL_GetAdminDataBySteamID(szSteamID);
            if (data is null) {
                @data = CAdminData(g_EngineFuncs.GetPlayerAuthId(_Player.edict()));
                g_a_lpAdmins.insertLast(data);
            }
            
            data.m_bListeningForValueInChat = true;
            data.m_eListeningMode = kSettingSizeOfSth;
            data.m_hCurrentVictim = EHandle(victim);
            
            g_PlayerFuncs.ClientPrint(_Player, HUD_PRINTTALK, "[SM] Type the desired size into chat.\n");
        }
        
        g_lpFunMenu_SetSizeOf.Open(0, 0, _Player);
    }
}

void AP_AreYouSureMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        //Hope this menu was opened forcefully by the server. - xWhitey
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        CVictimUserData@ lpUserData = null;

        _Item.m_pUserData.retrieve(@lpUserData);
    
        string szChoice = (_Item.m_lpszText);
        if (szChoice == g_lpszAreYouSureMenuYesBtnText) { //SAFETY: don't use `lpUserData.m_bTotallySure = szChoice == g_lpszAreYouSureMenuYesBtnText;`, process each choice in a condition
            lpUserData.m_bTotallySure = true;
            lpUserData.Process();
        } else if (szChoice == g_lpszAreYouSureMenuNoBtnText) {
            lpUserData.m_bTotallySure = false;
            lpUserData.Process();
        }
    }
}

void AP_ShowIPAddressesMenu_ChooseOutputModeCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
    
        string szChoice = (_Item.m_lpszText);
        
        CVictimUserData@ userData = null;
        _Item.m_pUserData.retrieve(@userData);
        
        if (szChoice == g_lpszShowIPAddressesMenu_OutputModeMenu_ToEveryone) {
            userData.m_eOutputType = kToEveryone;
        } else if (szChoice == g_lpszShowIPAddressesMenu_OutputModeMenu_ToTheCaller) {
            userData.m_eOutputType = kOnlyToTheCaller;
        }
        
        userData.Process();
    }
}

void AP_ShowIPAddressesMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener) {
    if (_Item !is null) {
        if (!AP_IsPlayerAllowedToOpenPanel(g_EngineFuncs.GetPlayerAuthId(_Player.edict()))) return;
        
        string szChoice = (_Item.m_lpszText);
        CBasePlayer@ victim = g_PlayerFuncs.FindPlayerByName(szChoice);
        if (victim is null) {
            g_PlayerFuncs.SayText(_Player, "[SM] Uh oh! Something went wrong in function AP_ShowIPAddressesMenuCB...\n");
            return;
        }
        string victims_steamID = g_EngineFuncs.GetPlayerAuthId(victim.edict());
        KeyValueBuffer@ lpVictimKeys = g_EngineFuncs.GetInfoKeyBuffer(victim.edict());
        const string model = lpVictimKeys.GetValue("model");
        string info = "Name: " + string(victim.pev.netname) + ", SteamID: " + victims_steamID + ", IP address: " + string(g_dictIPAddresses[victims_steamID]) + ", Model: " + model + "\n";
            
        //CVictimUserData(_In_ std::string& _TheData, _In_ eVictimUserDataOutputType _OutputType, _In_ CBasePlayer* _TheCaller, _In_ CBasePlayer* _TheVictim)
        CVictimUserData@ userData = CVictimUserData(info, kIllegalOutputType, _Player, victim);
            
        if (g_lpShowIPAddressesMenu_OutputModeMenu !is null) {
            g_lpShowIPAddressesMenu_OutputModeMenu.Unregister();
            @g_lpShowIPAddressesMenu_OutputModeMenu = null;
        }
            
        @g_lpShowIPAddressesMenu_OutputModeMenu = CCustomTextMenu(AP_ShowIPAddressesMenu_ChooseOutputModeCB);
        g_lpShowIPAddressesMenu_OutputModeMenu.SetTitle((g_lpszPlayerManagementMenu_Title + " \\r->\\y " + g_lpszShowIPAddressesMenu_Title + " \\r->\\y " + g_lpszShowIPAddressesMenu_OutputModeMenu_Title));
            
        g_lpShowIPAddressesMenu_OutputModeMenu.AddItem((g_lpszShowIPAddressesMenu_OutputModeMenu_ToEveryone), any(@userData));
        g_lpShowIPAddressesMenu_OutputModeMenu.AddItem((g_lpszShowIPAddressesMenu_OutputModeMenu_ToTheCaller), any(@userData));
            
        g_lpShowIPAddressesMenu_OutputModeMenu.Register();
        
        g_lpShowIPAddressesMenu_OutputModeMenu.Open(0, 0, _Player);
    }
}

/** 
 * Implementation of menus end 
 */
