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

    FLogReserveFileName: string;
    FLogTcpServerFileName: String;
    FLogTcpAgentServerFileName: String;
    FLogTcpAgentServerReadFileName: String;
    FLogErpApiFileName: String;
    FLogErpApiDelayFileName: String;
    FLogReserveDelayFileName: String;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Deletefiles(AFilePath : string);

    procedure LogWrite(ALog: string);
    procedure LogCtrlWrite(ALog: string);

    procedure LogReserveWrite(ALog: string);
    procedure LogServerWrite(ALog: string);

    procedure LogAgentServerWrite(ALog: string);
    procedure LogAgentServerRead(ALog: string);

    procedure LogErpApiWrite(ALog: string);
    procedure LogErpApiDelayWrite(ALog: string);
    procedure LogReserveDelayWrite(ALog: string);

    property LogFileName: string read FLogFileName write FLogFileName;
    property LogCtrlFileName: string read FLogCtrlFileName write FLogCtrlFileName;
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

  FLogFileName := FLogDir + 'XTAD_';
  FLogCtrlFileName := FLogDir + 'XTADCtrl_';

  FLogReserveFileName := FLogDir + 'XTADReserve_';
  FLogTcpServerFileName := FLogDir + 'XTADServer_';
  FLogTcpAgentServerFileName := FLogDir + 'XTAgentServer_';
  FLogTcpAgentServerReadFileName := FLogDir + 'AgentServerRead_';
  FLogErpApiFileName := FLogDir + 'XTADErpApi_';
  FLogErpApiDelayFileName := FLogDir + 'XTADErpApiDelay_';
  FLogReserveDelayFileName := FLogDir + 'XTADReserveDelay_';

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

procedure TLog.LogReserveWrite(ALog: string);
begin
  WriteLogDayFile(LogReserveFileName, ALog);
end;

procedure TLog.LogServerWrite(ALog: string);
begin
  WriteLogDayFile(FLogTcpServerFileName, ALog);
end;

procedure TLog.LogAgentServerWrite(ALog: string);
begin
  WriteLogDayFile(FLogTcpAgentServerFileName, ALog);
end;

procedure TLog.LogAgentServerRead(ALog: string);
begin
  WriteLogDayFile(FLogTcpAgentServerReadFileName, ALog);
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
