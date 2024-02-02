unit uSeatControlTcp;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type
  TControlMonThread = class(TThread)
  private
    FIdTCPClient: TIdTCPClient;
    FCmdSendBufArr: array[0..COM_CTL_MAX] of AnsiString;

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    FLastCtlSeatNo: Integer; //최종 제어타석기
    //FLastMonSeatNo: Integer; //최종 모니터링 타석기
    FLastMonSeatDeviceNo: Integer; //최종 모니터링 타석기
    FLastExeCommand: Integer; //최종 패킷 수행 펑션
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetCmdSendBuffer(ASendData: AnsiString);
  end;

  TControlComPortMonThread = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FReceived: Boolean;
    FChannel: String;

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    FLastCtlSeatNo: Integer; //최종 제어타석기
    //FLastMonSeatNo: Integer; //최종 모니터링 타석기
    FLastMonSeatDeviceNo: Integer;
    FLastExeCommand: Integer; //최종 패킷 수행 펑션
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ASendData: AnsiString);

    property ComPort: TComPort read FComPort write FComPort;
  end;

  function GetBaudrate(const ABaudrate: Integer): TBaudRate;
  function StringToHex(const S: string): string;

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

function StringToHex(const S: string): string;
var
  Index: Integer;
begin
  Result := '';
  for Index := 1 to Length(S) do
    Result := Result + IntToHex( Byte( S[Index] ), 2 );
end;

{ TControlMonThread }

constructor TControlMonThread.Create;
var
  sLogMsg: String;
begin
  FIdTCPClient := TIdTCPClient.Create(nil);
  FIdTCPClient.Disconnect;

  FIdTCPClient.Host := '127.0.0.1';
  FIdTCPClient.Port := 15002;

  FIdTCPClient.ConnectTimeout := 10000;
  FIdTCPClient.ReadTimeout := 10000;

  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastMonSeatNo := 1;
  FLastMonSeatDeviceNo := 0;

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TControlMonThread.Destroy;
begin
  FIdTCPClient.Disconnect;
  FIdTCPClient.Free;
  inherited;
end;

procedure TControlMonThread.SetCmdSendBuffer(ASendData: AnsiString);
begin
  FCmdSendBufArr[FLastCmdDataIdx] := ASendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > COM_CTL_MAX then
    FLastCmdDataIdx := 0;
end;

procedure TControlMonThread.Execute;
var
  bControlMode: Boolean;
  sChannelTemp, sLogMsg: String;
  sSendData, sRecvData: AnsiString;
  rSeatInfo: TSeatInfo;
begin
  inherited;

  while not Terminated do
  begin
    try
      if not FIdTCPClient.Connected then
      begin
        FIdTCPClient.Disconnect;
        FIdTCPClient.Connect();
      end;

      bControlMode := False;
      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //대기중인 제어명령이 있으면
        bControlMode := True;

        sChannelTemp := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);
        sSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FIdTCPClient.IOHandler.Write(sSendData);
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        //1	2	3	4	5	6
        //	0	1	1		6
        //01	30	31	31	04	36
        //sChannelTemp := Global.Seat.GetSeatNoToDevic(FLastMonSeatNo);
        sChannelTemp := Global.Seat.GetSeatDevicdNoToDevic(FLastMonSeatDeviceNo);
        sSendData := '' + sChannelTemp + '6';
        FIdTCPClient.IOHandler.Write(sSendData);
      end;

      Sleep(10);

      //성공 시에는 길이만큼 받을 수 있지만 전문오류나 값이 잘못되어
      //실패로 떨어질 경우 길이로 받으면 리턴값이 오지 않는다.
      sRecvData := FIdTCPClient.IOHandler.ReadString(16);
      //memo1.lines.Add(RecvData);

      //요청한 타석기 정보이면
      if sChannelTemp = Copy(sRecvData, 2, 3) then
      begin
        //1	2	3	4	5	6	7	8	9	10 11	12 13	14 15	16
        //	0	9	1	3	@	0	0	5	 4	9	 9	2	 5		 2

        rSeatInfo.StoreCd := ''; //가맹점 코드
        rSeatInfo.SeatNo := Global.Seat.GetDevicToSeatNo(sChannelTemp); //타석 번호
        rSeatInfo.SeatNm := '';  //타석명
        rSeatInfo.FloorZoneCode := ''; //층 구분 코드
        rSeatInfo.SeatZoneCode := '';  //구역 구분 코드

        if copy(sRecvData, 6, 1) = '@' then //정상
        begin
          if copy(sRecvData, 5, 1) = '4' then //빈타석
            rSeatInfo.UseStatus := '0'
          else if copy(sRecvData, 5, 1) = '3' then //사용중
            rSeatInfo.UseStatus := '1'
          else if copy(sRecvData, 5, 1) = '2' then //예약중: S0 으로 제어하는경우
            rSeatInfo.UseStatus := '0'
          else
            rSeatInfo.UseStatus := '0';
        end
        else if copy(sRecvData, 6, 1) = 'B' then //고장
          rSeatInfo.UseStatus := '9'
        else //3C
          rSeatInfo.UseStatus := '9';

        rSeatInfo.UseYn := '';        //사용 여부
        rSeatInfo.RemainBall := StrToInt(copy(sRecvData, 11, 4));
        rSeatInfo.RemainMinute := StrToInt(copy(sRecvData, 7, 4));
        //BCC := copy(Buff, 16, 1);

        Global.Seat.SetSeatInfo(rSeatInfo);

        //if (FLastMonSeatNo = 1) or (FLastMonSeatNo = 72) then
        //  MainForm.LogView(sRecvData);
      end
      else
      begin
        //memo1.lines.Add('요청타석기: ' + Global.Seat.GetDevicToSeatNo(sChannelTemp) +
        //                ' / 응답타석기: ' + Global.Seat.GetDevicToSeatNo(Copy(sRecvData, 2, 3)) );
      end;

      if bControlMode = False then
      begin
        //while True do
        begin
          {
          inc(FLastMonSeatNo);
          if FLastMonSeatNo > Global.Seat.SeatLastNo then
            FLastMonSeatNo := 1;

          if Global.Seat.GetSeatInfoUseYn(FLastMonSeatNo) = 'Y' then
            Break;
            }
          inc(FLastMonSeatDeviceNo);
          if FLastMonSeatDeviceNo > Global.Seat.SeatDevicNoCnt - 1 then
            FLastMonSeatDeviceNo := 0;
        end;
      end
      else
      begin
        if FLastCmdDataIdx <> FCurCmdDataIdx then
        begin
          inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
          if FCurCmdDataIdx > COM_CTL_MAX then
            FCurCmdDataIdx := 0;
        end;
      end;

      Sleep(10);

      //FIdTCPClient.Disconnect;

    except
      on e: Exception do
      begin
        sLogMsg := 'TControlMonThread Error : ' + e.Message;
        MainForm.LogView(sLogMsg);
        FIdTCPClient.Disconnect;

        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
        begin
          //wMonDelayTime := 10000; //10000 = 10초
          //g_bSMServerSocketError := True;
        end;
      end;
    end;
  end;
