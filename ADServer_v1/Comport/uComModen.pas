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

    //2020-06-08 ����3ȸ �õ��� ����ó��
    FCtlReTry: Integer;
    FCtlChannel: String;

    FReceived: Boolean;
    FChannel: String;
    FFloor: String;

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    //FLastCtlTeeboxNo: Integer; //���� ����Ÿ����
    //FLastMonSeatNo: Integer; //���� ����͸� Ÿ����

    FIndex: Integer;
    FMonDeviceNoStart: Integer;
    FMonDeviceNoEnd: Integer;
    FMonDeviceNoLast: Integer;

    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

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

    // �������� : STX(1) + ID(1) + COMMAND(1) + DATA(6) + CLASS(1) + ETC(4) + ETX(1) + üũ��(1)
    // 1  2	 3	4	 5	6	 7	8	 9 10	11 12	13 14	15 16
    //   1	 A	0	 0	0	 0	0	 0	T	 0	0  0	1	 	,
    //02 31	41 30	30 30	30 30	30 54	30 30	30 31	03 2C
    // 2 49	65 48	48 48	48 48	48 84	48 48	48 49	 3 44

    //.7A049000T0001.?
    //.@A000000T0121.>

    rTeeboxInfo.StoreCd := ''; //������ �ڵ�
    rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, FChannel); //Ÿ�� ��ȣ
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

    //2�ڸ�(12)	0: Default, 1: �����߻�, 2: CALL SW,
    //3�ڸ�(13)	0: Default, �����ڵ�
    //4�ڸ�(14)	�Ŀ���Ʈ(1:���� ON, 0:���� OFF)

    //�����ڵ�
    //1	������ �Է� �ð� �ʰ�
    //2	���� ������ �Է½ð� �ʰ�(���� ��� �Ҹ�Ǿ���)
    //3	����1(��ũ) ���� �Է½ð� �ʰ�
    //4	����2(Ƽ��) ���� �Է½ð� �ʰ�
    //5	���Լ��� �Է½ð� �ʰ�

    rTeeboxInfo.UseYn := '';        //��� ����
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 4, 3));
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 7, 3));

    if copy(FRecvData, 12, 1) = '0' then //����
    begin
      if rTeeboxInfo.RemainMinute > 0 then //�����
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0'; //��Ÿ��(����)
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
      sLogMsg := IntToStr(FLastExeCommand) + ' ��û: ' + IntToStr(Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, FChannel)) +
                 ' / ' + Global.Teebox.GetDevicToTeeboxNm(FChannel) + ' / ' + FChannel +
                 ' / ����: ' + IntToStr(Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, FChannel)) +
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

procedure TComThreadModen.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime: AnsiString;
begin
  // �������� : STX(1) + ID(1) + COMMAND(1) + DATA(6) + CLASS(1) + ETC(4) + ETX(1) + üũ��(1)
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

//2020-06-08 ����3ȸ �õ��� ����ó��
procedure TComThreadModen.SetTeeboxError(AChannel: String);
var
  rTeeboxInfo: TTeeboxInfo;
begin
  rTeeboxInfo.StoreCd := ''; //������ �ڵ�
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNoModen(FFloor, AChannel); //Ÿ�� ��ȣ
  rTeeboxInfo.RecvDeviceId := AChannel;
  rTeeboxInfo.TeeboxNm := '';  //Ÿ����
  rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
  rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
  rTeeboxInfo.UseStatus := '9';
  rTeeboxInfo.UseYn := '';        //��� ����
  rTeeboxInfo.RemainBall := 0;
  rTeeboxInfo.RemainMinute := 0;
  rTeeboxInfo.ErrorCd := 8; //����̻�
  rTeeboxInfo.ErrorCd2 := '8'; //����̻�

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

              if FCtlReTry > 2 then //����3ȸ �õ��� ����ó��
              begin
                FCtlReTry := 0;
                if FLastCmdDataIdx <> FCurCmdDataIdx then
                begin
                  inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
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
      begin //������� �������� ������
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 1);

        //2020-06-08 ����3ȸ �õ��� ����ó��
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

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
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
      Sleep(100);  //50 �����ΰ�� retry �߻�

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
