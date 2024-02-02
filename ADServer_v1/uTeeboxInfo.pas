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
    FTeeboxDevicNoTempZoom: array of String;
    FTeeboxDevicNoTempJehu435: array of String;

    FTeeboxDevicNoList: array of String;
    FTeeboxDevicNoCnt: Integer;
    FTeeboxInfoList: array of TTeeboxInfo;
    FTeeboxReserveList: array of TTeeboxReserveList;

    FTeeboxLastNo: Integer;
    //FTeeboxError: Boolean;
    FBallBackEnd: Boolean; //볼회수종료
    FBallBackEndCtl: Boolean; //볼회수종료 재배정명령여부

    FBallBackUse: Boolean; //볼회수여부, 볼회수시 키오스크에서 홀드, 배정 막기위해
    FTeeboxStatusUse: Boolean;
    FTeeboxReserveUse: Boolean;

    FSendApiErrorList: TStringList;

    procedure TeeboxDevicNoTempSetting;
  public
    constructor Create;
    destructor Destroy; override;

    procedure StartUp;

    function GetTeeboxListToApi: Boolean;
    function GetTeeboxListToDB: Boolean; //긴급배정용
    function SetTeeboxStartUseStatus: Boolean; //최초실행시

    //Teebox Thread
    procedure TeeboxStatusChk;
    procedure TeeboxStatusChkJMS;
    procedure TeeboxReserveChk;
    procedure TeeboxReserveChkJMS;

    //20201-12-16 빅토리아 반자동타석-제어없이 시스템상에서 시간계산
    procedure TeeboxStatusChkVictoria;
    procedure TeeboxReserveChkVictoria;

    procedure TeeboxReserveNextChk;
    //Teebox Thread

    procedure SetTeeboxInfo(ATeeboxInfo: TTeeboxInfo);
    procedure SetTeeboxInfoUseReset(ATeeboxNo: Integer);
    procedure SetTeeboxInfoJMS(ATeeboxInfo: TTeeboxInfo);

    //procedure SetTeeboxStartTime(ATeeboxNo: Integer; AStartTm: String);
    //procedure SetTeeboxReserveTime(ATeeboxNo: Integer; AStartTm: String);
    //procedure SetTeeboxReserveNo(ATeeboxNo: Integer; AReserveNo: String);

    procedure SetTeeboxDelay(ATeeboxNo: Integer; AType: Integer);

    procedure SetStoreClose;
    procedure SetTeeboxCtrl(ATeeboxNo: Integer; AType: String; ATime: Integer; ABall: Integer);
    procedure SetTeeboxCtrlRemainMin(ATeeboxNo: Integer; ATime: Integer); // MODENYJ 조광, 타석점검제어 용
    procedure SetTeeboxCtrlRemainMinFree(ATeeboxNo: Integer); // MODENYJ 조광, 타석점검제어 해제 용
    procedure SetTeeboxBallBackReply; //볼회수 종료후 한번더 배정위해

    procedure SetTeeboxErrorCnt(ATeeboxNo: Integer; AError: String; AMaxCnt: Integer);
    procedure SetTeeboxErrorCntModen(AIndex: Integer; ATeeboxNo: Integer; AError: String);

    procedure SendApiErrorRetry;

    function TeeboxDeviceCheck(ATeeboxNo: Integer; AType: String): Boolean;
    function TeeboxBallRecallStart: Boolean;
    function TeeboxBallRecallEnd: Boolean;

    //chy 2020-10-30 볼회수전 볼회수중인지 확인
    function TeeboxBallRecallStartCheck: Boolean;

    function GetDevicToTeeboxNo(ADev: String): Integer;
    function GetDevicToFloorTeeboxNo(AFloor, ADev: String): Integer;
    function GetDevicToFloorTeeboxNoModen(AFloor, ADev: String): Integer;
    function GetDevicToTeeboxNm(ADev: String): String;
    function GetTeeboxNoToDevic(ATeeboxNo: Integer): String;
    function GetTeeboxDevicdNoToDevic(AIndex: Integer): String; //장치ID 배열(좌우겸용으로 인해 별도 관리)
    function GetTeeboxInfo(ATeeboxNo: Integer): TTeeboxInfo;
    function GetNmToTeeboxInfo(ATeeboxNm: String): TTeeboxInfo;
    function GetTeeboxInfoA(AChannelCd: String): TTeeboxInfo;
    function GetTeeboxInfoUseYn(ATeeboxNo: Integer): String;
    function GetTeeboxStatusList: AnsiString;
    function GetTeeboxFloorNm(ATeeboxNo: Integer): String;

    function SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
    function GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;

    //예약목록에 등록
    function SetTeeboxReserveNext(AReserve: TSeatUseReserve): Boolean;
    function SetTeeboxReserveNextCancel(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveNextChange(ATeeboxNo: Integer; ASeatUseInfo: TSeatUseInfo): Boolean;
    function GetTeeboxReserveNextListCnt(ATeeboxNo: Integer): String;
    function SetTeeboxReserveNextCutInCheck(ASeatReserveInfo: TSeatUseReserve): String; //끼어넣기 가능여부 체크
    function SetTeeboxReserveNextCutIn(ASeatReserveInfo: TSeatUseReserve): Boolean; //끼어넣기
    function SetTeeboxReserveNextCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean; //체크인

    function CheckSeatReserve(ATeeboxInfo: TTeeboxInfo): Boolean;
    function SetTeeboxReserveInfo(ASeatReserveInfo: TSeatUseReserve): String;
    function SetTeeboxReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
    function SetTeeboxReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveClose(ATeeboxNo: Integer; AReserveNo: String): Boolean;
    function SetTeeboxReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String; //즉시배정
    function SetTeeboxReserveCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean; //체크인

    function ResetTeeboxRemainMinAdd(ATeeboxNo, ADelayTm: Integer; ATeeboxNm: String): Boolean;

    //2020-08-26 v26 기기고장 시간보상
    function ResetTeeboxRemainMinAddJMS(ATeeboxNo, ADelayTm: Integer): Boolean;
    function ResetTeeboxReserveMinAddJMS(ATeeboxNo, ADelayTm: Integer): Boolean;

    //예약시간 확인
    function GetTeeboxReserveLastTime(ATeeboxNo: String): String; //2020-05-31 예약시간 검증
    function GetTeeboxNowReserveLastTime(ATeeboxNo: String): String; //2021-04-19 현시간 배정 예약시간 검증

    //2020-06-09 잔여시간에 따른 예약시간 변경- 보류
    function ReSetTeeboxReserveDate(ATeeboxNo, ARemainMin: Integer): Boolean;
    //2020-06-29 시작시간기준 다음예약건 예약시간 변경
    function ResetReserveDateTime(ATeeboxNo: Integer; ATeeboxNm: String): Boolean;

    //메인 데이터 확인용
    function GetTeeboxReserveNextView(ATeeboxNo: Integer): String;
    //function SetTeeboxReservePrepare(ATeeboxNo: Integer): String;

    procedure SendADStatusToErp;

    function TeeboxClear: Boolean;

    //function ReSetTeeboxNextReserveData(ATeebox, AIndex, AReserveNo, AreserveDate: String): Boolean;

    function SetSendApiErrorAdd(AReserveNo, AApi, AStr: String): Boolean;

    property TeeboxLastNo: Integer read FTeeboxLastNo write FTeeboxLastNo;
    property TeeboxDevicNoCnt: Integer read FTeeboxDevicNoCnt write FTeeboxDevicNoCnt;
    //property TeeboxError: Boolean read FTeeboxError write FTeeboxError;
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
  TeeboxDevicNoTempSetting;
  TeeboxLastNo := 0;
  FTeeboxDevicNoCnt := 0;
  FBallBackEnd := False;
  FBallBackEndCtl := False;

  FTeeboxStatusUse := False;
  FTeeboxReserveUse := False;
  FBallBackUse := False;
end;

destructor TTeebox.Destroy;
begin
  TeeboxClear;

  inherited;
end;

procedure TTeebox.TeeboxDevicNoTempSetting;
begin
  FTeeboxDevicNoTempZoom := ['132131', '121', '112', '111', '102', '101', '092', '091', '082', '081', '072', '071',
                           '062', '061', '052', '051', '042', '041', '032', '031', '022', '021', '012', '011',

                           '262261', '251', '242', '241', '232', '231', '222', '221', '212', '211', '202', '201',
                           '192', '191', '182', '181', '172', '171', '162', '161', '152', '151', '142', '141',

                           '392391', '381', '372', '371', '362', '361', '352', '351', '342', '341', '332', '331',
                           '322', '321', '312', '311', '302', '301', '292', '291', '282', '281', '272', '271'];

  FTeeboxDevicNoTempJehu435 := ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
                              '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
                              '21', '22', '23', '25', '27',

                              '29', '30', '31', '32', '33', '34', '35', '36', '37', '38',
                              '39', '40', '41', '42', '43', '44', '45', '46', '47', '48',
                              '49', '50', '51', '53', '54', '55',

                              '57', '58', '59', '60', '61', '62', '63', '64', '65', '66',
                              '67', '68', '69', '70', '71', '72', '73', '74', '75', '76',
                              '77', '78', '79', '81', '82', '83'];
end;

procedure TTeebox.StartUp;
begin
  if Global.ADConfig.Emergency = False then
    GetTeeboxListToApi
  else
    GetTeeboxListToDB;

  SetTeeboxStartUseStatus;
  FSendApiErrorList := TStringList.Create;
end;

function TTeebox.GetTeeboxListToApi: Boolean;
var
  nIndex, nTeeboxNo, nTeeboxCnt: Integer;
  //sTeeboxVer: String;
  jObjArr: TJsonArray;
  jObj, jObjSub: TJSONObject;

  sJsonStr: AnsiString;
  sResult, sResultCd, sResultMsg, sLog: String;
begin
  Result := False;
  {
  sResult := Global.Api.GetTeeBoxVersion(sSeatVer, Global.ADConfig.ApiUrl, Global.ADConfig.ADToken, Global.ADConfig.StoreCode);
  if sResult = 'Success' then
  begin
    if FSeatVersion <> sSeatVer then
    begin
      //타석기 정보버전 확인필요???
      FSeatVersion := sSeatVer;
    end;
  end;
  }
  {
  sResult := Global.Api.GetTeeBoxList(jObjArr, Global.ADConfig.ApiUrl, Global.ADConfig.ADToken, Global.ADConfig.StoreCode);
  if sResult <> 'Success' then
  begin
    WriteLogDayFile(Global.LogFileName, sResult);
    Exit;
  end;
  }

  try

    sJsonStr := '?store_cd=' + Global.ADConfig.StoreCode;
    sResult := Global.Api.GetErpApiNoneData(sJsonStr, 'K204_TeeBoxlist', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

    //Global.Log.LogWrite(sResult);

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'GetSeatListToApi Fail : ' + sResult;
      //WriteLogDayFile(Global.LogFileName, sLog);
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K204_TeeBoxlist : ' + sResultCd + ' / ' + sResultMsg;
      //WriteLogDayFile(Global.LogFileName, sLog);
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObjArr := jObj.GetValue('result_data') as TJsonArray;

    nTeeboxCnt := jObjArr.Size;
    SetLength(FTeeboxInfoList, nTeeboxCnt + 1);
    SetLength(FTeeboxReserveList, nTeeboxCnt + 1);
    SetLength(FTeeboxDevicNoList, 0);

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

      //2020-12-16 빅토리아 반자동
      FTeeboxInfoList[nTeeboxNo].ControlYn := jObjSub.GetValue('control_yn').Value;
      {
      sLog := 'ControlYn : ' + IntToStr(nSeatNo) + ' / ' +
                    FSeatInfoList[nSeatNo].ControlYn;
            WriteLogDayFile(Global.LogFileName, sLog);
      }
      if jObjSub.GetValue('device_id').Value = 'null' then
      begin
        if Global.ADConfig.ProtocolType = 'ZOOM' then
          FTeeboxInfoList[nTeeboxNo].DeviceId := FTeeboxDevicNoTempZoom[nIndex]
        else if Global.ADConfig.ProtocolType = 'JEHU435' then
          FTeeboxInfoList[nTeeboxNo].DeviceId := FTeeboxDevicNoTempJehu435[nIndex]
        else if Global.ADConfig.ProtocolType = 'JMS' then
          FTeeboxInfoList[nTeeboxNo].DeviceId := IntToStr(nTeeboxNo);
      end
      else
      begin
        FTeeboxInfoList[nTeeboxNo].DeviceId := jObjSub.GetValue('device_id').Value;
      end;

      FTeeboxInfoList[nTeeboxNo].UseYn := jObjSub.GetValue('use_yn').Value;

      if FTeeboxInfoList[nTeeboxNo].UseYn = 'Y' then
      begin

        SetLength(FTeeboxDevicNoList, FTeeboxDevicNoCnt + 1);
        if (FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode = 'L') and (Global.ADConfig.StoreCode <> 'AB001') then
        begin
          if (Global.ADConfig.ProtocolType = 'ZOOM') or (Global.ADConfig.ProtocolType = 'ZOOM1') then
          begin
            FTeeboxDevicNoList[FTeeboxDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 1, 3);
            inc(FTeeboxDevicNoCnt);

            if Length(FTeeboxInfoList[nTeeboxNo].DeviceId) = 6 then
            begin
              SetLength(FTeeboxDevicNoList, FTeeboxDevicNoCnt + 1);
              FTeeboxDevicNoList[FTeeboxDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 4, 3);
              inc(FTeeboxDevicNoCnt);
            end;
          end
          else if (Global.ADConfig.ProtocolType = 'JEHU435') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
          begin
            FTeeboxDevicNoList[FTeeboxDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 1, 2);
            inc(FTeeboxDevicNoCnt);

            if Length(FTeeboxInfoList[nTeeboxNo].DeviceId) = 4 then
            begin
              SetLength(FTeeboxDevicNoList, FTeeboxDevicNoCnt + 1);
              FTeeboxDevicNoList[FTeeboxDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 3, 2);
              inc(FTeeboxDevicNoCnt);
            end;
          end
          else
          begin
            FTeeboxDevicNoList[FTeeboxDevicNoCnt] := FTeeboxInfoList[nTeeboxNo].DeviceId;
            inc(FTeeboxDevicNoCnt);
          end;
        end
        else
        begin
          FTeeboxDevicNoList[FTeeboxDevicNoCnt] := FTeeboxInfoList[nTeeboxNo].DeviceId;
          inc(FTeeboxDevicNoCnt);
        end;

        if (Global.ADConfig.ProtocolType = 'ZOOM') or (Global.ADConfig.ProtocolType = 'ZOOM1') then
        begin
          if Length(FTeeboxInfoList[nTeeboxNo].DeviceId) < 3 then
          begin
            sLog := 'GetTeeBoxList Error : TeeboxNo: ' + IntToStr(nTeeboxNo) + ' / ' +
                    FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode + ' / ' +
                    FTeeboxInfoList[nTeeboxNo].DeviceId;
            //WriteLogDayFile(Global.LogFileName, sLog);
            Global.Log.LogWrite(sLog);
            //Exit;
          end;
        end;

      end;

      //FSeatInfoList[nSeatNo].RemainMinute := StrToInt(jObj.GetValue('remain_min').Value);
      //FSeatInfoList[nSeatNo].RemainBall := StrToInt(jObj.GetValue('remain_balls').Value);
      FTeeboxInfoList[nTeeboxNo].UseStatus := '0';

      FTeeboxInfoList[nTeeboxNo].UseRStatus := '0';
      FTeeboxInfoList[nTeeboxNo].UseLStatus := '0';

      FTeeboxInfoList[nTeeboxNo].ComReceive := 'N'; //최초 1회 체크

      FTeeboxReserveList[nTeeboxNo].TeeboxNo := nTeeboxNo;
      //FTeeboxReserveList[nTeeboxNo].nCurrIdx := 0;
      //FTeeboxReserveList[nTeeboxNo].nLastIdx := 0;
      FTeeboxReserveList[nTeeboxNo].ReserveList := TStringList.Create;
    end;

  finally
    //FreeAndNil(jObjArr);
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
    SetLength(FTeeboxReserveList, nTeeboxCnt + 1);
    SetLength(FTeeboxDevicNoList, 0);

    for nIndex := 0 to nTeeboxCnt - 1 do
    begin

      nTeeboxNo := rTeeboxInfoList[nIndex].TeeboxNo;
      if FTeeboxLastNo < nTeeboxNo then
        FTeeboxLastNo := nTeeboxNo;

      FTeeboxInfoList[nTeeboxNo].TeeboxNo := rTeeboxInfoList[nIndex].TeeboxNo;
      FTeeboxInfoList[nTeeboxNo].TeeboxNm := rTeeboxInfoList[nIndex].TeeboxNm;
      FTeeboxInfoList[nTeeboxNo].FloorZoneCode := rTeeboxInfoList[nIndex].FloorZoneCode;
      //FTeeboxInfoList[nTeeboxNo].FloorNm := rTeeboxInfoList[I].FloorNm;
      FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode := rTeeboxInfoList[nIndex].TeeboxZoneCode;

      //빅토리아 반자동 29,28,2,1,58,57,31,30
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

      if FTeeboxInfoList[nTeeboxNo].UseYn = 'Y' then
      begin

        SetLength(FTeeboxDevicNoList, FTeeboxDevicNoCnt + 1);
        if (FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode = 'L') and (Global.ADConfig.StoreCode <> 'AB001') then
        begin
          if (Global.ADConfig.ProtocolType = 'ZOOM') or (Global.ADConfig.ProtocolType = 'ZOOM1') then
          begin
            FTeeboxDevicNoList[FTeeboxDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 1, 3);
            inc(FTeeboxDevicNoCnt);

            if Length(FTeeboxInfoList[nTeeboxNo].DeviceId) = 6 then
            begin
              SetLength(FTeeboxDevicNoList, FTeeboxDevicNoCnt + 1);
              FTeeboxDevicNoList[FTeeboxDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 4, 3);
              inc(FTeeboxDevicNoCnt);
            end;
          end
          else if (Global.ADConfig.ProtocolType = 'JEHU435') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
          begin
            FTeeboxDevicNoList[FTeeboxDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 1, 2);
            inc(FTeeboxDevicNoCnt);

            if Length(FTeeboxInfoList[nTeeboxNo].DeviceId) = 4 then
            begin
              SetLength(FTeeboxDevicNoList, FTeeboxDevicNoCnt + 1);
              FTeeboxDevicNoList[FTeeboxDevicNoCnt] := Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 3, 2);
              inc(FTeeboxDevicNoCnt);
            end;
          end
          else
          begin
            FTeeboxDevicNoList[FTeeboxDevicNoCnt] := FTeeboxInfoList[nTeeboxNo].DeviceId;
            inc(FTeeboxDevicNoCnt);
          end;
        end
        else
        begin
          FTeeboxDevicNoList[FTeeboxDevicNoCnt] := FTeeboxInfoList[nTeeboxNo].DeviceId;
          inc(FTeeboxDevicNoCnt);
        end;

        if (Global.ADConfig.ProtocolType = 'ZOOM') or (Global.ADConfig.ProtocolType = 'ZOOM1') then
        begin
          if Length(FTeeboxInfoList[nTeeboxNo].DeviceId) < 3 then
          begin
            sLog := 'GetTeeBoxList Error : TeeboxNo: ' + IntToStr(nTeeboxNo) + ' / ' +
                    FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode + ' / ' +
                    FTeeboxInfoList[nTeeboxNo].DeviceId;
            //WriteLogDayFile(Global.LogFileName, sLog);
            Global.Log.LogWrite(sLog);
            //Exit;
          end;
        end;

      end;

      FTeeboxInfoList[nTeeboxNo].UseStatus := '0';

      FTeeboxInfoList[nTeeboxNo].UseRStatus := '0';
      FTeeboxInfoList[nTeeboxNo].UseLStatus := '0';

      FTeeboxInfoList[nTeeboxNo].ComReceive := 'N'; //최초 1회 체크

      FTeeboxReserveList[nTeeboxNo].TeeboxNo := nTeeboxNo;
      //FTeeboxReserveList[nTeeboxNo].nCurrIdx := 0;
      //FTeeboxReserveList[nTeeboxNo].nLastIdx := 0;
      FTeeboxReserveList[nTeeboxNo].ReserveList := TStringList.Create;
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
  //rTeeboxHoldList: TList<TSeatUseReserve>;

  nDBMax: Integer;
  I, nTeeboxNo, nIndex: Integer;
  sStausChk, sBallBackStart: String;
  sStr, sPreDate: String;

  NextReserve: TNextReserve;
  nErpReserveNo: Integer;
