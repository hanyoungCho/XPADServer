unit uHeatControlCom;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils, System.Classes,
  uConsts, uStruct;

type

  TControlComPortHeatMonThread = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FHeatSeatNmTemp: array of String;
    FHeatInfoList: array of THeatInfo;
    FReTry: Integer;
    FReceived: Boolean;

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    FLastCtlSeatNo: Integer; //최종 제어타석기

    procedure HeatDevicNoTempSetting;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure HeatTimeChk;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer;
    procedure SetHeatUse(ASeatNm, AType, AAuto, AStartTm: String);

    function GetHeatUseStatus(ASeatNm: String): String;
    function GetHeatNo(ASeatNm: String): Integer;
    function GetSeatNm(AHeatNo: Integer): String;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TControlComPortHeatMonThread }

constructor TControlComPortHeatMonThread.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.HeatPort);
  FComPort.BaudRate := GetBaudrate(Global.ADConfig.Baudrate);
  //FComPort.Parity.Bits := GetParity(Global.ADConfig.Parity);
  FComPort.Open;

  FReTry := 0;
  FReceived := True;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FRecvData := '';
  HeatDevicNoTempSetting;

  Global.Log.LogWrite('TControlComPortHeatMonThread Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TControlComPortHeatMonThread.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TControlComPortHeatMonThread.HeatDevicNoTempSetting;
var
  nCnt, nIndex, nHeatNo: Integer;
begin

  FHeatSeatNmTemp := [ '', '8', '7', '6', '5', '4', '3', '2', '1','16',
                      '15','14','13','12','11','10', '9','24','23','22',
                      '21','20','19','18','17','32','31','30','29','28',
                      '27','26','25','40','39','38','37','36','35','34',
                      '33','48','47','46','45','44','43','42','41','56',
                      '55','54','53','52','50','51','49','64','63','62',
                      '61','60','59','58','57','72','71','70','69','68',
                      '67','66','65',  '',  '',  '',  '','77','75','74',
                      '73'];

  nCnt := Length(FHeatSeatNmTemp);
  SetLength(FHeatInfoList, nCnt + 1);
  for nIndex := 0 to nCnt - 1 do
  begin
    nHeatNo := nIndex + 1;
    FHeatInfoList[nHeatNo].HeatNo := nHeatNo;
    FHeatInfoList[nHeatNo].TeeboxNm := FHeatSeatNmTemp[nIndex];
    FHeatInfoList[nHeatNo].UseStatus := '0';
  end;
end;

procedure TControlComPortHeatMonThread.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sRecvData: AnsiString;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := '';
  FReceived := True;
end;

procedure TControlComPortHeatMonThread.SetCmdSendBuffer;
var
  nIndex: Integer;
  sSendData, sBcc: AnsiString;
begin

  sSendData := '';
  for nIndex := HEAT_MIN to HEAT_MAX do
  begin
    sSendData := sSendData + FHeatInfoList[nIndex].UseStatus;
  end;

  //Global.Log.LogHeatWrite(sSendData + ' / ' + sBcc);
  sBcc := GetBccStarHeat(sSendData);
  //Global.Log.LogHeatWrite(sSendData + ' / ' + sBcc);

  sSendData := 's' + '1018' + sSendData + sBcc + 'e';

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

procedure TControlComPortHeatMonThread.SetHeatuse(ASeatNm, AType, AAuto, AStartTm: String);
var
  nIndex, nHeatNo: Integer;
  sStr: String;
begin
  nHeatNo := 0;
  for nIndex := HEAT_MIN to HEAT_MAX do
  begin
    if FHeatInfoList[nIndex].TeeboxNm = ASeatNm then
    begin
      nHeatNo := nIndex;
      Break;
    end;
  end;

  if nHeatNo = 0 then
  begin
    sStr := 'SeatNm: ' + ASeatNm + ' No Device ';
    Global.Log.LogHeatWrite(sStr);
    Exit;
  end;

  FHeatInfoList[nHeatNo].UseStatus := AType;
  FHeatInfoList[nHeatNo].UseAuto := AAuto;
  sStr := 'SeatNm: ' + ASeatNm + ' / ' + AType;

  if AAuto = '1' then
  begin
    FHeatInfoList[nHeatNo].StartTime := DateStrToDateTime2(AStartTm);
    FHeatInfoList[nHeatNo].EndTime := FHeatInfoList[nHeatNo].StartTime +
                                      (((1/24)/60) * StrToInt(Global.ADConfig.HeatTime));
    sStr := sStr + ' / ' + AStartTm;
  end;

  Global.Log.LogHeatWrite(sStr);
end;

function TControlComPortHeatMonThread.GetHeatUseStatus(ASeatNm: String): String;
var
  nIndex: Integer;
  sStatus: String;
begin
  Result := '';

  sStatus := '';
  for nIndex := HEAT_MIN to HEAT_MAX do
  begin
    if FHeatInfoList[nIndex].TeeboxNm = ASeatNm then
    begin
      sStatus := FHeatInfoList[nIndex].UseStatus;
      Break;
    end;
  end;

  Result := sStatus;
end;

function TControlComPortHeatMonThread.GetHeatNo(ASeatNm: String): Integer;
var
  nIndex: Integer;
  nHeatNo: Integer;
begin

  nHeatNo := 0;
  for nIndex := HEAT_MIN to HEAT_MAX do
  begin
    if FHeatInfoList[nIndex].TeeboxNm = ASeatNm then
    begin
      nHeatNo := nIndex;
      Break;
    end;
  end;

  Result := nHeatNo;
end;

function TControlComPortHeatMonThread.GetSeatNm(AHeatNo: Integer): String;
begin
  Result := FHeatInfoList[AHeatNo].TeeboxNm;
end;

procedure TControlComPortHeatMonThread.HeatTimeChk;
var
  nHeatNo: Integer;
  sSendData: AnsiString;
  sSeatTime, sSeatBall, sBcc: AnsiString;
  nCnt, nIndex: Integer;
  sCheckTime, sTime, sStr, sSeatStr: string;
begin
  //Global.LogWrite('SeatReserveChk!!!');

  for nHeatNo := HEAT_MIN to HEAT_MAX do
  begin

    //Auto 여부
    if FHeatInfoList[nHeatNo].UseAuto <> '1' then
      Continue;

    //가동여부
    if FHeatInfoList[nHeatNo].UseStatus <> '1' then
      Continue;

    if FHeatInfoList[nHeatNo].EndTime < Now then
    begin
      FHeatInfoList[nHeatNo].UseStatus := '0';
      //Global.SetTeeboxHeatConfig(FHeatInfoList[nHeatNo].TeeboxNm, '', '0', FHeatInfoList[nHeatNo].UseAuto, '');
      SetCmdSendBuffer;

      sStr := '자동히터정지 : ' + FHeatInfoList[nHeatNo].TeeboxNm + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].StartTime) + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].EndTime);
      Global.Log.LogHeatWrite(sStr);
    end;
  end;

end;

procedure TControlComPortHeatMonThread.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nSeatNo: Integer;
begin
  inherited;

  while not Terminated do
  begin
    try
      //Synchronize(Global.SeatControlTimeCheck);

      if not FComPort.Connected then
      begin
        FComPort.Open;
      end;

      FSendData := '';
      bControlMode := False;
      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //대기중인 제어명령이 있으면
        bControlMode := True;
        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogHeatWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        inc(FReTry);
        if FReTry > 1 then
        begin
          FReTry := 0;
          if FLastCmdDataIdx <> FCurCmdDataIdx then
          begin
            inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
            if FCurCmdDataIdx > BUFFER_SIZE then
              FCurCmdDataIdx := 0;
          end;
        end;
      end;

      Sleep(500);

      //히터 자동사용시 타이머 체크
      Synchronize(HeatTimeChk);

    except
      on e: Exception do
      begin
        sLogMsg := 'TControlComPortHeatMonThread Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);

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
