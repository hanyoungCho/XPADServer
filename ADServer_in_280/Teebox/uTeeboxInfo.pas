unit uTeeboxInfo;

interface

uses
  uStruct, uConsts,
  System.Classes, System.SysUtils, System.DateUtils,
  Uni, System.Generics.Collections;

type
  TTeebox = class
  private

    FTeeboxInfoList: array of TTeeboxInfo;

    FTeeboxCnt: Integer;
    //FTeeboxLastNo: Integer;
    //FTeeboxTapoOnOffCheckLastIndex: Integer;

    FBallBackUse: Boolean; //��ȸ������, ��ȸ���� Ű����ũ���� Ȧ��, ���� ��������

    FTeeboxStatusUse: Boolean;
    FTeeboxReserveUse: Boolean;

  public
    constructor Create;
    destructor Destroy; override;

    procedure StartUp;

    function GetTeeboxListToApi: Boolean;
    function GetTeeboxListToDB: Boolean; //��޹�����
    function SetTeeboxStartUseStatus: Boolean; //���ʽ����

    //Teebox Thread
    //�ý��ۻ󿡼� �ð����
    procedure TeeboxReserveChk;
    procedure TeeboxStatusChk;
    //procedure TeeboxAgentChk; //������Ʈ ���������
    procedure TeeboxTapoOnOff;
    //procedure TeeboxTapoOnOffCheck;

    procedure TeeboxReserveNextChk;

    procedure SendBeamEnd;
    procedure SendBeamStartReCtl;

    //Teebox Thread

    //Ÿ������ set
    procedure SetStoreClose;
    procedure SetTeeboxIP(AMac, AIP: String);
    procedure SetTeeboxOnOff(AIP, AOnOff: String);
    procedure SetTeeboxTapoError(AIP: String);
    procedure SetTeeboxAgentCtlYN(AIP, ARecive: String); //agent ���俩��

    procedure SetTeeboxCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin, ASecond: Integer);
    procedure SetTeeboxVXCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin: Integer);
    procedure SetTeeboxBeamCtrl(AType: String; AReserveNo: String; ATeeboxNo: Integer);
    //procedure SetTeeboxErrorCnt(ATeeboxNo: Integer; AError: String; AMaxCnt: Integer);
    procedure SetTeeboxAgentMac(ATeeboxNo: Integer; AType: String; AMAC: String);

    function TeeboxDeviceCheck(ATeeboxNo: Integer; AType: String): Boolean; //����Ȯ��

    //Ÿ������ get
    function GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
    function GetTeeboxIndexInfo(AIndex: Integer): TTeeboxInfo;
    function GetTeeboxInfoIndex(ATeeboxNo: Integer): Integer; //Ÿ����ȣ�� ���� �ε��� ����
    function GetTeeboxInfoTeeboxNo(AIndex: Integer): Integer; //�ε����� ���� Ÿ��No ����
    function GetTeeboxInfoIP(AMac: String): String;
    function GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
    //function GetTeeboxInfoUseYn(ATeeboxNo: Integer): String;
    function GetTeeboxFloorNm(ATeeboxNo: Integer): String;
    function GetReserveEndTime(ATeeboxNo: Integer): Integer; //Ÿ������ ����ð����� �ʷ� ����
    function GetReservePrepareEndTime(ATeeboxNo: Integer): Integer; //Ÿ������ ����ð����� �ʷ� ����

    function TeeboxBallRecallStart: Boolean;
    function TeeboxBallRecallEnd: Boolean;
    procedure SetTeeboxDelay(AIndex: Integer; AType: Integer);
    function ResetTeeboxRemainMinAdd(AIndex, ADelayTm: Integer; ATeeboxNm: String): Boolean;

    //Ÿ������ ERP ���ۿ�
    function GetTeeboxStatusList: AnsiString;
    function GetTeeboxStatus(ATeeboxNo: String): AnsiString;

    function SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
    function GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;

    function SetTeeboxReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
    function SetTeeboxReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
    function SetTeeboxReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String; //��ù���
    function SetTeeboxReserveCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean; //üũ��

    //����ð� Ȯ��
    function GetTeeboxNowReserveLastTime(ATeeboxNo: String): String; //2021-04-19 ���ð� ���� ����ð� ����

    //���� ������ Ȯ�ο�
    function SetTeeboxReservePrepare(ATeeboxNo: Integer): String;

    //agent server port
    function SendTeeboxReserveStatus(ATeeboxNo: String): Boolean;
    function SendAgentSetting(ATeeboxNo, AMethod: String): Boolean;

    procedure SendADStatusToErp;

    procedure SendAgentWOL;
    procedure SendAgentOneWOL(ATeeboxNo: Integer);

    function TeeboxClear: Boolean;

    property TeeboxCnt: Integer read FTeeboxCnt write FTeeboxCnt;
    //property TeeboxLastNo: Integer read FTeeboxLastNo write FTeeboxLastNo;
    property BallBackUse: Boolean read FBallBackUse write FBallBackUse;
    property TeeboxStatusUse: Boolean read FTeeboxStatusUse write FTeeboxStatusUse;
    property TeeboxReserveUse: Boolean read FTeeboxReserveUse write FTeeboxReserveUse;
  end;

implementation

uses
  uGlobal, uFunction, JSON;

{ Tasuk }

constructor TTeebox.Create;
begin
  //TeeboxLastNo := 0;
  //FTeeboxTapoOnOffCheckLastIndex := 0;
  FTeeboxStatusUse := False;
  FTeeboxReserveUse := False;
end;

destructor TTeebox.Destroy;
begin
  TeeboxClear;

  inherited;
end;

procedure TTeebox.StartUp;
begin
  if Global.ADConfig.Emergency = False then
    GetTeeboxListToApi
  else
    GetTeeboxListToDB;

  Global.ReserveList.StartUp;

  SetTeeboxStartUseStatus;
end;

function TTeebox.GetTeeboxListToApi: Boolean;
var
  nIndex: Integer;
  nTeeboxNo: Integer;
  jObjArr: TJsonArray;
  jObj, jObjSub: TJSONObject;

  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;
begin
  Result := False;

  try

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                '&client_id=' + Global.ADConfig.UserId;

    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K204_TeeBoxlist', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
    Global.Log.LogWrite(sResult);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'GetSeatListToApi Fail : ' + sResult;
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K204_TeeBoxlist : ' + sResultCd + ' / ' + sResultMsg;
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObjArr := jObj.GetValue('result_data') as TJsonArray;

    FTeeboxCnt := jObjArr.Size;
    SetLength(FTeeboxInfoList, FTeeboxCnt);

    for nIndex := 0 to FTeeboxCnt - 1 do
    begin
      jObjSub := jObjArr.Get(nIndex) as TJSONObject;
      nTeeboxNo := StrToInt(jObjSub.GetValue('teebox_no').Value);

      FTeeboxInfoList[nIndex].TeeboxNo := nTeeboxNo;
      FTeeboxInfoList[nIndex].TeeboxNm := jObjSub.GetValue('teebox_nm').Value;
      FTeeboxInfoList[nIndex].FloorZoneCode := jObjSub.GetValue('floor_cd').Value;
      FTeeboxInfoList[nIndex].FloorNm := jObjSub.GetValue('floor_nm').Value;
      FTeeboxInfoList[nIndex].TeeboxZoneCode := jObjSub.GetValue('zone_div').Value;

      //FTeeboxInfoList[nTeeboxNo].ControlYn := jObjSub.GetValue('control_yn').Value;
      FTeeboxInfoList[nIndex].TapoMac := jObjSub.GetValue('device_id').Value;

      FTeeboxInfoList[nIndex].UseYn := jObjSub.GetValue('use_yn').Value;
      FTeeboxInfoList[nIndex].DelYn := jObjSub.GetValue('del_yn').Value;

      FTeeboxInfoList[nIndex].UseStatus := '0';
      FTeeboxInfoList[nIndex].ComReceive := 'N'; //���� 1ȸ üũ

      FTeeboxInfoList[nIndex].TapoIP := Global.ReadConfigTapoIP(nTeeboxNo);

      if Trim(FTeeboxInfoList[nIndex].TapoMac) = EmptyStr then
        FTeeboxInfoList[nIndex].TapoMac := Global.ReadConfigTapoMAC(nTeeboxNo);

      FTeeboxInfoList[nIndex].AgentIP_R := Global.ReadConfigAgentIP_R(nTeeboxNo);
      FTeeboxInfoList[nIndex].AgentIP_L := Global.ReadConfigAgentIP_L(nTeeboxNo);

      if Global.ADConfig.AgentWOL = True then
      begin
        FTeeboxInfoList[nIndex].AgentMAC_R := Global.ReadConfigAgentMAC_R(nTeeboxNo);
        FTeeboxInfoList[nIndex].AgentMAC_L := Global.ReadConfigAgentMAC_L(nTeeboxNo);
      end;

      if Global.ADConfig.BeamProjectorUse = True then
      begin
        FTeeboxInfoList[nIndex].BeamType := Global.ReadConfigBeamType(nTeeboxNo);
        FTeeboxInfoList[nIndex].BeamPW := Global.ReadConfigBeamPW(nTeeboxNo);
        FTeeboxInfoList[nIndex].BeamIP := Global.ReadConfigBeamIP(nTeeboxNo);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;

  Result := True;
end;

function TTeebox.GetTeeboxListToDB: Boolean;
var
  rTeeboxInfoList: TList<TTeeboxInfo>;
  nIndex: Integer;
begin
  Result := False;

  rTeeboxInfoList := Global.XGolfDM.SeatSelect;

  try
    FTeeboxCnt := rTeeboxInfoList.Count;
    SetLength(FTeeboxInfoList, FTeeboxCnt);

    for nIndex := 0 to FTeeboxCnt - 1 do
    begin
      FTeeboxInfoList[nIndex].TeeboxNo := rTeeboxInfoList[nIndex].TeeboxNo;
      FTeeboxInfoList[nIndex].TeeboxNm := rTeeboxInfoList[nIndex].TeeboxNm;
      FTeeboxInfoList[nIndex].FloorZoneCode := rTeeboxInfoList[nIndex].FloorZoneCode;
      //FTeeboxInfoList[nTeeboxNo].FloorNm := rTeeboxInfoList[I].FloorNm;
      FTeeboxInfoList[nIndex].TeeboxZoneCode := rTeeboxInfoList[nIndex].TeeboxZoneCode;
      //FTeeboxInfoList[nTeeboxNo].ControlYn := 'Y';

      FTeeboxInfoList[nIndex].UseYn := rTeeboxInfoList[nIndex].UseYn;
      FTeeboxInfoList[nIndex].UseStatus := '0';
      FTeeboxInfoList[nIndex].ComReceive := 'N'; //���� 1ȸ üũ

      FTeeboxInfoList[nIndex].TapoIP := Global.ReadConfigTapoIP(FTeeboxInfoList[nIndex].TeeboxNo);
      FTeeboxInfoList[nIndex].TapoMac := Global.ReadConfigTapoMAC(FTeeboxInfoList[nIndex].TeeboxNo);

      FTeeboxInfoList[nIndex].AgentIP_R := Global.ReadConfigAgentIP_R(FTeeboxInfoList[nIndex].TeeboxNo);
      FTeeboxInfoList[nIndex].AgentIP_L := Global.ReadConfigAgentIP_L(FTeeboxInfoList[nIndex].TeeboxNo);

      if Global.ADConfig.AgentWOL = True then
      begin
        FTeeboxInfoList[nIndex].AgentMAC_R := Global.ReadConfigAgentMAC_R(FTeeboxInfoList[nIndex].TeeboxNo);
        FTeeboxInfoList[nIndex].AgentMAC_L := Global.ReadConfigAgentMAC_L(FTeeboxInfoList[nIndex].TeeboxNo);
      end;

      if Global.ADConfig.BeamProjectorUse = True then
      begin
        FTeeboxInfoList[nIndex].BeamType := Global.ReadConfigBeamType(FTeeboxInfoList[nIndex].TeeboxNo);
        FTeeboxInfoList[nIndex].BeamIP := Global.ReadConfigBeamIP(FTeeboxInfoList[nIndex].TeeboxNo);
      end;
    end;

  finally
    FreeAndNil(rTeeboxInfoList);
  end;

  Result := True;
