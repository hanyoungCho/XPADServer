unit uComNano;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils,System.Classes,
  uConsts, uStruct;

type

  TComThreadNano = class(TThread)
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

    procedure SetTeeboxError(AChannel: String);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
    procedure SetCmdBuffer(ASendData: AnsiString);
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadJMS }

constructor TComThreadNano.Create;
begin

  FReTry := 0;
  FReceived := True;
  FTeeboxNoLast := 0;
  FRecvData := '';

  Global.Log.LogWrite('TComThreadSM Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadNano.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadNano.ComPortSetting(AFloorCd: String; AIndex, ATeeboxNoStart, ATeeboxNoEnd, APort, ABaudRate: Integer);
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

  Global.Log.LogWrite('TComThreadNano ComPortSetting : ' + FFloorCd);
end;

// 제어3회 시도후 에러처리
procedure TComThreadNano.SetTeeboxError(AChannel: String);
var
  rTeeboxInfo: TTeeboxInfo;
begin
  rTeeboxInfo.StoreCd := ''; //가맹점 코드
  rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, AChannel); //타석 번호
  //rSeatInfo.RecvDeviceId := AChannel;
  rTeeboxInfo.TeeboxNm := '';  //타석명
  rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
  rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드
  rTeeboxInfo.UseStatus := '9';
  rTeeboxInfo.UseYn := '';        //사용 여부
  rTeeboxInfo.RemainBall := 0;
  //rSeatInfo.RemainMinute := 0;
  rTeeboxInfo.ErrorCd := 8;
  rTeeboxInfo.ErrorCd2 := '8';

  Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);
end;

procedure TComThreadNano.ComPortRxChar(Sender: TObject; Count: Integer);
var
  nFuncCode: Integer;
  DevNo, State, Time, Ball, BCC: string;
  sLogMsg: string;

  nIndex: Integer;
  sRecvData: AnsiString;
  rTeeboxInfo: TTeeboxInfo;

  nStx, nEtx: Integer;

  sSendData, sBcc, sDisplayNo, sDisplayNoTm: AnsiString;
