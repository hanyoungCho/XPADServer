unit uTeeboxInfo;

interface

uses
  uStruct, uConsts,
  System.Classes, System.SysUtils, System.DateUtils,
  Uni, System.Generics.Collections;

type
  TTeebox = class
  private
    FTeeboxDevicNoList: array of String;
    FTeeboxDevicNoCnt: Integer;
    FTeeboxInfoList: array of TTeeboxInfo;

    FTeeboxLastNo: Integer;

    FTeeboxStatusUse: Boolean;
    FTeeboxReserveUse: Boolean;

  public
    constructor Create;
    destructor Destroy; override;

    procedure StartUp;

    function GetTeeboxListToApi: Boolean;

    function SetTeeboxStartUseStatus: Boolean; //최초실행시

    //Teebox Thread
    //제어없이 시스템상에서 시간계산
    procedure TeeboxStatusChk;
    procedure TeeboxReserveChk;
    procedure TeeboxAgentChk;
    procedure TeeboxTapoOnOff;
    //procedure TeeboxTapoXGMSTatus;

    procedure TeeboxReserveNextChk;

    procedure SendBeamEnd;
    procedure SendBeamStartReCtl;

    //Teebox Thread

    //타석정보 set
    procedure SetTeeboxIP(AMac, AIP: String);
    procedure SetTeeboxOnOff(AIP, AOnOff: String);
    procedure SetTeeboxAgentCtlYN(AIP, ARecive: String); //agent 응답여부

    procedure SetTeeboxCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin, ASecond: Integer);
    procedure SetTeeboxVXCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin: Integer);
    procedure SetTeeboxBeamCtrl(AType: String; AReserveNo: String; ATeeboxNo: Integer);

    function TeeboxDeviceCheck(ATeeboxNo: Integer; AType: String): Boolean;
    function TeeboxDeviceUseYN(ATeeboxNo: Integer; AType: String): Boolean;

    //타석정보 get
    function GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
    function GetTeeboxInfoIP(AMac: String): String;
    function GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
    function GetTeeboxFloorNm(ATeeboxNo: Integer): String;
    function GetReserveEndTime(ATeeboxNo: Integer): Integer; //타석종료 예상시간까지 초로 응답
    function GetReservePrepareEndTime(ATeeboxNo: Integer): Integer; //타석시작 예상시간까지 초로 응답
    function GetTeeboxInfoBeamType(ATeeboxNo: Integer): String;
    function GetTeeboxInfoBeamIP(ATeeboxNo: Integer): String;

    function SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
    function GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;

    function SetTeeboxReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
    function SetTeeboxReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
    function SetTeeboxReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String; //즉시배정

    function GetTeeboxNowReserveLastTime(ATeeboxNo: String): String; //2021-04-19 현시간 배정 예약시간 검증

    function SendTeeboxReserveStatus(ATeeboxNo: String): Boolean;

    property TeeboxLastNo: Integer read FTeeboxLastNo write FTeeboxLastNo;
    property TeeboxDevicNoCnt: Integer read FTeeboxDevicNoCnt write FTeeboxDevicNoCnt;
    property TeeboxStatusUse: Boolean read FTeeboxStatusUse write FTeeboxStatusUse;
    property TeeboxReserveUse: Boolean read FTeeboxReserveUse write FTeeboxReserveUse;
  end;

implementation

uses
  uGlobal, uFunction, JSON;

{ Tasuk }

constructor TTeebox.Create;
begin

  TeeboxLastNo := 0;
  FTeeboxDevicNoCnt := 0;
  FTeeboxStatusUse := False;
  FTeeboxReserveUse := False;

end;

destructor TTeebox.Destroy;
begin
  SetLength(FTeeboxInfoList, 0);

  inherited;
end;

procedure TTeebox.StartUp;
begin
  GetTeeboxListToApi;

  Global.ReserveList.StartUp;

  SetTeeboxStartUseStatus;
end;

function TTeebox.GetTeeboxListToApi: Boolean;
var
  nIndex, nTeeboxNo, nTeeboxCnt: Integer;

  jObjArr: TJsonArray;
  jObj, jObjSub: TJSONObject;

  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;
  //sMac, sIP: String;
begin
  Result := False;

  try

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode + '&search_date=' + FormatDateTime('YYYYMMDDHHNNSS', Now);
    sResult := Global.Api.GetErpApi(sJsonStr, 'K204_TeeBoxlist', Global.ADConfig.ApiUrl);

    //Global.Log.LogWrite(sResult);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'GetSeatListToApi Fail : ' + sResult;
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K204_TeeBoxlist : ' + sResultCd + ' / ' + sResultMsg;
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObjArr := jObj.GetValue('list') as TJsonArray;

    nTeeboxCnt := jObjArr.Size;
    SetLength(FTeeboxInfoList, nTeeboxCnt + 1);
    SetLength(FTeeboxDevicNoList, 0);

    for nIndex := 0 to nTeeboxCnt - 1 do
    begin
      jObjSub := jObjArr.Get(nIndex) as TJSONObject;
      nTeeboxNo := StrToInt(jObjSub.GetValue('teebox_no').Value);
      if FTeeboxLastNo < nTeeboxNo then
        FTeeboxLastNo := nTeeboxNo;

      FTeeboxInfoList[nTeeboxNo].TeeboxNo := StrToInt(jObjSub.GetValue('teebox_no').Value);
      FTeeboxInfoList[nTeeboxNo].TeeboxNm := jObjSub.GetValue('teebox_nm').Value;
      FTeeboxInfoList[nTeeboxNo].FloorCd := jObjSub.GetValue('floor_cd').Value;
      FTeeboxInfoList[nTeeboxNo].FloorNm := jObjSub.GetValue('floor_nm').Value;
      FTeeboxInfoList[nTeeboxNo].ZoneLeft := jObjSub.GetValue('zone_left').Value;
      FTeeboxInfoList[nTeeboxNo].ZoneDiv := jObjSub.GetValue('zone_div').Value;
      FTeeboxInfoList[nTeeboxNo].DeviceId := jObjSub.GetValue('device_id').Value;
      FTeeboxInfoList[nTeeboxNo].TapoMac := jObjSub.GetValue('iot_mac_adress').Value;
      FTeeboxInfoList[nTeeboxNo].TapoIP := jObjSub.GetValue('iot_ip_adress').Value;
      FTeeboxInfoList[nTeeboxNo].UseYn := jObjSub.GetValue('use_yn').Value;
      FTeeboxInfoList[nTeeboxNo].UseStatus := '0';

      //FTeeboxInfoList[nTeeboxNo].ComReceive := 'N'; //최초 1회 체크

      FTeeboxInfoList[nTeeboxNo].AgentIP_R := Global.ReadConfigAgentIP_R(nTeeboxNo);
      FTeeboxInfoList[nTeeboxNo].AgentIP_L := Global.ReadConfigAgentIP_L(nTeeboxNo);

      if Global.ADConfig.BeamProjectorUse = True then
      begin
        FTeeboxInfoList[nTeeboxNo].BeamType := Global.ReadConfigBeamType(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].BeamPW := Global.ReadConfigBeamPW(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].BeamIP := Global.ReadConfigBeamIP(nTeeboxNo);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;

  Result := True;
