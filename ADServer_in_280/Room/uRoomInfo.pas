unit uRoomInfo;

interface

uses
  uStruct, uConsts,
  System.Classes, System.SysUtils, System.DateUtils,
  Uni, System.Generics.Collections;

type
  TRoom = class
  private
    FRoomInfoList: array of TRoomInfo;
    FRoomCnt: Integer;
    FRoomTapoOnOffCheckLastIndex: Integer;
    FReserveRecve: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure StartUp;
    procedure StartReserve;

    function GetTeeboxListToApi: Boolean;
    function GetTeeboxListToDB: Boolean; //긴급배정용
    function SetTeeboxStartUseStatus: Boolean; //최초실행시

    procedure GetRoomReserveApi; //시작,종료 만 있음(대기 없음)
    procedure RoomReserveApiChk;
    procedure RoomReserveChk;
    procedure RoomStatusChk;

    function GetRoomInfoIndex(ARoomNo: Integer): Integer;
    function GetRoomIndexInfo(AIndex: Integer): TRoomInfo;
    function GetRoomInfo(ARoomNo: Integer): TRoomInfo;
    procedure SetRoomCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin, ASecond: Integer);
    function GetReserveEndTime(ARoomNo: Integer): Integer; //타석종료 예상시간까지 초로 응답

    procedure RoomAgentChk;
    procedure RoomTapoOnOff;
    procedure RoomTapoOnOffCheck;

    function GetRoomInfoIP(AMac: String): String;
    procedure SetRoomOnOff(AIP, AOnOff: String);
    procedure SetRoomTapoError(AIP: String);

    procedure SetRoomAgentCtlYN(AIP, ARecive: String); //agent 응답여부
    procedure SetRoomAgentMac(ARoomNo: Integer; AType: String; AMAC: String);

    function SendRoomReserveStatus(ARoomNo: String): Boolean;
    procedure SendAgentWOL;
    procedure SendAgentOneWOL(ARoomNo: Integer);

    function f_RoomClear: Boolean;

    property RoomCnt: Integer read FRoomCnt write FRoomCnt;
  end;

implementation

uses
  uGlobal, uFunction, JSON;

{ Tasuk }

constructor TRoom.Create;
begin
  FRoomTapoOnOffCheckLastIndex := 0;
end;

destructor TRoom.Destroy;
begin
  f_RoomClear;

  inherited;
end;

function TRoom.f_RoomClear: Boolean;
begin
  SetLength(FRoomInfoList, 0);
end;

procedure TRoom.StartUp;
begin
  if Global.ADConfig.Emergency = False then
    GetTeeboxListToApi
  else
    GetTeeboxListToDB;

  SetTeeboxStartUseStatus;
end;

procedure TRoom.StartReserve;
begin
  //룸 배정내역 ERP 요청
  GetRoomReserveApi;

  //배정내역 확인
  RoomReserveApiChk;

  //시간계산
  RoomReserveChk;

  //상태체크
  RoomStatusChk;
end;

function TRoom.GetTeeboxListToApi: Boolean;
var
  nIndex: Integer;
  jObjArr: TJsonArray;
  jObj, jObjSub: TJSONObject;

  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;
begin
  Result := False;

  try
    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                '&client_id=' + Global.ADConfig.UserId;

    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K204_TeeBoxlist', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

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

    jObjArr := jObj.GetValue('result_data') as TJsonArray;

    FRoomCnt := jObjArr.Size;
    SetLength(FRoomInfoList, FRoomCnt);

    for nIndex := 0 to FRoomCnt - 1 do
    begin
      jObjSub := jObjArr.Get(nIndex) as TJSONObject;

      FRoomInfoList[nIndex].RoomNo := StrToInt(jObjSub.GetValue('teebox_no').Value);
      FRoomInfoList[nIndex].RoomNm := jObjSub.GetValue('teebox_nm').Value;
      FRoomInfoList[nIndex].UseYn := jObjSub.GetValue('use_yn').Value;
      FRoomInfoList[nIndex].DelYn := jObjSub.GetValue('del_yn').Value;
      FRoomInfoList[nIndex].TapoIP := Global.ReadConfigTapoIP_R(FRoomInfoList[nIndex].RoomNo);
      FRoomInfoList[nIndex].TapoMac := Global.ReadConfigTapoMAC_R(FRoomInfoList[nIndex].RoomNo);
      FRoomInfoList[nIndex].UseStatus := '0';

      FRoomInfoList[nIndex].AgentIP_R := Global.ReadConfigAgentIP_R(FRoomInfoList[nIndex].RoomNo);
      FRoomInfoList[nIndex].AgentIP_L := Global.ReadConfigAgentIP_L(FRoomInfoList[nIndex].RoomNo);

      if Global.ADConfig.AgentWOL = True then
      begin
        FRoomInfoList[nIndex].AgentMAC_R := Global.ReadConfigAgentMAC_R(FRoomInfoList[nIndex].RoomNo);
        FRoomInfoList[nIndex].AgentMAC_L := Global.ReadConfigAgentMAC_L(FRoomInfoList[nIndex].RoomNo);
      end;

      if Global.ADConfig.BeamProjectorUse = True then
      begin
        FRoomInfoList[nIndex].BeamType := Global.ReadConfigBeamType(FRoomInfoList[nIndex].RoomNo);
        FRoomInfoList[nIndex].BeamIP := Global.ReadConfigBeamIP(FRoomInfoList[nIndex].RoomNo);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;

  Result := True;
