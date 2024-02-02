unit uTeeboxInfo;

interface

uses
  uStruct, uConsts,
  System.Classes, System.SysUtils, System.DateUtils,
  Uni, System.Generics.Collections;

type
  TTeebox = class
  private
    //FTeeboxVersion: String;

    FTeeboxDevicNoCnt: Integer;
    FTeeboxInfoList: array of TTeeboxInfo;

    FTeeboxLastNo: Integer;
    FBallBackEnd: Boolean; //��ȸ������
    FBallBackEndCtl: Boolean; //��ȸ������ �������ɿ���

    FBallBackUse: Boolean; //��ȸ������, ��ȸ���� Ű����ũ���� Ȧ��, ���� ��������
    FTeeboxStatusUse: Boolean;
    FTeeboxReserveUse: Boolean;

    FSendApiErrorList: TStringList;

  public
    constructor Create;
    destructor Destroy; override;

    procedure StartUp;

    function GetTeeboxListToApi: Boolean;
    function GetTeeboxListToDB: Boolean; //��޹�����
    function SetTeeboxStartUseStatus: Boolean; //���ʽ����

    //Teebox Thread
    procedure TeeboxReserveNextChk;

    //AD �ð���� - ���������� ����Ȯ��
    procedure TeeboxReserveChkAD;
    procedure TeeboxStatusChkAD;
    procedure SetTeeboxInfoAD(ATeeboxInfo: TTeeboxInfo);
    procedure SetTeeboxErrorCntAD(AIndex, ATeeboxNo: Integer; AError: String; AMaxCnt: Integer);
    procedure TeeboxReserveNextChkAD;
    procedure SetTeeboxCtrlAD(ATeeboxNo: Integer; AType: String; ATime: Integer; ABall: Integer);
    procedure SetTeeboxVXCtrl(AType: String; AReserveNo, ATeeboxNm: String; AMin: Integer);
    procedure SetTeeboxBeamCtrl(AType: String; AReserveNo: String; ATeeboxNo: Integer);
    procedure SendBeamEnd;
    procedure SendBeamStartReCtl;

    //agent �������
    procedure SetTeeboxAgentCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin, ASecond: Integer);
    procedure SetAgentCtlYN(AIP, ARecive: String);
    function SendAgentReserveStatus(ATeeboxNo: String): Boolean;
    function SendAgentSetting(ATeeboxNo, AMethod: String): Boolean;
    function SendAgent(ATeeboxNo: Integer; ASendData: String): Boolean;
    procedure SendAgentWOL(ATeeboxNo: Integer);
    procedure SendAgentWOLCtl(ATeeboxNo: Integer);

    procedure SetTeeboxInfoUseReset(ATeeboxNo: Integer);

    //Teebox Thread
    procedure SetTeeboxDelay(ATeeboxNo: Integer; AType: Integer);

    procedure SetStoreClose;
    procedure SetTeeboxCtrlRemainMin(ATeeboxNo: Integer; ATime: Integer); // MODENYJ ����, Ÿ���������� ��
    procedure SetTeeboxCtrlRemainMinFree(ATeeboxNo: Integer); // MODENYJ ����, Ÿ���������� ���� ��

    function TeeboxDeviceCheck(ATeeboxNo: Integer; AType: String): Boolean;
    function TeeboxBallRecallStart: Boolean;
    function TeeboxBallRecallEnd: Boolean;

    function GetDevicToFloorTeeboxNo(AFloor, ADev: String): Integer;
    function GetDevicToFloorIndexTeeboxNo(AFloor: String; AIndex: Integer; ADev: String): Integer; //���������� ����

    function GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
    function GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
    function GetDeviceToFloorTeeboxInfo(AFloor, AChannelCd: String): TTeeboxInfo;
    function GetDeviceToFloorIndexTeeboxInfo(AFloor: String; AIndex: Integer; AChannelCd: String): TTeeboxInfo; //���������� ����

    function GetTeeboxInfoUseYn(ATeeboxNo: Integer): String;
    function GetTeeboxStatusList: AnsiString;
    function GetTeeboxStatus(ATeebox: String): AnsiString;
    function GetTeeboxStatusError(ATeebox, ATeebox1: String): AnsiString;
    function GetTeeboxFloorNm(ATeeboxNo: Integer): String;
    function GetTeeboxErrorCode(ATeeboxNo: Integer): String;

    function SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
    function GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;

    function SetTeeboxReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
    function SetTeeboxReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
    function SetTeeboxReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String; //��ù���
    function SetTeeboxReserveCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean; //üũ��

    function ResetTeeboxRemainMinAdd(ATeeboxNo, ADelayTm: Integer; ATeeboxNm: String): Boolean;

    //2020-08-26 v26 ������ �ð�����
    function ResetTeeboxRemainMinAddJMS(ATeeboxNo, ADelayTm: Integer): Boolean;

    //����ð� Ȯ��
    function GetTeeboxNowReserveLastTime(ATeeboxNo: String): String; //2021-04-19 ���ð� ���� ����ð� ����

    procedure SendADStatusToErp;
    procedure SendApiErrorRetry;
    function SetSendApiErrorAdd(AReserveNo, AApi, AStr: String): Boolean;

    function TeeboxClear: Boolean;

    property TeeboxLastNo: Integer read FTeeboxLastNo write FTeeboxLastNo;
    property TeeboxDevicNoCnt: Integer read FTeeboxDevicNoCnt write FTeeboxDevicNoCnt;

    property BallBackEnd: Boolean read FBallBackEnd write FBallBackEnd;
    property BallBackEndCtl: Boolean read FBallBackEndCtl write FBallBackEndCtl;
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
  TeeboxLastNo := 0;
  FTeeboxDevicNoCnt := 0;

  FBallBackUse := False;
  FBallBackEnd := False;
  FBallBackEndCtl := False;

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

  FSendApiErrorList := TStringList.Create;
end;

function TTeebox.GetTeeboxListToApi: Boolean;
var
  nIndex, nTeeboxNo, nTeeboxCnt: Integer;
  jObjArr: TJsonArray;
  jObj, jObjSub: TJSONObject;

  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;
begin
  Result := False;

  try
    //try
    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
                '&client_id=' + Global.ADConfig.UserId;
    //Global.Log.LogWrite(sJsonStr);
    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K204_TeeBoxlist', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
    //Global.Log.LogWrite(sResult);

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

    nTeeboxCnt := jObjArr.Size;
    SetLength(FTeeboxInfoList, nTeeboxCnt + 1);

    for nIndex := 0 to nTeeboxCnt - 1 do
    begin
      jObjSub := jObjArr.Get(nIndex) as TJSONObject;
      nTeeboxNo := StrToInt(jObjSub.GetValue('teebox_no').Value);
      if FTeeboxLastNo < nTeeboxNo then
        FTeeboxLastNo := nTeeboxNo;

      FTeeboxInfoList[nTeeboxNo].TeeboxNo := StrToInt(jObjSub.GetValue('teebox_no').Value);
      FTeeboxInfoList[nTeeboxNo].TeeboxNm := jObjSub.GetValue('teebox_nm').Value;
      FTeeboxInfoList[nTeeboxNo].FloorZoneCode := jObjSub.GetValue('floor_cd').Value;
      FTeeboxInfoList[nTeeboxNo].FloorNm := jObjSub.GetValue('floor_nm').Value;
      FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode := jObjSub.GetValue('zone_div').Value;
      FTeeboxInfoList[nTeeboxNo].ControlYn := jObjSub.GetValue('control_yn').Value;
      FTeeboxInfoList[nTeeboxNo].DeviceId := jObjSub.GetValue('device_id').Value;
      FTeeboxInfoList[nTeeboxNo].UseYn := jObjSub.GetValue('use_yn').Value;
      FTeeboxInfoList[nTeeboxNo].DelYn := jObjSub.GetValue('del_yn').Value;

      if FTeeboxInfoList[nTeeboxNo].DelYn = 'Y' then
        Continue;

      FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
      FTeeboxInfoList[nTeeboxNo].ComReceive := 'N'; //���� 1ȸ üũ
      FTeeboxInfoList[nTeeboxNo].ErrorYn := 'N'; //���� 1ȸ üũ

      if (Global.ADConfig.StoreCode = 'CD001') then //CD001	��Ÿ����Ŭ��(�ϻ�)
      begin
        FTeeboxInfoList[nTeeboxNo].AgentIP_R := Global.ReadConfigAgentIP_R(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].AgentIP_L := Global.ReadConfigAgentIP_L(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].AgentMAC_R := Global.ReadConfigAgentMAC_R(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].AgentMAC_L := Global.ReadConfigAgentMAC_L(nTeeboxNo);

        FTeeboxInfoList[nTeeboxNo].BeamType := Global.ReadConfigBeamType(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].BeamPW := Global.ReadConfigBeamPW(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].BeamIP := Global.ReadConfigBeamIP(nTeeboxNo);
      end;
    end;
    {except
      on e: Exception do
      begin
        sLog := 'GetTeeboxListToApi Error : ' + e.Message;
        Global.Log.LogWrite(sLog);
      end;
    end;   }
  finally
    FreeAndNil(jObj);
  end;

  Result := True;
end;

function TTeebox.GetTeeboxListToDB: Boolean;
var
  rTeeboxInfoList: TList<TTeeboxInfo>;
  nIndex, nTeeboxNo, nTeeboxCnt: Integer;
  sLog: String;
begin
  Result := False;

  rTeeboxInfoList := Global.XGolfDM.SeatSelect;

  try

    nTeeboxCnt := rTeeboxInfoList.Count;
    SetLength(FTeeboxInfoList, nTeeboxCnt + 1);

    for nIndex := 0 to nTeeboxCnt - 1 do
    begin

      nTeeboxNo := rTeeboxInfoList[nIndex].TeeboxNo;
      if FTeeboxLastNo < nTeeboxNo then
        FTeeboxLastNo := nTeeboxNo;

      FTeeboxInfoList[nTeeboxNo].TeeboxNo := rTeeboxInfoList[nIndex].TeeboxNo;
      FTeeboxInfoList[nTeeboxNo].TeeboxNm := rTeeboxInfoList[nIndex].TeeboxNm;
      FTeeboxInfoList[nTeeboxNo].FloorZoneCode := rTeeboxInfoList[nIndex].FloorZoneCode;
      FTeeboxInfoList[nTeeboxNo].FloorNm := rTeeboxInfoList[nIndex].FloorNm;
      FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode := rTeeboxInfoList[nIndex].TeeboxZoneCode;

      //���丮�� ���ڵ� 29,28,2,1,58,57,31,30
      if Global.ADConfig.StoreCode = 'A7001' then
      begin
        if (FTeeboxInfoList[nTeeboxNo].TeeboxNm = '29') or (FTeeboxInfoList[nTeeboxNo].TeeboxNm = '28') or
           (FTeeboxInfoList[nTeeboxNo].TeeboxNm = '2') or (FTeeboxInfoList[nTeeboxNo].TeeboxNm = '1') or
           (FTeeboxInfoList[nTeeboxNo].TeeboxNm = '58') or (FTeeboxInfoList[nTeeboxNo].TeeboxNm = '57') or
           (FTeeboxInfoList[nTeeboxNo].TeeboxNm = '31') or (FTeeboxInfoList[nTeeboxNo].TeeboxNm = '30') then
        begin
          FTeeboxInfoList[nTeeboxNo].ControlYn := 'N';
        end
        else
        begin
          FTeeboxInfoList[nTeeboxNo].ControlYn := 'Y';
        end;
      end
      else
      begin
        FTeeboxInfoList[nTeeboxNo].ControlYn := 'Y';
      end;

      FTeeboxInfoList[nTeeboxNo].DeviceId := rTeeboxInfoList[nIndex].DeviceId;
      FTeeboxInfoList[nTeeboxNo].UseYn := rTeeboxInfoList[nIndex].UseYn;
      FTeeboxInfoList[nTeeboxNo].DelYn := rTeeboxInfoList[nIndex].DelYn;

      FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
      FTeeboxInfoList[nTeeboxNo].ComReceive := 'N'; //���� 1ȸ üũ

      if (Global.ADConfig.StoreCode = 'CD001') then //CD001	��Ÿ����Ŭ��(�ϻ�)
      begin
        FTeeboxInfoList[nTeeboxNo].AgentIP_R := Global.ReadConfigAgentIP_R(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].AgentIP_L := Global.ReadConfigAgentIP_L(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].AgentMAC_R := Global.ReadConfigAgentMAC_R(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].AgentMAC_L := Global.ReadConfigAgentMAC_L(nTeeboxNo);

        FTeeboxInfoList[nTeeboxNo].BeamType := Global.ReadConfigBeamType(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].BeamPW := Global.ReadConfigBeamPW(nTeeboxNo);
        FTeeboxInfoList[nTeeboxNo].BeamIP := Global.ReadConfigBeamIP(nTeeboxNo);
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

  nDBMax: Integer;
  I, nTeeboxNo, nIndex: Integer;
  sStausChk, sBallBackStart: String;
  sStr, sPreDate: String;

  NextReserve: TNextReserve;
  nErpReserveNo: Integer;

  sErrorReserveNo, sErrorStart, sErrorReward: String;
