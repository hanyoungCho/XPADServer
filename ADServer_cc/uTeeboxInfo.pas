unit uTeeboxInfo;

interface

uses
  uStruct, uConsts,
  System.Classes, System.SysUtils, System.DateUtils,
  Uni, System.Generics.Collections;

type
  TSeat = class
  private
    FDevicNoList: array of String;
    FDevicNoCnt: Integer;
    FTeeboxInfoList: array of TTeeboxInfo;
    FTeeboxReserveList: array of TTeeboxReserveList;

    FTeeboxLastNo: Integer;

    FBallBackEnd: Boolean; //볼회수종료
    FBallBackEndCtl: Boolean; //볼회수종료 재배정명령여부

    //2020-09-12 볼회수시 키오스크에서 홀드, 배정 막기위해
    FBallBackUse: Boolean; //볼회수여부

    FTeeboxStatusUse: Boolean;
    FTeeboxReserveUse: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure StartUp;

    function GetTeeboxListToApi: Boolean;
    function SetTeeboxStartUseStatus: Boolean; //최초실행시

    //Seat Thread
    procedure TeeboxReserveChkAD;
    procedure TeeboxStatusChkAD;

    procedure ReserveNextChk;
    //Seat Thread

    procedure SetStoreClose;

    procedure SetTeeboxInfo(ATeeboxInfo: TTeeboxInfo);
    procedure SetTeeboxErrorCntAD(ATeeboxNo: Integer; AError: String; AMaxCnt: Integer);
    procedure SetTeeboxDelay(ATeeboxNo: Integer; AType: Integer);

    procedure SetTeeboxCtrl(ATeeboxNo: Integer; AType: String; ATime: Integer; ABall: Integer);

    function TeeboxLockCheck(ATeeboxNo: Integer; AType: String): Boolean;
    function BallRecallStart: Boolean;
    function BallRecallEnd: Boolean;
    function BallRecallStartCheck: Boolean; // 볼회수전 볼회수중인지 확인

    function GetDeviceToTeeboxInfo(ADev: String): TTeeboxInfo;
    function GetSeatDevicdNoToDevic(AIndex: Integer): String; //장치ID 배열(좌우겸용으로 인해 별도 관리)
    function GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
    function GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
    function GetTeeboxStatusList: AnsiString;

    function SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
    function GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;

    //예약목록에 등록
    function SetReserveNext(AReserve: TSeatUseReserve): Boolean;
    function SetReserveNextCancel(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetReserveNextChange(ATeeboxNo: Integer; ASeatUseInfo: TSeatUseInfo): Boolean;
    function GetReserveNextListCnt(ATeeboxNo: Integer): String;
    function SetReserveNextCutInCheck(ASeatReserveInfo: TSeatUseReserve): String; //끼어넣기 가능여부 체크
    function SetReserveNextCutIn(ASeatReserveInfo: TSeatUseReserve): Boolean; //끼어넣기
    function GetReserveNextView(ATeeboxNo: Integer): String; //메인 데이터 확인용

    function SetReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
    function SetReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
    function SetReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String; //즉시배정
    function GetReserveLastTime(ATeeboxNo: String): String; //2020-05-31 예약시간 검증

    function ResetTeeboxRemainMinAdd(ATeeboxNo, ADelayTm: Integer; ATeeboxNm: String): Boolean;

    procedure SendADStatusToErp;
    procedure SendSMSToErp(ATeeboxNm: String);

    function SeatClear: Boolean;

    function ReSetTeeboxNextReserveData(ATeebox, AIndex, AReserveNo, AreserveDate: String): Boolean;

    property TeeboxLastNo: Integer read FTeeboxLastNo write FTeeboxLastNo;
    property DevicNoCnt: Integer read FDevicNoCnt write FDevicNoCnt;
    property BallBackEnd: Boolean read FBallBackEnd write FBallBackEnd;
    property BallBackEndCtl: Boolean read FBallBackEndCtl write FBallBackEndCtl;

    property BallBackUse: Boolean read FBallBackUse write FBallBackUse;
    property TeeboxStatusUse: Boolean read FTeeboxStatusUse write FTeeboxStatusUse;
    property TeeboxReserveUse: Boolean read FTeeboxReserveUse write FTeeboxReserveUse;
  end;

implementation

uses
  uGlobal, uFunction, JSON;

{ Tasuk }

constructor TSeat.Create;
begin

  TeeboxLastNo := 0;
  FDevicNoCnt := 0;
  //SeatError := False;
  FBallBackEnd := False;
  FBallBackEndCtl := False;

  FTeeboxStatusUse := False;
  FTeeboxReserveUse := False;

  FBallBackUse := False;
end;

destructor TSeat.Destroy;
begin
  SeatClear;

  inherited;
end;

procedure TSeat.StartUp;
begin
  GetTeeboxListToApi;
  SetTeeboxStartUseStatus;
end;

function TSeat.GetTeeboxListToApi: Boolean;
var
  nIndex, nTeeboxNo, nTeeboxCnt: Integer;
  //sSeatVer: String;
  jObjArr: TJsonArray;
  jObj, jObjSub: TJSONObject;

  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;
begin
  Result := False;

  try
    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;
    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K204_TeeBoxlist', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'GetTeeboxListToApi Fail : ' + sResult;
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

    jObjArr := jObj.GetValue('result_data') as TJsonArray;

    nTeeboxCnt := jObjArr.Size;
    SetLength(FTeeboxInfoList, nTeeboxCnt + 1);
    SetLength(FTeeboxReserveList, nTeeboxCnt + 1);
    SetLength(FDevicNoList, 0);

    for nIndex := 0 to nTeeboxCnt - 1 do
    begin
      jObjSub := jObjArr.Get(nIndex) as TJSONObject;
      nTeeboxNo := StrToInt(jObjSub.GetValue('teebox_no').Value);
      if FTeeboxLastNo < nTeeboxNo then
        FTeeboxLastNo := nTeeboxNo;

      FTeeboxInfoList[nTeeboxNo].TeeboxNo := StrToInt(jObjSub.GetValue('teebox_no').Value);
      FTeeboxInfoList[nTeeboxNo].TeeboxNm := jObjSub.GetValue('teebox_nm').Value;
      FTeeboxInfoList[nTeeboxNo].FloorZoneCode := jObjSub.GetValue('floor_cd').Value;
      FTeeboxInfoList[nTeeboxNo].FloorNm := jObjSub.GetValue('floor_nm').Value;
      FTeeboxInfoList[nTeeboxNo].ZoneDiv := jObjSub.GetValue('zone_div').Value;
      FTeeboxInfoList[nTeeboxNo].DeviceId := jObjSub.GetValue('device_id').Value;
      FTeeboxInfoList[nTeeboxNo].UseYn := jObjSub.GetValue('use_yn').Value;

      if FTeeboxInfoList[nTeeboxNo].UseYn = 'Y' then
      begin

        SetLength(FDevicNoList, FDevicNoCnt + 1);
        if FTeeboxInfoList[nTeeboxNo].ZoneDiv = 'L' then
        begin
          FDevicNoList[FDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 1, 3);
          inc(FDevicNoCnt);

          if Length(FTeeboxInfoList[nTeeboxNo].DeviceId) = 6 then
          begin
            SetLength(FDevicNoList, FDevicNoCnt + 1);
            FDevicNoList[FDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 4, 3);
            inc(FDevicNoCnt);
          end;
        end
        else
        begin
          FDevicNoList[FDevicNoCnt] := FTeeboxInfoList[nTeeboxNo].DeviceId;
          inc(FDevicNoCnt);
        end;

      end;

      FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
      FTeeboxInfoList[nTeeboxNo].ComReceive := 'N'; //최초 1회 체크

      FTeeboxReserveList[nTeeboxNo].TeeboxNo := nTeeboxNo;
      //FTeeboxReserveList[nTeeboxNo].nCurrIdx := 0;
      //FTeeboxReserveList[nTeeboxNo].nLastIdx := 0;
      FTeeboxReserveList[nTeeboxNo].ReserveList := TStringList.Create;
    end;

  finally
    FreeAndNil(jObj);
  end;

  Result := True;
end;

function TSeat.SetTeeboxStartUseStatus: Boolean;
var
  rSeatInfoList: TList<TTeeboxInfo>;
  nDBMax: Integer;
  I, nTeeboxNo, nIndex: Integer;
  rSeatUseReserveList: TList<TSeatUseReserve>;
  //rSeatHoldList: TList<TSeatUseReserve>;
  sStausChk, sBallBackStart: String;
  sStr, sPreDate: String;

  NextReserve: TNextReserve;
  nErpReserveNo: Integer;
begin
  rSeatInfoList := Global.XGolfDM.SeatSelect;

  sStausChk := '';
  nDBMax := 0;
  for I := 0 to rSeatInfoList.Count - 1 do
  begin
    nTeeboxNo := rSeatInfoList[I].TeeboxNo;

    if (FTeeboxInfoList[nTeeboxNo].TeeboxNm <> rSeatInfoList[I].TeeboxNm) or
       (FTeeboxInfoList[nTeeboxNo].FloorZoneCode <> rSeatInfoList[I].FloorZoneCode) or
       (FTeeboxInfoList[nTeeboxNo].ZoneDiv <> rSeatInfoList[I].ZoneDiv) or
       (FTeeboxInfoList[nTeeboxNo].DeviceId <> rSeatInfoList[I].DeviceId) or
       (FTeeboxInfoList[nTeeboxNo].UseYn <> rSeatInfoList[I].UseYn) then
    begin
      Global.XGolfDM.SeatUpdate(Global.ADConfig.StoreCode, FTeeboxInfoList[nTeeboxNo]);
    end;

    //FTeeboxInfoList[nTeeboxNo].UseStatusPre := rSeatInfoList[I].UseStatus;
    FTeeboxInfoList[nTeeboxNo].UseStatus := rSeatInfoList[I].UseStatus;
    if FTeeboxInfoList[nTeeboxNo].UseStatus = '8' then
      TeeboxLockCheck(nTeeboxNo, '8');

    //FTeeboxInfoList[nTeeboxNo].RemainMinPre := rSeatInfoList[I].RemainMinute;
    //FTeeboxInfoList[nTeeboxNo].RemainMinute := rSeatInfoList[I].RemainMinute;

    FTeeboxInfoList[nTeeboxNo].RemainBall := rSeatInfoList[I].RemainBall;

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '7' then
      sStausChk := '7';

    FTeeboxInfoList[nTeeboxNo].HoldUse := False;
    FTeeboxInfoList[nTeeboxNo].HoldUse := rSeatInfoList[I].HoldUse;
    FTeeboxInfoList[nTeeboxNo].HoldUser := rSeatInfoList[I].HoldUser;

    if FTeeboxInfoList[nTeeboxNo].HoldUse = True then
    begin
      sStr := 'HoldUse : ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nIndex].TeeboxNm;
      Global.Log.LogWrite(sStr);
    end;

    if nTeeboxNo > nDBMax then
      nDBMax := nTeeboxNo;
  end;
  FreeAndNil(rSeatInfoList);

  if FTeeboxLastNo > nDBMax then
  begin
    for I := nDBMax + 1 to FTeeboxLastNo do
    begin
      Global.XGolfDM.SeatInsert(Global.ADConfig.StoreCode, FTeeboxInfoList[I]);
    end;
  end;

  //2020-06-09 전날 배정 정리
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

    FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo := rSeatUseReserveList[nIndex].ReserveNo;
    FTeeboxInfoList[nTeeboxNo].Reserve.AssignMin := rSeatUseReserveList[nIndex].UseMinute;
    FTeeboxInfoList[nTeeboxNo].Reserve.AssignBalls := rSeatUseReserveList[nIndex].UseBalls;
    FTeeboxInfoList[nTeeboxNo].Reserve.PrepareMin := rSeatUseReserveList[nIndex].DelayMinute;
    FTeeboxInfoList[nTeeboxNo].Reserve.ReserveDate := rSeatUseReserveList[nIndex].ReserveDate;
    FTeeboxInfoList[nTeeboxNo].Reserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].Reserve.ReserveDate) +
                                                        (((1/24)/60) * FTeeboxInfoList[nTeeboxNo].Reserve.PrepareMin);

    FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate := rSeatUseReserveList[nIndex].StartTime;
    if rSeatUseReserveList[nIndex].UseStatus = '1' then
      FTeeboxInfoList[nTeeboxNo].Reserve.ReserveYn := 'Y';

    sStr := '목록 : ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].Reserve.AssignMin);
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

    //2020-06-29
    if FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo = rSeatUseReserveList[nIndex].ReserveNo then
      Continue;

    try
      NextReserve := TNextReserve.Create;
      NextReserve.ReserveNo := rSeatUseReserveList[nIndex].ReserveNo;
      NextReserve.UseStatus := rSeatUseReserveList[nIndex].UseStatus;
      NextReserve.SeatNo := IntToStr(rSeatUseReserveList[nIndex].SeatNo);
      NextReserve.UseMinute := IntToStr(rSeatUseReserveList[nIndex].UseMinute);
      NextReserve.UseBalls := IntToStr(rSeatUseReserveList[nIndex].UseBalls);
      NextReserve.DelayMinute := IntToStr(rSeatUseReserveList[nIndex].DelayMinute);
      NextReserve.ReserveDate := rSeatUseReserveList[nIndex].ReserveDate;
      NextReserve.StartTime := rSeatUseReserveList[nIndex].StartTime;
      FTeeboxReserveList[nTeeboxNo].ReserveList.AddObject(NextReserve.SeatNo, TObject(NextReserve));
    finally
      //FreeAndNil(NextReserve);
    end;

    sStr := '예약목록 : ' + IntToStr(nTeeboxNo) + ' / ' + rSeatUseReserveList[nIndex].ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;

  FreeAndNil(rSeatUseReserveList);

  Global.TcpServer.UseSeqNo := Global.XGolfDM.ReserveDateNo(Global.ADConfig.StoreCode, FormatDateTime('YYYYMMDD', Now));

  Global.TcpServer.LastUseSeqNo := Global.TcpServer.UseSeqNo;

  //시작시 볼회수 상태이면
  if sStausChk = '7' then
  begin
    sBallBackStart := Global.ReadConfigBallBackStartTime;
    if sBallBackStart = '' then
      FTeeboxInfoList[1].PauseTime := Now
    else
      FTeeboxInfoList[1].PauseTime := DateStrToDateTime2(sBallBackStart);

    //chy 2020-10-30 볼회수 체크
    FBallBackUse := True;
  end;
