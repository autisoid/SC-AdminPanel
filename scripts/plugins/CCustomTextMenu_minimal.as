namespace Hooks {
    namespace Player {
        const uint32 ClientCommand = 2147483647;
    }
    
    namespace Network {
        const uint32 MessageBegin = 2147483647;
    }
}

array<any> g_alpListeners;

funcdef void g_tCustomTextMenuCB(CCustomTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CCustomTextMenuItem@ _Item, const CCustomTextMenuListener@ _Listener);

const int MAX_ITEMS_PER_PAGE = 7;

string CustomMenus_UTIL_DecolorizeItem(const string& in _RawText) {
    if (_RawText[0] == '\\' and _RawText[1] == 'w' and ((_RawText[_RawText.Length() - 1] == 'r' or _RawText[_RawText.Length() - 1] == 'y') and _RawText[_RawText.Length() - 2] == '\\')) {
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
    } else if (_RawText[0] == '\\' and _RawText[1] == 'y') {
        string copy = "";
        
        for (uint idx = 0; idx < _RawText.Length(); idx++) {
            if (_RawText[idx] == '\n') continue;
            
            copy += _RawText[idx];
        }
        
        return copy.SubString(2, copy.Length());
    } else if (_RawText[0] == '\\' and _RawText[1] == 'r') {
        string copy = "";
        
        for (uint idx = 0; idx < _RawText.Length(); idx++) {
            if (_RawText[idx] == '\n') continue;
            
            copy += _RawText[idx];
        }
        
        return copy.SubString(2, copy.Length());
    }
    
    return _RawText;
}

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
}

bool CustomMenus_HandleMenuselectConCmd(edict_t@ _Entity, uint _Slot) {
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
    
    CCustomTextMenuItem(const CTextMenuItem@ _Wrappee) {
        m_lpszText = CustomMenus_UTIL_DecolorizeItem(_Wrappee.m_szName);
        @m_pUserData = _Wrappee.m_pUserData;
    }
}

class CCustomTextMenu {
	string m_lpszTitle;
	g_tCustomTextMenuCB@ m_lpfnCallback;
    array<CCustomTextMenuItem@> m_alpItems;
    array<CCustomTextMenuListener@> m_alpListeners;
    bool m_bHasRegisteredMenu;
    
    CTextMenu@ m_lpWrappee;
	
	CCustomTextMenu(g_tCustomTextMenuCB@ _Callback, bool _bExtraSpaceAfterTitle = true) {
        @m_lpfnCallback = _Callback;
        @m_lpWrappee = CTextMenu(TextMenuPlayerSlotCallback(this.WrapperCB));
        m_bHasRegisteredMenu = false;
    }
    
    void Register() {
        m_lpWrappee.Register();
    }
    
    void SetItemDelimeter(char _Delimeter) {
    }
    
    void MakeExitButtonTheSameColourAsTitle() {
    }
    
    void Unregister() {
        m_lpWrappee.Unregister();
    }
    
    void SetTitle(const string& in _Title) {
        m_lpszTitle = _Title;
        string szTitle = "\\y" + _Title;
        uint totalPages = (m_alpItems.length() + 6) / MAX_ITEMS_PER_PAGE;
        if (m_alpItems.length() > 9) {
            szTitle += "\n~ Page \\r";
        } else {
            szTitle += "\\r";
        }
        //szTitle += "\\w\n";
        //if (m_bExtraSpaceAfterTitle) {
        //    szTitle += "\n";
        //}
        
        m_lpWrappee.SetTitle(szTitle);
        
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
    
    void WrapperCB(CTextMenu@ _Menu, CBasePlayer@ _Player, int _Slot, const CTextMenuItem@ _Item) {
        if (_Item !is null) {
            string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
            for (uint idx = 0; idx < m_alpListeners.length(); idx++) {
                if (m_alpListeners[idx].m_lpszSteamID == szSteamID) {
                    m_alpListeners.removeAt(idx);
                    break;
                }
            }
            
            CCustomTextMenuListener@ pListener = CustomMenus_UTIL_GetListenerBySteamID(szSteamID);
            m_lpfnCallback(@this, _Player, _Slot, CCustomTextMenuItem(_Item), pListener);
        }
    }
    
    void Open(int _DisplayTime, uint _Page, CBasePlayer@ _Player) {
        if (!m_bHasRegisteredMenu) {
            m_lpWrappee.Unregister();
            int iMaxEntriesPerPage = m_alpItems.length() <= 9 ? 9 : 7;
            int iCount = 1;
            
            for (uint idx = 0; idx < m_alpItems.length(); idx++) {
                CCustomTextMenuItem@ pItem = @m_alpItems[idx];
                if (iCount < iMaxEntriesPerPage) {
                    if (idx != m_alpItems.length() - 1) {
                        m_lpWrappee.AddItem("\\w" + pItem.m_lpszText + "\\r", @pItem.m_pUserData);
                    } else {
                        m_lpWrappee.AddItem("\\w" + pItem.m_lpszText + "\\y", @pItem.m_pUserData);
                    }
                    iCount++;
                } else {
                    m_lpWrappee.AddItem("\\w" + pItem.m_lpszText + "\\y", @pItem.m_pUserData);
                    iCount = 1;
                }
            }
            
            m_lpWrappee.Register();
            m_bHasRegisteredMenu = true;
        }
        m_lpWrappee.Open(_DisplayTime, _Page, _Player);
        
        string szSteamID = g_EngineFuncs.GetPlayerAuthId(_Player.edict());
        CCustomTextMenuListener@ listener = CustomMenus_UTIL_GetListenerBySteamID(szSteamID);
        if (listener is null) {
            @listener = CCustomTextMenuListener(szSteamID);
            g_alpListeners.insertLast(any(@listener));
        }
        listener.m_iCurrentPage = _Page;
        @listener.m_lpCurrentOpenedMenu = @this;
    }
}
