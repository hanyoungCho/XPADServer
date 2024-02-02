unit uXGAgentServer;

interface

uses
  IdTCPServer, IdContext, System.SysUtils, System.Classes, JSON, Generics.Collections, Windows,
  uStruct, IdComponent;

type
  TTcpAgentServer = class
  private
    FTcpServer: TIdTCPServer;
    FClientCount: Integer;

    FCS: TRTLCriticalSection;

    F9004List: TStringList;

    procedure AddLog(const AMessage: string);
    procedure ReadAddLog(const AMessage: string);
    procedure ShowClientCount(const ADisconnected: Boolean=False);

    procedure TCPServerOnConnect(AContext: TIdContext);
    procedure TCPServerOnDisconnect(AContext: TIdContext);
    procedure TCPServerOnException(AContext: TIdContext; AException: Exception);
    procedure TCPServerOnExecute(AContext: TIdContext);
    procedure TCPServerOnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);

  public
    constructor Create;
    destructor Destroy; override;

    procedure BroadcastMessage(const AMessage: string);
    procedure SendTeeboxStatus;

    function SendDataCreat(AReceiveData: AnsiString): AnsiString;
    function AgentResponse: AnsiString;
    function GetAgentSetting(AReceiveData: AnsiString): AnsiString;
    function SetAgentSetting(AReceiveData: AnsiString): AnsiString;
    function GetTeeboxStatus(ATeeboxNo: String): AnsiString;

    property TcpServer: TIdTCPServer read FTcpServer write FTcpServer;
    property ClientCount: Integer read FClientCount write FClientCount;
  end;

implementation

uses
  uGlobal, uFunction, IdGlobal, IdException, IdStack;

{ TTcpServer }

constructor TTcpAgentServer.Create;
begin
  InitializeCriticalSection(FCS);

  FClientCount := 0;

  FTcpServer := TIdTCPServer.create;
  with TCPServer do
  begin
    OnConnect := TCPServerOnConnect;
    OnDisconnect := TCPServerOnDisconnect;
    OnException := TCPServerOnException;
    OnExecute := TCPServerOnExecute;
    OnStatus := TCPServerOnStatus;
  end;

  FTcpServer.Bindings.Add;
  FTcpServer.Bindings.Items[0].Port := Global.ADConfig.AgentTcpPort;
  FTcpServer.Active := True;

  F9004List := TStringList.Create;
end;

destructor TTcpAgentServer.Destroy;
var
  ContextList: TList;
  I, nCount: Integer;
begin
  {
  ContextList := TCPServer.Contexts.LockList;
  try
    for I := 0 to ContextList.Count - 1 do
    begin
      //if TIdContext(ContextList[I]).Connection.Connected then
        TIdContext(ContextList[I]).Connection.Disconnect;
      //TIdContext(ContextList[I]).Binding.PeerIP
      //TIdContext(ContextList[I]).Binding.PeerPort
      //TIdContext(ContextList[I]).Connection.Socket.Close;
    end;
  finally
    TCPServer.Contexts.UnlockList;
    FreeAndNil(ContextList);
  end;
  }
  FTcpServer.Active := False;
  FTcpServer.Free;

  for I := 0 to F9004List.Count - 1 do
  begin
    F9004List.Delete(0);
  end;
  FreeAndNil(F9004List);

  DeleteCriticalSection(FCS);

  inherited;
end;

procedure TTcpAgentServer.AddLog(const AMessage: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      //lbxLog.Items.Add('[' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '] ' + AMessage);
      //lbxLog.ItemIndex := Pred(lbxLog.Items.Count);
      Global.DebugLogViewWrite(AMessage);
      Global.Log.LogAgentServerWrite(AMessage);
    end);
end;

procedure TTcpAgentServer.ReadAddLog(const AMessage: string);
begin
  Global.Log.LogAgentServerRead(AMessage);
end;

procedure TTcpAgentServer.BroadcastMessage(const AMessage: string);
var
  ContextList: TList;
  I, nCount: Integer;
begin
  AddLog(AMessage);

  ContextList := TCPServer.Contexts.LockList;
  try
    for I := 0 to Pred(ContextList.Count) do
      TIdContext(ContextList[I]).Connection.IOHandler.WriteLn(AMessage, IndyTextEncoding_UTF8);
  finally
    TCPServer.Contexts.UnlockList;
  end
end;

procedure TTcpAgentServer.ShowClientCount(const ADisconnected: Boolean);
var
  nCount: Integer;
begin
  try
    nCount := TCPServer.Contexts.LockList.Count;
  finally
    TCPServer.Contexts.UnlockList;
  end;

  if ADisconnected then
    Dec(nCount);

  FClientCount := nCount;
