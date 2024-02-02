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
    FReceived: Boolean;

    FIndex: Integer;
    FFloorCd: String; //��

    FTeeboxNoStart: Integer; //���� Ÿ����ȣ
    FTeeboxNoEnd: Integer; //���� Ÿ����ȣ
    FTeeboxNoLast: Integer; //������ ��û Ÿ����ȣ

    FWriteTm: TDateTime;
    FTeeboxInfo: TTeeboxInfo;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetMonSendBuffer;

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

  FReTry := 0;

  FReceived := True;
  FTeeboxNoLast := 0;
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

procedure TComThreadModenYJ.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
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

  Global.Log.LogWrite('TComThreadModen ComPortSetting : ' + FFloorCd);
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
  rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo; //��û�� Ÿ�� ��ȣ
  rTeeboxInfo.RecvDeviceId := FTeeboxInfo.DeviceId;
  rTeeboxInfo.TeeboxNm := FTeeboxInfo.TeeboxNm;  //��û�� Ÿ����
  rTeeboxInfo.FloorZoneCode := '';
  rTeeboxInfo.TeeboxZoneCode := '';
  rTeeboxInfo.UseYn := '';

  if FTeeboxInfo.DeviceId <> sChannelTM then
  begin
    sLogMsg := 'Fail No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + rTeeboxInfo.TeeboxNm + ' : ' + FSendDataTM + ' / ' + sRecvData;
    Global.Log.LogReadMulti(FIndex, sLogMsg);

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  //sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendData + '   ' + FRecvData;
  FRecvDataTM := Copy(sRecvData, 17, 16);
  //sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendDataTM + '   ' + FRecvDataTM;
  sLogMsg := 'M:' + rTeeboxInfo.TeeboxNm + '/' + FSendDataTM + '/' + FRecvDataTM;
  Global.DebugLogMainViewMulti(FIndex, sLogMsg);

  //.L00000000000000
  //B2A056000T000100
  //000000000000003.

  sLogMsg := 'sRecvData No: ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm: ' + rTeeboxInfo.TeeboxNm + ' : ' + FSendDataTM + ' / ' + sRecvData;
  Global.Log.LogReadMulti(FIndex, sLogMsg);

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

  if sCommand <> 'A' then //����
  begin
    Global.Log.LogReadMulti(FIndex, 'sCommand <> A');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  sMin := Trim(sMin);
  if Length(sMin) <> 3 then
  begin
    Global.Log.LogReadMulti(FIndex, 'Length(sMin) <> 3');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  if isNumber(sMin) = False then
  begin
    Global.Log.LogReadMulti(FIndex, 'sMin isNumber');

    FRecvData := '';
    SetErrCnt(rTeeboxInfo.TeeboxNo);
    FReceived := True;
    Exit;
  end;

  sState := Trim(sState);
  if sState = '' then
  sState := '0';

  sErr := Trim(sErr);
  if sErr = '' then
  sErr := '0';

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
  end
  else if sState = '2' then //2: CALL SW
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 10; //2021-05-06 Call �߰�
  end
  else
  begin
    rTeeboxInfo.UseStatus := '9';
    rTeeboxInfo.ErrorCd := 0;
  end;

  rTeeboxInfo.RemainMinute := StrToInt(sMin);
  rTeeboxInfo.RemainBall := 0;

  Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

  Global.Teebox.SetTeeboxErrorCntAD(FIndex, rTeeboxInfo.TeeboxNo, 'N', 10);
  SetNextMonNo;

  FReceived := True;
end;

procedure TComThreadModenYJ.SetErrCnt(ATeeboxNo: Integer);
begin
  Global.Teebox.SetTeeboxErrorCntAD(FIndex, ATeeboxNo, 'Y', 10);
  SetNextMonNo;
end;

procedure TComThreadModenYJ.SetMonSendBuffer;
var
  sMin, sTeeboxTime: AnsiString;
begin

  FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);

  if FTeeboxInfo.UseStatus = '7' then //��ȸ��
    sMin := '0'
  else
    sMin := IntToStr(FTeeboxInfo.RemainMinute);

  sTeeboxTime := StrZeroAdd(sMin, 3);

  {
  //���¿�û ����
  sSendData := MODEN_STX + 'L' + '00000000000000' +
               sID + 'R' + '000' + '000' + 'T' + '0000' + 'XX' +
               '000000000000000' + MODEN_ETX;
  }

  FSendData := MODEN_STX + 'L' + '00000000000000' +
               FTeeboxInfo.DeviceId + 'O' + sTeeboxTime + '000' + 'T' + '0000' + 'XX' +
               '000000000000000' + MODEN_ETX;

  FSendDataTM := FTeeboxInfo.DeviceId + 'O' + sTeeboxTime + '000' + 'T';

  FComPort.Write(FSendData[1], Length(FSendData));
end;

function TComThreadModenYJ.SetNextMonNo: Boolean;
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

procedure TComThreadModenYJ.Execute;
var
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

            sLogMsg := 'Retry COM_MON Received Fail - No:' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
            Global.Log.LogWriteMulti(FIndex, sLogMsg);

            SetNextMonNo;

            inc(FReTry);

            if FReTry > 1 then
            begin
              FReTry := 0;
              Global.Log.LogWriteMulti(FIndex, 'ReOpen');
              FComPort.Close;
              FComPort.Open;
              FComPort.ClearBuffer(True, True);
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

      // ��û�� ���� ��ġ�� �ٸ�. ���������� ��û. �����ð��� ����
      // ����� �����ɰ�� �����ð��� ���� �߻��Ҽ� �־� ��������� �����ð� ���
      SetMonSendBuffer;

      FWriteTm := now + (((1/24)/60)/60) * 1;

      FReceived := False;
      Sleep(200);  //50 �����ΰ�� retry �߻�

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