begin
  rTeeboxInfoList := Global.XGolfDM.SeatSelect;

  sStausChk := '';
  nDBMax := 0;
  for I := 0 to rTeeboxInfoList.Count - 1 do
  begin
    nTeeboxNo := rTeeboxInfoList[I].TeeboxNo;

    if (FTeeboxInfoList[nTeeboxNo].TeeboxNm <> rTeeboxInfoList[I].TeeboxNm) or
       (FTeeboxInfoList[nTeeboxNo].FloorZoneCode <> rTeeboxInfoList[I].FloorZoneCode) or
       (FTeeboxInfoList[nTeeboxNo].FloorNm <> rTeeboxInfoList[I].FloorNm) or //2021-06-25 ���� �߰�(�̼����̻��)
       (FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode <> rTeeboxInfoList[I].TeeboxZoneCode) or
       (FTeeboxInfoList[nTeeboxNo].DeviceId <> rTeeboxInfoList[I].DeviceId) or
       (FTeeboxInfoList[nTeeboxNo].UseYn <> rTeeboxInfoList[I].UseYn) or
       (FTeeboxInfoList[nTeeboxNo].DelYn <> rTeeboxInfoList[I].DelYn) then
    begin
      if Global.ADConfig.Emergency = False then
        Global.XGolfDM.SeatUpdate(Global.ADConfig.StoreCode, FTeeboxInfoList[nTeeboxNo]);
    end;

    FTeeboxInfoList[nTeeboxNo].UseStatusPre := rTeeboxInfoList[I].UseStatus;
    FTeeboxInfoList[nTeeboxNo].UseStatus := rTeeboxInfoList[I].UseStatus;

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '8' then
      TeeboxDeviceCheck(nTeeboxNo, '8');

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '7' then
    begin
      sStausChk := '7';
      FTeeboxInfoList[nTeeboxNo].RemainMinPre := rTeeboxInfoList[I].RemainMinute;
      FTeeboxInfoList[nTeeboxNo].RemainMinute := rTeeboxInfoList[I].RemainMinute;

      if FTeeboxInfoList[nTeeboxNo].RemainMinute > 0 then
        FTeeboxInfoList[nTeeboxNo].UseStatusPre := '1'
      else
        FTeeboxInfoList[nTeeboxNo].UseStatusPre := '0';
    end;

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '9' then
    begin
      FTeeboxInfoList[nTeeboxNo].RemainMinPre := rTeeboxInfoList[I].RemainMinute;
      FTeeboxInfoList[nTeeboxNo].RemainMinute := rTeeboxInfoList[I].RemainMinute;
      FTeeboxInfoList[nTeeboxNo].DeviceUseStatus := '9'; // ����۽� ������ Ȯ���� �������� Ȯ��
    end;

    FTeeboxInfoList[nTeeboxNo].RemainBall := rTeeboxInfoList[I].RemainBall;

    FTeeboxInfoList[nTeeboxNo].HoldUse := False;
    FTeeboxInfoList[nTeeboxNo].HoldUse := rTeeboxInfoList[I].HoldUse;
    FTeeboxInfoList[nTeeboxNo].HoldUser := rTeeboxInfoList[I].HoldUser;

    if FTeeboxInfoList[nTeeboxNo].HoldUse = True then
    begin
      sStr := 'HoldUse : ' + IntToStr(nTeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm;
      Global.Log.LogWrite(sStr);
    end;

    if nTeeboxNo > nDBMax then
      nDBMax := nTeeboxNo;
  end;
  FreeAndNil(rTeeboxInfoList);

  if FTeeboxLastNo > nDBMax then
  begin
    for I := nDBMax + 1 to FTeeboxLastNo do
    begin
      Global.XGolfDM.SeatInsert(Global.ADConfig.StoreCode, FTeeboxInfoList[I]);
    end;
  end;

  //2020-06-09 ���� ���� ����
  if Global.Store.StartTime < Global.Store.EndTime then //���Ͽ����� 2023-01-18
  begin
    if FormatDateTime('hh', now) <= Copy(Global.Store.StartTime, 1, 2) then
    begin
      sPreDate := FormatDateTime('YYYYMMDD', now - 1);
      Global.XGolfDM.SeatUseStoreClose(Global.ADConfig.StoreCode, Global.ADConfig.UserId, sPreDate);

      sStr := 'SeatUseStoreClose : ' + sPreDate;
      Global.Log.LogWrite(sStr);

      for I := 1 to TeeboxLastNo do
      begin
        if (FTeeboxInfoList[I].UseStatus = '1') then // (FTeeboxInfoList[I].RemainMinute > 0)
        begin
          FTeeboxInfoList[I].UseStatus := '0';
          FTeeboxInfoList[I].RemainMinute := 0;
          sStr := 'No : ' + IntToStr(FTeeboxInfoList[I].TeeboxNo) + ' / Nm : ' + FTeeboxInfoList[nIndex].TeeboxNm +
                  'Min : ' + IntToStr(FTeeboxInfoList[I].RemainMinute) + ' -> 0';
          Global.Log.LogWrite(sStr);
        end;
      end;

    end;
  end;

  //Ÿ�� �������� �Ǵ� �ٷ� ������ �����
  rSeatUseReserveList := Global.XGolfDM.SeatUseAllReserveSelect(Global.ADConfig.StoreCode, '');
  for nIndex := 0 to rSeatUseReserveList.Count - 1 do
  begin
    nTeeboxNo := rSeatUseReserveList[nIndex].SeatNo;

    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo := rSeatUseReserveList[nIndex].ReserveNo;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin := rSeatUseReserveList[nIndex].UseMinute;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignBalls := rSeatUseReserveList[nIndex].UseBalls;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin := rSeatUseReserveList[nIndex].DelayMinute;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate := rSeatUseReserveList[nIndex].ReserveDate;
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate) +
                                                        (((1/24)/60) * FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin);

    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'N';
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := rSeatUseReserveList[nIndex].StartTime;
    if rSeatUseReserveList[nIndex].UseStatus = '1' then
    begin
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareCtlYn := 'Y';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      Global.Log.LogReserveWrite('UseStatus = 1 '  + rSeatUseReserveList[nIndex].ReserveNo);

      if (Global.ADConfig.StoreCode = 'B7001') and (Global.ComInfornetPLC <> nil) then
      begin
        if FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52 then
        begin
          Global.ComInfornetPLC.SetTeeboxUse(FTeeboxInfoList[nTeeboxNo].TeeboxNm, '1');
        end;
      end;
    end;

    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignYn := rSeatUseReserveList[nIndex].AssignYn;

    // �������ϰ��
    if FTeeboxInfoList[nTeeboxNo].UseStatus = '9' then
    begin
      Global.ReadConfigError(nTeeboxNo, sErrorReserveNo, sErrorStart, sErrorReward);
      if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = sErrorReserveNo then
      begin
        if sErrorStart = EmptyStr then
          FTeeboxInfoList[nTeeboxNo].PauseTime := Now
        else
          FTeeboxInfoList[nTeeboxNo].PauseTime := DateStrToDateTime2(sErrorStart);

        if sErrorReward = 'Y' then
          FTeeboxInfoList[nTeeboxNo].ErrorReward := True
        else
          FTeeboxInfoList[nTeeboxNo].ErrorReward := False;
      end
      else
      begin
        FTeeboxInfoList[nTeeboxNo].DeviceUseStatus := ''; // ������ ������ �ٸ����
      end;
    end;

    sStr := '��� : ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin);
    Global.Log.LogReserveWrite(sStr);

  end;
  FreeAndNil(rSeatUseReserveList);

  //Ÿ�� ���� �����,������� ������ ������ ������
  rSeatUseReserveList := Global.XGolfDM.SeatUseAllReserveSelectNext(Global.ADConfig.StoreCode);

  for nIndex := 0 to rSeatUseReserveList.Count - 1 do
  begin
    if rSeatUseReserveList[nIndex].SeatNo = 0 then
      Continue;

    nTeeboxNo := rSeatUseReserveList[nIndex].SeatNo;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = rSeatUseReserveList[nIndex].ReserveNo then
      Continue;

    Global.ReserveList.SetTeeboxReserveNext(rSeatUseReserveList[nIndex]);

    sStr := '������ : ' + IntToStr(nTeeboxNo) + ' / ' + rSeatUseReserveList[nIndex].ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;

  FreeAndNil(rSeatUseReserveList);

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
  else
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

    //2022-01-12 �׸��ʵ�
    if (Global.Store.UseRewardYn = 'N') and (Global.ADConfig.StoreCode <> 'B9001' ) then //�Ľ��� ����
    begin
      sStr := FormatDateTime('hhnn', FTeeboxInfoList[0].PauseTime);
      {
      if (sStr < global.Store.BallRecallStartTime) or (sStr > global.Store.BallRecallEndTime) then
      begin
        Global.SetStoreUseRewardException('Y');
        Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = Y');
      end;
      }
      if (Global.ADConfig.StoreCode = 'B7001') or //B7001	�����ڰ���������
         (Global.ADConfig.StoreCode = 'B2001') or (Global.ADConfig.StoreCode = 'BB001') then // B2001	�׸��ʵ���������� / BB001	������
      begin
        if (sStr < global.Store.BallRecallStartTime) or (sStr > global.Store.BallRecallEndTime) then
        begin
          Global.SetStoreUseRewardException('Y');
          Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = Y');
        end
        else
        begin
          Global.SetStoreUseRewardException('N');
          Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = N');
        end;
      end
      else
      begin
        if ((global.Store.BallRecallYn = true) and (sStr >= global.Store.BallRecallStartTime) and (sStr <= global.Store.BallRecallEndTime)) or
           ((global.Store.BallRecall2Yn = true) and (sStr >= global.Store.BallRecall2StartTime) and (sStr <= global.Store.BallRecall2EndTime)) then
        begin
          Global.SetStoreUseRewardException('N');
          Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = N');
        end
        else
        begin
          Global.SetStoreUseRewardException('Y');
          Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = Y');
        end;
      end;

    end;

    //chy 2020-10-30 ��ȸ�� üũ
    FBallBackUse := True;
  end;
end;

function TTeebox.TeeboxDeviceCheck(ATeeboxNo: Integer; AType: String): Boolean;
begin

  if AType = '8' then
    FTeeboxInfoList[ATeeboxNo].UseStatus := AType
  else
  begin
    //2021-10-12 ���������� ���°� ��Ȯ��
    if FTeeboxInfoList[ATeeboxNo].RemainMinute = 0 then
      FTeeboxInfoList[ATeeboxNo].UseStatus := '0'
    else
      FTeeboxInfoList[ATeeboxNo].UseStatus := '1';
  end;

  if (Global.ADConfig.ProtocolType = 'MODENYJ') and (AType = '0') then //���� ������
    SetTeeboxCtrlRemainMinFree(ATeeboxNo);
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

  if (Global.Store.UseRewardYn = 'N') and (Global.ADConfig.StoreCode <> 'B9001' ) then //�Ľ��� ����
  begin
    sStr := FormatDateTime('hhnn', Now);

    if (Global.ADConfig.StoreCode = 'B7001') or //B7001	�����ڰ���������
       (Global.ADConfig.StoreCode = 'B2001') or (Global.ADConfig.StoreCode = 'BB001') then // B2001	�׸��ʵ���������� / BB001	������
    begin
      if (sStr < global.Store.BallRecallStartTime) or (sStr > global.Store.BallRecallEndTime) then
      begin
        Global.SetStoreUseRewardException('Y');
        Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = Y');
      end
      else
      begin
        Global.SetStoreUseRewardException('N');
        Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = N');
      end;
    end
    else
    begin
      if ((global.Store.BallRecallYn = true) and (sStr >= global.Store.BallRecallStartTime) and (sStr <= global.Store.BallRecallEndTime)) or
         ((global.Store.BallRecall2Yn = true) and (sStr >= global.Store.BallRecall2StartTime) and (sStr <= global.Store.BallRecall2EndTime)) then
      begin
        Global.SetStoreUseRewardException('N');
        Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = N');
      end
      else
      begin
        Global.SetStoreUseRewardException('Y');
        Global.Log.LogReserveWrite('UseRewardYn = N / UseRewardException = Y');
      end;
    end;
  end;

  for nIndex := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nIndex].UseStatus = '9' then //Ÿ���� ����
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '8' then //���˻���
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '7' then //��������
      Continue;

    if (global.ADConfig.StoreCode = 'B7001') and (nIndex > 52) then //������ 3���� ������ ���� ��ȸ�� ����
      Continue;

    if (global.ADConfig.StoreCode = 'A8004') and (nIndex > 52) then //A8004	�����(������) �ǳ�Ÿ�� ��ȸ�� ����
      Continue;

    if (global.ADConfig.StoreCode = 'CD001') and (nIndex > 52) then //CD001	��Ÿ����Ŭ��(�ϻ�) �ǳ�Ÿ�� ��ȸ�� ����
      Continue;

    FTeeboxInfoList[nIndex].UseStatusPre := FTeeboxInfoList[nIndex].UseStatus;

    FTeeboxInfoList[nIndex].UseStatus := '7';
    FTeeboxInfoList[nIndex].DeviceCtrlCnt := 0; //����Ƚ�� �ʱ�ȭ

    if FTeeboxInfoList[nIndex].RemainMinute > 0 then
    begin
      SetTeeboxCtrlAD(nIndex, 'S1' , 0, FTeeboxInfoList[nIndex].RemainBall);

      sStr := '������� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
              FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
              IntToStr(FTeeboxInfoList[nIndex].RemainBall) + ' / ' +
              '7' + ' / ' + FTeeboxInfoList[nIndex].DeviceId;
      Global.Log.LogReserveWrite(sStr);
    end;

    Global.XGolfDM.TeeboxInfoUpdate(nIndex, FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].RemainBall, FTeeboxInfoList[nIndex].UseStatus, '');
  end;

  FBallBackEnd := False;
  BallBackEndCtl := False;

  FBallBackUse := True;

  Result := True;
end;

function TTeebox.TeeboxBallRecallEnd: Boolean;
var
  nIndex, nSeatRemainMin: Integer;
  sStr: String;
  nNum: Integer;
  sResult: String;
begin
  Result := False;
  //����ð� üũ����
  SetTeeboxDelay(0, 1);

  //��ȸ�� ������ ����
  Global.WriteConfigBallBackDelay(FTeeboxInfoList[0].DelayMin);

  for nIndex := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nIndex].UseStatus <> '7' then //��������
      Continue;

    if FTeeboxInfoList[nIndex].RemainMinute > 0 then
    begin
      if (Global.Store.UseRewardYn = 'Y') or // AD_JEU435, SM
         ((Global.Store.UseRewardYn = 'N') and (Global.Store.UseRewardException = 'Y')) then
      begin
        FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin + FTeeboxInfoList[0].DelayMin;

        sStr := '���͸�� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' / ' +
                IntToStr(FTeeboxInfoList[0].DelayMin) + ' / Min : ' + IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / UseStatusPre : ' + FTeeboxInfoList[nIndex].UseStatusPre;
      end
      else  //�ð������� �ƴϸ�
      begin
        sStr := '���͸�� : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].RemainBall) + ' / ' +
                FTeeboxInfoList[nIndex].UseStatus;
      end;
      Global.Log.LogReserveWrite(sStr);

      if (Global.ADConfig.ProtocolType = 'NANO') or (Global.ADConfig.ProtocolType = 'NANO2') then
      begin
        SetTeeboxCtrlAD(nIndex, 'S0' , FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].RemainBall);

        if Global.ADConfig.StoreCode <> 'BD001' then //	BD001	�׷������Ŭ��
          SetTeeboxCtrlAD(nIndex, 'S1' , FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].RemainBall);
      end
      else
        SetTeeboxCtrlAD(nIndex, 'S1' , FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].RemainBall);
    end;

    FTeeboxInfoList[nIndex].UseStatus := FTeeboxInfoList[nIndex].UseStatusPre;
  end;

  if (Global.Store.UseRewardYn = 'Y') or // 'AD_JEU435' 'SM'
     ((Global.Store.UseRewardYn = 'N') and (Global.Store.UseRewardException = 'Y')) then
  begin
    ResetTeeboxRemainMinAdd(0, FTeeboxInfoList[0].DelayMin, 'ALL'); //����:1,4 ��� �ð��߰�
  end;

  FBallBackUse := False;

  Result := True;
end;

function TTeebox.GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
begin
  Result := FTeeboxInfoList[ATeeboxNo];
end;

function TTeebox.GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
var
  i: Integer;
begin
  for i := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[i].TeeboxNm = ATeeboxNm then
    begin
      Result := FTeeboxInfoList[i];
      Break;
    end;
  end;
end;

procedure TTeebox.SetTeeboxDelay(ATeeboxNo: Integer; AType: Integer);
var
  nTemp: Integer;
  sStr: String;
