unit uXGClientDM;

interface

uses
  System.Variants, System.SysUtils, System.Classes, Data.DB, MemDS, DBAccess, Uni, UniProvider,
  MySQLUniProvider, uStruct, Generics.Collections, Windows;

type
  TXGolfDM = class(TDataModule)
    Connection: TUniConnection;
    MySQL: TMySQLUniProvider;
    qrySeatUpdate: TUniQuery;
    qryTemp: TUniQuery;
    qrySeatStatusUpdate: TUniQuery;
    ConnectionSeat: TUniConnection;
    ConnectionAuto: TUniConnection;
    ConnectionTm: TUniConnection;
    ConnectionReserve: TUniConnection;
    ConnectionHold: TUniConnection;
    conTeeBox: TUniConnection;
    ConnectionTemp: TUniConnection;
    UniDataSourceAgent: TUniDataSource;
    UniConnectionAgent: TUniConnection;
    UniQueryAgent: TUniQuery;

    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure conTeeBoxBeforeConnect(Sender: TObject);

  private
    { Private declarations }
    FDBSeatNo: Integer;
    FDBSeatStatus: String;

    //FCS: TRTLCriticalSection;

    procedure DBConnection;
    procedure DBDisconnect;
  public
    { Public declarations }
    procedure BeginTrans;                              // Begin
    procedure CommitTrans;                             // Commit
    procedure RollbackTrans;

    function SeatSelect: TList<TTeeboxInfo>;
    function SeatInsert(AStoreCode: String; ATeeboxInfo: TTeeboxInfo): Boolean;
    function SeatUpdate(AStoreCode: String; ATeeboxInfo: TTeeboxInfo): Boolean;
    function TeeboxInfoUpdate(ATeeboxNo, ARemainMin: Integer; AUseStatus: String): Boolean;
    function TeeboxErrorStatusUpdate(ATeeboxNo: Integer; AUseStatus, AErrorCd: String): Boolean; //타석 에러
    //agent 상태 저장
    function UpdateTeeboxAgentStatus(AStorecd:String; ATeeboxNo: Integer; AType: String): Boolean;

    //Connection
    function SeatUseInsert(ASeatUseInfo: TSeatUseInfo): String; //예약추가
    function SeatUseSelectOne(AStoreId, AUseSeq, AUseSeqDate, AUseSeqNo: String): TSeatUseInfo;
    function SeatUseSelectList(AStoreId, AUseSeq, AUseSeqDate, AUseSeqNo, AReceiptNo: String): TList<TSeatUseInfo>;
    function SelectPossibleReserveDatetime(ATeeboxNo: String): String;
    function SelectTeeboxReservationOneWithSeqList(AUseSeq: Array of Integer): TList<TSeatUseReserve>;
    function SelectTeeboxReservationOneWithSeq(AStoreCd, AUseSeqDate, AUseSeqNo: String): TSeatUseInfo;
    function InsertSeatMoveHist(AStoreCode, AUseSeq, AOldSeatNo, ANewSeatNo, AUserId: String): String;
    function SeatHeatUseUpdate(AStoreCode, ATeeboxNo, AHeatUse, AHeatAuto, AUserId: String): AnsiString;

    //ConnectionHold
    function TeeboxErrorUpdate(AUserId, ATeeboxNo, AErrorDiv: String): AnsiString; //점검, 볼회수
    function TeeboxHoldInsert(AUserId, ATeeboxNo, ATeeboxNm: String): AnsiString;
    //function TeeboxHoldSelect(ATeeboxNo: String): Integer;
    function TeeboxHoldDelete(AUserId, ATeeboxNo: String): String;

    //ConnectionAuto
    function TeeboxUseInsert(ASeatUseSql: String): AnsiString; //예약배정

    function SeatUseMoveUpdate(AStoreCode, ASeq, AUserId: String): AnsiString;
    function ReserveDateNo(AStoreId, ADate: String):Integer;
    function SetSeatReserveUseMinAdd(AStoreCode, ASeatNo, AUseSeqDate, ADelayTm: String): String; //배정시간 층가
    function SetSeatReserveTmChange(AStoreCode, ASeatNo, AUseSeqDate, ADelayTm, ADateTime: String): String; //예약시간 증가

    function SeatUseCutInSelect(AStoreCode, AReserveNo: String): AnsiString;
    function SeatUseCutInUpdate(AStoreCode, ASeq, AUserId: String): AnsiString;
    function SeatUseCutInUseDelete(AStoreCode, AReserveNo, AUserId: String): AnsiString;
    function SeatUseCutInUseListDelete(AStoreCode, ATeeboxNo, AReserveDate: String; AType: Boolean = False): AnsiString;
    function SeatUseCutInUseInsert(AStoreCode, AReserveNo: String): AnsiString;

    function SeatUseCheckInNextUpdate(AStoreCode, AReserveNo: String): AnsiString;
    function SeatUseCheckInUpdate(AStoreCode, AReserveNo: String; AAssignMin: Integer): AnsiString;

    //2020-06-29 시작시간기준 예약시간변경
    //function SetSeatReserveStartTmChange(AStoreCode, ASeatNo, ADate, AReserveNo: String): String;

    function SeatUseReserveDateUpdate(AStoreCode, AReserveNo, ADate: String): String;

    function SeatUseChangeUdate(ASeatUseInfo: TSeatUseInfo): AnsiString;
    function DeleteTeeboxReservation(AStoreId, AUserId, AUseSeq: String): AnsiString;

    function SeatUseAllReserveSelect(AStoreCode, AStr: String): TList<TSeatUseReserve>;
    function SeatUseAllReserveSelectNext(AStoreCode: String): TList<TSeatUseReserve>;

    //2020-06-09 마감 및 오픈전 배정정리
    function SeatUseStoreClose(AStorecd, AUserId, ADate: String): Boolean;

    //ConnectionTm
    function SeatUseStartDateUpdate(AStoreCode, AReserveNo, AReserveStartDate, AUserId: String): String;
    function SeatUseEndDateUpdate(AStoreCode, AReserveNo, AReserveEndDate, AEndTy: String): String;

    //DB 배정내역 삭제-한달전
    function SeatUseDeleteReserve(AStorecd, ADate: String): Boolean;

    function AgentSelectAll: String;
    function AgentSelect(AAgentNo, ALeftHanded: String): String;
    function AgentInsert(AAgentNo, ALeftHanded, ASetting: String): Boolean;
    function AgentUpdate(AAgentNo, ALeftHanded, ASetting: String): Boolean;

    function ReConnection: Boolean;
    function ReConnectionReserve: Boolean;
    function ReConnectionHold: Boolean;

  end;

var
  XGolfDM: TXGolfDM;

//2020-07-02 Prepared := True; Open 일 경우만 추가 적용

implementation

uses
  uGlobal, uFunction;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TXGolfDM.DataModuleCreate(Sender: TObject);
begin
  //InitializeCriticalSection(FCS);

  DBConnection;

  FDBSeatNo := 0;
  FDBSeatStatus := '2';
end;

procedure TXGolfDM.DataModuleDestroy(Sender: TObject);
begin
  DBDisconnect;

  //DeleteCriticalSection(FCS);
end;

procedure TXGolfDM.DBConnection;
begin

  Connection.Port := Global.ADConfig.DBPort;
  ConnectionSeat.Port := Global.ADConfig.DBPort;
  ConnectionAuto.Port := Global.ADConfig.DBPort;
  ConnectionTm.Port := Global.ADConfig.DBPort;
  ConnectionReserve.Port := Global.ADConfig.DBPort;
  ConnectionHold.Port := Global.ADConfig.DBPort;

  ConnectionTemp.Port := Global.ADConfig.DBPort;

  UniConnectionAgent.Port := Global.ADConfig.DBPort;

  //ConnectionAuto.Server := Format('%s,%d Allow User Variables=True', ['192.168.0.210', 3307]);

  Connection.Connect;
  ConnectionSeat.Connect;
  //UniConnection2.Connect;
  if not ConnectionAuto.Connected then
    ConnectionAuto.Connected := True;
  if not ConnectionTm.Connected then
    ConnectionTm.Connected := True;
  if not ConnectionReserve.Connected then
    ConnectionReserve.Connected := True;
  //2020-06-01 홀드 등록/취소시 ReceiveHeader: Net packets out of order: received[1], expected[2] 에러발생, 별도 커넥션 구성
  if not ConnectionHold.Connected then
    ConnectionHold.Connected := True;

  if not ConnectionTemp.Connected then
    ConnectionTemp.Connected := True;

  if not UniConnectionAgent.Connected then
    UniConnectionAgent.Connect;

end;

procedure TXGolfDM.DBDisconnect;
begin
  Connection.Disconnect;
  ConnectionSeat.Disconnect;
  ConnectionAuto.Disconnect;
  ConnectionTm.Disconnect;
  ConnectionReserve.Disconnect;
  ConnectionHold.Disconnect;

  ConnectionTemp.Disconnect;

  UniConnectionAgent.Disconnect;

  conTeeBox.Connected := False;
end;

procedure TXGolfDM.BeginTrans;
begin
  try
    if Connection.InTransaction then
      Connection.Rollback;
    Connection.StartTransaction;
  except on E: Exception do
    begin
      raise;
    end;
  end;