end;

function TTeebox.SetTeeboxStartUseStatus: Boolean;
var
  rTeeboxInfoList: TList<TTeeboxInfo>;
  rSeatUseReserveList: TList<TSeatUseReserve>;

  nDBMax: Integer;
  I, nTeeboxNo, nIndex: Integer;
  sStausChk, sBallBackStart: String;
  sStr, sPreDate: String;

  NextReserve: TNextReserve;
  nErpReserveNo: Integer;
begin
  rTeeboxInfoList := Global.XGolfDM.SeatSelect;

  sStausChk := '';
  nDBMax := 0;
  for I := 0 to rTeeboxInfoList.Count - 1 do
  begin
    nTeeboxNo := rTeeboxInfoList[I].TeeboxNo;

    if (FTeeboxInfoList[nTeeboxNo].TeeboxNm <> rTeeboxInfoList[I].TeeboxNm) or
       (FTeeboxInfoList[nTeeboxNo].FloorCd <> rTeeboxInfoList[I].FloorCd) or
       (FTeeboxInfoList[nTeeboxNo].ZoneLeft <> rTeeboxInfoList[I].ZoneLeft) or
       (FTeeboxInfoList[nTeeboxNo].ZoneDiv <> rTeeboxInfoList[I].ZoneDiv) or
       (FTeeboxInfoList[nTeeboxNo].DeviceId <> rTeeboxInfoList[I].DeviceId) or
       (FTeeboxInfoList[nTeeboxNo].UseYn <> rTeeboxInfoList[I].UseYn) then
    begin
      Global.XGolfDM.SeatUpdate(Global.ADConfig.StoreCode, FTeeboxInfoList[nTeeboxNo]);
    end;

    if rTeeboxInfoList[I].UseStatus = '8' then
    begin
      FTeeboxInfoList[nTeeboxNo].UseStatusPre := rTeeboxInfoList[I].UseStatus;
      FTeeboxInfoList[nTeeboxNo].UseStatus := rTeeboxInfoList[I].UseStatus;
    end
    else
    begin
      FTeeboxInfoList[nTeeboxNo].UseStatusPre := '0';
      FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
    end;

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '8' then
      TeeboxDeviceCheck(nTeeboxNo, '8');

    FTeeboxInfoList[nTeeboxNo].RemainMinPre := rTeeboxInfoList[I].RemainMinute;
    FTeeboxInfoList[nTeeboxNo].RemainMinute := rTeeboxInfoList[I].RemainMinute;

    //FTeeboxInfoList[nTeeboxNo].RemainBall := 0;

    FTeeboxInfoList[nTeeboxNo].HoldUse := False;
    FTeeboxInfoList[nTeeboxNo].HoldUse := rTeeboxInfoList[I].HoldUse;
    FTeeboxInfoList[nTeeboxNo].HoldUser := rTeeboxInfoList[I].HoldUser;

    if FTeeboxInfoList[nTeeboxNo].HoldUse = True then
    begin
      sStr := 'HoldUse : ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nIndex].TeeboxNm;
      Global.Log.LogWrite(sStr);
    end;

    if nTeeboxNo > nDBMax then
      nDBMax := nTeeboxNo;
  end;
  FreeAndNil(rTeeboxInfoList);

  if FTeeboxLastNo > nDBMax then
  begin
    for I := nDBMax + 1 to FTeeboxLastNo do
    begin
      Global.XGolfDM.SeatInsert(Global.ADConfig.StoreCode, FTeeboxInfoList[I]);
    end;
  end;

  //전날 배정 정리
  if FormatDateTime('hh', now) <= Copy(Global.Store.StartTime, 1, 2) then
  begin
    sPreDate := FormatDateTime('YYYYMMDD', now - 1);
    Global.XGolfDM.SeatUseStoreClose(Global.ADConfig.StoreCode, Global.ADConfig.UserId, sPreDate);
  end;

  //타석 현재사용중 또는 바로 배정할 대기목록
  rSeatUseReserveList := Global.XGolfDM.SeatUseAllReserveSelect(Global.ADConfig.StoreCode, '');
  for nIndex := 0 to rSeatUseReserveList.Count - 1 do
  begin
    nTeeboxNo := rSeatUseReserveList[nIndex].SeatNo;

    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo := rSeatUseReserveList[nIndex].ReserveNo;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin := rSeatUseReserveList[nIndex].UseMinute;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin := rSeatUseReserveList[nIndex].DelayMinute;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate := rSeatUseReserveList[nIndex].ReserveDate;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate) +
                                                        (((1/24)/60) * FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin);

    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := rSeatUseReserveList[nIndex].StartTime;
    if rSeatUseReserveList[nIndex].UseStatus = '1' then
    begin
      FTeeboxInfoList[nTeeboxNo].UseStatusPre := '1';
      FTeeboxInfoList[nTeeboxNo].UseStatus := '1';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.prepareYn := 'Y';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      Global.Log.LogReserveWrite('UseStatus = 1 '  + rSeatUseReserveList[nIndex].ReserveNo);
    end;

    sStr := '목록 : ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin);
    Global.Log.LogReserveWrite(sStr);

  end;
  FreeAndNil(rSeatUseReserveList);

  //타석 현재 사용중,대기중이 종료후 배정할 예약목록
  rSeatUseReserveList := Global.XGolfDM.SeatUseAllReserveSelectNext(Global.ADConfig.StoreCode);

  for nIndex := 0 to rSeatUseReserveList.Count - 1 do
  begin
    if rSeatUseReserveList[nIndex].SeatNo = 0 then
      Continue;

    nTeeboxNo := rSeatUseReserveList[nIndex].SeatNo;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = rSeatUseReserveList[nIndex].ReserveNo then
      Continue;

    Global.ReserveList.SetTeeboxReserveNext(rSeatUseReserveList[nIndex]);

    sStr := '예약목록 : ' + IntToStr(nTeeboxNo) + ' / ' + rSeatUseReserveList[nIndex].ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;

  FreeAndNil(rSeatUseReserveList);

  if (Global.Store.StartTime > Global.Store.EndTime) then
  begin

    if FormatDateTime('HH:NN', Now) < Global.Store.EndTime then
    begin
      Global.TcpServer.UseSeqNo := Global.XGolfDM.ReserveDateNo(Global.ADConfig.StoreCode, FormatDateTime('YYYYMMDD', Now - 1));
      Global.TcpServer.LastUseSeqNo := Global.TcpServer.UseSeqNo;
      Global.TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now - 1);
    end
    else
    begin
      Global.TcpServer.UseSeqNo := Global.XGolfDM.ReserveDateNo(Global.ADConfig.StoreCode, FormatDateTime('YYYYMMDD', Now));
      Global.TcpServer.LastUseSeqNo := Global.TcpServer.UseSeqNo;
      Global.TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now);
    end;

  end
  else
  begin
    Global.TcpServer.UseSeqNo := Global.XGolfDM.ReserveDateNo(Global.ADConfig.StoreCode, FormatDateTime('YYYYMMDD', Now));
    Global.TcpServer.LastUseSeqNo := Global.TcpServer.UseSeqNo;
    Global.TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now);
  end;