end;

function TTeebox.SetTeeboxStartUseStatus: Boolean;
var
  rTeeboxInfoList: TList<TTeeboxInfo>;
  rSeatUseReserveList: TList<TSeatUseReserve>;

  i, j, nTeeboxNo, nIndex: Integer;
  sStausChk, sBallBackStart: String;
  sStr, sPreDate: String;

  NextReserve: TNextReserve;
  nErpReserveNo: Integer;
begin
  rTeeboxInfoList := Global.XGolfDM.SeatSelect;

  for i := 0 to FTeeboxCnt - 1 do
  begin

    nTeeboxNo := FTeeboxInfoList[i].TeeboxNo;

    nIndex := -1;
    for j := 0 to rTeeboxInfoList.Count - 1 do
    begin
      if rTeeboxInfoList[j].TeeboxNo = nTeeboxNo then
      begin
        nIndex := j;
        Break;
      end;
    end;

    if nIndex = -1 then
    begin
      Global.XGolfDM.SeatInsert(Global.ADConfig.StoreCode, FTeeboxInfoList[i]);
      Continue;
    end;

    if (FTeeboxInfoList[i].TeeboxNm <> rTeeboxInfoList[nIndex].TeeboxNm) or
       (FTeeboxInfoList[i].FloorZoneCode <> rTeeboxInfoList[nIndex].FloorZoneCode) or
       (FTeeboxInfoList[i].TeeboxZoneCode <> rTeeboxInfoList[nIndex].TeeboxZoneCode) or
       //(FTeeboxInfoList[i].MacAddress <> rTeeboxInfoList[nIndex].MacAddress) or
       (FTeeboxInfoList[i].UseYn <> rTeeboxInfoList[nIndex].UseYn) or
       (FTeeboxInfoList[i].DelYn <> rTeeboxInfoList[nIndex].DelYn) then
    begin
      Global.XGolfDM.SeatUpdate(Global.ADConfig.StoreCode, FTeeboxInfoList[i]);
    end;

    FTeeboxInfoList[i].UseStatusPre := rTeeboxInfoList[nIndex].UseStatus;
    FTeeboxInfoList[i].UseStatus := rTeeboxInfoList[nIndex].UseStatus;

    if FTeeboxInfoList[i].UseStatus = '7' then
    begin
      sStausChk := '7';
      FTeeboxInfoList[i].RemainMinPre := rTeeboxInfoList[nIndex].RemainMinute;
      FTeeboxInfoList[i].RemainMinute := rTeeboxInfoList[nIndex].RemainMinute;

      if FTeeboxInfoList[i].RemainMinute > 0 then
        FTeeboxInfoList[i].UseStatusPre := '1'
      else
        FTeeboxInfoList[i].UseStatusPre := '0';
    end;

    if rTeeboxInfoList[nIndex].RemainMinute > 0 then
      FTeeboxInfoList[i].TapoOnOff := 'On'
    else
      FTeeboxInfoList[i].TapoOnOff := 'Off';

    FTeeboxInfoList[i].TapoError := False;

    //FTeeboxInfoList[nTeeboxNo].RemainMinPre := 0;
    //FTeeboxInfoList[nTeeboxNo].RemainMinute := 0;

    FTeeboxInfoList[i].HoldUse := False;
    FTeeboxInfoList[i].HoldUse := rTeeboxInfoList[nIndex].HoldUse;
    FTeeboxInfoList[i].HoldUser := rTeeboxInfoList[nIndex].HoldUser;

    if FTeeboxInfoList[i].HoldUse = True then
    begin
      sStr := 'HoldUse : ' + IntToStr(FTeeboxInfoList[i].TeeboxNo) + ' / ' + FTeeboxInfoList[i].TeeboxNm;
      Global.Log.LogWrite(sStr);
    end;

  end;
  FreeAndNil(rTeeboxInfoList);

  //���� ���� ����
  if FormatDateTime('hh', now) <= Copy(Global.Store.StartTime, 1, 2) then
  begin
    sPreDate := FormatDateTime('YYYYMMDD', now - 1);
    Global.XGolfDM.SeatUseStoreClose(Global.ADConfig.StoreCode, Global.ADConfig.UserId, sPreDate);
  end;

  //Ÿ�� �������� �Ǵ� �ٷ� ������ �����
  rSeatUseReserveList := Global.XGolfDM.SeatUseAllReserveSelect(Global.ADConfig.StoreCode, '');
  for i := 0 to rSeatUseReserveList.Count - 1 do
  begin
    nIndex := GetTeeboxInfoIndex(rSeatUseReserveList[i].SeatNo);

    FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo := rSeatUseReserveList[i].ReserveNo;
    FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := rSeatUseReserveList[i].UseMinute;
    FTeeboxInfoList[nIndex].TeeboxReserve.AssignBalls := rSeatUseReserveList[i].UseBalls;
    FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin := rSeatUseReserveList[i].DelayMinute;
    FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate := rSeatUseReserveList[i].ReserveDate;
    FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate) +
                                                        (((1/24)/60) * FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin);

    FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate := rSeatUseReserveList[i].StartTime;
    if rSeatUseReserveList[i].UseStatus = '1' then
    begin
      //FTeeboxInfoList[nTeeboxNo].UseStatusPre := '1';
      //FTeeboxInfoList[nTeeboxNo].UseStatus := '1';
      FTeeboxInfoList[nIndex].TeeboxReserve.ReserveYn := 'Y';
      Global.Log.LogReserveWrite('UseStatus = 1 '  + rSeatUseReserveList[i].ReserveNo);
    end;

    FTeeboxInfoList[nIndex].TeeboxReserve.AssignYn := rSeatUseReserveList[i].AssignYn;

    sStr := '��� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' + FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin);
    Global.Log.LogReserveWrite(sStr);

  end;
  FreeAndNil(rSeatUseReserveList);

  //Ÿ�� ���� �����,������� ������ ������ ������
  rSeatUseReserveList := Global.XGolfDM.SeatUseAllReserveSelectNext(Global.ADConfig.StoreCode);

  for i := 0 to rSeatUseReserveList.Count - 1 do
  begin
    if rSeatUseReserveList[i].SeatNo = 0 then
      Continue;

    nIndex := GetTeeboxInfoIndex(rSeatUseReserveList[i].SeatNo);

    if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo = rSeatUseReserveList[i].ReserveNo then
      Continue;

    Global.ReserveList.SetTeeboxReserveNext(rSeatUseReserveList[i]);

    sStr := '������ : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' + rSeatUseReserveList[i].ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;

  FreeAndNil(rSeatUseReserveList);
  {
  if (Global.Store.StartTime > Global.Store.EndTime) then
  begin

    if FormatDateTime('HH:NN', Now) < Global.Store.EndTime then
    begin
      Global.TcpServer.UseSeqNo := Global.XGolfDM.ReserveDateNo(Global.ADConfig.StoreCode, FormatDateTime('YYYYMMDD', Now - 1));
      Global.TcpServer.LastUseSeqNo := Global.TcpServer.UseSeqNo;
      Global.TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now - 1);
    end
    else
    begin
      Global.TcpServer.UseSeqNo := Global.XGolfDM.ReserveDateNo(Global.ADConfig.StoreCode, FormatDateTime('YYYYMMDD', Now));
      Global.TcpServer.LastUseSeqNo := Global.TcpServer.UseSeqNo;
      Global.TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now);
    end;

  end
  else    }
  begin
    Global.TcpServer.UseSeqNo := Global.XGolfDM.ReserveDateNo(Global.ADConfig.StoreCode, FormatDateTime('YYYYMMDD', Now));
    Global.TcpServer.LastUseSeqNo := Global.TcpServer.UseSeqNo;
    Global.TcpServer.UseSeqDate := FormatDateTime('YYYYMMDD', Now);
  end;

  //���۽� ��ȸ�� �����̸�
  if sStausChk = '7' then
  begin
    sBallBackStart := Global.ReadConfigBallBackStartTime;
    if sBallBackStart = '' then
      FTeeboxInfoList[0].PauseTime := Now
    else
      FTeeboxInfoList[0].PauseTime := DateStrToDateTime2(sBallBackStart);

    //2020-10-30 ��ȸ�� üũ
    FBallBackUse := True;
  end;
end;

function TTeebox.TeeboxDeviceCheck(ATeeboxNo: Integer; AType: String): Boolean;
var
  nIndex: Integer;
begin
  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  FTeeboxInfoList[nIndex].UseStatus := AType;
end;

function TTeebox.GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
var
  nIndex: Integer;
begin
  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  Result := FTeeboxInfoList[nIndex];
end;

function TTeebox.GetTeeboxIndexInfo(AIndex: Integer): TTeeboxInfo;
begin
  Result := FTeeboxInfoList[AIndex];
end;

