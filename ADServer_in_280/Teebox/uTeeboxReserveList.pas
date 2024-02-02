unit uTeeboxReserveList;

interface

uses
  uStruct, uConsts,
  System.Classes, System.SysUtils, System.DateUtils,
  Uni, System.Generics.Collections;

type
  TTeeboxReserveList = class
  private
    FList: array of TReserveList;

    //FTeeboxLastNo: Integer;
    FTeeboxCnt: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure StartUp;

    procedure ReserveListNextChk(ATeeboxNo: Integer);
    //Teebox Thread

    //예약목록에 등록
    function SetTeeboxReserveNext(AReserve: TSeatUseReserve): Boolean;
    function SetTeeboxReserveNextCancel(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveNextChange(ATeeboxNo: Integer; ASeatUseInfo: TSeatUseInfo): Boolean;
    function GetTeeboxReserveNextListCnt(ATeeboxNo: Integer): Integer;
    function SetTeeboxReserveNextCutInCheck(ASeatReserveInfo: TSeatUseReserve): String; //끼어넣기 가능여부 체크
    function SetTeeboxReserveNextCutIn(ASeatReserveInfo: TSeatUseReserve): Boolean; //끼어넣기
    function SetTeeboxReserveNextCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean; //체크인
    function SetTeeboxReserveNextStartNow(ATeeboxNo: Integer; AReserveNo: String): String;

    function GetListIndex(ATeeboxNo: Integer): Integer;

    //예약시간 검증
    function GetTeeboxReserveLastTime(ATeeboxNo: String): String;

    //메인 데이터 확인용
    function GetTeeboxReserveNextView(ATeeboxNo: Integer): String;

    function ReserveListClear: Boolean;

    //function ReSetTeeboxNextReserveData(ATeebox, AIndex, AReserveNo, AreserveDate: String): Boolean;

    property TeeboxCnt: Integer read FTeeboxCnt write FTeeboxCnt;
  end;

implementation

uses
  uGlobal, uFunction, JSON;

{ Tasuk }

constructor TTeeboxReserveList.Create;
begin
  TeeboxCnt := 0;
end;

destructor TTeeboxReserveList.Destroy;
begin
  ReserveListClear;

  inherited;
end;

procedure TTeeboxReserveList.StartUp;
var
  nIndex: Integer;
begin
  FTeeboxCnt := global.teebox.TeeboxCnt;
  SetLength(FList, FTeeboxCnt);

  for nIndex := 0 to FTeeboxCnt - 1 do
  begin
    FList[nIndex].TeeboxNo := global.teebox.GetTeeboxInfoTeeboxNo(nIndex);
    FList[nIndex].ReserveList := TStringList.Create;
  end;
end;

procedure TTeeboxReserveList.ReserveListNextChk(ATeeboxNo: Integer);
var
  nIndex: Integer;
  sLog: String;
  SeatUseReserve: TSeatUseReserve;
begin

  try

    nIndex := GetListIndex(ATeeboxNo);
    if FList[nIndex].CancelYn = 'Y' then //예약삭제중일 경우
    begin
      while True do
      begin
        if FList[nIndex].CancelYn <> 'Y' then
          Break;
      end;
    end;

    if FList[nIndex].ReserveList.Count = 0 then
      Exit;

    //2021-07-21 예약시간되기전에 예약내역으로 들어가지 않도록 처리
    if TNextReserve(FList[nIndex].ReserveList.Objects[0]).ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Exit;

    SeatUseReserve.ReserveNo := TNextReserve(FList[nIndex].ReserveList.Objects[0]).ReserveNo;
    SeatUseReserve.UseStatus := TNextReserve(FList[nIndex].ReserveList.Objects[0]).UseStatus;
    SeatUseReserve.SeatNo := StrToInt(TNextReserve(FList[nIndex].ReserveList.Objects[0]).TeeboxNo);
    SeatUseReserve.UseMinute := StrToInt(TNextReserve(FList[nIndex].ReserveList.Objects[0]).UseMinute);
    SeatUseReserve.DelayMinute := StrToInt(TNextReserve(FList[nIndex].ReserveList.Objects[0]).DelayMinute);
    SeatUseReserve.ReserveDate := TNextReserve(FList[nIndex].ReserveList.Objects[0]).ReserveDate;
    SeatUseReserve.StartTime := TNextReserve(FList[nIndex].ReserveList.Objects[0]).StartTime;
    SeatUseReserve.AssignYn := TNextReserve(FList[nIndex].ReserveList.Objects[0]).AssignYn;

    Global.Teebox.SetTeeboxReserveInfo(SeatUseReserve);

    TNextReserve(FList[nIndex].ReserveList.Objects[0]).Free;
    FList[nIndex].ReserveList.Objects[0] := nil;
    FList[nIndex].ReserveList.Delete(0);

  except
    on e: Exception do
    begin
       sLog := 'SeatReserveNextChk Exception : ' + e.Message;
       Global.Log.LogReserveWrite(sLog);
    end;
  end;

end;

function TTeeboxReserveList.SetTeeboxReserveNext(AReserve: TSeatUseReserve): Boolean;
var
  nIndex: Integer;
  NextReserve: TNextReserve;
begin
  nIndex := GetListIndex(AReserve.SeatNo);

  try
    NextReserve := TNextReserve.Create;
    NextReserve.ReserveNo := AReserve.ReserveNo;
    NextReserve.UseStatus := AReserve.UseStatus;
    NextReserve.TeeboxNo := IntToStr(AReserve.SeatNo);
    NextReserve.TeeboxNm := AReserve.SeatNm;
    NextReserve.UseMinute := IntToStr(AReserve.UseMinute);
    NextReserve.DelayMinute := IntToStr(AReserve.DelayMinute);
    NextReserve.ReserveDate := AReserve.ReserveDate;
    NextReserve.StartTime := AReserve.StartTime;
    NextReserve.AssignYn := AReserve.AssignYn;

    FList[nIndex].ReserveList.AddObject(NextReserve.TeeboxNo, TObject(NextReserve));
  finally
    //FreeAndNil(NextReserve);
  end;
end;

function TTeeboxReserveList.SetTeeboxReserveNextCancel(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  I: Integer;
  nIndex, nUntIn, nCnt: Integer;
  sResult, sLog, sDate: String;
begin
  nIndex := GetListIndex(ATeeboxNo);

  nUntIn := 0;
  nCnt := FList[nIndex].ReserveList.Count - 1;

  FList[nIndex].CancelYn := 'Y';
  for I := 0 to FList[nIndex].ReserveList.Count - 1 do
  begin
    if AReserveNo = TNextReserve(FList[nIndex].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FList[nIndex].ReserveList.Objects[I]).Free;
      FList[nIndex].ReserveList.Objects[I] := nil;
      FList[nIndex].ReserveList.Delete(I);

      nUntIn := I;

      Break;
    end;
  end;
  FList[nIndex].CancelYn := 'N';

  if nUntIn < nCnt then
  begin
    //끼워넣기 대상이였던 배정 끼워넣기 항목Y 처리
    sResult := Global.XGolfDM.SeatUseCutInUseInsert(Global.ADConfig.StoreCode, AReserveNo);
    if sResult <> 'Success' then
      sLog := 'SeatUseCutInUseInsert Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FList[nIndex].TeeboxNm + ' ] ' + AReserveNo
    else
      sLog := 'SeatUseCutInUseInsert : No ' + IntToStr(ATeeboxNo) + ' [ ' + FList[nIndex].TeeboxNm + ' ] ' + AReserveNo;

    Global.Log.LogErpApiWrite(sLog);
  end;

  if nUntIn = nCnt then //마지막 배정예약
  begin
    if FList[nIndex].ReserveList.Count = 0 then //모든예약삭제
    begin
      sDate := FormatDateTime('YYYYMMDDhhnnss', Now);
    end
    else
    begin
      I := FList[nIndex].ReserveList.Count - 1;
      sDate := TNextReserve(FList[nIndex].ReserveList.Objects[I]).ReserveDate;
    end;

    sResult := Global.XGolfDM.SeatUseCutInUseListDelete(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate);
    if sResult <> 'Success' then
      sLog := 'SeatUseCutInUseListDelete Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FList[nIndex].TeeboxNm + ' ] ' + sDate
    else
      sLog := 'SeatUseCutInUseListDelete : No ' + IntToStr(ATeeboxNo) + ' [ ' + FList[nIndex].TeeboxNm + ' ] ' + sDate;

    Global.Log.LogErpApiWrite(sLog);
  end;
