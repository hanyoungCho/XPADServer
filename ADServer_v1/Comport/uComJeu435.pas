unit uComJeu435;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadJeu435 = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FReceived: Boolean;
    FChannel: String;
    FFloor: String;

    //2021-04-07 ����3ȸ �õ��� ����ó��
    FCtlReTry: Integer;
    FCtlChannel: String;

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    FLastCtlSeatDeviceNo: String; //����Ÿ���� ����͸���
    FLastMonSeatDeviceNo: Integer;
    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    FIndex: Integer;
    FMonSeatDeviceNoStart: Integer;
    FMonSeatDeviceNoEnd: Integer;

    FWriteTm: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortSetting(Index, AStart, AEnd: Integer);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    //procedure SetCmdSendBuffer(ASendData: AnsiString);
    procedure SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);

    procedure SetSeatError(AChannel: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJeu435 }

constructor TComThreadJeu435.Create;
begin
  // ���� 15byte
  // 10�� 30�� 200��, STX(1)+ID(2)+�ܿ��ð�(3)+�ܿ���(4)+����(1)+����(1)+����(1)+BCC(1)+ETX(1)
  // 1,	 2	 3,	4  5  6,	7  8  9 10, 11 12 13, 14, 15
  //02,	 1   0,	0  3	0,	0	 2	0	 0,	 0  0	 0,  6, 03
  //02, 31	30, 30 33 30, 30 32 30 30, 30 30 30, 36, 03

  // ����13byte
  // 13�� 63���ܿ�999�� ����0�� ����UP, STX(1)+ID(2)+�ð�(3)+�ܿ���(4)+����(1)+BCC(1)+ETX
  //  1,	2	 3,	 4	5	 6,	 7	8	 9 10, 11, 12, 13
  //  ,	1	 3,	 0	6	 3,	 0	9	 9	9,	0,	0,	
  // 02, 31	33,	30 36	33,	30 39	39 39, 30, 30, 03

  // ���� 5byte
  // 1	2	 3	4	 5  / 10�� Ÿ�� ����Ÿ ��û, ENQ(1)+ID(2)+BCC(1)+ETX
  //05	1	 0  1 03
  //05 31	30 31	03
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
  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FLastCtlSeatDeviceNo := '';
  FLastMonSeatDeviceNo := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadJeu435 Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadJeu435.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadJeu435.ComPortSetting(Index, AStart, AEnd: Integer);
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

  Global.Log.LogWrite('TComThreadJeu435 ComPortSetting : ' + IntToStr(Index));
end;

