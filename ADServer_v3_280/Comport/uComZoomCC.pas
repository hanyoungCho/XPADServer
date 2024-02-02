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
    FCtlChannel: String;

    FReceived: Boolean;
    FChannel: String;

    FIndex: Integer;
    FFloorCd: String; //��

    FTeeboxNoStart: Integer; //���� Ÿ����ȣ
    FTeeboxNoEnd: Integer; //���� Ÿ����ȣ
    FTeeboxNoLast: Integer; //������ ��û Ÿ����ȣ

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    FLastCtlSeatNo: Integer; //���� ����Ÿ����
    //FLastMonSeatDeviceNo: Integer;
    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    FWriteTm: TDateTime;
    FTeeboxInfo: TTeeboxInfo;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);

    procedure ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
    //procedure SetSeatError(AChannel: String);

    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadZoomCC }

constructor TComThreadZoomCC.Create;
begin
  FReTry := 0;
  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastMonSeatDeviceNo := 0;
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

procedure TComThreadZoomCC.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
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
  FComPort.Parity.Bits := prOdd;
  FComPort.Open;

  Global.Log.LogWrite('TComThreadZoomCC ComPortSetting : ' + IntToStr(AIndex));
end;

procedure TComThreadZoomCC.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC, sErrorCd, sErrorCdHex: string;

  sLogMsg: string;
  //SeatInfo: TSeatInfo;

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

  if Pos(ZOOM_STX, FRecvData) = 0 then
    Exit;

  if Pos(ZOOM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(ZOOM_CC_STX, FRecvData);
  nEtx := Pos(ZOOM_CC_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 15) then
  begin
    Global.Log.LogReadMulti(FIndex, 'FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //STX(1) PLC(2) TEE(1) ����(1) ������ȣ(1) �ܿ��ð�(4) �ܿ�����(4) ETX(1) BCC(1)
    //����: 0.�ʱ�ȭ����� 1.Ÿ����ȣ(�����) 3.����� 4.����(END) 5.����
    //1, 2 3, 4, 5,	6, 7 8 9 10, 11	12 13	14, 15,	16
    //	 0 9 	1	 3	@	 0 0 5  4	  9	 9	2	 5	 	 2
    //02 30	39 31	33 40	30 30	35 34	39 39	32 35	03 32
    rTeeboxInfo.StoreCd := ''; //������ �ڵ�
    //rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(copy(FRecvData, 2, 3)); //Ÿ�� ��ȣ
    //rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, FChannel);
    rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo;
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

    if (copy(FRecvData, 6, 1) = '@') or (copy(FRecvData, 6, 1) = '0') then //����
    begin
      if copy(FRecvData, 5, 1) = '4' then //��Ÿ��(����)
        rTeeboxInfo.UseStatus := '0'
      else if copy(FRecvData, 5, 1) = '3' then //�����
        rTeeboxInfo.UseStatus := '1'
      else if copy(FRecvData, 5, 1) = '1' then //���
        rTeeboxInfo.UseStatus := '0'
      else
        rTeeboxInfo.UseStatus := '0';
    end
    else //1,2,3,4
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 0;

      sErrorCd := copy(FRecvData, 6, 1);
      sErrorCdHex := StrToAnsiHex(sErrorCd);
      {
      if copy(sErrorCdHex, 2, 1) = '1' then
        rTeeboxInfo.ErrorCd := 2 //error: ������
      else if copy(sErrorCdHex, 2, 1) = '2' then
        rSeatInfo.ErrorCd := 1 //���ɸ�
      else if copy(FRecvData, 2, 1) = '3' then
        rSeatInfo.ErrorCd := 4; //error: �����̻�
      }
      rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(sErrorCdHex, 2, 1));
      rTeeboxInfo.ErrorCd2 := copy(sErrorCdHex, 2, 1);

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / ' + sErrorCd + ' / ' + sErrorCdHex;
      Global.Log.LogWrite(sLogMsg);
    end;

    rTeeboxInfo.UseYn := '';        //��� ����
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 11, 4));
    if copy(FRecvData, 5, 1) = '1' then
      rTeeboxInfo.RemainMinute := 0
    else
      rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 7, 4));

    rTeeboxInfo.RecvData := FRecvData;
    rTeeboxInfo.SendData := FSendData;

    Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

    if FLastExeCommand = COM_CTL then
    begin
      sLogMsg := IntToStr(FLastExeCommand) + ' ��û: ' + IntToStr(rTeeboxInfo.TeeboxNo) +
                 ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel +
                 //' / ����: ' + IntToStr(Global.Teebox.GetDevicToTeeboxNo(Copy(FRecvData, 2, 3))) +
                 ' / ����: ' + FRecvData;
      Global.Log.LogReadMulti(FIndex, sLogMsg);
    end;

    //sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + '   ' + FRecvData;
    sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);
  end
  else
  begin
    sLogMsg := 'FChannel Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel + ' / ' + FRecvData;
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