function TTeebox.GetTeeboxInfoIndex(ATeeboxNo: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FTeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[i].TeeboxNo = ATeeboxNo then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TTeebox.GetTeeboxInfoTeeboxNo(AIndex: Integer): Integer;
begin
  Result := FTeeboxInfoList[AIndex].TeeboxNo;
end;

function TTeebox.GetTeeboxInfoIP(AMac: String): String;
var
  i: Integer;
begin
  for i := 0 to FTeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[i].TapoMac = AMac then
    begin
      Result := FTeeboxInfoList[i].TapoIP;
      Break;
    end;
  end;
end;

function TTeebox.GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
var
  i: Integer;
begin
  for i := 0 to FTeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[i].TeeboxNm = ATeeboxNm then
    begin
      Result := FTeeboxInfoList[i];
      Break;
    end;
  end;
end;


function TTeebox.SetTeeboxReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
var
  nIndex: Integer;
  sStr: String;
begin

  nIndex := GetTeeboxInfoIndex(ASeatReserveInfo.SeatNo);

  if nIndex = -1 then
  begin
    sStr := 'TeeboxNo error : ' + IntToStr(ASeatReserveInfo.SeatNo);
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo = ASeatReserveInfo.ReserveNo then
  begin
    sStr := '���Ͽ���� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
          ASeatReserveInfo.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo := ASeatReserveInfo.ReserveNo;
  FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := ASeatReserveInfo.UseMinute;
  FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin := ASeatReserveInfo.DelayMinute;
  if FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin < 0 then
    FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin := 0;

  FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate := ASeatReserveInfo.ReserveDate;
  FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate := '';
  FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate := '';
  FTeeboxInfoList[nIndex].TeeboxReserve.PrepareYn := 'N';
  FTeeboxInfoList[nIndex].TeeboxReserve.ReserveYn := 'N';
  FTeeboxInfoList[nIndex].TeeboxReserve.AssignYn:= ASeatReserveInfo.AssignYn;

  if ASeatReserveInfo.ReserveDate <= formatdatetime('YYYYMMDDhhnnss', Now) then
  begin
    FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
    FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime := Now + (((1/24)/60) * FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin);
  end
  else
  begin
    FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate := ASeatReserveInfo.ReserveDate;
    FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate) +
                                                         (((1/24)/60) * FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin);
  end;

  FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate := '';
  FTeeboxInfoList[nIndex].UseCancel := 'N';
  FTeeboxInfoList[nIndex].UseClose := 'N';

  FTeeboxInfoList[nIndex].BeamStartDT := '';
  FTeeboxInfoList[nIndex].BeamReCtl := False;

end;

function TTeebox.SetTeeboxReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
var
  nIndex, nCtlMin, nCtlSecond, nVXMin: Integer;
  sStr: String;
begin
  Result:= False;

  nIndex := GetTeeboxInfoIndex(ASeatUseInfo.SeatNo);
  if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo <> ASeatUseInfo.ReserveNo then
  begin
    Global.ReserveList.SetTeeboxReserveNextChange(FTeeboxInfoList[nIndex].TeeboxNo, ASeatUseInfo);
    Exit;
  end;

  //���ð�/�����ð� ���� üũ
  if (FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin = ASeatUseInfo.PrepareMin) and
     (FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin = ASeatUseInfo.AssignMin) then
  begin
    //����� ���� ����
    Exit;
  end;

  if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveYn = 'N' then
  begin
    sStr := '��������ð����� no: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
            '���ð�' + IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin) + ' -> ' +
            IntToStr(ASeatUseInfo.PrepareMin) + ' / ' +
            '�����ð�' + IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' -> ' +
            IntToStr(ASeatUseInfo.AssignMin);

    if FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin <> ASeatUseInfo.AssignMin then
      FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := ASeatUseInfo.AssignMin;

    if FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin <> ASeatUseInfo.PrepareMin then
    begin
      FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate) +
                                                          (((1/24)/60) * ASeatUseInfo.PrepareMin);
      FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin := ASeatUseInfo.PrepareMin;

      if Global.ADConfig.PrepareUse = 'Y' then
      begin
        FTeeboxInfoList[nIndex].AgentCtlType := 'D';
        FTeeboxInfoList[nIndex].AgentCtlYNPre := '0';
        FTeeboxInfoList[nIndex].AgentCtlYn := '0';
        nCtlSecond := GetReservePrepareEndTime(FTeeboxInfoList[nIndex].TeeboxNo);
        SetTeeboxCtrl('Tprepare', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin, nCtlSecond);
      end;

    end;
  end
  else
  begin
    //�������� �����ð� ���游 üũ
    if FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin <> ASeatUseInfo.AssignMin then
    begin

      //�����ð����� ���� ����迭�� ���
      nCtlMin := FTeeboxInfoList[nIndex].RemainMinute + (ASeatUseInfo.AssignMin - FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin);
      nVXMin := ASeatUseInfo.AssignMin - FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin;

      sStr := '�����ð����� no: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
              '�����ð�' + IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' -> ' +
              IntToStr(ASeatUseInfo.AssignMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' -> ' +
              IntToStr(nCtlMin);

      //FTeeboxInfoList[nTeeboxNo].ChangeMin := nCtlMin;
      FTeeboxInfoList[nIndex].RemainMinute := nCtlMin;
      FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := ASeatUseInfo.AssignMin;

      nCtlSecond := GetReserveEndTime(FTeeboxInfoList[nIndex].TeeboxNo);

      if nVXMin > 0 then
        SetTeeboxVXCtrl('VXadd', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, nVXMin);

      FTeeboxInfoList[nIndex].AgentCtlType := 'C';
      FTeeboxInfoList[nIndex].AgentCtlYNPre := '0';
      FTeeboxInfoList[nIndex].AgentCtlYn := '0';

      SetTeeboxCtrl('Tchange', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, nCtlMin, nCtlSecond);
     end;

  end;

  Global.Log.LogReserveWrite(sStr);
  Result:= True;
end;

function TTeebox.SetTeeboxReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
  nIndex: Integer;
begin
  Result := False;

  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    //������, ������ Ÿ���� �ƴ�
    Global.ReserveList.SetTeeboxReserveNextCancel(ATeeboxNo, AReserveNo);
    Exit;
  end;

  //������� ����迭�� ���
  FTeeboxInfoList[nIndex].UseCancel := 'Y';

  FTeeboxInfoList[nIndex].RemainMinute := 0;

  sStr := 'Cancel no: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

function TTeebox.SetTeeboxReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
  nIndex: Integer;
begin
  Result := False;

  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    Exit;
  end;

  FTeeboxInfoList[nIndex].UseClose := 'Y';
  FTeeboxInfoList[nIndex].RemainMinute := 0;

  sStr := 'Close no: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo;
  Global.Log.LogReserveWrite(sStr);
  Result := True;
end;

//��ù���
function TTeebox.SetTeeboxReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sStr, sResult: String;
  nIndex: Integer;
begin
  Result := '';

  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  if FTeeboxInfoList[nIndex].UseStatus <> '0' then
  begin
    Result := '������� Ÿ���Դϴ�.';
    Exit;
  end;

  if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo = AReserveNo then
  begin
    FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
    FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime := Now;

    sStr := '��ù��� ��� no: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end
  else
  begin
    sResult := Global.ReserveList.SetTeeboxReserveNextStartNow(ATeeboxNo, AReserveNo);
    if sResult <> 'Success' then
    begin
      Result := sResult;
      Exit;
    end;
  end;

  Result := 'Success';
end;

procedure TTeebox.TeeboxStatusChk;
var
  nIndex: Integer;
begin

  for nIndex := 0 to FTeeboxCnt - 1 do
  begin

    if (FTeeboxInfoList[nIndex].UseStatus <> '7') and (FTeeboxInfoList[nIndex].UseStatus <> '8') then //����
    begin
      if FTeeboxInfoList[nIndex].RemainMinute = 0 then
        FTeeboxInfoList[nIndex].UseStatus := '0'
      else
        FTeeboxInfoList[nIndex].UseStatus := '1';
    end;

    if FTeeboxInfoList[nIndex].AgentCtlYNPre <> FTeeboxInfoList[nIndex].AgentCtlYN then
    begin
      if FTeeboxInfoList[nIndex].AgentCtlYN = '1' then
        Global.XGolfDM.UpdateTeeboxAgentStatus(Global.ADConfig.StoreCode, FTeeboxInfoList[nIndex].TeeboxNo, '1') //�������
      else
        Global.XGolfDM.UpdateTeeboxAgentStatus(Global.ADConfig.StoreCode, FTeeboxInfoList[nIndex].TeeboxNo, '0');

      FTeeboxInfoList[nIndex].AgentCtlYNPre := FTeeboxInfoList[nIndex].AgentCtlYN;
    end;

    // DB����: Ÿ�������(�ð�,����)
    if FTeeboxInfoList[nIndex].RemainMinPre <> FTeeboxInfoList[nIndex].RemainMinute then
    begin
      Global.XGolfDM.TeeboxInfoUpdate(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].UseStatus);
    end;

    FTeeboxInfoList[nIndex].RemainMinPre := FTeeboxInfoList[nIndex].RemainMinute;
  end;

  Sleep(10);
end;
{
procedure TTeebox.TeeboxAgentChk;
var
  nIndex, nMin, nSecond: Integer;
begin

  for nIndex := 0 to FTeeboxCnt - 1 do
  begin

    //Agent�� 1ȸ ��õ�,  �ð��� ����Ǿ��������� �Ǵ�, �� �ٽð��
    if FTeeboxInfoList[nIndex].AgentCtlYn = '0' then
    begin
      if FTeeboxInfoList[nIndex].AgentCtlType = 'D' then
      begin
        FTeeboxInfoList[nIndex].AgentCtlYNPre := '2';
        FTeeboxInfoList[nIndex].AgentCtlYn := '2';

        nSecond := GetReservePrepareEndTime(FTeeboxInfoList[nIndex].TeeboxNo);
        if (nSecond mod 60) > 0 then
          nMin := (nSecond div 60) + 1
        else
          nMin := (nSecond div 60);

        SetTeeboxCtrl('Tprepare', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, nMin, nSecond);
      end;

      if FTeeboxInfoList[nIndex].AgentCtlType = 'S' then
      begin
        FTeeboxInfoList[nIndex].AgentCtlYNPre := '2';
        FTeeboxInfoList[nIndex].AgentCtlYn := '2';
        nSecond := GetReserveEndTime(FTeeboxInfoList[nIndex].TeeboxNo);
        SetTeeboxCtrl('Tstart', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].RemainMinute, nSecond);
      end;

      if FTeeboxInfoList[nIndex].AgentCtlType = 'C' then
      begin
        FTeeboxInfoList[nIndex].AgentCtlYNPre := '2';
        FTeeboxInfoList[nIndex].AgentCtlYn := '2';
        nSecond := GetReserveEndTime(FTeeboxInfoList[nIndex].TeeboxNo);
        SetTeeboxCtrl('Tchange', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].RemainMinute, nSecond);
      end;

      if FTeeboxInfoList[nIndex].AgentCtlType = 'E' then
      begin
        FTeeboxInfoList[nIndex].AgentCtlYNPre := '2';
        FTeeboxInfoList[nIndex].AgentCtlYn := '2';
        SetTeeboxCtrl('Tend', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, 0, 0);
      end;

    end;

  end;

  Sleep(10);
end;
}
procedure TTeebox.TeeboxTapoOnOff;
var
  nIndex: Integer;
  sStr: String;
