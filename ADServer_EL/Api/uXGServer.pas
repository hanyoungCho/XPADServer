unit uXGServer;

interface

uses
  IdTCPServer, IdContext, System.SysUtils, System.Classes, JSON, Generics.Collections, Windows,
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

    procedure ServerExecute(AContext: TIdContext);

    function SendDataCreat(AReceiveData: AnsiString): AnsiString;

    function SetTeeboxError(AReceiveData: AnsiString): AnsiString;  //Ÿ���� �������/���

    function SetTeeboxHold(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���
    function SetTeeboxHoldCancel(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���

    function SetTeeboxReserve(AReceiveData: AnsiString): AnsiString; //Ÿ���� ������
    function SetTeeboxReserveSql(ASeatUseInfo: TSeatUseInfo): String; //Ÿ���� ��������������
    function SetTeeboxReserveCancel(AReceiveData: AnsiString): AnsiString; //Ÿ���������
    function SetTeeboxReserveChange(AReceiveData: AnsiString): AnsiString; //Ÿ�����ຯ��

    function SetTeeboxMove(AReceiveData: AnsiString): AnsiString; //Ÿ���̵����
    function SetTeeboxClose(AReceiveData: AnsiString): AnsiString; //Ÿ������

    function SetTeeboxStart(AReceiveData: AnsiString): AnsiString; //��ù���
    function SetAgentSetting(AReceiveData: AnsiString): AnsiString; // Agent ���޿�
    function SetDeviceControl(AReceiveData: AnsiString): AnsiString; // ��������Ʈ �����

    function SetApiTeeBoxReg(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveStartDate, AAssignMin, AReserveEndDate: String): String;
    function SetApiTeeBoxEnd(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveEndDate, AEndTy: String): String;

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
  FTcpServer.OnExecute := ServerExecute;
  FTcpServer.Bindings.Add;
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

      sRcvData := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
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
  sStoreCd, sApi, sLogMsg, sUserId: String;
  sResult: AnsiString;
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

      if sApi = 'K403_TeeBoxError' then //Ÿ���� ��ֵ��
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
      else if sApi = 'K416_TeeBoxClose' then //Ÿ������
        sResult := SetTeeboxClose(AReceiveData)
      else if sApi = 'A417_TeeBoxStart' then //��ù���
        sResult := SetTeeboxStart(AReceiveData)
      else if sApi = 'A440_AgentSetting' then // Agent ���޿�
        sResult := SetAgentSetting(AReceiveData)
      else if sApi = 'K501_DeviceControl' then // ��������Ʈ ����
        sResult := SetDeviceControl(AReceiveData)
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

function TTcpServer.SetTeeboxError(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sStoreCd, sApi, sUserId, sTeeboxNo, sErrorDiv: String;
  sResult: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
begin

  //K403_TeeBoxError 03. Ÿ���� ��� ��� (POS/KIOSK)
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;

    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;      //����� Id
    sTeeboxNo := jObj.GetValue('teebox_no').Value;  //Ÿ���� ��ȣ
    sErrorDiv := jObj.GetValue('error_div').Value;  //��� ���� �ڵ�

    if (sTeeboxNo = '0') then
    begin
      Result := '{"result_cd":"403A",' +
                 '"result_msg":"Ÿ����ȣ�� Ȯ�����ּ���."}';

      Exit;
    end;

    if sErrorDiv = '0' then // ����/���Ұ� ����
    begin
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));

      //������ �ƴϰ� ������̸�
      if (rTeeboxInfo.UseStatus <> '8') and (rTeeboxInfo.UseYn = 'Y') then
      begin
        sResult := 'Success';
      end
      else
      begin
        if rTeeboxInfo.UseStatus = '8' then
        begin
          sResult := Global.XGolfDM.TeeboxErrorUpdate(sUserId, sTeeboxNo, '0');

          if sResult = 'Success' then
            Global.Teebox.TeeboxDeviceCheck(StrToInt(sTeeboxNo), '0');
        end;

        if rTeeboxInfo.UseYn = 'N' then
        begin
          sResult := Global.XGolfDM.TeeboxUseUpdate(sUserId, sTeeboxNo, 'Y');

          if sResult = 'Success' then
            Global.Teebox.TeeboxDeviceUseYN(StrToInt(sTeeboxNo), 'Y');
        end;
      end;
    end
    else if sErrorDiv = '1' then //����
    begin
      //�����̸�
      if rTeeboxInfo.UseStatus = '8' then
      begin
        sResult := 'Success';
      end
      else
      begin
        sResult := Global.XGolfDM.TeeboxErrorUpdate(sUserId, sTeeboxNo, '8');

        if sResult = 'Success' then
          Global.Teebox.TeeboxDeviceCheck(StrToInt(sTeeboxNo), '8');
      end;
    end
    else if sErrorDiv = '2' then //���Ұ�
    begin
      //���Ұ��̸�
      if rTeeboxInfo.UseYn = 'N' then
      begin
        sResult := 'Success';
      end
      else
      begin
        sResult := Global.XGolfDM.TeeboxUseUpdate(sUserId, sTeeboxNo, 'N');

        if sResult = 'Success' then
          Global.Teebox.TeeboxDeviceUseYN(StrToInt(sTeeboxNo), 'N');
      end;
    end;

    if sResult = 'Success' then
      Result := '{"result_cd":"0000","result_msg":"Success"}'
    else
      Result := '{"result_cd":"0001","result_msg":"' + sResult + '"}';

  finally
    FreeAndNil(jObj);
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
                 //'"result_msg":"Already holded teebox, choose another teebox please",' +
                 '"hold_yn":"Y","store_close_time":"' + Global.Store.EndTime + '","change_store_date":"' + Global.Store.StoreChgDate + '"}';
      Exit;
    end;

    rSeatInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));

    try
      sResult := Global.XGolfDM.TeeboxHoldInsert(sUserId, sTeeboxNo, rSeatInfo.TeeboxNm);

      if sResult = 'Success' then
      begin
        Global.Teebox.SetTeeboxHold(sTeeboxNo, sUserId, True);
        Result := '{"result_cd":"0000","result_msg":"Success","hold_yn":"Y","store_close_time":"' + Global.Store.EndTime + '","change_store_date":"' + Global.Store.StoreChgDate + '"}';
        //Result := '{"result_cd":"0000","result_msg":"Success","hold_yn":"Y"}';
      end
      else
      begin
        Result := '{"result_cd":"",' +
                    //'"result_msg":"' + sResult + '",' +
                    '"result_msg":"�ӽÿ��࿡ �����Ͽ����ϴ�. �ٽ� �õ����ּ���",' +
                    '"hold_yn":"N","store_close_time":"' + Global.Store.EndTime + '","change_store_date":"' + Global.Store.StoreChgDate + '"}';
      end;

    except
      on e: Exception do
      begin
        sLog := 'SeatHoldInsert Exception : ' + sTeeboxNo + ' / ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);

        Global.XGolfDM.ReConnectionHold;
        Global.Log.LogErpApiWrite('ReConnectionHold');

        Result := '{"result_cd":"",' +
                  //'"result_msg":"' + e.Message + '",' +
                  '"result_msg":"�ӽÿ����� ��ְ� �߻��Ͽ����ϴ�",' +
                  '"hold_yn":"N","store_close_time":"' + Global.Store.EndTime + '","change_store_date":"' + Global.Store.StoreChgDate + '"}';
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

      sResult := Global.XGolfDM.TeeboxHoldDelete(sUserId, sTeeboxNo);

      if sResult = 'Success' then
      begin
        Global.Teebox.SetTeeboxHold(sTeeboxNo, sUserId, False);
        //Result := '{"result_cd":"0000","result_msg":"Success","hold_yn":"N"}';
        Result := '{"result_cd":"0000","result_msg":"Success"}';
      end
      else
        //Result := '{"result_cd":"","result_msg":"�ӽÿ����� �������� ���Ͽ����ϴ�. �ٽ� �õ����ּ���.","hold_yn":"Y"}';
        Result := '{"result_cd":"","result_msg":"�ӽÿ����� �������� ���Ͽ����ϴ�. �ٽ� �õ����ּ���."}';

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
  sResult: String;

  nIndex, nReIndex: Integer;
  sPossibleReserveDatetime: String;
  rSeatUseInfo: TSeatUseInfo;
  nUseSeq: Integer;

  SeatUseReserveTemp: TSeatUseReserve;

  sUseSeqDate: String;

  jReciveObjArr: TJsonArray; //pos,kiosk ����
  jReciveItemObj: TJSONObject;

  jErpSeObj, jErpSeItemObj: TJSONObject; //Erp ��������
  jErpSeObjE: TJSONObject; //Epr ������ �����߻���

  jErpRvObj, jErpRvItemObj, jErpRvSubItemObj: TJSONObject;
  sErpRvResultCd, sErpRvResultMsg, sErpRvMemberNm: String;

  sLog: String;

  rSeatInfoTemp: TTeeboxInfo;

  jSendObj, jSendItemObj: TJSONObject; // pos,kiosk ��������
  jSendObjArr, jSendSubObjArr: TJSONArray;

  I, j: Integer;
  sDate: String;
  sReserveSql: String;

  //����ð� ����
  sPossibleReserveDatetimeChk: String;

  sReserveTmTemp: String;
  dtReserveStartTmTemp: TDateTime;

  //sAffiliateCd: String;
  bErpError: Boolean;
