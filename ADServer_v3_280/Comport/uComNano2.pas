unit uComNano2;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadNano2 = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FCtlReTry: Integer;
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
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxNm, ATeeboxTime, ATeeboxBall, AType: String);
    procedure SetCmdBuffer(ASendData: AnsiString);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJMS }

constructor TComThreadNano2.Create;
begin

  FReTry := 0;
  FReceived := True;
  FTeeboxNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadSM Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadNano2.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadNano2.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
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

  Global.Log.LogWrite('TComThreadNano2 ComPortSetting : ' + FFloorCd);
end;

procedure TComThreadNano2.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  sDisplay, sState, sTime, sBall, sError: string;
  sLogMsg: string;

  nIndex: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx: Integer;

  sSendData, sDisplayNoTm, sID, sID2: AnsiString;
begin
  //제어시 응답값 없음
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Length(FRecvData) < 33 then
    Exit;

  if Pos(Char(COM_STX), FRecvData) = 0 then
    Exit;

  if Pos(Char(COM_ETX), FRecvData) = 0 then
    Exit;

  nStx := Pos(Char(COM_STX), FRecvData);
  nEtx := Pos(Char(COM_ETX), FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 33) then
  begin
    Global.Log.LogReadMulti(FIndex, 'FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if Copy(FChannel, 1, 2) = Copy(FRecvData, 2, 2) then //012 013
  begin

    // 전문구성 : STX(1) + ID(2) + CLASS(1) + STATUS(2) + 타석명(4) + 타석상태(4) + 남은볼수(4) + 남은시간(4) + mode(4) + 에러코드(4) + FCC(2) + ETX(1)
    // 1  2	 3	4	 5	6	 7	8	 9 10	 11 12 13 14	15 16 17 18  19 20 21 22  23 24 25 26  27 28 29 30  31 32 33
    // 	2	 4	$	 R	D	 0	0	 7	2	  0	 0  0	 2	 0	9	 2	0	  0	 0  5	 4	 0	0	 0	1	  0	 0	0	 0   1  3  
    //5:시작, 6:종료, 3:대기, 9:초기

    sDisplay := copy(FRecvData, 7, 4);
    sState := copy(FRecvData, 14, 1);
    sBall := copy(FRecvData, 15, 4);
    sTime := copy(FRecvData, 19, 4);
    sError := copy(FRecvData, 30, 1);

    rTeeboxInfo.StoreCd := ''; //가맹점 코드
    rTeeboxInfo.TeeboxNo := FTeeboxInfo.TeeboxNo;
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //타석명
    rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
    rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드

    rTeeboxInfo.UseYn := '';        //사용 여부
    rTeeboxInfo.RemainMinute := StrToInt(sTime);
    rTeeboxInfo.RemainBall := StrToInt(sBall);

    if sError <> '0' then
    begin
      rTeeboxInfo.UseStatus := '9';
      rTeeboxInfo.ErrorCd := 10 + StrToInt(sError);
      rTeeboxInfo.ErrorCd2 := sError;
    end
    else
    begin
      if sState = '5' then //시작
        rTeeboxInfo.UseStatus := '1'
      else //6:종료?, 8: ???, 3:대기, 9:초기
      begin
        rTeeboxInfo.UseStatus := '0';

        if (Global.ADConfig.StoreCode = 'B8001') or // 제이제이골프클럽
           (Global.ADConfig.StoreCode = 'B5001') then //김포정원
        begin
          if (sState = '6') or (sState = '3') then //6:체크아웃상태(End표시상태), 3:빈타석, 3일경우 10분을 응답함.
            rTeeboxInfo.RemainMinute := 0;
        end;
      end;
    end;

    Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

    sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);

    sLogMsg := 'Nm:' + StrZeroAdd(FTeeboxInfo.TeeboxNm, 2) + ' : ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogMainViewMulti(FIndex, sLogMsg);

    //if (Global.ADConfig.StoreCode = 'B8001') or // 제이제이골프클럽
    if (Global.ADConfig.StoreCode = 'B5001') then
    begin
      sDisplayNoTm := StrZeroAdd(FTeeboxInfo.TeeboxNm, 4);
      sSendData := '';

      if (sState = '6') or (sState = '9') then
      begin
        sID := copy(FChannel, 1, 2);
        sID2 := Copy(FChannel, 3, 1);

        sSendData := COM_STX + sID + '#WD' + sID2 + '1' + '0009' + '00' + COM_ETX; //초기화
        SetCmdBuffer(sSendData);

        sSendData := COM_STX + sID + '#WD' + sID2 + '2' + sDisplayNoTm + '00' + COM_ETX; //타석명
        SetCmdBuffer(sSendData);

        //sLogMsg := 'No:' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm:' + sDisplayNoTm + ' 초기화';
        Global.Log.LogReadMulti(FIndex, 'No:' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / Nm:' + sDisplayNoTm + ' 초기화');
      end;

    end;
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

  sLogMsg := 'No:' + IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + sLogMsg;
  Global.Log.LogReadMulti(FIndex, sLogMsg);

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadNano2.SetCmdSendBuffer(ADeviceId, ATeeboxNm, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData: AnsiString;
  sID, sID2, sTeeboxTime, sTeeboxNm: AnsiString;
begin

  sTeeboxTime := StrZeroAdd(ATeeboxTime, 4);
  sTeeboxNm := StrZeroAdd(ATeeboxNm, 4); //타석명은 숫자형식이여야 함
  sID := copy(ADeviceId, 1, 2);
  sID2 := Copy(ADeviceId, 3, 1);

  // 전문구성 : STX(1) + ID(2) + #(1) + STATUS(2) + CMD(2) + DATA(4) + FCC(2) + ETX(1) - 15byte
  // 1	2	 3  4	 5	6	 7	8	 9 10	11 12	13 14	15
  //   1  0  #  W  D  3  1  0  0  0  9  0  0   (초기화)
  //   1  0  #  W  D  3  2  0  0  2  0  0  0   (타석명설정) 20번
  //   1  0  #  W  D  3  4  0  9  9  9  0  0   (볼셋팅) 999개
  //   1  0  #  W  D  3  5  0  0  7  0  0  0   (시간 셋팅) 70분
  //   1  0  #  W  D  3  3  0  0  0  1  0  0   (병산제)
  //   1  0  #  W  D  3  1  0  0  0  1  0  0   (대기)
  //   1  0  #  W  D  3  1  0  0  0  2  0  0   (시작)
  //   1  0  #  W  D  3  1  0  0  0  3  0  0   (체크아웃)

  //매장마다 체크인 을 해야 시작이 되는 곳이 있음.
  if (Global.ADConfig.StoreCode = 'B8001') or // 제이제이골프클럽
     (Global.ADConfig.StoreCode = 'B5001') then //김포정원
  begin
    if sTeeboxTime = '0000' then
    begin
      sSendData := COM_STX + sID + '#WD' + sID2 + '1' + '0003' + '00' + COM_ETX; //체크아웃
      SetCmdBuffer(sSendData);
    end
    else
    begin
      if AType = 'S0' then
      begin

        sSendData := COM_STX + sID + '#WD' + sID2 + '1' + '0009' + '00' + COM_ETX; //초기화
        SetCmdBuffer(sSendData);

        sSendData := COM_STX + sID + '#WD' + sID2 + '2' + sTeeboxNm + '00' + COM_ETX; //타석명
        SetCmdBuffer(sSendData);

        sSendData := COM_STX + sID + '#WD' + sID2 + '4' + '0999' + '00' + COM_ETX; //볼셋팅
        SetCmdBuffer(sSendData);

        sSendData := COM_STX + sID + '#WD' + sID2 + '5' + sTeeboxTime + '00' + COM_ETX; //시간셋팅
        SetCmdBuffer(sSendData);

        sSendData := COM_STX + sID + '#WD' + sID2 + '3' + '0001' + '00' + COM_ETX; //병산제(모드)
        SetCmdBuffer(sSendData);

        sSendData := COM_STX + sID + '#WD' + sID2 + '1' + '0001' + '00' + COM_ETX; //체크인(대기)
        SetCmdBuffer(sSendData);
      end
      else if AType = 'S1' then
      begin
        sSendData := COM_STX + sID + '#WD' + sID2 + '1' + '0002' + '00' + COM_ETX; //시작
        SetCmdBuffer(sSendData);
      end
      else if AType = 'S2' then //시간변경
      begin
        sSendData := COM_STX + sID + '#WD' + sID2 + '5' + sTeeboxTime + '00' + COM_ETX; //시간셋팅
        SetCmdBuffer(sSendData);
      end
      else if AType = 'S3' then //체크아웃
      begin
        sSendData := COM_STX + sID + '#WD' + sID2 + '1' + '0003' + '00' + COM_ETX;
        SetCmdBuffer(sSendData);
      end;
    end;
  end
  else
  begin
    if AType = 'S1' then
    begin
      sSendData := COM_STX + sID + '#WD' + sID2 + '1' + '0009' + '00' + COM_ETX; //초기화
      SetCmdBuffer(sSendData);

      sSendData := COM_STX + sID + '#WD' + sID2 + '2' + sTeeboxNm + '00' + COM_ETX; //타석명
      SetCmdBuffer(sSendData);

      sSendData := COM_STX + sID + '#WD' + sID2 + '4' + '0999' + '00' + COM_ETX; //볼셋팅
      SetCmdBuffer(sSendData);

      sSendData := COM_STX + sID + '#WD' + sID2 + '5' + sTeeboxTime + '00' + COM_ETX; //시간셋팅
      SetCmdBuffer(sSendData);

      sSendData := COM_STX + sID + '#WD' + sID2 + '3' + '0001' + '00' + COM_ETX; //병산제(모드)
      SetCmdBuffer(sSendData);

      sSendData := COM_STX + sID + '#WD' + sID2 + '1' + '0002' + '00' + COM_ETX; //시작
      SetCmdBuffer(sSendData);
    end
    else if AType = 'S2' then //시간변경
    begin
      sSendData := COM_STX + sID + '#WD' + sID2 + '5' + sTeeboxTime + '00' + COM_ETX; //시간셋팅
      SetCmdBuffer(sSendData);
    end;
  end;

  sSendData := COM_STX + sID + '#RD' + sID2 + '000' + COM_ETX;
  SetCmdBuffer(sSendData);

end;

procedure TComThreadNano2.SetCmdBuffer(ASendData: AnsiString);
begin
  FCmdSendBufArr[FLastCmdDataIdx] := ASendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadNano2.SetNextMonNo: Boolean;
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

procedure TComThreadNano2.Execute;
var
  bControlMode: Boolean;
  //sBcc: AnsiString;
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

            sLogMsg := 'Retry COM_MON Received Fail! No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData + ' / ' + FRecvData;
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

      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //대기중인 제어명령이 있으면
        bControlMode := True;
        FLastExeCommand := COM_CTL;
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 2) + Copy(FCmdSendBufArr[FCurCmdDataIdx], 7, 1);

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToFloorTeeboxInfo(FFloorCd, FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);

        if FLastCmdDataIdx <> FCurCmdDataIdx then
        begin
          inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
          if FCurCmdDataIdx > BUFFER_SIZE then
            FCurCmdDataIdx := 0;
        end;

        if Global.Teebox.BallBackEnd = True then
        begin
          Global.Teebox.BallBackEndCtl := True;
        end;

        Sleep(300);  //50 이하인경우 retry 발생
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        FLastExeCommand := COM_MON;
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);

        if (FTeeboxInfo.TeeboxZoneCode = 'L') or (FTeeboxInfo.TeeboxZoneCode = 'C') then
          FChannel := Copy(FTeeboxInfo.DeviceId, 1, Global.ADConfig.DeviceCnt)
        else
          FChannel := FTeeboxInfo.DeviceId;

        // 전문구성 : STX(1) + ID(2) + #(1) + STATUS(2) + CMD(2) + FCC(2) + ETX(1) - 11byte
        // 1	2	 3  4	 5	6	 7	8	 9 10	11
        // 	2	 4	#	 R	D	 3	0	 0	0	 

        FSendData := COM_STX + copy(FChannel, 1, 2) + '#RD' + Copy(FChannel, 3, 1) + '000' + COM_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;

        FReceived := False;
        Sleep(500);  //50 이하인경우 retry 발생
      end;

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadNano2 Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.
