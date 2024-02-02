unit uXGServerAgent;

interface

uses
  IdTCPServer, IdContext, System.SysUtils, System.Classes, JSON, Generics.Collections, Windows,
  uStruct, IdComponent;

type
  TTcpServerAgent = class
  private
    FTcpServer: TIdTCPServer;
    FUseSeqNo: Integer;
    FLastUseSeqNo: Integer; //마지막 임시seq
    FUseSeqDate: String;
    FLastReceiveData: AnsiString;

    FCS: TRTLCriticalSection;

    procedure AddLog(const AMessage: string);
    procedure BroadcastMessage(const AMessage: string);
    procedure SetServerActive(const AValue: Boolean);
    procedure ShowClientCount(const ADisconnected: Boolean=False);

    procedure TCPServerOnConnect(AContext: TIdContext);
    procedure TCPServerOnDisconnect(AContext: TIdContext);
    procedure TCPServerOnException(AContext: TIdContext; AException: Exception);
    procedure TCPServerOnExecute(AContext: TIdContext);
    procedure TCPServerOnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);

  public
    constructor Create;
    destructor Destroy; override;

    procedure ServerExecute(AContext: TIdContext);

    function SetTeeboxError(AReceiveData: AnsiString): AnsiString;  //타석기 에러등록/취소

    function SetApiTeeBoxReg(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveStartDate, AAssignMin, AReserveEndDate: String): String;
    function SetApiTeeBoxEnd(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveEndDate, AEndTy: String): String;

    property TcpServer: TIdTCPServer read FTcpServer write FTcpServer;
    property UseSeqNo: Integer read FUseSeqNo write FUseSeqNo;
    property LastUseSeqNo: Integer read FLastUseSeqNo write FLastUseSeqNo;
    property UseSeqDate: String read FUseSeqDate write FUseSeqDate;
  end;

implementation

uses
  uGlobal, uFunction, IdGlobal, IdException, IdStack;

{ TTcpServer }

constructor TTcpServerAgent.Create;
begin
  InitializeCriticalSection(FCS);

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
  //FTcpServer.Bindings.Items[0].IP := '127.0.0.1';
  FTcpServer.Bindings.Items[0].Port := 9900;
  //FTcpServer.Bindings.Items[0].Port := Global.ADConfig.TcpPort;
  FTcpServer.Active := True;
end;

destructor TTcpServerAgent.Destroy;
begin
  FTcpServer.Active := False;
  FTcpServer.Free;

  DeleteCriticalSection(FCS);

  inherited;
end;

procedure TTcpServerAgent.AddLog(const AMessage: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      //lbxLog.Items.Add('[' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '] ' + AMessage);
      //lbxLog.ItemIndex := Pred(lbxLog.Items.Count);
    end);
end;

procedure TTcpServerAgent.BroadcastMessage(const AMessage: string);
var
  ContextList: TList;
  I, nCount: Integer;
begin
  ContextList := TCPServer.Contexts.LockList;
  try
    for I := 0 to Pred(ContextList.Count) do
      TIdContext(ContextList[I]).Connection.IOHandler.WriteLn(AMessage, IndyTextEncoding_UTF8);
  finally
    TCPServer.Contexts.UnlockList;
  end
end;

procedure TTcpServerAgent.TCPServerOnConnect(AContext: TIdContext);
begin
  AddLog(Format('(PeerIP=%s PeerPort=%d) ', [AContext.Binding.PeerIP, AContext.Binding.PeerPort]) + '클라이언트 접속');
  ShowClientCount;
  AContext.Connection.IOHandler.WriteLn('서버에 접속됨!', IndyTextEncoding_UTF8);
end;

procedure TTcpServerAgent.TCPServerOnDisconnect(AContext: TIdContext);
begin
  AddLog(Format('(PeerIP=%s PeerPort=%d) ', [AContext.Binding.PeerIP, AContext.Binding.PeerPort]) + '클라이언트 접속 해제');
  ShowClientCount(True);
end;

procedure TTcpServerAgent.TCPServerOnException(AContext: TIdContext; AException: Exception);
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

procedure TTcpServerAgent.TCPServerOnExecute(AContext: TIdContext);
var
  sReadBuffer: string;
begin
  if (AContext.Connection = nil) or
     (not AContext.Connection.Connected) then
    Exit;

  try
    AContext.Connection.IOHandler.MaxLineLength := MaxInt;
    sReadBuffer := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
    AddLog(Format('(PeerIP=%s PeerPort=%d) ', [AContext.Binding.PeerIP, AContext.Binding.PeerPort]) + sReadBuffer);
    AContext.Connection.IOHandler.WriteLn('메시지 수신 완료', IndyTextEncoding_UTF8);
  except
    on E: EIdConnClosedGracefully do;
    on E: EIdSocketError do;
    on E: Exception do
      AddLog(Format('Execute.Exception : %s', [E.Message]));
  end;
end;

