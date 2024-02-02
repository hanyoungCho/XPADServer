unit FileLog;

interface

uses Sysutils;

type
  TFileLog = class(TObject)
  public
    FFileName: string;
    function SetProjectLogFile(ADir, AFile: string): Boolean;
    function Write(ALog: string): Boolean;
  end;

implementation

function TFileLog.SetProjectLogFile(ADir, AFile: string): Boolean;
var
  nHFile: Integer;
begin
  Result := FALSE;

  if (ADir <> '') and (not DirectoryExists(ADir)) then
    CreateDir(ADir);

  if not FileExists(AFile) then
  begin
    nHFile := FileCreate(AFile);
    if nHFile = -1 then
      Exit;

    FileClose(nHFile);
  end;

  FFileName := AFile;
  Result := TRUE;
end;

function TFileLog.Write(ALog: string): Boolean;
var
  tfFile: TextFile;
  sLog: string;
begin

  Result := FALSE;
  try
    sLog := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + '# ' + ALog;
    sLog := Trim(sLog);

    AssignFile(tfFile, FFileName);
    if IOResult = 0 then
    begin
      Append(tfFile);
      Writeln(tfFile, sLog);
      Flush(tfFile);
      CloseFile(tfFile);
    end;

  except
    Exit;
  end;
  Result := TRUE;
end;

end.

