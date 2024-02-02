unit uSeatControlTcp;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type
  TControlMonThread = class(TThread)
  private
    FIdTCPClient: TIdTCPClient;
    FCmdSendBufArr: array[0..COM_CTL_MAX] of AnsiString;

    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    FLastCtlSeatNo: Integer; //���� ����Ÿ����
    //FLastMonSeatNo: Integer; //���� ����͸� Ÿ����
    FLastMonSeatDeviceNo: Integer; //���� ����͸� Ÿ����
    FLastExeCommand: Integer; //���� ��Ŷ ���� ���
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    //procedure SetCmdSendBuffer(ASendData: AnsiString);
    procedure SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TControlMonThread }

constructor TControlMonThread.Create;
var
  sLogMsg: String;
begin
  FIdTCPClient := TIdTCPClient.Create(nil);
  FIdTCPClient.Disconnect;

  FIdTCPClient.Host := '127.0.0.1';
  FIdTCPClient.Port := 15002;

  FIdTCPClient.ConnectTimeout := 10000;
  FIdTCPClient.ReadTimeout := 10000;

  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  //FLastMonSeatNo := 1;
  FLastMonSeatDeviceNo := 0;

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TControlMonThread.Destroy;
begin
  FIdTCPClient.Disconnect;
  FIdTCPClient.Free;
  inherited;
end;

//procedure TControlMonThread.SetCmdSendBuffer(ASendData: AnsiString);
procedure TControlMonThread.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sSeatTime, sSeatBall: AnsiString;
begin
  sSeatTime := StrZeroAdd(ASeatTime, 4);
  sSeatBall := StrZeroAdd(ASeatBall, 4);

  sSendData := ADeviceId + AType + sSeatTime + sSeatBall;
  sBcc := GetBccCtl('05', sSendData, '04');
  sSendData := '' + sSendData + '' + sBcc;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > COM_CTL_MAX then
    FLastCmdDataIdx := 0;
end;

procedure TControlMonThread.Execute;
var
  bControlMode: Boolean;
  sChannelTemp, sLogMsg: String;
  sSendData, sRecvData: AnsiString;
  rSeatInfo: TTeeboxInfo;
begin
  inherited;

  while not Terminated do
  begin
    try
      if not FIdTCPClient.Connected then
      begin
        FIdTCPClient.Disconnect;
        FIdTCPClient.Connect();
      end;

      bControlMode := False;
      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //������� �������� ������
        bControlMode := True;

        sChannelTemp := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);
        sSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FIdTCPClient.IOHandler.Write(sSendData);
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        //1	2	3	4	5	6
        //	0	1	1		6
        //01	30	31	31	04	36
        //sChannelTemp := Global.Seat.GetSeatNoToDevic(FLastMonSeatNo);
        sChannelTemp := Global.Teebox.GetTeeboxDevicdNoToDevic(FLastMonSeatDeviceNo);
        sSendData := '' + sChannelTemp + '6';
        FIdTCPClient.IOHandler.Write(sSendData);
      end;

      Sleep(10);

      //���� �ÿ��� ���̸�ŭ ���� �� ������ ���������� ���� �߸��Ǿ�
      //���з� ������ ��� ���̷� ������ ���ϰ��� ���� �ʴ´�.
      sRecvData := FIdTCPClient.IOHandler.ReadString(16);
      //memo1.lines.Add(RecvData);

      //��û�� Ÿ���� �����̸�
      if sChannelTemp = Copy(sRecvData, 2, 3) then
      begin
        //1	2	3	4	5	6	7	8	9	10 11	12 13	14 15	16
        //	0	9	1	3	@	0	0	5	 4	9	 9	2	 5		 2

        rSeatInfo.StoreCd := ''; //������ �ڵ�
        rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(sChannelTemp); //Ÿ�� ��ȣ
        rSeatInfo.TeeboxNm := '';  //Ÿ����
        rSeatInfo.FloorZoneCode := ''; //�� ���� �ڵ�
        rSeatInfo.TeeboxZoneCode := '';  //���� ���� �ڵ�

        if copy(sRecvData, 6, 1) = '@' then //����
        begin
          if copy(sRecvData, 5, 1) = '4' then //��Ÿ��
            rSeatInfo.UseStatus := '0'
          else if copy(sRecvData, 5, 1) = '3' then //�����
            rSeatInfo.UseStatus := '1'
          else if copy(sRecvData, 5, 1) = '2' then //������: S0 ���� �����ϴ°��
            rSeatInfo.UseStatus := '0'
          else
            rSeatInfo.UseStatus := '0';
        end
        else if copy(sRecvData, 6, 1) = 'B' then //����
          rSeatInfo.UseStatus := '9'
        else //3C
          rSeatInfo.UseStatus := '9';

        rSeatInfo.UseYn := '';        //��� ����
        rSeatInfo.RemainBall := StrToInt(copy(sRecvData, 11, 4));
        rSeatInfo.RemainMinute := StrToInt(copy(sRecvData, 7, 4));
        //BCC := copy(Buff, 16, 1);

        Global.Teebox.SetTeeboxInfo(rSeatInfo);

        //if (FLastMonSeatNo = 1) or (FLastMonSeatNo = 72) then
        //  MainForm.LogView(sRecvData);
      end
      else
      begin
        //memo1.lines.Add('��ûŸ����: ' + Global.Seat.GetDevicToSeatNo(sChannelTemp) +
        //                ' / ����Ÿ����: ' + Global.Seat.GetDevicToSeatNo(Copy(sRecvData, 2, 3)) );
      end;

      if bControlMode = False then
      begin
        //while True do
        begin
          {
          inc(FLastMonSeatNo);
          if FLastMonSeatNo > Global.Seat.SeatLastNo then
            FLastMonSeatNo := 1;

          if Global.Seat.GetSeatInfoUseYn(FLastMonSeatNo) = 'Y' then
            Break;
            }
          inc(FLastMonSeatDeviceNo);
          if FLastMonSeatDeviceNo > Global.Teebox.TeeboxDevicNoCnt - 1 then
            FLastMonSeatDeviceNo := 0;
        end;
      end
      else
      begin
        if FLastCmdDataIdx <> FCurCmdDataIdx then
        begin
          inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
          if FCurCmdDataIdx > COM_CTL_MAX then
            FCurCmdDataIdx := 0;
        end;
      end;

      Sleep(10);

      //FIdTCPClient.Disconnect;

    except
      on e: Exception do
      begin
        sLogMsg := 'TControlMonThread Error : ' + e.Message;
        MainForm.LogView(sLogMsg);
        FIdTCPClient.Disconnect;

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
