unit uGlobal;

interface

uses
  Winapi.Windows, IniFiles, CPort, System.DateUtils, System.Classes, ShellAPI,
  uTeeboxInfo, uTeeboxReserveList, uTeeboxThread, uConsts, uFunction, uStruct, uErpApi,
  uXGClientDM, uXGServer, uXGAgentServer, uLogging, uTapo,
  uRoomInfo, uRoomThread;

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
    FTapo: TTapo;

    FRoom: TRoom;
    FRoomThread: TRoomThread;

    FAppName: string;
    FHomeDir: string;
    FConfig: TIniFile;
    FConfigFileName: string;
    FConfigBall: TIniFile;
    FConfigBallFileName: string;
    FConfigAgent: TIniFile;
    FConfigAgentFileName: string;
    FConfigDir: string;
    
    FTeeboxThreadTime: TDateTime;
    FTeeboxThreadError: String;
    FTeeboxThreadChk: Integer;
    FTeeboxControlTime: TDateTime;
    FTeeboxControlError: String;
    FTeeboxControlChk: Integer;

    FDebugSeatStatus: String;

    FReserveDBWrite: Boolean; //DB 재연결 확인용

    FSendACSTeeboxError: TDateTime;

    FTapoCtrlLock: Boolean; //TAPO 제어여부

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
    property Tapo: TTapo read FTapo write FTapo;
    property Log: TLog read FLog write FLog;

    property Room: TRoom read FRoom write FRoom;
    property RoomThread: TRoomThread read FRoomThread write FRoomThread;

    procedure DebugLogViewApiWrite(ALog: string);

    procedure SetADConfigToken(AToken: AnsiString);
    procedure WriteConfigStoreInfo;
    function ReadConfigTapoIP(ATeeboxNo: Integer): String;
    function ReadConfigTapoIP_R(ARoomNo: Integer): String;
    function ReadConfigTapoMAC(ATeeboxNo: Integer): String;
    function ReadConfigTapoMAC_R(ARoomNo: Integer): String;

    procedure WriteConfigAgentIP_R(ANo: Integer; AIP: String);
    procedure WriteConfigAgentIP_L(ANo: Integer; AIP: String);
    function ReadConfigAgentIP_R(ANo: Integer): String;
    function ReadConfigAgentIP_L(ANo: Integer): String;

    procedure WriteConfigAgentMAC_R(ANo: Integer; AMAC: String);
    procedure WriteConfigAgentMAC_L(ANo: Integer; AMAC: String);
    function ReadConfigAgentMAC_R(ANo: Integer): String;
    function ReadConfigAgentMAC_L(ANo: Integer): String;

    function ReadConfigBeamType(ANo: Integer): String;
    function ReadConfigBeamIP(ANo: Integer): String;
    function ReadConfigBeamPW(ANo: Integer): String;

    procedure SetKioskInfo(ADeviceNo, AUserId: String);
    procedure SetKioskPrint(ADeviceNo, AUserId, AError: String);
    procedure SetConfigDebug(AStr: String);

    function SetADConfigEmergency(AMode, AUserId: String): Boolean;

    procedure TeeboxThreadTimeCheck; //DB, 예약번호 초기화등
    procedure TeeboxControlTimeCheck;

    procedure SetStoreInfoClose(AClose: String);

    procedure WriteConfigBall(ATeeboxNo: Integer);
    procedure WriteConfigBallBackDelay(ADelay: Integer);
    function ReadConfigBallBackStartTime: String;

    procedure ReSetXGM;
    procedure SetWOLUnusedDt(ADt: String);

    property XGolfDM: TXGolfDM read FXGolfDM write FXGolfDM;

    property AppName: string read FAppName write FAppName;
    property HomeDir: string read FHomeDir write FHomeDir;
    property ConfigDir: string read FConfigDir write FConfigDir;
    property Config: TIniFile read FConfig write FConfig;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;
    property ConfigBall: TIniFile read FConfigBall write FConfigBall;
    property ConfigBallFileName: string read FConfigBallFileName write FConfigBallFileName;
    property ConfigAgent: TIniFile read FConfigAgent write FConfigAgent;
    property ConfigAgentFileName: string read FConfigAgentFileName write FConfigAgentFileName;

    property TeeboxThreadTime: TDateTime read FTeeboxThreadTime write FTeeboxThreadTime;
    property TeeboxThreadError: String read FTeeboxThreadError write FTeeboxThreadError;
    property TeeboxControlTime: TDateTime read FTeeboxControlTime write FTeeboxControlTime;
    property TeeboxControlError: String read FTeeboxControlError write FTeeboxControlError;

    property ReserveDBWrite: Boolean read FReserveDBWrite write FReserveDBWrite;

    property SendACSTeeboxError: TDateTime read FSendACSTeeboxError write FSendACSTeeboxError;

    property TapoCtrlLock: Boolean read FTapoCtrlLock write FTapoCtrlLock;

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
  FConfigFileName := FConfigDir + 'Xtouch_in.config';
  ForceDirectories(FConfigDir);
  FConfig := TIniFile.Create(FConfigFileName);
  if not FileExists(FConfigFileName) then
  begin
    WriteFile(FConfigFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigFileName, '');
  end;

  FConfigBallFileName := FConfigDir + 'XtouchBall_v3.config';
  FConfigBall := TIniFile.Create(FConfigBallFileName);
  if not FileExists(FConfigBallFileName) then
  begin
    WriteFile(FConfigBallFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigBallFileName, '');

    FConfigBall.WriteString('BallBack', 'Start', '');
  end;

  FConfigAgentFileName := FConfigDir + 'XtouchAgent_in.config';
  FConfigAgent := TIniFile.Create(FConfigAgentFileName);
  if not FileExists(FConfigAgentFileName) then
  begin
    WriteFile(FConfigAgentFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigAgentFileName, '');

    FConfigAgent.WriteString('Agent_1', 'TeeboxNo', '');
  end;

  CheckConfig;
  ReadConfig; //파트너센터 접속정보

  FTeeboxThreadTime := Now;

  FDebugSeatStatus := '0';
  FTeeboxThreadChk := 0;
  FTeeboxControlChk := 0;
  FReserveDBWrite := False;