end;

function TSeat.TeeboxLockCheck(ATeeboxNo: Integer; AType: String): Boolean;
begin
  FTeeboxInfoList[ATeeboxNo].UseStatus := AType;
end;

function TSeat.BallRecallStartCheck: Boolean;
var
  nIndex: Integer;
  sStr: String;
begin
  Result := False;

  for nIndex := 1 to TeeboxLastNo do
  begin
    if (FTeeboxInfoList[nIndex].UseYn = 'Y') and (FTeeboxInfoList[nIndex].UseStatus = '7') then //정지상태
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TSeat.BallRecallStart: Boolean;
var
  nIndex: Integer;
  sStr: String;
begin
  Result := False;

  //볼회수 일경우 현재 남은시간 저장
  Global.CheckConfigBall(0);
  //보상시간 체크시작
  SetTeeboxDelay(0, 0);

  for nIndex := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nIndex].UseStatus = '9' then //타석기 고장
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '8' then //점검상태
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '7' then //정지상태
      Continue;

    FTeeboxInfoList[nIndex].UseStatus := '7';
    FTeeboxInfoList[nIndex].DeviceCtrlCnt := 0; //제어횟수 초기화

    if FTeeboxInfoList[nIndex].RemainMinute > 0 then
    begin
      //배정위해 제어배열에 등록, S1 제어, 시간 초기화
      SetTeeboxCtrl(nIndex, 'S1' , 0, FTeeboxInfoList[nIndex].RemainBall);

      sStr := '정지명령 - No:' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].Reserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].RemainBall) + ' / ' +
              '7' + ' / ' + FTeeboxInfoList[nIndex].DeviceId;
      Global.Log.LogReserveWrite(sStr);
    end;

    Global.XGolfDM.SeatStatusUpdate(nIndex, FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].RemainBall, FTeeboxInfoList[nIndex].UseStatus, '');
  end;

  FBallBackEnd := False;
  BallBackEndCtl := False;

  FBallBackUse := True;

  Result := True;
