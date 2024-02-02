unit uComJehu435;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadJehu435 = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FReceived: Boolean;
    FChannel: String;

    FIndex: Integer;
    FFloor: String;

    //2021-04-07 ����3ȸ �õ��� ����ó��
    FCtlReTry: Integer;
    //FCtlChannel: String;

    FTeeboxNoStart: Integer; //���� Ÿ����ȣ
    FTeeboxNoEnd: Integer; //���� Ÿ����ȣ
    FTeeboxNoLast: Integer; //������ ��û Ÿ����ȣ

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    //FLastCtlSeatDeviceNo: String; //����Ÿ���� ����͸���
    //FLastMonSeatDeviceNo: Integer;
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

    //procedure SetSeatError(AChannel: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJeu435 }

constructor TComThreadJehu435.Create;
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
  
  FReTry := 0;
  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastCtlSeatDeviceNo := '';
  //FLastMonSeatDeviceNo := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadJeu435 Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadJehu435.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadJehu435.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
begin
  FTeeboxNoStart := ATeeboxNoStart;
  FTeeboxNoEnd := ATeeboxNoEnd;
  FTeeboxNoLast := ATeeboxNoStart;
  FIndex := AIndex;
  FFloor := AFloorCd;

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(APort);
  FComPort.BaudRate := GetBaudrate(ABaudRate);
  FComPort.Open;

  Global.Log.LogWrite('TComThreadJeu435 ComPortSetting : ' + IntToStr(AIndex));
end;

procedure TComThreadJehu435.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sLogMsg: string;
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
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : STX 02 Error ' + IntToStr(FLastExeCommand) + ' : ' +
       IntToStr(FTeeboxInfo.TeeboxNo) + ' : ' + FSendData + ' / ' + FRecvData);

      sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogFromViewMulti(FIndex, sLogMsg);

      FRecvData := '';
      Exit;
    end;

    if copy(FRecvData, 2, 1) = JEU_MON_ERR then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : 04 ���ſ��� ' + IntToStr(FLastExeCommand) + ' : ' +
       IntToStr(FTeeboxInfo.TeeboxNo) + ' : ' + FSendData + ' / ' + FRecvData);

      sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogFromViewMulti(FIndex, sLogMsg);

      FRecvData := '';
      Exit;
    end;

    if copy(FRecvData, 2, 1) = JEU_NAK then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : 15 �۽ſ���' + IntToStr(FLastExeCommand) + ' : ' +
       IntToStr(FTeeboxInfo.TeeboxNo) + ' : ' + FSendData + ' / ' + FRecvData);

      sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogFromViewMulti(FIndex, sLogMsg);

      FRecvData := '';
      Exit;
    end;

    if copy(FRecvData, 2, 1) = JEU_CTL_FIN then //���� ����
    begin
      sLogMsg := 'FRecvData CTL Succese ' + IntToStr(FLastExeCommand) + ' : ' + FSendData + ' / ' + FRecvData;

      rTeeboxInfo.StoreCd := ''; //������ �ڵ�
      rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo;
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

      Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

      if FLastCmdDataIdx <> FCurCmdDataIdx then
      begin
        inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
        if FCurCmdDataIdx > BUFFER_SIZE then
          FCurCmdDataIdx := 0;
      end;

      Global.Log.LogReadMulti(FIndex, sLogMsg);

      sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogMainViewMulti(FIndex, sLogMsg);

      sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogFromViewMulti(FIndex, sLogMsg);

      FRecvData := '';
      FReceived := True;

      Exit;
    end;

    if Length(FRecvData) > JEU_RECV_LENGTH then
    begin
      Global.Log.LogReadMulti(FIndex, 'Over : ' + FRecvData);

      sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogFromViewMulti(FIndex, sLogMsg);

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
    Global.Log.LogReadMulti(FIndex, '��ûŸ����: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / �ѱ��ڼ�: ' + IntToStr(Count) + ' / ' + FRecvData);

    sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogFromViewMulti(FIndex, sLogMsg);

    FRecvData := '';
    Exit;
  end;

  sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
  Global.DebugLogFromViewMulti(FIndex, sLogMsg);

  if FChannel = Copy(FRecvData, 2, 2) then
  begin

    // 10�� 30�� 200��, STX(1)+ID(2)+�ܿ��ð�(3)+�ܿ���(4)+����(1)+����(1)+����(1)+BCC(1)+ETX(1)
    // 1,	 2	 3,	4  5  6,	7  8  9 10, 11 12 13, 14, 15
    //02,	 1   0,	0  3	0,	0	 2	0	 0,	 0  0	 0,  6, 03
    //02, 31	30, 30 33 30, 30 32 30 30, 30 30 30, 36, 03

    //���� 0:OFF, 1:ON
    //���� 0:�ڵ�������, 1:����������, 9:����(������)
    //���� 0:��������, 1:Ƽ�������̻�, 2:Ÿ�ڼ����̻�, 3:���ۼ����̻�, 4:��ġ����?

    rTeeboxInfo.StoreCd := ''; //������ �ڵ�
    rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo;
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
        rTeeboxInfo.ErrorCd := ERROR_CODE_13
      else if copy(FRecvData, 13, 1) = '4' then
        rTeeboxInfo.ErrorCd := ERROR_CODE_14;

      rTeeboxInfo.ErrorCd2 := copy(FRecvData, 13, 1);
    end;

    if isNumber(copy(FRecvData, 4, 7)) = False then
    begin
      sLogMsg := 'Int Error : ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
      Global.Log.LogReadMulti(FIndex, sLogMsg);
      FRecvData := '';
      Exit;
    end;

    rTeeboxInfo.UseYn := '';        //��� ����
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 7, 4));
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 4, 3));

    Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

    sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);

    //sLogMsg := 'No:' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + sLogMsg;
    Global.Log.LogReadMulti(FIndex, sLogMsg);
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
  end;

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadJehu435.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
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