procedure TTcpServerAgent.TCPServerOnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
  AddLog(AStatusText);
end;

procedure TTcpServerAgent.ServerExecute(AContext: TIdContext);
Var
  nPort: Integer;
  sIP: String;
  sMainThID: string;
  sRcvData: AnsiString;
  sSendData: AnsiString;
  LogMsg: String;
begin

  try

    sIP := AContext.Connection.Socket.Binding.PeerIP;
    nPort := AContext.Connection.Socket.Binding.PeerPort;
    sMainThID := '[' + sIP + ':' + IntToStr(nPort) + ']';

    sRcvData := '';
    sSendData := '';

    Try

      if Not AContext.Connection.Connected then
      begin
        LogMsg := sMainThID + ' Not connected!';
        //LogView(LogMsg);
        Exit;
      end;

      //AContext.Connection.IOHandler.ReadTimeout := 100;
      sRcvData := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);

      //Application.ProcessMessages;
      Sleep(10);

    Except
      on E: exception do
      begin
        LogMsg := sMainThID + ' ' + E.Message;
        //LogView(LogMsg);
        if Not AContext.Connection.Connected then
          AContext.Connection.Disconnect;
        AContext.Connection.Socket.Close;
        Exit;
      end;
    End;


    Try
      EnterCriticalSection(FCS);
      try
        sSendData := SendDataCreat(sRcvData);
      finally
        LeaveCriticalSection(FCS);
      end;
      Sleep(0);
    Except
      on E: exception do
      begin
        LogMsg := sMainThID + ' SendData 오류 ' + E.Message;
        //LogView(LogMsg);
      end;
    End;

    if sSendData <> '' then
    begin
      try
        AContext.Connection.IOHandler.WriteLn(sSendData, IndyTextEncoding_UTF8);

        Sleep(10);
        AContext.Connection.Disconnect;
      Except
        on E: exception do
        begin
          LogMsg := sMainThID + ' 400 송신오류 ' + E.Message;
          //LogView(LogMsg);
          Exit;
        end;
      end;
    end
    else
    begin
      //LogView(sMainThID + ' 400 응답값이 없음 ' + sSendData);
    end;


  except
    on E: exception do
    begin
      LogMsg := sMainThID + ' TCPServerExecute 처리오류 ' + E.Message;
      //LogView(LogMsg);
      Exit;
    end;
  end;
end;

function TTcpServerAgent.SetTeeboxError(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sStoreCd, sApi, sUserId, sTeeboxNo, sErrorDiv: String;
  sResult: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
begin

  //K403_TeeBoxError 03. 타석기 장애 등록 (POS/KIOSK)
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;

    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;      //사용자 Id
    sTeeboxNo := jObj.GetValue('teebox_no').Value;  //타석기 번호
    sErrorDiv := jObj.GetValue('error_div').Value;  //장애 구분 코드

    if (sTeeboxNo = '0') then
    begin
      Result := '{"result_cd":"403A",' +
                 '"result_msg":"타석번호를 확인해주세요."}';

      Exit;
    end;

    if sErrorDiv = '0' then // 점검/사용불가 해제
    begin
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));

      if rTeeboxInfo.UseStatus = '8' then
      begin
        sResult := Global.XGolfDM.TeeboxErrorUpdate(sUserId, sTeeboxNo, '0');

        if sResult = 'Success' then
          Global.Teebox.TeeboxDeviceCheck(StrToInt(sTeeboxNo), '0');
      end
      else
      begin
        sResult := Global.XGolfDM.TeeboxUseUpdate(sUserId, sTeeboxNo, 'Y');

        if sResult = 'Success' then
          Global.Teebox.TeeboxDeviceUseYN(StrToInt(sTeeboxNo), 'Y');
      end;
    end
    else if sErrorDiv = '1' then //점검
    begin
      sResult := Global.XGolfDM.TeeboxErrorUpdate(sUserId, sTeeboxNo, '8');

      if sResult = 'Success' then
        Global.Teebox.TeeboxDeviceCheck(StrToInt(sTeeboxNo), '8');
    end
    else if sErrorDiv = '2' then //사용불가
    begin
      sResult := Global.XGolfDM.TeeboxUseUpdate(sUserId, sTeeboxNo, 'N');

      if sResult = 'Success' then
        Global.Teebox.TeeboxDeviceUseYN(StrToInt(sTeeboxNo), 'N');
    end;

    if sResult = 'Success' then
      Result := '{"result_cd":"0000","result_msg":"Success"}'
    else
      Result := '{"result_cd":"0001","result_msg":"' + sResult + '"}';

  finally
    FreeAndNil(jObj);
  end;

end;


function TTcpServerAgent.SetApiTeeBoxReg(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveStartDate, AAssignMin, AReserveEndDate: String): String;
var
  sJsonStr: AnsiString;
  jObj: TJSONObject;
  jErpSeObj: TJSONObject; //Erp 전송전문
  sResult, sResultCd, sResultMsg, sLog, sLogH: String;
