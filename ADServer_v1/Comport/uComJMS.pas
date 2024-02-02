unit uComJMS;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadJMS = class(TThread)
  private
    FComPort: TComPort;
    //FCmdSendBufArr: array[0..BUFFER_SIZE] of TJMSCmdData;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FReceived: Boolean;
    FChannel: String;
    FTeeboxNo: Integer;

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    FLastCtlSeatNo: Integer; //���� ����Ÿ����
    //FLastMonSeatNo: Integer; //���� ����͸� Ÿ����
    FMonDeviceNoLast: Integer;
    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    FWriteTm: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetTeeboxError(AChannel: String);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetMonSendBuffer(ADeviceId: String);

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJMS }

constructor TComThreadJMS.Create;
begin

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  //FComPort.Port := 'COM11';
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.Port);
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  //FComPort.Parity.Bits := GetParity(Global.ADConfig.Parity);
  FComPort.Parity.Bits := prOdd;
  FComPort.Open;

  FReTry := 0;
  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastMonSeatNo := 1;
  FMonDeviceNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadJMS Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadJMS.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

//2020-06-08 ����3ȸ �õ��� ����ó��
procedure TComThreadJMS.SetTeeboxError(AChannel: String);
var
  rTeeboxInfo: TTeeboxInfo;
begin
  rTeeboxInfo.StoreCd := ''; //������ �ڵ�
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(AChannel); //Ÿ�� ��ȣ
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

  Global.Teebox.SetTeeboxInfoJMS(rTeeboxInfo);
end;

procedure TComThreadJMS.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;
  //SeatInfo: TSeatInfo;

  nIndex: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
  nBuffArr: array[0..4] of byte;
begin

  if FComPort.InputCount = JMS_RECV_LENGTH then
  begin
    FComPort.Read(nBuffArr, JMS_RECV_LENGTH);
    FComPort.ClearBuffer(True, False); // Input ���� clear - True
  end
  else
  begin
    Global.Log.LogWrite('��ûŸ����: ' + FChannel + ' / �ѱ��ڼ�: ' + IntToStr(Count));
    Exit;
  end;

  FRecvData := '';
  for nIndex := 0 to Length(nBuffArr) - 1 do
  begin
    if nIndex > 0 then
      FRecvData := FRecvData + ' ';

    FRecvData := FRecvData + IntToHex(nBuffArr[nIndex]);
  end;

  sLogMsg := IntToStr(FTeeboxNo) + ' / ' + FSendData + '   ' + FRecvData;
  Global.DebugLogViewWrite(sLogMsg);
  //MainForm.Memo1.Lines.Add(sLogMsg);

  FRecvData := '';
  if JMS_ETX = nBuffArr[3] then
  begin
    //  ? / ��? / ����? / ������/ BCC
    // 23 37 20 45 41
    // 23 37 A1 45 C0
    // 23 38 21 45 3F

    rTeeboxInfo.StoreCd := ''; //������ �ڵ�
    rTeeboxInfo.TeeboxNo := FTeeboxNo; //Ÿ�� ��ȣ
    rTeeboxInfo.TeeboxNm := '';  //Ÿ����
    rTeeboxInfo.FloorZoneCode := ''; //�� ���� �ڵ�
    rTeeboxInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�
    rTeeboxInfo.UseRStatus := '0'; //������� ����

    if nBuffArr[2] = $20 then //����
      rTeeboxInfo.UseStatus := '0'
    else if nBuffArr[2] = $A1 then //���
    begin
      rTeeboxInfo.UseStatus := '0';
      rTeeboxInfo.UseRStatus := '1';
    end
    else if nBuffArr[2] = $21 then //�����
      rTeeboxInfo.UseStatus := '1'
    else if nBuffArr[2] = $25 then //error: ��������
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 3;
    end
    else if nBuffArr[2] = $40 then //error: ������ -> 2020-08-28
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 2;
    end
    else if (nBuffArr[2] = $41) or (nBuffArr[2] = $45) then //error: ������
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 2;
    end
    // 11/20 65 �߰�
    else if (nBuffArr[2] = $60) or (nBuffArr[2] = $65) then //error: �����̻�
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 4;
    end
    else if nBuffArr[2] = $61 then //error: ���ɸ�?
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 1;
    end
    else if nBuffArr[2] = $80 then //error: ��ſ���?
    begin
      rTeeboxInfo.UseStatus := '9';
      //rSeatInfo.ErrorCd := IntToHex(nBuffArr[2]);
      rTeeboxInfo.ErrorCd := 9;
    end
    else
    begin
      rTeeboxInfo.UseStatus := '9';
      //rSeatInfo.ErrorCd := IntToHex(nBuffArr[2]);
      rTeeboxInfo.ErrorCd := 0; //Ȯ�ξʵ� ����

      sLogMsg := 'Error Code: ' + intToStr(FTeeboxNo) + ' / ' + IntToHex(nBuffArr[2]);
      Global.Log.LogWrite(sLogMsg);
    end;

    rTeeboxInfo.UseYn := '';        //��� ����
    Ball := IntToHex(nBuffArr[1]);
    rTeeboxInfo.RemainBall := StrToInt(Ball);

    Global.Teebox.SetTeeboxInfoJMS(rTeeboxInfo);
  end;
  {
  else
  begin
    Exit;
  end;
  }
  inc(FMonDeviceNoLast);
  if FMonDeviceNoLast > Global.Teebox.TeeboxDevicNoCnt - 1 then
    FMonDeviceNoLast := 0;

  FReceived := True;
