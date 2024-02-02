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

    //�����Ͽ� ���
    function SetTeeboxReserveNext(AReserve: TSeatUseReserve): Boolean;
    function SetTeeboxReserveNextCancel(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveNextChange(ATeeboxNo: Integer; ASeatUseInfo: TSeatUseInfo): Boolean;
    function GetTeeboxReserveNextListCnt(ATeeboxNo: Integer): Integer;
    function SetTeeboxReserveNextCutInCheck(ASeatReserveInfo: TSeatUseReserve): String; //����ֱ� ���ɿ��� üũ
    function SetTeeboxReserveNextCutIn(ASeatReserveInfo: TSeatUseReserve): Boolean; //����ֱ�
    function SetTeeboxReserveNextCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean; //üũ��
    function SetTeeboxReserveNextStartNow(ATeeboxNo: Integer; AReserveNo: String): String;

    function ResetTeeboxReserveMinAddJMS(ATeeboxNo, ADelayTm: Integer): Boolean;

    //����ð� Ȯ��
    function GetTeeboxReserveLastTime(ATeeboxNo: String): String; //2020-05-31 ����ð� ����

    //2020-06-29 ���۽ð����� ��������� ����ð� ����
    //function ResetReserveDateTime(ATeeboxNo: Integer; ATeeboxNm: String; AssignMin: Integer): Boolean;

    //���� ������ Ȯ�ο�
    function GetTeeboxReserveNextView(ATeeboxNo: Integer): String;

    function ReserveListClear: Boolean;

    function ReSetTeeboxNextReserveData(ATeebox, AIndex, AReserveNo, AreserveDate: String): Boolean;

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

    if FList[ATeeboxNo].CancelYn = 'Y' then //����������� ���
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

    //2021-07-21 ����ð��Ǳ����� ���೻������ ���� �ʵ��� ó��
    if TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Exit;

    SeatUseReserve.ReserveNo := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).ReserveNo;
    SeatUseReserve.UseStatus := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).UseStatus;
    SeatUseReserve.SeatNo := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).SeatNo);
    SeatUseReserve.UseMinute := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).UseMinute);
    SeatUseReserve.UseBalls := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).UseBalls);
    SeatUseReserve.DelayMinute := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).DelayMinute);
    SeatUseReserve.ReserveDate := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).ReserveDate;
    SeatUseReserve.StartTime := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).StartTime;
    SeatUseReserve.AssignYn := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[nIndex]).AssignYn;

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
    NextReserve.SeatNo := IntToStr(AReserve.SeatNo);
    NextReserve.SeatNm := AReserve.SeatNm;
    NextReserve.UseMinute := IntToStr(AReserve.UseMinute);
    NextReserve.UseBalls := IntToStr(AReserve.UseBalls);
    NextReserve.DelayMinute := IntToStr(AReserve.DelayMinute);
    NextReserve.ReserveDate := AReserve.ReserveDate;
    NextReserve.StartTime := AReserve.StartTime;
    NextReserve.AssignYn := AReserve.AssignYn;

    FList[nTeeboxNo].ReserveList.AddObject(NextReserve.SeatNo, TObject(NextReserve));
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

  if nUntIn < nCnt then
  begin
    //�����ֱ� ����̿��� ���� �����ֱ� �׸�Y ó��
    sResult := Global.XGolfDM.SeatUseCutInUseInsert(Global.ADConfig.StoreCode, AReserveNo);
    if sResult <> 'Success' then
      sLog := 'SeatUseCutInUseInsert Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FList[ATeeboxNo].TeeboxNm + ' ] ' + AReserveNo
    else
      sLog := 'SeatUseCutInUseInsert : No ' + IntToStr(ATeeboxNo) + ' [ ' + FList[ATeeboxNo].TeeboxNm + ' ] ' + AReserveNo;

    Global.Log.LogErpApiWrite(sLog);
  end;

  if nUntIn = nCnt then //������ ��������
  begin
    if FList[ATeeboxNo].ReserveList.Count = 0 then //��翹�����
    begin
      sDate := FormatDateTime('YYYYMMDDhhnnss', Now);
    end
    else
    begin
      I := FList[ATeeboxNo].ReserveList.Count - 1;
      sDate := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate;
    end;

    sResult := Global.XGolfDM.SeatUseCutInUseListDelete(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate);
    if sResult <> 'Success' then
      sLog := 'SeatUseCutInUseListDelete Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FList[ATeeboxNo].TeeboxNm + ' ] ' + sDate
    else
      sLog := 'SeatUseCutInUseListDelete : No ' + IntToStr(ATeeboxNo) + ' [ ' + FList[ATeeboxNo].TeeboxNm + ' ] ' + sDate;

    Global.Log.LogErpApiWrite(sLog);
  end;

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

