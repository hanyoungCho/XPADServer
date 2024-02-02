unit uComJehu50A;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type

  TComThreadJehu50A = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;

    //2020-12-03 제어3회 시도후 에러처리
    FCtlReTry: Integer;
    //FCtlChannel: String;

    FReceived: Boolean;
    FChannel: String;
    FFloor: String;

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호

    FIndex: Integer;
    FTeeboxNoStart: Integer;
    FTeeboxNoEnd: Integer;
    FTeeboxNoLast: Integer;

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
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);

    //procedure SetTeeboxError(AChannel: String);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJeu50A }

constructor TComThreadJehu50A.Create;
begin

  //상태 7byte
  // 1	2	 3	4	 5	6	 7  / 100번 타석 데이타 요청, ENQ(1)+ID(3)+BCC(2)+ETX
  //05	1	 0  0	 9  1 03
  //05 31	30 30	39 31	03

  //응답 17byte
  //         100번,    30분,       200개, STX(1)+ID(3)+잔여시간(3)+잔여볼(4)+시작(1)+종료(1)+에러(1)+BCC(2)+ETX(1)
  // 1,	 2	 3	4,  5	 6	7,	8	 9 10 11, 12 13 14, 15 16, 17
  //02,	 1   0	0,  0  3	0,	0	 2	0	 0,	 0  0	 0,  8  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30, 38 36, 03

  //제어 15byte
  //        100번,     30분,   잔여200개, STX(1)+ID(3)+시간(3)+잔여볼(4)+종료(1)+BCC(2)+ETX
  // 1,	 2	 3	4,  5	 6  7,	8	 9 10 11, 12 13 14 15
  //02,  1   0	0,  0  3  0,	0	 2	0	 0,  0, 3  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30,  0,33 36, 03

  FReTry := 0;
  FCtlReTry := 0;

  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FRecvData := '';

  Global.Log.LogWriteMulti(FIndex, 'TComThreadJehu50A Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadJehu50A.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadJehu50A.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
begin
  FTeeboxNoStart := ATeeboxNoStart;
  FTeeboxNoEnd := ATeeboxNoEnd;
  FTeeboxNoLast := FTeeboxNoStart;
  FIndex := AIndex;
  FFloor := AFloorCd;

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(APort);
  FComPort.BaudRate := GetBaudrate(ABaudRate);
  FComPort.Open;

  Global.Log.LogWrite('TComThreadJehu50A ComPortSetting : ' + IntToStr(AIndex));
end;

procedure TComThreadJehu50A.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;

  Index: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  if Count < JEU_RECV_LENGTH_17 then
  begin
    FRecvData := FRecvData + sRecvData;

    if copy(FRecvData, 1, 1) = JEU_NAK then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : 15 수신에러' + IntToStr(FLastExeCommand) + ' - No:' +
                          IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    if copy(FRecvData, 1, 1) = JEU_SYN then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : 16 수신에러' + IntToStr(FLastExeCommand) + ' - No:' +
                          IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    // 타석종료처리시 응답 확인- 2021-04-16 추가
    if copy(FRecvData, 1, 1) = JEU_CTL_FIN then //제어 응답
    begin
      sLogMsg := 'FRecvData CTL Succese ' + IntToStr(FLastExeCommand) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.Log.LogReadMulti(FIndex, sLogMsg);

      rTeeboxInfo.StoreCd := ''; //가맹점 코드
      //rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel); //타석 번호
      //rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, FChannel);
      rTeeboxInfo.TeeboxNm := '';  //타석명
      rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
      rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드
      rTeeboxInfo.UseYn := '';        //사용 여부
      rTeeboxInfo.RemainBall := StrToInt(copy(FSendData, 8, 4));
      rTeeboxInfo.RemainMinute := StrToInt(copy(FSendData, 5, 3));

      if rTeeboxInfo.RemainMinute > 0 then
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0';

      Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

      if FLastCmdDataIdx <> FCurCmdDataIdx then
      begin
        inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
        if FCurCmdDataIdx > BUFFER_SIZE then
          FCurCmdDataIdx := 0;
      end;

      sLogMsg := StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
      Global.DebugLogMainViewMulti(FIndex, sLogMsg);

      FRecvData := '';
      FReceived := True;

      Exit;
    end;

    if copy(FRecvData, 1, 1) <> JEU_STX then
    begin
      Global.Log.LogReadMulti(FIndex, 'FRecvData fail : STX 02 Error ' + IntToStr(FLastExeCommand) + ' - No:' +
                          IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData);
      FRecvData := '';
      Exit;
    end;

    if Length(FRecvData) > JEU_RECV_LENGTH_17 then
    begin
      Global.Log.LogReadMulti(FIndex, 'Over : ' + FRecvData);
      FRecvData := '';
      Exit;
    end
    else if Length(FRecvData) < JEU_RECV_LENGTH_17 then
    begin
      Exit;
    end;

  end
  else if Count = JEU_RECV_LENGTH_17 then
  begin
    FRecvData := sRecvData;
  end
  else
  begin
    Global.Log.LogReadMulti(FIndex, '요청타석기- No:' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm:' + FTeeboxInfo.TeeboxNm + ' / 총글자수: ' + IntToStr(Count) + ' / ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if FChannel = Copy(FRecvData, 2, 3) then
  begin
    //         100번,    30분,       200개, STX(1)+ID(3)+잔여시간(3)+잔여볼(4)+시작(1)+종료(1)+에러(1)+BCC(2)+ETX(1)
    // 1,	 2	 3	4,  5	 6	7,	8	 9 10 11, 12 13 14, 15 16, 17
    //02,	 1   0	0,  0  3	0,	0	 2	0	 0,	 0  0	 0,  8  6, 03
    //02, 31	30 30, 30 33 30, 30 32 30 30, 30 30 30, 38 36, 03

    //시작 0:OFF, 1:ON
    //종료 0:자동동작중, 1:수동동작중, 9:종료(대기상태)
    //에러 0:에러없음, 1:티업센서이상, 2:타코센서이상, 3:버퍼센서이상, 4:장치없음?

    rTeeboxInfo.StoreCd := ''; //가맹점 코드
    //rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(FChannel); //타석 번호
    rTeeboxInfo.TeeboxNm := '';  //타석명
    rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
    rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드
    //001 036 0101 000 02
    //002 000 0000 090 01

    if copy(FRecvData, 14, 1) = '0' then //정상
    begin
      if copy(FRecvData, 13, 1) = '9' then //시작:종료
        rTeeboxInfo.UseStatus := '0'
      else if copy(FRecvData, 13, 1) = '0' then //사용중
        rTeeboxInfo.UseStatus := '1'
      else
        rTeeboxInfo.UseStatus := '0';
    end
    else // 1,2,3 장비Error
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 0;

      sLogMsg := 'Error Code: ' + intToStr(rTeeboxInfo.TeeboxNo) + ' / ' + copy(FRecvData, 14, 1);
      Global.Log.LogReadMulti(FIndex, sLogMsg);
    end;

    if isNumber(copy(FRecvData, 5, 7)) = False then
    begin
      sLogMsg := 'Int Error : ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
      Global.Log.LogReadMulti(FIndex, sLogMsg);
      FRecvData := '';
      Exit;
    end;

    rTeeboxInfo.UseYn := '';        //사용 여부
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 8, 4));
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 5, 3));

    Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

    sLogMsg := 'Nm:' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);
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

  if FLastExeCommand = COM_CTL then
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