end;

function TSeat.BallRecallEnd: Boolean;
var
  nIndex: Integer;
  //nSeatRemainMin, nDelayNo: Integer;
  sStr: String;
begin
  Result := False;
  //보상시간 체크종료
  SetTeeboxDelay(0, 1);
  //nDelayNo := -1;

  for nIndex := 1 to TeeboxLastNo do
  begin

    if FTeeboxInfoList[nIndex].UseStatus <> '7' then //정지상태
      Continue;

    if FTeeboxInfoList[nIndex].RemainMinute > 0 then
    begin
      FTeeboxInfoList[nIndex].Reserve.AssignMin := FTeeboxInfoList[nIndex].Reserve.AssignMin + FTeeboxInfoList[0].DelayMin;
      FTeeboxInfoList[nIndex].UseStatus := '1';

      //배정위해 제어배열에 등록
      SetTeeboxCtrl(nIndex, 'S1' , FTeeboxInfoList[nIndex].RemainMinute, 9999);

      sStr := '복귀명령 : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].Reserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].RemainMinute);
      Global.Log.LogReserveWrite(sStr);
    end
    else
    begin
      FTeeboxInfoList[nIndex].UseStatus := '0';
    end;

    FBallBackEnd := True;
  end;

  // index 0 번 기준으로 볼회수 시간 체크
  ResetTeeboxRemainMinAdd(0, FTeeboxInfoList[0].DelayMin, 'ALL');

  FBallBackUse := False;

  Result := True;
end;

function TSeat.GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
begin
  Result := FTeeboxInfoList[ATeeboxNo];
end;

function TSeat.GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
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

procedure TSeat.SetTeeboxDelay(ATeeboxNo: Integer; AType: Integer);
var
  nTemp: Integer;
  sStr: String;
begin
  if AType = 0 then //지연시작
  begin
    FTeeboxInfoList[ATeeboxNo].PauseTime := Now;
  end
  else if AType = 1 then //지연종료
  begin
    FTeeboxInfoList[ATeeboxNo].RePlayTime := Now;

    //2020-06-29 딜레이체크
    if formatdatetime('YYYYMMDD',FTeeboxInfoList[ATeeboxNo].PauseTime) <> formatdatetime('YYYYMMDD',now) then
    begin
      FTeeboxInfoList[ATeeboxNo].DelayMin := 0;
    end
    else
    begin
      //1분 추가 적용-20200507
      nTemp := Trunc((FTeeboxInfoList[ATeeboxNo].RePlayTime - FTeeboxInfoList[ATeeboxNo].PauseTime) *24 * 60 * 60); //초로 변환
      if (nTemp mod 60) > 0 then
        FTeeboxInfoList[ATeeboxNo].DelayMin := (nTemp div 60) + 1
      else
        FTeeboxInfoList[ATeeboxNo].DelayMin := (nTemp div 60);
    end;

    sStr := formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[ATeeboxNo].PauseTime) + ' / ' +
            formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[ATeeboxNo].RePlayTime) + ' / ' +
            IntToStr(FTeeboxInfoList[ATeeboxNo].DelayMin);
    Global.Log.LogReserveWrite(sStr);
  end;

end;

procedure TSeat.SetTeeboxInfo(ATeeboxInfo: TTeeboxInfo);
var
  nTeeboxNo: Integer;
  sStr: String;
begin
  nTeeboxNo := ATeeboxInfo.TeeboxNo;

  //2020-06-02 좌우타석 수정
  if FTeeboxInfoList[nTeeboxNo].ZoneDiv = 'L' then
  begin

    if Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 1, 3) = ATeeboxInfo.RecvDeviceId then //R 오른쪽
    begin
      FTeeboxInfoList[nTeeboxNo].DeviceUseStatus_R := ATeeboxInfo.UseStatus;
      FTeeboxInfoList[nTeeboxNo].DeviceRemainMin_R := ATeeboxInfo.RemainMinute;
      FTeeboxInfoList[nTeeboxNo].DeviceRemainBall_R := ATeeboxInfo.RemainBall;
      FTeeboxInfoList[nTeeboxNo].DeviceErrorCd_R := ATeeboxInfo.ErrorCd;
    end
    else
    begin
      FTeeboxInfoList[nTeeboxNo].DeviceUseStatus_L := ATeeboxInfo.UseStatus;
      FTeeboxInfoList[nTeeboxNo].DeviceRemainMin_L := ATeeboxInfo.RemainMinute;
      FTeeboxInfoList[nTeeboxNo].DeviceRemainBall_L := ATeeboxInfo.RemainBall;
      FTeeboxInfoList[nTeeboxNo].DeviceErrorCd_L := ATeeboxInfo.ErrorCd;

      //볼수: 적은거 기준
      if FTeeboxInfoList[nTeeboxNo].DeviceRemainBall_R > FTeeboxInfoList[nTeeboxNo].DeviceRemainBall_L then
        FTeeboxInfoList[nTeeboxNo].RemainBall := FTeeboxInfoList[nTeeboxNo].DeviceRemainBall_L
      else
        FTeeboxInfoList[nTeeboxNo].RemainBall := FTeeboxInfoList[nTeeboxNo].DeviceRemainBall_R;

      //상태: 가동중 기준
      if (FTeeboxInfoList[nTeeboxNo].DeviceUseStatus_R = '9') or (FTeeboxInfoList[nTeeboxNo].DeviceUseStatus_L = '9') then
        FTeeboxInfoList[nTeeboxNo].DeviceUseStatus := '9'
      else if (FTeeboxInfoList[nTeeboxNo].DeviceUseStatus_R = '1') or (FTeeboxInfoList[nTeeboxNo].DeviceUseStatus_L = '1') then
        FTeeboxInfoList[nTeeboxNo].DeviceUseStatus := '1'
      else
        FTeeboxInfoList[nTeeboxNo].DeviceUseStatus := '0';

      //잔여시간: 작은거 기준, 일정시간이후 좌우타석중 시간이 유지되는 경우가 있음
      if FTeeboxInfoList[nTeeboxNo].DeviceRemainMin_R > FTeeboxInfoList[nTeeboxNo].DeviceRemainMin_L then
        FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := FTeeboxInfoList[nTeeboxNo].DeviceRemainMin_L
      else
        FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := FTeeboxInfoList[nTeeboxNo].DeviceRemainMin_R;

    end;

  end
  else
  begin
    FTeeboxInfoList[nTeeboxNo].DeviceUseStatus := ATeeboxInfo.UseStatus;
    FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := ATeeboxInfo.RemainMinute;
    FTeeboxInfoList[nTeeboxNo].RemainBall := ATeeboxInfo.RemainBall;
    FTeeboxInfoList[nTeeboxNo].DeviceErrorCd := ATeeboxInfo.ErrorCd;
  end;

  FTeeboxInfoList[nTeeboxNo].ComReceive := 'Y';
end;

