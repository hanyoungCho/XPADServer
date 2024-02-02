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

    FTeeboxLastNo: Integer;
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
    function SetTeeboxReserveNextStartNow(ATeeboxNo: Integer; AReserveNo: String): String;

    //예약시간 검증
    function GetTeeboxReserveLastTime(ATeeboxNo: String): String;

    //메인 데이터 확인용
    function GetTeeboxReserveNextView(ATeeboxNo: Integer): String;

    function ReserveListClear: Boolean;

    property TeeboxLastNo: Integer read FTeeboxLastNo write FTeeboxLastNo;
  end;

implementation

uses
  uGlobal, uFunction, JSON;

{ Tasuk }

constructor TTeeboxReserveList.Create;
begin
  TeeboxLastNo := 0;
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
  FTeeboxLastNo := global.teebox.teeboxlastno;
  SetLength(FList, FTeeboxLastNo + 1);

  for nIndex := 1 to FTeeboxLastNo do
  begin
    FList[nIndex].TeeboxNo := nIndex;
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

    if FList[ATeeboxNo].CancelYn = 'Y' then //예약삭제중일 경우
    begin
      while True do
      begin
        if FList[ATeeboxNo].CancelYn <> 'Y' then
          Break;
      end;
    end;

    if FList[ATeeboxNo].ReserveList.Count = 0 then
      Exit;

    nIndex := 0;

    //2021-07-21 예약시간되기전에 예약내역으로 들어가지 않도록 처리
    if TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Exit;

    SeatUseReserve.ReserveNo := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).ReserveNo;
    SeatUseReserve.UseStatus := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).UseStatus;
    SeatUseReserve.SeatNo := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).TeeboxNo);
    SeatUseReserve.UseMinute := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).UseMinute);
    SeatUseReserve.DelayMinute := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).DelayMinute);
    SeatUseReserve.ReserveDate := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).ReserveDate;
    SeatUseReserve.StartTime := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).StartTime;

    Global.Teebox.SetTeeboxReserveInfo(SeatUseReserve);

    TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).Free;
    FList[ATeeboxNo].ReserveList.Objects[nIndex] := nil;
    FList[ATeeboxNo].ReserveList.Delete(nIndex);

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
  nTeeboxNo: Integer;
  NextReserve: TNextReserve;
begin
  nTeeboxNo := AReserve.SeatNo;

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

    FList[nTeeboxNo].ReserveList.AddObject(NextReserve.TeeboxNo, TObject(NextReserve));
  finally
    //FreeAndNil(NextReserve);
  end;
end;

function TTeeboxReserveList.SetTeeboxReserveNextCancel(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  I: Integer;
  nUntIn, nCnt: Integer;
  sResult, sLog, sDate: String;
begin
  nUntIn := 0;
  nCnt := FList[ATeeboxNo].ReserveList.Count - 1;

  FList[ATeeboxNo].CancelYn := 'Y';
  for I := 0 to FList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    if AReserveNo = TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).Free;
      FList[ATeeboxNo].ReserveList.Objects[I] := nil;
      FList[ATeeboxNo].ReserveList.Delete(I);

      nUntIn := I;

      Break;
    end;
  end;
  FList[ATeeboxNo].CancelYn := 'N';
  
end;

function TTeeboxReserveList.SetTeeboxReserveNextChange(ATeeboxNo: Integer; ASeatUseInfo: TSeatUseInfo): Boolean;
var
  I: Integer;
  NextReserve: TNextReserve;
begin

  for I := 0 to FList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatUseInfo.ReserveNo = TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).DelayMinute := IntToStr(ASeatUseInfo.PrepareMin);
      TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).UseMinute := IntToStr(ASeatUseInfo.AssignMin);

      Break;
    end;
  end;

end;

function TTeeboxReserveList.GetTeeboxReserveNextListCnt(ATeeboxNo: Integer): Integer;
begin
  Result := FList[ATeeboxNo].ReserveList.Count;
end;

function TTeeboxReserveList.GetTeeboxReserveNextView(ATeeboxNo: Integer): String;
var
  I: integer;
  sStr: String;
begin
  sStr := '';
  for I := 0 to FList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    sStr := sStr + IntToStr(I) + ': ';
    sStr := sStr + TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo + ' / ' +
          TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate + ' / ' +
          TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).DelayMinute  + ' / ' +
          TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).UseMinute;

    sStr := sStr + #13#10;
  end;

  Result := sStr;
end;

function TTeeboxReserveList.GetTeeboxReserveLastTime(ATeeboxNo: String): String; //2020-05-31 예약시간 검증
var
  nIdx, nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sReserveDate, sStr, sLog: String;
  DelayMin, UseMin: Integer;
begin
  sStr := '0';

  nTeeboxNo := StrToInt(ATeeboxNo);
  if FList[nTeeboxNo].ReserveList.Count = 0 then
    Exit;

  nIdx := FList[nTeeboxNo].ReserveList.Count - 1;
  sReserveDate := TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIdx]).ReserveDate;
  DelayMin := StrToInt(TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIdx]).DelayMinute);
  UseMin := StrToInt(TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIdx]).UseMinute);

  ReserveTm := DateStrToDateTime3(sReserveDate) + ( ((1/24)/60) * ( DelayMin + UseMin ) );

  sStr := FormatDateTime('YYYYMMDDhhnnss', ReserveTm);

  Result := sStr;
end;

function TTeeboxReserveList.ReserveListClear: Boolean;
var
  nTee, nIdx: Integer;
begin
  for nTee := 1 to TeeboxLastNo do
  begin
    for nIdx := 0 to FList[nTee].ReserveList.Count - 1 do
    begin
      TNextReserve(FList[nTee].ReserveList.Objects[0]).Free;
      FList[nTee].ReserveList.Objects[0] := nil;
      FList[nTee].ReserveList.Delete(0);
    end;
    FreeAndNil(FList[nTee].ReserveList);
  end;

  SetLength(FList, 0);
end;

function TTeeboxReserveList.SetTeeboxReserveNextStartNow(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sStr, sReserveNoTemp, sReserveDateTemp, sResult: String;
  SeatUseReserve: TSeatUseReserve;
begin
  Result := '';

  if FList[ATeeboxNo].ReserveList.Count = 0 then
  begin
    Result := '대기중인 예약이 없습니다.';
    Exit;
  end;

  sReserveNoTemp := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).ReserveNo;
  if sReserveNoTemp <> AReserveNo then
  begin
    Result := '대기중인 예약이 아닙니다.';
    Exit;
  end;

  SeatUseReserve.ReserveNo := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).ReserveNo;
  SeatUseReserve.UseStatus := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).UseStatus;
  SeatUseReserve.SeatNo := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).TeeboxNo);
  SeatUseReserve.UseMinute := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).UseMinute);
  SeatUseReserve.DelayMinute := 0;

  sReserveDateTemp := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).ReserveDate;
  SeatUseReserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
  SeatUseReserve.StartTime := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).StartTime;

  Global.Teebox.SetTeeboxReserveInfo(SeatUseReserve);

  TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).Free;
  FList[ATeeboxNo].ReserveList.Objects[0] := nil;
  FList[ATeeboxNo].ReserveList.Delete(0);

  sStr := 'Start Now no: ' + IntToStr(FList[ATeeboxNo].TeeboxNo) + ' / ' +
          FList[ATeeboxNo].TeeboxNm + ' / ' +
          SeatUseReserve.ReserveNo + ' / ' + sReserveDateTemp + ' -> ' + SeatUseReserve.ReserveDate;
  Global.Log.LogReserveWrite(sStr);
  
  Result := 'Success';
end;

end.
