unit uComZoomCC;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadZoomCC = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;

    //2020-06-08 제어3회 시도후 에러처리
    FCtlReTry: Integer;
    //FCtlChannel: String;
    //FCtlMin: String;

    FReceived: Boolean;
    FChannel: String;

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    FLastCtlSeatNo: Integer; //최종 제어타석기
    FLastDeviceNo: Integer;
    FLastExeCommand: Integer; //최종 패킷 수행 펑션

    FWriteTm: TDateTime;
    FTeeboxInfo: TTeeboxInfo;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);

    //procedure SetSeatError(AChannel: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

  function GetBaudrate(const ABaudrate: Integer): TBaudRate;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

function GetBaudrate(const ABaudrate: Integer): TBaudRate;
begin
  case ABaudrate of
    9600:   Result := br9600;
    14400:  Result := br14400;
    19200:  Result := br19200;
    38400:  Result := br38400;
    57600:  Result := br57600;
    115200: Result := br115200;
    128000: Result := br128000;
    256000: Result := br256000;
  else
    Result := br9600;
  end;
end;

{ TControlComPortZoomCCMonThread }

constructor TComThreadZoomCC.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  FComPort.Parity.Bits := prOdd;
  FComPort.Open;

  FReTry := 0;
  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FLastDeviceNo := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadZoomCC Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadZoomCC.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadZoomCC.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC, sErrorCd, sErrorCdHex: string;

  sLogMsg: string;
  //SeatInfo: TTeeboxInfo;

  Index: Integer;
  sRecvData: AnsiString;
  rSeatInfo: TTeeboxInfo;

  nStx, nEtx: Integer;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Length(FRecvData) < 16 then
    Exit;

  if Pos(ZOOM_STX, FRecvData) = 0 then
    Exit;

  if Pos(ZOOM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(ZOOM_CC_STX, FRecvData);
  nEtx := Pos(ZOOM_CC_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 15) then
  begin
    Global.Log.LogComRead('FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel <> Copy(FRecvData, 2, 3) then
  begin
    sLogMsg := 'FChannel Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel + ' / ' + FRecvData;
    Global.Log.LogComRead(sLogMsg);

    FRecvData := '';
    Exit;
  end;

  Global.Log.LogComRead('FRecvData : ' + FRecvData);

  //STX(1) PLC(2) TEE(1) 상태(1) 에러번호(1) 잔여시간(4) 잔여볼수(4) ETX(1) BCC(1)
  //상태: 0.초기화대기중 1.타석번호(대기중) 3.사용중 4.종료(END) 5.수동
  //1, 2 3, 4, 5,	6, 7 8 9 10, 11	12 13	14, 15,	16
  //	 0 9 	1	 3	@	 0 0 5  4	  9	 9	2	 5	 	 2
  //02 30	39 31	33 40	30 30	35 34	39 39	32 35	03 32
  rSeatInfo.StoreCd := ''; //가맹점 코드
  rSeatInfo.TeeboxNo := FTeeboxInfo.TeeboxNo; //타석 번호
  rSeatInfo.TeeboxNm := '';  //타석명
  rSeatInfo.RecvDeviceId := FChannel;
  rSeatInfo.FloorZoneCode := ''; //층 구분 코드
  rSeatInfo.ZoneDiv := '';  //구역 구분 코드

  //if copy(FRecvData, 6, 1) = '0' then //정상
  if copy(FRecvData, 6, 1) = '@' then //정상
  begin
    if copy(FRecvData, 5, 1) = '4' then //빈타석(정지)
      rSeatInfo.UseStatus := '0'
    else if copy(FRecvData, 5, 1) = '3' then //사용중
      rSeatInfo.UseStatus := '1'
    else if copy(FRecvData, 5, 1) = '1' then //대기
      rSeatInfo.UseStatus := '0'
    else
      rSeatInfo.UseStatus := '0';
  end
  else //1,2,3,4
  begin
    rSeatInfo.UseStatus := '9';
    rSeatInfo.ErrorCd := 0;

    sErrorCd := copy(FRecvData, 6, 1);
    sErrorCdHex := StrToAnsiHex(sErrorCd);

    if copy(sErrorCdHex, 2, 1) = '1' then
      rSeatInfo.ErrorCd := 2 //error: 볼없음
    else if copy(sErrorCdHex, 2, 1) = '2' then
      rSeatInfo.ErrorCd := 1 //볼걸림
    else if copy(FRecvData, 2, 1) = '3' then
      rSeatInfo.ErrorCd := 4; //error: 모터이상

    sLogMsg := 'Error Code - No:' + intToStr(FTeeboxInfo.TeeboxNo) + ' Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + sErrorCd + ' / ' + sErrorCdHex;
    Global.Log.LogComRead(sLogMsg);
  end;

  rSeatInfo.UseYn := '';        //사용 여부
  rSeatInfo.RemainBall := StrToInt(copy(FRecvData, 11, 4));
  if copy(FRecvData, 5, 1) = '1' then
    rSeatInfo.RemainMinute := 0
  else
    rSeatInfo.RemainMinute := StrToInt(copy(FRecvData, 7, 4));

  Global.Teebox.SetTeeboxInfo(rSeatInfo);

  if FLastExeCommand = COM_CTL then
  begin
    sLogMsg := IntToStr(FLastExeCommand) + ' 요청: ' + IntToStr(FTeeboxInfo.TeeboxNo) +
               ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel +
               ' / 응답:' + FRecvData;
    Global.Log.LogComRead(sLogMsg);
  end;

  sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
  Global.DebugLogViewWrite(sLogMsg);

  if FLastExeCommand = COM_MON then
  begin
    Global.Teebox.SetTeeboxErrorCntAD(FTeeboxInfo.TeeboxNo, 'N', 10);
    SetNextMonNo;
  end
  else
  begin
    if FLastCmdDataIdx <> FCurCmdDataIdx then
    begin
      inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
      if FCurCmdDataIdx > BUFFER_SIZE then
        FCurCmdDataIdx := 0;
    end;
  end;

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadZoomCC.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sSeatTime, sSeatBall: AnsiString;
begin
  if ASeatTime = '0' then
  begin
    sSendData := ADeviceId + 'E';
  end
  else
  begin
    sSeatTime := StrZeroAdd(ASeatTime, 4);
    sSeatBall := StrZeroAdd(ASeatBall, 4);

    sSendData := ADeviceId + 'S1' + sSeatTime + sSeatBall;
  end;

  sBcc := GetBCCZoomCC(sSendData);
  sSendData := ZOOM_CTL_STX + sSendData + ZOOM_REQ_ETX + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;
{
//2020-06-08 제어3회 시도후 에러처리
procedure TComThreadZoomCC.SetSeatError(AChannel: String);
var
  rSeatInfo: TSeatInfo;
begin
  rSeatInfo.StoreCd := ''; //가맹점 코드
  rSeatInfo.SeatNo := Global.Teebox.GetDevicToSeatNo(AChannel); //타석 번호
  rSeatInfo.RecvDeviceId := AChannel;
  rSeatInfo.SeatNm := '';  //타석명
  rSeatInfo.FloorZoneCode := ''; //층 구분 코드
  rSeatInfo.SeatZoneCode := '';  //구역 구분 코드
  rSeatInfo.UseStatus := '9';
  rSeatInfo.UseYn := '';        //사용 여부
  rSeatInfo.RemainBall := 0;
  rSeatInfo.RemainMinute := 0;
  rSeatInfo.ErrorCd := 8; //통신이상

  Global.Teebox.SetSeatInfo(rSeatInfo);
end;
}

function TComThreadZoomCC.SetNextMonNo: Boolean;
begin
  inc(FLastDeviceNo);
  if FLastDeviceNo > Global.Teebox.DevicNoCnt - 1 then
    FLastDeviceNo := 0;
end;

procedure TComThreadZoomCC.Execute;
var
  bControlMode: Boolean;
  sBcc, sSendDataTemp: AnsiString;
  sLogMsg: String;
  //nSeatNo: Integer;
begin
  inherited;

  while not Terminated do
  begin
    try

      while True do
      begin
        if FReceived = False then
        begin

          if now > FWriteTm then
          begin

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
              Global.Log.LogRetryWrite(sLogMsg);

              FRecvData := '';

              inc(FCtlReTry);
              if FCtlReTry > 2 then
              begin
                FCtlReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogRetryWrite('ReOpen');
              end;

              if FLastCmdDataIdx <> FCurCmdDataIdx then
              begin
                inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
                if FCurCmdDataIdx > BUFFER_SIZE then
                FCurCmdDataIdx := 0;
              end;

              Break;
            end
            else
            begin
              sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogRetryWrite(sLogMsg);

              Global.Teebox.SetTeeboxErrorCntAD(FTeeboxInfo.TeeboxNo, 'N', 10);
              SetNextMonNo;

              inc(FReTry);
              if FReTry > 10 then
              begin
                FReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogRetryWrite('ReOpen');
              end;

              Break;
            end;

          end;

        end
        else
        begin
          if FLastExeCommand = COM_CTL then
            FCtlReTry := 0;

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
      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //대기중인 제어명령이 있으면
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);
        
        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToTeeboxInfo(FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogComWrite(sLogMsg);
        //Sleep(50);

        FWriteTm := now + (((1/24)/60)/60) * 0.1;

        while True do
        begin
          if now > FWriteTm then
          begin
            Break;
          end;
        end;

        //체크아웃후 타석번호설정
        if Copy(FSendData, 5, 1) = 'E' then
        begin
          //ENQ(1) PLC(2) TEE(1) M(1) 3(고정숫자) 타석번호(3) EOT(1) BCC(1)
          sSendDataTemp := FChannel + 'M3' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 3);
          sBcc := GetBCCZoomCC(sSendDataTemp);
          FSendData := ZOOM_CC_ENQ + sSendDataTemp + ZOOM_CC_EOT + sBcc;
          FComPort.Write(FSendData[1], Length(FSendData));
          Global.Log.LogComWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

          FWriteTm := now + (((1/24)/60)/60) * 0.1;

          while True do
          begin
            if now > FWriteTm then
            begin
              Break;
            end;
          end;

        end;

        //제어후 리턴값이 없음
        sBcc := GetBCCZoomCC(FChannel);
        FSendData := ZOOM_CC_SOH + FChannel + ZOOM_CC_EOT + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogComWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;

        FWriteTm := now + (((1/24)/60)/60) * 2;
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        //1	2	3	4	5	6
        //	0	1	1		6
        //01	30	31	31	04	36
        FLastExeCommand := COM_MON;
        FChannel := Global.Teebox.GetSeatDevicdNoToDevic(FLastDeviceNo);
        FTeeboxInfo := Global.Teebox.GetDeviceToTeeboxInfo(FChannel);

        sBcc := GetBCCZoomCC(FChannel);
        FSendData := ZOOM_CC_SOH + FChannel + ZOOM_CC_EOT + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;
      Sleep(200);  //50 이하인경우 retry 발생

    except
      on e: Exception do
      begin
        sLogMsg := 'TComZoomCCMonThread Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