begin
  rTeeboxInfoList := Global.XGolfDM.SeatSelect;

  sStausChk := '';
  nDBMax := 0;
  for I := 0 to rTeeboxInfoList.Count - 1 do
  begin
    nTeeboxNo := rTeeboxInfoList[I].TeeboxNo;

    if (FTeeboxInfoList[nTeeboxNo].TeeboxNm <> rTeeboxInfoList[I].TeeboxNm) or
       (FTeeboxInfoList[nTeeboxNo].FloorZoneCode <> rTeeboxInfoList[I].FloorZoneCode) or
       (FTeeboxInfoList[nTeeboxNo].FloorNm <> rTeeboxInfoList[I].FloorNm) or //2021-06-25 층명 추가(이선우이사님)
       (FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode <> rTeeboxInfoList[I].TeeboxZoneCode) or
       (FTeeboxInfoList[nTeeboxNo].DeviceId <> rTeeboxInfoList[I].DeviceId) or
       (FTeeboxInfoList[nTeeboxNo].UseYn <> rTeeboxInfoList[I].UseYn) then
    begin
      Global.XGolfDM.SeatUpdate(Global.ADConfig.StoreCode, FTeeboxInfoList[nTeeboxNo]);
    end;

    FTeeboxInfoList[nTeeboxNo].UseStatusPre := rTeeboxInfoList[I].UseStatus;
    FTeeboxInfoList[nTeeboxNo].UseStatus := rTeeboxInfoList[I].UseStatus;
    if FTeeboxInfoList[nTeeboxNo].UseStatus = '8' then
      TeeboxDeviceCheck(nTeeboxNo, '8');

    FTeeboxInfoList[nTeeboxNo].RemainMinPre := rTeeboxInfoList[I].RemainMinute;
    FTeeboxInfoList[nTeeboxNo].RemainMinute := rTeeboxInfoList[I].RemainMinute;

    FTeeboxInfoList[nTeeboxNo].RemainBall := rTeeboxInfoList[I].RemainBall;

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '7' then
      sStausChk := '7';

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

  //2020-06-09 전날 배정 정리
  if FormatDateTime('hh', now) <= Copy(Global.Store.StartTime, 1, 2) then
  begin
    sPreDate := FormatDateTime('YYYYMMDD', now - 1);
    Global.XGolfDM.SeatUseStoreClose(Global.ADConfig.StoreCode, Global.ADConfig.UserId, sPreDate);
  end;

  //타석 현재사용중 또는 바로 배정할 대기목록
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

    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := rSeatUseReserveList[nIndex].StartTime;
    if rSeatUseReserveList[nIndex].UseStatus = '1' then
    begin
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      Global.Log.LogReserveWrite('UseStatus = 1 '  + rSeatUseReserveList[nIndex].ReserveNo);
    end;

    if Global.ADConfig.StoreCode = 'A5001' then
    begin
      if FTeeboxInfoList[nTeeboxNo].UseStatus = '0' then
        FTeeboxInfoList[nTeeboxNo].UseLStatus := '1';
    end;

    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignYn := rSeatUseReserveList[nIndex].AssignYn;

    sStr := '목록 : ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin);
    Global.Log.LogReserveWrite(sStr);

  end;
  FreeAndNil(rSeatUseReserveList);

  //타석 현재 사용중,대기중이 종료후 배정할 예약목록
  rSeatUseReserveList := Global.XGolfDM.SeatUseAllReserveSelectNext(Global.ADConfig.StoreCode);

  for nIndex := 0 to rSeatUseReserveList.Count - 1 do
  begin
    if rSeatUseReserveList[nIndex].SeatNo = 0 then
      Continue;

    nTeeboxNo := rSeatUseReserveList[nIndex].SeatNo;

    //2020-06-29
    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = rSeatUseReserveList[nIndex].ReserveNo then
      Continue;

    try
      NextReserve := TNextReserve.Create;
      NextReserve.ReserveNo := rSeatUseReserveList[nIndex].ReserveNo;
      NextReserve.UseStatus := rSeatUseReserveList[nIndex].UseStatus;
      NextReserve.SeatNo := IntToStr(rSeatUseReserveList[nIndex].SeatNo);
      NextReserve.UseMinute := IntToStr(rSeatUseReserveList[nIndex].UseMinute);
      NextReserve.UseBalls := IntToStr(rSeatUseReserveList[nIndex].UseBalls);
      NextReserve.DelayMinute := IntToStr(rSeatUseReserveList[nIndex].DelayMinute);
      NextReserve.ReserveDate := rSeatUseReserveList[nIndex].ReserveDate;
      NextReserve.StartTime := rSeatUseReserveList[nIndex].StartTime;
      NextReserve.AssignYn := rSeatUseReserveList[nIndex].AssignYn;

      FTeeboxReserveList[nTeeboxNo].ReserveList.AddObject(NextReserve.SeatNo, TObject(NextReserve));
    finally
      //FreeAndNil(NextReserve);
    end;

    sStr := '예약목록 : ' + IntToStr(nTeeboxNo) + ' / ' + rSeatUseReserveList[nIndex].ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;

  FreeAndNil(rSeatUseReserveList);

  if (Global.ADConfig.StoreCode = 'A4001') and //유명
     (Global.Store.StartTime > Global.Store.EndTime) then
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

  //시작시 볼회수 상태이면
  if sStausChk = '7' then
  begin
    sBallBackStart := Global.ReadConfigBallBackStartTime;
    if sBallBackStart = '' then
      FTeeboxInfoList[0].PauseTime := Now
    else
      FTeeboxInfoList[0].PauseTime := DateStrToDateTime2(sBallBackStart);

    //chy 2020-10-30 볼회수 체크
    FBallBackUse := True;
  end;
end;

//재시작시 예약내용과 타석기배정상태를 비교
function TTeebox.CheckSeatReserve(ATeeboxInfo: TTeeboxInfo): Boolean;
var
  nTeeboxNo, nUseTime: Integer;
  tmSeatEndExceptChkTime: TDateTime;
  sStr: String;
  bPrepare: Boolean;
begin
  nTeeboxNo := ATeeboxInfo.TeeboxNo;

  if (ATeeboxInfo.RemainMinute = 0) and (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = '' ) then
  begin
    FTeeboxInfoList[nTeeboxNo].RemainMinPre := ATeeboxInfo.RemainMinute;
    FTeeboxInfoList[nTeeboxNo].RemainMinute := ATeeboxInfo.RemainMinute;
    Exit;
  end;

  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'N';
  //Global.Log.LogReserveWrite('6');

  //오류로 재시작시 타석기의 배정이 끝난 경우
  if (ATeeboxInfo.RemainMinute = 0) and (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate <> '' ) then
  begin
    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';

    tmSeatEndExceptChkTime := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate) +
                               (((1/24)/60) * FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin);
    //배정종료시간을 넘은경우
    if tmSeatEndExceptChkTime < Now then
    begin
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

      sStr := '배정종료 예외처리 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
      Global.Log.LogReserveWrite(sStr);

      Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, '2');
    end
    else //볼회수중 AD종료, 볼회수 종료후 AD 구동인경우
    begin
      if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      begin
        ATeeboxInfo.RemainMinute := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;
      end
      else
      begin
        //배정위해 제어배열에 등록
        SetTeeboxCtrl(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall);

        sStr := '재기동 복귀명령 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute) + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainBall) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].UseStatus;
        Global.Log.LogReserveWrite(sStr);
      end;
    end;
  end;

  //if (Global.ADConfig.ProtocolType <> 'JMS') and (Global.ADConfig.ProtocolType <> 'MODENYJ') then
  begin

  if (ATeeboxInfo.UseStatus = '1') and (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> '' ) then
  begin
    if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') then
    begin
      nUseTime := (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin - ATeeboxInfo.RemainMinute);
      //FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := FormatDateTime('YYYYMMDDhhnnss', Now - (((1/24)/60) * nUseTime) );
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := FormatDateTime('YYYYMMDDhhnn00', Now - (((1/24)/60) * nUseTime) ); //2021-06-11

      sStr := 'StartDate reset - Config: ' + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
      Global.Log.LogReserveWrite(sStr);

      Global.XGolfDM.SeatUseStartDateUpdate(Global.ADConfig.StoreCode, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate, Global.ADConfig.UserId);
    end;

    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
  end;

  end;

  FTeeboxInfoList[nTeeboxNo].RemainMinPre := ATeeboxInfo.RemainMinute;
  FTeeboxInfoList[nTeeboxNo].RemainMinute := ATeeboxInfo.RemainMinute;

end;

function TTeebox.TeeboxDeviceCheck(ATeeboxNo: Integer; AType: String): Boolean;
begin
  FTeeboxInfoList[ATeeboxNo].UseApiStatus := AType;
  FTeeboxInfoList[ATeeboxNo].UseStatus := AType;

  if (Global.ADConfig.ProtocolType = 'MODENYJ') and (AType = '0') then //점검 해제시
    SetTeeboxCtrlRemainMinFree(ATeeboxNo);
end;

//chy 2020-10-30 볼회수전 볼회수상태인지 체크
function TTeebox.TeeboxBallRecallStartCheck: Boolean;
var
  nIndex: Integer;
  sStr: String;
begin
  Result := False;

  for nIndex := 1 to TeeboxLastNo do
  begin
    if (FTeeboxInfoList[nIndex].UseYn = 'Y') and (FTeeboxInfoList[nIndex].UseStatus = '7') then //정지상태
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TTeebox.TeeboxBallRecallStart: Boolean;
var
  nIndex: Integer;
  sStr: String;
begin
  Result := False;

  //볼회수 일경우 현재 남은시간 저장
  Global.CheckConfigBall(0);
  //보상시간 체크시작
  //SetSeatDelay(1, 0);
  SetTeeboxDelay(0, 0);

  for nIndex := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nIndex].UseStatus = '9' then //타석기 고장
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '8' then //점검상태
      Continue;

    if FTeeboxInfoList[nIndex].UseStatus = '7' then //정지상태
      Continue;

    if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      FTeeboxInfoList[nIndex].UseStatusPre := FTeeboxInfoList[nIndex].UseStatus;

    FTeeboxInfoList[nIndex].UseStatus := '7';

    if FTeeboxInfoList[nIndex].RemainMinute > 0 then
    begin
      //배정위해 제어배열에 등록, S1 제어, 시간 초기화
      if (Global.ADConfig.ProtocolType <> 'JMS') and (Global.ADConfig.ProtocolType <> 'MODENYJ') then
        SetTeeboxCtrl(nIndex, 'S1' , 0, FTeeboxInfoList[nIndex].RemainBall);

      sStr := '정지명령 : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
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
  nIndex, nSeatRemainMin, nDelayNo: Integer;
  sStr: String;
begin
  Result := False;
  //보상시간 체크종료
  //SetSeatDelay(1, 1);
  SetTeeboxDelay(0, 1);
  nDelayNo := -1;

  if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
  begin
    for nIndex := 1 to TeeboxLastNo do
    begin
      if FTeeboxInfoList[nIndex].UseStatus <> '7' then //정지상태
        Continue;

      if FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin > 0 then
      begin
        //2021-04-21 조광, 볼회수중 시작시간이 되는경우있음. 상태가 1이 였던것만 시간 추가
        if FTeeboxInfoList[nIndex].UseStatusPre = '1' then
          FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin + FTeeboxInfoList[0].DelayMin;

        sStr := '복귀명령 : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin) + ' / ' +
                IntToStr(FTeeboxInfoList[0].DelayMin) + ' / UseStatusPre : ' + FTeeboxInfoList[nIndex].UseStatusPre;
        Global.Log.LogReserveWrite(sStr);
      end;

      FTeeboxInfoList[nIndex].UseStatus := FTeeboxInfoList[nIndex].UseStatusPre;
    end;
  end
  else
  begin

    for nIndex := 1 to TeeboxLastNo do
    begin

      if FTeeboxInfoList[nIndex].UseStatus <> '7' then //정지상태
        Continue;

      //반자동
      if FTeeboxInfoList[nIndex].ControlYn = 'N' then
      begin
        if FTeeboxInfoList[nIndex].RemainMinute > 0 then
        begin
          FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin := FTeeboxInfoList[nIndex].TeeboxReserve.AssignMin + FTeeboxInfoList[0].DelayMin;
          FTeeboxInfoList[nIndex].UseStatus := '1';
        end
        else
          FTeeboxInfoList[nIndex].UseStatus := '0';

        Continue;
      end;

      nSeatRemainMin := Global.ReadConfigBallRemainMin(nIndex);
      if FTeeboxInfoList[nIndex].RemainMinute <> nSeatRemainMin then
      begin
        sStr := '복귀확인 : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].RemainBall) + ' / ' +
                'ConfigBall: ' + IntToStr(nSeatRemainMin);
        Global.Log.LogReserveWrite(sStr);

        FTeeboxInfoList[nIndex].RemainMinute := nSeatRemainMin;
      end;

      if FTeeboxInfoList[nIndex].RemainMinute > 0 then
      begin
        //배정위해 제어배열에 등록
        if Global.ADConfig.StoreCode = 'B2001' then //그린필드
        begin
          if FTeeboxInfoList[nIndex].RemainMinute < 2 then //1분이하인경우 제외
            FTeeboxInfoList[nIndex].RemainMinute := 0
          else
          begin
            FTeeboxInfoList[nIndex].RemainMinute := FTeeboxInfoList[nIndex].RemainMinute - FTeeboxInfoList[0].DelayMin;

            if FTeeboxInfoList[nIndex].RemainMinute < 0 then
              FTeeboxInfoList[nIndex].RemainMinute := 1;
          end;

          SetTeeboxCtrl(nIndex, 'S1' , FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].RemainBall);
        end
        else
          SetTeeboxCtrl(nIndex, 'S1' , FTeeboxInfoList[nIndex].RemainMinute, FTeeboxInfoList[nIndex].RemainBall);

        sStr := '복귀명령 : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].RemainBall) + ' / ' +
                FTeeboxInfoList[nIndex].UseStatus;
        Global.Log.LogReserveWrite(sStr);
        nDelayNo := nIndex;
      end;

      FBallBackEnd := True;
    end;
    {
    if nDelayNo = -1 then //빈타석인경우
      BallBackEndCtl := True;
    }
  end;

  // index 0 번 기준으로 볼회수 시간 체크-다음 예약중인 배정 DB예약시간 추가 적용
  if Global.ADConfig.StoreCode <> 'B2001' then //그린필드
    ResetTeeboxRemainMinAdd(0, FTeeboxInfoList[0].DelayMin, 'ALL');

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
  if AType = 0 then //지연시작
  begin
    FTeeboxInfoList[ATeeboxNo].PauseTime := Now;
  end
  else if AType = 1 then //지연종료
  begin
    FTeeboxInfoList[ATeeboxNo].RePlayTime := Now;

    //2020-06-29 딜레이체크
    if formatdatetime('YYYYMMDD', FTeeboxInfoList[ATeeboxNo].PauseTime) <> formatdatetime('YYYYMMDD',now) then
    begin
      FTeeboxInfoList[ATeeboxNo].DelayMin := 0;
    end
    else
    begin
      //1분 추가 적용-20200507
      nTemp := Trunc((FTeeboxInfoList[ATeeboxNo].RePlayTime - FTeeboxInfoList[ATeeboxNo].PauseTime) *24 * 60 * 60); //초로 변환
      if (nTemp mod 60) > 0 then
        FTeeboxInfoList[ATeeboxNo].DelayMin := (nTemp div 60) + 1
      else
        FTeeboxInfoList[ATeeboxNo].DelayMin := (nTemp div 60);
    end;

    sStr := formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[ATeeboxNo].PauseTime) + ' / ' +
            formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[ATeeboxNo].RePlayTime) + ' / ' +
            IntToStr(FTeeboxInfoList[ATeeboxNo].DelayMin);
    Global.Log.LogReserveWrite(sStr);
  end
  else if AType = 2 then //지연중
  begin
    nTemp := Trunc((Now - FTeeboxInfoList[ATeeboxNo].PauseTime) *24 * 60 * 60); //초로 변환
    if (nTemp mod 60) > 0 then
      FTeeboxInfoList[ATeeboxNo].DelayMin := FTeeboxInfoList[ATeeboxNo].DelayMin + (nTemp div 60) + 1
    else
      FTeeboxInfoList[ATeeboxNo].DelayMin := FTeeboxInfoList[ATeeboxNo].DelayMin + (nTemp div 60);
  end;

