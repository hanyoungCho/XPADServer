unit uGlobal;

interface

uses
  Winapi.Windows, IniFiles, CPort, System.DateUtils, System.Classes, ShellAPI,
  uTeeboxInfo, uTeeboxReserveList, uTeeboxThread, uConsts, uFunction, uStruct, uErpApi,
  uXGClientDM, uXGServer, uXGAgentServer, uLogging, uTapo;

type
  TGlobal = class

  private
    FStore: TStoreInfo;
    FADConfig: TADConfig;
    FLog: TLog;

    FTeebox: TTeebox;
    FReserveList: TTeeboxReserveList;
    FApi: TApiServer;

    FXGolfDM: TXGolfDM;
    FTcpServer: TTcpServer;
    FTcpAgentServer: TTcpAgentServer;
    FTeeboxThread: TTeeboxThread;
    FTapo: TTapo;

    FAppName: string;
    FHomeDir: string;
    FConfig: TIniFile;
    FConfigFileName: string;
    FConfigAgent: TIniFile;
    FConfigAgentFileName: string;
    FConfigDir: string;

    FTeeboxThreadTime: TDateTime;
    FTeeboxThreadError: String;
    FTeeboxControlTime: TDateTime;
    FDebugSeatStatus: String;
    FReserveDBWrite: Boolean; //DB 재연결 확인용

    procedure CheckConfig;
    procedure ReadConfig;
  public
    constructor Create;
    destructor Destroy; override;

    function StartUp: Boolean;
    function StopDown: Boolean;

    procedure SetConfig(const ASection, AItem: string; const ANewValue: Variant);

    function GetStoreInfoToApi: Boolean;
    function GetConfigInfoToApi: Boolean;

    function ReadConfigBeamType(ANo: Integer): String;
    function ReadConfigBeamIP(ANo: Integer): String;
    function ReadConfigBeamPW(ANo: Integer): String;

    function ReadConfigAgentSetting(ATeeboxNo: String): String;

    procedure WriteConfigAgentIP_R(ANo: Integer; AIP: String);
    procedure WriteConfigAgentIP_L(ANo: Integer; AIP: String);
    function ReadConfigAgentIP_R(ANo: Integer): String;
    function ReadConfigAgentIP_L(ANo: Integer): String;

    procedure DeleteDBReserve;

    property Store: TStoreInfo read FStore write FStore;
    property Teebox: TTeebox read FTeebox write FTeebox;
    property ReserveList: TTeeboxReserveList read FReserveList write FReserveList;
    property TeeboxThread: TTeeboxThread read FTeeboxThread write FTeeboxThread;
    property Api: TApiServer read FApi write FApi;
    property ADConfig: TADConfig read FADConfig write FADConfig;
    property ConfigAgent: TIniFile read FConfigAgent write FConfigAgent;
    property ConfigAgentFileName: string read FConfigAgentFileName write FConfigAgentFileName;
    property TcpServer: TTcpServer read FTcpServer write FTcpServer;
    property TcpAgentServer: TTcpAgentServer read FTcpAgentServer write FTcpAgentServer;
    property Tapo: TTapo read FTapo write FTapo;
    property Log: TLog read FLog write FLog;

    procedure DebugLogViewWrite(ALog: string);

    procedure SetStoreInfo(AStoreNm, AStartTime, AEndTime, AStoreChgDate: String);

    procedure TeeboxThreadTimeCheck; //DB, 예약번호 초기화등

    procedure ReSetXGM;

    property XGolfDM: TXGolfDM read FXGolfDM write FXGolfDM;

    property AppName: string read FAppName write FAppName;
    property HomeDir: string read FHomeDir write FHomeDir;
    property ConfigDir: string read FConfigDir write FConfigDir;
    property Config: TIniFile read FConfig write FConfig;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;

    property TeeboxThreadTime: TDateTime read FTeeboxThreadTime write FTeeboxThreadTime;
    property TeeboxThreadError: String read FTeeboxThreadError write FTeeboxThreadError;
    property TeeboxControlTime: TDateTime read FTeeboxControlTime write FTeeboxControlTime;
    property ReserveDBWrite: Boolean read FReserveDBWrite write FReserveDBWrite;
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
  FConfigFileName := FConfigDir + 'Xtouch_EL.config';
  ForceDirectories(FConfigDir);
  FConfig := TIniFile.Create(FConfigFileName);
  if not FileExists(FConfigFileName) then
  begin
    WriteFile(FConfigFileName, ';***** Xtouch Congiguration file *****');
    WriteFile(FConfigFileName, '');
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
  FReserveDBWrite := False;
end;

