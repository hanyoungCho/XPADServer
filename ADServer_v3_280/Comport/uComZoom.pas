unit uComZoom;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadZoom = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
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

    procedure SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);

    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadZoom }

constructor TComThreadZoom.Create;
begin
  FReTry := 0;
  FCtlReTry := 0;

  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadZoom Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadZoom.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadZoom.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
var
  sLogMsg: String;
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

  if (Global.ADConfig.StoreCode = 'C2001') or (Global.ADConfig.StoreCode = 'D4001') then // ����׸��Ͽ�����Ŭ��, ����CC
    FComPort.Parity.Bits := prNone
  else
    FComPort.Parity.Bits := prOdd;
  FComPort.Open;

  Global.Log.LogWrite('TComThreadZoom ComPortSetting : ' + IntToStr(AIndex));
end;

procedure TComThreadZoom.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sLogMsg: string;
  sRecvData, sCode, sStatus: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx: Integer;
  sSendData, sBcc: AnsiString;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  //sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData + ' / ' + StringToHex(FRecvData);
  //Global.DebugLogFromViewMulti(FIndex, sLogMsg);
  //Global.Log.LogReadMulti(FIndex, sLogMsg);
  {
  if Length(FRecvData) < 16 then
    Exit;
  }

  if Pos(ZOOM_STX, FRecvData) = 0 then
    Exit;

  if Pos(ZOOM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(ZOOM_STX, FRecvData);
  nEtx := Pos(ZOOM_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (global.ADConfig.StoreCode = 'D4001') then // D4001 ����CC
    FRecvData := Copy(FRecvData, 1, 15);

  //2020-06-17 ���� 19�ڸ� .0613@011799838A5C.$  , .0623@00529936D76C.$
  if (Length(FRecvData) <> 15) and (Length(FRecvData) <> 19) then
  begin
    Global.Log.LogReadMulti(FIndex, 'FRecvData Length fail : ' + IntToStr(Length(FRecvData)) + ' / ' + FRecvData);

    sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogFromViewMulti(FIndex, sLogMsg);

    FRecvData := '';
    Exit;
  end;

  sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
  Global.DebugLogFromViewMulti(FIndex, sLogMsg);

  //sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData + ' / ' + StringToHex(FRecvData);
  sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
  Global.Log.LogReadMulti(FIndex, sLogMsg);

  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //1	2	3	4	5	6	7	8	9	10 11	12 13	14 15	16
    //	0	9	1	3	@	0	0	5	 4	9	 9	2	 5		 2
    //02 30	39 31	33 40	30 30	35 34	39 39	32 35	03 32
    rTeeboxInfo.StoreCd := ''; //������ �ڵ�
    rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo;
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

    //2020-06-17 ���� @,0 �ΰ�� �߻�
    sCode := copy(FRecvData, 6, 1);
    if (sCode = '@') or (sCode = '0') then //����
    begin
      sStatus := copy(FRecvData, 5, 1);

      if sStatus = '4' then //��Ÿ��(����)
        rTeeboxInfo.UseStatus := '0'
      else if sStatus = '3' then //�����
        rTeeboxInfo.UseStatus := '1'
      else if sStatus = '2' then //������: S0 ���� �����ϴ°��
        rTeeboxInfo.UseStatus := '0'
      else if sStatus = '1' then //���: Ÿ����ȣ ǥ�û��� 2023.05.25 ��Ÿ����Ŭ��(�ϻ�)
        rTeeboxInfo.UseStatus := '0'
      else if sStatus = '5' then //���� 2021-08-18 �׸��ʵ�
      begin
        if (Global.ADConfig.StoreCode = 'B2001') then //�׸��ʵ�
          rTeeboxInfo.UseStatus := 'M'
        else
          rTeeboxInfo.UseStatus := '0';
      end
      else
        rTeeboxInfo.UseStatus := '0';

      if (global.ADConfig.StoreCode = 'CD001') then //CD001	��Ÿ����Ŭ��(�ϻ�)
      begin
        if (sCode = '0') and (sStatus = '4') then // ���������� �Ǵ�
        begin
          sSendData := FChannel + 'M4' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 3); // Ÿ���� 3�ڸ� M4 + 004
          sBcc := GetBCCZoomCC(sSendData);
          sSendData := ZOOM_CTL_STX + sSendData + ZOOM_REQ_ETX + sBcc;

          FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

          inc(FLastCmdDataIdx);
          if FLastCmdDataIdx > BUFFER_SIZE then
            FLastCmdDataIdx := 0;
        end;
      end;

    end
    {
    else if sCode = '1' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 2; //error: ������
      rTeeboxInfo.ErrorCd2 := '1';

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / 1';
      Global.Log.LogWrite(sLogMsg);
    end
    else if sCode = '2' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 1; //���ɸ�
      rTeeboxInfo.ErrorCd2 := '2';

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / 2';
      Global.Log.LogWrite(sLogMsg);
    end
    else if sCode = '3' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 4; //error: �����̻�
      rTeeboxInfo.ErrorCd2 := '3';

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / 3';
      Global.Log.LogWrite(sLogMsg);
    end
    }
    //�׸� �Ͽ�� ������ 1~5������ �ֽ��ϴ�. - ����� ����
    else if (sCode = '1') or (sCode = '2') or (sCode = '3') or (sCode = '4') or (sCode = '5') then //�����ڵ� ǥ�÷� ���� 2023-07-03
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 10 + StrToInt(sCode);
      rTeeboxInfo.ErrorCd2 := sCode;

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / ' + sCode;
      Global.Log.LogWrite(sLogMsg);
    end
    else //C
    begin
      rTeeboxInfo.UseStatus := '9';  //Error ����: 1,2,3,A,B,C
      rTeeboxInfo.ErrorCd := 0;
      rTeeboxInfo.ErrorCd2 := sCode;

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / ' + sCode;
      Global.Log.LogWrite(sLogMsg);
    end;

    rTeeboxInfo.UseYn := '';        //��� ����
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 11, 4));
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

    if sStatus = '5' then
       Global.Log.LogWrite(sLogMsg);
  end
  else
  begin
    sLogMsg := 'FChannel Fail - No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel + ' / ' + FRecvData;
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

