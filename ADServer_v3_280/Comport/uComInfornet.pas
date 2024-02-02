unit uComInfornet;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadInfornet = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FCtlReTry: Integer;
    FReceived: Boolean;
    FChannel: String;

    FIndex: Integer; //�α׿�
    FFloorCd: String; //��

    FTeeboxNoStart: Integer; //���� Ÿ����ȣ
    FTeeboxNoEnd: Integer; //���� Ÿ����ȣ
    FTeeboxNoLast: Integer; //������ ��û Ÿ����ȣ

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ

    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    FWriteTm: TDateTime;

    FTeeboxInfo: TTeeboxInfo;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);

    procedure SetTeeboxError(AChannel: String);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJMS }

constructor TComThreadInfornet.Create;
begin

  FReTry := 0;
  FReceived := True;
  FTeeboxNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadInfornet Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadInfornet.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadInfornet.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
begin
  FTeeboxNoStart := ATeeboxNoStart;
  FTeeboxNoEnd := ATeeboxNoEnd;
  FTeeboxNoLast := ATeeboxNoStart;
  FIndex := AIndex;
  FFloorCd := AFloorCd;

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(APort);
  FComPort.BaudRate := GetBaudrate(ABaudRate);
  FComPort.Open;

  Global.Log.LogWrite('TComThreadInfornet ComPortSetting : ' + FFloorCd);
end;

// ����3ȸ �õ��� ����ó��
procedure TComThreadInfornet.SetTeeboxError(AChannel: String);
var
  rTeeboxInfo: TTeeboxInfo;
begin
  rTeeboxInfo.StoreCd := ''; //������ �ڵ�
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, AChannel); //Ÿ�� ��ȣ
  //rSeatInfo.RecvDeviceId := AChannel;
  rTeeboxInfo.TeeboxNm := '';  //Ÿ����
  rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
  rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
  rTeeboxInfo.UseStatus := '9';
  rTeeboxInfo.UseYn := '';        //��� ����
  rTeeboxInfo.RemainBall := 0;
  //rSeatInfo.RemainMinute := 0;
  rTeeboxInfo.ErrorCd := 8;
  rTeeboxInfo.ErrorCd2 := '8';

  Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);
end;

procedure TComThreadInfornet.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;

  nIndex: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx: Integer;
begin

  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Pos(INFOR_REC, FRecvData) = 0 then
    Exit;

  if Pos(INFOR_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(INFOR_REC, FRecvData);
  nEtx := Pos(INFOR_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 11) and (Length(FRecvData) <> 26) then
  begin
    Global.Log.LogReadMulti(FIndex, 'FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if Copy(FChannel, 4, 3) = Copy(FRecvData, 2, 3) then
  begin

    // �������� : STX(1) + ID(3) + �ð�(5) + ��(5) + ��뺼��?(5) + ETC(4) + ����?(1) + BCC(1) + ETX(1)  - 26byte
    // 1	2	 3	4	 5	6	 7	8	 9 10	11 12	13 14	15 16	17 18	19 20	21 22	23 24	25 26
    // 	0	 0	6  0	0	 0	3  5	0	 0	9	 9	9  0	0	 2	3	 6	0	 0	0	 0	1	 ?	
    //06 30	30 36	30 30	30 33	35 30	30 39	39 39	30 30	32 33	36 30	30 30	30 31	3F 03

    // �������� : STX(1) + ��ġ(3) + ETC(5) +BCC(1) + ETX(1) - 11byte
    // 1  2	 3	4	 5	6	 7	8	 9 10	11
    // 	0	 0	3	 0	0	 0	0	 0	#	 
    //06 30	30 33	30 30	30 30	30 23	03

    rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, FChannel); //Ÿ�� ��ȣ

    if FLastExeCommand = COM_MON then
    begin
      rTeeboxInfo.StoreCd := ''; //������ �ڵ�
      //rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, FChannel); //Ÿ�� ��ȣ
      rTeeboxInfo.RecvDeviceId := FChannel;
      rTeeboxInfo.TeeboxNm := '';  //Ÿ����
      rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
      rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

      rTeeboxInfo.UseYn := '';        //��� ����
      rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 5, 5));
      rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 15, 5));
      {
      if copy(FRecvData, 12, 1) = '0' then //����
      begin
        if rTeeboxInfo.RemainMinute > 0 then //�����
          rTeeboxInfo.UseStatus := '1'
        else
          rTeeboxInfo.UseStatus := '0'; //��Ÿ��(����)
      end
      else //Error
      begin
        rTeeboxInfo.UseStatus := '9';
        rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(FRecvData, 12, 1));
      end;
      }

      if rTeeboxInfo.RemainMinute > 0 then //�����
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0'; //��Ÿ��(����)

      Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);
    end

    else //if copy(FRecvData, 2, 1) = JEU_CTL_FIN then //���� ����
    begin

      rTeeboxInfo.RecvDeviceId := FChannel;
      rTeeboxInfo.TeeboxNm := '';  //Ÿ����
      rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
      rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

      rTeeboxInfo.UseYn := '';        //��� ����

      //rTeeboxInfo.RemainBall := StrToInt(copy(FSendData, 10, 5));
      rTeeboxInfo.RemainMinute := StrToInt(copy(FSendData, 10, 5));

      if rTeeboxInfo.RemainMinute > 0 then
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0';

      Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

    end;

    sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);
  end
  else
  begin
    FRecvData := '';
    Exit;
  end;

  if FLastExeCommand = COM_MON then
  begin
    Global.Teebox.SetTeeboxErrorCntAD(Findex, rTeeboxInfo.TeeboxNo, 'N', 10);
    SetNextMonNo;
  end
  else
  begin
    //Global.Log.LogCtrlWriteMulti(FIndex, sLogMsg);

    if FLastCmdDataIdx <> FCurCmdDataIdx then
    begin
      inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
      if FCurCmdDataIdx > BUFFER_SIZE then
        FCurCmdDataIdx := 0;
    end;
  end;

  //�����ڵ带 �˼� ����. ������ ��� ����
  Global.Log.LogReadMulti(FIndex, sLogMsg);

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadInfornet.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sSendDataBcc, sBcc: AnsiString;
  sTeeboxTime: AnsiString;
