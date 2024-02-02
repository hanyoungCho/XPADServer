unit uGlobal;

interface

uses
  IniFiles, CPort, System.DateUtils, System.Classes,
  uConsts, IdGlobal,
  uLogging, uComConveyor, IdTCPClient;

type
  TGlobal = class

  private
    FPort: integer;
    FPosIp: String;
    FLog: TLog;

    FComThread: TComConveyorMonThread;

    FAppName: string;
    FHomeDir: string;
    FConfig: TIniFile;
    FConfigFileName: string;
    FConfigDir: string;

    FIndex: Integer;

    procedure ReadConfig;
  public
    constructor Create;
    destructor Destroy; override;

    function StartUp: Boolean;
    function StopDown: Boolean;

    property Log: TLog read FLog write FLog;


    procedure SetConveyor(ARecvData: Ansistring);
    procedure SetConveyorError(AState: String);

    function CallAdmin(ACode, AStr: String): Boolean;

    property ComThread: TComConveyorMonThread read FComThread write FComThread;

    property AppName: string read FAppName write FAppName;
    property HomeDir: string read FHomeDir write FHomeDir;
    property ConfigDir: string read FConfigDir write FConfigDir;
    property Config: TIniFile read FConfig write FConfig;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;

    property Port: integer read FPort write FPort;
    property PosIp: String read FPosIp write FPosIp;

  end;

var
  Global: TGlobal;

implementation

uses
  SysUtils, Variants, uXGMainForm, Vcl.Graphics, JSON, uFunction;

{ TGlobal }

constructor TGlobal.Create;
var
  sStr: string;
  nIndex: Integer;
begin
  FAppName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  FHomeDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  FConfigDir := FHomeDir + 'config\';
  FConfigFileName := FConfigDir + 'Xtouch.config';
  ForceDirectories(FConfigDir);
  FConfig := TIniFile.Create(FConfigFileName);

  ReadConfig;

  FIndex := 0;
end;

function TGlobal.StartUp: Boolean;
begin
  Result := False;

  Log := TLog.Create;

  ComThread := TComConveyorMonThread.Create;
  ComThread.Resume;

  Result := True;
end;


function TGlobal.StopDown: Boolean;
begin
  Result := False;

  if ComThread <> nil then
  begin
    ComThread.Terminate;
    ComThread.WaitFor;
    ComThread.Free;
  end;

  Result := True;
end;

destructor TGlobal.Destroy;
begin
  StopDown;

  FConfig.Free; //ini 파일
  Log.Free;

  inherited;
end;

procedure TGlobal.ReadConfig;
begin
  FPort := FConfig.ReadInteger('ADInfo', 'ConveyorPort', 10);
  FPosIp := FConfig.ReadString('ADInfo', 'ConveyorPos', '');
end;

procedure TGlobal.SetConveyor(ARecvData: Ansistring);
var
  sState, sBin: AnsiString;
  sRecvDataTm: AnsiString;
  sLog: String;
begin
  sState := Copy(ARecvData, 21, 1);

  if IsNumeric(sState) then
  begin
    sBin := DecToBinStr(StrToInt(sState));
    sBin := StrZeroAdd(sBin, 4);

    if Copy(sBin, 1, 1) = '1' then
    begin
      sLog := '3차막힘';
      MainForm.LogViewA(sLog);
      CallAdmin('7003', sLog);
    end;

    if Copy(sBin, 2, 1) = '1' then
    begin
      sLog := '2차막힘';
      MainForm.LogViewA(sLog);
      CallAdmin('7002', sLog);
    end;

    if Copy(sBin, 3, 1) = '1' then
    begin
      sLog := '1차막힘';
      MainForm.LogViewA(sLog);
      CallAdmin('7001', sLog);
    end;

  end
  else
  begin
    sLog := '컨베이어 이상';
    MainForm.LogViewA(sLog);
    CallAdmin('7004', sLog);
  end;

  //0010 - 1차막힘
  //0100 - 2차막힘
  //1000 - 3차막힘

  sRecvDataTm := Copy(ARecvData, 10, 20);
  sLog := sRecvDataTm +'-'+sBin;

  Inc(FIndex);
  if FIndex > 100 then
    FIndex := 1;

  sLog := StrZeroAdd(IntToStr(FIndex), 3) + ':' + sLog;

  //FCtrlBufferTemp := sLog;
  MainForm.LogView(sLog);
end;

procedure TGlobal.SetConveyorError(AState: String);
var
  sLog: String;
begin

  if AState = '0' then
  begin

  end
  else
  begin
    sLog := '컨베이어 통신이상';
    MainForm.LogViewA(sLog);
    MainForm.ErrorView;
    CallAdmin('7004', sLog);
  end;

end;

function TGlobal.CallAdmin(ACode, AStr: String): Boolean;
var
  Indy: TIdTCPClient;
  Msg, sBuffer: string;
  JO: TJSONObject;
begin

  Result := False;
  JO := TJSONObject.Create;
  with TIdTCPClient.Create(nil) do
  try
    try
      JO.AddPair(TJSONPair.Create('error_cd', ACode));
      JO.AddPair(TJSONPair.Create('sender_id', 'CONVEYOR'));
      JO.AddPair(TJSONPair.Create('error_msg', AStr));
      sBuffer := JO.ToString;

      Host := FPosIp;
      Port := 6001;
      ConnectTimeout := 2000;
      ReadTimeout := 2000;
      Connect;
      IOHandler.Writeln(sBuffer, IndyTextEncoding_UTF8);

      //Global.SBMessage.ShowMessageModalForm2(MSG_PRINT_ADMIN_CALL, True, 30, True, True);

      Result := Connected;
    except
      on e: Exception do
      begin
        //Global.SBMessage.ShowMessageModalForm(MSG_ADMIN_CALL_FAIL);
        Log.LogWrite('CallAdmin : ' + E.Message);
      end;
    end

  finally
    Disconnect;
    Free;
    FreeAndNilJSONObject(JO);
  end;

end;

end.