begin

  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then //TeeboxThread ���������
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;

  //K408_TeeBoxReserve2
  Result := '';

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
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;  //K408_TeeBoxReserve2
    sUserId := jObj.GetValue('user_id').Value;

    sMemberNo := jObj.GetValue('member_no').Value;
    sMemberNm := jObj.GetValue('member_nm').Value;
	  sReserveRootDiv := jObj.GetValue('reserve_root_div').Value; //����߱ǰ�α���	S	K	K:Ű����ũ, P:����, M:�����

    sXgUserKey := EmptyStr;
    if sReserveRootDiv = 'M' then
      sXgUserKey := jObj.GetValue('xg_user_key').Value;

    sReceiptNo := jObj.GetValue('receipt_no').Value; //��������ȣ

    jReciveObjArr := jObj.GetValue('data') as TJsonArray;

    sUseSeqDate := FormatDateTime('YYYYMMDD', Now);

    jReciveItemObj := jReciveObjArr.Get(0) as TJSONObject;

    FLastUseSeqNo := FLastUseSeqNo + 1;
    rSeatUseInfo.UseSeqDate := sUseSeqDate;
    rSeatUseInfo.UseSeqNo := FLastUseSeqNo;
    rSeatUseInfo.ReserveNo := rSeatUseInfo.UseSeqDate + StrZeroAdd(IntToStr(rSeatUseInfo.UseSeqNo), 4);

    rSeatUseInfo.StoreCd := Global.ADConfig.StoreCode;

    sTeeboxNo := jReciveItemObj.GetValue('teebox_no').Value;
    rSeatUseInfo.SeatNo := StrToInt(sTeeboxNo);

    rSeatInfoTemp := Global.Teebox.GetTeeboxInfo(rSeatUseInfo.SeatNo);

    rSeatUseInfo.SeatNm := rSeatInfoTemp.TeeboxNm;

    rSeatUseInfo.SeatUseStatus := '4';  // 4: ����
    rSeatUseInfo.MemberSeq := sMemberNo;
    rSeatUseInfo.MemberNm := sMemberNm;
    rSeatUseInfo.ReserveRootDiv := sReserveRootDiv;
    rSeatUseInfo.RegId := sUserId;
    rSeatUseInfo.ProductSeq := StrToInt(jReciveItemObj.GetValue('product_cd').Value);    //Ÿ����ǰ�ڵ�
    rSeatUseInfo.ProductNm := jReciveItemObj.GetValue('product_nm').Value;

    //�̷�- 1:Ÿ����ǰ, 2:������ǰ, 3:��Ŀ��ǰ
    rSeatUseInfo.ReserveDiv := jReciveItemObj.GetValue('reserve_div').Value;

    rSeatUseInfo.AssignMin := StrToInt(jReciveItemObj.GetValue('assign_min').Value);    //�����ð�(��)
    rSeatUseInfo.PrepareMin := StrToInt(jReciveItemObj.GetValue('prepare_min').Value);  //�غ�ð�(��)

    sPossibleReserveDatetime := Global.XGolfDM.SelectPossibleReserveDatetime(sTeeboxNo);
    if ( sPossibleReserveDatetime = '' ) or (sPossibleReserveDatetime < FormatDateTime('YYYYMMDDhhnnss', Now)) then
    begin
      sPossibleReserveDatetime := FormatDateTime('YYYYMMDDhhnnss', Now);

      //���翹��ð� ����
      if (rSeatInfoTemp.UseStatus = '1') then
      begin
        sPossibleReserveDatetimeChk :=  Global.Teebox.GetTeeboxNowReserveLastTime(sTeeboxNo);
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
      //����ð� ����
      sPossibleReserveDatetimeChk :=  Global.ReserveList.GetTeeboxReserveLastTime(sTeeboxNo);
      if sPossibleReserveDatetime < sPossibleReserveDatetimeChk then
      begin
        sLog := 'SetTeeboxReserve Time : ' + sTeeboxNo + ' / ' + sPossibleReserveDatetime + ' -> ' + sPossibleReserveDatetimeChk;
        Global.Log.LogErpApiWrite(sLog);
        sPossibleReserveDatetime := sPossibleReserveDatetimeChk;
      end;
    end;

    rSeatUseInfo.ReserveDate := sPossibleReserveDatetime;

    dtReserveStartTmTemp := DateStrToDateTime3(rSeatUseInfo.ReserveDate) + (((1/24)/60) * rSeatUseInfo.PrepareMin);
    SeatUseReserveTemp.StartTime := FormatDateTime('YYYYMMDDhhnnss', dtReserveStartTmTemp);

    rSeatUseInfo.StartTime := SeatUseReserveTemp.StartTime;

    //DB ��ȸ�κ� ����
    SeatUseReserveTemp.ReserveNo := rSeatUseInfo.ReserveNo;
    SeatUseReserveTemp.SeatNo := rSeatUseInfo.SeatNo;
    SeatUseReserveTemp.UseMinute := rSeatUseInfo.AssignMin;
    SeatUseReserveTemp.DelayMinute := rSeatUseInfo.PrepareMin;
    SeatUseReserveTemp.ReserveDate := rSeatUseInfo.ReserveDate;
    SeatUseReserveTemp.StartTime := rSeatUseInfo.StartTime;

    try

      //Erp ���� ��������
      jErpSeObj := TJSONObject.Create;
      jErpSeObjE := TJSONObject.Create;

      jErpSeObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
      jErpSeObj.AddPair(TJSONPair.Create('member_no', sMemberNo));
      jErpSeObj.AddPair(TJSONPair.Create('reserve_root_div', sReserveRootDiv));
      jErpSeObj.AddPair(TJSONPair.Create('user_id', sUserId));
      jErpSeObj.AddPair(TJSONPair.Create('memo', ''));
      jErpSeObj.AddPair( TJSONPair.Create( 'teebox_no', IntToStr(rSeatUseInfo.SeatNo) ) );
      jErpSeObj.AddPair( TJSONPair.Create( 'reserve_no', rSeatUseInfo.ReserveNo ) );
      jErpSeObj.AddPair( TJSONPair.Create( 'product_cd', IntToStr(rSeatUseInfo.ProductSeq) ) );
      jErpSeObj.AddPair( TJSONPair.Create( 'assign_min', IntToStr(rSeatUseInfo.AssignMin) ) );
      jErpSeObj.AddPair( TJSONPair.Create( 'prepare_min', IntToStr(rSeatUseInfo.PrepareMin) ) );
      jErpSeObj.AddPair( TJSONPair.Create( 'reserve_datetime', rSeatUseInfo.ReserveDate ) );

      //Erp ��������
      bErpError := False;
      sResult := Global.Api.PostErpApi(jErpSeObj.ToString, 'K701_TeeboxReserve', Global.ADConfig.ApiUrl);
      Global.Log.LogErpApiWrite(sResult);

      if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
      begin
        sLog := 'SetSeatReserve Fail : ' + rSeatUseInfo.ReserveNo + ' / ' + sResult;
        Global.Log.LogErpApiWrite(sLog);

        sLog := jErpSeObj.ToString;
        Global.Log.LogErpApiWrite(sLog);
        bErpError := True;
      end;

      if bErpError = True then //��ſ����� ��� ������Ͽ��� Ȯ��
      begin
        sleep(100);

        jErpSeObjE.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
        jErpSeObjE.AddPair(TJSONPair.Create('teebox_no', IntToStr(rSeatUseInfo.SeatNo) ) );
        jErpSeObjE.AddPair(TJSONPair.Create('reserve_no', rSeatUseInfo.ReserveNo ) );

        sResult := Global.Api.PostErpApi(jErpSeObjE.ToString, 'K707_TeeboxReserveCheck', Global.ADConfig.ApiUrl);
        Global.Log.LogErpApiWrite(sResult);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'K707_TeeboxReserveCheck Fail : ' + rSeatUseInfo.ReserveNo + ' / ' + sResult;
          Global.Log.LogErpApiWrite(sLog);

          sLog := jErpSeObjE.ToString;
          Global.Log.LogErpApiWrite(sLog);

          Result := '{"result_cd":"0002",' +
                     '"result_msg":"���೻���� ������ ����� ��ְ� �߻��Ͽ����ϴ�."}';

          //Ȧ����� ó��
          Global.Teebox.SetTeeboxHold(IntToStr(rSeatUseInfo.SeatNo), sUserId, False);
          Global.XGolfDM.TeeboxHoldDelete(sUserId, IntToStr(rSeatUseInfo.SeatNo));

          Global.Teebox.TeeboxReserveUse := False;
          Exit;
        end;
      end;

      jErpRvObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
      sErpRvResultCd := jErpRvObj.GetValue('result_cd').Value;
      sErpRvResultMsg := jErpRvObj.GetValue('result_msg').Value;

      if bErpError = True then
        sLog := 'K707_TeeboxReserveCheck : ' + rSeatUseInfo.ReserveNo + ' / ' + sErpRvResultCd + ' / ' + sErpRvResultMsg
      else
        sLog := 'K701_TeeBoxReserve : ' + rSeatUseInfo.ReserveNo + ' / ' + sErpRvResultCd + ' / ' + sErpRvResultMsg;
      Global.Log.LogErpApiWrite(sLog);

      if sErpRvResultCd <> '0000' then
      begin
        Result := '{"result_cd":"' + sErpRvResultCd + '",' +
                   '"result_msg":"' + sErpRvResultMsg + '"}';

        //Ȧ����� ó��
        Global.Teebox.SetTeeboxHold(IntToStr(rSeatUseInfo.SeatNo), sUserId, False);
        Global.XGolfDM.TeeboxHoldDelete(sUserId, IntToStr(rSeatUseInfo.SeatNo));

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;

      sReserveSql := '';
      sReserveSql := sReserveSql + SetTeeboxReserveSql(rSeatUseInfo);

      //Ȧ����� ó��
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
        //Global.XGolfDM.RollbackTrans;

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;
    end;

    FUseSeqNo := FLastUseSeqNo;

    jSendObjArr := TJSONArray.Create;
    jSendObj := TJSONObject.Create;
    jSendObj.AddPair(TJSONPair.Create('result_cd', '0000'));
    jSendObj.AddPair(TJSONPair.Create('result_msg', 'Success'));

    jSendObj.AddPair(TJSONPair.Create('data', jSendObjArr));

    if not (jErpRvObj.FindValue('result_data') is TJSONNull) then
    begin
      jErpRvItemObj := jErpRvObj.GetValue('result_data') as TJSONObject;

      jSendItemObj := TJSONObject.Create;
      jSendItemObj.AddPair( TJSONPair.Create( 'reserve_no', jErpRvItemObj.GetValue('reserve_no').Value) );
      //jSendItemObj.AddPair( TJSONPair.Create( 'purchase_cd', jErpRvItemObj.GetValue('purchase_cd').Value) );
      jSendItemObj.AddPair( TJSONPair.Create( 'product_cd', jErpRvItemObj.GetValue('product_cd').Value) );
      jSendItemObj.AddPair( TJSONPair.Create( 'product_nm', jErpRvItemObj.GetValue('product_nm').Value) );
      jSendItemObj.AddPair( TJSONPair.Create( 'product_div', jErpRvItemObj.GetValue('product_div').Value) );
      jSendItemObj.AddPair( TJSONPair.Create( 'floor_nm', jErpRvItemObj.GetValue('floor_nm').Value) );
      jSendItemObj.AddPair( TJSONPair.Create( 'teebox_nm', jErpRvItemObj.GetValue('teebox_nm').Value) );
      jSendItemObj.AddPair( TJSONPair.Create( 'reserve_datetime', jErpRvItemObj.GetValue('reserve_datetime').Value) );

      sReserveTmTemp := jErpRvItemObj.GetValue('reserve_datetime').Value;
      dtReserveStartTmTemp := DateStrToDateTime3(sReserveTmTemp) + (((1/24)/60) * rSeatUseInfo.PrepareMin);
      sDate := FormatDateTime('YYYY-MM-DD hh:nn:ss', dtReserveStartTmTemp);
      jSendItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate ) );

      jSendItemObj.AddPair( TJSONPair.Create( 'remain_min', jErpRvItemObj.GetValue('assign_min').Value) );
      jSendItemObj.AddPair( TJSONPair.Create( 'expire_day', jErpRvItemObj.GetValue('expire_day').Value) );
      jSendItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', jErpRvItemObj.GetValue('coupon_cnt').Value) );

      jSendObjArr.Add(jSendItemObj);
    end;

    Result := jSendObj.ToString;

    //�������
    if SeatUseReserveTemp.ReserveDate <= FormatDateTime('YYYYMMDDhhnnss', Now) then
      Global.Teebox.SetTeeboxReserveInfo(SeatUseReserveTemp)
    else
      global.ReserveList.SetTeeboxReserveNext(SeatUseReserveTemp);

  finally
    FreeAndNil(jErpSeObj);
    FreeAndNil(jErpSeObjE);

    FreeAndNil(jObj);
    FreeAndNil(jErpRvObj);

    FreeAndNil(jSendObj);

    Global.Teebox.TeeboxReserveUse := False;
  end;