end;

{ TControlComPortMonThread }

constructor TControlComPortMonThread.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  //FComPort.Port := 'COM11';
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
  //FComPort.BaudRate := br9600;
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  FComPort.Parity.Bits := prOdd;
  FComPort.Open;

  FReTry := 0;
  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastMonSeatNo := 1;
  FLastMonSeatDeviceNo := 0;
  FRecvData := '';

  Global.LogWrite('TControlComPortMonThread Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TControlComPortMonThread.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TControlComPortMonThread.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;
  SeatInfo: TSeatInfo;

  Index: Integer;
  sRecvData: AnsiString;
  rSeatInfo: TSeatInfo;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  if Count < 16 then
  begin
    //MainForm.LogView('요청타석기: ' + IntToStr(Global.Seat.GetDevicToSeatNo(FChannel)) + ' / 총글자수: ' + IntToStr(Count));
    FRecvData := FRecvData + sRecvData;

    if copy(FRecvData, 1, 1) <> '' then
    begin
      Global.LogWrite('FRecvData  fail : ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    if Length(FRecvData) > 16 then
    begin
      Global.LogWrite('Over : ' + FRecvData);
      FRecvData := '';
      Exit;
    end
    else if Length(FRecvData) < 16 then
    begin
      Exit;
    end;

  end
  else if Count = 16 then
  begin
    FRecvData := sRecvData;
  end
  else
  begin
    Global.LogWrite('요청타석기: ' + IntToStr(Global.Seat.GetDevicToSeatNo(FChannel)) + ' / 총글자수: ' + IntToStr(Count) + ' / ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //1	2	3	4	5	6	7	8	9	10 11	12 13	14 15	16
    //	0	9	1	3	@	0	0	5	 4	9	 9	2	 5		 2
    //02 30	39 31	33 40	30 30	35 34	39 39	32 35	03 32
    rSeatInfo.StoreCd := ''; //가맹점 코드
    rSeatInfo.SeatNo := Global.Seat.GetDevicToSeatNo(copy(FRecvData, 2, 3)); //타석 번호
    rSeatInfo.SeatNm := '';  //타석명
    rSeatInfo.FloorZoneCode := ''; //층 구분 코드
    rSeatInfo.SeatZoneCode := '';  //구역 구분 코드

    if copy(FRecvData, 6, 1) = '@' then //정상
    begin
      if copy(FRecvData, 5, 1) = '4' then //빈타석(정지)
        rSeatInfo.UseStatus := '0'
      else if copy(FRecvData, 5, 1) = '3' then //사용중
        rSeatInfo.UseStatus := '1'
      else if copy(sRecvData, 5, 1) = '2' then //예약중: S0 으로 제어하는경우
        rSeatInfo.UseStatus := '0'
      else
        rSeatInfo.UseStatus := '0';
    end
    else if copy(FRecvData, 6, 1) = 'B' then //장비Error
    begin
      rSeatInfo.UseStatus := '9';
    end
    else //C
    begin
      rSeatInfo.UseStatus := '9';
    end;

    rSeatInfo.UseYn := '';        //사용 여부
    rSeatInfo.RemainBall := StrToInt(copy(FRecvData, 11, 4));
    rSeatInfo.RemainMinute := StrToInt(copy(FRecvData, 7, 4));
    //BCC := copy(Buff, 16, 1);

    //sLogMsg := StringToHex(FRecvData);
    //MainForm.LogView(sLogMsg);

    Global.Seat.SetSeatInfo(rSeatInfo);

    if FLastExeCommand = COM_CTL then
    begin
      sLogMsg := IntToStr(FLastExeCommand) + ' 요청: ' + IntToStr(Global.Seat.GetDevicToSeatNo(FChannel)) +
                 ' / ' + Global.Seat.GetDevicToSeatNm(FChannel) + ' / ' + FChannel +
                 ' / 응답: ' + IntToStr(Global.Seat.GetDevicToSeatNo(Copy(FRecvData, 2, 3))) +
                 ' / ' + FRecvData;
      Global.LogCtrlWrite(sLogMsg);
    end;

    sLogMsg := IntToStr(rSeatInfo.SeatNo) + ' / ' + FSendData + '   ' + FRecvData;
    Global.DebugLogViewWrite(sLogMsg);
    //Global.LogWrite(sLogMsg);
  end
  else
  begin
    {
    sLogMsg := IntToStr(FLastExeCommand) + ' 요청타석기: ' + IntToStr(Global.Seat.GetDevicToSeatNo(FChannel)) + ' / ' + FChannel +
               ' / 응답타석기: ' + IntToStr(Global.Seat.GetDevicToSeatNo(Copy(FRecvData, 2, 3))) +
               ' / ' + Copy(FRecvData, 2, 3);
    Global.LogWrite(sLogMsg);
    }
    FRecvData := '';
    Exit;
  end;

  if FLastExeCommand = COM_MON then
  begin
    //while True do
    begin
      {
      inc(FLastMonSeatNo);
      if FLastMonSeatNo > Global.Seat.SeatLastNo then
        FLastMonSeatNo := 1;

      if Global.Seat.GetSeatInfoUseYn(FLastMonSeatNo) = 'Y' then
        Break;
      }
      inc(FLastMonSeatDeviceNo);
      if FLastMonSeatDeviceNo > Global.Seat.SeatDevicNoCnt - 1 then
        FLastMonSeatDeviceNo := 0;

    end;
  end
  else
  begin
    if FLastCmdDataIdx <> FCurCmdDataIdx then
    begin
      inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
      if FCurCmdDataIdx > BUFFER_SIZE then
        FCurCmdDataIdx := 0;

      //sLogMsg := 'Receive Success  FCurCmdDataIdx : ' + IntToStr(FCurCmdDataIdx);
      //Global.LogWrite(sLogMsg);
    end;
  end;

  FRecvData := '';
  FReceived := True;
end;

procedure TControlComPortMonThread.SetCmdSendBuffer(ASendData: AnsiString);
begin
  FCmdSendBufArr[FLastCmdDataIdx] := ASendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

procedure TControlComPortMonThread.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nSeatNo: Integer;
begin
  inherited;

  while not Terminated do
  begin
    try
      Synchronize(Global.SeatControlTimeCheck);

      if FReceived = False then
      begin
        Sleep(100);
        inc(FReTry);
        if FReTry > 3 then
        begin
          FReTry := 0;

          sLogMsg := 'Retry 3 / SeatControler Data Received Fail / ' + FSendData + ' / ' + FRecvData;
          Global.LogRetryWrite(sLogMsg);

          FRecvData := '';
          {
          inc(FLastMonSeatNo);
          if FLastMonSeatNo > Global.Seat.SeatLastNo then
            FLastMonSeatNo := 1;
          }
          inc(FLastMonSeatDeviceNo);
          if FLastMonSeatDeviceNo > Global.Seat.SeatDevicNoCnt - 1 then
            FLastMonSeatDeviceNo := 0;
        end;
      end
      else
        FReTry := 0;

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
        Global.LogCtrlWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);
        Sleep(50);

        //제어후 리턴값이 없음
        sBcc := GetBCC('01', FChannel, '04');
        FSendData := '' + FChannel + '' + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        //1	2	3	4	5	6
        //	0	1	1		6
        //01	30	31	31	04	36
        FLastExeCommand := COM_MON;
        //FChannel := Global.Seat.GetSeatNoToDevic(FLastMonSeatNo);
        FChannel := Global.Seat.GetSeatDevicdNoToDevic(FLastMonSeatDeviceNo);

        sBcc := GetBCC('01', FChannel, '04');
        FSendData := '' + FChannel + '' + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
      end;

      FReceived := False;
      Sleep(100);  //50 이하인경우 retry 발생

    except
      on e: Exception do
      begin
        sLogMsg := 'TControlComPortMonThread Error : ' + e.Message + ' / ' + FSendData;
        Global.LogWrite(sLogMsg);

        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
        begin
          //wMonDelayTime := 10000; //10000 = 10초
          //g_bSMServerSocketError := True;
        end;
      end;
    end;
  end;

end;

end.