end;

procedure TXGolfDM.CommitTrans;
begin
  try
    Connection.Commit;
  except on E: Exception do
    begin
      raise;
    end;
  end;
end;

procedure TXGolfDM.conTeeBoxBeforeConnect(Sender: TObject);
begin
  with TUniConnection(Sender) do
  begin
    ProviderName := 'MySQL';
    LoginPrompt := False;
    Database := 'xgolf';
    SpecificOptions.Clear;
    SpecificOptions.Add('MySQL.CharSet=utf8');
    SpecificOptions.Add('MySQL.UseUniCode=True');
    SpecificOptions.Add('MySQL.ConnectionTimeOut=30');
    Server := Format('%s,%d Allow User Variables=True', ['127.0.0.1', 3307]);
    //Server := Format('%s,%d Allow User Variables=True', ['192.168.0.210', 3307]);
    Port := 3307;
    UserName := 'xgolf';
    Password := 'xgolf0105';
  end;
end;

procedure TXGolfDM.RollbackTrans;
begin
  try
    Connection.Rollback;
  except on E: Exception do
    begin
      raise;
    end;
  end;
end;

function TXGolfDM.SeatSelect: TList<TTeeboxInfo>;
var
  sSql: String;
  nIndex: Integer;
  rSeatInfo: TTeeboxInfo;
begin

  with TUniQuery.Create(nil) do
  begin

    try

      Connection := ConnectionTemp;

      sSql := ' SELECT * FROM SEAT WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode);

      Close;
      SQL.Text := sSql;
      Prepared := True;
      ExecSQL;

      Result := TList<TTeeboxInfo>.Create;
      for nIndex := 0 to RecordCount - 1 do
      begin
        rSeatInfo.TeeboxNo := FieldByName('SEAT_NO').AsInteger;
        rSeatInfo.TeeboxNm := FieldByName('SEAT_NM').AsString;
        rSeatInfo.FloorZoneCode := FieldByName('FLOOR_ZONE_CODE').AsString;
        rSeatInfo.TeeboxZoneCode := FieldByName('SEAT_ZONE_CODE').AsString;
        rSeatInfo.TapoMac := FieldByName('DEVICE_ID').AsString;
        rSeatInfo.UseStatus := FieldByName('USE_STATUS').AsString;
        rSeatInfo.RemainMinute := FieldByName('REMAIN_MINUTE').AsInteger;
        rSeatInfo.UseYn := FieldByName('USE_YN').AsString;
        rSeatInfo.DelYn := FieldByName('Del_YN').AsString; //2022-01-27

        if FieldByName('HOLD_YN').AsString = 'Y' then
          rSeatInfo.HoldUse := True
        else
          rSeatInfo.HoldUse := False;

        rSeatInfo.HoldUser := FieldByName('HOLD_USER').AsString;

        Result.Add(rSeatInfo);
        Next;
      end;

    finally
      Close;
      Free;
    end;
  end;

end;


function TXGolfDM.SeatUpdate(AStoreCode: String; ATeeboxInfo: TTeeboxInfo): Boolean;
var
  sSql: String;
  I: Integer;
begin

  Result := False;

  try
    BeginTrans;

    sSql := ' UPDATE SEAT SET ' +
            '     SEAT_NM = ' + QuotedStr(ATeeboxInfo.TeeboxNm) + ',' +
            '     FLOOR_ZONE_CODE = ' + QuotedStr(ATeeboxInfo.FloorZoneCode) + ',' +
            '     FLOOR_NM = ' + QuotedStr(ATeeboxInfo.FloorNm) + ',' +
            '     SEAT_ZONE_CODE = ' + QuotedStr(ATeeboxInfo.TeeboxZoneCode) + ',' +
            '     DEVICE_ID = ' + QuotedStr(ATeeboxInfo.TapoMac) + ',' +
            '     USE_YN = ' + QuotedStr(ATeeboxInfo.UseYn) + ',' +
            '     DEL_YN = ' + QuotedStr(ATeeboxInfo.DelYn) + ',' +
            '     REG_DATE = now() ' +
            ' WHERE STORE_CD = ' + QuotedStr(AStoreCode) +
            ' AND SEAT_NO = ' + IntToStr(ATeeboxInfo.TeeboxNo);

    qryTemp.SQL.Text := sSql;
    qryTemp.Execute;

    CommitTrans;
  except
    on E: Exception do
    begin
      RollbackTrans;
    end;
  end;

  Result := True;
end;

function TXGolfDM.SeatInsert(AStoreCode: String; ATeeboxInfo: TTeeboxInfo): Boolean;
var
  sSql: String;
  I: Integer;
begin

  Result := False;

  try
    BeginTrans;

    sSql := ' INSERT INTO SEAT ' +
            '( STORE_CD, SEAT_NO, SEAT_NM, FLOOR_ZONE_CODE, SEAT_ZONE_CODE, DEVICE_ID, USE_YN ) ' +
            ' VALUES ' +
            '( ' + QuotedStr(AStoreCode) + ', '
                 + IntToStr(ATeeboxInfo.TeeboxNo) + ', '
                 + QuotedStr(ATeeboxInfo.TeeboxNm) +', '
                 + QuotedStr(ATeeboxInfo.FloorZoneCode) +', '
                 + QuotedStr(ATeeboxInfo.TeeboxZoneCode) +', '
                 + QuotedStr(ATeeboxInfo.TapoMac) +', '
                 + QuotedStr(ATeeboxInfo.UseYn) + ')';

    qryTemp.SQL.Text := sSql;
    qryTemp.Execute;

    CommitTrans;
  except
    on E: Exception do
    begin
      RollbackTrans;
    end;
  end;

  Result := True;
end;

function TXGolfDM.TeeboxInfoUpdate(ATeeboxNo, ARemainMin: Integer; AUseStatus: String): Boolean;
var
  sSql, sLog: String;
begin

  try
    sSql := ' UPDATE SEAT ' +
            ' SET USE_STATUS = ' + QuotedStr(AUseStatus) + ',' +
            '     REMAIN_MINUTE = ' + IntToStr(ARemainMin) + ',' +
            '     REG_DATE = now() ' +
            ' WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode) +
            ' AND SEAT_NO = ' + IntToStr(ATeeboxNo);

    qrySeatStatusUpdate.SQL.Text := sSql;
    qrySeatStatusUpdate.ExecSQL;
  except
    on E: Exception do
    begin
      sLog := 'SeatStatusUpdate Exception: ' + E.Message;
      Global.Log.LogErpApiWrite(sLog);
    end;
  end;

end;

function TXGolfDM.TeeboxErrorStatusUpdate(ATeeboxNo: Integer; AUseStatus, AErrorCd: String): Boolean;
var
  sSql, sLog: String;
begin
  //EnterCriticalSection(FCS);

  try
    //BeginTrans;

    sSql := ' UPDATE SEAT ' +
            ' SET USE_STATUS = ' + QuotedStr(AUseStatus) + ',';

    if AUseStatus = '9' then
    begin
      begin
        sSql := sSql +
            '     ERROR_CD = ' + AErrorCd + ',';
      end;
    end;

    sSql := sSql +
            '     REG_DATE = now() ' +
            ' WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode) +
            ' AND SEAT_NO = ' + IntToStr(ATeeboxNo);

    qrySeatStatusUpdate.SQL.Text := sSql;
    qrySeatStatusUpdate.ExecSQL;

    //CommitTrans;
  except
    on E: Exception do
    begin
      //RollbackTrans;

      sLog := 'TeeboxErrorStatusUpdate Exception: ' + E.Message;
      Global.Log.LogErpApiWrite(sLog);
    end;
  end;

  //LeaveCriticalSection(FCS);
end;

function TXGolfDM.TeeboxErrorUpdate(AUserId, ATeeboxNo, AErrorDiv: String): AnsiString;
var
  sSql, sLog: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        //Connection := Connection;
        Connection := ConnectionHold;
        //BeginTrans;

        if ATeeboxNo = '0' then
        begin
          sSql := ' UPDATE SEAT ' +
                  ' SET USE_STATUS = ' + QuotedStr(AErrorDiv) + ',' +
                  '     REG_DATE = now() ' +
                  ' WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode) +
                  ' AND use_status not in (''8'', ''9'')';
        end
        else
        begin
          sSql := ' UPDATE SEAT ' +
                  ' SET USE_STATUS = ' + QuotedStr(AErrorDiv) + ',' +
                  '     REG_DATE = now() ' +
                  ' WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode) +
                  ' AND SEAT_NO = ' + ATeeboxNo;
        end;

        Close;
        SQL.Text := sSql;
        Prepared := True;
        ExecSQL;

        //CommitTrans;
        Result := 'Success';
      except
        on E: Exception do
        begin
          //RollbackTrans;
          Result := E.Message;

          sLog := 'TeeboxErrorUpdate Exception: ' + E.Message;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.TeeboxHoldInsert(AUserId, ATeeboxNo, ATeeboxNm: String): AnsiString;
var
  sSql, sLog: String;