begin
  if Global.TapoCtrlLock = True then
    Exit;

  for nIndex := 0 to FTeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[nIndex].TapoIP = EmptyStr then
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '7' then
    begin
      if FTeeboxInfoList[nIndex].TapoOnOff <> 'Off' then
      begin
        sStr := 'UseStatus = 7 : On -> Off / No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo);
        Global.Log.LogCtrlWrite(sStr);

        Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[nIndex].TapoIP, False, False);
      end;
    end
    else
    begin

      if FTeeboxInfoList[nIndex].RemainMinute > 0 then
      begin
        if FTeeboxInfoList[nIndex].TapoOnOff <> 'On' then
        begin
          sStr := 'RemainMinute > 0 : Off -> On / No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo);
          Global.Log.LogCtrlWrite(sStr);

          Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[nIndex].TapoIP, True, False);
        end;
      end
      else
      begin
        if FTeeboxInfoList[nIndex].TapoOnOff <> 'Off' then
        begin
          sStr := 'RemainMinute =< 0 : On -> Off / No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo);
          Global.Log.LogCtrlWrite(sStr);

          Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[nIndex].TapoIP, False, False);
        end;
      end;
    end;

  end;

  Sleep(10);
end;
{
procedure TTeebox.TeeboxTapoOnOffCheck;
var
  nIndex: Integer;
begin
  if Global.TapoCtrlLock = True then
    Exit;
  
  nIndex := FTeeboxTapoOnOffCheckLastIndex;
  if FTeeboxInfoList[nIndex].TapoIP <> EmptyStr then
  begin
    Global.Log.LogCtrlWrite( 'GetDeviceInfo Teebox : ' + FTeeboxInfoList[nIndex].TeeboxNm);
    Global.Tapo.GetDeviceInfo(FTeeboxInfoList[nIndex].TapoIP);
  end;
  inc(FTeeboxTapoOnOffCheckLastIndex);
  if FTeeboxTapoOnOffCheckLastIndex > FTeeboxCnt - 1 then
    FTeeboxTapoOnOffCheckLastIndex := 0;

  Sleep(10);
end;
}
procedure TTeebox.TeeboxReserveChk;
var
  nIndex: Integer;
  sStr: string;

  nNN, nTmTemp, nSecond: Integer;
  tmTempS, tmTempE: TDateTime;
  sEndDateTemp: String;
  tmCheckIn: TDateTime;
begin

  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sStr := 'SeatReserveUse TeeboxReserveChkAD!';
    Global.Log.LogReserveDelayWrite(sStr);

    sleep(50);
  end;
  FTeeboxStatusUse := True;

  for nIndex := 0 to TeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[nIndex].UseStatus = '7' then
      continue;

    //Ÿ���� �������� Ȯ��
    if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo = '' then
      Continue;

    if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Continue;

    //���, ���� API ��û�� ���� ������
    if (FTeeboxInfoList[nIndex].UseCancel = 'Y') or (FTeeboxInfoList[nIndex].UseClose = 'Y') then //����ΰ�� K410_TeeBoxReserved ���� ERP ����
    begin
      if FTeeboxInfoList[nIndex].UseCancel = 'Y' then
      begin
        if (FTeeboxInfoList[nIndex].RemainMinute = 0) and
           (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveYn = 'N') and
           (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate = '') then
        begin
          FTeeboxInfoList[nIndex].TeeboxReserve.ReserveYn := 'Y';
          FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
          FTeeboxInfoList[nIndex].TeeboxReserve.AssignYn := 'Y'; //��üũ�� ����۵ǵ��� üũ��ó��

          sStr := '�������� no: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo;
          Global.Log.LogReserveWrite(sStr);
        end;
      end;

      if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate = '' then
      begin
        FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        if (FTeeboxInfoList[nIndex].UseClose = 'Y') then
        begin
          // DB/Erp����: ����ð�
          Global.TcpServer.SetApiTeeBoxEnd(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].TeeboxNm, FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate, '2');
        end;

        SetTeeboxVXCtrl('VXend', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, 0);
        SetTeeboxBeamCtrl('Bend', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo);

        FTeeboxInfoList[nIndex].AgentCtlType := 'E';
        FTeeboxInfoList[nIndex].AgentCtlYNPre := '0';
        FTeeboxInfoList[nIndex].AgentCtlYn := '0';
        SetTeeboxCtrl('Tend', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, 0, 0);

        //FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
        FTeeboxInfoList[nIndex].RemainMinute := 0;
      end;
    end;

    //�����,�Ⱓ�� �� üũ��
    if FTeeboxInfoList[nIndex].TeeboxReserve.AssignYn = 'N' then
    begin
      //�ð� �����ſ� ���� ���� ó�� �ʿ�
      tmCheckIn := DateStrToDateTime3(FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate) +
                   (((1/24)/60) * (FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin + FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin));

      if tmCheckIn < now then
      begin
        FTeeboxInfoList[nIndex].TeeboxReserve.ReserveYn := 'Y';
        FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
        FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        // DB/Erp����: ����ð�
        Global.TcpServer.SetApiTeeBoxEnd(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].TeeboxNm, FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate, '2');

        sStr := '��üũ�� no: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
        Global.Log.LogReserveWrite(sStr);

        FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo := '';
      end;

      Continue;
    end;

    //��������
    if (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate = '') and
       (FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime > Now) and
       (FTeeboxInfoList[nIndex].TeeboxReserve.prepareYn = 'N') then
    begin
      FTeeboxInfoList[nIndex].TeeboxReserve.prepareYn := 'Y';

      sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate;
      Global.Log.LogReserveWrite(sStr);

      //�������� ����迭�� ���
      SetTeeboxVXCtrl('VXstart', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, (FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin + FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin));

      if Global.ADConfig.PrepareUse = 'Y' then
      begin
        FTeeboxInfoList[nIndex].AgentCtlType := 'D';
        FTeeboxInfoList[nIndex].AgentCtlYNPre := '0';
        FTeeboxInfoList[nIndex].AgentCtlYn := '0';
        nSecond := GetReservePrepareEndTime(FTeeboxInfoList[nIndex].TeeboxNo);
        SetTeeboxCtrl('Tprepare', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin, nSecond);
      end;

      SetTeeboxBeamCtrl('Bstart', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo );
    end;

    //�����������̰� ���ð��� ��������
    if (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate = '') and
       (FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime < Now) then
    begin

      FTeeboxInfoList[nIndex].RemainMinute := FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin;
      //FTeeboxInfoList[nTeeboxNo].UseStatus := '1';

      FTeeboxInfoList[nIndex].TeeboxReserve.ReserveYn := 'Y';
      FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now); //2021-06-11

      sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate;
      Global.Log.LogReserveWrite(sStr);

      //��ù���� ���� ��Ⱑ ���� ���
      if (FTeeboxInfoList[nIndex].TeeboxReserve.prepareYn = 'N') then
        SetTeeboxVXCtrl('VXstart', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, (FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin + FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin));

      // DB����, 0�� ǥ�õǴ� ��� ����.
      if FTeeboxInfoList[nIndex].UseStatus <> '8' then //����
        Global.XGolfDM.TeeboxInfoUpdate(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].RemainMinute, '1');

      // DB/Erp����: ���۽ð�
      Global.TcpServer.SetApiTeeBoxReg(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].TeeboxNm, FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate);

      //�������� ����迭�� ���
      FTeeboxInfoList[nIndex].AgentCtlType := 'S';
      FTeeboxInfoList[nIndex].AgentCtlYNPre := '0';
      FTeeboxInfoList[nIndex].AgentCtlYn := '0';
      nSecond := GetReserveEndTime(FTeeboxInfoList[nIndex].TeeboxNo);
      SetTeeboxCtrl('Tstart', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin, nSecond);

      SetTeeboxBeamCtrl('Bstart', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo );
    end;

    //�ð����
    if (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate <> '') and
       (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate = '') and
       (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveYn = 'Y') then
    begin

      tmTempS := DateStrToDateTime3(FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate);
      nNN := MinutesBetween(now, tmTempS);

      nTmTemp := FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin - nNN;
      if nTmTemp < 0 then
        nTmTemp := 0;
      FTeeboxInfoList[nIndex].RemainMinute := nTmTemp;

      if FTeeboxInfoList[nIndex].RemainMinute = 0 then
      begin
        FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        // DB/Erp����: ����ð�
        Global.TcpServer.SetApiTeeBoxEnd(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].TeeboxNm, FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate, '2');

        //FTeeboxInfoList[nTeeboxNo].UseStatus := '0';

        SetTeeboxVXCtrl('VXend', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, 0);
        SetTeeboxBeamCtrl('Bend', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo);

        FTeeboxInfoList[nIndex].AgentCtlType := 'E';
        FTeeboxInfoList[nIndex].AgentCtlYn := '0';
        FTeeboxInfoList[nIndex].AgentCtlYNPre := '0';
        SetTeeboxCtrl('Tend', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, 0, 0);
      end;

    end;

  end;

  Sleep(10);
  FTeeboxStatusUse := False;
end;

{
function TTeebox.GetTeeboxInfoUseYn(ATeeboxNo: Integer): String;
begin
  Result := FTeeboxInfoList[ATeeboxNo].UseYn;
end;
}

function TTeebox.GetTeeboxStatusList: AnsiString;
var
  nIndex: Integer;
  sJsonStr: AnsiString;
  jObj, jItemObj: TJSONObject; //Erp ��������
  jObjArr: TJSONArray;
begin
  try
    jObjArr := TJSONArray.Create;
    jObj := TJSONObject.Create;
    jObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
    jObj.AddPair(TJSONPair.Create('user_id', Global.ADConfig.UserId));
    jObj.AddPair(TJSONPair.Create('data', jObjArr));

    for nIndex := 0 to TeeboxCnt - 1 do
    begin
      jItemObj := TJSONObject.Create;
      jItemObj.AddPair( TJSONPair.Create( 'teebox_no', IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) ) );
      jItemObj.AddPair( TJSONPair.Create( 'use_status', FTeeboxInfoList[nIndex].UseStatus ) );
      jObjArr.Add(jItemObj);
    end;

    sJsonStr := jObj.ToString;
  finally
    jObj.Free;
  end;

  Result := sJsonStr;
end;

function TTeebox.GetTeeboxStatus(ATeeboxNo: String): AnsiString;
var
  nIndex, nTeeboxNo: Integer;
  sJsonStr: AnsiString;
  jObj, jItemObj: TJSONObject; //Erp ��������
  jObjArr: TJSONArray;
begin
  try
    jObjArr := TJSONArray.Create;
    jObj := TJSONObject.Create;
    jObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
    jObj.AddPair(TJSONPair.Create('user_id', Global.ADConfig.UserId));
    jObj.AddPair(TJSONPair.Create('data', jObjArr));

    nTeeboxNo := StrToInt(ATeeboxNo);
    nIndex := GetTeeboxInfoIndex(nTeeboxNo);
    jItemObj := TJSONObject.Create;
    jItemObj.AddPair( TJSONPair.Create( 'teebox_no', IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) ) );
    jItemObj.AddPair( TJSONPair.Create( 'use_status', FTeeboxInfoList[nIndex].UseStatus ) );
    jObjArr.Add(jItemObj);

    sJsonStr := jObj.ToString;
  finally
    jObj.Free;
  end;

  Result := sJsonStr;