end;

function TTeeboxReserveList.SetTeeboxReserveNextChange(ATeeboxNo: Integer; ASeatUseInfo: TSeatUseInfo): Boolean;
var
  I, nIndex: Integer;
  NextReserve: TNextReserve;
  sStr: String;
begin
  Result := False;

  nIndex := GetListIndex(ATeeboxNo);
  if nIndex = -1 then
  begin
    sStr := 'SetTeeboxReserveNextChange TeeboxNo Error: ' + IntTostr(ATeeboxNo);
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  for I := 0 to FList[nIndex].ReserveList.Count - 1 do
  begin
    if ASeatUseInfo.ReserveNo = TNextReserve(FList[nIndex].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FList[nIndex].ReserveList.Objects[I]).DelayMinute := IntToStr(ASeatUseInfo.PrepareMin);
      TNextReserve(FList[nIndex].ReserveList.Objects[I]).UseMinute := IntToStr(ASeatUseInfo.AssignMin);

      Break;
    end;
  end;

  Result := True;
end;

function TTeeboxReserveList.GetTeeboxReserveNextListCnt(ATeeboxNo: Integer): Integer;
var
  nIndex: Integer;
begin
  nIndex := GetListIndex(ATeeboxNo);
  Result := FList[nIndex].ReserveList.Count;