destructor TGlobal.Destroy;
begin
  StopDown;

  XGolfDM.Free;
  FTcpServer.Free;

  Api.Free;
  Teebox.Free;
  ReserveList.Free; //타석기 예약목록

  //ini 파일
  FConfig.Free;
  FConfigAgent.Free;

  Log.Free;

  FTcpAgentServer.Free;

  if ADConfig.TapoUse = True then
    Tapo.Free;

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
  FTcpAgentServer := TTcpAgentServer.Create;

  Api := TApiServer.Create;

  //환경설정
  {
  if GetConfigInfoToApi = False then
    Exit;
  }
  ReadConfig; //파트너센터 정보 다시 읽기

  if GetStoreInfoToApi = False then
    Exit;

  XGolfDM := TXGolfDM.Create(Nil);

  DeleteDBReserve; //배정내역 삭제

  Teebox := TTeebox.Create; //타석기정보
  ReserveList := TTeeboxReserveList.Create; //타석기 예약목록
  TeeboxThread := TTeeboxThread.Create; //타석기 예약정보관리

  if ADConfig.TapoUse = True then
    Tapo := TTapo.create;

  Teebox.StartUp;
  TeeboxThread.Resume;

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

  Result := True;
end;

function TGlobal.GetStoreInfoToApi: Boolean;
var
  sResult, sResultCd, sResultMsg, sLog, sStoreChgDate: String;
  sStoreNm, sStartTime, sEndTime, sServerTime: String;
  dSvrTime: TDateTime;

  jObj, jSubObj: TJSONObject;
  sJsonStr: AnsiString;
begin
  Result := False;
  Log.LogWrite('Store Info Reset!!');

  try

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode + '&search_date=' + FormatDateTime('YYYYMMDDHHNNSS', Now);
    sResult := Global.Api.GetErpApi(sJsonStr, 'K203_StoreInfo', Global.ADConfig.ApiUrl);
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
    sStoreChgDate := jSubObj.GetValue('chg_date').Value;
    sServerTime := jSubObj.GetValue('server_time').Value;

    if sStartTime = 'null' then
      sStartTime := '06:00';
    if sEndTime = 'null' then
      sEndTime := '23:00';

    SetStoreInfo(sStoreNm, sStartTime, sEndTime, sStoreChgDate);

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
      {
      //데이타 확인필요
      if SetSystemTimeChange(dSvrTime) = False then
      begin
        sLog := 'server_time LocalPc Set Error !!';
        WriteLogDayFile(Log.LogFileName, sLog);
      end;
      }
    end
    else
    begin
      sLog := 'server_time length 14 error !!';
      WriteLogDayFile(Log.LogFileName, sLog);
    end;

    Result := True;
  finally
    FreeAndNil(jObj);
  end;

end;

function TGlobal.GetConfigInfoToApi: Boolean;
var
  sResult: String;

  jObj: TJSONObject;
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

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode + '&client_id=' + Global.ADConfig.UserId + '&search_date=' + FormatDateTime('YYYYMMDDHHNNSS', Now);
    sResult := Global.Api.GetErpApi(sJsonStr, 'K202_ConfiglistNew', Global.ADConfig.ApiUrl);
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

procedure TGlobal.CheckConfig;
begin

  if not FConfig.SectionExists('Partners') then
  begin
    FConfig.WriteString('Partners', 'StoreCode', '');
    FConfig.WriteString('Partners', 'UserId', '');
    //FConfig.WriteString('Partners', 'UserPw', '');
    FConfig.WriteString('Partners', 'Url', '');

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('TAPO') then
  begin
    FConfig.WriteString('TAPO', 'Host', '');
    //FConfig.WriteString('TAPO', 'Email', '');
    //FConfig.WriteString('TAPO', 'Pw', '');

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('ADInfo') then
  begin
    FConfig.WriteInteger('ADInfo', 'TcpPort', 3308);
    FConfig.WriteInteger('ADInfo', 'AgentTcpPort', 3309);
    FConfig.WriteInteger('ADInfo', 'DBPort', 3306);

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('Store') then
  begin
    FConfig.WriteString('Store', 'StartTime', '06:00');
    FConfig.WriteString('Store', 'EndTime', '23:00');

    WriteFile(FConfigFileName, '');
  end;

end;