end;

function TTcpServer.SetTeeboxReserveSql(ASeatUseInfo: TSeatUseInfo): String; //Ÿ���� ��������������
var
  sSql: String;
begin
  Result := '';

  sSql :=  ' insert into seat_use ' +
             '  (  use_seq_date, use_seq_no, store_cd, use_status, seat_no, seat_nm ' +
             '  , member_seq, member_nm ' +
             '  , product_seq, product_nm, reserve_div, use_minute ' +
             '  , delay_minute, reserve_date, reserve_root_div ' +
             '  , chg_date , reg_date, reg_id) ' +
              ' values ' +
             ' (' + QuotedStr(ASeatUseInfo.UseSeqDate) +
             ' ,' + IntToStr(ASeatUseInfo.UseSeqNo) +
             ' ,' + QuotedStr(ASeatUseInfo.StoreCd) +
             ' ,' + ASeatUseInfo.SeatUseStatus +
             ' ,' + IntToStr(ASeatUseInfo.SeatNo) +
             ' ,' + QuotedStr(ASeatUseInfo.SeatNm) +
             ' ,' + QuotedStr(ASeatUseInfo.MemberSeq) +
             ' ,' + QuotedStr(ASeatUseInfo.MemberNm) +
             ' ,' + IntToStr(ASeatUseInfo.ProductSeq) +
             ' ,' + QuotedStr(ASeatUseInfo.ProductNm) +
             ' ,' + QuotedStr(ASeatUseInfo.ReserveDiv) +
             ' ,' + IntToStr(ASeatUseInfo.AssignMin) +
             ' ,' + IntToStr(ASeatUseInfo.PrepareMin) +
             ' , date_format(' + QuotedStr(ASeatUseInfo.ReserveDate) + ', ''%Y-%m-%d %H:%i:%S'') ' +
             ' ,' + QuotedStr(ASeatUseInfo.ReserveRootDiv) +
             ' , now() ' +
             ' , now() ' +
             ' ,' + QuotedStr(ASeatUseInfo.RegId) + ' ); ';

  Result := sSql;