end;

function TTeebox.TeeboxDeviceCheck(ATeeboxNo: Integer; AType: String): Boolean;
begin
  FTeeboxInfoList[ATeeboxNo].UseStatus := AType;
end;

function TTeebox.TeeboxDeviceUseYN(ATeeboxNo: Integer; AType: String): Boolean;
begin
  FTeeboxInfoList[ATeeboxNo].UseYn := AType;
end;

function TTeebox.GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
begin
  Result := FTeeboxInfoList[ATeeboxNo];
end;

function TTeebox.GetTeeboxInfoIP(AMac: String): String;
var
  i: Integer;
begin
  for i := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[i].TapoMac = AMac then
    begin
      Result := FTeeboxInfoList[i].TapoIP;
      Break;
    end;
  end;
end;

function TTeebox.GetTeeboxInfoBeamType(ATeeboxNo: Integer): String;
begin
  Result := FTeeboxInfoList[ATeeboxNo].BeamType;
end;

function TTeebox.GetTeeboxInfoBeamIP(ATeeboxNo: Integer): String;
begin
  Result := FTeeboxInfoList[ATeeboxNo].BeamIP;
end;

function TTeebox.GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
var
  i: Integer;
begin
  for i := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[i].TeeboxNm = ATeeboxNm then
    begin
      Result := FTeeboxInfoList[i];
      Break;
    end;
  end;
end;

function TTeebox.SetTeeboxReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
var
  nSeatNo: Integer;
  sStr: String;
begin

  nSeatNo := ASeatReserveInfo.SeatNo;

  if nSeatNo > FTeeboxLastNo then
  begin
    sStr := 'SeatNo error : ' + IntToStr(nSeatNo);
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo = ASeatReserveInfo.ReserveNo then
  begin
    sStr := '동일예약건 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
          ASeatReserveInfo.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo := ASeatReserveInfo.ReserveNo;
  FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin := ASeatReserveInfo.UseMinute;
  FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin := ASeatReserveInfo.DelayMinute;
  if FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin < 0 then
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin := 0;

  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate := ASeatReserveInfo.ReserveDate;
  FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := '';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate := '';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareYn := 'N';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'N';

  if ASeatReserveInfo.ReserveDate <= formatdatetime('YYYYMMDDhhnnss', Now) then
  begin
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := Now + (((1/24)/60) * FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin);
  end
  else
  begin
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := ASeatReserveInfo.ReserveDate;
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate) +
                                                         (((1/24)/60) * FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin);
  end;

  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate := '';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.ChangeMin := 0;
  FTeeboxInfoList[nSeatNo].UseCancel := 'N';
  FTeeboxInfoList[nSeatNo].UseClose := 'N';

  FTeeboxInfoList[nSeatNo].BeamStartDT := '';
  FTeeboxInfoList[nSeatNo].BeamReCtl := False;
end;

function TTeebox.SetTeeboxReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
var
  nTeeboxNo, nCtlMin, nCtlSecond, nVXMin: Integer;
  sStr: String;
begin
  Result:= False;

  nTeeboxNo := ASeatUseInfo.SeatNo;
  if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> ASeatUseInfo.ReserveNo then
  begin
    Global.ReserveList.SetTeeboxReserveNextChange(nTeeboxNo, ASeatUseInfo);
    Exit;
  end;

  //대기시간/배정시간 변경 체크
  if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin = ASeatUseInfo.PrepareMin) and
     (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin = ASeatUseInfo.AssignMin) then
  begin
    //변경된 내용 없음
    Exit;
  end;

  if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N' then
  begin
    sStr := '예약배정시간변경 no: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
            '대기시간' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin) + ' -> ' +
            IntToStr(ASeatUseInfo.PrepareMin) + ' / ' +
            '배정시간' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' -> ' +
            IntToStr(ASeatUseInfo.AssignMin);

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin <> ASeatUseInfo.AssignMin then
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin := ASeatUseInfo.AssignMin;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin <> ASeatUseInfo.PrepareMin then
    begin
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate) +
                                                          (((1/24)/60) * ASeatUseInfo.PrepareMin);
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin := ASeatUseInfo.PrepareMin;
    end;
  end
  else
  begin
    //배정된후 배정시간 변경만 체크
    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin <> ASeatUseInfo.AssignMin then
    begin
      if ASeatUseInfo.AssignMin < 2 then
        ASeatUseInfo.AssignMin := 2; // 0 으로 변경시 대기시간 상태 적용됨

      //배정시간변경 위해 제어배열에 등록
      nCtlMin := FTeeboxInfoList[nTeeboxNo].RemainMinute + (ASeatUseInfo.AssignMin - FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin);
      nVXMin := ASeatUseInfo.AssignMin - FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;

      sStr := '배정시간변경 no: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              '배정시간' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' -> ' +
              IntToStr(ASeatUseInfo.AssignMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute) + ' -> ' +
              IntToStr(nCtlMin);

      //FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ChangeMin := nCtlMin;
      FTeeboxInfoList[nTeeboxNo].RemainMinute := nCtlMin;
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin := ASeatUseInfo.AssignMin;

      nCtlSecond := GetReserveEndTime(nTeeboxNo);

      if nVXMin > 0 then
        SetTeeboxVXCtrl('VXadd', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, nVXMin);

      FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'C';
      FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '0';
      SetTeeboxCtrl('Tchange', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, nCtlMin, nCtlSecond);
    end;

  end;

  Global.Log.LogReserveWrite(sStr);

  Result:= True;
end;

