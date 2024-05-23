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
        m_lpszText = _Wrappee.m_szName;
        @m_pUserData = _Wrappee.m_pUserData;
    }
}

class CCustomTextMenu {
	string m_lpszTitle;
	g_tCustomTextMenuCB@ m_lpfnCallback;
    array<CCustomTextMenuItem@> m_alpItems;
    array<CCustomTextMenuListener@> m_alpListeners;
    
    CTextMenu@ m_lpWrappee;
	
	CCustomTextMenu(g_tCustomTextMenuCB@ _Callback, bool _bExtraSpaceAfterTitle = true) {
        @m_lpfnCallback = _Callback;
        @m_lpWrappee = CTextMenu(TextMenuPlayerSlotCallback(this.WrapperCB));
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
        m_lpWrappee.SetTitle(_Title);
    }
    
    string GetTitle() {
        return m_lpszTitle;
    }
    
    void AddItem(const string& in _DisplayText) {
        m_alpItems.insertLast(CCustomTextMenuItem(_DisplayText));
        m_lpWrappee.AddItem(_DisplayText);
    }
    
    void AddItem(const string& in _DisplayText, any@ _UserData) {
        CCustomTextMenuItem@ item = CCustomTextMenuItem(_DisplayText);
        item.SetUserData(@_UserData);
        m_alpItems.insertLast(item);
        m_lpWrappee.AddItem(_DisplayText, @_UserData);
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
        m_lpWrappee.Unregister();
        m_lpWrappee.Register();
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
