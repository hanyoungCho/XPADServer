unit uComSM;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadSM = class(TThread)
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

    //procedure SetTeeboxError(AChannel: String);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJMS }

constructor TComThreadSM.Create;
begin

  FReTry := 0;
  FReceived := True;
  FTeeboxNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadSM Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadSM.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadSM.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
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

  Global.Log.LogWrite('TComThreadSM ComPortSetting : ' + FFloorCd + ' / S: ' + IntToStr(ATeeboxNoStart) + ' / E: ' +  IntToStr(ATeeboxNoEnd));
end;

{
// ����3ȸ �õ��� ����ó��
procedure TComThreadSM.SetTeeboxError(AChannel: String);
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

  Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);
end;
}

procedure TComThreadSM.ComPortRxChar(Sender: TObject; Count: Integer);
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

  if (Global.ADConfig.StoreCode = 'C0001') and (FIndex = 1) then //����������
  begin
    //W: 1R000000T0000<
    //R: 1A000000T0000+ R: �LP��0000T0000+  -> 1�� 15������ ������ ����
    if Pos(MODEN_ETX, FRecvData) = 0 then
      Exit;
    {
    nStx := Pos(MODEN_STX, FRecvData);
    if Length(FRecvData) < nStx+15 then
    begin
    sLogMsg := 'Over - ' + inttostr(nStx+15) + ' / ' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.Log.LogReadMulti(FIndex, sLogMsg);
    Exit;
    end;  }
  end
  else
  begin
    if Pos(MODEN_STX, FRecvData) = 0 then
      Exit;

    if Pos(MODEN_ETX, FRecvData) = 0 then
      Exit;

    nStx := Pos(MODEN_STX, FRecvData);
    nEtx := Pos(MODEN_ETX, FRecvData);

    FRecvData := Copy(FRecvData, nStx, nEtx);


    if (Length(FRecvData) <> 15) then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : ' + FRecvData);

      sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogFromViewMulti(FIndex, sLogMsg);

      FRecvData := '';
      Exit;
    end;
  end;

  sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
  Global.DebugLogFromViewMulti(FIndex, sLogMsg);

  if FChannel = Copy(FRecvData, 2, 1) then
  begin

    // �������� : STX(1) + ID(1) + COMMAND(1) + DATA(6) + CLASS(1) + ETC(4) + ETX(1) + üũ��(1)
    // 1  2	 3	4	 5	6	 7	8	 9 10	11 12	13 14	15 16
    //   1	 A	0	 0	0	 0	0	 0	I	 0	0  0	1	 	!
    //02 31	41 30	30 30	30 30	30 49	30 30	30 31	03 21

    //.1A000000I0001.!
    //.2A002034T1001.7
    //FA050032T1701S

    rTeeboxInfo.StoreCd := ''; //������ �ڵ�

    if (Global.ADConfig.StoreCode = 'C0001') then //����������
      rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorIndexTeeboxNo(FFloorCd, FIndex, FChannel)
    else
      rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, FChannel); //Ÿ�� ��ȣ

    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

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
    else //Error
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(FRecvData, 12, 1));
      rTeeboxInfo.ErrorCd2 := copy(FRecvData, 12, 1);
    end;

    Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

    //sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
    sLogMsg := 'Nm:' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);

    sLogMsg := 'No:' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + sLogMsg;
    Global.Log.LogReadMulti(FIndex, sLogMsg);
  end
  else
  begin
    sLogMsg := 'Fail - No:' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm:' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.Log.LogReadMulti(FIndex, sLogMsg);
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
    Global.Log.LogReadMulti(FIndex, 'Ctl: ' + sLogMsg);

    if FLastCmdDataIdx <> FCurCmdDataIdx then
    begin
      inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
      if FCurCmdDataIdx > BUFFER_SIZE then
        FCurCmdDataIdx := 0;
    end;
  end;

  //Global.Log.LogCtrlWriteMulti(FIndex, sLogMsg);

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadSM.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime: AnsiString;
begin
  sTeeboxTime := StrZeroAdd(ATeeboxTime, 3);

  // �������� : STX(1) + ID(1) + COMMAND(1) + �ð�(3) + ��?(3) + CLASS(1) + ETC(4) + ETX(1) + CRC(1) - 16byte
  // 1	2	 3  4	 5	6	 7	8	 9 10	11 12	13 14	15 16
  // .  8  R  0  0  0  0  0  0  T  0  0  0  0  .  C
  // .  9  O  0  7  5  0  0  0  T  1  0  0  0  .  N
  // .  3  O  0  0  0  0  0  0  I  0  0  0  0  .  0

  if sTeeboxTime = '000' then
    //sSendData := ADeviceId + 'O' + sSeatTime + '000' + 'I' + '0000'
    sSendData := ADeviceId + 'O' + sTeeboxTime + '000' + 'T' + '0000'
  else
    sSendData := ADeviceId + 'O' + sTeeboxTime + '000' + 'T' + '1000';

  sBcc := GetBccSM(sSendData);
  sSendData := JEU_STX + sSendData + JEU_ETX + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;

end;

function TComThreadSM.SetNextMonNo: Boolean;
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

procedure TComThreadSM.Execute;
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
              sLogMsg := 'Retry COM_CTL Received Fail - No:' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

              FRecvData := '';

              if (Global.ADConfig.StoreCode = 'C0001') then //����������
              begin

                inc(FCtlReTry);
                if (FTeeboxInfo.TeeboxNo = 25) or (FTeeboxInfo.TeeboxNo = 50) then
                begin
                  if FCtlReTry > 2 then
                  begin
                    FCtlReTry := 0;
                    FComPort.Close;
                    FComPort.Open;
                    Global.Log.LogWriteMulti(FIndex, 'ReOpen');

                    if FLastCmdDataIdx <> FCurCmdDataIdx then
                    begin
                      inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
                      if FCurCmdDataIdx > BUFFER_SIZE then
                        FCurCmdDataIdx := 0;
                    end;

                  end;

                end
                else
                begin

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
                end;

              end
              else
              begin
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
              end;

              Break;

            end
            else
            begin
              sLogMsg := 'Retry COM_MON Received Fail - No:' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / Send: ' + FSendData + ' / Recv: ' + FRecvData;
              Global.Log.LogWriteMulti(FIndex, sLogMsg);

              //Global.Teebox.SetTeeboxErrorCntAD(FIndex, FTeeboxInfo.TeeboxNo, 'Y', 10);
              Global.Teebox.SetTeeboxErrorCntAD(FIndex, FTeeboxInfo.TeeboxNo, 'Y', 15); //2022-06-20 ���������� ��û
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

        if (Global.ADConfig.StoreCode = 'C0001') then //����������
          FTeeboxInfo := Global.Teebox.GetDeviceToFloorIndexTeeboxInfo(FFloorCd, FIndex, FChannel)
        else
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
        //FChannel := FTeeboxInfo.DeviceId;
        if (FTeeboxInfo.TeeboxZoneCode = 'L') or (FTeeboxInfo.TeeboxZoneCode = 'C') then
          FChannel := Copy(FTeeboxInfo.DeviceId, 1, Global.ADConfig.DeviceCnt)
        else
          FChannel := FTeeboxInfo.DeviceId;

        FSendData := JEU_STX + FChannel + 'R' + '000' + '000' + 'T' + '0000' + JEU_ETX;
        sBcc := GetBccSM(FSendData);
        FSendData := FSendData + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;
      //Sleep(200);  //50 �����ΰ�� retry �߻�
      Sleep(400);  // 2022-06-20 ���������� ��û

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadSM Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.