begin

  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Length(FRecvData) < 33 then
    Exit;

  if Pos('%', FRecvData) = 0 then
    Exit;

  if Pos(Char(NANO_ETX), FRecvData) = 0 then
    Exit;

  nStx := Pos('%', FRecvData);
  nEtx := Pos(Char(NANO_ETX), FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if (Length(FRecvData) <> 33) then
  begin
    Global.Log.LogReadMulti(FIndex, 'FRecvData fail : ' + FRecvData);
    FRecvData := '';
    Exit;
  end;

  if Copy(FChannel, 1, 2) = Copy(FRecvData, 2, 2) then
  begin

    // 전문구성 : STX(1) + ID(2) + CLASS(3) + COMMAND(4) + 타석명(4) + 볼수(4) + data(4) + mode(4) + 시간(4) + CRC(2) + ETX(1)
    // 1  2	 3	4	 5	6	 7	8	 9 10	11 12	13 14	15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
    // %  0  5  $  R  D  0  5  0  0  1  0  0  0  8  0  0  6  0  0  0  0  0  3  0  0  4  4  0  0  1  8  .
    // %  0  2  $  R  D  0  5  0  0  0  4  0  0  9  7  0  8  0  3  0  0  0  3  0  0  1  0  0  0  1  3
    //RD0300 = 타석 비어 있을 때
    //RD0400 = 타석 배정하고 시작 전
    //RD0500 = 타석 시작 후 진행중

    rTeeboxInfo.StoreCd := ''; //가맹점 코드
    rTeeboxInfo.TeeboxNo := Global.Teebox.GetDevicToFloorTeeboxNo(FFloorCd, FChannel); //타석 번호
    rTeeboxInfo.RecvDeviceId := FChannel;
    rTeeboxInfo.TeeboxNm := '';  //타석명
    rTeeboxInfo.FloorZoneCode := ''; //층 구분 코드
    rTeeboxInfo.TeeboxZoneCode := '';  //구역 구분 코드

    rTeeboxInfo.UseYn := '';        //사용 여부
    rTeeboxInfo.RemainMinute := StrToInt(copy(FRecvData, 29, 2) + copy(FRecvData, 27, 2));
    rTeeboxInfo.RemainBall := StrToInt(copy(FRecvData, 17, 2) + copy(FRecvData, 15, 2));

    sDisplayNo := copy(FRecvData, 11, 2);

    if (Global.ADConfig.TimeCheckMode = '1') then
    begin
      if copy(FRecvData, 20, 1) <> '0' then //Error
      begin
        rTeeboxInfo.UseStatus := '9';
        rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(FRecvData, 20, 1));
        rTeeboxInfo.ErrorCd2 := copy(FRecvData, 20, 1);
      end
      else
      begin
        //'3':빈타석,'4':대기, '5':시작, '6':종료(End표시)
        rTeeboxInfo.UseStatus := copy(FRecvData, 8, 1);
      end;
    end
    else
    begin
      if copy(FRecvData, 8, 1) = '3' then //빈타석
      begin
        if copy(FRecvData, 20, 1) <> '0' then //Error
        begin
          rTeeboxInfo.UseStatus := '9';
          rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(FRecvData, 20, 1));
          rTeeboxInfo.ErrorCd2 := copy(FRecvData, 20, 1);
        end
        else
          rTeeboxInfo.UseStatus := '0';
      end
      else if copy(FRecvData, 8, 1) = '4' then //대기상태
      begin
        rTeeboxInfo.UseStatus := 'D';
      end
      else if copy(FRecvData, 8, 1) = '6' then //강제종료상태?
      begin
        //rTeeboxInfo.UseStatus := 'E';
        rTeeboxInfo.RemainMinute := 0;
      end
      else if copy(FRecvData, 8, 1) = '5' then
      begin
        if copy(FRecvData, 20, 1) <> '0' then //Error
        begin
          rTeeboxInfo.UseStatus := '9';
          rTeeboxInfo.ErrorCd := 10 + StrToInt(copy(FRecvData, 20, 1));
          rTeeboxInfo.ErrorCd2 := copy(FRecvData, 20, 1);
        end
        else
          rTeeboxInfo.UseStatus := '1';
      end;
    end;

    Global.Teebox.SetTeeboxInfoAD(rTeeboxInfo);

    sLogMsg := IntToStr(rTeeboxInfo.TeeboxNo) + ' / ' + FSendData + ' / ' + FRecvData;
    Global.DebugLogViewWriteMulti(FIndex, sLogMsg);

    sDisplayNoTm := StrZeroAdd(IntToStr(rTeeboxInfo.TeeboxNo), 2);
    sSendData := '';

    // 'B8001' 제이제이만 해당, 추가 매장 생기면 수정 필요
    if (Global.ADConfig.StoreCode = 'B8001') then // 제이제이골프클럽
    begin
      if (rTeeboxInfo.TeeboxNo = 23) then // 24번기준(120612) -> 23번 제어(120613)
      begin
        if ('120612' = rTeeboxInfo.RecvDeviceId) and (sDisplayNo <> '24') then // 24번타석 장치ID
        begin
          sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + '2400';
        end
        else if ('120613' = rTeeboxInfo.RecvDeviceId) and (sDisplayNo <> '23') then //23번타석 장치ID
        begin
          sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + '2300';
        end;
      end
      else if (rTeeboxInfo.TeeboxNo = 47) then // 48번기준(240612) -> 47번 제어(240613)
      begin
        if ('240612' = rTeeboxInfo.RecvDeviceId) and (sDisplayNo <> '48') then // 48번타석 장치ID
        begin
          sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + '4800';
        end
        else if ('240613' = rTeeboxInfo.RecvDeviceId) and (sDisplayNo <> '47') then //47번타석 장치ID
        begin
          sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + '4700';
        end;
      end
      else
      begin
        if sDisplayNo <> sDisplayNoTm then //타석기 LED 타석번호 설정
        begin
          sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + sDisplayNoTm + '00';
        end;
      end;
    end
    else
    begin
      if sDisplayNo <> sDisplayNoTm then //타석기 LED 타석번호 설정
      begin
        sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '3' + sDisplayNoTm + '00';
      end;
    end;

    if sSendData <> '' then
    begin
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);
    end;

    if copy(FRecvData, 8, 1) = '6' then
    begin
      //타석번호 표시 셋팅 추가 제어
      sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '1' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '1' + '0100';
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);
    end;

    if copy(FRecvData, 8, 1) = '9' then
    begin
      sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '1' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '1' + '0300';
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);

      sSendData := '%' + copy(rTeeboxInfo.RecvDeviceId, 1, 2) + '#WDD' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '1' + Copy(rTeeboxInfo.RecvDeviceId, 3, 4) + '1' + '0100'; //종료
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);
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
 { else
  begin
    //Global.Log.LogCtrlWriteMulti(FIndex, sLogMsg);

    if FLastCmdDataIdx <> FCurCmdDataIdx then
    begin
      inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
      if FCurCmdDataIdx > BUFFER_SIZE then
        FCurCmdDataIdx := 0;
    end;
  end;  }

  Global.Log.LogReadMulti(FIndex, sLogMsg);

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadNano.SetCmdSendBuffer(ADeviceId, ATeeboxTime, ATeeboxBall, AType: String);
var
  sSendData, sBcc: AnsiString;
  sTeeboxTime, sTeeboxTimeTm: AnsiString;
