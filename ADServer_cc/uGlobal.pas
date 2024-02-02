unit uGlobal;

interface

uses
  IniFiles, CPort,
  uTeeboxInfo, uTeeboxThread, uConsts, uFunction, uStruct, uErpApi,
  uComZoomCC,
  uXGClientDM, uXGServer, uLogging;

type
  TGlobal = class
  private
    FStore: TStoreInfo;
    FADConfig: TADConfig;
    FLog: TLog;

    FTeebox: TSeat;
    FApi: TApiServer;

    FXGolfDM: TXGolfDM;
    FTcpServer: TTcpServer;

    FTeeboxThread: TTeeboxThread;
    FComZoomCC: TComThreadZoomCC;

    FAppName: string;
    FHomeDir: string;
    FConfig: TIniFile;
    FConfigFileName: string;
    FConfigBall: TIniFile;
    FConfigBallFileName: string;

    FConfigDir: string;

    FSeatThreadTime: TDateTime;
    FSeatThreadTimePre: TDateTime;
    //FSeatThreadError: String;
    FSeatThreadChk: Integer;
    //FSeatControlTime: TDateTime;
    //FSeatControlTimePre: TDateTime;
    //FSeatControlError: String;
    //FSeatControlChk: Integer;

    //FDebugSeatStatus: String;

    FCtrlBufferTemp: String;

    FReserveDBWrite: Boolean; //DB 재연결 확인용

    procedure CheckConfig;
    procedure ReadConfig;
  public
    constructor Create;
    destructor Destroy; override;

    function StartUp: Boolean;
    function StopDown: Boolean;

    function GetErpOauth2: Boolean;
    function GetStoreInfoToApi: Boolean;

    procedure DeleteDBReserve;

    property Store: TStoreInfo read FStore write FStore;
    property Teebox: TSeat read FTeebox write FTeebox;
    property TeeboxThread: TTeeboxThread read FTeeboxThread write FTeeboxThread;
    property Api: TApiServer read FApi write FApi;
    property ADConfig: TADConfig read FADConfig write FADConfig;
    property TcpServer: TTcpServer read FTcpServer write FTcpServer;
    property Log: TLog read FLog write FLog;

    procedure DebugLogViewWrite(ALog: string);
    procedure DebugLogViewApiWrite(ALog: string);

    procedure SetADConfigToken(AToken: AnsiString);
    procedure SetStoreInfo(AStoreNm, AStartTime, AEndTime, AUseRewardYn, AStoreChgDate: String);

    procedure CheckConfigBall(ASeatNo: Integer);
    procedure SeatThreadTimeCheck;
    procedure SetStoreInfoClose(AClose: String);
    procedure SetStoreEndDBTime(AClose: String);

    procedure StartComPortThread;
    procedure StopComPortThread;

    procedure CtrlSendBuffer(ASeatNo: Integer; ADeviceId, ASeatTime, ASeatBall, AType: String);

    function ReadConfigBallBackStartTime: String;

    property XGolfDM: TXGolfDM read FXGolfDM write FXGolfDM;
    property ComZoomCC: TComThreadZoomCC read FComZoomCC write FComZoomCC;

    property AppName: string read FAppName write FAppName;
    property HomeDir: string read FHomeDir write FHomeDir;
    property ConfigDir: string read FConfigDir write FConfigDir;
    property Config: TIniFile read FConfig write FConfig;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;

    property CtrlBufferTemp: string read FCtrlBufferTemp write FCtrlBufferTemp;

    property SeatThreadTime: TDateTime read FSeatThreadTime write FSeatThreadTime;
    property SeatThreadTimePre: TDateTime read FSeatThreadTimePre write FSeatThreadTimePre;
    //property SeatThreadError: String read FSeatThreadError write FSeatThreadError;
    //property SeatControlTime: TDateTime read FSeatControlTime write FSeatControlTime;
    //property SeatControlTimePre: TDateTime read FSeatControlTimePre write FSeatControlTimePre;
    //property SeatControlError: String read FSeatControlError write FSeatControlError;

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
  FConfigFileName := FConfigDir + 'Xtouch_CC.config';
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

  CheckConfig;
  ReadConfig;

  FSeatThreadTime := Now;

  //FDebugSeatStatus := '0';
  FSeatThreadChk := 0;
  //FSeatControlChk := 0;
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

  if GetErpOauth2 = False then
    Exit;

  XGolfDM := TXGolfDM.Create(Nil);

  if GetStoreInfoToApi = False then
    Exit;

  //최초실행시,재설치시 ERP서버 배정정보 호출
  if FADConfig.SystemInstall <> '1' then
  begin
    if FTcpServer.GetErpTeeboxList = False then
      Exit;

    FConfig.WriteString('ADInfo', 'SystemInstall', '1');
  end;

  Teebox := TSeat.Create; //타석기정보

  TeeboxThread := TTeeboxThread.Create; //타석기 예약정보관리
  ComZoomCC := TComThreadZoomCC.Create;

  Teebox.StartUp;

  TeeboxThread.Resume;
  ComZoomCC.Resume;

  Result := True;