function TTeebox.SetTeeboxReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    //예약대기, 배정된 타석이 아님
    Global.ReserveList.SetTeeboxReserveNextCancel(ATeeboxNo, AReserveNo);
    Exit;
  end;

  //취소위해 제어배열에 등록
  FTeeboxInfoList[ATeeboxNo].UseCancel := 'Y';
  FTeeboxInfoList[ATeeboxNo].RemainMinute := 0;

  sStr := 'Cancel no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

function TTeebox.SetTeeboxReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo <> AReserveNo then
    Exit;

  FTeeboxInfoList[ATeeboxNo].UseClose := 'Y';
  FTeeboxInfoList[ATeeboxNo].RemainMinute := 0;

  sStr := 'Close no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

// 즉시배정
function TTeebox.SetTeeboxReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sStr, sResult: String;
begin
  Result := '';

  if FTeeboxInfoList[ATeeboxNo].UseStatus <> '0' then
  begin
    Result := '사용중인 타석입니다.';
    Exit;
  end;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo = AReserveNo then
  begin
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime := Now;

    sStr := 'Start Now 대기 no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end
  else
  begin
    sResult := Global.ReserveList.SetTeeboxReserveNextStartNow(ATeeboxNo, AReserveNo);
    if sResult <> 'Success' then
    begin
      Result := sResult;
      Exit;
    end;
  end;

  Result := 'Success';
end;


procedure TTeebox.TeeboxStatusChk;
var
  nTeeboxNo: Integer;
begin

  for nTeeboxNo := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].UseStatus <> '8' then //점검
    begin
      if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
        FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
      else
        FTeeboxInfoList[nTeeboxNo].UseStatus := '1';
    end;

    // DB저장: 타석기상태(시간,상태,볼수)
    if FTeeboxInfoList[nTeeboxNo].RemainMinPre <> FTeeboxInfoList[nTeeboxNo].RemainMinute then
    begin
      Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].UseStatus);
    end;

    FTeeboxInfoList[nTeeboxNo].RemainMinPre := FTeeboxInfoList[nTeeboxNo].RemainMinute;
  end;

  Sleep(10);
end;

procedure TTeebox.TeeboxReserveChk;
var
  nTeeboxNo: Integer;
  sStr: string;
  nNN, nTmTemp, nSecond: Integer;
  tmTempS, tmTempE: TDateTime;
  sEndDateTemp: String;
