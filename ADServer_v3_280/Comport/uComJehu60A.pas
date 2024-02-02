unit uComJehu60A;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadJehu60A = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FCtlReTry: Integer;

    FReceived: Boolean;
    FChannel: String;
    FFloor: String;

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ

    FIndex: Integer;
    FTeeboxNoStart: Integer;
    FTeeboxNoEnd: Integer;
    FTeeboxNoLast: Integer;

    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    FWriteTm: TDateTime;

    FTeeboxInfo: TTeeboxInfo;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);

    //procedure SetSeatError(AChannel: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJeu60A }

constructor TComThreadJehu60A.Create;
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

  //���� 20byte
  //        100��,     30��,   �ܿ�200��,     ����0��, ����UP, STX(1)+ID(3)+�ð�(3)+�ܿ���(4)+���ۺ�(4)+����UP/DOWN(1)+����(1)+BCC(2)+ETX
  // 1,	 2	 3	4,  5	 6  7,	8	 9 10 11, 12 13 14 15, 16 17, 18 19, 20
  //02,  1   0	0,  0  3  0,	0	 2	0	 0,  0  0	 0  0,	0	 0,  8  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30 30, 30 30, 38 36, 03
  //02 37 39 30 31 30 30 39 39 39 30 34 03

  FReTry := 0;
  FCtlReTry := 0;

  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadJehu60A Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadJehu60A.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadJehu60A.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
begin
  FTeeboxNoStart := ATeeboxNoStart;
  FTeeboxNoEnd := ATeeboxNoEnd;
  FTeeboxNoLast := FTeeboxNoStart;
  FIndex := AIndex;
  FFloor := AFloorCd;

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(APort);
  FComPort.BaudRate := GetBaudrate(ABaudRate);
  FComPort.Open;

  Global.Log.LogWrite('TComThreadJehu60A ComPortSetting : ' + IntToStr(AIndex) + '/' + IntToStr(ATeeboxNoStart) + '/' + IntToStr(ATeeboxNoEnd));
end;

procedure TComThreadJehu60A.ComPortRxChar(Sender: TObject; Count: Integer);
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
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : 04 ���ſ���' + IntToStr(FLastExeCommand) + ' : ' +
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
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : 15 �۽ſ���' + IntToStr(FLastExeCommand) + ' : ' +
                          IntToStr(Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)) + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    // Ÿ������ó���� ���� Ȯ��, �׿� ���� ���� ��Ȯ�ε�
    if copy(FRecvData, 1, 1) = JEU_CTL_FIN then //���� ����
    begin
      sLogMsg := 'FRecvData CTL Succese ' + IntToStr(FLastExeCommand) + ' : ' + FSendData + ' / ' + FRecvData;

      rSeatInfo.StoreCd := ''; //������ �ڵ�
      rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel); //Ÿ�� ��ȣ
      rSeatInfo.TeeboxNm := '';  //Ÿ����
      rSeatInfo.FloorZoneCode := ''; //�� ���� �ڵ�
      rSeatInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
      rSeatInfo.UseYn := '';        //��� ����
      rSeatInfo.RemainBall := StrToInt(copy(FSendData, 8, 4));
      rSeatInfo.RemainMinute := StrToInt(copy(FSendData, 5, 3));

      if rSeatInfo.RemainMinute > 0 then
        rSeatInfo.UseStatus := '1'
      else
        rSeatInfo.UseStatus := '0';

      Global.Teebox.SetTeeboxInfoAD(rSeatInfo);

      if FLastCmdDataIdx <> FCurCmdDataIdx then
      begin
        inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
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
    Global.Log.LogReadMulti(FIndex, '��ûŸ����: ' + IntToStr(Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel)) + ' / �ѱ��ڼ�: ' + IntToStr(Count) + ' / ' + FRecvData);
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

  //2020-06-17 ���� 19�ڸ� .0613@011799838A5C.$  , .0623@00529936D76C.$
  //(Length(FRecvData) <> 19) �߰�
  if (Length(FRecvData) <> 15) and (Length(FRecvData) <> 19) then
  begin
    Global.Log.LogCtrlWrite('FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;
  }

  sLogMsg := 'No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData;
  Global.Log.LogReadMulti(FIndex, sLogMsg);

  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //         100��,    30��,       200��, STX(1)+ID(3)+�ܿ��ð�(3)+�ܿ���(4)+����(1)+����(1)+����(1)+BCC(2)+ETX(1)
    // 1,	 2	 3	4,  5	 6	7,	8	 9 10 11, 12 13 14, 15 16, 17
    //02,	 1   0	0,  0  3	0,	0	 2	0	 0,	 0  0	 0,  8  6, 03
    //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30, 38 36, 03

    //���� 0:OFF, 1:ON
    //���� 0:�ڵ�������, 1:����������, 9:����(������)
    //���� 0:��������, 1:Ƽ�������̻�, 2:Ÿ�ڼ����̻�, 3:���ۼ����̻�, 4:��ġ����?

    rSeatInfo.StoreCd := ''; //������ �ڵ�
    rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel); //Ÿ�� ��ȣ
    rSeatInfo.TeeboxNm := '';  //Ÿ����
    rSeatInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rSeatInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
    //001 036 0101 000 02
    //002 000 0000 090 01

    if copy(FRecvData, 14, 1) = '0' then //����
    begin
      if copy(FRecvData, 13, 1) = '9' then //����:����
        rSeatInfo.UseStatus := '0'
      else if copy(FRecvData, 13, 1) = '0' then //�����
        rSeatInfo.UseStatus := '1'
      else
        rSeatInfo.UseStatus := '0';
    end
    else // 1,2,3 ���Error
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

    rSeatInfo.UseYn := '';        //��� ����
    rSeatInfo.RemainBall := StrToInt(copy(FRecvData, 8, 4));
    rSeatInfo.RemainMinute := StrToInt(copy(FRecvData, 5, 3));

    Global.Teebox.SetTeeboxInfoAD(rSeatInfo);

    sLogMsg := IntToStr(rSeatInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
    sLogMsg := 'Nm:' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);
  end
  else
  begin
    FRecvData := '';
    Exit;
  end;

  if FLastExeCommand = COM_MON then
  begin
    Global.Teebox.SetTeeboxErrorCntAD(FIndex, rSeatInfo.TeeboxNo, 'N', 10);
    SetNextMonNo;
  end;

  //A6001: ĳ������ ���� �� ���°� �������� ����.  016077999900000037 / 016077000000011 -> JEU_CTL_FIN ���� ������ ����.
  //���� �ٸ����忡�� 60A ���� �������䰪 ó���κ� Ȯ�� �ʿ�
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