begin

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      Connection := ConnectionHold;

      sSql := ' UPDATE SEAT SET ' +
              '     HOLD_YN = ''Y'',' +
              '     HOLD_USER = ' + QuotedStr(AUserId) + ',' +
              '     HOLD_DATE = now() ' +
              ' WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode) +
              ' AND SEAT_NO = ' + ATeeboxNo;

      Close;
      SQL.Text := sSql;
      Prepared := True;
      ExecSQL;

      Result := 'Success';
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

{
function TXGolfDM.TeeboxHoldSelect(ATeeboxNo: String): Integer;
var
  sSql, sLog: String;
begin

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      Connection := ConnectionHold;

      sSql := ' select * from seat ' +
              ' where store_cd = ' + QuotedStr(Global.ADConfig.StoreCode) +
              '   and seat_no = ' + ATeeboxNo +
              '   and hold_yn = ''Y'' ';

      Close;
      SQL.Text := sSql;
      Prepared := True;
      Open;

      if not IsEmpty then
        Result := 1
      else
        Result := 0;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;
}

function TXGolfDM.TeeboxHoldDelete(AUserId, ATeeboxNo: String): String;
var
  sSql, sLog: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      Connection := ConnectionHold;
      sSql := ' UPDATE SEAT SET ' +
              '     HOLD_YN = ''N'',' +
              '     HOLD_USER = ' + QuotedStr(AUserId) + ',' +
              '     HOLD_DATE = now() ' +
              ' WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode) +
              ' AND SEAT_NO = ' + ATeeboxNo;

      Close;
      SQL.Text := sSql;
      Prepared := True;
      ExecSQL;

      Result := 'Success';
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.UpdateTeeboxAgentStatus(AStorecd:String; ATeeboxNo: Integer; AType: String): Boolean;
var
  sSql: String;
  I: Integer;
begin
  Result := False;

  try
    BeginTrans;

    sSql := ' UPDATE SEAT SET ' +
            '     AGENT_STATUS = ' + QuotedStr(AType) +
            ' WHERE STORE_CD = ' + QuotedStr(AStorecd) +
            ' AND SEAT_NO = ' + IntToStr(ATeeboxNo);

    qryTemp.SQL.Text := sSql;
    qryTemp.Execute;

    CommitTrans;
  except
    on E: Exception do
    begin
      RollbackTrans;
    end;
  end;

  Result := True;
end;

function TXGolfDM.SeatUseSelectOne(AStoreId, AUseSeq, AUseSeqDate, AUseSeqNo: String): TSeatUseInfo;
var
  sSql, sLog: String;
  sStr: String;
  nLength, nTalLength, nSeq, nIndex: Integer;
  rSeatUseInfo: TSeatUseInfo;
begin
  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        sSql := ' select * from seat_use ' +
                ' where store_cd = ' + QuotedStr(AStoreId);

        if Trim(AUseSeq) <> '' then
        begin
          sSql := sSql +
                ' and use_seq = ' + AUseSeq;
        end;

        if Trim(AUseSeqDate) <> '' then
        begin
          sSql := sSql +
                ' and use_seq_date = ' + AUseSeqDate +
                ' and use_seq_no = ' + AUseSeqNo;
        end;

        sSql := sSql +
                ' order by use_seq desc ' +
                ' limit 1 ';

        //Connection := Connection;
        Connection := ConnectionTemp;

        Close;
        SQL.Text := sSql;
        Prepared := True;
        Open;

        rSeatUseInfo.UseSeq := FieldByName('use_seq').AsInteger;
        rSeatUseInfo.UseSeqDate := FieldByName('use_seq_date').AsString;
        rSeatUseInfo.UseSeqNo := FieldByName('use_seq_no').AsInteger;
       	rSeatUseInfo.StoreCd := FieldByName('store_cd').AsString;
        rSeatUseInfo.SeatNo := FieldByName('seat_no').AsInteger;
        rSeatUseInfo.SeatNm := FieldByName('seat_nm').AsString;
        rSeatUseInfo.SeatUseStatus := FieldByName('use_status').AsString;
        rSeatUseInfo.UseDiv := FieldByName('use_div').AsString;
        rSeatUseInfo.MemberSeq := FieldByName('member_seq').AsString;
        rSeatUseInfo.MemberNm := FieldByName('member_nm').AsString;
        rSeatUseInfo.MemberTel := FieldByName('member_tel').AsString;
        rSeatUseInfo.PurchaseSeq := FieldByName('purchase_seq').AsInteger;
        rSeatUseInfo.ProductSeq := FieldByName('product_seq').AsInteger;
        rSeatUseInfo.ProductNm := FieldByName('product_nm').AsString;
        rSeatUseInfo.ReserveDiv := FieldByName('reserve_div').AsString;
        rSeatUseInfo.ReceiptNo := FieldByName('receipt_no').AsString;
        rSeatUseInfo.AssignMin := FieldByName('use_minute').AsInteger;
        rSeatUseInfo.AssignBalls := FieldByName('use_balls').AsInteger;
        rSeatUseInfo.PrepareMin := FieldByName('delay_minute').AsInteger;
        rSeatUseInfo.ReserveDate := FieldByName('reserve_date').AsString;
        rSeatUseInfo.ReserveRootDiv := FieldByName('reserve_root_div').AsString;
        rSeatUseInfo.MoveYn := FieldByName('move_yn').AsString;
        rSeatUseInfo.AssignYn := FieldByName('assign_yn').AsString;
        //rSeatUseInfo.Json := FieldByName('erp_json').AsString;

        rSeatUseInfo.LessonProNm := FieldByName('LESSON_PRO_NM').AsString;
        rSeatUseInfo.LessonProPosColor := FieldByName('LESSON_PRO_POS_COLOR').AsString;

        rSeatUseInfo.ExpireDay := FieldByName('EXPIRE_DAY').AsString;
        rSeatUseInfo.CouponCnt := FieldByName('COUPON_CNT').AsString;

        rSeatUseInfo.AvailableZoneCd := FieldByName('AVAILABLE_ZONE_CD').AsString; //2021-12-20

        Result := rSeatUseInfo;
      except
        on E: Exception do
        begin
          //Result := E.Message;

          sLog := 'SeatUseSelectOne Exception : ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseSelectList(AStoreId, AUseSeq, AUseSeqDate, AUseSeqNo, AReceiptNo: String): TList<TSeatUseInfo>;
var
  sSql, sLog, sUseSeqNo: String;
  sStr: String;
  nLength, nTalLength, nSeq, nIndex: Integer;
  rSeatUseInfo: TSeatUseInfo;
begin

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        sSql := ' select * from seat_use ' +
                ' where store_cd = ' + QuotedStr(AStoreId);

        if Trim(AUseSeq) <> '' then
        begin
          sSql := sSql +
                ' and use_seq = ' + AUseSeq;
        end;

        if Trim(AUseSeqDate) <> '' then
        begin
          sSql := sSql +
                ' and use_seq_date = ' + AUseSeqDate +
                ' and use_seq_no = ' + AUseSeqNo;
        end;

        if Trim(AReceiptNo) <> '' then
        begin
          sSql := sSql +
                ' and receipt_no = ' + QuotedStr(AReceiptNo);
        end;

        sSql := sSql +
                ' order by use_seq desc ';

        Connection := ConnectionTemp;

        Close;
        SQL.Text := sSql;
        Prepared := True;
        Open;

        Result := TList<TSeatUseInfo>.Create;
        for nIndex := 0 to RecordCount - 1 do
        begin
          rSeatUseInfo.UseSeq := FieldByName('use_seq').AsInteger;
          rSeatUseInfo.UseSeqDate := FieldByName('use_seq_date').AsString;
          rSeatUseInfo.UseSeqNo := FieldByName('use_seq_no').AsInteger;

          sUseSeqNo := StrZeroAdd(FieldByName('use_seq_no').AsString, 4);
          rSeatUseInfo.ReserveNo := rSeatUseInfo.UseSeqDate + sUseSeqNo;

         	rSeatUseInfo.StoreCd := FieldByName('store_cd').AsString;
          rSeatUseInfo.SeatNo := FieldByName('seat_no').AsInteger;
          rSeatUseInfo.SeatNm := FieldByName('seat_nm').AsString;
          rSeatUseInfo.SeatUseStatus := FieldByName('use_status').AsString;
          rSeatUseInfo.UseDiv := FieldByName('use_div').AsString;
          rSeatUseInfo.MemberSeq := FieldByName('member_seq').AsString;
          rSeatUseInfo.MemberNm := FieldByName('member_nm').AsString;
          rSeatUseInfo.PurchaseSeq := FieldByName('purchase_seq').AsInteger;
          rSeatUseInfo.ProductSeq := FieldByName('product_seq').AsInteger;
          rSeatUseInfo.ProductNm := FieldByName('product_nm').AsString;
          rSeatUseInfo.ReserveDiv := FieldByName('reserve_div').AsString;
          rSeatUseInfo.ReceiptNo := FieldByName('receipt_no').AsString;
          rSeatUseInfo.AssignMin := FieldByName('use_minute').AsInteger;
          rSeatUseInfo.AssignBalls := FieldByName('use_balls').AsInteger;
          rSeatUseInfo.PrepareMin := FieldByName('delay_minute').AsInteger;
          rSeatUseInfo.ReserveDate := FieldByName('reserve_date').AsString;
          rSeatUseInfo.ReserveRootDiv := FieldByName('reserve_root_div').AsString;
          //rSeatUseInfo.Json := FieldByName('erp_json').AsString;
          rSeatUseInfo.ExpireDay := FieldByName('EXPIRE_DAY').AsString;
          rSeatUseInfo.CouponCnt := FieldByName('COUPON_CNT').AsString;

          Result.Add(rSeatUseInfo);
          Next;
        end;

      except
        on E: Exception do
        begin
          //Result := E.Message;

          sLog := 'SeatUseSelectList Exception : ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SelectPossibleReserveDatetime(ATeeboxNo: String): String;
