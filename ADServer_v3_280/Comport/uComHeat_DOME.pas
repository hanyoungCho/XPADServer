unit uComHeat_DOME;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils, System.Classes,
  uConsts, uStruct;

const
  DOME_HEAT_MIN = 1;
  DOME_HEAT_MAX = 63;

type

  TComThreadHeat_DOME = class(TThread)
  private
    FComPort: TComPort;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FHeatTemp: array of String;
    FHeatInfoList: array of THeatInfo;
    FHeatCtlList: array of THeatInfo;

    FCtlStatus: String;
    FCtlCnt: Integer;
    FCtlOnTime: Integer;
    FCtlOFFTime: Integer;

    procedure HeatDevicNoTempSetting;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure HeatTimeChk;
    procedure HeatOnOffTimeChk;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetHeatUseInit(ATeeboxNm, AType, AAuto, AStartTm: String);
    procedure SetHeatUse(ATeeboxNm, AUse, AAuto, AStartTm: String);
    procedure SetHeatUseAllOff;
    procedure SetHeatCtl(ACtlNm, AType: String);

    function GetHeatInfoListIdx(ATeeboxNm: String): Integer;

    procedure HeatOnOffTimeSetting(AOnTime, AOffTime: Integer);

    function GetHeatUseStatus(ATeeboxNm: String): String; //메인화면 히터제어상태용

    procedure SetHeatCtlStatus;
    function GetHeatCtlData(ATeeboxNm: String): String;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadHeat_DOME }

