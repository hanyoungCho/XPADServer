unit uLogging;

interface

uses
  System.DateUtils, System.Classes,
  uConsts, uFunction, uStruct;

type
  TLog = class
  private
    FLogDir: string;
    FLogFileName: string;

    FLogWriteFileName1: string;
    FLogWriteFileName2: string;
    FLogWriteFileName3: string;
    FLogWriteFileName4: string;
    FLogWriteFileName5: string;
    FLogWriteFileName6: string;

    FLogMonFileName: string;

    FLogReadFileName1: string;
    FLogReadFileName2: string;
    FLogReadFileName3: string;
    FLogReadFileName4: string;
    FLogReadFileName5: string;
    FLogReadFileName6: string;

    FLogReserveFileName: string;
    FDebugLogFileName: string;
    FLogHeatFileName: string;
    FLogHeatCtrlFileName: string;
    FLogHeatReadFileName: string;

    FLogFanFileName: string;
    FLogFanWriteFileName: string;
    FLogFanReadFileName: string;

    FLogTcpServerFileName: String;
    FLogErpApiFileName: String;
    FLogErpApiDelayFileName: String;
    FLogReserveDelayFileName: String;

    //2020-12-16 빅토리아 반자동
    FLogReserveSemiAutoFileName: String;

    FLogXGMFileName: string;
    FLogAgentFileName: string;
    FLogBeamFileName: string;

    FLogTcpAgentServerReadFileName: String;
    FLogTcpAgentServerEventFileName: String;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Deletefiles(AFilePath : string);

    procedure LogMonWrite(ALog: string);

    procedure LogWrite(ALog: string);
    procedure LogWriteMulti(AIndex: Integer; ALog: string);
    procedure LogReadMulti(AIndex: Integer; ALog: string);

    procedure LogReserveWrite(ALog: string);
    procedure LogHeatWrite(ALog: string);
    procedure LogHeatCtrlWrite(ALog: string);
    procedure LogHeatCtrlRead(ALog: string);

    procedure LogFanWrite(ALog: string);
    procedure LogFanComWrite(ALog: string);
    procedure LogFanComRead(ALog: string);

    procedure LogServerWrite(ALog: string);
    procedure LogErpApiWrite(ALog: string);
    procedure LogErpApiDelayWrite(ALog: string);
    procedure LogReserveDelayWrite(ALog: string);
    procedure LogReserveWriteSemiAuto(ALog: string); //빅토리아 반자동

    procedure LogXGMCtrlWrite(ALog: string);
    procedure LogAgentCtrlWrite(ALog: string);
    procedure LogAgentServerRead(ALog: string);
    procedure LogAgentServerEvent(ALog: string);
    procedure LogBeamCtrlWrite(ALog: string);

    property LogFileName: string read FLogFileName write FLogFileName;

    property LogWriteFileName1: string read FLogWriteFileName1 write FLogWriteFileName1;
    property LogWriteFileName2: string read FLogWriteFileName2 write FLogWriteFileName2;
    property LogWriteFileName3: string read FLogWriteFileName3 write FLogWriteFileName3;
    property LogWriteFileName4: string read FLogWriteFileName4 write FLogWriteFileName4;
    property LogWriteFileName5: string read FLogWriteFileName5 write FLogWriteFileName5;
    property LogWriteFileName6: string read FLogWriteFileName6 write FLogWriteFileName6;

    property LogMonFileName: string read FLogMonFileName write FLogMonFileName;

    property LogReadFileName1: string read FLogReadFileName1 write FLogReadFileName1;
    property LogReadFileName2: string read FLogReadFileName2 write FLogReadFileName2;
    property LogReadFileName3: string read FLogReadFileName3 write FLogReadFileName3;
    property LogReadFileName4: string read FLogReadFileName4 write FLogReadFileName4;
    property LogReadFileName5: string read FLogReadFileName5 write FLogReadFileName5;
    property LogReadFileName6: string read FLogReadFileName6 write FLogReadFileName6;

    property LogReserveFileName: string read FLogReserveFileName write FLogReserveFileName;

    property LogHeatFileName: string read FLogHeatFileName write FLogHeatFileName;
    property LogHeatCtrlFileName: string read FLogHeatCtrlFileName write FLogHeatCtrlFileName;
    property LogHeatReadFileName: string read FLogHeatReadFileName write FLogHeatReadFileName;

    property LogFanFileName: string read FLogFanFileName write FLogFanFileName;
    property LogFanWriteFileName: string read FLogFanWriteFileName write FLogFanWriteFileName;
    property LogFanReadFileName: string read FLogFanReadFileName write FLogFanReadFileName;

    property DebugLogFileName: string read FDebugLogFileName write FDebugLogFileName;

    //2020-12-16 빅토리아 반자동
    property LogReserveSemiAutoFileName: string read FLogReserveSemiAutoFileName write FLogReserveSemiAutoFileName;

    property LogXGMFileName: string read FLogXGMFileName write FLogXGMFileName;
    property LogAgentFileName: string read FLogAgentFileName write FLogAgentfileName;
    property LogBeamFileName: string read FLogBeamFileName write FLogBeamfileName;
  end;