end;

function TRoom.GetTeeboxListToDB: Boolean;
var
  rTeeboxInfoList: TList<TTeeboxInfo>;
  nIndex: Integer;
begin
  Result := False;

  rTeeboxInfoList := Global.XGolfDM.SeatSelect;

  try
    FRoomCnt := rTeeboxInfoList.Count;
    SetLength(FRoomInfoList, FRoomCnt);

    for nIndex := 0 to FRoomCnt - 1 do
    begin
      FRoomInfoList[nIndex].RoomNo := rTeeboxInfoList[nIndex].TeeboxNo;
      FRoomInfoList[nIndex].RoomNm := rTeeboxInfoList[nIndex].TeeboxNm;
      FRoomInfoList[nIndex].UseYn := rTeeboxInfoList[nIndex].UseYn;
      FRoomInfoList[nIndex].DelYn := rTeeboxInfoList[nIndex].DelYn;
      FRoomInfoList[nIndex].TapoIP := Global.ReadConfigTapoIP_R(FRoomInfoList[nIndex].RoomNo);
      FRoomInfoList[nIndex].TapoMac := Global.ReadConfigTapoMAC_R(FRoomInfoList[nIndex].RoomNo);
      FRoomInfoList[nIndex].UseStatus := '0';

      FRoomInfoList[nIndex].AgentIP_R := Global.ReadConfigAgentIP_R(FRoomInfoList[nIndex].RoomNo);
      FRoomInfoList[nIndex].AgentIP_L := Global.ReadConfigAgentIP_L(FRoomInfoList[nIndex].RoomNo);

      if Global.ADConfig.AgentWOL = True then
      begin
        FRoomInfoList[nIndex].AgentMAC_R := Global.ReadConfigAgentMAC_R(FRoomInfoList[nIndex].RoomNo);
        FRoomInfoList[nIndex].AgentMAC_L := Global.ReadConfigAgentMAC_L(FRoomInfoList[nIndex].RoomNo);
      end;

      if Global.ADConfig.BeamProjectorUse = True then
      begin
        FRoomInfoList[nIndex].BeamType := Global.ReadConfigBeamType(FRoomInfoList[nIndex].RoomNo);
        FRoomInfoList[nIndex].BeamIP := Global.ReadConfigBeamIP(FRoomInfoList[nIndex].RoomNo);
      end;
    end;

  finally
    FreeAndNil(rTeeboxInfoList);
  end;

  Result := True;
end;

function TRoom.SetTeeboxStartUseStatus: Boolean;
var
  rTeeboxInfoDBList: TList<TTeeboxInfo>;
  rTeeboxInfoTemp: TTeeboxInfo;
  i, j, nRoomNo, nIndex: Integer;
begin
  rTeeboxInfoDBList := Global.XGolfDM.SeatSelect;

  for i := 0 to FRoomCnt - 1 do
  begin

    nRoomNo := FRoomInfoList[i].RoomNo;

    nIndex := -1;
    for j := 0 to rTeeboxInfoDBList.Count - 1 do
    begin
      if rTeeboxInfoDBList[j].TeeboxNo = nRoomNo then
      begin
        nIndex := j;
        Break;
      end;
    end;

    if nIndex = -1 then
    begin
      rTeeboxInfoTemp.TeeboxNo := FRoomInfoList[i].RoomNo;
      rTeeboxInfoTemp.TeeboxNm := FRoomInfoList[i].RoomNm;
      rTeeboxInfoTemp.FloorZoneCode := '';
      rTeeboxInfoTemp.TeeboxZoneCode := '';
      rTeeboxInfoTemp.TapoMac := '';
      rTeeboxInfoTemp.UseYn := FRoomInfoList[i].UseYn;

      Global.XGolfDM.SeatInsert(Global.ADConfig.StoreCode, rTeeboxInfoTemp);
      Continue;
    end;

    if (FRoomInfoList[i].RoomNm <> rTeeboxInfoDBList[nIndex].TeeboxNm) or
       (FRoomInfoList[i].UseYn <> rTeeboxInfoDBList[nIndex].UseYn) or
       (FRoomInfoList[i].DelYn <> rTeeboxInfoDBList[nIndex].DelYn) then
    begin
      rTeeboxInfoTemp.TeeboxNo := FRoomInfoList[i].RoomNo;
      rTeeboxInfoTemp.TeeboxNm := FRoomInfoList[i].RoomNm;
      rTeeboxInfoTemp.FloorZoneCode := '';
      rTeeboxInfoTemp.FloorNm := '';
      rTeeboxInfoTemp.TeeboxZoneCode := '';
      rTeeboxInfoTemp.TapoMac := '';
      rTeeboxInfoTemp.UseYn := FRoomInfoList[i].UseYn;
      rTeeboxInfoTemp.DelYn := FRoomInfoList[i].DelYn;

      Global.XGolfDM.SeatUpdate(Global.ADConfig.StoreCode, rTeeboxInfoTemp);
    end;

    FRoomInfoList[i].UseStatusPre := rTeeboxInfoDBList[nIndex].UseStatus;
    FRoomInfoList[i].UseStatus := rTeeboxInfoDBList[nIndex].UseStatus;

    if FRoomInfoList[nIndex].RemainMinute > 0 then
      FRoomInfoList[i].TapoOnOff := 'On'
    else
      FRoomInfoList[i].TapoOnOff := 'Off';

    FRoomInfoList[i].TapoError := False;
  end;
  FreeAndNil(rTeeboxInfoDBList);