end;

procedure TTeebox.SetTeeboxInfo(ATeeboxInfo: TTeeboxInfo);
var
  nSeatNo: Integer;
  sStr, sEndTy, sChange: String;
  //bErrorChk: Boolean;
  bRecvDeviceR: Boolean;
begin
  nSeatNo := ATeeboxInfo.TeeboxNo;

  //점검, 볼회수 상태
  if (FTeeboxInfoList[nSeatNo].UseStatus = '7') and (BallBackEndCtl = False) then
    Exit;

  if FBallBackUse = True then
    Exit;

  //재시작시 예약내용과 타석기배정상태를 비교
  if FTeeboxInfoList[nSeatNo].ComReceive = 'N' then
    CheckSeatReserve(ATeeboxInfo);

  if (Global.ADConfig.StoreCode = 'A1001') or (Global.ADConfig.StoreCode = 'A9001') then //스타, 루이힐스
  begin
    if FTeeboxInfoList[nSeatNo].UseReset = 'Y' then
    begin
    sStr := '타석기 UseReset : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              IntToStr(ATeeboxInfo.RemainMinute);
      Global.Log.LogReserveWrite(sStr);
      Exit;
    end;
  end;

  if (Global.ADConfig.StoreCode = 'B2001') then //그린필드
  begin
    if ATeeboxInfo.UseStatus = 'M' then
    begin
      Global.XGolfDM.TeeboxErrorUpdate('AD', IntToStr(nSeatNo), '8');
      Global.Teebox.TeeboxDeviceCheck(nSeatNo, '8');

      sStr := '타석기 수동 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              IntToStr(ATeeboxInfo.RemainMinute);
      Global.Log.LogReserveWrite(sStr);
      Exit;
    end;
  end;

  if (FTeeboxInfoList[nSeatNo].UseStatus = '9') or (ATeeboxInfo.UseStatus = '9') then
  begin
    if (FTeeboxInfoList[nSeatNo].UseStatus = '9') and (ATeeboxInfo.UseStatus <> '9') and
       (FTeeboxInfoList[nSeatNo].RemainMinute > 0) and (ATeeboxInfo.RemainMinute = 0) then
    begin
      sStr := '타석기 대기 error 9 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nSeatNo].UseCancel + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].RemainMinute) + ' / ' +
              IntToStr(ATeeboxInfo.RemainMinute)  + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate;
      //임시 주석
      //Global.Log.LogReserveWrite(sStr);
    end
    else
    begin
      (*
      bErrorChk := False;
      if (FTeeboxInfoList[nSeatNo].TeeboxZoneCode = 'L') and (Global.ADConfig.StoreCode <> 'AB001') then
      begin

        bRecvDeviceR := False;

        if Global.ADConfig.StoreCode = 'A8001' then
        begin
          if Copy(FTeeboxInfoList[nSeatNo].DeviceId, 1, 2) = ATeeboxInfo.RecvDeviceId then //R 오른쪽
            bRecvDeviceR := True;
        end
        else
        begin
          if Copy(FTeeboxInfoList[nSeatNo].DeviceId, 1, 3) = ATeeboxInfo.RecvDeviceId then //R 오른쪽
            bRecvDeviceR := True;
        end;

        if bRecvDeviceR = True then
        begin
          if FTeeboxInfoList[nSeatNo].UseRStatus <> ATeeboxInfo.UseStatus then
            bErrorChk := True;
        end
        else
        begin
          if FTeeboxInfoList[nSeatNo].UseLStatus <> ATeeboxInfo.UseStatus then
            bErrorChk := True;
        end;
      end
      else
      begin
        if FTeeboxInfoList[nSeatNo].UseStatus <> ATeeboxInfo.UseStatus then
          bErrorChk := True;
      end;

      if bErrorChk = True then
      begin
        //FTeeboxError := True;

        { //타석기통신이 여러개일 경우 I/O 에러 발생소지 있음
        sStr := 'No: ' + IntToStr(ATeeboxInfo.TeeboxNo) + ' / ' +
                'Pre: ' + FTeeboxInfoList[nSeatNo].UseStatus + ' / ' +
                'Now: ' + ATeeboxInfo.UseStatus;
        if Global.ADConfig.StoreCode = 'AB001' then
        begin
          if ATeeboxInfo.TeeboxNo <= 16 then
            Global.LogRetryWriteModen(2, sStr)
          else if ATeeboxInfo.TeeboxNo <= 32 then
            Global.LogRetryWriteModen(3, sStr)
          else if ATeeboxInfo.TeeboxNo <= 48 then
            Global.LogRetryWriteModen(4, sStr)
          else
            Global.LogRetryWriteModen(5, sStr);

          //Global.LogWrite(sStr);
        end
        else
          Global.LogWrite(sStr);
        }
      end;
      *)
    end;
  end;

  //2020-06-02 좌우타석 수정
  if (FTeeboxInfoList[nSeatNo].TeeboxZoneCode = 'L') and
     ((Global.ADConfig.StoreCode <> 'A1001') and (Global.ADConfig.StoreCode <> 'AB001')) then
  begin

    bRecvDeviceR := False;

    if Global.ADConfig.StoreCode = 'A8001' then
    begin
      if Copy(FTeeboxInfoList[nSeatNo].DeviceId, 1, 2) = ATeeboxInfo.RecvDeviceId then //R 오른쪽
        bRecvDeviceR := True;
    end
    else
    begin
      if Copy(FTeeboxInfoList[nSeatNo].DeviceId, 1, 3) = ATeeboxInfo.RecvDeviceId then //R 오른쪽
        bRecvDeviceR := True;
    end;

    if bRecvDeviceR = True then
    begin
      FTeeboxInfoList[nSeatNo].UseRStatus := ATeeboxInfo.UseStatus;
      FTeeboxInfoList[nSeatNo].RemainRMin := ATeeboxInfo.RemainMinute;
      FTeeboxInfoList[nSeatNo].RemainRBall := ATeeboxInfo.RemainBall;
    end
    else
    begin
      FTeeboxInfoList[nSeatNo].UseLStatus := ATeeboxInfo.UseStatus;
      FTeeboxInfoList[nSeatNo].RemainLMin := ATeeboxInfo.RemainMinute;
      FTeeboxInfoList[nSeatNo].RemainLBall := ATeeboxInfo.RemainBall;

      //볼수: 적은거 기준
      if FTeeboxInfoList[nSeatNo].RemainRBall > FTeeboxInfoList[nSeatNo].RemainLBall then
        FTeeboxInfoList[nSeatNo].RemainBall := FTeeboxInfoList[nSeatNo].RemainLBall
      else
        FTeeboxInfoList[nSeatNo].RemainBall := FTeeboxInfoList[nSeatNo].RemainRBall;

      if (FTeeboxInfoList[nSeatNo].UseStatus <> '8') then //점검
      begin
        //상태: 가동중 기준
        if (FTeeboxInfoList[nSeatNo].UseRStatus = '9') or (FTeeboxInfoList[nSeatNo].UseLStatus = '9') then
          FTeeboxInfoList[nSeatNo].UseStatus := '9'
        else if (FTeeboxInfoList[nSeatNo].UseRStatus = '1') or (FTeeboxInfoList[nSeatNo].UseLStatus = '1') then
          FTeeboxInfoList[nSeatNo].UseStatus := '1'
        else
          FTeeboxInfoList[nSeatNo].UseStatus := '0';
      end;

      //잔여시간: 큰거 기준
      FTeeboxInfoList[nSeatNo].RemainMinute := FTeeboxInfoList[nSeatNo].RemainRMin;
      if FTeeboxInfoList[nSeatNo].RemainRMin < FTeeboxInfoList[nSeatNo].RemainLMin then
        FTeeboxInfoList[nSeatNo].RemainMinute := FTeeboxInfoList[nSeatNo].RemainLMin;
    end;
  end
  else
  begin
    FTeeboxInfoList[nSeatNo].RemainBall := ATeeboxInfo.RemainBall;
    FTeeboxInfoList[nSeatNo].RemainMinute := ATeeboxInfo.RemainMinute;
    if (FTeeboxInfoList[nSeatNo].UseStatus <> '8') then //점검
      FTeeboxInfoList[nSeatNo].UseStatus := ATeeboxInfo.UseStatus;
  end;

  //2020-06-29 Error코드
  FTeeboxInfoList[nSeatNo].ErrorCd := ATeeboxInfo.ErrorCd;
  FTeeboxInfoList[nSeatNo].ErrorCd2 := ATeeboxInfo.ErrorCd2;

  FTeeboxInfoList[nSeatNo].ComReceive := 'Y';
end;

procedure TTeebox.SetTeeboxInfoUseReset(ATeeboxNo: Integer);
begin
  FTeeboxInfoList[ATeeboxNo].UseReset := 'N';
end;

procedure TTeebox.SetTeeboxInfoJMS(ATeeboxInfo: TTeeboxInfo);
var
  nTeeboxNo, nTemp: Integer;
  sStr: String;
  bRecvDeviceR: Boolean;
begin
  nTeeboxNo := ATeeboxInfo.TeeboxNo;
  //Global.Log.LogWrite('0');
  //볼회수 상태
  if FTeeboxInfoList[nTeeboxNo].UseStatus = '7' then
    Exit;

  //Global.Log.LogWrite('1');
  //재시작시 예약내용과 타석기배정상태를 비교
  if FTeeboxInfoList[nTeeboxNo].ComReceive = 'N' then
    CheckSeatReserve(ATeeboxInfo);

  if (FTeeboxInfoList[nTeeboxNo].UseStatus = '9') or (ATeeboxInfo.UseStatus = '9') then
  begin

    if FTeeboxInfoList[nTeeboxNo].UseStatus <> ATeeboxInfo.UseStatus then
    begin
      //FTeeboxError := True;
      sStr := 'No: ' + IntToStr(ATeeboxInfo.TeeboxNo) + ' / ' +
              'Pre: ' + FTeeboxInfoList[nTeeboxNo].UseStatus + ' / ' +
              'Now: ' + ATeeboxInfo.UseStatus + ' / ' + 'cd: ' + IntToStr(ATeeboxInfo.ErrorCd);
      Global.Log.LogWrite(sStr);
    end;
  end;

  if (FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode = 'L') then
  begin

    bRecvDeviceR := False;

    if Copy(FTeeboxInfoList[nTeeboxNo].DeviceId, 1, 2) = ATeeboxInfo.RecvDeviceId then //R 오른쪽
      bRecvDeviceR := True;

    if bRecvDeviceR = True then
    begin
      FTeeboxInfoList[nTeeboxNo].UseRStatus := ATeeboxInfo.UseStatus;
    end
    else
    begin
      FTeeboxInfoList[nTeeboxNo].UseLStatus := ATeeboxInfo.UseStatus;

      if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '8') then //점검
      begin
        //상태: 가동중 기준
        if (FTeeboxInfoList[nTeeboxNo].UseRStatus = '9') or (FTeeboxInfoList[nTeeboxNo].UseLStatus = '9') then
          FTeeboxInfoList[nTeeboxNo].UseStatus := '9'
        else if (FTeeboxInfoList[nTeeboxNo].UseRStatus = '1') or (FTeeboxInfoList[nTeeboxNo].UseLStatus = '1') then
          FTeeboxInfoList[nTeeboxNo].UseStatus := '1'
        else
          FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
      end;

    end;
  end
  else
  begin
    FTeeboxInfoList[nTeeboxNo].RemainBall := ATeeboxInfo.RemainBall;
    //FSeatInfoList[nSeatNo].RemainMinute := ASeatInfo.RemainMinute;
    if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '8') then //점검
    begin
      FTeeboxInfoList[nTeeboxNo].UseStatus := ATeeboxInfo.UseStatus;
      FTeeboxInfoList[nTeeboxNo].UseRStatus := ATeeboxInfo.UseRStatus;

      if FTeeboxInfoList[nTeeboxNo].UseStatus = '1' then
      begin
        FTeeboxInfoList[nTeeboxNo].UseLStatus := '0';
        FTeeboxInfoList[nTeeboxNo].UseRStatus := '0';
      end;
    end;
  end;
  //Global.Log.LogWrite('2');
  FTeeboxInfoList[nTeeboxNo].ErrorCd := ATeeboxInfo.ErrorCd;
  FTeeboxInfoList[nTeeboxNo].ErrorCd2 := ATeeboxInfo.ErrorCd2;
  FTeeboxInfoList[nTeeboxNo].ComReceive := 'Y';

end;

{
procedure TTeebox.SetTeeboxStartTime(ATeeboxNo: Integer; AStartTm: String);
begin
  FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveStartDate := AStartTm;
end;
}
{
procedure TTeebox.SetTeeboxReserveTime(ATeeboxNo: Integer; AStartTm: String);
begin
  FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveDate := AStartTm;
end;
}

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
    sStr := '동일예약건 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
          ASeatReserveInfo.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
    Exit;
  end;

  //현재 배정중이면
  if (FTeeboxInfoList[nSeatNo].UseStatus = '1') and
     (FTeeboxInfoList[nSeatNo].RemainMinute > 0) then
  begin

    global.Teebox.SetTeeboxReserveNext(ASeatReserveInfo);
    sStr := '신규배정대기 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
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
  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'N';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignYn:= ASeatReserveInfo.AssignYn;

  if ASeatReserveInfo.ReserveDate <= formatdatetime('YYYYMMDDhhnnss', Now) then
  begin

    if (Global.ADConfig.StoreCode = 'A1001') then
    begin
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := Now;
    end
    else
    begin
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := formatdatetime('YYYYMMDDhhnn00', Now); //2021-06-11 초00 표시-이선우이사님
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate) +
                                                               (((1/24)/60) * FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin);
    end;
  end
  else
  begin

    if (Global.ADConfig.StoreCode = 'A1001') then
    begin
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := ASeatReserveInfo.ReserveDate;
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate);
    end
    else
    begin
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate := ASeatReserveInfo.ReserveDate;
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate) +
                                                           (((1/24)/60) * FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin);
    end;
  end;

  Global.SetADConfigBallPrepare(nSeatNo,
                                FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo,
                                FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate);

  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate := '';
  FTeeboxInfoList[nSeatNo].TeeboxReserve.ChangeMin := 0;
  FTeeboxInfoList[nSeatNo].DelayMin := 0;
  FTeeboxInfoList[nSeatNo].UseCancel := 'N';
  FTeeboxInfoList[nSeatNo].UseClose := 'N';
  FTeeboxInfoList[nSeatNo].PrepareChk := 0;

  if Global.ADConfig.StoreCode = 'A5001' then //송도-제우테크 예약대기중 확인용
    FTeeboxInfoList[nSeatNo].UseLStatus := '1';

  if Global.ADConfig.StoreCode = 'AC001' then //조광-상태초기화, 등록후 바로 취소시 UseLStatus 1->0 으로 변경이 않됨.
    FTeeboxInfoList[nSeatNo].UseLStatus := '0';

end;

function TTeebox.SetTeeboxReserveChange(ASeatUseInfo: TSeatUseInfo): Boolean;
var
  nSeatNo, nCtlMin: Integer;
  sStr: String;

  //2020-08-27 v26 이용타석 시간추가시 예약타석 시간증가
  nDelayMin: Integer;
begin
  Result:= False;

  nSeatNo := ASeatUseInfo.SeatNo;
  if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo <> ASeatUseInfo.ReserveNo then
  begin
    SetTeeboxReserveNextChange(nSeatNo, ASeatUseInfo);
    Exit;
  end;

  //대기시간/배정시간 변경 체크
  if (FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin = ASeatUseInfo.PrepareMin) and
     (FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin = ASeatUseInfo.AssignMin) then
  begin
    //변경된 내용 없음
    Exit;
  end;

  if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn = 'N' then
  begin
    sStr := '예약배정시간변경 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
            '대기시간' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' -> ' +
            IntToStr(ASeatUseInfo.PrepareMin) + ' / ' +
            '배정시간' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin) + ' -> ' +
            IntToStr(ASeatUseInfo.AssignMin);

    //2020-05-29 예약대기상태
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin <> ASeatUseInfo.AssignMin then
    begin
      FTeeboxInfoList[nSeatNo].TeeboxReserve.ChangeMin := ASeatUseInfo.AssignMin;
      if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      begin
        //2020-08-27 v26 시간추가시 예약타석시간추가
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
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate) +
                                                          (((1/24)/60) * ASeatUseInfo.PrepareMin);
      FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin := ASeatUseInfo.PrepareMin;
    end;
  end
  else
  begin
    //배정된후 배정시간 변경만 체크
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin <> ASeatUseInfo.AssignMin then
    begin
      if ASeatUseInfo.AssignMin < 2 then
        ASeatUseInfo.AssignMin := 2; // 0 으로 변경시 대기시간 상태 적용됨

      if Global.ADConfig.ProtocolType = 'JEHU435' then
      begin
        if (Global.ADConfig.StoreCode = 'A1001') or (Global.ADConfig.StoreCode = 'A9001') then //스타,루이힐스
        begin

          FTeeboxInfoList[nSeatNo].UseReset := 'Y';
          SetTeeboxCtrl(nSeatNo, 'S1' , 0, 0000);
          sStr := '배정시간변경 : 초기화';
          Global.Log.LogReserveWrite(sStr);
        end;
      end;

      //배정시간변경 위해 제어배열에 등록
      nCtlMin := ASeatUseInfo.RemainMin + (ASeatUseInfo.AssignMin - FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin);

      if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      begin
        //2020-08-27 v26 시간추가시 예약타석시간추가
        nDelayMin := 0;
        if ASeatUseInfo.RemainMin < ASeatUseInfo.AssignMin then
        begin
          nDelayMin := ASeatUseInfo.AssignMin - ASeatUseInfo.RemainMin;
        end;

        FTeeboxInfoList[nSeatNo].RemainMinute := nCtlMin;
      end
      else
        SetTeeboxCtrl(nSeatNo, 'S1' , nCtlMin, FTeeboxInfoList[nSeatNo].RemainBall);

      FTeeboxInfoList[nSeatNo].TeeboxReserve.ChangeMin := nCtlMin;

      sStr := '배정시간변경 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
              '배정시간' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin) + ' -> ' +
              IntToStr(ASeatUseInfo.AssignMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].RemainMinute) + ' -> ' +
              IntToStr(nCtlMin);
    end;

  end;

  Global.Log.LogReserveWrite(sStr);
  FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin := ASeatUseInfo.AssignMin;

  if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
    ResetTeeboxReserveMinAddJMS(nSeatNo, nDelayMin);

  Result:= True;
