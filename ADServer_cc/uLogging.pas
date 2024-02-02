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
    FLogReadFileName: string;
    FLogWriteFileName: string;

    FLogMonFileName: string;
    FLogRetryFileName: string;

    FLogReserveFileName: string;
    FLogTcpServerFileName: String;
    FLogErpApiFileName: String;
    FLogErpApiDelayFileName: String;
    FLogReserveDelayFileName: String;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Deletefiles(AFilePath : string);

    procedure LogWrite(ALog: string);
    procedure LogComRead(ALog: string);
    procedure LogComWrite(ALog: string);

    procedure LogMonWrite(ALog: string);
    procedure LogRetryWrite(ALog: string);

    procedure LogReserveWrite(ALog: string);
    procedure LogServerWrite(ALog: string);
    procedure LogErpApiWrite(ALog: string);
    procedure LogErpApiDelayWrite(ALog: string);
    procedure LogReserveDelayWrite(ALog: string);

    property LogFileName: string read FLogFileName write FLogFileName;
    property LogReadFileName: string read FLogReadFileName write FLogReadFileName;
    property LogWriteFileName: string read FLogWriteFileName write FLogWriteFileName;

    property LogMonFileName: string read FLogMonFileName write FLogMonFileName;
    property LogRetryFileName: string read FLogRetryFileName write FLogRetryFileName;

    property LogReserveFileName: string read FLogReserveFileName write FLogReserveFileName;
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
  FLogFileName := FLogDir + 'AD_';
  FLogReadFileName := FLogDir + 'ADRead_';
  FLogWriteFileName := FLogDir + 'ADWrite_';

  FLogMonFileName := FLogDir + 'ADMon_';
  FLogRetryFileName := FLogDir + 'ADRetry_';
  FLogReserveFileName := FLogDir + 'ADReserve_';

  FLogTcpServerFileName := FLogDir + 'ADServer_';
  FLogErpApiFileName := FLogDir + 'ADErpApi_';
  FLogErpApiDelayFileName := FLogDir + 'ADErpApiDelay_';
  FLogReserveDelayFileName := FLogDir + 'ADReserveDelay_';

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
procedure TLog.LogComRead(ALog: string);
begin
  WriteLogDayFile(LogReadFileName, ALog);
end;

procedure TLog.LogComWrite(ALog: string);
begin
  WriteLogDayFile(LogWriteFileName, ALog);
end;

procedure TLog.LogMonWrite(ALog: string);
begin
  WriteLogDayFile(LogMonFileName, ALog);
end;

procedure TLog.LogRetryWrite(ALog: string);
begin
  WriteLogDayFile(LogRetryFileName, ALog);
end;

procedure TLog.LogReserveWrite(ALog: string);
begin
  WriteLogDayFile(LogReserveFileName, ALog);
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