function TSeat.SetReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
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

  if FTeeboxInfoList[nSeatNo].Reserve.ReserveNo = ASeatReserveInfo.ReserveNo then
  begin
    sStr := '동일예약건 - No:' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' + FTeeboxInfoList[nSeatNo].Reserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //현재 배정중이면
  if (FTeeboxInfoList[nSeatNo].UseStatus = '1') and
     (FTeeboxInfoList[nSeatNo].RemainMinute > 0) then
  begin
    SetReserveNext(ASeatReserveInfo);
    sStr := '신규배정대기 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[nSeatNo].Reserve.ReserveNo + ' / ' +
          FTeeboxInfoList[nSeatNo].Reserve.ReserveStartDate + ' / ' +
          FTeeboxInfoList[nSeatNo].Reserve.ReserveEndDate + ' -> ' +
          ASeatReserveInfo.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  FTeeboxInfoList[nSeatNo].Reserve.ReserveNo := ASeatReserveInfo.ReserveNo;
  FTeeboxInfoList[nSeatNo].Reserve.AssignMin := ASeatReserveInfo.UseMinute;
  FTeeboxInfoList[nSeatNo].Reserve.AssignBalls := ASeatReserveInfo.UseBalls;

  if FTeeboxInfoList[nSeatNo].Reserve.AssignBalls > 9999 then
    FTeeboxInfoList[nSeatNo].Reserve.AssignBalls := 9999;

  FTeeboxInfoList[nSeatNo].Reserve.PrepareMin := ASeatReserveInfo.DelayMinute;
  if FTeeboxInfoList[nSeatNo].Reserve.PrepareMin < 0 then
    FTeeboxInfoList[nSeatNo].Reserve.PrepareMin := 0;

  FTeeboxInfoList[nSeatNo].Reserve.ReserveDate := ASeatReserveInfo.ReserveDate;
  FTeeboxInfoList[nSeatNo].Reserve.PrepareStartDate := '';
  FTeeboxInfoList[nSeatNo].Reserve.ReserveStartDate := '';
  FTeeboxInfoList[nSeatNo].Reserve.ReserveYn := 'N';

  if ASeatReserveInfo.ReserveDate <= formatdatetime('YYYYMMDDhhnnss', Now) then
  begin
    FTeeboxInfoList[nSeatNo].Reserve.PrepareStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
    FTeeboxInfoList[nSeatNo].Reserve.PrepareEndTime := Now + (((1/24)/60) * FTeeboxInfoList[nSeatNo].Reserve.PrepareMin);
  end
  else
  begin
    FTeeboxInfoList[nSeatNo].Reserve.PrepareStartDate := ASeatReserveInfo.ReserveDate;
    FTeeboxInfoList[nSeatNo].Reserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].Reserve.PrepareStartDate) +
                                                         (((1/24)/60) * FTeeboxInfoList[nSeatNo].Reserve.PrepareMin);
  end;

  FTeeboxInfoList[nSeatNo].Reserve.ReserveEndDate := '';
  FTeeboxInfoList[nSeatNo].DelayMin := 0;
  FTeeboxInfoList[nSeatNo].UseCancel := 'N';
  FTeeboxInfoList[nSeatNo].UseClose := 'N';
end;

function TSeat.SetReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
var
  nSeatNo, nCtlMin: Integer;
  sStr: String;

  //2020-08-27 v26 이용타석 시간추가시 예약타석 시간증가
  nDelayMin: Integer;
begin
  Result:= False;

  nSeatNo := ASeatUseInfo.SeatNo;
  if FTeeboxInfoList[nSeatNo].Reserve.ReserveNo <> ASeatUseInfo.ReserveNo then
  begin
    SetReserveNextChange(nSeatNo, ASeatUseInfo);
    Exit;
  end;

  //대기시간/배정시간 변경 체크
  if (FTeeboxInfoList[nSeatNo].Reserve.PrepareMin = ASeatUseInfo.PrepareMin) and
     (FTeeboxInfoList[nSeatNo].Reserve.AssignMin = ASeatUseInfo.AssignMin) then
  begin
    //변경된 내용 없음
    Exit;
  end;

  if FTeeboxInfoList[nSeatNo].Reserve.ReserveYn = 'N' then
  begin
    sStr := '예약배정시간변경 - No:' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[nSeatNo].Reserve.ReserveNo + ' / ' +
            '대기시간' + IntToStr(FTeeboxInfoList[nSeatNo].Reserve.PrepareMin) + ' -> ' + IntToStr(ASeatUseInfo.PrepareMin) + ' / ' +
            '배정시간' + IntToStr(FTeeboxInfoList[nSeatNo].Reserve.AssignMin) + ' -> ' + IntToStr(ASeatUseInfo.AssignMin);

    if FTeeboxInfoList[nSeatNo].Reserve.PrepareMin <> ASeatUseInfo.PrepareMin then
    begin
      FTeeboxInfoList[nSeatNo].Reserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].Reserve.PrepareStartDate) +
                                                          (((1/24)/60) * ASeatUseInfo.PrepareMin);
      FTeeboxInfoList[nSeatNo].Reserve.PrepareMin := ASeatUseInfo.PrepareMin;
    end;
  end
  else
  begin
    //배정된후 배정시간 변경만 체크
    if FTeeboxInfoList[nSeatNo].Reserve.AssignMin <> ASeatUseInfo.AssignMin then
    begin
      if ASeatUseInfo.AssignMin < 2 then
        ASeatUseInfo.AssignMin := 2; // 0 으로 변경시 대기시간 상태 적용됨

      //배정시간변경 위해 제어배열에 등록
      nCtlMin := ASeatUseInfo.RemainMin + (ASeatUseInfo.AssignMin - FTeeboxInfoList[nSeatNo].Reserve.AssignMin);

      SetTeeboxCtrl(nSeatNo, 'S1' , nCtlMin, 9999);

      sStr := '배정시간변경 - No:' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].Reserve.ReserveNo + ' / ' +
              '배정시간' + IntToStr(FTeeboxInfoList[nSeatNo].Reserve.AssignMin) + ' -> ' + IntToStr(ASeatUseInfo.AssignMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].RemainMinute) + ' -> ' + IntToStr(nCtlMin);
    end;
  end;

  Global.Log.LogReserveWrite(sStr);
  FTeeboxInfoList[nSeatNo].Reserve.AssignMin := ASeatUseInfo.AssignMin;

  Result:= True;
end;

function TSeat.SetReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].Reserve.ReserveNo <> AReserveNo then
  begin
    //예약대기, 배정된 타석이 아님
    SetReserveNextCancel(ATeeboxNo, AReserveNo);
    Exit;
  end;

  //취소위해 제어배열에 등록
  FTeeboxInfoList[ATeeboxNo].UseCancel := 'Y';

  SetTeeboxCtrl(ATeeboxNo, 'S1', 0, 9999);

  sStr := 'Cancel - No:' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].Reserve.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

function TSeat.SetReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].Reserve.ReserveNo <> AReserveNo then
    Exit;

  FTeeboxInfoList[ATeeboxNo].UseClose := 'Y';

  SetTeeboxCtrl(ATeeboxNo, 'S1', 0, 9999);

  sStr := 'Close - No:' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].Reserve.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

//chy 2020-10-27 즉시배정
function TSeat.SetReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sStr, sReserveNoTemp, sReserveDateTemp, sResult: String;
  SeatUseReserve: TSeatUseReserve;
begin
  Result := '';

  if FTeeboxInfoList[ATeeboxNo].UseStatus <> '0' then
  begin
    Result := '사용중인 타석입니다.';
    Exit;
  end;

  if FTeeboxInfoList[ATeeboxNo].Reserve.ReserveNo = AReserveNo then
  begin
    FTeeboxInfoList[ATeeboxNo].Reserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
    FTeeboxInfoList[ATeeboxNo].Reserve.PrepareEndTime := Now;

    sStr := 'Start Now 대기- No:' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[ATeeboxNo].Reserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end
  else
  begin
    if FTeeboxReserveList[ATeeboxNo].ReserveList.Count = 0 then
    begin
      Result := '대기중인 예약이 없습니다.';
      Exit;
    end;

    sReserveNoTemp := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).ReserveNo;
    if sReserveNoTemp <> AReserveNo then
    begin
      Result := '대기중인 예약이 아닙니다.';
      Exit;
    end;

    SeatUseReserve.ReserveNo := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).ReserveNo;
    SeatUseReserve.UseStatus := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).UseStatus;
    SeatUseReserve.SeatNo := StrToInt(TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).SeatNo);
    SeatUseReserve.UseMinute := StrToInt(TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).UseMinute);
    SeatUseReserve.UseBalls := StrToInt(TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).UseBalls);
    SeatUseReserve.DelayMinute := 0;
    sReserveDateTemp := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).ReserveDate;
    SeatUseReserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
    SeatUseReserve.StartTime := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).StartTime;

    SetReserveInfo(SeatUseReserve);

    TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).Free;
    FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0] := nil;
    FTeeboxReserveList[ATeeboxNo].ReserveList.Delete(0);

    sStr := 'Start Now - No:' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[ATeeboxNo].Reserve.ReserveNo + ' / ' + sReserveDateTemp + ' -> ' + SeatUseReserve.ReserveDate;
    Global.Log.LogReserveWrite(sStr);

    //2021-11-22끼어넣기 대상 제외처리
    sResult := Global.XGolfDM.SeatUseCutInUseListDelete(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sReserveDateTemp, True);
    if sResult <> 'Success' then
      sStr := 'Start Now CutInUseListDelete Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + sReserveDateTemp
    else
      sStr := 'Start Now CutInUseListDelete : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + sReserveDateTemp;

  end;

  Result := 'Success';