end;

procedure TGlobal.CtrlSendBuffer(ASeatNo: Integer; ADeviceId, ASeatTime, ASeatBall, AType: String);
begin
  ComZoomCC.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType)
end;

function TGlobal.GetStoreInfoToApi: Boolean;
var
  sResult, sStr: String;
  sStoreNm, sStartTime, sEndTime, sUseRewardYn, sServerTime: String;
  dSvrTime: TDateTime;

  jObj, jSubObj: TJSONObject;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog, sStoreChgDate: String;
begin
  Result := False;
  Log.LogWrite('Store Info Reset!!');

  try

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;
    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K203_StoreInfo', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'GetStoreInfoToApi Fail : ' + sResult;
      Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K203_StoreInfo : ' + sResultCd + ' / ' + sResultMsg;
      Log.LogWrite(sLog);
      Exit;
    end;

    jSubObj := jObj.GetValue('result_data') as TJSONObject;

    sStoreNm := jSubObj.GetValue('store_nm').Value;
    sStartTime := jSubObj.GetValue('start_time').Value;
    sEndTime := jSubObj.GetValue('end_time').Value;
    sUseRewardYn := jSubObj.GetValue('use_reward_yn').Value;
    sServerTime := jSubObj.GetValue('server_time').Value;
    sStoreChgDate := jSubObj.GetValue('chg_date').Value;

    SetStoreInfo(sStoreNm, sStartTime, sEndTime, sUseRewardYn, sStoreChgDate);
    sStr := 'StartTime: ' + sStartTime + ' / EndTime: ' + sEndTime + ' / UseRewardYn: ' + sUseRewardYn + ' / ' + sStoreChgDate;
    Log.LogWrite(sStr);

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
        Log.LogWrite(sStr);
      end;
    end
    else
    begin
      sStr := 'server_time length 14 error !!';
      Log.LogWrite(sStr);
    end;

    Result := True;
  finally
    FreeAndNil(jObj);
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

  if ComZoomCC <> nil then
  begin
    ComZoomCC.Terminate;
    ComZoomCC.WaitFor;
    ComZoomCC.Free;
  end;

  Result := True;
end;

procedure TGlobal.StartComPortThread;
begin
  ComZoomCC := TComThreadZoomCC.Create;
  ComZoomCC.Resume;

  //WriteLogDayFile(LogFileName, 'ReStartComPortThread !!!');
  Log.LogWrite('ReStartComPortThread !!!');
end;

procedure TGlobal.StopComPortThread;
begin
  if ComZoomCC <> nil then
  begin
    ComZoomCC.Terminate;
    ComZoomCC.WaitFor;
    ComZoomCC.Free;
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

  Log.Free;

  inherited;
end;

procedure TGlobal.CheckConfig;
begin
  if not FConfig.SectionExists('Partners') then
  begin
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
    FConfig.WriteString('ADInfo', 'SystemInstall', '0');

    WriteFile(FConfigFileName, '');
  end;

  if not FConfig.SectionExists('Store') then
  begin
    FConfig.WriteString('Store', 'ErrorSms', 'N'); //기기고장 1분유지시 문자발송여부

    WriteFile(FConfigFileName, '');
  end;

end;