end;

function TTeebox.SetTeeboxReserveCancle(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    //예약대기, 배정된 타석이 아님
    SetTeeboxReserveNextCancel(ATeeboxNo, AReserveNo);
    Exit;
  end;

  //취소위해 제어배열에 등록
  FTeeboxInfoList[ATeeboxNo].UseCancel := 'Y';

  if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
    FTeeboxInfoList[ATeeboxNo].RemainMinute := 0
  //2020-12-17 빅토리아 추가
  else if FTeeboxInfoList[ATeeboxNo].ControlYn = 'N' then
    FTeeboxInfoList[ATeeboxNo].RemainMinute := 0
  else
    SetTeeboxCtrl(ATeeboxNo, 'S1', 0, 9999);

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
  //2020-12-17 빅토리아 추가
  else if FTeeboxInfoList[ATeeboxNo].ControlYn = 'N' then
    FTeeboxInfoList[ATeeboxNo].RemainMinute := 0
  else
    SetTeeboxCtrl(ATeeboxNo, 'S1', 0, 9999);

  sStr := 'Close no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo;
  Global.Log.LogReserveWrite(sStr);
  Result := True;
end;

//chy 2020-10-27 즉시배정
function TTeebox.SetTeeboxReserveStartNow(ATeeboxNo: Integer; AReserveNo: String): String;
var
  sStr, sReserveNoTemp, sReserveDateTemp, sResult: String;
  SeatUseReserve: TSeatUseReserve;
begin
  Result := '';

  if FTeeboxInfoList[ATeeboxNo].UseStatus <> '0' then
  begin
    Result := '사용중인 타석입니다. 상태: ' + FTeeboxInfoList[ATeeboxNo].UseStatus;
    Exit;
  end;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo = AReserveNo then
  begin
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime := Now;

    sStr := 'Start Now 대기 no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end
  else
  begin
    if FTeeboxReserveList[ATeeboxNo].ReserveList.Count = 0 then
    begin
      Result := '대기중인 예약이 없습니다.';
      Exit;
    end;

    sReserveNoTemp := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).ReserveNo;
    if sReserveNoTemp <> AReserveNo then
    begin
      Result := '대기중인 예약이 아닙니다.';
      Exit;
    end;

    SeatUseReserve.ReserveNo := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).ReserveNo;
    SeatUseReserve.UseStatus := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).UseStatus;
    SeatUseReserve.SeatNo := StrToInt(TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).SeatNo);
    SeatUseReserve.UseMinute := StrToInt(TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).UseMinute);
    SeatUseReserve.UseBalls := StrToInt(TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).UseBalls);
    //SeatUseReserve.DelayMinute := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[0]).DelayMinute);
    SeatUseReserve.DelayMinute := 0;
    //SeatUseReserve.ReserveDate := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[0]).ReserveDate;
    sReserveDateTemp := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).ReserveDate;
    //SeatUseReserve.ReserveDate := formatdatetime('YYYYMMDDHHNNSS', now);
    SeatUseReserve.ReserveDate := formatdatetime('YYYYMMDDHHNN00', now); //2021-06-11
    SeatUseReserve.StartTime := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).StartTime;

    SetTeeboxReserveInfo(SeatUseReserve);

    TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).Free;
    FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0] := nil;
    FTeeboxReserveList[ATeeboxNo].ReserveList.Delete(0);

    sStr := 'Start Now no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo + ' / ' + sReserveDateTemp + ' -> ' + SeatUseReserve.ReserveDate;
    Global.Log.LogReserveWrite(sStr);

    //2021-08-03 끼어넣기 대상 제외처리
    sResult := Global.XGolfDM.SeatUseCutInUseListDelete(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sReserveDateTemp, True);
    if sResult <> 'Success' then
      sStr := 'Start Now CutInUseListDelete Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + sReserveDateTemp
    else
      sStr := 'Start Now CutInUseListDelete : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + sReserveDateTemp;

    Global.Log.LogReserveWrite(sStr);
  end;

  Result := 'Success';
end;

{
procedure TTeebox.SetTeeboxReserveNo(ATeeboxNo: Integer; AReserveNo: String);
begin
  FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo := AReserveNo;
end;
}

procedure TTeebox.TeeboxReserveChk;
var
  nSeatNo: Integer;
  sSendData: AnsiString;
  sSeatTime, sSeatBall, sBcc: AnsiString;
  nCnt, nIndex: Integer;
  sCheckTime, sTime, sStr, sSeatStr: string;

  AEndTime: TDateTime;
  nNNTemp, nTmTemp: Integer;
  bReAssignMin: Boolean;

  tmCheckIn: TDateTime;
begin
  //Global.LogWrite('SeatReserveChk!!!');

  sCheckTime := FormatDateTime('YYYYMMDD hh:nn:ss', Now);
  sTime := Copy(sCheckTime, 10, 5);

  if Global.ADConfig.StoreCode = 'A4001' then //유명
  begin

  end
  else
  begin

    if sTime < Global.Store.StartTime then
      Exit;

    if sTime > Global.Store.EndTime then
    begin
      if Global.Store.Close = 'N' then
      begin
        //SetStoreClose;
        Global.SetStoreInfoClose('Y');
        Global.Log.LogWrite('Store Close !!!');
      end;

      if (Global.Store.Close = 'Y') and (Global.Store.EndDBTime <> '') then
      begin
        if sTime > Global.Store.EndDBTime then
        begin
          Global.XGolfDM.SeatUseStoreClose( Global.ADConfig.StoreCode, Global.ADConfig.UserId, Copy(sCheckTime, 1, 8) );
          Global.SetStoreEndDBTime('');
        end;
      end;

      Exit;
    end;

    if Global.Store.Close = 'Y' then
    begin
      Global.SetStoreInfoClose('N');
      Global.Log.LogWrite('Store Open !!!');
    end;

  end;

  //Global.LogWrite('SeatReserveChk !!!');

  for nSeatNo := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nSeatNo].ComReceive <> 'Y' then
      Continue;

    //2020-12-17 빅토리아 추가
    if FTeeboxInfoList[nSeatNo].ControlYn <> 'Y' then
      continue;

    //타석기 배정상태 확인
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo = '' then
      Continue;

    //모바일,기간권 미 체크인
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignYn = 'N' then
    begin
      //시간 지난거에 대한 종료 처리 필요
      tmCheckIn := DateStrToDateTime3(FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate) +
                   (((1/24)/60) * (FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin + FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin));

      if tmCheckIn < now then
      begin
        FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'Y';
        FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
        FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        // DB/Erp저장: 종료시간
        Global.TcpServer.SetApiTeeBoxEnd(nSeatNo, FTeeboxInfoList[nSeatNo].TeeboxNm, FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate, '2');

        sStr := '미체크인 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin) + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
        Global.Log.LogReserveWrite(sStr);

        FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo := '';
      end;

      Continue;
    end;

    if (FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn = 'Y') and
       (FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate <> '') then //배정상태
    begin
      Continue;
    end;

    if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Continue;

    if FTeeboxInfoList[nSeatNo].UseStatus <> '0' then //가동상태(빈타석:0) 4@
    begin
      if (FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime > Now) and
         (FTeeboxInfoList[nSeatNo].UseStatus = '1') then
      begin
        //if (Global.ADConfig.ProtocolType = 'ZOOM') or (Global.ADConfig.StoreCode = 'B2001') then
        if (Global.ADConfig.ProtocolType = 'ZOOM') then
        begin
          sStr := 'PrepareEndTime > Now / UseStatus = 1';
          Global.Log.LogReserveWrite(sStr);
        end
        else
        begin
          Continue;
        end;
      end
      else
      begin
        Continue;
      end;
    end;

    if FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime < Now then
    begin
      FTeeboxInfoList[nSeatNo].PrepareChk := 0;

      //2020-07-13 v15 배정등록직전 예약취소시 타이밍문제 발생
      if FTeeboxInfoList[nSeatNo].UseCancel = 'Y' then
      begin
        SetTeeboxCtrl(nSeatNo, 'S1', 0, 9999);

        if (FTeeboxInfoList[nSeatNo].RemainMinute = 0) and
           (FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn = 'N') and
           (FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate = '') then
        begin
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'Y';
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
          FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

          sStr := '배정정리 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo;
          Global.Log.LogReserveWrite(sStr);
        end;

        sStr := '등록전취소 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo;
        Global.Log.LogReserveWrite(sStr);

        Continue;
      end;

      if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin = 0 then //배정시간이 0인 경우
      begin
        FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'Y';
        FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
        FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '배정에러 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
        Global.Log.LogReserveWrite(sStr);
      end
      else
      begin
        //배정위해 제어배열에 등록
        {
        if (Global.ADConfig.ProtocolType = 'ZOOM') or (Global.ADConfig.ProtocolType = 'ZOOM1') or
           (Global.ADConfig.ProtocolType = 'JEHU60A') or (Global.ADConfig.ProtocolType = 'JEU50A') then
          SetSeatCtrl(nSeatNo, 'S1' , FSeatInfoList[nSeatNo].SeatReserve.AssignMin, FSeatInfoList[nSeatNo].SeatReserve.AssignBalls)
        else
          SetSeatCtrl(nSeatNo, 'S1' , FSeatInfoList[nSeatNo].SeatReserve.AssignMin + FSeatInfoList[nSeatNo].SeatReserve.PrepareMin,
                      FSeatInfoList[nSeatNo].SeatReserve.AssignBalls);
        }

        sStr := '배정등록 : no' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
                FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate + ' / ';

        if Global.ADConfig.StoreCode = 'A1001' then //스타
          SetTeeboxCtrl(nSeatNo, 'S1' , FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin + FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin,
                      FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls)

        else if Global.ADConfig.StoreCode = 'AD001' then //한강 2021-06-18 야간볼회수후 배정되는 배정시간 종료시간 넘지 않도록 조치
        begin

          bReAssignMin := False;
          if FormatDateTime('HH:NN', Now) > '22:00' then //22시경 볼회수
          begin
            AEndTime := DateStrToDateTime(FormatDateTime('yyyymmdd', now) + StringReplace(Global.Store.EndTime, ':', '', [rfReplaceAll]) + '00');
            nNNTemp := MinutesBetween(AEndTime, now);

            if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin > nNNTemp then
            begin
              bReAssignMin := True;
              sStr := sStr + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin) + '->' + IntToStr(nNNTemp) + ' = ' +
                      formatdatetime('YYYYMMDDhhnnss', AEndTime) + ' / ';
            end;
          end;

          if bReAssignMin = True then
            SetTeeboxCtrl(nSeatNo, 'S1' , nNNTemp, FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls)
          else
            SetTeeboxCtrl(nSeatNo, 'S1' , FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls);

        end

        else
          SetTeeboxCtrl(nSeatNo, 'S1' , FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls);

        {
        sStr := '배정등록 : no' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
                FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate + ' / ' +
                formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
        }
        sStr := sStr + formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
        Global.Log.LogReserveWrite(sStr);
      end;
    end
    else
    begin
      if Global.ADConfig.StoreCode = 'B2001' then //그린필드, 줌테크,예약기능미사용
        Continue;

      if (Global.ADConfig.ProtocolType = 'ZOOM') or (Global.ADConfig.ProtocolType = 'ZOOM1') then
      begin
        inc(FTeeboxInfoList[nSeatNo].PrepareChk);

        if FTeeboxInfoList[nSeatNo].RemainMinute = 0 then
        begin

          //2021-04-07 배정등록직전 예약취소시 타이밍문제 발생-유명
          if (FTeeboxInfoList[nSeatNo].UseCancel = 'Y') and
             (Global.ADConfig.ProtocolType = 'ZOOM1') then
          begin

            if (FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn = 'N') and
               (FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate = '') then
            begin
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'Y';
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

              sStr := '배정정리 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo;
              Global.Log.LogReserveWrite(sStr);
            end;

            sStr := '등록전취소 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo;
            Global.Log.LogReserveWrite(sStr);

            Continue;
          end;


          //배정전 타석기 예약
          SetTeeboxCtrl(nSeatNo, 'S0' , FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls);

          sStr := '배정예약 : no ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
                  IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate;
          Global.Log.LogReserveWrite(sStr);
        end;

        if (Global.ADConfig.ProtocolType = 'ZOOM') then
        begin
          if FTeeboxInfoList[nSeatNo].PrepareChk > 10 then
          begin
            FTeeboxInfoList[nSeatNo].PrepareChk := 0;

            //2020-05-27 적용: 예약유지중인 타석 취소시 타이밍문제 발생
            if (FTeeboxInfoList[nSeatNo].RemainMinute > 0) and (FTeeboxInfoList[nSeatNo].UseCancel = 'Y') then
            begin
              //배정전 타석기 예약유지-예약상태에서 볼사용후 타석기버튼 클릭으로 볼재배치시 타석기 가동됨
              SetTeeboxCtrl(nSeatNo, 'S1', 0, 9999);

              sStr := '재취소 : no ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
                    FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
                    FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo;
              Global.Log.LogReserveWrite(sStr);
            end
            else
            begin
              //배정전 타석기 예약유지-예약상태에서 볼사용후 타석기버튼 클릭으로 볼재배치시 타석기 가동됨
              SetTeeboxCtrl(nSeatNo, 'S0' , FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls);

              sStr := '배정예약유지 no: ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
                    FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
                    FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
                    IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
                    FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate + ' / ' +
                    FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate + ' / ' +
                    formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime);
              Global.Log.LogReserveWrite(sStr);
            end;
          end;
        end;

        if (Global.ADConfig.ProtocolType = 'ZOOM1') then
        begin
          //2020-08-04 적용: 예약유지기능이 없음. 배정시간변경 확인
          FTeeboxInfoList[nSeatNo].PrepareChk := 0;

          if (FTeeboxInfoList[nSeatNo].RemainMinute > 0) and
             (FTeeboxInfoList[nSeatNo].RemainMinute <> FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin) then
          begin
            SetTeeboxCtrl(nSeatNo, 'S0' , FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignBalls);

            sStr := '배정예약변경 no : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
                  IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate + ' / ' +
                  FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate + ' / ' +
                  formatdatetime('YYYY-MM-DD hh:nn:ss', FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime);
            Global.Log.LogReserveWrite(sStr);
          end;
        end;

      end;

    end;
  end;

end;

procedure TTeebox.TeeboxReserveChkJMS;
var
  nTeeboxNo: Integer;
  sSendData: AnsiString;
  sSeatTime, sSeatBall, sBcc: AnsiString;
  nCnt, nIndex: Integer;
  sCheckTime, sTime, sStr, sSeatStr: string;
begin
  //Global.LogWrite('SeatReserveChk!!!');

  //2020-08-26 v26 JMS 영업종료시 타석정리 기능추가
  sCheckTime := FormatDateTime('YYYYMMDD hh:nn:ss', Now);
  sTime := Copy(sCheckTime, 10, 5);
  //sTime := '23:59';

  if (sTime < Global.Store.StartTime) or (sTime >= Global.Store.EndTime) then
  begin
    if Global.Store.Close = 'N' then
    begin
      SetStoreClose;
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

  for nTeeboxNo := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nTeeboxNo].ComReceive <> 'Y' then
      Continue;

    //타석기 배정상태 확인
    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = '' then
      Continue;

    if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'Y') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate <> '') then //배정상태
    begin
      Continue;
    end;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Continue;

    //if (FSeatInfoList[nSeatNo].UseStatus <> '0') then //가동상태(빈타석:0) 4@
    if (FTeeboxInfoList[nTeeboxNo].UseStatus = '0') and (FTeeboxInfoList[nTeeboxNo].UseLStatus = '0') then //가동상태(빈타석:0) 4@
    begin

    end
    else
    begin
      Continue;
    end;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin = 0 then //배정시간이 0인 경우
    begin
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

      sStr := '배정에러 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
      Global.Log.LogReserveWrite(sStr);

      Continue;
    end;

    if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime < Now then
    begin
      FTeeboxInfoList[nTeeboxNo].PrepareChk := 0;

      //2020-07-13 v15 배정등록직전 예약취소시 타이밍문제 발생
      if FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y' then
      begin
        //SetSeatCtrl(nSeatNo, 'S1', 0, 9999);
        FTeeboxInfoList[nTeeboxNo].RemainMinute := 0;

        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') and
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate = '') then
        begin
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

          sStr := '배정정리 no: ' + FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo;
          Global.Log.LogReserveWrite(sStr);
        end;

        sStr := '등록전취소 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo;
        Global.Log.LogReserveWrite(sStr);

        Continue;
      end;

      //배정위해 제어배열에 등록
      //SetSeatCtrl(nSeatNo, 'S1' , FSeatInfoList[nSeatNo].SeatReserve.AssignMin, FSeatInfoList[nSeatNo].SeatReserve.AssignBalls);
      FTeeboxInfoList[nTeeboxNo].RemainMinute := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;

      //if Global.ADConfig.ProtocolType = 'JMS' then
        FTeeboxInfoList[nTeeboxNo].UseLStatus := '1'; //대기시간초과

      sStr := '배정등록 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
      Global.Log.LogReserveWrite(sStr);
    end
    else
    begin
      if Global.ADConfig.ProtocolType = 'JMS' then
      begin

        if FTeeboxInfoList[nTeeboxNo].RemainMinute = 0 then
        begin
          //배정전 타석기 예약
          //SetSeatCtrl(nSeatNo, 'S0' , FSeatInfoList[nSeatNo].SeatReserve.AssignMin, FSeatInfoList[nSeatNo].SeatReserve.AssignBalls);
          FTeeboxInfoList[nTeeboxNo].RemainMinute := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin;

          sStr := '배정예약 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareMin) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate;
          Global.Log.LogReserveWrite(sStr);
        end;

      end;

    end;
  end;

end;

//2020-12-16 빅토리아
procedure TTeebox.TeeboxStatusChkVictoria;
var
  nTeeboxNo: Integer;
  sStr, sEndTy, sChange, sResult, sLog: String;
  I, nNN, nTmTemp, nTemp: Integer;
  tmTempS: TDateTime;