end;

function TTeeboxReserveList.GetTeeboxReserveNextView(ATeeboxNo: Integer): String;
var
  I, nIndex: integer;
  sStr: String;
begin
  sStr := '';
  nIndex := GetListIndex(ATeeboxNo);

  for I := 0 to FList[nIndex].ReserveList.Count - 1 do
  begin
    sStr := sStr + IntToStr(I) + ': ';
    sStr := sStr + TNextReserve(FList[nIndex].ReserveList.Objects[I]).ReserveNo + ' / ' +
          TNextReserve(FList[nIndex].ReserveList.Objects[I]).ReserveDate + ' / ' +
          TNextReserve(FList[nIndex].ReserveList.Objects[I]).DelayMinute  + ' / ' +
          TNextReserve(FList[nIndex].ReserveList.Objects[I]).UseMinute  + ' / ' +
          TNextReserve(FList[nIndex].ReserveList.Objects[I]).AssignYn;

    sStr := sStr + #13#10;
  end;

  Result := sStr;
end;

function TTeeboxReserveList.GetListIndex(ATeeboxNo: Integer): Integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to FTeeboxCnt - 1 do
  begin
    if FList[i].TeeboxNo = ATeeboxNo then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TTeeboxReserveList.GetTeeboxReserveLastTime(ATeeboxNo: String): String; //2020-05-31 예약시간 검증
var
  nReserveIdx, nIndex, nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sReserveDate, sStr, sLog: String;
  DelayMin, UseMin: Integer;
begin
  sStr := '';

  nTeeboxNo := StrToInt(ATeeboxNo);
  nIndex := GetListIndex(nTeeboxNo);
  if FList[nIndex].ReserveList.Count = 0 then
  begin
    Result := sStr;
    Exit;
  end;

  nReserveIdx := FList[nIndex].ReserveList.Count - 1;
  sReserveDate := TNextReserve(FList[nIndex].ReserveList.Objects[nReserveIdx]).ReserveDate;
  DelayMin := StrToInt(TNextReserve(FList[nIndex].ReserveList.Objects[nReserveIdx]).DelayMinute);
  UseMin := StrToInt(TNextReserve(FList[nIndex].ReserveList.Objects[nReserveIdx]).UseMinute);

  ReserveTm := DateStrToDateTime3(sReserveDate) + ( ((1/24)/60) * ( DelayMin + UseMin ) );

  sStr := FormatDateTime('YYYYMMDDhhnnss', ReserveTm);

  Result := sStr;
end;

{
function TTeeboxReserveList.ReSetTeeboxNextReserveData(ATeebox, AIndex, AReserveNo, AreserveDate: String): Boolean;
var
  nTeeboxNo, nIndex: Integer;
begin
  nTeeboxNo := StrToInt(ATeebox);
  nIndex := StrToInt(AIndex);

  if AReserveNo <> '' then
    TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveNo := AReserveNo;

  if AreserveDate <> '' then
    TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate := AreserveDate;

end;
}

function TTeeboxReserveList.ReserveListClear: Boolean;
var
  nIndex, i: Integer;
begin
  for nIndex := 0 to FTeeboxCnt - 1 do
  begin
    for i := 0 to FList[nIndex].ReserveList.Count - 1 do
    begin
      TNextReserve(FList[nIndex].ReserveList.Objects[0]).Free;
      FList[nIndex].ReserveList.Objects[0] := nil;
      FList[nIndex].ReserveList.Delete(0);
    end;
    FreeAndNil(FList[nIndex].ReserveList);
  end;

  SetLength(FList, 0);
end;