end;

procedure TRoom.GetRoomReserveApi;
var
  nIdx, nRevCnt, nRevIdx: Integer;
  sResult, sResultCd, sResultMsg, sLog, sEndTime: string;
  sJsonStr: AnsiString;
  jObjArr: TJsonArray;
  jObj, jObjSub: TJSONObject;
begin

  FReserveRecve := False;
  try
    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;
    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K761_RoomReserveList', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
    Global.Log.LogErpApiWrite(sResult);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
      Exit;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K761_RoomReserveList : ' + sResultCd + ' / ' + sResultMsg;
      Global.Log.LogErpApiWrite(sLog);
      Exit;
    end;

    for nIdx := 0 to FRoomCnt - 1 do
    begin
      FRoomInfoList[nIdx].RecvYn := 'N';
    end;

    jObjArr := jObj.GetValue('result_data') as TJsonArray;
    nRevCnt := jObjArr.Size;

    for nRevIdx := 0 to nRevCnt - 1 do
    begin
      jObjSub := jObjArr.Get(nRevIdx) as TJSONObject;
      nIdx := GetRoomInfoIndex(StrToInt(jObjSub.GetValue('teebox_no').Value));

      if FRoomInfoList[nIdx].Reserve.ReserveNo <> jObjSub.GetValue('reserve_no').Value then
      begin
        sLog := 'reserve_no : ' + IntToStr(FRoomInfoList[nIdx].RoomNo) + ' / ' + FRoomInfoList[nIdx].Reserve.ReserveNo + ' -> ' + jObjSub.GetValue('reserve_no').Value;
        Global.Log.LogErpApiWrite(sLog);

        FRoomInfoList[nIdx].Reserve.ReserveYn := 'N';
      end;

      FRoomInfoList[nIdx].Reserve.ReserveNo := jObjSub.GetValue('reserve_no').Value;
      FRoomInfoList[nIdx].Reserve.StartTime := jObjSub.GetValue('start_time').Value;  //10:00
      FRoomInfoList[nIdx].Reserve.EndTime := jObjSub.GetValue('end_time').Value;    //10:55

      sEndTime := formatdatetime('YYYY-MM-DD', Now) + ' ' + FRoomInfoList[nIdx].Reserve.EndTime + ':59';
      FRoomInfoList[nIdx].Reserve.EndDate := DateStrToDateTime2(sEndTime); //YYYY-MM-DD hh:nn:ss 형식

      FRoomInfoList[nIdx].RecvYn := 'Y';
    end;

    FReserveRecve := True;
  finally
    FreeAndNil(jObj);
  end;

  Sleep(10);
end;

procedure TRoom.RoomReserveApiChk;
var
  nIndex, nMin, nSecond: Integer;
  sLog: String;
