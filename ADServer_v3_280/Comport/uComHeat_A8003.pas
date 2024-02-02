unit uComHeat_A8003;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils, System.Classes,
  uConsts, uStruct;

const
  HEAT_MIN = 1;
  HEAT_MAX = 44;

type
  TComThreadHeat_A8003 = class(TThread)
  private
    FComPort: TComPort;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FHeatDevice: array of String;
    FHeatData: array of String;
    FHeatInfoList: array of THeatInfo;

    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    //FReTry: Integer;
    //FReceived: Boolean;

    FTeeboxNm: String;

    Cnt_1: Integer;
    //Cnt_2: Integer;

    procedure HeatDevicNoSetting;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure HeatTimeChk;
    //procedure HeatOnOff;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ATeeboxNm, AType: String);
    procedure SetHeatUse(ATeeboxNm, AType, AAuto, AStartTm: String; ACtrl: Boolean = False);
    procedure SetHeatUseAllOff;

    function GetHeatUseStatus(ATeeboxNm: String): String;
    function HeatDeviceNm(AId: String): String;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadHeat_DOME }

constructor TComThreadHeat_A8003.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.HeatPort);
  FComPort.BaudRate := br9600;
  FComPort.Open;

  FRecvData := '';

  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;

  Cnt_1 := 0;
  //Cnt_2 := 0;

  HeatDevicNoSetting;

  Global.Log.LogWrite('TComThreadHeat_A8003 Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadHeat_A8003.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadHeat_A8003.HeatDevicNoSetting;
var
  nIndex: Integer;
begin
  FHeatDevice := ['00','01','02','03','04','05','06','07','08','09','0A','0B','0C','0D','0E',
                  '0F','10','11','12','13','14','15','16','17','18','19','1A','1B','1C','1D',
                  '1E','1F','20','21','22','23','24','25','26','27','28','29','2A','2B','2C',
                  '2D','2E','2F','30','31','32','33','34','35','36','37','38','39','3A','3B'];

  FHeatData := ['16','15','14','13', '12','11','10','9',   '8','7','6','5',     '4','3','2','1',
                '32','31','30','29', '28','27','26','25', '24','23','22','21', '20','19','18','17',
                '48','47','46','45', '44','43','42','41', '40','39','38','37', '36','35','34','33',
                '00','00','00','00','00','00','00','00','00','00','00'];

  SetLength(FHeatInfoList, HEAT_MAX + 1);
  for nIndex := HEAT_MIN to HEAT_MAX do
  begin
    FHeatInfoList[nIndex].TeeboxNm := IntToStr(nIndex);
    FHeatInfoList[nIndex].UseStatus := '0';
  end;
end;

procedure TComThreadHeat_A8003.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sRecvData: AnsiString;
  nStx, nEtx: Integer;
  sDeviceId, sHeatNm: String;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Pos(#06, FRecvData) = 0 then
    Exit;

  if Pos(#03, FRecvData) = 0 then
    Exit;

  nStx := Pos(#06, FRecvData);
  nEtx := Pos(#03, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  if Copy(FSendData, 4, 2) = 'WS' then //제어인 경우
  begin
    sDeviceId := Copy(FSendData, 15, 2);
    sHeatNm := HeatDeviceNm(sDeviceId);
    Global.Log.LogHeatCtrlRead('Nm: ' + sHeatNm + ' - ' + FSendData + ' / ' + FRecvData);
  end
  else
  begin
    Global.Log.LogHeatCtrlRead(FSendData + ' / ' + FRecvData);
  end;

  if Pos('00WSS', FRecvData) <> 0 then //제어에 의한 응답인경우
  begin
    FRecvData := '';
    Exit;
  end;

  //상태요청 응답값 비교-보류
  //Display2(FRecvData);

  FRecvData := '';
end;

procedure TComThreadHeat_A8003.SetHeatUse(ATeeboxNm, AType, AAuto, AStartTm: String; ACtrl: Boolean = False); //타석별 제어상태
var
  nIndex, nHeatNo: Integer;
  sStr: String;
begin

  //if ATeeboxNm > '44' then
    //Exit;

  nHeatNo := StrToInt(ATeeboxNm);

  if nHeatNo > 44 then
    Exit;

  FHeatInfoList[nHeatNo].UseStatus := AType;
  FHeatInfoList[nHeatNo].UseAuto := AAuto;
  sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AType;

  if AAuto = '1' then
  begin
    FHeatInfoList[nHeatNo].StartTime := DateStrToDateTime2(AStartTm);
    FHeatInfoList[nHeatNo].EndTime := FHeatInfoList[nHeatNo].StartTime +
                                      (((1/24)/60) * StrToInt(Global.ADConfig.HeatTime));
    sStr := sStr + ' / ' + AStartTm;
  end;

  Global.Log.LogHeatWrite(sStr);

  if ACtrl = True then
    SetCmdSendBuffer(ATeeboxNm, AType);
end;

procedure TComThreadHeat_A8003.SetHeatUseAllOff; //전체OFF
var
  nIndex: Integer;
  sSendData: AnsiString;
begin
  sSendData := '';

  for nIndex := HEAT_MIN to HEAT_MAX do
  begin
    FHeatInfoList[nIndex].UseStatus := '0';
    Global.SetTeeboxHeatConfig(FHeatInfoList[nIndex].TeeboxNm, '', '0', '0', '');

    // .00WSS0106%MX00000.
    sSendData := #05 + '00WSS0106%MX0' + FHeatDevice[nIndex - 1] + '00' + #04;

    FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

    inc(FLastCmdDataIdx);
    if FLastCmdDataIdx > COM_CTL_MAX then
      FLastCmdDataIdx := 0;
  end;

  // .00RSB06%MW00005.
  //sSendData := #05 + '00RSB06%MW00005' + #04;
  //SetCmdSendBuffer(sSendData);
end;

function TComThreadHeat_A8003.GetHeatUseStatus(ATeeboxNm: String): String;
var
  nHeatNo: Integer;
begin
  nHeatNo := StrToInt(ATeeboxNm);
  Result := FHeatInfoList[nHeatNo].UseStatus;
end;

procedure TComThreadHeat_A8003.SetCmdSendBuffer(ATeeboxNm, AType: String);
var
  sSendData: AnsiString;
  nIndex: Integer;
begin
  sSendData := '';
  nIndex := StrToInt(ATeeboxNm);

  // .00WSS0106%MX00000.  0:off, 1: on -> W: 00WSS0106%MX00001
  sSendData := #05 + '00WSS0106%MX0' + FHeatDevice[nIndex - 1] + '0' + AType + #04;

  //상태요청 보류
  //sSendData := #05 + '00RSB06%MW00005' + #04;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > COM_CTL_MAX then
    FLastCmdDataIdx := 0;
end;

procedure TComThreadHeat_A8003.HeatTimeChk; //타석별 자동시간 계산
var
  nHeatNo: Integer;
  sStr: string;
begin

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
      Global.SetTeeboxHeatConfig(FHeatInfoList[nHeatNo].TeeboxNm, '', '0', FHeatInfoList[nHeatNo].UseAuto, '');
      SetCmdSendBuffer(FHeatInfoList[nHeatNo].TeeboxNm, '0'); //개별제어

      sStr := '자동히터정지 : ' + FHeatInfoList[nHeatNo].TeeboxNm + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].StartTime) + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].EndTime);
      Global.Log.LogHeatCtrlWrite(sStr);
    end;

  end;

end;

function TComThreadHeat_A8003.HeatDeviceNm(AId: String): String;
var
  i, nIndex: Integer;
  sStr: String;
begin
  sStr := '';

  for i := 0 to 44 do
  begin
    if FHeatDevice[i] = AId then
    begin
      sStr := IntToStr(i + 1);
      Break;
    end;

  end;

  Result := sStr;
end;

{
procedure TComThreadHeat_A8003.HeatOnOff; //1분마다 전체제어
var
  nIndex: Integer;
  sSendData: AnsiString;
  sChk: String;
begin

  try
    sSendData := '';

    for nIndex := 1 to 60 do
    begin

      sChk := '00';
      if nIndex < 46 then
      begin
        if FHeatInfoList[nIndex].UseStatus = '1' then
          sChk := '01';
      end;

      // .00WSS0106%MX00000.
      sSendData := #05 + '00WSS0106%MX0' + FHeatDevice[nIndex - 1] + sChk + #04;
      SetCmdSendBuffer(sSendData);
    end;

    // .00RSB06%MW00005.
    sSendData := #05 + '00RSB06%MW00005' + #04;
    SetCmdSendBuffer(sSendData);

  except
    on E: Exception do
    begin
      //Log(E.Message);
    end;
  end;

end;
}
procedure TComThreadHeat_A8003.Execute;
var
  sLogMsg: String;
begin
  inherited;

  while not Terminated do
  begin
    try

      if not FComPort.Connected then
      begin
        FComPort.Open;
      end;

      FSendData := '';

      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //대기중인 제어명령이 있으면

        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogHeatCtrlWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        if FLastCmdDataIdx <> FCurCmdDataIdx then
        begin
          inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
          if FCurCmdDataIdx > BUFFER_SIZE then
            FCurCmdDataIdx := 0;
        end;
      end;

      Sleep(100);

      inc(Cnt_1);
      if Cnt_1 > 10 then
      begin
        //히터 자동사용시 타이머 체크
        Synchronize(HeatTimeChk);
        Cnt_1 := 0;
      end;
      {
      inc(Cnt_2);
      if Cnt_2 > 60 then
      begin
        //1분마다 전체제어 명령
        Synchronize(HeatOnOff);
        Cnt_2 := 0;
      end;
       }
    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadHeat_A8003 Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogHeatCtrlWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
