unit uGlobal;

interface

uses
  IniFiles, CPort, System.DateUtils, System.Classes,
  uTeeboxInfo, uTeeboxThread, uConsts, uFunction, uStruct, uErpApi,
  uHeatControlCom, uHeatControlTcp,
  uComZoom,
  uComJMS,
  uComJeu435, uComJeu60A, uComJeu50A,
  uComModen, uComModenYJ,
  uSeatControlTcp, uXGClientDM, uXGServer, uLogging;

type
  TGlobal = class

  private
    FStore: TStoreInfo;
    FADConfig: TADConfig;
    FLog: TLog;
    FKioskList: array[0..10] of TKioskInfo;

    FTeebox: TTeebox;
    FApi: TApiServer;

    FXGolfDM: TXGolfDM;
    FTcpServer: TTcpServer;

    FTeeboxThread: TTeeboxThread;
    FControlMonThread: TControlMonThread;
    FComThreadZoom: TComThreadZoom;
    FComThreadJMS: TComThreadJMS;

    FComJeu435: TComThreadJeu435;
    FComJeu435_2: TComThreadJeu435;
    FComJeu435_3: TComThreadJeu435;

    FComJeu60A: TComThreadJeu60A;
    FComJeu60A_2: TComThreadJeu60A;
    FComJeu60A_3: TComThreadJeu60A;
    FComJeu60A_4: TComThreadJeu60A;

    FComJeu50A: TComThreadJeu50A;
    FComJeu50A_2: TComThreadJeu50A;
    FComJeu50A_3: TComThreadJeu50A;

    FComThreadModen: TComThreadModen;
    FComThreadModen_2: TComThreadModen;
    FComThreadModen_3: TComThreadModen;
    FComThreadModen_4: TComThreadModen;

    FComThreadModenYJ: TComThreadModenYJ;

    //FControlComPortHeatMonThread: TControlComPortHeatMonThread;
    FTcpThreadHeat: TTcpThreadHeat;

    FAppName: string;
    FHomeDir: string;
    FConfig: TIniFile;
    FConfigFileName: string;
    FConfigBall: TIniFile;
    FConfigBallFileName: string;
    FConfigHeat: TIniFile;
    FConfigHeatFileName: string;
    FConfigDir: string;
    
    FTeeboxThreadTime: TDateTime;
    FTeeboxThreadTimePre: TDateTime;
    FHeatThreadTime: TDateTime;
    FTeeboxThreadError: String;
    FTeeboxThreadChk: Integer;
    FTeeboxControlTime: TDateTime;
    FTeeboxControlTimePre: TDateTime;
    FTeeboxControlError: String;
    FTeeboxControlChk: Integer;

    FDebugSeatStatus: String;

    FCtrlBufferTemp: String;

    FCtrlBufferTemp1: String;
    FCtrlBufferTemp2: String;
    FCtrlBufferTemp3: String;
    FCtrlBufferTemp4: String;

    FReserveDBWrite: Boolean; //DB 재연결 확인용

    FSendACSTeeboxError: TDateTime;

    FNoErpMode: Boolean; //파트너센터 에러시

    procedure CheckConfig;
    procedure ReadConfig;
  public
    constructor Create;
    destructor Destroy; override;

    function StartUp: Boolean;
    function StopDown: Boolean;

    function GetErpOauth2: Boolean;

    procedure SetConfig(const ASection, AItem: string; const ANewValue: Variant);
    function GetConfig(const AVarType: TVarType; const ASection, AItem: string; const ADefaultValue: Variant): Variant;
    function GetConfigByString(const ASection, AItem: string; const ADefaultValue: string): string;
    function GetConfigByInteger(const ASection, AItem: string; const ADefaultValue: integer): integer;
    function GetConfigByBool(const ASection, AItem: string; const ADefaultValue: boolean): boolean;
    function GetStoreInfoToApi: Boolean;
    function GetConfigInfoToApi: Boolean;

    procedure DeleteDBReserve;
    procedure KioskTimeCheck;
    procedure SendSMSToErp(ASendDiv, ATeeboxNm: String);
    procedure SendACSToErp(ASendDiv, ATeeboxNm: String);

    property Store: TStoreInfo read FStore write FStore;
    //property Kiosk: TKioskInfo read FKiosk write FKiosk;
    property Teebox: TTeebox read FTeebox write FTeebox;
    property TeeboxThread: TTeeboxThread read FTeeboxThread write FTeeboxThread;
    property Api: TApiServer read FApi write FApi;
    property ADConfig: TADConfig read FADConfig write FADConfig;
    property TcpServer: TTcpServer read FTcpServer write FTcpServer;
    property Log: TLog read FLog write FLog;

    //procedure DebugLogWrite(ALog: string);
    procedure DebugLogViewWrite(ALog: string);
    procedure DebugLogViewWriteA6001(AIndex: Integer; ALog: string);
    procedure DebugLogViewApiWrite(ALog: string);

    procedure SetADConfigToken(AToken: AnsiString);
    procedure SetStoreInfo(AStoreNm, AStartTime, AEndTime, AUseRewardYn, AStoreChgDate, AACS, AACS1Yn, AACS1HpNo, AACS2Yn, AACS3Yn: String; AACS1, AACS2, AACS3: Integer; ABallRecallStartTime, ABallRecallEndTime: String);
    procedure SetKioskInfo(ADeviceNo, AUserId: String);
    procedure SetKioskPrint(ADeviceNo, AUserId, AError: String);
    procedure SetConfigDebug(AStr: String);
    procedure SetADConfigBallReserve(ATeeboxNo: Integer; AReserveNo: String; AReserveStartDate: String);
    procedure SetADConfigBallPrepare(ATeeboxNo: Integer; AReserveNo: String; APrepareStartDate: String);

    function SetADConfigEmergency(AMode, AUserId: String): Boolean;

    procedure CheckConfigBall(ATeeboxNo: Integer);
    procedure TeeboxThreadTimeCheck; //DB, 예약번호 초기화등
    procedure HeatThreadTimeCheck;
    procedure TeeboxControlTimeCheck;
    procedure TeeboxThreadErrorCheck;
    procedure ControlThreadErrorCheck;

    procedure SetStoreInfoClose(AClose: String);
    procedure SetStoreEndDBTime(AClose: String);

    procedure StartComPortThread;
    procedure StopComPortThread;

    procedure CtrlSendBuffer(ATeeboxNo: Integer; ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
    procedure CtrlHeatSendBuffer(ATeeboxNo: Integer; ATeeboxUse, AType: String);

    function ReadConfigBallBackStartTime: String;
    function ReadConfigBallStartTime(ATeeboxNo: Integer; AReserveNo: String): String;
    function ReadConfigBallPrepareStartTime(ATeeboxNo: Integer; AReserveNo: String): String;
    function ReadConfigBallReserveNo(ATeeboxNo: Integer): String;
    function ReadConfigBallRemainMin(ATeeboxNo: Integer): Integer;
    function ReadConfigBallRemainBall(ATeeboxNo: Integer): Integer;
    function SetTeeboxHeatConfig(ATeeboxNo, ATime, AUse, AAuto, AStartTm: String): Boolean;
    function SetHeatStatus: Boolean;

    property XGolfDM: TXGolfDM read FXGolfDM write FXGolfDM;

    //property ControlComPortHeatMonThread: TControlComPortHeatMonThread read FControlComPortHeatMonThread write FControlComPortHeatMonThread;
    property TcpThreadHeat: TTcpThreadHeat read FTcpThreadHeat write FTcpThreadHeat;

    property ControlMonThread: TControlMonThread read FControlMonThread write FControlMonThread;
    property ComThreadZoom: TComThreadZoom read FComThreadZoom write FComThreadZoom;
    property ComThreadJMS: TComThreadJMS read FComThreadJMS write FComThreadJMS;

    property ComJeu435: TComThreadJeu435 read FComJeu435 write FComJeu435;
    property ComJeu435_2: TComThreadJeu435 read FComJeu435_2 write FComJeu435_2;
    property ComJeu435_3: TComThreadJeu435 read FComJeu435_3 write FComJeu435_3;

    property ComJeu60A: TComThreadJeu60A read FComJeu60A write FComJeu60A;
    property ComJeu60A_2: TComThreadJeu60A read FComJeu60A_2 write FComJeu60A_2;
    property ComJeu60A_3: TComThreadJeu60A read FComJeu60A_3 write FComJeu60A_3;
    property ComJeu60A_4: TComThreadJeu60A read FComJeu60A_4 write FComJeu60A_4;

    property ComJeu50A: TComThreadJeu50A read FComJeu50A write FComJeu50A;
    property ComJeu50A_2: TComThreadJeu50A read FComJeu50A_2 write FComJeu50A_2;
    property ComJeu50A_3: TComThreadJeu50A read FComJeu50A_3 write FComJeu50A_3;

    property ComThreadModen: TComThreadModen read FComThreadModen write FComThreadModen;
    property ComThreadModen2: TComThreadModen read FComThreadModen_2 write FComThreadModen_2;
    property ComThreadModen3: TComThreadModen read FComThreadModen_3 write FComThreadModen_3;
    property ComThreadModen4: TComThreadModen read FComThreadModen_4 write FComThreadModen_4;

    property ComThreadModenYJ: TComThreadModenYJ read FComThreadModenYJ write FComThreadModenYJ;

    property AppName: string read FAppName write FAppName;
    property HomeDir: string read FHomeDir write FHomeDir;
    property ConfigDir: string read FConfigDir write FConfigDir;
    property Config: TIniFile read FConfig write FConfig;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;

    property CtrlBufferTemp: string read FCtrlBufferTemp write FCtrlBufferTemp;
    property CtrlBufferTemp1: string read FCtrlBufferTemp1 write FCtrlBufferTemp1;
    property CtrlBufferTemp2: string read FCtrlBufferTemp2 write FCtrlBufferTemp2;
    property CtrlBufferTemp3: string read FCtrlBufferTemp3 write FCtrlBufferTemp3;
    property CtrlBufferTemp4: string read FCtrlBufferTemp4 write FCtrlBufferTemp4;

    property TeeboxThreadTime: TDateTime read FTeeboxThreadTime write FTeeboxThreadTime;
    property TeeboxThreadTimePre: TDateTime read FTeeboxThreadTimePre write FTeeboxThreadTimePre;
    property HeatThreadTime: TDateTime read FHeatThreadTime write FHeatThreadTime;
    property TeeboxThreadError: String read FTeeboxThreadError write FTeeboxThreadError;
    property TeeboxControlTime: TDateTime read FTeeboxControlTime write FTeeboxControlTime;
    property TeeboxControlTimePre: TDateTime read FTeeboxControlTimePre write FTeeboxControlTimePre;
    property TeeboxControlError: String read FTeeboxControlError write FTeeboxControlError;

    property ReserveDBWrite: Boolean read FReserveDBWrite write FReserveDBWrite;

    property SendACSTeeboxError: TDateTime read FSendACSTeeboxError write FSendACSTeeboxError;

    property NoErpMode: Boolean read FNoErpMode write FNoErpMode;
  end;

var
  Global: TGlobal;

implementation

uses
  SysUtils, Variants, uXGMainForm, Vcl.Graphics, JSON;

{ TGlobal }

constructor TGlobal.Create;
var
  sStr: string;
  nIndex: Integer;
begin
  FAppName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  FHomeDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  FConfigDir := FHomeDir + 'config\';
  FConfigFileName := FConfigDir + 'Xtouch.config';
  ForceDirectories(FConfigDir);
  FConfig := TIniFile.Create(FConfigFileName);
  if not FileExists(FConfigFileName) then
  begin
    WriteFile(FConfigFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigFileName, '');
  end;

  FConfigBallFileName := FConfigDir + 'XtouchfBall.config';
  FConfigBall := TIniFile.Create(FConfigBallFileName);
  if not FileExists(FConfigBallFileName) then
  begin
    WriteFile(FConfigBallFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigBallFileName, '');

    for nIndex := 1 to 100 do
    begin
      FConfigBall.WriteString('Seat_' + IntToStr(nIndex), 'ReserveNo', '');
    end;
  end;

  FConfigHeatFileName := FConfigDir + 'XtouchfHeat.config';
  FConfigHeat := TIniFile.Create(FConfigHeatFileName);
  if not FileExists(FConfigHeatFileName) then
  begin
    WriteFile(FConfigHeatFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigHeatFileName, '');

    for nIndex := 1 to 100 do
    begin
      FConfigHeat.WriteString('Seat_' + IntToStr(nIndex), 'HeatUse', '0');
    end;
  end;

  CheckConfig;
  ReadConfig; //파트너센터 접속정보

  FTeeboxThreadTime := Now;

  FDebugSeatStatus := '0';
  FTeeboxThreadChk := 0;
  FTeeboxControlChk := 0;
  FReserveDBWrite := False;
  FNoErpMode := False;
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
      //WriteLogDayFile(Log.LogFileName, sResult);
      Log.LogWrite(sResult);

      sResult := Api.GetOauth2(sToken, FADConfig.ApiUrl, FADConfig.UserId, FADConfig.UserPw);
      if sResult = 'Success' then
      begin
        SetADConfigToken(sToken);
        //WriteLogDayFile(Log.LogFileName, 'Token '  + sResult);
        Log.LogWrite('Token '  + sResult);

        Log.LogReserveWrite('Token ' + sResult);
      end
      else
      begin
        //WriteLogDayFile(Log.LogFileName, sResult);
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
      //WriteLogDayFile(Log.LogFileName, 'Token ' + sResult);
      Log.LogWrite('Token ' + sResult);
    end
    else
    begin
      //WriteLogDayFile(Log.LogFileName, sResult);
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
begin
  Result := False;

  Log := TLog.Create;
  //XGolfDM := TXGolfDM.Create(Nil);
  FTcpServer := TTcpServer.Create;

  Api := TApiServer.Create;

  if Global.ADConfig.Emergency = False then
  begin
    if GetErpOauth2 = False then
      Exit;

    //환경설정
    if GetConfigInfoToApi = False then
      Exit;

    ReadConfig; //파트너센터 정보 다시 읽기

    if GetStoreInfoToApi = False then
      Exit;

    //최초실행시,재설치시 ERP서버 배정정보 호출
    if FADConfig.SystemInstall <> '1' then
    begin
      if FTcpServer.GetErpTeeboxList = False then
        Exit;

      FConfig.WriteString('ADInfo', 'SystemInstall', '1');
    end;

  end;

  XGolfDM := TXGolfDM.Create(Nil);

  if ADConfig.StoreCode = 'T0001' then //장한평
    DeleteDBReserve; //배정내역 삭제

  Teebox := TTeebox.Create; //타석기정보

  //test시 주석처리
  TeeboxThread := TTeeboxThread.Create; //타석기 예약정보관리

  //ControlMonThread := TControlMonThread.Create; //Simulation TCP 통신
  if (FADConfig.ProtocolType = 'ZOOM') or (FADConfig.ProtocolType = 'ZOOM1') then
  begin
    ComThreadZoom := TComThreadZoom.Create; //Simulation Com 통신
  end
  else if FADConfig.ProtocolType = 'JEHU435' then
  begin
    ComJeu435 := TComThreadJeu435.Create;

    if ADConfig.StoreCode = 'A1001' then //스타
    begin
      {$IFDEF RELEASE}
      //ControlComPortHeatMonThread := TControlComPortHeatMonThread.Create;
      //SetHeatStatus;
      {$ENDIF}
      {$IFDEF DEBUG}
      {$ENDIF}
    end;

    if ADConfig.StoreCode = 'A8001' then
    begin
      {$IFDEF RELEASE}
      ComJeu435_2 := TComThreadJeu435.Create;
      ComJeu435_3 := TComThreadJeu435.Create;
      {$ENDIF}
    end;

  end
  else if FADConfig.ProtocolType = 'JEHU60A' then
  begin
    ComJeu60A := TComThreadJeu60A.Create;

    if (ADConfig.StoreCode = 'A6001') or (ADConfig.StoreCode = 'AD001') then //캐슬렉스, 한강
    begin
      {$IFDEF RELEASE}
      ComJeu60A_2 := TComThreadJeu60A.Create;
      ComJeu60A_3 := TComThreadJeu60A.Create;

      if (ADConfig.StoreCode = 'A6001') then
        ComJeu60A_4 := TComThreadJeu60A.Create;
      {$ENDIF}
    end;

  end
  else if FADConfig.ProtocolType = 'JEU50A' then
  begin
    ComJeu50A := TComThreadJeu50A.Create;

    //빅토리아
    if ADConfig.StoreCode = 'A7001' then
    begin
      ComJeu50A_2 := TComThreadJeu50A.Create;
      ComJeu50A_3 := TComThreadJeu50A.Create;
    end;
  end
  else if FADConfig.ProtocolType = 'JMS' then
  begin
    ComThreadJMS := TComThreadJMS.Create;
  end
  else if FADConfig.ProtocolType = 'MODEN' then
  begin
    ComThreadModen := TComThreadModen.Create;
    ComThreadModen2 := TComThreadModen.Create;
    ComThreadModen3 := TComThreadModen.Create;
    ComThreadModen4 := TComThreadModen.Create;
  end
  else if FADConfig.ProtocolType = 'MODENYJ' then
  begin
    ComThreadModenYJ := TComThreadModenYJ.Create;
  end;

  Teebox.StartUp;
  //Global.Log.LogWrite('Teebox.StartUp');

  //test시 주석처리
  TeeboxThread.Resume;
  //Global.Log.LogWrite('TeeboxThread.Resume');

  //ControlMonThread.Resume;
  if (FADConfig.ProtocolType = 'ZOOM') or (FADConfig.ProtocolType = 'ZOOM1') then
  begin
    ComThreadZoom.Resume;
  end
  else if FADConfig.ProtocolType = 'JEHU435' then
  begin
    if ADConfig.StoreCode = 'A8001' then //쇼골프
    begin
      ComJeu435.ComPortSetting(1, 1, 63); //63타석, 1번 좌우겸용, 총 64개타석기
    end
    else
    begin
      ComJeu435.ComPortSetting(1, 1, Teebox.TeeboxDevicNoCnt);
    end;
    ComJeu435.Resume;

    if ADConfig.StoreCode = 'A1001' then
    begin
      {$IFDEF RELEASE}
      //ControlComPortHeatMonThread.Resume;
      {$ENDIF}
    end;

    if ADConfig.StoreCode = 'A8001' then //쇼골프
    begin
      {$IFDEF RELEASE}
      ComJeu435_2.ComPortSetting(2, 64, 128); //65타석, 1번 좌우겸용, 총 66개타석기
      //ComJeu435_3.ComPortSetting(3, 131, Teebox.TeeboxDevicNoCnt); //65타석, 1번 좌우겸용, 11타석 미사용,  총 55개타석기
      ComJeu435_3.ComPortSetting(3, 129, Teebox.TeeboxDevicNoCnt); //65타석, 1번 좌우겸용, 11타석 미사용,  총 55개타석기
      ComJeu435_2.Resume;
      ComJeu435_3.Resume;
      {$ENDIF}
    end;
  end
  else if FADConfig.ProtocolType = 'JEHU60A' then
  begin

    if ADConfig.StoreCode = 'A6001' then //캐슬렉스
    begin
      ComJeu60A.ComPortSetting(1, 1, 30);
      ComJeu60A.Resume;
      {$IFDEF RELEASE}
      ComJeu60A_2.ComPortSetting(2, 31, 63);
      ComJeu60A_3.ComPortSetting(3, 64, 98);
      ComJeu60A_2.Resume;
      ComJeu60A_3.Resume;
      ComJeu60A_4.ComPortSetting(4, 99, 123);
      ComJeu60A_4.Resume;
      {$ENDIF}
    end
    else if ADConfig.StoreCode = 'AD001' then //한강
    begin
      ComJeu60A.ComPortSetting(1, 1, 44); //45타석,사용 44 ComPortSetting(1, 1, 45)
      ComJeu60A.Resume;
      {$IFDEF RELEASE}
      ComJeu60A_2.ComPortSetting(2, 45, 88); //45타석, 사용 44  ComPortSetting(1, 46, 90)
      ComJeu60A_3.ComPortSetting(3, 89, 116); //29타석, 사용 28 ComPortSetting(1, 91, 119)
      ComJeu60A_2.Resume;
      ComJeu60A_3.Resume;
      {$ENDIF}
    end
    else
    begin //송도
      ComJeu60A.ComPortSetting(1, 1, Teebox.TeeboxDevicNoCnt);
      ComJeu60A.Resume;
    end;

  end
  else if FADConfig.ProtocolType = 'JEU50A' then
  begin

    if ADConfig.StoreCode = 'A7001' then //빅토리아
    begin
      {
      1) 오토티업타석 : 1층 : 3~27번 / 2층 : 32~56타석 / 3층 : 59~68타석
      2) 반자동타석 : 1층 1, 2, 28, 29 / 2층 : 30, 31, 57, 58
      3) 실외스크린 : 3층 69 ~ 83타석
      }

      ComJeu50A.ComPortSetting(1, 3, 27);
      ComJeu50A.Resume;

      ComJeu50A_2.ComPortSetting(2, 32, 56);
      ComJeu50A_3.ComPortSetting(3, 74, 83); //59~68 표시반대
      ComJeu50A_2.Resume;
      ComJeu50A_3.Resume;

    end
  end
  else if FADConfig.ProtocolType = 'JMS' then
  begin
    ComThreadJMS.Resume;
  end
  else if FADConfig.ProtocolType = 'MODEN' then
  begin
    ComThreadModen.ComPortSetting(2, 1, 16); //16
    ComThreadModen2.ComPortSetting(3, 17, 32); //16
    ComThreadModen3.ComPortSetting(4, 33, 48); //16
    ComThreadModen4.ComPortSetting(5, 49, 62); //14

    ComThreadModen.Resume;
    ComThreadModen2.Resume;
    ComThreadModen3.Resume;
    ComThreadModen4.Resume;
  end
  else if FADConfig.ProtocolType = 'MODENYJ' then
  begin
    ComThreadModenYJ.Resume;
  end;

  //if FADConfig.StoreCode = 'B2001' then 드림테크/ 그린필드, 조광
  begin
    if FADConfig.HeatTcpPort <> 0 then
    begin
      TcpThreadHeat := TTcpThreadHeat.Create;
      SetHeatStatus;
      TcpThreadHeat.Resume;
    end;
  end;

  Result := True;