begin
  if FReserveRecve <> True then
    Exit;

  for nIndex := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[nIndex].RecvYn = 'N' then
    begin
      if FRoomInfoList[nIndex].RemainMinute = 0 then
        Continue;

      sLog := '배정취소 : ' + IntToStr(FRoomInfoList[nIndex].RoomNo) + ' / ' +
              FRoomInfoList[nIndex].RoomNm + ' / ' +
              FRoomInfoList[nIndex].Reserve.ReserveNo;
      Global.Log.LogReserveWrite(sLog);

      FRoomInfoList[nIndex].AgentCtlType := 'E';
      FRoomInfoList[nIndex].AgentCtlYNPre := '0';
      FRoomInfoList[nIndex].AgentCtlYn := '0';
      SetRoomCtrl('Tend', FRoomInfoList[nIndex].Reserve.ReserveNo, FRoomInfoList[nIndex].RoomNo, 0, 0);

      FRoomInfoList[nIndex].RemainMinute := 0;
      continue;
    end;

    if FRoomInfoList[nIndex].RemainMinute > 0 then
      Continue;

    if (FRoomInfoList[nIndex].RemainMinute = 0) and (FRoomInfoList[nIndex].Reserve.ReserveYn <> 'Y') then
    begin
      sLog := '배정구동 : ' + IntToStr(FRoomInfoList[nIndex].RoomNo) + ' / ' +
              FRoomInfoList[nIndex].RoomNm + ' / ' +
              FRoomInfoList[nIndex].Reserve.ReserveNo;
      Global.Log.LogReserveWrite(sLog);

      nMin := MinutesBetween(now, FRoomInfoList[nIndex].Reserve.EndDate);
      nSecond := SecondsBetween(now, FRoomInfoList[nIndex].Reserve.EndDate);

      FRoomInfoList[nIndex].RemainMinute := nMin;
      Global.XGolfDM.TeeboxInfoUpdate(FRoomInfoList[nIndex].RoomNo, FRoomInfoList[nIndex].RemainMinute, '1');

      FRoomInfoList[nIndex].Reserve.ReserveYn := 'Y';

      //배정위해 제어배열에 등록
      FRoomInfoList[nIndex].AgentCtlType := 'S';
      FRoomInfoList[nIndex].AgentCtlYNPre := '0';
      FRoomInfoList[nIndex].AgentCtlYn := '0';
      nSecond := GetReserveEndTime(FRoomInfoList[nIndex].RoomNo);
      SetRoomCtrl('Tstart', FRoomInfoList[nIndex].Reserve.ReserveNo, FRoomInfoList[nIndex].RoomNo, FRoomInfoList[nIndex].RemainMinute, nSecond);
    end;

  end;

  Sleep(10);
end;

procedure TRoom.RoomReserveChk;
var
  nIndex, nMin: Integer;
  sLog: String;
begin

  for nIndex := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[nIndex].Reserve.ReserveNo = '' then
      Continue;

    if FRoomInfoList[nIndex].RemainMinute = 0 then
      Continue;

    //시간계산
    nMin := MinutesBetween(now, FRoomInfoList[nIndex].Reserve.EndDate);
    if nMin < 0 then
      nMin := 0;

    FRoomInfoList[nIndex].RemainMinute := nMin;
    FRoomInfoList[nIndex].UseStatus := '1';

    if FRoomInfoList[nIndex].RemainMinute = 0 then
    begin
      FRoomInfoList[nIndex].UseStatus := '0';

      sLog := '배정종료 : ' + IntToStr(FRoomInfoList[nIndex].RoomNo) + ' / ' +
              FRoomInfoList[nIndex].RoomNm + ' / ' +
              FRoomInfoList[nIndex].Reserve.ReserveNo + ' / ' +
              FRoomInfoList[nIndex].Reserve.EndTime;
      Global.Log.LogReserveWrite(sLog);

      FRoomInfoList[nIndex].AgentCtlType := 'E';
      FRoomInfoList[nIndex].AgentCtlYn := '0';
      FRoomInfoList[nIndex].AgentCtlYNPre := '0';
      SetRoomCtrl('Tend', FRoomInfoList[nIndex].Reserve.ReserveNo, FRoomInfoList[nIndex].RoomNo, 0, 0);
    end;

  end;

  Sleep(10);
end;

procedure TRoom.RoomStatusChk;
var
  nIndex, nMin: Integer;
  sLog: String;
begin

  for nIndex := 0 to FRoomCnt - 1 do
  begin

    if FRoomInfoList[nIndex].AgentCtlYNPre <> FRoomInfoList[nIndex].AgentCtlYN then
    begin
      if FRoomInfoList[nIndex].AgentCtlYN = '1' then
        Global.XGolfDM.UpdateTeeboxAgentStatus(Global.ADConfig.StoreCode, FRoomInfoList[nIndex].RoomNo, '1') //응답받음
      else
        Global.XGolfDM.UpdateTeeboxAgentStatus(Global.ADConfig.StoreCode, FRoomInfoList[nIndex].RoomNo, '0');

      FRoomInfoList[nIndex].AgentCtlYNPre := FRoomInfoList[nIndex].AgentCtlYN;
    end;

    // DB저장: 타석기상태(시간,상태)
    if FRoomInfoList[nIndex].RemainMinPre <> FRoomInfoList[nIndex].RemainMinute then
    begin
      Global.XGolfDM.TeeboxInfoUpdate(FRoomInfoList[nIndex].RoomNo, FRoomInfoList[nIndex].RemainMinute, FRoomInfoList[nIndex].UseStatus);
    end;

    FRoomInfoList[nIndex].RemainMinPre := FRoomInfoList[nIndex].RemainMinute;
  end;

  Sleep(10);
end;

procedure TRoom.SetRoomCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin, ASecond: Integer);
var
  sLogMsg: String;
  sSendStr: AnsiString;
  nIndex, i: Integer;