begin
  sTeeboxTimeTm := StrZeroAdd(ATeeboxTime, 4);
  sTeeboxTime := copy(sTeeboxTimeTm, 3, 2) + copy(sTeeboxTimeTm, 1, 2);
  //자리수 십, 일, 천, 백: 시간 100분 인경우 -> 0100 -> 0001

  // 전문구성 : STX(1) + ID(2) + COMMAND(4) + ID2(4) + CLASS(1) + ID2(4) + CLASS(1) + 값(4) + CRC(2) + ETX(1) - 16byte
  // 1	2	 3  4	 5	6	 7	8	 9 10	11  12	13 14	15 16  17  18 19 20 21  22 23 24
  // %  0  1  #  W  D  D  0  6  1  3   7   0  6  1  3   7   0  0  0  1   5  1  . (시간)
  // %  0  1  #  W  D  D  0  6  1  3   4   0  6  1  3   4   0  0  0  9   5  9  . (볼)
  // %  0  1  #  W  D  D  0  6  1  3   6   0  6  1  3   6   0  3  0  0   5  3  . (운영모드-1:볼수,3:시간)
  // %  0  1  #  W  D  D  0  6  1  3   1   0  6  1  3   1   0  2  0  0   5  2  . (적용)
  // %  0  1  #  W  D  D  0  6  1  3   1   0  6  1  3   1   0  8  0  0   5  8  . (시작)

  // %  0  1  #  W  D  D  0  6  1  3   1   0  6  1  3   1   0  3  0  0   5  3  . (카운터에서 타석종료)
  // %  0  1  #  W  D  D  0  6  1  3   1   0  6  1  3   1   0  1  0  0   5  1  . (종료)

  if sTeeboxTime = '0000' then
  begin
    if AType = 'S3' then
    begin
      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '1' + Copy(ADeviceId, 3, 4) + '1' + '0100';
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);
    end
    else
    begin
      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '1' + Copy(ADeviceId, 3, 4) + '1' + '0300';
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);

      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '1' + Copy(ADeviceId, 3, 4) + '1' + '0100'; //종료-타석번호디스플레이
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);
      {
      if (Global.ADConfig.TimeCheckMode = '0') then
      begin
        //타석번호 표시 셋팅 추가 제어
        sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '1' + Copy(ADeviceId, 3, 4) + '1' + '0100';
        sBcc := GetBccNano(sSendData);
        sSendData := sSendData + sBcc;
        SetCmdBuffer(sSendData);
      end;
      }
    end;
  end
  else
  begin
    if AType = 'S0' then
    begin
      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '7' + Copy(ADeviceId, 3, 4) + '7' + sTeeboxTime; //시간
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);

      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '4' + Copy(ADeviceId, 3, 4) + '4' + '0009'; //볼수
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);

      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '6' + Copy(ADeviceId, 3, 4) + '6' + '0300'; //운영모드
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);

      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '1' + Copy(ADeviceId, 3, 4) + '1' + '0200'; //적용
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);
    end
    else if AType = 'S1' then
    begin
      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '1' + Copy(ADeviceId, 3, 4) + '1' + '0800'; //시작
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);
    end
    else if AType = 'S2' then //시간변경
    begin
      sSendData := '%' + copy(ADeviceId, 1, 2) + '#WDD' + Copy(ADeviceId, 3, 4) + '7' + Copy(ADeviceId, 3, 4) + '7' + sTeeboxTime; //시간
      sBcc := GetBccNano(sSendData);
      sSendData := sSendData + sBcc;
      SetCmdBuffer(sSendData);
    end;
  end;
  {
  sSendData := '%' + copy(ADeviceId, 1, 2) + '#RDD' + Copy(ADeviceId, 3, 4) + '2' + Copy(ADeviceId, 3, 4) + '7';
  sBcc := GetBccNano(sSendData);
  sSendData := sSendData + sBcc;
  SetCmdBuffer(sSendData);
  }