end;

procedure TGlobal.CtrlSendBuffer(ATeeboxNo: Integer; ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  rSeatInfo: TTeeboxInfo;
  sHeatUse: String;
begin
  //LogWrite('CtrlSendBuffer : ' + ADeviceId);
  if ControlMonThread <> nil then
    ControlMonThread.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
  else if ComThreadZoom <> nil then
    ComThreadZoom.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
  else if ComJeu435 <> nil then
  begin
    if ADConfig.StoreCode = 'A8001' then //쇼골프
    begin
      if ATeeboxNo <= 63 then
        ComJeu435.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= 128 then
        ComJeu435_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else
        ComJeu435_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end
    else
      ComJeu435.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    {
    if ADConfig.HeatAuto = '1' then
    begin
      sHeatUse := '0';
      if StrToInt(ATeeboxTime) > 0 then
        sHeatUse := '1';

      CtrlHeatSendBuffer(ATeeboxNo, sHeatUse, '1');
    end;
    }
  end
  else if ComJeu60A <> nil then
  begin

    if ADConfig.StoreCode = 'A6001' then
    begin
      if ATeeboxNo <= 30 then
        ComJeu60A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= 63 then
        ComJeu60A_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ATeeboxNo <= 98 then
        ComJeu60A_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else
        ComJeu60A_4.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end
    else if ADConfig.StoreCode = 'AD001' then //한강
    begin
      if ADeviceId < '046' then
        ComJeu60A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ADeviceId < '091' then
        ComJeu60A_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else
        ComJeu60A_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end
    else
      ComJeu60A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end
  else if ComJeu50A <> nil then
  begin
    {
    1) 오토티업타석 : 1층 : 3~27번 / 2층 : 32~56타석 / 3층 : 59~68타석
    2) 반자동타석 : 1층 1, 2, 28, 29 / 2층 : 30, 31, 57, 58
    3) 실외스크린 : 3층 69 ~ 83타석
    }
    if ADConfig.StoreCode = 'A7001' then
    begin
      if ADeviceId < '029' then
        ComJeu50A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else if ADeviceId < '058' then
        ComJeu50A_2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
      else
        ComJeu50A_3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
    end
    else
      ComJeu50A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end
  else if ComThreadModen <> nil then
  begin
    //LogWrite('ADeviceId : ' + ADeviceId);
    if ATeeboxNo <= 16 then
      ComThreadModen.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= 32 then
      ComThreadModen2.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else if ATeeboxNo <= 48 then
      ComThreadModen3.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType)
    else
      ComThreadModen4.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType);
  end;

  //heat
  //if ADConfig.StoreCode = 'B2001' then //그린필드
  if FADConfig.HeatTcpPort <> 0 then //그린필드, 조광
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