begin
  if Global.TapoCtrlLock = True then
    Exit;

  if (AType <> 'Tsetting') and (ATeeboxNo = 0) then
    Exit;

  sLogMsg := AType + ' / ' + IntToStr(ATeeboxNo) + ' / ' + AReserveNo + ' / ' + IntToStr(AMin) + ' / ' + IntToStr(ASecond);
  if ATeeboxNo > 0 then
  begin
    nIndex := GetRoomInfoIndex(ATeeboxNo);
    sLogMsg := AType + ' / ' + IntToStr(FRoomInfoList[nIndex].RoomNo) + ' / ' + FRoomInfoList[nIndex].RoomNm+ ' / ' + AReserveNo + ' / ' + IntToStr(AMin) + ' / ' + IntToStr(ASecond);
  end;
  Global.Log.LogCtrlWrite(sLogMsg);

  //9001 준비 'prepare'
  //9002 시작 'start', 'change'
  //9003 종료 'end'
  //9005 설정 'setting'
  (*
  if AType = 'Tprepare' then
  begin
    sSendStr := '{"api_id":9001,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "prepare_min":"' + IntToStr(AMin) + '",' +
                ' "prepare_second":' + IntToStr(ASecond) + '}';
  end;
  *)

  //ERP 에서 정보 받음. 대기 없음.
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

  if Global.ADConfig.AgentSendUse = True then
  begin
    if ATeeboxNo = 0 then
    begin
      for i := 0 to FRoomCnt - 1 do
      begin
        if FRoomInfoList[i].UseYn <> 'Y' then
          Continue;

        if (FRoomInfoList[i].AgentIP_R = '') and (FRoomInfoList[i].AgentIP_L = '') then
        begin
          Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FRoomInfoList[i].RoomNo));
        end
        else
        begin
          if FRoomInfoList[i].AgentIP_R <> '' then
          begin
            //Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[i].AgentIP_R + ' : ' + sSendStr);
            sLogMsg := Global.Api.SendAgentApi(FRoomInfoList[i].AgentIP_R, sSendStr);
            Global.Log.LogCtrlWrite('우- ' + FRoomInfoList[i].AgentIP_R + ' : ' + sLogMsg);
          end;

          if FRoomInfoList[i].AgentIP_L <> '' then
          begin
            //Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[i].AgentIP_L + ' : ' + sSendStr);
            sLogMsg := Global.Api.SendAgentApi(FRoomInfoList[i].AgentIP_L, sSendStr);
            Global.Log.LogCtrlWrite('좌- ' + FRoomInfoList[i].AgentIP_L + ' : ' + sLogMsg);
          end;
        end;

        FRoomInfoList[i].AgentCtlYN := '1';
      end;
    end
    else
    begin
      if (FRoomInfoList[nIndex].AgentIP_R = '') and (FRoomInfoList[nIndex].AgentIP_L = '') then
      begin
        Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FRoomInfoList[nIndex].RoomNo));
      end
      else
      begin
        if FRoomInfoList[nIndex].AgentIP_R <> '' then
        begin
          //Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sSendStr);
          sLogMsg := Global.Api.SendAgentApi(FRoomInfoList[nIndex].AgentIP_R, sSendStr);
          Global.Log.LogCtrlWrite('우- ' + FRoomInfoList[nIndex].AgentIP_R + ' : ' + sLogMsg);
        end;

        if FRoomInfoList[nIndex].AgentIP_L <> '' then
        begin
          //Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sSendStr);
          sLogMsg := Global.Api.SendAgentApi(FRoomInfoList[nIndex].AgentIP_L, sSendStr);
          Global.Log.LogCtrlWrite('좌- ' + FRoomInfoList[nIndex].AgentIP_L + ' : ' + sLogMsg);
        end;
      end;

      FRoomInfoList[nIndex].AgentCtlYN := '1';
    end;
  end
  else
  begin
    Global.TcpAgentServer.BroadcastMessage(sSendStr);
  end;

  if ATeeboxNo = 0 then
    Exit;

  if FRoomInfoList[nIndex].AgentCtlYN = '2' then
    Exit;

  if FRoomInfoList[nIndex].TapoIP = EmptyStr then
  begin
    sLogMsg := 'IP null';
    Global.Log.LogCtrlWrite(sLogMsg);
  end
  else
  begin
    if (AType = 'Tstart') then
    begin
      Global.Tapo.SetDeviceOnOff(FRoomInfoList[nIndex].TapoIP, True, False);
    end
    else if (AType = 'Tend') then
    begin
      Global.Tapo.SetDeviceOnOff(FRoomInfoList[nIndex].TapoIP, False, False);
    end;
  end;

end;

function TRoom.GetReserveEndTime(ARoomNo: Integer): Integer;
var
  tmEndTime: TDateTime;
  nSecond, nIndex: Integer;
  sEndTime: String;
begin
  nSecond := 0;
  nIndex := GetRoomInfoIndex(ARoomNo);
  sEndTime := formatdatetime('YYYY-MM-DD', Now) + ' ' + FRoomInfoList[nIndex].Reserve.EndTime + ':00';
  tmEndTime := DateStrToDateTime2(sEndTime); //YYYY-MM-DD hh:nn:ss 형식
  nSecond := SecondsBetween(now, tmEndTime);
  Result := nSecond;
end;