var
  sSql, sLog: String;
  tmDate, endDate: TDatetime;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try

        //2021-06-10 종료시간과 다음예약시간1분차이, 10분종료, 11분예약 이선우이사님
        sSql := ' select reserve_date, start_date, use_minute, delay_minute, USE_STATUS, ' +
                '        date_add( reserve_date, interval (use_minute + delay_minute + 1) minute) as reserve_datetime , ' +
                '        date_add( start_date, interval (use_minute + 1) minute) as start_datetime  ' +
                ' from seat_use ' +
                ' where store_cd = ' + QuotedStr(Global.ADConfig.StoreCode) +
                ' and seat_no = ' + ATeeboxNo +
                ' and use_status in (''1'', ''4'') ' +
                ' order by use_seq desc ' +
                ' limit 1 ';

        //Connection := Connection;
        Connection := ConnectionTemp;

        Close;
        SQL.Text := sSql;
        Prepared := True;
        Open;

        if FieldByName('USE_STATUS').AsString = '1' then
          tmDate := FieldByName('start_datetime').AsDateTime
        else
          tmDate := FieldByName('reserve_datetime').AsDateTime;

        Result := FormatDateTime('YYYYMMDDhhnnss', tmDate);

      except
        on E: Exception do
        begin
          Result := E.Message + ' / ' + sSql;

          sLog := 'SelectPossibleReserveDatetime Exception : ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

//시스템 재설치, DB초기화시 금일 배정목록 ERP로 부터 받아옴
function TXGolfDM.SeatUseInsert(ASeatUseInfo: TSeatUseInfo): String;
var
  sSql: String;
begin
  Result := '';
  try

    sSql := ' insert into seat_use ' +
            ' ( use_seq_date, use_seq_no, store_cd, seat_no, seat_nm, use_status, use_div, ';

    if ASeatUseInfo.MemberSeq <> '' then
    begin
      sSql := sSql +
            '   member_seq, member_nm, ';
    end;

    sSql := sSql +
            '   purchase_seq, product_seq, product_nm, reserve_div, use_minute, ' +
            '   use_balls, ' +
            '   delay_minute, ' +
            '   reserve_date, ' +
            '   start_date, ' +
            '   reg_date, reg_id) ' +
            ' values ' +
            ' ( ' +
                QuotedStr(ASeatUseInfo.UseSeqDate) + ',' +
                IntToStr(ASeatUseInfo.UseSeqNo) + ',' +
                QuotedStr(ASeatUseInfo.StoreCd) + ',' +
                IntToStr(ASeatUseInfo.SeatNo) + ',' +
                QuotedStr(ASeatUseInfo.SeatNm) + ',' +
                QuotedStr(ASeatUseInfo.SeatUseStatus) + ',' + // '4'
                QuotedStr(ASeatUseInfo.UseDiv) + ',';
     if ASeatUseInfo.MemberSeq <> '' then
    begin
      sSql := sSql +
                ASeatUseInfo.MemberSeq + ',' +
                QuotedStr(ASeatUseInfo.MemberNm) + ',';
    end;
    sSql := sSql +
                IntToStr(ASeatUseInfo.PurchaseSeq) + ',' +
                IntToStr(ASeatUseInfo.ProductSeq) + ',' +
                QuotedStr(ASeatUseInfo.ProductNm) + ',' +
                QuotedStr(ASeatUseInfo.ReserveDiv) + ',' +
                IntToStr(ASeatUseInfo.AssignMin) + ',' +
                IntToStr(ASeatUseInfo.AssignBalls) + ',' +
                IntToStr(ASeatUseInfo.PrepareMin) + ',' +
            '   date_format(' + QuotedStr(ASeatUseInfo.ReserveDate) + ', ''%Y-%m-%d %H:%i:%S''),' +
            '   date_format(' + QuotedStr(ASeatUseInfo.StartTime) + ', ''%Y-%m-%d %H:%i:%S''),' +
            '   now(), ' + QuotedStr(ASeatUseInfo.RegId) +
            ' ) ';

    qrySeatUpdate.Close;
    qrySeatUpdate.SQL.Text := sSql;
    qrySeatUpdate.ExecSQL;

    Result := 'Success';
  except
    on E: Exception do
    begin
      Result := E.Message + ' / ' + sSql;
    end;
  end;

end;

function TXGolfDM.TeeboxUseInsert(ASeatUseSql: String): AnsiString;
var
  sSql, sLog: String;
begin
  Result := '';

  sSql := ASeatUseSql;

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;

        Close;
        SQL.Text := sSql;
        //Prepared := True; //쿼리문이 복수개일경우 에러발생
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseChangeUdate(ASeatUseInfo: TSeatUseInfo): AnsiString;
var
  sSql, sLog: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);
    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' update seat_use set ' +
               '    use_minute = ' + IntToStr(ASeatUseInfo.AssignMin) +
               '  , use_balls = ' + IntToStr(ASeatUseInfo.AssignBalls) +
               '  , delay_minute = ' + IntToStr(ASeatUseInfo.PrepareMin) +
               '  , memo = ' + QuotedStr(ASeatUseInfo.Memo) +
               '  , chg_id = ' + QuotedStr(ASeatUseInfo.ChgId) +
               '  , chg_date = now() ' +
               ' where store_cd = ' + QuotedStr(ASeatUseInfo.StoreCd) +
               ' and use_seq = ' + IntToStr(ASeatUseInfo.UseSeq);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message + ' / ' + sSql;

          sLog := E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseStartDateUpdate(AStoreCode, AReserveNo, AReserveStartDate, AUserId: String): String;
var
  sSql, sUseSeqDate, sUseSeqNo: String;
  nNo: Integer;
  sLog: String;
begin
  Result := '';

  sUseSeqDate := Copy(AReserveNo, 1, 8);
  sUseSeqNo := Copy(AReserveNo, 9, 4);
  nNo := StrToInt(sUseSeqNo);
  sUseSeqNo := IntToStr(nNo);

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionTm;

        sSql := ' update seat_use set ' +
                '    start_date = date_format(' + QuotedStr(AReserveStartDate) + ', ''%Y%m%d%H%i%S'') ' +
                '  , use_status = 1 ' +
                '  , chg_id = ' + QuotedStr(AUserId) +
                '  , chg_date = now() ' +
                ' where store_cd = ' + QuotedStr(AStoreCode) +
                ' and use_status = 4 ' +   //2021-04-13 추가
                ' and use_seq_date = ' + QuotedStr(sUseSeqDate) +
                ' and use_seq_no = ' + sUseSeqNo;

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';

      except
        on E: Exception do
        begin
          Result := E.Message + ' / ' + sSql;

          sLog := E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;

      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseEndDateUpdate(AStoreCode, AReserveNo, AReserveEndDate, AEndTy: String): String;
var
  sSql, sUseSeqDate, sUseSeqNo: String;
  nNo: Integer;
  sLog: String;
begin
  Result := '';

  if AReserveNo = '' then
    Exit;

  sUseSeqDate := Copy(AReserveNo, 1, 8);
  sUseSeqNo := Copy(AReserveNo, 9, 4);
  nNo := StrToInt(sUseSeqNo);
  sUseSeqNo := IntToStr(nNo);

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionTm;

        sSql := ' update seat_use set ' +
                '    end_date = date_format(' + QuotedStr(AReserveEndDate) + ', ''%Y%m%d%H%i%S'') ' +
                '  , use_status = ' + AEndTy + //2: 종료, 5:취소
                //'  , chg_id = ' + QuotedStr(AUserId) + //등록자,취소자 유지
                '  , chg_date = now() ' +
                ' where store_cd = ' + QuotedStr(AStoreCode) +
                ' and use_seq_date = ' + QuotedStr(sUseSeqDate) +
                ' and use_seq_no = ' + sUseSeqNo;

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';

      except
        on E: Exception do
        begin
          Result := E.Message + ' / ' + sSql;

          sLog := E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;

      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseMoveUpdate(AStoreCode, ASeq, AUserId: String): AnsiString;
var
  sSql, sLog: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' update seat_use set ' +
                 '    use_status = ''2'' ' +  // '종료'처리
                 '  , end_date = now() ' +
                 '  , move_yn = ''Y'' ' +
                 '  , chg_id = ' + QuotedStr(AUserId) +
                 '  , chg_date = now() ' +
                 ' where store_cd = ' + QuotedStr(AStoreCode) +
                 ' and use_seq = ' + ASeq;

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := 'SeatUseMoveUpdate.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseAllReserveSelect(AStoreCode, AStr: String): TList<TSeatUseReserve>;
var
  sSql, sUseSeqDate, sUseSeqNo: String;
  rSeatUseReserve: TSeatUseReserve;
  tmDateTime: TDateTime;
  nIndex: Integer;
  sLog: String;
