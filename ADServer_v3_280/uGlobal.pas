unit uGlobal;

interface

uses
  IniFiles, CPort, System.DateUtils, System.Classes, ShellAPI, Winapi.Windows,
  uTeeboxInfo, uTeeboxReserveList, uTeeboxThread,
  uConsts, uFunction, uStruct, uErpApi,
  { teebox }
  //uHeatControlCom,
  uComZoom, uComZoomCC,
  //uComJMS,
  uComJehu435, uComJehu60A, uComSM, uComInfornet, uComInfornetPLC, uComNano, uComNano2, uComWin,
  uComModen, uComModenYJ,
  uComFieldLo, uComMagicShot,
  //uComJeu60A, uComJehu50A,
  { heat }
  uHeatControlTcp, uComFan_DOME, uComHeat_DOME, uComHeat_A8003, uComHeat_D4001,
  uXGClientDM, uXGServer, uXGAgentServer,
  uLogging,
  { Indy }
  IdIcmpClient;

type
  TGlobal = class

  private
    FStore: TStoreInfo;
    FADConfig: TADConfig;
    FLog: TLog;
    FKioskList: array[0..10] of TKioskInfo;

    FTeebox: TTeebox;
    FReserveList: TTeeboxReserveList;
    FApi: TApiServer;

    FXGolfDM: TXGolfDM;
    FTcpServer: TTcpServer;
    FTcpAgentServer: TTcpAgentServer;
    FTeeboxThread: TTeeboxThread;

    FComZoom: TComThreadZoom;
    FComZoom_2: TComThreadZoom;
    FComZoom_3: TComThreadZoom;
    FComZoomCC: TComThreadZoomCC;
    FComZoomCC_2: TComThreadZoomCC;

    FComJehu435: TComThreadJehu435;
    FComJehu435_2: TComThreadJehu435;
    FComJehu435_3: TComThreadJehu435;

    //FComJehu50A: TComThreadJehu50A;

    FComJehu60A_1: TComThreadJehu60A;
    FComJehu60A_2: TComThreadJehu60A;
    FComJehu60A_3: TComThreadJehu60A;
    FComJehu60A_4: TComThreadJehu60A;

    FComModen_1: TComThreadModen;
    FComModen_2: TComThreadModen;
    FComModen_3: TComThreadModen;
    FComModen_4: TComThreadModen;

    FComModenYJ: TComThreadModenYJ;

    FComSM_1: TComThreadSM;
    FComSM_2: TComThreadSM;
    FComSM_3: TComThreadSM;
    FComSM_4: TComThreadSM;
    FComSM_5: TComThreadSM;
    FComSM_6: TComThreadSM;

    FComInfornet: TComThreadInfornet;
    FComInfornetPLC: TComThreadInfornetPLC;

    FComNano: TComThreadNano;
    FComNano2_1: TComThreadNano2;
    FComNano2_2: TComThreadNano2;
    FComNano2_3: TComThreadNano2;
    FComNano2_4: TComThreadNano2;

    //FControlComPortHeatMonThread: TControlComPortHeatMonThread;
    FTcpThreadHeat: TTcpThreadHeat;

    FComWin_1: TComThreadWin;
    FComWin_2: TComThreadWin;
    FComWin_3: TComThreadWin;

    FComFan_Dome: TComThreadFan_DOME;
    FComHeat_Dome: TComThreadHeat_DOME;
    FComHeat_A8003: TComThreadHeat_A8003;

    FComFieldLo: TComThreadFieldLo;
    FComMS: TComThreadMagicShot;

    FComHeat_D4001: TComThreadHeat_D4001;

    FAppName: string;
    FHomeDir: string;
    FConfig: TIniFile;
    FConfigFileName: string;
    FConfigBall: TIniFile;
    FConfigBallFileName: string;
    FConfigError: TIniFile;
    FConfigErrorFileName: string;
    FConfigHeat: TIniFile;
    FConfigHeatFileName: string;
    FConfigFan: TIniFile;
    FConfigFanFileName: string;
    FConfigDir: string;
    
    FTeeboxThreadTime: TDateTime;
    FHeatThreadTime: TDateTime;
    FPLCThreadTime: TDateTime;

    FTeeboxThreadError: String;
    FTeeboxThreadChk: Integer;
    FTeeboxControlTime: TDateTime;

    FTeeboxControlError: String;
    FTeeboxControlChk: Integer;

    FDebugSeatStatus: String;

    FCtrlBufferTemp1: String;
    FCtrlBufferTemp2: String;
    FCtrlBufferTemp3: String;
    FCtrlBufferTemp4: String;
    FCtrlBufferTemp5: String;
    FCtrlBufferTemp6: String;

    FReserveDBWrite: Boolean; //DB 재연결 확인용

    FSendACSTeeboxError: TDateTime;

    //FNoErpMode: Boolean; //파트너센터 에러시

    FDebugIndex: String;
    FDebugStart: String;
    FDebugEnd: String;

    procedure CheckConfig;
    procedure ReadConfig;
  public
    constructor Create;
    destructor Destroy; override;

    function StartUp: Boolean;
    function StopDown: Boolean;

    function GetErpOauth2: Boolean;

    procedure SetConfig(const ASection, AItem: string; const ANewValue: Variant);
    function GetStoreInfoToApi: Boolean;
    function GetConfigInfoToApi: Boolean;

    procedure DeleteDBReserve;
    procedure KioskTimeCheck;
    procedure SendSMSToErp(ASendDiv, ATeeboxNm: String);
    procedure SendACSToErp(ASendDiv, ATeeboxNm: String);

    property Store: TStoreInfo read FStore write FStore;
    //property Kiosk: TKioskInfo read FKiosk write FKiosk;
    property Teebox: TTeebox read FTeebox write FTeebox;
    property ReserveList: TTeeboxReserveList read FReserveList write FReserveList;
    property TeeboxThread: TTeeboxThread read FTeeboxThread write FTeeboxThread;
    property Api: TApiServer read FApi write FApi;
    property ADConfig: TADConfig read FADConfig write FADConfig;
    property TcpServer: TTcpServer read FTcpServer write FTcpServer;
    property TcpAgentServer: TTcpAgentServer read FTcpAgentServer write FTcpAgentServer;
    property Log: TLog read FLog write FLog;

    procedure DebugLogMainViewMulti(AIndex: Integer; ALog: string);
    procedure DebugLogFromViewMulti(AIndex: Integer; ALog: string);
    procedure DebugLogViewApiWrite(ALog: string);

    procedure SetADConfigToken(AToken: AnsiString);

    procedure WriteConfigStoreInfo;

    procedure SetKioskInfo(ADeviceNo, AUserId: String);
    procedure SetKioskPrint(ADeviceNo, AUserId, AError: String);

    function SetADConfigEmergency(AMode, AUserId: String): Boolean;

    procedure DNSPingCheck; //2021-11-02 핑
    procedure OnICmpClientReply(ASender: TComponent; const AReplyStatus: TReplyStatus);
    procedure DNSPingError; //2021-11-02 핑 20초 이상 않될시 인터넷 장애로 판단

    procedure TeeboxThreadTimeCheck; //DB, 예약번호 초기화등
    procedure HeatThreadTimeCheck;
    procedure TeeboxControlTimeCheck;
    procedure PLCThreadTimeCheck; //프라자

    procedure SetStoreInfoClose(AClose: String);
    procedure SetStoreUseRewardException(AType: String);

    procedure CtrlSendBuffer(ATeeboxNo: Integer; ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
    procedure CtrlHeatSendBuffer(ATeeboxNo: Integer; ATeeboxUse, AType: String);
    procedure CtrlFanSendBuffer(ATeeboxNo: Integer; ATeeboxUse, AType: String);

    procedure WriteConfigBall(ATeeboxNo: Integer);
    procedure WriteConfigBallBackDelay(ADelay: Integer);
    function ReadConfigBallBackStartTime: String;
    function ReadConfigBallPrepareStartTime(ATeeboxNo: Integer; AReserveNo: String): String;
    function ReadConfigBallRemainMin(ATeeboxNo: Integer): Integer;

    procedure WriteConfigError(ATeeboxNo, ARemainMin: Integer; ATeeboxNm, AReserveNo: String);
    procedure WriteConfigErrorReward(ATeeboxNo: Integer);
    procedure ReadConfigError(ATeeboxNo: Integer; var AReserveNo, AStart, AReward: String);

    function SetTeeboxHeatSetConfig(ATime, AUse: String): Boolean;
    function SetTeeboxHeatConfig(ATeebox, ATime, AUse, AAuto, AStartTm: String): Boolean;
    function SetTeeboxFanConfig(ATeeboxNm, ATime, AUse, AAuto, AStartTm: String): Boolean;
    function SetHeatStatus: Boolean;
    function SetFanStatus: Boolean;

    function SetDeviceTypeConfig(AType: Integer): Boolean;
    function SetHeatOnOffTimeConfig(AOnTime, AOffTime: Integer): Boolean;

    function ShowDebug: Boolean;

    procedure ReSetXGM;

    procedure WriteConfigAgentIP_R(ANo: Integer; AIP: String);
    procedure WriteConfigAgentIP_L(ANo: Integer; AIP: String);
    function ReadConfigAgentIP_R(ANo: Integer): String;
    function ReadConfigAgentIP_L(ANo: Integer): String;
    function ReadConfigAgentMAC_R(ANo: Integer): String;
    function ReadConfigAgentMAC_L(ANo: Integer): String;

    function ReadConfigBeamType(ANo: Integer): String;
    function ReadConfigBeamIP(ANo: Integer): String;
    function ReadConfigBeamPW(ANo: Integer): String;

    property XGolfDM: TXGolfDM read FXGolfDM write FXGolfDM;

    //property ControlComPortHeatMonThread: TControlComPortHeatMonThread read FControlComPortHeatMonThread write FControlComPortHeatMonThread;

    property TcpThreadHeat: TTcpThreadHeat read FTcpThreadHeat write FTcpThreadHeat;

    property ComZoom: TComThreadZoom read FComZoom write FComZoom;
    property ComZoom_2: TComThreadZoom read FComZoom_2 write FComZoom_2;
    property ComZoom_3: TComThreadZoom read FComZoom_3 write FComZoom_3;
    property ComZoomCC: TComThreadZoomCC read FComZoomCC write FComZoomCC;
    property ComZoomCC_2: TComThreadZoomCC read FComZoomCC_2 write FComZoomCC_2;

    property ComJehu435: TComThreadJehu435 read FComJehu435 write FComJehu435;
    property ComJehu435_2: TComThreadJehu435 read FComJehu435_2 write FComJehu435_2;
    property ComJehu435_3: TComThreadJehu435 read FComJehu435_3 write FComJehu435_3;

    //property ComJehu50A: TComThreadJehu50A read FComJehu50A write FComJehu50A;

    property ComJehu60A_1: TComThreadJehu60A read FComJehu60A_1 write FComJehu60A_1;
    property ComJehu60A_2: TComThreadJehu60A read FComJehu60A_2 write FComJehu60A_2;
    property ComJehu60A_3: TComThreadJehu60A read FComJehu60A_3 write FComJehu60A_3;
    property ComJehu60A_4: TComThreadJehu60A read FComJehu60A_4 write FComJehu60A_4;

    property ComModen_1: TComThreadModen read FComModen_1 write FComModen_1;
    property ComModen_2: TComThreadModen read FComModen_2 write FComModen_2;
    property ComModen_3: TComThreadModen read FComModen_3 write FComModen_3;
    property ComModen_4: TComThreadModen read FComModen_4 write FComModen_4;

    property ComModenYJ: TComThreadModenYJ read FComModenYJ write FComModenYJ;

    property ComFieldLo: TComThreadFieldLo read FComFieldLo write FComFieldLo;

    property ComSM_1: TComThreadSM read FComSM_1 write FComSM_1;
    property ComSM_2: TComThreadSM read FComSM_2 write FComSM_2;
    property ComSM_3: TComThreadSM read FComSM_3 write FComSM_3;
    property ComSM_4: TComThreadSM read FComSM_4 write FComSM_4;
    property ComSM_5: TComThreadSM read FComSM_5 write FComSM_5;
    property ComSM_6: TComThreadSM read FComSM_6 write FComSM_6;

    property ComInfornet: TComThreadInfornet read FComInfornet write FComInfornet;
    property ComInfornetPLC: TComThreadInfornetPLC read FComInfornetPLC write FComInfornetPLC;

    property ComNano: TComThreadNano read FComNano write FComNano;

    property ComNano2_1: TComThreadNano2 read FComNano2_1 write FComNano2_1;
    property ComNano2_2: TComThreadNano2 read FComNano2_2 write FComNano2_2;
    property ComNano2_3: TComThreadNano2 read FComNano2_3 write FComNano2_3;
    property ComNano2_4: TComThreadNano2 read FComNano2_4 write FComNano2_4;

    property ComWin_1: TComThreadWin read FComWin_1 write FComWin_1;
    property ComWin_2: TComThreadWin read FComWin_2 write FComWin_2;
    property ComWin_3: TComThreadWin read FComWin_3 write FComWin_3;

    property ComMS: TComThreadMagicShot read FComMS write FComMS;

    property ComFan_Dome: TComThreadFan_DOME read FComFan_Dome write FComFan_Dome;
    property ComHeat_Dome: TComThreadheat_DOME read FComHeat_Dome write FComHeat_Dome;
    property ComHeat_A8003: TComThreadheat_A8003 read FComHeat_A8003 write FComHeat_A8003; //쇼골프(가양점) 히터
    property ComHeat_D4001: TComThreadheat_D4001 read FComHeat_D4001 write FComHeat_D4001; //수원CC 냉난방

    property AppName: string read FAppName write FAppName;
    property HomeDir: string read FHomeDir write FHomeDir;
    property ConfigDir: string read FConfigDir write FConfigDir;
    property Config: TIniFile read FConfig write FConfig;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;
    property ConfigBall: TIniFile read FConfigBall write FConfigBall;
    property ConfigBallFileName: string read FConfigBallFileName write FConfigBallFileName;
    property ConfigError: TIniFile read FConfigError write FConfigError;
    property ConfigErrorFileName: string read FConfigErrorFileName write FConfigErrorFileName;

    property CtrlBufferTemp1: string read FCtrlBufferTemp1 write FCtrlBufferTemp1;
    property CtrlBufferTemp2: string read FCtrlBufferTemp2 write FCtrlBufferTemp2;
    property CtrlBufferTemp3: string read FCtrlBufferTemp3 write FCtrlBufferTemp3;
    property CtrlBufferTemp4: string read FCtrlBufferTemp4 write FCtrlBufferTemp4;
    property CtrlBufferTemp5: string read FCtrlBufferTemp5 write FCtrlBufferTemp5;
    property CtrlBufferTemp6: string read FCtrlBufferTemp6 write FCtrlBufferTemp6;

    property TeeboxThreadTime: TDateTime read FTeeboxThreadTime write FTeeboxThreadTime;
    property HeatThreadTime: TDateTime read FHeatThreadTime write FHeatThreadTime;
    property PLCThreadTime: TDateTime read FPLCThreadTime write FPLCThreadTime;

    property TeeboxThreadError: String read FTeeboxThreadError write FTeeboxThreadError;
    property TeeboxControlTime: TDateTime read FTeeboxControlTime write FTeeboxControlTime;
    property TeeboxControlError: String read FTeeboxControlError write FTeeboxControlError;

    property ReserveDBWrite: Boolean read FReserveDBWrite write FReserveDBWrite;

    property SendACSTeeboxError: TDateTime read FSendACSTeeboxError write FSendACSTeeboxError;

    property DebugIndex: String read FDebugIndex write FDebugIndex;
    property DebugStart: String read FDebugStart write FDebugStart;
    property DebugEnd: String read FDebugEnd write FDebugEnd;

    //property NoErpMode: Boolean read FNoErpMode write FNoErpMode;
  end;

var
  Global: TGlobal;

implementation

uses
  SysUtils, Variants, uXGMainForm, Vcl.Graphics, JSON,
  IdGlobal, uDebug;

{ TGlobal }

constructor TGlobal.Create;
var
  sStr: string;
  nIndex: Integer;
begin
  FAppName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  FHomeDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  FConfigDir := FHomeDir + 'config\';
  FConfigFileName := FConfigDir + 'Xtouch_v3.config';
  ForceDirectories(FConfigDir);
  FConfig := TIniFile.Create(FConfigFileName);
  if not FileExists(FConfigFileName) then
  begin
    WriteFile(FConfigFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigFileName, '');
  end;

  FConfigBallFileName := FConfigDir + 'XtouchfBall_v3.config';
  FConfigBall := TIniFile.Create(FConfigBallFileName);
  if not FileExists(FConfigBallFileName) then
  begin
    WriteFile(FConfigBallFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigBallFileName, '');

    FConfigBall.WriteString('BallBack', 'Start', '');

    for nIndex := 1 to 100 do
    begin
      FConfigBall.WriteString('Teebox_' + IntToStr(nIndex), 'ReserveNo', '');
    end;
  end;

  FConfigErrorFileName := FConfigDir + 'XtouchfError_v3.config';
  FConfigError := TIniFile.Create(FConfigErrorFileName);
  if not FileExists(FConfigErrorFileName) then
  begin
    WriteFile(FConfigErrorFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigErrorFileName, '');

    for nIndex := 1 to 100 do
    begin
      FConfigError.WriteString('Teebox_' + IntToStr(nIndex), 'TeeboxNm', '');
      FConfigError.WriteString('Teebox_' + IntToStr(nIndex), 'ReserveNo', '');
      FConfigError.WriteString('Teebox_' + IntToStr(nIndex), 'RemainMinute', '');
      FConfigError.WriteString('Teebox_' + IntToStr(nIndex), 'Start', '');
      FConfigError.WriteString('Teebox_' + IntToStr(nIndex), 'End', '');
      FConfigError.WriteString('Teebox_' + IntToStr(nIndex), 'Reward', '');
    end;
  end;

  FConfigHeatFileName := FConfigDir + 'XtouchfHeat_v3.config';
  FConfigHeat := TIniFile.Create(FConfigHeatFileName);
  if not FileExists(FConfigHeatFileName) then
  begin
    WriteFile(FConfigHeatFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigHeatFileName, '');
    {
    for nIndex := 1 to 100 do
    begin
      FConfigHeat.WriteString('TeeboxNm_' + IntToStr(nIndex), 'HeatUse', '0');
    end;
    }
  end;

  FConfigFanFileName := FConfigDir + 'XtouchfFan_v3.config';
  FConfigFan := TIniFile.Create(FConfigFanFileName);
  if not FileExists(FConfigFanFileName) then
  begin
    WriteFile(FConfigFanFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigFanFileName, '');

    for nIndex := 1 to 70 do
    begin
      FConfigFan.WriteString('TeeboxNm_' + IntToStr(nIndex), 'FanUse', '0');
    end;
  end;

  CheckConfig;
  ReadConfig; //파트너센터 접속정보

  FTeeboxThreadTime := Now;
  FPLCThreadTime := Now; //프라자

  FDebugSeatStatus := '0';
  FTeeboxThreadChk := 0;
  FTeeboxControlChk := 0;
  FReserveDBWrite := False;
  //FNoErpMode := False;
end;

function TGlobal.GetErpOauth2: Boolean;
var
  sResult: String;
  sToken: AnsiString;
begin
  Result := False;

  if FADConfig.ADToken <> '' then
  begin
    sResult := Api.GetTokenChk(FADConfig.ApiUrl, FADConfig.UserId, FADConfig.UserPw, FADConfig.ADToken);
    if sResult <> 'Success' then
    begin
      Log.LogWrite(sResult);

      sResult := Api.GetOauth2(sToken, FADConfig.ApiUrl, FADConfig.UserId, FADConfig.UserPw);
      if sResult = 'Success' then
      begin
        SetADConfigToken(sToken);
        Log.LogWrite('Token '  + sResult);
      end
      else
      begin
        Log.LogWrite(sResult);
        Exit;
      end;
    end;
  end
  else
  begin
    sResult := Api.GetOauth2(sToken, FADConfig.ApiUrl, FADConfig.UserId, FADConfig.UserPw);
    if sResult = 'Success' then
    begin
      SetADConfigToken(sToken);
      Log.LogWrite('Token ' + sResult);
    end
    else
    begin
      Log.LogWrite(sResult);
      Exit;
    end;
  end;

  Result := True;
end;

function TGlobal.StartUp: Boolean;
var
  sResult: String;
  sToken: AnsiString;
  sStr: String;
  I: integer;
begin
  Result := False;

  Log := TLog.Create;
  FTcpServer := TTcpServer.Create;
  Api := TApiServer.Create;

  if ADConfig.Emergency = False then
  begin
    if GetErpOauth2 = False then
    begin
      SetADConfigEmergency('Y', ADConfig.UserId);
    end;
  end;

  if ADConfig.Emergency = False then
  begin

    //환경설정
    if GetConfigInfoToApi = False then
      Exit;

    ReadConfig; //파트너센터 정보 다시 읽기

    if GetStoreInfoToApi = False then
      Exit;

    {
    //최초실행시,재설치시 ERP서버 배정정보 호출
    if FADConfig.SystemInstall <> '1' then
    begin
      if FTcpServer.GetErpTeeboxList = False then
        Exit;

      FConfig.WriteString('ADInfo', 'SystemInstall', '1');
    end;
    }
  end;

  XGolfDM := TXGolfDM.Create(Nil);

  Teebox := TTeebox.Create; //타석기정보
  ReserveList := TTeeboxReserveList.Create; //타석기 예약목록
  TeeboxThread := TTeeboxThread.Create; //타석기 예약정보관리

  Teebox.StartUp;
  TeeboxThread.Resume;

  if (FADConfig.ProtocolType = 'JEHU435') or (FADConfig.ProtocolType = 'AD_JEU435') then
  begin
    if ADConfig.StoreCode = 'A8001' then
    begin
      ComJehu435 := TComThreadJehu435.Create;
      ComJehu435.ComPortSetting('1', 1, 1, 63, ADConfig.Port, ADConfig.Baudrate); //63타석, 1번 좌우겸용, 총 64개타석기
      ComJehu435.Resume;

      {$IFDEF RELEASE}
      ComJehu435_2 := TComThreadJehu435.Create;
      ComJehu435_2.ComPortSetting('2', 2, 64, 128, ADConfig.Port2, ADConfig.Baudrate2); //65타석, 1번 좌우겸용, 총 66개타석기
      ComJehu435_2.Resume;
      ComJehu435_3 := TComThreadJehu435.Create;
      ComJehu435_3.ComPortSetting('3', 3, 129, 182, ADConfig.Port3, ADConfig.Baudrate3); //65타석, 1번 좌우겸용, 11타석 미사용,  총 55개타석기
      ComJehu435_3.Resume;
      {$ENDIF}

    end
    else //if ADConfig.StoreCode = 'BF001' then //두성
    begin
      for I := 1 to Global.ADConfig.PortCnt do
      begin
        if I = 1 then
        begin
          ComJehu435 := TComThreadJehu435.Create;
          ComJehu435.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
          ComJehu435.Resume;
        end;
        if I = 2 then
        begin
          ComJehu435_2 := TComThreadJehu435.Create;
          ComJehu435_2.ComPortSetting(ADConfig.Port2FloorCd, 2, ADConfig.Port2Start, ADConfig.Port2End, ADConfig.Port2, ADConfig.Baudrate2);
          ComJehu435_2.Resume;
        end;
      end;
    end;
  end
  {
  else if (FADConfig.ProtocolType = 'JEHU50A') then
  begin
    ComJehu50A := TComThreadJehu50A.Create;
    ComJehu50A.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
    ComJehu50A.Resume;
  end
  }
  else if (FADConfig.ProtocolType = 'JEHU60A') then
  begin
    for I := 1 to Global.ADConfig.PortCnt do
    begin
      if I = 1 then
      begin
        ComJehu60A_1 := TComThreadJehu60A.Create;
        ComJehu60A_1.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
        ComJehu60A_1.Resume;
      end;
      if I = 2 then
      begin
        ComJehu60A_2 := TComThreadJehu60A.Create;
        ComJehu60A_2.ComPortSetting(ADConfig.Port2FloorCd, 2, ADConfig.Port2Start, ADConfig.Port2End, ADConfig.Port2, ADConfig.Baudrate2);
        ComJehu60A_2.Resume;
      end;
      if I = 3 then
      begin
        ComJehu60A_3 := TComThreadJehu60A.Create;
        ComJehu60A_3.ComPortSetting(ADConfig.Port3FloorCd, 3, ADConfig.Port3Start, ADConfig.Port3End, ADConfig.Port3, ADConfig.Baudrate3);
        ComJehu60A_3.Resume;
      end;
      if I = 4 then
      begin
        ComJehu60A_4 := TComThreadJehu60A.Create;
        ComJehu60A_4.ComPortSetting(ADConfig.Port4FloorCd, 4, ADConfig.Port4Start, ADConfig.Port4End, ADConfig.Port4, ADConfig.Baudrate4);
        ComJehu60A_4.Resume;
      end;
    end;
  end
  else if FADConfig.ProtocolType = 'SM' then // 타석번호로DeviceId 체크
  begin
    for I := 1 to Global.ADConfig.PortCnt do
    begin
      if I = 1 then
      begin
        ComSM_1 := TComThreadSM.Create;
        ComSM_1.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
        ComSM_1.Resume;
      end;
      if I = 2 then
      begin
        ComSM_2 := TComThreadSM.Create;
        ComSM_2.ComPortSetting(ADConfig.Port2FloorCd, 2, ADConfig.Port2Start, ADConfig.Port2End, ADConfig.Port2, ADConfig.Baudrate2);
        ComSM_2.Resume;
      end;
      if I = 3 then
      begin
        ComSM_3 := TComThreadSM.Create;
        ComSM_3.ComPortSetting(ADConfig.Port3FloorCd, 3, ADConfig.Port3Start, ADConfig.Port3End, ADConfig.Port3, ADConfig.Baudrate3);
        ComSM_3.Resume;
      end;
      if I = 4 then
      begin
        ComSM_4 := TComThreadSM.Create;
        ComSM_4.ComPortSetting(ADConfig.Port4FloorCd, 4, ADConfig.Port4Start, ADConfig.Port4End, ADConfig.Port4, ADConfig.Baudrate4);
        ComSM_4.Resume;
      end;
      if I = 5 then
      begin
        ComSM_5 := TComThreadSM.Create;
        ComSM_5.ComPortSetting(ADConfig.Port5FloorCd, 5, ADConfig.Port5Start, ADConfig.Port5End, ADConfig.Port5, ADConfig.Baudrate5);
        ComSM_5.Resume;
      end;
      if I = 6 then
      begin
        ComSM_6 := TComThreadSM.Create;
        ComSM_6.ComPortSetting(ADConfig.Port6FloorCd, 6, ADConfig.Port6Start, ADConfig.Port6End, ADConfig.Port6, ADConfig.Baudrate6);
        ComSM_6.Resume;
      end;
    end;

    if (Global.ADConfig.StoreCode = 'C0001') then //강릉리더스
    begin
      ComMS := TComThreadMagicShot.Create;
      ComMS.ComPortSetting(ADConfig.Port5FloorCd, 5, ADConfig.Port5Start, ADConfig.Port5End, ADConfig.Port5, ADConfig.Baudrate5);
      ComMS.Resume;
    end;
  end
  else if FADConfig.ProtocolType = 'MODEN' then
  begin
    for I := 1 to Global.ADConfig.PortCnt do
    begin
      if I = 1 then
      begin
        ComModen_1 := TComThreadModen.Create;
        ComModen_1.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
        ComModen_1.Resume;
      end;
      if I = 2 then
      begin
        ComModen_2 := TComThreadModen.Create;
        ComModen_2.ComPortSetting(ADConfig.Port2FloorCd, 2, ADConfig.Port2Start, ADConfig.Port2End, ADConfig.Port2, ADConfig.Baudrate2);
        ComModen_2.Resume;
      end;
      if I = 3 then
      begin
        ComModen_3 := TComThreadModen.Create;
        ComModen_3.ComPortSetting(ADConfig.Port3FloorCd, 3, ADConfig.Port3Start, ADConfig.Port3End, ADConfig.Port3, ADConfig.Baudrate3);
        ComModen_3.Resume;
      end;
      if I = 4 then
      begin
        ComModen_4 := TComThreadModen.Create;
        ComModen_4.ComPortSetting(ADConfig.Port4FloorCd, 4, ADConfig.Port4Start, ADConfig.Port4End, ADConfig.Port4, ADConfig.Baudrate4);
        ComModen_4.Resume;
      end;

    end;
  end
  else if FADConfig.ProtocolType = 'MODENYJ' then
  begin
    ComModenYJ := TComThreadModenYJ.Create;
    ComModenYJ.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
    ComModenYJ.Resume;
  end
  else if FADConfig.ProtocolType = 'INFORNET' then
  begin
    ComInfornet := TComThreadInfornet.Create;
    ComInfornet.ComPortSetting('0', 1, 1, 52, ADConfig.Port, ADConfig.Baudrate);
    ComInfornet.Resume;
    //{$IFDEF RELEASE}
    //ComInfornetPLC := TComThreadInfornetPLC.Create;
    //ComInfornetPLC.ComPortSetting('0', 2, Global.ADConfig.Port2, Global.ADConfig.Baudrate2); //53~ 전원제어
    //ComInfornetPLC.Resume;
    //{$ENDIF}
  end
  else if (FADConfig.ProtocolType = 'ZOOM') then
  begin

    for I := 1 to Global.ADConfig.PortCnt do
    begin
      if I = 1 then
      begin
        ComZoom := TComThreadZoom.Create;
        //ComZoom.ComPortSetting('0', 1, 1, 72, ADConfig.Port, ADConfig.Baudrate); //B2001	그린필드골프연습장
        ComZoom.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
        ComZoom.Resume;
      end
      else if I = 2 then
      begin
        ComZoom_2 := TComThreadZoom.Create;
        ComZoom_2.ComPortSetting(ADConfig.Port2FloorCd, 2, ADConfig.Port2Start, ADConfig.Port2End, ADConfig.Port2, ADConfig.Baudrate2);
        ComZoom_2.Resume;
      end
      else if I = 3 then
      begin
        ComZoom_3 := TComThreadZoom.Create;
        ComZoom_3.ComPortSetting(ADConfig.Port3FloorCd, 3, ADConfig.Port3Start, ADConfig.Port3End, ADConfig.Port3, ADConfig.Baudrate3);
        ComZoom_3.Resume;
      end;
    end;

    if (Global.ADConfig.StoreCode = 'AA001') then // AA001	엠스퀘어골프클럽
    begin
      ComZoomCC_2 := TComThreadZoomCC.Create;
      ComZoomCC_2.ComPortSetting(ADConfig.Port2FloorCd, 2, ADConfig.Port2Start, ADConfig.Port2End, ADConfig.Port2, ADConfig.Baudrate2);
      ComZoomCC_2.Resume;
    end;
  end
  else if FADConfig.ProtocolType = 'ZOOMCC' then
  begin
    ComZoomCC := TComThreadZoomCC.Create;

    if (Global.ADConfig.StoreCode = 'A8003') then // 쇼골프 가양점
      ComZoomCC.ComPortSetting('0', 1, 1, 45, ADConfig.Port, ADConfig.Baudrate)
    else if (Global.ADConfig.StoreCode = 'A5001') then // 송도
      ComZoomCC.ComPortSetting('0', 1, 1, 30, ADConfig.Port, ADConfig.Baudrate)
    else
      ComZoomCC.ComPortSetting('0', 1, 1, 52, ADConfig.Port, ADConfig.Baudrate);

    ComZoomCC.Resume;
  end
  else if FADConfig.ProtocolType = 'NANO' then
  begin
    ComNano := TComThreadNano.Create;
    ComNano.ComPortSetting('0', 1, 1, Teebox.TeeboxLastNo, ADConfig.Port, ADConfig.Baudrate);  //제이제이
    ComNano.Resume;
  end
  else if FADConfig.ProtocolType = 'NANO2' then
  begin

    if (Global.ADConfig.StoreCode = 'B5001') then //김포정원
    begin
      for I := 1 to Global.ADConfig.PortCnt do
      begin
        if I = 1 then
        begin
          ComNano2_1 := TComThreadNano2.Create;
          ComNano2_1.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
          ComNano2_1.Resume;
        end;
        if I = 2 then
        begin
          ComNano2_2 := TComThreadNano2.Create;
          ComNano2_2.ComPortSetting(ADConfig.Port2FloorCd, 2, ADConfig.Port2Start, ADConfig.Port2End, ADConfig.Port2, ADConfig.Baudrate2);
          ComNano2_2.Resume;
        end;
        if I = 3 then
        begin
          ComNano2_3 := TComThreadNano2.Create;
          ComNano2_3.ComPortSetting(ADConfig.Port3FloorCd, 3, ADConfig.Port3Start, ADConfig.Port3End, ADConfig.Port3, ADConfig.Baudrate3);
          ComNano2_3.Resume;
        end;

        if I = 4 then
        begin
          ComNano2_4 := TComThreadNano2.Create;
          ComNano2_4.ComPortSetting(ADConfig.Port4FloorCd, 4, ADConfig.Port4Start, ADConfig.Port4End, ADConfig.Port4, ADConfig.Baudrate4);
          ComNano2_4.Resume;
        end;

      end;
    end
    else
    begin
      ComNano2_1 := TComThreadNano2.Create;
      if (Global.ADConfig.StoreCode = 'B8001') then // 제이제이골프클럽
        ComNano2_1.ComPortSetting('0', 1, 1, 72, ADConfig.Port, ADConfig.Baudrate)
      else
        ComNano2_1.ComPortSetting('0', 1, 1, 38, ADConfig.Port, ADConfig.Baudrate); //쇼골프(여의도)
      ComNano2_1.Resume;
    end;
  end
  else if FADConfig.ProtocolType = 'WIN' then
  begin
    ComWin_1 := TComThreadWin.Create;
    ComWin_1.ComPortSetting('1', 1, 1, 20, ADConfig.Port, ADConfig.Baudrate);
    ComWin_1.Resume;
    {$IFDEF RELEASE}
    ComWin_2 := TComThreadWin.Create;
    ComWin_2.ComPortSetting('2', 2, 21, 40, ADConfig.Port2, ADConfig.Baudrate2);
    ComWin_2.Resume;
    ComWin_3 := TComThreadWin.Create;
    ComWin_3.ComPortSetting('3', 3, 41, 60, ADConfig.Port3, ADConfig.Baudrate3);
    ComWin_3.Resume;
    {$ENDIF}
  end
  else if FADConfig.ProtocolType = 'MAGICSHOT' then
  begin
    ComMS := TComThreadMagicShot.Create;
    ComMS.ComPortSetting(ADConfig.PortFloorCd, 1, ADConfig.PortStart, ADConfig.PortEnd, ADConfig.Port, ADConfig.Baudrate);
    ComMS.Resume;
  end;

  // 부가 제어(타석기 외)
  if (Global.ADConfig.StoreCode = 'B7001') then //B7001	프라자골프연습장
  begin
    {$IFDEF RELEASE}
    ComInfornetPLC := TComThreadInfornetPLC.Create;
    ComInfornetPLC.ComPortSetting('0', 2, ADConfig.Port2, ADConfig.Baudrate2); //53~ 전원제어
    ComInfornetPLC.Resume;
    {$ENDIF}
  end;

  //heat - 드림테크/ 그린필드, 쇼골프
  if FADConfig.HeatTcpPort <> 0 then
  begin
    TcpThreadHeat := TTcpThreadHeat.Create;
    SetHeatStatus;
    TcpThreadHeat.Resume;
  end;

  if (Global.ADConfig.StoreCode = 'BB001') then //돔골프
  begin
    if FADConfig.HeatPort <> 0 then
    begin
      ComHeat_Dome := TComThreadHeat_DOME.Create;
      SetHeatStatus;
      ComHeat_Dome.HeatOnOffTimeSetting(FADConfig.HeatOnTime, FADConfig.HeatOffTime);
      ComHeat_Dome.Resume;
    end;

    if FADConfig.FanPort <> 0 then
    begin
      ComFan_Dome := TComThreadFan_DOME.Create;
      SetFanStatus;
      ComFan_Dome.Resume;
    end;
  end;

  if (Global.ADConfig.StoreCode = 'A8003') then //쇼골프(가양점)
  begin
    if FADConfig.HeatPort <> 0 then
    begin
      ComHeat_A8003 := TComThreadHeat_A8003.Create;
      SetHeatStatus;
      //Global.Log.LogWrite('TComThreadHeat_A8003 SetHeatStatus');
      ComHeat_A8003.Resume;
      //Global.Log.LogWrite('TComThreadHeat_A8003 Resume');
    end;
  end;

  if (Global.ADConfig.StoreCode = 'D4001') then // 수원CC
  begin
    if FADConfig.HeatPort <> 0 then
    begin
      ComHeat_D4001 := TComThreadHeat_D4001.Create;
      SetHeatStatus;
      ComHeat_D4001.Resume;
    end;
  end;

  // 부가 제어(타석기 필드로)
  if (Global.ADConfig.StoreCode = 'A8004') then //A8004	쇼골프(도봉점)
  begin
    {$IFDEF RELEASE}
    if FADConfig.Port5 <> 0 then
    begin
      ComFieldLo := TComThreadFieldLo.Create;
      ComFieldLo.ComPortSetting('0', 5, ADConfig.Port5Start, ADConfig.Port5End, ADConfig.Port5, ADConfig.Baudrate5);
      ComFieldLo.Resume;
    end;
    {$ENDIF}
  end;

  // 부가 제어(실내 에이전트)
  if (Global.ADConfig.StoreCode = 'CD001') then //CD001	스타골프클럽(일산)
  begin
    FTcpAgentServer := TTcpAgentServer.Create;
  end;

  Result := True;
end;

procedure TGlobal.CtrlSendBuffer(ATeeboxNo: Integer; ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
  sHeatUse, sFanUse: String;
begin
  if ComJehu435 <> nil then
  begin
    if ADConfig.StoreCode = 'A8001' then
    begin
      if ATeeboxNo <= 63 then
        ComJehu435.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= 128 then
        ComJehu435_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else
        ComJehu435_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end
    else //if ADConfig.StoreCode = 'BF001' then //두성, 분당 그린피아
    begin
      if ATeeboxNo <= Global.ADConfig.PortEnd then
        ComJehu435.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= Global.ADConfig.Port2End then
        ComJehu435_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end;
  end;
  {
  if ComJehu50A <> nil then
  begin
    ComJehu50A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end;
  }
  if ComJehu60A_1 <> nil then
  begin
    if ATeeboxNo <= Global.ADConfig.PortEnd then
      ComJehu60A_1.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port2End then
      ComJehu60A_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port3End then
      ComJehu60A_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port4End then
      ComJehu60A_4.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end;

  if ComSM_1 <> nil then
  begin
    {
    if ATeeboxNo <= Global.ADConfig.PortEnd then
      ComSM_1.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port2End then
      ComSM_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port3End then
      ComSM_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port4End then
      ComSM_4.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port5End then
      ComSM_5.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else
      ComSM_6.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    }

    if (ATeeboxNo >= Global.ADConfig.PortStart) and (ATeeboxNo <= Global.ADConfig.PortEnd) then
      ComSM_1.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if (ATeeboxNo >= Global.ADConfig.Port2Start) and (ATeeboxNo <= Global.ADConfig.Port2End) then
      ComSM_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if (ATeeboxNo >= Global.ADConfig.Port3Start) and (ATeeboxNo <= Global.ADConfig.Port3End) then
      ComSM_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if (ATeeboxNo >= Global.ADConfig.Port4Start) and (ATeeboxNo <= Global.ADConfig.Port4End) then
      ComSM_4.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if (ATeeboxNo >= Global.ADConfig.Port5Start) and (ATeeboxNo <= Global.ADConfig.Port5End) then
    begin
      if (Global.ADConfig.StoreCode = 'C0001') then //강릉리더스
        ComMS.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else
        ComSM_5.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end
    else
      ComSM_6.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end;

  if ComModen_1 <> nil then
  begin
    if ATeeboxNo <= Global.ADConfig.PortEnd then
      ComModen_1.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port2End then
      ComModen_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port3End then
      ComModen_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port4End then
      ComModen_4.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= Global.ADConfig.Port5End then
    begin
      if (Global.ADConfig.StoreCode = 'A8004') then //A8004	쇼골프(도봉점)
        ComFieldLo.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end;
  end;

  if ComInfornet <> nil then
  begin
    if ATeeboxNo <= 52 then
      ComInfornet.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else
    begin
      if ComInfornetPLC <> nil then //3층 전원제어
      begin
        rTeeboxInfo := Teebox.GetTeeboxInfo(ATeeboxNo);
        if StrToInt(ATeeboxTime) > 0 then
          ComInfornetPLC.SetTeeboxUse(rTeeboxInfo.TeeboxNm, '1')
        else
          ComInfornetPLC.SetTeeboxUse(rTeeboxInfo.TeeboxNm, '0');

        ComInfornetPLC.SetCmdSendBuffer;
      end;
    end;
  end;

  if ComZoom <> nil then
  begin
    if (Global.ADConfig.StoreCode = 'AA001') then // AA001	엠스퀘어골프클럽
    begin
      if ATeeboxNo <= Global.ADConfig.PortEnd then
        ComZoom.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else
        ComZoomCC_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end
    else
    begin
      if ATeeboxNo <= Global.ADConfig.PortEnd then
        ComZoom.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= Global.ADConfig.Port2End then
        ComZoom_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= Global.ADConfig.Port3End then
        ComZoom_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end;
  end;

  if ComZoomCC <> nil then
  begin
    if Global.ADConfig.StoreCode = 'B7001' then //프라자
    begin
      if ATeeboxNo <= 52 then
        ComZoomCC.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else
      begin
        if ComInfornetPLC <> nil then //3층 전원제어
        begin
          rTeeboxInfo := Teebox.GetTeeboxInfo(ATeeboxNo);
          if StrToInt(ATeeboxTime) > 0 then
            ComInfornetPLC.SetTeeboxUse(rTeeboxInfo.TeeboxNm, '1')
          else
            ComInfornetPLC.SetTeeboxUse(rTeeboxInfo.TeeboxNm, '0');

          ComInfornetPLC.SetCmdSendBuffer;
        end;
      end;
    end
    else
      ComZoomCC.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end;

  if ComNano <> nil then
  begin
    ComNano.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end;

  if ComNano2_1 <> nil then
  begin
    rTeeboxInfo := Teebox.GetTeeboxInfo(ATeeboxNo);

    if (Global.ADConfig.StoreCode = 'B5001') then //김포정원
    begin
      if ATeeboxNo <= Global.ADConfig.PortEnd then
        ComNano2_1.SetCmdSendBuffer(ADeviceId, rTeeboxInfo.TeeboxNm, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= Global.ADConfig.Port2End then
        ComNano2_2.SetCmdSendBuffer(ADeviceId, rTeeboxInfo.TeeboxNm, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= Global.ADConfig.Port3End then
        ComNano2_3.SetCmdSendBuffer(ADeviceId, rTeeboxInfo.TeeboxNm, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= Global.ADConfig.Port4End then
        ComNano2_4.SetCmdSendBuffer(ADeviceId, rTeeboxInfo.TeeboxNm, ATeeboxTime, ATeeboxBall, AType);
    end
    else
    begin
      ComNano2_1.SetCmdSendBuffer(ADeviceId, rTeeboxInfo.TeeboxNm, ATeeboxTime, ATeeboxBall, AType);
    end;
  end;

  if ComWin_1 <> nil then
  begin
    if ATeeboxNo <= 20 then
      ComWin_1.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= 40 then
      ComWin_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else
      ComWin_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end;

  //heat
  if FADConfig.HeatTcpPort <> 0 then
  begin
    if ADConfig.HeatAuto = '1' then
    begin
      sHeatUse := '0';
      if StrToInt(ATeeboxTime) > 0 then
        sHeatUse := '1';

      CtrlHeatSendBuffer(ATeeboxNo, sHeatUse, '1');
    end;
  end;

  if (Global.ADConfig.StoreCode = 'BB001') then //돔골프
  begin
    //fan
    if Global.ADConfig.DeviceType = 0 then
    begin
      if FADConfig.FanPort <> 0 then
      begin
        if ADConfig.HeatAuto = '1' then //돔골프 옵션 같이 사용함
        begin
          sFanUse := '0';
          if StrToInt(ATeeboxTime) > 0 then
            sFanUse := '1';

          CtrlFanSendBuffer(ATeeboxNo, sFanUse, '1');
        end;
      end;
    end
    else
    begin
      //heat
      if FADConfig.HeatPort <> 0 then
      begin
        if ADConfig.HeatAuto = '1' then
        begin
          sHeatUse := '0';
          if StrToInt(ATeeboxTime) > 0 then
            sHeatUse := '1';

          CtrlHeatSendBuffer(ATeeboxNo, sHeatUse, '1');
        end;
      end;
    end;

  end;

  if (Global.ADConfig.StoreCode = 'A8003') or (Global.ADConfig.StoreCode = 'D4001') then //쇼골프(가양점)
  begin
    //heat
    if FADConfig.HeatPort <> 0 then
    begin
      if ADConfig.HeatAuto = '1' then
      begin
        sHeatUse := '0';
        if StrToInt(ATeeboxTime) > 0 then
          sHeatUse := '1';

        CtrlHeatSendBuffer(ATeeboxNo, sHeatUse, '1');
      end;
    end;
  end;

end;

procedure TGlobal.CtrlHeatSendBuffer(ATeeboxNo: Integer; ATeeboxUse, AType: String);
var
  sSendData, sBcc: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
  sHeatTaget, sResult: String;
begin
  if (ADConfig.StoreCode = 'A6001') and (ATeeboxNo >= 99) then //A6001	캐슬렉스서울
    Exit;

  if (Global.ADConfig.StoreCode = 'A8004') and (ATeeboxNo > 52) then //A8004	쇼골프(도봉점)
    Exit;

  rTeeboxInfo := Teebox.GetTeeboxInfo(ATeeboxNo);

  if (Global.ADConfig.StoreCode = 'BB001') then //돔골프 -> 히터가 여러타석이 묶여있는 경우, 추가 매장 발생시 옵션하 처리 필요
  begin
    //히터가 여러타석에 묶여있는경우 SetHeatuse 에서 config, DB 저장을 함.
    if AType = '1' then //auto
    begin
      if ComHeat_Dome <> nil then
        ComHeat_Dome.SetHeatuse(rTeeboxInfo.TeeboxNm, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));
    end
    else //수동:포스에서 제어
    begin
      if ComHeat_Dome <> nil then
        ComHeat_Dome.SetHeatuse(rTeeboxInfo.TeeboxNm, ATeeboxUse, '0', '');
    end;
  end
  else
  begin
    if AType = '1' then //auto
    begin
      if TcpThreadHeat <> nil then
      begin
        SetTeeboxHeatConfig(IntToStr(ATeeboxNo), ADConfig.HeatTime, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));
        TcpThreadHeat.SetHeatuse(ATeeboxNo, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
      end;

      if ComHeat_A8003 <> nil then
      begin
        SetTeeboxHeatConfig(rTeeboxInfo.TeeboxNm, ADConfig.HeatTime, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));
        ComHeat_A8003.SetHeatuse(rTeeboxInfo.TeeboxNm, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
      end;

      if ComHeat_D4001 <> nil then
      begin
        SetTeeboxHeatConfig(rTeeboxInfo.TeeboxNm, ADConfig.HeatTime, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));
        if (rTeeboxInfo.TeeboxZoneCode = 'L') or (rTeeboxInfo.TeeboxZoneCode = 'C') then
        begin
          if rTeeboxInfo.TeeboxNm = '33/34' then
          begin
            ComHeat_D4001.SetHeatuse('33', ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
            ComHeat_D4001.SetHeatuse('34', ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
          end
          else if rTeeboxInfo.TeeboxNm = '65/66' then
          begin
            ComHeat_D4001.SetHeatuse('65', ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
            ComHeat_D4001.SetHeatuse('66', ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
          end
          else if rTeeboxInfo.TeeboxNm = '101/102' then
          begin
            ComHeat_D4001.SetHeatuse('101', ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
            ComHeat_D4001.SetHeatuse('102', ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
          end;
        end
        else
          ComHeat_D4001.SetHeatuse(rTeeboxInfo.TeeboxNm, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
      end;
    end
    else //수동:포스에서 제어
    begin
      if TcpThreadHeat <> nil then
      begin
        SetTeeboxHeatConfig(IntToStr(ATeeboxNo), '', ATeeboxUse, '0', '');
        TcpThreadHeat.SetHeatuse(ATeeboxNo, ATeeboxUse, '0', '', True);
      end;

      if ComHeat_A8003 <> nil then
      begin
        SetTeeboxHeatConfig(rTeeboxInfo.TeeboxNm, '', ATeeboxUse, '0', '');
        ComHeat_A8003.SetHeatuse(rTeeboxInfo.TeeboxNm, ATeeboxUse, '0', '', True);
      end;

      if ComHeat_D4001 <> nil then
      begin
        SetTeeboxHeatConfig(rTeeboxInfo.TeeboxNm, '', ATeeboxUse, '0', '');
        if (rTeeboxInfo.TeeboxZoneCode = 'L') or (rTeeboxInfo.TeeboxZoneCode = 'C') then
        begin
          if rTeeboxInfo.TeeboxNm = '33/34' then
          begin
            ComHeat_D4001.SetHeatuse('33', ATeeboxUse, '0', '', True);
            ComHeat_D4001.SetHeatuse('34', ATeeboxUse, '0', '', True);
          end
          else if rTeeboxInfo.TeeboxNm = '65/66' then
          begin
            ComHeat_D4001.SetHeatuse('65', ATeeboxUse, '0', '', True);
            ComHeat_D4001.SetHeatuse('66', ATeeboxUse, '0', '', True);
          end
          else if rTeeboxInfo.TeeboxNm = '101/102' then
          begin
            ComHeat_D4001.SetHeatuse('101', ATeeboxUse, '0', '', True);
            ComHeat_D4001.SetHeatuse('102', ATeeboxUse, '0', '', True);
          end;
        end
        else
          ComHeat_D4001.SetHeatuse(rTeeboxInfo.TeeboxNm, ATeeboxUse, '0', '', True);
      end;
    end;

    sResult := XGolfDM.TeeboxHeatUseUpdate(ADConfig.StoreCode, IntToStr(ATeeboxNo), ATeeboxUse, AType, '');
    if sResult <> 'Success' then
    begin
      //Result := '{"result_cd":"","result_msg":"' + sResult + '"}';
      //Exit;
    end;
  end;

end;

procedure TGlobal.CtrlFanSendBuffer(ATeeboxNo: Integer; ATeeboxUse, AType: String);
var
  rTeeboxInfo: TTeeboxInfo;
  sHeatUse, sResult: String;
begin
  rTeeboxInfo := Teebox.GetTeeboxInfo(ATeeboxNo);

  if AType = '1' then //auto
  begin
    SetTeeboxFanConfig(rTeeboxInfo.TeeboxNm, ADConfig.HeatTime, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));
    ComFan_Dome.SetFanUse(rTeeboxInfo.TeeboxNm, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));
  end
  else
  begin
    SetTeeboxFanConfig(rTeeboxInfo.TeeboxNm, '', ATeeboxUse, '0', '');
    ComFan_Dome.SetFanUse(rTeeboxInfo.TeeboxNm, ATeeboxUse, '0', '');
  end;

  sResult := XGolfDM.TeeboxHeatUseUpdate(ADConfig.StoreCode, IntToStr(ATeeboxNo), ATeeboxUse, AType, '');
  if sResult <> 'Success' then
  begin
    //Result := '{"result_cd":"","result_msg":"' + sResult + '"}';
    //Exit;
  end;
end;

function TGlobal.GetStoreInfoToApi: Boolean;
var
  sResult, sStr: String;
  sServerTime: String;
  dSvrTime: TDateTime;

  jObj, jSubObj, jArrSubObj: TJSONObject;
  jObjArr: TJsonArray;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog, sStoreChgDate, sACS, sACS1, sACS2, sACS3, sACS1RecvHpNo: String;
  nCnt, nIndex, nACS1, nACS2, nACS3: Integer;

  sBallRecallStartTime, sBallRecallEndTime: String;
  STime, ETime: TDateTime;
  nNN, nHH: integer;
  sNN, sReserveStartTime: String;

  sWOLTm: String;
  WOLTimeTemp, WOLTimeTemp1: TDateTime;
begin
  Result := False;
  Log.LogWrite('Store Info Reset!!');

  try

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;
    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K203_StoreInfo', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
    Log.LogErpApiWrite(sResult);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'GetStoreInfoToApi Fail : ' + sResult;
      WriteLogDayFile(Log.LogFileName, sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K203_StoreInfo : ' + sResultCd + ' / ' + sResultMsg;
      WriteLogDayFile(Log.LogFileName, sLog);
      Exit;
    end;

    jSubObj := jObj.GetValue('result_data') as TJSONObject;

    FStore.StoreNm := jSubObj.GetValue('store_nm').Value;
    FStore.StartTime := jSubObj.GetValue('start_time').Value;
    FStore.EndTime := jSubObj.GetValue('end_time').Value;
    FStore.ShutdownTimeout := jSubObj.GetValue('shutdown_timeout').Value;

    FStore.WOLTime := '';
    if Global.ADConfig.AgentWOL = True then
    begin
      sWOLTm := formatdatetime('YYYY-MM-DD', Now) + ' ' + FStore.StartTime + ':59';
      WOLTimeTemp := DateStrToDateTime2(sWOLTm); //YYYY-MM-DD hh:nn:ss 형식
      WOLTimeTemp1 := IncMinute(WOLTimeTemp, -10);
      FStore.WOLTime := formatdatetime('hh:nn', WOLTimeTemp1);
    end;

    FStore.ReserveTimeYn := jSubObj.GetValue('reserve_time_yn').Value; //예약시작시간 사용여부
    sReserveStartTime := jSubObj.GetValue('reserve_start_time').Value;
    FStore.ReserveStartTime := StringReplace(sReserveStartTime, ':', '', [rfReplaceAll]); //예약시작시간

    FStore.UseRewardYn := jSubObj.GetValue('use_reward_yn').Value;
    FStore.StoreChgDate := jSubObj.GetValue('chg_date').Value;
    FStore.ACS := jSubObj.GetValue('acs_use_yn').Value;

    sServerTime := jSubObj.GetValue('server_time').Value;

    jObjArr := jSubObj.GetValue('acs_config_list') as TJsonArray;
    nCnt := jObjArr.Size;
    sACS1 := 'N';
    sACS2 := 'N';
    sACS3 := 'N';
    nACS1 := 0;
    nACS2 := 0;
    nACS3 := 0;

    if nCnt > 0 then
    begin

      for nIndex := 0 to nCnt - 1 do
      begin
        (*
        "acs_config_list":[{"failure_second":40,"send_div":"1","recv_hp_no":"01028726707"},
        {"failure_second":40,"send_div":"2","recv_hp_no":"01028726707"},
        {"failure_second":40,"send_div":"3","recv_hp_no":"01028726707"}]
        *)
        jArrSubObj := jObjArr.Get(nIndex) as TJSONObject;
        if jArrSubObj.GetValue('send_div').Value = '1' then //타석기고장
        begin
          sACS1 := 'Y';
          nACS1 := StrToIntDef(jArrSubObj.GetValue('failure_second').Value, 0);
          sACS1RecvHpNo := jArrSubObj.GetValue('recv_hp_no').Value;
        end
        else if jArrSubObj.GetValue('send_div').Value = '2' then //KIOSK 고장
        begin
          sACS2 := 'Y';
          nACS2 := StrToIntDef(jArrSubObj.GetValue('failure_second').Value, 0);
          if nACS2 < 120 then
          begin
            sStr := 'nACS2: ' + IntToStr(nACS2) + ' -> 120';
            WriteLogDayFile(Log.LogFileName, sStr);

            nACS2 := 120;
          end;
        end
        else if jArrSubObj.GetValue('send_div').Value = '3' then //KIOSK 용지 없음
        begin
          sACS3 := 'Y';
          nACS3 := StrToIntDef(jArrSubObj.GetValue('failure_second').Value, 0);
        end;
      end;
    end;

    FStore.StoreLastTM := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now); //2019-09-18 10:28:28

    FStore.ACS_1_Yn := sACS1;
    FStore.ACS_1_Hp := sACS1RecvHpNo;
    FStore.ACS_2_Yn := sACS2;
    FStore.ACS_3_Yn := sACS3;
    FStore.ACS_1 := nACS1;
    FStore.ACS_2 := nACS2;
    FStore.ACS_3 := nACS3;

    //2021-08-20 그린필드, 볼회수
    //2023-11-27 동도 -> 2개로 늘림
    FStore.BallRecallYn := jSubObj.GetValue('ball_recall_yn').Value = 'Y'; //볼회수 사용 여부
    sBallRecallStartTime := jSubObj.GetValue('ball_recall_start_time').Value; //볼회수 시작시간
    FStore.BallRecallStartTime := StringReplace(sBallRecallStartTime, ':', '', [rfReplaceAll]);
    sBallRecallEndTime := jSubObj.GetValue('ball_recall_end_time').Value; //볼회수 종료시간
    FStore.BallRecallEndTime := StringReplace(sBallRecallEndTime, ':', '', [rfReplaceAll]);

    STime := DateStrToDateTime(FormatDateTime('yyyymmdd', now) + FStore.BallRecallStartTime + '00');
    ETime := DateStrToDateTime(FormatDateTime('yyyymmdd', now) + FStore.BallRecallEndTime + '00');
    FStore.BallRecallTime := MinutesBetween(STime, ETime);

    FStore.BallRecall2Yn := jSubObj.GetValue('ball_recall2_yn').Value = 'Y'; //볼회수 사용 여부
    sBallRecallStartTime := jSubObj.GetValue('ball_recall2_start_time').Value; //볼회수 시작시간
    FStore.BallRecall2StartTime := StringReplace(sBallRecallStartTime, ':', '', [rfReplaceAll]);
    sBallRecallEndTime := jSubObj.GetValue('ball_recall2_end_time').Value; //볼회수 종료시간
    FStore.BallRecall2EndTime := StringReplace(sBallRecallEndTime, ':', '', [rfReplaceAll]);

    STime := DateStrToDateTime(FormatDateTime('yyyymmdd', now) + FStore.BallRecall2StartTime + '00');
    ETime := DateStrToDateTime(FormatDateTime('yyyymmdd', now) + FStore.BallRecall2EndTime + '00');
    FStore.BallRecall2Time := MinutesBetween(STime, ETime);

    FStore.DNSType := 'KT';
    FStore.DNSError := False;
    {
    if FStore.StartTime > FStore.EndTime then
    begin
      sNN := Copy(FStore.EndTime, 4, 2);
      nHH := StrToInt(Copy(FStore.EndTime, 1, 2)) + 24;
      FStore.EndTime := IntToStr(nHH) + ':' + sNN;
    end;
    }
    WriteConfigStoreInfo;

    if (Length(sServerTime) = 14) then
    begin
      dSvrTime := StrToDateTime(Format('%s-%s-%s %s:%s:%s',
              [
                Copy(sServerTime, 1, 4),
                Copy(sServerTime, 5, 2),
                Copy(sServerTime, 7, 2),
                Copy(sServerTime, 9, 2),
                Copy(sServerTime, 11, 2),
                Copy(sServerTime, 13, 2)
              ]));

      if SetSystemTimeChange(dSvrTime) = False then
      begin
        sStr := 'server_time LocalPc Set Error !!';
        WriteLogDayFile(Log.LogFileName, sStr);
      end;

    end
    else
    begin
      sStr := 'server_time length 14 error !!';
      WriteLogDayFile(Log.LogFileName, sStr);
    end;

    Result := True;
  finally
    FreeAndNil(jObj);
  end;

end;

function TGlobal.GetConfigInfoToApi: Boolean;
var
  sResult, sStr: String;
  sStoreNm, sStartTime, sEndTime, sUseRewardYn, sServerTime: String;
  dSvrTime: TDateTime;

  jObj, jSubObj, jArrSubObj: TJSONObject;
  jObjArr: TJsonArray;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog, sStoreChgDate, sACS, sACS1, sACS2, sACS3, sACS1RecvHpNo: String;
  nCnt, nIndex, nACS1, nACS2, nACS3: Integer;

  MI: TMemIniFile;
  SL, IL: TStringList;
  SS: TStringStream;
  I, J: Integer;
begin
  Result := False;
  Log.LogWrite('Config Info Reset!!');

  try

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode + '&client_id=' + Global.ADConfig.UserId;
    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K202_ConfiglistNew', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
    Log.LogErpApiWrite(sResult);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'GetConfigInfoToApi Fail : ' + sResult;
      //WriteLogDayFile(Global.LogFileName, sLog);
      Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K202_ConfiglistNew : ' + sResultCd + ' / ' + sResultMsg;
      //WriteLogDayFile(Global.LogFileName, sLog);
      Log.LogWrite(sLog);
      Exit;
    end;

    if jObj.FindValue('settings') is TJSONNull then
      Exit;

    SS := TStringStream.Create;
    SS.Clear;
    SS.WriteString(jObj.GetValue('settings').Value);
    MI := TMemIniFile.Create(SS, TEncoding.UTF8);
    SL := TStringList.Create;
    IL := TStringList.Create;

    MI.ReadSections(SL);
    for I := 0 to Pred(SL.Count) do
    begin
      IL.Clear;
      //MI.ReadSectionValues(SL[I], IL);
      MI.ReadSection(SL[I], IL);
      for J := 0 to Pred(IL.Count) do
        SetConfig(SL[I], IL[J], MI.ReadString(SL[I], IL[J], ''));
    end;

    Result := True;
  finally
    FreeAndNil(jObj);
    FreeAndNil(IL);
    FreeAndNil(SL);
    FreeAndNil(MI);
    SS.Free;
  end;

end;

function TGlobal.StopDown: Boolean;
begin
  Result := False;

  if TeeboxThread <> nil then
  begin
    TeeboxThread.Terminate;
    TeeboxThread.WaitFor;
    TeeboxThread.Free;
  end;

  if TcpThreadHeat <> nil then
  begin
    TcpThreadHeat.Terminate;
    TcpThreadHeat.WaitFor;
    TcpThreadHeat.Free;
  end;

  if ComJehu435 <> nil then
  begin
    ComJehu435.Terminate;
    ComJehu435.WaitFor;
    ComJehu435.Free;
  end;

  if ComJehu435_2 <> nil then
  begin
    ComJehu435_2.Terminate;
    ComJehu435_2.WaitFor;
    ComJehu435_2.Free;
  end;

  if ComJehu435_3 <> nil then
  begin
    ComJehu435_3.Terminate;
    ComJehu435_3.WaitFor;
    ComJehu435_3.Free;
  end;
  {
  if ComJehu50A <> nil then
  begin
    ComJehu50A.Terminate;
    ComJehu50A.WaitFor;
    ComJehu50A.Free;
  end;
  }
  if ComJehu60A_1 <> nil then
  begin
    ComJehu60A_1.Terminate;
    ComJehu60A_1.WaitFor;
    ComJehu60A_1.Free;
  end;

  if ComJehu60A_2 <> nil then
  begin
    ComJehu60A_2.Terminate;
    ComJehu60A_2.WaitFor;
    ComJehu60A_2.Free;
  end;

  if ComJehu60A_3 <> nil then
  begin
    ComJehu60A_3.Terminate;
    ComJehu60A_3.WaitFor;
    ComJehu60A_3.Free;
  end;

  if ComJehu60A_4 <> nil then
  begin
    ComJehu60A_4.Terminate;
    ComJehu60A_4.WaitFor;
    ComJehu60A_4.Free;
  end;

  {
  if ControlComPortHeatMonThread <> nil then
  begin
    ControlComPortHeatMonThread.Terminate;
    ControlComPortHeatMonThread.WaitFor;
    ControlComPortHeatMonThread.Free;
  end;
  }
  if ComSM_1 <> nil then
  begin
    ComSM_1.Terminate;
    ComSM_1.WaitFor;
    ComSM_1.Free;
  end;

  if ComSM_2 <> nil then
  begin
    ComSM_2.Terminate;
    ComSM_2.WaitFor;
    ComSM_2.Free;
  end;

  if ComSM_3 <> nil then
  begin
    ComSM_3.Terminate;
    ComSM_3.WaitFor;
    ComSM_3.Free;
  end;

  if ComSM_4 <> nil then
  begin
    ComSM_4.Terminate;
    ComSM_4.WaitFor;
    ComSM_4.Free;
  end;

  if ComSM_5 <> nil then
  begin
    ComSM_5.Terminate;
    ComSM_5.WaitFor;
    ComSM_5.Free;
  end;

  if ComSM_6 <> nil then
  begin
    ComSM_6.Terminate;
    ComSM_6.WaitFor;
    ComSM_6.Free;
  end;

  if ComModen_1 <> nil then
  begin
    ComModen_1.Terminate;
    ComModen_1.WaitFor;
    ComModen_1.Free;
  end;

  if ComModen_2 <> nil then
  begin
    ComModen_2.Terminate;
    ComModen_2.WaitFor;
    ComModen_2.Free;
  end;

  if ComModen_3 <> nil then
  begin
    ComModen_3.Terminate;
    ComModen_3.WaitFor;
    ComModen_3.Free;
  end;

  if ComModen_4 <> nil then
  begin
    ComModen_4.Terminate;
    ComModen_4.WaitFor;
    ComModen_4.Free;
  end;

  if ComModenYJ <> nil then
  begin
    ComModenYJ.Terminate;
    ComModenYJ.WaitFor;
    ComModenYJ.Free;
  end;

  if ComFieldLo <> nil then
  begin
    ComFieldLo.Terminate;
    ComFieldLo.WaitFor;
    ComFieldLo.Free;
  end;

  if ComMS <> nil then
  begin
    ComMS.Terminate;
    ComMS.WaitFor;
    ComMS.Free;
  end;

  if ComInfornet <> nil then
  begin
    ComInfornet.Terminate;
    ComInfornet.WaitFor;
    ComInfornet.Free;
  end;

  if ComInfornetPLC <> nil then
  begin
    ComInfornetPLC.Terminate;
    ComInfornetPLC.WaitFor;
    ComInfornetPLC.Free;
  end;

  if ComZoom <> nil then
  begin
    ComZoom.Terminate;
    ComZoom.WaitFor;
    ComZoom.Free;
  end;

  if ComZoom_2 <> nil then
  begin
    ComZoom_2.Terminate;
    ComZoom_2.WaitFor;
    ComZoom_2.Free;
  end;

  if ComZoom_3 <> nil then
  begin
    ComZoom_3.Terminate;
    ComZoom_3.WaitFor;
    ComZoom_3.Free;
  end;

  if ComZoomCC <> nil then
  begin
    ComZoomCC.Terminate;
    ComZoomCC.WaitFor;
    ComZoomCC.Free;
  end;

  if ComZoomCC_2 <> nil then
  begin
    ComZoomCC_2.Terminate;
    ComZoomCC_2.WaitFor;
    ComZoomCC_2.Free;
  end;

  if ComNano <> nil then
  begin
    ComNano.Terminate;
    ComNano.WaitFor;
    ComNano.Free;
  end;

  if ComNano2_1 <> nil then
  begin
    ComNano2_1.Terminate;
    ComNano2_1.WaitFor;
    ComNano2_1.Free;
  end;

  if ComNano2_2 <> nil then
  begin
    ComNano2_2.Terminate;
    ComNano2_2.WaitFor;
    ComNano2_2.Free;
  end;

  if ComNano2_3 <> nil then
  begin
    ComNano2_3.Terminate;
    ComNano2_3.WaitFor;
    ComNano2_3.Free;
  end;

  if ComNano2_4 <> nil then
  begin
    ComNano2_4.Terminate;
    ComNano2_4.WaitFor;
    ComNano2_4.Free;
  end;

  if ComWin_1 <> nil then
  begin
    ComWin_1.Terminate;
    ComWin_1.WaitFor;
    ComWin_1.Free;
  end;

  if ComWin_2 <> nil then
  begin
    ComWin_2.Terminate;
    ComWin_2.WaitFor;
    ComWin_2.Free;
  end;

  if ComWin_3 <> nil then
  begin
    ComWin_3.Terminate;
    ComWin_3.WaitFor;
    ComWin_3.Free;
  end;

  if ComFan_Dome <> nil then
  begin
    ComFan_Dome.Terminate;
    ComFan_Dome.WaitFor;
    ComFan_Dome.Free;
  end;

  if ComHeat_Dome <> nil then
  begin
    ComHeat_Dome.Terminate;
    ComHeat_Dome.WaitFor;
    ComHeat_Dome.Free;
  end;

  if ComHeat_A8003 <> nil then
  begin
    ComHeat_A8003.Terminate;
    ComHeat_A8003.WaitFor;
    ComHeat_A8003.Free;
  end;

  if ComHeat_D4001 <> nil then
  begin
    ComHeat_D4001.Terminate;
    ComHeat_D4001.WaitFor;
    ComHeat_D4001.Free;
  end;

  Result := True;
end;

destructor TGlobal.Destroy;
begin
  StopDown;

  XGolfDM.Free;
  FTcpServer.Free;

  if (Global.ADConfig.StoreCode = 'CD001') then //CD001	스타골프클럽(일산)
    FTcpAgentServer.Free;

  Api.Free;
  Teebox.Free;
  ReserveList.Free;

  //ini 파일
  FConfig.Free;
  FConfigBall.Free;
  FConfigError.Free;
  FConfigHeat.Free;
  FConfigFan.Free;

  Log.Free;

  inherited;
end;

procedure TGlobal.CheckConfig;
begin

  if not FConfig.SectionExists('Partners') then
  begin
    //FConfig.WriteString('ADInfo', 'BranchCode', '');
    FConfig.WriteString('Partners', 'StoreCode', '');
    //FConfig.WriteString('ADInfo', 'ADToken', '');
    FConfig.WriteString('Partners', 'UserId', '');
    FConfig.WriteString('Partners', 'UserPw', '');
    FConfig.WriteString('Partners', 'Url', '');

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('ADInfo') then
  begin
    FConfig.WriteInteger('ADInfo', 'Port', 1);
    FConfig.WriteInteger('ADInfo', 'Baudrate', 9600);
    FConfig.WriteInteger('ADInfo', 'TcpPort', 3308);
    FConfig.WriteInteger('ADInfo', 'DBPort', 3306);
    FConfig.WriteString('ADInfo', 'ProtocolType', 'ZOOM');
    FConfig.WriteInteger('ADInfo', 'HeatPort', 0);
    FConfig.WriteString('ADInfo', 'HeatAuto', '0');
    FConfig.WriteString('ADInfo', 'HeatTime', '0');
    FConfig.WriteString('ADInfo', 'SystemInstall', '0');

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('Store') then
  begin
    //2020-11-05 기기고장 1분유지시 문자발송여부
    FConfig.WriteString('Store', 'ErrorSms', 'N');
    FConfig.WriteString('Store', 'ACS', 'N');
    FConfig.WriteString('Store', 'ACS_1_YN', 'N');
    FConfig.WriteString('Store', 'ACS_1_HP', '');
    FConfig.WriteString('Store', 'ACS_2_YN', 'N');
    FConfig.WriteString('Store', 'ACS_3_YN', 'N');
    FConfig.WriteInteger('Store', 'ACS_1', 0);
    FConfig.WriteInteger('Store', 'ACS_2', 0);
    FConfig.WriteInteger('Store', 'ACS_3', 0);

    WriteFile(FConfigFileName, '');
  end;

end;

procedure TGlobal.ReadConfig;
var
  sStr: String;
begin
  FADConfig.StoreCode := FConfig.ReadString('Partners', 'StoreCode', '');
  FADConfig.ApiUrl := FConfig.ReadString('Partners', 'Url', '');
  FADConfig.UserId := FConfig.ReadString('Partners', 'UserId', '');

  sStr := FConfig.ReadString('Partners', 'UserPw', '');
  FADConfig.UserPw := StrDecrypt(Trim(sStr));

  {$IFDEF RELEASE}
  FADConfig.Port := FConfig.ReadInteger('ADInfo', 'Port', 1);
  FADConfig.Baudrate := FConfig.ReadInteger('ADInfo', 'Baudrate', 9600);
  {$ENDIF}
  {$IFDEF DEBUG}
  FADConfig.Port := 11;
  FADConfig.Baudrate := 9600;
  {$ENDIF}

  FADConfig.Port2 := FConfig.ReadInteger('ADInfo', 'Port2', 1);
  FADConfig.Baudrate2 := FConfig.ReadInteger('ADInfo', 'Baudrate2', 9600);
  FADConfig.Port3 := FConfig.ReadInteger('ADInfo', 'Port3', 1);
  FADConfig.Baudrate3 := FConfig.ReadInteger('ADInfo', 'Baudrate3', 9600);
  FADConfig.Port4 := FConfig.ReadInteger('ADInfo', 'Port4', 1);
  FADConfig.Baudrate4 := FConfig.ReadInteger('ADInfo', 'Baudrate4', 9600);
  FADConfig.Port5 := FConfig.ReadInteger('ADInfo', 'Port5', 1);
  FADConfig.Baudrate5 := FConfig.ReadInteger('ADInfo', 'Baudrate5', 9600);
  FADConfig.Port6 := FConfig.ReadInteger('ADInfo', 'Port6', 1);
  FADConfig.Baudrate6 := FConfig.ReadInteger('ADInfo', 'Baudrate6', 9600);

  FADConfig.PortCnt := FConfig.ReadInteger('ADInfo', 'PortCnt', 1);
  FADConfig.DeviceCnt := FConfig.ReadInteger('ADInfo', 'DeviceCnt', 1);

  FADConfig.PortFloorCd := FConfig.ReadString('ADInfo', 'PortFloorCd', '');
  FADConfig.PortStart := FConfig.ReadInteger('ADInfo', 'PortStart', 1);
  FADConfig.PortEnd := FConfig.ReadInteger('ADInfo', 'PortEnd', 1);
  FADConfig.Port2FloorCd := FConfig.ReadString('ADInfo', 'Port2FloorCd', '');
  FADConfig.Port2Start := FConfig.ReadInteger('ADInfo', 'Port2Start', 1);
  FADConfig.Port2End := FConfig.ReadInteger('ADInfo', 'Port2End', 1);
  FADConfig.Port3FloorCd := FConfig.ReadString('ADInfo', 'Port3FloorCd', '');
  FADConfig.Port3Start := FConfig.ReadInteger('ADInfo', 'Port3Start', 1);
  FADConfig.Port3End := FConfig.ReadInteger('ADInfo', 'Port3End', 1);
  FADConfig.Port4FloorCd := FConfig.ReadString('ADInfo', 'Port4FloorCd', '');
  FADConfig.Port4Start := FConfig.ReadInteger('ADInfo', 'Port4Start', 1);
  FADConfig.Port4End := FConfig.ReadInteger('ADInfo', 'Port4End', 1);
  FADConfig.Port5FloorCd := FConfig.ReadString('ADInfo', 'Port5FloorCd', '');
  FADConfig.Port5Start := FConfig.ReadInteger('ADInfo', 'Port5Start', 1);
  FADConfig.Port5End := FConfig.ReadInteger('ADInfo', 'Port5End', 1);
  FADConfig.Port6FloorCd := FConfig.ReadString('ADInfo', 'Port6FloorCd', '');
  FADConfig.Port6Start := FConfig.ReadInteger('ADInfo', 'Port6Start', 1);
  FADConfig.Port6End := FConfig.ReadInteger('ADInfo', 'Port6End', 1);

  FADConfig.TcpPort := FConfig.ReadInteger('ADInfo', 'TcpPort', 3308);

  FADConfig.DBPort := FConfig.ReadInteger('ADInfo', 'DBPort', 3306);

  FADConfig.AgentTcpPort := FConfig.ReadInteger('ADInfo', 'AgentTcpPort', 9900);
  FADConfig.AgentSendPort := FConfig.ReadInteger('ADInfo', 'AgentSendPort', 9901);
  FADConfig.AgentSendUse := FConfig.ReadString('ADInfo', 'AgentSendUse', 'N') = 'Y';
  FADConfig.AgentWOL := FConfig.ReadString('ADInfo', 'AgentWOL', 'N') = 'Y';

  if ADConfig.StoreCode = 'A8001' then
    FADConfig.ProtocolType := 'AD_JEU435'
  else
    FADConfig.ProtocolType := FConfig.ReadString('ADInfo', 'ProtocolType', 'ZOOM');

  FADConfig.DeviceType := FConfig.ReadInteger('ADInfo', 'DeviceType', 1); //0:Fan, 1:Heat 돔골프 전용

  FADConfig.HeatPort := FConfig.ReadInteger('ADInfo', 'HeatPort', 2);
  FADConfig.HeatTcpIP := FConfig.ReadString('ADInfo', 'HeatTcpIP', '127.0.0.1');
  FADConfig.HeatTcpPort := FConfig.ReadInteger('ADInfo', 'HeatTcpPort', 0);
  FADConfig.HeatAuto := FConfig.ReadString('ADInfo', 'HeatAuto', '0');
  FADConfig.HeatTime := FConfig.ReadString('ADInfo', 'HeatTime', '0');
  FADConfig.HeatOnTime := FConfig.ReadInteger('ADInfo', 'HeatOnTime', 0);
  FADConfig.HeatOffTime := FConfig.ReadInteger('ADInfo', 'HeatOffTime', 0);
  FADConfig.FanPort := FConfig.ReadInteger('ADInfo', 'FanPort', 2);

  FADConfig.SystemInstall := FConfig.ReadString('ADInfo', 'SystemInstall', '0');

  //긴급배정모드
  FADConfig.Emergency := FConfig.ReadString('ADInfo', 'Emergency', 'N') = 'Y';

  if FADConfig.Emergency = True then
  begin
    MainForm.pnlEmergency.Color := clRed;
    MainForm.pnlEmergency2.Color := clRed;
  end
  else
  begin
    MainForm.pnlEmergency.Color := clBtnFace;
    MainForm.pnlEmergency2.Color := clBtnFace;
  end;

  FADConfig.NetCheck := FConfig.ReadString('ADInfo', 'NetCheck', 'N') = 'Y'; //DNS 체크여부
  FADConfig.MultiCom := FConfig.ReadString('ADInfo', 'MultiCom', 'N') = 'Y'; //멀티포트 여부
  FADConfig.ReserveMode := FConfig.ReadString('ADInfo', 'ReserveMode', 'N') = 'Y'; //예약모드
  //FADConfig.TimeCheckMode := FConfig.ReadString('ADInfo', 'TimeCheckMode', '0'); //시간체크 기준 0:AD, 1:타석기
  FADConfig.ErrorTimeReward := FConfig.ReadString('ADInfo', 'ErrorTimeReward', 'Y') = 'Y'; //기기고장시 시간보상여부
  //FADConfig.StoreMode := FConfig.ReadString('ADInfo', 'StoreMode', '0'); //매장타입 0:실외, 1:실내
  FADConfig.CheckInUse := FConfig.ReadString('ADInfo', 'CheckInUse', 'N'); //체크인 사용여부
  FADConfig.XGM_VXUse := FConfig.ReadString('ADInfo', 'XGM_VXUse', 'N') = 'Y';
  FADConfig.BeamProjectorUse := FConfig.ReadString('ADInfo', 'BeamProjectorUse', 'N') = 'Y';

  //2020-11-05 기기고장 1분유지시 문자발송여부
  FStore.ErrorSms := FConfig.ReadString('Store', 'ErrorSms', 'N');

  FStore.StartTime := FConfig.ReadString('Store', 'StartTime', '05:00');
  FStore.EndTime := FConfig.ReadString('Store', 'EndTime', '23:00');
  FStore.ReserveTimeYn := FConfig.ReadString('Store', 'ReserveTimeYn', 'N');
  FStore.ReserveStartTime := FConfig.ReadString('Store', 'ReserveStartTime', '');
  FStore.UseRewardYn := FConfig.ReadString('Store', 'UseRewardYn', 'Y');
  FStore.ACS := FConfig.ReadString('Store', 'ACS', 'N');
  FStore.ACS_1_Yn := FConfig.ReadString('Store', 'ACS_1_YN', 'N');
  FStore.ACS_1_Hp := FConfig.ReadString('Store', 'ACS_1_HP', '');
  FStore.ACS_2_Yn := FConfig.ReadString('Store', 'ACS_2_YN', 'N');
  FStore.ACS_3_Yn := FConfig.ReadString('Store', 'ACS_3_YN', 'N');
  FStore.ACS_1 := FConfig.ReadInteger('Store', 'ACS_1', 0);
  FStore.ACS_2 := FConfig.ReadInteger('Store', 'ACS_2', 0);
  FStore.ACS_3 := FConfig.ReadInteger('Store', 'ACS_3', 0);

  FStore.Close := 'Y';
end;

procedure TGlobal.WriteConfigBall(ATeeboxNo: Integer);
var
  I: Integer;
  rTeeboxInfo: TTeeboxInfo;
  sLog: String;
begin
  if ATeeboxNo = 0 then
  begin
    FConfigBall.WriteString('BallBack', 'Start', FormatDateTime('YYYY-MM-DD hh:nn:ss', now));
    FConfigBall.WriteInteger('BallBack', 'Delay', 0);

    for I := 1 to Teebox.TeeboxLastNo do
    begin
      rTeeboxInfo := Teebox.GetTeeboxInfo(I);

      FConfigBall.WriteString('Teebox_' + IntToStr(I), 'TeeboxNm', rTeeboxInfo.TeeboxNm);
      FConfigBall.WriteString('Teebox_' + IntToStr(I), 'ReserveNo', rTeeboxInfo.TeeboxReserve.ReserveNo);
      FConfigBall.WriteInteger('Teebox_' + IntToStr(I), 'AssignMin', rTeeboxInfo.TeeboxReserve.AssignMin);
      FConfigBall.WriteInteger('Teebox_' + IntToStr(I), 'RemainMinute', rTeeboxInfo.RemainMinute);
      FConfigBall.WriteInteger('Teebox_' + IntToStr(I), 'RemainBall', rTeeboxInfo.RemainBall);
      FConfigBall.WriteString('Teebox_' + IntToStr(I), 'UseStatus', rTeeboxInfo.UseStatus);
    end;
    sLog := '볼회수 WriteConfigBall';
    Log.LogWrite(sLog);
  end
  else
  begin
    rTeeboxInfo := Teebox.GetTeeboxInfo(ATeeboxNo);

    FConfigBall.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'ReserveNo', rTeeboxInfo.TeeboxReserve.ReserveNo);
    FConfigBall.WriteInteger('Teebox_' + IntToStr(ATeeboxNo), 'RemainMinute', rTeeboxInfo.RemainMinute);
    FConfigBall.WriteInteger('Teebox_' + IntToStr(ATeeboxNo), 'RemainBall', rTeeboxInfo.RemainBall);
    FConfigBall.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'UseStatus', rTeeboxInfo.UseStatus);

    sLog := '점검 WriteConfigBall : ' + IntToStr(ATeeboxNo) + ' / ' + rTeeboxInfo.TeeboxNm + ' / ' +
            IntToStr(rTeeboxInfo.RemainMinute) + ' / ' + IntToStr(rTeeboxInfo.RemainBall) + ' / ' + rTeeboxInfo.UseStatus;
    Log.LogWrite(sLog);
  end;
end;

procedure TGlobal.WriteConfigBallBackDelay(ADelay: Integer);
var
  sLog: String;
begin
  FConfigBall.WriteInteger('BallBack', 'Delay', ADelay);
  sLog := 'WriteConfigBallBackDelay : ' + IntToStr(ADelay);
  Log.LogWrite(sLog);
end;

//볼회수 시작시간
function TGlobal.ReadConfigBallBackStartTime: String;
begin
  Result := FConfigBall.ReadString('BallBack', 'Start', '');
end;

function TGlobal.ReadConfigBallRemainMin(ATeeboxNo: Integer): Integer;
begin
  //볼회수시 남은시간 초기화일 경우 회수종료후 남은시간 체크용
  Result := FConfigBall.ReadInteger('Teebox_' + IntToStr(ATeeboxNo), 'RemainMinute', 0);
end;

function TGlobal.ReadConfigBallPrepareStartTime(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sReserveNo, sStartTime: String;
begin
  Result := '';
  sReserveNo := FConfigBall.ReadString('Teebox_' + IntToStr(ATeeboxNo), 'ReserveNo', '');
  sStartTime := FConfigBall.ReadString('Teebox_' + IntToStr(ATeeboxNo), 'PrepareStartDate', '');

  if AReserveNo = sReserveNo then
    Result := sStartTime;
end;

procedure TGlobal.WriteConfigError(ATeeboxNo, ARemainMin: Integer; ATeeboxNm, AReserveNo: String);
var
  sLog: String;
begin
  FConfigError.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'TeeboxNm', ATeeboxNm);
  FConfigError.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'ReserveNo', AReserveNo);
  FConfigError.WriteInteger('Teebox_' + IntToStr(ATeeboxNo), 'RemainMinute', ARemainMin);
  FConfigError.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'Start', FormatDateTime('YYYY-MM-DD hh:nn:ss', now));
  FConfigError.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'End', '');
  FConfigError.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'Reward', 'N');

  sLog := 'WriteConfigError - No: ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + AReserveNo + ' / ' + IntToStr(ARemainMin);
  Log.LogWrite(sLog);
end;

procedure TGlobal.WriteConfigErrorReward(ATeeboxNo: Integer);
var
  sLog: String;
begin
  FConfigError.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'Reward', 'Y');
  FConfigError.WriteString('Teebox_' + IntToStr(ATeeboxNo), 'End', FormatDateTime('YYYY-MM-DD hh:nn:ss', now));

  sLog := 'WriteConfigErrorReward - No: ' + IntToStr(ATeeboxNo);
  Log.LogWrite(sLog);
end;

procedure TGlobal.ReadConfigError(ATeeboxNo: Integer; var AReserveNo, AStart, AReward: String);
var
  sLog: String;
begin
  AReserveNo := FConfigError.ReadString('Teebox_' + IntToStr(ATeeboxNo), 'ReserveNo', '');
  AReward := FConfigError.ReadString('Teebox_' + IntToStr(ATeeboxNo), 'Reward', 'N');
  AStart := FConfigError.ReadString('Teebox_' + IntToStr(ATeeboxNo), 'Start', '');

  sLog := 'ReadConfigError : ' + IntToStr(ATeeboxNo) + ' / ' + AReserveNo + ' / ' + AStart + ' / ' + AReward;
  Log.LogWrite(sLog);
end;

procedure TGlobal.SetADConfigToken(AToken: AnsiString);
begin
  FADConfig.ADToken := AToken;
  //FConfig.WriteString('ADInfo', 'ADToken', AToken);
end;

procedure TGlobal.WriteConfigStoreInfo;
begin
  FConfig.WriteString('Store', 'StoreNm', FStore.StoreNm);
  FConfig.WriteString('Store', 'StartTime', FStore.StartTime);
  FConfig.WriteString('Store', 'EndTime', FStore.EndTime);
  FConfig.WriteString('Store', 'ReserveTimeYn', FStore.ReserveTimeYn);
  FConfig.WriteString('Store', 'ReserveStartTime', FStore.ReserveStartTime);
  FConfig.WriteString('Store', 'UseRewardYn', FStore.UseRewardYn);
  FConfig.WriteString('Store', 'ACS', FStore.ACS);
  FConfig.WriteString('Store', 'ACS_1_YN', FStore.ACS_1_Yn);
  FConfig.WriteString('Store', 'ACS_1_HP', FStore.ACS_1_Hp);
  FConfig.WriteString('Store', 'ACS_2_YN', FStore.ACS_2_Yn);
  FConfig.WriteString('Store', 'ACS_3_YN', FStore.ACS_3_Yn);
  FConfig.WriteString('Store', 'ACS_1', IntToStr(FStore.ACS_1));
  FConfig.WriteString('Store', 'ACS_2', IntToStr(FStore.ACS_2));
  FConfig.WriteString('Store', 'ACS_3', IntToStr(FStore.ACS_3));

  FConfig.WriteString('Store', 'BallRecallYn', IfThen(FStore.BallRecallYn, 'Y', 'N'));
  FConfig.WriteString('Store', 'BallRecallStartTime', FStore.BallRecallStartTime);
  FConfig.WriteString('Store', 'BallRecallEndTime', FStore.BallRecallEndTime);

  FConfig.WriteString('Store', 'BallRecall2Yn', IfThen(FStore.BallRecall2Yn, 'Y', 'N'));
  FConfig.WriteString('Store', 'BallRecall2StartTime', FStore.BallRecall2StartTime);
  FConfig.WriteString('Store', 'BallRecall2EndTime', FStore.BallRecall2EndTime);
end;

procedure TGlobal.SetKioskInfo(ADeviceNo, AUserId: String);
var
  nNN, nKioskNo: integer;
begin
  if ADeviceNo = '' then
    nKioskNo := 0
  else
    nKioskNo := StrToInt(ADeviceNo);

  FKioskList[nKioskNo].KioskNo := nKioskNo;
  FKioskList[nKioskNo].UserId := AUserId;
  FKioskList[nKioskNo].Status := True;
  FKioskList[nKioskNo].StatusTime := now;

end;

procedure TGlobal.SetKioskPrint(ADeviceNo, AUserId, AError: String);
var
  nNN, nKioskNo: integer;
begin
  if ADeviceNo = '' then
    nKioskNo := 0
  else
    nKioskNo := StrToInt(ADeviceNo);

  FKioskList[nKioskNo].KioskNo := nKioskNo;
  FKioskList[nKioskNo].UserId := AUserId;
  if AError = 'Y' then
    FKioskList[nKioskNo].PrintError := True
  else
    FKioskList[nKioskNo].PrintError := False;
  FKioskList[nKioskNo].PrintErrorTime := now;

end;

function TGlobal.SetADConfigEmergency(AMode, AUserId: String): Boolean;
begin
  Result := False;

  if AMode = 'Y' then
  begin
    FADConfig.Emergency := True;
    MainForm.pnlEmergency.Color := clRed;
    MainForm.pnlEmergency2.Color := clRed;
  end
  else
  begin
    if GetErpOauth2 = False then
      Exit;

    FADConfig.Emergency := False;
    MainForm.pnlEmergency.Color := clBtnFace;
    MainForm.pnlEmergency2.Color := clBtnFace;
  end;

  FConfig.WriteString('ADInfo', 'Emergency', AMode);

  Result := True;
end;

function TGlobal.SetTeeboxHeatSetConfig(ATime, AUse: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  FADConfig.HeatAuto := AUse;
  FADConfig.HeatTime := ATime;
  FConfig.WriteString('ADInfo', 'HeatAuto', AUse);
  FConfig.WriteString('ADInfo', 'HeatTime', ATime);

  sStr := '히터설정 : ' + AUse + ' / ' + ATime;
  Log.LogHeatWrite(sStr);

  Result := True;
end;

function TGlobal.SetTeeboxHeatConfig(ATeebox, ATime, AUse, AAuto, AStartTm: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  //tcp - No, 그외-Nm
  FConfigHeat.WriteString('Teebox_' + ATeebox, 'HeatUse', AUse);
  FConfigHeat.WriteString('Teebox_' + ATeebox, 'HeatAuto', AAuto);

  if AAuto = '1' then
  begin
    FConfigHeat.WriteString('Teebox_' + ATeebox, 'HeatStart', AStartTm);
  end;

  Result := True;
end;

function TGlobal.SetTeeboxFanConfig(ATeeboxNm, ATime, AUse, AAuto, AStartTm: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  FConfigFan.WriteString('TeeboxNm_' + ATeeboxNm, 'FanUse', AUse);
  FConfigFan.WriteString('TeeboxNm_' + ATeeboxNm, 'FanAuto', AAuto);

  if AAuto = '1' then
  begin
    FConfigFan.WriteString('TeeboxNm_' + ATeeboxNm, 'FanStart', AStartTm);
  end;

  Result := True;
end;

function TGlobal.SetHeatStatus: Boolean;
var
  nIndex: Integer;
  sHeatUse, sHeatAuto, sHeatStart, sHeatFloorNm, sNm: String;
begin
  //tcp - No, 그외-Nm
  if TcpThreadHeat <> nil then
  begin

    for nIndex := 1 to Teebox.TeeboxLastNo do
    begin
      sHeatUse := FConfigHeat.ReadString('Teebox_' + IntToStr(nIndex), 'HeatUse', '0');
      sHeatAuto := FConfigHeat.ReadString('Teebox_' + IntToStr(nIndex), 'HeatAuto', '0');
      sHeatStart := FConfigHeat.ReadString('Teebox_' + IntToStr(nIndex), 'HeatStart', '');

      TcpThreadHeat.SetHeatuse(nIndex, sHeatUse, sHeatAuto, sHeatStart, False);
    end;
  end
  else
  begin

    for nIndex := 1 to Teebox.TeeboxLastNo do
    begin
      if (Global.ADConfig.StoreCode = 'BB001') then //돔골프
      begin
        if nIndex = 20 then
          sNm := '20/21'
        else if nIndex = 41 then
          sNm := '41/42'
        else if nIndex = 62 then
          sNm := '62/63'
        else
          sNm := IntToStr(nIndex);
      end
      else
        sNm := IntToStr(nIndex);

      sHeatUse := FConfigHeat.ReadString('Teebox_' + sNm, 'HeatUse', '0');
      sHeatAuto := FConfigHeat.ReadString('Teebox_' + sNm, 'HeatAuto', '0');
      sHeatStart := FConfigHeat.ReadString('Teebox_' + sNm, 'HeatStart', '');
      {
      if ControlComPortHeatMonThread <> nil then
        ControlComPortHeatMonThread.SetHeatuse(sNm, sHeatUse, sHeatAuto, sHeatStart);
      }

      if ComHeat_Dome <> nil then
        ComHeat_Dome.SetHeatUseInit(sNm, sHeatUse, sHeatAuto, sHeatStart);

      if ComHeat_A8003 <> nil then
        ComHeat_A8003.SetHeatuse(sNm, sHeatUse, sHeatAuto, sHeatStart, False);

      if ComHeat_D4001 <> nil then
      begin
        if sNm = '33/34' then
        begin
          ComHeat_D4001.SetHeatuse('33', sHeatUse, sHeatAuto, sHeatStart, False);
          ComHeat_D4001.SetHeatuse('34', sHeatUse, sHeatAuto, sHeatStart, False);
        end
        else if sNm = '65/66' then
        begin
          ComHeat_D4001.SetHeatuse('65', sHeatUse, sHeatAuto, sHeatStart, False);
          ComHeat_D4001.SetHeatuse('66', sHeatUse, sHeatAuto, sHeatStart, False);
        end
        else if sNm = '101/102' then
        begin
          ComHeat_D4001.SetHeatuse('101', sHeatUse, sHeatAuto, sHeatStart, False);
          ComHeat_D4001.SetHeatuse('102', sHeatUse, sHeatAuto, sHeatStart, False);
        end
        else
          ComHeat_D4001.SetHeatuse(sNm, sHeatUse, sHeatAuto, sHeatStart, False);
      end;
    end;
  end;
end;

function TGlobal.SetFanStatus: Boolean;
var
  nIndex: Integer;
  sFanUse, sFanAuto, sFanStart, sNm: String;
begin

  for nIndex := 1 to Teebox.TeeboxLastNo do
  begin // 20/21   41/42   62/63
    if nIndex = 20 then
      sNm := '20/21'
    else if nIndex = 41 then
      sNm := '41/42'
    else if nIndex = 62 then
      sNm := '62/63'
    else
      sNm := IntToStr(nIndex);

    sFanUse := FConfigFan.ReadString('TeeboxNm_' + sNm, 'FanUse', '0');
    sFanAuto := FConfigFan.ReadString('TeeboxNm_' + sNm, 'FanAuto', '0');
    sFanStart := FConfigFan.ReadString('TeeboxNm_' + sNm, 'FanStart', '');

    if ComFan_Dome <> nil then
      ComFan_Dome.SetFanUse(sNm, sFanUse, sFanAuto, sFanStart);
  end;
end;

function TGlobal.SetDeviceTypeConfig(AType: Integer): Boolean;
var
  sStr: String;
begin
  Result := False;

  sStr := '장치설정변경 : ' + IntToStr(FADConfig.DeviceType) + ' -> ' + IntToStr(AType);
  Log.LogWrite(sStr);

  FADConfig.DeviceType := AType;
  FConfig.WriteInteger('ADInfo', 'DeviceType', AType);

  Result := True;
end;

function TGlobal.SetHeatOnOffTimeConfig(AOnTime, AOffTime: Integer): Boolean;
var
  sStr: String;
begin
  Result := False;

  sStr := '히터 ON/OFF 설정 : ' + IntToStr(FADConfig.HeatOnTime) + ' -> '+ IntToStr(AOnTime) + ' / ' + IntToStr(FADConfig.HeatOffTime) + ' -> '+ IntToStr(AOffTime);
  Log.LogWrite(sStr);

  FADConfig.HeatOnTime := AOnTime;
  FADConfig.HeatOffTime := AOffTime;
  FConfig.WriteInteger('ADInfo', 'HeatOnTime', AOnTime);
  FConfig.WriteInteger('ADInfo', 'HeatOffTime', AOffTime);

  Result := True;
end;

procedure TGlobal.DNSPingCheck;
var
  Icmp: TIdIcmpClient;
  Msg: string;
begin

  Icmp := TIdIcmpClient.Create(nil);
  try
    try
      Icmp.IPVersion := Id_IPv4;
      Icmp.PacketSize := 32;
      Icmp.Protocol := 1;
      Icmp.ReceiveTimeout := 1000;
      Icmp.OnReply:= OnICmpClientReply;

      if Store.DNSType = 'KT' then
      begin
        Icmp.Host := '168.126.63.1'; //KT
        FStore.DNSType := 'LG';
      end
      else
      begin
        Icmp.Host := '203.248.252.2'; //LG
        FStore.DNSType := 'KT';
      end;

      try
        Icmp.Ping;
      except
      end;

    finally
      FreeAndNil(Icmp);
    end;
  except
    on E: Exception do
      Log.LogWrite(Format('DNSPingCheck.Exception : %s', [E.Message]));
  end;
end;

procedure TGlobal.OnICmpClientReply(ASender: TComponent; const AReplyStatus: TReplyStatus);
begin
  with AReplyStatus do
  begin
    case ReplyStatusType of
      rsEcho:
      begin
        //Log.LogWrite(Format('Ping %s Response : Bytes=%d Time=%dms TTL=%d', [FromIpAddress, BytesReceived, MsRoundTripTime, TimeToLive]));
        FStore.DNSCheckTime := Now;
        FStore.DNSError := False;
      end;
      rsTimeOut:
      begin
        Log.LogWrite(Format('Ping %s Request Timeout.', [TIdIcmpClient(ASender).Host]));
      end;
    end;
  end;
end;

procedure TGlobal.DNSPingError;
var
  sLog: string;
begin

  if SecondsBetween(Store.DNSCheckTime, now) >= 20 then
  begin
    FStore.DNSError := True;
    sLog := 'DNSPingError';
    log.LogWrite(sLog);
  end;

end;

procedure TGlobal.TeeboxThreadTimeCheck;
var
  sPtime, sNtime, sLogMsg: String;
  sResult: String;
  sToken: AnsiString;
  sPWOLtime, sNWOLtime: String;
begin
  sPtime := FormatDateTime('YYYYMMDDHH', TeeboxThreadTime);
  sNtime := FormatDateTime('YYYYMMDDHH', Now);

  if (Global.ADConfig.StoreCode = 'CD001') then //CD001	스타골프클럽(일산)
  begin
    if ADConfig.AgentWOL = True then
    begin

      sPWOLtime := FormatDateTime('HH:NN', TeeboxThreadTime);
      sNWOLtime := FormatDateTime('HH:NN', Now);

      if sPWOLtime <> sNWOLtime then
      begin
        if sNWOLtime = Store.WOLTime then
        begin
          {
          if Store.WOLUnusedDt = FormatDateTime('YYYY-MM-DD', Now) then
          begin
            Log.LogCtrlWrite('휴장설정 - WOL 미사용');
            MainForm.btnCheckWOL.Click;
          end
          else }
          begin
            Teebox.SendAgentWOL(0);
            sleep(1000);
            Teebox.SendAgentWOL(0);
            sleep(1000);
            Teebox.SendAgentWOL(0);
          end;
        end;
      end;

    end;
  end;

  if sPtime <> sNtime then
  begin
    sLogMsg := 'TSeatThread TimeCheck !!';
    Log.LogWrite(sLogMsg);

    if Copy(sNtime, 9, 2) = '00' then //2023-05-25 seqno 초기화
    begin
      TcpServer.UseSeqNo := 0;
      TcpServer.LastUseSeqNo := TcpServer.UseSeqNo;
      TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now);
    end;

    if Copy(sNtime, 9, 2) = '04' then  //02 2021-06-01 유명 3시까지 연장영업
    begin
      DeleteDBReserve;

      //2021-11-02 인증확인용
      sResult := Api.GetOauth2(sToken, FADConfig.ApiUrl, FADConfig.UserId, FADConfig.UserPw);
      if sResult = 'Success' then
      begin
        if FADConfig.ADToken <> sToken then
        begin
          SetADConfigToken(sToken);
          Log.LogWrite('Token '  + sResult);
        end;
      end
      else
      begin
        Log.LogWrite('Token Fail');
      end;

      GetStoreInfoToApi;

      //2020-10-09 재부팅 제외로 seqno 초기화
      TcpServer.UseSeqNo := 0;
      TcpServer.LastUseSeqNo := TcpServer.UseSeqNo;
      TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now);

      //2020-11-04 DB재연결
      Global.XGolfDM.ReConnection;

      FReserveDBWrite := False;
    end;

    //2020-12-04 양평08시 이후 첫배정되는 경우 있음.
    if Copy(sNtime, 9, 2) = '05' then
    begin
      sResult := Api.GetOauth2(sToken, FADConfig.ApiUrl, FADConfig.UserId, FADConfig.UserPw);
      if sResult = 'Success' then
      begin
        if FADConfig.ADToken <> sToken then
        begin
          SetADConfigToken(sToken);
          Log.LogWrite('Token '  + sResult);
        end;
      end
      else
      begin
        Log.LogWrite('Token Fail');
      end;

      GetStoreInfoToApi;

      Global.XGolfDM.ReConnection;

      if FADConfig.XGM_VXUse = True then //2023-01-25 프라자 추가
        ReSetXGM;

      FReserveDBWrite := False;
    end;

    //공사등으로 인한 오후 오픈인 경우 발생-양평01.31
    if Copy(sNtime, 9, 2) = '12' then
    begin
      if FReserveDBWrite = False then
      begin
        Global.XGolfDM.ReConnection;
      end;
    end;

  end;

  TeeboxThreadTime := Now;
end;

procedure TGlobal.HeatThreadTimeCheck;
begin
  HeatThreadTime := Now;
end;

procedure TGlobal.PLCThreadTimeCheck;
begin
  PLCThreadTime := Now;
end;

procedure TGlobal.TeeboxControlTimeCheck;
var
  sPtime, sNtime, sLogMsg: String;
begin
  sPtime := FormatDateTime('YYYYMMDDHH', TeeboxControlTime);
  sNtime := FormatDateTime('YYYYMMDDHH', Now);

  if sPtime <> sNtime then
  begin
    sLogMsg := 'TSeatControl TimeCheck !!';
    Log.LogWrite(sLogMsg);
  end;

  TeeboxControlTime := Now;
end;

procedure TGlobal.SetStoreInfoClose(AClose: String);
begin
  FStore.Close := AClose;
end;

procedure TGlobal.SetStoreUseRewardException(AType: String);
begin
  FStore.UseRewardException := AType;
end;

procedure TGlobal.DebugLogMainViewMulti(AIndex: Integer; ALog: string);
begin
  if AIndex = 1 then
    FCtrlBufferTemp1 := ALog;

  if AIndex = 2 then
    FCtrlBufferTemp2 := ALog;

  if AIndex = 3 then
    FCtrlBufferTemp3 := ALog;

  if AIndex = 4 then
    FCtrlBufferTemp4 := ALog;

  if AIndex = 5 then
    FCtrlBufferTemp5 := ALog;

  if AIndex = 6 then
    FCtrlBufferTemp6 := ALog;
end;

procedure TGlobal.DebugLogFromViewMulti(AIndex: Integer; ALog: string);
begin
  if frmDebug = nil then
    Exit;

  if IntToStr(AIndex) <> DebugIndex then
    Exit;

  if DebugStart <> 'Y' then
    Exit;


  TThread.Queue(nil,
    procedure
    begin
      frmDebug.AddLog(ALog);
    end);

end;
 
procedure TGlobal.DebugLogViewApiWrite(ALog: string);
begin
  MainForm.edApiResult.Text := ALog;

  if ALog = 'Fail' then
    MainForm.cxTabSheet1.color := clRed
  else
    MainForm.cxTabSheet1.color := clWindow;
end;

procedure TGlobal.SetConfig(const ASection, AItem: string; const ANewValue: Variant);
begin
  case VarType(ANewValue) of
    varInteger:
      FConfig.WriteInteger(ASection, AItem, ANewValue);
    varBoolean:
      FConfig.WriteBool(ASection, AItem, ANewValue);
  else
    FConfig.WriteString(ASection, AItem, ANewValue);
  end;
end;

procedure TGlobal.DeleteDBReserve;
var
  sDateStr: string;
  bResult: Boolean;
begin
  sDateStr := FormatDateTime('YYYYMMDD', Now - 3);
  bResult := XGolfDM.SeatUseDeleteReserve(ADConfig.StoreCode, sDateStr);

  if bResult = True then
    Log.LogWrite('배정데이터 삭제 완료: ' + sDateStr)
  else
    Log.LogWrite('배정데이터 삭제 실패: ' + sDateStr)

end;

procedure TGlobal.KioskTimeCheck;
var
  sLog: String;
  I: Integer;
  bSend: Boolean;
begin
  if Global.Store.ACS_2_Yn = 'Y' then //키오스크 상태
  begin

    //Kiosk.UserId := sUserId;
    bSend := False;
    for I := 0 to 10 do
    begin

      if FKioskList[I].Status = True then
      begin
         //Kiosk.StatusTime := now;
        if SecondsBetween(FKioskList[I].StatusTime, now) >= Global.Store.ACS_2 then //120
        begin
          sLog := 'KioskStatus : ' + FormatDateTime('YYYY-MM-DD HH:NN:SS', FKioskList[I].StatusTime) + ' / ' + FormatDateTime('YYYY-MM-DD HH:NN:SS', now);
          //WriteLogDayFile(Global.LogFileName, sLog);
          log.LogWrite(sLog);
          FKioskList[I].Status := False;

          bSend := True;
        end;
      end;
    end;

    if bSend = True then
      SendACSToErp('2', '0');
  end;

  if Global.Store.ACS_3_Yn = 'Y' then //키오스크 프린터 용지없음
  begin

    //Kiosk.UserId := sUserId;
    bSend := False;
    for I := 0 to 10 do
    begin

      if FKioskList[I].PrintError = True then
      begin
        if SecondsBetween(FKioskList[I].PrintErrorTime, now) >= Global.Store.ACS_3 then
        begin
          sLog := 'PrintError : ' + FormatDateTime('YYYY-MM-DD HH:NN:SS', FKioskList[I].PrintErrorTime) + ' / ' + FormatDateTime('YYYY-MM-DD HH:NN:SS', now);
          //WriteLogDayFile(Global.LogFileName, sLog);
          log.LogWrite(sLog);
          FKioskList[I].PrintError := False;

          bSend := True;
        end;
      end;
    end;

    if bSend = True then
      SendACSToErp('3', '0');
  end;

end;

procedure TGlobal.SendSMSToErp(ASendDiv, ATeeboxNm: String);
var
  sJsonStr: AnsiString;
  sResult: String;
begin
  if Global.ADConfig.Emergency = True then
  begin
    Log.LogErpApiWrite('긴급배정모드: K801_SendSms');
    Exit;
  end;

  sJsonStr := '?store_cd=' + ADConfig.StoreCode +
              '&send_div=' + ASendDiv;
  if ASendDiv = '9' then
  begin
  sJsonStr := sJsonStr +
              '&receiver_hp_no=' + Store.ACS_1_Hp;
  end
  else
  begin
  sJsonStr := sJsonStr +
              '&receiver_hp_no=00011110000';
  end;
  sJsonStr := sJsonStr +
              '&send_text=' + ATeeboxNm + '번 타석기가 고장났습니다';
              //'&send_text=No5번 타석기가 고장났습니다';

  sResult := Api.SetErpApiNoneDataEncoding(sJsonStr, 'K801_SendSms', ADConfig.ApiUrl, ADConfig.ADToken);
  Log.LogErpApiWrite(sResult);
end;

// 구동확인용-> ERP 전송
procedure TGlobal.SendACSToErp(ASendDiv, ATeeboxNm: String);
var
  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;

  jObj, jObjSub: TJSONObject;
  sChgDate: String;
begin
  if Global.ADConfig.Emergency = True then
  begin
    Log.LogErpApiWrite('긴급배정모드: K802_SendAcs');
    Exit;
  end;

  try

    while True do //TeeboxThread 에서 보냄
    begin
      if Teebox.TeeboxReserveUse = False then //Server 통신중인지
        Break;

      sLog := 'SeatReserveUse SendKioskStatusToErp!';
      Log.LogErpApiDelayWrite(sLog);

      sleep(50);
    end;

    Teebox.TeeboxReserveUse := True;

    if ASendDiv = '1' then
    begin
      if SecondsBetween(FSendACSTeeboxError, now) < 60 then
      begin
        SendSMSToErp('9', ATeeboxNm);
        Exit;
      end;
    end;

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                '&send_div=' + ASendDiv +
                '&teebox_nm=' + ATeeboxNm;

    sResult := Api.SetErpApiNoneData(sJsonStr, 'K802_SendAcs', ADConfig.ApiUrl, ADConfig.ADToken);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'K802_SendAcs Fail : ' + sResult;
      log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    sLog := 'K802_SendAcs : ' + sResultCd + ' / ' + sResultMsg;
    log.LogWrite(sLog);

    if ASendDiv = '1' then
      FSendACSTeeboxError := now;

    Sleep(50);
    Teebox.TeeboxReserveUse := False;
  finally
    Teebox.TeeboxReserveUse := False;
    FreeAndNil(jObj);
  end;
end;

function TGlobal.ShowDebug: Boolean;
begin
  try
    Result := False;
    frmDebug := TfrmDebug.Create(nil);
    frmDebug.ShowModal;
    Result := True;
  finally
    FreeAndNil(frmDebug);
  end;
end;

procedure TGlobal.ReSetXGM;
var
  nCnt: Integer;
begin
  ShellExecute(MainForm.FApplicationHandle, 'open', PChar(HomeDir + 'exit.vbs'), nil, nil, SW_SHOW);
  Log.LogWrite('run_app 종료');
  nCnt := 0;

  while True do
  begin
    if IsRunningProcess('run_app.exe') then
    begin
      //Log.LogWrite('run_app 구동중')
      inc(nCnt);
      if nCnt > 200 then
      begin
        Log.LogWrite('run_app 종료 실패!!!');
        break;
      end;
    end
    else
    begin
      Log.LogWrite('run_app 구동종료');
      ShellExecute(MainForm.FApplicationHandle, 'open', PChar(HomeDir + 'run.vbs'), nil, nil, SW_SHOW);
      Log.LogWrite('run_app 구동');

      break;
    end;

    sleep(500);
  end;

end;

procedure TGlobal.WriteConfigAgentIP_R(ANo: Integer; AIP: String);
begin
  FConfig.WriteString('AGENT', 'R_IP_' + IntToStr(ANo), AIP);
end;

procedure TGlobal.WriteConfigAgentIP_L(ANo: Integer; AIP: String);
begin
  FConfig.WriteString('AGENT', 'L_IP_' + IntToStr(ANo), AIP);
end;

function TGlobal.ReadConfigAgentIP_R(ANo: Integer): String;
begin
  Result := FConfig.ReadString('AGENT', 'R_IP_' + IntToStr(ANo), '');
end;

function TGlobal.ReadConfigAgentIP_L(ANo: Integer): String;
begin
  Result := FConfig.ReadString('AGENT', 'L_IP_' + IntToStr(ANo), '');
end;

function TGlobal.ReadConfigAgentMAC_R(ANo: Integer): String;
begin
  Result := FConfig.ReadString('AGENT', 'R_MAC_' + IntToStr(ANo), '');
end;

function TGlobal.ReadConfigAgentMAC_L(ANo: Integer): String;
begin
  Result := FConfig.ReadString('AGENT', 'L_MAC_' + IntToStr(ANo), '');
end;

function TGlobal.ReadConfigBeamType(ANo: Integer): String;
begin
  Result := FConfig.ReadString('BEAM', 'TYPE_' + IntToStr(ANo), '');
end;

function TGlobal.ReadConfigBeamIP(ANo: Integer): String;
begin
  Result := FConfig.ReadString('BEAM', 'IP_' + IntToStr(ANo), '');
end;

function TGlobal.ReadConfigBeamPW(ANo: Integer): String;
begin
  Result := FConfig.ReadString('BEAM', 'PW_' + IntToStr(ANo), '');
end;

end.
