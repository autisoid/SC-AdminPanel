array<any> g_alpMenus;
array<any> g_alpListeners;

funcdef void g_tCustomTextMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener);

const int MAX_ITEMS_PER_PAGE = 7;

CCustomTextMenuListener@ CustomMenus_UTIL_GetListenerBySteamID(const string& in _SteamID) {
    if (g_alpListeners.length() == 0) return null; //save some computing powerz
    
    for (uint idx = 0; idx < g_alpListeners.length(); idx++) {
        CCustomTextMenuListener@ theListener = null;
        g_alpListeners[idx].retrieve(@theListener);
        
        if (theListener.m_lpszSteamID == _SteamID) return @theListener;
    }

    return null;
}
    
class CCustomTextMenuListener {
    string m_lpszSteamID;
    CCustomTextMenu@ m_lpCurrentOpenedMenu;
    int m_iCurrentPage;
    
    CCustomTextMenuListener(const string& in _SteamID) {
        m_lpszSteamID = _SteamID;
        @m_lpCurrentOpenedMenu = null;
        m_iCurrentPage = 0;
    }
}

void CustomMenus_HandleMessageBegin(int _MsgDestination, int _MsgType, Vector _Origin, edict_t@ _Edict) {
    if (_MsgType != NetworkMessages::ShowMenu) return;
    
    string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Edict);
    
    for (uint idx = 0; idx < g_alpMenus.length(); idx++) {
        CCustomTextMenu@ menu = null;
        g_alpMenus[idx].retrieve(@menu);
            
        for (uint j = 0; j < menu.m_alpListeners.length(); j++) {
            if (menu.m_alpListeners[j].m_lpszSteamID == szSteamID)
                menu.m_alpListeners.removeAt(j);
        }
    }
}

bool CustomMenus_HandleMenuselectConCmd(edict_t@ _Entity, uint _Slot) {
    if (_Entity is null) 
        return false;

    string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Entity);
    CCustomTextMenuListener@ listener = CustomMenus_UTIL_GetListenerBySteamID(szSteamID);
    if (listener is null)
        return false;
    
    if (listener.m_lpCurrentOpenedMenu is null)
        return false;
     
    CCustomTextMenu@ menu = listener.m_lpCurrentOpenedMenu;
    if (menu.m_alpListeners.length() == 0) return false;
    
    bool bAllowedToContinueExecution = false;
    int iListenerIdx = -1;
    
    for (uint idx = 0; idx < menu.m_alpListeners.length(); idx++) {
        if (menu.m_alpListeners[idx].m_lpszSteamID == szSteamID) {
            bAllowedToContinueExecution = true;
            iListenerIdx = idx;
            break;
        }
    }
    
    if (!bAllowedToContinueExecution) return false;
    
    if (iListenerIdx != -1) {
        menu.m_alpListeners.removeAt(iListenerIdx);
    }
        
    if (_Slot == 9) {
        //exit
        @listener.m_lpCurrentOpenedMenu = null;
    
        return false;
    }
    
    CBaseEntity@ ent = g_EntityFuncs.Instance(_Entity);
    if (ent is null) 
        return false;
    CBasePlayer@ player = cast<CBasePlayer@>(ent);
    
    if (menu.m_alpItems.length() > 9 && _Slot == 7) {
        //open previous page, if any
        menu.Open(menu.m_iLastDur, listener.m_iCurrentPage - 1, player);
        
        return false;
    }
    
    if (menu.m_alpItems.length() > 9 && _Slot == 8) {
        //open next page, if any
        menu.Open(menu.m_iLastDur, listener.m_iCurrentPage + 1, player);
        
        return false;
    }
    
    if (menu.m_lpfnCallback !is null && _Slot < menu.m_alpItems.length())
        menu.m_lpfnCallback(@menu, @player, _Slot, @menu.m_alpItems[listener.m_iCurrentPage * MAX_ITEMS_PER_PAGE + _Slot], listener);
        
    return true;
}

class CCustomTextMenuItem {
    string m_lpszText;
    any@ m_pUserData;
    
    void SetUserData(any@ _UserData) {
        @m_pUserData = _UserData;
    }
    
    CCustomTextMenuItem(const string& in _DisplayText) {
        m_lpszText = _DisplayText;
    }
}

class CCustomTextMenu {
	string m_lpszTitle;
	g_tCustomTextMenuCB@ m_lpfnCallback;
    array<CCustomTextMenuItem@> m_alpItems;
    int m_iLastDur;
    array<CCustomTextMenuListener@> m_alpListeners;
    bool m_bExtraSpaceAfterTitle;
    char m_cItemDelimeter;
    bool m_bExitButtonIsTheSameColourAsTitle;
	