procedure TGlobal.CtrlHeatSendBuffer(ATeeboxNo: Integer; ATeeboxUse, AType: String);
var
  sSendData, sBcc: AnsiString;
  rSeatInfo: TTeeboxInfo;
  sHeatUse, sResult: String;
begin

  if (ADConfig.StoreCode = 'A6001') and (ATeeboxNo >= 99) then //A6001	캐슬렉스서울
    Exit;

  rSeatInfo := Teebox.GetTeeboxInfo(ATeeboxNo);

  if AType = '1' then //auto
  begin
    SetTeeboxHeatConfig(IntToStr(ATeeboxNo), ADConfig.HeatTime, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));

    //if ControlComPortHeatMonThread <> nil then //스타
      //ControlComPortHeatMonThread.SetHeatuse(rSeatInfo.TeeboxNm, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));

    if TcpThreadHeat <> nil then //그린필드, 조광
      TcpThreadHeat.SetHeatuse(ATeeboxNo, ATeeboxUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now), True);
  end
  else
  begin
    SetTeeboxHeatConfig(IntToStr(ATeeboxNo), '', ATeeboxUse, '0', '');

    //if ControlComPortHeatMonThread <> nil then //스타
      //ControlComPortHeatMonThread.SetHeatuse(rSeatInfo.TeeboxNm, ATeeboxUse, '0', '');

    if TcpThreadHeat <> nil then //그린필
      TcpThreadHeat.SetHeatuse(ATeeboxNo, ATeeboxUse, '0', '', True);
  end;

  sResult := XGolfDM.SeatHeatUseUpdate(ADConfig.StoreCode, IntToStr(ATeeboxNo), ATeeboxUse, AType, '');
  if sResult <> 'Success' then
  begin
    //Result := '{"result_cd":"","result_msg":"' + sResult + '"}';
    //Exit;
  end;

  //if ControlComPortHeatMonThread <> nil then //스타
    //ControlComPortHeatMonThread.SetCmdSendBuffer;