end;

procedure TSeat.TeeboxReserveChkAD;
var
  nTeeboxNo: Integer;
  sCheckTime, sTime, sStr, sLog: string;
  I, nNN, nTmTemp, nTemp: Integer;
  tmTempS: TDateTime;
  tmCheckIn: TDateTime;
  nCtlSecond: Integer;
begin

  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sLog := 'SeatReserveUse TeeboxReserveChkAD!';
    Global.Log.LogReserveDelayWrite(sLog);

    sleep(50);
  end;
  FTeeboxStatusUse := True;

  sCheckTime := FormatDateTime('YYYYMMDD hh:nn:ss', Now);
  sTime := Copy(sCheckTime, 10, 5);

  if sTime < Global.Store.StartTime then
    Exit;

  if sTime > Global.Store.EndTime then
  begin
    if Global.Store.Close = 'N' then
    begin
      SetStoreClose;
      Global.SetStoreInfoClose('Y');
      Global.Log.LogWrite('Store Close !!!');
    end;

    if (Global.Store.Close = 'Y') and (Global.Store.EndDBTime <> '') then
    begin
      if sTime > Global.Store.EndDBTime then
      begin
        Global.XGolfDM.SeatUseStoreClose( Global.ADConfig.StoreCode, Global.ADConfig.UserId, Copy(sCheckTime, 1, 8) );
        Global.SetStoreEndDBTime('');
      end;
    end;

    Exit;
  end;

  if Global.Store.Close = 'Y' then
  begin
    Global.SetStoreInfoClose('N');
    Global.Log.LogWrite('Store Open !!!');
  end;

  for nTeeboxNo := 1 to TeeboxLastNo do
  begin
    //UseStatus = '9' 기기고장 체크하지 않음

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '7' then //볼회수
      continue;

    //타석기 배정상태 확인
    if FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo = '' then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].Reserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Continue;

    //취소, 종료 API 요청시 종료 제어함
    if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') or (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') then //취소인경우 K410_TeeBoxReserved 통해 ERP 전송
    begin

      if FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y' then
      begin
        if (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveYn = 'N') and
           (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate = '') then
        begin
          FTeeboxInfoList[nTeeboxNo].Reserve.ReserveYn := 'Y';
          FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);

          sStr := '등록전취소 no: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo;
          Global.Log.LogReserveWrite(sStr);
        end;
      end;

      if FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate = '' then
      begin
        FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '배정종료 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].Reserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        if (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') then
        begin
          // DB/Erp저장: 종료시간
          Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo,
                                           FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate, '2');
        end;

        //FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
        FTeeboxInfoList[nTeeboxNo].RemainMinute := 0;
      end;
    end;

    //배정시작전이고 대기시간을 지났으면
    if (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate = '') and
       (FTeeboxInfoList[nTeeboxNo].Reserve.PrepareEndTime < Now) then
    begin

      FTeeboxInfoList[nTeeboxNo].RemainMinute := FTeeboxInfoList[nTeeboxNo].Reserve.AssignMin;
      //FTeeboxInfoList[nTeeboxNo].UseStatus := '1';

      FTeeboxInfoList[nTeeboxNo].Reserve.ReserveYn := 'Y';
      FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now); //2021-06-11

      sStr := '배정구동 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].Reserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].Reserve.ReserveDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].Reserve.PrepareStartDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate;
      Global.Log.LogReserveWrite(sStr);

      // DB저장, 0분 표시되는 경우 있음.
      if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '8') and (FTeeboxInfoList[nTeeboxNo].UseStatus <> '9') then //점검, 고장
        Global.XGolfDM.SeatStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999, '1', '');

      // DB/Erp저장: 시작시간
      Global.TcpServer.SetApiTeeBoxReg(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo,
                                       FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate);

      //배정위해 제어배열에 등록
      SetTeeboxCtrl(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].Reserve.AssignMin, 9999);
    end;

    //시간계산
    if (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate <> '') and
       (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate = '') and
       (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveYn = 'Y') then
    begin

      tmTempS := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate);
      nNN := MinutesBetween(now, tmTempS);

      nTmTemp := FTeeboxInfoList[nTeeboxNo].Reserve.AssignMin - nNN;
      if nTmTemp < 0 then
        nTmTemp := 0;

      if (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) and (nTmTemp = 1) then
      begin
        sStr := '시간오류 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo;
        Global.Log.LogReserveWrite(sStr);
      end;

      FTeeboxInfoList[nTeeboxNo].RemainMinute := nTmTemp;

      if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
      begin
        FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '배정종료 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].Reserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        // DB/Erp저장: 종료시간
        Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo,
                                         FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate, '2');

        SetTeeboxCtrl(nTeeboxNo, 'S1', 0, 9999);
      end;

    end;

  end;

  Sleep(10);
  FTeeboxStatusUse := False;
end;

procedure TSeat.TeeboxStatusChkAD;
var
  nTeeboxNo: Integer;
  sStr, sEndTy, sChange, sResult, sLog: String;
  I, nNN, nTmTemp, nTemp: Integer;
  tmTempS: TDateTime;

  //기기고장 발생여부
  bTeeboxError: Boolean;
