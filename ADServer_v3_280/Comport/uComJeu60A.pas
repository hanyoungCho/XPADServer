unit uComJeu60A;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadJeu60A = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;

    //2020-12-03 제어3회 시도후 에러처리
    FCtlReTry: Integer;
    FCtlChannel: String;

    FReceived: Boolean;
    FChannel: String;
    FFloor: String;

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    FLastCtlSeatDeviceNo: String; //제어타석기 모니터링용

    FIndex: Integer;
    FMonSeatDeviceNoStart: Integer;
    FMonSeatDeviceNoEnd: Integer;
    FLastMonSeatDeviceNo: Integer;

    FLastExeCommand: Integer; //최종 패킷 수행 펑션

    FWriteTm: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortSetting(Index, AStart, AEnd: Integer);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);

    procedure SetSeatError(AChannel: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJeu60A }

constructor TComThreadJeu60A.Create;
begin

  //상태 7byte
  // 1	2	 3	4	 5	6	 7  / 100번 타석 데이타 요청, ENQ(1)+ID(3)+BCC(2)+ETX
  //05	1	 0  0	 9  1 03
  //05 31	30 30	39 31	03

  //응답 17byte
  //         100번,    30분,       200개, STX(1)+ID(3)+잔여시간(3)+잔여볼(4)+시작(1)+종료(1)+에러(1)+BCC(2)+ETX(1)
  // 1,	 2	 3	4,  5	 6	7,	8	 9 10 11, 12 13 14, 15 16, 17
  //02,	 1   0	0,  0  3	0,	0	 2	0	 0,	 0  0	 0,  8  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30, 38 36, 03

  //제어 20byte
  //        100번,     30분,   잔여200개,     시작0개, 볼수UP, STX(1)+ID(3)+시간(3)+잔여볼(4)+시작볼(4)+볼수UP/DOWN(1)+종료(1)+BCC(2)+ETX
  // 1,	 2	 3	4,  5	 6  7,	8	 9 10 11, 12 13 14 15, 16 17, 18 19, 20
  //02,  1   0	0,  0  3  0,	0	 2	0	 0,  0  0	 0  0,	0	 0,  8  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30 30, 30 30, 38 36, 03
  //02 37 39 30 31 30 30 39 39 39 30 34 03

  {
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  //FComPort.Port := 'COM11';
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  //FComPort.Parity.Bits := GetParity(Global.ADConfig.Parity);
  FComPort.Open;
  }

  FReTry := 0;
  FCtlReTry := 0;

  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FLastCtlSeatDeviceNo := '';
  FLastMonSeatDeviceNo := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadJeu60A Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadJeu60A.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadJeu60A.ComPortSetting(Index, AStart, AEnd: Integer);
begin
  FMonSeatDeviceNoStart := AStart - 1;
  FMonSeatDeviceNoEnd := AEnd - 1;
  FLastMonSeatDeviceNo := AStart - 1;
  FIndex := Index;
  FFloor := IntToStr(Index);

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;

  if Index = 1 then
  begin
    FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
    FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
    FComPort.Open;
  end;

  if Index = 2 then
  begin
    FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port2);
    FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate2);
    FComPort.Open;
  end;

  if Index = 3 then
  begin
    FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port3);
    FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate3);
    FComPort.Open;
  end;

  if Index = 4 then
  begin
    FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port4);
    FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate4);
    FComPort.Open;
  end;

  Global.Log.LogWrite('TComThreadJeu60A ComPortSetting : ' + IntToStr(Index) + '/' + IntToStr(AStart) + '/' + IntToStr(AEnd));
end;