begin
  if AType = 0 then //��������
  begin
    FTeeboxInfoList[ATeeboxNo].PauseTime := Now;
  end
  else if AType = 1 then //��������
  begin
    FTeeboxInfoList[ATeeboxNo].RePlayTime := Now;

    //2020-06-29 ������üũ
    if formatdatetime('YYYYMMDD', FTeeboxInfoList[ATeeboxNo].PauseTime) <> formatdatetime('YYYYMMDD',now) then
    begin
      FTeeboxInfoList[ATeeboxNo].DelayMin := 0;
    end
    else
    begin
      //1�� �߰� ����-20200507
      nTemp := Trunc((FTeeboxInfoList[ATeeboxNo].RePlayTime - FTeeboxInfoList[ATeeboxNo].PauseTime) *24 * 60 * 60); //�ʷ� ��ȯ
      if (nTemp mod 60) > 0 then
        FTeeboxInfoList[ATeeboxNo].DelayMin := (nTemp div 60) + 1
      else
        FTeeboxInfoList[ATeeboxNo].DelayMin := (nTemp div 60);
    end;

    sStr := 'PauseTime: ' + formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[ATeeboxNo].PauseTime) +
            ' / RePlayTime: ' + formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[ATeeboxNo].RePlayTime) + ' / ' +
            IntToStr(FTeeboxInfoList[ATeeboxNo].DelayMin);
    Global.Log.LogReserveWrite(sStr);
  end
  else if AType = 2 then //������
  begin
    nTemp := Trunc((Now - FTeeboxInfoList[ATeeboxNo].PauseTime) *24 * 60 * 60); //�ʷ� ��ȯ
    if (nTemp mod 60) > 0 then
      FTeeboxInfoList[ATeeboxNo].DelayMin := FTeeboxInfoList[ATeeboxNo].DelayMin + (nTemp div 60) + 1
    else
      FTeeboxInfoList[ATeeboxNo].DelayMin := FTeeboxInfoList[ATeeboxNo].DelayMin + (nTemp div 60);
  end;

end;

function TTeebox.SetTeeboxReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
var
  nSeatNo: Integer;
  sStr: String;
begin

  nSeatNo := ASeatReserveInfo.SeatNo;

  if nSeatNo > FTeeboxLastNo then
  begin
    sStr := 'SeatNo error : ' + IntToStr(nSeatNo);
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo = ASeatReserveInfo.ReserveNo then
  begin
    sStr := '���Ͽ���� : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
          ASeatReserveInfo.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //���� �������̸�
  if (FTeeboxInfoList[nSeatNo].UseStatus = '1') and
     (FTeeboxInfoList[nSeatNo].RemainMinute > 0) then
  begin
    global.ReserveList.SetTeeboxReserveNext(ASeatReserveInfo);
    sStr := '�űԹ������ : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate + ' -> ' +
          ASeatReserveInfo.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo := ASeatReserveInfo.ReserveNo;
  FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin := ASeatReserveInfo.UseMinute;
  FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls := ASeatReserveInfo.UseBalls;
  if Global.ADConfig.ProtocolType = 'JEHU435' then
  begin
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls > 999 then
      FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls := 999;
  end
  else
  begin
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls > 9999 then
      FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls := 9999;
  end;

  FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin := ASeatReserveInfo.DelayMinute;
  if FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin < 0 then
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin := 0;

  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate := ASeatReserveInfo.ReserveDate;
  FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := '';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate := '';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareCtlYn := 'N';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'N';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignYn:= ASeatReserveInfo.AssignYn;

  if ASeatReserveInfo.ReserveDate <= formatdatetime('YYYYMMDDhhnnss', Now) then
  begin
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := formatdatetime('YYYYMMDDhhnn00', Now); //2021-06-11 ��00 ǥ��-�̼����̻��
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate) +
                                                            (((1/24)/60) * FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin);
  end
  else
  begin
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := ASeatReserveInfo.ReserveDate;
    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate) +
                                                         (((1/24)/60) * FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin);
  end;

  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate := '';
  FTeeboxInfoList[nSeatNo].DelayMin := 0;
  FTeeboxInfoList[nSeatNo].UseCancel := 'N';
  FTeeboxInfoList[nSeatNo].UseClose := 'N';
  FTeeboxInfoList[nSeatNo].PrepareChk := 0;
end;

function TTeebox.SetTeeboxReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
var
  nSeatNo, nCtlMin: Integer;
  sStr: String;
  nVXMin: integer;
  //2020-08-27 v26 �̿�Ÿ�� �ð��߰��� ����Ÿ�� �ð�����
  nDelayMin: Integer;
  nCtlSecond: Integer;
begin
  Result:= False;

  nSeatNo := ASeatUseInfo.SeatNo;
  if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo <> ASeatUseInfo.ReserveNo then
  begin
    Global.ReserveList.SetTeeboxReserveNextChange(nSeatNo, ASeatUseInfo);
    Exit;
  end;

  //���ð�/�����ð� ���� üũ
  if (FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin = ASeatUseInfo.PrepareMin) and
     (FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin = ASeatUseInfo.AssignMin) then
  begin
    //����� ���� ����
    Exit;
  end;

  if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn = 'N' then
  begin
    sStr := '��������ð����� no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
            '���ð�' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' -> ' +
            IntToStr(ASeatUseInfo.PrepareMin) + ' / ' +
            '�����ð�' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin) + ' -> ' +
            IntToStr(ASeatUseInfo.AssignMin);

    //2020-05-29 ���������
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin <> ASeatUseInfo.AssignMin then
    begin
      nVXMin := ASeatUseInfo.AssignMin - FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin;

      if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      begin
        //2020-08-27 v26 �ð��߰��� ����Ÿ���ð��߰�
        nDelayMin := 0;
        if FTeeboxInfoList[nSeatNo].RemainMinute < ASeatUseInfo.AssignMin then
        begin
          nDelayMin := ASeatUseInfo.AssignMin - FTeeboxInfoList[nSeatNo].RemainMinute;
        end;

        FTeeboxInfoList[nSeatNo].RemainMinute := ASeatUseInfo.AssignMin;
      end;
    end;

    if FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin <> ASeatUseInfo.PrepareMin then
    begin
      nVXMin := nVXMin + (ASeatUseInfo.PrepareMin - FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin);

      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate) +
                                                          (((1/24)/60) * ASeatUseInfo.PrepareMin);
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin := ASeatUseInfo.PrepareMin;

      if (Global.ADConfig.StoreCode = 'CD001') and (FTeeboxInfoList[nSeatNo].TeeboxNo > 52) then //CD001	��Ÿ����Ŭ��(�ϻ�)
      begin
        FTeeboxInfoList[nSeatNo].AgentCtlType := 'D';
        nCtlSecond := SecondsBetween(now, FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime);
        SetTeeboxAgentCtrl('Tprepare', FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nSeatNo].TeeboxNo, FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin, nCtlSecond);
      end;

      if (Global.ADConfig.StoreCode = 'A0003') then //	�븲��ũ�κ�
      begin
        FTeeboxInfoList[nSeatNo].AgentCtlType := 'D';
        nCtlSecond := SecondsBetween(now, FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime);
        SetTeeboxAgentCtrl('Tprepare', FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nSeatNo].TeeboxNo, FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin, nCtlSecond);
      end;
    end;

    if Global.ADConfig.XGM_VXUse = True then //2023-01-25 ������ �߰�
    begin
      if (Global.ADConfig.StoreCode = 'B7001') and (FTeeboxInfoList[nSeatNo].TeeboxNo > 52) then //������
      begin
        if nVXMin > 0 then
          SetTeeboxVXCtrl('VXadd', FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nSeatNo].TeeboxNm, nVXMin);
      end;
    end;

  end
  else
  begin
    //�������� �����ð� ���游 üũ
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin <> ASeatUseInfo.AssignMin then
    begin
      if ASeatUseInfo.AssignMin < 2 then
        ASeatUseInfo.AssignMin := 2; // 0 ���� ����� ���ð� ���� �����

      if Global.ADConfig.ProtocolType = 'JEHU435' then
      begin
        if (Global.ADConfig.StoreCode = 'A9001') or (Global.ADConfig.StoreCode = 'D2001') then //��������, ����
        begin
          FTeeboxInfoList[nSeatNo].UseReset := 'Y';
          SetTeeboxCtrlAD(nSeatNo, 'S1' , 0, 0000);
          sStr := '�����ð����� : �ʱ�ȭ';
          Global.Log.LogReserveWrite(sStr);
        end;
      end;

      //�����ð����� ���� ����迭�� ���
      nCtlMin := ASeatUseInfo.RemainMin + (ASeatUseInfo.AssignMin - FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin);

      if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      begin
        //2020-08-27 v26 �ð��߰��� ����Ÿ���ð��߰�
        nDelayMin := 0;
        if ASeatUseInfo.RemainMin < ASeatUseInfo.AssignMin then
        begin
          nDelayMin := ASeatUseInfo.AssignMin - ASeatUseInfo.RemainMin;
        end;

        FTeeboxInfoList[nSeatNo].RemainMinute := nCtlMin;
      end
      else if (Global.ADConfig.ProtocolType = 'NANO') or (Global.ADConfig.ProtocolType = 'NANO2') then
        SetTeeboxCtrlAD(nSeatNo, 'S2' , nCtlMin, FTeeboxInfoList[nSeatNo].RemainBall)
      else
        SetTeeboxCtrlAD(nSeatNo, 'S1' , nCtlMin, FTeeboxInfoList[nSeatNo].RemainBall);

      sStr := '�����ð����� no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
              '�����ð�' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin) + ' -> ' +
              IntToStr(ASeatUseInfo.AssignMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].RemainMinute) + ' -> ' +
              IntToStr(nCtlMin);

      if Global.ADConfig.XGM_VXUse = True then //2023-01-25 ������ �߰�
      begin
        if (Global.ADConfig.StoreCode = 'B7001') and (FTeeboxInfoList[nSeatNo].TeeboxNo > 52) then //������
        begin
          nVXMin := ASeatUseInfo.AssignMin - FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin;

          if nVXMin > 0 then
            SetTeeboxVXCtrl('VXadd', FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nSeatNo].TeeboxNm, nVXMin);
        end;
      end;

      if (Global.ADConfig.StoreCode = 'CD001') and (FTeeboxInfoList[nSeatNo].TeeboxNo > 52) then //CD001	��Ÿ����Ŭ��(�ϻ�)
      begin
        FTeeboxInfoList[nSeatNo].AgentCtlType := 'C';
        nCtlSecond := SecondsBetween(now, IncMinute(DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate), ASeatUseInfo.AssignMin));
        SetTeeboxAgentCtrl('Tchange', FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nSeatNo].TeeboxNo, nCtlMin, nCtlSecond);
      end;

      if (Global.ADConfig.StoreCode = 'A0003') then //	�븲��ũ�κ�
      begin
        FTeeboxInfoList[nSeatNo].AgentCtlType := 'C';
        nCtlSecond := SecondsBetween(now, IncMinute(DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate), ASeatUseInfo.AssignMin));
        SetTeeboxAgentCtrl('Tchange', FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nSeatNo].TeeboxNo, nCtlMin, nCtlSecond);
      end;

    end;

  end;

  Global.Log.LogReserveWrite(sStr);
  FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin := ASeatUseInfo.AssignMin;

  if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
    Global.ReserveList.ResetTeeboxReserveMinAddJMS(nSeatNo, nDelayMin);

  Result:= True;
end;

function TTeebox.SetTeeboxReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    //������, ������ Ÿ���� �ƴ�
    Global.ReserveList.SetTeeboxReserveNextCancel(ATeeboxNo, AReserveNo);
    Exit;
  end;

  //������� ����迭�� ���
  FTeeboxInfoList[ATeeboxNo].UseCancel := 'Y';

  if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
    FTeeboxInfoList[ATeeboxNo].RemainMinute := 0
  //2020-12-17 ���丮�� �߰�
  else if FTeeboxInfoList[ATeeboxNo].ControlYn = 'N' then
    FTeeboxInfoList[ATeeboxNo].RemainMinute := 0
  else
    SetTeeboxCtrlAD(ATeeboxNo, 'S1', 0, 9999);

  sStr := 'Cancel no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

function TTeebox.SetTeeboxReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    Exit;
  end;

  FTeeboxInfoList[ATeeboxNo].UseClose := 'Y';

  if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
    FTeeboxInfoList[ATeeboxNo].RemainMinute := 0
  //2020-12-17 ���丮�� �߰�
  else if FTeeboxInfoList[ATeeboxNo].ControlYn = 'N' then
  begin
    FTeeboxInfoList[ATeeboxNo].RemainMinute := 0;
    FTeeboxInfoList[ATeeboxNo].DeviceRemainMin := 0;
  end
  else
    SetTeeboxCtrlAD(ATeeboxNo, 'S1', 0, 9999);

  sStr := 'Close no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo;
  Global.Log.LogServerWrite(sStr);
  Result := True;
end;

//chy 2020-10-27 ��ù���
function TTeebox.SetTeeboxReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sStr, sResult: String;
begin
  Result := '';

  if FTeeboxInfoList[ATeeboxNo].UseStatus <> '0' then
  begin
    Result := '������� Ÿ���Դϴ�. ����: ' + FTeeboxInfoList[ATeeboxNo].UseStatus;
    Exit;
  end;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo = AReserveNo then
  begin
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime := Now;

    sStr := '��ù��� ��� no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo;
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

function TTeebox.GetDevicToFloorTeeboxNo(AFloor, ADev: String): Integer;
var
  i: Integer;
  sFloorCd, sDeviceId: String;
begin
  Result := 0;
  sFloorCd := AFloor;

  for i := 1 to FTeeboxLastNo do
  begin

    //�۵�: 'A5001' jeu60A, 1 port ���
    if sFloorCd <> '0' then // 0: ������Ʈ
    begin
      if FTeeboxInfoList[i].FloorZoneCode <> sFloorCd then
        Continue;
    end;

    if FTeeboxInfoList[i].DelYn = 'Y' then
      Continue;

    if (Global.ADConfig.StoreCode = 'A8004') or //A8004	�����(������)
       (Global.ADConfig.StoreCode = 'BF001') or //�μ�
       (Global.ADConfig.StoreCode = 'CF001') then //����������
    begin
      if (FTeeboxInfoList[i].TeeboxZoneCode = 'L') or (FTeeboxInfoList[i].TeeboxZoneCode = 'C') then //�¿���, VIP��(Ŀ��)
      begin
        sDeviceId := Copy(FTeeboxInfoList[i].DeviceId, 1, Global.ADConfig.DeviceCnt);
        if (sDeviceId = ADev) then
        begin
          Result := i;
          Break;
        end;
      end
      else
      begin
        if FTeeboxInfoList[i].DeviceId = ADev then
        begin
          Result := i;
          Break;
        end;
      end;
    end
    else
    begin
      if FTeeboxInfoList[i].DeviceId = ADev then
      begin
        Result := i;
        Break;
      end;
    end;
  end;

end;

function TTeebox.GetDevicToFloorIndexTeeboxNo(AFloor: String; AIndex: Integer; ADev: String): Integer;
var
  i: Integer;
  sDeviceIdR, sDeviceIdL: String;
begin
  Result := 0;
  for i := 1 to FTeeboxLastNo do
  begin

    if AFloor <> '0' then // 0: ������Ʈ
    begin
      if FTeeboxInfoList[i].FloorZoneCode <> AFloor then
        Continue;
    end;

    if FTeeboxInfoList[i].DelYn = 'Y' then
      Continue;

    //�����濡 ���� ��ġID ���, �����ڰ� ���� �ε����� ��
    //1, 2 -> 1�� / 1 = No:1~15 / Nm:1-15��
    if AIndex = 2 then // No:16~25 / Nm:16-25/26
    begin
      if FTeeboxInfoList[i].TeeboxNo < 16 then
        Continue;
    end;

    //3, 4 -> 2�� / 3 = No:26~39 Nm:27-40
    if AIndex = 4 then // No:40~50 / Nm: 41-51/52
    begin
      if FTeeboxInfoList[i].TeeboxNo < 40 then
        Continue;
    end;

    if FTeeboxInfoList[i].DeviceId = ADev then
    begin
      Result := i;
      Break;
    end;
  end;