begin
  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sStr := 'SeatReserveUse TeeboxReserveChkAD!';
    Global.Log.LogReserveDelayWrite(sStr);

    sleep(50);
  end;
  FTeeboxStatusUse := True;

  for nTeeboxNo := 1 to TeeboxLastNo do
  begin

    if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
      Continue;

    //타석기 배정상태 확인
    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = '' then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Continue;

    //취소, 종료 API 요청시 종료 제어함
    if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') or (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') then //취소인경우 K410_TeeBoxReserved 통해 ERP 전송
    begin
      if FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y' then
      begin
        if (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) and
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') and
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') then
        begin
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);

          sStr := '등록전취소 no: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo;
          Global.Log.LogReserveWrite(sStr);
        end;
      end;

      if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '' then
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '배정종료 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        if (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') then
        begin
          // DB/Erp저장: 종료시간
          Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, '2');
        end;

        SetTeeboxVXCtrl('VXend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, 0);
        SetTeeboxBeamCtrl('Bend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo);

        FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'E';
        FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '0';
        SetTeeboxCtrl('Tend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, 0, 0);

        //FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
        FTeeboxInfoList[nTeeboxNo].RemainMinute := 0;
      end;
    end;

    //배정시작
    if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime > Now) and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.prepareYn = 'N') then
    begin
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.prepareYn := 'Y';

      sStr := '배정시작 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate;
      Global.Log.LogReserveWrite(sStr);

      //배정위해 제어배열에 등록
      SetTeeboxVXCtrl('VXstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin));

      FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'D';
      FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '0';
      nSecond := GetReservePrepareEndTime(nTeeboxNo);
      SetTeeboxCtrl('Tprepare', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin, nSecond);

      SetTeeboxBeamCtrl('Bstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo );
    end;

    //배정시작전이고 대기시간을 지났으면
    if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime < Now) then
    begin

      FTeeboxInfoList[nTeeboxNo].RemainMinute := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;
      //FTeeboxInfoList[nTeeboxNo].UseStatus := '1';

      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now); //2021-06-11

      sStr := '배정구동 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
      Global.Log.LogReserveWrite(sStr);

      //즉시배정등에 의해 대기가 없을 경우
      if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.prepareYn = 'N') then
        SetTeeboxVXCtrl('VXstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin));

      // DB저장, 0분 표시되는 경우 있음.
      if FTeeboxInfoList[nTeeboxNo].UseStatus <> '8' then //점검
        Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, '1');

      //예상종료시간
      tmTempE := IncMinute(Now, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin);
      sEndDateTemp := formatdatetime('YYYYMMDDhhnnss', tmTempE);

      // DB/Erp저장: 시작시간
      Global.TcpServer.SetApiTeeBoxReg(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate, IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin), sEndDateTemp);

      //배정위해 제어배열에 등록
      FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'S';
      FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '0';
      nSecond := GetReserveEndTime(nTeeboxNo);
      SetTeeboxCtrl('Tstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, nSecond);

      SetTeeboxBeamCtrl('Bstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo );
    end;

    //시간계산
    if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate <> '') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'Y') then
    begin

      tmTempS := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);
      nNN := MinutesBetween(now, tmTempS);

      nTmTemp := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin - nNN;
      if nTmTemp < 0 then
        nTmTemp := 0;
      FTeeboxInfoList[nTeeboxNo].RemainMinute := nTmTemp;

      if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '배정종료 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        // DB/Erp저장: 종료시간
        Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, '2');

        //FTeeboxInfoList[nTeeboxNo].UseStatus := '0';

        SetTeeboxVXCtrl('VXend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, 0);

        FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'E';
        FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '0';
        SetTeeboxCtrl('Tend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, 0, 0);

        SetTeeboxBeamCtrl('Bend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo);
      end;

    end;

  end;

  Sleep(10);
  FTeeboxStatusUse := False;
end;

procedure TTeebox.TeeboxAgentChk;
var
  nTeeboxNo, nMin, nSecond: Integer;
begin

  for nTeeboxNo := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
      Continue;

    //Agent에 1회 재시도,  시간이 진행되었을것으로 판단, 분 다시계산
    if FTeeboxInfoList[nTeeboxNo].AgentCtlYn = '0' then
    begin
      if FTeeboxInfoList[nTeeboxNo].AgentCtlType = 'D' then
      begin
        FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '2';

        nSecond := GetReservePrepareEndTime(nTeeboxNo);
        if (nSecond mod 60) > 0 then
          nMin := (nSecond div 60) + 1
        else
          nMin := (nSecond div 60);

        SetTeeboxCtrl('Tprepare', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, nMin, nSecond);
      end;

      if FTeeboxInfoList[nTeeboxNo].AgentCtlType = 'S' then
      begin
        FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '2';
        nSecond := GetReserveEndTime(nTeeboxNo);
        SetTeeboxCtrl('Tstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, nSecond);
      end;

      if FTeeboxInfoList[nTeeboxNo].AgentCtlType = 'C' then
      begin
        FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '2';
        nSecond := GetReserveEndTime(nTeeboxNo);
        SetTeeboxCtrl('Tchange', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, nSecond);
      end;

      if FTeeboxInfoList[nTeeboxNo].AgentCtlType = 'E' then
      begin
        FTeeboxInfoList[nTeeboxNo].AgentCtlYn := '2';
        SetTeeboxCtrl('Tend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, nTeeboxNo, 0, 0);
      end;

    end;

  end;

  Sleep(10);
end;

procedure TTeebox.TeeboxTapoOnOff;
var
  nTeeboxNo: Integer;
  sStr: String;
begin

  for nTeeboxNo := 1 to FTeeboxLastNo do
  begin

    if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].TapoIP = EmptyStr then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].RemainMinute > 0 then
    begin
      if FTeeboxInfoList[nTeeboxNo].TapoOnOff <> 'On' then
      begin
        sStr := 'RemainMinute > 0 : Off -> On / No: ' + IntToStr(nTeeboxNo);
        Global.Log.LogCtrlWrite(sStr);

        Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[nTeeboxNo].TapoIP, True, False);
      end;
    end
    else
    begin
      if FTeeboxInfoList[nTeeboxNo].TapoOnOff <> 'Off' then
      begin
        sStr := 'RemainMinute =< 0 : On -> Off / No: ' + IntToStr(nTeeboxNo);
        Global.Log.LogCtrlWrite(sStr);

        Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[nTeeboxNo].TapoIP, False, False);
      end;
    end;

  end;

  Sleep(10);
end;

(*
procedure TTeebox.TeeboxTapoXGMSTatus;
var
  nTeeboxNo: Integer;
  sTeeboxNo: String;
  MainJson, jObjSub: TJSONObject;
  ResultStr: string;
begin
  //ResultStr := '{"1":{"ip":"192.168.0.100","nickname":"1","device_on":false},"2":{"ip":"192.168.0.101","nickname":"2","device_on":false}}';
  ResultStr := Global.Api.GetPlugApi;

  if (Copy(ResultStr, 1, 1) <> '{') or (Copy(ResultStr, Length(ResultStr), 1) <> '}') then
  begin
    Global.Log.LogCtrlWrite(ResultStr);
    Exit;
  end;

  try

    MainJson := TJSONObject.ParseJSONValue(ResultStr) as TJSONObject;

    for nTeeboxNo := 1 to FTeeboxLastNo do
    begin

      if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
        Continue;

      sTeeboxNo := IntToStr(nTeeboxNo);
      jObjSub := MainJson.GetValue(sTeeboxNo) as TJSONObject;

      if jObjSub = nil then
        Continue;

      if jObjSub.GetValue('device_on').Value = 'false' then
        FTeeboxInfoList[nTeeboxNo].TapoOnOff := 'off'
      else
        FTeeboxInfoList[nTeeboxNo].TapoOnOff := 'on';

      FTeeboxInfoList[nTeeboxNo].TapoError := False;

      if FTeeboxInfoList[nTeeboxNo].RemainMinute > 0 then
      begin
        if FTeeboxInfoList[nTeeboxNo].TapoOnOff <> 'on' then
          FTeeboxInfoList[nTeeboxNo].TapoError := True;
      end
      else
      begin
        if FTeeboxInfoList[nTeeboxNo].TapoOnOff <> 'off' then
          FTeeboxInfoList[nTeeboxNo].TapoError := True;
      end;

    end;

  finally
    FreeAndNil(MainJson);
  end;

end;
*)

function TTeebox.GetTeeboxFloorNm(ATeeboxNo: Integer): String;
begin
  Result := FTeeboxInfoList[ATeeboxNo].FloorNm;
end;

function TTeebox.GetReserveEndTime(ATeeboxNo: Integer): Integer;
var
  tmStartTime, tmEndTime: TDateTime;
  nSecond: Integer;
begin
  nSecond := 0;

  tmStartTime := DateStrToDateTime3(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveStartDate);
  tmEndTime := IncMinute(tmStartTime, FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin);

  nSecond := SecondsBetween(now, tmEndTime);
  Result := nSecond;
end;

function TTeebox.GetReservePrepareEndTime(ATeeboxNo: Integer): Integer;
var
  tmEndTime: TDateTime;
  nSecond: Integer;
begin
  nSecond := 0;
  tmEndTime := FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime;

  nSecond := SecondsBetween(now, tmEndTime);
  Result := nSecond;
end;

procedure TTeebox.SetTeeboxIP(AMac, AIP: String);
var
  nTeeboxNo: integer;
begin
  for nTeeboxNo := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].TapoMac = AMac then
    begin
      FTeeboxInfoList[nTeeboxNo].TapoIP :=  AIP;
        Break;
    end;
  end;
end;

procedure TTeebox.SetTeeboxOnOff(AIP, AOnOff: String);
var
  nTeeboxNo: integer;
begin
  for nTeeboxNo := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].TapoIP = AIP then
    begin
      FTeeboxInfoList[nTeeboxNo].TapoOnOff := AOnOff;
      Break;
    end;

  end;
end;

procedure TTeebox.SetTeeboxAgentCtlYN(AIP, ARecive: String);
var
  nTeeboxNo: integer;
  jObj: TJSONObject;
  sApiId, sTeeboxNo, sLeftHanded, sStr: String;
