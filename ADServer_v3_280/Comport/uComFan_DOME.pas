unit uComFan_DOME;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils, System.Classes,
  uConsts, uStruct;

const
  FAN_MIN = 1;
  FAN_MAX = 63;

type

  TComThreadFan_DOME = class(TThread)
  private
    FComPort: TComPort;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReceived: Boolean;
    FLastExeCommand: Integer; //최종 패킷 수행 펑션
    FWriteTm: TDateTime;

    FFanInfoList: array of TFanInfo;

    procedure FanDevicNoTempSetting;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure FanTimeChk;
    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetFanUse(ATeeboxNm, AType, AAuto, AStartTm: String);
    procedure SetFanUseAllOff;

    function GetFanUseStatus(ATeeboxNm: String): String;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadFan_DOME }

constructor TComThreadFan_DOME.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.FanPort);
  FComPort.BaudRate := br9600;
  FComPort.Open;

  FRecvData := '';
  FanDevicNoTempSetting;

  Global.Log.LogWrite('TComThreadFan_DOME Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadFan_DOME.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadFan_DOME.FanDevicNoTempSetting;
var
  nIndex: Integer;
begin
  SetLength(FFanInfoList, FAN_MAX + 1);
  for nIndex := FAN_MIN to FAN_MAX do
  begin  // 20/21   41/42   62/63
    FFanInfoList[nIndex].FanNo := nIndex;
    if nIndex = 20 then
      FFanInfoList[nIndex].TeeboxNm := '20/21'
    else if nIndex = 41 then
      FFanInfoList[nIndex].TeeboxNm := '41/42'
    else if nIndex = 62 then
      FFanInfoList[nIndex].TeeboxNm := '62/63'
    else
      FFanInfoList[nIndex].TeeboxNm := IntToStr(nIndex);
    FFanInfoList[nIndex].UseStatus := 'F';
  end;
end;

procedure TComThreadFan_DOME.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sRecvData: AnsiString;
  sLogMsg: string;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Pos(COM_STX, FRecvData) = 0 then
    Exit;

  if Pos(COM_ETX, FRecvData) = 0 then
    Exit;

  if FLastExeCommand = 1 then
    FLastExeCommand := 2
  else
    FLastExeCommand := 1;

  sLogMsg := FSendData + ' / ' + FRecvData;
  Global.Log.LogFanComRead(sLogMsg);

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadFan_DOME.SetFanUse(ATeeboxNm, AType, AAuto, AStartTm: String);
var
  nIndex, nFanNo: Integer;
  sStr: String;
begin
  nFanNo := 0;
  for nIndex := FAN_MIN to FAN_MAX do
  begin
    if FFanInfoList[nIndex].TeeboxNm = ATeeboxNm then
    begin
      nFanNo := nIndex;
      Break;
    end;
  end;

  if nFanNo = 0 then
  begin
    sStr := 'TeeboxNm: ' + ATeeboxNm + ' / No Device ';
    Global.Log.LogFanWrite(sStr);
    Exit;
  end;

  if AType = '0' then
    FFanInfoList[nFanNo].UseStatus := 'F'
  else
    FFanInfoList[nFanNo].UseStatus := 'N';

  if nFanNo = 41 then //'41/42'
    FFanInfoList[42].UseStatus := FFanInfoList[41].UseStatus;

  FFanInfoList[nFanNo].UseAuto := AAuto;
  sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AType;

  if AAuto = '1' then
  begin
    FFanInfoList[nFanNo].StartTime := DateStrToDateTime2(AStartTm);
    FFanInfoList[nFanNo].EndTime := FFanInfoList[nFanNo].StartTime + (((1/24)/60) * StrToInt(Global.ADConfig.HeatTime));
    sStr := sStr + ' / ' + AStartTm;
  end;

  Global.Log.LogFanWrite(sStr);
end;

procedure TComThreadFan_DOME.SetFanUseAllOff;
var
  nIndex: Integer;
  sStr: String;
begin

  for nIndex := FAN_MIN to FAN_MAX do
  begin
    FFanInfoList[nIndex].UseStatus := 'F';
  end;

  sStr := 'All Off !!';
  Global.Log.LogFanWrite(sStr);
end;

function TComThreadFan_DOME.GetFanUseStatus(ATeeboxNm: String): String;
var
  nIndex: Integer;
  sStatus: String;
begin
  Result := '';

  sStatus := '';
  for nIndex := FAN_MIN to FAN_MAX do
  begin
    if FFanInfoList[nIndex].TeeboxNm = ATeeboxNm then
    begin
      sStatus := FFanInfoList[nIndex].UseStatus;
      Break;
    end;
  end;

  Result := sStatus;
end;

procedure TComThreadFan_DOME.FanTimeChk;
var
  nFanNo: Integer;
  sStr: string;
begin

  for nFanNo := FAN_MIN to FAN_MAX do
  begin

    //Auto 여부
    if FFanInfoList[nFanNo].UseAuto <> '1' then
      Continue;

    //가동여부
    if FFanInfoList[nFanNo].UseStatus <> 'N' then
      Continue;

    if FFanInfoList[nFanNo].EndTime < Now then
    begin
      FFanInfoList[nFanNo].UseStatus := 'F';
      Global.SetTeeboxFanConfig(FFanInfoList[nFanNo].TeeboxNm, '', '0', FFanInfoList[nFanNo].UseAuto, '');

      sStr := '자동정지 : ' + FFanInfoList[nFanNo].TeeboxNm + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FFanInfoList[nFanNo].StartTime) + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FFanInfoList[nFanNo].EndTime);
      Global.Log.LogFanComWrite(sStr);
    end;
  end;

end;

procedure TComThreadFan_DOME.Execute;
var
  sLogMsg: String;
  nIndex: Integer;
begin
  inherited;

  while not Terminated do
  begin
    try

      while True do
      begin
        if FReceived = False then
        begin

          if now > FWriteTm then
          begin

            sLogMsg := 'Retry COM_MON Received Fail : ' + ' / ' + FSendData + ' / ' + FRecvData;
            Global.Log.LogFanComWrite(sLogMsg);

            if FLastExeCommand = 1 then
              FLastExeCommand := 2
            else
              FLastExeCommand := 1;

            Break;
          end;

        end
        else
        begin
          Break;
        end;
      end;

      if not FComPort.Connected then
      begin
        FComPort.Open;
      end;

      FSendData := '';

      //장치에 데이터값을 요청하는 부분
      if FLastExeCommand = 1 then
      begin
        for nIndex := 1 to 40 do
        FSendData := FSendData + FFanInfoList[nIndex].UseStatus;

        FSendData := COM_STX + 'A01' + FSendData + '00' + COM_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogFanComWrite(FSendData);
      end
      else
      begin
        for nIndex := 41 to 63 do
        FSendData := FSendData + FFanInfoList[nIndex].UseStatus;

        for nIndex := 0 to 16 do //17개
          FSendData := FSendData + 'F';

        FSendData := COM_STX + 'A02' + FSendData + '00' + COM_ETX;
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogFanComWrite(FSendData);
      end;

      FWriteTm := now + (((1/24)/60)/60) * 1;
      FReceived := False;
      Sleep(200);

      //히터 자동사용시 타이머 체크
      Synchronize(FanTimeChk);

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadFan_DOME Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogFanComWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