end;

function TTeebox.GetDeviceToFloorIndexTeeboxInfo(AFloor: String; AIndex: Integer; AChannelCd: String): TTeeboxInfo;
var
  i: Integer;
begin

  for i := 1 to FTeeboxLastNo do
  begin

    if AFloor <> '0' then // 0: ������Ʈ
    begin
      if FTeeboxInfoList[i].FloorZoneCode <> AFloor then
        Continue;
    end;

    if FTeeboxInfoList[i].DelYn = 'Y' then
      Continue;

    //�����濡 ���� ��ġID ���, �����ڰ� ���� �ε����� ��
    //1, 2 -> 1�� / 1 = 1-15
    if AIndex = 2 then // No:16~25 / Nm:16-25/26
    begin
      if FTeeboxInfoList[i].TeeboxNo < 16 then
        Continue;
    end;

    //3, 4 -> 2�� / 3 = No:26~39 Nm:27-40
    if AIndex = 4 then // No:40~50 / Nm: 41-51/52
    begin
      if FTeeboxInfoList[i].TeeboxNo < 40 then
        Continue;
    end;

    if FTeeboxInfoList[i].DeviceId = AChannelCd then
    begin
      Result := FTeeboxInfoList[i];
      Break;
    end;
  end;

end;

function TTeebox.GetDeviceToFloorTeeboxInfo(AFloor, AChannelCd: String): TTeeboxInfo; //����� Ÿ������ Ȯ�ο�
var
  nIndex: Integer;
  sFloorCd, sDeviceIdR, sDeviceIdL: String;
  sDeviceId: String;
begin

  for nIndex := 1 to FTeeboxLastNo do
  begin

    if AFloor <> '0' then // 0: ������Ʈ
    begin
      // 1���� port�� 2���� ����/���� ��ġID  ���
      if (Global.ADConfig.StoreCode = 'D2001') then // D2001	������Ʈ���� ����������
      begin
        //1:1~31, 2:32~62, 3:63~93, 4:94~124
        sFloorCd := FTeeboxInfoList[nIndex].FloorZoneCode;
        if sFloorCd = '2' then
          sFloorCd := '1';
        if sFloorCd = '4' then
          sFloorCd := '3';

        if sFloorCd <> AFloor then
          Continue;
      end
      else
      begin
        if FTeeboxInfoList[nIndex].FloorZoneCode <> AFloor then
          Continue;
      end;
    end;

    if (FTeeboxInfoList[nIndex].TeeboxZoneCode = 'L') or   //�¿���
       (FTeeboxInfoList[nIndex].TeeboxZoneCode = 'C') then //�¿���, VIP��(Ŀ��)
    begin
      if (Global.ADConfig.StoreCode = 'AB001') or //�뼺����Ŭ��
         (Global.ADConfig.StoreCode = 'B7001') or //�����ڰ���������
         (Global.ADConfig.StoreCode = 'A8001') then //�����(������)
      begin
        if FTeeboxInfoList[nIndex].DeviceId = AChannelCd then
        begin
          Result := FTeeboxInfoList[nIndex];
          Break;
        end;
      end
      else if (Global.ADConfig.StoreCode = 'C0001') or //����������
              (Global.ADConfig.StoreCode = 'BB001') or // ������,
            	(Global.ADConfig.StoreCode = 'A8003') or // �����(������)
             	(Global.ADConfig.StoreCode = 'B8001') or // �������̰���Ŭ��
              (Global.ADConfig.StoreCode = 'AC001') or // ����
              (Global.ADConfig.StoreCode = 'B9001') then  // �Ľ���
      begin
        if Global.ADConfig.ProtocolType = 'MODENYJ' then
        begin
          sDeviceIdR := Copy(FTeeboxInfoList[nIndex].DeviceId, 1, 2);
          sDeviceIdL := Copy(FTeeboxInfoList[nIndex].DeviceId, 3, 2);
        end
        else
        begin
          sDeviceIdR := Copy(FTeeboxInfoList[nIndex].DeviceId, 1, 3);
          sDeviceIdL := Copy(FTeeboxInfoList[nIndex].DeviceId, 4, 3);
        end;

        if (sDeviceIdR = AChannelCd) or (sDeviceIdL = AChannelCd) then
        begin
          Result := FTeeboxInfoList[nIndex];
          Break;
        end;
      end
      else
      begin
        //���� �¿��� ���� ��� ��� ��Ʈ�ʼ��� ��ġID �� ������ ���� �ʿ�
        // A8004	�����(������), BF001 �μ�, CB001 //�д�׸��Ǿ�
        sDeviceId := Copy(FTeeboxInfoList[nIndex].DeviceId, 1, Global.ADConfig.DeviceCnt);

        if (sDeviceId = AChannelCd) then
        begin
          Result := FTeeboxInfoList[nIndex];
          Break;
        end;

      end;

    end
    else
    begin
      if FTeeboxInfoList[nIndex].DeviceId = AChannelCd then
      begin
        Result := FTeeboxInfoList[nIndex];
        Break;
      end;
    end;
  end;

end;

function TTeebox.GetTeeboxInfoUseYn(ATeeboxNo: Integer): String;
begin
  Result := FTeeboxInfoList[ATeeboxNo].UseYn;
end;

function TTeebox.GetTeeboxFloorNm(ATeeboxNo: Integer): String;
begin
  Result := FTeeboxInfoList[ATeeboxNo].FloorNm;
end;
function TTeebox.GetTeeboxErrorCode(ATeeboxNo: Integer): String;
begin
  Result := FTeeboxInfoList[ATeeboxNo].ErrorCd2;
end;

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

    for nIndex := 1 to TeeboxLastNo do
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

function TTeebox.GetTeeboxStatus(ATeebox: String): AnsiString;
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

    nIndex := StrToInt(ATeebox);
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

function TTeebox.GetTeeboxStatusError(ATeebox, ATeebox1: String): AnsiString;
var
  nIndex: Integer;
  sJsonStr: AnsiString;
  jObj, jItemObj: TJSONObject; //Erp ��������
  jObjArr: TJSONArray;

  slErrorS, slErrorE: TStringList;
  I: Integer;
  sErrorCode: string;
begin
  try
    slErrorS := TStringList.Create;
    slErrorE := TStringList.Create;

    jObjArr := TJSONArray.Create;
    jObj := TJSONObject.Create;
    jObj.AddPair(TJSONPair.Create('store_cd', Global.ADConfig.StoreCode));
    jObj.AddPair(TJSONPair.Create('user_id', Global.ADConfig.UserId));
    jObj.AddPair(TJSONPair.Create('data', jObjArr));

    if ATeebox <> EmptyStr then
    begin
      ExtractStrings(['/'], [], PChar(ATeebox), slErrorS);
      for I := 0 to slErrorS.Count - 1 do
      begin
        jItemObj := TJSONObject.Create;
        jItemObj.AddPair( TJSONPair.Create( 'teebox_no', slErrorS[I] ) );
        jItemObj.AddPair( TJSONPair.Create( 'use_status', '9' ) );

        sErrorCode := GetTeeboxErrorCode(StrToInt(slErrorS[I]));
        jItemObj.AddPair( TJSONPair.Create( 'error_code', sErrorCode ) );

        jObjArr.Add(jItemObj);
      end;
    end;

    if ATeebox1 <> EmptyStr then
    begin
      ExtractStrings(['/'], [], PChar(ATeebox1), slErrorE);
      for I := 0 to slErrorE.Count - 1 do
      begin
        nIndex := StrToInt(slErrorE[I]);
        jItemObj := TJSONObject.Create;
        jItemObj.AddPair( TJSONPair.Create( 'teebox_no', IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) ) );
        jItemObj.AddPair( TJSONPair.Create( 'use_status', FTeeboxInfoList[nIndex].UseStatus ) );
        jItemObj.AddPair( TJSONPair.Create( 'error_code', '' ) );
        jObjArr.Add(jItemObj);
      end;
    end;

    sJsonStr := jObj.ToString;
  finally
    jObj.Free;
    slErrorS.Free;
    slErrorE.Free;
  end;

  Result := sJsonStr;
end;

procedure TTeebox.SetStoreClose;
var
  nIndex: Integer;
  sSendData, sBcc: AnsiString;
  sStr: String;
begin
  for nIndex := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nIndex].UseYn = 'N' then
      Continue;

    if FTeeboxInfoList[nIndex].RemainMinute <= 0 then
      Continue;

    //�ð��ʱ�ȭ ����迭 ���
    FTeeboxInfoList[nIndex].UseClose := 'Y';

    //2020-08-26 v26 JMS ��������� Ÿ������ �߰�
    if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      FTeeboxInfoList[nIndex].RemainMinute := 0
    else
      //SetTeeboxCtrl(nIndex, 'S1' , 0, 9999);
      SetTeeboxCtrlAD(nIndex, 'S1' , 0, 9999);

    sStr := 'Close : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
            IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;
end;

//2021-06-02 ����, MODENYJ / Ÿ����������
procedure TTeebox.SetTeeboxCtrlRemainMin(ATeeboxNo: Integer; ATime: Integer);
begin
  FTeeboxInfoList[ATeeboxNo].RemainMinute := ATime;
  FTeeboxInfoList[ATeeboxNo].CheckCtrl := True;
end;

//2021-06-02 ����, MODENYJ / Ÿ����������
procedure TTeebox.SetTeeboxCtrlRemainMinFree(ATeeboxNo: Integer);
begin
  if FTeeboxInfoList[ATeeboxNo].CheckCtrl = False then
    Exit;

  FTeeboxInfoList[ATeeboxNo].RemainMinute := 0;
  FTeeboxInfoList[ATeeboxNo].CheckCtrl := False;
end;

function TTeebox.ResetTeeboxRemainMinAdd(ATeeboxNo, ADelayTm: Integer; ATeeboxNm: String): Boolean;
var
  sResult: String;
  sDate, sStr: String;
  sDateTime: String; //��ȸ�����۽ð�
begin

  //2020-06-29 ������üũ
  if ADelayTm = 0 then
    Exit;

  if (Global.Store.UseRewardYn = 'N') and (Global.Store.UseRewardException = 'Y') then
  begin
    if ADelayTm > 60 then
    begin
      sStr := 'ADelayTm > 60 : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + IntToStr(ADelayTm);
      Global.Log.LogReserveWrite('ResetTeeboxReserveDateAdd : ' + sStr);
      Exit;
    end;
  end
  else
  begin
    //if ADelayTm > 10 then //����� 10���̻��� ��� (�������) ������. �������� ���ڼ� 13���̻��̿��� ������. 2023-10-11
    //if ADelayTm > 15 then //ĳ������ 14�� �̻� ��ȸ��
    if ADelayTm > 20 then
    begin
      //sStr := 'ADelayTm > 10 : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + IntToStr(ADelayTm);
      //sStr := 'ADelayTm > 15 : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + IntToStr(ADelayTm);
      sStr := 'ADelayTm > 20 : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + IntToStr(ADelayTm);
      Global.Log.LogReserveWrite('ResetTeeboxReserveDateAdd : ' + sStr);
      Exit;
    end;
  end;

  sDate := formatdatetime('YYYYMMDD', Now);

  // MODENYJ ó�� AD ��ü �ð� ����� ���  �����ð��߰� ���� DB�� ����, �����use_status = 1
  sResult := Global.XGolfDM.SetSeatReserveUseMinAdd(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm));
  sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm);
  Global.Log.LogReserveWrite('ResetTeeboxUseMinAdd : ' + sStr);

  //2021-06-24 �Ѱ�, ��ȸ���߿� ������û�� ��� DB ����ð� �̺��� ��ġ, ����� use_status = 4
  sDateTime := formatdatetime('YYYYMMDDHHNNSS', FTeeboxInfoList[0].PauseTime);
  sResult := Global.XGolfDM.SetSeatReserveTmChange(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm), sDateTime);
  sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm) + ' / ' + sDateTime;

  Global.Log.LogReserveWrite('ResetTeeboxReserveDateAdd : ' + sStr);
end;

function TTeebox.ResetTeeboxRemainMinAddJMS(ATeeboxNo, ADelayTm: Integer): Boolean;
var
  sResult: String;
  sDate, sStr: String;
  I: integer;
  tmReserve: TDateTime;
begin
  if ADelayTm = 0 then
    Exit;
  { ����
  if ADelayTm > 30 then
  begin
    ADelayTm := 30;
    Global.Log.LogReserveWrite('AssignMin Add : 30 OVer');
  end;
  }
  FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin := FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin + ADelayTm;
  sStr := IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin) + ' / ' + IntToStr(ADelayTm);
  Global.Log.LogReserveWrite('AssignMin Add : ' + sStr);

  Global.ReserveList.ResetTeeboxReserveMinAddJMS(ATeeboxNo, ADelayTm);
end;

procedure TTeebox.TeeboxReserveNextChk;
var
  nIndex, nTeeboxNo, nIdx: Integer;
  sLog, sCancel: String;
  I: Integer;
  SeatUseReserve: TSeatUseReserve;