function TTeeboxReserveList.SetTeeboxReserveNextCutInCheck(ASeatReserveInfo: TSeatUseReserve): String;
var
  sStr: String;

  nTeeboxNo: Integer;
  I, nIndex: Integer;
  dtTmTemp: TDateTime;
  sTmTemp, sTmTempE: String;
  bCheck: Boolean;
  rTeeboxInfo: TTeeboxInfo;
begin
  Result := '';

  nTeeboxNo := ASeatReserveInfo.SeatNo;

  if FList[nTeeboxNo].ReserveList.Count = 0 then
  begin
    Result := '����ֱ⸦ ������ �������� �����ϴ�.';
    Exit;
  end;

  nIndex := 0;
  bCheck := False; //���� ����ð� Ȯ��
  for I := 0 to FList[nTeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatReserveInfo.ReserveDate <= TNextReserve(FList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
    begin
      if ASeatReserveInfo.ReserveDate = TNextReserve(FList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
        bCheck := True;

      nIndex := I;
      Break;
    end;
  end;

  if bCheck = True then
  begin
    Result := '������ ����ð����� ����� ������ �ֽ��ϴ�.';
    Exit;
  end;

  if nIndex = 0 then //������ ù��° ����
  begin
    //���� ����̸� ����ð� üũ
    rTeeboxInfo := Global.Teebox.GetTeeboxInfo(nTeeboxNo);
    if (rTeeboxInfo.UseStatus <> '0') and (rTeeboxInfo.RemainMinute > 0) then
    begin
      dtTmTemp := IncMinute(Now, rTeeboxInfo.RemainMinute); //���� ����ð�
      sTmTemp := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);

      dtTmTemp := DateStrToDateTime3(ASeatReserveInfo.ReserveDate) + (((1/24)/60) * 5);
      sTmTempE := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);
      if sTmTemp > sTmTempE then //��������ð��� ������� (����ð� + 5��) ���� ũ��
      begin
        sStr := 'CutIn check : Fail Index=0 ' + IntToStr(nTeeboxNo) + ' / EndTm: ' + sTmTemp + ' > CutIn Reserve: ' + ASeatReserveInfo.ReserveDate;
        Global.Log.LogReserveWrite(sStr);

        Result := 'Ÿ������ð��� ����ð����� Ů�ϴ�.';
        Exit;
      end;

    end;
  end
  else
  begin

    dtTmTemp := DateStrToDateTime3(ASeatReserveInfo.ReserveDate) + (((1/24)/60) * (ASeatReserveInfo.DelayMinute + ASeatReserveInfo.UseMinute));
    sTmTemp := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);

    if sTmTemp > TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate then
    begin
      sStr := 'CutIn check : Fail ' + IntToStr(nTeeboxNo) + ' / ' + ASeatReserveInfo.ReserveDate + ' - ' + sTmTemp + ' < ' +
              TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate;
      Global.Log.LogReserveWrite(sStr);

      Result := '������� �����ð��� ���� ������� ����ð��� �ʰ� �մϴ�.';
      Exit;
    end;
  end;

  Result := 'success';
end;

function TTeeboxReserveList.SetTeeboxReserveNextCutIn(ASeatReserveInfo: TSeatUseReserve): Boolean;
var
  sStr: String;

  nTeeboxNo: Integer;
  NextReserve: TNextReserve;
  I, nIndex: Integer;
begin
  Result := False;

  nTeeboxNo := ASeatReserveInfo.SeatNo;

  nIndex := 0;
  for I := 0 to FList[nTeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatReserveInfo.ReserveDate < TNextReserve(FList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
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
  NextReserve.AssignYn := ASeatReserveInfo.AssignYn;

  FList[nTeeboxNo].ReserveList.InsertObject(nIndex, NextReserve.SeatNo, TObject(NextReserve));

  sStr := 'CutIn no: ' + IntToStr(nTeeboxNo) + ' / nIndex: ' + IntToStr(nIndex) + ' / ' + ASeatReserveInfo.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
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
          TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).UseMinute  + ' / ' +
          TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).AssignYn;

    sStr := sStr + #13#10;
  end;

  Result := sStr;
