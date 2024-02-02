unit uComModenYJ;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadModenYJ = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FRecvDataTM: AnsiString;
    FSendDataTM: AnsiString;

    FReTry: Integer;
    FErrCnt: Integer;

    FReceived: Boolean;
    FChannel: String;
    FTeeboxNo: Integer;

    FMonDeviceNoLast: Integer;

    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    FWriteTm: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetMonSendBuffer(ADeviceId: String);

    procedure SetErrCnt(ATeeboxNo: Integer);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadModenYJ }

constructor TComThreadModenYJ.Create;
begin
  {
  ['AX','AW','AV','AU','AT','AS','AR','AQ','AP','AI',
   'AH','AG','AF','AE','AD','AC','AB','AA','A@','A9',
   'A8','A7','A6','A5','A4','A3','A2','A1',
   'BX','BW','BV','BU','BT','BS','BR','BQ','BP','BI',
   'BH','BG','BF','BE','BD','BC','BB','BA','B@','B9',
   'B8','B7','B6','B5','B4','B3','B2','B1'];
  }

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
  //FComPort.BaudRate := br57600;
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  FComPort.Open;

  FReTry := 0;
  FErrCnt := 0;

  FReceived := True;
  FMonDeviceNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadModenYJ Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadModenYJ.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadModenYJ.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;

  Index: Integer;
  sRecvData, sChannelTM, sCommand, sState, sMin, sErr: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx, nPos: Integer;
  bExcept: Boolean;

  sBuffer: String;
