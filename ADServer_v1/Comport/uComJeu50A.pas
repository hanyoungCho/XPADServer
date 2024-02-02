unit uComJeu50A;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadJeu50A = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;

    //2020-12-03 ����3ȸ �õ��� ����ó��
    FCtlReTry: Integer;
    FCtlChannel: String;

    FReceived: Boolean;
    FChannel: String;

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    //FLastCtlTeeboxDeviceNo: String; //����Ÿ���� ����͸���

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
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);

    procedure SetTeeboxError(AChannel: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJeu50A }

constructor TComThreadJeu50A.Create;
begin

  //���� 7byte
  // 1	2	 3	4	 5	6	 7  / 100�� Ÿ�� ����Ÿ ��û, ENQ(1)+ID(3)+BCC(2)+ETX
  //05	1	 0  0	 9  1 03
  //05 31	30 30	39 31	03

  //���� 17byte
  //         100��,    30��,       200��, STX(1)+ID(3)+�ܿ��ð�(3)+�ܿ���(4)+����(1)+����(1)+����(1)+BCC(2)+ETX(1)
  // 1,	 2	 3	4,  5	 6	7,	8	 9 10 11, 12 13 14, 15 16, 17
  //02,	 1   0	0,  0  3	0,	0	 2	0	 0,	 0  0	 0,  8  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30, 38 36, 03

  //���� 15byte
  //        100��,     30��,   �ܿ�200��, STX(1)+ID(3)+�ð�(3)+�ܿ���(4)+����(1)+BCC(2)+ETX
  // 1,	 2	 3	4,  5	 6  7,	8	 9 10 11, 12 13 14 15
  //02,  1   0	0,  0  3  0,	0	 2	0	 0,  0, 3  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30,  0,33 36, 03

  FReTry := 0;
  FCtlReTry := 0;

  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastCtlTeeboxDeviceNo := '';
  FMonDeviceNoLast := 0;
  FRecvData := '';

  Global.Log.LogCtrlWriteA6001(FIndex, 'TComThreadJeu50A Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadJeu50A.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadJeu50A.ComPortSetting(Index, AStart, AEnd: Integer);
begin
  FMonDeviceNoStart := AStart - 1;
  FMonDeviceNoEnd := AEnd - 1;
  FMonDeviceNoLast := AStart - 1;
  FIndex := Index;

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

  Global.Log.LogCtrlWriteA6001(FIndex, 'TComThreadJeu50A ComPortSetting : ' + IntToStr(Index));
end;

procedure TComThreadJeu50A.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;

  Index: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  if Count < JEU_RECV_LENGTH_17 then
  begin
    FRecvData := FRecvData + sRecvData;

    if copy(FRecvData, 1, 1) = JEU_NAK then
    begin
      Global.Log.LogCtrlWriteA6001(FIndex, 'FRecvData fail : 15 ���ſ���' + IntToStr(FLastExeCommand) + ' : ' +
                          IntToStr(Global.Teebox.GetDevicToTeeboxNo(FChannel)) + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    // Ÿ������ó���� ���� Ȯ��- 2021-04-16 �߰�
    if copy(FRecvData, 1, 1) = JEU_CTL_FIN then //���� ����
    begin
      sLogMsg := 'FRecvData CTL Succese ' + IntToStr(FLastExeCommand) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.Log.LogCtrlWriteA6001(FIndex, sLogMsg);

      rTeeboxInfo.StoreCd := ''; //������ �ڵ�
      rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel); //Ÿ�� ��ȣ
      rTeeboxInfo.TeeboxNm := '';  //Ÿ����
      rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
      rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
      rTeeboxInfo.UseYn := '';        //��� ����
      rTeeboxInfo.RemainBall := StrToInt(copy(FSendData, 8, 4));
      rTeeboxInfo.RemainMinute := StrToInt(copy(FSendData, 5, 3));

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

      //Global.Log.LogCtrlWriteA6001(FIndex, sLogMsg);
      FRecvData := '';
      FReceived := True;

      sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
      //Global.DebugLogViewWrite(sLogMsg);
      Global.DebugLogViewWriteA6001(FIndex, sLogMsg);

      Exit;
    end;

    if copy(FRecvData, 1, 1) <> JEU_STX then
    begin
      Global.Log.LogCtrlWriteA6001(FIndex, 'FRecvData fail : STX 02 Error ' + IntToStr(FLastExeCommand) + ' : ' +
                          IntToStr(Global.Teebox.GetDevicToTeeboxNo(FChannel)) + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    if Length(FRecvData) > JEU_RECV_LENGTH_17 then
    begin
      Global.Log.LogCtrlWriteA6001(FIndex, 'Over : ' + FRecvData);
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
    Global.Log.LogCtrlWriteA6001(FIndex, '��ûŸ����: ' + IntToStr(Global.Teebox.GetDevicToTeeboxNo(FChannel)) + ' / �ѱ��ڼ�: ' + IntToStr(Count) + ' / ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //         100��,    30��,       200��, STX(1)+ID(3)+�ܿ��ð�(3)+�ܿ���(4)+����(1)+����(1)+����(1)+BCC(2)+ETX(1)
    // 1,	 2	 3	4,  5	 6	7,	8	 9 10 11, 12 13 14, 15 16, 17
    //02,	 1   0	0,  0  3	0,	0	 2	0	 0,	 0  0	 0,  8  6, 03
    //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30, 38 36, 03

    //���� 0:OFF, 1:ON
    //���� 0:�ڵ�������, 1:����������, 9:����(������)
    //���� 0:��������, 1:Ƽ�������̻�, 2:Ÿ�ڼ����̻�, 3:���ۼ����̻�, 4:��ġ����?

    rTeeboxInfo.StoreCd := ''; //������ �ڵ�
    rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel); //Ÿ�� ��ȣ
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
    //001 036 0101 000 02
    //002 000 0000 090 01

    if copy(FRecvData, 14, 1) = '0' then //����
    begin
      if copy(FRecvData, 13, 1) = '9' then //����:����
        rTeeboxInfo.UseStatus := '0'
      else if copy(FRecvData, 13, 1) = '0' then //�����
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0';
    end
    else // 1,2,3 ���Error
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 0;
      rTeeboxInfo.ErrorCd2 := '0';

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / ' + copy(FRecvData, 14, 1);
      //Global.LogWrite(sLogMsg);
      Global.Log.LogCtrlWriteA6001(FIndex, sLogMsg);
    end;

    if isNumber(copy(FRecvData, 5, 7)) = False then
    begin
      sLogMsg := 'Int Error : ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
      Global.Log.LogCtrlWriteA6001(FIndex, sLogMsg);
      FRecvData := '';
      Exit;
    end;

    rTeeboxInfo.UseYn := '';        //��� ����
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 8, 4));
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 5, 3));

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

  if FLastExeCommand = COM_CTL then
  begin
    if FLastCmdDataIdx <> FCurCmdDataIdx then
    begin
      inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
      if FCurCmdDataIdx > BUFFER_SIZE then
        FCurCmdDataIdx := 0;
    end;
  end;

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadJeu50A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime, sTeeboxBall: AnsiString;
begin
  sTeeboxTime := StrZeroAdd(ATeeboxTime, 3);

  //������ũ 6.0A �ΰ�� ���纼���� ���Ƚ�� �̹Ƿ� ����� ���ٽ� ����
  //sSeatBall := StrZeroAdd(ASeatBall, 4);
  sTeeboxBall := '9999';

  //        100��,     30��,   �ܿ�200��, STX(1)+ID(3)+�ð�(3)+�ܿ���(4)+����(1)+BCC(2)+ETX
  // 1,	 2	 3	4,  5	 6  7,	8	 9 10 11, 12, 13 14, 15
  //02,  1   0	0,  0  3  0,	0	 2	0	 0,  0,  3  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30, 33 36, 03

  if sTeeboxTime = '000' then
    sSendData := ADeviceId + sTeeboxTime + '0000' + '9'
  else
    sSendData := ADeviceId + sTeeboxTime + sTeeboxBall + '0';

  sBcc := GetBccJehu2Byte(sSendData);

  sSendData := JEU_STX + sSendData + sBcc + JEU_ETX;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadJeu50A.SetNextMonNo: Boolean;
