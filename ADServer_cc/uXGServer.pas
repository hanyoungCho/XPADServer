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
    FLastReceiveData: AnsiString;

    FCS: TRTLCriticalSection;
  protected

  public
    constructor Create;
    destructor Destroy; override;

    //procedure ServerConnect(AContext: TIdContext);
    procedure ServerExecute(AContext: TIdContext);

    procedure ServerReConnect;

    function SendDataCreat(AReceiveData: AnsiString): AnsiString;
    function SetSeatError(AReceiveData: AnsiString): AnsiString;  //Ÿ���� �������/���

    function SetSeatHold(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���
    function SetSeatHoldCancel(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���

    function SetSeatReserve(AReceiveData: AnsiString): AnsiString; //Ÿ���� ������
    function SetTeeboxReserveSql(ASeatUseInfo: TSeatUseInfo; AMove: Boolean = False; ACutIn: Boolean = False): String; //Ÿ���� ��������������
    function SetSeatReserveCancel(AReceiveData: AnsiString): AnsiString; //Ÿ���������
    function SetSeatReserveChange(AReceiveData: AnsiString): AnsiString; //Ÿ�����ຯ��

    function SetSeatMove(AReceiveData: AnsiString): AnsiString; //Ÿ���̵����
    function SetSeatUsed(AReceiveData: AnsiString): AnsiString; //Ÿ�����������
    function SetSeatClose(AReceiveData: AnsiString): AnsiString; //Ÿ������

    function SetSeatStart(AReceiveData: AnsiString): AnsiString; //��ù���
    function SetTeeboxCutIn(AReceiveData: AnsiString): AnsiString; //����ֱ� 2021-11-17

    function SetApiTeeBoxReg(ASeatNo: Integer; ASeatNm, AReserveNo, AReserveStartDate: String): String;
    function SetApiTeeBoxEnd(ASeatNo: Integer; ASeatNm, AReserveNo, AReserveEndDate, AEndTy: String): String;
    function SetApiTeeBoxStatus: Boolean;
    function GetErpTeeboxList: Boolean; //Ÿ��������ü��ȸ
    function GetErpTeeboxListLastNo: Integer; //����۽� Erp ������ Ȯ�ο�

    property TcpServer: TIdTCPServer read FTcpServer write FTcpServer;
    property UseSeqNo: Integer read FUseSeqNo write FUseSeqNo;
    property LastUseSeqNo: Integer read FLastUseSeqNo write FLastUseSeqNo;
  end;

implementation

uses
  uGlobal, uFunction, IdGlobal;

{ TTcpServer }

constructor TTcpServer.Create;
begin
  InitializeCriticalSection(FCS);

  FTcpServer := TIdTCPServer.create;

  //FTcpServer.OnConnect := ServerConnect;
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
{
procedure TTcpServer.ServerConnect(AContext: TIdContext);
var
  MainTH_ID: string;
  tID, tPort: Integer;
  LogMsg: String;
begin
  //tPort := AContext.Connection.Socket.Binding.PeerPort;
  //MainTH_ID := Format('%06d', [tPort]);

  //LogMsg := Format('Handle[%s] Connect ======================== ', [MainTH_ID]);
  //LogView(LogMsg);
end;
 }
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
  sStoreCd, sApi, sLogMsg: String;
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

      //2020-09-12 ��ȸ���� ��������
      if (Global.Teebox.BallBackUse = True) and
         ((sApi = 'K408_TeeBoxReserve2') or (sApi = 'K405_TeeBoxHold')) then
      begin
        sResult := '{"result_cd":"0001","result_msg":"��ȸ���� �Դϴ�. ��ȸ�� ������ �̿��� �ּ���."}';
        Global.Log.LogServerWrite(sResult + #13);
        Result := sResult;
        Exit;
      end;

      if sApi = 'K403_TeeBoxError' then //Ÿ���� ��ֵ��
        sResult := SetSeatError(AReceiveData)
      else if sApi = 'K404_TeeBoxError' then //Ÿ���� ��ֵ�� ���
        sResult := SetSeatError(AReceiveData)
      else if sApi = 'K405_TeeBoxHold' then //Ÿ���� Ȧ�� ���
        sResult := SetSeatHold(AReceiveData)
      else if sApi = 'K406_TeeBoxHold' then //Ÿ���� Ȧ�� ���
        sResult := SetSeatHoldCancel(AReceiveData)
      else if sApi = 'K408_TeeBoxReserve2' then //Ÿ���� ������
        sResult := SetSeatReserve(AReceiveData)
      else if sApi = 'K410_TeeBoxReserved' then //Ÿ���������
        sResult := SetSeatReserveCancel(AReceiveData)
      else if sApi = 'K411_TeeBoxReserved' then //Ÿ�����ຯ��
        sResult := SetSeatReserveChange(AReceiveData)
      else if sApi = 'K412_MoveTeeBoxReserved' then //Ÿ���̵����
        sResult := SetSeatMove(AReceiveData)
      else if sApi = 'K416_TeeBoxClose' then //Ÿ������
        sResult := SetSeatClose(AReceiveData)
      else if sApi = 'A417_TeeBoxStart' then //��ù���
        sResult := SetSeatStart(AReceiveData)
      else if sApi = 'A431_TeeboxCutIn' then // ����ֱ�
        sResult := SetTeeboxCutIn(AReceiveData)
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

function TTcpServer.SetSeatError(AReceiveData: AnsiString): AnsiString;
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

    //chy 2020-10-30 ��ȸ���� ��ȸ���������� üũ
    if (sTeeboxNo = '0') and (sErrorDiv = '7') then //��ȸ�� ����
    begin
      //��ȸ�� ���͸���� ���� �����̳� �����°��� ���޾ƿͼ� 7(��ȸ�� �����ΰ��)
      if (Global.Teebox.BallBackUse = False) and (Global.Teebox.BallRecallStartCheck = True) then
      begin
        Result := '{"result_cd":"404A",' +
                   '"result_msg":"���� ��ȸ������ ���� �Դϴ�."}';

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;
    end;

    sResult := Global.XGolfDM.SeatErrorUpdate(sUserId, sTeeboxNo, sErrorDiv);

    if sResult = 'Success' then
    begin
      if (sTeeboxNo = '0') then
      begin
        if (sErrorDiv = '7') then //��ȸ�� ����
          Global.Teebox.BallRecallStart
        else if (sErrorDiv = '0') then //��ȸ�� ����
          Global.Teebox.BallRecallEnd;

        //2020-08-27 v25 ��ȸ���� Ÿ���Ϻ� �̾�����Ʈ �Ǵ°�� �߻�. �������Ʈ
        Global.XGolfDM.SeatErrorUpdate(sUserId, sTeeboxNo, sErrorDiv);
      end
      else
      begin
        Global.Teebox.TeeboxLockCheck(StrToInt(sTeeboxNo), sErrorDiv);
      end;

      Result := '{"result_cd":"0000","result_msg":"Success"}';

      SetApiTeeBoxStatus;
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

function TTcpServer.SetSeatHold(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���/���
var
  jObj: TJSONObject;
  sApi, sUserId, sTeeboxNo, sLog: String;
  sResult: AnsiString;
  //nResult: Integer;
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
                 '"hold_yn":"Y","store_close_time":"' + Global.Store.EndTime + '","change_store_date":"' + Global.Store.StoreChgDate + '"}';
      Exit;
    end;

    rSeatInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));

    try
      sResult := Global.XGolfDM.SeatHoldInsert(sUserId, sTeeboxNo, rSeatInfo.TeeboxNm);

      if sResult = 'Success' then
      begin
        Global.Teebox.SetTeeboxHold(sTeeboxNo, sUserId, True);
        Result := '{"result_cd":"0000","result_msg":"Success","hold_yn":"Y","store_close_time":"' + Global.Store.EndTime + '","change_store_date":"' + Global.Store.StoreChgDate + '"}';
      end
      else
      begin
        Result := '{"result_cd":"",' +
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
                  '"result_msg":"�ӽÿ����� ��ְ� �߻��Ͽ����ϴ�",' +
                  '"hold_yn":"N","store_close_time":"' + Global.Store.EndTime + '","change_store_date":"' + Global.Store.StoreChgDate + '"}';
        Exit;
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

function TTcpServer.SetSeatHoldCancel(AReceiveData: AnsiString): AnsiString;  //Ÿ���� Ȧ�� ���/���
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
        Result := '{"result_cd":"0000","result_msg":"Success","hold_yn":"N"}';
      end
      else
        Result := '{"result_cd":"","result_msg":"�ӽÿ����� �������� ���Ͽ����ϴ�. �ٽ� �õ����ּ���.","hold_yn":"Y"}';

    except
      on e: Exception do
      begin
        sLog := 'SetSeatHoldCancel Exception : ' + e.Message;
        Global.Log.LogErpApiWrite(sLog);

        Global.XGolfDM.ReConnectionHold;
        Global.Log.LogErpApiWrite('ReConnectionHold');

        Result := '{"result_cd":"",' +
                  '"result_msg":"�ӽÿ��� ������ ��ְ� �߻��Ͽ����ϴ�.",' +
                  '"hold_yn":"Y"}';
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

function TTcpServer.SetSeatReserve(AReceiveData: AnsiString): AnsiString; //Ÿ���� ������
var
  jObj: TJSONObject;
  sApi, sUserId, sTeeboxNo, sMemberNo, sMemberNm, sMemberTel, sReserveRootDiv, sReceiptNo: String;
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

  sAffiliateCd: String; //���޻��ڵ� �߰�
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
    jObj := TJSONObject.ParseJSONValue( AReceiveData ) as TJSONObject;

    sApi := jObj.GetValue('api').Value;  //K408_TeeBoxReserve2
    sUserId := jObj.GetValue('user_id').Value;      //����� Id
    sMemberNo := jObj.GetValue('member_no').Value; //ȸ����ȣ	S
    sMemberNm := jObj.GetValue('member_nm').Value;
    //2020-06-01 ��ȭ��ȣ �߰�
    //sMemberTel := jObj.GetValue('member_tel').Value;
	  sReserveRootDiv := jObj.GetValue('reserve_root_div').Value; //����߱ǰ�α���	S	K	K:Ű����ũ, P:����, M:�����
    sReceiptNo := jObj.GetValue('receipt_no').Value; //��������ȣ	receipt_no
    sAffiliateCd := ''; //���޻��ڵ�	affiliate_cd

    jReciveObjArr := jObj.GetValue('data') as TJsonArray;

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

      sPossibleReserveDatetime := Global.XGolfDM.SelectPossibleReserveDatetime(sTeeboxNo);
      sPossibleReserveDatetimeChk := '';  //2022-08-01
      if ( sPossibleReserveDatetime = '' ) or (sPossibleReserveDatetime < FormatDateTime('YYYYMMDDhhnnss', Now)) then
        sPossibleReserveDatetime := FormatDateTime('YYYYMMDDhhnnss', Now)
      else
      begin
        //2020-05-31 ����ð� ����
        sPossibleReserveDatetimeChk := Global.Teebox.GetReserveLastTime(sTeeboxNo);
        if sPossibleReserveDatetime < sPossibleReserveDatetimeChk then
        begin
          sLog := 'SetSeatReserve Time : ' + sTeeboxNo + ' / ' + sPossibleReserveDatetime + ' -> ' + sPossibleReserveDatetimeChk;
          Global.Log.LogErpApiWrite(sLog);
          sPossibleReserveDatetime := sPossibleReserveDatetimeChk;
        end;
      end;

      rSeatInfo := Global.Teebox.GetTeeboxInfo(StrToInt(sTeeboxNo));
      //nUseSeqNo := nUseSeqNo + 1;

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

      //2020-06-01 ��ȭ��ȣ �߰�
      //ASeatUseInfoArr[nIndex].MemberTel := sMemberTel;

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

      //2020-07-13 DB ��ȸ�κ� ����
      SeatUseReserveTemp.ReserveNo := ASeatUseInfoArr[nIndex].ReserveNo;
      SeatUseReserveTemp.SeatNo := ASeatUseInfoArr[nIndex].SeatNo;
      SeatUseReserveTemp.UseMinute := ASeatUseInfoArr[nIndex].AssignMin;
      SeatUseReserveTemp.UseBalls := ASeatUseInfoArr[nIndex].AssignBalls;
      SeatUseReserveTemp.DelayMinute := ASeatUseInfoArr[nIndex].PrepareMin;
      SeatUseReserveTemp.ReserveDate := ASeatUseInfoArr[nIndex].ReserveDate;

      dtReserveStartTmTemp := DateStrToDateTime3(SeatUseReserveTemp.ReserveDate) + (((1/24)/60) * SeatUseReserveTemp.DelayMinute);
      SeatUseReserveTemp.StartTime := FormatDateTime('YYYYMMDDhhnnss', dtReserveStartTmTemp);

      rSeatUseReserveList.Add(SeatUseReserveTemp);
    end;

    try

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

      if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
      begin
        sLog := 'SetSeatReserve Fail : ' + sReserveNoTemp + ' / ' + sResult;
        Global.Log.LogErpApiWrite(sLog);

        sLog := jErpSeObj.ToString;
        Global.Log.LogErpApiWrite(sLog);

        Result := '{"result_cd":"0002",' +
                   '"result_msg":"���೻���� ������ ����� ��ְ� �߻��Ͽ����ϴ�."}';

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
      end;

      jErpRvObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
      sErpRvResultCd := jErpRvObj.GetValue('result_cd').Value;
      sErpRvResultMsg := jErpRvObj.GetValue('result_msg').Value;

      sLog := 'K701_TeeBoxReserve : ' + sReserveNoTemp + ' / ' + sErpRvResultCd + ' / ' + sErpRvResultMsg;
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
          sLog := 'K701_TeeBoxReserve Retry : ' + sReserveNoTemp;
          Global.Log.LogErpApiWrite(sLog);
        end
        else
        begin
          Result := '{"result_cd":"' + sErpRvResultCd + '",' +
                     '"result_msg":"' + sErpRvResultMsg + '"}';

          Global.Teebox.TeeboxReserveUse := False;
          Exit;
        end;

      end;

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
      if sResult <> 'Success' then
      begin
        Result := '{"result_cd":"0004",' +
                   '"result_msg":"DB ���忡 �����Ͽ����ϴ� ' + sResult + '"}';

        Global.Teebox.TeeboxReserveUse := False;
        Exit;
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
    jSendObj.AddPair(TJSONPair.Create('data', jSendObjArr));

    if not (jErpRvObj.FindValue('result_data') is TJSONNull) then
    begin
      JV := jErpRvObj.Get('result_data').JsonValue;
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
        for nReIndex := 0 to rSeatUseReserveList.Count - 1 do
        begin
          if (JV as TJSONArray).Items[i].P['reserve_no'].Value = rSeatUseReserveList[nReIndex].ReserveNo then
          begin
            sDate := Copy(rSeatUseReserveList[nReIndex].StartTime, 1, 4) + '-' +
                    Copy(rSeatUseReserveList[nReIndex].StartTime, 5, 2) + '-' +
                    Copy(rSeatUseReserveList[nReIndex].StartTime, 7, 2) + ' ' +
                    Copy(rSeatUseReserveList[nReIndex].StartTime, 9, 2) + ':' +
                    Copy(rSeatUseReserveList[nReIndex].StartTime, 11, 2) + ':' +
                    Copy(rSeatUseReserveList[nReIndex].StartTime, 13, 2);
            jSendItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate ) );

            bStartTm := True;
          end;
        end;

        //2020-07-02 ���۽ð� Ȯ��
        if bStartTm = False then
        begin
          sReserveTmTemp := (JV as TJSONArray).Items[i].P['reserve_datetime'].Value;
          dtReserveStartTmTemp := DateStrToDateTime2(sReserveTmTemp) + (((1/24)/60) * StrToInt(sPrepareMin));
          sDate := FormatDateTime('YYYY-MM-DD hh:nn:ss', dtReserveStartTmTemp);
          jSendItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate ) );

          sLog := 'SetSeatReserve StartTm : ' + sReserveTmTemp + ' / ' + sDate;
          Global.Log.LogErpApiWrite(sLog);
        end;

        jSendItemObj.AddPair( TJSONPair.Create( 'remain_min', (JV as TJSONArray).Items[i].P['remain_min'].Value) );
        jSendItemObj.AddPair( TJSONPair.Create( 'expire_day', (JV as TJSONArray).Items[i].P['expire_day'].Value) );
        jSendItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', (JV as TJSONArray).Items[i].P['coupon_cnt'].Value) );

        jSendSubObjArr := TJSONArray.Create;
        jSendItemObj.AddPair(TJSONPair.Create('coupon', jSendSubObjArr));

        if not ((JV as TJSONArray).Items[i].P['coupon'] is TJSONNull) then
        begin
          JV2 := (JV as TJSONArray).Items[i].P['coupon'];
          nCount2 := (JV2 as TJSONArray).Count;
          if (nCount2 > 0) then
          for j := 0 to Pred(nCount2) do
          begin
            jSendSubItemObj := TJSONObject.Create;
            jSendSubItemObj.AddPair( TJSONPair.Create( 'reserve_no', (JV2 as TJSONArray).Items[j].P['reserve_no'].Value) );
            jSendSubItemObj.AddPair( TJSONPair.Create( 'start_datetime', (JV2 as TJSONArray).Items[j].P['start_datetime'].Value) );
            jSendSubItemObj.AddPair( TJSONPair.Create( 'end_datetime', (JV2 as TJSONArray).Items[j].P['end_datetime'].Value) );
            jSendSubObjArr.Add(jSendSubItemObj);
          end;
        end;

        jSendObjArr.Add(jSendItemObj);

        //ERP���� json ����
        for nIndex := 0 to nProductListSize - 1 do
        begin

          if (JV as TJSONArray).Items[i].P['reserve_no'].Value = ASeatUseInfoArr[nIndex].ReserveNo then
          begin
            ASeatUseInfoArr[nIndex].JSon := jSendItemObj.ToString;
            sResult := Global.XGolfDM.SeatUseJsonUpdate(ASeatUseInfoArr[nIndex]); // POS/KIOSK �� Update

            if sResult <> 'Success' then
            begin
              //Result := '{"result_cd":"0004",' +
              //           '"result_msg":"DB �������"}';
            end;
          end;
        end;

      end;

    end;

    Result := jSendObj.ToString;

    //�������
    for nIndex := 0 to rSeatUseReserveList.Count - 1 do
    begin
      if rSeatUseReserveList[nIndex].ReserveDate <= FormatDateTime('YYYYMMDDhhnnss', Now) then
        Global.Teebox.SetReserveInfo(rSeatUseReserveList[nIndex])
      else
        global.Teebox.SetReserveNext(rSeatUseReserveList[nIndex]);
    end;

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
             '  (  use_seq_date, use_seq_no, store_cd, use_status, seat_no, seat_nm, use_div ' +
             '  , member_seq , member_nm ' +
             '  , reserve_cutin ' +
             '  , purchase_seq, product_seq, product_nm, reserve_div, use_minute ' +
             '  , use_balls, delay_minute, reserve_date, reserve_root_div, receipt_no, reserve_move ' +
             '  , chg_date , erp_json, reg_date, reg_id, affiliate_cd) ' +
              ' values ' +
             ' (' + QuotedStr(ASeatUseInfo.UseSeqDate) +
             ' ,' + IntToStr(ASeatUseInfo.UseSeqNo) +
             ' ,' + QuotedStr(ASeatUseInfo.StoreCd) +
             ' ,' + ASeatUseInfo.SeatUseStatus +
             ' ,' + IntToStr(ASeatUseInfo.SeatNo) +
             ' ,' + QuotedStr(ASeatUseInfo.SeatNm) +
             ' ,' + ASeatUseInfo.UseDiv +
             ' ,' + QuotedStr(ASeatUseInfo.MemberSeq) +
             ' ,' + QuotedStr(ASeatUseInfo.MemberNm) +
             ' ,' + QuotedStr(sCutIn) +
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
             ' ,' + QuotedStr(sMove) +
             ' , now() ' +
             ' ,' + QuotedStr(ASeatUseInfo.Json) +
             ' , now() ' +
             ' ,' + QuotedStr(ASeatUseInfo.RegId) +
             ' ,' + QuotedStr(ASeatUseInfo.AffiliateCd) + ' ); ';

  Result := sSql;
