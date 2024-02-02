unit uComZoomCC;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadZoomCC = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;

    //2020-06-08 ����3ȸ �õ��� ����ó��
    FCtlReTry: Integer;
    //FCtlChannel: String;
    //FCtlMin: String;

    FReceived: Boolean;
    FChannel: String;

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    FLastCtlSeatNo: Integer; //���� ����Ÿ����
    FLastDeviceNo: Integer;
    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    FWriteTm: TDateTime;
    FTeeboxInfo: TTeeboxInfo;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);

    //procedure SetSeatError(AChannel: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

  function GetBaudrate(const ABaudrate: Integer): TBaudRate;

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

{ TControlComPortZoomCCMonThread }

constructor TComThreadZoomCC.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  FComPort.Parity.Bits := prOdd;
  FComPort.Open;

  FReTry := 0;
  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FLastDeviceNo := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadZoomCC Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadZoomCC.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadZoomCC.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC, sErrorCd, sErrorCdHex: string;

  sLogMsg: string;
  //SeatInfo: TTeeboxInfo;

  Index: Integer;
  sRecvData: AnsiString;
  rSeatInfo: TTeeboxInfo;

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

  nStx := Pos(ZOOM_CC_STX, FRecvData);
  nEtx := Pos(ZOOM_CC_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 15) then
  begin
    Global.Log.LogComRead('FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel <> Copy(FRecvData, 2, 3) then
  begin
    sLogMsg := 'FChannel Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel + ' / ' + FRecvData;
    Global.Log.LogComRead(sLogMsg);

    FRecvData := '';
    Exit;
  end;

  Global.Log.LogComRead('FRecvData : ' + FRecvData);

  //STX(1) PLC(2) TEE(1) ����(1) ������ȣ(1) �ܿ��ð�(4) �ܿ�����(4) ETX(1) BCC(1)
  //����: 0.�ʱ�ȭ����� 1.Ÿ����ȣ(�����) 3.����� 4.����(END) 5.����
  //1, 2 3, 4, 5,	6, 7 8 9 10, 11	12 13	14, 15,	16
  //	 0 9 	1	 3	@	 0 0 5  4	  9	 9	2	 5	 	 2
  //02 30	39 31	33 40	30 30	35 34	39 39	32 35	03 32
  rSeatInfo.StoreCd := ''; //������ �ڵ�
  rSeatInfo.TeeboxNo := FTeeboxInfo.TeeboxNo; //Ÿ�� ��ȣ
  rSeatInfo.TeeboxNm := '';  //Ÿ����
  rSeatInfo.RecvDeviceId := FChannel;
  rSeatInfo.FloorZoneCode := ''; //�� ���� �ڵ�
  rSeatInfo.ZoneDiv := '';  //���� ���� �ڵ�

  //if copy(FRecvData, 6, 1) = '0' then //����
  if copy(FRecvData, 6, 1) = '@' then //����
  begin
    if copy(FRecvData, 5, 1) = '4' then //��Ÿ��(����)
      rSeatInfo.UseStatus := '0'
    else if copy(FRecvData, 5, 1) = '3' then //�����
      rSeatInfo.UseStatus := '1'
    else if copy(FRecvData, 5, 1) = '1' then //���
      rSeatInfo.UseStatus := '0'
    else
      rSeatInfo.UseStatus := '0';
  end
  else //1,2,3,4
  begin
    rSeatInfo.UseStatus := '9';
    rSeatInfo.ErrorCd := 0;

    sErrorCd := copy(FRecvData, 6, 1);
    sErrorCdHex := StrToAnsiHex(sErrorCd);

    if copy(sErrorCdHex, 2, 1) = '1' then
      rSeatInfo.ErrorCd := 2 //error: ������
    else if copy(sErrorCdHex, 2, 1) = '2' then
      rSeatInfo.ErrorCd := 1 //���ɸ�
    else if copy(FRecvData, 2, 1) = '3' then
      rSeatInfo.ErrorCd := 4; //error: �����̻�

    sLogMsg := 'Error Code - No:' + intToStr(FTeeboxInfo.TeeboxNo) + ' Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + sErrorCd + ' / ' + sErrorCdHex;
    Global.Log.LogComRead(sLogMsg);
  end;

  rSeatInfo.UseYn := '';        //��� ����
  rSeatInfo.RemainBall := StrToInt(copy(FRecvData, 11, 4));
  if copy(FRecvData, 5, 1) = '1' then
    rSeatInfo.RemainMinute := 0
  else
    rSeatInfo.RemainMinute := StrToInt(copy(FRecvData, 7, 4));

  Global.Teebox.SetTeeboxInfo(rSeatInfo);

  if FLastExeCommand = COM_CTL then
  begin
    sLogMsg := IntToStr(FLastExeCommand) + ' ��û: ' + IntToStr(FTeeboxInfo.TeeboxNo) +
               ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel +
               ' / ����:' + FRecvData;
    Global.Log.LogComRead(sLogMsg);
  end;

  sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
  Global.DebugLogViewWrite(sLogMsg);

  if FLastExeCommand = COM_MON then
  begin
    Global.Teebox.SetTeeboxErrorCntAD(FTeeboxInfo.TeeboxNo, 'N', 10);
    SetNextMonNo;
  end
  else
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

procedure TComThreadZoomCC.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sSeatTime, sSeatBall: AnsiString;
begin
  if ASeatTime = '0' then
  begin
    sSendData := ADeviceId + 'E';
  end
  else
  begin
    sSeatTime := StrZeroAdd(ASeatTime, 4);
    sSeatBall := StrZeroAdd(ASeatBall, 4);

    sSendData := ADeviceId + 'S1' + sSeatTime + sSeatBall;
  end;

  sBcc := GetBCCZoomCC(sSendData);
  sSendData := ZOOM_CTL_STX + sSendData + ZOOM_REQ_ETX + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;
{
//2020-06-08 ����3ȸ �õ��� ����ó��
procedure TComThreadZoomCC.SetSeatError(AChannel: String);
var
  rSeatInfo: TSeatInfo;
begin
  rSeatInfo.StoreCd := ''; //������ �ڵ�
  rSeatInfo.SeatNo := Global.Teebox.GetDevicToSeatNo(AChannel); //Ÿ�� ��ȣ
  rSeatInfo.RecvDeviceId := AChannel;
  rSeatInfo.SeatNm := '';  //Ÿ����
  rSeatInfo.FloorZoneCode := ''; //�� ���� �ڵ�
  rSeatInfo.SeatZoneCode := '';  //���� ���� �ڵ�
  rSeatInfo.UseStatus := '9';
  rSeatInfo.UseYn := '';        //��� ����
  rSeatInfo.RemainBall := 0;
  rSeatInfo.RemainMinute := 0;
  rSeatInfo.ErrorCd := 8; //����̻�

  Global.Teebox.SetSeatInfo(rSeatInfo);
end;
}

function TComThreadZoomCC.SetNextMonNo: Boolean;
begin
  inc(FLastDeviceNo);
  if FLastDeviceNo > Global.Teebox.DevicNoCnt - 1 then
    FLastDeviceNo := 0;
end;

procedure TComThreadZoomCC.Execute;
var
  bControlMode: Boolean;
  sBcc, sSendDataTemp: AnsiString;
  sLogMsg: String;
  //nSeatNo: Integer;
begin
  inherited;

  while not Terminated do
  begin
    try

      while True do
      begin
        if FReceived = False then
        begin

          if now > FWriteTm then
          begin

            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
              Global.Log.LogRetryWrite(sLogMsg);

              FRecvData := '';

              inc(FCtlReTry);
              if FCtlReTry > 2 then
              begin
                FCtlReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogRetryWrite('ReOpen');
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
              sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData;
              Global.Log.LogRetryWrite(sLogMsg);

              Global.Teebox.SetTeeboxErrorCntAD(FTeeboxInfo.TeeboxNo, 'N', 10);
              SetNextMonNo;

              inc(FReTry);
              if FReTry > 10 then
              begin
                FReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogRetryWrite('ReOpen');
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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);
        
        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToTeeboxInfo(FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogComWrite(sLogMsg);
        //Sleep(50);

        FWriteTm := now + (((1/24)/60)/60) * 0.1;

        while True do
        begin
          if now > FWriteTm then
          begin
            Break;
          end;
        end;

        //üũ�ƿ��� Ÿ����ȣ����
        if Copy(FSendData, 5, 1) = 'E' then
        begin
          //ENQ(1) PLC(2) TEE(1) M(1) 3(��������) Ÿ����ȣ(3) EOT(1) BCC(1)
          sSendDataTemp := FChannel + 'M3' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 3);
          sBcc := GetBCCZoomCC(sSendDataTemp);
          FSendData := ZOOM_CC_ENQ + sSendDataTemp + ZOOM_CC_EOT + sBcc;
          FComPort.Write(FSendData[1], Length(FSendData));
          Global.Log.LogComWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

          FWriteTm := now + (((1/24)/60)/60) * 0.1;

          while True do
          begin
            if now > FWriteTm then
            begin
              Break;
            end;
          end;

        end;

        //������ ���ϰ��� ����
        sBcc := GetBCCZoomCC(FChannel);
        FSendData := ZOOM_CC_SOH + FChannel + ZOOM_CC_EOT + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogComWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;

        FWriteTm := now + (((1/24)/60)/60) * 2;
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        //1	2	3	4	5	6
        //	0	1	1		6
        //01	30	31	31	04	36
        FLastExeCommand := COM_MON;
        FChannel := Global.Teebox.GetSeatDevicdNoToDevic(FLastDeviceNo);
        FTeeboxInfo := Global.Teebox.GetDeviceToTeeboxInfo(FChannel);

        sBcc := GetBCCZoomCC(FChannel);
        FSendData := ZOOM_CC_SOH + FChannel + ZOOM_CC_EOT + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;
      Sleep(200);  //50 �����ΰ�� retry �߻�

    except
      on e: Exception do
      begin
        sLogMsg := 'TComZoomCCMonThread Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