end;

function TGlobal.GetStoreInfoToApi: Boolean;
var
  sResult, sStr: String;
  sStoreNm, sStartTime, sEndTime, sUseRewardYn, sServerTime: String;
  dSvrTime: TDateTime;

  jObj, jSubObj, jArrSubObj: TJSONObject;
  jObjArr: TJsonArray;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog, sStoreChgDate, sACS, sACS1, sACS2, sACS3, sACS1RecvHpNo: String;
  nCnt, nIndex, nACS1, nACS2, nACS3: Integer;

  sBallRecallStartTime, sBallRecallEndTime: String;
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

    sStoreNm := jSubObj.GetValue('store_nm').Value;
    sStartTime := jSubObj.GetValue('start_time').Value;
    sEndTime := jSubObj.GetValue('end_time').Value;
    sUseRewardYn := jSubObj.GetValue('use_reward_yn').Value;
    sServerTime := jSubObj.GetValue('server_time').Value;
    sStoreChgDate := jSubObj.GetValue('chg_date').Value;
    sACS := jSubObj.GetValue('acs_use_yn').Value;

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

    //2021-08-20 그린필드, 볼회수
    sBallRecallStartTime := jSubObj.GetValue('ball_recall_start_time').Value; //볼회수 시작시간
    sBallRecallEndTime := jSubObj.GetValue('ball_recall_end_time').Value; //볼회수 종료시간

    SetStoreInfo(sStoreNm, sStartTime, sEndTime, sUseRewardYn, sStoreChgDate, sACS, sACS1, sACS1RecvHpNo, sACS2, sACS3, nACS1, nACS2, nACS3, sBallRecallStartTime, sBallRecallEndTime);
    {
    sStr := 'StartTime: ' + sStartTime + ' / EndTime: ' + sEndTime + ' / UseRewardYn: ' + sUseRewardYn + ' / ' +
            sStoreChgDate  + ' / ' + sACS  + ' / ' + sACS1 + ' / ' + sACS1RecvHpNo + ' / ' + sACS2 + ' / ' + sACS3 + ' / ' +
            IntToStr(nACS1)  + ' / ' + IntToStr(nACS2)  + ' / ' + IntToStr(nACS3);
    WriteLogDayFile(Global.LogFileName, sStr);
    }

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
  //sStoreNm, sStartTime, sEndTime, sUseRewardYn, sServerTime: String;
  //dSvrTime: TDateTime;

  jObj, jSubObj, jArrSubObj: TJSONObject;
  //jObjArr: TJsonArray;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog: string;
  //sStoreChgDate, sACS, sACS1, sACS2, sACS3, sACS1RecvHpNo: String;
  //nCnt, nIndex, nACS1, nACS2, nACS3: Integer;

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
      Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K202_ConfiglistNew : ' + sResultCd + ' / ' + sResultMsg;
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

  if ControlMonThread <> nil then
  begin
    ControlMonThread.Terminate;
    ControlMonThread.WaitFor;
    ControlMonThread.Free;
  end;

  if ComThreadZoom <> nil then
  begin
    ComThreadZoom.Terminate;
    ComThreadZoom.WaitFor;
    ComThreadZoom.Free;
  end;

  if ComJeu435 <> nil then
  begin
    ComJeu435.Terminate;
    ComJeu435.WaitFor;
    ComJeu435.Free;
  end;

  if ADConfig.StoreCode = 'A8001' then //쇼골프
  begin
    if ComJeu435_2 <> nil then
    begin
      ComJeu435_2.Terminate;
      ComJeu435_2.WaitFor;
      ComJeu435_2.Free;
    end;

    if ComJeu435_3 <> nil then
    begin
      ComJeu435_3.Terminate;
      ComJeu435_3.WaitFor;
      ComJeu435_3.Free;
    end;
  end;

  if ComJeu60A <> nil then
  begin
    ComJeu60A.Terminate;
    ComJeu60A.WaitFor;
    ComJeu60A.Free;
  end;

  //chy 캐슬렉스, 한강
  if (ADConfig.StoreCode = 'A6001') or (ADConfig.StoreCode = 'AD001') then
  begin
    if ComJeu60A_2 <> nil then
    begin
      ComJeu60A_2.Terminate;
      ComJeu60A_2.WaitFor;
      ComJeu60A_2.Free;
    end;

    if ComJeu60A_3 <> nil then
    begin
      ComJeu60A_3.Terminate;
      ComJeu60A_3.WaitFor;
      ComJeu60A_3.Free;
    end;

    if ComJeu60A_4 <> nil then
    begin
      ComJeu60A_4.Terminate;
      ComJeu60A_4.WaitFor;
      ComJeu60A_4.Free;
    end;
  end;

  if ComJeu50A <> nil then
  begin
    ComJeu50A.Terminate;
    ComJeu50A.WaitFor;
    ComJeu50A.Free;
  end;

  //chy 빅토리아
  if ADConfig.StoreCode = 'A7001' then
  begin
    if ComJeu50A_2 <> nil then
    begin
      ComJeu50A_2.Terminate;
      ComJeu50A_2.WaitFor;
      ComJeu50A_2.Free;
    end;

    if ComJeu50A_3 <> nil then
    begin
      ComJeu50A_3.Terminate;
      ComJeu50A_3.WaitFor;
      ComJeu50A_3.Free;
    end;
  end;

  if ComThreadJMS <> nil then
  begin
    ComThreadJMS.Terminate;
    ComThreadJMS.WaitFor;
    ComThreadJMS.Free;
  end;

  if ADConfig.StoreCode = 'AB001' then
  begin
    if ComThreadModen <> nil then
    begin
      ComThreadModen.Terminate;
      ComThreadModen.WaitFor;
      ComThreadModen.Free;
    end;

    if ComThreadModen2 <> nil then
    begin
      ComThreadModen2.Terminate;
      ComThreadModen2.WaitFor;
      ComThreadModen2.Free;
    end;

    if ComThreadModen3 <> nil then
    begin
      ComThreadModen3.Terminate;
      ComThreadModen3.WaitFor;
      ComThreadModen3.Free;
    end;

    if ComThreadModen4 <> nil then
    begin
      ComThreadModen4.Terminate;
      ComThreadModen4.WaitFor;
      ComThreadModen4.Free;
    end;
  end;

  if ComThreadModenYJ <> nil then
  begin
    ComThreadModenYJ.Terminate;
    ComThreadModenYJ.WaitFor;
    ComThreadModenYJ.Free;
  end;

  //heat
  {
  if ControlComPortHeatMonThread <> nil then
  begin
    ControlComPortHeatMonThread.Terminate;
    ControlComPortHeatMonThread.WaitFor;
    ControlComPortHeatMonThread.Free;
  end;
  }
  if TcpThreadHeat <> nil then
  begin
    TcpThreadHeat.Terminate;
    TcpThreadHeat.WaitFor;
    TcpThreadHeat.Free;
  end;

  Result := True;