begin

  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sLog := 'SeatReserveUse TeeboxStatusChkAD!';
    Global.Log.LogReserveDelayWrite(sLog);

    sleep(50);
  end;
  FTeeboxStatusUse := True;

  //기기고장 발생,해제시 상태 파트너센터 상태 업데이트
  bTeeboxError := False;

  for nTeeboxNo := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
      Continue;

    if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '7') and //볼회수
       (FTeeboxInfoList[nTeeboxNo].UseStatus <> '8') then //점검
    begin
      if FTeeboxInfoList[nTeeboxNo].DeviceUseStatus = '9' then // 타석기 고장상태, 기기고장/통신이상
      begin
        if FTeeboxInfoList[nTeeboxNo].UseStatus <> '9' then //상태가 고장이 아니면
        begin
          sStr := 'Error No: ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  'ErrorCd : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].UseStatus + ' -> 9';
          Global.Log.LogWrite(sStr);

          FTeeboxInfoList[nTeeboxNo].UseStatus := '9';
          FTeeboxInfoList[nTeeboxNo].ErrorCd := FTeeboxInfoList[nTeeboxNo].DeviceErrorCd;

          Global.XGolfDM.TeeboxErrorStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

          bTeeboxError := True;

          if global.Store.ErrorSms = 'Y' then
          begin
            //사용중일경우 기기고장 보상위해 저장
            //if FTeeboxInfoList[nTeeboxNo].ErrorCd <> 8 then
            begin
              FTeeboxInfoList[nTeeboxNo].PauseTime := Now;
              FTeeboxInfoList[nTeeboxNo].SendSMS := 'N';
            end;
          end;
        end;

        //2020-11-05 기기고장 1분 이상유지시 문자발송
        if (global.Store.ErrorSms = 'Y') then
        begin
          nTemp := SecondsBetween(FTeeboxInfoList[nTeeboxNo].PauseTime, now);

          if nTemp > 30 then //30초이상 기기고장 유지면
          begin
            if (global.Store.ErrorSms = 'Y') then
            begin
              if FTeeboxInfoList[nTeeboxNo].SendSMS <> 'Y' then
              begin
                SendSMSToErp(FTeeboxInfoList[nTeeboxNo].TeeboxNm);
                FTeeboxInfoList[nTeeboxNo].SendSMS := 'Y';
                sStr := 'SendSMSToErp No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm;
                Global.Log.LogErpApiWrite(sStr);
              end;
            end;
          end;

        end;

      end
      else
      begin
        if FTeeboxInfoList[nTeeboxNo].UseStatus = '9' then //상태가 고장이면
        begin

          if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
            FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
          else
            FTeeboxInfoList[nTeeboxNo].UseStatus := '1';

          FTeeboxInfoList[nTeeboxNo].ErrorCd := FTeeboxInfoList[nTeeboxNo].DeviceErrorCd;

          Global.XGolfDM.TeeboxErrorStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

          sStr := 'Error No:' + IntToStr(nTeeboxNo) + ' / Nm:' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  'ErrorCd : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) + ' / ' +
                  '9 -> ' + FTeeboxInfoList[nTeeboxNo].UseStatus;
          Global.Log.LogWrite(sStr);

          bTeeboxError := True;
        end;
      end;

      if FTeeboxInfoList[nTeeboxNo].UseStatus <> '9' then
      begin
        if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
          FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
        else
          FTeeboxInfoList[nTeeboxNo].UseStatus := '1';
      end;

    end;

    if (FTeeboxInfoList[nTeeboxNo].UseStatus = '7') then
    begin
      if (FTeeboxInfoList[nTeeboxNo].DeviceRemainMin > 1) then
      begin
        inc(FTeeboxInfoList[nTeeboxNo].DeviceCtrlCnt);

        if FTeeboxInfoList[nTeeboxNo].DeviceCtrlCnt < 3 then
        begin
          sStr := '볼회수 종료제어 - No:' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].DeviceRemainMin);
          Global.Log.LogReserveWrite(sStr);

          SetTeeboxCtrl(nTeeboxNo, 'S1', 0, 9999);
        end;
      end;
    end
    else
    begin
      if (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) and (FTeeboxInfoList[nTeeboxNo].DeviceRemainMin > 1) and
         (FTeeboxInfoList[nTeeboxNo].UseStatus = '0')  then
      begin
        sStr := '종료제어 - No:' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].DeviceRemainMin);
        Global.Log.LogReserveWrite(sStr);

        SetTeeboxCtrl(nTeeboxNo, 'S1', 0, 9999);
      end;
    end;

    // DB저장: 타석기상태(시간,상태,볼수)
    if FTeeboxInfoList[nTeeboxNo].RemainMinPre <> FTeeboxInfoList[nTeeboxNo].RemainMinute then
    begin
      Global.XGolfDM.SeatStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

      //배정시간과 타석기잔여시간 오차 제어
      if (FTeeboxInfoList[nTeeboxNo].RemainMinute <> FTeeboxInfoList[nTeeboxNo].DeviceRemainMin) and
         (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
         (FTeeboxInfoList[nTeeboxNo].UseStatus = '1') then
      begin

        if Abs(FTeeboxInfoList[nTeeboxNo].RemainMinute - FTeeboxInfoList[nTeeboxNo].DeviceRemainMin) > 2 then //2022-06-08
        begin
          sStr := '오차제어 - No:' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo + ' / ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].DeviceRemainMin) + ' -> ' + IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
          Global.Log.LogReserveWrite(sStr);

          SetTeeboxCtrl(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
        end;
      end;

      if (FTeeboxInfoList[nTeeboxNo].RemainMinPre = 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute = 1) then
      begin

        //시간오류 발생시 시간 초기화
        if (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo <> '') and
           (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate <> '') then
        begin
          FTeeboxInfoList[nTeeboxNo].RemainMinute := 0;

          sStr := '시간오류1  보정: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].Reserve.ReserveNo;
        end;

        Global.Log.LogReserveWrite(sStr);
      end;

    end;

    FTeeboxInfoList[nTeeboxNo].RemainMinPre := FTeeboxInfoList[nTeeboxNo].RemainMinute;
  end;

  if bTeeboxError = True then
    Global.TcpServer.SetApiTeeBoxStatus;

  Sleep(10);
  FTeeboxStatusUse := False;
end;

function TSeat.GetDeviceToTeeboxInfo(ADev: String): TTeeboxInfo;
var
  i: Integer;
  sDeviceIdR, sDeviceIdL: String;
begin

  for i := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[i].ZoneDiv = 'L' then //좌우겸용
    begin
      sDeviceIdR := Copy(FTeeboxInfoList[i].DeviceId, 1, 3);
      sDeviceIdL := Copy(FTeeboxInfoList[i].DeviceId, 4, 3);

      if (sDeviceIdR = ADev) or (sDeviceIdL = ADev) then
      begin
        Result := FTeeboxInfoList[i];
        Break;
      end;
    end
    else
    begin
      if FTeeboxInfoList[i].DeviceId = ADev then
      begin
        Result := FTeeboxInfoList[i];
        Break;
      end;
    end;
  end;

end;

function TSeat.GetSeatDevicdNoToDevic(AIndex: Integer): String;
begin
  Result := FDevicNoList[AIndex];
end;

function TSeat.GetTeeboxStatusList: AnsiString;
var
  nIndex: Integer;
  sJsonStr: AnsiString;
  jObj, jItemObj: TJSONObject; //Erp 전송전문
  jObjArr: TJSONArray;
begin
  try
    jObjArr := TJSONArray.Create;
    jObj := TJSONObject.Create;
    jObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
    jObj.AddPair(TJSONPair.Create('user_id', Global.ADConfig.UserId));
    jObj.AddPair(TJSONPair.Create('data', jObjArr));

    for nIndex := 1 to TeeboxLastNo do
    begin
      jItemObj := TJSONObject.Create;
      jItemObj.AddPair( TJSONPair.Create( 'teebox_no', IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) ) );
      jItemObj.AddPair( TJSONPair.Create( 'use_status', FTeeboxInfoList[nIndex].UseStatus ) );
      jObjArr.Add(jItemObj);
    end;

    sJsonStr := jObj.ToString;
  finally
    jObj.Free;
  end;

  Result := sJsonStr;
end;

procedure TSeat.SetStoreClose;
var
  nIndex: Integer;
  sStr: String;
begin
  for nIndex := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nIndex].UseYn = 'N' then
      Continue;

    if FTeeboxInfoList[nIndex].RemainMinute <= 0 then
      Continue;

    //시간초기화 제어배열 등록
    FTeeboxInfoList[nIndex].UseClose := 'Y';

    SetTeeboxCtrl(nIndex, 'S1' , 0, 9999);

    sStr := 'Close - No:' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
            IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
            FTeeboxInfoList[nIndex].Reserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;
end;

procedure TSeat.SetTeeboxCtrl(ATeeboxNo: Integer; AType: String; ATime: Integer; ABall: Integer);
var
  sSeatTime, sSeatBall, sDeviceIdR, sDeviceIdL: AnsiString;
begin
  sSeatTime := IntToStr(ATime);
  sSeatBall := IntToStr(ABall);

  //	2	4	2	S	1	0	0	0	0	9	9	9	9		J
  if FTeeboxInfoList[ATeeboxNo].ZoneDiv = 'L' then //좌우겸용
  begin
    sDeviceIdR := Copy(FTeeboxInfoList[ATeeboxNo].DeviceId, 1, 3);
    Global.CtrlSendBuffer(ATeeboxNo, sDeviceIdR, sSeatTime, sSeatBall, AType);

    if Length(FTeeboxInfoList[ATeeboxNo].DeviceId) = 6 then
    begin
      sDeviceIdL := Copy(FTeeboxInfoList[ATeeboxNo].DeviceId, 4, 3);
      Global.CtrlSendBuffer(ATeeboxNo, sDeviceIdL, sSeatTime, sSeatBall, AType);
    end;
  end
  else
  begin
    Global.CtrlSendBuffer(ATeeboxNo, FTeeboxInfoList[ATeeboxNo].DeviceId, sSeatTime, sSeatBall, AType);
  end;

end;

function TSeat.ResetTeeboxRemainMinAdd(ATeeboxNo, ADelayTm: Integer; ATeeboxNm: String): Boolean;
var
  sResult: String;
  sDate, sStr: String;
begin
  //2020-06-29 딜레이체크
  if ADelayTm = 0 then
    Exit;

  if ADelayTm > 20 then
    Exit;

  sDate := formatdatetime('YYYYMMDD', Now);

  sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm);
  sResult := Global.XGolfDM.SetSeatReserveUseMinAdd(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm));
  Global.Log.LogReserveWrite('ResetTeeboxUseMinAdd : ' + sStr);

  sResult := Global.XGolfDM.SetSeatReserveTmChange(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm));
  //sStr := sResult + ' : ' + IntToStr(ASeatNo) + ' / ' + ASeatNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm);
  Global.Log.LogReserveWrite('ResetTeeboxRemainMinAdd : ' + sStr);