procedure TGlobal.ReadConfig;
begin
  FADConfig.StoreCode := FConfig.ReadString('Partners', 'StoreCode', '');
  //FADConfig.ADToken := FConfig.ReadString('ADInfo', 'ADToken', '');
  FADConfig.UserId := FConfig.ReadString('Partners', 'UserId', '');
  FADConfig.UserPw := FConfig.ReadString('Partners', 'UserPw', '');
  FADConfig.ApiUrl := FConfig.ReadString('Partners', 'Url', '');

  FADConfig.Port := FConfig.ReadInteger('ADInfo', 'Port', 1);
  FADConfig.Baudrate := FConfig.ReadInteger('ADInfo', 'Baudrate', 9600);

  FADConfig.TcpPort := FConfig.ReadInteger('ADInfo', 'TcpPort', 3308);
  FADConfig.DBPort := FConfig.ReadInteger('ADInfo', 'DBPort', 3306);
  FADConfig.ProtocolType := FConfig.ReadString('ADInfo', 'ProtocolType', 'ZOOM');
  FADConfig.SystemInstall := FConfig.ReadString('ADInfo', 'SystemInstall', '0');

  FStore.ErrorSms := FConfig.ReadString('Store', 'ErrorSms', 'N');
  FStore.StartTime := FConfig.ReadString('Store', 'StartTime', '05:00');
  FStore.EndTime := FConfig.ReadString('Store', 'EndTime', '23:00');
  FStore.UseRewardYn := FConfig.ReadString('Store', 'UseRewardYn', 'Y');

  FStore.Close := 'Y';
end;

procedure TGlobal.CheckConfigBall(ASeatNo: Integer);
begin
  FConfigBall.WriteString('BallBack', 'Start', FormatDateTime('YYYYMMDD hh:nn:ss', now));
end;

//볼회수 시작시간
function TGlobal.ReadConfigBallBackStartTime: String;
begin
  Result := FConfigBall.ReadString('BallBack', 'Start', '');
end;

procedure TGlobal.SetADConfigToken(AToken: AnsiString);
begin
  FADConfig.ADToken := AToken;
  //FConfig.WriteString('ADInfo', 'ADToken', AToken);
end;

procedure TGlobal.SetStoreInfo(AStoreNm, AStartTime, AEndTime, AUseReWardYn, AStoreChgDate: String);
var
  nNN: integer;
begin
  FStore.StoreNm := AStoreNm;

  FStore.StartTime := AStartTime;
  FStore.EndTime := AEndTime;

  FStore.UseRewardYn := AUseReWardYn;
  FStore.StoreLastTM := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now); //2019-09-18 10:28:28
  FStore.StoreChgDate := AStoreChgDate;

  nNN := StrToInt(Copy(FStore.EndTime, 4, 2));
  if (nNN + 10) > 50 then
    FStore.EndDBTime := ''
  else
    FStore.EndDBTime := Copy(FStore.EndTime, 1, 3) + IntToStr(nNN + 10);

  FConfig.WriteString('Store', 'StoreNm', FStore.StoreNm);
  FConfig.WriteString('Store', 'StartTime', FStore.StartTime);
  FConfig.WriteString('Store', 'EndTime', FStore.EndTime);
  FConfig.WriteString('Store', 'UseRewardYn', FStore.UseRewardYn);
end;

procedure TGlobal.SeatThreadTimeCheck;
var
  sPtime, sNtime, sLogMsg: String;
begin
  sPtime := FormatDateTime('YYYYMMDDHH', SeatThreadTime);
  sNtime := FormatDateTime('YYYYMMDDHH', Now);

  if sPtime <> sNtime then
  begin
    sLogMsg := 'TSeatThread TimeCheck !!';
    Log.LogWrite(sLogMsg);

    if Copy(sNtime, 9, 2) = '01' then
    begin
      DeleteDBReserve;

      GetStoreInfoToApi;

      //재부팅 제외로 seqno 초기화
      TcpServer.UseSeqNo := 0;
      TcpServer.LastUseSeqNo := TcpServer.UseSeqNo;

      //DB재연결
      Global.XGolfDM.ReConnection;
      FReserveDBWrite := False;
    end;

    //2020-12-04 양평08시 이후 첫배정되는 경우 있음.
    if Copy(sNtime, 9, 2) = '05' then
    begin
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

  SeatThreadTime := Now;

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

procedure TGlobal.DebugLogViewApiWrite(ALog: string);
begin
  MainForm.edApiResult.Text := ALog;

  if ALog = 'Fail' then
    MainForm.cxTabSheet1.color := clRed
  else
    MainForm.cxTabSheet1.color := clWindow;
end;

procedure TGlobal.DeleteDBReserve;
var
  sDateStr: string;
  bResult: Boolean;
begin
  sDateStr := FormatDateTime('YYYYMMDD', Now - 30);
  bResult := XGolfDM.SeatUseDeleteReserve(ADConfig.StoreCode, sDateStr);

  if bResult = True then
    Log.LogWrite('배정데이터 삭제 완료: ' + sDateStr)
  else
    Log.LogWrite('배정데이터 삭제 실패: ' + sDateStr);

end;

end.