procedure TComThreadJeu435.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode, nTeeboxNo: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;
  //SeatInfo: TTeeboxInfo;

  Index: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  if Count < JEU_RECV_LENGTH then
  begin
    FRecvData := FRecvData + sRecvData;

    if copy(FRecvData, 1, 1) <> JEU_STX then
    begin
      if (Global.ADConfig.StoreCode = 'A8001') then //�����
        nTeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)
      else
        nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);

      Global.Log.LogCtrlWriteA6001(FIndex, 'FRecvData fail : STX 02 Error ' + IntToStr(FLastExeCommand) + ' : ' +
       IntToStr(nTeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData);

      FRecvData := '';
      Exit;
    end;

    if copy(FRecvData, 2, 1) = JEU_MON_ERR then
    begin
      if (Global.ADConfig.StoreCode = 'A8001') then //�����
        nTeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)
      else
        nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);

      Global.Log.LogCtrlWriteA6001(FIndex, 'FRecvData fail : 04 ���ſ��� ' + IntToStr(FLastExeCommand) + ' : ' +
       IntToStr(nTeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';

      if FLastExeCommand = COM_MON then
      begin
        //SetNextMonNo;
      end;
      //FReceived := True;

      Exit;
    end;

    if copy(FRecvData, 2, 1) = JEU_NAK then
    begin
      if (Global.ADConfig.StoreCode = 'A8001') then //�����
        nTeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)
      else
        nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);

      Global.Log.LogCtrlWriteA6001(FIndex, 'FRecvData fail : 15 �۽ſ���' + IntToStr(FLastExeCommand) + ' : ' +
       IntToStr(nTeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    if copy(FRecvData, 2, 1) = JEU_CTL_FIN then //���� ����
    begin
      sLogMsg := 'FRecvData CTL Succese ' + IntToStr(FLastExeCommand) + ' : ' + FSendData + ' / ' + FRecvData;

      rTeeboxInfo.StoreCd := ''; //������ �ڵ�

      if (Global.ADConfig.StoreCode = 'A8001') then //�����
        rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)
      else
        rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);

      rTeeboxInfo.TeeboxNm := '';  //Ÿ����
      rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
      rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
      rTeeboxInfo.UseYn := '';        //��� ����
      rTeeboxInfo.RemainBall := StrToInt(copy(FSendData, 7, 4));
      rTeeboxInfo.RemainMinute := StrToInt(copy(FSendData, 4, 3));

      if rTeeboxInfo.RemainMinute > 0 then
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0';

      Global.Teebox.SetTeeboxInfo(rTeeboxInfo);

      if FLastCmdDataIdx <> FCurCmdDataIdx then
      begin
        inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
        if FCurCmdDataIdx > BUFFER_SIZE then
          FCurCmdDataIdx := 0;
      end;

      Global.Log.LogCtrlWriteA6001(FIndex, sLogMsg);
      FRecvData := '';
      FReceived := True;

      sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogViewWriteA6001(FIndex, sLogMsg);

      Exit;
    end;

    if Length(FRecvData) > JEU_RECV_LENGTH then
    begin
      Global.Log.LogCtrlWriteA6001(FIndex, 'Over : ' + FRecvData);
      FRecvData := '';
      Exit;
    end
    else if Length(FRecvData) < JEU_RECV_LENGTH then
    begin
      Exit;
    end;

  end
  else if Count = JEU_RECV_LENGTH then
  begin
    FRecvData := sRecvData;
  end
  else
  begin
    if (Global.ADConfig.StoreCode = 'A8001') then //�����
      nTeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)
    else
      nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);

    Global.Log.LogCtrlWriteA6001(FIndex, '��ûŸ����: ' + IntToStr(nTeeboxNo) + ' / �ѱ��ڼ�: ' + IntToStr(Count) + ' / ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 2) then
  begin
    //sLogMsg := 'FChannel : ' + FChannel + ' / ' + FSendData + ' / ' + FRecvData;
    //Global.LogRetryWriteA6001(FIndex, sLogMsg);

    // 10�� 30�� 200��, STX(1)+ID(2)+�ܿ��ð�(3)+�ܿ���(4)+����(1)+����(1)+����(1)+BCC(1)+ETX(1)
    // 1,	 2	 3,	4  5  6,	7  8  9 10, 11 12 13, 14, 15
    //02,	 1   0,	0  3	0,	0	 2	0	 0,	 0  0	 0,  6, 03
    //02, 31	30, 30 33 30, 30 32 30 30, 30 30 30, 36, 03

    //���� 0:OFF, 1:ON
    //���� 0:�ڵ�������, 1:����������, 9:����(������)
    //���� 0:��������, 1:Ƽ�������̻�, 2:Ÿ�ڼ����̻�, 3:���ۼ����̻�, 4:��ġ����?

    rTeeboxInfo.StoreCd := ''; //������ �ڵ�

    //rSeatInfo.SeatNo := Global.Seat.GetDevicToFloorSeatNo(FFloor, FChannel); //Ÿ�� ��ȣ
    if (Global.ADConfig.StoreCode = 'A8001') then //�����
      rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)
    else
      rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);

    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
    rTeeboxInfo.ErrorCd := 0;
    rTeeboxInfo.ErrorCd2 := '0';

    //01 036 0101 0 0 0 2
    //02 000 0000 0 9 0 1
    if copy(FRecvData, 13, 1) = '0' then //����
    begin
      if copy(FRecvData, 12, 1) = '9' then //����:����
        rTeeboxInfo.UseStatus := '0'
      else if copy(FRecvData, 12, 1) = '0' then //�����
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0';
    end
    else // 1,2,3 ���Error
    begin
      rTeeboxInfo.UseStatus := '9';

      if copy(FRecvData, 13, 1) = '1' then
        rTeeboxInfo.ErrorCd := ERROR_CODE_11
      else if copy(FRecvData, 13, 1) = '2' then
        rTeeboxInfo.ErrorCd := ERROR_CODE_12
      else if copy(FRecvData, 13, 1) = '3' then
        rTeeboxInfo.ErrorCd := ERROR_CODE_13;

      rTeeboxInfo.ErrorCd2 := copy(FRecvData, 13, 1);
    end;

    if isNumber(copy(FRecvData, 4, 7)) = False then
    begin
      sLogMsg := 'Int Error : ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
      Global.Log.LogCtrlWriteA6001(FIndex, sLogMsg);
      FRecvData := '';
      Exit;
    end;

    rTeeboxInfo.UseYn := '';        //��� ����
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 7, 4));
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 4, 3));

    Global.Teebox.SetTeeboxInfo(rTeeboxInfo);

    sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
    //Global.DebugLogViewWrite(sLogMsg);
    Global.DebugLogViewWriteA6001(FIndex, sLogMsg);

  end
  else
  begin
    FRecvData := '';
    Exit;
  end;

  if FLastExeCommand = COM_MON then
  begin
    Global.Teebox.SetTeeboxErrorCnt(rTeeboxInfo.TeeboxNo, 'N', 10);
    SetNextMonNo;
  end;

  FRecvData := '';
  FReceived := True;