begin
  try

    with TUniQuery.Create(nil) do
    try

      Connection := ConnectionAuto;
      sSql := ' select ' +
            '        use_seq as use_seq, ' +
            '        use_seq_date as use_seq_date, ' +
            '        use_seq_no as use_seq_no, ' +
            '        store_cd as store_cd, ' +
            '        seat_no as teebox_no, ' +
            '        min(use_status) as use_status, ' +
            '        use_minute as assign_min, ' +
            '        delay_minute as prepare_min, ' +
            '        use_balls as assign_balls, ' +
            '        assign_yn as assign_yn, ' +
            '        reserve_date as reserve_datetime, ' +
            '        start_date as start_datetime, ' +
            '        end_date as end_datetime ' +
            '  from seat_use ' +
            ' where store_cd = ' + QuotedStr(AStoreCode) +
            //'   and use_seq_date = ' + FormatDateTime('YYYYMMDD', Now) +
            //'   and now() > reserve_date ';
            '   and ( (now() > reserve_date ) or (now() > start_date) ) '; //2022-06-17 즉시배정된 배정

      if AStr = '' then
      begin
      sSql := sSql +
            '   and use_status in (''4'', ''1'') ' + //-- ( 4:예약, 1:이용중 )
            ' group by teebox_no ';
      end
      else
      begin
      sSql := sSql +
            '   and seat_no in (' + AStr + ') ' +
            '   and use_status = ''4'' ' +
            ' group by teebox_no ';
      end;

      Close;
      SQL.Text := sSql;
      Prepared := True;
      //Global.ErpApiLogWrite(sSql + #13);
      Open;

      Result := TList<TSeatUseReserve>.Create;
      for nIndex := 0 to RecordCount - 1 do
      begin
        rSeatUseReserve.SeatNo := FieldByName('teebox_no').AsInteger;

        //rSeatUseReserve.ReserveNo := qryTemp.FieldByName('reserve_no').AsString;
        sUseSeqDate := FieldByName('use_seq_date').AsString;
        sUseSeqNo := StrZeroAdd(FieldByName('use_seq_no').AsString, 4);
        rSeatUseReserve.ReserveNo := sUseSeqDate + sUseSeqNo;

        rSeatUseReserve.UseStatus := FieldByName('use_status').AsString;
        rSeatUseReserve.UseMinute := FieldByName('assign_min').AsInteger;
        rSeatUseReserve.UseBalls := FieldByName('assign_balls').AsInteger;
        rSeatUseReserve.AssignYn := FieldByName('assign_yn').AsString;
        rSeatUseReserve.DelayMinute := FieldByName('prepare_min').AsInteger;
        rSeatUseReserve.ReserveDateTm := FieldByName('reserve_datetime').AsDateTime;
        rSeatUseReserve.ReserveDate := FormatDateTime('YYYYMMDDhhnnss', rSeatUseReserve.ReserveDateTm);
        //rSeatUseReserve.ReserveDate := qryTemp.FieldByName('reserve_datetime').AsString;
        if FieldByName('start_datetime').AsString = '' then
        begin
          rSeatUseReserve.StartTime := '';
        end
        else
        begin
          rSeatUseReserve.StartTimeTm := FieldByName('start_datetime').AsDateTime;
          rSeatUseReserve.StartTime := FormatDateTime('YYYYMMDDhhnnss', rSeatUseReserve.StartTimeTm);
        end;

        Result.Add(rSeatUseReserve);
        Next;
      end;

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;

  except
    on E: Exception do
    begin
      sLog := 'SeatUseAllReserveSelect.Exception: ' +  E.Message;
      Global.Log.LogErpApiWrite(sLog);
    end;
  end;

end;

function TXGolfDM.SeatUseAllReserveSelectNext(AStoreCode: String): TList<TSeatUseReserve>;
var
  sSql, sUseSeqDate, sUseSeqNo: String;
  rSeatUseReserve: TSeatUseReserve;
  tmDateTime: TDateTime;
  nIndex: Integer;
  sLog: String;
begin
  try

    with TUniQuery.Create(nil) do
    try
      //EnterCriticalSection(FCS);

      Connection := ConnectionAuto;
      sSql := ' select ' +
              '        use_seq as use_seq, ' +
              '        use_seq_date as use_seq_date, ' +
              '        use_seq_no as use_seq_no, ' +
              '        store_cd as store_cd, ' +
              '        seat_no as teebox_no, ' +
              '        use_status as use_status, ' +
              '        use_minute as assign_min, ' +
              '        delay_minute as prepare_min, ' +
              '        use_balls as assign_balls, ' +
              '        assign_yn as assign_yn, ' +
              '        reserve_date as reserve_datetime, ' +
              '        start_date as start_datetime, ' +
              '        end_date as end_datetime ' +
              '  from seat_use ' +
              ' where store_cd = ' + QuotedStr(AStoreCode) +
              '   and use_status = ''4'' '; //-- ( 4:예약, 1:이용중 )
              //'   and use_seq_date = ' + FormatDateTime('YYYYMMDD', Now);
              //'   and now() <= reserve_date ' ; //2020-06-29 수정

      Close;
      SQL.Text := sSql;
      Prepared := True;
      Open;

      Result := TList<TSeatUseReserve>.Create;
      for nIndex := 0 to RecordCount - 1 do
      begin
        rSeatUseReserve.SeatNo := FieldByName('teebox_no').AsInteger;

        sUseSeqDate := FieldByName('use_seq_date').AsString;
        sUseSeqNo := StrZeroAdd(FieldByName('use_seq_no').AsString, 4);
        rSeatUseReserve.ReserveNo := sUseSeqDate + sUseSeqNo;

        rSeatUseReserve.UseStatus := FieldByName('use_status').AsString;
        rSeatUseReserve.UseMinute := FieldByName('assign_min').AsInteger;
        rSeatUseReserve.UseBalls := FieldByName('assign_balls').AsInteger;
        rSeatUseReserve.DelayMinute := FieldByName('prepare_min').AsInteger;
        rSeatUseReserve.AssignYn := FieldByName('assign_yn').AsString;
        rSeatUseReserve.ReserveDateTm := FieldByName('reserve_datetime').AsDateTime;
        rSeatUseReserve.ReserveDate := FormatDateTime('YYYYMMDDhhnnss', rSeatUseReserve.ReserveDateTm);

        Result.Add(rSeatUseReserve);
        Next;
      end;

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;

  except
    on E: Exception do
    begin
      sLog := 'SeatUseAllReserveSelectNext.Exception: ' +  E.Message;
      Global.Log.LogErpApiWrite(sLog);
    end;
  end;

end;

function TXGolfDM.SelectTeeboxReservationOneWithSeqList(AUseSeq: Array of Integer): TList<TSeatUseReserve>;
var
  sSql: String;
  rSeatUseReserve: TSeatUseReserve;
  nIndex: Integer;
  sStr, sUseSeqDate, sUseSeqNo: String;
  I: Integer;
  tmDateTime: TDatetime;
  sLog: String;
