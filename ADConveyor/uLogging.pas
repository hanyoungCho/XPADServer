unit uLogging;

interface

uses
  System.DateUtils, System.Classes,
  uConsts, uStruct;

type
  TLog = class
  private
    FLogDir: string;
    FLogFileName: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Deletefiles(AFilePath : string);

    procedure LogWrite(ALog: string);

    property LogFileName: string read FLogFileName write FLogFileName;
  end;

var
  Log: TLog;

implementation

uses
  SysUtils, Variants, uXGMainForm, Vcl.Graphics, JSON, uGlobal, uFunction;

{ TGlobal }

constructor TLog.Create;
begin
  FLogDir := global.HomeDir + 'ADConlog\';
  ForceDirectories(FLogDir);
  FLogFileName := FLogDir + 'ADConveyor_';
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

    // fConfig.F_MSGFile_Head : �������Ͽ��� ���� ��� ���� �̸� Format�� �����Ѵ�
    // ������ �̸��� ���ϸ� ã�Ƽ� �����.

    if FindFirst(DelPath + '*.log', faAnyFile, SR) = 0 then begin

      repeat
        if (SR.Attr <> faDirectory) and (SR.Name <> '.') and (SR.Name <> '..') then begin // ���丮�� �����ϰ�
          SFile := '';
          SFile := DelPath + SR.Name;

          if FileExists(SFile) then begin // ���� ���� üũ

            //----------------------------------------------------------
            // _MUN_ : 2012-03-29 - ���� ������¥ �������� ���� - ������¥ ����� ������� ���������� ����� ����
            FileDate := FileDateToDateTime( FileAge(SFile) );
            TmpDateStr := FormatDateTime('YYYYMMDD', FileDate);
            //----------------------------------------------------------

            if TmpDateStr <= NowDateStr then begin // ��¥ ��  - ��¥����
              DeleteFile(SFile);
              WriteLogDayFile(LogFileName, 'Delete File : ' + SR.Name);
            end;

          end;
        end;
      until (FindNext(SR) <> 0);
      FindClose(SR);
    end;

    WriteLogDayFile(LogFileName, '�α׵����� ���� �Ϸ�');
  except
    on E: Exception do begin
      WriteLogDayFile(LogFileName, 'Deletefiles Error Message : ' + E.Message);
    end;
  end;

end;

end.
