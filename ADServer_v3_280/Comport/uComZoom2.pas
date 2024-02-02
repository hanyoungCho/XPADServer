unit uComZoom2;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadZoom2 = class(TThread)
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

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    FLastCtlSeatNo: Integer; //최종 제어타석기
    //FLastMonSeatNo: Integer; //최종 모니터링 타석기
    FMonDeviceNoLast: Integer;
    FLastExeCommand: Integer; //최종 패킷 수행 펑션

    FWriteTm: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    //procedure SetCmdSendBuffer(ASendData: AnsiString);

    procedure SetTeeboxError(AChannel: String);

    procedure SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadZoom }

constructor TComThreadZoom2.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
  //FComPort.BaudRate := br9600;
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  FComPort.Parity.Bits := prOdd;
  FComPort.Open;

  FReTry := 0;
  FCtlReTry := 0;

  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastMonSeatNo := 1;
  FMonDeviceNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadZoom2 Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadZoom2.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadZoom2.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;
  //SeatInfo: TTeeboxInfo;

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

  if Pos(ZOOM_STX, FRecvData) = 0 then
    Exit;

  if Pos(ZOOM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(ZOOM_STX, FRecvData);
  nEtx := Pos(ZOOM_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 15) then
  begin
    Global.Log.LogCtrlWrite('FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //1	2	3	4	5	6	7	8	9	10 11	12 13	14 15	16
    //	0	9	1	3	@	0	0	5	 4	9	 9	2	 5		 2
    //02 30	39 31	33 40	30 30	35 34	39 39	32 35	03 32
    rTeeboxInfo.StoreCd := ''; //가맹점 코드
    rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(copy(FRecvData, 2, 3)); //타석 번호
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //타석명
    rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
    rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드

    if (copy(FRecvData, 6, 1) = '@') or (copy(FRecvData, 6, 1) = '0') then //정상
    begin
      if copy(FRecvData, 5, 1) = '4' then //빈타석(정지)
        rTeeboxInfo.UseStatus := '0'
      else if copy(FRecvData, 5, 1) = '3' then //사용중
        rTeeboxInfo.UseStatus := '1'
      else if copy(sRecvData, 5, 1) = '2' then //예약중: S0 으로 제어하는경우
        rTeeboxInfo.UseStatus := '0'
      else
        rTeeboxInfo.UseStatus := '0';
    end
    else if copy(FRecvData, 6, 1) = '1' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 2; //error: 볼없음

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / 1';
      Global.Log.LogWrite(sLogMsg);
    end
    else if copy(FRecvData, 6, 1) = '2' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 1; //볼걸림

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / 2';
      Global.Log.LogWrite(sLogMsg);
    end
    else if copy(FRecvData, 6, 1) = '3' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 4; //error: 모터이상

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / 3';
      Global.Log.LogWrite(sLogMsg);
    end
    {
    else if copy(FRecvData, 6, 1) = 'A' then
    begin
      rSeatInfo.UseStatus := '9';
      rSeatInfo.ErrorCd := 10;
    end
    else if copy(FRecvData, 6, 1) = 'B' then //장비Error
    begin
      rSeatInfo.UseStatus := '9';
      rSeatInfo.ErrorCd := 11;
    end
    else if copy(FRecvData, 6, 1) = 'C' then
    begin
      rSeatInfo.UseStatus := '9';
      rSeatInfo.ErrorCd := 12;
    end
    }
    else //C
    begin
      rTeeboxInfo.UseStatus := '9';  //Error 종류: 1,2,3,A,B,C
      rTeeboxInfo.ErrorCd := 0;

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / ' + copy(FRecvData, 6, 1);
      Global.Log.LogWrite(sLogMsg);
    end;

    rTeeboxInfo.UseYn := '';        //사용 여부
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 11, 4));
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 7, 4));

    rTeeboxInfo.RecvData := FRecvData;
    rTeeboxInfo.SendData := FSendData;
    //BCC := copy(Buff, 16, 1);

    //sLogMsg := StringToHex(FRecvData);
    //MainForm.LogView(sLogMsg);

    //Global.Teebox.SetTeeboxInfo(rTeeboxInfo);
    Global.Teebox.SetTeeboxInfoJMS(rTeeboxInfo);

    if FLastExeCommand = COM_CTL then
    begin
      sLogMsg := IntToStr(FLastExeCommand) + ' 요청: ' + IntToStr(Global.Teebox.GetDevicToTeeboxNo(FChannel)) +
                 ' / ' + Global.Teebox.GetDevicToTeeboxNm(FChannel) + ' / ' + FChannel +
                 ' / 응답: ' + IntToStr(Global.Teebox.GetDevicToTeeboxNo(Copy(FRecvData, 2, 3))) +
                 ' / ' + FRecvData;
      Global.Log.LogCtrlWrite(sLogMsg);
    end;

    sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + '   ' + FRecvData;
    Global.DebugLogViewWrite(sLogMsg);
    //Global.LogWrite(sLogMsg);
  end
  else
  begin
    sLogMsg := 'FChannel Fail : ' + IntToStr(Global.Teebox.GetDevicToTeeboxNo(FChannel)) + ' / ' + FChannel + ' / ' + FRecvData;
    Global.Log.LogCtrlWrite(sLogMsg);

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
      inc(FMonDeviceNoLast);
      if FMonDeviceNoLast > Global.Teebox.TeeboxDevicNoCnt - 1 then
        FMonDeviceNoLast := 0;

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