begin

  sStr := '(';
  for I := 0 to Length(AUseSeq) - 1 do
  begin
    if i > 0 then
      sStr := sStr + ',';
    sStr := sStr + IntToStr(AUseSeq[i]);
  end;
  sStr := sStr + ')';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        sSql :=  ' select ' +
                 '        t1.use_seq, t1.use_seq_date, t1.use_seq_no, ' +
                 '        t2.FLOOR_ZONE_CODE as floor_cd, ' +
                 '        t1.SEAT_NO as teebox_no, ' +
                 '        t2.SEAT_NM as teebox_nm, ' +
                 '        t1.USE_MINUTE as remain_min, ' +
                 '        t1.USE_BALLS as remain_balls, ' +
                 '        t1.DELAY_MINUTE as prepare_min, ' +
                 '        t1.RESERVE_DATE as reserve_datetime, ' +
                 '        case t1.use_status ' +
                 '           when ''1'' then t1.start_date ' +
                 '           when ''4'' then date_add(now(), interval t6.remain_sum - t1.use_minute minute) ' +
                 '           else t1.start_date ' +
                 '        end as start_datetime, ' +
                 '        case t1.use_status ' +
                 '           when ''1'' then date_add(t1.start_date, interval t1.use_minute minute) ' +
                 '           when ''4'' then date_add(now(), interval t6.remain_sum minute) ' +
                 '           else t1.end_date ' +
                 '        end as end_datetime, ' +
                 '        t2.SEAT_ZONE_CODE as vip_yn, ' +
                 '        t2.USE_YN as use_yn, ' +
                 '        t2.USE_STATUS as use_status, ' +
                 //'        concat(t1.store_cd,  t1.use_seq) as reserve_no, ' +
                 '        t1.PURCHASE_SEQ as purchase_cd, ' +
                 '        t1.reg_date as reg_datetime ' +
                 ' from seat_use t1 ' +
                 '     left outer join seat t2 on t1.seat_no = t2.seat_no and t1.store_cd = t2.store_cd  ' +
                 '     left outer join vi_seat_use_time t6 on t1.use_seq = t6.use_seq ' +
                 ' where t1.store_cd = ' + QuotedStr(Global.ADConfig.StoreCode) +
                 //' and t1.use_seq in ' + sStr +
                 ' and t1.use_seq_date = ' + FormatDateTime('YYYYMMDD', Now) +
                 ' and t1.use_seq_no in ' + sStr +
                 ' order by t1.use_seq desc';

        //Connection := Connection;
        Connection := ConnectionTemp;

        Close;
        SQL.Text := sSql;
        Prepared := True;
        Open;

        Result := TList<TSeatUseReserve>.Create;
        for nIndex := 0 to RecordCount - 1 do
        begin

          //rSeatUseReserve.ReserveNo := qryTemp.FieldByName('reserve_no').AsString;
          sUseSeqDate := FieldByName('use_seq_date').AsString;
          sUseSeqNo := StrZeroAdd(FieldByName('use_seq_no').AsString, 4);
          rSeatUseReserve.ReserveNo := sUseSeqDate + sUseSeqNo;

          tmDateTime := FieldByName('start_datetime').AsDateTime;
          rSeatUseReserve.StartTime := FormatDateTime('YYYYMMDDhhnnss', tmDateTime);

          rSeatUseReserve.SeatNo := FieldByName('teebox_no').AsInteger;
          rSeatUseReserve.UseMinute := FieldByName('remain_min').AsInteger;
          rSeatUseReserve.UseBalls := FieldByName('remain_balls').AsInteger;
          rSeatUseReserve.DelayMinute := FieldByName('prepare_min').AsInteger;
          tmDateTime := FieldByName('reserve_datetime').AsDateTime;
          rSeatUseReserve.ReserveDate := FormatDateTime('YYYYMMDDhhnnss', tmDateTime);

          Result.Add(rSeatUseReserve);
          Next;
        end;

      except
        on E: Exception do
        begin
          //Result := E.Message + ' / ' + sSql;

          sLog := 'SelectTeeboxReservationOneWithSeqList Exception : ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SelectTeeboxReservationOneWithSeq(AStoreCd, AUseSeqDate, AUseSeqNo: String): TSeatUseInfo;
var
  sSql, sUseSeqDate, sUseSeqNo: String;
  rSeatUseInfo: TSeatUseInfo;
  tmDateTime: TDateTime;
  sLog: String;
begin

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        sSql :=  ' select ' +
                 '        t1.use_seq, t1.use_seq_date, t1.use_seq_no, ' +
                 '        t2.FLOOR_ZONE_CODE as floor_cd, ' +
                 '        t1.SEAT_NO as teebox_no, ' +
                 '        t2.SEAT_NM as teebox_nm, ' +
                 '        t1.USE_MINUTE as remain_min, ' +
                 '        t1.USE_BALLS as remain_balls, ' +
                 '        t1.DELAY_MINUTE as prepare_min, ' +
                 '        t1.RESERVE_DATE as reserve_datetime, ' +
                 '        case t1.use_status ' +
                 '           when ''1'' then t1.start_date ' +
                 //2021-05-26 시간변경시 대기중인 타석의 앞타석이 공백이 클경우 시작시간표시 문제될수 있어 수정
                 //'           when ''4'' then date_add(now(), interval t6.remain_sum - t1.use_minute minute) ' +
                 '           when ''4'' then date_add(t1.RESERVE_DATE, interval t1.DELAY_MINUTE minute) ' +
                 '           else t1.start_date ' +
                 '        end as start_datetime, ' +
                 '        case t1.use_status ' +
                 '           when ''1'' then date_add(t1.start_date, interval t1.use_minute minute) ' +
                 //'           when ''4'' then date_add(now(), interval t6.remain_sum minute) ' +
                 '           when ''4'' then date_add(t1.RESERVE_DATE, interval t1.USE_MINUTE + t1.DELAY_MINUTE minute) ' +
                 '           else t1.end_date ' +
                 '        end as end_datetime, ' +
                 '        t2.SEAT_ZONE_CODE as vip_yn, ' +
                 '        t2.USE_YN as use_yn, ' +
                 '        t2.USE_STATUS as use_status, ' +
                 '        t1.use_status as seat_use_status, ' +
                 '        t2.remain_minute, ' +
                 //'        concat(t1.store_cd,  t1.use_seq) as reserve_no, ' +
                 '        t1.PURCHASE_SEQ as purchase_cd, ' +
                 '        t1.PRODUCT_SEQ as product_cd, ' +
                 '        t1.PRODUCT_NM as product_nm, ' +
                 '        t1.RESERVE_DIV as reserve_div, ' +
                 '        t1.reg_date as reg_datetime, ' +
                 '        t1.RESERVE_ROOT_DIV, ' +
                 '        t1.ASSIGN_YN, ' +
                 '        t1.LESSON_PRO_NM, ' +
                 '        t1.LESSON_PRO_POS_COLOR, ' +
                 //'        t1.ERP_JSON ' +
                 '        t1.EXPIRE_DAY, ' +
                 '        t1.COUPON_CNT ' +
                 ' from seat_use t1 ' +
                 '      left outer join seat t2 on t1.seat_no = t2.seat_no and t1.store_cd = t2.store_cd ' +
                 '      left outer join vi_seat_use_time t6 on t1.use_seq = t6.use_seq ' +
                 ' where t1.store_cd = ' + QuotedStr(AStoreCd);

        if Trim(AUseSeqDate) <> '' then
        begin
          sSql := sSql +
                '    and t1.use_seq_date = ' + AUseSeqDate +
                '    and t1.use_seq_no = ' + AUseSeqNo;
        end;

        sSql := sSql +
                 ' order by t1.use_seq desc ' +
                 ' limit 1 ';

        Connection := ConnectionTemp;

        Close;
        SQL.Text := sSql;
        Prepared := True;
        Open;

        if IsEmpty then
        begin
          rSeatUseInfo.StoreCd := AStoreCd;
          rSeatUseInfo.UseSeq := -1;

          sLog := 'SelectTeeboxReservationOneWithSeq : ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end
        else
        begin

          rSeatUseInfo.StoreCd := AStoreCd;
          rSeatUseInfo.UseSeq := FieldByName('use_seq').AsInteger;
          rSeatUseInfo.SeatNo := FieldByName('teebox_no').AsInteger;
          rSeatUseInfo.SeatNm := FieldByName('teebox_nm').AsString;
          rSeatUseInfo.SeatUseStatus := FieldByName('seat_use_status').AsString;   // 4: 예약
          rSeatUseInfo.AssignMin := FieldByName('remain_min').AsInteger;
          rSeatUseInfo.AssignBalls := FieldByName('remain_balls').AsInteger;
          rSeatUseInfo.PrepareMin := FieldByName('prepare_min').AsInteger;
          rSeatUseInfo.RemainMin := FieldByName('remain_minute').AsInteger;
          rSeatUseInfo.PurchaseSeq := FieldByName('purchase_cd').AsInteger;
          rSeatUseInfo.ProductSeq := FieldByName('product_cd').AsInteger;
          rSeatUseInfo.ProductNm := FieldByName('product_nm').AsString;
          rSeatUseInfo.ReserveDiv := FieldByName('reserve_div').AsString;

          rSeatUseInfo.UseSeqDate := FieldByName('use_seq_date').AsString;
          sUseSeqDate := rSeatUseInfo.UseSeqDate;
          rSeatUseInfo.UseSeqNo := FieldByName('use_seq_no').AsInteger;
          sUseSeqNo := StrZeroAdd(FieldByName('use_seq_no').AsString, 4);

          rSeatUseInfo.ReserveNo := sUseSeqDate + sUseSeqNo;

          tmDateTime := FieldByName('start_datetime').AsDateTime;
          rSeatUseInfo.StartTime := FormatDateTime('YYYYMMDDhhnnss', tmDateTime);

          tmDateTime := FieldByName('reserve_datetime').AsDateTime;
          rSeatUseInfo.ReserveDate := FormatDateTime('YYYYMMDDhhnnss', tmDateTime);

          rSeatUseInfo.AssignYn := FieldByName('ASSIGN_YN').AsString;

          rSeatUseInfo.LessonProNm := FieldByName('LESSON_PRO_NM').AsString;
          rSeatUseInfo.LessonProPosColor := FieldByName('LESSON_PRO_POS_COLOR').AsString;

          //rSeatUseInfo.Json := FieldByName('ERP_JSON').AsString;
          rSeatUseInfo.ExpireDay := FieldByName('EXPIRE_DAY').AsString;
          rSeatUseInfo.CouponCnt := FieldByName('COUPON_CNT').AsString;
        end;

        Result := rSeatUseInfo;

      except
        on E: Exception do
        begin
          //Result := E.Message + ' / ' + sSql;
          sLog := 'SelectTeeboxReservationOneWithSeq.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.DeleteTeeboxReservation(AStoreId, AUserId, AUseSeq: String): AnsiString;