end;

function TTeebox.GetTeeboxFloorNm(ATeeboxNo: Integer): String;
var
  nIndex: Integer;
begin
  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  Result := FTeeboxInfoList[nIndex].FloorNm;
end;

function TTeebox.GetReserveEndTime(ATeeboxNo: Integer): Integer;
var
  tmStartTime, tmEndTime: TDateTime;
  nSecond, nIndex: Integer;
begin
  nSecond := 0;
  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  tmStartTime := DateStrToDateTime3(FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate);
  tmEndTime := IncMinute(tmStartTime, FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin);

  nSecond := SecondsBetween(now, tmEndTime);
  Result := nSecond;
end;

function TTeebox.GetReservePrepareEndTime(ATeeboxNo: Integer): Integer;
var
  tmEndTime: TDateTime;
  nSecond, nIndex: Integer;
begin
  nSecond := 0;
  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  tmEndTime := FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime;

  nSecond := SecondsBetween(now, tmEndTime);
  Result := nSecond;
end;

procedure TTeebox.SetStoreClose;
var
  nIndex: Integer;
  //sSendData, sBcc: AnsiString;
  sStr: String;
begin
  for nIndex := 0 to TeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[nIndex].UseYn = 'N' then
      Continue;

    if FTeeboxInfoList[nIndex].RemainMinute <= 0 then
      Continue;

    //�ð��ʱ�ȭ ����迭 ���
    FTeeboxInfoList[nIndex].UseClose := 'Y';

    //2020-08-26 v26 JMS ��������� Ÿ������ �߰�
      FTeeboxInfoList[nIndex].RemainMinute := 0;

    sStr := 'Close : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
            IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;
end;

procedure TTeebox.SetTeeboxIP(AMac, AIP: String);
var
  nIndex: integer;
begin
  for nIndex := 0 to TeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[nIndex].TapoMac = AMac then
    begin
      FTeeboxInfoList[nIndex].TapoIP := AIP;
      Break;
    end;
  end;
end;

procedure TTeebox.SetTeeboxOnOff(AIP, AOnOff: String);
var
  nIndex: integer;
begin
  for nIndex := 0 to TeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[nIndex].TapoIP = AIP then
    begin
      FTeeboxInfoList[nIndex].TapoOnOff := AOnOff;
      FTeeboxInfoList[nIndex].TapoError := False;
      Break;
    end;
  end;
end;

procedure TTeebox.SetTeeboxTapoError(AIP: String);
var
  nIndex: integer;
begin
  for nIndex := 0 to TeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[nIndex].TapoIP = AIP then
    begin
      FTeeboxInfoList[nIndex].TapoError := True;
      Break;
    end;
  end;
end;

procedure TTeebox.SetTeeboxAgentCtlYN(AIP, ARecive: String);
var
  nTeeboxNo, nIndex: integer;
  jObj: TJSONObject;
  sApiId, sTeeboxNo, sLeftHanded, sStr: String;
begin

  try
    //{"api_id": "9002", "teebox_no": "1", "reserve_no": "202110240002", "result_cd": "0000", "result_msg": "????? ?? ?????."}
    jObj := TJSONObject.ParseJSONValue(ARecive) as TJSONObject;
    sApiId := jObj.GetValue('api_id').Value;
    sTeeboxNo := jObj.GetValue('teebox_no').Value;
    sLeftHanded := '0';
    if jObj.FindValue('left_handed') <> nil then
      sLeftHanded := jObj.GetValue('left_handed').Value;

    if sApiId = '9901' then //����üũ
      Exit;

    if (Trim(sApiId) = EmptyStr) or (Trim(sTeeboxNo) = EmptyStr) then
    begin
      Global.Log.LogWrite('Fail: ' + ARecive);
      Exit;
    end;

    nTeeboxNo := StrToInt(sTeeboxNo);
    nIndex := GetTeeboxInfoIndex(nTeeboxNo);

    //9001 �غ� 'prepare'
    //9002 ���� 'start', 'change'
    //9003 ���� 'end'

    if Global.ADConfig.AgentSendUse <> True then
      FTeeboxInfoList[nIndex].AgentCtlYN := '1';

    if sLeftHanded = '0' then //��
    begin
      if FTeeboxInfoList[nIndex].AgentIP_R <> AIP then
      begin
        sStr := 'IP ����(��) - No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' + FTeeboxInfoList[nIndex].AgentIP_R + ' -> ' + AIP;
        Global.Log.LogAgentServerRead(sStr);

        FTeeboxInfoList[nIndex].AgentIP_R := AIP;
        Global.WriteConfigAgentIP_R(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].AgentIP_R);
      end;
    end
    else
    begin
      if FTeeboxInfoList[nIndex].AgentIP_L <> AIP then
      begin
        sStr := 'IP ����(��) - No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' + FTeeboxInfoList[nIndex].AgentIP_L + ' -> ' + AIP;
        Global.Log.LogAgentServerRead(sStr);

        FTeeboxInfoList[nIndex].AgentIP_L := AIP;
        Global.WriteConfigAgentIP_L(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].AgentIP_L);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

procedure TTeebox.SetTeeboxCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin, ASecond: Integer);
var
  sLogMsg, sUrl: String;
  sSendStr, sSendTapo: AnsiString;
  nIndex, i: Integer;
begin
  if Global.TapoCtrlLock = True then
    Exit;

  if (AType <> 'Tsetting') and (ATeeboxNo = 0) then
    Exit;

  if ATeeboxNo = 0 then
  begin
    sLogMsg := AType + ' / ' + IntToStr(ATeeboxNo) + ' / ' + AReserveNo + ' / ' + IntToStr(AMin) + ' / ' + IntToStr(ASecond);
  end
  else
  begin
    nIndex := GetTeeboxInfoIndex(ATeeboxNo);
    sLogMsg := AType + ' / No:' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[nIndex].TeeboxNm+ ' / ' + AReserveNo + ' / ' + IntToStr(AMin) + ' / ' + IntToStr(ASecond);
  end;
  Global.Log.LogCtrlWrite(sLogMsg);

  //9001 �غ� 'prepare'
  //9002 ���� 'start', 'change'
  //9003 ���� 'end'
  //9005 ���� 'setting'

  if AType = 'Tprepare' then //���
  begin
    sSendStr := '{"api_id":9001,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "prepare_min":"' + IntToStr(AMin) + '",' +
                ' "prepare_second":' + IntToStr(ASecond) + '}';
  end;

  if (AType = 'Tstart') then //����
  begin
    sSendStr := '{"api_id":9002,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "assign_min":"' + IntToStr(AMin) + '",' +
                ' "assign_second":' + IntToStr(ASecond) + '}';
  end;

  if (AType = 'Tchange') then //����
  begin
    sSendStr := '{"api_id":9006,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "assign_min":"' + IntToStr(AMin) + '",' +
                ' "assign_second":' + IntToStr(ASecond) + '}';
  end;

  if AType = 'Tend' then //����
  begin
    sSendStr := '{"api_id":9003,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '"}';
  end;

  if AType = 'Tsetting' then //����
  begin
    sSendStr := '{"api_id":9005,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "method":' + IntToStr(AMin) + '}';
  end;

  if Global.ADConfig.AgentUse = True then
  begin

    if Global.ADConfig.AgentSendUse = True then
    begin
      if ATeeboxNo = 0 then
      begin
        for i := 0 to FTeeboxCnt - 1 do
        begin
          if FTeeboxInfoList[i].UseYn <> 'Y' then
            Continue;

          if (FTeeboxInfoList[i].AgentIP_R = '') and (FTeeboxInfoList[i].AgentIP_L = '') then
          begin
            Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[i].TeeboxNo));
          end
          else
          begin
            if FTeeboxInfoList[i].AgentIP_R <> '' then
            begin
              //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[i].AgentIP_R + ' : ' + sSendStr);
              sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[i].AgentIP_R, sSendStr);
              Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[i].AgentIP_R + ' : ' + sLogMsg);
            end;

            if FTeeboxInfoList[i].AgentIP_L <> '' then
            begin
              //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[i].AgentIP_L + ' : ' + sSendStr);
              sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[i].AgentIP_L, sSendStr);
              Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[i].AgentIP_L + ' : ' + sLogMsg);
            end;
          end;

          FTeeboxInfoList[i].AgentCtlYN := '1';
        end;
      end
      else
      begin
        if (FTeeboxInfoList[nIndex].AgentIP_R = '') and (FTeeboxInfoList[nIndex].AgentIP_L = '') then
        begin
          Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo));
        end
        else
        begin
          if FTeeboxInfoList[nIndex].AgentIP_R <> '' then
          begin
            //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sSendStr);
            sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[nIndex].AgentIP_R, sSendStr);
            Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sLogMsg);
          end;

          if FTeeboxInfoList[nIndex].AgentIP_L <> '' then
          begin
            //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sSendStr);
            sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[nIndex].AgentIP_L, sSendStr);
            Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sLogMsg);
          end;
        end;

        FTeeboxInfoList[nIndex].AgentCtlYN := '1';
      end;
    end
    else
    begin
      Global.TcpAgentServer.BroadcastMessage(sSendStr);
    end;
  end;

  if ATeeboxNo = 0 then
    Exit;

  if FTeeboxInfoList[nIndex].AgentCtlYN = '2' then
    Exit;

  if Global.ADConfig.TapoUse = True then
  begin
    if Global.ADConfig.XGM_TapoUse = 'Y' then
    begin
      //XGM Tapo ����
      if (AType = 'Tstart') or (AType = 'Tend') then
      begin
        sSendTapo := ''; //'{"nickname": "1"}'
        sSendTapo := '{"nickname":"' + IntToStr(ATeeboxNo) + '"}';

        if (AType = 'Tstart') then
          sUrl := 'http://localhost:8000/plug/on'
        else if (AType = 'Tend') then
          sUrl := 'http://localhost:8000/plug/off';

        sLogMsg := 'Tapo : ' + AType + ' / ' + sUrl + ' / ' + IntToStr(ATeeboxNo) + ' / ' + AReserveNo + ' / ' + sSendTapo;
        Global.Log.LogCtrlWrite(sLogMsg);

        sLogMsg := Global.Api.PostPlugApi(sUrl, sSendTapo);
        Global.Log.LogCtrlWrite(sLogMsg);

        //���¿�û �ּ�ó��. ��������� Ȯ���ʿ�
        FTeeboxInfoList[ATeeboxNo].TapoError := False;
        if (AType = 'Tstart') then
          FTeeboxInfoList[ATeeboxNo].TapoOnOff := 'on'
        else if (AType = 'Tend') then
          FTeeboxInfoList[ATeeboxNo].TapoOnOff := 'off';
      end;
    end
    else
    begin
      if FTeeboxInfoList[nIndex].TapoIP = EmptyStr then
      begin
        sLogMsg := 'Tapo IP null';
        Global.Log.LogCtrlWrite(sLogMsg);
      end
      else
      begin
        if (AType = 'Tstart') then
          Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[nIndex].TapoIP, True, False)
        else if (AType = 'Tend') then
          Global.Tapo.SetDeviceOnOff(FTeeboxInfoList[nIndex].TapoIP, False, False);
      end;
    end;
  end;

