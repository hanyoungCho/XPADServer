unit uXGServer;

interface

uses
  IdTCPServer, IdContext, System.SysUtils, System.Classes, JSON, Generics.Collections, Windows, System.DateUtils,
  uStruct;

type
  TTcpServer = class
  private
    FTcpServer: TIdTCPServer;
    FUseSeqNo: Integer;
    FLastUseSeqNo: Integer; //������ �ӽ�seq
    FUseSeqDate: String;
    FLastReceiveData: AnsiString;

    FCS: TRTLCriticalSection;
  protected

  public
    constructor Create;
    destructor Destroy; override;

    procedure ServerConnect(AContext: TIdContext);
    procedure ServerExecute(AContext: TIdContext);

    procedure ServerReConnect;

    function SendDataCreat(AReceiveData: AnsiString): AnsiString;
    function SetTeeboxStatus(AjObj: TJSONObject): String;  //Ÿ����絿��Ȳ��û��
    function SetTeeboxError(AReceiveData: AnsiString): AnsiString;  //Ÿ���� �������/���

    function SetTeeboxHold(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���
    function SetTeeboxHoldCancel(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���

    function SetTeeboxReserve(AReceiveData: AnsiString): AnsiString; //Ÿ���� ������
    function SetTeeboxReserveSql(ASeatUseInfo: TSeatUseInfo; AMove: Boolean = False; ACutIn: Boolean = False): String; //Ÿ���� ��������������
    function SetTeeboxReserveCancel(AReceiveData: AnsiString): AnsiString; //Ÿ���������
    function SetTeeboxReserveChange(AReceiveData: AnsiString): AnsiString; //Ÿ�����ຯ��

    function SetTeeboxMove(AReceiveData: AnsiString): AnsiString; //Ÿ���̵����
    function SetTeeboxHeatUsed(AReceiveData: AnsiString): AnsiString; //Ÿ�����������
    function SetTeeboxClose(AReceiveData: AnsiString): AnsiString; //Ÿ������

    function SetTeeboxStart(AReceiveData: AnsiString): AnsiString; //��ù���
    function SetKioskPrint(AReceiveData: AnsiString): AnsiString; //ACS
    function SetKioskStatus(AReceiveData: AnsiString): AnsiString; //ACS

    function SetTeeBoxEmergency(AReceiveData: AnsiString): AnsiString; //��Ʈ�ʼ��� ����Ÿ��, ��޹������
    function GetTeeBoxEmergency(AReceiveData: AnsiString): AnsiString; //��Ʈ�ʼ��� ����Ÿ��, ��޹������ ���� ����
    function SetTeeboxCheckCtrl(AReceiveData: AnsiString): AnsiString; //Ÿ����������
    function SetTeeboxCutIn(AReceiveData: AnsiString): AnsiString; //����ֱ� 2021-07-21
    function SetTeeboxCheckIn(AReceiveData: AnsiString): AnsiString; //üũ�� 2021-07-27
    function SetTeeboxHeatAll(AReceiveData: AnsiString): AnsiString; //���� ��üOFF���� 2021-12-15
    function SetParkingPrintCheck(AReceiveData: AnsiString): AnsiString; //�����ǹ���üũ(����� ������ ����)

    function SetAgentSetting(AReceiveData: AnsiString): AnsiString; //Agent ���޿�

    function SetApiTeeBoxReg(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveStartDate: String): String;
    function SetApiTeeBoxEnd(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveEndDate, AEndTy: String): String;
    function SetApiTeeBoxStatus(AType, ATeeboxNo, ATeeboxNo1: String): Boolean;
    function GetErpTeeboxList: Boolean; //Ÿ��������ü��ȸ
    function GetErpTeeboxListLastNo: Integer; //����۽� Erp ������ Ȯ�ο�

    function BallRecallTimeCheck(ASeatUseInfo: TSeatUseInfo; AStart, AEnd: String): Boolean; //��ȸ�� �ð� �����ð��� �߰�
    function BallRecallTimeCheckMulti(ASeatUseInfo: TSeatUseInfo): Boolean; //��ȸ�� �ð� �����ð��� �߰�

    function ReserveEndTimeCheck(APossibleReserveDatetime, APrepareMin, AAssignMin: String): Boolean; //���� ��������ð� üũ

    property TcpServer: TIdTCPServer read FTcpServer write FTcpServer;
    property UseSeqNo: Integer read FUseSeqNo write FUseSeqNo;
    property LastUseSeqNo: Integer read FLastUseSeqNo write FLastUseSeqNo;
    property UseSeqDate: String read FUseSeqDate write FUseSeqDate;
  end;

implementation

uses
  uGlobal, uFunction, IdGlobal;

{ TTcpServer }

constructor TTcpServer.Create;
begin
  InitializeCriticalSection(FCS);

  FTcpServer := TIdTCPServer.create;

  FTcpServer.OnConnect := ServerConnect;
  FTcpServer.OnExecute := ServerExecute;

  FTcpServer.Bindings.Add;
  //FTcpServer.Bindings.Items[0].IP := '127.0.0.1';
  //FTcpServer.Bindings.Items[0].Port := 3308;
  FTcpServer.Bindings.Items[0].Port := Global.ADConfig.TcpPort;
  FTcpServer.Active := True;
end;

destructor TTcpServer.Destroy;
begin
  FTcpServer.Active := False;
  FTcpServer.Free;

  DeleteCriticalSection(FCS);

  inherited;
end;

procedure TTcpServer.ServerConnect(AContext: TIdContext);
begin
  //tPort := AContext.Connection.Socket.Binding.PeerPort;
  //MainTH_ID := Format('%06d', [tPort]);

  //LogMsg := Format('Handle[%s] Connect ======================== ', [MainTH_ID]);
  //LogView(LogMsg);
end;

procedure TTcpServer.ServerReConnect;
begin
  FTcpServer.Active := False;
  FTcpServer.Active := True;

  Global.Log.LogServerWrite('ServerReConnect' + #13);
end;

procedure TTcpServer.ServerExecute(AContext: TIdContext);
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

      if Pos('Cookie', sRcvData) <> 0 then
      begin
        LogMsg := sMainThID + ' / ' + sRcvData;
        Global.Log.LogServerWrite(LogMsg + #13);

        if Not AContext.Connection.Connected then
          AContext.Connection.Disconnect;
        AContext.Connection.Socket.Close;
        Exit;
      end;

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
        LogMsg := sMainThID + ' SendData ���� ' + E.Message;
        //LogView(LogMsg);
      end;
    End;

    if sSendData <> '' then
    begin
      try
        //���̶����� ���� �߻��� Ȯ���ʿ�
        //AContext.Connection.IOHandler.MaxLineLength
        AContext.Connection.IOHandler.WriteLn(sSendData, IndyTextEncoding_UTF8);

        Sleep(10);
        AContext.Connection.Disconnect;
      Except
        on E: exception do
        begin
          LogMsg := sMainThID + ' 400 �۽ſ��� ' + E.Message;
          //LogView(LogMsg);
          Exit;
        end;
      end;
    end
    else
    begin
      //LogView(sMainThID + ' 400 ���䰪�� ���� ' + sSendData);
    end;


  except
    on E: exception do
    begin
      LogMsg := sMainThID + ' TCPServerExecute ó������ ' + E.Message;
      //LogView(LogMsg);
      Exit;
    end;
  end;
end;

function TTcpServer.SendDataCreat(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sStoreCd, sApi, sLogMsg, sUserId, sTeeboxNo: String;
  sResult: AnsiString;
  bKiosk: Boolean;
begin
  Result := '';
  sResult := '';
  Global.Log.LogServerWrite(AReceiveData + #13);

  if (Copy(AReceiveData, 1, 1) <> '{') or (Copy(AReceiveData, Length(AReceiveData), 1) <> '}') then
  begin
    sResult := '{"result_cd":"0001","result_msg":"Json Fail"}';
    Global.Log.LogServerWrite(sResult + #13);
    Result := sResult;
    Exit;
  end;

  try
    try
      jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;

      sStoreCd := jObj.GetValue('store_cd').Value;
      if sStoreCd <> Global.ADConfig.StoreCode then
      begin
        sResult := '{"result_cd":"0002","result_msg":"Store Fail"}';
        Global.Log.LogServerWrite(sResult + #13);
        Result := sResult;
        Exit;
      end;

      sApi := jObj.GetValue('api').Value;
      sUserId := jObj.GetValue('user_id').Value;

      bKiosk := StrPos(PChar(sUserId), PChar('kiosk')) <> nil;

      //2021-12-17 ������ 3�� ����
      if (bKiosk = True) and (Global.ADConfig.StoreCode = 'B7001') then
      begin
        sTeeboxNo := jObj.GetValue('teebox_no').Value;
        if StrToInt(sTeeboxNo) > 52 then
          bKiosk := False;
      end;

      //2020-09-12 ��ȸ���� ��������, pos ����
      if (Global.Teebox.BallBackUse = True) and
         (bKiosk = True) and
         ((sApi = 'K408_TeeBoxReserve2') or (sApi = 'K405_TeeBoxHold')) then
      begin
        sResult := '{"result_cd":"0001","result_msg":"��ȸ���� �Դϴ�. ��ȸ�� ������ �̿��� �ּ���."}';
        Global.Log.LogServerWrite(sResult + #13);
        Result := sResult;
        Exit;
      end;

      //2021-08-24 ����ֱ� �׸��ʵ�, �����, ������ �� ����
      //2021-08-24 üũ�� �׸��ʵ�(�����,��ȭ����), �����/������(����ϸ�) �� ����
      //if (sApi = 'A431_TeeboxCutIn') or (sApi = 'A432_TeeboxCheckIn') then
      if (sApi = 'A432_TeeboxCheckIn') then
      begin
        if (Global.ADConfig.CheckInUse <> 'Y') then
        begin
          sResult := '{"result_cd":"0001","result_msg":"����Ҽ� ���� ����Դϴ�."}';
          Global.Log.LogServerWrite(sResult + #13);
          Result := sResult;
          Exit;
        end;
      end;

      if sApi = 'K402_TeeBoxStatus' then //Ÿ���� ,������Ȳ��û
        //sResult := SetSeatStatus(AReceiveDate)
      else if sApi = 'K403_TeeBoxError' then //Ÿ���� ��ֵ��
        sResult := SetTeeboxError(AReceiveData)
      else if sApi = 'K404_TeeBoxError' then //Ÿ���� ��ֵ�� ���
        sResult := SetTeeboxError(AReceiveData)
      else if sApi = 'K405_TeeBoxHold' then //Ÿ���� Ȧ�� ���
        sResult := SetTeeboxHold(AReceiveData)
      else if sApi = 'K406_TeeBoxHold' then //Ÿ���� Ȧ�� ���
        sResult := SetTeeboxHoldCancel(AReceiveData)
      else if sApi = 'K408_TeeBoxReserve2' then //Ÿ���� ������
        sResult := SetTeeboxReserve(AReceiveData)
      else if sApi = 'K410_TeeBoxReserved' then //Ÿ���������
        sResult := SetTeeboxReserveCancel(AReceiveData)
      else if sApi = 'K411_TeeBoxReserved' then //Ÿ�����ຯ��
        sResult := SetTeeboxReserveChange(AReceiveData)
      else if sApi = 'K412_MoveTeeBoxReserved' then //Ÿ���̵����
        sResult := SetTeeboxMove(AReceiveData)
      //else if sApi = 'K413_TeeBoxUsed' then //Ÿ�����������
        //sResult := SetSeatUsed(AReceiveDate)
      else if sApi = 'K414_TeeBoxHeat' then
        sResult := SetTeeboxHeatUsed(AReceiveData)
      //else if sApi = 'K415_TeeBoxHeatStatus' then
        //sResult := SetSeatHeatStatus(AReceiveDate)
      else if sApi = 'K416_TeeBoxClose' then //Ÿ������
        sResult := SetTeeboxClose(AReceiveData)
      else if sApi = 'A417_TeeBoxStart' then //��ù���
        sResult := SetTeeboxStart(AReceiveData)
      else if sApi = 'A418_KioskPrintError' then //Kiosk ������ ����
        sResult := SetKioskPrint(AReceiveData)  ///wix/api/K802_SendAcs
      else if sApi = 'A419_KioskStatus' then //Kiosk ����
        sResult := SetKioskStatus(AReceiveData)
      else if sApi = 'A420_SetTeeBoxEmergency' then //��Ʈ�ʼ��� �����ϴ� ���, ��޹������
        sResult := SetTeeBoxEmergency(AReceiveData)
      else if sApi = 'A421_GetTeeBoxEmergency' then //��Ʈ�ʼ��� �����ϴ� ���, ��޹������ ���� ����
        sResult := GetTeeBoxEmergency(AReceiveData)
      else if sApi = 'A430_TeeboxCheckCtrl' then //2021-06-01 �������� Ÿ�� 10�� ����, ����������, Ÿ����������
        sResult := SetTeeboxCheckCtrl(AReceiveData)
      else if sApi = 'A431_TeeboxCutIn' then //2021-07-21 ����ֱ�
        sResult := SetTeeboxCutIn(AReceiveData)
      else if sApi = 'A432_TeeboxCheckIn' then //2021-07-27 üũ��
        sResult := SetTeeboxCheckIn(AReceiveData)
      else if sApi = 'A433_ParkingPrintCheck' then //2022-07-15 �����ǹ���üũ(����� ������ ����)
        sResult := SetParkingPrintCheck(AReceiveData)
      else if sApi = 'A440_AgentSetting' then // Agent ���޿�
        sResult := SetAgentSetting(AReceiveData)
      else if sApi = 'K450_TeeBoxHeatAll' then //2021-12-15 ���� ��üOFF����
        sResult := SetTeeboxHeatAll(AReceiveData)
      else
      begin
        sResult := '{"result_cd":"0003","result_msg":"Api Fail"}';
      end;

      Global.Log.LogServerWrite(sResult + #13);
      Result := sResult;

    except
      on E: exception do
      begin
        sLogMsg := 'SendDataCreat Except : ' + e.Message;
        Global.Log.LogServerWrite(sLogMsg + #13);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

function TTcpServer.SetTeeboxStatus(AjObj: TJSONObject): String;
begin
  //K402_TeeBoxStatus Ÿ���� ������Ȳ��û
  Result := '';
end;

function TTcpServer.SetTeeboxError(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sStoreCd, sApi, sUserId, sTeeboxNo, sErrorDiv, sLog: String;
  sResult: AnsiString;
begin

  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse SetSeatError!';
    Global.Log.LogErpApiDelayWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;

  //K403_TeeBoxError 03. Ÿ���� ��� ��� (POS/KIOSK)
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;

    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;      //����� Id
    sTeeboxNo := jObj.GetValue('teebox_no').Value;  //Ÿ���� ��ȣ
    sErrorDiv := jObj.GetValue('error_div').Value;  //��� ���� �ڵ�

    if sApi = 'K403_TeeBoxError' then //��ֵ��
    begin
      if (sTeeboxNo = '0') and (sErrorDiv = '8') then
      begin
        Result := '{"result_cd":"403A",' +
                   '"result_msg":"If you want to set maintain_mode(8), you should set teebox_no"}';

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;
    end;

    // ��ȸ�����ΰ�� ��ȸ������ API �� ������ ��� PauseTime �ʱ�ȭ��
    if (sTeeboxNo = '0') and (sErrorDiv = '7') then //��ȸ�� ����
    begin
      //if (Global.ADConfig.StoreCode = 'B8001') or // �������̰���Ŭ��
      if (Global.ADConfig.StoreCode = 'A8002') or // SHOWGOLF ���ǵ���
         (Global.ADConfig.StoreCode = 'D3001') then // D3001	����� ���ǵ�
      begin
        Result := '{"result_cd":"0001","result_msg":"����Ҽ� ���� ����Դϴ�."}';
        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;

      if Global.Teebox.BallBackUse = True then
      begin
        //Result := '{"result_cd":"404A",' + '"result_msg":"���� ��ȸ������ ���� �Դϴ�."}';
        Result := '{"result_cd":"0000","result_msg":"Success"}';

        sLog := '��ȸ�� �� ���۸��';
        Global.Log.LogReserveWrite(sLog);

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;
    end;

    sResult := Global.XGolfDM.TeeboxErrorUpdate(sUserId, sTeeboxNo, sErrorDiv);

    if sResult = 'Success' then
    begin
      if (sTeeboxNo = '0') then
      begin
        if (sErrorDiv = '7') then //��ȸ�� ����
          Global.Teebox.TeeboxBallRecallStart
        else if (sErrorDiv = '0') then //��ȸ�� ����
          Global.Teebox.TeeboxBallRecallEnd;

        //2020-08-27 v25 ��ȸ���� Ÿ���Ϻ� �̾�����Ʈ �Ǵ°�� �߻�. �������Ʈ
        Global.XGolfDM.TeeboxErrorUpdate(sUserId, sTeeboxNo, sErrorDiv);
      end
      else
      begin
        Global.Teebox.TeeboxDeviceCheck(StrToInt(sTeeboxNo), sErrorDiv);
      end;

      Result := '{"result_cd":"0000","result_msg":"Success"}';

      //2021-10-12 ��������: ��ȸ����ü, ���˰���
      if (sTeeboxNo = '0') then
        SetApiTeeBoxStatus('ball', '', '')
      else
        SetApiTeeBoxStatus('check', sTeeboxNo, '');
    end
    else
    begin
      Result := '{"result_cd":"","result_msg":"' + sResult + '"}';
    end;
  finally
    FreeAndNil(jObj);
    Global.Teebox.TeeboxReserveUse := False;
  end;

end;

function TTcpServer.SetTeeboxHold(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���/���
var
  jObj: TJSONObject;
  sApi, sUserId, sTeeboxNo, sLog: String;
  sResult: AnsiString;
  nResult: Integer;
  rSeatInfo: TTeeboxInfo;
begin
  //K405_TeeBoxHold
  Result := '';

  try

    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;      //����� Id
    sTeeboxNo := jObj.GetValue('teebox_no').Value;  //Ÿ���� ��ȣ

    if Global.Teebox.GetTeeboxHold(sTeeboxNo, sUserId, 'Insert') = True then
    begin
      Result := '{"result_cd":"405A",' +
                 '"result_msg":"������ �������� Ÿ���Դϴ�. �ٸ� Ÿ���� �������ּ���",' +
                 '"hold_yn":"Y",' +
                 '"emergency_yn":"' + IfThen(Global.ADConfig.Emergency, 'Y', 'N') + '",' +
                 '"DNSFail_yn":"' + IfThen(Global.Store.DNSError, 'Y', 'N') + '",' +
                 '"store_close_time":"' + Global.Store.EndTime + '",' +
                 '"change_store_date":"' + Global.Store.StoreChgDate + '"}';
      Exit;
    end;

    rSeatInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));

    try
      sResult := Global.XGolfDM.TeeboxHoldInsert(sUserId, sTeeboxNo, rSeatInfo.TeeboxNm);

      if sResult = 'Success' then
      begin
        Global.Teebox.SetTeeboxHold(sTeeboxNo, sUserId, True);
        Result := '{"result_cd":"0000",' +
                   '"result_msg":"Success",' +
                   '"hold_yn":"Y",' +
                   '"emergency_yn":"' + IfThen(Global.ADConfig.Emergency, 'Y', 'N') + '",' +
                   '"DNSFail_yn":"' + IfThen(Global.Store.DNSError, 'Y', 'N') + '",' +
                   '"store_close_time":"' + Global.Store.EndTime + '",' +
                   '"change_store_date":"' + Global.Store.StoreChgDate + '"}';
      end
      else
      begin
        Result := '{"result_cd":"",' +
                    '"result_msg":"�ӽÿ��࿡ �����Ͽ����ϴ�. �ٽ� �õ����ּ���",' +
                    '"hold_yn":"N",' +
                    '"emergency_yn":"' + IfThen(Global.ADConfig.Emergency, 'Y', 'N') + '",' +
                    '"DNSFail_yn":"' + IfThen(Global.Store.DNSError, 'Y', 'N') + '",' +
                    '"store_close_time":"' + Global.Store.EndTime + '",' +
                    '"change_store_date":"' + Global.Store.StoreChgDate + '"}';
      end;

    except
      on e: Exception do
      begin
        sLog := 'SeatHoldInsert Exception : ' + sTeeboxNo + ' / ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);

        Global.XGolfDM.ReConnectionHold;
        Global.Log.LogErpApiWrite('ReConnectionHold');

        Result := '{"result_cd":"",' +
                  '"result_msg":"�ӽÿ����� ��ְ� �߻��Ͽ����ϴ�",' +
                  '"hold_yn":"N",' +
                  '"emergency_yn":"' + IfThen(Global.ADConfig.Emergency, 'Y', 'N') + '",' +
                  '"DNSFail_yn":"' + IfThen(Global.Store.DNSError, 'Y', 'N') + '",' +
                  '"store_close_time":"' + Global.Store.EndTime + '",' +
                  '"change_store_date":"' + Global.Store.StoreChgDate + '"}';
        Exit;
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

function TTcpServer.SetTeeboxHoldCancel(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���/���
var
  jObj: TJSONObject;
  sApi, sUserId, sTeeboxNo, sLog: String;
  sResult: String;
begin
  //K406_TeeBoxHold
  Result := '';

  try
    try

      jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
      sApi := jObj.GetValue('api').Value;
      sUserId := jObj.GetValue('user_id').Value;      //����� Id
      sTeeboxNo := jObj.GetValue('teebox_no').Value;  //Ÿ���� ��ȣ

      // 2021-10-13 Ű����ũ���� �����Ϸ��� Ȧ����� ����. �����Ϸ��� ��� AD���� Ȧ�� ���ó����.
      // Ű����ũ���� Ȧ����� ��û�� ID Ȯ��
      if StrPos(PChar(sUserId), PChar('kiosk')) <> nil then
      begin
        if Global.Teebox.GetTeeboxHold(sTeeboxNo, sUserId, 'Delete') = False then  //Ȧ�����ڰ� �ٸ���
        begin
          Result := '{"result_cd":"0000","result_msg":"User Fail","hold_yn":"N"}';
          Exit;
        end;
      end;

      sResult := Global.XGolfDM.TeeboxHoldDelete(sUserId, sTeeboxNo);

      if sResult = 'Success' then
      begin
        Global.Teebox.SetTeeboxHold(sTeeboxNo, sUserId, False);
        Result := '{"result_cd":"0000","result_msg":"Success","hold_yn":"N"}';
      end
      else
        //Result := '{"result_cd":"","result_msg":"' + sResult + '","hold_yn":"Y"}';
        Result := '{"result_cd":"","result_msg":"�ӽÿ����� �������� ���Ͽ����ϴ�. �ٽ� �õ����ּ���.","hold_yn":"Y"}';

    except
      on e: Exception do
      begin
        sLog := 'SetSeatHoldCancel Exception : ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);

        Global.XGolfDM.ReConnectionHold;
        Global.Log.LogErpApiWrite('ReConnectionHold');

        Result := '{"result_cd":"",' +
                  //'"result_msg":"' + e.Message + '",' +
                  '"result_msg":"�ӽÿ��� ������ ��ְ� �߻��Ͽ����ϴ�.",' +
                  '"hold_yn":"Y"}';
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

function TTcpServer.SetTeeboxReserve(AReceiveData: AnsiString): AnsiString; //Ÿ���� ������
var
  jObj: TJSONObject;
  sApi, sUserId, sTeeboxNo, sMemberNo, sMemberNm, sMemberTel, sReserveRootDiv, sReceiptNo: String;
  sXgUserKey: String;
  sPurchaseCd, sProductCd, sProductNm, sReserveDiv, sAssignMin, sAssignBalls, sPrepareMin: String;
  sResult: String;

  nProductListSize, nIndex, nReIndex: Integer;
  sPossibleReserveDatetime: String;
  ASeatUseInfoArr: Array of TSeatUseInfo;
  nUseSeq: Integer;

  aUseSeqList: array of Integer;
  rSeatUseReserveList: TList<TSeatUseReserve>;
  SeatUseReserveTemp: TSeatUseReserve;

  sUseSeqDate: String;
  sJsonStr: AnsiString;

  jReciveObjArr: TJsonArray; //pos,kiosk ����
  jReciveItemObj: TJSONObject;

  jErpSeObj, jErpSeItemObj: TJSONObject; //Erp ��������
  jErpSeObjArr: TJSONArray;

  jErpRvObj, jErpRvItemObj, jErpRvSubItemObj: TJSONObject;
  jErpRvObjArr, jErpRvSubObjArr: TJsonArray;
  sErpRvResultCd, sErpRvResultMsg, sErpRvMemberNm: String;

  sLog: String;

  rSeatInfo: TTeeboxInfo;

  jSendObj, jSendItemObj, jSendSubItemObj: TJSONObject; // pos,kiosk ��������
  jSendObjArr, jSendSubObjArr: TJSONArray;

  JV, JV2: TJSONValue;
  nCount, nCount2: integer;
  I, j: Integer;
  sDate: String;
  sReserveNoTemp, sReserveSql: String;

  //2020-05-31 ����ð� ����
  sPossibleReserveDatetimeChk: String;

  //2020-07-02 ���۽ð� Ȯ�ο�
  bStartTm: Boolean;
  sReserveTmTemp: String;
  dtReserveStartTmTemp: TDateTime;

  dtReserveEndTmTemp, dtReserveEndTmTemp1: TDateTime;
  nNNTemp: Integer;

  //2020-08-18 ���޻��ڵ� �߰�
  sAffiliateCd: String;

  sReceRemainMin: String;

  sLessonProNm, sLessonProPosColor: String; //��������
  sAvailableZoneCd: String; //��밡�� ����
  bBallRecallTimeCheck: Boolean;
  nBallRecallTime: Integer;
begin

  //2020-06-04
  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then //TeeboxThread ���������
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiDelayWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;

  //K408_TeeBoxReserve2
  Result := '';
  sReserveNoTemp := '';

  //2020-05-29 ��õ� ���� �����ȣ �ӽû���
  if FUseSeqNo < FLastUseSeqNo then //������ ������ ���� ������ �ʵȻ���
  begin
    //������ ���೻�� ��
    if FLastReceiveData = AReceiveData then
      FLastUseSeqNo := FUseSeqNo //��õ�
    else
      FUseSeqNo := FLastUseSeqNo; //�ű�
  end;
  FLastReceiveData := AReceiveData;

  try

    try

      jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
      sApi := jObj.GetValue('api').Value;  //K408_TeeBoxReserve2
      sUserId := jObj.GetValue('user_id').Value;      //����� Id
      sMemberNo := jObj.GetValue('member_no').Value; //ȸ����ȣ	S
      sMemberNm := jObj.GetValue('member_nm').Value;

      //2020-06-01 ��ȭ��ȣ �߰� -> 2023-02-13 Ȱ��ȭ
      if jObj.FindValue('hp_no') <> nil then
        sMemberTel := jObj.GetValue('hp_no').Value;

      sReserveRootDiv := jObj.GetValue('reserve_root_div').Value; //����߱ǰ�α���	S	K	K:Ű����ũ, P:����, M:�����

      //2021-04-21
      sXgUserKey := EmptyStr;
      if sReserveRootDiv = 'M' then
        sXgUserKey := jObj.GetValue('xg_user_key').Value;

      sReceiptNo := jObj.GetValue('receipt_no').Value; //��������ȣ	receipt_no
      sAffiliateCd := jObj.GetValue('affiliate_cd').Value; //���޻��ڵ�	affiliate_cd

      jReciveObjArr := jObj.GetValue('data') as TJsonArray;

      //if Global.ADConfig.StoreCode = 'A4001' then //����
      if (Global.Store.StartTime > Global.Store.EndTime) then
        sUseSeqDate := FUseSeqDate
      else
        sUseSeqDate := FormatDateTime('YYYYMMDD', Now);

      //2020-07-13 v15 DB ��ȸ�κ� ����
      rSeatUseReserveList := TList<TSeatUseReserve>.Create;

      nProductListSize := jReciveObjArr.Size;
      SetLength(ASeatUseInfoArr, nProductListSize);
      for nIndex := 0 to nProductListSize - 1 do
      begin
        jReciveItemObj := jReciveObjArr.Get(nIndex) as TJSONObject;

        sPurchaseCd := jReciveItemObj.GetValue('purchase_cd').Value;  //�����ڵ�		purchase_cd		S	506
        sProductCd := jReciveItemObj.GetValue('product_cd').Value;    //Ÿ����ǰ�ڵ�		product_cd		S	52
        sProductNm := jReciveItemObj.GetValue('product_nm').Value;

        //2020-08-20 R:��ȸ��, C:����ȸ�� -> 1:����Ÿ��, 2:�Ⱓȸ��, 3:����ȸ�� ��������
        //sReserveDiv := jReciveItemObj.GetValue('reserve_div').Value;
        if jReciveItemObj.GetValue('reserve_div').Value = 'R' then
          sReserveDiv := '2'
        else if jReciveItemObj.GetValue('reserve_div').Value = 'C' then
          sReserveDiv := '3'
        else
          sReserveDiv := '1';

        sTeeboxNo := jReciveItemObj.GetValue('teebox_no').Value;      //Ÿ����ȣ		teebox_no		S	20
        sAssignMin := jReciveItemObj.GetValue('assign_min').Value;    //�����ð�(��)		assign_min		S	70
        sAssignBalls := jReciveItemObj.GetValue('assign_balls').Value; //���� ����		assign_balls		S	9999
        sPrepareMin := jReciveItemObj.GetValue('prepare_min').Value;  //�غ�ð�(��)		prepare_min		S	5

        if jReciveItemObj.FindValue('available_zone_cd') <> nil then
          sAvailableZoneCd := jReciveItemObj.GetValue('available_zone_cd').Value;

        // Ȧ������ ���� �˻� 2021-09-17
        if Global.Teebox.GetTeeboxHold(sTeeboxNo, sUserId, '') = False then
        begin
          Result := '{"result_cd":"408A",' +
                     '"result_msg":"Ÿ��Ȧ�� ������ �ȵǾ����ϴ�. �ٽ� ���� ���μ����� �������ּ���."}';

          Global.Teebox.TeeboxReserveUse := False;
          Exit;
        end;

        rSeatInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));

        sPossibleReserveDatetime := Global.XGolfDM.SelectPossibleReserveDatetime(sTeeboxNo);
        sPossibleReserveDatetimeChk := '';  //2022-07-04
        if ( sPossibleReserveDatetime = '' ) or (sPossibleReserveDatetime < FormatDateTime('YYYYMMDDhhnn00', Now)) then //2021-06-11 ��00 ǥ��-�̼����̻��
        begin
          sPossibleReserveDatetime := FormatDateTime('YYYYMMDDhhnn00', Now); //2021-06-11 ��00 ǥ��-�̼����̻��

          if Global.Store.ReserveTimeYn = 'Y' then
          begin
            if Copy(sPossibleReserveDatetime, 9, 4) < Global.Store.ReserveStartTime then
            begin
              sPossibleReserveDatetime := Copy(sPossibleReserveDatetime, 1, 8) + Global.Store.ReserveStartTime + '00';
            end;
          end;

          //2021-04-19 ���翹��ð� ����
          if (rSeatInfo.UseStatus = '1') then
          begin
            sPossibleReserveDatetimeChk := Global.Teebox.GetTeeboxNowReserveLastTime(sTeeboxNo);
            if sPossibleReserveDatetime < sPossibleReserveDatetimeChk then
            begin
              sLog := 'SetTeeboxNowReserve Time : ' + sTeeboxNo + ' / ' + sPossibleReserveDatetime + ' -> ' + sPossibleReserveDatetimeChk;
              Global.Log.LogErpApiWrite(sLog);
              sPossibleReserveDatetime := sPossibleReserveDatetimeChk;
            end;
          end;
        end
        else
        begin
          //2020-05-31 ����ð� ����
          sPossibleReserveDatetimeChk := Global.ReserveList.GetTeeboxReserveLastTime(sTeeboxNo);
          if sPossibleReserveDatetime < sPossibleReserveDatetimeChk then
          begin
            sLog := 'SetTeeboxReserve Time : ' + sTeeboxNo + ' / ' + sPossibleReserveDatetime + ' -> ' + sPossibleReserveDatetimeChk;
            Global.Log.LogErpApiWrite(sLog);
            sPossibleReserveDatetime := sPossibleReserveDatetimeChk;
          end;
        end;

        // ����� ������ ��� ��������ð��� ��������ð� �ʰ����� Ȯ��
        if sReserveRootDiv = 'M' then
        begin
          if ReserveEndTimeCheck(sPossibleReserveDatetime, sPrepareMin, sAssignMin) = False then
          begin
            Result := '{"result_cd":"AD99",' +
                       '"result_msg":"���� ��������ð��� ��������ð��� �ʰ��Ͽ����ϴ�. �ٽ� ���� ���μ����� �������ּ���."}';

            Global.Teebox.TeeboxReserveUse := False;
            Exit;
          end;
        end;

        //2020-05-29 ��õ� ���� �����ȣ �ӽû���
        FLastUseSeqNo := FLastUseSeqNo + 1;

        ASeatUseInfoArr[nIndex].UseSeqDate := sUseSeqDate;
        ASeatUseInfoArr[nIndex].UseSeqNo := FLastUseSeqNo;
        ASeatUseInfoArr[nIndex].ReserveNo := ASeatUseInfoArr[nIndex].UseSeqDate + StrZeroAdd(IntToStr(ASeatUseInfoArr[nIndex].UseSeqNo), 4);
        ASeatUseInfoArr[nIndex].StoreCd := Global.ADConfig.StoreCode;
        ASeatUseInfoArr[nIndex].SeatNo := StrToInt(sTeeboxNo);
        ASeatUseInfoArr[nIndex].SeatNm := rSeatInfo.TeeboxNm;
        ASeatUseInfoArr[nIndex].SeatUseStatus := '4';  // 4: ����
        ASeatUseInfoArr[nIndex].UseDiv := '1';     // 1:����, 2:�߰�
        ASeatUseInfoArr[nIndex].MemberSeq := sMemberNo;
        ASeatUseInfoArr[nIndex].MemberNm := sMemberNm;
        ASeatUseInfoArr[nIndex].MemberTel := sMemberTel;
        ASeatUseInfoArr[nIndex].PurchaseSeq := StrToInt(sPurchaseCd);
        ASeatUseInfoArr[nIndex].ProductSeq := StrToInt(sProductCd);
        ASeatUseInfoArr[nIndex].ProductNm := sProductNm;
        ASeatUseInfoArr[nIndex].ReserveDiv := sReserveDiv;
        ASeatUseInfoArr[nIndex].ReceiptNo := sReceiptNo;
        ASeatUseInfoArr[nIndex].AssignMin := StrToInt(sAssignMin);
        ASeatUseInfoArr[nIndex].AssignBalls := StrToInt(sAssignBalls);
        ASeatUseInfoArr[nIndex].PrepareMin := StrToInt(sPrepareMin);
        ASeatUseInfoArr[nIndex].ReserveDate := sPossibleReserveDatetime;
        ASeatUseInfoArr[nIndex].ReserveRootDiv := sReserveRootDiv;
        ASeatUseInfoArr[nIndex].RegId := sUserId;
        ASeatUseInfoArr[nIndex].AffiliateCd := sAffiliateCd;
        ASeatUseInfoArr[nIndex].XgUserKey := sXgUserKey;
        ASeatUseInfoArr[nIndex].AssignYn := 'Y';

        if (Global.ADConfig.CheckInUse = 'Y') then
        begin
          if (sReserveDiv = '2') and
             ((sReserveRootDiv = 'M') or (sReserveRootDiv = 'T')) then
            ASeatUseInfoArr[nIndex].AssignYn := 'N'
          else
            ASeatUseInfoArr[nIndex].AssignYn := 'Y';
        end;

        dtReserveStartTmTemp := DateStrToDateTime3(sPossibleReserveDatetime) + (((1/24)/60) * ASeatUseInfoArr[nIndex].PrepareMin);
        ASeatUseInfoArr[nIndex].StartTime := FormatDateTime('YYYYMMDDhhnnss', dtReserveStartTmTemp);

        ASeatUseInfoArr[nIndex].LessonProNm := '';
        ASeatUseInfoArr[nIndex].LessonProPosColor := '';
        ASeatUseInfoArr[nIndex].AvailableZoneCd := sAvailableZoneCd;

        if Global.Store.UseRewardYn <> 'Y' then //�׸��ʵ�, ������,�Ľ���
        begin
          sReceRemainMin := IntToStr(ASeatUseInfoArr[nIndex].AssignMin);
          {
          //��ȸ�� �ð�üũ
          if Global.Store.BallRecallTime > 0 then
          begin
            bBallRecallTimeCheck := False;

            if Global.ADConfig.StoreCode = 'B9001' then //�Ľ���
            begin
              bBallRecallTimeCheck := BallRecallTimeCheckMulti(ASeatUseInfoArr[nIndex]);
            end
            else if (Global.ADConfig.StoreCode = 'B7001') then //B7001	�����ڰ���������
            begin
              if ASeatUseInfoArr[nIndex].SeatNo <= 52 then
                bBallRecallTimeCheck := BallRecallTimeCheck(ASeatUseInfoArr[nIndex]);
            end
            else
            begin
              bBallRecallTimeCheck := BallRecallTimeCheck(ASeatUseInfoArr[nIndex]);
            end;

            if bBallRecallTimeCheck = True then
            begin
              ASeatUseInfoArr[nIndex].AssignMin := ASeatUseInfoArr[nIndex].AssignMin + Global.Store.BallRecallTime;

              sLog := 'BallRecallTime change : ' + ASeatUseInfoArr[nIndex].ReserveNo + ' / ' + inttostr(ASeatUseInfoArr[nIndex].SeatNo) + ' / ' + sReceRemainMin + ' -> ' +
                      IntToStr(ASeatUseInfoArr[nIndex].AssignMin);
              Global.Log.LogReserveWrite(sLog);
            end;
          end;
          }
          //chy 2023-11-28 2ȸ��ȸ���� ����
          //��ȸ�� �ð�üũ
          nBallRecallTime := 0;
          bBallRecallTimeCheck := False;

          if Global.ADConfig.StoreCode = 'B9001' then //�Ľ���
          begin
            if Global.Store.BallRecallTime > 0 then
            begin
              nBallRecallTime := Global.Store.BallRecallTime;
              bBallRecallTimeCheck := BallRecallTimeCheckMulti(ASeatUseInfoArr[nIndex]);
            end;
          end
          else if (Global.ADConfig.StoreCode = 'B7001') then //B7001	�����ڰ���������
          begin
            if Global.Store.BallRecallTime > 0 then
            begin
              if ASeatUseInfoArr[nIndex].SeatNo <= 52 then
              begin
                nBallRecallTime := Global.Store.BallRecallTime;
                bBallRecallTimeCheck := BallRecallTimeCheck(ASeatUseInfoArr[nIndex], global.Store.BallRecallStartTime, global.Store.BallRecallEndTime);
              end;
            end;
          end
          else if (Global.ADConfig.StoreCode = 'B2001') or (Global.ADConfig.StoreCode = 'BB001') then // B2001	�׸��ʵ���������� / BB001	������
          begin
            if Global.Store.BallRecallTime > 0 then
            begin
              nBallRecallTime := Global.Store.BallRecallTime;
              bBallRecallTimeCheck := BallRecallTimeCheck(ASeatUseInfoArr[nIndex], global.Store.BallRecallStartTime, global.Store.BallRecallEndTime);
            end;
          end
          else
          begin
            if rSeatInfo.ControlYn = 'Y' then
            begin
              if (Global.Store.BallRecallYn = True) and (Global.Store.BallRecallTime > 0) then
              begin
                nBallRecallTime := Global.Store.BallRecallTime;
                bBallRecallTimeCheck := BallRecallTimeCheck(ASeatUseInfoArr[nIndex], global.Store.BallRecallStartTime, global.Store.BallRecallEndTime);
              end;

              if bBallRecallTimeCheck = False then // 1��° ��ȸ�� Ȯ����
              begin
                if ((Global.Store.BallRecall2Yn = True) and (Global.Store.BallRecall2Time > 0)) then
                begin
                  nBallRecallTime := Global.Store.BallRecall2Time;
                  bBallRecallTimeCheck := BallRecallTimeCheck(ASeatUseInfoArr[nIndex], global.Store.BallRecall2StartTime, global.Store.BallRecall2EndTime);
                end;
              end;
            end;
          end;

          if bBallRecallTimeCheck = True then
          begin
            ASeatUseInfoArr[nIndex].AssignMin := ASeatUseInfoArr[nIndex].AssignMin + nBallRecallTime;

            sLog := 'BallRecallTime change : ' + ASeatUseInfoArr[nIndex].ReserveNo + ' / ' + inttostr(ASeatUseInfoArr[nIndex].SeatNo) + ' / ' + sReceRemainMin + ' -> ' +
                    IntToStr(ASeatUseInfoArr[nIndex].AssignMin);
            Global.Log.LogReserveWrite(sLog);
          end;

        end;

        if Global.ADConfig.StoreCode = 'B2001' then //�׸��ʵ�
        begin
          if sReserveDiv = '2' then
          begin
            if StrPos(PChar(sProductNm), PChar('�ְ�-')) <> nil then
            begin
              dtReserveEndTmTemp := DateStrToDateTime3(ASeatUseInfoArr[nIndex].ReserveDate) +
                                    (((1/24)/60) * (ASeatUseInfoArr[nIndex].AssignMin + ASeatUseInfoArr[nIndex].PrepareMin));
              if FormatDateTime('hhnnss', dtReserveEndTmTemp) > '173000'  then
              begin
                dtReserveEndTmTemp1 := DateStrToDateTime3(FormatDateTime('YYYYMMDD', Now) + '173000');
                nNNTemp := MinutesBetween(dtReserveEndTmTemp, dtReserveEndTmTemp1);
                ASeatUseInfoArr[nReIndex].AssignMin := ASeatUseInfoArr[nIndex].AssignMin - nNNTemp;

                sLog := 'AssignMin change : ' + ASeatUseInfoArr[nIndex].ReserveNo + ' / ' + inttostr(ASeatUseInfoArr[nIndex].SeatNo) + ' / ' + sReceRemainMin + ' -> ' +
                        IntToStr(ASeatUseInfoArr[nIndex].AssignMin);
                Global.Log.LogReserveWrite(sLog);
              end;
            end;
          end;

        end;

      end;
    except
      on e: Exception do
      begin
        Result := '{"result_cd":"0004",' +
                   '"result_msg":"�������� ��ְ� �߻��Ͽ����ϴ� ' + e.Message + '"}';

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;

    end;

    try

      if Global.ADConfig.Emergency = False then
      begin

        //Erp ���� ��������
        jErpSeObjArr := TJSONArray.Create;
        jErpSeObj := TJSONObject.Create;
        jErpSeObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
        jErpSeObj.AddPair(TJSONPair.Create('member_no', sMemberNo));
        jErpSeObj.AddPair(TJSONPair.Create('reserve_root_div', sReserveRootDiv));
        jErpSeObj.AddPair(TJSONPair.Create('user_id', sUserId));
        jErpSeObj.AddPair(TJSONPair.Create('memo', ''));
        jErpSeObj.AddPair(TJSONPair.Create('data', jErpSeObjArr));

        for nIndex := 0 to nProductListSize - 1 do
        begin
          jErpSeItemObj := TJSONObject.Create;
          jErpSeItemObj.AddPair( TJSONPair.Create( 'teebox_no', IntToStr(ASeatUseInfoArr[nIndex].SeatNo) ) );
          jErpSeItemObj.AddPair( TJSONPair.Create( 'reserve_no', ASeatUseInfoArr[nIndex].ReserveNo ) );
          jErpSeItemObj.AddPair( TJSONPair.Create( 'purchase_cd', IntToStr(ASeatUseInfoArr[nIndex].PurchaseSeq) ) );
          jErpSeItemObj.AddPair( TJSONPair.Create( 'product_cd', IntToStr(ASeatUseInfoArr[nIndex].ProductSeq) ) );
          jErpSeItemObj.AddPair( TJSONPair.Create( 'assign_min', IntToStr(ASeatUseInfoArr[nIndex].AssignMin) ) );
          jErpSeItemObj.AddPair( TJSONPair.Create( 'prepare_min', IntToStr(ASeatUseInfoArr[nIndex].PrepareMin) ) );
          jErpSeItemObj.AddPair( TJSONPair.Create( 'assign_balls', IntToStr(ASeatUseInfoArr[nIndex].AssignBalls ) ) );
          jErpSeItemObj.AddPair( TJSONPair.Create( 'reserve_datetime', ASeatUseInfoArr[nIndex].ReserveDate ) );
          jErpSeObjArr.Add(jErpSeItemObj);

          sReserveNoTemp := sReserveNoTemp + '/' + ASeatUseInfoArr[nIndex].ReserveNo;
        end;

        //Erp ��������
        sResult := Global.Api.SetErpApiJsonData(jErpSeObj.ToString, 'K701_TeeboxReserve', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
        sJsonStr := sResult;

        //Global.Log.LogErpApiWrite(sResult);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetSeatReserve Fail : ' + sReserveNoTemp + ' / ' + sResult;
          Global.Log.LogErpApiWrite(sLog);

          sLog := jErpSeObj.ToString;
          Global.Log.LogErpApiWrite(sLog);

          Result := '{"result_cd":"0002",' +
                     //'"result_msg":"' + sResult + '"}';
                     '"result_msg":"���೻���� ������ ����� ��ְ� �߻��Ͽ����ϴ�."}';

          Global.Teebox.TeeboxReserveUse := False;
          Exit;
        end;

        jErpRvObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
        sErpRvResultCd := jErpRvObj.GetValue('result_cd').Value;
        sErpRvResultMsg := jErpRvObj.GetValue('result_msg').Value;

        sLog := 'K701_TeeBoxReserve : ' + sReserveNoTemp + ' / ' + sErpRvResultCd + ' / ' + sErpRvResultMsg;
        //sLog := 'K701_TeeBoxReserve : ' + sReserveNoTemp + ' / ' + sResult;
        Global.Log.LogErpApiWrite(sLog);

        if sErpRvResultCd <> '0000' then
        begin
          //2020-05-28 : �Ⱓ��,���� ��õ�
          if (sErpRvResultCd = '8006') and //���� �����ȣ
             //2020-08-20 R:��ȸ��, C:����ȸ�� -> 1:����Ÿ��, 2:�Ⱓȸ��, 3:����ȸ�� ��������
             //((sReserveDiv = 'R') or (sReserveDiv = 'C')) then //�Ⱓ��, ����
             ((sReserveDiv = '2') or (sReserveDiv = '3')) then //�Ⱓ��, ����
          begin
            //2023-07-28 M : ������� ���-������ ��ǥ
            if (sReserveRootDiv = 'M') then
            begin
              Result := '{"result_cd":"' + sErpRvResultCd + '",' +
                        '"result_msg":"' + sErpRvResultMsg + '"}';

              for nIndex := 0 to nProductListSize - 1 do
              begin
                Global.Teebox.SetTeeboxHold(IntToStr(ASeatUseInfoArr[nIndex].SeatNo), sUserId, False);
                Global.XGolfDM.TeeboxHoldDelete(sUserId, IntToStr(ASeatUseInfoArr[nIndex].SeatNo));
              end;

              Global.Teebox.TeeboxReserveUse := False;
              Exit;
            end
            else
            begin
              //����������� �Ǵ�, DB�� �����Ѵ�.
              sLog := 'K701_TeeBoxReserve Retry : ' + sReserveNoTemp;
              Global.Log.LogErpApiWrite(sLog);
            end;
          end
          else
          begin
            Result := '{"result_cd":"' + sErpRvResultCd + '",' +
                       '"result_msg":"' + sErpRvResultMsg + '"}';

            //2021-06-30 M : ������� ��� �ڵ� 9999 �̸� �ӽÿ��� ���ó��-������ ��ǥ
            if (sReserveRootDiv = 'M') and (sErpRvResultCd = '9999') then
            begin
              for nIndex := 0 to nProductListSize - 1 do
              begin
                Global.Teebox.SetTeeboxHold(IntToStr(ASeatUseInfoArr[nIndex].SeatNo), sUserId, False);
                Global.XGolfDM.TeeboxHoldDelete(sUserId, IntToStr(ASeatUseInfoArr[nIndex].SeatNo));
              end;
            end;

            Global.Teebox.TeeboxReserveUse := False;
            Exit;
          end;

        end;
      end;
      
    except
      //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
      on e: Exception do
      begin
        sLog := 'SetSeatReserve Exception : ' + ASeatUseInfoArr[0].ReserveNo + ' / ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);

        Result := '{"result_cd":"0003",' +
                   '"result_msg":"�������� ��ְ� �߻��Ͽ����ϴ� ' + e.Message + '"}';
        //Global.XGolfDM.RollbackTrans;

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;
    end;

    FUseSeqNo := FLastUseSeqNo;

    //2020-07-13 client �������� ����
    //rSeatUseReserveList := Global.XGolfDM.SelectTeeboxReservationOneWithSeqList(aUseSeqList);

    jSendObjArr := TJSONArray.Create;
    jSendObj := TJSONObject.Create;
    jSendObj.AddPair(TJSONPair.Create('result_cd', '0000'));
    jSendObj.AddPair(TJSONPair.Create('result_msg', 'Success'));

    if Global.ADConfig.Emergency = False then
    begin

      jSendObj.AddPair(TJSONPair.Create('data', jSendObjArr));

      if not (jErpRvObj.FindValue('result_data') is TJSONNull) then
      begin
        JV := jErpRvObj.Get('result_data').JsonValue;

        sLessonProNm := (JV as TJSONObject).Get('lesson_pro_nm').JsonValue.Value;
        sLessonProPosColor := (JV as TJSONObject).Get('lesson_pro_pos_color').JsonValue.Value;

        JV := (JV as TJSONObject).Get('dataList').JsonValue;
        nCount := (JV as TJSONArray).Count;

        for I := 0 to nCount - 1 do
        begin
          jSendItemObj := TJSONObject.Create;
          jSendItemObj.AddPair( TJSONPair.Create( 'reserve_no', (JV as TJSONArray).Items[i].P['reserve_no'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'purchase_cd', (JV as TJSONArray).Items[i].P['purchase_cd'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'product_cd', (JV as TJSONArray).Items[i].P['product_cd'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'product_nm', (JV as TJSONArray).Items[i].P['product_nm'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'product_div', (JV as TJSONArray).Items[i].P['product_div'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'floor_nm', (JV as TJSONArray).Items[i].P['floor_nm'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'teebox_nm', (JV as TJSONArray).Items[i].P['teebox_nm'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'reserve_datetime', (JV as TJSONArray).Items[i].P['reserve_datetime'].Value) );
          
          bStartTm := False;
          for nReIndex := 0 to nProductListSize - 1 do
          begin
            if (JV as TJSONArray).Items[i].P['reserve_no'].Value = ASeatUseInfoArr[nReIndex].ReserveNo then
            begin
              sDate := Copy(ASeatUseInfoArr[nReIndex].StartTime, 1, 4) + '-' +
                       Copy(ASeatUseInfoArr[nReIndex].StartTime, 5, 2) + '-' +
                       Copy(ASeatUseInfoArr[nReIndex].StartTime, 7, 2) + ' ' +
                       Copy(ASeatUseInfoArr[nReIndex].StartTime, 9, 2) + ':' +
                       Copy(ASeatUseInfoArr[nReIndex].StartTime, 11, 2) + ':' +
                       Copy(ASeatUseInfoArr[nReIndex].StartTime, 13, 2);
              jSendItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate ) );

              ASeatUseInfoArr[nReIndex].LessonProNm := sLessonProNm;
              ASeatUseInfoArr[nReIndex].LessonProPosColor := sLessonProPosColor;

              ASeatUseInfoArr[nReIndex].ExpireDay := (JV as TJSONArray).Items[i].P['expire_day'].Value;
              ASeatUseInfoArr[nReIndex].CouponCnt := (JV as TJSONArray).Items[i].P['coupon_cnt'].Value;
              ASeatUseInfoArr[nReIndex].AccessBarcode := (JV as TJSONArray).Items[i].P['access_barcode'].Value;
              ASeatUseInfoArr[nReIndex].AccessControlNm := (JV as TJSONArray).Items[i].P['access_control_nm'].Value;

              bStartTm := True;
              Break;
            end;
          end;

          //2020-07-02 ���۽ð� Ȯ��
          if bStartTm = False then
          begin
            sReserveTmTemp := (JV as TJSONArray).Items[i].P['reserve_datetime'].Value;
            dtReserveStartTmTemp := DateStrToDateTime2(sReserveTmTemp) + (((1/24)/60) * StrToInt(sPrepareMin));
            sDate := FormatDateTime('YYYY-MM-DD hh:nn:ss', dtReserveStartTmTemp);
            jSendItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate ) );

            sLog := 'SetTeeboxReserve StartTm : ' + sReserveTmTemp + ' / ' + sDate;
            Global.Log.LogErpApiWrite(sLog);
          end;

          jSendItemObj.AddPair( TJSONPair.Create( 'remain_min', (JV as TJSONArray).Items[i].P['remain_min'].Value) );
          //sReceRemainMin := (JV as TJSONArray).Items[i].P['remain_min'].Value;

          jSendItemObj.AddPair( TJSONPair.Create( 'expire_day', (JV as TJSONArray).Items[i].P['expire_day'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', (JV as TJSONArray).Items[i].P['coupon_cnt'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'access_barcode', (JV as TJSONArray).Items[i].P['access_barcode'].Value) );
          jSendItemObj.AddPair( TJSONPair.Create( 'access_control_nm', (JV as TJSONArray).Items[i].P['access_control_nm'].Value) );

          jSendSubObjArr := TJSONArray.Create;
          jSendItemObj.AddPair(TJSONPair.Create('coupon', jSendSubObjArr));

          // ������� ��ǥ�� ����-2021-03-29 ����������

          jSendObjArr.Add(jSendItemObj);

        end;

      end;

    end
    else
    begin

      jSendObj.AddPair(TJSONPair.Create('data', jSendObjArr));

      for nIndex := 0 to nProductListSize - 1 do
      begin
        jSendItemObj := TJSONObject.Create;
        jSendItemObj.AddPair( TJSONPair.Create( 'reserve_no', ASeatUseInfoArr[nIndex].ReserveNo ) );
        jSendItemObj.AddPair( TJSONPair.Create( 'purchase_cd', IntToStr(ASeatUseInfoArr[nIndex].PurchaseSeq) ) );
        jSendItemObj.AddPair( TJSONPair.Create( 'product_cd', IntTOStr(ASeatUseInfoArr[nIndex].ProductSeq) ) );
        jSendItemObj.AddPair( TJSONPair.Create( 'product_nm', ASeatUseInfoArr[nIndex].ProductNm ) );

        if ASeatUseInfoArr[nIndex].ReserveDiv = '2' then
          jSendItemObj.AddPair( TJSONPair.Create( 'product_div', 'R' ) )
        else if ASeatUseInfoArr[nIndex].ReserveDiv = '3' then
          jSendItemObj.AddPair( TJSONPair.Create( 'product_div', 'C' ) )
        else
          jSendItemObj.AddPair( TJSONPair.Create( 'product_div', 'D' ) );

        jSendItemObj.AddPair( TJSONPair.Create( 'floor_nm', ASeatUseInfoArr[nIndex].FloorNm ) );
        jSendItemObj.AddPair( TJSONPair.Create( 'teebox_nm', ASeatUseInfoArr[nIndex].SeatNm ) );

        sDate := Copy(ASeatUseInfoArr[nIndex].ReserveDate, 1, 4) + '-' +
                 Copy(ASeatUseInfoArr[nIndex].ReserveDate, 5, 2) + '-' +
                 Copy(ASeatUseInfoArr[nIndex].ReserveDate, 7, 2) + ' ' +
                 Copy(ASeatUseInfoArr[nIndex].ReserveDate, 9, 2) + ':' +
                 Copy(ASeatUseInfoArr[nIndex].ReserveDate, 11, 2) + ':' +
                 Copy(ASeatUseInfoArr[nIndex].ReserveDate, 13, 2);
        jSendItemObj.AddPair( TJSONPair.Create( 'reserve_datetime', sDate ) );

        sDate := Copy(ASeatUseInfoArr[nIndex].StartTime, 1, 4) + '-' +
                 Copy(ASeatUseInfoArr[nIndex].StartTime, 5, 2) + '-' +
                 Copy(ASeatUseInfoArr[nIndex].StartTime, 7, 2) + ' ' +
                 Copy(ASeatUseInfoArr[nIndex].StartTime, 9, 2) + ':' +
                 Copy(ASeatUseInfoArr[nIndex].StartTime, 11, 2) + ':' +
                 Copy(ASeatUseInfoArr[nIndex].StartTime, 13, 2);
        jSendItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate ) );

        jSendItemObj.AddPair( TJSONPair.Create( 'remain_min', IntToStr(ASeatUseInfoArr[nIndex].RemainMin) ) );
        jSendItemObj.AddPair( TJSONPair.Create( 'expire_day', '' ) );
        jSendItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', '' ) );
        jSendItemObj.AddPair( TJSONPair.Create( 'access_barcode', '' ) );
        jSendItemObj.AddPair( TJSONPair.Create( 'access_control_nm', '' ) );

        jSendSubObjArr := TJSONArray.Create;
        jSendItemObj.AddPair(TJSONPair.Create('coupon', jSendSubObjArr));

        jSendObjArr.Add(jSendItemObj);

      end;

    end;

    //�׸��ʵ� ��ġ����
    for nIndex := 0 to nProductListSize - 1 do
    begin
      //2020-07-13 DB ��ȸ�κ� ����
      SeatUseReserveTemp.ReserveNo := ASeatUseInfoArr[nIndex].ReserveNo;
      SeatUseReserveTemp.SeatNo := ASeatUseInfoArr[nIndex].SeatNo;
      SeatUseReserveTemp.UseMinute := ASeatUseInfoArr[nIndex].AssignMin;
      SeatUseReserveTemp.UseBalls := ASeatUseInfoArr[nIndex].AssignBalls;
      SeatUseReserveTemp.DelayMinute := ASeatUseInfoArr[nIndex].PrepareMin;
      SeatUseReserveTemp.ReserveDate := ASeatUseInfoArr[nIndex].ReserveDate;
      SeatUseReserveTemp.AssignYn := ASeatUseInfoArr[nIndex].AssignYn;
      SeatUseReserveTemp.StartTime := ASeatUseInfoArr[nIndex].StartTime;
      rSeatUseReserveList.Add(SeatUseReserveTemp);
    end;

    //2021-07-28 DB ������ġ ����
    sReserveSql := '';
    for nIndex := 0 to nProductListSize - 1 do
    begin
      sReserveSql := sReserveSql + SetTeeboxReserveSql(ASeatUseInfoArr[nIndex]);

      SetLength(aUseSeqList, Length(aUseSeqList) + 1);
      aUseSeqList[Length(aUseSeqList) - 1] := ASeatUseInfoArr[nIndex].UseSeqNo;

      Global.Teebox.SetTeeboxHold(IntToStr(ASeatUseInfoArr[nIndex].SeatNo), sUserId, False);
      Global.XGolfDM.TeeboxHoldDelete(sUserId, IntToStr(ASeatUseInfoArr[nIndex].SeatNo));
    end;

    //���೻�� DB ����
    sResult := Global.XGolfDM.TeeboxUseInsert(sReserveSql);
    //sResult := Global.XGolfDM.TeeboxUseArrInsert(ASeatUseInfoArr);
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"0004",' +
                 '"result_msg":"DB ���忡 �����Ͽ����ϴ� ' + sResult + '"}';

      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;
    Global.ReserveDBWrite := True;

    Result := jSendObj.ToString;

    //�������
    for nIndex := 0 to rSeatUseReserveList.Count - 1 do
    begin
      if rSeatUseReserveList[nIndex].ReserveDate <= FormatDateTime('YYYYMMDDhhnn00', Now) then //2021-06-11 ��00 ǥ��-�̼����̻��
        Global.Teebox.SetTeeboxReserveInfo(rSeatUseReserveList[nIndex])
      else
        global.ReserveList.SetTeeboxReserveNext(rSeatUseReserveList[nIndex]);
    end;
    
    sleep(50); //chy 2021-10-10 ������
  finally
    FreeAndNil(jErpSeObj);

    FreeAndNil(jObj);
    FreeAndNil(jErpRvObj);
    FreeAndNil(jSendObj);

    FreeAndNil(rSeatUseReserveList);

    Global.Teebox.TeeboxReserveUse := False;
  end;

end;

function TTcpServer.SetTeeboxReserveSql(ASeatUseInfo: TSeatUseInfo; AMove: Boolean = False; ACutIn: Boolean = False): String; //Ÿ���� ��������������
var
  sSql: String;
  sMove, sCutIn: String;
begin
  Result := '';

  sMove := 'N';
  if AMove = True then
    sMove := 'Y';

  sCutIn := 'N';
  if ACutIn = True then
    sCutIn := 'Y';

  sSql :=  ' insert into seat_use ' +
             '  (  use_seq_date, use_seq_no, store_cd, use_status, seat_no, seat_nm, use_div ';
    if ASeatUseInfo.MemberSeq <> '' then
      sSql := sSql +
             '  , member_seq ';
    if ASeatUseInfo.MemberNm <> '' then
      sSql := sSql +
             '  , member_nm ';
    if ASeatUseInfo.MemberTel <> '' then
      sSql := sSql +
             '  , member_tel ';

    //2021-07-26
    if ACutIn = True then
      sSql := sSql +
             '  , reserve_cutin ';

    sSql := sSql +
             '  , XG_USER_KEY, purchase_seq, product_seq, product_nm, reserve_div, use_minute ' +
             '  , use_balls, delay_minute, reserve_date, reserve_root_div, receipt_no, reserve_move ' +
             '  , chg_date , reg_date, reg_id, assign_yn, affiliate_cd ' + //erp_json, ���� 2021-07-28 / 2021-08-06 assign_yn �߰� üũ�ο�
             '  , lesson_pro_nm , lesson_pro_pos_color, expire_day, coupon_cnt, AVAILABLE_ZONE_CD ) ' + //2021-10-05 ��������
              ' values ' +
             ' (' + QuotedStr(ASeatUseInfo.UseSeqDate) +
             ' ,' + IntToStr(ASeatUseInfo.UseSeqNo) +
             ' ,' + QuotedStr(ASeatUseInfo.StoreCd) +
             ' ,' + ASeatUseInfo.SeatUseStatus +
             ' ,' + IntToStr(ASeatUseInfo.SeatNo) +
             ' ,' + QuotedStr(ASeatUseInfo.SeatNm) +
             ' ,' + ASeatUseInfo.UseDiv;
    if ASeatUseInfo.MemberSeq <> '' then
      sSql := sSql +
             ' ,' + QuotedStr(ASeatUseInfo.MemberSeq);
    if ASeatUseInfo.MemberNm <> '' then
      sSql := sSql +
             ' ,' + QuotedStr(ASeatUseInfo.MemberNm);
    if ASeatUseInfo.MemberTel <> '' then
      sSql := sSql +
             ' ,' + QuotedStr(ASeatUseInfo.MemberTel);

    //2021-07-26
    if ACutIn = True then
      sSql := sSql +
             ' ,' + QuotedStr(sCutIn);

    sSql := sSql +
             ' ,' + QuotedStr(ASeatUseInfo.XgUserKey) +
             ' ,' + IntToStr(ASeatUseInfo.PurchaseSeq) +
             ' ,' + IntToStr(ASeatUseInfo.ProductSeq) +
             ' ,' + QuotedStr(ASeatUseInfo.ProductNm) +
             ' ,' + QuotedStr(ASeatUseInfo.ReserveDiv) +
             ' ,' + IntToStr(ASeatUseInfo.AssignMin) +
             ' ,' + IntToStr(ASeatUseInfo.AssignBalls) +
             ' ,' + IntToStr(ASeatUseInfo.PrepareMin) +
             ' , date_format(' + QuotedStr(ASeatUseInfo.ReserveDate) + ', ''%Y-%m-%d %H:%i:%S'') ' +
             ' ,' + QuotedStr(ASeatUseInfo.ReserveRootDiv) +
             ' ,' + QuotedStr(ASeatUseInfo.ReceiptNo) +

             //2021-07-05
             ' ,' + QuotedStr(sMove) +

             ' , now() ' +
             //' ,' + QuotedStr(ASeatUseInfo.Json) +  //erp_json, ���� 2021-07-28
             ' , now() ' +
             //2020-08-18
             //' ,' + QuotedStr(ASeatUseInfo.RegId) + ' ); ';
             ' ,' + QuotedStr(ASeatUseInfo.RegId) +
             ' ,' + QuotedStr(ASeatUseInfo.AssignYn) +
             ' ,' + QuotedStr(ASeatUseInfo.AffiliateCd) +

             ' ,' + QuotedStr(ASeatUseInfo.LessonProNm) +
             ' ,' + QuotedStr(ASeatUseInfo.LessonProPosColor) +
             ' ,' + QuotedStr(ASeatUseInfo.ExpireDay) +
             ' ,' + QuotedStr(ASeatUseInfo.CouponCnt) +
             ' ,' + QuotedStr(ASeatUseInfo.AvailableZoneCd) + ' ); ';

  Result := sSql;
end;

function TTcpServer.SetTeeboxReserveCancel(AReceiveData: AnsiString): AnsiString; //Ÿ���������
var
  jObj: TJSONObject;
  jRvObj: TJSONObject;
  sApi, sUserId, sReserveNo, sReserveNoTemp, sReceiptNo: String;
  sUseSeqDate, sUseSeqNo: String;
  nUseSeqNo, nIndex: Integer;
  sResult: AnsiString;
  rSeatUseInfoList: TList<TSeatUseInfo>;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog, sLogH: String;
begin
  //2020-07-23
  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiDelayWrite(sLog);

    sleep(50);
  end;

  //2020-08-14
  Global.Teebox.TeeboxReserveUse := True;

  //K410_TeeBoxReserved
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;      //����� Id
    sReserveNo := jObj.GetValue('reserve_no').Value;  //Ÿ���� ��ȣ
    sReceiptNo := jObj.GetValue('receipt_no').Value;  //��������ȣ

    sUseSeqDate := '';
    sUseSeqNo := '';
    if sReserveNo <> '' then
    begin
      sUseSeqDate := Copy(sReserveNo, 1, 8);
      nUseSeqNo := StrToInt(Copy(sReserveNo, 9, 4));
      sUseSeqNo := IntToStr(nUseSeqNo);
    end;

    rSeatUseInfoList := Global.XGolfDM.SeatUseSelectList(Global.ADConfig.StoreCode, '', sUseSeqDate, sUseSeqNo, sReceiptNo);

    for nIndex := 0 to rSeatUseInfoList.Count - 1 do
    begin

      sResult := Global.XGolfDM.DeleteTeeboxReservation(Global.ADConfig.StoreCode, sUserId, IntToStr(rSeatUseInfoList[nIndex].UseSeq));
      if sResult <> 'Success' then
      begin
        Result := '{"result_cd":"","result_msg":"' + sResult + '"}';
        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;

      sReserveNoTemp := rSeatUseInfoList[nIndex].UseSeqDate + StrZeroAdd(IntToStr(rSeatUseInfoList[nIndex].UseSeqNo), 4);

      global.Teebox.SetTeeboxReserveCancle(rSeatUseInfoList[nIndex].SeatNo, sReserveNoTemp);

      if Global.ADConfig.Emergency = False then
      begin
        try
          sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                      '&teebox_no=' + IntToStr(rSeatUseInfoList[nIndex].SeatNo) +
                      '&reserve_no=' + sReserveNoTemp +
                      '&user_id=' + sUserId +
                      '&memo=''';

          sLogH := IntToStr(rSeatUseInfoList[nIndex].SeatNo) + ' [ ' + rSeatUseInfoList[nIndex].SeatNm + ' ] ' + sReserveNoTemp;
          sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K704_TeeboxCancel', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

          if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
          begin
            sLog := 'SetSeatReserveCancel Fail : ' + sResult;
            Global.Log.LogErpApiWrite(sLog);
          end
          else
          begin
            jRvObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
            sResultCd := jRvObj.GetValue('result_cd').Value;
            sResultMsg := jRvObj.GetValue('result_msg').Value;

            sLog := 'K704_TeeboxCancel : ' + sLogH + ' / ' + sResultCd + ' / ' + sResultMsg;
            Global.Log.LogErpApiWrite(sLog);
          end;

        except
          //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
          on e: Exception do
          begin
            sLog := 'SetSeatReserveCancel Exception : ' + e.Message;
            Global.Log.LogErpApiWrite(sLog);
          end;
        end;
      end;

    end;

    Result := '{"result_cd":"0000","result_msg":"Success"}';

  finally
    FreeAndNil(jRvObj);
    FreeAndNil(jObj);
    FreeAndNil(rSeatUseInfoList);

    Global.Teebox.TeeboxReserveUse := False;
  end;

end;

function TTcpServer.SetTeeboxReserveChange(AReceiveData: AnsiString): AnsiString; //Ÿ�����ຯ��
var
  jObj: TJSONObject;
  sApi, sUserId, sReserveNo, sAssignBalls, sAssignMin, sPrepareMin, sMemo: String;
  sSeq, sSeqDate: String;
  nSeqNo: Integer;
  sResult: AnsiString;

  sDate: String;
  rSeatUseInfo: TSeatUseInfo;
  rSeatUseInfoTemp: TSeatUseInfo;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog: String;

  jSeObj, jSeItemObj: TJSONObject; //Erp ��������
  jSeSubItemObj: TJSONObject; //Erp ��������
  jSeObjArr, jSeSubObjArr: TJSONArray;

  jErpRvObj: TJSONObject;
  dtReserveStartTmTemp: TDateTime;
begin

  //2020-08-14
  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiDelayWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;

  //K411_TeeBoxReserved
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sReserveNo := jObj.GetValue('reserve_no').Value;     //  �����ȣ	reserve_no			S	T29433062
    sUserId := jObj.GetValue('user_id').Value;           //����� ID	user_id			S	admin5
    sAssignBalls := jObj.GetValue('assign_balls').Value; //���� ����	assign_balls			S	9999
    sAssignMin := jObj.GetValue('assign_min').Value;     //�����ð�(��)	assign_min			S	80
    sPrepareMin := jObj.GetValue('prepare_min').Value;  //�غ�ð�(��)	prepare_min			S	10
    sMemo := jObj.GetValue('memo').Value;               //�޸�	memo			S

    sSeqDate := Copy(sReserveNo, 1, 8);
    nSeqNo := StrToInt(Copy(sReserveNo, 9, 4));
    rSeatUseInfo := Global.XGolfDM.SelectTeeboxReservationOneWithSeq(Global.ADConfig.StoreCode, sSeqDate, IntToStr(nSeqNo));

    if ( rSeatUseInfo.UseSeq = -1 ) then
    begin
      Result := '{"result_cd":"411A","result_msg":"���������� ã���� �����ϴ�!"}';
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    rSeatUseInfo.ReserveNo := sReserveNo;

    //�����ð��� �߰��ð� �߰�
    if rSeatUseInfo.SeatUseStatus = '4' then
      rSeatUseInfo.AssignMin := StrToInt(sAssignMin)
    else
      rSeatUseInfo.AssignMin := rSeatUseInfo.AssignMin + ( StrToInt(sAssignMin) - rSeatUseInfo.RemainMin );

    rSeatUseInfo.AssignBalls := StrToInt(sAssignBalls);
    rSeatUseInfo.PrepareMin := StrToInt(sPrepareMin);
    rSeatUseInfo.Memo := sMemo;
    rSeatUseInfo.ChgId := sUserId;

    sResult := Global.XGolfDM.SeatUseChangeUdate(rSeatUseInfo); // POS/KIOSK �� Update
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"411B","result_msg":"����ð� ���濡 �����Ͽ����ϴ�."}';
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    rSeatUseInfoTemp := Global.XGolfDM.SelectTeeboxReservationOneWithSeq(Global.ADConfig.StoreCode, sSeqDate, IntToStr(nSeqNo));

    //2020-07-02 rSeatUseInfoTemp ����������
    if rSeatUseInfoTemp.UseSeq = -1 then
    begin
      rSeatUseInfoTemp.ReserveNo := sSeqDate + StrZeroAdd(IntToStr(nSeqNo), 4);
      dtReserveStartTmTemp := DateStrToDateTime3(rSeatUseInfo.ReserveDate) + (((1/24)/60) * rSeatUseInfo.PrepareMin);
      rSeatUseInfoTemp.StartTime := FormatDateTime('YYYYMMDDhhnn00', dtReserveStartTmTemp); //2021-06-11

      sLog := 'SetSeatReserveChange reset : ' + rSeatUseInfoTemp.ReserveNo + ' / ' + rSeatUseInfoTemp.StartTime;
      Global.Log.LogErpApiWrite(sLog);
    end;

    jSeObj := TJSONObject.Create;
    jSeObj.AddPair(TJSONPair.Create('result_cd', '0000'));
    jSeObj.AddPair(TJSONPair.Create('result_msg', 'Success'));
    jSeObjArr := TJSONArray.Create;
    jSeObj.AddPair(TJSONPair.Create('data', jSeObjArr));
    
    jSeItemObj := TJSONObject.Create;
    jSeItemObj.AddPair( TJSONPair.Create( 'reserve_no', rSeatUseInfoTemp.ReserveNo) );
    jSeItemObj.AddPair( TJSONPair.Create( 'purchase_cd', IntToStr(rSeatUseInfoTemp.PurchaseSeq)) );
    jSeItemObj.AddPair( TJSONPair.Create( 'product_cd', IntToStr(rSeatUseInfoTemp.ProductSeq)) );
    jSeItemObj.AddPair( TJSONPair.Create( 'product_nm', rSeatUseInfoTemp.ProductNm) );

    if rSeatUseInfoTemp.ReserveDiv = '2' then
      jSeItemObj.AddPair( TJSONPair.Create( 'product_div', 'R') )
    else if rSeatUseInfoTemp.ReserveDiv = '3' then
      jSeItemObj.AddPair( TJSONPair.Create( 'product_div', 'C') )
    else
      jSeItemObj.AddPair( TJSONPair.Create( 'product_div', 'D') );

    jSeItemObj.AddPair( TJSONPair.Create( 'floor_nm', global.Teebox.GetTeeboxFloorNm(rSeatUseInfo.SeatNo)) );
    jSeItemObj.AddPair( TJSONPair.Create( 'teebox_nm', rSeatUseInfo.SeatNm) );

    sDate := Copy(rSeatUseInfoTemp.StartTime, 1, 4) + '-' +
             Copy(rSeatUseInfoTemp.StartTime, 5, 2) + '-' +
             Copy(rSeatUseInfoTemp.StartTime, 7, 2) + ' ' +
             Copy(rSeatUseInfoTemp.StartTime, 9, 2) + ':' +
             Copy(rSeatUseInfoTemp.StartTime, 11, 2) + ':' +
             Copy(rSeatUseInfoTemp.StartTime, 13, 2);

    jSeItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate) );
    jSeItemObj.AddPair( TJSONPair.Create( 'remain_min', sAssignMin) );
    jSeItemObj.AddPair( TJSONPair.Create( 'expire_day', rSeatUseInfo.ExpireDay) );
    jSeItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', rSeatUseInfo.CouponCnt) );

    jSeSubObjArr := TJSONArray.Create;
    jSeItemObj.AddPair(TJSONPair.Create('coupon', jSeSubObjArr));

    jSeObjArr.Add(jSeItemObj);

    Result := jSeObj.toString;

    //Ÿ���� ����
    Global.Teebox.SetTeeboxReserveChange(rSeatUseInfo);

    if Global.ADConfig.Emergency = False then
    begin
      try
        sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                    '&teebox_no=' + IntToStr(rSeatUseInfo.SeatNo) +
                    '&reserve_no=' + sReserveNo +
                    //'&assign_min=' + sAssignMin +
                    '&assign_min=' + IntToStr(rSeatUseInfo.AssignMin) +
                    '&prepare_min=' + sPrepareMin +
                    '&assign_balls=9999' +
                    '&user_id=' + sUserId +
                    '&memo=' + sMemo;

        sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K703_TeeboxChg', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetSeatReserveChange Fail : ' + sResult;
          Global.Log.LogErpApiWrite(sLog);
          Global.Teebox.SetSendApiErrorAdd(sReserveNo, 'K703_TeeboxChg', sJsonStr);
        end
        else
        begin
          jErpRvObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
          sResultCd := jErpRvObj.GetValue('result_cd').Value;
          sResultMsg := jErpRvObj.GetValue('result_msg').Value;

          sLog := 'K703_TeeboxChg : ' + IntToStr(rSeatUseInfo.SeatNo)  + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
                  sReserveNo + ' / ' + sResultCd + ' / ' + sResultMsg;
          Global.Log.LogErpApiWrite(sLog);
        end;

      except
        //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
        on e: Exception do
        begin
          sLog := 'SetSeatReserveChange Exception : ' + e.Message;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    end;

  finally
    FreeAndNil(jErpRvObj);
    //FreeAndNil(jErpItemObj);
    FreeAndNil(jSeObj);
    FreeAndNil(jObj);

    Global.Teebox.TeeboxReserveUse := False;
  end;
end;

function TTcpServer.SetTeeboxMove(AReceiveData: AnsiString): AnsiString; //Ÿ���̵����
var
  jObj: TJSONObject;
  sApi, sUserId, sReserveNo, sAssignBalls, sAssignMin, sPrepareMin, sTeeboxNo: String;
  sSeq, sSeqDate, sPossibleReserveDatetime: String;
  //nSeq, nIndex: Integer;
  nSeqNo: Integer;
  //sResult, sData: AnsiString;
  sResult: AnsiString;
  rSeatUseInfo: TSeatUseInfo;
  rSeatUseInfoTemp: TSeatUseInfo;
  sOldSeatNo, sOldSeatNm: String;
  //sNewUseSeq: String;
  rSeatUseReserve: TSeatUseReserve;
  sJsonStr: AnsiString;

  sResultCd, sResultMsg, sLog, sDate, sReserveSql: String;
  nUseSeq: Integer;

  jErpObjArr: TJSONArray;
  jErpItemObj, jErpSubItemObj: TJSONObject;

  rSeatInfo: TTeeboxInfo;
  jSeObj, jSeItemObj, jSeSubItemObj: TJSONObject; //Erp ��������
  jSeObjArr, jSeSubObjArr: TJSONArray;

  jErpRvObj: TJSONObject;

  //2020-07-02
  dtReserveStartTmTemp: TDateTime;

  //2020-05-31 ����ð� ����
  sPossibleReserveDatetimeChk: String;
begin

  //2020-07-23
  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiDelayWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;

  //K412_MoveTeeBoxReserved
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sReserveNo := jObj.GetValue('reserve_no').Value;     //  �����ȣ	reserve_no			S	T29433062
    sUserId := jObj.GetValue('user_id').Value;           //����� ID	user_id			S	admin5
    sAssignBalls := jObj.GetValue('assign_balls').Value; //���� ����	assign_balls			S	9999
    sAssignMin := jObj.GetValue('assign_min').Value;     //�����ð�(��)	assign_min			S	80
    sPrepareMin := jObj.GetValue('prepare_min').Value;  //�غ�ð�(��)	prepare_min			S	10
    sTeeboxNo := jObj.GetValue('teebox_no').Value;               //Ÿ����ȣ	teebox_no			S	19

    sSeqDate := Copy(sReserveNo, 1, 8);
    nSeqNo := StrToInt(Copy(sReserveNo, 9, 4));
    
    //������������ Ȯ��
    rSeatUseInfo := Global.XGolfDM.SeatUseSelectOne(Global.ADConfig.StoreCode, '', sSeqDate, IntToStr(nSeqNo));
    sOldSeatNo := IntToStr(rSeatUseInfo.SeatNo);
    sOldSeatNm := rSeatUseInfo.SeatNm;

    // seat_use ���̺��� Ȧ������ ���� �˻�
    if Global.Teebox.GetTeeboxHold(sTeeboxNo, sUserId, '') = False then
    begin
      Result := '{"result_cd":"408A",' +
                 '"result_msg":"Ÿ��Ȧ�� ������ �ȵǾ����ϴ�. �ٽ� ���� ���μ����� �������ּ���."}';

      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    // 2021-07-14 �̵�ó���� ����, ȭ�� �̰������� ���̵� ��û �ü� ����. �Ѱ�
    if rSeatUseInfo.MoveYn = 'Y' then
    begin
      Result := '{"result_cd":"409A",' +
                 '"result_msg":"Ÿ���̵� ó���� �����Դϴ�."}';

      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    // ����ɸ��ִ°� �������� �ɱ�
    sPossibleReserveDatetime := Global.XGolfDM.SelectPossibleReserveDatetime(sTeeboxNo);

    if ( sPossibleReserveDatetime = '' ) or (sPossibleReserveDatetime < FormatDateTime('YYYYMMDDhhnn00', Now)) then //2021-06-11
      sPossibleReserveDatetime := FormatDateTime('YYYYMMDDhhnn00', Now)
    else
    begin
      //2020-07-20 ����ð� ����
      sPossibleReserveDatetimeChk := Global.ReserveList.GetTeeboxReserveLastTime(sTeeboxNo);
      if sPossibleReserveDatetime < sPossibleReserveDatetimeChk then
      begin
        sLog := 'SetSeatMove Time : ' + sTeeboxNo + ' / ' + sPossibleReserveDatetime + ' -> ' + sPossibleReserveDatetimeChk;
        Global.Log.LogErpApiWrite(sLog);
        sPossibleReserveDatetime := sPossibleReserveDatetimeChk;
      end;
    end;

    //���泻�� ����
    rSeatUseInfo.SeatNo := StrToInt(sTeeboxNo);
    rSeatInfo := Global.Teebox.GetTeeboxInfo(rSeatUseInfo.SeatNo);
    rSeatUseInfo.SeatNm := rSeatInfo.TeeboxNm;
    rSeatUseInfo.SeatUseStatus := '4';  // 4: ����
    rSeatUseInfo.ReserveDate := sPossibleReserveDatetime;
    rSeatUseInfo.AssignMin := StrToInt(sAssignMin);
    rSeatUseInfo.AssignBalls := StrToInt(sAssignBalls);
    rSeatUseInfo.PrepareMin := StrToInt(sPrepareMin);
    rSeatUseInfo.RegId := sUserId;

    //if Global.ADConfig.StoreCode = 'A4001' then //����
    if (Global.Store.StartTime > Global.Store.EndTime) then
      rSeatUseInfo.UseSeqDate := FUseSeqDate
    else
      rSeatUseInfo.UseSeqDate := FormatDateTime('YYYYMMDD', Now);

    FUseSeqNo := FUseSeqNo + 1;
    //2020-06-01 ��õ� ���� �����ȣ �ӽû������� ����
    FLastUseSeqNo := FUseSeqNo;
    rSeatUseInfo.UseSeqNo := FUseSeqNo;

    //Global.XGolfDM.BeginTrans;

    //����ó��
    sResult := Global.XGolfDM.SeatUseMoveUpdate(Global.ADConfig.StoreCode, IntToStr(rSeatUseInfo.UseSeq), sUserId);
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"412C","result_msg":"����ó���� �����Ͽ����ϴ� ' + sResult + '"}';
      //Global.XGolfDM.RollbackTrans;
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    //rSeatUseInfo.UseSeq := nUseSeq; //Ȧ��

    //�̵�Ÿ�� ������Ʈ
    sReserveSql := SetTeeboxReserveSql(rSeatUseInfo, True);
    sResult := Global.XGolfDM.TeeboxUseInsert(sReserveSql);
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"412D","result_msg":"�ű� ������� ' + sResult + '"}';
      //Global.XGolfDM.RollbackTrans;
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    //Global.XGolfDM.CommitTrans;

    rSeatUseInfoTemp := Global.XGolfDM.SelectTeeboxReservationOneWithSeq(Global.ADConfig.StoreCode, rSeatUseInfo.UseSeqDate, IntToStr(rSeatUseInfo.UseSeqNo));

    //2020-07-02 rSeatUseInfoTemp ����������
    if rSeatUseInfoTemp.UseSeq = -1 then
    begin
      rSeatUseInfoTemp.ReserveNo := rSeatUseInfo.UseSeqDate + StrZeroAdd(IntToStr(rSeatUseInfo.UseSeqNo), 4);
      dtReserveStartTmTemp := DateStrToDateTime3(rSeatUseInfo.ReserveDate) + (((1/24)/60) * rSeatUseInfo.PrepareMin);
      rSeatUseInfoTemp.StartTime := FormatDateTime('YYYYMMDDhhnnss', dtReserveStartTmTemp);

      sLog := 'SetSeatMove reset : ' + rSeatUseInfoTemp.ReserveNo + ' / ' + rSeatUseInfoTemp.StartTime;
      Global.Log.LogErpApiWrite(sLog);
    end;

    jSeObjArr := TJSONArray.Create;
    jSeObj := TJSONObject.Create;
    jSeObj.AddPair(TJSONPair.Create('result_cd', '0000'));
    jSeObj.AddPair(TJSONPair.Create('result_msg', 'Success'));
    jSeObj.AddPair(TJSONPair.Create('data', jSeObjArr));

    jSeItemObj := TJSONObject.Create;
    jSeItemObj.AddPair( TJSONPair.Create( 'reserve_no', rSeatUseInfoTemp.ReserveNo) );
    jSeItemObj.AddPair( TJSONPair.Create( 'purchase_cd', IntToStr(rSeatUseInfoTemp.PurchaseSeq)) );
    jSeItemObj.AddPair( TJSONPair.Create( 'product_cd', IntToStr(rSeatUseInfoTemp.ProductSeq)) );
    jSeItemObj.AddPair( TJSONPair.Create( 'product_nm', rSeatUseInfoTemp.ProductNm) );

    if rSeatUseInfoTemp.ReserveDiv = '2' then
      jSeItemObj.AddPair( TJSONPair.Create( 'product_div', 'R') )
    else if rSeatUseInfoTemp.ReserveDiv = '3' then
      jSeItemObj.AddPair( TJSONPair.Create( 'product_div', 'C') )
    else
      jSeItemObj.AddPair( TJSONPair.Create( 'product_div', 'D') );

    jSeItemObj.AddPair( TJSONPair.Create( 'floor_nm', global.Teebox.GetTeeboxFloorNm(rSeatUseInfo.SeatNo)) );
    jSeItemObj.AddPair( TJSONPair.Create( 'teebox_nm', rSeatUseInfo.SeatNm) );

    sDate := Copy(rSeatUseInfoTemp.StartTime, 1, 4) + '-' +
             Copy(rSeatUseInfoTemp.StartTime, 5, 2) + '-' +
             Copy(rSeatUseInfoTemp.StartTime, 7, 2) + ' ' +
             Copy(rSeatUseInfoTemp.StartTime, 9, 2) + ':' +
             Copy(rSeatUseInfoTemp.StartTime, 11, 2) + ':' +
             Copy(rSeatUseInfoTemp.StartTime, 13, 2);
    jSeItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate) );

    jSeItemObj.AddPair( TJSONPair.Create( 'remain_min', sAssignMin) );

    jSeItemObj.AddPair( TJSONPair.Create( 'expire_day', rSeatUseInfo.ExpireDay) );
    jSeItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', rSeatUseInfo.CouponCnt) );

    jSeSubObjArr := TJSONArray.Create;
    jSeItemObj.AddPair(TJSONPair.Create('coupon', jSeSubObjArr));

    jSeObjArr.Add(jSeItemObj);

    Result := jSeObj.ToString;

    global.Teebox.SetTeeboxReserveCancle(StrToInt(sOldSeatNo), sReserveNo);

    rSeatUseReserve.SeatNo := StrToInt(sTeeboxNo);
    rSeatUseReserve.ReserveNo := rSeatUseInfoTemp.ReserveNo;
    rSeatUseReserve.UseMinute := StrToInt(sAssignMin);
    rSeatUseReserve.UseBalls := StrToInt(sAssignBalls);
    rSeatUseReserve.DelayMinute := StrToInt(sPrepareMin);
    rSeatUseReserve.ReserveDate := sPossibleReserveDatetime;
    rSeatUseReserve.AssignYn := rSeatUseInfoTemp.AssignYn;

    if rSeatUseReserve.ReserveDate <= FormatDateTime('YYYYMMDDhhnnss', Now) then
      Global.Teebox.SetTeeboxReserveInfo(rSeatUseReserve)
    else
      global.ReserveList.SetTeeboxReserveNext(rSeatUseReserve);

    if Global.ADConfig.Emergency = False then
    begin
      try
        sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                    '&teebox_no=' + sOldSeatNo +
                    '&reserve_no=' + sReserveNo +
                    '&move_teebox_no=' + sTeeboxNo +
                    '&move_reserve_no=' + rSeatUseReserve.ReserveNo +
                    '&reserve_datetime=' + rSeatUseReserve.ReserveDate +
                    '&assign_balls=' + sAssignBalls +
                    '&assign_min=' + sAssignMin +
                    '&prepare_min=' + sPrepareMin +
                    '&user_id=' + sUserId +
                    '&memo=''';

        sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K706_TeeboxMove', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetSeatMove Fail : ' + sResult;
          Global.Log.LogErpApiWrite(sLog);
          Global.Teebox.SetSendApiErrorAdd(sReserveNo, 'K706_TeeboxMove', sJsonStr);
        end
        else
        begin
          jErpRvObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
          sResultCd := jErpRvObj.GetValue('result_cd').Value;
          sResultMsg := jErpRvObj.GetValue('result_msg').Value;

          //if sResultCd <> '0000' then
          begin
            sLog := 'K706_TeeboxMove : ' + sOldSeatNo + ' [ ' + sOldSeatNm + ' ] ' + sReserveNo + ' -> ' +
                    IntToStr(rSeatUseInfo.SeatNo)  + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
                    rSeatUseReserve.ReserveNo + ' / ' + sResultCd + ' / ' + sResultMsg;
            Global.Log.LogErpApiWrite(sLog);
          end;
        end;

      except
        //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
        on e: Exception do
        begin
          sLog := 'SetSeatMove Exception : ' + e.Message;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    end;

  finally
    FreeAndNil(jErpRvObj);
    FreeAndNil(jSeObj);
    FreeAndNil(jObj);
    FreeAndNil(jErpItemObj);

    Global.Teebox.TeeboxReserveUse := False;
  end;
end;

function TTcpServer.SetTeeboxHeatUsed(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sUserId, sTeeboxNo, sHeatTime, sHeatUse, sTeeboxNm: String;
  //sResult: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
begin
  //K414_TeeBoxHeat
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;

    if (Global.TcpThreadHeat = nil) and  //�帲��ũ- �׸��ʵ�, �����
       (Global.ComHeat_Dome = nil) and   //������
       (Global.ComHeat_A8003 = nil) and //�����(������)
       (Global.ComHeat_D4001 = nil) then //����CC
    begin
      Result := '{"result_cd":"414B","result_msg":"Heat Unuse"}';
      Exit;
    end;

    sUserId := jObj.GetValue('user_id').Value;
    sTeeboxNo := jObj.GetValue('teebox_no').Value;
    sHeatTime := jObj.GetValue('heat_time').Value;
    sHeatUse := jObj.GetValue('heat_use').Value;

    if sTeeboxNo = '0' then //���ͼ���
    begin
      if Global.SetTeeboxHeatSetConfig(sHeatTime, sHeatUse) = False then
      begin
        Result := '{"result_cd":"414A","result_msg":"Config Write Fail"}';
        Exit;
      end;
    end
    else //�������� 0:off, 1: on
    begin
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));
      sTeeboxNm := rTeeboxInfo.TeeboxNm;

      if Global.ADConfig.DeviceType = 0 then //0:Fan, 1:Heat ������ ����
      begin
        Global.CtrlFanSendBuffer(StrToInt(sTeeboxNo), sHeatUse, '0');
      end
      else //1:Heat
      begin
        Global.CtrlHeatSendBuffer(StrToInt(sTeeboxNo), sHeatUse, '0');
      end;
    end;

    Result := '{"result_cd":"0000","result_msg":"Success"}';
  finally
    FreeAndNil(jObj);
  end;
end;

function TTcpServer.SetTeeboxClose(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sReserveNo, sUseSeqDate: String;
  nUseSeqNo: Integer;
  //sResult: AnsiString;
  rSeatUseInfo: TSeatUseInfo;
  sLog: String;
begin
  //K416_TeeBoxClose
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;   //K416_TeeBoxClose
    sUserId := jObj.GetValue('user_id').Value;
    sReserveNo := jObj.GetValue('reserve_no').Value;

    sUseSeqDate := Copy(sReserveNo, 1, 8);
    nUseSeqNo := StrToInt(Copy(sReserveNo, 9, 4));

    rSeatUseInfo := Global.XGolfDM.SeatUseSelectOne(Global.ADConfig.StoreCode, '', sUseSeqDate, IntToStr(nUseSeqNo));

    Result := '{"result_cd":"0000","result_msg":"Success"}';

    global.Teebox.SetTeeboxReserveClose(rSeatUseInfo.SeatNo, sReserveNo);

    sLog := 'K416_TeeBoxClose : ' + IntToStr(rSeatUseInfo.SeatNo) + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
            sUserId + ' / ' + sReserveNo;
    Global.Log.LogServerWrite(sLog);
  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetTeeboxStart(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sReserveNo, sUseSeqDate: String;
  nUseSeqNo: Integer;
  sResult: String;
  rSeatUseInfo: TSeatUseInfo;
  sLog: String;
begin
  //A417_TeeBoxStart
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;   //A417_TeeBoxStart
    sUserId := jObj.GetValue('user_id').Value;
    sReserveNo := jObj.GetValue('reserve_no').Value;

    sUseSeqDate := Copy(sReserveNo, 1, 8);
    nUseSeqNo := StrToInt(Copy(sReserveNo, 9, 4));

    if (Global.ADConfig.StoreCode = 'A2001') or //����
       (Global.ADConfig.StoreCode = 'A3001') then //JMS
    begin
      Result := '{"result_cd":"0001","result_msg":"����Ҽ� ���� ����Դϴ�."}';
      Exit
    end;

    rSeatUseInfo := Global.XGolfDM.SeatUseSelectOne(Global.ADConfig.StoreCode, '', sUseSeqDate, IntToStr(nUseSeqNo));

    if rSeatUseInfo.AssignYn <> 'Y' then
    begin
      Result := '{"result_cd":"0001","result_msg":"��üũ�ε� ������ ��ù����Ҽ� �����ϴ�."}';
      Exit;
    end;

    sResult := global.Teebox.SetTeeboxReserveStartNow(rSeatUseInfo.SeatNo, sReserveNo);
    if sResult = 'Success' then
    begin
      Result := '{"result_cd":"0000","result_msg":"Success"}';
      sLog := 'A417_TeeBoxStart : ' + IntToStr(rSeatUseInfo.SeatNo) + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
            sUserId + ' / ' + sReserveNo;
    end
    else
    begin
      Result := '{"result_cd":"0002","result_msg":"' + sResult + '"}';
      sLog := 'A417_TeeBoxStart Fail : ' + IntToStr(rSeatUseInfo.SeatNo) + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
            sUserId + ' / ' + sReserveNo;
    end;

    Global.Log.LogErpApiWrite(sLog);
  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetApiTeeBoxReg(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveStartDate: String): String;
var
  sJsonStr: AnsiString;
  jObj: TJSONObject;
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

  if Global.ADConfig.Emergency = False then
  begin
    try
      try
        sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                    '&teebox_no=' + IntToStr(ATeeboxNo) +
                    '&reserve_no=' + AReserveNo +
                    '&start_datetime=' + AReserveStartDate +
                    '&user_id=' + Global.ADConfig.UserId;

        sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K702_TeeboxReg', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetApiTeeBoxReg Fail : ' + sLogH + ' / ' + sResult;
          Global.Log.LogErpApiWrite(sLog);
          Global.Teebox.SetSendApiErrorAdd(AReserveNo, 'K702_TeeboxReg', sJsonStr);
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
    end;
  end;

  Result := 'Success';

end;

function TTcpServer.SetApiTeeBoxEnd(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveEndDate, AEndTy: String): String;
var
  sJsonStr: AnsiString;
  jObj: TJSONObject;
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

  if AEndTy <> '2' then //2:����,5:���
    Exit;

  if Global.ADConfig.Emergency = False then
  begin
    try
      try

        sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                    '&teebox_no=' + IntToStr(ATeeboxNo) +
                    '&reserve_no=' + AReserveNo +
                    '&end_datetime=' + AReserveEndDate +
                    '&user_id=' + Global.ADConfig.UserId;

        sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K705_TeeboxEnd', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetApiTeeBoxEnd Fail : ' + sLogH + ' / ' + sResult;
          Global.Log.LogErpApiWrite(sLog);
          Global.Teebox.SetSendApiErrorAdd(AReserveNo, 'K705_TeeboxEnd', sJsonStr);
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
    end;
  end;

  Result := 'Success';

end;

function TTcpServer.SetApiTeeBoxStatus(AType, ATeeboxNo, ATeeboxNo1: String): Boolean;
var
  sJsonStr: AnsiString;
  jObj: TJSONObject;
  sResult, sResultCd, sResultMsg, sLog: String;
begin

  if Global.ADConfig.Emergency = False then
  begin
    try
      try
        //type: ball, check, error
        if AType = 'check' then
          sJsonStr := Global.Teebox.GetTeeboxStatus(ATeeboxNo)
        else if AType = 'error' then
          sJsonStr := Global.Teebox.GetTeeboxStatusError(ATeeboxNo, ATeeboxNo1)
        else
          sJsonStr := Global.Teebox.GetTeeboxStatusList;

        sResult := Global.Api.SetErpApiJsonData(sJsonStr, 'K707_TeeboxStatus', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetApiTeeBoxStatus Fail : ' + sResult;
          Global.Log.LogErpApiWrite(sLog);
        end
        else
        begin
          jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
          sResultCd := jObj.GetValue('result_cd').Value;
          sResultMsg := jObj.GetValue('result_msg').Value;

          sLog := 'K707_TeeBoxStatus : ' + sResultCd + ' / ' + sResultMsg;
          Global.Log.LogErpApiWrite(sLog);
        end;

      except
        //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
        on e: Exception do
        begin
          sLog := 'SetApiTeeBoxStatus Exception : ' + e.Message;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end
    finally
      FreeAndNil(jObj);
    end;
  end;

end;

function TTcpServer.GetErpTeeboxList: Boolean;
var
  sJsonStr: AnsiString;
  jObj, jItemObj: TJSONObject; //Erp ��������
  jObjArr: TJSONArray;
  sResult, sResultCd, sResultMsg, sLog: String;
  ASeatUseInfoArr: Array of TSeatUseInfo;
  nSize, nIndex: Integer;
begin
  Result := False;

  try
    try
      sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;

      sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K709_TeeboxList', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

      if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
      begin
        sLog := 'GetErpTeeboxList Fail : ' + sResult;
        Global.Log.LogErpApiWrite(sLog);
        Exit;
      end;

      jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
      sResultCd := jObj.GetValue('result_cd').Value;
      sResultMsg := jObj.GetValue('result_msg').Value;

      if sResultCd <> '0000' then
      begin
        sLog := 'K709_TeeboxList : ' + sResultCd + ' / ' + sResultMsg;
        Global.Log.LogErpApiWrite(sLog);
        Exit;
      end;

      jObjArr := jObj.GetValue('result_data') as TJsonArray;

      nSize := jObjArr.Size;
      SetLength(ASeatUseInfoArr, nSize);

      for nIndex := 0 to nSize - 1 do
      begin
        jItemObj := jObjArr.Get(nIndex) as TJSONObject;

        ASeatUseInfoArr[nIndex].StoreCd := Global.ADConfig.StoreCode;
        ASeatUseInfoArr[nIndex].SeatNo := StrToInt(jItemObj.GetValue('teebox_no').Value);
        ASeatUseInfoArr[nIndex].SeatNm := jItemObj.GetValue('teebox_nm').Value;
        ASeatUseInfoArr[nIndex].ReserveNo := jItemObj.GetValue('reserve_no').Value;
        ASeatUseInfoArr[nIndex].UseSeqDate := Copy(ASeatUseInfoArr[nIndex].ReserveNo, 1, 8);
        ASeatUseInfoArr[nIndex].UseSeqNo := StrToInt(Copy(ASeatUseInfoArr[nIndex].ReserveNo, 9, 4));

        //1:����Ÿ��D, 2:�Ⱓȸ��, 3:����ȸ��
        ASeatUseInfoArr[nIndex].ReserveDiv := jItemObj.GetValue('reserve_div').Value;
        if ASeatUseInfoArr[nIndex].ReserveDiv = '1' then
          ASeatUseInfoArr[nIndex].ReserveDiv := 'D'
        else if ASeatUseInfoArr[nIndex].ReserveDiv = '2' then
          ASeatUseInfoArr[nIndex].ReserveDiv := 'R'
        else if ASeatUseInfoArr[nIndex].ReserveDiv = '3' then
          ASeatUseInfoArr[nIndex].ReserveDiv := 'C';

        ASeatUseInfoArr[nIndex].ProductSeq := StrToInt(jItemObj.GetValue('product_cd').Value);
        ASeatUseInfoArr[nIndex].ProductNm := jItemObj.GetValue('product_nm').Value;
        ASeatUseInfoArr[nIndex].ReserveRootDiv := jItemObj.GetValue('reserve_root_div').Value;
        //ASeatUseInfoArr[nIndex].teebox_no := jItemObj.GetValue('assign_yn').Value;
        ASeatUseInfoArr[nIndex].MemberSeq := jItemObj.GetValue('member_no').Value;
        ASeatUseInfoArr[nIndex].MemberNm := jItemObj.GetValue('member_nm').Value;
        ASeatUseInfoArr[nIndex].MemberTel := jItemObj.GetValue('hp_no').Value;
        ASeatUseInfoArr[nIndex].ReserveDate := jItemObj.GetValue('reserve_datetime').Value;
        ASeatUseInfoArr[nIndex].StartTime := jItemObj.GetValue('start_datetime').Value;
        ASeatUseInfoArr[nIndex].PurchaseSeq := StrToInt(jItemObj.GetValue('purchase_cd').Value);
        //ASeatUseInfoArr[nIndex].teebox_no := jItemObj.GetValue('receipt_no').Value; //��������ȣ: T000120190918010005	����Ÿ���� �����ڸ� ��ȸ ����
        ASeatUseInfoArr[nIndex].AssignMin := StrToInt(jItemObj.GetValue('assign_min').Value);
        ASeatUseInfoArr[nIndex].AssignBalls := StrToInt(jItemObj.GetValue('assign_balls').Value);
        ASeatUseInfoArr[nIndex].PrepareMin := StrToInt(jItemObj.GetValue('prepare_min').Value);
        //ASeatUseInfoArr[nIndex].teebox_no := jItemObj.GetValue('reg_datetime').Value;
      end;

      Global.XGolfDM.BeginTrans;

      for nIndex := 0 to nSize - 1 do
      begin
        sResult := Global.XGolfDM.SeatUseInsert(ASeatUseInfoArr[nIndex]); // POS/KIOSK �� Update

        if sResult <> 'Success' then
        begin
          sLog := 'GetErpTeeboxList DB fail';
          Global.Log.LogErpApiWrite(sLog);
          Global.XGolfDM.RollbackTrans;
          Exit;
        end;
      end;

      Global.XGolfDM.CommitTrans;

    except
      //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
      on e: Exception do
      begin
        sLog := 'GetErpTeeboxList Exception : ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);
        Exit;
      end;
    end;
  finally
    FreeAndNil(jObj);
  end;

  Result := True;
end;

function TTcpServer.GetErpTeeboxListLastNo: Integer;
var
  sJsonStr: AnsiString;
  jObj, jItemObj: TJSONObject; //Erp ��������
  jObjArr: TJSONArray;
  sResult, sResultCd, sResultMsg, sLog: String;
  nSize, nIndex: Integer;

  sDate, sReserveNo: String;
  nLastNo: Integer;
begin
  Result := 0;

  try
    try
      sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;

      sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K709_TeeboxList', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

      if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
      begin
        sLog := 'GetErpTeeboxListLastNo Fail : ' + sResult;
        Global.Log.LogErpApiWrite(sLog);
        Exit;
      end;

      jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
      sResultCd := jObj.GetValue('result_cd').Value;
      sResultMsg := jObj.GetValue('result_msg').Value;

      if sResultCd <> '0000' then
      begin
        sLog := 'K709_TeeboxList : ' + sResultCd + ' / ' + sResultMsg;
        Global.Log.LogErpApiWrite(sLog);
        Exit;
      end;

      jObjArr := jObj.GetValue('result_data') as TJsonArray;

      nSize := jObjArr.Size;
      sDate := FormatDateTime('YYYYMMDD', now);
      nLastNo := 0;

      for nIndex := 0 to nSize - 1 do
      begin
        jItemObj := jObjArr.Get(nIndex) as TJSONObject;

        sReserveNo := jItemObj.GetValue('reserve_no').Value;
        if sDate = Copy(sReserveNo, 1, 8) then
        begin
          if nLastNo < StrToInt(Copy(sReserveNo, 9, 4)) then
            nLastNo := StrToInt(Copy(sReserveNo, 9, 4));
        end;

      end;

      Result := nLastNo;
    except
      //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
      on e: Exception do
      begin
        sLog := 'GetErpTeeboxListLastNo Exception : ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);
        Exit;
      end;
    end;
  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetKioskPrint(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sDeviceNo, sError: String;
begin
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;  //A418_KioskPrintError
    sDeviceNo := jObj.GetValue('device_no').Value;
    sUserId := jObj.GetValue('user_id').Value;      //����� Id
    sError := jObj.GetValue('error_cd').Value;

    Global.SetKioskPrint(sDeviceNo, sUserId, sError);
    Result := '{"result_cd":"0000","result_msg":"Success"}';

  finally
    FreeAndNil(jObj);
  end;
end;

function TTcpServer.SetKioskStatus(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sDeviceNo: String;
begin
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;   //A419_KioskStatus
    sDeviceNo := jObj.GetValue('device_no').Value;
    sUserId := jObj.GetValue('user_id').Value;

    Global.SetKioskInfo(sDeviceNo, sUserId);
    Result := '{"result_cd":"0000","result_msg":"Success"}';

  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetTeeBoxEmergency(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sMode: String;
begin
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;   //A420_SetTeeBoxEmergency
    sMode := jObj.GetValue('mode_yn').Value;
    sUserId := jObj.GetValue('user_id').Value;

    if Global.SetADConfigEmergency(sMode, sUserId) = false then
      Result := '{"result_cd":"0001","result_msg":"fail"}'
    else
      Result := '{"result_cd":"0000","result_msg":"Success"}';

  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.GetTeeBoxEmergency(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId: String;
  bMode: Boolean;
begin
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;   //A421_GetTeeBoxEmergency
    sUserId := jObj.GetValue('user_id').Value;

    bMode := Global.ADConfig.Emergency;

    if bMode = false then
      Result := '{"result_cd":"0000","result_msg":"Success","result_yn":"N"}'
    else
      Result := '{"result_cd":"0000","result_msg":"Success","result_yn":"Y"}';

  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetTeeboxCheckCtrl(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sTeeboxNo: String;
  rSeatInfo: TTeeboxInfo;
begin
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;   //A430_TeeboxCheckCtrl
    sTeeboxNo := jObj.GetValue('teebox_no').Value;
    sUserId := jObj.GetValue('user_id').Value;

    rSeatInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));

    if rSeatInfo.UseStatus <> '8' then
    begin
      Result := '{"result_cd":"0001","result_msg":"�������� Ÿ���� �ƴմϴ�."}';
      Exit;
    end;

    if Global.ADConfig.ProtocolType = 'MODENYJ' then
      Global.Teebox.SetTeeboxCtrlRemainMin(rSeatInfo.TeeboxNo, 10)
    else
      //Global.Teebox.SetTeeboxCtrl(rSeatInfo.TeeboxNo, 'S1' , 10, 9999);
      Global.Teebox.SetTeeboxCtrlAD(rSeatInfo.TeeboxNo, 'S1' , 10, 9999);

    Result := '{"result_cd":"0000","result_msg":"Success"}';

  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetTeeboxCutIn(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId: string;
  //sReserveRootDiv: String;
  sXgUserKey: String;
  sReserveDate, sReserveDiv: String;
  sTargetReserveNo: String;
  sResult: String;

  nIndex, nReIndex: Integer;

  rSeatUseInfo: TSeatUseInfo;
  nUseSeq: Integer;

  rSeatUseReserveTemp: TSeatUseReserve;

  sUseSeqDate: String;
  sJsonStr: AnsiString;

  jErpSeObj, jErpSeItemObj: TJSONObject; //Erp ��������
  jErpSeObjArr: TJSONArray;

  jErpRvObj: TJSONObject;
  sErpRvResultCd, sErpRvResultMsg: String;

  sLog: String;

  rSeatInfo: TTeeboxInfo;

  jSendObj: TJSONObject; // pos,kiosk ��������

  JV: TJSONValue;
  nCount: integer;
  I: Integer;
  sDate: String;
  sReserveSql: String;

  //���۽ð� Ȯ�ο�
  sReserveTmTemp: String;
  dtReserveStartTmTemp: TDateTime;
begin

  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then //TeeboxThread ���������
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiDelayWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;

  //A431_TeeboxCutIn
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;

    //sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;

    if Global.ADConfig.StoreCode = 'A4001' then //����
      sUseSeqDate := FUseSeqDate
    else
      sUseSeqDate := FormatDateTime('YYYYMMDD', Now);

    FLastUseSeqNo := FLastUseSeqNo + 1;
    rSeatUseInfo.UseSeqDate := sUseSeqDate;
    rSeatUseInfo.UseSeqNo := FLastUseSeqNo;
    rSeatUseInfo.ReserveNo := rSeatUseInfo.UseSeqDate + StrZeroAdd(IntToStr(rSeatUseInfo.UseSeqNo), 4);

    rSeatUseInfo.StoreCd := Global.ADConfig.StoreCode;
    rSeatUseInfo.SeatNo := StrToInt(jObj.GetValue('teebox_no').Value);

    rSeatInfo := Global.Teebox.GetTeeboxInfo(rSeatUseInfo.SeatNo);
    rSeatUseInfo.SeatNm := rSeatInfo.TeeboxNm;

    rSeatUseInfo.SeatUseStatus := '4';  // 4: ����
    rSeatUseInfo.UseDiv := '1';     // 1:����, 2:�߰�
    rSeatUseInfo.MemberSeq := jObj.GetValue('member_no').Value;
    rSeatUseInfo.MemberNm := jObj.GetValue('member_nm').Value;

    //2023-02-13 Ȱ��ȭ
    if jObj.FindValue('hp_no') <> nil then
      rSeatUseInfo.MemberTel := jObj.GetValue('hp_no').Value;

    rSeatUseInfo.PurchaseSeq := StrToInt(jObj.GetValue('purchase_cd').Value); //�����ڵ�
    rSeatUseInfo.ProductSeq := StrToInt(jObj.GetValue('product_cd').Value);   //Ÿ����ǰ�ڵ�
    rSeatUseInfo.ProductNm := jObj.GetValue('product_nm').Value;

    if jObj.GetValue('reserve_div').Value = 'R' then
      sReserveDiv := '2'
    else if jObj.GetValue('reserve_div').Value = 'C' then
      sReserveDiv := '3'
    else
      sReserveDiv := '1';

    rSeatUseInfo.ReserveDiv := sReserveDiv;

    if jObj.FindValue('available_zone_cd') <> nil then
      rSeatUseInfo.AvailableZoneCd := jObj.GetValue('available_zone_cd').Value; //2021-12-20 ������

    rSeatUseInfo.ReceiptNo := jObj.GetValue('receipt_no').Value; //��������ȣ
    rSeatUseInfo.ReserveRootDiv := jObj.GetValue('reserve_root_div').Value; //K:Ű����ũ, P:����, M:�����
    rSeatUseInfo.AffiliateCd := jObj.GetValue('affiliate_cd').Value; //���޻��ڵ�

    sXgUserKey := EmptyStr;
    if rSeatUseInfo.ReserveRootDiv = 'M' then
      sXgUserKey := jObj.GetValue('xg_user_key').Value;
    rSeatUseInfo.XgUserKey := sXgUserKey;

    rSeatUseInfo.AssignMin := StrToInt(jObj.GetValue('assign_min').Value);
    rSeatUseInfo.AssignBalls := StrToInt(jObj.GetValue('assign_balls').Value);
    rSeatUseInfo.PrepareMin := StrToInt(jObj.GetValue('prepare_min').Value);

    sReserveDate := jObj.GetValue('reserve_date').Value;
    rSeatUseInfo.ReserveDate := Copy(sReserveDate, 1, 4) +
                                Copy(sReserveDate, 6, 2) +
                                Copy(sReserveDate, 9, 2) +
                                Copy(sReserveDate, 12, 2) +
                                Copy(sReserveDate, 15, 2) +
                                Copy(sReserveDate, 18, 2);

    sTargetReserveNo := jObj.GetValue('reserve_no').Value;

    dtReserveStartTmTemp := DateStrToDateTime3(rSeatUseInfo.ReserveDate) + (((1/24)/60) * rSeatUseInfo.PrepareMin);
    rSeatUseInfo.StartTime := FormatDateTime('YYYYMMDDhhnnss', dtReserveStartTmTemp);
    rSeatUseInfo.RegId := sUserId;

    rSeatUseInfo.AssignYn := 'Y';

    if (Global.ADConfig.CheckInUse = 'Y') then
    begin
      if (sReserveDiv = '2') and
         ((rSeatUseInfo.ReserveRootDiv = 'M') or (rSeatUseInfo.ReserveRootDiv = 'T')) then
        rSeatUseInfo.AssignYn := 'N'
      else
        rSeatUseInfo.AssignYn := 'Y';
    end;

    if rSeatUseInfo.ReserveDate < FormatDateTime('YYYYMMDDHHNNSS', now) then
    begin
      Result := '{"result_cd":"0010",' +
                 '"result_msg":"�����ֱ����� ����ð��� �̹� �������ϴ�."}';

      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    sResult := Global.XGolfDM.SeatUseCutInSelect(Global.ADConfig.StoreCode, sTargetReserveNo);
    if sResult <> 'success' then
    begin
      Result := '{"result_cd":"0011",' +
                 '"result_msg":"' + sResult + '"}';

      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    //������ Ȯ��
    rSeatUseReserveTemp.SeatNo := rSeatUseInfo.SeatNo;
    rSeatUseReserveTemp.ReserveNo := rSeatUseInfo.ReserveNo;
    rSeatUseReserveTemp.UseMinute := rSeatUseInfo.AssignMin;
    rSeatUseReserveTemp.UseBalls := rSeatUseInfo.AssignBalls;
    rSeatUseReserveTemp.DelayMinute := rSeatUseInfo.PrepareMin;
    rSeatUseReserveTemp.ReserveDate := rSeatUseInfo.ReserveDate;
    rSeatUseReserveTemp.StartTime := rSeatUseInfo.StartTime;
    rSeatUseReserveTemp.AssignYn := rSeatUseInfo.AssignYn;

    sResult := global.ReserveList.SetTeeboxReserveNextCutInCheck(rSeatUseReserveTemp);
    if sResult <> 'success' then
    begin
      Result := '{"result_cd":"0012",' +
                 '"result_msg":"' + sResult + '"}';

      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    try

      if Global.ADConfig.Emergency = False then
      begin

        //Erp ���� ��������
        jErpSeObjArr := TJSONArray.Create;
        jErpSeObj := TJSONObject.Create;
        jErpSeObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
        jErpSeObj.AddPair(TJSONPair.Create('member_no', rSeatUseInfo.MemberSeq));
        jErpSeObj.AddPair(TJSONPair.Create('reserve_root_div', rSeatUseInfo.ReserveRootDiv));
        jErpSeObj.AddPair(TJSONPair.Create('user_id', sUserId));
        jErpSeObj.AddPair(TJSONPair.Create('memo', ''));
        jErpSeObj.AddPair(TJSONPair.Create('data', jErpSeObjArr));

        jErpSeItemObj := TJSONObject.Create;
        jErpSeItemObj.AddPair( TJSONPair.Create( 'teebox_no', IntToStr(rSeatUseInfo.SeatNo) ) );
        jErpSeItemObj.AddPair( TJSONPair.Create( 'reserve_no', rSeatUseInfo.ReserveNo ) );
        jErpSeItemObj.AddPair( TJSONPair.Create( 'purchase_cd', IntToStr(rSeatUseInfo.PurchaseSeq) ) );
        jErpSeItemObj.AddPair( TJSONPair.Create( 'product_cd', IntToStr(rSeatUseInfo.ProductSeq) ) );
        jErpSeItemObj.AddPair( TJSONPair.Create( 'assign_min', IntToStr(rSeatUseInfo.AssignMin) ) );
        jErpSeItemObj.AddPair( TJSONPair.Create( 'prepare_min', IntToStr(rSeatUseInfo.PrepareMin) ) );
        jErpSeItemObj.AddPair( TJSONPair.Create( 'assign_balls', IntToStr(rSeatUseInfo.AssignBalls ) ) );
        jErpSeItemObj.AddPair( TJSONPair.Create( 'reserve_datetime', rSeatUseInfo.ReserveDate ) );
        jErpSeObjArr.Add(jErpSeItemObj);


        //Erp ��������
        sResult := Global.Api.SetErpApiJsonData(jErpSeObj.ToString, 'K701_TeeboxReserve', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
        sJsonStr := sResult;

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetSeatReserve Fail : ' + rSeatUseInfo.ReserveNo + ' / ' + sResult;
          Global.Log.LogErpApiWrite(sLog);

          sLog := jErpSeObj.ToString;
          Global.Log.LogErpApiWrite(sLog);

          Result := '{"result_cd":"0002",' +
                     //'"result_msg":"' + sResult + '"}';
                     '"result_msg":"���೻���� ������ ����� ��ְ� �߻��Ͽ����ϴ�."}';

          Global.Teebox.TeeboxReserveUse := False;
          Exit;
        end;

        jErpRvObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
        sErpRvResultCd := jErpRvObj.GetValue('result_cd').Value;
        sErpRvResultMsg := jErpRvObj.GetValue('result_msg').Value;

        sLog := 'K701_TeeBoxReserve : ' + rSeatUseInfo.ReserveNo + ' / ' + sErpRvResultCd + ' / ' + sErpRvResultMsg;
        Global.Log.LogErpApiWrite(sLog);

        if sErpRvResultCd <> '0000' then
        begin
          //2020-05-28 : �Ⱓ��,���� ��õ�
          if (sErpRvResultCd = '8006') and //���� �����ȣ
             //2020-08-20 R:��ȸ��, C:����ȸ�� -> 1:����Ÿ��, 2:�Ⱓȸ��, 3:����ȸ�� ��������
             //((sReserveDiv = 'R') or (sReserveDiv = 'C')) then //�Ⱓ��, ����
             ((sReserveDiv = '2') or (sReserveDiv = '3')) then //�Ⱓ��, ����
          begin
            //����������� �Ǵ�, DB�� �����Ѵ�.
            sLog := 'K701_TeeBoxReserve Retry : ' + rSeatUseInfo.ReserveNo;
            Global.Log.LogErpApiWrite(sLog);
          end
          else
          begin
            Result := '{"result_cd":"' + sErpRvResultCd + '",' +
                       '"result_msg":"' + sErpRvResultMsg + '"}';

            //2021-06-30 M : ������� ��� �ڵ� 9999 �̸� �ӽÿ��� ���ó��-������ ��ǥ
            if (rSeatUseInfo.ReserveRootDiv = 'M') and (sErpRvResultCd = '9999') then
            begin
              Global.Teebox.SetTeeboxHold(IntToStr(rSeatUseInfo.SeatNo), sUserId, False);
              Global.XGolfDM.TeeboxHoldDelete(sUserId, IntToStr(rSeatUseInfo.SeatNo));
            end;

            Global.Teebox.TeeboxReserveUse := False;
            Exit;
          end;

        end;
      end;

      sReserveSql := '';
      sReserveSql := SetTeeboxReserveSql(rSeatUseInfo, false, True);

      Global.Teebox.SetTeeboxHold(IntToStr(rSeatUseInfo.SeatNo), sUserId, False);
      Global.XGolfDM.TeeboxHoldDelete(sUserId, IntToStr(rSeatUseInfo.SeatNo));

      //���೻�� DB ����
      sResult := Global.XGolfDM.TeeboxUseInsert(sReserveSql);
      if sResult <> 'Success' then
      begin
        Result := '{"result_cd":"0004",' +
                   '"result_msg":"DB ���忡 �����Ͽ����ϴ� ' + sResult + '"}';

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;
      Global.ReserveDBWrite := True;

    except
      //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
      on e: Exception do
      begin
        sLog := 'SetSeatReserve Exception : ' + rSeatUseInfo.ReserveNo + ' / ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);

        Result := '{"result_cd":"0003",' +
                   '"result_msg":"�������� ��ְ� �߻��Ͽ����ϴ� ' + e.Message + '"}';

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;
    end;

    FUseSeqNo := FLastUseSeqNo;

    jSendObj := TJSONObject.Create;
    jSendObj.AddPair(TJSONPair.Create('result_cd', '0000'));
    jSendObj.AddPair(TJSONPair.Create('result_msg', 'Success'));

    if Global.ADConfig.Emergency = False then
    begin

      if not (jErpRvObj.FindValue('result_data') is TJSONNull) then
      begin
        JV := jErpRvObj.Get('result_data').JsonValue;

        rSeatUseInfo.LessonProNm := (JV as TJSONObject).Get('lesson_pro_nm').JsonValue.Value;
        rSeatUseInfo.LessonProPosColor := (JV as TJSONObject).Get('lesson_pro_pos_color').JsonValue.Value;

        JV := (JV as TJSONObject).Get('dataList').JsonValue;
        nCount := (JV as TJSONArray).Count;

        //for I := 0 to nCount - 1 do // 1��
        begin
          //jSendItemObj := TJSONObject.Create;
          jSendObj.AddPair( TJSONPair.Create( 'reserve_no', (JV as TJSONArray).Items[0].P['reserve_no'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'purchase_cd', (JV as TJSONArray).Items[0].P['purchase_cd'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'product_cd', (JV as TJSONArray).Items[0].P['product_cd'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'product_nm', (JV as TJSONArray).Items[0].P['product_nm'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'product_div', (JV as TJSONArray).Items[0].P['product_div'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'floor_nm', (JV as TJSONArray).Items[0].P['floor_nm'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'teebox_nm', (JV as TJSONArray).Items[0].P['teebox_nm'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'reserve_datetime', (JV as TJSONArray).Items[0].P['reserve_datetime'].Value) );


          sReserveTmTemp := (JV as TJSONArray).Items[0].P['reserve_datetime'].Value;
          dtReserveStartTmTemp := DateStrToDateTime2(sReserveTmTemp) + (((1/24)/60) * rSeatUseInfo.PrepareMin);
          sDate := FormatDateTime('YYYY-MM-DD hh:nn:ss', dtReserveStartTmTemp);
          jSendObj.AddPair( TJSONPair.Create( 'start_datetime', sDate ) );

          jSendObj.AddPair( TJSONPair.Create( 'remain_min', (JV as TJSONArray).Items[0].P['remain_min'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'expire_day', (JV as TJSONArray).Items[0].P['expire_day'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'coupon_cnt', (JV as TJSONArray).Items[0].P['coupon_cnt'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'access_barcode', (JV as TJSONArray).Items[0].P['access_barcode'].Value) );
          jSendObj.AddPair( TJSONPair.Create( 'access_control_nm', (JV as TJSONArray).Items[0].P['access_control_nm'].Value) );
        end;

      end;

    end
    else
    begin

      //jSendObj.AddPair(TJSONPair.Create('data', jSendObjArr));

      //jSendItemObj := TJSONObject.Create;
      jSendObj.AddPair( TJSONPair.Create( 'reserve_no', rSeatUseInfo.ReserveNo ) );
      jSendObj.AddPair( TJSONPair.Create( 'purchase_cd', IntToStr(rSeatUseInfo.PurchaseSeq) ) );
      jSendObj.AddPair( TJSONPair.Create( 'product_cd', IntTOStr(rSeatUseInfo.ProductSeq) ) );
      jSendObj.AddPair( TJSONPair.Create( 'product_nm', rSeatUseInfo.ProductNm ) );

      if rSeatUseInfo.ReserveDiv = '2' then
        jSendObj.AddPair( TJSONPair.Create( 'product_div', 'R' ) )
      else if rSeatUseInfo.ReserveDiv = '3' then
        jSendObj.AddPair( TJSONPair.Create( 'product_div', 'C' ) )
      else
        jSendObj.AddPair( TJSONPair.Create( 'product_div', 'D' ) );

      jSendObj.AddPair( TJSONPair.Create( 'floor_nm', rSeatUseInfo.FloorNm ) );
      jSendObj.AddPair( TJSONPair.Create( 'teebox_nm', rSeatUseInfo.SeatNm ) );

      sDate := Copy(rSeatUseInfo.ReserveDate, 1, 4) + '-' +
               Copy(rSeatUseInfo.ReserveDate, 5, 2) + '-' +
               Copy(rSeatUseInfo.ReserveDate, 7, 2) + ' ' +
               Copy(rSeatUseInfo.ReserveDate, 9, 2) + ':' +
               Copy(rSeatUseInfo.ReserveDate, 11, 2) + ':' +
               Copy(rSeatUseInfo.ReserveDate, 13, 2);
      jSendObj.AddPair( TJSONPair.Create( 'reserve_datetime', sDate ) );

      sDate := Copy(rSeatUseInfo.StartTime, 1, 4) + '-' +
               Copy(rSeatUseInfo.StartTime, 5, 2) + '-' +
               Copy(rSeatUseInfo.StartTime, 7, 2) + ' ' +
               Copy(rSeatUseInfo.StartTime, 9, 2) + ':' +
               Copy(rSeatUseInfo.StartTime, 11, 2) + ':' +
               Copy(rSeatUseInfo.StartTime, 13, 2);
      jSendObj.AddPair( TJSONPair.Create( 'start_datetime', sDate ) );

      jSendObj.AddPair( TJSONPair.Create( 'remain_min', IntToStr(rSeatUseInfo.RemainMin) ) );
      jSendObj.AddPair( TJSONPair.Create( 'expire_day', '' ) );
      jSendObj.AddPair( TJSONPair.Create( 'coupon_cnt', '' ) );
      jSendObj.AddPair( TJSONPair.Create( 'access_barcode', '' ) );
      jSendObj.AddPair( TJSONPair.Create( 'access_control_nm', '' ) );
    end;

    Result := jSendObj.ToString;

    //�������-����ֱ�
    if global.ReserveList.SetTeeboxReserveNextCutIn(rSeatUseReserveTemp) then
    begin

    end;

    //�����ֱ� ����̿��� ���� �����ֱ� �׸�N ó��
    sResult := Global.XGolfDM.SeatUseCutInUseDelete(Global.ADConfig.StoreCode, sTargetReserveNo, sUserId);
    if sResult <> 'Success' then
    begin
      sLog := 'SeatUseCutInUseDelete Fail : ' + sTargetReserveNo;
      Global.Log.LogErpApiWrite(sLog);
    end;

  finally
    FreeAndNil(jErpSeObj);

    FreeAndNil(jObj);
    FreeAndNil(jErpRvObj);
    FreeAndNil(jSendObj);

    Global.Teebox.TeeboxReserveUse := False;
  end;

end;

function TTcpServer.SetTeeboxCheckIn(AReceiveData: AnsiString): AnsiString;
var
  jObj, jObjItem: TJSONObject;
  jObjArr: TJsonArray; //pos,kiosk ����
  sApi, sUserId, sLog: String;
  nIndex, nCnt: Integer;
  sReserveNo: String;
  nTeeboxNo: Integer;
begin

  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiDelayWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;

  //A432_TeeboxCheckIn
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;         //����� ID

    jObjArr := jObj.GetValue('data') as TJsonArray;
    nCnt := jObjArr.Size;

    for nIndex := 0 to nCnt - 1 do
    begin
      jObjItem := jObjArr.Get(nIndex) as TJSONObject;
      sReserveNo := jObjItem.GetValue('reserve_no').Value;
      nTeeboxNo := StrToInt(jObjItem.GetValue('teebox_no').Value);

      //�������� üũ��
      global.Teebox.SetTeeboxReserveCheckIn(nTeeboxNo, sReserveNo);
    end;

    Result := '{"result_cd":"0000","result_msg":"Success"}';
  finally
    FreeAndNil(jObj);

    Global.Teebox.TeeboxReserveUse := False;
  end;

end;

function TTcpServer.BallRecallTimeCheck(ASeatUseInfo: TSeatUseInfo; AStart, AEnd: String): Boolean; //��ȸ�� �ð� �����ð��� �߰�
var
  sSTm, sETm, sStr: String;
  dtEndTmTemp: TDateTime;
begin
  Result := True;

  sSTm := Copy(ASeatUseInfo.StartTime, 9, 4);
  dtEndTmTemp := DateStrToDateTime3(ASeatUseInfo.StartTime) + (((1/24)/60) * ASeatUseInfo.AssignMin);
  sETm := FormatDateTime('hhnn', dtEndTmTemp);

  //�������۽ð��� ��ȸ�����۽ð��� �����ϸ�
  if sSTm = AStart then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sSTm: ' + sSTm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //�������۽ð��� ��ȸ�� ���۽ð��� ����ð� �����̸�
  if (sSTm > AStart) and
     (sSTm < AEnd) then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sSTm: ' + sSTm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //��������ð��� ��ȸ������ð��� �����ϸ�
  if sETm = AEnd then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sETm: ' + sETm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //��������ð��� ��ȸ�� ���۽ð��� ����ð� �����̸�
  if (sETm > AStart) and
     (sETm < AEnd) then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sETm: ' + sETm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //�����ð� ���̿� ��ȸ�� �ð� ������
  if (sSTm < AStart) and
     (sETm > AEnd) then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sSTm: ' + sSTm + ' / sETm: ' +sETm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  Result := False;
end;

function TTcpServer.BallRecallTimeCheckMulti(ASeatUseInfo: TSeatUseInfo): Boolean; //��ȸ�� �ð� �����ð��� �߰�
var
  sSTm, sETm, sStr: String;
  dtEndTmTemp: TDateTime;
begin
  Result := True;

  sSTm := Copy(ASeatUseInfo.StartTime, 9, 4);
  dtEndTmTemp := DateStrToDateTime3(ASeatUseInfo.StartTime) + (((1/24)/60) * ASeatUseInfo.AssignMin);
  sETm := FormatDateTime('hhnn', dtEndTmTemp);

  //�������۽ð��� ��ȸ�����۽ð��� �����ϸ�
  if (sSTm = '0900') or (sSTm = '1200') or (sSTm = '1500') or (sSTm = '1800') then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sSTm: ' + sSTm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //�������۽ð��� ��ȸ�� ���۽ð��� ����ð� �����̸�
  if ((sSTm > '0900') and (sSTm < '0903')) or
     ((sSTm > '1200') and (sSTm < '1203')) or
     ((sSTm > '1500') and (sSTm < '1503')) or
     ((sSTm > '1800') and (sSTm < '1803')) then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sSTm: ' + sSTm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //��������ð��� ��ȸ������ð��� �����ϸ�
  if (sETm = '0903') or (sETm = '1203') or (sETm = '1503') or (sETm = '1803') then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sETm: ' + sETm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //��������ð��� ��ȸ�� ���۽ð��� ����ð� �����̸�
  if ((sETm > '0900') and (sETm < '0903')) or
     ((sETm > '1200') and (sETm < '1203')) or
     ((sETm > '1500') and (sETm < '1503')) or
     ((sETm > '1800') and (sETm < '1803')) then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sETm: ' + sETm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //�����ð� ���̿� ��ȸ�� �ð� ������
  if ((sSTm < '0900') and (sETm > '0903')) or
     ((sSTm < '1200') and (sETm > '1203')) or
     ((sSTm < '1500') and (sETm > '1503')) or
     ((sSTm < '1800') and (sETm > '1803')) then
  begin
    sStr := '��ȸ�� : ' + ASeatUseInfo.ReserveNo + ' / sSTm: ' + sSTm + ' / sETm: ' +sETm;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  Result := False;
end;

function TTcpServer.SetTeeboxHeatAll(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId: String;
begin
  {
  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiDelayWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;
  }
  //K450_TeeBoxHeatAll
  Result := '';

  if (Global.ADConfig.StoreCode = 'BB001') then //������
  begin
    if Global.ADConfig.DeviceType = 0 then //0:Fan, 1:Heat ������ ����
    begin
      if Global.ComFan_Dome = nil then
      begin
        Result := '{"result_cd":"9999","result_msg":"��ǳ������ ����� ��Ȱ��ȭ �����Դϴ�."}';
        Exit;
      end;
    end
    else
    begin
      if Global.ComHeat_Dome = nil then
      begin
        Result := '{"result_cd":"9999","result_msg":"�������� ����� ��Ȱ��ȭ �����Դϴ�."}';
        Exit;
      end;
    end;
  end
  else if (Global.ADConfig.StoreCode = 'A8003') then // ����� ������
  begin
    if Global.ComHeat_A8003 = nil then
    begin
      Result := '{"result_cd":"9999","result_msg":"�������� ����� ��Ȱ��ȭ �����Դϴ�."}';
      Exit;
    end;
  end
  else
  begin
    if Global.TcpThreadHeat = nil then
    begin
      Result := '{"result_cd":"9999","result_msg":"�������� ����� �����ϴ�."}';
      Exit;
    end;
  end;

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;

    if (Global.ADConfig.StoreCode = 'BB001') then //������
    begin
      if Global.ADConfig.DeviceType = 0 then //0:Fan, 1:Heat ������ ����
        Global.ComFan_Dome.SetFanUseAllOff
      else
        Global.ComHeat_Dome.SetHeatUseAllOff;
    end
    else if (Global.ADConfig.StoreCode = 'A8003') then // ����� ������
      Global.ComHeat_A8003.SetHeatUseAllOff
    else
      Global.TcpThreadHeat.SetHeatuseAll;

    Global.XGolfDM.TeeboxHeatUseUpdate(Global.ADConfig.StoreCode, '0', '0', '0', '');

    Result := '{"result_cd":"0000","result_msg":"Success"}';

  finally
    FreeAndNil(jObj);

    //Global.Teebox.TeeboxReserveUse := False;
  end;

end;

function TTcpServer.SetParkingPrintCheck(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sReserveNo, sResult: String;
begin
  //A433_ParkingPrintCheck
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;
    sReserveNo := jObj.GetValue('reserve_no').Value;

    sResult := Global.XGolfDM.SeatUseParkSelect(Global.ADConfig.StoreCode, sReserveNo);
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"9999","result_msg":"' + sResult + '"}';
      Exit;
    end;

    sResult := Global.XGolfDM.SeatUseParkUpdate(Global.ADConfig.StoreCode, sReserveNo);
    Result := '{"result_cd":"0000","result_msg":"Success"}';

  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.ReserveEndTimeCheck(APossibleReserveDatetime, APrepareMin, AAssignMin: String): Boolean;
var
  sLog: String;
  dtEndTmTemp, dtStoreEndTmTemp: TDateTime;
  nMin: Integer;
begin
  Result := False;

  nMin := StrToInt(APrepareMin) + StrToInt(AAssignMin);
  dtEndTmTemp := IncMinute(DateStrToDateTime3(APossibleReserveDatetime), nMin);

  if (Global.Store.StartTime > Global.Store.EndTime) then //��������
  begin
    if FormatDateTime('HH:NN', Now) < Global.Store.EndTime then //����
      dtStoreEndTmTemp := DateStrToDateTime2(FormatDateTime('YYYY-MM-DD', now) + ' ' + Global.Store.EndTime + ':00')
    else
      dtStoreEndTmTemp := DateStrToDateTime2(FormatDateTime('YYYY-MM-DD', now) + ' ' + Global.Store.EndTime + ':00') + 1;
  end
  else //��������
  begin
    dtStoreEndTmTemp := DateStrToDateTime2(FormatDateTime('YYYY-MM-DD', now) + ' ' + Global.Store.EndTime + ':00');
  end;
  dtStoreEndTmTemp := IncMinute(dtStoreEndTmTemp, 1);

  if dtStoreEndTmTemp < dtEndTmTemp then
  begin
    sLog := '��������ð� �ʰ� : ' + FormatDateTime('HH:NN', dtStoreEndTmTemp) + ' < ' + FormatDateTime('HH:NN', dtEndTmTemp);
    Global.Log.LogErpApiWrite(sLog);

    Exit;
  end;

  Result := True;
end;

function TTcpServer.SetAgentSetting(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId: String;
  nTeeboxNo, nMethod: Integer;
  sResult: String;
begin
  //A440_AgentSetting
  Result := '';

  if (Global.ADConfig.StoreCode <> 'CD001') then //CD001	��Ÿ����Ŭ��(�ϻ�)
  begin
    Result := '{"result_cd":"9999","result_msg":"����Ҽ� ���� ����Դϴ�"}';
    Exit;
  end;

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;
    nTeeboxNo := StrToInt(jObj.GetValue('teebox_no').Value);
    nMethod := StrToInt(jObj.GetValue('method').Value);

    if nTeeboxNo < 0 then
    begin
      Result := '{"result_cd":"9999","result_msg":"teebox_no Error"}';
      Exit;
    end;

    if nMethod = 8 then // 8: Ÿ����PC �ѱ�(Wake-On-LKAN)
    begin
      Global.Teebox.SendAgentWOL(nTeeboxNo);

      Result := '{"result_cd":"0000","result_msg":"Success"}';
      Exit;
    end;

    Global.TcpAgentServer.SetSettingList(AReceiveData);

    Result := '{"result_cd":"0000","result_msg":"Success"}';
  finally
    FreeAndNil(jObj);
  end;

end;

end.