end;

function TTcpServer.SetTeeboxReserveCancel(AReceiveData: AnsiString): AnsiString; //Ÿ���������
var
  jObj: TJSONObject;
  jErpSeObj, jRvObj: TJSONObject;
  sApi, sUserId, sReserveNo, sReserveNoTemp, sReceiptNo: String;
  sUseSeqDate, sUseSeqNo: String;
  nUseSeqNo, nIndex: Integer;
  sResult: AnsiString;
  rSeatUseInfoList: TList<TSeatUseInfo>;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog, sLogH: String;
begin

  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiWrite(sLog);

    sleep(50);
  end;

  Global.Teebox.TeeboxReserveUse := True;

  //K410_TeeBoxReserved
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;      //����� Id
    sReserveNo := jObj.GetValue('reserve_no').Value;  //Ÿ���� ��ȣ

    sUseSeqDate := '';
    sUseSeqNo := '';
    if sReserveNo <> '' then
    begin
      sUseSeqDate := Copy(sReserveNo, 1, 8);
      nUseSeqNo := StrToInt(Copy(sReserveNo, 9, 4));
      sUseSeqNo := IntToStr(nUseSeqNo);
    end;

    rSeatUseInfoList := Global.XGolfDM.SeatUseSelectList(Global.ADConfig.StoreCode, '', sUseSeqDate, sUseSeqNo, sReceiptNo);

    if rSeatUseInfoList.Count = 0 then
    begin
      Result := '{"result_cd":"0001","result_msg":"�������� �ʴ� �����ȣ �Դϴ�."}';
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

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

      try
        jErpSeObj := TJSONObject.Create;
        jErpSeObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
        jErpSeObj.AddPair(TJSONPair.Create('teebox_no', IntToStr(rSeatUseInfoList[nIndex].SeatNo) ) );
        jErpSeObj.AddPair(TJSONPair.Create('reserve_no', sReserveNo ) );
        jErpSeObj.AddPair(TJSONPair.Create('user_id', sUserId));
        jErpSeObj.AddPair(TJSONPair.Create('memo', '' ) );

        sLogH := IntToStr(rSeatUseInfoList[nIndex].SeatNo) + ' [ ' + rSeatUseInfoList[nIndex].SeatNm + ' ] ' + sReserveNoTemp;
        sResult := Global.Api.PostErpApi(jErpSeObj.ToString, 'K704_TeeboxCancel', Global.ADConfig.ApiUrl);

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
  nSeq, nSeqNo, nIndex: Integer;
  sResult: AnsiString;

  sDate: String;
  rSeatUseInfo: TSeatUseInfo;
  rSeatUseInfoTemp: TSeatUseInfo;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog: String;

  jErpObjArr: TJSONArray;
  jErpItemObj, jErpSubItemObj: TJSONObject;

  jSeObj, jSeItemObj: TJSONObject; //������
  jSeSubItemObj: TJSONObject; //���䰪
  jSeObjArr, jSeSubObjArr: TJSONArray;

  jErpSeObj: TJSONObject;
  jErpRvObj: TJSONObject;

  dtReserveStartTmTemp, tmTempE: TDateTime;
  sEndDateTemp: String;
  sMemberNo, sMemberNm: String;