begin

  try

    for nTeeboxNo := 1 to TeeboxLastNo do
    begin

      //2020-12-17 ���ڵ�
      if FTeeboxInfoList[nTeeboxNo].ControlYn <> 'N' then
      begin
        if FTeeboxInfoList[nTeeboxNo].ComReceive <> 'Y' then
          Continue;
      end;

      if (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) or (FTeeboxInfoList[nTeeboxNo].UseStatus <> '0') then
        Continue;

      //Ÿ���� �������� Ȯ��
      //if FSeatInfoList[nTeeboxNo].SeatReserve.ReserveNo = '' then
      //  Continue;

      if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
        Continue;

      //2020-05-29 �����߰�, 2021-07-21 ���Ǽ���
      if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate <> '') and (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') then
        Continue;

      Global.ReserveList.ReserveListNextChk(nTeeboxNo);
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
  nTeeboxNo: Integer;
begin
  Result := False;

  if ATeeboxNo = '-1' then
    Exit;

  nTeeboxNo := StrToInt(ATeeboxNo);
  FTeeboxInfoList[nTeeboxNo].HoldUse := AUse;
  FTeeboxInfoList[nTeeboxNo].HoldUser := AUserId;

  Result := True;
end;

function TTeebox.GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;
var
  nTeeboxNo: Integer;
begin
  nTeeboxNo := StrToInt(ATeeboxNo);

  //2020-05-27 ����: Insert
  if AType = 'Insert' then
  begin
    if FTeeboxInfoList[nTeeboxNo].HoldUser = AUserId then
      Result := False //Ȧ�����ڰ� �����ϸ�
    else
      Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end
  else if AType = 'Delete' then
  begin
    if FTeeboxInfoList[nTeeboxNo].HoldUser = AUserId then
      Result := True //Ȧ�����ڰ� �����ϸ�
    else
      Result := False;
  end
  else
  begin
    Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end;

end;

function TTeebox.GetTeeboxNowReserveLastTime(ATeeboxNo: String): String; //2021-04-19 ���ð� ����ð� ����
var
  nIdx, nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sStartDate, sStr, sLog: String;
  DelayMin, UseMin, nCnt: Integer;
begin
  sStr := '0';

  nTeeboxNo := StrToInt(ATeeboxNo);
  nCnt := Global.ReserveList.GetTeeboxReserveNextListCnt(nTeeboxNo);
  if nCnt = 0 then
  begin
    sStartDate := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
    //DelayMin := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;
    UseMin := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin;

    ReserveTm := DateStrToDateTime3(sStartDate) + ( ((1/24)/60) * UseMin );

    //sStr := FormatDateTime('YYYYMMDDhhnnss', ReserveTm);
    sStr := FormatDateTime('YYYYMMDDhhnn00', ReserveTm); //2021-06-11
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
      Global.Log.LogReserveDelayWrite(sLog);

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
var
  nIdx: Integer;
begin
  SetLength(FTeeboxInfoList, 0);

  for nIdx := 0 to FSendApiErrorList.Count - 1 do
  begin
    FSendApiErrorList.Delete(0);
  end;
  FreeAndNil(FSendApiErrorList);
end;

function TTeebox.SetTeeboxReserveCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
  tmTemp: TDateTime;
  nNN: integer;
  sJsonStr: AnsiString;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    //������, ������ Ÿ���� �ƴ�
    Global.ReserveList.SetTeeboxReserveNextCheckIn(ATeeboxNo, AReserveNo);

    //üũ�� DB ����
    Global.XGolfDM.SeatUseCheckInNextUpdate(Global.ADConfig.StoreCode, AReserveNo);

    Exit;
  end;

  //üũ���� �������� ���ð�, �����ð� ����
  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime < Now then //���ð��� �ʰ�������
  begin
    nNN := MinutesBetween(now, FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime);
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin := FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin - nNN;
  end;

  FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignYn := 'Y';

  //üũ�� DB ����
  Global.XGolfDM.SeatUseCheckInUpdate(Global.ADConfig.StoreCode, AReserveNo, FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin);

  //üũ������ ���� �����ð� ���� erp �������� ������ �׸����� ���
  sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode +
              '&teebox_no=' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) +
              '&reserve_no=' + AReserveNo +
              '&assign_min=' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin) +
              '&prepare_min=' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareMin) +
              '&assign_balls=9999' +
              '&user_id=' + Global.ADConfig.UserId +
              '&memo=';
  SetSendApiErrorAdd(AReserveNo, 'K703_TeeboxChg', sJsonStr);

  sStr := 'checkIn no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
          intToStr(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareMin) + ' / ' +
          IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin);
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;


procedure TTeebox.TeeboxStatusChkAD;
var
  nTeeboxNo: Integer;
  sStr, sEndTy, sChange, sResult, sLog: String;
  I, nNN, nTmTemp, nTemp: Integer;
  tmTempS: TDateTime;

  //������ �߻�����
  bTeeboxError: Boolean;
  sErrorS, sErrorE: String;
