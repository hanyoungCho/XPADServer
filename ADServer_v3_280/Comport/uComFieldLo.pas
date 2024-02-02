unit uComFieldLo;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadFieldLo = class(TThread)
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

constructor TComThreadFieldLo.Create;
begin
  //ProtocolType=FIELDLO
  FReTry := 0;
  FReceived := True;
  FTeeboxNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadFieldLo Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadFieldLo.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadFieldLo.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
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

  Global.Log.LogWrite('TComThreadFieldLo ComPortSetting : ' + FFloorCd);
end;

procedure TComThreadFieldLo.ComPortRxChar(Sender: TObject; Count: Integer);
var
  //nFuncCode: Integer;
  //DevNo, State, Time: string;
  sLogMsg: string;

  //nIndex: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx: Integer;
begin

  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;
  Global.Log.LogReadMulti(FIndex, 'FRecvData : ' + FRecvData);
  if Length(FRecvData) < 9 then
    Exit;

  if Pos(COM_STX, FRecvData) = 0 then
    Exit;

  if Pos(COM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(COM_STX, FRecvData);
  nEtx := Pos(COM_ETX, FRecvData);

  //Global.Log.LogReadMulti(FIndex, 'FRecvData : ' + FRecvData);
  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 8) then
  begin
    Global.Log.LogReadMulti(FIndex, 'FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 2) then
  begin

    // �������� : STX(1) + ID(2) + COMMAND(1) + �ð�(3) + ETX(1) + üũ��(1)
    // 1  2	 3	4	 5	6	 7	8	 9
    //   0	 1	0	 0	0	 0		 !

    rTeeboxInfo.StoreCd := ''; //������ �ڵ�
    //rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, FChannel); //Ÿ�� ��ȣ
    rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo;
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

    rTeeboxInfo.UseYn := '';        //��� ����
    rTeeboxInfo.RemainBall := 0;

    if (copy(FRecvData, 4, 1) = 'S') then //Error
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(FRecvData, 7, 1));
      rTeeboxInfo.ErrorCd2 := copy(FRecvData, 7, 1);
    end
    else //0 ~ 7:����- tee����
    begin
      rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 5, 3));

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

procedure TComThreadFieldLo.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime: AnsiString;
begin
  sTeeboxTime := StrZeroAdd(ATeeboxTime, 3);

  // �������� : STX(1) + ID(2) + COMMAND(1) + �ð�(3) + ETX(1) + CRC(1) - 9byte
  // 1	2	 3  4	 5	6	 7	8	 9
  // .  0  1  T  0  0  0  .  C

  sSendData := COM_STX + ADeviceId + 'T' + sTeeboxTime + COM_ETX;
  sBcc := GetBccFieldLo(sSendData);
  sSendData := sSendData + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;

end;

function TComThreadFieldLo.SetNextMonNo: Boolean;
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

procedure TComThreadFieldLo.Execute;
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
        {
        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;
        }
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        FLastExeCommand := COM_MON;
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
        FChannel := FTeeboxInfo.DeviceId;

        FSendData := COM_STX + FChannel + 'S' + '000' + COM_ETX;
        sBcc := GetBccFieldLo(FSendData);
        FSendData := FSendData + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;

      Sleep(200);  //50 �����ΰ�� retry �߻�

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadFieldLo Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.