var
  Log: TLog;

implementation

uses
  SysUtils, Variants, uXGMainForm, Vcl.Graphics, JSON, uGlobal;

{ TGlobal }

constructor TLog.Create;
begin

  FLogDir := global.HomeDir + 'ADlog\';
  ForceDirectories(FLogDir);
  FLogFileName := FLogDir + 'XTAD_';

  FLogWriteFileName1 := FLogDir + 'ADComWrite_1_';
  FLogWriteFileName2 := FLogDir + 'ADComWrite_2_';
  FLogWriteFileName3 := FLogDir + 'ADComWrite_3_';
  FLogWriteFileName4 := FLogDir + 'ADComWrite_4_';
  FLogWriteFileName5 := FLogDir + 'ADComWrite_5_';
  FLogWriteFileName6 := FLogDir + 'ADComWrite_6_';

  FLogMonFileName := FLogDir + 'ADMon_';

  FLogReadFileName1 := FLogDir + 'ADComRead_1_';
  FLogReadFileName2 := FLogDir + 'ADComRead_2_';
  FLogReadFileName3 := FLogDir + 'ADComRead_3_';
  FLogReadFileName4 := FLogDir + 'ADComRead_4_';
  FLogReadFileName5 := FLogDir + 'ADComRead_5_';
  FLogReadFileName6 := FLogDir + 'ADComRead_6_';

  FLogReserveFileName := FLogDir + 'ADReserve_';
  FDebugLogFileName := FLogDir + 'ADDebug_';

  FLogHeatFileName := FLogDir + 'ADHeat_';
  FLogHeatCtrlFileName := FLogDir + 'ADHeatCtrl_';
  FLogHeatReadFileName := FLogDir + 'ADHeatRead_';

  FLogFanFileName := FLogDir + 'ADFan_';
  FLogFanWriteFileName := FLogDir + 'ADFanWrite_';
  FLogFanReadFileName := FLogDir + 'ADFanRead_';

  FLogTcpServerFileName := FLogDir + 'ADServer_';
  FLogErpApiFileName := FLogDir + 'ADErpApi_';
  FLogErpApiDelayFileName := FLogDir + 'ADErpApiDelay_';
  FLogReserveDelayFileName := FLogDir + 'ADReserveDelay_';

  //2020-12-16 빅토리아 반자동
  FLogReserveSemiAutoFileName := FLogDir + 'ADReserveSemi_';

  FLogXGMFileName := FLogDir + 'ADXGMCtrl_';
  FLogAgentFileName := FLogDir + 'ADAgentCtrl_';
  FLogBeamFileName := FLogDir + 'ADBeamCtrl_';
  FLogTcpAgentServerReadFileName := FLogDir + 'ADAgentServerRead_';
  FLogTcpAgentServerEventFileName := FLogDir + 'ADAgentServerEvent_';

  Deletefiles(FLogDir);
end;

destructor TLog.Destroy;
begin

  inherited;
end;

procedure TLog.LogWrite(ALog: string);
begin
  WriteLogDayFile(LogFileName, ALog);
end;

procedure TLog.LogWriteMulti(AIndex: Integer; ALog: string);
begin
  if AIndex = 1 then
    WriteLogDayFile(LogWriteFileName1, ALog)
  else if AIndex = 2 then
    WriteLogDayFile(LogWriteFileName2, ALog)
  else if AIndex = 3 then
    WriteLogDayFile(LogWriteFileName3, ALog)
  else if AIndex = 4 then
    WriteLogDayFile(LogWriteFileName4, ALog)
  else if AIndex = 5 then
    WriteLogDayFile(LogWriteFileName5, ALog)
  else
    WriteLogDayFile(LogWriteFileName6, ALog);
end;

procedure TLog.LogReadMulti(AIndex: Integer; ALog: string);
begin
  if AIndex  = 1 then
    WriteLogDayFile(LogReadFileName1, ALog)
  else if AIndex = 2 then
    WriteLogDayFile(LogReadFileName2, ALog)
  else if AIndex = 3 then
    WriteLogDayFile(LogReadFileName3, ALog)
  else if AIndex = 4 then
    WriteLogDayFile(LogReadFileName4, ALog)
  else if AIndex = 5 then
    WriteLogDayFile(LogReadFileName5, ALog)
  else
    WriteLogDayFile(LogReadFileName6, ALog);