var
  nSeatNo: Integer;
  sChannel: String;
begin

  while True do
  begin
    inc(FMonDeviceNoLast);
    {
    if FLastMonSeatDeviceNo > Global.Seat.SeatDevicNoCnt - 1 then
      FLastMonSeatDeviceNo := 0;
    }

    if FMonDeviceNoLast > FMonDeviceNoEnd then
      FMonDeviceNoLast := FMonDeviceNoStart;

    sChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);

    nSeatNo := Global.Teebox.GetDevicToTeeboxNo(sChannel);
    if Global.Teebox.GetTeeboxInfoUseYn(nSeatNo) = 'Y' then
      Break;
  end;

end;

//2020-12-03 ����3ȸ �õ��� ����ó��
procedure TComThreadJeu50A.SetTeeboxError(AChannel: String);
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

procedure TComThreadJeu50A.Execute;
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

            nSeatNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(FIndex) + ' / ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogRetryWriteA6001(FIndex, sLogMsg);

              FRecvData := '';

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

                SetTeeboxError(FChannel);
                FCtlChannel := FChannel;
              end;

              Break;
            end
            else
            begin
              sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(FIndex) + ' / ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
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
            nSeatNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);
            sLogMsg := 'Received True : ' + IntToStr(FIndex) + ' / ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);

        //2020-12-03 ����3ȸ �õ��� ����ó��
        if FCtlChannel = FChannel then
          Continue;

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];

        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogCtrlWriteA6001(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FIndex) + ' / ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        { 2021-04-16 ����ó���� ���� '' , JEU_CTL_FIN
        // Ÿ������ó���� ���� ����
        if Copy(FSendData, 12, 1) = '9' then
        begin

          //FWriteTm := now + (((1/24)/60)/60) * 1;
          FWriteTm := now + (((1/24)/60)/60) * 0.1;

          while True do
          begin
            if now > FWriteTm then
            begin
              Break;
            end;
          end;

          sBcc := GetBccJehu2Byte(FChannel);
          FSendData := JEU_ENQ + FChannel + sBcc + JEU_ETX;
          FComPort.Write(FSendData[1], Length(FSendData));
          Global.Log.LogCtrlWriteA6001(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);
        end;
        }
        FWriteTm := now + (((1/24)/60)/60) * 2; //5

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        // 1	2	 3	4	 5	6	 7  / 100�� Ÿ�� ����Ÿ ��û, ENQ(1)+ID(3)+BCC(2)+ETX
        //05	1	 0  0	 9  1 03
        //05 31	30 30	39 31	03
        FLastExeCommand := COM_MON;
        FChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);

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
        sLogMsg := 'TComThreadJeu50A Error : ' + IntToStr(FIndex) + ' / ' + e.Message + ' / ' + FSendData;
        Global.Log.LogCtrlWriteA6001(FIndex, sLogMsg);

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
