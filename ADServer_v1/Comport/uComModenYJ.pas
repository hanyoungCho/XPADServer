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
    FErrCnt: Integer;

    FReceived: Boolean;
    FChannel: String;
    FTeeboxNo: Integer;

    FMonDeviceNoLast: Integer;

    FLastExeCommand: Integer; //최종 패킷 수행 펑션

    FWriteTm: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetMonSendBuffer(ADeviceId: String);

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

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
  //FComPort.BaudRate := br57600;
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  FComPort.Open;

  FReTry := 0;
  FErrCnt := 0;

  FReceived := True;
  FMonDeviceNoLast := 0;
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
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel); //요청한 타석 번호
  rTeeboxInfo.RecvDeviceId := FChannel;
  rTeeboxInfo.TeeboxNm := Global.Teebox.GetDevicToTeeboxNm(FChannel);  //요청한 타석명
  rTeeboxInfo.FloorZoneCode := '';
  rTeeboxInfo.TeeboxZoneCode := '';
  rTeeboxInfo.UseYn := '';

  if FChannel <> sChannelTM then
  begin
    sLogMsg := 'Fail No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + rTeeboxInfo.TeeboxNm + ' : ' + FSendDataTM + ' / ' + sRecvData;
    Global.Log.LogRetryWrite(sLogMsg);

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendData + '   ' + FRecvData;
  FRecvDataTM := Copy(sRecvData, 17, 16);
  //sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendDataTM + '   ' + FRecvDataTM;
  sLogMsg := 'M:' + rTeeboxInfo.TeeboxNm + '/' + FSendDataTM + '/' + FRecvDataTM;
  Global.DebugLogViewWrite(sLogMsg);

  //.L00000000000000
  //B2A056000T000100
  //000000000000003.

  sLogMsg := 'sRecvData No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + rTeeboxInfo.TeeboxNm + ' : ' + FSendDataTM + ' / ' + sRecvData;
  Global.Log.LogRetryWrite(sLogMsg);

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

  //Global.Log.LogRetryWrite('--------');

  if sCommand <> 'A' then //응답
  begin
    Global.Log.LogRetryWrite('sCommand <> A');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //Global.Log.LogRetryWrite('000000');

  sMin := Trim(sMin);
  if Length(sMin) <> 3 then
  begin
    Global.Log.LogRetryWrite('Length(sMin) <> 3');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //Global.Log.LogRetryWrite('111111');

  if isNumber(sMin) = False then
  begin
    Global.Log.LogRetryWrite('sMin isNumber');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //Global.Log.LogRetryWrite('2222');

  sState := Trim(sState);
  if sState = '' then
  sState := '0';

  sErr := Trim(sErr);
  if sErr = '' then
  sErr := '0';

  //Global.Log.LogRetryWrite('3333');

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
    rTeeboxInfo.ErrorCd2 := sErr;
  end
  else if sState = '2' then //2: CALL SW
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 10; //2021-05-06 Call 추가
    rTeeboxInfo.ErrorCd2 := '10';
  end
  else
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 0;
    rTeeboxInfo.ErrorCd2 := '0';
  end;

  //Global.Log.LogRetryWrite('4444');

  rTeeboxInfo.RemainMinute := StrToInt(sMin);
  rTeeboxInfo.RemainBall := 0;

  Global.Teebox.SetTeeboxInfoJMS(rTeeboxInfo);

  FErrCnt := 0;
  Global.Teebox.SetTeeboxErrorCnt(rTeeboxInfo.TeeboxNo, 'N', 5);
  SetNextMonNo;

  //Global.Log.LogRetryWrite('FReceived := True');
  FReceived := True;
end;

procedure TComThreadModenYJ.SetErrCnt(ATeeboxNo: Integer);
begin
  inc(FErrCnt);

  if FErrCnt > 5 then
  begin
    Global.Teebox.SetTeeboxErrorCnt(ATeeboxNo, 'Y', 5);
    FErrCnt := 0;
    SetNextMonNo;
  end;
end;

procedure TComThreadModenYJ.SetMonSendBuffer(ADeviceId: String);
var
  rTeeboxInfo: TTeeboxInfo;
  sSendData, sMin, sTeeboxTime: AnsiString;
  sDeviceIdR, sDeviceIdL: AnsiString;
begin
  rTeeboxInfo := Global.Teebox.GetTeeboxInfoA(ADeviceId);
  FTeeboxNo := rTeeboxInfo.TeeboxNo;

  if rTeeboxInfo.UseStatus = '7' then //볼회수
    rTeeboxInfo.RemainMinute := 0;

  sMin := IntToStr(rTeeboxInfo.RemainMinute);
  sTeeboxTime := StrZeroAdd(sMin, 3);

  {
  if AType = 'MON' then
  begin
    sSendData := MODEN_STX + 'L' + '00000000000000' +
                 sID + 'R' + '000' + '000' + 'T' + '0000' + 'XX' +
                 '000000000000000' + MODEN_ETX;
  end
  else }
  begin
    FSendData := MODEN_STX + 'L' + '00000000000000' +
                 ADeviceId + 'O' + sTeeboxTime + '000' + 'T' + '0000' + 'XX' +
                 '000000000000000' + MODEN_ETX;

    FSendDataTM := ADeviceId + 'O' + sTeeboxTime + '000' + 'T';
  end;

  FComPort.Write(FSendData[1], Length(FSendData));
  //FComPort.WriteStr(FSendData);
  //Global.Log.LogRetryWrite('Write : ' + FSendData);
end;

function TComThreadModenYJ.SetNextMonNo: Boolean;
var
  nTeeboxNo: Integer;
  sChannel: String;
begin

  while True do
  begin
    inc(FMonDeviceNoLast);
    if FMonDeviceNoLast > Global.Teebox.TeeboxDevicNoCnt - 1 then
      FMonDeviceNoLast := 0;

    sChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);
    nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(sChannel);
    if Global.Teebox.GetTeeboxInfoUseYn(nTeeboxNo) = 'Y' then
      Break;
  end;

end;

procedure TComThreadModenYJ.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nTeeboxNo: Integer;
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

            nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);
            sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(nTeeboxNo) + ' / ' + FSendData;
            Global.Log.LogRetryWrite(sLogMsg);

            SetNextMonNo;

            inc(FReTry);

            if FReTry > 1 then
            begin
              FReTry := 0;
              Global.Log.LogRetryWrite('ReOpen');
              FComPort.Close;
              //FComPort.ClearBuffer(True, True);
              FComPort.Open;
              FComPort.ClearBuffer(True, True);
              //Global.Log.LogRetryWrite('ReOpen');
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
      bControlMode := False;

      // 요청과 응답 장치가 다름. 제어방식으로 요청. 남은시간을 보냄
      // 명령이 지연될경우 남은시간의 오차 발생할수 있어 제어문생성시 남은시간 계산
      FLastExeCommand := COM_MON;
      FChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);
      SetMonSendBuffer(FChannel);
      //FChannel := FLastMonSeatDeviceNo;

      FWriteTm := now + (((1/24)/60)/60) * 1;

      FReceived := False;
      Sleep(200);  //50 이하인경우 retry 발생
      //Sleep(10);  //50 이하인경우 retry 발생

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