begin

  //2020-08-13
  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sLog := 'SeatReserveUse SeatStatusChkVictoria!';
    Global.Log.LogReserveDelayWrite(sLog);

    sleep(50);
  end;

  FTeeboxStatusUse := True;

  for nTeeboxNo := 1 to FTeeboxLastNo do
  begin

    if FTeeboxInfoList[nTeeboxNo].ControlYn <> 'N' then
      continue;

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '7' then
      continue;

    //시간계산
    if (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'Y') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate <> '') then
    begin

      //sNN := FormatDateTime('NN', now - DateStrToDateTime3(FSeatInfoList[nTeeboxNo].SeatReserve.ReserveStartDate));
      tmTempS := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);
      nNN := MinutesBetween(now, tmTempS);

      nTmTemp := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin - nNN;
      if nTmTemp < 0 then
        nTmTemp := 0;
      FTeeboxInfoList[nTeeboxNo].RemainMinute := nTmTemp;

    end;

    if (FTeeboxInfoList[nTeeboxNo].RemainMinPre = 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) then
    begin

      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := '';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'N';

      sStr := '배정시작 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].UseStatus + ' / ' + inttostr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
      Global.Log.LogReserveWrite(sStr);
    end;

    if (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') and
       (FTeeboxInfoList[nTeeboxNo].UseStatus = '1') then
    begin

      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> '' then
      begin
        //FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnn00', Now); //2021-06-11

        sStr := '배정구동 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
        Global.Log.LogReserveWriteSemiAuto(sStr);

        // DB/Erp저장: 시작시간
        sResult := Global.TcpServer.SetApiTeeBoxReg(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);
      end;

    end;

    if (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) then
    begin

      if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') or
         (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') or
         (FTeeboxInfoList[nTeeboxNo].RemainMinPre < 3) then
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '배정종료 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWriteSemiAuto(sStr);

        sEndTy := '2';
        if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') then //취소인경우 K410_TeeBoxReserved 통해 ERP 전송
          sEndTy := '5'
        else
        begin
          // DB/Erp저장: 종료시간
          sResult := Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, sEndTy);
        end;

        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') then  //예약대기상태
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo := '';

        FTeeboxInfoList[nTeeboxNo].UseStatus := '0';
      end;

    end;

    // DB저장: 타석기상태(시간,상태,볼수)
    if FTeeboxInfoList[nTeeboxNo].RemainMinPre <> FTeeboxInfoList[nTeeboxNo].RemainMinute then
      Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

    FTeeboxInfoList[nTeeboxNo].RemainMinPre := FTeeboxInfoList[nTeeboxNo].RemainMinute;
  end;

  Sleep(10);
  FTeeboxStatusUse := False;
end;

//2020-12-16 빅토리아
procedure TTeebox.TeeboxReserveChkVictoria;
var
  nSeatNo: Integer;
  sSendData: AnsiString;
  sSeatTime, sSeatBall, sBcc: AnsiString;
  nCnt, nIndex: Integer;
  sCheckTime, sTime, sStr, sSeatStr: string;
begin
  //Global.LogWrite('SeatReserveChk!!!');

  //2020-08-26 v26 JMS 영업종료시 타석정리 기능추가
  sCheckTime := FormatDateTime('YYYYMMDD hh:nn:ss', Now);
  sTime := Copy(sCheckTime, 10, 5);
  //sTime := '23:59';

  if (sTime < Global.Store.StartTime) or (sTime >= Global.Store.EndTime) then
  begin
    if Global.Store.Close = 'N' then
    begin

      for nIndex := 1 to TeeboxLastNo do
      begin
        if FTeeboxInfoList[nIndex].ControlYn <> 'N' then
          Continue;

        if FTeeboxInfoList[nIndex].RemainMinute <= 0 then
          Continue;

        FTeeboxInfoList[nIndex].RemainMinute := 0;

        sStr := 'Close : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
                IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
                FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo;
        Global.Log.LogReserveWriteSemiAuto(sStr);
      end;
    end;

    Exit;
  end;

  for nSeatNo := 1 to TeeboxLastNo do
  begin
    if FTeeboxInfoList[nSeatNo].ControlYn <> 'N' then
      Continue;

    //타석기 배정상태 확인
    if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo = '' then
      Continue;

    if (FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn = 'Y') and
       (FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate <> '') then //배정상태
    begin
      Continue;
    end;

    if FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
      Continue;

    if (FTeeboxInfoList[nSeatNo].UseStatus <> '0') then //가동상태(빈타석:0) 4@
      Continue;

    if FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin = 0 then //배정시간이 0인 경우
    begin
      FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'Y';
      FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
      FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

      sStr := '배정에러 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
      Global.Log.LogReserveWriteSemiAuto(sStr);

      Continue;
    end;

    if FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareEndTime < Now then
    begin
      FTeeboxInfoList[nSeatNo].PrepareChk := 0;

      if FTeeboxInfoList[nSeatNo].UseCancel = 'Y' then
      begin
        FTeeboxInfoList[nSeatNo].RemainMinute := 0;

        sStr := '등록전취소 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo;
        Global.Log.LogReserveWriteSemiAuto(sStr);

        Continue;
      end;

      FTeeboxInfoList[nSeatNo].RemainMinute := FTeeboxInfoList[nSeatNo].TeeboxReserve.AssignMin;
      FTeeboxInfoList[nSeatNo].UseStatus := '1';
      FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveStartDate := '';
      FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveYn := 'N';

      sStr := '배정등록 : ' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate + ' / ' +
              FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate + ' / ' +
              formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
      Global.Log.LogReserveWriteSemiAuto(sStr);
    end;

  end;

end;

function TTeebox.GetDevicToTeeboxNo(ADev: String): Integer;
var
  i: Integer;
  sDeviceIdR, sDeviceIdL: String;
begin
  Result := 0;
  for i := 1 to FTeeboxLastNo do
  begin
    if (FTeeboxInfoList[i].TeeboxZoneCode = 'L') and (Global.ADConfig.StoreCode <> 'AB001') then //좌우겸용
    begin
      if (Global.ADConfig.ProtocolType = 'JEHU435') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      begin
        sDeviceIdR := Copy(FTeeboxInfoList[i].DeviceId, 1, 2);
        sDeviceIdL := Copy(FTeeboxInfoList[i].DeviceId, 3, 2);
      end
      else
      begin
        sDeviceIdR := Copy(FTeeboxInfoList[i].DeviceId, 1, 3);
        sDeviceIdL := Copy(FTeeboxInfoList[i].DeviceId, 4, 3);
      end;

      if (sDeviceIdR = ADev) or (sDeviceIdL = ADev) then
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
  end;

end;

function TTeebox.GetDevicToFloorTeeboxNo(AFloor, ADev: String): Integer;
var
  i: Integer;
  sDeviceIdR, sDeviceIdL: String;
begin
  Result := 0;
  for i := 1 to FTeeboxLastNo do
  begin
    if (Global.ADConfig.StoreCode = 'A5001') then //송도: jeu60A, 1 port 사용
    begin
    end
    else
    begin
      if FTeeboxInfoList[i].FloorZoneCode <> AFloor then
        Continue;
    end;

    if (FTeeboxInfoList[i].TeeboxZoneCode = 'L') and (Global.ADConfig.StoreCode <> 'AB001') then //좌우겸용
    begin
      sDeviceIdR := Copy(FTeeboxInfoList[i].DeviceId, 1, 2);
      sDeviceIdL := Copy(FTeeboxInfoList[i].DeviceId, 3, 2);

      if (sDeviceIdR = ADev) or (sDeviceIdL = ADev) then
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
  end;

end;

function TTeebox.GetDevicToFloorTeeboxNoModen(AFloor, ADev: String): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to FTeeboxLastNo do
  begin
    if FTeeboxInfoList[i].FloorZoneCode <> AFloor then
      Continue;

    if FTeeboxInfoList[i].DeviceId = ADev then
    begin
      Result := i;
      Break;
    end;
  end;

end;

function TTeebox.GetDevicToTeeboxNm(ADev: String): String;
var
  i: Integer;
  sDeviceIdR, sDeviceIdL: String;
begin
  Result := '';
  for i := 1 to FTeeboxLastNo do
  begin
    if (FTeeboxInfoList[i].TeeboxZoneCode = 'L') and (Global.ADConfig.StoreCode <> 'AB001') then //좌우겸용
    begin
      sDeviceIdR := Copy(FTeeboxInfoList[i].DeviceId, 1, 3);
      sDeviceIdL := Copy(FTeeboxInfoList[i].DeviceId, 4, 3);

      if (sDeviceIdR = ADev) or (sDeviceIdL = ADev) then
      begin
        Result := FTeeboxInfoList[i].TeeboxNm;
        Break;
      end;
    end
    else
    begin
      if FTeeboxInfoList[i].DeviceId = ADev then
      begin
        Result := FTeeboxInfoList[i].TeeboxNm;
        Break;
      end;
    end;
  end;

end;

function TTeebox.GetTeeboxNoToDevic(ATeeboxNo: Integer): String;
begin
  Result := FTeeboxInfoList[ATeeboxNo].DeviceId;
end;

function TTeebox.GetTeeboxDevicdNoToDevic(AIndex: Integer): String;
begin
  Result := FTeeboxDevicNoList[AIndex];
end;

function TTeebox.GetTeeboxInfoA(AChannelCd: String): TTeeboxInfo;
var
  nIndex: Integer;
  sDeviceIdR, sDeviceIdL: String;
begin
  for nIndex := 1 to FTeeboxLastNo do
  begin
    if (FTeeboxInfoList[nIndex].TeeboxZoneCode = 'L') and (Global.ADConfig.StoreCode <> 'AB001') then //좌우겸용
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

function TTeebox.GetTeeboxStatusList: AnsiString;
var
  nIndex: Integer;
  sJsonStr: AnsiString;
  jObj, jItemObj: TJSONObject; //Erp 전송전문
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

      if FTeeboxInfoList[nIndex].UseStatus = '9' then
        jItemObj.AddPair( TJSONPair.Create( 'error_code', FTeeboxInfoList[nIndex].ErrorCd2 ) );

      jObjArr.Add(jItemObj);
    end;

    sJsonStr := jObj.ToString;
  finally
    jObj.Free;
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

    //시간초기화 제어배열 등록
    FTeeboxInfoList[nIndex].UseClose := 'Y';

    //2020-08-26 v26 JMS 영업종료시 타석정리 추가
    if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      FTeeboxInfoList[nIndex].RemainMinute := 0
    else
      SetTeeboxCtrl(nIndex, 'S1' , 0, 9999);

    sStr := 'Close : ' + IntToStr(FTeeboxInfoList[nIndex].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxNm + ' / ' +
            IntToStr(FTeeboxInfoList[nIndex].RemainMinute) + ' / ' +
            FTeeboxInfoList[nIndex].TeeboxReserve.ReserveNo;
    Global.Log.LogReserveWrite(sStr);
  end;
end;

procedure TTeebox.SetTeeboxCtrl(ATeeboxNo: Integer; AType: String; ATime: Integer; ABall: Integer);
var
  sSendData: AnsiString;
  sSeatTime, sSeatBall, sDeviceIdR, sDeviceIdL: AnsiString;
  sStr: String;
begin

  {
    //2021-06-14 점검중인 상태이면 배정않되도록, 송도, 이종섭 과장
    if FTeeboxInfoList[nSeatNo].UseStatus = '8' then //점검
    begin
      sStr := '배정제외(점검) : no' + IntToStr(FTeeboxInfoList[nSeatNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[nSeatNo].TeeboxNm + ' / ' +
            FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveNo + ' / ' +
            IntToStr(FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareMin) + ' / ' +
            FTeeboxInfoList[nSeatNo].TeeboxReserve.ReserveDate + ' / ' +
            FTeeboxInfoList[nSeatNo].TeeboxReserve.PrepareStartDate + ' / ' +
            formatdatetime('YYYY-MM-DD hh:nn:ss', Now);
      Global.Log.LogReserveWrite(sStr);

      Continue;
    end;
  }


  sSeatTime := IntToStr(ATime);
  sSeatBall := IntToStr(ABall);

  //global.LogWrite('SetTeeboxCtrl : ' + IntToStr(ASeatNo));

  //	2	4	2	S	1	0	0	0	0	9	9	9	9		J
  // 대성 AB001: 장치ID 한자리, 좌우겸용 표시만
  if (FTeeboxInfoList[ATeeboxNo].TeeboxZoneCode = 'L') and (Global.ADConfig.StoreCode <> 'AB001') then //좌우겸용
  begin
    if Global.ADConfig.ProtocolType = 'JEHU435' then  //스타 A1001 표시만 좌우겸용
    begin
      sDeviceIdR := Copy(FTeeboxInfoList[ATeeboxNo].DeviceId, 1, 2);
      Global.CtrlSendBuffer(ATeeboxNo, sDeviceIdR, sSeatTime, sSeatBall, AType);

      // chy 2021-04-07 스타 볼회수 에러로 length, trim 추가 2,56번타석
      if Length(FTeeboxInfoList[ATeeboxNo].DeviceId) = 4 then
      begin
        sDeviceIdL := Copy(FTeeboxInfoList[ATeeboxNo].DeviceId, 3, 2);

        if Trim(sDeviceIdL) <> '' then
        begin
          Global.CtrlSendBuffer(ATeeboxNo, sDeviceIdL, sSeatTime, sSeatBall, AType);
        end
        else
        begin
          sStr := '좌우겸용 sDeviceIdL Empty : ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].DeviceId;
          Global.Log.LogReserveWrite(sStr);
        end;
      end;
    end
    else
    begin

      sDeviceIdR := Copy(FTeeboxInfoList[ATeeboxNo].DeviceId, 1, 3);
      Global.CtrlSendBuffer(ATeeboxNo, sDeviceIdR, sSeatTime, sSeatBall, AType);

      if Length(FTeeboxInfoList[ATeeboxNo].DeviceId) = 6 then
      begin
        sDeviceIdL := Copy(FTeeboxInfoList[ATeeboxNo].DeviceId, 4, 3);

        if Trim(sDeviceIdL) <> '' then
        begin
          Global.CtrlSendBuffer(ATeeboxNo, sDeviceIdL, sSeatTime, sSeatBall, AType);
        end
        else
        begin
          sStr := '좌우겸용 sDeviceIdL Empty : ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].DeviceId;
          Global.Log.LogReserveWrite(sStr);
        end;
      end;
    end;

  end
  else
  begin
    Global.CtrlSendBuffer(ATeeboxNo, FTeeboxInfoList[ATeeboxNo].DeviceId, sSeatTime, sSeatBall, AType);

    //181	V8	3
    if (Global.ADConfig.StoreCode = 'A8001') and (FTeeboxInfoList[ATeeboxNo].TeeboxNo = 181) then //쇼골프, V8
    begin //8번룸 vip, 좌우겸용
      Global.CtrlSendBuffer(ATeeboxNo, '64', sSeatTime, sSeatBall, AType);
    end;

  end;

end;

//2021-06-02 조광, MODENYJ / 타석점검제어
procedure TTeebox.SetTeeboxCtrlRemainMin(ATeeboxNo: Integer; ATime: Integer);
begin
  FTeeboxInfoList[ATeeboxNo].RemainMinute := ATime;
  FTeeboxInfoList[ATeeboxNo].CheckCtrl := True;
end;

//2021-06-02 조광, MODENYJ / 타석점검제어
procedure TTeebox.SetTeeboxCtrlRemainMinFree(ATeeboxNo: Integer);
begin
  if FTeeboxInfoList[ATeeboxNo].CheckCtrl = False then
    Exit;

  FTeeboxInfoList[ATeeboxNo].RemainMinute := 0;
  FTeeboxInfoList[ATeeboxNo].CheckCtrl := False;
end;

procedure TTeebox.SetTeeboxBallBackReply;
var
  i, nSeatRemainMin: Integer;
  sStr: String;
begin
  for i := 1 to FTeeboxLastNo do
  begin
    nSeatRemainMin := Global.ReadConfigBallRemainMin(i);

    if nSeatRemainMin > 0 then
    begin
      //배정위해 제어배열에 등록
      SetTeeboxCtrl(i, 'S1' , nSeatRemainMin, FTeeboxInfoList[i].RemainBall);

      sStr := '복귀명령_2 : ' + IntToStr(FTeeboxInfoList[i].TeeboxNo) + ' / ' +
              FTeeboxInfoList[i].TeeboxNm + ' / ' +
              FTeeboxInfoList[i].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(nSeatRemainMin) + ' / ' +
              IntToStr(FTeeboxInfoList[i].RemainBall) + ' / ' +
              FTeeboxInfoList[i].UseStatus;
      Global.Log.LogReserveWrite(sStr);
    end;
  end;
end;

procedure TTeebox.SetTeeboxErrorCnt(ATeeboxNo: Integer; AError: String; AMaxCnt: Integer);
var
  sLogMsg: String;
begin
  if FTeeboxInfoList[ATeeboxNo].UseStatus = '8' then //점검
  begin
    //sLogMsg := 'UseStatus = 8 : ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
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
        sLogMsg := 'ErrorCnt : ' + IntToStr(AMaxCnt) + ' / ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
        Global.Log.LogRetryWrite(sLogMsg);
      end;

      FTeeboxInfoList[ATeeboxNo].ErrorYn := 'Y';
      FTeeboxInfoList[ATeeboxNo].UseStatus := '9';
      FTeeboxInfoList[ATeeboxNo].ErrorCd := 8; //통신이상
      FTeeboxInfoList[ATeeboxNo].ErrorCd2 := '8'; //통신이상
    end;
  end
  else
  begin
    FTeeboxInfoList[ATeeboxNo].ErrorCnt := 0;
    FTeeboxInfoList[ATeeboxNo].ErrorYn := 'N';
  end;
end;

procedure TTeebox.SetTeeboxErrorCntModen(AIndex: Integer; ATeeboxNo: Integer; AError: String);
var
  sLogMsg: String;
begin
  if FTeeboxInfoList[ATeeboxNo].UseStatus = '8' then
  begin
    sLogMsg := 'UseStatus = 8 : ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
    Global.Log.LogRetryWriteModen(AIndex, sLogMsg);
    Exit;
  end;

  if AError = 'Y' then
  begin
    FTeeboxInfoList[ATeeboxNo].ErrorCnt := FTeeboxInfoList[ATeeboxNo].ErrorCnt + 1;
    if FTeeboxInfoList[ATeeboxNo].ErrorCnt > 2 then
    begin
      if FTeeboxInfoList[ATeeboxNo].ErrorYn = 'N' then
      begin
        sLogMsg := 'ErrorCnt 3 / ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm;
        Global.Log.LogRetryWriteModen(AIndex, sLogMsg);
      end;

      FTeeboxInfoList[ATeeboxNo].ErrorYn := 'Y';
      FTeeboxInfoList[ATeeboxNo].UseStatus := '9';
      FTeeboxInfoList[ATeeboxNo].ErrorCd := 8; //통신이상
      FTeeboxInfoList[ATeeboxNo].ErrorCd2 := '8'; //통신이상
    end;
  end
  else
  begin
    FTeeboxInfoList[ATeeboxNo].ErrorCnt := 0;
    FTeeboxInfoList[ATeeboxNo].ErrorYn := 'N';
  end;
end;

function TTeebox.ResetTeeboxRemainMinAdd(ATeeboxNo, ADelayTm: Integer; ATeeboxNm: String): Boolean;
var
  sResult: String;
  sDate, sStr: String;
  sDateTime: String; //볼회수시작시간
begin
  //2020-06-29 딜레이체크
  if ADelayTm = 0 then
    Exit;

  if ADelayTm > 20 then
  begin
    sStr := 'ADelayTm > 20 : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + IntToStr(ADelayTm);
    Global.Log.LogReserveWrite('ResetTeeboxReserveDateAdd : ' + sStr);
    Exit;
  end;

  sDate := formatdatetime('YYYYMMDD', Now);

  if Global.ADConfig.StoreCode = 'AC001' then //조광
  begin
    if ATeeboxNo = 0 then
    begin
      // MODENYJ 처럼 AD 자체 시간 계산일 경우  배정시간추가 내용 DB도 저장
      sResult := Global.XGolfDM.SetSeatReserveUseMinAdd(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm));
      sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm);
      Global.Log.LogReserveWrite('ResetTeeboxUseMinAdd : ' + sStr);
    end;
  end;

  //2021-06-24 한강, 볼회수중에 배정요청한 경우 DB 예약시간 미변경 조치
  //sResult := Global.XGolfDM.SetSeatReserveTmChange(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm));
  //sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm);
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
  { 보류
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

  ResetTeeboxReserveMinAddJMS(ATeeboxNo, ADelayTm);
end;

function TTeebox.ResetTeeboxReserveMinAddJMS(ATeeboxNo, ADelayTm: Integer): Boolean;
var
  sResult: String;
  sDate, sStr: String;
  I: integer;
  tmReserve: TDateTime;
begin
  if ADelayTm = 0 then
    Exit;

  if FTeeboxReserveList[ATeeboxNo].ReserveList.Count = 0 then
    Exit;

  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    tmReserve := IncMinute(DateStrToDateTime3( TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate ), ADelayTm);
    //sDate := formatdatetime('YYYYMMDDHHNNSS', tmReserve);
    sDate := formatdatetime('YYYYMMDDHHNN00', tmReserve); //2021-06-11
    TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate := sDate;
  end;

  sDate := formatdatetime('YYYYMMDD', Now);
  //sResult := Global.XGolfDM.SetSeatReserveTmChange(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm));
  sResult := Global.XGolfDM.SetSeatReserveTmChange(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, IntToStr(ADelayTm), '');
  sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' + sDate + ' / ' + IntToStr(ADelayTm);
  Global.Log.LogReserveWrite('ResetTeeboxRemainMinAdd : ' + sStr);

end;

procedure TTeebox.TeeboxStatusChk;
var
  nTeeboxNo: Integer;
  sStr, sEndTy, sChange, sResult, sLog: String;
  I, nNN: Integer;
  sNN: String;

  tmNowEnd, tmNowEndTemp: TDateTime;
  nTemp: Integer;

  //기기고장 발생여부
  bTeeboxError: Boolean;
begin

  //2020-08-13
  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sLog := 'SeatReserveUse SeatStatusChk!';
    Global.Log.LogReserveDelayWrite(sLog);

    sleep(50);
  end;

  FTeeboxStatusUse := True;

  //기기고장 발생,해제시 상태 파트너센터 상태 업데이트
  bTeeboxError := False;

  for nTeeboxNo := 1 to FTeeboxLastNo do
  begin

    if Global.ADConfig.ProtocolType <> 'MODEN' then
    begin
      if FTeeboxInfoList[nTeeboxNo].ComReceive = 'N' then
        continue;
    end;

    //2020-12-17 빅토리아 추가
    if FTeeboxInfoList[nTeeboxNo].ControlYn <> 'Y' then
      continue;

    // DB저장: 타석기상태(시간,상태,볼수)
    if (FTeeboxInfoList[nTeeboxNo].UseStatusPre = '9') or (FTeeboxInfoList[nTeeboxNo].UseStatus = '9') then
    begin

      if FTeeboxInfoList[nTeeboxNo].UseStatusPre <> FTeeboxInfoList[nTeeboxNo].UseStatus then
      begin

        //2020-11-05 기기고장 30초 이상유지시 문자발송
        if (global.adconfig.ErrorSms = 'Y') or ((global.Store.ACS = 'Y') and (global.Store.ACS_1_Yn = 'Y')) then
        begin

          if FTeeboxInfoList[nTeeboxNo].UseStatus = '9' then
          begin
            FTeeboxInfoList[nTeeboxNo].PauseTime := now;
            FTeeboxInfoList[nTeeboxNo].SendSMS := 'N';
            FTeeboxInfoList[nTeeboxNo].SendACS := 'N';
            sStr := 'No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' cd: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd);
            Global.Log.LogReserveWrite('PauseTime : ' + sStr);
          end;

        end;

        //2021-05-11 점검중일경우 기기고장으로 변경하지 않음
        if FTeeboxInfoList[nTeeboxNo].UseStatusPre <> '8' then //점검
        //Global.XGolfDM.SeatStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );
          Global.XGolfDM.TeeboxErrorStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

        //2021-01-02 로그추가
        if FTeeboxInfoList[nTeeboxNo].UseStatusPre <> '8' then //점검
        begin
          sStr := 'Error No: ' + IntToStr(nTeeboxNo) + ' / ' + FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  'ErrorCd : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].UseStatusPre + ' -> ' + FTeeboxInfoList[nTeeboxNo].UseStatus;
          Global.Log.LogWrite(sStr);
        end;

        FTeeboxInfoList[nTeeboxNo].UseStatusPre := FTeeboxInfoList[nTeeboxNo].UseStatus;

        //2020-11-05 에러발생히스토리용
        bTeeboxError := True;
      end;

      //2020-11-05 기기고장 1분 이상유지시 문자발송
      if (global.adconfig.ErrorSms = 'Y') or ((global.Store.ACS = 'Y') and (global.Store.ACS_1_Yn = 'Y')) then
      begin

        if (FTeeboxInfoList[nTeeboxNo].UseStatusPre = '9') and (FTeeboxInfoList[nTeeboxNo].UseStatus = '9') then
        begin

          nTemp := SecondsBetween(FTeeboxInfoList[nTeeboxNo].PauseTime, now);

          if nTemp > 30 then //30초이상 기기고장 유지면
          begin
            if (global.adconfig.ErrorSms = 'Y') then
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

          if nTemp > global.Store.ACS_1 then //30초이상 기기고장 유지면
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

      end;

    end;

    if FTeeboxInfoList[nTeeboxNo].RemainMinPre = FTeeboxInfoList[nTeeboxNo].RemainMinute then
    begin
      if (FTeeboxInfoList[nTeeboxNo].RemainMinute = FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) and
         (FTeeboxInfoList[nTeeboxNo].UseStatus = '1') then
      begin

      end
      else
        Continue;
    end
    else
    //if FTeeboxInfoList[nSeatNo].RemainMinute <> ATeeboxInfo.RemainMinute then
    begin
      //Log
      sStr := IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' [ ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' ] ' +
              FTeeboxInfoList[nTeeboxNo].DeviceId + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre) + ' <> ' + IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
      Global.Log.LogMonWrite(sStr);
    end;

    //남은시간증가
    if (FTeeboxInfoList[nTeeboxNo].UseStatus = '1') and
       (FTeeboxInfoList[nTeeboxNo].RemainMinPre < FTeeboxInfoList[nTeeboxNo].RemainMinute) and
       (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0 ) then
    begin
      //2020-08-07 적용: 타석기시간증가 복구 - 장한평점만 적용
      if (Global.ADConfig.ProtocolType = 'ZOOM') or
         (Global.ADConfig.StoreCode = 'A8001') or //2021-04-13 쇼골프
         (Global.ADConfig.ProtocolType = 'MODEN') then //2021-03-19
      begin

        //쇼골프 로그 확인용 2021-06-01
        if Global.ADConfig.StoreCode = 'A8001' then
        begin
          sStr := '타석기 증가 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre) + ' -> ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute) + ' : ChangeMin ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ChangeMin);
          Global.Log.LogReserveWrite(sStr);
        end;

        //시간변경에 의한 잔여시간 변경인지 확인
        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ChangeMin = 0) or
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ChangeMin <> FTeeboxInfoList[nTeeboxNo].RemainMinute) then
        begin

          //타석기에서 시간이 증가된 경우(타석기 오류))
          sStr := '타석기 복구(증가) : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre) + ' -> ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute) + ' : ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre);
          Global.Log.LogReserveWrite(sStr);

          //타석기 복구 재배정
          SetTeeboxCtrl(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinPre, FTeeboxInfoList[nTeeboxNo].RemainBall);

          Continue;
        end;
      end;

      //종료시간이 존재하면 배정종료된 타석...수동으로 타석 시간 등록시 종료된 배정이 가동중인 배정으로 변경됨
      // 들어간 시간만큼 현재 시간으로 시작처리되서 상태값이 1로 변경
      //FSeatInfoList[nSeatNo].SeatReserve.ReserveEndDate := '';
      ResetTeeboxRemainMinAdd(nTeeboxNo, (FTeeboxInfoList[nTeeboxNo].RemainMinute - FTeeboxInfoList[nTeeboxNo].RemainMinPre) + 1, FTeeboxInfoList[nTeeboxNo].TeeboxNm);
    end;

    if (FTeeboxInfoList[nTeeboxNo].RemainMinPre = 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) then
    begin

      if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo = '') or
         (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate <> '') then
      begin

        if FTeeboxInfoList[nTeeboxNo].UseStatus = '8' then
        begin
          sStr := '수동초기화(점검) : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm;
          Global.Log.LogReserveWrite(sStr);
        end
        else if FTeeboxInfoList[nTeeboxNo].UseStatus = 'M' then //2021-08-18 그린필드
        begin
          sStr := '수동초기화(수동) : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
          Global.Log.LogReserveWrite(sStr);
        end
        {
        else if Global.ADConfig.StoreCode = 'B2001' then //2021-08-18 그린필드
        begin
          Global.XGolfDM.TeeboxErrorUpdate('AD', IntToStr(nTeeboxNo), '8');
          Global.Teebox.TeeboxDeviceCheck(nTeeboxNo, '8');

          sStr := '수동초기화(수동/점검) : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' + IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
          Global.Log.LogReserveWrite(sStr);
        end
        }
        else
        begin

          //2020-05-27 적용: 수동초기화
          sStr := '수동초기화 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FormatDateTime('YYYYMMDDhhnnss', FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime);
          Global.Log.LogReserveWrite(sStr);

          SetTeeboxCtrl(nTeeboxNo, 'S1', 0, 9999);
        end;

        Continue;
      end
      else
      begin

        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := '';
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'N';

        sStr := '배정시작 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].UseStatus + ' / ' + inttostr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
        Global.Log.LogReserveWrite(sStr);

      end;
    end;

    if (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
       //(FSeatInfoList[nTeeboxNo].SeatReserve.PrepareEndTime < Now) and //2020-06-15 양평추가로 변경
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') and
       ((FTeeboxInfoList[nTeeboxNo].UseStatus = '1') or (Global.ADConfig.ProtocolType = 'MODEN'))
    then
    begin

      if (Global.ADConfig.ProtocolType = 'ZOOM') and (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareEndTime > Now) then
      begin
        //
      end
      else
      begin

        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
        if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> '' then
        begin
          //FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnn00', Now); //2021-06-11
          Global.SetADConfigBallReserve(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);

          sStr := '배정구동 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
          Global.Log.LogReserveWrite(sStr);

          if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') then
          begin
            //2021-04-13 11:46:35.417# SendData : FCurCmdDataIdx 2 / 174 / 0371009999077
            //2021-04-13 11:46:35.729# Cancel no: 51 / 37 / 202104130082
            //2021-04-13 11:46:35.745# SendData : FCurCmdDataIdx 2 / 175 / 0370000000949
            // 배정후 바로 취소하는 경우 배정된 응답값 온후 취소응답값이 들어옴.

            sStr := '배정구동 DB저장 취소';
            Global.Log.LogReserveWrite(sStr);
          end
          else
          begin

            //한번더 저장
            Global.SetADConfigBallReserve(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);

            // 2021-11-02 타석테이블의 정보 갱신이 늦어 0으로 표시되는 경우 있음.
            Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall, FTeeboxInfoList[nTeeboxNo].UseStatus, '');

            // DB/Erp저장: 시작시간
            sResult := Global.TcpServer.SetApiTeeBoxReg(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                           FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);

            //2020-07-13 v15 시작시간기준 다음예약건 예약시간 변경
            ResetReserveDateTime(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm);

            //좌우타석일 경우 한쪽만 작동할수 있음
            if Global.ADConfig.ProtocolType = 'ZOOM' then
            begin
              if FTeeboxInfoList[nTeeboxNo].TeeboxZoneCode = 'L' then
              begin
                SetTeeboxCtrl(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignBalls);
                sStr := '좌우타석 배정구동확인용 제어 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                        FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                        IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
                Global.Log.LogReserveWrite(sStr);
              end;
            end;

            if Global.ADConfig.StoreCode = 'A5001' then //송도
              FTeeboxInfoList[nTeeboxNo].UseLStatus := '0';
          end;

        end;

      end;
    end;

    if (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) then
    begin
      //2020-07-03 양평 타석기에서 종료시키는 경우가 있음. 예외처리함
      if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') or
         (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') or
         (FTeeboxInfoList[nTeeboxNo].RemainMinPre < 3) or
         //(Global.ADConfig.ProtocolType = 'ZOOM1') then
         (Global.ADConfig.StoreCode = 'A2001') then //양평 //유명 초기화복구 적용 2020-10-30
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '배정종료 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        sEndTy := '2';
        if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') then //취소인경우 K410_TeeBoxReserved 통해 ERP 전송
          sEndTy := '5'
        else
        begin
          // DB/Erp저장: 종료시간
          sResult := Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, sEndTy);
          {
          if sResult = '' then
          begin
            SetLength(FTeeboxEndDBError, Length(FTeeboxEndDBError) + 1);
            FTeeboxEndDBError[Length(FTeeboxEndDBError) - 1].ReserveNo := FSeatInfoList[nTeeboxNo].SeatReserve.ReserveNo;
            FTeeboxEndDBError[Length(FTeeboxEndDBError) - 1].ReserveEndDate := FSeatInfoList[nTeeboxNo].SeatReserve.ReserveEndDate;
            FTeeboxEndDBError[Length(FTeeboxEndDBError) - 1].ReserveYn := sEndTy;
          end;
          }
        end;

        //if Global.ADConfig.ProtocolType = 'JEHU435' then
        {$IFDEF RELEASE}
        //if (Global.ADConfig.StoreCode = 'A1001') then
        //if (Global.ControlComPortHeatMonThread <> nil) or //스타
        if (Global.TcpThreadHeat <> nil) then //그린필
          Global.CtrlHeatSendBuffer(nTeeboxNo, '0', '0');
        {$ENDIF}
        {$IFDEF DEBUG}
        {$ENDIF}

        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') then  //예약대기상태
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo := '';

        if Global.ADConfig.StoreCode = 'A5001' then //송도
          FTeeboxInfoList[nTeeboxNo].UseLStatus := '0';
      end
      else
      begin
        if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> '' then
        begin
        //타석기에서 시간이 초기화 된 경우(타석기 고장으로 인한 초기화, 점검/볼회수로 인해 초기화)
        sStr := '타석기 대기 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].UseCancel + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre) + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute)  + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);
        //타석기 대기 : 32 / 41 / T00012908 / 70 / N / 8 / 0 / 2019-12-13 21:58:18 /
        end;

        //타석기 대기 재배정
        if FTeeboxInfoList[nTeeboxNo].UseStatus = '9' then
        begin
          sStr := '타석기 대기 제어 취소(고장): ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm;
          Global.Log.LogReserveWrite(sStr);

          Continue;
        end
        //2021-06-16 송도, 점검시 제어취소
        else if FTeeboxInfoList[nTeeboxNo].UseStatus = '8' then
        begin
          sStr := '타석기 대기 제어 취소(점검): ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm;
          Global.Log.LogReserveWrite(sStr);

          Continue;
        end
        { //캐슬렉스 수동제어시...보류
        else if FSeatInfoList[nTeeboxNo].SeatReserve.ReserveNo = '' then
        begin
          sStr := '타석기 미배정 대기 제어 취소: ' + IntToStr(FSeatInfoList[nTeeboxNo].SeatNo) + ' / ' +
                FSeatInfoList[nTeeboxNo].SeatNm;
          Global.LogReserveWrite(sStr);
        end
        }
        else
        begin
          if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> '' then
          //SetSeatCtrl(nTeeboxNo, 'S1' , FSeatInfoList[nTeeboxNo].RemainMinPre, FSeatInfoList[nTeeboxNo].RemainBall);
            SetTeeboxCtrl(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinPre, 9999);

          Continue;
        end;

        //Continue;
      end;

    end;

    //2020-05-27 적용: 타석기시간감소 복구
    if (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) then
    begin

      //2020-08-10 10분에서 5분으로 변경
      //if (FSeatInfoList[nTeeboxNo].RemainMinPre - FSeatInfoList[nTeeboxNo].RemainMinute) >= 10 then
      if (FTeeboxInfoList[nTeeboxNo].RemainMinPre - FTeeboxInfoList[nTeeboxNo].RemainMinute) >= 5 then
      begin
        //시간변경에 의한 잔여시간 변경인지 확인
        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ChangeMin = 0) or
           (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ChangeMin <> FTeeboxInfoList[nTeeboxNo].RemainMinute) then
        begin

          tmNowEnd := IncMinute(DateStrToDateTime3( FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate ), FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin);
          tmNowEndTemp := IncMinute(now, FTeeboxInfoList[nTeeboxNo].RemainMinute);
          nTemp := MinutesBetween(tmNowEnd, tmNowEndTemp);

          if nTemp >= 5 then
          begin
            //2021-06-16 송도, 점검시 제어취소
            if FTeeboxInfoList[nTeeboxNo].UseStatus = '8' then //점검
            begin
              FTeeboxInfoList[nTeeboxNo].RemainMinPre := FTeeboxInfoList[nTeeboxNo].RemainMinute;

              sStr := '타석기 복구취소(감소/점검) : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                    FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                    FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                    IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre) + ' -> ' +
                    IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute) + ' : ' +
                    IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre);
              Global.Log.LogReserveWrite(sStr);

              Continue;
            end;

            //타석기에서 시간이 감소된 경우(타석기 오류))
            sStr := '타석기 복구(감소) : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                  FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre) + ' -> ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute) + ' : ' +
                  IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre);
            Global.Log.LogReserveWrite(sStr);

            //타석기 복구 재배정
            SetTeeboxCtrl(nTeeboxNo, 'S1' , FTeeboxInfoList[nTeeboxNo].RemainMinPre, FTeeboxInfoList[nTeeboxNo].RemainBall);

            Continue;
          end
          else
          begin
            //타석기에서 시간이 감소된 경우(타석기 오류))
            sStr := '타석기 복구취소(감소) : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre) + ' -> ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute) + ' : ' +
                formatdatetime('YYYYMMDDHHNNSS', tmNowEnd) + ' -> ' + formatdatetime('YYYYMMDDHHNNSS', tmNowEndTemp);
            Global.Log.LogReserveWrite(sStr);
          end;

        end;

      end;
    end;

    //FSeatInfoList[nTeeboxNo].RemainMinPre := FSeatInfoList[nTeeboxNo].RemainMinute;

    // DB저장: 타석기상태(시간,상태,볼수)
    //2020-06-29 errorcd 추가
    if FTeeboxInfoList[nTeeboxNo].RemainMinPre <> FTeeboxInfoList[nTeeboxNo].RemainMinute then
      Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

    FTeeboxInfoList[nTeeboxNo].RemainMinPre := FTeeboxInfoList[nTeeboxNo].RemainMinute;
  end;

  //2020-11-05 기기고장 발생,해제 파트너센터 상태업데이트
  if bTeeboxError = True then
    Global.TcpServer.SetApiTeeBoxStatus;

  Sleep(10);
  FTeeboxStatusUse := False;