begin

  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiWrite(sLog);

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

    if jObj.FindValue('member_no') <> nil then
      sMemberNo := jObj.GetValue('member_no').Value;

    if jObj.FindValue('member_nm') <> nil then
      sMemberNm := jObj.GetValue('member_nm').Value;

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

    rSeatUseInfo.PrepareMin := StrToInt(sPrepareMin);
    rSeatUseInfo.ChgId := sUserId;

    if sMemberNo <> '' then
      rSeatUseInfo.MemberSeq := sMemberNo;
    if sMemberNm <> '' then
      rSeatUseInfo.MemberNm := sMemberNm;

    sResult := Global.XGolfDM.SeatUseChangeUdate(rSeatUseInfo); // POS/KIOSK �� Update
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"411B","result_msg":"����ð� ���濡 �����Ͽ����ϴ�."}';
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    rSeatUseInfoTemp := Global.XGolfDM.SelectTeeboxReservationOneWithSeq(Global.ADConfig.StoreCode, sSeqDate, IntToStr(nSeqNo));

    if rSeatUseInfoTemp.UseSeq = -1 then
    begin
      rSeatUseInfoTemp.ReserveNo := sSeqDate + StrZeroAdd(IntToStr(nSeqNo), 4);
      dtReserveStartTmTemp := DateStrToDateTime3(rSeatUseInfo.ReserveDate) + (((1/24)/60) * rSeatUseInfo.PrepareMin);
      rSeatUseInfoTemp.StartTime := FormatDateTime('YYYYMMDDhhnnss', dtReserveStartTmTemp);

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
    jSeItemObj.AddPair( TJSONPair.Create( 'product_cd', IntToStr(rSeatUseInfoTemp.ProductSeq)) );
    jSeItemObj.AddPair( TJSONPair.Create( 'product_nm', rSeatUseInfoTemp.ProductNm) );
    jSeItemObj.AddPair( TJSONPair.Create( 'product_div', rSeatUseInfoTemp.ReserveDiv) );
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
    jSeItemObj.AddPair( TJSONPair.Create( 'expire_day', '') );
    jSeItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', '') );

    jSeSubObjArr := TJSONArray.Create;
    jSeItemObj.AddPair(TJSONPair.Create('coupon', jSeSubObjArr));

    jSeObjArr.Add(jSeItemObj);

    Result := jSeObj.toString;

    //Ÿ���� ����
    Global.Teebox.SetTeeboxReserveChange(rSeatUseInfo);

    try

      //��������ð�
      //tmTempE := DateStrToDateTime3(rSeatUseInfoTemp.StartTime) + (((1/24)/60) * StrToInt(sAssignMin));
      tmTempE := DateStrToDateTime3(rSeatUseInfoTemp.StartTime) + (((1/24)/60) * rSeatUseInfo.AssignMin);
      sEndDateTemp := formatdatetime('YYYYMMDDhhnnss', tmTempE);

      jErpSeObj := TJSONObject.Create;
      jErpSeObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
      jErpSeObj.AddPair(TJSONPair.Create('teebox_no', IntToStr(rSeatUseInfo.SeatNo) ) );
      jErpSeObj.AddPair(TJSONPair.Create('reserve_no', sReserveNo ) );
      jErpSeObj.AddPair(TJSONPair.Create('assign_min', IntToStr(rSeatUseInfo.AssignMin) ) );
      jErpSeObj.AddPair(TJSONPair.Create('prepare_min', sPrepareMin ) );
      jErpSeObj.AddPair(TJSONPair.Create('end_datetime', sEndDateTemp ) );
      jErpSeObj.AddPair(TJSONPair.Create('user_id', sUserId));

      sResult := Global.Api.PostErpApi(jErpSeObj.ToString, 'K703_TeeboxChg', Global.ADConfig.ApiUrl);

      if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
      begin
        sLog := 'SetSeatReserveChange Fail : ' + sResult;
        Global.Log.LogErpApiWrite(sLog);
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

  finally
    FreeAndNil(jErpRvObj);
    FreeAndNil(jErpItemObj);
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
  nSeq, nSeqNo, nIndex: Integer;

  sResult: AnsiString;
  rSeatUseInfo: TSeatUseInfo;
  rSeatUseInfoTemp: TSeatUseInfo;
  sOldSeatNo, sOldSeatNm: String;

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

  dtReserveStartTmTemp: TDateTime;

  //����ð� ����
  sPossibleReserveDatetimeChk: String;