end;

function TTeeboxReserveList.GetTeeboxReserveLastTime(ATeeboxNo: String): String; //2020-05-31 ����ð� ����
var
  nIdx, nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sReserveDate, sStr, sLog: String;
  DelayMin, UseMin: Integer;
begin
  sStr := '';

  nTeeboxNo := StrToInt(ATeeboxNo);
  if FList[nTeeboxNo].ReserveList.Count = 0 then
  begin
    Result := sStr;
    Exit;
  end;

  nIdx := FList[nTeeboxNo].ReserveList.Count - 1;
  sReserveDate := TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIdx]).ReserveDate;
  DelayMin := StrToInt(TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIdx]).DelayMinute);
  UseMin := StrToInt(TNextReserve(FList[nTeeboxNo].ReserveList.Objects[nIdx]).UseMinute);

  ReserveTm := DateStrToDateTime3(sReserveDate) + ( ((1/24)/60) * ( DelayMin + UseMin ) );

  //sStr := FormatDateTime('YYYYMMDDhhnnss', ReserveTm);
  sStr := FormatDateTime('YYYYMMDDhhnn00', ReserveTm); //2021-06-11

  Result := sStr;
end;

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
{
function TTeeboxReserveList.ResetReserveDateTime(ATeeboxNo: Integer; ATeeboxNm: String; AssignMin: Integer): Boolean;
var
  tmNowEnd, tmNextStart: TDateTime;
  nMin, nDelayMin, I, nTemp: Integer;
  sDate, sReserveDate, sReserveNo, sResult, sStr: String;
begin

  if FList[ATeeboxNo].ReserveList.Count = 0 then
    Exit;

  for I := 0 to FList[ATeeboxNo].ReserveList.Count - 1 do
  begin

    if I = 0 then
    begin
      nMin := AssignMin;
      tmNowEnd := IncMinute(now(), nMin + 1); //2021-06-11
    end
    else
    begin
      nMin := StrToInt( TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I-1]).UseMinute );
      nDelayMin := StrToInt( TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I-1]).DelayMinute );
      tmNowEnd := IncMinute(DateStrToDateTime3( TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I-1]).ReserveDate ), nMin + nDelayMin + 1);
    end;

    sDate := formatdatetime('YYYYMMDDHHNN00', tmNowEnd); //2021-06-11
    sReserveDate := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate;

    if I = 0 then
    begin
      tmNextStart := DateStrToDateTime3( sReserveDate );
      nTemp := MinutesBetween(tmNowEnd, tmNextStart);

      if nTemp < 4 then
        Exit;
    end;

    if Copy(sReserveDate, 1, 12) < Copy(sDate, 1, 12) then
    begin
      TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate := sDate;

      sReserveNo := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo;
      sResult := Global.XGolfDM.SetSeatReserveStartTmChange(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, sReserveNo);

      sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + sReserveNo + ' / ' + sReserveDate + ' -> ' + sDate;
      Global.Log.LogErpApiWrite('ResetReserveDateTime : ' + sStr);
    end;

  end;

end;
}
function TTeeboxReserveList.SetTeeboxReserveNextCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  I: Integer;
  sStr: String;
  bCheck: Boolean;
begin
  bCheck := False;

  for I := 0 to FList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    if AReserveNo = TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).AssignYn := 'Y';
      bCheck := True;

      Break;
    end;
  end;

  if bCheck = True then
    sStr := 'checkIn next no: ' + IntToStr(FList[ATeeboxNo].TeeboxNo) + ' / ' + FList[ATeeboxNo].TeeboxNm + ' / ' + AReserveNo
  else
    sStr := 'checkIn next not find no: ' + IntToStr(FList[ATeeboxNo].TeeboxNo) + ' / ' + FList[ATeeboxNo].TeeboxNm + ' / ' + AReserveNo;

  Global.Log.LogReserveWrite(sStr);
end;