//procedure TControlComPortMonThread.SetCmdSendBuffer(ASendData: AnsiString);
procedure TComThreadZoom2.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sSeatTime, sSeatBall: AnsiString;
begin
  sSeatTime := StrZeroAdd(ASeatTime, 4);
  sSeatBall := StrZeroAdd(ASeatBall, 4);

  sSendData := ADeviceId + AType + sSeatTime + sSeatBall;
  sBcc := GetBccCtl(ZOOM_CTL_STX, sSendData, ZOOM_REQ_ETX);
  sSendData := ZOOM_CTL_STX + sSendData + ZOOM_REQ_ETX + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

//2020-06-08 제어3회 시도후 에러처리
procedure TComThreadZoom2.SetTeeboxError(AChannel: String);
var
  rTeeboxInfo: TTeeboxInfo;
begin
  rTeeboxInfo.StoreCd := ''; //가맹점 코드
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(AChannel); //타석 번호
  rTeeboxInfo.RecvDeviceId := AChannel;
  rTeeboxInfo.TeeboxNm := '';  //타석명
  rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
  rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드
  rTeeboxInfo.UseStatus := '9';
  rTeeboxInfo.UseYn := '';        //사용 여부
  rTeeboxInfo.RemainBall := 0;
  rTeeboxInfo.RemainMinute := 0;
  rTeeboxInfo.ErrorCd := 8; //통신이상

  Global.Teebox.SetTeeboxInfo(rTeeboxInfo);
end;

procedure TComThreadZoom2.Execute;
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
            sLogMsg := 'Retry COM Received Fail : ' + IntToStr(nTeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
            Global.Log.LogRetryWrite(sLogMsg);

            FRecvData := '';

            FComPort.Close;
            FComPort.Open;
            Global.Log.LogRetryWrite('ReOpen');

            inc(FReTry);
            // 2회 시도후 에러처리
            if FReTry > 2 then
            begin
              FReTry := 0;

              inc(FMonDeviceNoLast);
              if FMonDeviceNoLast > Global.Teebox.TeeboxDevicNoCnt - 1 then
                FMonDeviceNoLast := 0;

              SetTeeboxError(FChannel);
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
      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //대기중인 제어명령이 있으면
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);

        //2020-06-08 제어3회 시도후 에러처리
        if FCtlChannel = FChannel then
          Continue;

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogCtrlWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);
        Sleep(100);
        {
        //FWriteTm := now + (((1/24)/60)/60) * 1;
        FWriteTm := now + (((1/24)/60)/60) * 0.1;
        //FWriteTm := now + (((1/24)/60)/60) * 0.3;

        while True do
        begin
          if now > FWriteTm then
          begin
            Break;
          end;
        end;
        }
        //제어후 리턴값이 없음
        sBcc := GetBCC(ZOOM_MON_STX, FChannel, ZOOM_REQ_ETX);
        FSendData := ZOOM_MON_STX + FChannel + ZOOM_REQ_ETX + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogCtrlWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;

        //FWriteTm := now + (((1/24)/60)/60) * 5;
        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        //1	2	3	4	5	6
        //	0	1	1		6
        //01	30	31	31	04	36
        FLastExeCommand := COM_MON;
        //FChannel := Global.Seat.GetSeatNoToDevic(FLastMonSeatNo);
        FChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);

        sBcc := GetBCC(ZOOM_MON_STX, FChannel, ZOOM_REQ_ETX);
        FSendData := ZOOM_MON_STX + FChannel + ZOOM_REQ_ETX + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
        //Global.LogCtrlWrite('SendData : FLastMonSeatDeviceNo ' + IntToStr(FLastMonSeatDeviceNo) + ' / ' + FSendData);

        //FWriteTm := now + (((1/24)/60)/60) * 3;
        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;
      {
      FWriteTm := now + (((1/24)/60)/60) * 0.1;

      while True do
      begin
        if now > FWriteTm then
        begin
          Break;
        end;
      end;
      Sleep(0);
      }
      Sleep(100);  //50 이하인경우 retry 발생

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadZoom Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