end;

procedure TTeebox.SetTeeboxVXCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin: Integer);
var
  sLogMsg, sUrl: String;
  sSendStr: AnsiString;
begin
  if Global.ADConfig.XGM_VXUse <> 'Y' then
    Exit;

  // '/room/status' : ����  {  "roomNum": 24 // ������}
  // '/room/start'  : ����  {  "roomNum": 23,  "mtime": 60 }
  // '/room/stop'   : ����  {  "roomNum": 23 }
  // '/room/add'    : �߰�  {  "roomNum": 23,  "mtime": 60 }

  sUrl := 'http://localhost:8000';
  if (AType = 'VXstart') then
  begin
    sUrl := sUrl + '/room/start';
    sSendStr := '{"roomNum":' + IntToStr(ATeeboxNo) + ',' +
                ' "mtime":' + IntToStr(AMin) + '}';
  end;

  if (AType = 'VXadd') then
  begin
    sUrl := sUrl + '/room/add';
    sSendStr := '{"roomNum":' + IntToStr(ATeeboxNo) + ',' +
                ' "mtime":' + IntToStr(AMin) + '}';
  end;

  if AType = 'VXend' then
  begin
    sUrl := sUrl + '/room/stop';
    sSendStr := '{"roomNum":' + IntToStr(ATeeboxNo) + '}';
  end;

  sLogMsg := AType + IntToStr(ATeeboxNo) + ' / ' + AReserveNo + ' / ' + sUrl + ' / ' + sSendStr;
  Global.Log.LogCtrlWrite(sLogMsg);

  if (Global.ADConfig.StoreCode = 'BA001') and (AType = 'VXstart') then //	�߷�������������
  begin
    sLogMsg := 'BA001(�߷�������������) VX ���۸�� ����ó��';
    Global.Log.LogCtrlWrite(sLogMsg);
  end
  else
  begin
    sLogMsg := Global.Api.PostVXApi(sUrl, sSendStr);
    Global.Log.LogCtrlWrite(sLogMsg);
  end;

end;

procedure TTeebox.SetTeeboxBeamCtrl(AType: String; AReserveNo: String; ATeeboxNo: Integer);
var
  sLogMsg: String;
  nIndex: Integer;
  bResult: Boolean;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  nIndex := GetTeeboxInfoIndex(ATeeboxNo);

  if FTeeboxInfoList[nIndex].BeamIP = EmptyStr then
  begin
    sLogMsg := 'Beam IP null';
    Global.Log.LogCtrlWrite(sLogMsg);
    Exit;
  end;

  sLogMsg := AType + ' / Nm:' + FTeeboxInfoList[nIndex].TeeboxNm + ' / ' + AReserveNo + ' / ' + FTeeboxInfoList[nIndex].BeamIP;
  Global.Log.LogCtrlWrite(sLogMsg);

  if (AType = 'Bstart') then
  begin
    if FTeeboxInfoList[nIndex].BeamType = '0' then
    begin
      bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[nIndex].BeamIP, FTeeboxInfoList[nIndex].BeamPW, 1);
      if bResult = False then
      begin
        //��ſ���� disconnect �Ǵ� ��� ����
        sleep(100);
        bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[nIndex].BeamIP, FTeeboxInfoList[nIndex].BeamPW, 1);
      end;
    end
    else if FTeeboxInfoList[nIndex].BeamType = '1' then
    begin
      Global.Api.PostBeamHitachiApi(FTeeboxInfoList[nIndex].BeamIP, 1);
    end;

    FTeeboxInfoList[nIndex].BeamEndDT := '';
    FTeeboxInfoList[nIndex].BeamStartDT := formatdatetime('YYYYMMDDhhnnss', Now);
    FTeeboxInfoList[nIndex].BeamReCtl := False;
  end
  else if AType = 'Bend' then
  begin
    FTeeboxInfoList[nIndex].BeamEndDT := formatdatetime('YYYYMMDDhhnnss', Now);
  end;

end;

procedure TTeebox.SendBeamEnd;
var
  sLogMsg: String;
  i, nNN: Integer;
  bResult: Boolean;
  tmTemp: TDateTime;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  for i := 0 to FTeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[i].UseYn <> 'Y' then
      Continue;

    if FTeeboxInfoList[i].RemainMinute > 0 then
      Continue;

    if FTeeboxInfoList[i].BeamEndDT = EmptyStr then
      Continue;

    if FTeeboxInfoList[i].BeamIP = EmptyStr then
      Continue;

    tmTemp := DateStrToDateTime3(FTeeboxInfoList[i].BeamEndDT);
    nNN := MinutesBetween(now, tmTemp);

    if nNN > 5 then
    begin
      if FTeeboxInfoList[i].BeamType = '0' then
      begin
        bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[i].BeamIP, FTeeboxInfoList[i].BeamPW, 0);
        if bResult = False then
        begin
          //��ſ���� disconnect �Ǵ� ��� ����
          sleep(100);
          bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[i].BeamIP, FTeeboxInfoList[i].BeamPW, 0);
        end;
      end
      else if FTeeboxInfoList[i].BeamType = '1' then
      begin
        Global.Api.PostBeamHitachiApi(FTeeboxInfoList[i].BeamIP, 0);
      end;

      FTeeboxInfoList[i].BeamEndDT := '';

      sLogMsg := 'Bend 5min / Nm:' + FTeeboxInfoList[i].TeeboxNm;
      Global.Log.LogCtrlWrite(sLogMsg);
    end;

  end;

end;

procedure TTeebox.SendBeamStartReCtl;
var
  sLogMsg: String;
  i, nSS: Integer;
  bResult: Boolean;
  tmTemp: TDateTime;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  for i := 0 to FTeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[i].UseYn <> 'Y' then
      Continue;

    if FTeeboxInfoList[i].BeamIP = EmptyStr then
      Continue;

    if FTeeboxInfoList[i].BeamStartDT = EmptyStr then
      Continue;

    if FTeeboxInfoList[i].BeamReCtl = True then
      Continue;

    tmTemp := DateStrToDateTime3(FTeeboxInfoList[i].BeamStartDT);
    nSS := SecondsBetween(now, tmTemp);

    if nSS > 30 then
    begin
      if FTeeboxInfoList[i].BeamType = '0' then
      begin
        bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[i].BeamIP, FTeeboxInfoList[i].BeamPW, 1);
        if bResult = False then
        begin
          //��ſ���� disconnect �Ǵ� ��� ����
          sleep(100);
          bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[i].BeamIP, FTeeboxInfoList[i].BeamPW, 1);
        end;
      end
      else if FTeeboxInfoList[i].BeamType = '1' then
      begin
        Global.Api.PostBeamHitachiApi(FTeeboxInfoList[i].BeamIP, 1);
      end;

      FTeeboxInfoList[i].BeamReCtl := True;

      sLogMsg := 'Bstart rectr 30Second / Nm:' + FTeeboxInfoList[i].TeeboxNm;
      Global.Log.LogCtrlWrite(sLogMsg);
    end;

  end;

end;

{
procedure TTeebox.SetTeeboxErrorCnt(ATeeboxNo: Integer; AError: String; AMaxCnt: Integer);
var
  sLogMsg: String;
begin
  if FTeeboxInfoList[ATeeboxNo].UseStatus = '8' then
  begin
    sLogMsg := 'UseStatus = 8 : ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
    Global.Log.LogRetryWrite(sLogMsg);
    Exit;
  end;

  if AError = 'Y' then
  begin
    FTeeboxInfoList[ATeeboxNo].ErrorCnt := FTeeboxInfoList[ATeeboxNo].ErrorCnt + 1;
    //if FTeeboxInfoList[ATeeboxNo].ErrorCnt > 10 then
    if FTeeboxInfoList[ATeeboxNo].ErrorCnt >= AMaxCnt then
    begin
      if FTeeboxInfoList[ATeeboxNo].ErrorYn = 'N' then
      begin
        sLogMsg := 'ErrorCnt : ' + IntToStr(AMaxCnt) + ' / ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
        Global.Log.LogRetryWrite(sLogMsg);
      end;

      FTeeboxInfoList[ATeeboxNo].ErrorYn := 'Y';
      FTeeboxInfoList[ATeeboxNo].UseStatus := '9';
      FTeeboxInfoList[ATeeboxNo].ErrorCd := 8; //����̻�
    end;
  end
  else
  begin
    FTeeboxInfoList[ATeeboxNo].ErrorCnt := 0;
    FTeeboxInfoList[ATeeboxNo].ErrorYn := 'N';
  end;
end;
}

procedure TTeebox.SetTeeboxAgentMac(ATeeboxNo: Integer; AType: String; AMAC: String);
var
  nIndex: integer;
begin

  nIndex := GetTeeboxInfoIndex(ATeeboxNo);

  if AType = '0' then //��
  begin
    FTeeboxInfoList[nIndex].AgentMAC_R := AMAC;
    Global.WriteConfigAgentMAC_R(FTeeboxInfoList[nIndex].TeeboxNo, AMAC);
  end
  else
  begin
    FTeeboxInfoList[nIndex].AgentMAC_L := AMAC;
    Global.WriteConfigAgentMAC_L(FTeeboxInfoList[nIndex].TeeboxNo, AMAC);
  end;

end;

procedure TTeebox.TeeboxReserveNextChk;
var
  nIndex: Integer;
  sLog: String;
  //sCancel: String;
  //I: Integer;
  //SeatUseReserve: TSeatUseReserve;
begin

  try

    for nIndex := 0 to TeeboxCnt - 1 do
    begin

      if (FTeeboxInfoList[nIndex].RemainMinPre > 0) or (FTeeboxInfoList[nIndex].UseStatus <> '0') then
        Continue;

      //Ÿ���� �������� Ȯ��
      //if FSeatInfoList[nTeeboxNo].SeatReserve.ReserveNo = '' then
      //  Continue;

      if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
        Continue;

      //2020-05-29 �����߰�, 2021-07-21 ���Ǽ���
      if (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate <> '') and (FTeeboxInfoList[nIndex].TeeboxReserve.ReserveEndDate = '') then
        Continue;

      Global.ReserveList.ReserveListNextChk(FTeeboxInfoList[nIndex].TeeboxNo);

    end;

  except
    on e: Exception do
    begin
       sLog := 'SeatReserveNextChk Exception : ' + e.Message;
       Global.Log.LogReserveWrite(sLog);
    end;
  end;