end;

procedure TComThreadNano.SetCmdBuffer(ASendData: AnsiString);
begin
  FCmdSendBufArr[FLastCmdDataIdx] := ASendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

function TComThreadNano.SetNextMonNo: Boolean;
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

procedure TComThreadNano.Execute;
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
            {
            if FLastExeCommand = COM_CTL then
            begin
              sLogMsg := 'Retry COM_CTL Received Fail : ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
              Global.Log.LogRetryWriteMulti(FIndex, sLogMsg);

              FRecvData := '';

              inc(FCtlReTry);
              if FCtlReTry > 2 then
              begin
                FCtlReTry := 0;
                FComPort.Close;
                FComPort.Open;
                Global.Log.LogRetryWriteMulti(FIndex, 'ReOpen');
              end;

              if FLastCmdDataIdx <> FCurCmdDataIdx then
              begin
                inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
                if FCurCmdDataIdx > BUFFER_SIZE then
                  FCurCmdDataIdx := 0;
              end;

              Break;

            end
            else  }
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
        FChannel := Copy(FCmdSendBufArr[FCurCmdDataIdx], 2, 2) + Copy(FCmdSendBufArr[FCurCmdDataIdx], 8, 4);

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));

        FTeeboxInfo := Global.Teebox.GetDeviceToFloorTeeboxInfo(FFloorCd, FChannel);
        sLogMsg := 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' No: ' + IntToStr(FTeeboxInfo.TeeboxNo) + ' / Nm: ' + FTeeboxInfo.TeeboxNm + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);

        //FWriteTm := now + (((1/24)/60)/60) * 1;

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

        Sleep(100);  //50 이하인경우 retry 발생
      end;

      //장치에 데이터값을 요청하는 부분
      if bControlMode = False then
      begin
        FLastExeCommand := COM_MON;
        FTeeboxInfo := Global.Teebox.GetTeeboxInfo(FTeeboxNoLast);
        FChannel := FTeeboxInfo.DeviceId;

        // 전문구성 : STX(1) + ID(2) + COMMAND(4) + ID2(4) + CLASS(1) + ID2(4) + CLASS(1) + CRC(2) + ETX(1) - 20byte
        // 1	2	 3  4	 5	6	 7	8	 9 10	11 12	13 14	15 16 17 18 19 20
        // %  0  1  #  R  D  D  0  6  1  3  2  0  6  1  3  7  5  0  .
        FSendData := '%' + copy(FChannel, 1, 2) + '#RDD' + Copy(FChannel, 3, 4) + '2' + Copy(FChannel, 3, 4) + '7';
        sBcc := GetBccNano(FSendData);
        FSendData := FSendData + sBcc;
        FComPort.Write(FSendData[1], Length(FSendData));

        FWriteTm := now + (((1/24)/60)/60) * 1;

        FReceived := False;
        Sleep(200);  //50 이하인경우 retry 발생
      end;

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadNano Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.