begin

  //��û�� ��ġ�� ���䰪�� �ƴ� ���� ��û�� ���� ���䰪�� ����
  //JMS �� ������ ������� ��û. ����GM ���� ���� �ð����� ��� ��û�ϰ� ������ �ش� ��ġ���� Ȯ������ ����
  //���� ��û�� �ش� ��ġ�� ����̻� ������ üũ�Ҽ� ����
  bExcept := False;

  FComPort.ReadStr(sBuffer, Count);
  {
  nPos := Pos(MODEN_STX + 'L', sBuffer);
  if (nPos > 0) then
     FRecvData := Copy(sBuffer, nPos, Count)
  else  }
     FRecvData := FRecvData + sBuffer;

  nPos := Pos(MODEN_ETX, FRecvData);
  if (nPos > 0) then
  begin
     sRecvData := Copy(FRecvData, nPos - 48, nPos);

     //���� �Ϸ� ó��
    FRecvData := '';
  end
  else
  begin
    Exit;
  end;

  //sLogMsg := 'sRecvData : ' + sRecvData;
  //Global.Log.LogRetryWrite(sLogMsg);

  {
  if (Length(FRecvData) <> 48) then
  begin
    //Global.Log.LogCtrlWrite('FRecvData fail : ' + FRecvData);
    Global.Log.LogRetryWrite('<> 48');
    FRecvData := '';
    Exit;
  end;
  }
  //.L00000000000000 A.BA064000T00000 00000000000000r.
  //.L00000000000000 ABA063000T000100 00000000000000@.

  //.L00000000000000 BWXXXXXXXXXXXX00 00000000000000W.

  //.L00000000000000 BVA000000T015100 000000000000002.

  if (Copy(sRecvData, 18, 1) = '.') or (Copy(sRecvData, 18, 1) = '')then
  begin
    //Global.Log.LogCtrlWrite('FRecvData . : ' + FRecvData);
    //Global.Log.LogRetryWrite('FRecvData . : ' + FRecvData);
    sChannelTM := Copy(sRecvData, 17, 1) + Copy(sRecvData, 19, 1);
    bExcept := True;
  end
  else
  begin
    sChannelTM := Copy(sRecvData, 17, 2);
  end;

  rTeeboxInfo.StoreCd := '';
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel); //��û�� Ÿ�� ��ȣ
  rTeeboxInfo.RecvDeviceId := FChannel;
  rTeeboxInfo.TeeboxNm := Global.Teebox.GetDevicToTeeboxNm(FChannel);  //��û�� Ÿ����
  rTeeboxInfo.FloorZoneCode := '';
  rTeeboxInfo.TeeboxZoneCode := '';
  rTeeboxInfo.UseYn := '';

  if FChannel <> sChannelTM then
  begin
    sLogMsg := 'Fail No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + rTeeboxInfo.TeeboxNm + ' : ' + FSendDataTM + ' / ' + sRecvData;
    Global.Log.LogRetryWrite(sLogMsg);

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendData + '   ' + FRecvData;
  FRecvDataTM := Copy(sRecvData, 17, 16);
  //sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendDataTM + '   ' + FRecvDataTM;
  sLogMsg := 'M:' + rTeeboxInfo.TeeboxNm + '/' + FSendDataTM + '/' + FRecvDataTM;
  Global.DebugLogViewWrite(sLogMsg);

  //.L00000000000000
  //B2A056000T000100
  //000000000000003.

  sLogMsg := 'sRecvData No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + rTeeboxInfo.TeeboxNm + ' : ' + FSendDataTM + ' / ' + sRecvData;
  Global.Log.LogRetryWrite(sLogMsg);

  //2�ڸ�(28)	0: Default, 1: �����߻�, 2: CALL SW,
  //3�ڸ�(29)	0: Default, �����ڵ�
  //4�ڸ�(30)	�Ŀ���Ʈ(1:���� ON, 0:���� OFF)

  //�����ڵ�
  //1	������ �Է� �ð� �ʰ�
  //2	���� ������ �Է½ð� �ʰ�(���� ��� �Ҹ�Ǿ���)
  //3	����1(��ũ) ���� �Է½ð� �ʰ�
  //4	����2(Ƽ��) ���� �Է½ð� �ʰ�
  //5	���Լ��� �Է½ð� �ʰ�

  if bExcept = True then
  begin
    //A.BA064000T00000
    //AQA000000T02000 : call
    sCommand:= copy(sRecvData, 20, 1);
    sMin := copy(sRecvData, 21, 3);
    sState := copy(sRecvData, 29, 1);
    sErr := copy(sRecvData, 30, 1);
  end
  else
  begin
    sCommand := copy(sRecvData, 19, 1);
    sMin := copy(sRecvData, 20, 3);
    sState := copy(sRecvData, 28, 1);
    sErr := copy(sRecvData, 29, 1);
  end;

  //Global.Log.LogRetryWrite('--------');

  if sCommand <> 'A' then //����
  begin
    Global.Log.LogRetryWrite('sCommand <> A');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //Global.Log.LogRetryWrite('000000');

  sMin := Trim(sMin);
  if Length(sMin) <> 3 then
  begin
    Global.Log.LogRetryWrite('Length(sMin) <> 3');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //Global.Log.LogRetryWrite('111111');

  if isNumber(sMin) = False then
  begin
    Global.Log.LogRetryWrite('sMin isNumber');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //Global.Log.LogRetryWrite('2222');

  sState := Trim(sState);
  if sState = '' then
  sState := '0';

  sErr := Trim(sErr);
  if sErr = '' then
  sErr := '0';

  //Global.Log.LogRetryWrite('3333');

  if sState = '0' then //����
  begin
    if StrToInt(sMin) > 0 then //�����
      rTeeboxInfo.UseStatus := '1'
    else
      rTeeboxInfo.UseStatus := '0'; //��Ÿ��(����)
  end
  else if sState = '1' then //Error
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 10 + StrToInt(sErr);
    rTeeboxInfo.ErrorCd2 := sErr;
  end
  else if sState = '2' then //2: CALL SW
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 10; //2021-05-06 Call �߰�
    rTeeboxInfo.ErrorCd2 := '10';
  end
  else
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 0;
    rTeeboxInfo.ErrorCd2 := '0';
  end;

  //Global.Log.LogRetryWrite('4444');

  rTeeboxInfo.RemainMinute := StrToInt(sMin);
  rTeeboxInfo.RemainBall := 0;

  Global.Teebox.SetTeeboxInfoJMS(rTeeboxInfo);

  FErrCnt := 0;
  Global.Teebox.SetTeeboxErrorCnt(rTeeboxInfo.TeeboxNo, 'N', 5);
  SetNextMonNo;

  //Global.Log.LogRetryWrite('FReceived := True');
  FReceived := True;