procedure TComThreadZoomCC.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime, sTeeboxBall: AnsiString;
begin
  if ATeeboxTime = '0' then
  begin
    sSendData := ADeviceId + 'E';
  end
  else
  begin
    sTeeboxTime := StrZeroAdd(ATeeboxTime, 4);
    sTeeboxBall := StrZeroAdd(ATeeboxBall, 4);

    sSendData := ADeviceId + 'S1' + sTeeboxTime + sTeeboxBall;
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
  rTeeboxInfo: TTeeboxInfo;
begin
  rTeeboxInfo.StoreCd := ''; //������ �ڵ�
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(AChannel); //Ÿ�� ��ȣ
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

  Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);
end;
}

function TComThreadZoomCC.SetNextMonNo: Boolean;
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

procedure TComThreadZoomCC.Execute;
var
  bControlMode: Boolean;
  sBcc, sSendDataTemp: AnsiString;
  sLogMsg, sTeeboxNm: String;
  //nSeatNo: Integer;
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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToFloorTeeboxInfo(FFloorCd, FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
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
          //ENQ(1) PLC(2) TEE(1) M(1) 3(��������) Ÿ����ȣ(3) EOT(1) BCC(1)  -> �¿������� �����ִ� Ÿ���� ��� tee �� -> 3 / ���� tee ������ �Ұ�� �����°� Ǯ��

          if Global.ADConfig.StoreCode = 'A8003' then
          begin
            if (FChannel = '242') then // 44��Ÿ��
              sSendDataTemp := FChannel + 'M3' + StrZeroAdd('44', 3)
            else
              sSendDataTemp := FChannel + 'M3' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 3);
          end
          else if Global.ADConfig.StoreCode = 'B7001' then //������
          begin
            if (FChannel = '142') then // 26��Ÿ��
              sSendDataTemp := FChannel + 'M3' + StrZeroAdd('26', 3)
            else if (FChannel = '272') then // 50��Ÿ��
              sSendDataTemp := FChannel + 'M3' + StrZeroAdd('50', 3)
            else if (FChannel = '282') then // 51��Ÿ��
              sSendDataTemp := FChannel + 'M3' + StrZeroAdd('51', 3)
            else
              sSendDataTemp := FChannel + 'M3' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 3);
          end
          else
            sSendDataTemp := FChannel + 'M3' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 3);

          sBcc := GetBCCZoomCC(sSendDataTemp);
          FSendData := ZOOM_CC_ENQ + sSendDataTemp + ZOOM_CC_EOT + sBcc;
          FComPort.Write(FSendData[1], Length(FSendData));
          Global.Log.LogWriteMulti(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

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
        Global.Log.LogWriteMulti(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
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
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
        FChannel := FTeeboxInfo.DeviceId;

        sBcc := GetBCCZoomCC(FChannel);
        FSendData := ZOOM_CC_SOH + FChannel + ZOOM_CC_EOT + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 3;
      end;

      FReceived := False;
      Sleep(200);  //50 �����ΰ�� retry �߻�

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadZoomCC Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