function TTeeboxReserveList.SetTeeboxReserveNextStartNow(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sStr, sReserveNoTemp, sReserveDateTemp, sResult: String;
  SeatUseReserve: TSeatUseReserve;
begin
  Result := '';

  if FList[ATeeboxNo].ReserveList.Count = 0 then
  begin
    Result := '������� ������ �����ϴ�.';
    Exit;
  end;

  sReserveNoTemp := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).ReserveNo;
  if sReserveNoTemp <> AReserveNo then
  begin
    Result := '������� ������ �ƴմϴ�.';
    Exit;
  end;

  SeatUseReserve.ReserveNo := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).ReserveNo;
  SeatUseReserve.UseStatus := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).UseStatus;
  SeatUseReserve.SeatNo := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).SeatNo);
  SeatUseReserve.UseMinute := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).UseMinute);
  SeatUseReserve.UseBalls := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).UseBalls);

  { �������� nano -> nano2 �� ���� 2022-08-22
  if (Global.ADConfig.ProtocolType = 'NANO') and (Global.ADConfig.StoreCode = 'B8001') then //'B8001' �������̰���Ŭ��
    SeatUseReserve.DelayMinute := StrToInt(TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).DelayMinute)
  else }
    SeatUseReserve.DelayMinute := 0;

  sReserveDateTemp := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).ReserveDate;
  SeatUseReserve.ReserveDate := formatdatetime('YYYYMMDDHHNN00', now); //2021-06-11
  SeatUseReserve.StartTime := TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).StartTime;

  Global.Teebox.SetTeeboxReserveInfo(SeatUseReserve);

  TNextReserve(FList[ATeeboxNo].ReserveList.Objects[0]).Free;
  FList[ATeeboxNo].ReserveList.Objects[0] := nil;
  FList[ATeeboxNo].ReserveList.Delete(0);

  sStr := '��ù��� no: ' + IntToStr(FList[ATeeboxNo].TeeboxNo) + ' / ' +
          FList[ATeeboxNo].TeeboxNm + ' / ' +
          SeatUseReserve.ReserveNo + ' / ' + sReserveDateTemp + ' -> ' + SeatUseReserve.ReserveDate;
  Global.Log.LogReserveWrite(sStr);

  //2022-11-22 ��ù����� DB ���ð��� ����ð����� ����- ��ù������� ���� ���� ������ ������ ���ð����� ������ ����. �̷����� �ܿ��ð� ��� �����߻�
  sResult := Global.XGolfDM.SeatUseReserveDateUpdate(Global.ADConfig.StoreCode, AReserveNo, formatdatetime('YYYYMMDDHHNN00', now));
  sStr := '��ù��� ReserveDate ����ð����� ����: ' + sResult;
  Global.Log.LogReserveWrite(sStr);

  //2021-08-03 ����ֱ� ��� ����ó��
  sResult := Global.XGolfDM.SeatUseCutInUseListDelete(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sReserveDateTemp, True);
  if sResult <> 'Success' then
    sStr := '��ù��� CutInUseListDelete Fail : No ' + IntToStr(ATeeboxNo) + sReserveDateTemp
  else
    sStr := '��ù��� CutInUseListDelete : No ' + IntToStr(ATeeboxNo) + sReserveDateTemp;

  Global.Log.LogReserveWrite(sStr);

  Result := 'Success';
end;

function TTeeboxReserveList.ResetTeeboxReserveMinAddJMS(ATeeboxNo, ADelayTm: Integer): Boolean;
var
  sResult: String;
  sDate, sStr: String;
  I: integer;
  tmReserve: TDateTime;
begin
  if ADelayTm = 0 then
    Exit;

  if FList[ATeeboxNo].ReserveList.Count = 0 then
    Exit;

  for I := 0 to FList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    tmReserve := IncMinute(DateStrToDateTime3( TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate ), ADelayTm);
    sDate := formatdatetime('YYYYMMDDHHNN00', tmReserve); //2021-06-11
    TNextReserve(FList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate := sDate;
  end;

  sDate := formatdatetime('YYYYMMDD', Now);
  sResult := Global.XGolfDM.SetSeatReserveTmChange(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm), '');
  sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + FList[ATeeboxNo].TeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm);
  Global.Log.LogReserveWrite('ResetTeeboxRemainMinAdd : ' + sStr);

end;


end.