end;

procedure TComThreadModenYJ.SetErrCnt(ATeeboxNo: Integer);
begin
  inc(FErrCnt);

  if FErrCnt > 5 then
  begin
    Global.Teebox.SetTeeboxErrorCnt(ATeeboxNo, 'Y', 5);
    FErrCnt := 0;
    SetNextMonNo;
  end;
end;

procedure TComThreadModenYJ.SetMonSendBuffer(ADeviceId: String);
var
  rTeeboxInfo: TTeeboxInfo;
  sSendData, sMin, sTeeboxTime: AnsiString;
  sDeviceIdR, sDeviceIdL: AnsiString;
begin
  rTeeboxInfo := Global.Teebox.GetTeeboxInfoA(ADeviceId);
  FTeeboxNo := rTeeboxInfo.TeeboxNo;

  if rTeeboxInfo.UseStatus = '7' then //��ȸ��
    rTeeboxInfo.RemainMinute := 0;

  sMin := IntToStr(rTeeboxInfo.RemainMinute);
  sTeeboxTime := StrZeroAdd(sMin, 3);

  {
  if AType = 'MON' then
  begin
    sSendData := MODEN_STX + 'L' + '00000000000000' +
                 sID + 'R' + '000' + '000' + 'T' + '0000' + 'XX' +
                 '000000000000000' + MODEN_ETX;
  end
  else }
  begin
    FSendData := MODEN_STX + 'L' + '00000000000000' +
                 ADeviceId + 'O' + sTeeboxTime + '000' + 'T' + '0000' + 'XX' +
                 '000000000000000' + MODEN_ETX;

    FSendDataTM := ADeviceId + 'O' + sTeeboxTime + '000' + 'T';
  end;

  FComPort.Write(FSendData[1], Length(FSendData));
  //FComPort.WriteStr(FSendData);
  //Global.Log.LogRetryWrite('Write : ' + FSendData);
end;

function TComThreadModenYJ.SetNextMonNo: Boolean;
var
  nTeeboxNo: Integer;
  sChannel: String;
begin

  while True do
  begin
    inc(FMonDeviceNoLast);
    if FMonDeviceNoLast > Global.Teebox.TeeboxDevicNoCnt - 1 then
      FMonDeviceNoLast := 0;

    sChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);
    nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(sChannel);
    if Global.Teebox.GetTeeboxInfoUseYn(nTeeboxNo) = 'Y' then
      Break;
  end;

end;

procedure TComThreadModenYJ.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nTeeboxNo: Integer;
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

            nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);
            sLogMsg := 'Retry COM_MON Received Fail : ' + IntToStr(nTeeboxNo) + ' / ' + FSendData;
            Global.Log.LogRetryWrite(sLogMsg);

            SetNextMonNo;

            inc(FReTry);

            if FReTry > 1 then
            begin
              FReTry := 0;
              Global.Log.LogRetryWrite('ReOpen');
              FComPort.Close;
              //FComPort.ClearBuffer(True, True);
              FComPort.Open;
              FComPort.ClearBuffer(True, True);
              //Global.Log.LogRetryWrite('ReOpen');
            end;

            Break;
          end;

        end
        else
        begin
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

      // ��û�� ���� ��ġ�� �ٸ�. ���������� ��û. �����ð��� ����
      // ����� �����ɰ�� �����ð��� ���� �߻��Ҽ� �־� ��������� �����ð� ���
      FLastExeCommand := COM_MON;
      FChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);
      SetMonSendBuffer(FChannel);
      //FChannel := FLastMonSeatDeviceNo;

      FWriteTm := now + (((1/24)/60)/60) * 1;

      FReceived := False;
      Sleep(200);  //50 �����ΰ�� retry �߻�
      //Sleep(10);  //50 �����ΰ�� retry �߻�

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadModenYJ Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
