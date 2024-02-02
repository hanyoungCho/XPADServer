unit uComMagicShot;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadMagicShot = class(TThread)
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
    FFloorCd: String; //층

    FTeeboxNoStart: Integer; //시작 타석번호
    FTeeboxNoEnd: Integer; //종료 타석번호
    FTeeboxNoLast: Integer; //마지막 요청 타석번호

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호

    FLastExeCommand: Integer; //최종 패킷 수행 펑션

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

{ TComThreadMagicShot }

constructor TComThreadMagicShot.Create;
begin
  FReTry := 0;
  FCtlReTry := 0;

  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadMagicShot Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadMagicShot.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadMagicShot.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
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

  Global.Log.LogWrite('TComThreadMagicShot ComPortSetting : ' + IntToStr(AIndex));
end;

procedure TComThreadMagicShot.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sLogMsg: string;
  sRecvData, sCode, sErr: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx: Integer;
  sSendData: AnsiString;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Pos(ZOOM_STX, FRecvData) = 0 then
    Exit;

  if Pos(ZOOM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(ZOOM_STX, FRecvData);
  nEtx := Pos(ZOOM_ETX, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
  Global.DebugLogFromViewMulti(FIndex, sLogMsg);

  if FChannel <> Copy(FRecvData, 2, 2) then
  begin
    sLogMsg := 'FChannel Fail - No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel + ' / ' + FRecvData;
    Global.Log.LogReadMulti(FIndex, sLogMsg);

    FRecvData := '';
    Exit;
  end;

  sCode := copy(FRecvData, 4, 1);
  if (sCode <> 'A') or (sCode <> 'E') or (sCode <> 'I') then
  begin
    sLogMsg := 'Cmd Fail - No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FChannel + ' / ' + FRecvData;
    Global.DebugLogFromViewMulti(FIndex, sLogMsg);

    FRecvData := '';
    Exit;
  end;

  //  1	2	3	 4	5	6	7	8	9	10 11	12 13	14 15
  //&h2 0 9 'A' 1 2 3 3 2 1  #1 #2  0  # &h3  'A' : 현재 진행중인 Time & Ball개수 를 받음
  //&h2 0 9 'E' 0 # &h3                       'E' : 타석이타석이 종료상태이다
  //&h2 0 9 'I' 0 # &h3                       'I' : 타석이타석이 최초최초 기동상태이다기동상태이다 (전원이전원이 들어오고들어오고 통신을통신을 받지받지 않았다않았다)

  rTeeboxInfo.StoreCd := ''; //가맹점 코드
  rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo;
  rTeeboxInfo.RecvDeviceId := FChannel;
  rTeeboxInfo.TeeboxNm := '';  //타석명
  rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
  rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드

  // ERR
  // '1' Counter Sensor Error
  // '2' Low Sensor Error
  // '3' Tee Sensor Error
  // '4' Supply Sensor Error
  // '5' Caddy Detect Error

  if (sCode = 'A') then
  begin
    sErr := copy(FRecvData, 13, 1);
    if sErr <> '0' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 10 + StrToInt(sErr);
      rTeeboxInfo.ErrorCd2 := sCode;

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / ' + sErr;
      Global.Log.LogReadMulti(FIndex, sLogMsg);
    end
    else
      rTeeboxInfo.UseStatus := '1';

    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 8, 3));;
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 5, 3));;
  end
  else if (sCode = 'E') or (sCode = 'I') then
  begin
    sErr := copy(FRecvData, 5, 1);
    if sErr <> '0' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 10 + StrToInt(sErr);
      rTeeboxInfo.ErrorCd2 := sCode;

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / ' + sErr;
      Global.Log.LogReadMulti(FIndex, sLogMsg);
    end
    else
      rTeeboxInfo.UseStatus := '0';

    rTeeboxInfo.RemainBall := 0;
    rTeeboxInfo.RemainMinute := 0;
  end;

  rTeeboxInfo.UseYn := '';        //사용 여부
  rTeeboxInfo.RecvData := FRecvData;
  rTeeboxInfo.SendData := FSendData;

  Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

  if FLastExeCommand = COM_MON then
  begin
    Global.Teebox.SetTeeboxErrorCntAD(FIndex, rTeeboxInfo.TeeboxNo, 'N', 10);
    SetNextMonNo;
  end
  else
  begin
    if FLastCmdDataIdx <> FCurCmdDataIdx then
    begin
      inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
      if FCurCmdDataIdx > BUFFER_SIZE then
        FCurCmdDataIdx := 0;
    end;
  end;

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadMagicShot.SetCmdSendBuffer(ADeviceId, ASeatTime, ASeatBall, AType: String);
var
  sSendData: AnsiString;
  sSeatTime, sSeatBall: AnsiString;
begin
  sSeatTime := StrZeroAdd(ASeatTime, 3);
  sSeatBall := StrZeroAdd(ASeatBall, 3);

  if sSeatTime = '000' then
    sSendData := ZOOM_STX + ADeviceId + 'E' + '&' + ZOOM_ETX
  else
    sSendData := ZOOM_STX + ADeviceId + 'S' + sSeatTime + sSeatBall + '01' + '&' + ZOOM_ETX;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadMagicShot.SetNextMonNo: Boolean;
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

procedure TComThreadMagicShot.Execute;
var
  bControlMode: Boolean;
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
                inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
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
      begin //대기중인 제어명령이 있으면
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 2);

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToFloorTeeboxInfo(FFloorCd, FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        //  1	2	3	 4	5	  6
        //&h2 0 9 'R' & &h3

        FLastExeCommand := COM_MON;
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
        FChannel := FTeeboxInfo.DeviceId;

        FSendData := ZOOM_STX + FChannel + 'R' + '&' + ZOOM_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;
      end;

      FReceived := False;
      Sleep(100);  //50 이하인경우 retry 발생

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadMagicShot Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