begin
  try
    //{"api_id": "9002", "teebox_no": "1", "reserve_no": "202110240002", "result_cd": "0000", "result_msg": "????? ?? ?????."}
    jObj := TJSONObject.ParseJSONValue(ARecive) as TJSONObject;
    sApiId := jObj.GetValue('api_id').Value;
    sTeeboxNo := jObj.GetValue('teebox_no').Value;
    sLeftHanded := '0';
    if jObj.FindValue('left_handed') <> nil then
      sLeftHanded := jObj.GetValue('left_handed').Value;

    if sApiId = '9901' then //상태체크
      Exit;

    if (Trim(sApiId) = EmptyStr) or (Trim(sTeeboxNo) = EmptyStr) then
    begin
      Global.Log.LogWrite('Fail: ' + ARecive);
      Exit;
    end;

    nTeeboxNo := StrToInt(sTeeboxNo);

    //9001 준비 'prepare'
    //9002 시작 'start', 'change'
    //9003 종료 'end'

    if Global.ADConfig.AgentSendUse <> 'Y' then
      FTeeboxInfoList[nTeeboxNo].AgentCtlYN := '1';
    if sLeftHanded = '0' then //우
    begin
      if FTeeboxInfoList[nTeeboxNo].AgentIP_R <> AIP then
      begin
        //sStr := 'IP 변경: ' + FTeeboxInfoList[nTeeboxNo].AgentIP_R + ' -> ' + AIP;
        sStr := 'IP 변경(우) - No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].AgentIP_R + ' -> ' + AIP;
        Global.Log.LogAgentServerRead(sStr);

        FTeeboxInfoList[nTeeboxNo].AgentIP_R := AIP;
        Global.WriteConfigAgentIP_R(FTeeboxInfoList[nTeeboxNo].TeeboxNo, FTeeboxInfoList[nTeeboxNo].AgentIP_R);
      end;
    end
    else
    begin
      if FTeeboxInfoList[nTeeboxNo].AgentIP_L <> AIP then
      begin
        sStr := 'IP 변경(좌) - No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].AgentIP_L + ' -> ' + AIP;
        Global.Log.LogAgentServerRead(sStr);

        FTeeboxInfoList[nTeeboxNo].AgentIP_L := AIP;
        Global.WriteConfigAgentIP_L(FTeeboxInfoList[nTeeboxNo].TeeboxNo, FTeeboxInfoList[nTeeboxNo].AgentIP_L);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

procedure TTeebox.SetTeeboxCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin, ASecond: Integer);
var
  sLogMsg, sUrl: String;
  sSendStr, sSendTapo: AnsiString;
  i: Integer;
begin
  if (AType <> 'Tsetting') and (ATeeboxNo = 0) then
    Exit;

  sLogMsg := AType + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm+ ' / ' + AReserveNo + ' / ' + IntToStr(AMin) + ' / ' + IntToStr(ASecond);
  Global.Log.LogCtrlWrite(sLogMsg);

  //9001 준비 'prepare'
  //9002 시작 'start', 'change'
  //9003 종료 'end'
  //9005 설정 'setting'

  if AType = 'Tprepare' then
  begin
    sSendStr := '{"api_id":9001,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "prepare_min":"' + IntToStr(AMin) + '",' +
                ' "prepare_second":' + IntToStr(ASecond) + '}';
  end;

  if (AType = 'Tstart') then
  begin
    sSendStr := '{"api_id":9002,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "assign_min":"' + IntToStr(AMin) + '",' +
                ' "assign_second":' + IntToStr(ASecond) + '}';
  end;

  if (AType = 'Tchange') then
  begin
    sSendStr := '{"api_id":9006,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "assign_min":"' + IntToStr(AMin) + '",' +
                ' "assign_second":' + IntToStr(ASecond) + '}';
  end;

  if AType = 'Tend' then
  begin
    sSendStr := '{"api_id":9003,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '"}';
  end;

  if AType = 'Tsetting' then
  begin
    sSendStr := '{"api_id":9005,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "method":' + IntToStr(AMin) + '}';
  end;

  if Global.ADConfig.AgentSendUse = 'Y' then
  begin
    if ATeeboxNo = 0 then
    begin
      for i := 1 to TeeboxLastNo do
      begin
        if FTeeboxInfoList[i].UseYn <> 'Y' then
          Continue;

        if (FTeeboxInfoList[i].AgentIP_R = '') and (FTeeboxInfoList[i].AgentIP_L = '') then
        begin
          Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[i].TeeboxNo));
        end
        else
        begin
          //sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[i].AgentIP_R, sSendStr);
          //Global.Log.LogCtrlWrite(FTeeboxInfoList[i].AgentIP_R + ' : ' + sLogMsg);

          if FTeeboxInfoList[i].AgentIP_R <> '' then
          begin
            //Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[i].AgentIP_R + ' : ' + sSendStr);
            sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[i].AgentIP_R, sSendStr);
            Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[i].AgentIP_R + ' : ' + sLogMsg);
          end;

          if FTeeboxInfoList[i].AgentIP_L <> '' then
          begin
            //Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[i].AgentIP_L + ' : ' + sSendStr);
            sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[i].AgentIP_L, sSendStr);
            Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[i].AgentIP_L + ' : ' + sLogMsg);
          end;
        end;

        FTeeboxInfoList[i].AgentCtlYN := '1';
      end;
    end
    else
    begin
      //sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[ATeeboxNo].AgentIP_R, sSendStr);
      //Global.Log.LogCtrlWrite(FTeeboxInfoList[ATeeboxNo].AgentIP_R + ' : ' + sLogMsg);

      if (FTeeboxInfoList[ATeeboxNo].AgentIP_R = '') and (FTeeboxInfoList[ATeeboxNo].AgentIP_L = '') then
      begin
        Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo));
      end
      else
      begin
        if FTeeboxInfoList[ATeeboxNo].AgentIP_R <> '' then
        begin
          //Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sSendStr);
          sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[ATeeboxNo].AgentIP_R, sSendStr);
          Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[ATeeboxNo].AgentIP_R + ' : ' + sLogMsg);
        end;

        if FTeeboxInfoList[ATeeboxNo].AgentIP_L <> '' then
        begin
          //Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sSendStr);
          sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[ATeeboxNo].AgentIP_L, sSendStr);
          Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[ATeeboxNo].AgentIP_L + ' : ' + sLogMsg);
        end;
      end;

      FTeeboxInfoList[ATeeboxNo].AgentCtlYN := '1';
    end;
  end
  else
  begin
    Global.TcpAgentServer.BroadcastMessage(sSendStr);
  end;

  if ATeeboxNo = 0 then
    Exit;

  if FTeeboxInfoList[ATeeboxNo].AgentCtlYN = '2' then
    Exit;

  if Global.ADConfig.XGMTapoUse = 'Y' then
  begin
    (* 2023-01-26 xgm tapo 제어 제외
    //XGM Tapo 제어
    if (AType = 'Tstart') or (AType = 'Tend') then
    begin
      sSendTapo := ''; //'{"nickname": "1"}'
      sSendTapo := '{"nickname":"' + IntToStr(ATeeboxNo) + '"}';

      if (AType = 'Tstart') then
        sUrl := 'http://localhost:8000/plug/on'
      else if (AType = 'Tend') then
        sUrl := 'http://localhost:8000/plug/off';

      sLogMsg := 'Tapo : ' + AType + ' / ' + sUrl + ' / ' + IntToStr(ATeeboxNo) + ' / ' + AReserveNo + ' / ' + sSendTapo;
      Global.Log.LogCtrlWrite(sLogMsg);

      sLogMsg := Global.Api.PostPlugApi(sUrl, sSendTapo);
      Global.Log.LogCtrlWrite(sLogMsg);

      //상태요청 주석처리. 제어성공여부 확인필요
      FTeeboxInfoList[ATeeboxNo].TapoError := False;
      if (AType = 'Tstart') then
        FTeeboxInfoList[ATeeboxNo].TapoOnOff := 'on'
      else if (AType = 'Tend') then
        FTeeboxInfoList[ATeeboxNo].TapoOnOff := 'off';
    end;
    *)
  end
  else
  begin
    //Tapo 직접제어
    if FTeeboxInfoList[ATeeboxNo].TapoIP = EmptyStr then
    begin
      sLogMsg := 'IP null';
      Global.Log.LogCtrlWrite(sLogMsg);
    end
    else
    begin
      if (AType = 'Tstart') then
      begin
        Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[ATeeboxNo].TapoIP, True, False)
      end
      else if (AType = 'Tend') then
      begin
        Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[ATeeboxNo].TapoIP, False, False);
      end;
    end;
  end;