end;

destructor TGlobal.Destroy;
begin
  StopDown;

  XGolfDM.Free;
  FTcpServer.Free;
  FTcpAgentServer.Free;
  Api.Free;

  if FADConfig.StoreType = 0 then
  begin
    Teebox.Free;
    ReserveList.Free;
  end
  else if FADConfig.StoreType = 1 then
  begin
    Room.Free;
  end;

  //ini 파일
  FConfig.Free;
  FConfigBall.Free;
  FConfigAgent.Free;

  {$IFDEF RELEASE}
  if Global.ADConfig.TapoUse = True then
    Tapo.Free;
  {$ENDIF}

  Log.Free;

  inherited;
end;

function TGlobal.StartUp: Boolean;
var
  sResult: String;
  sToken: AnsiString;
  sStr: String;
begin
  Result := False;

  Log := TLog.Create;
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

  if FADConfig.StoreType = 0 then
  begin
    Teebox := TTeebox.Create; //타석기정보
    ReserveList := TTeeboxReserveList.Create; //타석기 예약목록
    TeeboxThread := TTeeboxThread.Create; //타석기 예약정보관리
  end
  else if FADConfig.StoreType = 1 then
  begin
    Room := TRoom.Create;
    RoomThread := TRoomThread.Create;
  end;

  {$IFDEF RELEASE}
  if Global.ADConfig.TapoUse = True then
    Tapo := TTapo.create;
  {$ENDIF}

  FTcpAgentServer := TTcpAgentServer.Create;

  if FADConfig.StoreType = 0 then //실내
  begin
    Teebox.StartUp;
    TeeboxThread.Resume;
  end
  else if FADConfig.StoreType = 1 then //스튜디오, 실내외 동일매장으로 추가시
  begin
    Room.StartUp;
    Room.StartReserve;
    RoomThread.Resume;
  end;

  Result := True;
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

  if RoomThread <> nil then
  begin
    RoomThread.Terminate;
    RoomThread.WaitFor;
    RoomThread.Free;
  end;

  Result := True;
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

        Log.LogReserveWrite('Token ' + sResult);
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

  STime, ETime, WOLTimeTemp, WOLTimeTemp1: TDateTime;
  nNN, nHH: integer;
  sNN, sWOLTm: String;
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
    //FStore.UseRewardYn := jSubObj.GetValue('use_reward_yn').Value;
    FStore.StoreChgDate := jSubObj.GetValue('chg_date').Value;
    FStore.ACS := jSubObj.GetValue('acs_use_yn').Value;

    FStore.WOLTime := '';
    if Global.ADConfig.AgentWOL = True then
    begin
      sWOLTm := formatdatetime('YYYY-MM-DD', Now) + ' ' + FStore.StartTime + ':59';
      WOLTimeTemp := DateStrToDateTime2(sWOLTm); //YYYY-MM-DD hh:nn:ss 형식
      WOLTimeTemp1 := IncMinute(WOLTimeTemp, -10);
      FStore.WOLTime := formatdatetime('hh:nn', WOLTimeTemp1);
    end;

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

  jObj, jSubObj, jArrSubObj: TJSONObject;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog: String;

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