end;

procedure TLog.LogMonWrite(ALog: string);
begin
  WriteLogDayFile(LogMonFileName, ALog);
end;

procedure TLog.LogReserveWrite(ALog: string);
begin
  WriteLogDayFile(LogReserveFileName, ALog);
end;

//2020-12-16 빅토리아 반자동
procedure TLog.LogReserveWriteSemiAuto(ALog: string);
begin
  WriteLogDayFile(LogReserveSemiAutoFileName, ALog);
end;

procedure TLog.LogHeatWrite(ALog: string);
begin
  WriteLogDayFile(LogHeatFileName, ALog);
end;

procedure TLog.LogHeatCtrlWrite(ALog: string);
begin
  WriteLogDayFile(LogHeatCtrlFileName, ALog);
end;

procedure TLog.LogHeatCtrlRead(ALog: string);
begin
  WriteLogDayFile(LogHeatReadFileName, ALog);
end;

procedure TLog.LogFanWrite(ALog: string);
begin
  WriteLogDayFile(LogFanFileName, ALog);
end;

procedure TLog.LogFanComWrite(ALog: string);
begin
  WriteLogDayFile(LogFanWriteFileName, ALog);
end;

procedure TLog.LogFanComRead(ALog: string);
begin
  WriteLogDayFile(LogFanReadFileName, ALog);
end;

procedure TLog.LogServerWrite(ALog: string);
begin
  WriteLogDayFile(FLogTcpServerFileName, ALog);
end;

procedure TLog.LogErpApiWrite(ALog: string);
begin
  WriteLogDayFile(FLogErpApiFileName, ALog);
end;

procedure TLog.LogErpApiDelayWrite(ALog: string);
begin
  WriteLogDayFile(FLogErpApiDelayFileName, ALog);
end;

procedure TLog.LogReserveDelayWrite(ALog: string);
begin
  WriteLogDayFile(FLogReserveDelayFileName, ALog);
end;

procedure TLog.LogXGMCtrlWrite(ALog: string);
begin
  WriteLogDayFile(LogXGMFileName, ALog);
end;

procedure TLog.LogAgentCtrlWrite(ALog: string);
begin
  WriteLogDayFile(LogAgentFileName, ALog);
end;

procedure TLog.LogAgentServerRead(ALog: string);
begin
  WriteLogDayFile(FLogTcpAgentServerReadFileName, ALog);
end;

procedure TLog.LogAgentServerEvent(ALog: string);
begin
  WriteLogDayFile(FLogTcpAgentServerEventFileName, ALog);
end;

procedure TLog.LogBeamCtrlWrite(ALog: string);
begin
  WriteLogDayFile(LogBeamFileName, ALog);
end;

procedure TLog.Deletefiles(AFilePath : string);
var
  Cnt: Integer;
  NowDateStr, TmpDateStr: string;
  SR: TSearchRec;
  SFile : string;
  DelPath: string;
  FileDate: TDateTime;
begin
  Cnt := 0;
  DelPath := '';
  NowDateStr := FormatDateTime('YYYYMMDD', Now - 30);

  try
    DelPath := ExcludeTrailingBackslash(AFilePath) + '\';

    // fConfig.F_MSGFile_Head : 설정파일에서 삭제 대상 파일 이름 Format을 지정한다
    // 지정된 이름의 패턴만 찾아서 지운다.

    if FindFirst(DelPath + '*.log', faAnyFile, SR) = 0 then begin

      repeat
        if (SR.Attr <> faDirectory) and (SR.Name <> '.') and (SR.Name <> '..') then begin // 디렉토리는 제외하고
          SFile := '';
          SFile := DelPath + SR.Name;

          if FileExists(SFile) then begin // 파일 존재 체크

            //----------------------------------------------------------
            // _MUN_ : 2012-03-29 - 파일 수정날짜 기준으로 변경 - 생성날짜 사용은 배업파일 수정때문에 고려해 본다
            FileDate := FileDateToDateTime( FileAge(SFile) );
            TmpDateStr := FormatDateTime('YYYYMMDD', FileDate);
            //----------------------------------------------------------

            if TmpDateStr <= NowDateStr then begin // 날짜 비교  - 일짜기준
              DeleteFile(SFile);
              WriteLogDayFile(LogFileName, 'Delete File : ' + SR.Name);
            end;

          end;
        end;
      until (FindNext(SR) <> 0);
      FindClose(SR);
    end;

    WriteLogDayFile(LogFileName, '로그데이터 삭제 완료');
  except
    on E: Exception do begin
      WriteLogDayFile(LogFileName, 'Deletefiles Error Message : ' + E.Message);
    end;
  end;

end;

end.