procedure TGlobal.ReadConfig;
begin

  FADConfig.StoreCode := FConfig.ReadString('Partners', 'StoreCode', '');
  FADConfig.UserId := FConfig.ReadString('Partners', 'UserId', '');
  //FADConfig.UserPw := FConfig.ReadString('Partners', 'UserPw', '');
  FADConfig.ApiUrl := FConfig.ReadString('Partners', 'Url', '');

  FADConfig.TapoHost := FConfig.ReadString('TAPO', 'Host', '');

  if FADConfig.StoreCode = 'E0001' then //이룸골프 잠실점
  begin
    FADConfig.TapoEmail := 'xparaa1@gmail.com';
    FADConfig.TapoPwd := 'xpargolf1!';
  end
  else if FADConfig.StoreCode = 'E0008' then //이룸골프 동탄라크몽
  begin
    FADConfig.TapoEmail := 'eloom0001@gmail.com';
    FADConfig.TapoPwd := 'eloomgolf1#';
  end
  else if FADConfig.StoreCode = 'E0009' then //강남
  begin
    FADConfig.TapoEmail := 'xpar0008@gmail.com';
    FADConfig.TapoPwd := 'xpartners12';
  end
  else if FADConfig.StoreCode = 'E0011' then //구리갈매센터
  begin
    FADConfig.TapoEmail := '';
    FADConfig.TapoPwd := '';
  end
  else
  begin
    //FADConfig.TapoEmail := FConfig.ReadString('TAPO', 'Email', '');
    FADConfig.TapoEmail := 'xpar0003@gmail.com';
    //FADConfig.TapoPwd := FConfig.ReadString('TAPO', 'Pw', '');
    FADConfig.TapoPwd := 'xpartners3#';
  end;
  FADConfig.IPV4_C_Class := FConfig.ReadString('TAPO', 'IPV4_C_Class', '');

  FADConfig.TcpPort := FConfig.ReadInteger('ADInfo', 'TcpPort', 3308);
  FADConfig.AgentTcpPort := FConfig.ReadInteger('ADInfo', 'AgentTcpPort', 9900);
  FADConfig.AgentSendPort := FConfig.ReadInteger('ADInfo', 'AgentSendPort', 9901);
  FADConfig.AgentSendUse := FConfig.ReadString('ADInfo', 'AgentSendUse', 'N');
  {$IFDEF RELEASE}
  FADConfig.DBPort := FConfig.ReadInteger('ADInfo', 'DBPort', 3306);
  {$ENDIF}
  {$IFDEF DEBUG}
  FADConfig.DBPort := 3306;
  {$ENDIF}

  FADConfig.TapoUse := FConfig.ReadString('ADInfo', 'TapoUse', 'N') = 'Y';

  {$IFDEF RELEASE}
  FADConfig.VXUse := FConfig.ReadString('ADInfo', 'VXUse', 'N');
  FADConfig.XGMTapoUse := FConfig.ReadString('ADInfo', 'XGMTapoUse', 'N');
  FADConfig.BeamProjectorUse := FConfig.ReadString('ADInfo', 'BeamProjectorUse', 'N') = 'Y';
  {$ENDIF}
  {$IFDEF DEBUG}
  FADConfig.VXUse := 'N';
  FADConfig.XGMTapoUse := 'N';
  FADConfig.BeamProjectorUse := True;
  {$ENDIF}

  FStore.StartTime := FConfig.ReadString('Store', 'StartTime', '05:00');
  FStore.EndTime := FConfig.ReadString('Store', 'EndTime', '23:00');

  //FStore.Close := 'Y';
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

function TGlobal.ReadConfigAgentSetting(ATeeboxNo: String): String;
var
  IL: TStringList;
  J: Integer;
  jObj: TJSONObject;
  sSection, sData: String;
begin

  try

    IL := TStringList.Create;
    jObj := TJSONObject.Create;
    sSection := 'Agent_' + ATeeboxNo;
    FConfigAgent.ReadSection(sSection, IL);

    for J := 0 to Pred(IL.Count) do
    begin
      sData := FConfig.ReadString(sSection, IL[J], '');
      jObj.AddPair(TJSONPair.Create(IL[J], sData));
    end;

    Result := jObj.ToString;
  finally
    FreeAndNil(jObj);
    FreeAndNil(IL);
  end;

end;

procedure TGlobal.SetStoreInfo(AStoreNm, AStartTime, AEndTime, AStoreChgDate: String);
begin
  FStore.StoreNm := AStoreNm;

  FStore.StartTime := AStartTime;
  FStore.EndTime := AEndTime;

  FStore.StoreLastTM := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now); //2019-09-18 10:28:28
  FStore.StoreChgDate := AStoreChgDate;

  FConfig.WriteString('Store', 'StoreNm', FStore.StoreNm);
  FConfig.WriteString('Store', 'StartTime', FStore.StartTime);
  FConfig.WriteString('Store', 'EndTime', FStore.EndTime);
end;

procedure TGlobal.TeeboxThreadTimeCheck;
var
  sPtime, sNtime, sLogMsg: String;
begin
  sPtime := FormatDateTime('YYYYMMDDHH', TeeboxThreadTime);
  sNtime := FormatDateTime('YYYYMMDDHH', Now);

  if sPtime <> sNtime then
  begin
    sLogMsg := 'TSeatThread TimeCheck !!';
    Log.LogWrite(sLogMsg);

    //2021-05-03 유명
    if Copy(sNtime, 9, 2) = '04' then  //02 2021-06-01 유명 3시까지 연장영업
    begin
      DeleteDBReserve;

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
      ReSetXGM;

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

  end;

  TeeboxThreadTime := Now;
end;

procedure TGlobal.DebugLogViewWrite(ALog: string);
begin
  //FCtrlBufferTemp := ALog;
  MainForm.LogView(ALog);
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

procedure TGlobal.ReSetXGM;
begin
  ShellExecute(MainForm.FApplicationHandle, 'open', PChar(HomeDir + 'exit.vbs'), nil, nil, SW_SHOW);
  Log.LogWrite('run_app 종료');

  while True do
  begin
    if IsRunningProcess('run_app.exe') then
    begin
      //Log.LogWrite('run_app 구동중')
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

end.