function TComThreadJehu435.SetNextMonNo: Boolean;
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
{
//2021-04-07 ����3ȸ �õ��� ����ó��
procedure TComThreadJehu435.SetSeatError(AChannel: String);
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

procedure TComThreadJehu435.Execute;
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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 2);

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToFloorTeeboxInfo(FFloor, FChannel);
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
        // 1	2	 3	4	 5  / 10�� Ÿ�� ����Ÿ ��û, ENQ(1)+ID(2)+BCC(1)+ETX
        //05	1	 0  1 03
        //05 31	30 31	03
        FLastExeCommand := COM_MON;
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);

        if Global.ADConfig.StoreCode = 'A8001' then
        begin
          FChannel := FTeeboxInfo.DeviceId;
        end
        else //if Global.ADConfig.StoreCode = 'BF001' then //�μ�, �д�׸��Ǿ�
        begin
          if (FTeeboxInfo.TeeboxZoneCode = 'L') or (FTeeboxInfo.TeeboxZoneCode = 'C') then
            FChannel := Copy(FTeeboxInfo.DeviceId, 1, Global.ADConfig.DeviceCnt)
          else
            FChannel := FTeeboxInfo.DeviceId;
        end;

        sBcc := GetBccJehu(FChannel);
        if Length(sBcc) > 1 then
          sBcc := Copy(sBcc, length(sBcc), 1);
        FSendData := JEU_ENQ + FChannel + sBcc + JEU_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;  //3
      end;

      FReceived := False;

      if (Global.ADConfig.StoreCode = 'A9001') or (Global.ADConfig.StoreCode = 'D2001') then // ��������, ����
      begin
        if bControlMode = True then
        begin
          if FTeeboxInfo.UseReset = 'Y' then
          begin
            Sleep(2000); //�����ð� ����� 2���̻��� �����̰� �־�� �ʱ�ȭ�� �����(1�� ����)
            sLogMsg := 'UseReset : No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm;
            Global.Log.LogWriteMulti(FIndex, sLogMsg);
            Global.Teebox.SetTeeboxInfoUseReset(FTeeboxInfo.TeeboxNo);
          end;
        end;
      end;

      Sleep(200);

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadJeu435 Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.