end;

procedure TGlobal.StartComPortThread;
begin
  ComThreadZoom := TComThreadZoom.Create;
  ComThreadZoom.Resume;

  //WriteLogDayFile(LogFileName, 'ReStartComPortThread !!!');
  Log.LogWrite('ReStartComPortThread !!!');
end;

procedure TGlobal.StopComPortThread;
begin
  if ComThreadZoom <> nil then
  begin
    ComThreadZoom.Terminate;
    ComThreadZoom.WaitFor;
    ComThreadZoom.Free;
  end;
end;

destructor TGlobal.Destroy;
begin
  StopDown;

  XGolfDM.Free;
  FTcpServer.Free;
  Api.Free;
  Teebox.Free;

  //ini 파일
  FConfig.Free;
  FConfigBall.Free;
  FConfigHeat.Free;

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

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('ADInfo') then
  begin
    FConfig.WriteInteger('ADInfo', 'Port', 1);
    FConfig.WriteInteger('ADInfo', 'Baudrate', 9600);
    FConfig.WriteString('ADInfo', 'Url', '');
    FConfig.WriteInteger('ADInfo', 'TcpPort', 3308);
    FConfig.WriteInteger('ADInfo', 'DBPort', 3306);
    FConfig.WriteString('ADInfo', 'ProtocolType', 'ZOOM');
    FConfig.WriteInteger('ADInfo', 'HeatPort', 2);
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
  //FADConfig.BranchCode := FConfig.ReadString('ADInfo', 'BranchCode', '');
  FADConfig.StoreCode := FConfig.ReadString('Partners', 'StoreCode', '');
  //FADConfig.ADToken := FConfig.ReadString('ADInfo', 'ADToken', '');
  FADConfig.UserId := FConfig.ReadString('Partners', 'UserId', '');
  FADConfig.ApiUrl := FConfig.ReadString('Partners', 'Url', '');

  //FADConfig.UserPw := FConfig.ReadString('Partners', 'UserPw', '');
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

  FADConfig.TcpPort := FConfig.ReadInteger('ADInfo', 'TcpPort', 3308);

  {$IFDEF RELEASE}
  FADConfig.DBPort := FConfig.ReadInteger('ADInfo', 'DBPort', 3306);
  {$ENDIF}
  {$IFDEF DEBUG}
  FADConfig.DBPort := 3307;
  {$ENDIF}

  //FADConfig.AgentTcpPort := FConfig.ReadInteger('ADInfo', 'AgentTcpPort', 16000);
  FADConfig.ProtocolType := FConfig.ReadString('ADInfo', 'ProtocolType', 'ZOOM');
  FADConfig.HeatPort := FConfig.ReadInteger('ADInfo', 'HeatPort', 2);
  FADConfig.HeatTcpIP := FConfig.ReadString('ADInfo', 'HeatTcpIP', '127.0.0.1');
  FADConfig.HeatTcpPort := FConfig.ReadInteger('ADInfo', 'HeatTcpPort', 0);
  FADConfig.HeatAuto := FConfig.ReadString('ADInfo', 'HeatAuto', '0');
  FADConfig.HeatTime := FConfig.ReadString('ADInfo', 'HeatTime', '0');
  FADConfig.SystemInstall := FConfig.ReadString('ADInfo', 'SystemInstall', '0');

  //2020-11-05 기기고장 1분유지시 문자발송여부
  FADConfig.ErrorSms := FConfig.ReadString('ADInfo', 'ErrorSms', 'N');

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

  FStore.StartTime := FConfig.ReadString('Store', 'StartTime', '05:00');
  FStore.EndTime := FConfig.ReadString('Store', 'EndTime', '23:00');
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