end;

//procedure TControlComPortJehu435MonThread.SetCmdSendBuffer(ASendData: AnsiString);
procedure TComThreadJeu435.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sSeatTime, sSeatBall: AnsiString;
begin
  sSeatTime := StrZeroAdd(ASeatTime, 3);
  sSeatBall := StrZeroAdd(ASeatBall, 4);

  // 13�� 63���ܿ�999�� ����0�� ����UP, STX(1)+ID(2)+�ð�(3)+�ܿ���(4)+����(1)+BCC(1)+ETX
  //  1,	2	 3,	 4	5	 6,	 7	8	 9 10, 11, 12, 13
  //  ,	1	 3,	 0	6	 3,	 0	9	 9	9,	0,	0,	
  // 02, 31	33,	30 36	33,	30 39	39 39, 30, 30, 03

  if sSeatTime = '000' then
    sSendData := ADeviceId + sSeatTime + '0000' + '9'
  else
    //sSendData := ADeviceId + sSeatTime + sSeatBall + '0';
    sSendData := ADeviceId + sSeatTime + '9999' + '0';
  sBcc := GetBccJehu(sSendData);

  if Length(sBcc) > 1 then
    sBcc := Copy(sBcc, length(sBcc), 1);

  sSendData := JEU_STX + sSendData + sBcc + JEU_ETX;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadJeu435.SetNextMonNo: Boolean;
var
  nSeatNo: Integer;
  sChannel: String;
begin

  while True do
  begin
    inc(FLastMonSeatDeviceNo);

    if FLastMonSeatDeviceNo > FMonSeatDeviceNoEnd then
      FLastMonSeatDeviceNo := FMonSeatDeviceNoStart;

    sChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FLastMonSeatDeviceNo);

    if (Global.ADConfig.StoreCode = 'A8001') then //�����
      nSeatNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, sChannel)
    else
      nSeatNo := Global.Teebox.GetDevicToTeeboxNo(sChannel);

    if Global.Teebox.GetTeeboxInfoUseYn(nSeatNo) = 'Y' then
      Break;

  end;

end;

//2021-04-07 ����3ȸ �õ��� ����ó��
procedure TComThreadJeu435.SetSeatError(AChannel: String);
var
  rSeatInfo: TTeeboxInfo;
begin
  rSeatInfo.StoreCd := ''; //������ �ڵ�
  rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(AChannel); //Ÿ�� ��ȣ
  rSeatInfo.RecvDeviceId := AChannel;
  rSeatInfo.TeeboxNm := '';  //Ÿ����
  rSeatInfo.FloorZoneCode := ''; //�� ���� �ڵ�
  rSeatInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
  rSeatInfo.UseStatus := '9';
  rSeatInfo.UseYn := '';        //��� ����
  rSeatInfo.RemainBall := 0;
  rSeatInfo.RemainMinute := 0;
  rSeatInfo.ErrorCd := 8; //����̻�
  rSeatInfo.ErrorCd2 := '8'; //����̻�

  Global.Teebox.SetTeeboxInfo(rSeatInfo);