end;

function TTeebox.SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
var
  nIndex: Integer;
begin
  if ATeeboxNo = '-1' then
    Exit;

  nIndex := GetTeeboxInfoIndex(StrToInt(ATeeboxNo));
  FTeeboxInfoList[nIndex].HoldUse := AUse;
  FTeeboxInfoList[nIndex].HoldUser := AUserId;
end;

function TTeebox.GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;
var
  nIndex: Integer;
begin
  nIndex := GetTeeboxInfoIndex(StrToInt(ATeeboxNo));

  if AType = 'Insert' then
  begin
    if FTeeboxInfoList[nIndex].HoldUser = AUserId then
      Result := False //Ȧ�����ڰ� �����ϸ�
    else
      Result := FTeeboxInfoList[nIndex].HoldUse;
  end
  else if AType = 'Delete' then
  begin
    if FTeeboxInfoList[nIndex].HoldUser = AUserId then
      Result := True //Ȧ�����ڰ� �����ϸ�
    else
      Result := False;
  end
  else
  begin
    Result := FTeeboxInfoList[nIndex].HoldUse;
  end;

end;

function TTeebox.SetTeeboxReservePrepare(ATeeboxNo: Integer): String;
var
  nIndex: Integer;
begin
  nIndex := GetTeeboxInfoIndex(ATeeboxNo);
  FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate := FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate;
  FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nIndex].TeeboxReserve.PrepareStartDate) +
                                                       (((1/24)/60) * FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin);
end;

function TTeebox.GetTeeboxNowReserveLastTime(ATeeboxNo: String): String; //2021-04-19 ���ð� ����ð� ����
var
  nIndex, nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sStartDate, sStr, sLog: String;
  DelayMin, UseMin, nCnt: Integer;
begin
  sStr := '0';

  nTeeboxNo := StrToInt(ATeeboxNo);
  nIndex := GetTeeboxInfoIndex(nTeeboxNo);
  nCnt := Global.ReserveList.GetTeeboxReserveNextListCnt(nTeeboxNo);
  if nCnt = 0 then
  begin
    sStartDate := FTeeboxInfoList[nIndex].TeeboxReserve.ReserveStartDate;
    //DelayMin := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;
    UseMin := FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin;

    ReserveTm := DateStrToDateTime3(sStartDate) + ( ((1/24)/60) * UseMin );

    sStr := FormatDateTime('YYYYMMDDhhnnss', ReserveTm);
  end
  else
  begin
    sStr := Global.ReserveList.GetTeeboxReserveLastTime(ATeeboxNo);
    sLog := 'GetTeeboxReserveLastTime : ' + ATeeboxNo;
    Global.Log.LogErpApiWrite(sLog);
  end;

  Result := sStr;
end;

//Ÿ���� ����Ȯ�ο�-> ERP ����
procedure TTeebox.SendADStatusToErp;
var
  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;

  jObj, jObjSub: TJSONObject;
  sChgDate: String;
begin

  //if FNoErpMode = True then
    //Exit;

  try

    while True do
    begin
      if FTeeboxReserveUse = False then
        Break;

      sLog := 'SeatReserveUse SendADStatusToErp!';
      Global.Log.LogErpApiDelayWrite(sLog);

      sleep(50);
    end;

    FTeeboxStatusUse := True;

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;

    //2021-06-10 ������� ���������߻�->����ǥ����µ�. Timeout ����. Ÿ����AD���¿��̶� �켱 ������.
    sResult := Global.Api.SetErpApiK710TeeboxTime(sJsonStr, 'K710_TeeboxTime', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'SendADStatusToErp Fail : ' + sResult;
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K710_TeeboxTime : ' + sResultCd + ' / ' + sResultMsg;
      Global.Log.LogWrite(sLog);
    end
    else
    begin

      jObjSub := jObj.GetValue('result_data') as TJSONObject;
      sChgDate := jObjSub.GetValue('chg_date').Value;

      if sChgDate > Global.Store.StoreLastTM then
      begin
        sLog := 'K710_TeeboxTime : ' + sResult;
        Global.Log.LogWrite(sLog);

        Global.GetStoreInfoToApi;
      end;

    end;

    Sleep(50);
    FTeeboxStatusUse := False;
  finally
    FTeeboxStatusUse := False;
    FreeAndNil(jObj);
  end;
end;

function TTeebox.TeeboxClear: Boolean;
begin
  SetLength(FTeeboxInfoList, 0);
end;

function TTeebox.TeeboxBallRecallStart: Boolean;
var
  nIndex: Integer;
  sStr: String;
begin
  Result := False;

  //��ȸ�� �ϰ�� ���� �����ð� ����
  Global.WriteConfigBall(0);
  //����ð� üũ����
  SetTeeboxDelay(0, 0);

  for nIndex := 0 to TeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[nIndex].UseStatus = '9' then //Ÿ���� ����
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '8' then //���˻���
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '7' then //��������
      Continue;

    FTeeboxInfoList[nIndex].UseStatusPre := FTeeboxInfoList[nIndex].UseStatus;
    FTeeboxInfoList[nIndex].UseStatus := '7';

    if FTeeboxInfoList[nIndex].RemainMinute > 0 then
    begin

      FTeeboxInfoList[nIndex].AgentCtlType := 'E';
      FTeeboxInfoList[nIndex].AgentCtlYNPre := '0';
      FTeeboxInfoList[nIndex].AgentCtlYn := '0';
      SetTeeboxCtrl('Tend', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, 0, 0);

      sStr := '������� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / 7';
      Global.Log.LogReserveWrite(sStr);
    end;

    Global.XGolfDM.TeeboxInfoUpdate(FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].UseStatus);
  end;

  FBallBackUse := True;

  Result := True;
end;

function TTeebox.TeeboxBallRecallEnd: Boolean;
var
  nIndex, nSeatRemainMin, nDelayNo, nSecond: Integer;
  sStr: String;
begin
  Result := False;
  //����ð� üũ����
  SetTeeboxDelay(0, 1);
  nDelayNo := -1;

  //��ȸ�� ������ ����
  Global.WriteConfigBallBackDelay(FTeeboxInfoList[0].DelayMin);

  for nIndex := 0 to TeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[nIndex].UseStatus <> '7' then //��������
      Continue;

    if FTeeboxInfoList[nIndex].RemainMinute > 0 then
    begin
      FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin + FTeeboxInfoList[0].DelayMin;

      sStr := '���͸�� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' / ' +
              IntToStr(FTeeboxInfoList[0].DelayMin) + ' / Min : ' + IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / UseStatusPre : ' + FTeeboxInfoList[nIndex].UseStatusPre;
      Global.Log.LogReserveWrite(sStr);

      //�������� ����迭�� ���
      FTeeboxInfoList[nIndex].AgentCtlType := 'S';
      FTeeboxInfoList[nIndex].AgentCtlYNPre := '0';
      FTeeboxInfoList[nIndex].AgentCtlYn := '0';
      nSecond := GetReserveEndTime(nIndex);

      SetTeeboxCtrl('Tstart', FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo, FTeeboxInfoList[nIndex].TeeboxNo, FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin, nSecond);
    end;

    FTeeboxInfoList[nIndex].UseStatus := FTeeboxInfoList[nIndex].UseStatusPre;

  end;

  ResetTeeboxRemainMinAdd(0, FTeeboxInfoList[0].DelayMin, 'ALL');

  FBallBackUse := False;

  Result := True;
end;

procedure TTeebox.SetTeeboxDelay(AIndex: Integer; AType: Integer);
var
  nTemp: Integer;
  sStr: String;
begin
  if AType = 0 then //��������
  begin
    FTeeboxInfoList[AIndex].PauseTime := Now;
  end
  else if AType = 1 then //��������
  begin
    FTeeboxInfoList[AIndex].RePlayTime := Now;

    //2020-06-29 ������üũ
    if formatdatetime('YYYYMMDD', FTeeboxInfoList[AIndex].PauseTime) <> formatdatetime('YYYYMMDD',now) then
    begin
      FTeeboxInfoList[AIndex].DelayMin := 0;
    end
    else
    begin
      //1�� �߰� ����-20200507
      nTemp := Trunc((FTeeboxInfoList[AIndex].RePlayTime - FTeeboxInfoList[AIndex].PauseTime) *24 * 60 * 60); //�ʷ� ��ȯ
      if (nTemp mod 60) > 0 then
        FTeeboxInfoList[AIndex].DelayMin := (nTemp div 60) + 1
      else
        FTeeboxInfoList[AIndex].DelayMin := (nTemp div 60);
    end;

    sStr := 'PauseTime: ' + formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[AIndex].PauseTime) +
            ' / RePlayTime: ' + formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[AIndex].RePlayTime) + ' / ' +
            IntToStr(FTeeboxInfoList[AIndex].DelayMin);
    Global.Log.LogReserveWrite(sStr);
  end;

end;

function TTeebox.ResetTeeboxRemainMinAdd(AIndex, ADelayTm: Integer; ATeeboxNm: String): Boolean;
var
  sResult: String;
  sDate, sStr: String;
  sDateTime: String; //��ȸ�����۽ð�
  nTeebox: Integer;
begin
  //2020-06-29 ������üũ
  if ADelayTm = 0 then
    Exit;

  nTeebox := AIndex;

  //if ADelayTm > 10 then
  if ADelayTm > 60 then
  begin
    //sStr := 'ADelayTm > 10 : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + IntToStr(ADelayTm);
    sStr := 'ADelayTm > 60 : ' + IntToStr(nTeebox) + ' / ' + ATeeboxNm + ' / ' + IntToStr(ADelayTm);
    Global.Log.LogReserveWrite('ResetTeeboxReserveDateAdd : ' + sStr);
    Exit;
  end;

  sDate := formatdatetime('YYYYMMDD', Now);

  //AD ��ü �ð� ����� ���  �����ð��߰� ���� DB�� ����
  sResult := Global.XGolfDM.SetSeatReserveUseMinAdd(Global.ADConfig.StoreCode, IntToStr(nTeebox), sDate, IntToStr(ADelayTm));
  sStr := sResult + ' : ' + IntToStr(nTeebox) + ' / ' + ATeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm);
  Global.Log.LogReserveWrite('ResetTeeboxUseMinAdd : ' + sStr);

  //��ȸ���߿� ������û�� ��� DB ����ð� �̺��� ��ġ
  sDateTime := formatdatetime('YYYYMMDDHHNNSS', FTeeboxInfoList[0].PauseTime);
  sResult := Global.XGolfDM.SetSeatReserveTmChange(Global.ADConfig.StoreCode, IntToStr(nTeebox), sDate, IntToStr(ADelayTm), sDateTime);
  sStr := sResult + ' : ' + IntToStr(nTeebox) + ' / ' + ATeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm) + ' / ' + sDateTime;

  Global.Log.LogReserveWrite('ResetTeeboxReserveDateAdd : ' + sStr);