procedure TGlobal.CheckConfigBall(ATeeboxNo: Integer);
var
  I: Integer;
  SeatInfo: TTeeboxInfo;
  sLog: String;
begin
  if ATeeboxNo = 0 then
  begin
    FConfigBall.WriteString('BallBack', 'Start', FormatDateTime('YYYYMMDD hh:nn:ss', now));

    for I := 1 to Teebox.TeeboxLastNo do
    begin
      SeatInfo := Teebox.GetTeeboxInfo(I);

      FConfigBall.WriteString('Seat_' + IntToStr(I), 'ReserveNo', SeatInfo.TeeboxReserve.ReserveNo);
      FConfigBall.WriteInteger('Seat_' + IntToStr(I), 'RemainMinute', SeatInfo.RemainMinute);
      FConfigBall.WriteInteger('Seat_' + IntToStr(I), 'RemainBall', SeatInfo.RemainBall);
      FConfigBall.WriteString('Seat_' + IntToStr(I), 'UseStatus', SeatInfo.UseStatus);
    end;
    sLog := '볼회수 CheckConfigBall : ' + IntToStr(ATeeboxNo) + ' / ' + SeatInfo.TeeboxNm + ' / ' +
            IntToStr(SeatInfo.RemainMinute) + ' / ' + IntToStr(SeatInfo.RemainBall) + ' / ' + SeatInfo.UseStatus;
    //WriteLogDayFile(Global.LogFileName, sLog);
    Log.LogWrite(sLog);
  end
  else
  begin
    SeatInfo := Teebox.GetTeeboxInfo(ATeeboxNo);

    FConfigBall.WriteString('Seat_' + IntToStr(ATeeboxNo), 'ReserveNo', SeatInfo.TeeboxReserve.ReserveNo);
    FConfigBall.WriteInteger('Seat_' + IntToStr(ATeeboxNo), 'RemainMinute', SeatInfo.RemainMinute);
    FConfigBall.WriteInteger('Seat_' + IntToStr(ATeeboxNo), 'RemainBall', SeatInfo.RemainBall);
    FConfigBall.WriteString('Seat_' + IntToStr(ATeeboxNo), 'UseStatus', SeatInfo.UseStatus);

    sLog := '점검 CheckConfigBall : ' + IntToStr(ATeeboxNo) + ' / ' + SeatInfo.TeeboxNm + ' / ' +
            IntToStr(SeatInfo.RemainMinute) + ' / ' + IntToStr(SeatInfo.RemainBall) + ' / ' + SeatInfo.UseStatus;
    //WriteLogDayFile(Global.LogFileName, sLog);
    Log.LogWrite(sLog);
  end;

end;

function TGlobal.ReadConfigBallRemainMin(ATeeboxNo: Integer): Integer;
begin
  //볼회수시 남은시간 초기화일 경우 회수종료후 남은시간 체크용
  Result := FConfigBall.ReadInteger('Seat_' + IntToStr(ATeeboxNo), 'RemainMinute', 0);
end;

function TGlobal.ReadConfigBallRemainBall(ATeeboxNo: Integer): Integer;
begin
  //볼회수시 남은시간 초기화일 경우 회수종료후 남은볼수 체크용
  Result := FConfigBall.ReadInteger('Seat_' + IntToStr(ATeeboxNo), 'RemainBall', 0);
end;

//볼회수 시작시간
function TGlobal.ReadConfigBallBackStartTime: String;
begin
  Result := FConfigBall.ReadString('BallBack', 'Start', '');
end;