end;

procedure TComThreadJMS.SetMonSendBuffer(ADeviceId: String);
var
  nDataArr: array[0..10] of byte;
  nIndex: Integer;
  sTeeboxNo, sTeeboxTime, sCtl: String;
  sTeeboxNo1, sTeeboxNo2, sTeeboxTm1, sTeeboxTm2, sLogMsg: String;
  btBcc: byte;
  rTeeboxInfo: TTeeboxInfo;
begin

  rTeeboxInfo := Global.Teebox.GetTeeboxInfoA(ADeviceId);
  FTeeboxNo := rTeeboxInfo.TeeboxNo;

  // 4E 00 01 FF FF FF FF 80 00 45 F0
  //sSeatNo := StrZeroAdd(IntToStr(rSeatInfo.SeatNo), 4);
  sTeeboxNo := StrZeroAdd(ADeviceId, 4);
  sTeeboxNo1 := Copy(sTeeboxNo, 1, 2);
  sTeeboxNo2 := Copy(sTeeboxNo, 3, 2);
  //sCtl := '4E';

  if rTeeboxInfo.UseStatus = '7' then
    rTeeboxInfo.RemainMinute := 0;

  sTeeboxTime := '';
  if rTeeboxInfo.RemainMinute > 0 then
  begin
    sTeeboxTime := StrZeroAdd(IntToStr(rTeeboxInfo.RemainMinute), 4);
    sTeeboxTm1 := Copy(sTeeboxTime, 1, 2);
    sTeeboxTm2 := Copy(sTeeboxTime, 3, 2);
  end;

  FillChar(nDataArr, sizeof(nDataArr), 0);

  if (sTeeboxNo2 = '85') or (sTeeboxNo2 = '88') then
    nDataArr[0] := $4F
  else
    nDataArr[0] := $4E;

  nDataArr[1] := StrToInt('$' + sTeeboxNo1);
  nDataArr[2] := StrToInt('$' + sTeeboxNo2);

  if rTeeboxInfo.RemainMinute > 0 then
  begin
    nDataArr[3] := StrToInt('$' + sTeeboxTm1);
    nDataArr[4] := StrToInt('$' + sTeeboxTm2);
  end
  else
  begin
    nDataArr[3] := $FF;
    nDataArr[4] := $FF;
  end;

  nDataArr[5] := $FF;
  nDataArr[6] := $FF;

  if rTeeboxInfo.RemainMinute > 0 then
    nDataArr[7] := $40
  else
    nDataArr[7] := $80;

  nDataArr[8] := 0;
  nDataArr[9] := $45;
  //nData_Arr[10] := $FF;

  btBcc := $00;
  for nIndex := 0 to 9 do
  begin
    btBcc := btBcc + byte(nDataArr[nIndex]);
  end;
  btBcc := 256 - btBcc;
  nDataArr[10] := btBcc;

  for nIndex := 0 to 10 do
  begin
    if nIndex > 0 then
      FSendData := FSendData + ' ';

    FSendData := FSendData + IntToHex(nDataArr[nIndex]);
  end;

  FComPort.Write(nDataArr, 11);

  //sLogMsg := IntToStr(rSeatInfo.SeatNo) + ' / ' + FSendData;
  //MainForm.Memo1.Lines.Add(sLogMsg);
end;

procedure TComThreadJMS.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
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

            nTeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);
            sLogMsg := 'Retry COM Received Fail : ' + IntToStr(nTeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
            Global.Log.LogRetryWrite(sLogMsg);

            FRecvData := '';

            FComPort.Close;
            FComPort.Open;
            Global.Log.LogRetryWrite('ReOpen');

            inc(FReTry);
            // 2ȸ �õ��� ����ó��
            if FReTry > 2 then
            begin
              FReTry := 0;

              inc(FMonDeviceNoLast);
              if FMonDeviceNoLast > Global.Teebox.TeeboxDevicNoCnt - 1 then
                FMonDeviceNoLast := 0;

              SetTeeboxError(FChannel);
              //FCtlChannel := FChannel;
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

      // ���¿�û ����� ������ ����. �����ð��� ����
      // ����� �����ɰ�� �����ð��� ���� �߻��Ҽ� �־� ��������� �����ð� ���
      FLastExeCommand := COM_MON;
      FChannel := Global.Teebox.GetTeeboxDevicdNoToDevic(FMonDeviceNoLast);
      SetMonSendBuffer(FChannel);
      //FChannel := FLastMonSeatDeviceNo;

      FWriteTm := now + (((1/24)/60)/60) * 3;

      FReceived := False;
      Sleep(50);  //50 �����ΰ�� retry �߻�

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadJMS Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);

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