end;

function TTeebox.SendTeeboxReserveStatus(ATeeboxNo: String): Boolean;
var
  jObj: TJSONObject;
  sApiId, sTeeboxNo, sStatus, sMin, sSecond: String;
  nTeeboxNo, nSecond, nMin: integer;
  sSendData: AnsiString;
  nIndex: Integer;
  sLogMsg: String;
begin
  Result := False;

  if Trim(ATeeboxNo) = EmptyStr then
  begin
    //sResult := '{"result_cd":"AD03","result_msg":"Api Fail"}';
    Exit;
  end;

  sTeeboxNo := ATeeboxNo;
  nTeeboxNo := StrToInt(ATeeboxNo);
  nIndex := GetTeeboxInfoIndex(nTeeboxNo);

  if (FTeeboxInfoList[nIndex].AgentIP_R = '') and (FTeeboxInfoList[nIndex].AgentIP_L = '') then
  begin
    Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo));
    Exit;
  end;

  //0: ���޻���, 1: �غ�, 2:�����
  sStatus := '0';
  sMin := '0';
  sSecond := '0';
  if FTeeboxInfoList[nIndex].AgentCtlType = 'D' then
  begin
    sStatus := '1';
    //sMin := IntToStr(rTeeboxInfo.TeeboxReserve.PrepareMin);

    nSecond := GetReservePrepareEndTime(nTeeboxNo);
    sSecond := IntToStr(nSecond);

    if (nSecond mod 60) > 0 then
      nMin := (nSecond div 60) + 1
    else
      nMin := (nSecond div 60);

    sMin := IntToStr(nMin);
  end
  else if FTeeboxInfoList[nIndex].RemainMinute > 0 then
  begin
    sStatus := '2';
    sMin := IntToStr(FTeeboxInfoList[nIndex].RemainMinute);

    nSecond := GetReserveEndTime(nTeeboxNo);
    sSecond := IntToStr(nSecond);
  end;

  sSendData := '{' +
               '"api_id": 9004,' +
               '"teebox_no": ' + sTeeboxNo + ',' +
               '"reserve_no": "' + FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + '",' +
               '"teebox_status": ' + sStatus + ',' +
               '"remain_min": ' + sMin + ',' +
               '"remain_second": ' + sSecond + ',' +
               '"result_cd": "0000",' +
               '"result_msg": "���������� ó�� �Ǿ����ϴ�."' +
             '}';

  if FTeeboxInfoList[nIndex].AgentIP_R <> '' then
  begin
    //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sSendData);
    sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[nIndex].AgentIP_R, sSendData);
    Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sLogMsg);
  end;

  if FTeeboxInfoList[nIndex].AgentIP_L <> '' then
  begin
    //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sSendData);
    sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[nIndex].AgentIP_L, sSendData);
    Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sLogMsg);
  end;

  FTeeboxInfoList[nIndex].AgentCtlYN := '1';

  Result := True;
end;

function TTeebox.SendAgentSetting(ATeeboxNo, AMethod: String): Boolean;
var
  jObj: TJSONObject;
  nTeeboxNo: integer;
  sSendData: AnsiString;
  nIndex, i: Integer;
  sLogMsg: String;
begin
  Result := False;

  if Trim(ATeeboxNo) = EmptyStr then
    Exit;

  if ATeeboxNo = '0' then
  begin
    for i := 0 to FTeeboxCnt - 1 do
    begin
      if FTeeboxInfoList[i].UseYn <> 'Y' then
        Continue;

      sSendData := '{"api_id":9005,' +
                   ' "teebox_no":' + IntTostr(FTeeboxInfoList[i].TeeboxNo) + ',' +
                   ' "method":' + AMethod + '}';

      if (FTeeboxInfoList[i].AgentIP_R = '') and (FTeeboxInfoList[i].AgentIP_L = '') then
      begin
        Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[i].TeeboxNo));
      end
      else
      begin
        if FTeeboxInfoList[i].AgentIP_R <> '' then
        begin
          //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[i].AgentIP_R + ' : ' + sSendStr);
          sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[i].AgentIP_R, sSendData);
          Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[i].AgentIP_R + ' : ' + sLogMsg);
        end;

        if FTeeboxInfoList[i].AgentIP_L <> '' then
        begin
          //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[i].AgentIP_L + ' : ' + sSendStr);
          sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[i].AgentIP_L, sSendData);
          Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[i].AgentIP_L + ' : ' + sLogMsg);
        end;
      end;

      FTeeboxInfoList[i].AgentCtlYN := '1';
    end;
  end
  else
  begin

    nTeeboxNo := StrToInt(ATeeboxNo);
    nIndex := GetTeeboxInfoIndex(nTeeboxNo);

    sSendData := '{"api_id":9005,' +
                   ' "teebox_no":' + ATeeboxNo + ',' +
                   ' "method":' + AMethod + '}';

    if (FTeeboxInfoList[nIndex].AgentIP_R = '') and (FTeeboxInfoList[nIndex].AgentIP_L = '') then
    begin
      Global.Log.LogCtrlWrite('Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo));
    end
    else
    begin
      if FTeeboxInfoList[nIndex].AgentIP_R <> '' then
      begin
        //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sSendStr);
        sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[nIndex].AgentIP_R, sSendData);
        Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_R + ' : ' + sLogMsg);
      end;

      if FTeeboxInfoList[nIndex].AgentIP_L <> '' then
      begin
        //Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sSendStr);
        sLogMsg := Global.Api.SendAgentApi(FTeeboxInfoList[nIndex].AgentIP_L, sSendData);
        Global.Log.LogCtrlWrite('��- ' + FTeeboxInfoList[nIndex].AgentIP_L + ' : ' + sLogMsg);
      end;
    end;

    FTeeboxInfoList[nIndex].AgentCtlYN := '1';
  end;

  Result := True;
end;

procedure TTeebox.SendAgentWOL;
var
  sLogMsg: String;
  i: Integer;
begin

  for i := 0 to FTeeboxCnt - 1 do
  begin
    if FTeeboxInfoList[i].UseYn <> 'Y' then
      Continue;

    if (FTeeboxInfoList[i].AgentMAC_R = '') and (FTeeboxInfoList[i].AgentMAC_L = '') then
    begin
      Global.Log.LogCtrlWrite('Agent MAC NULL - No: ' + IntToStr(FTeeboxInfoList[i].TeeboxNo));
      Continue;
    end;

    if FTeeboxInfoList[i].AgentMAC_R <> '' then
    begin
      sLogMsg := Global.Api.WakeOnLan(FTeeboxInfoList[i].AgentMAC_R);
      Global.Log.LogCtrlWrite('R - No:' + IntToStr(FTeeboxInfoList[i].TeeboxNo) + ' / ' + FTeeboxInfoList[i].AgentMAC_R + ' / ' + sLogMsg);
      Sleep(100);
    end;

    if FTeeboxInfoList[i].AgentMAC_L <> '' then
    begin
      sLogMsg := Global.Api.WakeOnLan(FTeeboxInfoList[i].AgentMAC_L);
      Global.Log.LogCtrlWrite('L - No:' + IntToStr(FTeeboxInfoList[i].TeeboxNo) + ' / ' + FTeeboxInfoList[i].AgentMAC_L + ' / ' + sLogMsg);
      Sleep(100);
    end;

  end;

end;

procedure TTeebox.SendAgentOneWOL(ATeeboxNo: Integer);
var
  sLogMsg: String;
  nIndex: Integer;
begin
  nIndex := GetTeeboxInfoIndex(ATeeboxNo);

  if FTeeboxInfoList[nIndex].UseYn <> 'Y' then
    Exit;

  if (FTeeboxInfoList[nIndex].AgentMAC_R = '') and (FTeeboxInfoList[nIndex].AgentMAC_L = '') then
  begin
    Global.Log.LogCtrlWrite('Agent MAC NULL - No: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo));
    Exit;
  end;

  if FTeeboxInfoList[nIndex].AgentMAC_R <> '' then
  begin
    sLogMsg := Global.Api.WakeOnLan(FTeeboxInfoList[nIndex].AgentMAC_R);
    Global.Log.LogCtrlWrite('R - No:' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' + FTeeboxInfoList[nIndex].AgentMAC_R + ' / ' + sLogMsg);
    Sleep(100);
  end;

  if FTeeboxInfoList[nIndex].AgentMAC_L <> '' then
  begin
    sLogMsg := Global.Api.WakeOnLan(FTeeboxInfoList[nIndex].AgentMAC_L);
    Global.Log.LogCtrlWrite('L - No:' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' + FTeeboxInfoList[nIndex].AgentMAC_L + ' / ' + sLogMsg);
    Sleep(100);
  end;

end;

function TTeebox.SetTeeboxReserveCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr, sResult: String;
  tmTemp: TDateTime;
  nNN, nIndex: integer;
  sJsonStr: AnsiString;
begin
  Result := False;

  nIndex := GetTeeboxInfoIndex(ATeeboxNo);

  if FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    //������, ������ Ÿ���� �ƴ�
    Global.ReserveList.SetTeeboxReserveNextCheckIn(ATeeboxNo, AReserveNo);

    //üũ�� DB ����
    Global.XGolfDM.SeatUseCheckInNextUpdate(Global.ADConfig.StoreCode, AReserveNo);

    Exit;
  end;

  //üũ���� �������� ���ð�, �����ð� ����
  if FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime < Now then //���ð��� �ʰ�������
  begin
    nNN := MinutesBetween(now, FTeeboxInfoList[nIndex].TeeboxReserve.PrepareEndTime);
    FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin - nNN;
  end;

  FTeeboxInfoList[nIndex].TeeboxReserve.AssignYn := 'Y';

  //üũ�� DB ����
  Global.XGolfDM.SeatUseCheckInUpdate(Global.ADConfig.StoreCode, AReserveNo, FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin);

  if Global.ADConfig.Emergency = False then
  begin
    try
      sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                  '&teebox_no=' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) +
                  '&reserve_no=' + AReserveNo +
                  '&assign_min=' + IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) +
                  '&prepare_min=' + IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin) +
                  '&assign_balls=9999' +
                  '&user_id=' + Global.ADConfig.UserId +
                  '&memo=';

      sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K703_TeeboxChg', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
      sStr := 'K703_TeeboxChg : ' + sResult;
      Global.Log.LogErpApiWrite(sStr);
    except
      on e: Exception do
      begin
        sStr := 'K703_TeeboxChg Exception : ' + e.Message;
        Global.Log.LogErpApiWrite(sStr);
      end;
    end;
  end;

  sStr := 'checkIn no: ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
          FTeeboxInfoList[nIndex].TeeboxReserve.ReserveDate + ' / ' +
          intToStr(FTeeboxInfoList[nIndex].TeeboxReserve.PrepareMin) + ' / ' +
          IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin);
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

end.