function TGlobal.ReadConfigBallStartTime(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sReserveNo, sStartTime: String;
begin
  Result := '';
  sReserveNo := FConfigBall.ReadString('Seat_' + IntToStr(ATeeboxNo), 'ReserveNo', '');
  sStartTime := FConfigBall.ReadString('Seat_' + IntToStr(ATeeboxNo), 'ReserveStartDate', '');

  if AReserveNo = sReserveNo then
    Result := sStartTime;
end;

function TGlobal.ReadConfigBallPrepareStartTime(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sReserveNo, sStartTime: String;
begin
  Result := '';
  sReserveNo := FConfigBall.ReadString('Seat_' + IntToStr(ATeeboxNo), 'ReserveNo', '');
  sStartTime := FConfigBall.ReadString('Seat_' + IntToStr(ATeeboxNo), 'PrepareStartDate', '');

  if AReserveNo = sReserveNo then
    Result := sStartTime;
end;

function TGlobal.ReadConfigBallReserveNo(ATeeboxNo: Integer): String;
begin
  Result := FConfigBall.ReadString('Seat_' + IntToStr(ATeeboxNo), 'ReserveNo', '');
end;


procedure TGlobal.SetADConfigToken(AToken: AnsiString);
begin
  FADConfig.ADToken := AToken;
  //FConfig.WriteString('ADInfo', 'ADToken', AToken);
end;

procedure TGlobal.SetStoreInfo(AStoreNm, AStartTime, AEndTime, AUseReWardYn, AStoreChgDate, AACS, AACS1Yn, AACS1HpNo, AACS2Yn, AACS3Yn: String; AACS1, AACS2, AACS3: Integer;
                              ABallRecallStartTime, ABallRecallEndTime: String);
var
  nNN, nHH: integer;
  sNN: String;
  STime, ETime: TDateTime;
begin
  FStore.StoreNm := AStoreNm;

  FStore.StartTime := AStartTime;
  FStore.EndTime := AEndTime;
  {
  if FStore.StartTime > FStore.EndTime then
  begin
    sNN := Copy(FStore.EndTime, 4, 2);
    nHH := StrToInt(Copy(FStore.EndTime, 1, 2)) + 24;
    FStore.EndTime := IntToStr(nHH) + ':' + sNN;
  end;
  }
  FStore.UseRewardYn := AUseReWardYn;
  FStore.StoreLastTM := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now); //2019-09-18 10:28:28
  FStore.StoreChgDate := AStoreChgDate;
  FStore.ACS := AACS;
  FStore.ACS_1_Yn := AACS1Yn;
  FStore.ACS_1_Hp := AACS1HpNo;
  FStore.ACS_2_Yn := AACS2Yn;
  FStore.ACS_3_Yn := AACS3Yn;
  FStore.ACS_1 := AACS1;
  FStore.ACS_2 := AACS2;
  FStore.ACS_3 := AACS3;

  nNN := StrToInt(Copy(FStore.EndTime, 4, 2));
  if (nNN + 10) > 50 then
    FStore.EndDBTime := ''
  else
    //FStore.EndDBTime := Copy(AEndTime, 1, 3) + IntToStr(nNN + 10);
    FStore.EndDBTime := Copy(FStore.EndTime, 1, 3) + IntToStr(nNN + 10);

  FStore.BallRecallStartTime := StringReplace(ABallRecallStartTime, ':', '', [rfReplaceAll]);
  FStore.BallRecallEndTime := StringReplace(ABallRecallEndTime, ':', '', [rfReplaceAll]);

  STime := DateStrToDateTime(FormatDateTime('yyyymmdd', now) + FStore.BallRecallStartTime + '00');
  ETime := DateStrToDateTime(FormatDateTime('yyyymmdd', now) + FStore.BallRecallEndTime + '00');
  FStore.BallRecallTime := MinutesBetween(STime, ETime);

  FConfig.WriteString('Store', 'StoreNm', FStore.StoreNm);
  FConfig.WriteString('Store', 'StartTime', FStore.StartTime);
  FConfig.WriteString('Store', 'EndTime', FStore.EndTime);
  FConfig.WriteString('Store', 'UseRewardYn', FStore.UseRewardYn);
  FConfig.WriteString('Store', 'ACS', FStore.ACS);
  FConfig.WriteString('Store', 'ACS_1_YN', FStore.ACS_1_Yn);
  FConfig.WriteString('Store', 'ACS_1_HP', FStore.ACS_1_Hp);
  FConfig.WriteString('Store', 'ACS_2_YN', FStore.ACS_2_Yn);
  FConfig.WriteString('Store', 'ACS_3_YN', FStore.ACS_3_Yn);
  FConfig.WriteString('Store', 'ACS_1', IntToStr(FStore.ACS_1));
  FConfig.WriteString('Store', 'ACS_2', IntToStr(FStore.ACS_2));
  FConfig.WriteString('Store', 'ACS_3', IntToStr(FStore.ACS_3));

  FConfig.WriteString('Store', 'BallRecallStartTime', FStore.BallRecallStartTime);
  FConfig.WriteString('Store', 'BallRecallEndTime', FStore.BallRecallEndTime);

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

function TGlobal.SetTeeboxHeatConfig(ATeeboxNo, ATime, AUse, AAuto, AStartTm: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  if ATeeboxNo = '0' then
  begin
    FADConfig.HeatAuto := AUse;
    FADConfig.HeatTime := ATime;
    FConfig.WriteString('ADInfo', 'HeatAuto', AUse);
    FConfig.WriteString('ADInfo', 'HeatTime', ATime);

    sStr := '히터설정 : ' + ATeeboxNo + ' / ' + AUse + ' / ' + ATime + ' / ' + AStartTm;
    Log.LogHeatWrite(sStr);
  end
  else
  begin
    FConfigHeat.WriteString('Seat_' + ATeeboxNo, 'HeatUse', AUse);
    FConfigHeat.WriteString('Seat_' + ATeeboxNo, 'HeatAuto', AAuto);

    if AAuto = '1' then
    begin
      FConfigHeat.WriteString('Seat_' + ATeeboxNo, 'HeatStart', AStartTm);
    end;
  end;

  Result := True;
end;

function TGlobal.SetHeatStatus: Boolean;
var
  nIndex, nCnt: Integer;
  sHeatUse, sHeatAuto, sHeatStart, sHeatFloor: String;
begin
  {if ControlComPortHeatMonThread <> nil then
    nCnt := HEAT_MAX
  else }
    nCnt := Teebox.TeeboxLastNo;

  //for nIndex := HEAT_MIN to HEAT_MAX do
  for nIndex := 1 to nCnt do
  begin
    sHeatUse := FConfigHeat.ReadString('Seat_' + IntToStr(nIndex), 'HeatUse', '0');
    sHeatAuto := FConfigHeat.ReadString('Seat_' + IntToStr(nIndex), 'HeatAuto', '0');
    sHeatStart := FConfigHeat.ReadString('Seat_' + IntToStr(nIndex), 'HeatStart', '');
    {
    if ControlComPortHeatMonThread <> nil then
      ControlComPortHeatMonThread.SetHeatuse(IntToStr(nIndex), sHeatUse, sHeatAuto, sHeatStart);
    }
    if TcpThreadHeat <> nil then
      TcpThreadHeat.SetHeatuse(nIndex, sHeatUse, sHeatAuto, sHeatStart, False);
  end;
end;

procedure TGlobal.SetConfigDebug(AStr: String);
begin
  FConfig.WriteString('ADInfo', 'Debug', AStr);
end;

procedure TGlobal.TeeboxThreadTimeCheck;
var
  sPtime, sNtime, sLogMsg: String;
  sResult: String;
  sToken: AnsiString;
begin
  sPtime := FormatDateTime('YYYYMMDDHH', TeeboxThreadTime);
  sNtime := FormatDateTime('YYYYMMDDHH', Now);

  if sPtime <> sNtime then
  begin
    sLogMsg := 'TSeatThread TimeCheck !!';
    Log.LogWrite(sLogMsg);

    //2021-05-03 유명
    //if Copy(sNtime, 9, 2) = '01' then
    if Copy(sNtime, 9, 2) = '04' then  //02 2021-06-01 유명 3시까지 연장영업
    begin
      DeleteDBReserve;

      //2021-11-05 인증확인용
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

    if (Global.ADConfig.StoreCode = 'A9001') then //루이힐스- 일반PC여서 재부팅기능 추가
    begin
      if Copy(sNtime, 9, 2) = '23' then
      begin
        MyExitWindows;
      end;
    end;

  end;

  TeeboxThreadTime := Now;
end;

procedure TGlobal.HeatThreadTimeCheck;
begin
  HeatThreadTime := Now;
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

procedure TGlobal.TeeboxThreadErrorCheck;
var
  sLog: String;
begin
  if TeeboxThreadTimePre = TeeboxThreadTime then
  begin
    TeeboxThreadError := 'Y';
    sLog := 'SeatThreadError : ' + FormatDateTime('YYYYMMDD hh:nn:ss', TeeboxThreadTimePre) + ' / ' +
            FormatDateTime('YYYYMMDD hh:nn:ss', TeeboxThreadTime);
    Log.LogWrite(sLog);
  end
  else
  begin
    TeeboxThreadError := 'N';
    TeeboxThreadTimePre := TeeboxThreadTime;
  end;

end;

procedure TGlobal.ControlThreadErrorCheck;
var
  sLog: String;
begin

  if TeeboxControlTimePre = TeeboxControlTime then
  begin
    TeeboxControlError := 'Y';
    sLog := 'TeeboxControlError : ' + FormatDateTime('YYYYMMDD hh:nn:ss', TeeboxControlTimePre) + ' / ' +
            FormatDateTime('YYYYMMDD hh:nn:ss', TeeboxControlTime);
    Log.LogWrite(sLog);

    StopComPortThread;
    StartComPortThread;
  end
  else
  begin
    TeeboxControlError := 'N';
    TeeboxControlTimePre := TeeboxControlTime;
  end;

end;

procedure TGlobal.SetADConfigBallReserve(ATeeboxNo: Integer; AReserveNo: String; AReserveStartDate: String);
var
  sStr: String;
begin
  try
    FConfigBall.WriteString('Seat_' + IntToStr(ATeeboxNo), 'ReserveNo', AReserveNo);
    FConfigBall.WriteString('Seat_' + IntToStr(ATeeboxNo), 'ReserveStartDate', AReserveStartDate);
  except
    on e: Exception do
    begin
      sStr := 'SetADConfigBallReserve Error : ' + e.Message + ' / ' +
              IntToStr(ATeeboxNo) + ' / ' +  AReserveNo + ' / ' + AReserveStartDate;
      Log.LogWrite(sStr);
    end;
  end;
end;

procedure TGlobal.SetADConfigBallPrepare(ATeeboxNo: Integer; AReserveNo: String; APrepareStartDate: String);
var
  sStr: String;
begin
  try
    FConfigBall.WriteString('Seat_' + IntToStr(ATeeboxNo), 'ReserveNo', AReserveNo);
    FConfigBall.WriteString('Seat_' + IntToStr(ATeeboxNo), 'PrepareStartDate', APrepareStartDate);
  except
    on e: Exception do
    begin
      sStr := 'SetADConfigBallPrepare Error : ' + e.Message + ' / ' +
              IntToStr(ATeeboxNo) + ' / ' +  AReserveNo + ' / ' + APrepareStartDate;
      Log.LogWrite(sStr);
    end;
  end;
end;

procedure TGlobal.SetStoreInfoClose(AClose: String);
begin
  FStore.Close := AClose;
end;

procedure TGlobal.SetStoreEndDBTime(AClose: String);
begin
  FStore.EndDBTime := AClose;
end;

procedure TGlobal.DebugLogViewWrite(ALog: string);
begin
  FCtrlBufferTemp := ALog;
  //MainForm.LogView(ALog);
end;

procedure TGlobal.DebugLogViewWriteA6001(AIndex: Integer; ALog: string);
begin
  if (Global.ADConfig.StoreCode = 'A6001') or (Global.ADConfig.StoreCode = 'A7001') or
     (Global.ADConfig.StoreCode = 'A8001') or (Global.ADConfig.StoreCode = 'AD001') then //캐슬렉스, 빅토리아, 쇼골프,대성,한강
  begin
    if AIndex = 1 then
      FCtrlBufferTemp1 := ALog;

    if AIndex = 2 then
      FCtrlBufferTemp2 := ALog;

    if AIndex = 3 then
      FCtrlBufferTemp3 := ALog;

    if AIndex = 4 then
      FCtrlBufferTemp4 := ALog;
  end
  else if (Global.ADConfig.StoreCode = 'AB001') then
  begin
    if AIndex = 2 then
      FCtrlBufferTemp1 := ALog;

    if AIndex = 3 then
      FCtrlBufferTemp2 := ALog;

    if AIndex = 4 then
      FCtrlBufferTemp3 := ALog;

    if AIndex = 5 then
    begin
      FCtrlBufferTemp4 := ALog;
      //LogCtrlWriteModen(5, ALog);
    end;
  end
  else
  begin
    FCtrlBufferTemp := ALog;
  end;

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

function TGlobal.GetConfig(const AVarType: TVarType; const ASection, AItem: string; const ADefaultValue: Variant): Variant;
begin
  case AVarType of
    varInteger:
      Result := FConfig.ReadInteger(ASection, AItem, ADefaultValue);
    varBoolean:
      Result := FConfig.ReadBool(ASection, AItem, ADefaultValue);
  else
    Result := FConfig.ReadString(ASection, AItem, ADefaultValue);
  end;
end;

function TGlobal.GetConfigByString(const ASection, AItem: string; const ADefaultValue: string): string;
begin
  Result := FConfig.ReadString(ASection, AItem, ADefaultValue);
end;

function TGlobal.GetConfigByInteger(const ASection, AItem: string; const ADefaultValue: integer): integer;
begin
  Result := FConfig.ReadInteger(ASection, AItem, ADefaultValue);
end;

function TGlobal.GetConfigByBool(const ASection, AItem: string; const ADefaultValue: boolean): boolean;
begin
  Result := FConfig.ReadBool(ASection, AItem, ADefaultValue);
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
    Log.LogWrite('배정데이터 삭제 실패: ' + sDateStr);

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

    //FKiosk.Status := False;
    if ASendDiv = '1' then
      FSendACSTeeboxError := now;

    Sleep(50);
    Teebox.TeeboxReserveUse := False;
  finally
    Teebox.TeeboxReserveUse := False;
    FreeAndNil(jObj);
  end;
end;

end.