procedure TComThreadZoom.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sSeatTime, sSeatBall: AnsiString;
begin
  sSeatTime := StrZeroAdd(ASeatTime, 4);
  sSeatBall := StrZeroAdd(ASeatBall, 4);

  sSendData := ADeviceId + AType + sSeatTime + sSeatBall;
  sBcc := GetBCCZoomCC(sSendData);
  sSendData := ZOOM_CTL_STX + sSendData + ZOOM_REQ_ETX + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadZoom.SetNextMonNo: Boolean;
var
  rTeeboxInfo: TTeeboxInfo;
begin

  while True do
  begin
    inc(FTeeboxNoLast);
    if FTeeboxNoLast > FTeeboxNoEnd then
      FTeeboxNoLast := FTeeboxNoStart;

    rTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
    if (rTeeboxInfo.TeeboxNo > 0) and (rTeeboxInfo.UseYn = 'Y') then
      Break;
  end;

end;

procedure TComThreadZoom.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
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

              sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / Fail';
              Global.DebugLogFromViewMulti(FIndex, sLogMsg);

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

              sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / Fail';
              Global.DebugLogFromViewMulti(FIndex, sLogMsg);

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

        if (global.ADConfig.StoreCode = 'CD001') and (Copy(FSendData, 5, 1) = 'M') then //CD001	��Ÿ����Ŭ��(�ϻ�)
        begin
          //���¿�û ����
        end
        else
        begin
          Sleep(100);

          //������ ���ϰ��� ����
          sBcc := GetBCCZoomCC(FChannel);
          FSendData := ZOOM_MON_STX + FChannel + ZOOM_REQ_ETX + sBcc;
          //FRecvData := '';
          FComPort.Write(FSendData[1], Length(FSendData));
          Global.Log.LogWriteMulti(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);
        end;

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        //1	2	3	4	5	6
        //	0	1	1		6
        //01	30	31	31	04	36
        FLastExeCommand := COM_MON;
        //Global.Log.LogWriteMulti(FIndex, 'FTeeboxNoLast: ' + IntToStr(FTeeboxNoLast));
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
        //FChannel := FTeeboxInfo.DeviceId;
        if (FTeeboxInfo.TeeboxZoneCode = 'L') or (FTeeboxInfo.TeeboxZoneCode = 'C') then
          FChannel := Copy(FTeeboxInfo.DeviceId, 1, Global.ADConfig.DeviceCnt)
        else
          FChannel := FTeeboxInfo.DeviceId;

        sBcc := GetBCCZoomCC(FChannel);
        FSendData := ZOOM_MON_STX + FChannel + ZOOM_REQ_ETX + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));
        //Global.Log.LogWriteMulti(FIndex, 'SendData : bControlMode ' + IntToStr(FTeeboxNoLast) + ' / ' + FSendData);

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;
      Sleep(100);  //50 �����ΰ�� retry �߻�

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadZoom Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
