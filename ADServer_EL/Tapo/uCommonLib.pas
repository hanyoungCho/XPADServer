unit uCommonLib;

interface

uses
  System.SysUtils, System.JSON;

function Base64Decode(const AData: string): string;
function Base64Encode(const AData: string; const AConvertUTF8: Boolean=False): string;
function BytesToString(const AValue: TBytes): WideString;
function SHA1HexDigest(const AData: string): string;
procedure FreeAndNilJSONObject(AObject: TJSONAncestor);
procedure UpdateLog(const AFileName, AStr: string; const AUseLineBreak: Boolean=False);
procedure WriteToFile(const AFileName, AStr: string; const ANewFile: Boolean=False);

implementation

uses
  System.StrUtils, Soap.EncdDecd, IdHashSHA;

function Base64Decode(const AData: string): string;
var
  Bytes: TBytes;
  UTF8: UTF8String;
begin
  Bytes := Soap.EncdDecd.DecodeBase64(AData);
  SetLength(UTF8, Length(Bytes));
  Move(Pointer(Bytes)^, Pointer(UTF8)^, Length(Bytes));
  Result := String(UTF8);
end;

function Base64Encode(const AData: string; const AConvertUTF8: Boolean=False): string;
var
  UTF8: UTF8String;
begin
  if AConvertUTF8 then
  begin
    UTF8 := UTF8String(AData);
    Result := Soap.EncdDecd.EncodeBase64(PChar(UTF8), Length(UTF8));
  end
  else
    Result := Soap.EncdDecd.EncodeBase64(PChar(AData), Length(AData));
end;

function BytesToString(const AValue: TBytes): WideString;
begin
  SetLength(Result, Length(AValue) div SizeOf(WideChar));
  if Length(Result) > 0 then
    Move(AValue[0], Result[1], Length(AValue));
end;

function SHA1HexDigest(const AData: string): string;
begin
  with TIdHashSHA1.Create do
  try
    Result := HashStringAsHex(AData);
  finally
    Free;
  end;
end;

procedure FreeAndNilJSONObject(AObject: TJSONAncestor);
begin
  try
    if Assigned(AObject) then
    begin
      AObject.Owned := False;
      AObject.Free;
    end;
  except
  end;
end;

procedure UpdateLog(const AFileName, AStr: string; const AUseLineBreak: Boolean);
begin
  try
    WriteToFile(AFileName,
      '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ']' +
      IfThen(AUseLineBreak, System.sLineBreak, ' ') + AStr);
  except
  end;
end;

procedure WriteToFile(const AFileName, AStr: string; const ANewFile: Boolean);
var
  hFile: TextFile;
begin
  if ANewFile then
    DeleteFile(AFileName);

  AssignFile(hFile, AFileName);
  try
    try
      if FileExists(AFileName) then
        Append(hFile)
      else
        Rewrite(hFile);

      WriteLn(hFile, AStr);
    except
    end;
  finally
    CloseFile(hFile);
  end;
end;

end.
