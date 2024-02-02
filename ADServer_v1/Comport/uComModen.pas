unit uComModen;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadModen = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;

    //2020-06-08 제어3회 시도후 에러처리
    FCtlReTry: Integer;
    FCtlChannel: String;

    FReceived: Boolean;
    FChannel: String;
    FFloor: String;

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    //FLastCtlTeeboxNo: Integer; //최종 제어타석기
    //FLastMonSeatNo: Integer; //최종 모니터링 타석기

    FIndex: Integer;
    FMonDeviceNoStart: Integer;
    FMonDeviceNoEnd: Integer;
    FMonDeviceNoLast: Integer;

    FLastExeCommand: Integer; //최종 패킷 수행 펑션

    FWriteTm: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortSetting(Index, AStart, AEnd: Integer);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    //procedure SetCmdSendBuffer(ASendData: AnsiString);

    procedure SetTeeboxError(AChannel: String);

    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);

    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadModen }

constructor TComThreadModen.Create;
begin
  FReTry := 0;
  FCtlReTry := 0;

  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastMonSeatNo := 1;
  FMonDeviceNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadModen Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadModen.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadModen.ComPortSetting(Index, AStart, AEnd: Integer);
begin
  FMonDeviceNoStart := AStart - 1;
  FMonDeviceNoEnd := AEnd - 1;
  FMonDeviceNoLast := AStart - 1;
  FIndex := Index;
  FFloor := IntToStr(Index);

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;

  if Index = 2 then
  begin
    FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
    FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
    FComPort.Open;
  end;

  if Index = 3 then
  begin
    FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port2);
    FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate2);
    FComPort.Open;
  end;

  if Index = 4 then
  begin
    FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port3);
    FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate3);
    FComPort.Open;
  end;

  if Index = 5 then
  begin
    FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port4);
    FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate4);
    FComPort.Open;
  end;

  Global.Log.LogWrite('TComThreadModen ComPortSetting : ' + IntToStr(Index));
end;

procedure TComThreadModen.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;

  Index: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx: Integer;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Length(FRecvData) < 16 then
    Exit;

  if Pos(MODEN_STX, FRecvData) = 0 then
    Exit;

  if Pos(MODEN_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(MODEN_STX, FRecvData);
  nEtx := Pos(MODEN_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 15) then
  begin
    Global.Log.LogCtrlWriteModen(FIndex, 'FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 1) then
  begin
    //Global.LogCtrlWriteModen(FIndex, 'FRecvData: ' + FRecvData);

    // 전문구성 : STX(1) + ID(1) + COMMAND(1) + DATA(6) + CLASS(1) + ETC(4) + ETX(1) + 체크섬(1)
    // 1  2	 3	4	 5	6	 7	8	 9 10	11 12	13 14	15 16
    //   1	 A	0	 0	0	 0	0	 0	T	 0	0  0	1	 	,
    //02 31	41 30	30 30	30 30	30 54	30 30	30 31	03 2C
    // 2 49	65 48	48 48	48 48	48 84	48 48	48 49	 3 44

    //.7A049000T0001.?
    //.@A000000T0121.>

    rTeeboxInfo.StoreCd := ''; //가맹점 코드
    rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, FChannel); //타석 번호
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //타석명
    rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
    rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드

    //2자리(12)	0: Default, 1: 에러발생, 2: CALL SW,
    //3자리(13)	0: Default, 에러코드
    //4자리(14)	파워비트(1:전원 ON, 0:전원 OFF)

    //에러코드
    //1	볼센서 입력 시간 초과
    //2	레일 볼센서 입력시간 초과(공이 모두 소모되었슴)
    //3	모터1(후크) 센서 입력시간 초과
    //4	모터2(티업) 센서 입력시간 초과
    //5	리밋센서 입력시간 초과

    rTeeboxInfo.UseYn := '';        //사용 여부
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 4, 3));
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 7, 3));

    if copy(FRecvData, 12, 1) = '0' then //정상
    begin
      if rTeeboxInfo.RemainMinute > 0 then //사용중
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0'; //빈타석(정지)
    end
    else if copy(FRecvData, 12, 1) = '1' then //Error
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(FRecvData, 13, 1));
      rTeeboxInfo.ErrorCd2 := copy(FRecvData, 13, 1);
    end
    else //2: CALL SW,
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 0;
      rTeeboxInfo.ErrorCd2 := '0';
    end;

    Global.Teebox.SetTeeboxInfo(rTeeboxInfo);

    if FLastExeCommand = COM_CTL then
    begin
      sLogMsg := IntToStr(FLastExeCommand) + ' 요청: ' + IntToStr(Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, FChannel)) +
                 ' / ' + Global.Teebox.GetDevicToTeeboxNm(FChannel) + ' / ' + FChannel +
                 ' / 응답: ' + IntToStr(Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, FChannel)) +
                 ' / ' + FRecvData;
      Global.Log.LogCtrlWriteModen(FIndex, sLogMsg);
    end;

    sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + '   ' + FRecvData;
    Global.DebugLogViewWriteA6001(FIndex, sLogMsg);
    //Global.LogWrite(sLogMsg);
  end
  else
  begin
    //sLogMsg := 'FChannel Fail : ' + IntToStr(Global.Seat.GetDevicToFloorTeeboxNoModen(FFloor, FChannel)) + ' / ' + FChannel + ' / ' + FRecvData;
    //Global.LogCtrlWriteA6001(FIndex, sLogMsg);

    FRecvData := '';
    Exit;
  end;

  if FLastExeCommand = COM_MON then
  begin
    Global.Teebox.SetTeeboxErrorCntModen(FIndex, rTeeboxInfo.TeeboxNo, 'N');
    SetNextMonNo;
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