constructor TComThreadHeat_DOME.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.HeatPort);
  FComPort.BaudRate := br9600;
  FComPort.Open;

  FRecvData := '';
  HeatDevicNoTempSetting;

  FCtlStatus := '1';
  FCtlCnt := 0;
  FCtlOnTime := 0;
  FCtlOFFTime := 0;

  Global.Log.LogWrite('TComThreadHeat_DOME Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadHeat_DOME.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadHeat_DOME.HeatDevicNoTempSetting;
var
  nIndex: Integer;
begin
  FHeatTemp := [ '8', '7', '6', '5', '4', '3', '2', '1','16','15',
                '14','13','12','11','10', '9','24','23','22','21',
                '20','19','18','17'];
  SetLength(FHeatCtlList, 24);
  for nIndex := 0 to 23 do
  begin
    FHeatCtlList[nIndex].HeatNo := nIndex;
    FHeatCtlList[nIndex].TeeboxNm := FHeatTemp[nIndex];
    FHeatCtlList[nIndex].UseStatus := '0';
  end;

  SetLength(FHeatInfoList, DOME_HEAT_MAX + 1);
  for nIndex := DOME_HEAT_MIN to DOME_HEAT_MAX do
  begin
    FHeatInfoList[nIndex].HeatNo := nIndex;
    if nIndex = 20 then
      FHeatInfoList[nIndex].TeeboxNm := '20/21'
    else if nIndex = 41 then
      FHeatInfoList[nIndex].TeeboxNm := '41/42'
    else if nIndex = 62 then
      FHeatInfoList[nIndex].TeeboxNm := '62/63'
    else
      FHeatInfoList[nIndex].TeeboxNm := IntToStr(nIndex);
    FHeatInfoList[nIndex].UseStatus := '0';
    FHeatInfoList[nIndex].HeatCtl := GetHeatCtlData(FHeatInfoList[nIndex].TeeboxNm);
  end;
end;

procedure TComThreadHeat_DOME.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sRecvData: AnsiString;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := '';
end;

procedure TComThreadHeat_DOME.HeatOnOffTimeSetting(AOnTime, AOffTime: Integer);
begin
  FCtlOnTime := AOnTime;
  FCtlOFFTime := AOffTime;
end;

function TComThreadHeat_DOME.GetHeatInfoListIdx(ATeeboxNm: String): Integer;
var
  nIndex, nHeatNo: Integer;
begin
  nHeatNo := 0;
  for nIndex := DOME_HEAT_MIN to DOME_HEAT_MAX do
  begin
    if FHeatInfoList[nIndex].TeeboxNm = ATeeboxNm then
    begin
      nHeatNo := nIndex;
      Break;
    end;
  end;

  Result := nHeatNo;
end;

procedure TComThreadHeat_DOME.SetHeatUseInit(ATeeboxNm, AType, AAuto, AStartTm: String); //타석별 제어상태
var
  nIndex, nHeatNo: Integer;
  sStr: String;
begin
  nHeatNo := GetHeatInfoListIdx(ATeeboxNm);
  if nHeatNo = 0 then
  begin
    sStr := 'TeeboxNm: ' + ATeeboxNm + ' / No Device ';
    Global.Log.LogHeatWrite(sStr);
    Exit;
  end;

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
end;

procedure TComThreadHeat_DOME.SetHeatUse(ATeeboxNm, AUse, AAuto, AStartTm: String); //타석별 제어상태
var
  nIndex, nHeatNo: Integer;
  sStr, sResult, sSql: String;
  sHeatCtl, sHeatCtlStatus: String;
  bAutoUse: Boolean;
begin
  nHeatNo := GetHeatInfoListIdx(ATeeboxNm);
  if nHeatNo = 0 then
  begin
    sStr := 'TeeboxNm: ' + ATeeboxNm + ' / No Device ';
    Global.Log.LogHeatWrite(sStr);
    Exit;
  end;

  sSql := '';
  sStr := '';
  sHeatCtl := GetHeatCtlData(ATeeboxNm);

  if AAuto = '1' then
  begin
    FHeatInfoList[nHeatNo].UseStatus := AUse;
    FHeatInfoList[nHeatNo].UseAuto := AAuto;
    FHeatInfoList[nHeatNo].StartTime := DateStrToDateTime2(AStartTm);
    FHeatInfoList[nHeatNo].EndTime := FHeatInfoList[nHeatNo].StartTime +
                                      (((1/24)/60) * StrToInt(Global.ADConfig.HeatTime));

    //config
    Global.SetTeeboxHeatConfig(ATeeboxNm, Global.ADConfig.HeatTime, AUse, '1', FormatDateTime('YYYY-MM-DD hh:nn:ss', Now));

    //AUse 0 일경우 DB저장시 다른타석 확인필요
    if AUse = '0' then
    begin

      bAutoUse := False;
      for nIndex := DOME_HEAT_MIN to DOME_HEAT_MAX do
      begin
        if FHeatInfoList[nIndex].HeatCtl = sHeatCtl then
        begin

          if sSql = '' then
          begin
            sSql := ' ''' + FHeatInfoList[nIndex].TeeboxNm + ''' ';
            sStr := FHeatInfoList[nIndex].TeeboxNm;
          end
          else
          begin
            sSql := sSql + ' ,''' + FHeatInfoList[nIndex].TeeboxNm + ''' ';
            sStr := sStr + ', ' + FHeatInfoList[nIndex].TeeboxNm;
          end;

          if FHeatInfoList[nIndex].UseStatus = '1' then
          begin
            bAutoUse := True;
            Break;
          end;

        end;
      end;

      if bAutoUse = True then
      begin
        sSql := '';
        sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AUse + ' / ' + AStartTm + ' -> ' + sStr + ' 사용중';
      end
      else
      begin
        sSql := '( ' + sSql + ' )';
        sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AUse + ' / ' + AStartTm + ' -> ' + sStr;
      end;
    end
    else
    begin
      //현재 타석에 해당하는 히터의 가동상태
      sHeatCtlStatus := GetHeatUseStatus(ATeeboxNm);

      if sHeatCtlStatus = '1' then
      begin
        sSql := '';
        sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AUse + ' / ' + AStartTm + ' -> 가동중';
      end
      else
      begin
        for nIndex := DOME_HEAT_MIN to DOME_HEAT_MAX do
        begin
          if FHeatInfoList[nIndex].HeatCtl = sHeatCtl then
          begin
            if sSql = '' then
            begin
              sSql := ' ''' + FHeatInfoList[nIndex].TeeboxNm + ''' ';
              sStr := FHeatInfoList[nIndex].TeeboxNm;
            end
            else
            begin
              sSql := sSql + ' ,''' + FHeatInfoList[nIndex].TeeboxNm + ''' ';
              sStr := sStr + ', ' + FHeatInfoList[nIndex].TeeboxNm;
            end;
          end;
        end;

        sSql := '( ' + sSql + ' )';
        sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AUse + ' / ' + AStartTm + ' -> ' + sStr;
      end;

    end;

  end
  else //수동제어(포스)
  begin

    for nIndex := DOME_HEAT_MIN to DOME_HEAT_MAX do
    begin
      if FHeatInfoList[nIndex].HeatCtl = sHeatCtl then
      begin
        FHeatInfoList[nIndex].UseStatus := AUse;
        FHeatInfoList[nIndex].UseAuto := AAuto;

        Global.SetTeeboxHeatConfig(FHeatInfoList[nIndex].TeeboxNm, '', AUse, '0', '');

        if sSql = '' then
        begin
          sSql := ' ''' + FHeatInfoList[nIndex].TeeboxNm + ''' ';
          sStr := FHeatInfoList[nIndex].TeeboxNm;
        end
        else
        begin
          sSql := sSql + ' ,''' + FHeatInfoList[nIndex].TeeboxNm + ''' ';
          sStr := sStr + ', ' + FHeatInfoList[nIndex].TeeboxNm;
        end;
      end;
    end;

    sSql := '( ' + sSql + ' )';
    sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AUse + ' -> ' + sStr;
  end;

  //DB
  if sSql <> '' then
  begin
    sResult := Global.XGolfDM.TeeboxHeatUseDomeUpdate(Global.ADConfig.StoreCode, sSql, AUse, AAuto);
    if sResult <> 'Success' then
    begin
      //Result := '{"result_cd":"","result_msg":"' + sResult + '"}';
      //Exit;
    end;
  end;

  Global.Log.LogHeatWrite(sStr);

end;

procedure TComThreadHeat_DOME.SetHeatUseAllOff; //장치변경에 따른 전체Off
var
  nIndex: Integer;
  sStr: String;
begin

  for nIndex := DOME_HEAT_MIN to DOME_HEAT_MAX do
  begin
    FHeatInfoList[nIndex].UseStatus := '0';
  end;

  sStr := 'All Off !!';
  Global.Log.LogHeatWrite(sStr);
end;

function TComThreadHeat_DOME.GetHeatUseStatus(ATeeboxNm: String): String; //메인화면 히터제어상태용
var
  nIndex: Integer;
  sHeatCtl, sStatus: String;
begin
  Result := '';

  sHeatCtl := GetHeatCtlData(ATeeboxNm);

  sStatus := '';
  for nIndex := 0 to 23 do
  begin
    if FHeatCtlList[nIndex].TeeboxNm = sHeatCtl then
    begin
      sStatus := FHeatCtlList[nIndex].UseStatus;
      Break;
    end;
  end;

  Result := sStatus;
end;

procedure TComThreadHeat_DOME.HeatTimeChk; //타석별 자동시간 계산
var
  nHeatNo: Integer;
  sStr: string;
begin

  for nHeatNo := DOME_HEAT_MIN to DOME_HEAT_MAX do
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

      sStr := '자동히터정지 : ' + FHeatInfoList[nHeatNo].TeeboxNm + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].StartTime) + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].EndTime);
      Global.Log.LogHeatCtrlWrite(sStr);
    end;
  end;

end;

procedure TComThreadHeat_DOME.HeatOnOffTimeChk; //타석별 자동시간 계산
begin
  if (FCtlOnTime = 0) and (FCtlOffTime = 0) then
    Exit;

  inc(FCtlCnt);

  if FCtlStatus = '1' then //On
  begin
    if FCtlOnTime < FCtlCnt then
    begin
      FCtlStatus := '0';
      FCtlCnt := 0;
    end;
  end
  else
  begin
    if FCtlOffTime < FCtlCnt then
    begin
      FCtlStatus := '1';
      FCtlCnt := 0;
    end;
  end;
end;

procedure TComThreadHeat_DOME.SetHeatCtlStatus; //히터별 상태저장
var
  nIndex: Integer;
  sStatus: String;
begin

  sStatus := '0';
  if (FHeatInfoList[1].UseStatus = '1') or (FHeatInfoList[2].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('1', sStatus);

  sStatus := '0';
  if (FHeatInfoList[3].UseStatus = '1') or (FHeatInfoList[4].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('2', sStatus);

  sStatus := '0';
  if (FHeatInfoList[5].UseStatus = '1') or (FHeatInfoList[6].UseStatus = '1') or (FHeatInfoList[7].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('3', sStatus);

  sStatus := '0';
  if (FHeatInfoList[8].UseStatus = '1') or (FHeatInfoList[9].UseStatus = '1') or (FHeatInfoList[10].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('4', sStatus);

  sStatus := '0';
  if (FHeatInfoList[11].UseStatus = '1') or (FHeatInfoList[12].UseStatus = '1') or (FHeatInfoList[13].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('5', sStatus);

  sStatus := '0';
  if (FHeatInfoList[14].UseStatus = '1') or (FHeatInfoList[15].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('6', sStatus);

  sStatus := '0';
  if (FHeatInfoList[16].UseStatus = '1') or (FHeatInfoList[17].UseStatus = '1') or (FHeatInfoList[18].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('7', sStatus);

  sStatus := '0';
  if (FHeatInfoList[19].UseStatus = '1') or (FHeatInfoList[20].UseStatus = '1') or (FHeatInfoList[21].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('8', sStatus);

  sStatus := '0';
  if (FHeatInfoList[22].UseStatus = '1') or (FHeatInfoList[23].UseStatus = '1') or (FHeatInfoList[24].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('9', sStatus);

  sStatus := '0';
  if (FHeatInfoList[25].UseStatus = '1') or (FHeatInfoList[26].UseStatus = '1') or (FHeatInfoList[27].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('10', sStatus);

  sStatus := '0';
  if (FHeatInfoList[28].UseStatus = '1') or (FHeatInfoList[29].UseStatus = '1') or (FHeatInfoList[30].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('11', sStatus);

  sStatus := '0';
  if (FHeatInfoList[31].UseStatus = '1') or (FHeatInfoList[32].UseStatus = '1') or (FHeatInfoList[33].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('12', sStatus);

  sStatus := '0';
  if (FHeatInfoList[34].UseStatus = '1') or (FHeatInfoList[35].UseStatus = '1') or (FHeatInfoList[36].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('13', sStatus);

  sStatus := '0';
  if (FHeatInfoList[37].UseStatus = '1') or (FHeatInfoList[38].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('14', sStatus);

  sStatus := '0';
  if (FHeatInfoList[39].UseStatus = '1') or (FHeatInfoList[40].UseStatus = '1') or (FHeatInfoList[41].UseStatus = '1') or (FHeatInfoList[42].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('15', sStatus);

  sStatus := '0';
  if (FHeatInfoList[43].UseStatus = '1') or (FHeatInfoList[44].UseStatus = '1') or (FHeatInfoList[45].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('16', sStatus);

  sStatus := '0';
  if (FHeatInfoList[46].UseStatus = '1') or (FHeatInfoList[47].UseStatus = '1') or (FHeatInfoList[48].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('17', sStatus);

  sStatus := '0';
  if (FHeatInfoList[49].UseStatus = '1') or (FHeatInfoList[50].UseStatus = '1') or (FHeatInfoList[51].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('18', sStatus);

  sStatus := '0';
  if (FHeatInfoList[52].UseStatus = '1') or (FHeatInfoList[53].UseStatus = '1') or (FHeatInfoList[54].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('19', sStatus);

  sStatus := '0';
  if (FHeatInfoList[55].UseStatus = '1') or (FHeatInfoList[56].UseStatus = '1') or (FHeatInfoList[57].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('20', sStatus);

  sStatus := '0';
  if (FHeatInfoList[58].UseStatus = '1') or (FHeatInfoList[59].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('21', sStatus);

  sStatus := '0';
  if (FHeatInfoList[60].UseStatus = '1') or (FHeatInfoList[61].UseStatus = '1') or (FHeatInfoList[62].UseStatus = '1') or (FHeatInfoList[63].UseStatus = '1') then
    sStatus := '1';
  SetHeatCtl('22', sStatus);
end;

procedure TComThreadHeat_DOME.SetHeatCtl(ACtlNm, AType: String); //타석제어상태를 통해 히터상태 저장
var
  nCtlNo, nIndex: Integer;
  sStr: String;
begin

  nCtlNo := 0;
  for nIndex := 0 to 23 do
  begin
    if FHeatCtlList[nIndex].TeeboxNm = ACtlNm then
    begin
      nCtlNo := nIndex;
      Break;
    end;
  end;

  FHeatCtlList[nCtlNo].UseStatus := AType;
  //sStr := 'CtlNm: ' + ACtlNm + ' / ' + AType;
  //Global.Log.LogHeatWrite(sStr);
end;

function TComThreadHeat_DOME.GetHeatCtlData(ATeeboxNm: String): String; //타석에 해당하는 히터정보
begin
  Result := '';  // 20/21   41/42   62/63

  if (ATeeboxNm = '1') or (ATeeboxNm = '2') then Result := '1'
  else if (ATeeboxNm = '3') or (ATeeboxNm = '4') then Result := '2'
  else if (ATeeboxNm = '5') or (ATeeboxNm = '6') or (ATeeboxNm = '7') then Result := '3'
  else if (ATeeboxNm = '8') or (ATeeboxNm = '9') or (ATeeboxNm = '10') then Result := '4'
  else if (ATeeboxNm = '11') or (ATeeboxNm = '12') or (ATeeboxNm = '13') then Result := '5'
  else if (ATeeboxNm = '14') or (ATeeboxNm = '15') then Result := '6'
  else if (ATeeboxNm = '16') or (ATeeboxNm = '17') or (ATeeboxNm = '18') then Result := '7'
  else if (ATeeboxNm = '19') or (ATeeboxNm = '20') or (ATeeboxNm = '21') or (ATeeboxNm = '20/21') then Result := '8'
  else if (ATeeboxNm = '22') or (ATeeboxNm = '23') or (ATeeboxNm = '24') then Result := '9'
  else if (ATeeboxNm = '25') or (ATeeboxNm = '26') or (ATeeboxNm = '27') then Result := '10'
  else if (ATeeboxNm = '28') or (ATeeboxNm = '29') or (ATeeboxNm = '30') then Result := '11'
  else if (ATeeboxNm = '31') or (ATeeboxNm = '32') or (ATeeboxNm = '33') then Result := '12'
  else if (ATeeboxNm = '34') or (ATeeboxNm = '35') or (ATeeboxNm = '36') then Result := '13'
  else if (ATeeboxNm = '37') or (ATeeboxNm = '38') then Result := '14'
  else if (ATeeboxNm = '39') or (ATeeboxNm = '40') or (ATeeboxNm = '41') or (ATeeboxNm = '42') or (ATeeboxNm = '41/42') then Result := '15'
  else if (ATeeboxNm = '43') or (ATeeboxNm = '44') or (ATeeboxNm = '45') then Result := '16'
  else if (ATeeboxNm = '46') or (ATeeboxNm = '47') or (ATeeboxNm = '48') then Result := '17'
  else if (ATeeboxNm = '49') or (ATeeboxNm = '50') or (ATeeboxNm = '51') then Result := '18'
  else if (ATeeboxNm = '52') or (ATeeboxNm = '53') or (ATeeboxNm = '54') then Result := '19'
  else if (ATeeboxNm = '55') or (ATeeboxNm = '56') or (ATeeboxNm = '57') then Result := '20'
  else if (ATeeboxNm = '58') or (ATeeboxNm = '59') then Result := '21'
  else if (ATeeboxNm = '60') or (ATeeboxNm = '61') or (ATeeboxNm = '62') or (ATeeboxNm = '63') or (ATeeboxNm = '62/63') then Result := '22';

end;

procedure TComThreadHeat_DOME.Execute;
var
  bControlMode: Boolean;
  sBcc: AnsiString;
  sLogMsg, sChannelR, sChannelL: String;
  nSeatNo, nIndex: Integer;
  btBcc: Byte;
begin
  inherited;

  while not Terminated do
  begin
    try

      if not FComPort.Connected then
      begin
        FComPort.Open;
      end;

      Synchronize(SetHeatCtlStatus);

      FSendData := '';

      if FCtlStatus = '1' then
      begin
        for nIndex := 0 to 23 do
        begin
          FSendData := FSendData + FHeatCtlList[nIndex].UseStatus;
        end;
        FSendData := FSendData + '0000000000000000000000000000000';
      end
      else
      begin
        for nIndex := 0 to 54 do
        begin
          FSendData := FSendData + '0';
        end;
      end;

      btBcc := $00;
      for nIndex := 0 to Length(FSendData) - 1 do
      begin
        btBcc := btBcc + byte(FSendData[nIndex]);
      end;
      btBcc := 44 + btBcc;
      sBcc := Chr(btBcc);

      FSendData := 's' + '10155' + FSendData + sBcc + 'e';

      FComPort.Write(FSendData[1], Length(FSendData));
      Global.Log.LogHeatCtrlWrite('CtlStatus : ' + FCtlStatus + ' / ' + FSendData);

      Sleep(1000);

      //히터 자동사용시 타이머 체크
      Synchronize(HeatTimeChk);

      //시간설정에 따른 On/Off
      Synchronize(HeatOnOffTimeChk);

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadHeat_DOME Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogHeatCtrlWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
