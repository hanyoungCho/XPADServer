unit uTapo;

interface

uses
  IniFiles, CPort, System.DateUtils, System.Classes,
  uConsts, uFunction, uStruct, uErpApi,
  uXGServer, uXGAgentServer, uLogging,
  System.Threading,
  { Indy }
  IdIcmpClient,
  { Custom }
  uArpHelper, uTapoHelper;

type
  TTapo = class
  private
    FList: TStringList;

    FArpTable: TARPTable;
    FTaskIcmp: ITask;

    FTerminalUUID: string;
    FTapoHelper: TTapoHelper;
    FTaskStatus: ITask;

    FSetDeviceOnOffErrorList: TStringList;

    procedure GenerateUUID;

    function ActivateCkDLL(var AErrMsg: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function StartUp: Boolean;
    function ListClear: Boolean;

    procedure RescanIPList;
    procedure OnICmpClientReply(ASender: TComponent; const AReplyStatus: TReplyStatus);
    procedure SetDeviceOnOffErrorRetry;

    function GetDeviceList: Boolean;
    function GetDeviceInfo(const AIP: String): Boolean;
    function SetDeviceOnOff(const AIP: String; const APowerOn, ADebug: Boolean): Boolean;
    function SetDeviceOnOffErrorAdd(AIP: String; APowerOn: Boolean): Boolean;

    property TerminalUUID: string read FTerminalUUID write FTerminalUUID;
    property List: TStringList read FList write FList;
    property ArpTable: TARPTable read FArpTable write FArpTable;
  end;

var
  Tapo: TTapo;

implementation

uses
  SysUtils, Variants, uXGMainForm, Vcl.Graphics, JSON, IdGlobal,
  uGlobal,
  CkGlobal, CkJsonObject, CkJsonArray, uCommonLib;

{ TGlobal }

constructor TTapo.Create;
var
  sErrMsg: string;
begin
  FList := TStringList.Create;
  FArpTable := TARPTable.Create;

  GenerateUUID;

  FTapoHelper := TTapoHelper.Create(global.ADConfig.TapoHost, global.ADConfig.TapoEmail, global.ADConfig.TapoPwd, TerminalUUID);
  //FTapoHelper.PythonEngine.IO := PythonGUIInputOutput;
  if not FTapoHelper.PythonEngineLoaded then
    Global.Log.LogWrite('Python Engine Can not loaded.');

  if not ActivateCkDLL(sErrMsg) then
    Global.Log.LogWrite(Format('ActivateCkDLL.Exception : %s', [sErrMsg]));

  FSetDeviceOnOffErrorList := TStringList.Create;
end;

destructor TTapo.Destroy;
var
  nIdx: Integer;
begin
  ListClear;
  FreeAndNil(FList);
  FArpTable.Free;
  FTapoHelper.Free;

  for nIdx := 0 to FSetDeviceOnOffErrorList.Count - 1 do
  begin
    FSetDeviceOnOffErrorList.Delete(0);
  end;
  FreeAndNil(FSetDeviceOnOffErrorList);

  inherited;
end;

function TTapo.StartUp: Boolean;
var
  sResult: String;
  sToken: AnsiString;
  sStr: String;
begin
  Result := False;

  Result := True;
end;

function TTapo.ListClear: Boolean;
var
  nTee, nIdx: Integer;
begin
  for nIdx := 0 to FList.Count - 1 do
  begin
    TDeviceInfo(FList.Objects[0]).Free;
    FList.Objects[0] := nil;
    FList.Delete(0);
  end;
end;

procedure TTapo.RescanIPList;
begin
  if Assigned(FTaskIcmp) and
     (not (FTaskIcmp.Status in [TTaskStatus.Completed])) then
    Exit;

  FTaskIcmp := TTask.Create(
    procedure
    var
      Icmp: TIdIcmpClient;
      I: Integer;
    begin
      MainForm.AddLog('RescanIPList.Starting...');
      Icmp := TIdIcmpClient.Create(nil);
      try
        try
          Icmp.IPVersion := Id_IPv4;
          Icmp.PacketSize := 32;
          Icmp.Protocol := 1;
          Icmp.ReceiveTimeout := 1000;
          Icmp.OnReply:= OnICmpClientReply;
          for I := 1 to 254 do
          begin
            Icmp.Host := Format('%s.%s', [global.ADConfig.IPV4_C_Class, IntToStr(I)]);
            try
              Icmp.Ping;
            except
            end;
          end;
        finally
          FreeAndNil(Icmp);
        end;
      except
        on E: Exception do
          MainForm.AddLog(Format('RescanIPList.Exception : %s', [E.Message]));
      end;
      MainForm.AddLog('RescanIPList.Completed');
    end);

  FTaskIcmp.Start;
end;

procedure TTapo.OnICmpClientReply(ASender: TComponent; const AReplyStatus: TReplyStatus);
begin
  with AReplyStatus do
  begin

    case ReplyStatusType of
      rsEcho:
        MainForm.AddLog(Format('Ping %s Response : Bytes=%d Time=%dms TTL=%d', [FromIpAddress, BytesReceived, MsRoundTripTime, TimeToLive]));
      rsTimeOut:
        MainForm.AddLog(Format('Ping %s Request Timeout.', [TIdIcmpClient(ASender).Host]));
    end;

  end;
end;

procedure TTapo.GenerateUUID;
var
  sValue: string;
begin
  sValue := TGUID.NewGuid.ToString;

  TerminalUUID := StringReplace(StringReplace(StringReplace(sValue, '-', '', [rfReplaceAll]), '{', '', [rfReplaceAll]), '}', '', [rfReplaceAll]);
  //AddLog(Format('GenerateUUID.Result : %s', [TerminalUUID]));
end;

function TTapo.ActivateCkDLL(var AErrMsg: string): Boolean;
var
  CkGlobal: HCkGlobal;
  nStatus: Integer;
begin
  Result := False;
  AErrMsg := '';
  CkGlobal := CkGlobal_Create;
  try
    try
      if not CkGlobal_UnlockBundle(CkGlobal, LC_APIDLL_LICKEY) then
      //if not CkGlobal_UnlockBundle(CkGlobal, 'SLBPSK.CB1112022_ncysW5kq8RmQ') then
        raise Exception.Create(CkGlobal__lastErrorText(CkGlobal));

      nStatus := CkGlobal_getUnlockStatus(CkGlobal);
      if (nStatus <> 2) then
        raise Exception.Create(Format('Status=%d', [nStatus]));

      Result := True;
    except
      on E: Exception do
        AErrMsg := E.Message;
    end;
  finally
    CkGlobal_Dispose(CkGlobal);
  end;
end;

function TTapo.GetDeviceList: Boolean;
var
  JO, RO: HCkJsonObject;
  JA: HCkJsonArray;
  RS: TStringStream;
  DI: TDeviceInfo;
  I, nErrorCode, nCount, nStatus: Integer;
  sResponse, sMAC, sIP, sDeviceType, sDeviceName, sDeviceAlias, sErrMsg: string;
begin
  Result := False;
  try
    ListClear;

    JO := CkJsonObject_Create();
    RS := TStringStream.Create;
    try
      if not FTapoHelper.GetDeviceList(sResponse, sErrMsg) then
        raise Exception.Create(sErrMsg);

      sResponse := StringReplace(sResponse, #39, #34, [rfReplaceAll]);
      RS.WriteString(sResponse);
      //RS.SaveToFile(FLogDir + 'GetDeviceList.json');
      //AddLog('GetDeviceList.Response : ' + sResponse);
      global.Log.LogWrite('GetDeviceList.Response : ' + sResponse);

      if not CkJsonObject_Load(JO, PWideChar(sResponse)) then
        raise Exception.Create('Bad JSON Format');

      nErrorCode := CkJsonObject_IntOf(JO, 'error_code');
      if (nErrorCode <> 0) then
        raise Exception.Create(Format('ErrorCode(%d)', [nErrorCode]));

      JA := CkJsonObject_ArrayOf(JO, 'result.deviceList');
      if not CkJsonObject_getLastMethodSuccess(JO) then
        raise Exception.Create('result.deviceList not found');

      nCount := CkJsonArray_getSize(JA);
      if (nCount > 0) then
      begin

        try
          for I := 0 to Pred(nCount) do
          begin
            RO := CkJsonArray_ObjectAt(JA, I);
            try
              sMAC := CkJsonObject__stringOf(RO, 'deviceMac');
              if not sMAC.IsEmpty then
                sMAC := sMAC.Substring(0, 2) + '-' +
                        sMAC.Substring(2, 2) + '-' +
                        sMAC.Substring(4, 2) + '-' +
                        sMAC.Substring(6, 2) + '-' +
                        sMAC.Substring(8, 2) + '-' +
                        sMAC.Substring(10, 2);

              sIP := FArpTable.IP(sMAC);
              if sIP = '' then
              begin
                if global.ADConfig.StoreType = 0 then
                  sIP := global.Teebox.GetTeeboxInfoIP(sMAC)
                else
                  sIP := global.Room.GetRoomInfoIP(sMAC);
              end;

              sDeviceType := CkJsonObject__stringOf(RO, 'deviceType');
              sDeviceName := CkJsonObject__stringOf(RO, 'deviceName');
              sDeviceAlias := Base64Decode(CkJsonObject__stringOf(RO, 'alias'));
              nStatus := CkJsonObject_IntOf(RO, 'status');

              DI := TDeviceInfo.Create;
              DI.MAC := sMAC;
              DI.IP := sIP;
              DI.DeviceType := sDeviceType;
              DI.DeviceName := sDeviceName;
              DI.DeviceAlias := sDeviceAlias;
              DI.DeviceOn := False;
              DI.OverHeated := False;
              DI.OnTimes := 0;
              DI.Status := nStatus;

              FList.AddObject(DI.MAC, TObject(DI));

              //GetDeviceInfo(I);
              if sIP <> EmptyStr then
                GetDeviceInfo(sIP);

            finally
              CkJsonObject_Dispose(RO);
            end;
          end;
        finally

        end;
      end;

      //AddLog(Format('GetDeviceList.Success : Count=%d', [nCount]));
      Result := False;
    finally
      FreeAndNil(RS);
      CkJsonArray_Dispose(JA);
      CkJsonObject_Dispose(JO);
    end;
  except
    on E: Exception do
      Global.Log.LogWrite(Format('GetDeviceList.Exception : %s', [E.Message]));
  end;
end;

function TTapo.GetDeviceInfo(const AIP: String): Boolean;
var
  JO: HCkJsonObject;
  RS: TStringStream;
  nErrorCode: Integer;
  sIP, sResponse, sErrMsg: string;
  bDeviceOn: Boolean;
begin
  try
    Global.Log.LogCtrlWrite('GetDeviceInfo -1');
    sIP := AIP;
    JO := CkJsonObject_Create();
    RS := TStringStream.Create;
    try
      if not FTapoHelper.GetDeviceInfo(sIP, sResponse, sErrMsg) then
        raise Exception.Create(sErrMsg);

      sResponse := StringReplace(sResponse, #39, #34, [rfReplaceAll]);
      RS.WriteString(sResponse);
      //RS.SaveToFile(FLogDir + 'GetDeviceInfo.json');
      MainForm.AddLog(Format('GetDeviceInfo(%s).Response : %s', [sIP, sResponse]));
      Global.Log.LogCtrlWrite( Format('GetDeviceInfo(%s).Response : %s', [sIP, sResponse]) );

      if not CkJsonObject_Load(JO, PWideChar(sResponse)) then
        raise Exception.Create('Bad JSON Format');

      nErrorCode := CkJsonObject_IntOf(JO, 'error_code');
      if (nErrorCode <> 0) then
        raise Exception.Create(Format('ErrorCode(%d)', [nErrorCode]));

      bDeviceOn := CkJsonObject_BoolOf(JO, 'result.device_on');

      if Global.ADConfig.StoreType = 0 then
        Global.Teebox.SetTeeboxOnOff(sIP, IIF(bDeviceOn, 'On', 'Off'))
      else
        Global.Room.SetRoomOnOff(sIP, IIF(bDeviceOn, 'On', 'Off'));

      {
      with TDeviceInfo(lbxDeviceList.Items.Objects[Aindex]) do
      begin
        DeviceOn := CkJsonObject_BoolOf(JO, 'result.device_on');
        OverHeated := CkJsonObject_BoolOf(JO, 'result.overheated');
        OnTimes := CkJsonObject_IntOf(JO, 'result.on_time');
        AddLog(Format('GetDeviceInfo(%s).Success : DeviceOn=%s, OverHeated=%s, OnTime=%d',
          [sIP, IIF(DeviceOn, 'True', 'False'), IIF(OverHeated, 'True', 'False'), OnTimes]));

        Global.Teebox.SetTeeboxOnOff(sIP, IIF(DeviceOn, 'On', 'Off'));
      end;
      }

      Result := True;
    finally
      FreeAndNil(RS);
      CkJsonObject_Dispose(JO);
    end;
  except
    on E: Exception do
    begin
      if Global.ADConfig.StoreType = 0 then
        Global.Teebox.SetTeeboxTapoError(sIP)
      else
        Global.Room.SetRoomTapoError(sIP);

      MainForm.AddLog(Format('GetDeviceInfo(%s).Exception : %s', [sIP, E.Message]));
      Global.Log.LogCtrlWrite(Format('GetDeviceInfo(%s).Exception : %s', [sIP, E.Message]));
    end;
  end;
end;

function TTapo.SetDeviceOnOff(const AIP: String; const APowerOn, ADebug: Boolean): Boolean;
var
  JO: HCkJsonObject;
  RS: TStringStream;
  I, nErrorCode: Integer;
  sIP, sResponse, sErrMsg: string;
begin
  try
    //Global.Log.LogCtrlWrite('SetDeviceOnOff ' + AIP);
    sIP := AIP;
    JO := CkJsonObject_Create();
    RS := TStringStream.Create;
    try
      //Global.Log.LogCtrlWrite('SetDeviceOnOff 0');
      if not FTapoHelper.SetDeviceOnOff(sIP, APowerOn, sResponse, sErrMsg) then
      begin
        //Global.Log.LogCtrlWrite('SetDeviceOnOff 1');
        SetDeviceOnOffErrorAdd(sIP, APowerOn);
        raise Exception.Create(sErrMsg);
      end;
      //Global.Log.LogCtrlWrite('SetDeviceOnOff 2');

      sResponse := StringReplace(sResponse, #39, #34, [rfReplaceAll]);
      RS.WriteString(sResponse);
      //RS.SaveToFile(FLogDir + 'SetDeviceOnOff.json');
      //AddLog(Format('SetDeviceOnOff(%s, %s).Response : %s', [sIP, IIF(APowerOn, 'True', 'False'), sResponse]));
      Global.Log.LogCtrlWrite( Format('SetDeviceOnOff(%s, %s).Response : %s', [sIP, IIF(APowerOn, 'True', 'False'), sResponse]) );

      if not CkJsonObject_Load(JO, PWideChar(sResponse)) then
        raise Exception.Create('Bad JSON Format');

      nErrorCode := CkJsonObject_IntOf(JO, 'error_code');
      if (nErrorCode <> 0) then
        raise Exception.Create(Format('ErrorCode(%d)', [nErrorCode]));

      // 2021-11-24 제어시error_code = 0 이면 성공으로 판단. 상태요청 제외
      //GetDeviceInfo(sIP);
      if Global.ADConfig.StoreType = 0 then
        Global.Teebox.SetTeeboxOnOff(sIP, IIF(APowerOn, 'On', 'Off'))
      else
        Global.Room.SetRoomOnOff(sIP, IIF(APowerOn, 'On', 'Off'));

      if ADebug = True then
        MainForm.AddLog(Format('SetDeviceOnOff(%s).Success : Plug %s', [sIP, IIF(APowerOn, 'On', 'Off')]));
      Result := True;
    finally
      FreeAndNil(RS);
      CkJsonObject_Dispose(JO);
    end;
  except
    on E: Exception do
      Global.Log.LogCtrlWrite(Format('SetDeviceOnOff(%s).Exception : %s', [sIP, E.Message]));
  end;
end;

function TTapo.SetDeviceOnOffErrorAdd(AIP: String; APowerOn: Boolean): Boolean;
var
  Data: TSetDeviceOnOffErrorData;
begin
  Result := False;

  Data := TSetDeviceOnOffErrorData.Create;
  Data.IP := AIP;
  Data.Power := APowerOn;

  FSetDeviceOnOffErrorList.AddObject(AIP, TObject(Data));

  Result := True;
end;

procedure TTapo.SetDeviceOnOffErrorRetry;
var
  sIP, sLog: String;
  bPower: Boolean;
begin
  // tapo 제어 재시도
  if FSetDeviceOnOffErrorList.Count = 0 then
    Exit;

  sIP := TSetDeviceOnOffErrorData(FSetDeviceOnOffErrorList.Objects[0]).IP;
  bPower := TSetDeviceOnOffErrorData(FSetDeviceOnOffErrorList.Objects[0]).Power;

  TSetDeviceOnOffErrorData(FSetDeviceOnOffErrorList.Objects[0]).Free;
  FSetDeviceOnOffErrorList.Objects[0] := nil;
  FSetDeviceOnOffErrorList.Delete(0);

  try
    sLog := 'SetDeviceOnOffErrorRetry : ' + sIP + ' / ' + IIF(bPower, 'On', 'Off');
    Global.Log.LogCtrlWrite(sLog);

    SetDeviceOnOff(sIP, bPower, False);
  except
    on e: Exception do
    begin
      sLog := 'SetDeviceOnOffErrorRetry Exception : ' + sIP + ' / ' + e.Message;
      Global.Log.LogCtrlWrite(sLog);
    end;
  end

end;

end.