procedure TGlobal.CheckConfig;
begin

  if not FConfig.SectionExists('Partners') then
  begin
    FConfig.WriteString('Partners', 'StoreCode', '');
    //FConfig.WriteString('ADInfo', 'ADToken', '');
    FConfig.WriteString('Partners', 'UserId', '');
    FConfig.WriteString('Partners', 'UserPw', '');

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('TAPO') then
  begin
    FConfig.WriteString('TAPO', 'Host', '');
    FConfig.WriteString('TAPO', 'Email', '');
    FConfig.WriteString('TAPO', 'Pw', '');

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('ADInfo') then
  begin
    FConfig.WriteInteger('ADInfo', 'TcpPort', 3308);
    FConfig.WriteInteger('ADInfo', 'DBPort', 3306);
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
  //FADConfig.ADToken := FConfig.ReadString('ADInfo', 'ADToken', '');
  FADConfig.ApiUrl := FConfig.ReadString('Partners', 'Url', '');
  FADConfig.UserId := FConfig.ReadString('Partners', 'UserId', '');
  //FADConfig.UserPw := FConfig.ReadString('Partners', 'UserPw', '');
  sStr := FConfig.ReadString('Partners', 'UserPw', '');
  FADConfig.UserPw := StrDecrypt(Trim(sStr));

  FADConfig.IPV4_C_Class := FConfig.ReadString('TAPO', 'IPV4_C_Class', '');
  FADConfig.TapoHost := FConfig.ReadString('TAPO', 'Host', '');
  FADConfig.TapoEmail := FConfig.ReadString('TAPO', 'Email', '');
  //FADConfig.TapoPwd := FConfig.ReadString('TAPO', 'Pw', '');
  sStr := FConfig.ReadString('TAPO', 'Pw', '');
  FADConfig.TapoPwd := StrDecrypt(Trim(sStr));

  FADConfig.StoreType := FConfig.ReadInteger('ADInfo', 'StoreType', 0);  //  0: 실내, 1: 스튜디오(실내외 동일매장으로 추가시)
  FADConfig.TcpPort := FConfig.ReadInteger('ADInfo', 'TcpPort', 3308);

  FADConfig.TapoUse := FConfig.ReadString('ADInfo', 'TapoUse', 'N') = 'Y';

  FADConfig.AgentUse := FConfig.ReadString('ADInfo', 'AgentUse', 'N') = 'Y';
  FADConfig.AgentSendUse := FConfig.ReadString('ADInfo', 'AgentSendUse', 'N') = 'Y';
  FADConfig.AgentTcpPort := FConfig.ReadInteger('ADInfo', 'AgentTcpPort', 9900);
  FADConfig.AgentSendPort := FConfig.ReadInteger('ADInfo', 'AgentSendPort', 9901);
  FADConfig.AgentWOL := FConfig.ReadString('ADInfo', 'AgentWOL', 'N') = 'Y';
  //FADConfig.TapoStatus := FConfig.ReadString('ADInfo', 'TapoStatus', 'N') = 'Y';

  {$IFDEF RELEASE}
  FADConfig.DBPort := FConfig.ReadInteger('ADInfo', 'DBPort', 3306);
  FADConfig.XGM_VXUse := FConfig.ReadString('ADInfo', 'XGM_VXUse', 'N');
  FADConfig.XGM_TapoUse := FConfig.ReadString('ADInfo', 'XGM_TapoUse', 'N');
  FADConfig.BeamProjectorUse := FConfig.ReadString('ADInfo', 'BeamProjectorUse', 'N') = 'Y';
  {$ENDIF}
  {$IFDEF DEBUG}
  FADConfig.DBPort := 3306;
  FADConfig.XGM_VXUse := 'N';
  FADConfig.XGM_TapoUse := 'N';
  FADConfig.BeamProjectorUse := True;
  {$ENDIF}

  FADConfig.PrepareUse := FConfig.ReadString('ADInfo', 'PrepareUse', 'Y');

  FADConfig.SystemInstall := FConfig.ReadString('ADInfo', 'SystemInstall', '0');

  FADConfig.ErrorSms := FConfig.ReadString('ADInfo', 'ErrorSms', 'N'); //2020-11-05 기기고장 1분유지시 문자발송여부
  FADConfig.Emergency := FConfig.ReadString('ADInfo', 'Emergency', 'N') = 'Y'; //긴급배정모드

  if FADConfig.Emergency = True then
    MainForm.pnlEmergency.Color := clRed
  else
    MainForm.pnlEmergency.Color := clBtnFace;

  FADConfig.CheckInUse := FConfig.ReadString('ADInfo', 'CheckInUse', 'N'); //체크인 사용여부

  FTapoCtrlLock := FConfig.ReadString('ADInfo', 'TapoCtrlLock', 'N') = 'Y';
  if FTapoCtrlLock = True then
    MainForm.btnCtrlLock.Caption := '제어해제'
  else
    MainForm.btnCtrlLock.Caption := '제어잠금';

  FStore.StartTime := FConfig.ReadString('Store', 'StartTime', '05:00');
  FStore.EndTime := FConfig.ReadString('Store', 'EndTime', '23:00');
  //FStore.UseRewardYn := FConfig.ReadString('Store', 'UseRewardYn', 'Y');
  FStore.WOLTime := FConfig.ReadString('Store', 'WOLTime', '04:50');

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
  FConfig.WriteString('Store', 'WOLTime', FStore.WOLTime);
  //FConfig.WriteString('Store', 'UseRewardYn', FStore.UseRewardYn);
  FConfig.WriteString('Store', 'ACS', FStore.ACS);
  FConfig.WriteString('Store', 'ACS_1_YN', FStore.ACS_1_Yn);
  FConfig.WriteString('Store', 'ACS_1_HP', FStore.ACS_1_Hp);
  FConfig.WriteString('Store', 'ACS_2_YN', FStore.ACS_2_Yn);
  FConfig.WriteString('Store', 'ACS_3_YN', FStore.ACS_3_Yn);
  FConfig.WriteString('Store', 'ACS_1', IntToStr(FStore.ACS_1));
  FConfig.WriteString('Store', 'ACS_2', IntToStr(FStore.ACS_2));
  FConfig.WriteString('Store', 'ACS_3', IntToStr(FStore.ACS_3));