procedure TComThreadJehu50A.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime, sTeeboxBall: AnsiString;
begin
  sTeeboxTime := StrZeroAdd(ATeeboxTime, 3);

  //제우테크 6.0A 인경우 현재볼수는 사용횟수 이므로 제어시 볼다시 셋팅
  //sSeatBall := StrZeroAdd(ASeatBall, 4);
  sTeeboxBall := '9999';

  //        100번,     30분,   잔여200개, STX(1)+ID(3)+시간(3)+잔여볼(4)+종료(1)+BCC(2)+ETX
  // 1,	 2	 3	4,  5	 6  7,	8	 9 10 11, 12, 13 14, 15
  //02,  1   0	0,  0  3  0,	0	 2	0	 0,  0,  3  6, 03
  //02, 31	30 30, 30 33 30, 30 32 30 30, 30, 33 36, 03

  if sTeeboxTime = '000' then
    sSendData := ADeviceId + sTeeboxTime + '0000' + '9'
  else
    sSendData := ADeviceId + sTeeboxTime + sTeeboxBall + '0';

  sBcc := GetBccJehu2Byte(sSendData);

  sSendData := JEU_STX + sSendData + sBcc + JEU_ETX;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadJehu50A.SetNextMonNo: Boolean;
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
//2020-12-03 제어3회 시도후 에러처리
procedure TComThreadJehu50A.SetTeeboxError(AChannel: String);
var
  rSeatInfo: TTeeboxInfo;