end;

procedure TComThreadJeu435.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nSeatNo: Integer;
  rSeatInfo: TTeeboxInfo; //�����ð� ����Ȯ�ο�
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

            //nSeatNo := Global.Seat.GetDevicToFloorSeatNo(FFloor, FChannel);
            if (Global.ADConfig.StoreCode = 'A8001') then //�����
              nSeatNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)
            else
              nSeatNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogRetryWriteA6001(FIndex, sLogMsg);

              FRecvData := '';
              {
              FComPort.Close;
              FComPort.Open;
              Global.Log.LogRetryWriteA6001(FIndex, 'ReOpen');
              Break;
              }

              FComPort.Close;
              FComPort.Open;
              Global.Log.LogRetryWriteA6001(FIndex, 'ReOpen');

              inc(FCtlReTry);
              //2020-12-03 ����3ȸ �õ��� ����ó��
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
              Global.Log.LogRetryWriteA6001(FIndex, sLogMsg);

              Global.Teebox.SetTeeboxErrorCnt(nSeatNo, 'Y', 10);
              SetNextMonNo;

              inc(FReTry);

              if FReTry > 10 then
              begin
                FReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogRetryWriteA6001(FIndex, 'ReOpen');
              end;

              Break;
            end;

          end;

        end
        else
        begin
          if FLastExeCommand = COM_CTL then
          begin
            //nSeatNo := Global.Seat.GetDevicToFloorSeatNo(FFloor, FChannel);
            if (Global.ADConfig.StoreCode = 'A8001') then //�����
              nSeatNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)
            else
              nSeatNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);
            sLogMsg := 'Received True : ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
            Global.Log.LogRetryWriteA6001(FIndex, sLogMsg);

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
      begin //������� �������� ������
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 2);

        //2021-04-07 ����3ȸ �õ��� ����ó��
        if FCtlChannel = FChannel then
          Continue;

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];

        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogCtrlWriteA6001(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        FWriteTm := now + (((1/24)/60)/60) * 2; //5

        //FLastMonSeatDeviceNo := Global.Seat.GetDevicToSeatNo(FChannel);
        //SetNextMonNo;

        Sleep(0);

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        // 1	2	 3	4	 5  / 10�� Ÿ�� ����Ÿ ��û, ENQ(1)+ID(2)+BCC(1)+ETX
        //05	1	 0  1 03
        //05 31	30 31	03
        FLastExeCommand := COM_MON;
        FChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FLastMonSeatDeviceNo);

        //Global.LogCtrlWrite('FLastMonSeatDeviceNo ' + IntToStr(FLastMonSeatDeviceNo) + ' / ' + FChannel);

        sBcc := GetBccJehu(FChannel);
        if Length(sBcc) > 1 then
          sBcc := Copy(sBcc, length(sBcc), 1);
        FSendData := JEU_ENQ + FChannel + sBcc + JEU_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;  //3
      end;

      FReceived := False;

      if (Global.ADConfig.StoreCode = 'A1001') or (Global.ADConfig.StoreCode = 'A9001') then //��Ÿ, ��������
      begin

        if bControlMode = True then
        begin
          rSeatInfo := Global.Teebox.GetTeeboxInfoA(FChannel);
          if rSeatInfo.UseReset = 'Y' then
          begin
            Sleep(2000); //�����ð� ����� 2���̻��� �����̰� �־�� �ʱ�ȭ�� �����(1�� ����)
            Global.Log.LogCtrlWriteA6001(FIndex, 'UseReset : ' + IntToStr(rSeatInfo.TeeboxNo) + ' / ' + rSeatInfo.TeeboxNm + ' / ' + FChannel);
            Global.Teebox.SetTeeboxInfoUseReset(rSeatInfo.TeeboxNo);
          end;
        end;
      end;

      Sleep(100);

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadJeu435 Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);

        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
        begin
          //wMonDelayTime := 10000; //10000 = 10��
          //g_bSMServerSocketError := True;
        end;
      end;
    end;
  end;

end;

end.