begin
  Result := '';
  sLogH := IntToStr(ATeeboxNo) + ' [ ' + ATeeboxNm + ' ] ' + AReserveNo;

  sResult := Global.XGolfDM.SeatUseStartDateUpdate(Global.ADConfig.StoreCode, AReserveNo, AReserveStartDate, Global.ADConfig.UserId);
  if sResult <> 'Success' then
  begin
    sLog := 'SetApiTeeBoxRegDB Exception : ' + sLogH;
    Global.Log.LogErpApiWrite(sLog);
  end;

  try
    try

      jErpSeObj := TJSONObject.Create;
      jErpSeObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
      jErpSeObj.AddPair(TJSONPair.Create('teebox_no', IntToStr(ATeeboxNo) ) );
      jErpSeObj.AddPair(TJSONPair.Create('reserve_no', AReserveNo ) );
      jErpSeObj.AddPair(TJSONPair.Create('start_datetime', AReserveStartDate ) );
      jErpSeObj.AddPair(TJSONPair.Create('assign_min', AAssignMin ) );
      jErpSeObj.AddPair(TJSONPair.Create('end_datetime', AReserveEndDate ) );
      jErpSeObj.AddPair(TJSONPair.Create('user_id', Global.ADConfig.UserId));

      sResult := Global.Api.PostErpApi(jErpSeObj.ToString, 'K702_TeeboxReg', Global.ADConfig.ApiUrl);

      if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
      begin
        sLog := 'SetApiTeeBoxReg Fail : ' + sLogH + ' / ' + sResult;
        Global.Log.LogErpApiWrite(sLog);
      end
      else
      begin
        jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
        sResultCd := jObj.GetValue('result_cd').Value;
        sResultMsg := jObj.GetValue('result_msg').Value;

        //if sResultCd <> '0000' then
        begin
          sLog := 'K702_TeeboxReg : ' + sLogH + ' / ' + sResultCd + ' / ' + sResultMsg;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;

    except
      //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
      on e: Exception do
      begin
        sLog := 'SetApiTeeBoxReg Exception : ' + sLogH + ' / ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);
      end;
    end

  finally
    FreeAndNil(jObj);
    FreeAndNil(jErpSeObj);
  end;

  Result := 'Success';

end;

function TTcpServerAgent.SetApiTeeBoxEnd(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveEndDate, AEndTy: String): String;
var
  sJsonStr: AnsiString;
  jObj, jErpSeObj: TJSONObject;
  sResult, sResultCd, sResultMsg, sLog, sLogH: String;
begin
  Result := '';
  sLogH := IntToStr(ATeeboxNo) + ' [ ' + ATeeboxNm + ' ] ' + AReserveNo;

  if Trim(AReserveNo) = ''  then
  begin
    sLog := 'SetApiTeeBoxEnd Error : ' + sLogH;
    Global.Log.LogErpApiWrite(sLog);
    Exit;
  end;

  sResult := Global.XGolfDM.SeatUseEndDateUpdate(Global.ADConfig.StoreCode, AReserveNo, AReserveEndDate, AEndTy);
  if sResult <> 'Success' then
  begin
    sLog := 'SetApiTeeBoxEndDB Exception : ' + sLogH;
    Global.Log.LogErpApiWrite(sLog);
  end;

  if AEndTy <> '2' then //2:종료,5:취소
    Exit;


  begin
    try
      try
        jErpSeObj := TJSONObject.Create;
        jErpSeObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
        jErpSeObj.AddPair(TJSONPair.Create('teebox_no', IntToStr(ATeeboxNo) ) );
        jErpSeObj.AddPair(TJSONPair.Create('reserve_no', AReserveNo ) );
        jErpSeObj.AddPair(TJSONPair.Create('end_datetime', AReserveEndDate ) );
        jErpSeObj.AddPair(TJSONPair.Create('user_id', Global.ADConfig.UserId));

        sResult := Global.Api.PostErpApi(jErpSeObj.ToString, 'K705_TeeboxEnd', Global.ADConfig.ApiUrl);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetApiTeeBoxEnd Fail : ' + sLogH + ' / ' + sResult;
          Global.Log.LogErpApiWrite(sLog);
        end
        else
        begin
          jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
          sResultCd := jObj.GetValue('result_cd').Value;
          sResultMsg := jObj.GetValue('result_msg').Value;

          //if sResultCd <> '0000' then
          begin
            sLog := 'K705_TeeboxEnd : ' + sLogH + ' / ' + sResultCd + ' / ' + sResultMsg;
            Global.Log.LogErpApiWrite(sLog);
          end;
        end;

      except
        //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
        on e: Exception do
        begin
          sLog := 'SetApiTeeBoxEnd Exception : ' + sLogH + ' / ' + e.Message;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end
    finally
      FreeAndNil(jObj);
      FreeAndNil(jErpSeObj);
    end;
  end;

  Result := 'Success';

end;

end.
