-------------------------------------------------
-- ��Ϸ��� �ļ�
-------------------------------------------------
HotRequire("games.502.init")

local gamemain = class("gamemain", HotRequire(luafile.CtrlBase))

function gamemain:ctor( ... )
	self.super.ctor(self, ... )
    self:Init()
end

function gamemain:Init( ... )
    -- �����¼��ɷ���
    --cc.load("event"):setEventDispatcher(self, GameController)

    --self.ServerItemInfo = {} -- ��������Ϣ

    self.serviceState = {}
    print( "gamemain:Init" )
    self:initEvent()
    --self:GetServerInfo()
    self:initCtrl()

    gameManager:getpubInfo():setServiceStatus(enServiceStatus.ServiceStatus_Unknow)

    --self:InitTcp()
end

function gamemain:initEvent()
    --self.eventHandler = self:addEventListener(CreateGame.CONNECT_GAMESERVER_SUCC, handler(self, self.onConnectSucc)) -- �����¼�
    self.eventHandler = self:addEventListener(CreateGame.CREATE_GAME, handler(self, self.onCreateGame)) -- �����¼�
    self.eventHandler = self:addEventListener(CreateGame.BACK_HALL, handler(self, self.onBackHall)) -- ���ش���
    self.eventHandler = self:addEventListener(CreateGame.GAME_DATA, handler(self, self.onGameData)) -- ��Ϸ���ݷ���
    self.eventHandler = self:addEventListener(CreateGame.ENTER_ROOM, handler(self, self.onEnterRoom)) -- ���뷿��
end

function gamemain:initCtrl()
    -- ��Ϸ�߼�������
    GameLogicCtrl       = new_class(loadlua.GameLogicCtrl)

    -- ͨ����
    gameMainConfig      = new_class(loadlua.gameMainConfig)
    gameMainGameFrame   = new_class(loadlua.gameMainGameFrame)
    gameMainLogon       = new_class(loadlua.gameMainLogon)
    gameMainMatch       = new_class(loadlua.gameMainMatch)
    gameMainPrivate     = new_class(loadlua.gameMainPrivate)
    gameMainStatus      = new_class(loadlua.gameMainStatus)
    gameMainSystem      = new_class(loadlua.gameMainSystem)
    gameMainUser        = new_class(loadlua.gameMainUser)

    -- ����������
    gameManager = new_class(loadlua.GameManager)
    
end

function gamemain:onGameData(event)
    if event.name ~= CreateGame.GAME_DATA then return end 
    print( "gamemain:onGameData" )
    local msgtype = event.data.msgtype
    local wMainCmdID = event.data.wMainCmdID
    local wSubCmdID = event.data.wSubCmdID
    local packet = event.data.packet
    
    self:onEventTCPSocketRead(wMainCmdID, wSubCmdID, packet)

end

function gamemain:onEnterRoom(event)
    if event.name ~= CreateGame.ENTER_ROOM then return end

    LayerManager.show(loadlua.RoomLayer)
end

function gamemain:onEventTCPSocketRead(wMainCmdID, wSubCmdID, packet)
    print( "gamemain:onEventTCPSocketRead" )
--		//��¼��Ϣ 1 
	if wMainCmdID == MDM_GR_LOGON then
        gameMainLogon:OnSocketMainLogon(wMainCmdID, wSubCmdID, packet)
	elseif wMainCmdID ==  MDM_GR_CONFIG then
--		--		//������Ϣ 2 
        gameMainConfig:OnSocketMainConfig(wMainCmdID, wSubCmdID, packet)
	elseif wMainCmdID ==   MDM_GR_USER then
--		//�û���Ϣ 3
        gameMainUser:OnSocketMainUser(wMainCmdID, wSubCmdID, packet)
	elseif wMainCmdID ==   MDM_GR_STATUS then
        --//״̬��Ϣ 4 
        gameMainStatus:OnSocketMainStatus(wMainCmdID, wSubCmdID, packet)
	elseif wMainCmdID ==   MDM_CM_SYSTEM then 
    --		//ϵͳ��Ϣ 1000
        gameMainSystem:OnSocketMainSystem(wMainCmdID, wSubCmdID, packet)
	elseif wMainCmdID ==   MDM_GF_GAME or wMainCmdID ==   MDM_GF_FRAME then
--		//�����Ϣ--	100	//��Ϸ��Ϣ  200
        gameMainGameFrame:OnSocketMainGameFrame(wMainCmdID, wSubCmdID, packet)
	elseif wMainCmdID ==   MDM_GR_MATCH then
--		//������Ϣ 9 
        gameMainMatch:OnSocketMainMatch(wMainCmdID, wSubCmdID, packet)
	elseif wMainCmdID ==   MDM_GR_PRIVATE then
--		//˽�˳���Ϣ  10
        gameMainPrivate:OnSocketMainPrivate(wMainCmdID, wSubCmdID, packet)
    end