procedure TComThreadJeu60A.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;
  //SeatInfo: TTeeboxInfo;

  Index: Integer;
  sRecvData: AnsiString;
  rSeatInfo: TTeeboxInfo;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  if Count < JEU_RECV_LENGTH_17 then
  begin
    FRecvData := FRecvData + sRecvData;

    if copy(FRecvData, 1, 1) = JEU_MON_ERR then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : 04 수신에러' + IntToStr(FLastExeCommand) + ' : ' +
                          IntToStr(Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)) + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';

      if FLastExeCommand = COM_MON then
      begin
        //SetNextMonNo;
      end;
      //FReceived := True;

      Exit;
    end;

    if copy(FRecvData, 1, 1) = JEU_NAK then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : 15 송신에러' + IntToStr(FLastExeCommand) + ' : ' +
                          IntToStr(Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)) + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    // 타석종료처리시 응답 확인, 그외 상항 아직 미확인됨
    if copy(FRecvData, 1, 1) = JEU_CTL_FIN then //제어 응답
    begin
      sLogMsg := 'FRecvData CTL Succese ' + IntToStr(FLastExeCommand) + ' : ' + FSendData + ' / ' + FRecvData;

      rSeatInfo.StoreCd := ''; //가맹점 코드
      rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel); //타석 번호
      rSeatInfo.TeeboxNm := '';  //타석명
      rSeatInfo.FloorZoneCode := ''; //층 구분 코드
      rSeatInfo.TeeboxZoneCode := '';  //구역 구분 코드
      rSeatInfo.UseYn := '';        //사용 여부
      rSeatInfo.RemainBall := StrToInt(copy(FSendData, 8, 4));
      rSeatInfo.RemainMinute := StrToInt(copy(FSendData, 5, 3));

      if rSeatInfo.RemainMinute > 0 then
        rSeatInfo.UseStatus := '1'
      else
        rSeatInfo.UseStatus := '0';

      Global.Teebox.SetTeeboxInfoAD(rSeatInfo);

      if FLastCmdDataIdx <> FCurCmdDataIdx then
      begin
        inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
        if FCurCmdDataIdx > BUFFER_SIZE then
          FCurCmdDataIdx := 0;
      end;

      Global.Log.LogReadMulti(FIndex, sLogMsg);
      FRecvData := '';
      FReceived := True;

      sLogMsg := IntToStr(rSeatInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
      //Global.DebugLogViewWrite(sLogMsg);
      Global.DebugLogMainViewMulti(FIndex, sLogMsg);

      Exit;
    end;

    if copy(FRecvData, 1, 1) <> JEU_STX then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : STX 02 Error ' + IntToStr(FLastExeCommand) + ' : ' +
                          IntToStr(Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)) + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    if Length(FRecvData) > JEU_RECV_LENGTH_17 then
    begin
      Global.Log.LogReadMulti(FIndex, 'Over : ' + FRecvData);
      FRecvData := '';
      Exit;
    end
    else if Length(FRecvData) < JEU_RECV_LENGTH_17 then
    begin
      Exit;
    end;

  end
  else if Count = JEU_RECV_LENGTH_17 then
  begin
    FRecvData := sRecvData;
  end
  else
  begin
    Global.Log.LogReadMulti(FIndex, '요청타석기: ' + IntToStr(Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)) + ' / 총글자수: ' + IntToStr(Count) + ' / ' + FRecvData);
    FRecvData := '';
    Exit;
  end;


  {
  if Pos(ZOOM_STX, FRecvData) = 0 then
    Exit;

  if Pos(ZOOM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(ZOOM_STX, FRecvData);
  nEtx := Pos(ZOOM_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  //2020-06-17 양평 19자리 .0613@011799838A5C.$  , .0623@00529936D76C.$
  //(Length(FRecvData) <> 19) 추가
  if (Length(FRecvData) <> 15) and (Length(FRecvData) <> 19) then
  begin
    Global.Log.LogCtrlWrite('FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;
  }


  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //         100번,    30분,       200개, STX(1)+ID(3)+잔여시간(3)+잔여볼(4)+시작(1)+종료(1)+에러(1)+BCC(2)+ETX(1)
    // 1,	 2	 3	4,  5	 6	7,	8	 9 10 11, 12 13 14, 15 16, 17
    //02,	 1   0	0,  0  3	0,	0	 2	0	 0,	 0  0	 0,  8  6, 03
    //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30, 38 36, 03

    //시작 0:OFF, 1:ON
    //종료 0:자동동작중, 1:수동동작중, 9:종료(대기상태)
    //에러 0:에러없음, 1:티업센서이상, 2:타코센서이상, 3:버퍼센서이상, 4:장치없음?

    rSeatInfo.StoreCd := ''; //가맹점 코드
    rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel); //타석 번호
    rSeatInfo.TeeboxNm := '';  //타석명
    rSeatInfo.FloorZoneCode := ''; //층 구분 코드
    rSeatInfo.TeeboxZoneCode := '';  //구역 구분 코드
    //001 036 0101 000 02
    //002 000 0000 090 01

    if copy(FRecvData, 14, 1) = '0' then //정상
    begin
      if copy(FRecvData, 13, 1) = '9' then //시작:종료
        rSeatInfo.UseStatus := '0'
      else if copy(FRecvData, 13, 1) = '0' then //사용중
        rSeatInfo.UseStatus := '1'
      else
        rSeatInfo.UseStatus := '0';
    end
    else // 1,2,3 장비Error
    begin
      rSeatInfo.UseStatus := '9';
      rSeatInfo.ErrorCd := 0;

      rSeatInfo.ErrorCd := 10 + StrToInt( copy(FRecvData, 14, 1) );

      sLogMsg := 'Error Code: ' + intToStr(rSeatInfo.TeeboxNo) + ' / ' + copy(FRecvData, 14, 1);
      //Global.LogWrite(sLogMsg);
      Global.Log.LogReadMulti(FIndex, sLogMsg);
    end;

    if isNumber(copy(FRecvData, 5, 7)) = False then
    begin
      sLogMsg := 'Int Error : ' + IntToStr(rSeatInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
      Global.Log.LogReadMulti(FIndex, sLogMsg);
      FRecvData := '';
      Exit;
    end;

    rSeatInfo.UseYn := '';        //사용 여부
    rSeatInfo.RemainBall := StrToInt(copy(FRecvData, 8, 4));
    rSeatInfo.RemainMinute := StrToInt(copy(FRecvData, 5, 3));

    Global.Teebox.SetTeeboxInfoAD(rSeatInfo);

    sLogMsg := IntToStr(rSeatInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
    //Global.DebugLogViewWrite(sLogMsg);
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);

  end
  else
  begin
    FRecvData := '';
    Exit;
  end;

  if FLastExeCommand = COM_MON then
  begin
    //Global.Teebox.SetTeeboxErrorCnt(rSeatInfo.TeeboxNo, 'N', 10);
    SetNextMonNo;
  end;

  if FLastExeCommand = COM_CTL then
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

procedure TComThreadJeu60A.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sSeatTime, sSeatBall: AnsiString;
begin
  sSeatTime := StrZeroAdd(ASeatTime, 3);

  //제우테크 6.0A 인경우 현재볼수는 사용횟수 이므로 제어시 볼다시 셋팅
  //sSeatBall := StrZeroAdd(ASeatBall, 4);
  sSeatBall := '9999';

  //        100번,     30분,   잔여200개,     시작0개, 볼수UP, STX(1)+ID(3)+시간(3)+잔여볼(4)+시작볼(4)+볼수UP/DOWN(1)+종료(1)+BCC(2)+ETX
  // 1,	 2	 3	4,  5	 6  7,	8	 9 10 11, 12 13 14 15, 16 17, 18 19, 20
  //02,  1   0	0,  0  3  0,	0	 2	0	 0,  0  0	 0  0,	0	 0,  8  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30 30, 30 30, 38 36, 03
  //02 37 39 30 31 30 30 39 39 39 30 34 03

  if sSeatTime = '000' then
    sSendData := ADeviceId + sSeatTime + '0000' + '0000' + '0' + '9'
  else
    sSendData := ADeviceId + sSeatTime + sSeatBall + '0000' + '0' + '0';

  sBcc := GetBccJehu2Byte(sSendData);

  sSendData := JEU_STX + sSendData + sBcc + JEU_ETX;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadJeu60A.SetNextMonNo: Boolean;
var
  nSeatNo: Integer;
  sChannel: String;
begin

  while True do
  begin
    inc(FLastMonSeatDeviceNo);
    {
    if FLastMonSeatDeviceNo > Global.Seat.SeatDevicNoCnt - 1 then
      FLastMonSeatDeviceNo := 0;
    }

    if FLastMonSeatDeviceNo > FMonSeatDeviceNoEnd then
      FLastMonSeatDeviceNo := FMonSeatDeviceNoStart;

    sChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FLastMonSeatDeviceNo);

    if (Global.ADConfig.StoreCode = 'A6001') and (sChannel = '097') then //캐슬렉스 097 통신응답이 없음
    begin
      inc(FLastMonSeatDeviceNo);

      if FLastMonSeatDeviceNo > FMonSeatDeviceNoEnd then
        FLastMonSeatDeviceNo := FMonSeatDeviceNoStart;

      sChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FLastMonSeatDeviceNo);

      nSeatNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, sChannel);
      if Global.Teebox.GetTeeboxInfoUseYn(nSeatNo) = 'Y' then
        Break;
    end
    else
    begin
      nSeatNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, sChannel);
      if Global.Teebox.GetTeeboxInfoUseYn(nSeatNo) = 'Y' then
        Break;
    end;
  end;