function TTeeboxReserveList.SetTeeboxReserveNextStartNow(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sStr, sReserveNoTemp, sReserveDateTemp, sResult: String;
  SeatUseReserve: TSeatUseReserve;
  nIndex: Integer;
begin
  Result := '';

  nIndex := GetListIndex(ATeeboxNo);
  if FList[nIndex].ReserveList.Count = 0 then
  begin
    Result := '대기중인 예약이 없습니다.';
    Exit;
  end;

  sReserveNoTemp := TNextReserve(FList[nIndex].ReserveList.Objects[0]).ReserveNo;
  if sReserveNoTemp <> AReserveNo then
  begin
    Result := '대기중인 예약이 아닙니다.';
    Exit;
  end;

  SeatUseReserve.ReserveNo := TNextReserve(FList[nIndex].ReserveList.Objects[0]).ReserveNo;
  SeatUseReserve.UseStatus := TNextReserve(FList[nIndex].ReserveList.Objects[0]).UseStatus;
  SeatUseReserve.SeatNo := StrToInt(TNextReserve(FList[nIndex].ReserveList.Objects[0]).TeeboxNo);
  SeatUseReserve.UseMinute := StrToInt(TNextReserve(FList[nIndex].ReserveList.Objects[0]).UseMinute);
  SeatUseReserve.DelayMinute := 0;

  sReserveDateTemp := TNextReserve(FList[nIndex].ReserveList.Objects[0]).ReserveDate;
  SeatUseReserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
  SeatUseReserve.StartTime := TNextReserve(FList[nIndex].ReserveList.Objects[0]).StartTime;

  Global.Teebox.SetTeeboxReserveInfo(SeatUseReserve);

  TNextReserve(FList[nIndex].ReserveList.Objects[0]).Free;
  FList[nIndex].ReserveList.Objects[0] := nil;
  FList[nIndex].ReserveList.Delete(0);

  sStr := '즉시배정 no: ' + IntToStr(FList[nIndex].TeeboxNo) + ' / ' +
          FList[nIndex].TeeboxNm + ' / ' +
          SeatUseReserve.ReserveNo + ' / ' + sReserveDateTemp + ' -> ' + SeatUseReserve.ReserveDate;
  Global.Log.LogReserveWrite(sStr);

  //2022-11-22 즉시배정시 DB 대기시간을 현재시간으로 변경- 즉시배정으로 인해 다음 예약이 현배정 대기시간보다 빠를수 있음. 이로인해 잔여시간 계산 오류발생
  sResult := Global.XGolfDM.SeatUseReserveDateUpdate(Global.ADConfig.StoreCode, AReserveNo, formatdatetime('YYYYMMDDHHNN00', now));
  sStr := '즉시배정 ReserveDate 현재시간으로 변경: ' + sResult;
  Global.Log.LogReserveWrite(sStr);

  //2022-10-04 끼어넣기 대상 제외처리
  sResult := Global.XGolfDM.SeatUseCutInUseListDelete(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sReserveDateTemp, True);
  if sResult <> 'Success' then
    sStr := '즉시배정 CutInUseListDelete Fail : No ' + IntToStr(ATeeboxNo) + sReserveDateTemp
  else
    sStr := '즉시배정 CutInUseListDelete : No ' + IntToStr(ATeeboxNo) + sReserveDateTemp;

  Global.Log.LogReserveWrite(sStr);

  Result := 'Success';
end;


function TTeeboxReserveList.SetTeeboxReserveNextCutInCheck(ASeatReserveInfo: TSeatUseReserve): String;
var
  sStr: String;

  nTeeboxIdx: Integer;
  I, nIndex: Integer;
  dtTmTemp: TDateTime;
  sTmTemp, sTmTempE: String;
  bCheck: Boolean;
  rTeeboxInfo: TTeeboxInfo;
begin
  Result := '';

  nTeeboxIdx := GetListIndex(ASeatReserveInfo.SeatNo);

  if FList[nTeeboxIdx].ReserveList.Count = 0 then
  begin
    Result := '끼어넣기를 수행할 예약목록이 없습니다.';
    Exit;
  end;

  nIndex := 0;
  bCheck := False; //동일 예약시간 확인
  for I := 0 to FList[nTeeboxIdx].ReserveList.Count - 1 do
  begin
    if ASeatReserveInfo.ReserveDate <= TNextReserve(FList[nTeeboxIdx].ReserveList.Objects[I]).ReserveDate then
    begin
      if ASeatReserveInfo.ReserveDate = TNextReserve(FList[nTeeboxIdx].ReserveList.Objects[I]).ReserveDate then
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
    rTeeboxInfo := Global.Teebox.GetTeeboxInfo(ASeatReserveInfo.SeatNo);
    if (rTeeboxInfo.UseStatus <> '0') and (rTeeboxInfo.RemainMinute > 0) then
    begin
      dtTmTemp := IncMinute(Now, rTeeboxInfo.RemainMinute); //종료 예상시간
      sTmTemp := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);

      dtTmTemp := DateStrToDateTime3(ASeatReserveInfo.ReserveDate) + (((1/24)/60) * 5);
      sTmTempE := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);
      if sTmTemp > sTmTempE then //예상종료시간이 끼어넣을 (예약시간 + 5분) 보다 크면
      begin
        sStr := 'CutIn check : Fail Index=0 No:' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / EndTm: ' + sTmTemp + ' > CutIn Reserve: ' + ASeatReserveInfo.ReserveDate;
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

    if sTmTemp > TNextReserve(FList[nTeeboxIdx].ReserveList.Objects[nIndex]).ReserveDate then
    begin
      sStr := 'CutIn check : Fail ' + IntToStr(ASeatReserveInfo.SeatNo) + ' / ' + ASeatReserveInfo.ReserveDate + ' - ' + sTmTemp + ' < ' +
              TNextReserve(FList[nTeeboxIdx].ReserveList.Objects[nIndex]).ReserveDate;
      Global.Log.LogReserveWrite(sStr);

      Result := '끼어넣을 배정시간이 다음 예약건의 예약시간을 초과 합니다.';
      Exit;
    end;
  end;

  Result := 'success';