end

function gamemain:InitTcp(roomcode, rule, playerCountIdx, ip, port)
    --if self.ServerItemInfo == nil or self.ServerItemInfo.wServerPort == nil then return end
	local function connectCallback(connectType, data)
		if connectType == CreateGame.CONNECT_GAMESERVER_SUCC then
            -- ���ӳɹ�
            -- ���͵�½��Ϣ
            self:LoginGameServer()

			--local token = UserManager:getUserInfo():getLoginToken()
			--log("ConnectGameServer.connectCallback", token)
			--if not token or token == "" then
			--	this:GuestLoginGame()
			--else
			--	this:WechatLoginGame()
			--end
		end

        if connectType == CreateGame.CONNECT_GAMESERVER_FAIL then
            -- ����ʧ��

        end
		---SendClientInfoRequest()
	end

    ---- �������� -- ���뷿��
    local createitem = {}
    
    createitem.roomcode = roomcode
    createitem.rule = rule  -- ����
    createitem.playerCountIdx = playerCountIdx-- 8 ��  16 ��
    createitem.ip = ip
    createitem.port = port

    gameManager:getpubInfo():setCreateRoom(createitem)

    LinkServerController:ConnectGameServer(ip, port, connectCallback)

	--LinkServerController:ConnectGameServer(GAME_SERVER_DEFAULT.ip, self.ServerItemInfo.wServerPort, connectCallback)	
    	
end

function gamemain:LoginGameServer()
    if GameServerNet == nil then return end 

--[[
//���� ID ��¼
struct CMD_GR_LogonUserID
{
	dword							dwPlazaVersion;						//�㳡�汾
	dword							dwFrameVersion;						//��ܰ汾
	dword							dwProcessVersion;					//���̰汾

	//��¼��Ϣ
	dword							dwUserID;							//�û� I D
	char							szPassword[LEN_MD5];				//��¼����
	char							szMachineID[LEN_MACHINE_ID];		//��������
	word							wKindID;							//��������
};
]]

    local userdata = UserManager:getUserInfo():getData()
    if userdata == nil then return end 

    local CMD_GR_LogonUserID = {}

    CMD_GR_LogonUserID.dwPlazaVersion = pubFun.getPlazaVersion(10, 0, 3) --						//�㳡�汾
    CMD_GR_LogonUserID.dwFrameVersion = 0 --;						//��ܰ汾
    CMD_GR_LogonUserID.dwProcessVersion = pubFun.GetGameVersion() --;					//���̰汾
    
    
    CMD_GR_LogonUserID.dwUserID = userdata.dwUserID --;							//�û� I D
    CMD_GR_LogonUserID.szPassword = userdata.szPassword or "" --[LEN_MD5];				//��¼����
    CMD_GR_LogonUserID.szMachineID = "" --[LEN_MACHINE_ID];		//��������
    CMD_GR_LogonUserID.wKindID = GAMEID --;							//��������


    local s = string.pack( "I4", CMD_GR_LogonUserID.dwPlazaVersion,CMD_GR_LogonUserID.dwFrameVersion, CMD_GR_LogonUserID.dwProcessVersion, CMD_GR_LogonUserID.dwUserID)
    s = s .. pubFun.FillString( CMD_GR_LogonUserID.szPassword, LEN_MD5 )
    s = s .. pubFun.FillString( CMD_GR_LogonUserID.szMachineID, LEN_MACHINE_ID )

    s = s .. string.pack( "H", CMD_GR_LogonUserID.wKindID)

    -- maincmd 1   subcmd 1
    self:SendGamePack(MDM_GR_LOGON,SUB_GR_LOGON_USERID, s)
end

function gamemain:getServerPortFrmGameId(gameid)
    --[[
//��Ϸ�����б�ṹ
struct tagGameServer
{
	word							wKindID;							//��������
	word							wNodeID;							//�ڵ�����
	word							wSortID;							//��������
	word							wServerID;							//��������
	//WORD                            wServerKind;                        //��������
	word							wServerType;						//��������
	word							wServerPort;						//����˿�
	SCORE							lCellScore;							//��Ԫ����
	SCORE							lEnterScore;						//�������
	dword							dwServerRule;						//�������
	dword							dwOnLineCount;						//��������
	dword							dwAndroidCount;						//��������
	dword							dwFullCount;						//��Ա����
	char							szServerAddr[32];					//��������
	char							szServerName[LEN_SERVER];			//��������
};
]]
    local re = 0
    local data = UserManager:getServerData():getRoomInfo()
    if data ~= nil then
        for i, item in ipairs(data) do
            if item ~= nil then 
                if item.wKindID == gameid then 
                    re = item.wServerPort
                    break
                end
            end
        end    
    end
    return re
end

function gamemain:onConnectSucc()
    
end

function gamemain:onCreateGame()
    print("")
end

function gamemain:onBackHall()
end

return gamemain