begin

  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sLog := 'SeatReserveUse TeeboxStatusChkAD!';
    Global.Log.LogReserveDelayWrite(sLog);

    sleep(50);
  end;
  FTeeboxStatusUse := True;

  //������ �߻�,������ ���� ��Ʈ�ʼ��� ���� ������Ʈ
  bTeeboxError := False;
  sErrorS := EmptyStr;
  sErrorE := EmptyStr;

  for nTeeboxNo := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].UseYn <> 'Y' then
      Continue;

    if (Global.ADConfig.StoreCode = 'B2001') then //�׸��ʵ�
    begin
      if FTeeboxInfoList[nTeeboxNo].DeviceUseStatus = 'M' then
      begin
        if FTeeboxInfoList[nTeeboxNo].UseStatus <> '8' then
        begin
          Global.XGolfDM.TeeboxErrorUpdate('AD', IntToStr(nTeeboxNo), '8');
          Global.Teebox.TeeboxDeviceCheck(nTeeboxNo, '8');
        end;

        sStr := 'Ÿ���� ���� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
        Global.Log.LogReserveWrite(sStr);
      end;
    end;

    if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '7') and //��ȸ��
       (FTeeboxInfoList[nTeeboxNo].UseStatus <> '8') then //����
    begin
      if FTeeboxInfoList[nTeeboxNo].DeviceUseStatus = '9' then // Ÿ���� �������, ������/����̻�
      begin
        if FTeeboxInfoList[nTeeboxNo].UseStatus <> '9' then //���°� ������ �ƴϸ�
        begin
          FTeeboxInfoList[nTeeboxNo].UseStatusPre := FTeeboxInfoList[nTeeboxNo].UseStatus;
          FTeeboxInfoList[nTeeboxNo].UseStatus := '9';
          FTeeboxInfoList[nTeeboxNo].ErrorCd := FTeeboxInfoList[nTeeboxNo].DeviceErrorCd;
          FTeeboxInfoList[nTeeboxNo].ErrorCd2 := FTeeboxInfoList[nTeeboxNo].DeviceErrorCd2;

          Global.XGolfDM.TeeboxErrorStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

          sStr := 'Error No: ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  'ErrorCd : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].UseStatusPre + ' -> 9';
          Global.Log.LogWrite(sStr);

          bTeeboxError := True;
          if sErrorS = EmptyStr then
            sErrorS := IntToStr(nTeeboxNo)
          else
            sErrorS := sErrorS + '/' + IntToStr(nTeeboxNo);

          //������ϰ�� ������ �������� ����
          //if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> EmptyStr) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and (FTeeboxInfoList[nTeeboxNo].ErrorCd <> 8) then
          if FTeeboxInfoList[nTeeboxNo].ErrorCd <> 8 then
          begin
            FTeeboxInfoList[nTeeboxNo].PauseTime := Now;
            FTeeboxInfoList[nTeeboxNo].ErrorReward := False;
            FTeeboxInfoList[nTeeboxNo].SendSMS := 'N';
            FTeeboxInfoList[nTeeboxNo].SendACS := 'N';
            Global.WriteConfigError(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo);
          end;
        end;

        if (global.ADConfig.ErrorTimeReward = True) then //������ �ð�����
        begin
          //������ϰ�� ������ ���� �ִ� 10�� üũ, �����������̸�
          if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> EmptyStr) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
             (FTeeboxInfoList[nTeeboxNo].ErrorReward = False) and (FTeeboxInfoList[nTeeboxNo].ErrorCd <> 8) then
          begin
            nTemp := MinutesBetween(FTeeboxInfoList[nTeeboxNo].PauseTime, Now);
            if nTemp >= 10 then
            begin
              FTeeboxInfoList[nTeeboxNo].RePlayTime := Now;
              FTeeboxInfoList[nTeeboxNo].ErrorReward := True;
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin + 10;

              ResetTeeboxRemainMinAdd(nTeeboxNo, 10, FTeeboxInfoList[nTeeboxNo].TeeboxNm);
              Global.WriteConfigErrorReward(nTeeboxNo);
            end;
          end;
        end;

        //2020-11-05 ������ 1�� �̻������� ���ڹ߼�
        if (global.Store.ErrorSms = 'Y') or ((global.Store.ACS = 'Y') and (global.Store.ACS_1_Yn = 'Y')) then
        begin
          nTemp := SecondsBetween(FTeeboxInfoList[nTeeboxNo].PauseTime, now);

          if nTemp > 30 then //30���̻� ������ ������
          begin
            if (global.Store.ErrorSms = 'Y') then
            begin
              if FTeeboxInfoList[nTeeboxNo].SendSMS <> 'Y' then
              begin
                Global.SendSMSToErp('1', FTeeboxInfoList[nTeeboxNo].TeeboxNm);
                FTeeboxInfoList[nTeeboxNo].SendSMS := 'Y';
                sStr := 'SendSMSToErp No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm;
                Global.Log.LogErpApiWrite(sStr);
              end;
            end;
          end;

          if nTemp > global.Store.ACS_1 then //30���̻� ������ ������
          begin
            if (global.Store.ACS = 'Y') and (global.Store.ACS_1_Yn = 'Y') then
            begin
              if FTeeboxInfoList[nTeeboxNo].SendACS <> 'Y' then
              begin
                Global.SendACSToErp('1', FTeeboxInfoList[nTeeboxNo].TeeboxNm);
                FTeeboxInfoList[nTeeboxNo].SendACS := 'Y';
                sStr := 'SendACSToErp No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm;
                Global.Log.LogErpApiWrite(sStr);
              end;
            end;
          end;
        end;

      end
      else
      begin
        if FTeeboxInfoList[nTeeboxNo].UseStatus = '9' then //���°� �����̸�
        begin

          if (global.ADConfig.ErrorTimeReward = True) then //������ �ð�����
          begin

            //������ϰ�� ������ ����
            if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> EmptyStr) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
               (FTeeboxInfoList[nTeeboxNo].ErrorReward = False) and (FTeeboxInfoList[nTeeboxNo].ErrorCd <> 8) then
            begin
              FTeeboxInfoList[nTeeboxNo].RePlayTime := Now;
              FTeeboxInfoList[nTeeboxNo].ErrorReward := True;
              nTemp := MinutesBetween(FTeeboxInfoList[nTeeboxNo].PauseTime, FTeeboxInfoList[nTeeboxNo].RePlayTime);
              if nTemp > 0 then
              begin
                if nTemp > 10 then
                begin
                  sStr := 'PauseTime Fail DelayTm > 10 : ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' + IntToStr(nTemp);
                  Global.Log.LogReserveWrite(sStr);

                  nTemp := 10;
                end;

                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin + nTemp;

                ResetTeeboxRemainMinAdd(nTeeboxNo, nTemp, FTeeboxInfoList[nTeeboxNo].TeeboxNm);
                Global.WriteConfigErrorReward(nTeeboxNo);
              end;
            end;
          end;

          if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
            FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
          else
            FTeeboxInfoList[nTeeboxNo].UseStatus := '1';
          FTeeboxInfoList[nTeeboxNo].ErrorCd := FTeeboxInfoList[nTeeboxNo].DeviceErrorCd;
          FTeeboxInfoList[nTeeboxNo].ErrorCd2 := FTeeboxInfoList[nTeeboxNo].DeviceErrorCd2;

          Global.XGolfDM.TeeboxErrorStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

          sStr := 'Error No: ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  'ErrorCd : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) + ' / ' +
                  '9 -> ' + FTeeboxInfoList[nTeeboxNo].UseStatus;
          Global.Log.LogWrite(sStr);

          bTeeboxError := True;
          if sErrorE = EmptyStr then
            sErrorE := IntToStr(nTeeboxNo)
          else
            sErrorE := sErrorE + '/' + IntToStr(nTeeboxNo);

        end;
      end;

      if FTeeboxInfoList[nTeeboxNo].UseStatus <> '9' then
      begin
        if (Global.ADConfig.ReserveMode = True) then //������
        begin
          if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
            FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
          else
          begin
            if FTeeboxInfoList[nTeeboxNo].DeviceUseStatus = 'D' then
              FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
            else
              FTeeboxInfoList[nTeeboxNo].UseStatus := '1';

            //Ÿ������ ������ ���
            if (FTeeboxInfoList[nTeeboxNo].DeviceUseStatus = '1') and
               (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') and
               (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate < formatdatetime('YYYYMMDDhhnnss', Now)) then
            begin
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnn00', Now); //2021-06-11

              sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                      FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                      IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
              Global.Log.LogReserveWrite(sStr);

              // DB/Erp����: ���۽ð�
              Global.TcpServer.SetApiTeeBoxReg(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                               FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);

              if (Global.ADConfig.StoreCode = 'B8001') then // �������̰���Ŭ��
              begin
                if (FTeeboxInfoList[nTeeboxNo].TeeboxNo = 23) then // 24	120612
                  Global.CtrlSendBuffer(nTeeboxNo, '122', IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute), '0', 'S1');

                if (FTeeboxInfoList[nTeeboxNo].TeeboxNo = 47) then // 48	240612
                  Global.CtrlSendBuffer(nTeeboxNo, '242', IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute), '0', 'S1');
              end;
            end;
          end;
        end
        else
        begin
          if Global.ADConfig.StoreCode = 'BD001' then //BD001	�׷������Ŭ�� -> ���������� ����
          begin
            if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
              FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
            else
            begin
              if FTeeboxInfoList[nTeeboxNo].DeviceUseStatus = 'D' then
                FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
              else
              begin
                //Ÿ������ ������ ���
                if (FTeeboxInfoList[nTeeboxNo].UseStatus = '0') and (FTeeboxInfoList[nTeeboxNo].DeviceUseStatus = '1') then
                begin
                  sStr := 'Ÿ������ : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                          FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                          IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
                  Global.Log.LogReserveWrite(sStr);
                end;

                FTeeboxInfoList[nTeeboxNo].UseStatus := '1';
              end;

            end;
          end
          else
          begin
            if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
              FTeeboxInfoList[nTeeboxNo].UseStatus := '0'
            else
              FTeeboxInfoList[nTeeboxNo].UseStatus := '1';
          end;
        end;

      end;

    end;

    if (FTeeboxInfoList[nTeeboxNo].UseStatus = '7') then
    begin
      if (FTeeboxInfoList[nTeeboxNo].DeviceRemainMin > 1) and (Global.ADConfig.ProtocolType <> 'MODENYJ') then //MODENYJ Ÿ������� ������
      begin
        inc(FTeeboxInfoList[nTeeboxNo].DeviceCtrlCnt);

        if FTeeboxInfoList[nTeeboxNo].DeviceCtrlCnt < 3 then
        begin
          sStr := '��ȸ�� �������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].DeviceRemainMin);
          Global.Log.LogReserveWrite(sStr);

          SetTeeboxCtrlAD(nTeeboxNo, 'S1', 0, 9999);
        end;
      end;
    end
    else
    begin
      if (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) and (FTeeboxInfoList[nTeeboxNo].DeviceRemainMin > 1) and
         (FTeeboxInfoList[nTeeboxNo].UseStatus = '0') and (Global.ADConfig.ProtocolType <> 'MODENYJ') then //MODENYJ Ÿ������� ������
      begin
        sStr := '�������� - No:' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) +
                ' / Nm:' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].DeviceRemainMin);
        Global.Log.LogReserveWrite(sStr);

        if (Global.ADConfig.StoreCode = 'B8001') or //'B8001' �������̰���Ŭ��
           (Global.ADConfig.StoreCode = 'B5001') then
        SetTeeboxCtrlAD(nTeeboxNo, 'S3' , 0, 9999)
        else
        SetTeeboxCtrlAD(nTeeboxNo, 'S1', 0, 9999);
      end;
    end;

    if (Global.ADConfig.ReserveMode = True) then //������
    begin
      if (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
         (FTeeboxInfoList[nTeeboxNo].DeviceRemainMin = 0) and
         (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') and
         (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate < formatdatetime('YYYYMMDDhhnnss', Now)) then
      begin
        sStr := '�������� ���û : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate;
        Global.Log.LogReserveWrite(sStr);

        SetTeeboxCtrlAD(nTeeboxNo, 'S0' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
      end;
    end;

    // DB����: Ÿ�������(�ð�,����,����)
    if FTeeboxInfoList[nTeeboxNo].RemainMinPre <> FTeeboxInfoList[nTeeboxNo].RemainMinute then
    begin
      Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

      //�����ð��� Ÿ�����ܿ��ð� ���� ����
      if (FTeeboxInfoList[nTeeboxNo].RemainMinute <> FTeeboxInfoList[nTeeboxNo].DeviceRemainMin) and
         (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
         (FTeeboxInfoList[nTeeboxNo].UseStatus = '1') and
         (Global.ADConfig.ProtocolType <> 'MODENYJ') then  //MODENYJ Ÿ������� ������
      begin

        //if Abs(FTeeboxInfoList[nTeeboxNo].RemainMinute - FTeeboxInfoList[nTeeboxNo].DeviceRemainMin) > 3 then
        if Abs(FTeeboxInfoList[nTeeboxNo].RemainMinute - FTeeboxInfoList[nTeeboxNo].DeviceRemainMin) > 2 then //2022-06-08
        begin
          sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].DeviceRemainMin) + ' -> ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
          Global.Log.LogReserveWrite(sStr);

          if (Global.ADConfig.ProtocolType = 'NANO') then
          begin
            if FTeeboxInfoList[nTeeboxNo].DeviceRemainMin = 0 then
            begin
              SetTeeboxCtrlAD(nTeeboxNo, 'S0' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);

              if Global.ADConfig.StoreCode <> 'BD001' then //BD001	�׷������Ŭ�� -> ���������� ����
                SetTeeboxCtrlAD(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
            end
            else
              SetTeeboxCtrlAD(nTeeboxNo, 'S2' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
          end
          else if (Global.ADConfig.ProtocolType = 'NANO2') then
          begin
            if (Global.ADConfig.StoreCode = 'B8001') or //'B8001' �������̰���Ŭ��
               (Global.ADConfig.StoreCode = 'B5001') then
            begin
              if FTeeboxInfoList[nTeeboxNo].DeviceRemainMin = 0 then
              begin
                SetTeeboxCtrlAD(nTeeboxNo, 'S0' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
                SetTeeboxCtrlAD(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
              end
              else
                SetTeeboxCtrlAD(nTeeboxNo, 'S2' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
            end
            else
              SetTeeboxCtrlAD(nTeeboxNo, 'S2' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
          end
          else if (Global.ADConfig.ProtocolType = 'JEHU435') then
          begin
            if (Global.ADConfig.StoreCode = 'A9001') or (Global.ADConfig.StoreCode = 'D2001') then //��������, ����
            begin
              FTeeboxInfoList[nTeeboxNo].UseReset := 'Y';
              SetTeeboxCtrlAD(nTeeboxNo, 'S1' , 0, 0000);
              sStr := '�������� : �ʱ�ȭ';
              Global.Log.LogReserveWrite(sStr);
            end;

            SetTeeboxCtrlAD(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
          end
          else
            SetTeeboxCtrlAD(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999);
        end;
      end;

      if (FTeeboxInfoList[nTeeboxNo].RemainMinPre = 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute = 1) then
      begin
        sStr := '�ð�����1 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo;
        //Global.Log.LogReserveWrite(sStr);

        //�ð����� �߻��� �ð� �ʱ�ȭ
        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> '') and
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate <> '') then
        begin
          FTeeboxInfoList[nTeeboxNo].RemainMinute := 0;

          sStr := '�ð�����1  ����: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo;
        end;

        Global.Log.LogReserveWrite(sStr);
      end;

    end;

    FTeeboxInfoList[nTeeboxNo].RemainMinPre := FTeeboxInfoList[nTeeboxNo].RemainMinute;
  end;

  if bTeeboxError = True then
    Global.TcpServer.SetApiTeeBoxStatus('error', sErrorS, sErrorE);

  Sleep(10);
  FTeeboxStatusUse := False;
end;

procedure TTeebox.TeeboxReserveChkAD;
var
  nTeeboxNo: Integer;
  sCheckTime, sTime, sStr, sLog: string;
  I, nNN, nTmTemp, nTemp: Integer;
  tmTempS: TDateTime;
  tmCheckIn: TDateTime;
  nCtlSecond: Integer;
begin
  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sLog := 'SeatReserveUse TeeboxReserveChkAD!';
    Global.Log.LogReserveDelayWrite(sLog);

    sleep(50);
  end;
  FTeeboxStatusUse := True;

  sCheckTime := FormatDateTime('YYYYMMDD hh:nn:ss', Now);
  sTime := Copy(sCheckTime, 10, 5);

  //chy test �ӽ��ּ� - ��������ð� �ʰ��� AD �ð� ����� ��� ��������ð��� ����� ���� ����.
  {
  if (sTime < Global.Store.StartTime) or (sTime >= Global.Store.EndTime) then
  begin
    if Global.Store.Close = 'N' then
    begin
      Global.SetStoreInfoClose('Y');
      Global.Log.LogWrite('Store Close !!!');
    end;

    Exit;
  end;

  if Global.Store.Close = 'Y' then
  begin
    Global.SetStoreInfoClose('N');
    Global.Log.LogWrite('Store Open !!!');
  end;
  }

  for nTeeboxNo := 1 to TeeboxLastNo do
  begin

    if (global.Store.UseRewardYn = 'Y') or // ����������-�̿�ð� ���� '��'�ΰ��
       ((Global.Store.UseRewardYn = 'N') and (Global.Store.UseRewardException = 'Y')) then // ����������-�̿�ð� ���� '�ƴϿ�' �̰� ������ ��ȸ�� �ð��� �ƴѰ��
    begin
      if FTeeboxInfoList[nTeeboxNo].UseStatus = '7' then //��ȸ��
        continue;
    end;

    if (global.ADConfig.ErrorTimeReward = True) then //������ �ð�����
    begin
      if (FTeeboxInfoList[nTeeboxNo].UseStatus = '9') and (FTeeboxInfoList[nTeeboxNo].ErrorReward = False) and (FTeeboxInfoList[nTeeboxNo].ErrorCd <> 8) then
        continue;
    end;

    //Ÿ���� �������� Ȯ��
    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = '' then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Continue;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin = 0 then //�����ð��� 0�� ���
    begin
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

      sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / AssignMin = 0';
      Global.Log.LogReserveWrite(sStr);

      // DB/Erp����: ����ð�
      Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, '2');

      Continue;
    end;

    //���, ���� API ��û�� ���� ������
    if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') or (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') then //����ΰ�� K410_TeeBoxReserved ���� ERP ����
    begin

      if FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y' then
      begin
        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') and
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') then
        begin
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignYn := 'Y'; //��üũ�� ����۵ǵ��� üũ��ó��

          sStr := '�������� no: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo;
          Global.Log.LogReserveWrite(sStr);
        end;
      end;

      if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '' then
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        if (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') then
        begin
          // DB/Erp����: ����ð�
          Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, '2');
        end;

        //FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
        FTeeboxInfoList[nTeeboxNo].RemainMinute := 0;

        if (Global.ADConfig.StoreCode = 'B7001') and (nTeeboxNo > 52) then //������Ʈ, ������, 3���� ��������
        begin
          FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := 0;

          if Global.ADConfig.XGM_VXUse = True then
            SetTeeboxVXCtrl('VXend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, 0);
        end;

        if (Global.ADConfig.StoreCode = 'CD001') and (FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52) then //CD001	��Ÿ����Ŭ��(�ϻ�)
        begin
          FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'E';
          FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := 0;
          SetTeeboxAgentCtrl('Tend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo, 0, 0);

          SetTeeboxBeamCtrl('Bend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo);
        end;

        if (Global.ADConfig.StoreCode = 'A0003') then //	�븲��ũ�κ�
        begin
          FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'E';
          FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := 0;
          SetTeeboxAgentCtrl('Tend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo, 0, 0);
        end;

        if FTeeboxInfoList[nTeeboxNo].ControlYn = 'N' then
          FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := 0;
      end;
    end;

    //�����,�Ⱓ�� �� üũ��
    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignYn = 'N' then
    begin
      //�ð� �����ſ� ���� ���� ó�� �ʿ�
      tmCheckIn := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate) +
                   (((1/24)/60) * (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin));

      if tmCheckIn < now then
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        // DB/Erp����: ����ð�
        Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, '2');

        sStr := '��üũ�� no: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
        Global.Log.LogReserveWrite(sStr);

        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo := '';
      end;

      Continue;
    end;

    //����ũ(ZOOM, ZOOM1) - ������, �׸��ʵ�: �����ɹ̻��
    if Global.ADConfig.ReserveMode = True then
    begin
      if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') and
         (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') and
         (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate < formatdatetime('YYYYMMDDhhnnss', Now)) and
         (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) then
      begin
        FTeeboxInfoList[nTeeboxNo].RemainMinute := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;

        sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate;
        Global.Log.LogReserveWrite(sStr);

        //�������� ����迭�� ���
        SetTeeboxCtrlAD(nTeeboxNo, 'S0' , FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignBalls);
      end;
    end;

    if (Global.ADConfig.StoreCode = 'B7001') or (Global.ADConfig.StoreCode = 'CD001') then
    begin
      if (FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52) then //������, ��Ÿ����Ŭ��(�ϻ�)
      begin

        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') and
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') and
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate < formatdatetime('YYYYMMDDhhnnss', Now)) and
           (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) and
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareCtlYn = 'N') then
        begin
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareCtlYn := 'Y';

          sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate;
          Global.Log.LogReserveWrite(sStr);

          if (Global.ADConfig.XGM_VXUse = True) and (Global.ADConfig.StoreCode = 'B7001') then //���ð��� ���� �߰�
          begin
            //�������� ����迭�� ���
            SetTeeboxVXCtrl('VXstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm,
                            (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin));
          end;

          if (Global.ADConfig.StoreCode = 'CD001') then //CD001	��Ÿ����Ŭ��(�ϻ�)
          begin
            FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'D';
            nCtlSecond := SecondsBetween(now, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime);
            SetTeeboxAgentCtrl('Tprepare', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin, nCtlSecond);

            SetTeeboxBeamCtrl('Bstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo );
          end;

        end;
      end;
    end;

    if (Global.ADConfig.StoreCode = 'A0003') then //	�븲��ũ�κ�
    begin

      if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') and
         (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') and
         (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate < formatdatetime('YYYYMMDDhhnnss', Now)) and
         (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) and
         (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareCtlYn = 'N') then
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareCtlYn := 'Y';

        sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate;
        Global.Log.LogReserveWrite(sStr);

        if (Global.ADConfig.StoreCode = 'CD001') then //CD001	��Ÿ����Ŭ��(�ϻ�)
        begin
          FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'D';
          nCtlSecond := SecondsBetween(now, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime);
          SetTeeboxAgentCtrl('Tprepare', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin, nCtlSecond);
        end;
      end;

    end;

    //�����������̰� ���ð��� ��������
    if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime < Now) then
    begin
      FTeeboxInfoList[nTeeboxNo].PrepareChk := 0;

      FTeeboxInfoList[nTeeboxNo].RemainMinute := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;
      //FTeeboxInfoList[nTeeboxNo].UseStatus := '1';

      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnn00', Now); //2021-06-11

      sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
      Global.Log.LogReserveWrite(sStr);

      // DB����, 0�� ǥ�õǴ� ��� ����.
      if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '8') and (FTeeboxInfoList[nTeeboxNo].UseStatus <> '9') then //����, ����
        Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999, '1', '');

      // DB/Erp����: ���۽ð�
      Global.TcpServer.SetApiTeeBoxReg(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);

      //�������� ����迭�� ���
      if Global.ADConfig.StoreCode = 'BD001' then //BD001	�׷������Ŭ�� -> ���������� ����
        SetTeeboxCtrlAD(nTeeboxNo, 'S0' , FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignBalls)
      else if Global.ADConfig.StoreCode = 'B5001' then // ��������
      begin
        SetTeeboxCtrlAD(nTeeboxNo, 'S0' , FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignBalls);

        SetTeeboxCtrlAD(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignBalls);
        // 1ȸ���� �߰� - 2023-05-10
        SetTeeboxCtrlAD(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignBalls);
      end
      else
        SetTeeboxCtrlAD(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignBalls);

      //��ù���� ���� ��Ⱑ ���� ���
      if Global.ADConfig.XGM_VXUse = True then
      begin
        if (Global.ADConfig.StoreCode = 'B7001') and (FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52) then //������
        begin
          if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareCtlYn = 'N') then
            SetTeeboxVXCtrl('VXstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin);
        end;
      end;

      if (Global.ADConfig.StoreCode = 'CD001') and (FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52) then //CD001	��Ÿ����Ŭ��(�ϻ�)
      begin
        FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'S';
        nCtlSecond := SecondsBetween(now, IncMinute(DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate), FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin));
        SetTeeboxAgentCtrl('Tstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, nCtlSecond);

        SetTeeboxBeamCtrl('Bstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo );
      end;

      if (Global.ADConfig.StoreCode = 'A0003') then //	�븲��ũ�κ�
      begin
        FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'S';
        nCtlSecond := SecondsBetween(now, IncMinute(DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate), FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin));
        SetTeeboxAgentCtrl('Tstart', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, nCtlSecond);
      end;

    end;

    //�ð����
    if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate <> '') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'Y') then
    begin

      tmTempS := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);
      nNN := MinutesBetween(now, tmTempS);

      nTmTemp := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin - nNN;
      if nTmTemp < 0 then
        nTmTemp := 0;

      if (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) and (nTmTemp = 1) then
      begin
        sStr := '�ð����� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo;
        Global.Log.LogReserveWrite(sStr);
      end;

      FTeeboxInfoList[nTeeboxNo].RemainMinute := nTmTemp;

      if (Global.ADConfig.StoreCode = 'B7001') or //������Ʈ, ������, 3���� ��������
         (Global.ADConfig.StoreCode = 'CD001') then
      begin
        if nTeeboxNo > 52 then
          FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := nTmTemp;
      end;

      if FTeeboxInfoList[nTeeboxNo].ControlYn = 'N' then //���ڵ�
      begin
        FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := nTmTemp;
      end;

      if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '�������� : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        // DB/Erp����: ����ð�
        Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, '2');

        if Global.ADConfig.ProtocolType = 'NANO2' then
          SetTeeboxCtrlAD(nTeeboxNo, 'S2', 0, 9999)
        else
          SetTeeboxCtrlAD(nTeeboxNo, 'S1', 0, 9999);

        if Global.ADConfig.XGM_VXUse = True then
        begin
          if (Global.ADConfig.StoreCode = 'B7001') and (FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52) then //������
            SetTeeboxVXCtrl('VXend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, 0);
        end;

        if (Global.ADConfig.StoreCode = 'CD001') and (FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52) then //CD001	��Ÿ����Ŭ��(�ϻ�)
        begin
          FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'E';
          SetTeeboxAgentCtrl('Tend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo, 0, 0);

          SetTeeboxBeamCtrl('Bend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo);
        end;

        if (Global.ADConfig.StoreCode = 'A0003') then //	�븲��ũ�κ�
        begin
          FTeeboxInfoList[nTeeboxNo].AgentCtlType := 'E';
          SetTeeboxAgentCtrl('Tend', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxNo, 0, 0);
        end;

      end;

    end;

  end;

  Sleep(10);
  FTeeboxStatusUse := False;
end;

procedure TTeebox.TeeboxReserveNextChkAD;
var
  nTeeboxNo: Integer;
  sLog: String;
begin

  try

    for nTeeboxNo := 1 to TeeboxLastNo do
    begin

      if (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0)  then
        Continue;

      //������ �ְ� ���� �������̸�
      if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate <> '') and (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') then
        Continue;

      Global.ReserveList.ReserveListNextChk(nTeeboxNo);
    end;

  except
    on e: Exception do
    begin
       sLog := 'SeatReserveNextChk Exception : ' + e.Message;
       Global.Log.LogReserveWrite(sLog);
    end;
  end;

end;

procedure TTeebox.SetTeeboxInfoAD(ATeeboxInfo: TTeeboxInfo);
var
  nTeeboxNo: Integer;
  sStr: String;
begin
  nTeeboxNo := ATeeboxInfo.TeeboxNo;
  {
  if (Global.ADConfig.TimeCheckMode = '1') and (Global.ADConfig.ProtocolType = 'NANO') then
  begin
    //����, ��ȸ�� ����
    if (FTeeboxInfoList[nTeeboxNo].UseStatus = '7') and (BallBackEndCtl = False) then
      Exit;

    if FBallBackUse = True then
      Exit;
  end;
  }

  if (Global.ADConfig.StoreCode = 'A1001') or (Global.ADConfig.StoreCode = 'A9001') or (Global.ADConfig.StoreCode = 'D2001') then //��Ÿ, ��������, ����
  begin
    if FTeeboxInfoList[nTeeboxNo].UseReset = 'Y' then
    begin
      {
      sStr := 'Ÿ���� UseReset : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              IntToStr(ATeeboxInfo.RemainMinute);
      Global.Log.LogReserveWrite(sStr);
      }
      Exit;
    end;
  end;

  FTeeboxInfoList[nTeeboxNo].RemainBall := ATeeboxInfo.RemainBall;
  FTeeboxInfoList[nTeeboxNo].DeviceRemainMin := ATeeboxInfo.RemainMinute;
  FTeeboxInfoList[nTeeboxNo].DeviceUseStatus := ATeeboxInfo.UseStatus;
  //FTeeboxInfoList[nTeeboxNo].ErrorCd := ATeeboxInfo.ErrorCd;
  FTeeboxInfoList[nTeeboxNo].DeviceErrorCd := ATeeboxInfo.ErrorCd;
  FTeeboxInfoList[nTeeboxNo].DeviceErrorCd2 := ATeeboxInfo.ErrorCd2;
  FTeeboxInfoList[nTeeboxNo].ComReceive := 'Y';
end;

procedure TTeebox.SetTeeboxErrorCntAD(AIndex, ATeeboxNo: Integer; AError: String; AMaxCnt: Integer);
var
  sLogMsg: String;
begin
  if (FTeeboxInfoList[ATeeboxNo].UseStatus = '7') or (FTeeboxInfoList[ATeeboxNo].UseStatus = '8') then
  begin
    //sLogMsg := 'UseStatus = ' + FTeeboxInfoList[ATeeboxNo].UseStatus + ' : ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
    //Global.Log.LogRetryWrite(sLogMsg);
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
        sLogMsg := 'ErrorCnt : ' + IntToStr(AMaxCnt) + ' / No:' + IntToStr(ATeeboxNo) + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
        Global.Log.LogReadMulti(AIndex, sLogMsg);
      end;

      FTeeboxInfoList[ATeeboxNo].ErrorYn := 'Y';
      FTeeboxInfoList[ATeeboxNo].DeviceUseStatus := '9';
      //FTeeboxInfoList[ATeeboxNo].ErrorCd := 8; //����̻�
      FTeeboxInfoList[ATeeboxNo].DeviceErrorCd := 8; //����̻�
      FTeeboxInfoList[ATeeboxNo].DeviceErrorCd2 := '8'; //����̻�
    end;
  end
  else
  begin
    FTeeboxInfoList[ATeeboxNo].ErrorCnt := 0;
    FTeeboxInfoList[ATeeboxNo].ErrorYn := 'N';
  end;
end;

procedure TTeebox.SetTeeboxCtrlAD(ATeeboxNo: Integer; AType: String; ATime: Integer; ABall: Integer);
var
  sSendData: AnsiString;
  sTeeboxTime, sTeeboxBall, sDeviceId: AnsiString;
  sStr: String;
  bCtrlExcept: Boolean;
begin

  if FTeeboxInfoList[ATeeboxNo].ControlYn = 'N' then //���ڵ�
    Exit;

  if (Global.ADConfig.StoreCode = 'CD001') then //CD001	��Ÿ����Ŭ��(�ϻ�)
  begin
    if ATeeboxNo > 52 then
      Exit;
  end;

  //if (FTeeboxInfoList[ATeeboxNo].UseStatus = '7') or   //��ȸ��
  if (FTeeboxInfoList[ATeeboxNo].UseStatus = '8') or   //����
     (FTeeboxInfoList[ATeeboxNo].UseStatus = '9') then //����
  begin
    bCtrlExcept := True;

    if (Global.ADConfig.StoreCode = 'B8001') and (FTeeboxInfoList[ATeeboxNo].UseStatus = '9') and (FTeeboxInfoList[ATeeboxNo].ErrorCd <> 8) then //��������
      bCtrlExcept := False;

    if bCtrlExcept = True then
    begin
      sStr := '�������� : no ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
            FTeeboxInfoList[ATeeboxNo].UseStatus;
      Global.Log.LogReserveWrite(sStr);

      FTeeboxInfoList[ATeeboxNo].UseReset := 'N';

      Exit;
    end;
  end;

  sTeeboxTime := IntToStr(ATime);
  sTeeboxBall := IntToStr(ABall);

  if (Global.ADConfig.StoreCode = 'A8001') or //�����
     (Global.ADConfig.StoreCode = 'B7001') or // ������
     (Global.ADConfig.StoreCode = 'B8001') or // �������̰���Ŭ��
     (Global.ADConfig.StoreCode = 'BB001') or //������
     (Global.ADConfig.StoreCode = 'A8003') or //�����-������
     (Global.ADConfig.StoreCode = 'C0001') then //����������
  begin
    Global.CtrlSendBuffer(ATeeboxNo, FTeeboxInfoList[ATeeboxNo].DeviceId, sTeeboxTime, sTeeboxBall, AType);

    //181	V8	3
    if (Global.ADConfig.StoreCode = 'A8001') then //�����
    begin //8���� vip, �¿���
      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 179) then //vvip10
        Global.CtrlSendBuffer(ATeeboxNo, '61', sTeeboxTime, sTeeboxBall, AType);

      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 181) then // V8 -> vvip11
        Global.CtrlSendBuffer(ATeeboxNo, '64', sTeeboxTime, sTeeboxBall, AType);
    end;

    if (Global.ADConfig.StoreCode = 'B7001') then // ������
    begin
      if (FTeeboxInfoList[ATeeboxNo].TeeboxNm = '26') then // 26	204013	��,	204014	��
        Global.CtrlSendBuffer(ATeeboxNo, '142', sTeeboxTime, sTeeboxBall, AType);

      if (FTeeboxInfoList[ATeeboxNo].TeeboxNm = '50') then // 50	205012	��,	205003	��
        Global.CtrlSendBuffer(ATeeboxNo, '272', sTeeboxTime, sTeeboxBall, AType);

      if (FTeeboxInfoList[ATeeboxNo].TeeboxNm = '51') then // 51	205005	��,	205002	��
        Global.CtrlSendBuffer(ATeeboxNo, '282', sTeeboxTime, sTeeboxBall, AType);
    end;

    if (Global.ADConfig.StoreCode = 'B8001') then // �������̰���Ŭ��
    begin
      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 23) then // 24������(120612) -> 23�� ����(120613)
        Global.CtrlSendBuffer(ATeeboxNo, '123', sTeeboxTime, sTeeboxBall, AType);

      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 47) then // 48������(240612) -> 47�� ����(240613)
        Global.CtrlSendBuffer(ATeeboxNo, '243', sTeeboxTime, sTeeboxBall, AType);
    end;

    if (Global.ADConfig.StoreCode = 'BB001') then //������
    begin
      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 1) then
        Global.CtrlSendBuffer(ATeeboxNo, 'R', sTeeboxTime, sTeeboxBall, AType);

      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 21) then
        Global.CtrlSendBuffer(ATeeboxNo, 'T', sTeeboxTime, sTeeboxBall, AType);

      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 41) then
        Global.CtrlSendBuffer(ATeeboxNo, 'T', sTeeboxTime, sTeeboxBall, AType);
    end;

    if (Global.ADConfig.StoreCode = 'A8003') then //�����-������
    begin
      if (FTeeboxInfoList[ATeeboxNo].TeeboxNm = '44') then
        Global.CtrlSendBuffer(ATeeboxNo, '242', sTeeboxTime, sTeeboxBall, AType);
    end;

    if (Global.ADConfig.StoreCode = 'C0001') then //����������
    begin
      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 25) then //25/26
        Global.CtrlSendBuffer(ATeeboxNo, 'A', sTeeboxTime, sTeeboxBall, AType); //26

      if (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 50) then //51/52
        Global.CtrlSendBuffer(ATeeboxNo, 'B', sTeeboxTime, sTeeboxBall, AType); //52
    end;

  end
  else
  begin
    if ((FTeeboxInfoList[ATeeboxNo].TeeboxZoneCode = 'L') or (FTeeboxInfoList[ATeeboxNo].TeeboxZoneCode = 'C')) and
       (Length(FTeeboxInfoList[ATeeboxNo].DeviceId) > Global.ADConfig.DeviceCnt) then
    begin
      sDeviceId := copy(FTeeboxInfoList[ATeeboxNo].DeviceId, 1, Global.ADConfig.DeviceCnt);
      Global.CtrlSendBuffer(ATeeboxNo, sDeviceId, sTeeboxTime, sTeeboxBall, AType);

      sDeviceId := copy(FTeeboxInfoList[ATeeboxNo].DeviceId, (1 + Global.ADConfig.DeviceCnt), Global.ADConfig.DeviceCnt);
      Global.CtrlSendBuffer(ATeeboxNo, sDeviceId, sTeeboxTime, sTeeboxBall, AType);
    end
    else
    begin
      sDeviceId := FTeeboxInfoList[ATeeboxNo].DeviceId;
      Global.CtrlSendBuffer(ATeeboxNo, sDeviceId, sTeeboxTime, sTeeboxBall, AType);
    end;
  end;