end;


procedure TTeebox.TeeboxStatusChkJMS;
var
  nTeeboxNo: Integer;
  sStr, sEndTy, sChange, sResult, sLog: String;
  I, nNN, nTmTemp, nTemp: Integer;
  tmTempS: TDateTime;
begin

  //2020-08-13
  while True do
  begin
    if FTeeboxReserveUse = False then
      Break;

    sLog := 'SeatReserveUse SeatStatusChkJMS!';
    Global.Log.LogReserveDelayWrite(sLog);

    sleep(50);
  end;

  FTeeboxStatusUse := True;

  for nTeeboxNo := 1 to FTeeboxLastNo do
  begin

    if FTeeboxInfoList[nTeeboxNo].ComReceive = 'N' then
      continue;

    if FTeeboxInfoList[nTeeboxNo].UseStatus = '7' then
      continue;

    // DB저장: 타석기상태(시간,상태,볼수)
    if (FTeeboxInfoList[nTeeboxNo].UseStatusPre = '9') or (FTeeboxInfoList[nTeeboxNo].UseStatus = '9') then
    begin
      if FTeeboxInfoList[nTeeboxNo].UseStatusPre <> FTeeboxInfoList[nTeeboxNo].UseStatus then
      begin

        //2020-08-26 v26 기기고장시 시간보상->2020-09-15 위치변경
        //if Global.ADConfig.ProtocolType = 'JMS' then //2021-05-28 조광제외-이종섭과장 -> 2023-05-18 조광적용-이종섭차장
        begin
          if FTeeboxInfoList[nTeeboxNo].UseStatus = '9' then
          begin
            FTeeboxInfoList[nTeeboxNo].PauseTime := now;
            sStr := 'No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' cd: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd);
            Global.Log.LogReserveWrite('PauseTime : ' + sStr);
          end;

          if FTeeboxInfoList[nTeeboxNo].UseStatusPre = '9' then
          begin
            FTeeboxInfoList[nTeeboxNo].RePlayTime := now;
            sStr := 'No: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' cd: ' + IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd);
            Global.Log.LogReserveWrite('RePlayTime : ' + sStr);

            nTemp := MinutesBetween(FTeeboxInfoList[nTeeboxNo].PauseTime, FTeeboxInfoList[nTeeboxNo].RePlayTime);
            if nTemp > 0 then
            begin
              ResetTeeboxRemainMinAddJMS(FTeeboxInfoList[nTeeboxNo].TeeboxNo, nTemp);
            end;

          end;

          Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );
        end;
        {
        else
        begin
          if FTeeboxInfoList[nTeeboxNo].UseStatusPre <> '8' then //점검
            Global.XGolfDM.TeeboxErrorStatusUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );
        end;  }

        FTeeboxInfoList[nTeeboxNo].UseStatusPre := FTeeboxInfoList[nTeeboxNo].UseStatus;
      end;
    end;

    //시간계산
    if (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'Y') and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate <> '') and
       (FTeeboxInfoList[nTeeboxNo].UseStatus <> '9') then
    begin
      //if (FSeatInfoList[nTeeboxNo].UseStatus = '1') or (FSeatInfoList[nTeeboxNo].UseLStatus = '1') then
      begin
        //sNN := FormatDateTime('NN', now - DateStrToDateTime3(FSeatInfoList[nTeeboxNo].SeatReserve.ReserveStartDate));
        tmTempS := DateStrToDateTime3(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);
        nNN := MinutesBetween(now, tmTempS);

        nTmTemp := FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin - nNN;
        if nTmTemp < 0 then
          nTmTemp := 0;
        FTeeboxInfoList[nTeeboxNo].RemainMinute := nTmTemp;

        //Global.Log.LogReserveWrite('4');
      end;
    end;

    if (FTeeboxInfoList[nTeeboxNo].RemainMinPre = 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
       (FTeeboxInfoList[nTeeboxNo].UseStatus = '0') and (FTeeboxInfoList[nTeeboxNo].UseRStatus = '1') then
    begin

      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := '';
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'N';

      sStr := '배정시작 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
              IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
              FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
              FTeeboxInfoList[nTeeboxNo].UseStatus + ' / ' + inttostr(FTeeboxInfoList[nTeeboxNo].RemainMinute);
      Global.Log.LogReserveWrite(sStr);
    end;

    if (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) and
       (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') and
       ((FTeeboxInfoList[nTeeboxNo].UseStatus = '1') or (FTeeboxInfoList[nTeeboxNo].UseLStatus = '1'))
    then
    begin
      //Global.Log.LogReserveWrite('5');
      FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn := 'Y';
      if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo <> '' then
      begin
        //FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnnss', Now);
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate := formatdatetime('YYYYMMDDhhnn00', Now); //2021-06-11
        Global.SetADConfigBallReserve(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);

        sStr := '배정구동 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate;
        Global.Log.LogReserveWrite(sStr);

        // DB저장, 0분 표시되는 경우 있음.  2023-05-18
        if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '8') and (FTeeboxInfoList[nTeeboxNo].UseStatus <> '9') then //점검, 고장
          Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, 9999, '1', '' );

        //한번더 저장
        Global.SetADConfigBallReserve(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);

        // DB/Erp저장: 시작시간
        sResult := Global.TcpServer.SetApiTeeBoxReg(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                       FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate);

        //2020-07-13 v15 시작시간기준 다음예약건 예약시간 변경
        //ResetReserveDateTime(nTeeboxNo, FSeatInfoList[nTeeboxNo].SeatNm);

        //히터- 조광
        if Global.ADConfig.HeatTcpPort <> 0 then
        begin
          if Global.ADConfig.HeatAuto = '1' then
          begin
            Global.CtrlHeatSendBuffer(nTeeboxNo, '1', '1');
          end;
        end;

      end;

    end;

    //if (FSeatInfoList[nTeeboxNo].RemainMinPre > 0) and (FSeatInfoList[nTeeboxNo].RemainMinute = 0) and
    //   (FSeatInfoList[nTeeboxNo].UseStatus = '0') then
    if (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) and (FTeeboxInfoList[nTeeboxNo].RemainMinute = 0) then
    begin
      //2020-07-03 양평 타석기에서 종료시키는 경우가 있음. 예외처리함
      if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') or
         (FTeeboxInfoList[nTeeboxNo].UseClose = 'Y') or
         (FTeeboxInfoList[nTeeboxNo].RemainMinPre < 3) then
      begin
        FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate := formatdatetime('YYYYMMDDhhnnss', Now);

        sStr := '배정종료 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.PrepareStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);

        sEndTy := '2';
        if (FTeeboxInfoList[nTeeboxNo].UseCancel = 'Y') then //취소인경우 K410_TeeBoxReserved 통해 ERP 전송
          sEndTy := '5'
        else
        begin
          // DB/Erp저장: 종료시간
          sResult := Global.TcpServer.SetApiTeeBoxEnd(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].TeeboxNm, FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo,
                                         FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate, sEndTy);
          {
          if sResult = '' then
          begin
            SetLength(FTeeboxEndDBError, Length(FTeeboxEndDBError) + 1);
            FTeeboxEndDBError[Length(FTeeboxEndDBError) - 1].ReserveNo := FSeatInfoList[nTeeboxNo].SeatReserve.ReserveNo;
            FTeeboxEndDBError[Length(FTeeboxEndDBError) - 1].ReserveEndDate := FSeatInfoList[nTeeboxNo].SeatReserve.ReserveEndDate;
            FTeeboxEndDBError[Length(FTeeboxEndDBError) - 1].ReserveYn := sEndTy;
          end;
          }
        end;

        //히터- 조광
        if Global.ADConfig.HeatTcpPort <> 0 then
        begin
          Global.CtrlHeatSendBuffer(nTeeboxNo, '0', '0');
        end;

        if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveYn = 'N') then  //예약대기상태
          FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo := '';

        FTeeboxInfoList[nTeeboxNo].UseLStatus := '0';
      end
      else
      begin
        //타석기에서 시간이 초기화 된 경우(타석기 고장으로 인한 초기화, 점검/볼회수로 인해 초기화)
        sStr := '타석기 대기 : ' + IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxNo) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxNm + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].TeeboxReserve.AssignMin) + ' / ' +
                FTeeboxInfoList[nTeeboxNo].UseCancel + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinPre) + ' / ' +
                IntToStr(FTeeboxInfoList[nTeeboxNo].RemainMinute)  + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveStartDate + ' / ' +
                FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate;
        Global.Log.LogReserveWrite(sStr);
        //타석기 대기 : 32 / 41 / T00012908 / 70 / N / 8 / 0 / 2019-12-13 21:58:18 /

        //타석기 대기 재배정
        //SetSeatCtrl(nTeeboxNo, 'S1' , FSeatInfoList[nTeeboxNo].RemainMinPre, FSeatInfoList[nTeeboxNo].RemainBall);
        //SetSeatCtrl(nTeeboxNo, 'S1' , FSeatInfoList[nTeeboxNo].RemainMinPre, 9999);

        Continue;
      end;

    end;

    //FSeatInfoList[nTeeboxNo].RemainMinPre := FSeatInfoList[nTeeboxNo].RemainMinute;

    // DB저장: 타석기상태(시간,상태,볼수)
    //2020-06-29 errorcd 추가
    if FTeeboxInfoList[nTeeboxNo].RemainMinPre <> FTeeboxInfoList[nTeeboxNo].RemainMinute then
      Global.XGolfDM.TeeboxInfoUpdate(nTeeboxNo, FTeeboxInfoList[nTeeboxNo].RemainMinute, FTeeboxInfoList[nTeeboxNo].RemainBall, FTeeboxInfoList[nTeeboxNo].UseStatus, IntToStr(FTeeboxInfoList[nTeeboxNo].ErrorCd) );

    FTeeboxInfoList[nTeeboxNo].RemainMinPre := FTeeboxInfoList[nTeeboxNo].RemainMinute;
  end;

  Sleep(10);
  FTeeboxStatusUse := False;
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

      //2020-12-17 반자동
      if FTeeboxInfoList[nTeeboxNo].ControlYn <> 'N' then
      begin
        if FTeeboxInfoList[nTeeboxNo].ComReceive <> 'Y' then
          Continue;
      end;

      if (FTeeboxInfoList[nTeeboxNo].RemainMinPre > 0) or (FTeeboxInfoList[nTeeboxNo].UseStatus <> '0') then
        Continue;

      //타석기 배정상태 확인
      //if FSeatInfoList[nTeeboxNo].SeatReserve.ReserveNo = '' then
      //  Continue;

      if FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
        Continue;

      //2020-05-29 조건추가, 2021-07-21 조건수정
      if (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveDate <> '') and (FTeeboxInfoList[nTeeboxNo].TeeboxReserve.ReserveEndDate = '') then
        Continue;

      if FTeeboxReserveList[nTeeboxNo].CancelYn = 'Y' then //예약삭제중일 경우
      begin
        while True do
        begin
          if FTeeboxReserveList[nTeeboxNo].CancelYn <> 'Y' then
            Break;
        end;
      end;

      if FTeeboxReserveList[nTeeboxNo].ReserveList.Count = 0 then
        Continue;

      nIndex := 0;

      //2021-07-21 예약시간되기전에 예약내역으로 들어가지 않도록 처리
      if TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate > formatdatetime('YYYYMMDDhhnnss', Now) then
        Continue;

      SeatUseReserve.ReserveNo := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveNo;
      SeatUseReserve.UseStatus := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).UseStatus;
      SeatUseReserve.SeatNo := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).SeatNo);
      SeatUseReserve.UseMinute := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).UseMinute);
      SeatUseReserve.UseBalls := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).UseBalls);
      SeatUseReserve.DelayMinute := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).DelayMinute);
      SeatUseReserve.ReserveDate := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate;
      SeatUseReserve.StartTime := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).StartTime;
      SeatUseReserve.AssignYn := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).AssignYn;

      SetTeeboxReserveInfo(SeatUseReserve);


      TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).Free;
      FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex] := nil;
      FTeeboxReserveList[nTeeboxNo].ReserveList.Delete(nIndex);

    end;

  except
    on e: Exception do
    begin
       sLog := 'SeatReserveNextChk Exception : ' + e.Message;
       Global.Log.LogReserveWrite(sLog);
    end;
  end;