procedure TComThreadJehu60A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime, sTeeboxBall: AnsiString;
begin
  sTeeboxTime := StrZeroAdd(ATeeboxTime, 3);

  //������ũ 6.0A �ΰ�� ���纼���� ���Ƚ�� �̹Ƿ� ����� ���ٽ� ����
  //sSeatBall := StrZeroAdd(ASeatBall, 4);
  sTeeboxBall := '9999';

  //        100��,     30��,   �ܿ�200��,     ����0��, ����UP, STX(1)+ID(3)+�ð�(3)+�ܿ���(4)+���ۺ�(4)+����UP/DOWN(1)+����(1)+BCC(2)+ETX
  // 1,	 2	 3	4,  5	 6  7,	8	 9 10 11, 12 13 14 15, 16 17, 18 19, 20
  //02,  1   0	0,  0  3  0,	0	 2	0	 0,  0  0	 0  0,	0	 0,  8  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30 30, 30 30, 38 36, 03
  //02 37 39 30 31 30 30 39 39 39 30 34 03

  if sTeeboxTime = '000' then
    sSendData := ADeviceId + sTeeboxTime + '0000' + '0000' + '0' + '9'
  else
    sSendData := ADeviceId + sTeeboxTime + sTeeboxBall + '0000' + '0' + '0';

  sBcc := GetBccJehu2Byte(sSendData);

  sSendData := JEU_STX + sSendData + sBcc + JEU_ETX;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadJehu60A.SetNextMonNo: Boolean;
var
  rTeeboxInfo: TTeeboxInfo;
begin

  while True do
  begin
    inc(FTeeboxNoLast);
    if FTeeboxNoLast > FTeeboxNoEnd then
      FTeeboxNoLast := FTeeboxNoStart;

    rTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
    if rTeeboxInfo.UseYn = 'Y' then
      Break;
  end;

end;

procedure TComThreadJehu60A.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  //nSeatNo: Integer;
  //rSeatInfo: TTeeboxInfo; //�����ð� ����Ȯ�ο�
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

            //nSeatNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloor, FChannel);

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail - No:' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

              FRecvData := '';

              inc(FCtlReTry);
              //2020-12-03 ����3ȸ �õ��� ����ó��
              if FCtlReTry > 2 then
              begin
                FCtlReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogWriteMulti(FIndex, 'ReOpen');
              end;

              if FLastCmdDataIdx <> FCurCmdDataIdx then
              begin
                inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
                if FCurCmdDataIdx > BUFFER_SIZE then
                  FCurCmdDataIdx := 0;
              end;

              Break;
            end
            else
            begin
              sLogMsg := 'Retry COM_MON Received Fail - No:' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
              if Trim(FRecvData) <> '' then
                sLogMsg := sLogMsg + ' / �������';
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

              FRecvData := '';

              Global.Teebox.SetTeeboxErrorCntAD(FIndex, FTeeboxInfo.TeeboxNo, 'Y', 10);
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
            FCtlReTry := 0;
          end;

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
      begin //������� �������� ������
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToFloorTeeboxInfo(FFloor, FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);

        FWriteTm := now + (((1/24)/60)/60) * 1; //5

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
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
        FChannel := FTeeboxInfo.DeviceId;

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
        sLogMsg := 'TComThreadJehu60A Error : ' + IntToStr(FIndex) + ' / ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.