begin

  while True do
  begin
    if Global.Teebox.TeeboxStatusUse = False then
      Break;

    sLog := 'SeatStatusUse !!!!!!';
    Global.Log.LogErpApiWrite(sLog);

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

    // ����ɸ��ִ°� �������� �ɱ�
    sPossibleReserveDatetime := Global.XGolfDM.SelectPossibleReserveDatetime(sTeeboxNo);
    if ( sPossibleReserveDatetime = '' ) or (sPossibleReserveDatetime < FormatDateTime('YYYYMMDDhhnnss', Now)) then
      sPossibleReserveDatetime := FormatDateTime('YYYYMMDDhhnnss', Now)
    else
    begin
      //����ð� ����
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
    rSeatUseInfo.PrepareMin := StrToInt(sPrepareMin);
    rSeatUseInfo.RegId := sUserId;

    rSeatUseInfo.UseSeqDate := FormatDateTime('YYYYMMDD', Now);
    FUseSeqNo := FUseSeqNo + 1;

    //��õ� ���� �����ȣ �ӽû������� ����
    FLastUseSeqNo := FUseSeqNo;
    rSeatUseInfo.UseSeqNo := FUseSeqNo;

    //����ó��
    sResult := Global.XGolfDM.SeatUseMoveUpdate(Global.ADConfig.StoreCode, IntToStr(rSeatUseInfo.UseSeq), sUserId);
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"412C","result_msg":"����ó���� �����Ͽ����ϴ� ' + sResult + '"}';
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    //�̵�Ÿ�� ������Ʈ
    sReserveSql := SetTeeboxReserveSql(rSeatUseInfo);

    //Ȧ����� ó��
    Global.Teebox.SetTeeboxHold(IntToStr(rSeatUseInfo.SeatNo), sUserId, False);
    Global.XGolfDM.TeeboxHoldDelete(sUserId, IntToStr(rSeatUseInfo.SeatNo));

    sResult := Global.XGolfDM.TeeboxUseInsert(sReserveSql);
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"412D","result_msg":"�ű� ������� ' + sResult + '"}';
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    rSeatUseInfoTemp := Global.XGolfDM.SelectTeeboxReservationOneWithSeq(Global.ADConfig.StoreCode, rSeatUseInfo.UseSeqDate, IntToStr(rSeatUseInfo.UseSeqNo));

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

    jSeItemObj.AddPair( TJSONPair.Create( 'expire_day', '') );
    jSeItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', '') );

    jSeSubObjArr := TJSONArray.Create;
    jSeItemObj.AddPair(TJSONPair.Create('coupon', jSeSubObjArr));

    jSeObjArr.Add(jSeItemObj);

    Result := jSeObj.ToString;

    global.Teebox.SetTeeboxReserveCancle(StrToInt(sOldSeatNo), sReserveNo);

    rSeatUseReserve.SeatNo := StrToInt(sTeeboxNo);
    rSeatUseReserve.ReserveNo := rSeatUseInfoTemp.ReserveNo;
    rSeatUseReserve.UseMinute := StrToInt(sAssignMin);
    rSeatUseReserve.DelayMinute := StrToInt(sPrepareMin);
    rSeatUseReserve.ReserveDate := sPossibleReserveDatetime;

    if rSeatUseReserve.ReserveDate <= FormatDateTime('YYYYMMDDhhnnss', Now) then
      Global.Teebox.SetTeeboxReserveInfo(rSeatUseReserve)
    else
      global.ReserveList.SetTeeboxReserveNext(rSeatUseReserve);


    begin
      try
        sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                    '&teebox_no=' + sOldSeatNo +
                    '&reserve_no=' + sReserveNo +
                    '&move_teebox_no=' + sTeeboxNo +
                    '&move_reserve_no=' + rSeatUseReserve.ReserveNo +
                    '&reserve_datetime=' + rSeatUseReserve.ReserveDate +
                    '&assign_min=' + sAssignMin +
                    '&prepare_min=' + sPrepareMin +
                    '&user_id=' + sUserId;

        sResult := Global.Api.PostErpApi(sJsonStr, 'K706_TeeboxMove', Global.ADConfig.ApiUrl);

        if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
        begin
          sLog := 'SetSeatMove Fail : ' + sResult;
          Global.Log.LogErpApiWrite(sLog);
        end
        else
        begin
          jErpRvObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
          sResultCd := jErpRvObj.GetValue('result_cd').Value;
          sResultMsg := jErpRvObj.GetValue('result_msg').Value;

          sLog := 'K706_TeeboxMove : ' + sOldSeatNo + ' [ ' + sOldSeatNm + ' ] ' + sReserveNo + ' -> ' +
                  IntToStr(rSeatUseInfo.SeatNo)  + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
                  rSeatUseReserve.ReserveNo + ' / ' + sResultCd + ' / ' + sResultMsg;
          Global.Log.LogErpApiWrite(sLog);
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