function TRoom.GetRoomInfoIndex(ARoomNo: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[i].RoomNo = ARoomNo then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TRoom.GetRoomIndexInfo(AIndex: Integer): TRoomInfo;
begin
  Result := FRoomInfoList[AIndex];
end;

function TRoom.GetRoomInfo(ARoomNo: Integer): TRoomInfo;
var
  i: Integer;
begin
  for i := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[i].RoomNo = ARoomNo then
    begin
      Result := FRoomInfoList[i];
      Break;
    end;
  end;
end;

function TRoom.GetRoomInfoIP(AMac: String): String;
var
  i: Integer;
begin
  for i := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[i].TapoMac = AMac then
    begin
      Result := FRoomInfoList[i].TapoIP;
      Break;
    end;
  end;
end;

procedure TRoom.RoomAgentChk;
var
  nIndex, nMin, nSecond: Integer;
begin

  for nIndex := 0 to FRoomCnt - 1 do
  begin

    //Agent에 1회 재시도,  시간이 진행되었을것으로 판단, 분 다시계산
    if FRoomInfoList[nIndex].AgentCtlYn = '0' then
    begin
      if FRoomInfoList[nIndex].AgentCtlType = 'S' then
      begin
        FRoomInfoList[nIndex].AgentCtlYNPre := '2';
        FRoomInfoList[nIndex].AgentCtlYn := '2';
        nSecond := GetReserveEndTime(FRoomInfoList[nIndex].RoomNo);
        SetRoomCtrl('Tstart', FRoomInfoList[nIndex].Reserve.ReserveNo, FRoomInfoList[nIndex].RoomNo, FRoomInfoList[nIndex].RemainMinute, nSecond);
      end;

      if FRoomInfoList[nIndex].AgentCtlType = 'C' then
      begin
        FRoomInfoList[nIndex].AgentCtlYNPre := '2';
        FRoomInfoList[nIndex].AgentCtlYn := '2';
        nSecond := GetReserveEndTime(FRoomInfoList[nIndex].RoomNo);
        SetRoomCtrl('Tchange', FRoomInfoList[nIndex].Reserve.ReserveNo, FRoomInfoList[nIndex].RoomNo, FRoomInfoList[nIndex].RemainMinute, nSecond);
      end;

      if FRoomInfoList[nIndex].AgentCtlType = 'E' then
      begin
        FRoomInfoList[nIndex].AgentCtlYNPre := '2';
        FRoomInfoList[nIndex].AgentCtlYn := '2';
        SetRoomCtrl('Tend', FRoomInfoList[nIndex].Reserve.ReserveNo, FRoomInfoList[nIndex].RoomNo, 0, 0);
      end;

    end;

  end;

  Sleep(10);
end;

procedure TRoom.RoomTapoOnOff;
var
  nIndex: Integer;
  sStr: String;
begin
  if Global.TapoCtrlLock = True then
    Exit;

  for nIndex := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[nIndex].TapoIP = EmptyStr then
      Continue;

    if FRoomInfoList[nIndex].UseStatus = '7' then
    begin
      if FRoomInfoList[nIndex].TapoOnOff <> 'Off' then
      begin
        sStr := 'UseStatus = 7 : On -> Off / No: ' + IntToStr(FRoomInfoList[nIndex].RoomNo);
        Global.Log.LogCtrlWrite(sStr);

        Global.Tapo.SetDeviceOnOff(FRoomInfoList[nIndex].TapoIP, False, False);
      end;
    end
    else
    begin

      if FRoomInfoList[nIndex].RemainMinute > 0 then
      begin
        if FRoomInfoList[nIndex].TapoOnOff <> 'On' then
        begin
          sStr := 'RemainMinute > 0 : Off -> On / No: ' + IntToStr(FRoomInfoList[nIndex].RoomNo);
          Global.Log.LogCtrlWrite(sStr);

          Global.Tapo.SetDeviceOnOff(FRoomInfoList[nIndex].TapoIP, True, False);
        end;
      end
      else
      begin
        if FRoomInfoList[nIndex].TapoOnOff <> 'Off' then
        begin
          sStr := 'RemainMinute =< 0 : On -> Off / No: ' + IntToStr(FRoomInfoList[nIndex].RoomNo);
          Global.Log.LogCtrlWrite(sStr);

          Global.Tapo.SetDeviceOnOff(FRoomInfoList[nIndex].TapoIP, False, False);
        end;
      end;
    end;

  end;

  Sleep(10);
end;


procedure TRoom.RoomTapoOnOffCheck;
var
  nIndex: Integer;
begin
  if Global.TapoCtrlLock = True then
    Exit;

  nIndex := FRoomTapoOnOffCheckLastIndex;
  if FRoomInfoList[nIndex].TapoIP <> EmptyStr then
  begin
    Global.Log.LogCtrlWrite( 'GetDeviceInfo Teebox : ' + FRoomInfoList[nIndex].RoomNm);
    Global.Tapo.GetDeviceInfo(FRoomInfoList[nIndex].TapoIP);
  end;
  inc(FRoomTapoOnOffCheckLastIndex);
  if FRoomTapoOnOffCheckLastIndex > FRoomCnt - 1 then
    FRoomTapoOnOffCheckLastIndex := 0;

  Sleep(10);
end;

procedure TRoom.SetRoomOnOff(AIP, AOnOff: String);
var
  nIndex: integer;
begin
  for nIndex := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[nIndex].TapoIP = AIP then
    begin
      FRoomInfoList[nIndex].TapoOnOff := AOnOff;
      FRoomInfoList[nIndex].TapoError := False;
      Break;
    end;
  end;
end;

procedure TRoom.SetRoomTapoError(AIP: String);
var
  nIndex: integer;
begin
  for nIndex := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[nIndex].TapoIP = AIP then
    begin
      FRoomInfoList[nIndex].TapoError := True;
      Break;
    end;
  end;
end;

procedure TRoom.SetRoomAgentCtlYN(AIP, ARecive: String);
var
  nRoomNo, nIndex: integer;
  jObj: TJSONObject;
  sApiId, sRoomNo, sLeftHanded, sStr: String;
begin

  try
    //{"api_id": "9002", "teebox_no": "1", "reserve_no": "202110240002", "result_cd": "0000", "result_msg": "????? ?? ?????."}
    jObj := TJSONObject.ParseJSONValue(ARecive) as TJSONObject;
    sApiId := jObj.GetValue('api_id').Value;
    sRoomNo := jObj.GetValue('teebox_no').Value;
    sLeftHanded := '0';
    if jObj.FindValue('left_handed') <> nil then
      sLeftHanded := jObj.GetValue('left_handed').Value;

    if sApiId = '9901' then //상태체크
      Exit;

    if (Trim(sApiId) = EmptyStr) or (Trim(sRoomNo) = EmptyStr) then
    begin
      Global.Log.LogWrite('Fail: ' + ARecive);
      Exit;
    end;

    nRoomNo := StrToInt(sRoomNo);
    nIndex := GetRoomInfoIndex(nRoomNo);

    //9001 준비 'prepare'
    //9002 시작 'start', 'change'
    //9003 종료 'end'

    if Global.ADConfig.AgentSendUse <> True then
      FRoomInfoList[nIndex].AgentCtlYN := '1';

    if sLeftHanded = '0' then //우
    begin
      if FRoomInfoList[nIndex].AgentIP_R <> AIP then
      begin
        sStr := 'IP 변경(우) - No: ' + IntToStr(FRoomInfoList[nIndex].RoomNo) + ' / ' + FRoomInfoList[nIndex].AgentIP_R + ' -> ' + AIP;
        Global.Log.LogAgentServerRead(sStr);

        FRoomInfoList[nIndex].AgentIP_R := AIP;
        Global.WriteConfigAgentIP_R(FRoomInfoList[nIndex].RoomNo, FRoomInfoList[nIndex].AgentIP_R);
      end;
    end
    else
    begin
      if FRoomInfoList[nIndex].AgentIP_L <> AIP then
      begin
        sStr := 'IP 변경(좌) - No: ' + IntToStr(FRoomInfoList[nIndex].RoomNo) + ' / ' + FRoomInfoList[nIndex].AgentIP_L + ' -> ' + AIP;
        Global.Log.LogAgentServerRead(sStr);

        FRoomInfoList[nIndex].AgentIP_L := AIP;
        Global.WriteConfigAgentIP_L(FRoomInfoList[nIndex].RoomNo, FRoomInfoList[nIndex].AgentIP_L);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;

end;

procedure TRoom.SetRoomAgentMac(ARoomNo: Integer; AType: String; AMAC: String);
var
  nIndex: integer;
begin

  nIndex := GetRoomInfoIndex(ARoomNo);

  if AType = '0' then //우
  begin
    FRoomInfoList[nIndex].AgentMAC_R := AMAC;
    Global.WriteConfigAgentMAC_R(FRoomInfoList[nIndex].RoomNo, AMAC);
  end
  else
  begin
    FRoomInfoList[nIndex].AgentMAC_L := AMAC;
    Global.WriteConfigAgentMAC_L(FRoomInfoList[nIndex].RoomNo, AMAC);
  end;

end;

function TRoom.SendRoomReserveStatus(ARoomNo: String): Boolean;
var
  jObj: TJSONObject;
  sApiId, sRoomNo, sStatus, sMin, sSecond: String;
  nRoomNo, nSecond, nMin: integer;
  sSendData: AnsiString;
  nIndex: Integer;
  sLogMsg: String;
begin
  Result := False;

  if Trim(ARoomNo) = EmptyStr then
  begin
    //sResult := '{"result_cd":"AD03","result_msg":"Api Fail"}';
    Exit;
  end;

  sRoomNo := ARoomNo;
  nRoomNo := StrToInt(ARoomNo);
  nIndex := GetRoomInfoIndex(nRoomNo);

  if (FRoomInfoList[nIndex].AgentIP_R = '') and (FRoomInfoList[nIndex].AgentIP_L = '') then
  begin
    Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FRoomInfoList[nIndex].RoomNo));
    Exit;
  end;

  //0: 유휴상태, 1: 준비, 2:사용중
  sStatus := '0';
  sMin := '0';
  sSecond := '0';

  //if FRoomInfoList[nIndex].AgentCtlType = 'D' then -> 대기 없음
  if FRoomInfoList[nIndex].RemainMinute > 0 then
  begin
    sStatus := '2';
    sMin := IntToStr(FRoomInfoList[nIndex].RemainMinute);

    nSecond := GetReserveEndTime(nRoomNo);
    sSecond := IntToStr(nSecond);
  end;

  sSendData := '{' +
               '"api_id": 9004,' +
               '"teebox_no": ' + sRoomNo + ',' +
               '"reserve_no": "' + FRoomInfoList[nIndex].Reserve.ReserveNo + '",' +
               '"teebox_status": ' + sStatus + ',' +
               '"remain_min": ' + sMin + ',' +
               '"remain_second": ' + sSecond + ',' +
               '"result_cd": "0000",' +
               '"result_msg": "정상적으로 처리 되었습니다."' +
             '}';

  if FRoomInfoList[nIndex].AgentIP_R <> '' then
  begin
    //Global.Log.LogCtrlWrite('우- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sSendData);
    sLogMsg := Global.Api.SendAgentApi(FRoomInfoList[nIndex].AgentIP_R, sSendData);
    Global.Log.LogCtrlWrite('우- ' + FRoomInfoList[nIndex].AgentIP_R + ' : ' + sLogMsg);
  end;

  if FRoomInfoList[nIndex].AgentIP_L <> '' then
  begin
    //Global.Log.LogCtrlWrite('좌- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sSendData);
    sLogMsg := Global.Api.SendAgentApi(FRoomInfoList[nIndex].AgentIP_L, sSendData);
    Global.Log.LogCtrlWrite('좌- ' + FRoomInfoList[nIndex].AgentIP_L + ' : ' + sLogMsg);
  end;

  FRoomInfoList[nIndex].AgentCtlYN := '1';

  Result := True;