end;

function TGlobal.ReadConfigTapoIP(ATeeboxNo: Integer): String;
begin
  Result := FConfig.ReadString('TAPO', 'IP' + IntToStr(ATeeboxNo), '');
end;

function TGlobal.ReadConfigTapoIP_R(ARoomNo: Integer): String;
begin
  Result := FConfig.ReadString('TAPO', 'IP' + IntToStr(ARoomNo), '');
end;

function TGlobal.ReadConfigTapoMAC(ATeeboxNo: Integer): String;
begin
  Result := FConfig.ReadString('TAPO', 'MAC' + IntToStr(ATeeboxNo), '');
end;

function TGlobal.ReadConfigTapoMAC_R(ARoomNo: Integer): String;
begin
  Result := FConfig.ReadString('TAPO', 'MAC' + IntToStr(ARoomNo), '');
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

procedure TGlobal.WriteConfigAgentMAC_R(ANo: Integer; AMAC: String);
begin
  FConfig.WriteString('AGENT', 'R_MAC_' + IntToStr(ANo), AMAC);
end;

procedure TGlobal.WriteConfigAgentMAC_L(ANo: Integer; AMAC: String);
begin
  FConfig.WriteString('AGENT', 'L_MAC_' + IntToStr(ANo), AMAC);
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
  end
  else
  begin
    if GetErpOauth2 = False then
      Exit;

    FADConfig.Emergency := False;
    MainForm.pnlEmergency.Color := clBtnFace;
  end;

  FConfig.WriteString('ADInfo', 'Emergency', AMode);

  Result := True;
end;

procedure TGlobal.SetConfigDebug(AStr: String);
begin
  FConfig.WriteString('ADInfo', 'Debug', AStr);