end;

function TTcpServer.SetSeatReserveCancel(AReceiveData: AnsiString): AnsiString; //Ÿ���������
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

      global.Teebox.SetReserveCancle(rSeatUseInfoList[nIndex].SeatNo, sReserveNoTemp);

      try
        sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                    '&teebox_no=' + IntToStr(rSeatUseInfoList[nIndex].SeatNo) +
                    '&reserve_no=' + sReserveNo +
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

    Result := '{"result_cd":"0000","result_msg":"Success"}';

  finally
    FreeAndNil(jRvObj);
    FreeAndNil(jObj);
    FreeAndNil(rSeatUseInfoList);

    Global.Teebox.TeeboxReserveUse := False;
  end;

end;

function TTcpServer.SetSeatReserveChange(AReceiveData: AnsiString): AnsiString; //Ÿ�����ຯ��
var
  jObj: TJSONObject;
  sApi, sUserId, sReserveNo, sAssignBalls, sAssignMin, sPrepareMin, sMemo: String;
  sSeq, sSeqDate: String;
  nSeq, nSeqNo, nIndex: Integer;
  sResult: AnsiString;
  //sData,
  sDate: String;
  rSeatUseInfo: TSeatUseInfo;
  rSeatUseInfoTemp: TSeatUseInfo;
  sJsonStr: AnsiString;
  sResultCd, sResultMsg, sLog: String;

  jErpObjArr: TJSONArray;
  jErpItemObj, jErpSubItemObj: TJSONObject;

  //rSeatInfo: TSeatInfo;
  jSeObj, jSeItemObj: TJSONObject; //Erp ��������
  jSeSubItemObj: TJSONObject; //Erp ��������
  jSeObjArr, jSeSubObjArr: TJSONArray;

  jErpRvObj: TJSONObject;
  dtReserveStartTmTemp: TDateTime;
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

    //rSeatUseInfo.UseSeq := sSeq;
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

    //Global.XGolfDM.BeginTrans;
    sResult := Global.XGolfDM.SeatUseChangeUdate(rSeatUseInfo); // POS/KIOSK �� Update
    if sResult <> 'Success' then
    begin
      Result := '{"result_cd":"411B","result_msg":"����ð� ���濡 �����Ͽ����ϴ�."}';
      //Global.XGolfDM.RollbackTrans;
      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;
    //Global.XGolfDM.CommitTrans;

    rSeatUseInfoTemp := Global.XGolfDM.SelectTeeboxReservationOneWithSeq(Global.ADConfig.StoreCode, sSeqDate, IntToStr(nSeqNo));

    //2020-07-02 rSeatUseInfoTemp ����������
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

    if Trim(rSeatUseInfo.Json) <> '' then
    begin
      jErpItemObj := TJSONObject.ParseJSONValue(rSeatUseInfo.Json) as TJSONObject;

      jSeItemObj := TJSONObject.Create;
      jSeItemObj.AddPair( TJSONPair.Create( 'reserve_no', rSeatUseInfoTemp.ReserveNo) );
      jSeItemObj.AddPair( TJSONPair.Create( 'purchase_cd', jErpItemObj.GetValue('purchase_cd').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'product_cd', jErpItemObj.GetValue('product_cd').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'product_nm', jErpItemObj.GetValue('product_nm').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'product_div', jErpItemObj.GetValue('product_div').Value) );

      jSeItemObj.AddPair( TJSONPair.Create( 'floor_nm', jErpItemObj.GetValue('floor_nm').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'teebox_nm', jErpItemObj.GetValue('teebox_nm').Value) );

      sDate := Copy(rSeatUseInfoTemp.StartTime, 1, 4) + '-' +
               Copy(rSeatUseInfoTemp.StartTime, 5, 2) + '-' +
               Copy(rSeatUseInfoTemp.StartTime, 7, 2) + ' ' +
               Copy(rSeatUseInfoTemp.StartTime, 9, 2) + ':' +
               Copy(rSeatUseInfoTemp.StartTime, 11, 2) + ':' +
               Copy(rSeatUseInfoTemp.StartTime, 13, 2);

      jSeItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate) );
      jSeItemObj.AddPair( TJSONPair.Create( 'remain_min', sAssignMin) );
      jSeItemObj.AddPair( TJSONPair.Create( 'expire_day', jErpItemObj.GetValue('expire_day').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', jErpItemObj.GetValue('coupon_cnt').Value) );

      jSeSubObjArr := TJSONArray.Create;
      jSeItemObj.AddPair(TJSONPair.Create('coupon', jSeSubObjArr));

      jErpObjArr := jErpItemObj.GetValue('coupon') as TJsonArray;

      for nIndex := 0 to jErpObjArr.Size - 1 do
      begin
        jErpSubItemObj := jErpObjArr.Get(nIndex) as TJSONObject;

        jSeSubItemObj := TJSONObject.Create;
        jSeSubItemObj.AddPair( TJSONPair.Create( 'reserve_no', jErpSubItemObj.GetValue('reserve_no').Value) );
        jSeSubItemObj.AddPair( TJSONPair.Create( 'start_datetime', jErpSubItemObj.GetValue('start_datetime').Value) );
        jSeSubItemObj.AddPair( TJSONPair.Create( 'end_datetime', jErpSubItemObj.GetValue('end_datetime').Value) );
        jSeSubObjArr.Add(jSeSubItemObj);
      end;

      jSeObjArr.Add(jSeItemObj);
    end;

    Result := jSeObj.toString;

    //Ÿ���� ����
    Global.Teebox.SetReserveChange(rSeatUseInfo);

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
    end

  finally
    FreeAndNil(jErpRvObj);
    FreeAndNil(jErpItemObj);
    FreeAndNil(jSeObj);
    FreeAndNil(jObj);

    Global.Teebox.TeeboxReserveUse := False;
  end;
end;

function TTcpServer.SetSeatMove(AReceiveData: AnsiString): AnsiString; //Ÿ���̵����
var
  jObj: TJSONObject;
  sApi, sUserId, sReserveNo, sAssignBalls, sAssignMin, sPrepareMin, sTeeboxNo: String;
  sSeq, sSeqDate, sPossibleReserveDatetime: String;
  nSeq, nSeqNo, nIndex: Integer;
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
    //rSeatUseInfo := Global.XGolfDM.SeatUseSelectOne(Global.ADConfig.StoreCode, IntToStr(rSeatUseInfo.UseSeq), '', '');
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
      //2020-07-20 ����ð� ����
      sPossibleReserveDatetimeChk := Global.Teebox.GetReserveLastTime(sTeeboxNo);
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

    rSeatUseInfo.UseSeqDate := FormatDateTime('YYYYMMDD', Now);
    FUseSeqNo := FUseSeqNo + 1;
    //2020-06-01 ��õ� ���� �����ȣ �ӽû������� ����
    FLastUseSeqNo := FUseSeqNo;
    rSeatUseInfo.UseSeqNo := FUseSeqNo;

    //rSeatUseInfo.Json := rSeatUseInfo.Json;

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
    //if rSeatUseInfoTemp.ReserveNo = '0000' then
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

    if Trim(rSeatUseInfo.Json) <> '' then
    begin
      jErpItemObj := TJSONObject.ParseJSONValue(rSeatUseInfo.Json) as TJSONObject;

      jSeItemObj := TJSONObject.Create;
      jSeItemObj.AddPair( TJSONPair.Create( 'reserve_no', rSeatUseInfoTemp.ReserveNo) );
      jSeItemObj.AddPair( TJSONPair.Create( 'purchase_cd', jErpItemObj.GetValue('purchase_cd').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'product_cd', jErpItemObj.GetValue('product_cd').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'product_nm', jErpItemObj.GetValue('product_nm').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'product_div', jErpItemObj.GetValue('product_div').Value) );

      jSeItemObj.AddPair( TJSONPair.Create( 'floor_nm', rSeatInfo.floorNm) );
      jSeItemObj.AddPair( TJSONPair.Create( 'teebox_nm', rSeatInfo.TeeboxNm) );

      sDate := Copy(rSeatUseInfoTemp.StartTime, 1, 4) + '-' +
               Copy(rSeatUseInfoTemp.StartTime, 5, 2) + '-' +
               Copy(rSeatUseInfoTemp.StartTime, 7, 2) + ' ' +
               Copy(rSeatUseInfoTemp.StartTime, 9, 2) + ':' +
               Copy(rSeatUseInfoTemp.StartTime, 11, 2) + ':' +
               Copy(rSeatUseInfoTemp.StartTime, 13, 2);
      jSeItemObj.AddPair( TJSONPair.Create( 'start_datetime', sDate) );

      //jSeItemObj.AddPair( TJSONPair.Create( 'remain_min', jErpItemObj.GetValue('remain_min').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'remain_min', sAssignMin) );
      jSeItemObj.AddPair( TJSONPair.Create( 'expire_day', jErpItemObj.GetValue('expire_day').Value) );
      jSeItemObj.AddPair( TJSONPair.Create( 'coupon_cnt', jErpItemObj.GetValue('coupon_cnt').Value) );

      jSeSubObjArr := TJSONArray.Create;
      jSeItemObj.AddPair(TJSONPair.Create('coupon', jSeSubObjArr));

      jErpObjArr := jErpItemObj.GetValue('coupon') as TJsonArray;
      //jSeItemObj.AddPair(TJSONPair.Create('coupon', jErpObjArr));

      for nIndex := 0 to jErpObjArr.Size - 1 do
      begin
        jErpSubItemObj := jErpObjArr.Get(nIndex) as TJSONObject;

        jSeSubItemObj := TJSONObject.Create;
        jSeSubItemObj.AddPair( TJSONPair.Create( 'reserve_no', jErpSubItemObj.GetValue('reserve_no').Value) );
        jSeSubItemObj.AddPair( TJSONPair.Create( 'start_datetime', jErpSubItemObj.GetValue('start_datetime').Value) );
        jSeSubItemObj.AddPair( TJSONPair.Create( 'end_datetime', jErpSubItemObj.GetValue('end_datetime').Value) );
        jSeSubObjArr.Add(jSeSubItemObj);
      end;

      //2020-06-25 Ÿ���̵��� ������ json ����,����
      rSeatUseInfoTemp.JSon := jSeItemObj.ToString;
      sResult := Global.XGolfDM.SeatUseJsonUpdate(rSeatUseInfoTemp); // POS/KIOSK �� Update
      if sResult <> 'Success' then
      begin
        //Result := '{"result_cd":"0004",' +
        //           '"result_msg":"DB �������"}';
      end;

      jSeObjArr.Add(jSeItemObj);
    end;

    Result := jSeObj.ToString;

    global.Teebox.SetReserveCancle(StrToInt(sOldSeatNo), sReserveNo);

    rSeatUseReserve.SeatNo := StrToInt(sTeeboxNo);
    rSeatUseReserve.ReserveNo := rSeatUseInfoTemp.ReserveNo;
    rSeatUseReserve.UseMinute := StrToInt(sAssignMin);
    rSeatUseReserve.UseBalls := StrToInt(sAssignBalls);
    rSeatUseReserve.DelayMinute := StrToInt(sPrepareMin);
    rSeatUseReserve.ReserveDate := sPossibleReserveDatetime;

    if rSeatUseReserve.ReserveDate <= FormatDateTime('YYYYMMDDhhnnss', Now) then
      Global.Teebox.SetReserveInfo(rSeatUseReserve)
    else
      global.Teebox.SetReserveNext(rSeatUseReserve);

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
    end
  finally
    FreeAndNil(jErpRvObj);
    FreeAndNil(jSeObj);
    FreeAndNil(jObj);
    FreeAndNil(jErpItemObj);

    Global.Teebox.TeeboxReserveUse := False;
  end;
end;

function TTcpServer.SetSeatUsed(AReceiveData: AnsiString): AnsiString; //Ÿ�����������
begin
  //'K413_TeeBoxUsed' Ÿ�����������
end;

function TTcpServer.SetSeatClose(AReceiveData: AnsiString): AnsiString;
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
    sApi := jObj.GetValue('api').Value;
    sUserId := jObj.GetValue('user_id').Value;
    sReserveNo := jObj.GetValue('reserve_no').Value;

    sUseSeqDate := Copy(sReserveNo, 1, 8);
    nUseSeqNo := StrToInt(Copy(sReserveNo, 9, 4));

    rSeatUseInfo := Global.XGolfDM.SeatUseSelectOne(Global.ADConfig.StoreCode, '', sUseSeqDate, IntToStr(nUseSeqNo));

    Result := '{"result_cd":"0000","result_msg":"Success"}';

    global.Teebox.SetReserveClose(rSeatUseInfo.SeatNo, sReserveNo);

    sLog := 'K416_TeeBoxClose : ' + IntToStr(rSeatUseInfo.SeatNo) + ' [ ' + rSeatUseInfo.SeatNm + ' ] ' +
            sUserId + ' / ' + sReserveNo;
    Global.Log.LogErpApiWrite(sLog);
  finally
    FreeAndNil(jObj);
  end;

end;

function TTcpServer.SetSeatStart(AReceiveData: AnsiString): AnsiString;
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

    sResult := global.Teebox.SetReserveStartNow(rSeatUseInfo.SeatNo, sReserveNo);
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
    //ASeatUseInfo.MemberTel := sMemberTel;

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

    rSeatUseInfo.ReceiptNo := jObj.GetValue('receipt_no').Value; //��������ȣ
    rSeatUseInfo.ReserveRootDiv := jObj.GetValue('reserve_root_div').Value; //K:Ű����ũ, P:����, M:�����
    rSeatUseInfo.AffiliateCd := jObj.GetValue('affiliate_cd').Value; //���޻��ڵ�
    {
    sXgUserKey := EmptyStr;
    if rSeatUseInfo.ReserveRootDiv = 'M' then
      sXgUserKey := jObj.GetValue('xg_user_key').Value;
    rSeatUseInfo.XgUserKey := sXgUserKey;
    }
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

    sResult := global.Teebox.SetReserveNextCutInCheck(rSeatUseReserveTemp);
    if sResult <> 'success' then
    begin
      Result := '{"result_cd":"0012",' +
                 '"result_msg":"' + sResult + '"}';

      Global.Teebox.TeeboxReserveUse := False;
      Exit;
    end;

    try

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

    //jSendObjArr := TJSONArray.Create;
    jSendObj := TJSONObject.Create;
    jSendObj.AddPair(TJSONPair.Create('result_cd', '0000'));
    jSendObj.AddPair(TJSONPair.Create('result_msg', 'Success'));

    //jSendObj.AddPair(TJSONPair.Create('data', jSendObjArr));

    if not (jErpRvObj.FindValue('result_data') is TJSONNull) then
    begin
      JV := jErpRvObj.Get('result_data').JsonValue;

      JV := (JV as TJSONObject).Get('dataList').JsonValue;
      nCount := (JV as TJSONArray).Count;

      // 1��
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

    Result := jSendObj.ToString;

    //�������-����ֱ�
    global.Teebox.SetReserveNextCutIn(rSeatUseReserveTemp);

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

function TTcpServer.SetApiTeeBoxReg(ASeatNo: Integer; ASeatNm, AReserveNo, AReserveStartDate: String): String;
var
  sJsonStr: AnsiString;
  jObj: TJSONObject;
  sResult, sResultCd, sResultMsg, sLog, sLogH: String;
begin
  Result := '';
  sLogH := IntToStr(ASeatNo) + ' [ ' + ASeatNm + ' ] ' + AReserveNo;

  sResult := Global.XGolfDM.SeatUseStartDateUpdate(Global.ADConfig.StoreCode, AReserveNo, AReserveStartDate, Global.ADConfig.UserId);
  if sResult <> 'Success' then
  begin
    sLog := 'SetApiTeeBoxRegDB Exception : ' + sLogH;
    Global.Log.LogErpApiWrite(sLog);
  end;

  try
    try
      sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                  '&teebox_no=' + IntToStr(ASeatNo) +
                  '&reserve_no=' + AReserveNo +
                  '&start_datetime=' + AReserveStartDate +
                  '&user_id=' + Global.ADConfig.UserId;

      sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K702_TeeboxReg', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

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
  end;

  Result := 'Success';

end;

function TTcpServer.SetApiTeeBoxEnd(ASeatNo: Integer; ASeatNm, AReserveNo, AReserveEndDate, AEndTy: String): String;
var
  sJsonStr: AnsiString;
  jObj: TJSONObject;
  sResult, sResultCd, sResultMsg, sLog, sLogH: String;
begin
  Result := '';
  sLogH := IntToStr(ASeatNo) + ' [ ' + ASeatNm + ' ] ' + AReserveNo;

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
      
      sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                  '&teebox_no=' + IntToStr(ASeatNo) +
                  '&reserve_no=' + AReserveNo +
                  '&end_datetime=' + AReserveEndDate +
                  '&user_id=' + Global.ADConfig.UserId;

      sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K705_TeeboxEnd', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

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
  end;

  Result := 'Success';

end;

function TTcpServer.SetApiTeeBoxStatus: Boolean;
var
  sJsonStr: AnsiString;
  jObj: TJSONObject;
  sResult, sResultCd, sResultMsg, sLog: String;
begin

  try
    try
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
        //ASeatUseInfoArr[nIndex].MemberTel := jItemObj.GetValue('hp_no').Value;
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

end.