end;

procedure TRoom.SendAgentWOL;
var
  sLogMsg: String;
  i: Integer;
begin

  for i := 0 to FRoomCnt - 1 do
  begin
    if FRoomInfoList[i].UseYn <> 'Y' then
      Continue;

    if (FRoomInfoList[i].AgentMAC_R = '') and (FRoomInfoList[i].AgentMAC_L = '') then
    begin
      Global.Log.LogCtrlWrite('Agent MAC NULL - No: ' + IntToStr(FRoomInfoList[i].RoomNo));
      Continue;
    end;

    if FRoomInfoList[i].AgentMAC_R <> '' then
    begin
      sLogMsg := Global.Api.WakeOnLan(FRoomInfoList[i].AgentMAC_R);
      Global.Log.LogCtrlWrite('R - No:' + IntToStr(FRoomInfoList[i].RoomNo) + ' / ' + FRoomInfoList[i].AgentMAC_R + ' / ' + sLogMsg);
      Sleep(100);
    end;

    if FRoomInfoList[i].AgentMAC_L <> '' then
    begin
      sLogMsg := Global.Api.WakeOnLan(FRoomInfoList[i].AgentMAC_L);
      Global.Log.LogCtrlWrite('L - No:' + IntToStr(FRoomInfoList[i].RoomNo) + ' / ' + FRoomInfoList[i].AgentMAC_L + ' / ' + sLogMsg);
      Sleep(100);
    end;

  end;

