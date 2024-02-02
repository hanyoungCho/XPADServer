unit uComModenYJ;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadModenYJ = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FRecvDataTM: AnsiString;
    FSendDataTM: AnsiString;

    FReTry: Integer;
    FReceived: Boolean;

    FIndex: Integer;
    FFloorCd: String; //층

    FTeeboxNoStart: Integer; //시작 타석번호
    FTeeboxNoEnd: Integer; //종료 타석번호
    FTeeboxNoLast: Integer; //마지막 요청 타석번호

    FWriteTm: TDateTime;
    FTeeboxInfo: TTeeboxInfo;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetMonSendBuffer;

    procedure SetErrCnt(ATeeboxNo: Integer);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadModenYJ }

constructor TComThreadModenYJ.Create;
begin
  {
  ['AX','AW','AV','AU','AT','AS','AR','AQ','AP','AI',
   'AH','AG','AF','AE','AD','AC','AB','AA','A@','A9',
   'A8','A7','A6','A5','A4','A3','A2','A1',
   'BX','BW','BV','BU','BT','BS','BR','BQ','BP','BI',
   'BH','BG','BF','BE','BD','BC','BB','BA','B@','B9',
   'B8','B7','B6','B5','B4','B3','B2','B1'];
  }

  FReTry := 0;

  FReceived := True;
  FTeeboxNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadModenYJ Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadModenYJ.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadModenYJ.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
begin
  FTeeboxNoStart := ATeeboxNoStart;
  FTeeboxNoEnd := ATeeboxNoEnd;
  FTeeboxNoLast := ATeeboxNoStart;
  FIndex := AIndex;
  FFloorCd := AFloorCd;

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(APort);
  FComPort.BaudRate := GetBaudrate(ABaudRate);
  FComPort.Open;

  Global.Log.LogWrite('TComThreadModen ComPortSetting : ' + FFloorCd);
end;

procedure TComThreadModenYJ.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;

  Index: Integer;
  sRecvData, sChannelTM, sCommand, sState, sMin, sErr: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx, nPos: Integer;
  bExcept: Boolean;

  sBuffer: String;
begin

  //요청한 장치의 응답값이 아닌 이전 요청에 대한 응답값이 들어옴
  //JMS 와 동일한 방식으로 요청. 기존GM 에서 현재 시간으로 제어만 요청하고 응답이 해당 장치인지 확인하지 않음
  //제어 요청시 해당 장치의 통신이상 유무를 체크할수 없음
  bExcept := False;

  FComPort.ReadStr(sBuffer, Count);
  {
  nPos := Pos(MODEN_STX + 'L', sBuffer);
  if (nPos > 0) then
     FRecvData := Copy(sBuffer, nPos, Count)
  else  }
     FRecvData := FRecvData + sBuffer;

  nPos := Pos(MODEN_ETX, FRecvData);
  if (nPos > 0) then
  begin
     sRecvData := Copy(FRecvData, nPos - 48, nPos);

     //수신 완료 처리
    FRecvData := '';
  end
  else
  begin
    Exit;
  end;

  //sLogMsg := 'sRecvData : ' + sRecvData;
  //Global.Log.LogRetryWrite(sLogMsg);

  {
  if (Length(FRecvData) <> 48) then
  begin
    //Global.Log.LogCtrlWrite('FRecvData fail : ' + FRecvData);
    Global.Log.LogRetryWrite('<> 48');
    FRecvData := '';
    Exit;
  end;
  }
  //.L00000000000000 A.BA064000T00000 00000000000000r.
  //.L00000000000000 ABA063000T000100 00000000000000@.

  //.L00000000000000 BWXXXXXXXXXXXX00 00000000000000W.

  //.L00000000000000 BVA000000T015100 000000000000002.

  if (Copy(sRecvData, 18, 1) = '.') or (Copy(sRecvData, 18, 1) = '')then
  begin
    //Global.Log.LogCtrlWrite('FRecvData . : ' + FRecvData);
    //Global.Log.LogRetryWrite('FRecvData . : ' + FRecvData);
    sChannelTM := Copy(sRecvData, 17, 1) + Copy(sRecvData, 19, 1);
    bExcept := True;
  end
  else
  begin
    sChannelTM := Copy(sRecvData, 17, 2);
  end;

  rTeeboxInfo.StoreCd := '';
  rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo; //요청한 타석 번호
  rTeeboxInfo.RecvDeviceId := FTeeboxInfo.DeviceId;
  rTeeboxInfo.TeeboxNm := FTeeboxInfo.TeeboxNm;  //요청한 타석명
  rTeeboxInfo.FloorZoneCode := '';
  rTeeboxInfo.TeeboxZoneCode := '';
  rTeeboxInfo.UseYn := '';

  if FTeeboxInfo.DeviceId <> sChannelTM then
  begin
    sLogMsg := 'Fail No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + rTeeboxInfo.TeeboxNm + ' : ' + FSendDataTM + ' / ' + sRecvData;
    Global.Log.LogReadMulti(FIndex, sLogMsg);

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendData + '   ' + FRecvData;
  FRecvDataTM := Copy(sRecvData, 17, 16);
  //sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendDataTM + '   ' + FRecvDataTM;
  sLogMsg := 'M:' + rTeeboxInfo.TeeboxNm + '/' + FSendDataTM + '/' + FRecvDataTM;
  Global.DebugLogMainViewMulti(FIndex, sLogMsg);

  //.L00000000000000
  //B2A056000T000100
  //000000000000003.

  sLogMsg := 'sRecvData No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + rTeeboxInfo.TeeboxNm + ' : ' + FSendDataTM + ' / ' + sRecvData;
  Global.Log.LogReadMulti(FIndex, sLogMsg);

  //2자리(28)	0: Default, 1: 에러발생, 2: CALL SW,
  //3자리(29)	0: Default, 에러코드
  //4자리(30)	파워비트(1:전원 ON, 0:전원 OFF)

  //에러코드
  //1	볼센서 입력 시간 초과
  //2	레일 볼센서 입력시간 초과(공이 모두 소모되었슴)
  //3	모터1(후크) 센서 입력시간 초과
  //4	모터2(티업) 센서 입력시간 초과
  //5	리밋센서 입력시간 초과

  if bExcept = True then
  begin
    //A.BA064000T00000
    //AQA000000T02000 : call
    sCommand:= copy(sRecvData, 20, 1);
    sMin := copy(sRecvData, 21, 3);
    sState := copy(sRecvData, 29, 1);
    sErr := copy(sRecvData, 30, 1);
  end
  else
  begin
    sCommand := copy(sRecvData, 19, 1);
    sMin := copy(sRecvData, 20, 3);
    sState := copy(sRecvData, 28, 1);
    sErr := copy(sRecvData, 29, 1);
  end;

  if sCommand <> 'A' then //응답
  begin
    Global.Log.LogReadMulti(FIndex, 'sCommand <> A');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  sMin := Trim(sMin);
  if Length(sMin) <> 3 then
  begin
    Global.Log.LogReadMulti(FIndex, 'Length(sMin) <> 3');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  if isNumber(sMin) = False then
  begin
    Global.Log.LogReadMulti(FIndex, 'sMin isNumber');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  sState := Trim(sState);
  if sState = '' then
  sState := '0';

  sErr := Trim(sErr);
  if sErr = '' then
  sErr := '0';

  if sState = '0' then //정상
  begin
    if StrToInt(sMin) > 0 then //사용중
      rTeeboxInfo.UseStatus := '1'
    else
      rTeeboxInfo.UseStatus := '0'; //빈타석(정지)
  end
  else if sState = '1' then //Error
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 10 + StrToInt(sErr);
  end
  else if sState = '2' then //2: CALL SW
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 10; //2021-05-06 Call 추가
  end
  else
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 0;
  end;

  rTeeboxInfo.RemainMinute := StrToInt(sMin);
  rTeeboxInfo.RemainBall := 0;

  Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

  Global.Teebox.SetTeeboxErrorCntAD(FIndex, rTeeboxInfo.TeeboxNo, 'N', 10);
  SetNextMonNo;

  FReceived := True;