end;

procedure TTeebox.SetTeeboxVXCtrl(AType: String; AReserveNo, ATeeboxNm: String; AMin: Integer);
var
  sLogMsg, sUrl: String;
  sSendStr: AnsiString;
begin
  if Global.ADConfig.XGM_VXUse = False then
    Exit;

  // '/room/status' : ����  {  "roomNum": 24 // ������}
  // '/room/start'  : ����  {  "roomNum": 23,  "mtime": 60 }
  // '/room/stop'   : ����  {  "roomNum": 23 }
  // '/room/add'    : �߰�  {  "roomNum": 23,  "mtime": 60 }

  sUrl := 'http://localhost:8000';
  if (AType = 'VXstart') then
  begin
    sUrl := sUrl + '/room/start';
    sSendStr := '{"roomNum":' + ATeeboxNm + ',' +
                ' "mtime":' + IntToStr(AMin) + '}';
  end;

  if (AType = 'VXadd') then
  begin
    sUrl := sUrl + '/room/add';
    sSendStr := '{"roomNum":' + ATeeboxNm + ',' +
                ' "mtime":' + IntToStr(AMin) + '}';
  end;

  if AType = 'VXend' then
  begin
    sUrl := sUrl + '/room/stop';
    sSendStr := '{"roomNum":' + ATeeboxNm + '}';
  end;

  sLogMsg := AType + ATeeboxNm + ' / ' + AReserveNo + ' / ' + sUrl + ' / ' + sSendStr;
  Global.Log.LogXGMCtrlWrite('send : ' + sLogMsg);

  sLogMsg := Global.Api.PostVXApi(sUrl, sSendStr);
  Global.Log.LogXGMCtrlWrite('rece : ' + sLogMsg);

end;

procedure TTeebox.SetTeeboxBeamCtrl(AType: String; AReserveNo: String; ATeeboxNo: Integer);
var
  sLogMsg: String;
  bResult: Boolean;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  if FTeeboxInfoList[ATeeboxNo].BeamIP = EmptyStr then
  begin
    sLogMsg := 'Beam IP null';
    Global.Log.LogBeamCtrlWrite(sLogMsg);
    Exit;
  end;

  sLogMsg := AType + ' - No:' + IntToStr(ATeeboxNo) +  ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' + AReserveNo + ' / ' + FTeeboxInfoList[ATeeboxNo].BeamIP;
  Global.Log.LogBeamCtrlWrite(sLogMsg);

  if (AType = 'Bstart') then
  begin
    if FTeeboxInfoList[ATeeboxNo].BeamType = '0' then
    begin
      bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[ATeeboxNo].BeamIP, FTeeboxInfoList[ATeeboxNo].BeamPW, 1);
      if bResult = False then
      begin
        //��ſ���� disconnect �Ǵ� ��� ����
        sleep(100);
        bResult := Global.Api.PostBeamPJLinkApi(FTeeboxInfoList[ATeeboxNo].BeamIP, FTeeboxInfoList[ATeeboxNo].BeamPW, 1);
      end;
    end
    else if FTeeboxInfoList[ATeeboxNo].BeamType = '1' then
    begin
      Global.Api.PostBeamHitachiApi(FTeeboxInfoList[ATeeboxNo].BeamIP, 1);
    end;

    FTeeboxInfoList[ATeeboxNo].BeamEndDT := '';
    FTeeboxInfoList[ATeeboxNo].BeamStartDT := formatdatetime('YYYYMMDDhhnnss', Now);
    FTeeboxInfoList[ATeeboxNo].BeamSReCtl1 := False;
    FTeeboxInfoList[ATeeboxNo].BeamSReCtl2 := False;
  end
  else if AType = 'Bend' then
  begin
    FTeeboxInfoList[ATeeboxNo].BeamEndDT := formatdatetime('YYYYMMDDhhnnss', Now);
    FTeeboxInfoList[ATeeboxNo].BeamEReCtl1 := False;
    FTeeboxInfoList[ATeeboxNo].BeamEReCtl2 := False;
    FTeeboxInfoList[ATeeboxNo].BeamEReCtl3 := False;
  end;

end;

procedure TTeebox.SendBeamEnd;
var
  sLogMsg: String;
  i, nSS: Integer;
  bResult: Boolean;
  tmTemp: TDateTime;
  bCtl: Boolean;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  //if (Global.ADConfig.StoreCode = 'CD001') and (FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52) then //CD001	��Ÿ����Ŭ��(�ϻ�)
  for i := 53 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[i].UseYn <> 'Y' then
      Continue;

    if FTeeboxInfoList[i].RemainMinute > 0 then
      Continue;

    if FTeeboxInfoList[i].BeamEndDT = EmptyStr then
      Continue;

    if FTeeboxInfoList[i].BeamIP = EmptyStr then
      Continue;

    if FTeeboxInfoList[i].BeamEReCtl3 = True then
      Continue;

    tmTemp := DateStrToDateTime3(FTeeboxInfoList[i].BeamEndDT);
    nSS := SecondsBetween(now, tmTemp);
    bCtl := False;

    if (FTeeboxInfoList[i].BeamEReCtl1 = False) then
    begin
      if (nSS > 300) then
        bCtl := True
      else
        Continue;
    end
    else
    begin
      if (FTeeboxInfoList[i].BeamEReCtl2 = False) then
      begin
        if (nSS > 320) then
          bCtl := True
        else
          Continue;
      end
      else
      begin
        if (FTeeboxInfoList[i].BeamEReCtl3 = False) then
        begin
          if (nSS > 340) then
            bCtl := True
          else
            Continue;
        end;
      end;
    end;

    if bCtl = True then
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

      if FTeeboxInfoList[i].BeamEReCtl1 = False then
      begin
        FTeeboxInfoList[i].BeamEReCtl1 := True;
        sLogMsg := 'Bend 5min / Nm:' + FTeeboxInfoList[i].TeeboxNm;
      end
      else
      begin
        if FTeeboxInfoList[i].BeamEReCtl2 = False then
        begin
          FTeeboxInfoList[i].BeamEReCtl2 := True;
          sLogMsg := 'Bend 20Second / Nm:' + FTeeboxInfoList[i].TeeboxNm;
        end
        else
        begin
          FTeeboxInfoList[i].BeamEReCtl3 := True;
          sLogMsg := 'Bend 40Second / Nm:' + FTeeboxInfoList[i].TeeboxNm;
        end;
      end;

      Global.Log.LogBeamCtrlWrite(sLogMsg);
    end;

  end;