	CCustomTextMenu(g_tCustomTextMenuCB@ _Callback, bool _bExtraSpaceAfterTitle = true) {
        @m_lpfnCallback = _Callback;
        m_iLastDur = 0;
        m_bExtraSpaceAfterTitle = _bExtraSpaceAfterTitle;
        SetItemDelimeter('.');
        m_bExitButtonIsTheSameColourAsTitle = false;
    }
    
    void Register() {
        g_alpMenus.insertLast(any(@this));
    }
    
    void SetItemDelimeter(char _Delimeter) {
        m_cItemDelimeter = _Delimeter;
    }
    
    void MakeExitButtonTheSameColourAsTitle() {
        m_bExitButtonIsTheSameColourAsTitle = true;
    }
    
    void Unregister() {
        for (uint idx = 0; idx < g_alpMenus.length(); idx++) {
            CCustomTextMenu@ menu = null;
            g_alpMenus[idx].retrieve(@menu);
            if (@menu == @this) {
                g_alpMenus.removeAt(idx);
                break;
            }
        }
    }
    
    void SetTitle(const string& in _Title) {
        m_lpszTitle = _Title;
    }
    
    string GetTitle() {
        return m_lpszTitle;
    }
    
    void AddItem(const string& in _DisplayText) {
        m_alpItems.insertLast(CCustomTextMenuItem(_DisplayText));
    }
    
    void AddItem(const string& in _DisplayText, any@ _UserData) {
        CCustomTextMenuItem@ item = CCustomTextMenuItem(_DisplayText);
        item.SetUserData(@_UserData);
        m_alpItems.insertLast(item);
    }
    
    uint GetPageCount() {
        return (m_alpItems.length() + 6) / MAX_ITEMS_PER_PAGE;
    }
    
    void Open(int _DisplayTime, uint _Page, CBasePlayer@ _Player) {
        m_iLastDur = _DisplayTime;
        
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        CCustomTextMenuListener@ listener = CustomMenus_UTIL_GetListenerBySteamID(szSteamID);
        if (listener is null) {
            @listener = CCustomTextMenuListener(szSteamID);
            g_alpListeners.insertLast(any(@listener));
        }
        listener.m_iCurrentPage = _Page;
        @listener.m_lpCurrentOpenedMenu = @this;
        
        string szMenuText = "\\y" + m_lpszTitle;
        uint totalPages = (m_alpItems.length() + 6) / MAX_ITEMS_PER_PAGE;
        if (m_alpItems.length() > 9) {
            szMenuText += "\n~ Page \\r" + string(listener.m_iCurrentPage + 1) + "/" + string(totalPages);
        }
        szMenuText += "\\w\n";
        if (m_bExtraSpaceAfterTitle) {
            szMenuText += "\n";
        }
        int16 validSlots = (1 << 9);
        uint limitPerPage = m_alpItems.length() > 9 ? MAX_ITEMS_PER_PAGE : 9;
        uint itemOffset = _Page * MAX_ITEMS_PER_PAGE;
        
        int addedOptions = 0;
        for (uint i = itemOffset, k = 0; i < itemOffset + limitPerPage && i < m_alpItems.length(); i++, k++) {
            szMenuText += "\\r" + string(k + 1) + m_cItemDelimeter + " \\w" + m_alpItems[i].m_lpszText + "\n";
            validSlots |= (1 << k);
            addedOptions++;
        }

        while (m_alpItems.length() > 9 && addedOptions < MAX_ITEMS_PER_PAGE) {
            //szMenuText += "\n";
            addedOptions++;
        }

        szMenuText += "\n";
        
        if (m_alpItems.length() > 9) {
            if (_Page > 0) {
                szMenuText += "\\r8" + m_cItemDelimeter + " \\wBack\n";
                validSlots |= (1 << 7);
            } else {
                szMenuText += "\n";
            }
            if (_Page < totalPages - 1) {
                szMenuText += "\\r9" + m_cItemDelimeter +" \\wMore\n\n";
                validSlots |= (1 << 8);
            } else {
                szMenuText += "\n";
            }
        }

        if (!m_bExitButtonIsTheSameColourAsTitle) {
            szMenuText += "\\r0" + m_cItemDelimeter + " \\wExit";
        } else {
            szMenuText += "\\y0" + m_cItemDelimeter + " Exit";
        }
        
        NetworkMessage msg(MSG_ONE, NetworkMessages::ShowMenu, g_vecZero, _Player.edict());
        msg.WriteShort(validSlots);
        msg.WriteChar(_DisplayTime);
        msg.WriteByte(0);
        msg.WriteString(szMenuText);
        msg.End();
        m_alpListeners.insertLast(@listener);
    }
}
