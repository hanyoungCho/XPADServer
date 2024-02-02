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
    FLogCtrlFileName: string;

    FLogCtrlFileName1: string;
    FLogCtrlFileName2: string;
    FLogCtrlFileName3: string;
    FLogCtrlFileName4: string;

    FLogMonFileName: string;
    FLogRetryFileName: string;

    FLogRetryFileName1: string;
    FLogRetryFileName2: string;
    FLogRetryFileName3: string;
    FLogRetryFileName4: string;

    FLogReserveFileName: string;
    FDebugLogFileName: string;
    FLogHeatFileName: string;
    FLogHeatCtrlFileName: String;
    FLogTcpServerFileName: String;
    FLogErpApiFileName: String;
    FLogErpApiDelayFileName: String;
    FLogReserveDelayFileName: String;

    //2020-12-16 빅토리아 반자동
    FLogReserveSemiAutoFileName: String;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Deletefiles(AFilePath : string);

    procedure LogWrite(ALog: string);
    procedure LogCtrlWrite(ALog: string);
    procedure LogCtrlWriteA6001(AIndex: Integer; ALog: string);
    procedure LogCtrlWriteModen(AIndex: Integer; ALog: string);

    procedure LogMonWrite(ALog: string);
    procedure LogRetryWrite(ALog: string);
    procedure LogRetryWriteA6001(AIndex: Integer; ALog: string);
    procedure LogRetryWriteModen(AIndex: Integer; ALog: string);

    procedure LogReserveWrite(ALog: string);
    procedure LogHeatWrite(ALog: string);
    procedure LogHeatCtrlWrite(ALog: string);
    procedure LogServerWrite(ALog: string);
    procedure LogErpApiWrite(ALog: string);
    procedure LogErpApiDelayWrite(ALog: string);
    procedure LogReserveDelayWrite(ALog: string);
    procedure LogReserveWriteSemiAuto(ALog: string); //빅토리아 반자동

    property LogFileName: string read FLogFileName write FLogFileName;
    property LogCtrlFileName: string read FLogCtrlFileName write FLogCtrlFileName;

    property LogCtrlFileName1: string read FLogCtrlFileName1 write FLogCtrlFileName1;
    property LogCtrlFileName2: string read FLogCtrlFileName2 write FLogCtrlFileName2;
    property LogCtrlFileName3: string read FLogCtrlFileName3 write FLogCtrlFileName3;
    property LogCtrlFileName4: string read FLogCtrlFileName4 write FLogCtrlFileName4;

    property LogMonFileName: string read FLogMonFileName write FLogMonFileName;
    property LogRetryFileName: string read FLogRetryFileName write FLogRetryFileName;

    property LogRetryFileName1: string read FLogRetryFileName1 write FLogRetryFileName1;
    property LogRetryFileName2: string read FLogRetryFileName2 write FLogRetryFileName2;
    property LogRetryFileName3: string read FLogRetryFileName3 write FLogRetryFileName3;
    property LogRetryFileName4: string read FLogRetryFileName4 write FLogRetryFileName4;

    property LogReserveFileName: string read FLogReserveFileName write FLogReserveFileName;
    property LogHeatFileName: string read FLogHeatFileName write FLogHeatFileName;
    property LogHeatCtrlFileName: string read FLogHeatCtrlFileName write FLogHeatCtrlFileName;
    property DebugLogFileName: string read FDebugLogFileName write FDebugLogFileName;

    //2020-12-16 빅토리아 반자동
    property LogReserveSemiAutoFileName: string read FLogReserveSemiAutoFileName write FLogReserveSemiAutoFileName;
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
  FLogCtrlFileName := FLogDir + 'XTADCtrl_';

  FLogCtrlFileName1 := FLogDir + 'XTADCtrl_1_';
  FLogCtrlFileName2 := FLogDir + 'XTADCtrl_2_';
  FLogCtrlFileName3 := FLogDir + 'XTADCtrl_3_';
  FLogCtrlFileName4 := FLogDir + 'XTADCtrl_4_';

  FLogMonFileName := FLogDir + 'XTADMon_';
  FLogRetryFileName := FLogDir + 'XTADRetry_';

  FLogRetryFileName1 := FLogDir + 'XTADRetry_1_';
  FLogRetryFileName2 := FLogDir + 'XTADRetry_2_';
  FLogRetryFileName3 := FLogDir + 'XTADRetry_3_';
  FLogRetryFileName4 := FLogDir + 'XTADRetry_4_';

  FLogReserveFileName := FLogDir + 'XTADReserve_';
  FDebugLogFileName := FLogDir + 'XTADDebug_';

  FLogHeatFileName := FLogDir + 'XTADHeat_';
  FLogHeatCtrlFileName := FLogDir + 'XTADHeatCtrl_';

  FLogTcpServerFileName := FLogDir + 'XTADServer_';
  FLogErpApiFileName := FLogDir + 'XTADErpApi_';
  FLogErpApiDelayFileName := FLogDir + 'XTADErpApiDelay_';
  FLogReserveDelayFileName := FLogDir + 'XTADReserveDelay_';

  //2020-12-16 빅토리아 반자동
  FLogReserveSemiAutoFileName := FLogDir + 'XTADReserveSemi_';

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

procedure TLog.LogCtrlWrite(ALog: string);
begin
  WriteLogDayFile(LogCtrlFileName, ALog);
end;

procedure TLog.LogCtrlWriteA6001(AIndex: Integer; ALog: string);
begin
  if AIndex  = 1 then
    WriteLogDayFile(LogCtrlFileName1, ALog)
  else if AIndex = 2 then
    WriteLogDayFile(LogCtrlFileName2, ALog)
  else if AIndex = 3 then
    WriteLogDayFile(LogCtrlFileName3, ALog)
  else
    WriteLogDayFile(LogCtrlFileName4, ALog);
end;

procedure TLog.LogCtrlWriteModen(AIndex: Integer; ALog: string);
begin
  if AIndex  = 2 then
    WriteLogDayFile(LogCtrlFileName1, ALog)
  else if AIndex = 3 then
    WriteLogDayFile(LogCtrlFileName2, ALog)
  else if AIndex = 4 then
    WriteLogDayFile(LogCtrlFileName3, ALog)
  else
    WriteLogDayFile(LogCtrlFileName4, ALog);
end;

procedure TLog.LogMonWrite(ALog: string);
begin
  WriteLogDayFile(LogMonFileName, ALog);
end;

procedure TLog.LogRetryWrite(ALog: string);
begin
  WriteLogDayFile(LogRetryFileName, ALog);
end;

procedure TLog.LogRetryWriteA6001(AIndex: Integer; ALog: string);
begin
  if AIndex  = 1 then
    WriteLogDayFile(LogRetryFileName1, ALog)
  else if AIndex = 2 then
    WriteLogDayFile(LogRetryFileName2, ALog)
  else if AIndex = 3 then
    WriteLogDayFile(LogRetryFileName3, ALog)
  else
    WriteLogDayFile(LogRetryFileName4, ALog);
end;

procedure TLog.LogRetryWriteModen(AIndex: Integer; ALog: string);
begin
  if AIndex  = 2 then
    WriteLogDayFile(LogRetryFileName1, ALog)
  else if AIndex = 3 then
    WriteLogDayFile(LogRetryFileName2, ALog)
  else if AIndex = 4 then
    WriteLogDayFile(LogRetryFileName3, ALog)
  else
    WriteLogDayFile(LogRetryFileName4, ALog);
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
