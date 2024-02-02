unit uComWin;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadWin = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FCtlReTry: Integer;
    FReceived: Boolean;
    FChannel: String;

    FIndex: Integer;
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

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJMS }

constructor TComThreadWin.Create;
begin
  //ProtocolType=WIN
  FReTry := 0;
  FReceived := True;
  FTeeboxNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadWin Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadWin.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadWin.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
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

  Global.Log.LogWrite('TComThreadWin ComPortSetting : ' + FFloorCd);
end;

procedure TComThreadWin.ComPortRxChar(Sender: TObject; Count: Integer);
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

  if Length(FRecvData) < 16 then
    Exit;

  if Pos(COM_STX, FRecvData) = 0 then
    Exit;

  if Pos(COM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(COM_STX, FRecvData);
  nEtx := Pos(COM_ETX, FRecvData);

  //Global.Log.LogReadMulti(FIndex, 'FRecvData : ' + FRecvData);
  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 15) then
  begin
    Global.Log.LogReadMulti(FIndex, 'FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 1) then
  begin

    // �������� : STX(1) + ID(1) + COMMAND(1) + �ð�(3) + ��?(3) + CLASS(1) + ETC(4) + ETX(1) + üũ��(1)
    // 1  2	 3	4	 5	6	 7	8	 9 10	11 12	13 14	15 16
    //   1	 A	0	 0	0	 0	0	 0	T	 0	0  0	1	 	!
    //02 31	41 30	30 30	30 30	30 49	30 30	30 31	03 21

    //QA067000T0001Y

    rTeeboxInfo.StoreCd := ''; //������ �ڵ�
    //rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, FChannel); //Ÿ�� ��ȣ
    rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo;
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

    rTeeboxInfo.UseYn := '';        //��� ����
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 4, 3));
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 7, 3));

    if (copy(FRecvData, 12, 1) = '1') then //Error
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(FRecvData, 13, 1));
      rTeeboxInfo.ErrorCd2 := copy(FRecvData, 13, 1);
    end
    else //if (copy(FRecvData, 12, 1) = '0') or (copy(FRecvData, 12, 1) = '2') then //0:����, 2:Call SW (����)
    begin
      // 3 �� �ö���� ��찡 ����. �ü� ���� �ڵ尪 ����ó��
      if rTeeboxInfo.RemainMinute > 0 then //�����
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0'; //��Ÿ��(����)
    end;

    Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

    //sLogMsg := 'No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData;
    sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);
  end
  else
  begin
    FRecvData := '';
    Exit;
  end;

  if FLastExeCommand = COM_MON then
  begin
    Global.Teebox.SetTeeboxErrorCntAD(FIndex, rTeeboxInfo.TeeboxNo, 'N', 10);
    SetNextMonNo;
  end
  else
  begin
    //Global.Log.LogReadMulti(FIndex, sLogMsg);

    if FLastCmdDataIdx <> FCurCmdDataIdx then
    begin
      inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
      if FCurCmdDataIdx > BUFFER_SIZE then
        FCurCmdDataIdx := 0;
    end;
  end;

  Global.Log.LogReadMulti(FIndex, sLogMsg);

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadWin.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime: AnsiString;
begin
  sTeeboxTime := StrZeroAdd(ATeeboxTime, 3);

  // �������� : STX(1) + ID(1) + COMMAND(1) + �ð�(3) + ��?(3) + CLASS(1) + ETC(4) + ETX(1) + CRC(1) - 16byte
  // 1	2	 3  4	 5	6	 7	8	 9 10	11 12	13 14	15 16
  // .  8  R  0  0  0  0  0  0  T  0  0  0  0  .  C
  // .  9  O  0  7  5  0  0  0  T  0  0  0  0  .  N

  sSendData := ADeviceId + 'O' + sTeeboxTime + '000' + 'T' + '0000';
  sBcc := GetBccSM(sSendData);
  sSendData := COM_STX + sSendData + COM_ETX + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;

end;

function TComThreadWin.SetNextMonNo: Boolean;
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

procedure TComThreadWin.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg: String;
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
              sLogMsg := 'Retry COM_CTL Received Fail! No : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

              FRecvData := '';

              inc(FCtlReTry);
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
              sLogMsg := 'Retry COM_MON Received Fail! No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData;
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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 1);

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

        FSendData := FChannel + 'R' + '000' + '000' + 'T' + '0000';
        sBcc := GetBccSM(FSendData);
        FSendData := COM_STX + FSendData + COM_ETX + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;

      if (bControlMode = False) and (FTeeboxNoLast = FTeeboxNoEnd) then //���¿�û�̰� ������Ÿ���̸� 2��
        Sleep(2000)
      else
        Sleep(300);  //50 �����ΰ�� retry �߻�

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadWin Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.