begin
  sTeeboxTime := StrZeroAdd(ATeeboxTime, 5);

  // �������� : STX(1) + ID(3) + ��ġ(3) + COMMAND(2) + �ð�(5) + ��(5) + ETC(8) + BCC(1) + ETX(1) - 29byte
  //  1	 2	3	 4	5	 6	7	 8	9	10 11	12 13	14 15	16 17	18 19	20 21	22 23	24 25	26 27	28 29
  //  	 2	0	 5	0	 0	3	 S	A	 0	0	 0	3	 5	0	 0	9	 9	9	 0	0	 0  0	 0	0	 0	0	 .	
  // 02	32 30	35 30	30 33	53 41	30 30	30 33	35 30	30 39	39 39	30 30	30 30	30 30	30 30	2E 03

  sSendData := ADeviceId + 'SA' + sTeeboxTime + '00999' + '00000000';

  sSendDataBcc := Copy(sSendData, 4, Length(sSendData) - 3);
  sBcc := GetBccInfornet(sSendDataBcc);
  sSendData := INFOR_STX + sSendData + sBcc + INFOR_ETX;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;

end;

function TComThreadInfornet.SetNextMonNo: Boolean;
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

procedure TComThreadInfornet.Execute;
var
  bControlMode: Boolean;
  sSendDataBcc, sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nTeeboxNo, nIndex: Integer;
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

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

              FRecvData := '';

              inc(FCtlReTry);
              if FCtlReTry > 1 then //��Ż��°� ���� �ʾ� 1ȸ ��õ�
              begin
                FCtlReTry := 0;

                if FLastCmdDataIdx <> FCurCmdDataIdx then
                begin
                  inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
                  if FCurCmdDataIdx > BUFFER_SIZE then
                    FCurCmdDataIdx := 0;
                end;

                FComPort.Close;
                FComPort.Open;
                Global.Log.LogWriteMulti(FIndex, 'ReOpen');
              end;

              Break;

            end
            else
            begin
              sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

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
      begin //������� �������� ������
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 6);

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToFloorTeeboxInfo(FFloorCd, FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);

        FWriteTm := now + (((1/24)/60)/60) * 1;

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        FLastExeCommand := COM_MON;
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
        FChannel := FTeeboxInfo.DeviceId;

        // �������� : STX(1) + ID(3) + ��ġ(3) + COMMAND(2) + BCC(1) + ETX(1)  - 11byte
        //  1	 2	3	 4	5	 6	7	 8	9	10 11
        //  	 2	0	 1	0	 0	6	 R	A	 %	
        // 02	32 30	31 30	30 36	52 41	25 03

        FSendData := FChannel + 'RA';
        sSendDataBcc := Copy(FSendData, 4, Length(FSendData) - 3);
        sBcc := GetBccInfornet(sSendDataBcc);
        FSendData := INFOR_STX + FSendData + sBcc + INFOR_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;
      //Sleep(100);  //50 �����ΰ�� retry �߻�
      Sleep(200);  //���� Ȯ������

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadSM Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);

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
