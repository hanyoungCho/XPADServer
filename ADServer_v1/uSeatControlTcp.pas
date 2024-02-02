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

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    FLastCtlSeatNo: Integer; //최종 제어타석기
    //FLastMonSeatNo: Integer; //최종 모니터링 타석기
    FLastMonSeatDeviceNo: Integer; //최종 모니터링 타석기
    FLastExeCommand: Integer; //최종 패킷 수행 펑션
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
      begin //대기중인 제어명령이 있으면
        bControlMode := True;

        sChannelTemp := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);
        sSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FIdTCPClient.IOHandler.Write(sSendData);
      end;

      //장치에 데이터값을 요청하는 부분
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

      //성공 시에는 길이만큼 받을 수 있지만 전문오류나 값이 잘못되어
      //실패로 떨어질 경우 길이로 받으면 리턴값이 오지 않는다.
      sRecvData := FIdTCPClient.IOHandler.ReadString(16);
      //memo1.lines.Add(RecvData);

      //요청한 타석기 정보이면
      if sChannelTemp = Copy(sRecvData, 2, 3) then
      begin
        //1	2	3	4	5	6	7	8	9	10 11	12 13	14 15	16
        //	0	9	1	3	@	0	0	5	 4	9	 9	2	 5		 2

        rSeatInfo.StoreCd := ''; //가맹점 코드
        rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(sChannelTemp); //타석 번호
        rSeatInfo.TeeboxNm := '';  //타석명
        rSeatInfo.FloorZoneCode := ''; //층 구분 코드
        rSeatInfo.TeeboxZoneCode := '';  //구역 구분 코드

        if copy(sRecvData, 6, 1) = '@' then //정상
        begin
          if copy(sRecvData, 5, 1) = '4' then //빈타석
            rSeatInfo.UseStatus := '0'
          else if copy(sRecvData, 5, 1) = '3' then //사용중
            rSeatInfo.UseStatus := '1'
          else if copy(sRecvData, 5, 1) = '2' then //예약중: S0 으로 제어하는경우
            rSeatInfo.UseStatus := '0'
          else
            rSeatInfo.UseStatus := '0';
        end
        else if copy(sRecvData, 6, 1) = 'B' then //고장
          rSeatInfo.UseStatus := '9'
        else //3C
          rSeatInfo.UseStatus := '9';

        rSeatInfo.UseYn := '';        //사용 여부
        rSeatInfo.RemainBall := StrToInt(copy(sRecvData, 11, 4));
        rSeatInfo.RemainMinute := StrToInt(copy(sRecvData, 7, 4));
        //BCC := copy(Buff, 16, 1);

        Global.Teebox.SetTeeboxInfo(rSeatInfo);

        //if (FLastMonSeatNo = 1) or (FLastMonSeatNo = 72) then
        //  MainForm.LogView(sRecvData);
      end
      else
      begin
        //memo1.lines.Add('요청타석기: ' + Global.Seat.GetDevicToSeatNo(sChannelTemp) +
        //                ' / 응답타석기: ' + Global.Seat.GetDevicToSeatNo(Copy(sRecvData, 2, 3)) );
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
          inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
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
          //wMonDelayTime := 10000; //10000 = 10초
          //g_bSMServerSocketError := True;
        end;
      end;
    end;
  end;
end;

end.