end;

procedure TGlobal.TeeboxThreadTimeCheck;
var
  sPtime, sNtime, sLogMsg, sPWOLtime, sNWOLtime: String;
begin
  sPtime := FormatDateTime('YYYYMMDDHH', TeeboxThreadTime);
  sNtime := FormatDateTime('YYYYMMDDHH', Now);

  if ADConfig.AgentWOL = True then
  begin
    sPWOLtime := FormatDateTime('HH:NN', TeeboxThreadTime);
    sNWOLtime := FormatDateTime('HH:NN', Now);

    if sPWOLtime <> sNWOLtime then
    begin
      if sNWOLtime = Store.WOLTime then
      begin
        if Store.WOLUnusedDt = FormatDateTime('YYYY-MM-DD', Now) then
        begin
          Log.LogCtrlWrite('휴장설정 - WOL 미사용');
          MainForm.btnCheckWOL.Click;
        end
        else
        begin
          if FADConfig.StoreType = 0 then
          begin
            Teebox.SendAgentWOL;
            sleep(1000);
            Teebox.SendAgentWOL;
            sleep(1000);
            Teebox.SendAgentWOL;
          end;
          //else if FADConfig.StoreType = 1 then
            //Global.Room.SendAgentWOL;
        end;
      end;
    end;
  end;

  if sPtime <> sNtime then
  begin
    sLogMsg := 'TSeatThread TimeCheck !!';
    Log.LogWrite(sLogMsg);

    if Copy(sNtime, 9, 2) = '00' then
    begin
      //2020-10-09 재부팅 제외로 seqno 초기화
      TcpServer.UseSeqNo := 0;
      TcpServer.LastUseSeqNo := TcpServer.UseSeqNo;
      TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now);
    end;

    if Copy(sNtime, 9, 2) = '04' then
    begin
      DeleteDBReserve;

      GetStoreInfoToApi;

      //2020-10-09 재부팅 제외로 seqno 초기화
      //TcpServer.UseSeqNo := 0;
      //TcpServer.LastUseSeqNo := TcpServer.UseSeqNo;
      //TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now);

      //2020-11-04 DB재연결
      Global.XGolfDM.ReConnection;

      FReserveDBWrite := False;
    end;

    //2020-12-04 양평08시 이후 첫배정되는 경우 있음.
    if Copy(sNtime, 9, 2) = '05' then
    begin
      GetStoreInfoToApi;

      Global.XGolfDM.ReConnection;

      ReSetXGM;

      FReserveDBWrite := False;
    end;

    //공사등으로 인한 오후 오픈인 경우 발생-양평01.31
    if (Copy(sNtime, 9, 2) = '09') or (Copy(sNtime, 9, 2) = '12') or (Copy(sNtime, 9, 2) = '15') or (Copy(sNtime, 9, 2) = '18') then
    begin
      if FReserveDBWrite = False then
      begin
        Global.XGolfDM.ReConnection;
      end
      else
      begin
        FReserveDBWrite := False;
        Global.Log.LogWrite('FReserveDBWrite -> False');
      end;
    end;
    {
    if Copy(sNtime, 9, 2) = '18' then
    begin
      if FReserveDBWrite = False then
      begin
        Global.XGolfDM.ReConnection;
      end;
    end;
    }
  end;

  TeeboxThreadTime := Now;
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
      //WriteLogDayFile(Global.LogFileName, sLog);
      log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    sLog := 'K802_SendAcs : ' + sResultCd + ' / ' + sResultMsg;
    //WriteLogDayFile(Global.LogFileName, sLog);
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

procedure TGlobal.WriteConfigBall(ATeeboxNo: Integer);
var
  sLog: String;
begin
  if ATeeboxNo = 0 then
  begin
    FConfigBall.WriteString('BallBack', 'Start', FormatDateTime('YYYY-MM-DD hh:nn:ss', now));
    FConfigBall.WriteInteger('BallBack', 'Delay', 0);

    sLog := '볼회수 WriteConfigBall';
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

procedure TGlobal.SetWOLUnusedDt(ADt: String);
begin
  FStore.WOLUnusedDt := ADt;
  if ADt = '' then
    Log.LogWrite('WOL 사용설정 - 해제')
  else
    Log.LogWrite('WOL 사용설정 - ' + ADt);
end;

end.