var
  sSql: String;
  sStr: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;
        sSql := ' update seat_use set ' +
                '        use_status = ''5'', ' +
                '        chg_date = now(), ' +
                '        chg_id = ' +  QuotedStr(AUserId) +
                ' where store_cd = ' + QuotedStr(AStoreId) +
                ' and use_seq = ' + AUseSeq;
        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;
        end;
      end;

    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.InsertSeatMoveHist(AStoreCode, AUseSeq, AOldSeatNo, ANewSeatNo, AUserId: String): String;
var
  sSql, sLog: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;
        sSql := ' insert into seat_move_hist ' +
                ' ( store_cd, use_seq, old_no, new_no, reg_date, reg_id) ' +
                ' values ( ' +
                  QuotedStr(AStoreCode) + ', ' +
                  AUseSeq + ', ' +
                  AOldSeatNo + ', ' +
                  ANewSeatNo + ', ' +
                ' now(), ' +
                  QuotedStr(AUserId) +
                ' ) ';

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message + ' / ' + sSql;

          sLog := 'InsertSeatMoveHist Exception: ' + E.Message;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.ReConnection: Boolean;
begin
  //Connection.Disconnect;
  //Connection.Connect;
  Global.Log.LogWrite('DB ReConnection!!');
  DBDisconnect;
  DBConnection;
end;

function TXGolfDM.ReConnectionReserve: Boolean;
begin
  ConnectionReserve.Disconnect;
  ConnectionReserve.Connect;
end;

function TXGolfDM.ReConnectionHold: Boolean;
begin
  ConnectionHold.Disconnect;
  ConnectionHold.Connect;
end;

function TXGolfDM.ReserveDateNo(AStoreId, ADate: String):Integer;
var
  sSql: String;
  nSeq: Integer;
begin
  Result := 1;

  with TUniQuery.Create(nil) do
  try
    Connection := ConnectionAuto;
    sSql := ' select Max(use_seq_no) as max_use_seq_no from seat_use ' +
            ' where store_cd = ' + QuotedStr(AStoreId) +
            '   and use_seq_date = ' + QuotedStr(ADate);

    Close;
    SQL.Text := sSql;
    Prepared := True;
    Open;

    if not IsEmpty then
    begin
      nSeq := FieldByName('max_use_seq_no').AsInteger;
      Result := nSeq;
    end;

  finally
    Close;
    Free;
  end;

end;

function TXGolfDM.SeatHeatUseUpdate(AStoreCode, ATeeboxNo, AHeatUse, AHeatAuto, AUserId: String): AnsiString;
var
  sSql: String;
  sStr, sLog: String;
begin
  Result := '';
  try
    BeginTrans;

    sSql := ' update seat set ' +
            '        heat_auto = ' +  QuotedStr(AHeatAuto) +
            '       , heat_status = ' +  QuotedStr(AHeatUse) +
            '       , reg_date = now() ' +
            //'       , chg_id = ' +  QuotedStr(AUserId) +
            ' where store_cd = ' + QuotedStr(AStoreCode) +
            ' and seat_no = ' + ATeeboxNo;

    qrySeatUpdate.Close;
    qrySeatUpdate.SQL.Text := sSql;
    qrySeatUpdate.ExecSQL;

    CommitTrans;
    Result := 'Success';
  except
    on E: Exception do
    begin
      RollbackTrans;
      Result := E.Message;

      sLog := 'SeatHeatUseUpdate Exception: ' + E.Message;
      Global.Log.LogErpApiWrite(sLog);
    end;
  end;

end;

function TXGolfDM.SetSeatReserveUseMinAdd(AStoreCode, ASeatNo, AUseSeqDate, ADelayTm: String): String;
var
  sSql: String;
  //sStr: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try

        Connection := ConnectionAuto;
        sSql := ' update seat_use ' +
                ' set use_minute = use_minute + ' + ADelayTm +
                ' where store_cd = ' + QuotedStr(AStoreCode);
        if ASeatNo <> '0' then
          sSql := sSql +
                ' and seat_no = ' + ASeatNo;
        sSql := sSql +
                ' and use_status = ''1'' ' +
                ' and use_seq_date = ' + QuotedStr(AUseSeqDate);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
      on E: Exception do
        begin
          Result := E.Message;
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SetSeatReserveTmChange(AStoreCode, ASeatNo, AUseSeqDate, ADelayTm, ADateTime: String): String;
var
  sSql: String;
  sStr: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try

        Connection := ConnectionAuto;
        sSql := ' update seat_use ' +
                ' set reserve_date = date_add(reserve_date, INTERVAL ' + ADelayTm + ' MINUTE) ' +
                ' where store_cd = ' + QuotedStr(AStoreCode);
        if ASeatNo <> '0' then
          sSql := sSql +
                ' and seat_no = ' + ASeatNo;

        if ASeatNo = '0' then
        begin
          begin
            sSql := sSql +
                  ' and REG_DATE < date_format(' + QuotedStr(ADateTime) + ', ''%Y%m%d%H%i%S'') ';
          end;
        end;

        sSql := sSql +
                ' and use_status = ''4'' ' +
                ' and use_seq_date = ' + QuotedStr(AUseSeqDate);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
      on E: Exception do
        begin
          Result := E.Message;
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;
{
function TXGolfDM.SetSeatReserveStartTmChange(AStoreCode, ASeatNo, ADate, AReserveNo: String): String;
var
  sSql: String;
  sStr, sSeqDate: String;
  nSeqNo: Integer;
begin
  Result := '';

  sSeqDate := copy(AReserveNo, 1, 8);
  nSeqNo := StrToInt( copy(AReserveNo, 9, 4) );

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try

        Connection := ConnectionAuto;
        sSql := ' update seat_use ' +
                ' set reserve_date = date_format(' + QuotedStr(ADate) + ', ''%Y%m%d%H%i%S'') ' +
                ' where store_cd = ' + QuotedStr(AStoreCode) +
                ' and seat_no = ' + ASeatNo +
                ' and use_status = ''4'' ' +
                ' and use_seq_no = ' + IntToStr(nSeqNo) +
                ' and use_seq_date = ' + QuotedStr(sSeqDate);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
      on E: Exception do
        begin
          Result := E.Message;
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;
}

function TXGolfDM.SeatUseReserveDateUpdate(AStoreCode, AReserveNo, ADate: String): String;
var
  sSql: String;
  sStr, sSeqDate: String;
  nSeqNo: Integer;
begin
  Result := 'Fail';

  sSeqDate := copy(AReserveNo, 1, 8);
  nSeqNo := StrToInt( copy(AReserveNo, 9, 4) );

  with TUniQuery.Create(nil) do
  begin

    try
      try

        Connection := ConnectionAuto;
        sSql := ' update seat_use ' +
                ' set reserve_date = date_format(' + QuotedStr(ADate) + ', ''%Y%m%d%H%i%S'') ' +
                ' where store_cd = ' + QuotedStr(AStoreCode) +
                //' and use_status = ''4'' ' +
                ' and use_seq_no = ' + IntToStr(nSeqNo) +
                ' and use_seq_date = ' + QuotedStr(sSeqDate);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
      on E: Exception do
        begin
          Result := E.Message;
        end;
      end;
    finally
      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseStoreClose(AStorecd, AUserId, ADate: String): Boolean;
var
  sSql, sLog: String;
begin

  Result := False;

  with TUniQuery.Create(nil) do
  try
    try
      Connection := ConnectionAuto;
      sSql :=  ' update seat_use set ' +
               '  use_status = ''2'' ' +
               ', chg_id = ' + QuotedStr(AUserId) +
               ', chg_date = now() ' +
               ' where store_cd = ' + QuotedStr(AStorecd) +
               ' and use_seq_date = ' + QuotedStr(ADate) +
               ' and use_status = ''1'' ';

      Close;
      SQL.Text := sSql;
      ExecSQL;

      Result := True;
    except
      on E: Exception do
      begin
        //Result := E.Message + ' / ' + sSql;

        sLog := 'SeatUseStoreClose Exception: ' + E.Message;
        Global.Log.LogErpApiWrite(sLog);
      end;
    end;
  finally
    Close;
    Free;
  end;

end;

function TXGolfDM.SeatUseDeleteReserve(AStorecd, ADate: String): Boolean;
var
  sSql, sLog: String;
begin

  Result := False;

  with TUniQuery.Create(nil) do
  try
    try
      Connection := ConnectionAuto;
      sSql :=  ' delete from seat_use ' +
               ' where store_cd = ' + QuotedStr(AStorecd) +
               ' and use_seq_date < ' + QuotedStr(ADate);
      Close;
      SQL.Text := sSql;
      ExecSQL;

      Result := True;
    except
      on E: Exception do
      begin
        //Result := E.Message + ' / ' + sSql;

        sLog := 'SeatUseDeleteReserve Exception: ' + E.Message;
        Global.Log.LogErpApiWrite(sLog);
      end;
    end;
  finally
    Close;
    Free;
  end;

end;

function TXGolfDM.AgentSelectAll: String;
var
  sSql: String;
begin
  sSql := ' SELECT * FROM AGENT ORDER BY TEEBOX_NO';

  UniQueryAgent.Close;
  UniQueryAgent.SQL.Text := sSql;
  UniQueryAgent.Open;