end;

function TTeebox.SetTeeboxReserveNext(AReserve: TSeatUseReserve): Boolean;
var
  nTeeboxNo: Integer;
  NextReserve: TNextReserve;
begin
  nTeeboxNo := AReserve.SeatNo;

  try
    NextReserve := TNextReserve.Create;
    NextReserve.ReserveNo := AReserve.ReserveNo;
    NextReserve.UseStatus := AReserve.UseStatus;
    NextReserve.SeatNo := IntToStr(AReserve.SeatNo);
    NextReserve.UseMinute := IntToStr(AReserve.UseMinute);
    NextReserve.UseBalls := IntToStr(AReserve.UseBalls);
    NextReserve.DelayMinute := IntToStr(AReserve.DelayMinute);
    NextReserve.ReserveDate := AReserve.ReserveDate;
    NextReserve.StartTime := AReserve.StartTime;
    NextReserve.AssignYn := AReserve.AssignYn;

    FTeeboxReserveList[nTeeboxNo].ReserveList.AddObject(NextReserve.SeatNo, TObject(NextReserve));
  finally
    //FreeAndNil(NextReserve);
  end;
end;

function TTeebox.SetTeeboxReserveNextCancel(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  rCancelList: TCancelList;
  I: Integer;
  nUntIn, nCnt: Integer;
  sResult, sLog, sDate: String;
begin
  nUntIn := 0;
  nCnt := FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1;

  FTeeboxReserveList[ATeeboxNo].CancelYn := 'Y';
  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    if AReserveNo = TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).Free;
      FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I] := nil;
      FTeeboxReserveList[ATeeboxNo].ReserveList.Delete(I);

      nUntIn := I;

      Break;
    end;
  end;
  FTeeboxReserveList[ATeeboxNo].CancelYn := 'N';

  if nUntIn < nCnt then
  begin
    //끼워넣기 대상이였던 배정 끼워넣기 항목Y 처리
    sResult := Global.XGolfDM.SeatUseCutInUseInsert(Global.ADConfig.StoreCode, AReserveNo);
    if sResult <> 'Success' then
      sLog := 'SeatUseCutInUseInsert Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + AReserveNo
    else
      sLog := 'SeatUseCutInUseInsert : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + AReserveNo;

    Global.Log.LogErpApiWrite(sLog);
  end;

  if nUntIn = nCnt then //마지막 배정예약
  begin
    if FTeeboxReserveList[ATeeboxNo].ReserveList.Count = 0 then //모든예약삭제
    begin
      sDate := FormatDateTime('YYYYMMDDhhnnss', Now);
    end
    else
    begin
      I := FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1;
      sDate := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate;
    end;

    sResult := Global.XGolfDM.SeatUseCutInUseListDelete(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate);
    if sResult <> 'Success' then
      sLog := 'SeatUseCutInUseListDelete Fail : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + sDate
    else
      sLog := 'SeatUseCutInUseListDelete : No ' + IntToStr(ATeeboxNo) + ' [ ' + FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' ] ' + sDate;

    Global.Log.LogErpApiWrite(sLog);
  end;

end;

function TTeebox.SetTeeboxReserveNextChange(ATeeboxNo: Integer; ASeatUseInfo: TSeatUseInfo): Boolean;
var
  I: Integer;
  NextReserve: TNextReserve;
begin

  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatUseInfo.ReserveNo = TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).DelayMinute := IntToStr(ASeatUseInfo.PrepareMin);
      TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).UseMinute := IntToStr(ASeatUseInfo.AssignMin);

      Break;
    end;
  end;