end;

procedure TComThreadModenYJ.SetErrCnt(ATeeboxNo: Integer);
begin
  Global.Teebox.SetTeeboxErrorCntAD(FIndex, ATeeboxNo, 'Y', 10);
  SetNextMonNo;
end;

procedure TComThreadModenYJ.SetMonSendBuffer;
var
  sMin, sTeeboxTime: AnsiString;
begin

  FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);

  if FTeeboxInfo.UseStatus = '7' then //볼회수
    sMin := '0'
  else
    sMin := IntToStr(FTeeboxInfo.RemainMinute);

  sTeeboxTime := StrZeroAdd(sMin, 3);

  {
  //상태요청 구문
  sSendData := MODEN_STX + 'L' + '00000000000000' +
               sID + 'R' + '000' + '000' + 'T' + '0000' + 'XX' +
               '000000000000000' + MODEN_ETX;
  }

  FSendData := MODEN_STX + 'L' + '00000000000000' +
               FTeeboxInfo.DeviceId + 'O' + sTeeboxTime + '000' + 'T' + '0000' + 'XX' +
               '000000000000000' + MODEN_ETX;

  FSendDataTM := FTeeboxInfo.DeviceId + 'O' + sTeeboxTime + '000' + 'T';

  FComPort.Write(FSendData[1], Length(FSendData));
end;

function TComThreadModenYJ.SetNextMonNo: Boolean;
var
  rTeeboxInfo: TTeeboxInfo;
begin

  while True do
  begin
    inc(FTeeboxNoLast);
    if FTeeboxNoLast > FTeeboxNoEnd then
      FTeeboxNoLast := FTeeboxNoStart;

    rTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
    if rTeeboxInfo.UseYn = 'Y' then
      Break;
  end;

end;

procedure TComThreadModenYJ.Execute;
var
  sLogMsg: String;
begin
  inherited;

  while not Terminated do
  begin
    try
      Synchronize(Global.TeeboxControlTimeCheck);

      while True do
      begin
        if FReceived = False then
        begin

          if now > FWriteTm then
          begin

            sLogMsg := 'Retry COM_MON Received Fail - No:' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
            Global.Log.LogWriteMulti(FIndex, sLogMsg);

            SetNextMonNo;

            inc(FReTry);

            if FReTry > 1 then
            begin
              FReTry := 0;
              Global.Log.LogWriteMulti(FIndex, 'ReOpen');
              FComPort.Close;
              FComPort.Open;
              FComPort.ClearBuffer(True, True);
            end;

            Break;
          end;

        end
        else
        begin
          FReTry := 0;
          Break;
        end;
      end;

      if not FComPort.Connected then
      begin
        FComPort.Open;
      end;

      FSendData := '';

      // 요청과 응답 장치가 다름. 제어방식으로 요청. 남은시간을 보냄
      // 명령이 지연될경우 남은시간의 오차 발생할수 있어 제어문생성시 남은시간 계산
      SetMonSendBuffer;

      FWriteTm := now + (((1/24)/60)/60) * 1;

      FReceived := False;
      Sleep(200);  //50 이하인경우 retry 발생

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadModenYJ Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