function TTcpServer.SetTeeboxClose(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sReserveNo, sUseSeqDate: String;
  nUseSeqNo: Integer;
  sResult: AnsiString;
  rSeatUseInfo: TSeatUseInfo;
  sLog: String;
begin
  //K416_TeeBoxClose
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;   //K414_TeeBoxClose
    sUserId := jObj.GetValue('user_id').Value;
    sReserveNo := jObj.GetValue('reserve_no').Value;

    sUseSeqDate := Copy(sReserveNo, 1, 8);
    nUseSeqNo := StrToInt(Copy(sReserveNo, 9, 4));

    rSeatUseInfo := Global.XGolfDM.SeatUseSelectOne(Global.ADConfig.StoreCode, '', sUseSeqDate, IntToStr(nUseSeqNo));

    Result := '{"result_cd":"0000","result_msg":"Success"}';

    global.Teebox.SetTeeboxReserveClose(rSeatUseInfo.SeatNo, sReserveNo);

    sLog := 'K414_TeeBoxClose : ' + IntToStr(rSeatUseInfo.SeatNo) + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
            sUserId + ' / ' + sReserveNo;
    Global.Log.LogErpApiWrite(sLog);
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
  //K416_TeeBoxClose
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;   //K414_TeeBoxClose
    sUserId := jObj.GetValue('user_id').Value;
    sReserveNo := jObj.GetValue('reserve_no').Value;

    sUseSeqDate := Copy(sReserveNo, 1, 8);
    nUseSeqNo := StrToInt(Copy(sReserveNo, 9, 4));

    rSeatUseInfo := Global.XGolfDM.SeatUseSelectOne(Global.ADConfig.StoreCode, '', sUseSeqDate, IntToStr(nUseSeqNo));

    sResult := global.Teebox.SetTeeboxReserveStartNow(rSeatUseInfo.SeatNo, sReserveNo);
    if sResult = 'Success' then
    begin
      Result := '{"result_cd":"0000","result_msg":"Success"}';
      sLog := 'A417_TeeBoxStart : ' + IntToStr(rSeatUseInfo.SeatNo) + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
            sUserId + ' / ' + sReserveNo;
    end
    else
    begin
      Result := '{"result_cd":"0000","result_msg":"' + sResult + '"}';
      sLog := 'A417_TeeBoxStart Fail : ' + IntToStr(rSeatUseInfo.SeatNo) + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
            sUserId + ' / ' + sReserveNo;
    end;

    Global.Log.LogErpApiWrite(sLog);
  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetAgentSetting(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId: String;
  nTeeboxNo, nMethod: Integer;
  //sResult: String;
begin
  //A440_AgentSetting
  Result := '';

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

    Global.Teebox.SetTeeboxCtrl('Tsetting', '', nTeeboxNo, nMethod, 0);

    Result := '{"result_cd":"0000","result_msg":"Success"}';
  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetDeviceControl(AReceiveData: AnsiString): AnsiString;
var
  jObj: TJSONObject;
  sApi, sUserId, sDeviceDiv, sControlDiv, sCommand: String;
  nTeeboxNo: Integer;
  sResult: String;
  sBeamType, sBeamIp: String;
begin
  //K450_BeamProjectorOnOff
  Result := '';

  try
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;
    nTeeboxNo := StrToInt(jObj.GetValue('teebox_no').Value);
    sDeviceDiv := jObj.GetValue('device_div').Value;
    sControlDiv := jObj.GetValue('control_div').Value;
    sCommand := jObj.GetValue('command').Value;

    if nTeeboxNo < 0 then
    begin
      Result := '{"result_cd":"9999","result_msg":"teebox_no Error"}';
      Exit;
    end;

    if sDeviceDiv = '100' then //����������
    begin
      if sControlDiv = '101' then //���������� ��������
      begin
        sBeamType := Global.Teebox.GetTeeboxInfoBeamType(nTeeboxNo);
        sBeamIp := Global.Teebox.GetTeeboxInfoBeamIP(nTeeboxNo);
        sResult := Global.Api.PostBeamApi(sBeamType, sBeamIp);
        //Global.Log.LogErpApiWrite(sResult);

        if sBeamType = '1' then  //1:'Hitachi' , 2:'Sony'
        begin
          if sResult <> '[{"rtn":6,"opt":[0,0,0,0] },]' then
          begin
            Result := '{"result_cd":"9999","result_msg":"Fail / ' + sResult + '"}';
            Exit;
          end;
        end
        else if sBeamType = '2' then
        begin
          if sResult <> '[{ "value": 32},]' then
          begin
            Result := '{"result_cd":"9999","result_msg":"Fail / ' + sResult + '"}';
            Exit;
          end;
        end
        else
        begin
          Result := '{"result_cd":"9999","result_msg":"Fail / control_div error / BeamType ' + sBeamType + '"}';
          Exit;
        end;
      end
      else
      begin
        Result := '{"result_cd":"9999","result_msg":"Fail / control_div error"}';
        Exit;
      end;
    end
    else
    begin
      Result := '{"result_cd":"9999","result_msg":"Fail / device_div error"}';
      Exit;
    end;

    Result := '{"result_cd":"0000","result_msg":"Success"}';
  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetApiTeeBoxReg(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveStartDate, AAssignMin, AReserveEndDate: String): String;
var
  sJsonStr: AnsiString;
  jObj: TJSONObject;
  jErpSeObj: TJSONObject; //Erp ��������
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

        sLog := 'K702_TeeboxReg : ' + sLogH + ' / ' + sResultCd + ' / ' + sResultMsg;
        Global.Log.LogErpApiWrite(sLog);
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

function TTcpServer.SetApiTeeBoxEnd(ATeeboxNo: Integer; ATeeboxNm, AReserveNo, AReserveEndDate, AEndTy: String): String;
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

  if AEndTy <> '2' then //2:����,5:���
    Exit;

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

        sLog := 'K705_TeeboxEnd : ' + sLogH + ' / ' + sResultCd + ' / ' + sResultMsg;
        Global.Log.LogErpApiWrite(sLog);
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

  Result := 'Success';

end;

end.