begin
  rSeatInfo.StoreCd := ''; //가맹점 코드
  rSeatInfo.TeeboxNo := Global.Teebox.GetDevicToTeeboxNo(AChannel); //타석 번호
  rSeatInfo.RecvDeviceId := AChannel;
  rSeatInfo.TeeboxNm := '';  //타석명
  rSeatInfo.FloorZoneCode := ''; //층 구분 코드
  rSeatInfo.TeeboxZoneCode := '';  //구역 구분 코드
  rSeatInfo.UseStatus := '9';
  rSeatInfo.UseYn := '';        //사용 여부
  rSeatInfo.RemainBall := 0;
  rSeatInfo.RemainMinute := 0;
  rSeatInfo.ErrorCd := 8; //통신이상

  Global.Teebox.SetTeeboxInfoAD(rSeatInfo);
end;
}

procedure TComThreadJehu50A.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nSeatNo: Integer;
  rSeatInfo: TTeeboxInfo; //배정시간 변경확인용
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
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(FIndex) + ' / ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
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
          begin
            {
            nSeatNo := Global.Teebox.GetDevicToTeeboxNo(FChannel);
            sLogMsg := 'Received True : ' + IntToStr(FIndex) + ' / ' + IntToStr(nSeatNo) + ' / ' + FSendData + ' / ' + FRecvData;
            Global.Log.LogWriteMulti(FIndex, sLogMsg);
            }
            FCtlReTry := 0;
          end;

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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 3);

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToFloorTeeboxInfo(FFloor, FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);

        { 2021-04-16 종료처리시 응답 '' , JEU_CTL_FIN
        // 타석종료처리시 응답 없음
        if Copy(FSendData, 12, 1) = '9' then
        begin

          //FWriteTm := now + (((1/24)/60)/60) * 1;
          FWriteTm := now + (((1/24)/60)/60) * 0.1;

          while True do
          begin
            if now > FWriteTm then
            begin
              Break;
            end;
          end;

          sBcc := GetBccJehu2Byte(FChannel);
          FSendData := JEU_ENQ + FChannel + sBcc + JEU_ETX;
          FComPort.Write(FSendData[1], Length(FSendData));
          Global.Log.LogCtrlWriteA6001(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);
        end;
        }
        FWriteTm := now + (((1/24)/60)/60) * 1; //5

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        // 1	2	 3	4	 5	6	 7  / 100번 타석 데이타 요청, ENQ(1)+ID(3)+BCC(2)+ETX
        //05	1	 0  0	 9  1 03
        //05 31	30 30	39 31	03
        FLastExeCommand := COM_MON;
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
        FChannel := FTeeboxInfo.DeviceId;

        sBcc := GetBccJehu2Byte(FChannel);
        FSendData := JEU_ENQ + FChannel + sBcc + JEU_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1; //5
      end;

      FReceived := False;
      Sleep(200);

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadJehu50A Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.