end;

procedure TSeat.ReserveNextChk;
var
  nIndex, nTeeboxNo, nIdx: Integer;
  sLog, sCancel: String;
  I: Integer;
  SeatUseReserve: TSeatUseReserve;
begin

  try

    for nTeeboxNo := 1 to TeeboxLastNo do
    begin

      if FTeeboxInfoList[nTeeboxNo].ComReceive <> 'Y' then
        Continue;

      if (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) then
        Continue;

      if FTeeboxInfoList[nTeeboxNo].Reserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
        Continue;

      if (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveDate <> '') and (FTeeboxInfoList[nTeeboxNo].Reserve.ReserveEndDate = '') then
        Continue;

      if FTeeboxReserveList[nTeeboxNo].CancelYn = 'Y' then //예약삭제중일 경우
      begin
        while True do
        begin
          if FTeeboxReserveList[nTeeboxNo].CancelYn <> 'Y' then
            Break;
        end;
      end;

      if FTeeboxReserveList[nTeeboxNo].ReserveList.Count = 0 then
        Continue;

      nIndex := 0;

      SeatUseReserve.ReserveNo := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveNo;
      SeatUseReserve.UseStatus := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).UseStatus;
      SeatUseReserve.SeatNo := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).SeatNo);
      SeatUseReserve.UseMinute := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).UseMinute);
      SeatUseReserve.UseBalls := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).UseBalls);
      SeatUseReserve.DelayMinute := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).DelayMinute);
      SeatUseReserve.ReserveDate := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate;
      SeatUseReserve.StartTime := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).StartTime;

      SetReserveInfo(SeatUseReserve);

      TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).Free;
      FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex] := nil;
      FTeeboxReserveList[nTeeboxNo].ReserveList.Delete(nIndex);

    end;

  except
    on e: Exception do
    begin
       sLog := 'ReserveNextChk Exception : ' + e.Message;
       Global.Log.LogReserveWrite(sLog);
    end;
  end;

end;

function TSeat.SetReserveNext(AReserve: TSeatUseReserve): Boolean;
var
  nTeeboxNo: Integer;
  NextReserve: TNextReserve;
begin
  nTeeboxNo := AReserve.SeatNo;

  try
    NextReserve := TNextReserve.Create;
    NextReserve.ReserveNo := AReserve.ReserveNo;
    NextReserve.UseStatus := AReserve.UseStatus;
    NextReserve.SeatNo := IntToStr(AReserve.SeatNo);
    NextReserve.UseMinute := IntToStr(AReserve.UseMinute);
    NextReserve.UseBalls := IntToStr(AReserve.UseBalls);
    NextReserve.DelayMinute := IntToStr(AReserve.DelayMinute);
    NextReserve.ReserveDate := AReserve.ReserveDate;
    NextReserve.StartTime := AReserve.StartTime;
    FTeeboxReserveList[nTeeboxNo].ReserveList.AddObject(NextReserve.SeatNo, TObject(NextReserve));
  finally
    //FreeAndNil(NextReserve);
  end;
end;

function TSeat.SetReserveNextCancel(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  I: Integer;
  nUntIn, nCnt: Integer;
  sResult, sLog, sDate: String;
begin
  nUntIn := 0;
  nCnt := FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1;

  FTeeboxReserveList[ATeeboxNo].CancelYn := 'Y';
  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    if AReserveNo = TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).Free;
      FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I] := nil;
      FTeeboxReserveList[ATeeboxNo].ReserveList.Delete(I);

      nUntIn := I;

      Break;
    end;
  end;
  FTeeboxReserveList[ATeeboxNo].CancelYn := 'N';

  if nUntIn < nCnt then
  begin
    //끼워넣기 대상이였던 배정 끼워넣기 항목Y 처리
    sResult := Global.XGolfDM.SeatUseCutInUseInsert(Global.ADConfig.StoreCode, AReserveNo);
    if sResult <> 'Success' then
      sLog := 'SeatUseCutInUseInsert Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + AReserveNo
    else
      sLog := 'SeatUseCutInUseInsert : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + AReserveNo;

    Global.Log.LogErpApiWrite(sLog);
  end;

  if nUntIn = nCnt then //마지막 배정예약
  begin
    if FTeeboxReserveList[ATeeboxNo].ReserveList.Count = 0 then //모든예약삭제
    begin
      sDate := FormatDateTime('YYYYMMDDhhnnss', Now);
    end
    else
    begin
      I := FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1;
      sDate := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate;
    end;

    sResult := Global.XGolfDM.SeatUseCutInUseListDelete(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate);
    if sResult <> 'Success' then
      sLog := 'SeatUseCutInUseListDelete Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + sDate
    else
      sLog := 'SeatUseCutInUseListDelete : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + sDate;

    Global.Log.LogErpApiWrite(sLog);
  end;
end;

function TSeat.SetReserveNextChange(ATeeboxNo: Integer; ASeatUseInfo: TSeatUseInfo): Boolean;
var
  I: Integer;
  NextReserve: TNextReserve;
begin

  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatUseInfo.ReserveNo = TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).DelayMinute := IntToStr(ASeatUseInfo.PrepareMin);
      TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).UseMinute := IntToStr(ASeatUseInfo.AssignMin);

      Break;
    end;
  end;

end;

function TSeat.GetReserveNextListCnt(ATeeboxNo: Integer): String;
begin
  Result := IntToStr(FTeeboxReserveList[ATeeboxNo].ReserveList.Count);
end;

function TSeat.SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
var
  nNo: Integer;
begin
  if ATeeboxNo = '-1' then
    Exit;

  nNo := StrToInt(ATeeboxNo);
  FTeeboxInfoList[nNo].HoldUse := AUse;
  FTeeboxInfoList[nNo].HoldUser := AUserId;
end;

function TSeat.GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;
var
  nTeeboxNo: Integer;
begin
  nTeeboxNo := StrToInt(ATeeboxNo);

  //2020-05-27 적용: Insert
  if AType = 'Insert' then
  begin
    if FTeeboxInfoList[nTeeboxNo].HoldUser = AUserId then //홀드등록자가 동일하면
      Result := False
    else
      Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end
  else
  begin
    Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end;

end;

function TSeat.GetReserveNextView(ATeeboxNo: Integer): String;
var
  I: integer;
  sStr: String;
begin
  sStr := '';
  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    sStr := sStr + IntToStr(I) + ': ';
    sStr := sStr + TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo + ' / ' +
          TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate + ' / ' +
          TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).DelayMinute  + ' / ' +
          TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).UseMinute;

    sStr := sStr + #13#10;
  end;

  Result := sStr;
end;

function TSeat.GetReserveLastTime(ATeeboxNo: String): String; //2020-05-31 예약시간 검증
var
  nIdx, nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sReserveDate, sStr, sLog: String;
  DelayMin, UseMin: Integer;
begin
  sStr := ''; //2022-08-01

  nTeeboxNo := StrToInt(ATeeboxNo);
  if FTeeboxReserveList[nTeeboxNo].ReserveList.Count = 0 then
  begin
    Result := sStr; //2022-08-01
    Exit;
  end;

  nIdx := FTeeboxReserveList[nTeeboxNo].ReserveList.Count - 1;
  sReserveDate := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIdx]).ReserveDate;
  DelayMin := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIdx]).DelayMinute);
  UseMin := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIdx]).UseMinute);

  ReserveTm := DateStrToDateTime3(sReserveDate) + ( ((1/24)/60) * ( DelayMin + UseMin ) );

  sStr := FormatDateTime('YYYYMMDDhhnnss', ReserveTm);

  Result := sStr;
end;

//타석기 구동확인용-> ERP 전송
procedure TSeat.SendADStatusToErp;
var
  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;

  jObj, jObjSub: TJSONObject;
  sChgDate: String;
