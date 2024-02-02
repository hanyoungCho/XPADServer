unit uSeatControlCom;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TControlComPortMonThread = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;

    //2020-06-08 ����3ȸ �õ��� ����ó��
    FCtlReTry: Integer;
    FCtlChannel: String;

    FReceived: Boolean;
    FChannel: String;

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    FLastCtlSeatNo: Integer; //���� ����Ÿ����
    //FLastMonSeatNo: Integer; //���� ����͸� Ÿ����
    FLastMonSeatDeviceNo: Integer;
    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    FWriteTm: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    //procedure SetCmdSendBuffer(ASendData: AnsiString);

    procedure SetSeatError(AChannel: String);

    procedure SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);

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
  FCtlReTry := 0;

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

  //2020-06-17 ���� 19�ڸ� .0613@011799838A5C.$  , .0623@00529936D76C.$
  //(Length(FRecvData) <> 19) �߰�
  if (Length(FRecvData) <> 15) and (Length(FRecvData) <> 19) then
  begin
    Global.LogCtrlWrite('FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  (*
  if Count < 16 then
  begin
    //MainForm.LogView('��ûŸ����: ' + IntToStr(Global.Seat.GetDevicToSeatNo(FChannel)) + ' / �ѱ��ڼ�: ' + IntToStr(Count));
    FRecvData := FRecvData + sRecvData;

    if copy(FRecvData, 1, 1) <> '' then
    begin
      Global.LogCtrlWrite('FRecvData  fail : ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    if Length(FRecvData) > 16 then
    begin
      Global.LogCtrlWrite('Over : ' + FRecvData);
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
    Global.LogCtrlWrite('��ûŸ����: ' + IntToStr(Global.Seat.GetDevicToSeatNo(FChannel)) + ' / �ѱ��ڼ�: ' + IntToStr(Count) + ' / ' + FRecvData);
    FRecvData := '';
    Exit;
  end;
  *)
  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //1	2	3	4	5	6	7	8	9	10 11	12 13	14 15	16
    //	0	9	1	3	@	0	0	5	 4	9	 9	2	 5		 2
    //02 30	39 31	33 40	30 30	35 34	39 39	32 35	03 32
    rSeatInfo.StoreCd := ''; //������ �ڵ�
    rSeatInfo.SeatNo := Global.Seat.GetDevicToSeatNo(copy(FRecvData, 2, 3)); //Ÿ�� ��ȣ
    rSeatInfo.RecvDeviceId := FChannel;
    rSeatInfo.SeatNm := '';  //Ÿ����
    rSeatInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rSeatInfo.SeatZoneCode := '';  //���� ���� �ڵ�

    //2020-06-17 ���� @,0 �ΰ�� �߻�
    if (copy(FRecvData, 6, 1) = '@') or (copy(FRecvData, 6, 1) = '0') then //����
    begin
      if copy(FRecvData, 5, 1) = '4' then //��Ÿ��(����)
        rSeatInfo.UseStatus := '0'
      else if copy(FRecvData, 5, 1) = '3' then //�����
        rSeatInfo.UseStatus := '1'
      else if copy(sRecvData, 5, 1) = '2' then //������: S0 ���� �����ϴ°��
        rSeatInfo.UseStatus := '0'
      else
        rSeatInfo.UseStatus := '0';
    end
    else if copy(FRecvData, 6, 1) = '1' then
    begin
      rSeatInfo.UseStatus := '9';
      rSeatInfo.ErrorCd := 2; //error: ������
    end
    else if copy(FRecvData, 6, 1) = '2' then
    begin
      rSeatInfo.UseStatus := '9';
      rSeatInfo.ErrorCd := 1; //���ɸ�
    end
    else if copy(FRecvData, 6, 1) = '3' then
    begin
      rSeatInfo.UseStatus := '9';
      rSeatInfo.ErrorCd := 4; //error: �����̻�
    end
    {
    else if copy(FRecvData, 6, 1) = 'A' then
    begin
      rSeatInfo.UseStatus := '9';
      rSeatInfo.ErrorCd := 10;
    end
    else if copy(FRecvData, 6, 1) = 'B' then //���Error
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
      rSeatInfo.UseStatus := '9';  //Error ����: 1,2,3,A,B,C
      rSeatInfo.ErrorCd := 0;

      sLogMsg := 'Error Code: ' + intToStr(rSeatInfo.SeatNo) + ' / ' + copy(FRecvData, 6, 1);
      Global.LogWrite(sLogMsg);
    end;

    rSeatInfo.UseYn := '';        //��� ����
    rSeatInfo.RemainBall := StrToInt(copy(FRecvData, 11, 4));
    rSeatInfo.RemainMinute := StrToInt(copy(FRecvData, 7, 4));

    rSeatInfo.RecvData := FRecvData;
    rSeatInfo.SendData := FSendData;
    //BCC := copy(Buff, 16, 1);

    //sLogMsg := StringToHex(FRecvData);
    //MainForm.LogView(sLogMsg);

    Global.Seat.SetSeatInfo(rSeatInfo);

    if FLastExeCommand = COM_CTL then
    begin
      sLogMsg := IntToStr(FLastExeCommand) + ' ��û: ' + IntToStr(Global.Seat.GetDevicToSeatNo(FChannel)) +
                 ' / ' + Global.Seat.GetDevicToSeatNm(FChannel) + ' / ' + FChannel +
                 ' / ����: ' + IntToStr(Global.Seat.GetDevicToSeatNo(Copy(FRecvData, 2, 3))) +
                 ' / ' + FRecvData;
      Global.LogCtrlWrite(sLogMsg);
    end;

    sLogMsg := IntToStr(rSeatInfo.SeatNo) + ' / ' + FSendData + '   ' + FRecvData;
    Global.DebugLogViewWrite(sLogMsg);
    //Global.LogWrite(sLogMsg);
  end
  else
  begin
    sLogMsg := 'FChannel Fail : ' + IntToStr(Global.Seat.GetDevicToSeatNo(FChannel)) + ' / ' + FChannel + ' / ' + FRecvData;
    Global.LogCtrlWrite(sLogMsg);

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
      inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
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
procedure TControlComPortMonThread.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
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

//2020-06-08 ����3ȸ �õ��� ����ó��
procedure TControlComPortMonThread.SetSeatError(AChannel: String);
var
  rSeatInfo: TSeatInfo;
begin
  rSeatInfo.StoreCd := ''; //������ �ڵ�
  rSeatInfo.SeatNo := Global.Seat.GetDevicToSeatNo(AChannel); //Ÿ�� ��ȣ
  rSeatInfo.RecvDeviceId := AChannel;
  rSeatInfo.SeatNm := '';  //Ÿ����
  rSeatInfo.FloorZoneCode := ''; //�� ���� �ڵ�
  rSeatInfo.SeatZoneCode := '';  //���� ���� �ڵ�
  rSeatInfo.UseStatus := '9';
  rSeatInfo.UseYn := '';        //��� ����
  rSeatInfo.RemainBall := 0;
  rSeatInfo.RemainMinute := 0;
  rSeatInfo.ErrorCd := 8; //����̻�

  Global.Seat.SetSeatInfo(rSeatInfo);
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

      while True do
      begin
        if FReceived = False then
        begin

          if now > FWriteTm then
          begin

            nSeatNo := Global.Seat.GetDevicToSeatNo(FChannel);

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
              Global.LogRetryWrite(sLogMsg);

              FRecvData := '';

              FComPort.Close;
              FComPort.Open;
              Global.LogRetryWrite('ReOpen');

              inc(FCtlReTry);
              //2020-06-08 ����3ȸ �õ��� ����ó��
              if FCtlReTry > 2 then
              begin
                FCtlReTry := 0;
                if FLastCmdDataIdx <> FCurCmdDataIdx then
                begin
                  inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
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
              sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
              Global.LogRetryWrite(sLogMsg);

              inc(FLastMonSeatDeviceNo);
              if FLastMonSeatDeviceNo > Global.Seat.SeatDevicNoCnt - 1 then
                FLastMonSeatDeviceNo := 0;

              inc(FReTry);

              if FReTry > 10 then
              begin
                FReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.LogRetryWrite('ReOpen');
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
      begin //������� �������� ������
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);

        //2020-06-08 ����3ȸ �õ��� ����ó��
        if FCtlChannel = FChannel then
          Continue;

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.LogCtrlWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);
        //Sleep(50);

        //FWriteTm := now + (((1/24)/60)/60) * 1;
        FWriteTm := now + (((1/24)/60)/60) * 0.1;

        while True do
        begin
          if now > FWriteTm then
          begin
            Break;
          end;
        end;

        //������ ���ϰ��� ����
        sBcc := GetBCC(ZOOM_MON_STX, FChannel, ZOOM_REQ_ETX);
        FSendData := ZOOM_MON_STX + FChannel + ZOOM_REQ_ETX + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.LogCtrlWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        if Global.Seat.BallBackEnd = True then
        begin
          Global.Seat.BallBackEndCtl := True;
        end;

        FWriteTm := now + (((1/24)/60)/60) * 5;
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        //1	2	3	4	5	6
        //	0	1	1		6
        //01	30	31	31	04	36
        FLastExeCommand := COM_MON;
        //FChannel := Global.Seat.GetSeatNoToDevic(FLastMonSeatNo);
        FChannel := Global.Seat.GetSeatDevicdNoToDevic(FLastMonSeatDeviceNo);

        sBcc := GetBCC(ZOOM_MON_STX, FChannel, ZOOM_REQ_ETX);
        FSendData := ZOOM_MON_STX + FChannel + ZOOM_REQ_ETX + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
        //Global.LogCtrlWrite('SendData : FLastMonSeatDeviceNo ' + IntToStr(FLastMonSeatDeviceNo) + ' / ' + FSendData);

        FWriteTm := now + (((1/24)/60)/60) * 3;
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
      Sleep(100);  //50 �����ΰ�� retry �߻�

    except
      on e: Exception do
      begin
        sLogMsg := 'TControlComPortMonThread Error : ' + e.Message + ' / ' + FSendData;
        Global.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