end;

//2020-12-03 제어3회 시도후 에러처리
procedure TComThreadJeu60A.SetSeatError(AChannel: String);
var
  rSeatInfo: TTeeboxInfo;
begin
  rSeatInfo.StoreCd := ''; //가맹점 코드
  rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, AChannel); //타석 번호
  rSeatInfo.RecvDeviceId := AChannel;
  rSeatInfo.TeeboxNm := '';  //타석명
  rSeatInfo.FloorZoneCode := ''; //층 구분 코드
  rSeatInfo.TeeboxZoneCode := '';  //구역 구분 코드
  rSeatInfo.UseStatus := '9';
  rSeatInfo.UseYn := '';        //사용 여부
  rSeatInfo.RemainBall := 0;
  rSeatInfo.RemainMinute := 0;
  rSeatInfo.ErrorCd := 8; //통신이상

  Global.Teebox.SetTeeboxInfoAD(rSeatInfo);
end;

procedure TComThreadJeu60A.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nSeatNo: Integer;
  rSeatInfo: TTeeboxInfo; //배정시간 변경확인용
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

            nSeatNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel);

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(FIndex) + ' / ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

              FRecvData := '';

              FComPort.Close;
              FComPort.Open;
              Global.Log.LogWriteMulti(FIndex, 'ReOpen');

              inc(FCtlReTry);
              //2020-12-03 제어3회 시도후 에러처리
              if FCtlReTry > 2 then
              begin
                FCtlReTry := 0;
                if FLastCmdDataIdx <> FCurCmdDataIdx then
                begin
                  inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
                  if FCurCmdDataIdx > BUFFER_SIZE then
                  FCurCmdDataIdx := 0;
                end;

                SetSeatError(FChannel);
                FCtlChannel := FChannel;
              end;

              Break;
            end
            else
            begin
              sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(FIndex) + ' / ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

              FRecvData := '';

              //Global.Teebox.SetTeeboxErrorCnt(nSeatNo, 'Y', 10);
              SetNextMonNo;

              inc(FReTry);

              if FReTry > 10 then
              begin
                FReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogWriteMulti(FIndex, 'ReOpen');
              end;

              Break;
            end;

          end;

        end
        else
        begin
          if FLastExeCommand = COM_CTL then
          begin
            nSeatNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel);
            sLogMsg := 'Received True : ' + IntToStr(FIndex) + ' / ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
            Global.Log.LogWriteMulti(FIndex, sLogMsg);

            FCtlReTry := 0;
          end;

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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);

        //2020-12-03 제어3회 시도후 에러처리
        if FCtlChannel = FChannel then
          Continue;

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];

        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogWriteMulti(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FIndex) + ' / ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        FWriteTm := now + (((1/24)/60)/60) * 2; //5

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        // 1	2	 3	4	 5	6	 7  / 100번 타석 데이타 요청, ENQ(1)+ID(3)+BCC(2)+ETX
        //05	1	 0  0	 9  1 03
        //05 31	30 30	39 31	03
        FLastExeCommand := COM_MON;
        FChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FLastMonSeatDeviceNo);

        //Global.LogCtrlWriteA6001(FIndex, 'FLastMonSeatDeviceNo ' + IntToStr(FLastMonSeatDeviceNo) + ' / ' + FChannel);

        sBcc := GetBccJehu2Byte(FChannel);
        FSendData := JEU_ENQ + FChannel + sBcc + JEU_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1; //5
      end;

      FReceived := False;
      Sleep(100);

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadJeu60A Error : ' + IntToStr(FIndex) + ' / ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);

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