end;

function TTeebox.GetTeeboxReserveNextListCnt(ATeeboxNo: Integer): String;
begin
  Result := IntToStr(FTeeboxReserveList[ATeeboxNo].ReserveList.Count);
end;

function TTeebox.SetTeeboxReserveNextCutInCheck(ASeatReserveInfo: TSeatUseReserve): String;
var
  sStr: String;

  nTeeboxNo: Integer;
  I, nIndex: Integer;
  dtTmTemp: TDateTime;
  sTmTemp, sTmTempE: String;
  bCheck: Boolean;
begin
  Result := '';

  nTeeboxNo := ASeatReserveInfo.SeatNo;

  if FTeeboxReserveList[nTeeboxNo].ReserveList.Count = 0 then
  begin
    Result := '끼어넣기를 수행할 예약목록이 없습니다.';
    Exit;
  end;

  nIndex := 0;
  bCheck := False; //동일 예약시간 확인
  for I := 0 to FTeeboxReserveList[nTeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatReserveInfo.ReserveDate <= TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
    begin
      if ASeatReserveInfo.ReserveDate = TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
        bCheck := True;

      nIndex := I;
      Break;
    end;
  end;

  if bCheck = True then
  begin
    Result := '동일한 예약시간으로 예약된 배정이 있습니다.';
    Exit;
  end;

  if nIndex = 0 then //예약중 첫번째 이전
  begin
    //현재 운영중이면 종료시간 체크
    if (FTeeboxInfoList[nTeeboxNo].UseStatus <> '0') and (FTeeboxInfoList[nTeeboxNo].RemainMinute > 0) then
    begin
      dtTmTemp := IncMinute(Now, FTeeboxInfoList[nTeeboxNo].RemainMinute); //종료 예상시간
      sTmTemp := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);

      dtTmTemp := DateStrToDateTime3(ASeatReserveInfo.ReserveDate) + (((1/24)/60) * 5);
      sTmTempE := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);
      if sTmTemp > sTmTempE then //예상종료시간이 끼어넣을 (예약시간 + 5분) 보다 크면
      begin
        sStr := 'CutIn check : Fail Index=0 ' + IntToStr(nTeeboxNo) + ' / EndTm: ' + sTmTemp + ' > CutIn Reserve: ' + ASeatReserveInfo.ReserveDate;
        Global.Log.LogReserveWrite(sStr);

        Result := '타석종료시간이 예약시간보다 큽니다.';
        Exit;
      end;

    end;
  end
  else
  begin

    dtTmTemp := DateStrToDateTime3(ASeatReserveInfo.ReserveDate) + (((1/24)/60) * (ASeatReserveInfo.DelayMinute + ASeatReserveInfo.UseMinute));
    sTmTemp := FormatDateTime('YYYYMMDDhhnnss', dtTmTemp);

    if sTmTemp > TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate then
    begin
      sStr := 'CutIn check : Fail ' + IntToStr(nTeeboxNo) + ' / ' + ASeatReserveInfo.ReserveDate + ' - ' + sTmTemp + ' < ' +
              TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate;
      Global.Log.LogReserveWrite(sStr);

      Result := '끼어넣을 배정시간이 다음 예약건의 예약시간을 초과 합니다.';
      Exit;
    end;
  end;

  Result := 'success';
end;

function TTeebox.SetTeeboxReserveNextCutIn(ASeatReserveInfo: TSeatUseReserve): Boolean;
var
  sStr: String;

  nTeeboxNo: Integer;
  NextReserve: TNextReserve;
  I, nIndex: Integer;
begin
  Result := False;

  nTeeboxNo := ASeatReserveInfo.SeatNo;

  nIndex := 0;
  for I := 0 to FTeeboxReserveList[nTeeboxNo].ReserveList.Count - 1 do
  begin
    if ASeatReserveInfo.ReserveDate < TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[I]).ReserveDate then
    begin
      nIndex := I;

      Break;
    end;
  end;

  NextReserve := TNextReserve.Create;
  NextReserve.ReserveNo := ASeatReserveInfo.ReserveNo;
  NextReserve.UseStatus := ASeatReserveInfo.UseStatus;
  NextReserve.SeatNo := IntToStr(ASeatReserveInfo.SeatNo);
  NextReserve.UseMinute := IntToStr(ASeatReserveInfo.UseMinute);
  NextReserve.UseBalls := IntToStr(ASeatReserveInfo.UseBalls);
  NextReserve.DelayMinute := IntToStr(ASeatReserveInfo.DelayMinute);
  NextReserve.ReserveDate := ASeatReserveInfo.ReserveDate;
  NextReserve.StartTime := ASeatReserveInfo.StartTime;
  NextReserve.AssignYn := ASeatReserveInfo.AssignYn;

  FTeeboxReserveList[nTeeboxNo].ReserveList.InsertObject(nIndex, NextReserve.SeatNo, TObject(NextReserve));

  sStr := 'CutIn no: ' + IntToStr(nTeeboxNo) + ' / nIndex: ' + IntToStr(nIndex) + ' / ' + ASeatReserveInfo.ReserveNo;
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

function TTeebox.SetTeeboxHold(ATeeboxNo, AUserId: String; AUse: Boolean): Boolean;
var
  nTeeboxNo: Integer;
begin
  if ATeeboxNo = '-1' then
    Exit;

  nTeeboxNo := StrToInt(ATeeboxNo);
  FTeeboxInfoList[nTeeboxNo].HoldUse := AUse;
  FTeeboxInfoList[nTeeboxNo].HoldUser := AUserId;
end;

function TTeebox.GetTeeboxHold(ATeeboxNo, AUserId, AType: String): Boolean;
var
  nTeeboxNo: Integer;
begin
  nTeeboxNo := StrToInt(ATeeboxNo);

  //2020-05-27 적용: Insert
  if AType = 'Insert' then
  begin
    if FTeeboxInfoList[nTeeboxNo].HoldUser = AUserId then
      Result := False //홀드등록자가 동일하면
    else
      Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end
  {
  else
  begin
    if FTeeboxInfoList[nTeeboxNo].HoldUser <> AUserId then
    begin
      Result := False;
      Exit;
    end;

    Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end;
  }
  else if AType = 'Delete' then //2022-07-20
  begin
    if FTeeboxInfoList[nTeeboxNo].HoldUser = AUserId then
      Result := True //홀드등록자가 동일하면
    else
      Result := False;
  end
  else
  begin
    Result := FTeeboxInfoList[nTeeboxNo].HoldUse;
  end;

end;

function TTeebox.GetTeeboxReserveNextView(ATeeboxNo: Integer): String;
var
  I: integer;
  sStr: String;
begin
  sStr := '';
  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    sStr := sStr + IntToStr(I) + ': ';
    sStr := sStr + TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo + ' / ' +
          TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate + ' / ' +
          TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).DelayMinute  + ' / ' +
          TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).UseMinute  + ' / ' +
          TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).AssignYn;

    sStr := sStr + #13#10;
  end;

  Result := sStr;
end;

{
function TTeebox.SetTeeboxReservePrepare(ATeeboxNo: Integer): String;
begin
  //if Global.ADConfig.ProtocolType = 'JEHU435' then
  if (Global.ADConfig.StoreCode = 'A1001') then
  begin
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareStartDate := FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveDate;
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareStartDate);
  end
  else
  begin
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareStartDate := FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveDate;
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime := DateStrToDateTime3(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareStartDate) +
                                                         (((1/24)/60) * FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareMin);
  end;
end;
}

function TTeebox.GetTeeboxReserveLastTime(ATeeboxNo: String): String; //2020-05-31 예약시간 검증
var
  nIdx, nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sReserveDate, sStr, sLog: String;
  DelayMin, UseMin: Integer;
begin
  sStr := '';

  nTeeboxNo := StrToInt(ATeeboxNo);
  if FTeeboxReserveList[nTeeboxNo].ReserveList.Count = 0 then
  begin
    Result := sStr;
    Exit;
  end;

  nIdx := FTeeboxReserveList[nTeeboxNo].ReserveList.Count - 1;
  sReserveDate := TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIdx]).ReserveDate;
  DelayMin := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIdx]).DelayMinute);
  UseMin := StrToInt(TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIdx]).UseMinute);

  ReserveTm := DateStrToDateTime3(sReserveDate) + ( ((1/24)/60) * ( DelayMin + UseMin ) );

  //sStr := FormatDateTime('YYYYMMDDhhnnss', ReserveTm);
  sStr := FormatDateTime('YYYYMMDDhhnn00', ReserveTm); //2021-06-11

  Result := sStr;
end;

function TTeebox.GetTeeboxNowReserveLastTime(ATeeboxNo: String): String; //2021-04-19 현시간 예약시간 검증
var
  nIdx, nTeeboxNo: integer;
  ReserveTm: TDateTime;
  sStartDate, sStr, sLog: String;
  DelayMin, UseMin: Integer;
begin
  sStr := '0';

  nTeeboxNo := StrToInt(ATeeboxNo);
  if FTeeboxReserveList[nTeeboxNo].ReserveList.Count = 0 then
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
    sStr := GetTeeboxReserveLastTime(ATeeboxNo);
    sLog := 'GetTeeboxReserveLastTime : ' + ATeeboxNo;
    Global.Log.LogErpApiWrite(sLog);
  end;

  Result := sStr;
end;

//타석기 구동확인용-> ERP 전송
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

    //2021-06-10 응답대기로 배정지연발생->배정표미출력됨. Timeout 설정. 타석기AD상태용이라 우선 적용함.
    //sResult := Global.Api.SetErpApiNoneData(sJsonStr, 'K710_TeeboxTime', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);
    sResult := Global.Api.SetErpApiK710TeeboxTime(sJsonStr, 'K710_TeeboxTime', Global.ADConfig.ApiUrl, Global.ADConfig.ADToken);

    {
    if StrPos(PChar(sResult), PChar('Exception')) <> nil then
      Global.ErpApiLogWrite(sResult);
    }

    //'{"result_cd":"0000","result_msg":"처리가 되었습니다.","result_data":{"chg_date":"2021-02-01 17:52:53"},"result_date":null}'

    if (Copy(sResult, 1, 1) <> '{') or (Copy(sResult, Length(sResult), 1) <> '}') then
    begin
      sLog := 'SendADStatusToErp Fail : ' + sResult;
      //WriteLogDayFile(Global.LogFileName, sLog);
      Global.Log.LogWrite(sLog);
      Exit;
    end;

    jObj := TJSONObject.ParseJSONValue(sResult) as TJSONObject;
    sResultCd := jObj.GetValue('result_cd').Value;
    sResultMsg := jObj.GetValue('result_msg').Value;

    if sResultCd <> '0000' then
    begin
      sLog := 'K710_TeeboxTime : ' + sResultCd + ' / ' + sResultMsg;
      //WriteLogDayFile(Global.LogFileName, sLog);
      Global.Log.LogWrite(sLog);
    end
    else
    begin

      jObjSub := jObj.GetValue('result_data') as TJSONObject;
      sChgDate := jObjSub.GetValue('chg_date').Value;

      if sChgDate > Global.Store.StoreLastTM then
      begin
        sLog := 'K710_TeeboxTime : ' + sResult;
        //WriteLogDayFile(Global.LogFileName, sLog);
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

{
function TTeebox.ReSetTeeboxNextReserveData(ATeebox, AIndex, AReserveNo, AreserveDate: String): Boolean;
var
  nTeeboxNo, nIndex: Integer;
begin
  nTeeboxNo := StrToInt(ATeebox);
  nIndex := StrToInt(AIndex);

  if AReserveNo <> '' then
    TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveNo := AReserveNo;

  if AreserveDate <> '' then
    TNextReserve(FTeeboxReserveList[nTeeboxNo].ReserveList.Objects[nIndex]).ReserveDate := AreserveDate;

end;
}

function TTeebox.TeeboxClear: Boolean;
var
  nTee, nIdx: Integer;
begin
  for nTee := 1 to TeeboxLastNo do
  begin
    for nIdx := 0 to FTeeboxReserveList[nTee].ReserveList.Count - 1 do
    begin
      TNextReserve(FTeeboxReserveList[nTee].ReserveList.Objects[0]).Free;
      FTeeboxReserveList[nTee].ReserveList.Objects[0] := nil;
      FTeeboxReserveList[nTee].ReserveList.Delete(0);
    end;
    FreeAndNil(FTeeboxReserveList[nTee].ReserveList);
  end;

  SetLength(FTeeboxInfoList, 0);

  for nIdx := 0 to FSendApiErrorList.Count - 1 do
  begin
    FSendApiErrorList.Delete(0);
  end;
  FreeAndNil(FSendApiErrorList);

end;

function TTeebox.ReSetTeeboxReserveDate(ATeeboxNo, ARemainMin: Integer): Boolean;
var
  tmNowEnd, tmNextStart: TDateTime;
  nMin, I, nTemp: Integer;
  sDate: String;
begin

  if FTeeboxReserveList[ATeeboxNo].ReserveList.Count = 0 then
    Exit;

  tmNowEnd := IncMinute(now(), ARemainMin);
  tmNextStart := DateStrToDateTime3( TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[0]).ReserveDate );

  if tmNowEnd <= tmNextStart then
    Exit;

  nTemp := Trunc(( tmNowEnd - tmNextStart ) *24 * 60 * 60); //초로 변환
  if (nTemp mod 60) > 0 then
    nMin := (nTemp div 60) + 1
  else
    nMin := (nTemp div 60);

  if nMin < 6 then
    Exit;

  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    tmNextStart := DateStrToDateTime3( TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate );
    tmNowEnd := IncMinute(tmNextStart, nMin + 1); //2021-06-11
    sDate := formatdatetime('YYYYMMDDHHNN00', tmNowEnd); //2021-06-11
    TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate := sDate;
  end;

  ResetTeeboxRemainMinAdd(ATeeboxNo, nMin, FTeeboxInfoList[ATeeboxNo].TeeboxNm);
end;

function TTeebox.ResetReserveDateTime(ATeeboxNo: Integer; ATeeboxNm: String): Boolean;
var
  tmNowEnd, tmNextStart: TDateTime;
  nMin, nDelayMin, I, nTemp: Integer;
  sDate, sReserveDate, sReserveNo, sResult, sStr: String;
begin

  if FTeeboxReserveList[ATeeboxNo].ReserveList.Count = 0 then
    Exit;

  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin

    if I = 0 then
    begin
      nMin := FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin;
      tmNowEnd := IncMinute(now(), nMin + 1); //2021-06-11
    end
    else
    begin
      nMin := StrToInt( TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I-1]).UseMinute );
      nDelayMin := StrToInt( TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I-1]).DelayMinute );
      tmNowEnd := IncMinute(DateStrToDateTime3( TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I-1]).ReserveDate ), nMin + nDelayMin + 1);
    end;

    sDate := formatdatetime('YYYYMMDDHHNN00', tmNowEnd); //2021-06-11
    sReserveDate := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate;

    if I = 0 then
    begin
      tmNextStart := DateStrToDateTime3( sReserveDate );
      nTemp := MinutesBetween(tmNowEnd, tmNextStart);

      if nTemp < 4 then
        Exit;
    end;

    if Copy(sReserveDate, 1, 12) < Copy(sDate, 1, 12) then
    begin
      TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveDate := sDate;

      sReserveNo := TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo;
      sResult := Global.XGolfDM.SetSeatReserveStartTmChange(Global.ADConfig.StoreCode, IntToStr(ATeeboxNo), sDate, sReserveNo);

      sStr := sResult + ' : ' + IntToStr(ATeeboxNo) + ' / ' + ATeeboxNm + ' / ' + sReserveNo + ' / ' + sReserveDate + ' -> ' + sDate;
      Global.Log.LogErpApiWrite('ResetReserveDateTime : ' + sStr);
    end;

  end;

end;

function TTeebox.SetTeeboxReserveCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  sStr: String;
  nNN: integer;
begin
  Result := False;

  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo <> AReserveNo then
  begin
    //예약대기, 배정된 타석이 아님
    SetTeeboxReserveNextCheckIn(ATeeboxNo, AReserveNo);

    //체크인 DB 저장
    Global.XGolfDM.SeatUseCheckInUpdate(Global.ADConfig.StoreCode, AReserveNo);

    Exit;
  end;

  //체크인한 시점으로 대기시간, 배정시간 변경
  if FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime < Now then //대기시간을 초과했으면
  begin
    nNN := MinutesBetween(now, FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareEndTime);
    FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin := FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin - nNN;
  end;

  FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignYn := 'Y';

  //체크인 DB 저장
  Global.XGolfDM.SeatUseCheckInUpdate(Global.ADConfig.StoreCode, AReserveNo);

  sStr := 'checkIn no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveNo + ' / ' +
          FTeeboxInfoList[ATeeboxNo].TeeboxReserve.ReserveDate + ' / ' +
          intToStr(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.PrepareMin) + ' / ' +
          IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxReserve.AssignMin);
  Global.Log.LogReserveWrite(sStr);

  Result := True;
end;

function TTeebox.SetTeeboxReserveNextCheckIn(ATeeboxNo: Integer; AReserveNo: String): Boolean;
var
  I: Integer;
  sStr: String;
  bCheck: Boolean;
begin
  Result := False;
  bCheck := False;

  for I := 0 to FTeeboxReserveList[ATeeboxNo].ReserveList.Count - 1 do
  begin
    if AReserveNo = TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).ReserveNo then
    begin
      TNextReserve(FTeeboxReserveList[ATeeboxNo].ReserveList.Objects[I]).AssignYn := 'Y';
      bCheck := True;

      Break;
    end;
  end;

  if bCheck = True then
  begin
    sStr := 'checkIn next no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' + AReserveNo;
  end
  else
  begin
    sStr := 'checkIn next not find no: ' + IntToStr(FTeeboxInfoList[ATeeboxNo].TeeboxNo) + ' / ' +
            FTeeboxInfoList[ATeeboxNo].TeeboxNm + ' / ' + AReserveNo;
  end;

  Global.Log.LogReserveWrite(sStr);
  Result := True;
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
  if Global.ADConfig.Emergency = True then
    Exit;

  if FSendApiErrorList.Count = 0 then
    Exit;

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
  except
    on e: Exception do
    begin
      sLog := 'SendApiErrorRetry Exception : ' + sJson + ' / ' + e.Message;
      Global.Log.LogErpApiWrite(sLog);
    end;
  end

end;

end.