end;

procedure TTeebox.SetTeeboxVXCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin: Integer);
var
  sLogMsg, sUrl: String;
  sSendStr: AnsiString;
begin
  if Global.ADConfig.VXUse <> 'Y' then
    Exit;

  // '/room/status' : 상태  {  "roomNum": 24 // 방정보}
  // '/room/start'  : 시작  {  "roomNum": 23,  "mtime": 60 }
  // '/room/stop'   : 종료  {  "roomNum": 23 }
  // '/room/add'    : 추가  {  "roomNum": 23,  "mtime": 60 }

  sUrl := 'http://localhost:8000';
  if (AType = 'VXstart') then
  begin
    sUrl := sUrl + '/room/start';
    sSendStr := '{"roomNum":' + IntToStr(ATeeboxNo) + ',' +
                ' "mtime":' + IntToStr(AMin) + '}';
  end;

  if (AType = 'VXadd') then
  begin
    sUrl := sUrl + '/room/add';
    sSendStr := '{"roomNum":' + IntToStr(ATeeboxNo) + ',' +
                ' "mtime":' + IntToStr(AMin) + '}';
  end;

  if AType = 'VXend' then
  begin
    sUrl := sUrl + '/room/stop';
    sSendStr := '{"roomNum":' + IntToStr(ATeeboxNo) + '}';
  end;

  sLogMsg := AType + IntToStr(ATeeboxNo) + ' / ' + AReserveNo + ' / ' + sUrl + ' / ' + sSendStr;
  Global.Log.LogCtrlWrite(sLogMsg);

  sLogMsg := Global.Api.PostVXApi(sUrl, sSendStr);
  Global.Log.LogCtrlWrite(sLogMsg);

end;


procedure TTeebox.SetTeeboxBeamCtrl(AType: String; AReserveNo: String; ATeeboxNo: Integer);
var
  sLogMsg: String;
  //nIndex: Integer;
  bResult: Boolean;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  //nIndex := GetTeeboxInfoIndex(ATeeboxNo);

  if FTeeboxInfoList[ATeeboxNo].BeamIP = EmptyStr then
  begin
    sLogMsg := 'Beam IP null';
    Global.Log.LogCtrlWrite(sLogMsg);
    Exit;
  end;

  sLogMsg := AType + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' + AReserveNo + ' / ' + FTeeboxInfoList[ATeeboxNo].BeamIP;
  Global.Log.LogCtrlWrite(sLogMsg);

  if (AType = 'Bstart') then
  begin
    if FTeeboxInfoList[ATeeboxNo].BeamType = '0' then
    begin
      bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[ATeeboxNo].BeamIP, FTeeboxInfoList[ATeeboxNo].BeamPW, 1);
      if bResult = False then
      begin
        //통신연결시 disconnect 되는 경우 있음
        sleep(100);
        bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[ATeeboxNo].BeamIP, FTeeboxInfoList[ATeeboxNo].BeamPW, 1);
      end;
    end
    else if FTeeboxInfoList[ATeeboxNo].BeamType = '1' then
    begin
      Global.Api.PostBeamHitachiApi(FTeeboxInfoList[ATeeboxNo].BeamIP, 1);
    end;

    FTeeboxInfoList[ATeeboxNo].BeamEndDT := '';
    FTeeboxInfoList[ATeeboxNo].BeamStartDT := formatdatetime('YYYYMMDDhhnnss', Now);
    FTeeboxInfoList[ATeeboxNo].BeamReCtl := False;
  end
  else if AType = 'Bend' then
  begin
    FTeeboxInfoList[ATeeboxNo].BeamEndDT := formatdatetime('YYYYMMDDhhnnss', Now);
  end;

end;

procedure TTeebox.SendBeamEnd;
var
  sLogMsg: String;
  nTeeboxNo, nNN: Integer;
  bResult: Boolean;
  tmTemp: TDateTime;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  for nTeeboxNo := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].RemainMinute > 0 then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].BeamEndDT = EmptyStr then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].BeamIP = EmptyStr then
      Continue;

    tmTemp := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].BeamEndDT);
    nNN := MinutesBetween(now, tmTemp);

    if nNN > 5 then
    begin
      if FTeeboxInfoList[nTeeboxNo].BeamType = '0' then
      begin
        bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[nTeeboxNo].BeamIP, FTeeboxInfoList[nTeeboxNo].BeamPW, 0);
        if bResult = False then
        begin
          //통신연결시 disconnect 되는 경우 있음
          sleep(100);
          bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[nTeeboxNo].BeamIP, FTeeboxInfoList[nTeeboxNo].BeamPW, 0);
        end;
      end
      else if FTeeboxInfoList[nTeeboxNo].BeamType = '1' then
      begin
        Global.Api.PostBeamHitachiApi(FTeeboxInfoList[nTeeboxNo].BeamIP, 0);
      end;

      FTeeboxInfoList[nTeeboxNo].BeamEndDT := '';

      sLogMsg := 'Bend 5min / Nm:' + FTeeboxInfoList[nTeeboxNo].TeeboxNm;
      Global.Log.LogCtrlWrite(sLogMsg);
    end;

  end;

end;