procedure TComThreadModen.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime: AnsiString;
begin
  // 전문구성 : STX(1) + ID(1) + COMMAND(1) + DATA(6) + CLASS(1) + ETC(4) + ETX(1) + 체크섬(1)
  // 1	2	 3	4	 5	6	 7	8	 9 10	11 12	13 14	15 16
  // 	1	 O	0	 0	0	 0	0	 0	T	 0	0	 0	0	 	9
  //02 31	4F 30	30 30	30 30	30 54	30 30	30 30	03 39
  // 2 49	79 48	48 48	48 48	48 84	48 48	48 48	 3 57
  //    7  O  0	 4  8	 0  0	 0  T	 0  0	 0  0		  K

  sTeeboxTime := StrZeroAdd(ATeeboxTime, 3);
  sSendData := MODEN_STX + ADeviceId + 'O' + sTeeboxTime + '000' + 'T' + '0000' + MODEN_ETX;
  sBcc := GetBccModen(sSendData);
  sSendData := sSendData + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadModen.SetNextMonNo: Boolean;
var
  nTeeboxNo: Integer;
  sChannel: String;
begin

  while True do
  begin
    inc(FMonDeviceNoLast);
    if FMonDeviceNoLast > FMonDeviceNoEnd then
      FMonDeviceNoLast := FMonDeviceNoStart;

    sChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);
    nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(sChannel);
    if Global.Teebox.GetTeeboxInfoUseYn(nTeeboxNo) = 'Y' then
      Break;
  end;

end;

//2020-06-08 제어3회 시도후 에러처리
procedure TComThreadModen.SetTeeboxError(AChannel: String);
var
  rTeeboxInfo: TTeeboxInfo;
begin
  rTeeboxInfo.StoreCd := ''; //가맹점 코드
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, AChannel); //타석 번호
  rTeeboxInfo.RecvDeviceId := AChannel;
  rTeeboxInfo.TeeboxNm := '';  //타석명
  rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
  rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드
  rTeeboxInfo.UseStatus := '9';
  rTeeboxInfo.UseYn := '';        //사용 여부
  rTeeboxInfo.RemainBall := 0;
  rTeeboxInfo.RemainMinute := 0;
  rTeeboxInfo.ErrorCd := 8; //통신이상
  rTeeboxInfo.ErrorCd2 := '8'; //통신이상

  Global.Teebox.SetTeeboxInfo(rTeeboxInfo);
end;

procedure TComThreadModen.Execute;
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

            nTeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, FChannel);

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(nTeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogRetryWriteModen(FIndex, sLogMsg);

              FRecvData := '';

              FComPort.Close;
              FComPort.Open;
              Global.Log.LogRetryWriteModen(FIndex, 'ReOpen');

              inc(FCtlReTry);

              if FCtlReTry > 2 then //제어3회 시도후 에러처리
              begin
                FCtlReTry := 0;
                if FLastCmdDataIdx <> FCurCmdDataIdx then
                begin
                  inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
                  if FCurCmdDataIdx > BUFFER_SIZE then
                  FCurCmdDataIdx := 0;
                end;

                SetTeeboxError(FChannel);
                FCtlChannel := FChannel;
              end;

              Break;
            end
            else
            begin
              sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(nTeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogRetryWriteModen(FIndex, sLogMsg);

              Global.Teebox.SetTeeboxErrorCntModen(FIndex, nTeeboxNo, 'Y');
              SetNextMonNo;

              inc(FReTry);

              if FReTry > 10 then
              begin
                FReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogRetryWriteModen(FIndex, 'ReOpen');
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

          if FCtlChannel = FChannel then
            FCtlChannel := '';

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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 1);

        //2020-06-08 제어3회 시도후 에러처리
        if FCtlChannel = FChannel then
          Continue;

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogCtrlWriteModen(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);
        //Sleep(50);

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;

        FWriteTm := now + (((1/24)/60)/60) * 3; //5
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        FLastExeCommand := COM_MON;
        //FChannel := Global.Seat.GetSeatNoToDevic(FLastMonSeatNo);
        FChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);

        FSendData := MODEN_STX + FChannel + 'R' + '000' + '000' + 'T' + '0000' + MODEN_ETX;
        sBcc := GetBccModen(FSendData);
        FSendData := FSendData + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
        //Global.LogCtrlWriteA6001(FIndex, 'SendData : FLastMonSeatDeviceNo ' + IntToStr(FLastMonSeatDeviceNo) + ' / ' + FSendData);

        FWriteTm := now + (((1/24)/60)/60) * 2; //3
      end;

      FReceived := False;
      Sleep(100);  //50 이하인경우 retry 발생

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadModen Error : ' + e.Message + ' / ' + FSendData;
        //Global.Log.LogWrite(sLogMsg);
        Global.Log.LogRetryWriteModen(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.