end;

procedure TTcpAgentServer.TCPServerOnConnect(AContext: TIdContext);
begin
  AddLog(Format('(PeerIP=%s PeerPort=%d) ', [AContext.Binding.PeerIP, AContext.Binding.PeerPort]) + '클라이언트 접속');
  ShowClientCount;
  AContext.Connection.IOHandler.WriteLn('서버에 접속됨!', IndyTextEncoding_UTF8);
end;

procedure TTcpAgentServer.TCPServerOnDisconnect(AContext: TIdContext);
begin
  AddLog(Format('(PeerIP=%s PeerPort=%d) ', [AContext.Binding.PeerIP, AContext.Binding.PeerPort]) + '클라이언트 접속 해제');
  ShowClientCount(True);
end;

procedure TTcpAgentServer.TCPServerOnException(AContext: TIdContext; AException: Exception);
begin
  if (AContext.Connection = nil) then
    Exit;

  try
    if (AException is EIdSilentException) or
       (AException is EIdConnClosedGracefully) then
      Exit;

    AddLog(Format('Exception : %s', [AException.Message]));
  finally
    AContext.Connection.Disconnect;
  end;
end;


function TTcpAgentServer.SendDataCreat(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApiId, sTeeboxNo, sStatus, sMin, sSecond: String;
  nTeeboxNo, nMin, nSecond: integer;
  sResult: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
begin
  Result := '';
  sResult := '';

  try
    try
      jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;

      sApiId := jObj.GetValue('api_id').Value;
      sTeeboxNo := jObj.GetValue('teebox_no').Value;

      if sApiId = '9901' then //상태체크
        sResult := AgentResponse
      else if sApiId = '9902' then //설정값
        sResult := GetAgentSetting(AReceiveData)
      else if sApiId = '9903' then //설정값 저장
        sResult := SetAgentSetting(AReceiveData)
      else if sApiId = '9004' then
      begin
        if Global.ADConfig.AgentSendUse = 'Y' then
        begin
          F9004List.Add(AReceiveData);
          sResult := AgentResponse;
        end
        else
          sResult := GetTeeboxStatus(sTeeboxNo)
      end
      else
      begin
        sResult := '{"result_cd":"0003","result_msg":"Api Fail"}';
      end;

      Result := sResult;

    except
      on E: exception do
      begin
        ReadAddLog('TTcpAgentServer.SendDataCreat Except : ' + e.Message + #13);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

function TTcpAgentServer.AgentResponse: AnsiString;
begin
  Result := '{' +
               '"result_cd": "0000",' +
               '"result_msg": "정상적으로 처리 되었습니다."' +
             '}';
end;

function TTcpAgentServer.GetAgentSetting(AReceiveData: AnsiString): AnsiString;
var
  jObj, jObjSend: TJSONObject;
  sApi, sTeeboxNo, sSettings: String;
  sResult: AnsiString;
  sLeftHanded: String;
begin
  //9902
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api_id').Value;
    sTeeboxNo := jObj.GetValue('teebox_no').Value;
    sLeftHanded := jObj.GetValue('left_handed').Value;

    sResult := Global.XGolfDM.AgentSelect(sTeeboxNo, sLeftHanded);

    if sResult = 'fail' then
    begin
      Result := '{ "result_cd": 9999, "result_msg": "해당 설정값이 없습니다." }';
      Exit;
    end;

    jObjSend := TJSONObject.Create;
    jObjSend.AddPair(TJSONPair.Create('result_cd', '0000'));
    jObjSend.AddPair(TJSONPair.Create('result_msg', '정상적으로 처리 되었습니다.'));
    jObjSend.AddPair(TJSONPair.Create('settings', sResult));

    Result := jObjSend.ToString;
  finally
    FreeAndNil(jObj);
    FreeAndNil(jObjSend);
  end;

end;

function TTcpAgentServer.SetAgentSetting(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sTeeboxNo, sLeftHanded, sSettings: String;
  sResult: String;
  bResult: Boolean;
begin
  Result := '';

  try

    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api_id').Value;
    sTeeboxNo := jObj.GetValue('teebox_no').Value;
    sLeftHanded := jObj.GetValue('left_handed').Value;
    sSettings := jObj.GetValue('settings').Value;

    sResult := Global.XGolfDM.AgentSelect(sTeeboxNo, sLeftHanded);
    if sResult = 'fail' then
      bResult := Global.XGolfDM.AgentInsert(sTeeboxNo, sLeftHanded, sSettings)
    else
      bResult := Global.XGolfDM.AgentUpdate(sTeeboxNo, sLeftHanded, sSettings);


    if bResult = True then
      Result := '{"result_cd":"0000", "result_msg":"정상적으로 처리 되었습니다."}'
    else
      Result := '{"result_cd":"9999", "result_msg":"저장중 오류가 발생하였습니다."}';

  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpAgentServer.GetTeeboxStatus(ATeeboxNo: String): AnsiString;
var
  jObj: TJSONObject;
  sTeeboxNo, sStatus, sMin, sSecond: String;
  nTeeboxNo, nSecond, nMin: integer;
  sResult: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
begin

  if Trim(ATeeboxNo) = EmptyStr then
  begin
    //sResult := '{"result_cd":"AD03","result_msg":"Api Fail"}';
    Exit;
  end;

  sTeeboxNo := ATeeboxNo;
  nTeeboxNo := StrToInt(sTeeboxNo);
  if nTeeboxNo > Global.Teebox.TeeboxLastNo then
    Exit;

  rTeeboxInfo := Global.Teebox.GetTeeboxInfo(nTeeboxNo);

  //0: 유휴상태, 1: 준비, 2:사용중
  sStatus := '0';
  sMin := '0';
  if rTeeboxInfo.AgentCtlType = 'D' then
  begin
    sStatus := '1';

    nSecond := Global.Teebox.GetReservePrepareEndTime(nTeeboxNo);
    sSecond := IntToStr(nSecond);

    if (nSecond mod 60) > 0 then
      nMin := (nSecond div 60) + 1
    else
      nMin := (nSecond div 60);
    sMin := IntToStr(nMin);
  end
  else if rTeeboxInfo.RemainMinute > 0 then
  begin
    sStatus := '2';
    sMin := IntToStr(rTeeboxInfo.RemainMinute);
    nSecond := Global.Teebox.GetReserveEndTime(nTeeboxNo);
    sSecond := IntToStr(nSecond);
  end;

  sResult := '{' +
               '"api_id": 9004,' +
               '"teebox_no": ' + sTeeboxNo + ',' +
               '"reserve_no": "' + rTeeboxInfo.TeeboxReserve.ReserveNo + '",' +
               '"teebox_status": ' + sStatus + ',' +
               '"remain_min": ' + sMin + ',' +
               '"remain_second": ' + sSecond + ',' +
               '"result_cd": "0000",' +
               '"result_msg": "정상적으로 처리 되었습니다."' +
             '}';

  Result := sResult;
end;

procedure TTcpAgentServer.SendTeeboxStatus;
var
  jObj: TJSONObject;
  sReceiveData, sApi, sTeeboxNo: String;
  I: integer;
begin
  if F9004List.Count = 0 then
    Exit;

  try
    for I := 0 to F9004List.Count - 1 do
    begin
      sReceiveData := F9004List[i];

      jObj := TJSONObject.ParseJSONValue( sReceiveData ) as TJSONObject;
      sApi := jObj.GetValue('api_id').Value;
      sTeeboxNo := jObj.GetValue('teebox_no').Value;

      Global.Teebox.SendTeeboxReserveStatus(sTeeboxNo);
    end;

    for I := 0 to F9004List.Count - 1 do
    begin
      F9004List.Delete(0);
    end;

  finally
    FreeAndNil(jObj);
  end;

end;


procedure TTcpAgentServer.TCPServerOnExecute(AContext: TIdContext);
var
  sReadBuffer: string;
  sSendData: AnsiString;
begin
  if (AContext.Connection = nil) or
     (not AContext.Connection.Connected) then
    Exit;

  try
    AContext.Connection.IOHandler.MaxLineLength := MaxInt;
    sReadBuffer := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
    ReadAddLog(Format('(PeerIP=%s PeerPort=%d) ', [AContext.Binding.PeerIP, AContext.Binding.PeerPort]) + sReadBuffer);

    global.Teebox.setTeeboxAgentCtlYN(AContext.Binding.PeerIP, sReadBuffer);
    //AContext.Connection.IOHandler.WriteLn('메시지 수신 완료', IndyTextEncoding_UTF8);

    sSendData := '';
    sSendData := SendDataCreat(sReadBuffer);

    if sSendData <> '' then
    begin
      AContext.Connection.IOHandler.WriteLn(sSendData, IndyTextEncoding_UTF8);
      ReadAddLog(Format('(PeerIP=%s PeerPort=%d) ', [AContext.Binding.PeerIP, AContext.Binding.PeerPort]) + sSendData);
    end;
  except
    on E: EIdConnClosedGracefully do;
    on E: EIdSocketError do;
    on E: Exception do
      ReadAddLog(Format('Execute.Exception : %s', [E.Message]));
  end;
end;

procedure TTcpAgentServer.TCPServerOnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
  AddLog(AStatusText);
end;

end.