procedure TTeebox.SendBeamStartReCtl;
var
  sLogMsg: String;
  nTeeboxNo, nSS: Integer;
  bResult: Boolean;
  tmTemp: TDateTime;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  for nTeeboxNo := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].BeamIP = EmptyStr then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].BeamStartDT = EmptyStr then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].BeamReCtl = True then
      Continue;

    tmTemp := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].BeamStartDT);
    nSS := SecondsBetween(now, tmTemp);

    if nSS > 30 then
    begin
      if FTeeboxInfoList[nTeeboxNo].BeamType = '0' then
      begin
        bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[nTeeboxNo].BeamIP, FTeeboxInfoList[nTeeboxNo].BeamPW, 1);
        if bResult = False then
        begin
          //통신연결시 disconnect 되는 경우 있음
          sleep(100);
          bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[nTeeboxNo].BeamIP, FTeeboxInfoList[nTeeboxNo].BeamPW, 1);
        end;
      end
      else if FTeeboxInfoList[nTeeboxNo].BeamType = '1' then
      begin
        Global.Api.PostBeamHitachiApi(FTeeboxInfoList[nTeeboxNo].BeamIP, 1);
      end;

      FTeeboxInfoList[nTeeboxNo].BeamReCtl := True;

      sLogMsg := 'Bstart rectr 30Second / Nm:' + FTeeboxInfoList[nTeeboxNo].TeeboxNm;
      Global.Log.LogCtrlWrite(sLogMsg);
    end;

  end;

end;

procedure TTeebox.TeeboxReserveNextChk;
var
  nTeeboxNo: Integer;
  sLog: String;
begin

  try

    for nTeeboxNo := 1 to TeeboxLastNo do
    begin

      if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
        Continue;

      if (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) or (FTeeboxInfoList[nTeeboxNo].UseStatus <> '0') then
        Continue;

      if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
        Continue;

      if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate <> '') and (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') then
        Continue;

      Global.ReserveList.ReserveListNextChk(nTeeboxNo);
    end;

  except
    on e: Exception do
    begin
       sLog := 'SeatReserveNextChk Exception : ' + e.Message;
       Global.Log.LogReserveWrite(sLog);
    end;
  end;

end;

function TTeebox.SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
var
  nTeeboxNo: Integer;
begin
  if ATeeboxNo = '-1' then
    Exit;

  nTeeboxNo := StrToInt(ATeeboxNo);
  FTeeboxInfoList[nTeeboxNo].HoldUse := AUse;
  FTeeboxInfoList[nTeeboxNo].HoldUser := AUserId;
end;

function TTeebox.GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;
var
  nTeeboxNo: Integer;
begin
  nTeeboxNo := StrToInt(ATeeboxNo);

  //적용: Insert
  if AType = 'Insert' then
  begin
    if FTeeboxInfoList[nTeeboxNo].HoldUser = AUserId then
      Result := False //홀드등록자가 동일하면
    else
      Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end
  else
  begin
    Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end;

end;

function TTeebox.GetTeeboxNowReserveLastTime(ATeeboxNo: String): String; //현시간 예약시간 검증
var
  nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sStartDate, sStr, sLog: String;
  UseMin, nCnt: Integer;
begin
  sStr := '0';

  nTeeboxNo := StrToInt(ATeeboxNo);
  nCnt := Global.ReserveList.GetTeeboxReserveNextListCnt(nTeeboxNo);
  if nCnt = 0 then
  begin
    sStartDate := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
    UseMin := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin;

    ReserveTm := DateStrToDateTime3(sStartDate) + ( ((1/24)/60) * UseMin );
    sStr := FormatDateTime('YYYYMMDDhhnnss', ReserveTm);
  end
  else
  begin
    sStr := Global.ReserveList.GetTeeboxReserveLastTime(ATeeboxNo);
    sLog := 'GetTeeboxReserveLastTime : ' + ATeeboxNo;
    Global.Log.LogErpApiWrite(sLog);
  end;

  Result := sStr;
end;

function TTeebox.SendTeeboxReserveStatus(ATeeboxNo: String): Boolean;
var
  jObj: TJSONObject;
  sApiId, sTeeboxNo, sStatus, sMin, sSecond: String;
  nTeeboxNo, nSecond, nMin: integer;
  sSendData: AnsiString;
  //nIndex: Integer;
  sLogMsg: String;
begin
  Result := False;

  if Trim(ATeeboxNo) = EmptyStr then
  begin
    //sResult := '{"result_cd":"AD03","result_msg":"Api Fail"}';
    Exit;
  end;

  sTeeboxNo := ATeeboxNo;
  nTeeboxNo := StrToInt(ATeeboxNo);

  if (FTeeboxInfoList[nTeeboxNo].AgentIP_R = '') and (FTeeboxInfoList[nTeeboxNo].AgentIP_L = '') then
  begin
    Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo));
    Exit;
  end;

  //0: 유휴상태, 1: 준비, 2:사용중
  sStatus := '0';
  sMin := '0';
  sSecond := '0';
  if FTeeboxInfoList[nTeeboxNo].AgentCtlType = 'D' then
  begin
    sStatus := '1';
    //sMin := IntToStr(rTeeboxInfo.TeeboxReserve.PrepareMin);

    nSecond := GetReservePrepareEndTime(nTeeboxNo);
    sSecond := IntToStr(nSecond);

    if (nSecond mod 60) > 0 then
      nMin := (nSecond div 60) + 1
    else
      nMin := (nSecond div 60);

    sMin := IntToStr(nMin);
  end
  else if FTeeboxInfoList[nTeeboxNo].RemainMinute > 0 then
  begin
    sStatus := '2';
    sMin := IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute);

    nSecond := GetReserveEndTime(nTeeboxNo);
    sSecond := IntToStr(nSecond);
  end;

  sSendData := '{' +
               '"api_id": 9004,' +
               '"teebox_no": ' + sTeeboxNo + ',' +
               '"reserve_no": "' + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + '",' +
               '"teebox_status": ' + sStatus + ',' +
               '"remain_min": ' + sMin + ',' +
               '"remain_second": ' + sSecond + ',' +
               '"result_cd": "0000",' +
               '"result_msg": "정상적으로 처리 되었습니다."' +
             '}';

  if FTeeboxInfoList[nTeeboxNo].AgentIP_R <> '' then
  begin
    //Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sSendData);
    sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[nTeeboxNo].AgentIP_R, sSendData);
    Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[nTeeboxNo].AgentIP_R + ' : ' + sLogMsg);
  end;

  if FTeeboxInfoList[nTeeboxNo].AgentIP_L <> '' then
  begin
    //Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sSendData);
    sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[nTeeboxNo].AgentIP_L, sSendData);
    Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[nTeeboxNo].AgentIP_L + ' : ' + sLogMsg);
  end;

  FTeeboxInfoList[nTeeboxNo].AgentCtlYN := '1';

  Result := True;
end;

end.