begin
  try
    //2020-08-13
    while True do
    begin
      if FTeeboxReserveUse = False then
        Break;

      sLog := 'SeatReserveUse SendADStatusToErp!';
      Global.Log.LogReserveDelayWrite(sLog);

      sleep(50);
    end;

    FTeeboxStatusUse := True;

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;

    sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K710_TeeboxTime', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'SendADStatusToErp Fail : ' + sResult;
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K710_TeeboxTime : ' + sResultCd + ' / ' + sResultMsg;
      Global.Log.LogWrite(sLog);
    end
    else
    begin

      jObjSub := jObj.GetValue('result_data') as TJSONObject;
      sChgDate := jObjSub.GetValue('chg_date').Value;

      if sChgDate > Global.Store.StoreLastTM then
      begin
        sLog := 'K710_TeeboxTime : ' + sResult;
        Global.Log.LogWrite(sLog);

        Global.GetStoreInfoToApi;
      end;

    end;

    Sleep(50);
    FTeeboxStatusUse := False;
  finally
    FTeeboxStatusUse := False;
    FreeAndNil(jObj);
  end;
end;

procedure TSeat.SendSMSToErp(ATeeboxNm: String);
var
  sJsonStr: AnsiString;
  sResult, sLog: String;
begin
  sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
              '&send_div=1' +
              '&receiver_hp_no=00011110000' +
              '&send_text=' + ATeeboxNm + '번 타석기가 고장났습니다';

  sResult := Global.Api.SetErpApiNoneDataEncoding(sJsonStr, 'K801_SendSms', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

  Global.Log.LogErpApiWrite(sResult);
end;


function TSeat.ReSetTeeboxNextReserveData(ATeebox, AIndex, AReserveNo, AreserveDate: String): Boolean;
var
  nTeeboxNo, nIndex: Integer;
begin
  nTeeboxNo := StrToInt(ATeebox);
  nIndex := StrToInt(AIndex);

  if AReserveNo <> '' then
    TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveNo := AReserveNo;

  if AreserveDate <> '' then
    TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate := AreserveDate;

end;

function TSeat.SeatClear: Boolean;
var
  nTee, nIdx: Integer;
begin
  for nTee := 1 to TeeboxLastNo do
  begin
    for nIdx := 0 to FTeeboxReserveList[nTee].ReserveList.Count - 1 do
    begin
      TNextReserve(FTeeboxReserveList[nTee].ReserveList.Objects[0]).Free;
      FTeeboxReserveList[nTee].ReserveList.Objects[0] := nil;
      FTeeboxReserveList[nTee].ReserveList.Delete(0);
    end;
    FreeAndNil(FTeeboxReserveList[nTee].ReserveList);
  end;

  SetLength(FTeeboxInfoList, 0);
end;

function TSeat.SetReserveNextCutInCheck(ASeatReserveInfo: TSeatUseReserve): String;
var
  sStr: String;

  nTeeboxNo: Integer;
  I, nIndex: Integer;
  dtTmTemp: TDateTime;
  sTmTemp, sTmTempE: String;
  bCheck: Boolean;
begin
  Result := '';

  nTeeboxNo := ASeatReserveInfo.SeatNo;

  if FTeeboxReserveList[nTeeboxNo].ReserveList.Count = 0 then
  begin
    Result := '끼어넣기를 수행할 예약목록이 없습니다.';
    Exit;
  end;

  nIndex := 0;
  bCheck := False; //동일 예약시간 확인
  for I := 0 to FTeeboxReserveList[nTeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatReserveInfo.ReserveDate <= TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
    begin
      if ASeatReserveInfo.ReserveDate = TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
        bCheck := True;

      nIndex := I;
      Break;
    end;
  end;

  if bCheck = True then
  begin
    Result := '동일한 예약시간으로 예약된 배정이 있습니다.';
    Exit;
  end;

  if nIndex = 0 then //예약중 첫번째 이전
  begin
    //현재 운영중이면 종료시간 체크
    if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '0') and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) then
    begin
      dtTmTemp := IncMinute(Now, FTeeboxInfoList[nTeeboxNo].RemainMinute); //종료 예상시간
      sTmTemp := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);

      dtTmTemp := DateStrToDateTime3(ASeatReserveInfo.ReserveDate) + (((1/24)/60) * 5);
      sTmTempE := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);
      if sTmTemp > sTmTempE then //예상종료시간이 끼어넣을 (예약시간 + 5분) 보다 크면
      begin
        sStr := 'CutIn check : Fail Index=0 ' + IntToStr(nTeeboxNo) + ' / EndTm: ' + sTmTemp + ' > CutIn Reserve: ' + ASeatReserveInfo.ReserveDate;
        Global.Log.LogReserveWrite(sStr);

        Result := '타석종료시간이 예약시간보다 큽니다.';
        Exit;
      end;

    end;
  end
  else
  begin

    dtTmTemp := DateStrToDateTime3(ASeatReserveInfo.ReserveDate) + (((1/24)/60) * (ASeatReserveInfo.DelayMinute + ASeatReserveInfo.UseMinute));
    sTmTemp := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);

    if sTmTemp > TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate then
    begin
      sStr := 'CutIn check : Fail ' + IntToStr(nTeeboxNo) + ' / ' + ASeatReserveInfo.ReserveDate + ' - ' + sTmTemp + ' < ' +
              TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate;
      Global.Log.LogReserveWrite(sStr);

      Result := '끼어넣을 배정시간이 다음 예약건의 예약시간을 초과 합니다.';
      Exit;
    end;
  end;

  Result := 'success';
end;

function TSeat.SetReserveNextCutIn(ASeatReserveInfo: TSeatUseReserve): Boolean;
var
  sStr: String;

  nTeeboxNo: Integer;
  NextReserve: TNextReserve;
  I, nIndex: Integer;
begin
  Result := False;

  nTeeboxNo := ASeatReserveInfo.SeatNo;

  nIndex := 0;
  for I := 0 to FTeeboxReserveList[nTeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatReserveInfo.ReserveDate < TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
    begin
      nIndex := I;

      Break;
    end;
  end;

  NextReserve := TNextReserve.Create;
  NextReserve.ReserveNo := ASeatReserveInfo.ReserveNo;
  NextReserve.UseStatus := ASeatReserveInfo.UseStatus;
  NextReserve.SeatNo := IntToStr(ASeatReserveInfo.SeatNo);
  NextReserve.UseMinute := IntToStr(ASeatReserveInfo.UseMinute);
  NextReserve.UseBalls := IntToStr(ASeatReserveInfo.UseBalls);
  NextReserve.DelayMinute := IntToStr(ASeatReserveInfo.DelayMinute);
  NextReserve.ReserveDate := ASeatReserveInfo.ReserveDate;
  NextReserve.StartTime := ASeatReserveInfo.StartTime;

  FTeeboxReserveList[nTeeboxNo].ReserveList.InsertObject(nIndex, NextReserve.SeatNo, TObject(NextReserve));

  sStr := 'CutIn no: ' + IntToStr(nTeeboxNo) + ' / nIndex: ' + IntToStr(nIndex) + ' / ' + ASeatReserveInfo.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

procedure TSeat.SetTeeboxErrorCntAD(ATeeboxNo: Integer; AError: String; AMaxCnt: Integer);
var
  sLogMsg: String;
begin
  if (FTeeboxInfoList[ATeeboxNo].UseStatus = '7') or (FTeeboxInfoList[ATeeboxNo].UseStatus = '8') then
    Exit;

  if AError = 'Y' then
  begin
    FTeeboxInfoList[ATeeboxNo].ErrorCnt := FTeeboxInfoList[ATeeboxNo].ErrorCnt + 1;
    if FTeeboxInfoList[ATeeboxNo].ErrorCnt >= AMaxCnt then
    begin
      if FTeeboxInfoList[ATeeboxNo].ErrorYn = 'N' then
      begin
        sLogMsg := 'ErrorCnt : ' + IntToStr(AMaxCnt) + ' / No:' + IntToStr(ATeeboxNo) + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
        Global.Log.LogComRead(sLogMsg);
      end;

      FTeeboxInfoList[ATeeboxNo].ErrorYn := 'Y';
      FTeeboxInfoList[ATeeboxNo].DeviceUseStatus := '9';
      FTeeboxInfoList[ATeeboxNo].DeviceErrorCd := 8; //통신이상
    end;
  end
  else
  begin
    FTeeboxInfoList[ATeeboxNo].ErrorCnt := 0;
    FTeeboxInfoList[ATeeboxNo].ErrorYn := 'N';
  end;
end;

end.