end;

function TTeeboxReserveList.SetTeeboxReserveNextCutIn(ASeatReserveInfo: TSeatUseReserve): Boolean;
var
  sStr: String;

  nTeeboxIdx: Integer;
  NextReserve: TNextReserve;
  I, nIndex: Integer;
begin
  Result := False;

  nTeeboxIdx := GetListIndex(ASeatReserveInfo.SeatNo);

  nIndex := 0;
  for I := 0 to FList[nTeeboxIdx].ReserveList.Count - 1 do
  begin
    if ASeatReserveInfo.ReserveDate < TNextReserve(FList[nTeeboxIdx].ReserveList.Objects[I]).ReserveDate then
    begin
      nIndex := I;

      Break;
    end;
  end;

  NextReserve := TNextReserve.Create;
  NextReserve.ReserveNo := ASeatReserveInfo.ReserveNo;
  NextReserve.UseStatus := ASeatReserveInfo.UseStatus;
  NextReserve.TeeboxNo := IntToStr(ASeatReserveInfo.SeatNo);
  NextReserve.UseMinute := IntToStr(ASeatReserveInfo.UseMinute);
  //NextReserve.UseBalls := IntToStr(ASeatReserveInfo.UseBalls);
  NextReserve.DelayMinute := IntToStr(ASeatReserveInfo.DelayMinute);
  NextReserve.ReserveDate := ASeatReserveInfo.ReserveDate;
  NextReserve.StartTime := ASeatReserveInfo.StartTime;
  NextReserve.AssignYn := ASeatReserveInfo.AssignYn;

  FList[nTeeboxIdx].ReserveList.InsertObject(nIndex, NextReserve.TeeboxNo, TObject(NextReserve));

  sStr := 'CutIn no: ' + IntToStr(ASeatReserveInfo.SeatNo) + ' / nIndex: ' + IntToStr(nIndex) + ' / ' + ASeatReserveInfo.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

function TTeeboxReserveList.SetTeeboxReserveNextCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  I, nTeeboxIdx: Integer;
  sStr: String;
  bCheck: Boolean;
begin
  bCheck := False;

  nTeeboxIdx := GetListIndex(ATeeboxNo);

  for I := 0 to FList[nTeeboxIdx].ReserveList.Count - 1 do
  begin
    if AReserveNo = TNextReserve(FList[nTeeboxIdx].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FList[nTeeboxIdx].ReserveList.Objects[I]).AssignYn := 'Y';
      bCheck := True;

      Break;
    end;
  end;

  if bCheck = True then
    sStr := 'checkIn next no: ' + IntToStr(FList[nTeeboxIdx].TeeboxNo) + ' / ' + FList[nTeeboxIdx].TeeboxNm + ' / ' + AReserveNo
  else
    sStr := 'checkIn next not find no: ' + IntToStr(FList[nTeeboxIdx].TeeboxNo) + ' / ' + FList[nTeeboxIdx].TeeboxNm + ' / ' + AReserveNo;

  Global.Log.LogReserveWrite(sStr);
end;

end.