end;

procedure TTeebox.SendBeamStartReCtl;
var
  sLogMsg: String;
  i, nSS: Integer;
  bResult: Boolean;
  tmTemp: TDateTime;
  bCtl: Boolean;
begin
  if Global.ADConfig.BeamProjectorUse = False then
    Exit;

  //if (Global.ADConfig.StoreCode = 'CD001') and (FTeeboxInfoList[nTeeboxNo].TeeboxNo > 52) then //CD001	��Ÿ����Ŭ��(�ϻ�)
  for i := 53 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[i].UseYn <> 'Y' then
      Continue;

    if FTeeboxInfoList[i].BeamIP = EmptyStr then
      Continue;

    if FTeeboxInfoList[i].BeamStartDT = EmptyStr then
      Continue;

    if FTeeboxInfoList[i].BeamSReCtl2 = True then
      Continue;

    tmTemp := DateStrToDateTime3(FTeeboxInfoList[i].BeamStartDT);
    nSS := SecondsBetween(now, tmTemp);
    bCtl := False;

    if (FTeeboxInfoList[i].BeamSReCtl1 = False) then
    begin
      if (nSS > 20) then
        bCtl := True
      else
        Continue;
    end
    else
    begin
      if (FTeeboxInfoList[i].BeamSReCtl2 = False) then
      begin
        if (nSS > 40) then
          bCtl := True
        else
          Continue;
      end;
    end;

    if bCtl = True then
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

      if FTeeboxInfoList[i].BeamSReCtl1 = False then
      begin
        FTeeboxInfoList[i].BeamSReCtl1 := True;
        sLogMsg := 'Bstart rectl 20Second / Nm:' + FTeeboxInfoList[i].TeeboxNm;
      end
      else
      begin
        FTeeboxInfoList[i].BeamSReCtl2 := True;
        sLogMsg := 'Bstart rectl 40Second / Nm:' + FTeeboxInfoList[i].TeeboxNm;
      end;

      Global.Log.LogBeamCtrlWrite(sLogMsg);
    end;

  end;

end;

procedure TTeebox.SetTeeboxInfoUseReset(ATeeboxNo: Integer);
begin
  FTeeboxInfoList[ATeeboxNo].UseReset := 'N';
end;

function TTeebox.SetSendApiErrorAdd(AReserveNo, AApi, AStr: String): Boolean;
var
  Data: TSendApiErrorData;
begin
  Data := TSendApiErrorData.Create;
  Data.Api := AApi;
  Data.Json := AStr;

  FSendApiErrorList.AddObject(AReserveNo, TObject(Data));
end;

procedure TTeebox.SendApiErrorRetry;
var
  sResult, sApi, sJson, sLog: String;
begin
  // ����, ����,����, �̵� erp ��Ͻ� ���� �߻����� ���� ��õ�, ���۵� ������ üũ�� �߰�
  if FSendApiErrorList.Count = 0 then
    Exit;

  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sLog := 'SeatReserveUse SendApiErrorRetry!';
    Global.Log.LogReserveDelayWrite(sLog);

    sleep(50);
  end;
  FTeeboxStatusUse := True;

  sApi := TSendApiErrorData(FSendApiErrorList.Objects[0]).Api;
  sJson := TSendApiErrorData(FSendApiErrorList.Objects[0]).Json;

  TSendApiErrorData(FSendApiErrorList.Objects[0]).Free;
  FSendApiErrorList.Objects[0] := nil;
  FSendApiErrorList.Delete(0);

  try
    sLog := 'SendApiErrorRetry : ' + sApi + ' / ' + sJson;
    Global.Log.LogErpApiWrite(sLog);

    sResult := Global.Api.SetErpApiNoneData(sJson, sApi, Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

    sLog := 'SendApiErrorRetry Result : ' + sResult;
    Global.Log.LogErpApiWrite(sLog);
    FTeeboxStatusUse := False;
  except
    on e: Exception do
    begin
      sLog := 'SendApiErrorRetry Exception : ' + sJson + ' / ' + e.Message;
      Global.Log.LogErpApiWrite(sLog);
      FTeeboxStatusUse := False;
    end;
  end

end;

procedure TTeebox.SetTeeboxAgentCtrl(AType: String; AReserveNo: String; ATeeboxNo, AMin, ASecond: Integer);
var
  sResult: String;
  sSendStr: AnsiString;
begin

  if (FTeeboxInfoList[ATeeboxNo].AgentIP_R = '') and (FTeeboxInfoList[ATeeboxNo].AgentIP_L = '') then
  begin
    Global.Log.LogAgentCtrlWrite('error : Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / Nm: ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm);
    Exit;
  end;

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
  end
  else if (AType = 'Tstart') then //����
  begin
    sSendStr := '{"api_id":9002,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "assign_min":"' + IntToStr(AMin) + '",' +
                ' "assign_second":' + IntToStr(ASecond) + '}';
  end
  else if (AType = 'Tchange') then //����
  begin
    sSendStr := '{"api_id":9006,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '",' +
                ' "assign_min":"' + IntToStr(AMin) + '",' +
                ' "assign_second":' + IntToStr(ASecond) + '}';
  end
  else if AType = 'Tend' then //����
  begin
    sSendStr := '{"api_id":9003,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "reserve_no":"' + AReserveNo + '"}';
  end
  else if AType = 'Tsetting' then //����
  begin
    sSendStr := '{"api_id":9005,' +
                ' "teebox_no":' + IntToStr(ATeeboxNo) + ',' +
                ' "method":' + IntToStr(AMin) + '}';
  end;

  SendAgent(ATeeboxNo, sSendStr);
end;

function TTeebox.SendAgentReserveStatus(ATeeboxNo: String): Boolean;
var
  sStatus, sMin, sSecond: String;
  nTeeboxNo, nSecond, nMin: integer;
  sSendData: AnsiString;
  sLogMsg: String;
begin
  Result := False;

  if Trim(ATeeboxNo) = EmptyStr then
  begin
    //sResult := '{"result_cd":"AD03","result_msg":"Api Fail"}';
    Exit;
  end;

  nTeeboxNo := StrToInt(ATeeboxNo);

  if (FTeeboxInfoList[nTeeboxNo].AgentIP_R = '') and (FTeeboxInfoList[nTeeboxNo].AgentIP_L = '') then
  begin
    Global.Log.LogAgentCtrlWrite('error : Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / Nm: ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm);
    Exit;
  end;

  //0: ���޻���, 1: �غ�, 2:�����
  sStatus := '0';
  sMin := '0';
  sSecond := '0';

  if FTeeboxInfoList[nTeeboxNo].AgentCtlType = 'D' then
  begin
    sStatus := '1';
    nSecond := SecondsBetween(now, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime);
    sSecond := IntToStr(nSecond);

    if (nSecond mod 60) > 0 then
      nMin := (nSecond div 60) + 1
    else
      nMin := (nSecond div 60);

    sMin := IntToStr(nMin);
  end
  else if FTeeboxInfoList[nTeeboxNo].RemainMinute > 0 then
  begin
    sStatus := '2';
    sMin := IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
    nSecond := SecondsBetween(now, IncMinute(DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate), FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin));
    sSecond := IntToStr(nSecond);
  end;

  sSendData := '{' +
               '"api_id": 9004,' +
               '"teebox_no": ' + ATeeboxNo + ',' +
               '"reserve_no": "' + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + '",' +
               '"teebox_status": ' + sStatus + ',' +
               '"remain_min": ' + sMin + ',' +
               '"remain_second": ' + sSecond + ',' +
               '"result_cd": "0000",' +
               '"result_msg": "���������� ó�� �Ǿ����ϴ�."' +
               '}';

  SendAgent(nTeeboxNo, sSendData);

  Result := True;
end;

function TTeebox.SendAgentSetting(ATeeboxNo, AMethod: String): Boolean;
var
  nTeeboxNo: integer;
  sSendData: AnsiString;
  i: Integer;
  sLogMsg: String;
begin
  Result := False;

  if Trim(ATeeboxNo) = EmptyStr then
    Exit;

  if ATeeboxNo = '0' then
  begin
    for i := 53 to TeeboxLastNo do
    begin
      if FTeeboxInfoList[i].UseYn <> 'Y' then
        Continue;

      if (FTeeboxInfoList[i].AgentIP_R = '') and (FTeeboxInfoList[i].AgentIP_L = '') then
      begin
        Global.Log.LogAgentCtrlWrite('error : Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[i].TeeboxNo) + ' / Nm: ' + FTeeboxInfoList[i].TeeboxNm);
        Continue;
      end;

      sSendData := '{"api_id":9005,' +
                   ' "teebox_no":' + IntTostr(FTeeboxInfoList[i].TeeboxNo) + ',' +
                   ' "method":' + AMethod + '}';

      SendAgent(i, sSendData);
    end;
  end
  else
  begin
    nTeeboxNo := StrToInt(ATeeboxNo);

    if (FTeeboxInfoList[nTeeboxNo].AgentIP_R = '') and (FTeeboxInfoList[nTeeboxNo].AgentIP_L = '') then
    begin
      Global.Log.LogAgentCtrlWrite('error : Agent IP NULL - No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / Nm: ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm);
      Exit;
    end;

    sSendData := '{"api_id":9005,' +
                   ' "teebox_no":' + ATeeboxNo + ',' +
                   ' "method":' + AMethod + '}';

    SendAgent(nTeeboxNo, sSendData);
  end;

  Result := True;
end;

function TTeebox.SendAgent(ATeeboxNo: Integer; ASendData: String): Boolean;
var
  sResult: String;
begin
  Global.Log.LogAgentCtrlWrite('send : ' + ASendData);

  if FTeeboxInfoList[ATeeboxNo].AgentIP_R <> '' then
  begin
    sResult := Global.Api.SendAgentApi(FTeeboxInfoList[ATeeboxNo].AgentIP_R, ASendData);
    Global.Log.LogAgentCtrlWrite('rece : R- ' + FTeeboxInfoList[ATeeboxNo].AgentIP_R + ' : ' + sResult);
  end;

  if FTeeboxInfoList[ATeeboxNo].AgentIP_L <> '' then
  begin
    sResult := Global.Api.SendAgentApi(FTeeboxInfoList[ATeeboxNo].AgentIP_L, ASendData);
    Global.Log.LogAgentCtrlWrite('rece : L- ' + FTeeboxInfoList[ATeeboxNo].AgentIP_L + ' : ' + sResult);
  end;

end;

procedure TTeebox.SetAgentCtlYN(AIP, ARecive: String);
var
  nTeeboxNo: integer;
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
      Global.Log.LogAgentServerRead('Fail: ' + ARecive);
      Exit;
    end;

    nTeeboxNo := StrToInt(sTeeboxNo);

    //9001 �غ� 'prepare'
    //9002 ���� 'start', 'change'
    //9003 ���� 'end'

    if sLeftHanded = '0' then //��
    begin
      if FTeeboxInfoList[nTeeboxNo].AgentIP_R <> AIP then
      begin
        sStr := 'IP ����(��) - No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / Nm: ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' + FTeeboxInfoList[nTeeboxNo].AgentIP_R + ' -> ' + AIP;
        Global.Log.LogAgentServerRead(sStr);

        FTeeboxInfoList[nTeeboxNo].AgentIP_R := AIP;
        Global.WriteConfigAgentIP_R(FTeeboxInfoList[nTeeboxNo].TeeboxNo, FTeeboxInfoList[nTeeboxNo].AgentIP_R);
      end;
    end
    else
    begin
      if FTeeboxInfoList[nTeeboxNo].AgentIP_L <> AIP then
      begin
        sStr := 'IP ����(��) - No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / Nm: ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm  + ' / ' + FTeeboxInfoList[nTeeboxNo].AgentIP_L + ' -> ' + AIP;
        Global.Log.LogAgentServerRead(sStr);

        FTeeboxInfoList[nTeeboxNo].AgentIP_L := AIP;
        Global.WriteConfigAgentIP_L(FTeeboxInfoList[nTeeboxNo].TeeboxNo, FTeeboxInfoList[nTeeboxNo].AgentIP_L);
      end;
    end;

  finally
    FreeAndNil(jObj);
  end;
end;

procedure TTeebox.SendAgentWOL(ATeeboxNo: Integer);
var
  i: Integer;
begin

  if ATeeboxNo = 0 then
  begin
    for i := 53 to TeeboxLastNo do
    begin
      if FTeeboxInfoList[i].UseYn <> 'Y' then
        Continue;

      if (FTeeboxInfoList[i].AgentMAC_R = '') and (FTeeboxInfoList[i].AgentMAC_L = '') then
      begin
        Global.Log.LogAgentCtrlWrite('error : Agent MAC NULL - No: ' + IntToStr(FTeeboxInfoList[i].TeeboxNo) + ' / Nm: ' + FTeeboxInfoList[i].TeeboxNm);
        Continue;
      end;

      SendAgentWOLCtl(i);
    end;
  end
  else
  begin
    if FTeeboxInfoList[ATeeboxNo].UseYn <> 'Y' then
      Exit;

    if (FTeeboxInfoList[ATeeboxNo].AgentMAC_R = '') and (FTeeboxInfoList[ATeeboxNo].AgentMAC_L = '') then
    begin
      Global.Log.LogAgentCtrlWrite('error : Agent MAC NULL - No: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / Nm: ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm);
      Exit;
    end;

    SendAgentWOLCtl(ATeeboxNo);
  end;

end;

procedure TTeebox.SendAgentWOLCtl(ATeeboxNo: Integer);
var
  sLogMsg: String;
begin

  if FTeeboxInfoList[ATeeboxNo].AgentMAC_R <> '' then
  begin
    sLogMsg := Global.Api.WakeOnLan(FTeeboxInfoList[ATeeboxNo].AgentMAC_R);
    Global.Log.LogAgentCtrlWrite('recv : MAC_R - No:' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' + FTeeboxInfoList[ATeeboxNo].AgentMAC_R + ' / ' + sLogMsg);
    Sleep(100);
  end;

  if FTeeboxInfoList[ATeeboxNo].AgentMAC_L <> '' then
  begin
    sLogMsg := Global.Api.WakeOnLan(FTeeboxInfoList[ATeeboxNo].AgentMAC_L);
    Global.Log.LogAgentCtrlWrite('recv : MAC_L - No:' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / Nm:' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' + FTeeboxInfoList[ATeeboxNo].AgentMAC_L + ' / ' + sLogMsg);
    Sleep(100);
  end;

end;

end.