end;

procedure TRoom.SendAgentOneWOL(ARoomNo: Integer);
var
  sLogMsg: String;
  nIndex: integer;
begin
  nIndex := GetRoomInfoIndex(ARoomNo);

  if FRoomInfoList[nIndex].UseYn <> 'Y' then
    Exit;

  if (FRoomInfoList[nIndex].AgentMAC_R = '') and (FRoomInfoList[nIndex].AgentMAC_L = '') then
  begin
    Global.Log.LogCtrlWrite('Agent MAC NULL - No: ' + IntToStr(FRoomInfoList[nIndex].RoomNo));
    Exit;
  end;

  if FRoomInfoList[nIndex].AgentMAC_R <> '' then
  begin
    sLogMsg := Global.Api.WakeOnLan(FRoomInfoList[nIndex].AgentMAC_R);
    Global.Log.LogCtrlWrite('R - No:' + IntToStr(FRoomInfoList[nIndex].RoomNo) + ' / ' + FRoomInfoList[nIndex].AgentMAC_R + ' / ' + sLogMsg);
    Sleep(100);
  end;

  if FRoomInfoList[nIndex].AgentMAC_L <> '' then
  begin
    sLogMsg := Global.Api.WakeOnLan(FRoomInfoList[nIndex].AgentMAC_L);
    Global.Log.LogCtrlWrite('L - No:' + IntToStr(FRoomInfoList[nIndex].RoomNo) + ' / ' + FRoomInfoList[nIndex].AgentMAC_L + ' / ' + sLogMsg);
    Sleep(100);
  end;

end;

end.