end;

function TXGolfDM.AgentSelect(AAgentNo, ALeftHanded: String): String;
var
  sSql: String;
begin

  with TUniQuery.Create(nil) do
  begin

    try

      Connection := ConnectionTemp;

      sSql := ' SELECT * FROM AGENT WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode) +
              ' AND TEEBOX_NO = ' + AAgentNo +
              ' AND LEFT_HANDED = ' + ALeftHanded;

      Close;
      SQL.Text := sSql;
      Prepared := True;
      ExecSQL;

      if RecordCount = 0 then
        Result := 'fail'
      else
        Result := FieldByName('SETTING').AsString;

    finally
      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.AgentInsert(AAgentNo, ALeftHanded, ASetting: String): Boolean;
var
  sSql: String;
  I: Integer;
begin
  Result := False;

  with TUniQuery.Create(nil) do
  begin

    try
      Connection := ConnectionTemp;

      sSql := ' INSERT INTO AGENT ' +
            '( STORE_CD, TEEBOX_NO, LEFT_HANDED, SETTING, CHG_DATE ) ' +
            ' VALUES ' +
            '( ' + QuotedStr(Global.ADConfig.StoreCode) + ', '
                 + AAgentNo + ', '
                 + QuotedStr(ALeftHanded) +', '
                 + QuotedStr(ASetting) +', '
                 + 'now())';

      Close;
      SQL.Text := sSql;
      Execute;

    finally
      Close;
      Free;
    end;
  end;

  Result := True;
end;

function TXGolfDM.AgentUpdate(AAgentNo, ALeftHanded, ASetting: String): Boolean;
var
  sSql: String;
  I: Integer;
begin

  Result := False;

  with TUniQuery.Create(nil) do
  begin

    try

      Connection := ConnectionTemp;

      sSql := ' UPDATE AGENT SET ' +
            '     SETTING = ' + QuotedStr(ASetting) + ',' +
            '     CHG_DATE = now() ' +
            ' WHERE STORE_CD = ' + QuotedStr(Global.ADConfig.StoreCode) +
            ' AND TEEBOX_NO = ' + AAgentNo +
            ' AND LEFT_HANDED = ' + ALeftHanded;

      Close;
      SQL.Text := sSql;
      Execute;

    finally
      Close;
      Free;
    end;
  end;

  Result := True;
end;


function TXGolfDM.SeatUseCutInSelect(AStoreCode, AReserveNo: String): AnsiString;
var
  sSql, sLog, sSeqDate: String;
  nSeqNo: Integer;
  sCutInYn, sCutInUse: String;
begin
  Result := '';

  sSeqDate := Copy(AReserveNo, 1, 8);
  nSeqNo := StrToInt(Copy(AReserveNo, 9, 4));

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' select * from seat_use ' +
                 ' where store_cd = ' + QuotedStr(AStoreCode) +
                 ' and use_seq_no = ' + IntToStr(nSeqNo) +
                 ' and use_seq_date = ' + QuotedStr(sSeqDate);

        Close;
        SQL.Text := sSql;
        Open;

        sCutInYn := FieldByName('cutin_yn').AsString;
        sCutInUse := FieldByName('cutin_use').AsString;

        if (sCutInYn = 'Y') and (sCutInUse = 'N') then
        begin
          Result := '끼어넣기를 사용한 배정 입니다.';
          Exit;
        end;

        if (sCutInYn = 'N') and (sCutInUse = 'N') then
        begin
          Result := '끼어넣기를 사용할수 없는 배정 입니다.';
          Exit;
        end;

        Result := 'success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := 'SeatUseCutInSelect.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseCutInUpdate(AStoreCode, ASeq, AUserId: String): AnsiString;
var
  sSql, sLog: String;
begin
  Result := '';

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' update seat_use set ' +
                 '    use_status = ''2'' ' +  // '종료'처리
                 '  , end_date = now() ' +
                 '  , cutin_yn = ''Y'' ' +
                 '  , chg_id = ' + QuotedStr(AUserId) +
                 '  , chg_date = now() ' +
                 ' where store_cd = ' + QuotedStr(AStoreCode) +
                 ' and use_seq = ' + ASeq;

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := 'SeatUseCutInUpdate.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseCutInUseInsert(AStoreCode, AReserveNo: String): AnsiString;
var
  sSql, sLog, sSeqDate: String;
  nSeqNo: Integer;
begin
  Result := '';

  sSeqDate := Copy(AReserveNo, 1, 8);
  nSeqNo := StrToInt(Copy(AReserveNo, 9, 4));

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' update seat_use set ' +
                 '  cutin_use = ''Y'' ' +
                 //'  , chg_id = ' + QuotedStr(AUserId) +
                 //'  , chg_date = now() ' +
                 ' where store_cd = ' + QuotedStr(AStoreCode) +
                 ' and use_seq_no = ' + IntToStr(nSeqNo) +
                 ' and use_seq_date = ' + QuotedStr(sSeqDate);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := 'SeatUseCutInUseInsert.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseCutInUseDelete(AStoreCode, AReserveNo, AUserId: String): AnsiString;
var
  sSql, sLog, sSeqDate: String;
  nSeqNo: Integer;
begin
  Result := '';

  sSeqDate := Copy(AReserveNo, 1, 8);
  nSeqNo := StrToInt(Copy(AReserveNo, 9, 4));

  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' update seat_use set ' +
                 '  cutin_yn = ''Y'' ' +
                 '  , cutin_use = ''N'' ' +
                 '  , chg_id = ' + QuotedStr(AUserId) +
                 '  , chg_date = now() ' +
                 ' where store_cd = ' + QuotedStr(AStoreCode) +
                 ' and use_seq_no = ' + IntToStr(nSeqNo) +
                 ' and use_seq_date = ' + QuotedStr(sSeqDate);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := 'SeatUseCutInUseDelete.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;

function TXGolfDM.SeatUseCutInUseListDelete(AStoreCode, ATeeboxNo, AReserveDate: String; AType: Boolean = False): AnsiString;
var
  sSql, sLog: String;
begin
  Result := '';

  //AReserveDate 기준으로 cutin_use = N 처리
  with TUniQuery.Create(nil) do
  begin
    //EnterCriticalSection(FCS);

    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' update seat_use set ' +
                 '  cutin_use = ''N'' ' +
                 //'  , chg_id = ' + QuotedStr(AUserId) +
                 //'  , chg_date = now() ' +
                 ' where store_cd = ' + QuotedStr(AStoreCode) +
                 ' and SEAT_NO = ' + ATeeboxNo;

        if AType = True then //즉시배정 인경우
          sSql := sSql +
                 ' and reserve_date < date_format(' + QuotedStr(AReserveDate) + ', ''%Y%m%d%H%i%S'') '
        else
          sSql := sSql +
                 ' and reserve_date > date_format(' + QuotedStr(AReserveDate) + ', ''%Y%m%d%H%i%S'') ';

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := 'SeatUseCutInUseListDelete.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      //LeaveCriticalSection(FCS);

      Close;
      Free;
    end;
  end;

end;


function TXGolfDM.SeatUseCheckInNextUpdate(AStoreCode, AReserveNo: String): AnsiString;
var
  sSql, sLog, sSeqDate: String;
  nSeqNo: Integer;
begin
  Result := '';

  sSeqDate := Copy(AReserveNo, 1, 8);
  nSeqNo := StrToInt(Copy(AReserveNo, 9, 4));

  with TUniQuery.Create(nil) do
  begin

    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' update seat_use set ' +
                 '  assign_yn = ''Y'' ' +
                 ' where store_cd = ' + QuotedStr(AStoreCode) +
                 ' and use_seq_no = ' + IntToStr(nSeqNo) +
                 ' and use_seq_date = ' + QuotedStr(sSeqDate);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := 'SeatUseCheckInNextUpdate.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      Close;
      Free;
    end;
  end;

end;


function TXGolfDM.SeatUseCheckInUpdate(AStoreCode, AReserveNo: String; AAssignMin: Integer): AnsiString;
var
  sSql, sLog, sSeqDate: String;
  nSeqNo: Integer;
begin
  Result := '';

  sSeqDate := Copy(AReserveNo, 1, 8);
  nSeqNo := StrToInt(Copy(AReserveNo, 9, 4));

  with TUniQuery.Create(nil) do
  begin

    try
      try
        Connection := ConnectionAuto;
        sSql :=  ' update seat_use set ' +
                 '    use_minute = ' + IntToStr(AAssignMin) +
                 '  , assign_yn = ''Y'' ' +
                 ' where store_cd = ' + QuotedStr(AStoreCode) +
                 ' and use_seq_no = ' + IntToStr(nSeqNo) +
                 ' and use_seq_date = ' + QuotedStr(sSeqDate);

        Close;
        SQL.Text := sSql;
        ExecSQL;

        Result := 'Success';
      except
        on E: Exception do
        begin
          Result := E.Message;

          sLog := 'SeatUseCheckInUpdate.Exception: ' + E.Message + ' / ' + sSql;
          Global.Log.LogErpApiWrite(sLog);
        end;
      end;
    finally
      Close;
      Free;
    end;
  end;

end;

end.
