unit uFunction;

interface

uses
  System.Classes, System.SysUtils, Winapi.Windows, IdGlobal, CPort, JSON, TlHelp32,
  uConsts,
  IdHashMessageDigest, IdHash;

  function DateStrToDateTime(ADateTime: string): TDateTime;
  function DateStrToDateTime2(ADateTime: string): TDateTime;
  function DateStrToDateTime3(ADateTime: string): TDateTime;
  //암호화
  function Encode(const AStr: AnsiString): AnsiString;
  //복호화
  function Decode(const AStr: AnsiString): AnsiString;
  //텍스트 파일 생성 및 기록
  procedure WriteFile(const AFileName, AStr: string);
  procedure WriteLogFile(const AFileName, AStr: string);
  procedure WriteLogDayFile(AFileName, AStr: string);

  function GetBCC(ASTX, AData, AETX: String): AnsiString;
  function GetBccCtl(ASTX, AData, AETX: String): AnsiString;
  function GetBccJehu(AData: String): AnsiString;
  function GetBccJehu2Byte(AData: String): AnsiString;
  function GetBccStarHeat(AData: String): AnsiString;
  function GetBCCZoomCC(AData: String): AnsiString;
  function GetBccModen(AData: AnsiString): AnsiString;
  function GetBccSM(AData: AnsiString): AnsiString;
  function GetBccInfornet(AData: AnsiString): AnsiString;
  function GetBccNano(AData: AnsiString): AnsiString;
  function GetBccFieldLo(AData: AnsiString): AnsiString;

  function StrZeroAdd(AStr: String; ACnt: Integer): String;

  function StrToAnsiHex(const AStr: String): String;
  function AnsiHexToStr(const AStr: String): String;
  function StringToHex(const S: string): string;

  function SetSystemTimeChange(const ADateTime: TDateTime): Boolean;

  function GetBaudrate(const ABaudrate: Integer): TBaudRate;
  function GetParity(const AParity: Integer): TParityBits;
  //function MyExitWindows(RebootParam: Longword): Boolean;
  function MyExitWindows: Boolean;
  function isNumber(s: String): Boolean;
  function URLEncode(const psSrc: string): string;
  procedure FreeAndNilJSONObject(AObject: TJSONAncestor);

  function DecToBinStr(n: integer): String; // 10진수를 2진수로...
  function CharToInteger(chr: Char): Integer;

  function IfThen(IsTrue: Boolean; AValue, BValue: Variant): Variant;

  //암호화, 복호화
  function StrEncrypt(const AStr: AnsiString): AnsiString;
  function StrDecrypt(const AStr: AnsiString): AnsiString;

  function Bin2Dec(BinString: string): LongInt;

  // uses 에 TlHelp32 추가
  function IsRunningProcess(const ProcName: String) : Boolean; //프로세스 검사
  function KillProcess(const ProcName: String): Boolean; //프로세스 죽이기

  function MD5Str(const S: String): String;

implementation

//YYYYMMDDhhnnss 형식
function DateStrToDateTime(ADateTime: string): TDateTime;
begin
  Result := 0;
  if Length(ADateTime) = 14 then
  begin
    Result :=
      EncodeDate(StrToIntDef(Copy(ADateTime, 1, 4), 0),
        StrToIntDef(Copy(ADateTime, 5, 2), 0), StrToIntDef(Copy(ADateTime, 7, 2), 0)) +
      EncodeTime(StrToIntDef(Copy(ADateTime, 9, 2), 0),
        StrToIntDef(Copy(ADateTime, 11, 2), 0), StrToIntDef(Copy(ADateTime, 13, 2), 0), 0);
  end;
end;

//YYYY-MM-DD hh:nn:ss 형식
function DateStrToDateTime2(ADateTime: string): TDateTime;
begin
  Result := 0;
  if Length(ADateTime) = 19 then
  begin
    Result :=
      EncodeDate(StrToIntDef(Copy(ADateTime, 1, 4), 0),
        StrToIntDef(Copy(ADateTime, 6, 2), 0), StrToIntDef(Copy(ADateTime, 9, 2), 0)) +
      EncodeTime(StrToIntDef(Copy(ADateTime, 12, 2), 0),
        StrToIntDef(Copy(ADateTime, 15, 2), 0), StrToIntDef(Copy(ADateTime, 18, 2), 0), 0);
  end;
end;

//YYYYMMDDhhnnss 형식
function DateStrToDateTime3(ADateTime: string): TDateTime;
begin
  Result := 0;
  if Length(ADateTime) = 14 then
  begin
    Result :=
      EncodeDate(StrToIntDef(Copy(ADateTime, 1, 4), 0),
        StrToIntDef(Copy(ADateTime, 5, 2), 0), StrToIntDef(Copy(ADateTime, 7, 2), 0)) +
      EncodeTime(StrToIntDef(Copy(ADateTime, 9, 2), 0),
        StrToIntDef(Copy(ADateTime, 11, 2), 0), StrToIntDef(Copy(ADateTime, 13, 2), 0), 0);
  end;
end;

//암호화
function Encode(const AStr: AnsiString): AnsiString;
const
  HexData: array[0..9] of Integer = (186, 165, 20, 188, 61, 85, 171, 61, 244, 164);
var
  i, sKey, sRndCnt: Integer;
  strRet, strTemp: AnsiString;
  PWord: ^AnsiChar;
begin
  Randomize();
  sKey := Random(254);
  sRndCnt := Random(9) + 5;
  strRet := strRet + Format('%.2X', [((sRndCnt xor sKey) xor HexData[5])]);

	sKey := sKey xor HexData[9];

  for i := 1 to sRndCnt do
    strRet := strRet + Format('%.2X', [Random(254) xor sKey]);

	sKey := sKey xor HexData[5];

  i := 0;
  while(i < Length(aStr)) do
  begin
    PWord := Pointer(PAnsiChar(aStr) + i);
    strTemp := Format('%.2X', [(Ord(PWord^) xor sKey) xor HexData[i mod 10]]);
    strRet := strRet + strTemp;
    Inc(i);
  end;
  strTemp := Format('%.2X', [sKey]);
  Result := strTemp + strRet;
end;

//복호화
function Decode(const AStr: AnsiString): AnsiString;
const
  HexData: array[0..9] of Integer = (186, 165, 20, 188, 61, 85, 171, 61, 244, 164);
var
  i, sLen, iPos, sKey, sBaseKey, sRndCnt, iTmp: Integer;
  strRet, strTemp: AnsiString;
begin
  Result := '';
  sLen := Length(aStr);
  if sLen < 6 then Exit;

  sBaseKey := StrToInt('$' + Copy(aStr, 1, 2));
	sKey := sBaseKey xor HexData[5];
	sKey := sKey xor HexData[9];

  sRndCnt := ((StrToInt('$' + Copy(aStr, 3, 2)) xor HexData[5]) xor sKey);
	iPos := 4 + sRndCnt * 2 + 1;

	if sLen <= iPos then Exit;

	sKey := sBaseKey;
  i := 0;
  while iPos < sLen do
  begin
    strTemp := '$' + Copy(aStr, iPos, 2);
    iTmp := ((StrToInt(strTemp) xor HexData[i mod 10]) xor sKey);
    strRet := strRet + Chr(iTmp);
    Inc(i);
    iPos := iPos + 2;
  end;
  Result := strRet;
end;

//텍스트 파일 생성 및 기록
procedure WriteFile(const AFileName, AStr: string);
var
  hFile: TextFile;
begin
  try
    AssignFile(hFile, AFileName);
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

procedure WriteLogFile(const AFileName, AStr: string);
var
  hFile: TextFile;
  sLog: string;
begin
  try
    sLog := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + '# ' + AStr;

    AssignFile(hFile, AFileName);
    try
      if FileExists(AFileName) then
        Append(hFile)
      else
        Rewrite(hFile);

      WriteLn(hFile, sLog);
    except
    end;
  finally
    CloseFile(hFile);
  end;
end;

procedure WriteLogDayFile(AFileName, AStr: string);
var
  hFile: TextFile;
  sLog: string;
begin
  try
    AFileName := AFileName + FormatDateTime('yyyymmdd', Now) + '.log';
    sLog := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + '# ' + AStr;

    AssignFile(hFile, AFileName);
    try
      if FileExists(AFileName) then
        Append(hFile)
      else
        Rewrite(hFile);

      WriteLn(hFile, sLog);
    except
    end;
  finally
    CloseFile(hFile);
  end;
end;

function GetBCC(ASTX, AData, AETX: String): AnsiString;
var
  nSTX, nLen, i, nBcc: Integer;
  sStr: AnsiString;
begin
  {
  nSTX := StrToIntDef(ASTX, 0);
  nLen := Length(AData);
  nBcc := 0;
  nBcc := StrToIntDef(ASTX, 0);

  for i := 1 to nLen do
    nBcc := nBcc + Ord(AData[i]);

  nBcc := nBcc + StrToIntDef(AETX, 0);
  nBcc := (nBcc mod 256) - nSTX;

  while (nBcc > 63) do
    nBcc := nBcc - 32;

  Result := Char(nBcc);
  }

  nBcc := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
  begin
    if IsNumeric(AData[i]) then
      nBcc := nBcc + StrToInt(AData[i]);
  end;

  If nBcc + 52 < 64 Then
    sStr := Char(nBcc + 52)
  Else
    sStr := Char(nBcc + 52 - 32);

  Result := sStr;
end;

function GetBccCtl(ASTX, AData, AETX: String): AnsiString;
var
  nSTX, nLen, i, nBcc: Integer;
  //nBcc: byte;
begin
  {
  nSTX := StrToIntDef(ASTX, 0);
  nLen := Length(AData);
  nBcc := 0;
  //nBcc := StrToIntDef(ASTX, 0);

  for i := 1 to nLen do
    nBcc := nBcc + Ord(AData[i]);

  nBcc := nBcc + StrToIntDef(AETX, 0);
  nBcc := (nBcc mod 128);

  Result := Char(nBcc);
  }

  nBcc := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
  begin
    if IsNumeric(AData[i]) then
      nBcc := nBcc + StrToInt(AData[i])
    else
      nBcc := nBcc + Ord(AData[i]);
  end;
  Result := Char(nBcc - 60);
  //Result := Char(900);
end;

function GetBccJehu(AData: String): AnsiString;
var
  nLen, i, nBcc: Integer;
  sStr: String;
begin
  nBcc := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
  begin
    sStr := IntToHex(Ord(AData[i]), 2);
    nBcc := nBcc + StrToInt(sStr);
  end;
  Result := IntToStr(nBcc);
end;

function GetBccJehu2Byte(AData: String): AnsiString; //5.0A, 6.0A
var
  nLen, i, nBcc: Integer;
  sStr, sBcc: String;
begin
  nBcc := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
  begin
    sStr := IntToHex(Ord(AData[i]), 2);
    nBcc := nBcc + StrToInt(sStr);
  end;

  sBcc := IntToStr(nBcc);
  if Length(sBcc) > 2 then
    sBcc := Copy(sBcc, length(sBcc) - 1, 2);

  Result := sBcc;
end;

function GetBccStarHeat(AData: String): AnsiString;
var
  nLen, i, nBcc: Integer;
  sStr: String;
begin
  nBcc := 0;
  for i := 1 to HEAT_MAX do
  begin
    nBcc := nBcc + StrToInt(AData[i])
  end;

  if nBcc < 6 then
  begin
    //0	7A	122, 1	7B	123,2	7C	124,3	7D	125,4	7E	126,5	7F	127
    nBcc := 122 + nBcc;
  end
  else if nBcc < 39 then
  begin
    //6	20	32, 38	40	64
    nBcc := 26 + nBcc;
  end
  else
  begin
    //39	21	33, 67	3D	61
    nBcc := nBcc - 6;
  end;

  Result := Char(nBcc);
end;

function GetBCCZoomCC(AData: String): AnsiString;
var
  nSTX, nLen, i, nBcc: Integer;
  sStr: AnsiString;
  bBcc: Byte;
begin

  {
  g_box.sum_bcc += i;
  g_box.sum_bcc &= 0x7f;
  if(g_box.sum_bcc < 0x20) g_box,.sum_bcc += 0x20;
  }

  nBcc := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
  begin
    nBcc := nBcc + Ord(AData[i]);
  end;
  nBcc := nBcc + Ord(ZOOM_CC_EOT);

  bBcc := nBcc;
  bBcc := bBcc and $7f;
  if(bBcc < $20) then
   bBcc := bBcc + $20;

  sStr := Char(bBcc);

  Result := sStr;
end;

function GetBccModen(AData: AnsiString): AnsiString;
var
  nLen, i, nBcc, nTemp: Integer;
  sStr: String;
begin
  nBcc := 0;
  nTemp := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
    nTemp := nTemp + Integer(AData[i]);

  nBcc := nTemp mod 128;

  if nBcc < 32 then
    nBcc := nBcc + 32;

  Result := Chr(nBcc);
end;

function GetBccSM(AData: AnsiString): AnsiString;
var
  nLen, i: Integer;
  bBcc: Byte;
begin

  bBcc := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
  begin
    bBcc := bBcc + Ord(AData[i]);
  end;
  bBcc := bBcc + 5;
  bBcc := (bBcc mod 128);

  Result := Char(bBcc);

end;

function GetBccInfornet(AData: AnsiString): AnsiString;
var
  nLen, i: Integer;
  bBcc: Byte;
begin

  bBcc := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
  begin
    bBcc := bBcc xor Ord(AData[i]);
  end;

  Result := Char(bBcc);
end;

function GetBccNano(AData: AnsiString): AnsiString;
var
  nLen, i: Integer;
  bBcc: Byte;
  bBcc1, bBcc2: Byte;
  sStr: AnsiString;
begin

  bBcc := 0;
  nLen := Length(AData);
  for i := 1 to nLen do
  begin
    bBcc := bBcc xor Ord(AData[i]);
  end;

  sStr := DecToBinStr(bBcc);
  sStr := StrZeroAdd(sStr, 8);

  bBcc1 := Bin2Dec('0000' + Copy(sStr, 1, 4));
  bBcc2 := Bin2Dec('0000' + Copy(sStr, 5, 8));

  Result := Char(bBcc1 + $30) + Char(bBcc2 + $30) + Char(NANO_ETX);
end;

function GetBccFieldLo(AData: AnsiString): AnsiString;
var
  i: Integer;
  bBcc: Byte;
begin
  bBcc := 0;
  for i := 1 to 9 do
  begin
    bBcc := bBcc + Ord(AData[i]);
  end;
  Result := Char(bBcc);
end;

function StrZeroAdd(AStr: String; ACnt: Integer): String;
var
  I, nCnt: Integer;
begin
  nCnt := Length(AStr);
  for I := nCnt + 1 to ACnt do
  begin
    AStr := '0' + AStr;
  end;
  Result :=  AStr;
end;

function StrToAnsiHex(const AStr: String): String;
var
  nIndex: Integer;
  sTemp: AnsiString;
begin
  Result := '';
  sTemp := AnsiString(AStr);

  for nIndex := 1 to Length(sTemp) do
  begin
    if nIndex > 1 then
      Result := Result + ' ';

    Result := Result + IntToHex(Ord(sTemp[nIndex]), 2);
  end;
end;

function AnsiHexToStr(const AStr: String): String;
var
  nIndex: Integer;
  sTemp: AnsiString;
  Arr: array of byte;
begin
  Result := '';
  //sTemp := AnsiString(AStr);

  SetLength(Arr, Length(AStr) div 2);
  for nIndex := 0 to (Length(AStr) div 2 - 1) do
  begin
    Arr[nIndex] := StrToInt('$' + AStr[nIndex*2+1] + AStr[nIndex*2+2]);
  end;

  //for nIndex:=0 to High(arr) do
  //  Result := Result + WriteLn(arr[nIndex]);

  SetString(sTemp, PAnsiChar(@arr[0]), Length(arr));
  Result := String(sTemp);

  //unsigned char buf[10];
  //HexToBin("38FC3034303530202F2F2F2C",buf,10);
end;

function StringToHex(const S: string): string;
var
  Index: Integer;
begin
  Result := '';
  for Index := 1 to Length(S) do
    Result := Result + IntToHex( Byte( S[Index] ), 2 );
end;


//로컬 시각 변경
function SetSystemTimeChange(const ADateTime: TDateTime): Boolean;
var
  dSysTime: TSystemTime;
begin
  Result := False;
  try
    DateTimeToSystemTime(ADateTime, dSysTime);
    if SetLocalTime(dSysTime) = true then
      Result := True;

  except
  end;
end;

function GetBaudrate(const ABaudrate: Integer): TBaudRate;
begin
  case ABaudrate of
    9600:   Result := br9600;
    14400:  Result := br14400;
    19200:  Result := br19200;
    38400:  Result := br38400;
    57600:  Result := br57600;
    115200: Result := br115200;
    128000: Result := br128000;
    256000: Result := br256000;
  else
    Result := br9600;
  end;
end;

function GetParity(const AParity: Integer): TParityBits;
begin
  case AParity of
    0:  Result := prNone;
    1:  Result := prOdd;
    2:  Result := prEven;
    3:  Result := prMark;
    4:  Result := prSpace;
  else
    Result := prNone;
  end;
end;

//function MyExitWindows(RebootParam: Longword): Boolean;
function MyExitWindows: Boolean;
var
  TTokenHd: THandle;
  TTokenPvg: TTokenPrivileges;
  cbtpPrevious: DWORD;
  rTTokenPvg: TTokenPrivileges;
  pcbtpPreviousRequired: DWORD;
  tpResult: Boolean;
const
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    tpResult := OpenProcessToken(GetCurrentProcess(),
      TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
      TTokenHd);
    if tpResult then
    begin
      tpResult := LookupPrivilegeValue(nil,
                                       SE_SHUTDOWN_NAME,
                                       TTokenPvg.Privileges[0].Luid);
      TTokenPvg.PrivilegeCount := 1;
      TTokenPvg.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
      cbtpPrevious := SizeOf(rTTokenPvg);
      pcbtpPreviousRequired := 0;
      if tpResult then
        AdjustTokenPrivileges(TTokenHd,
                                      False,
                                      TTokenPvg,
                                      cbtpPrevious,
                                      rTTokenPvg,
                                      pcbtpPreviousRequired);
    end;
  end;
  //Result := ExitWindowsEx(RebootParam, 0);
  Result := ExitWindowsEx(EWX_REBOOT, 0);
end;

function isNumber(s: String): Boolean;
var i: Integer;
begin
  Result:=True;

  if Length(Trim(s))=0 then begin
    Result:=False;
    Exit;
  end;

  s:=Trim(s);
  for i:=1 to Length(s) do begin
    if not CharInSet(s[i], ['0'..'9']) then begin
      Result:=False;
      Exit;
    end;
  end;
end;

function URLEncode(const psSrc: string): string;
const
 UnsafeChars = ' *#%<>';
var
 i: Integer;
begin
  Result := '';
  for i := 1 to Length(psSrc) do
  begin
    if (IndyPos(psSrc[i], UnsafeChars) > 0) or (psSrc[i] >= #$80) then
    begin
      Result := Result + '%' + IntToHex(Ord(psSrc[i]), 2);
    end
    else
    begin
      Result := Result + psSrc[i];
    end;
  end;
end;

procedure FreeAndNilJSONObject(AObject: TJSONAncestor);
begin
  if Assigned(AObject) then
  begin
    AObject.Owned := False;
    FreeAndNil(AObject);
  end;
end;

// 10진수를 2진수로...
function DecToBinStr(n: integer): String;
var
  S: string;
  i: integer;
  Negative: boolean;
begin
  if n = 0 then
  begin
    Result := '0';
    System.Exit;
  end;
  Negative := False;
  if n < 0 then
    Negative := True; // 음수표시
    n := Abs(n);
    for i := 1 to SizeOf(n) * 8 do
    begin
      if n < 0 then
        S := S + '1' else S := S + '0';
      n := n shl 1;
    end;
  Delete(S,1,Pos('1',S) - 1); //remove leading zeros
  if Negative then
    S := '-' + S;
  Result := S;
end;

// 문자를 10진수로...
function CharToInteger(chr: Char): Integer;
begin
  Result := Ord(chr);
end;

function IfThen(IsTrue: Boolean; AValue, BValue: Variant): Variant;
begin
  if IsTrue then
    Result := AValue
  else
    Result := BValue;
end;

//암호화
function StrEncrypt(const AStr: AnsiString): AnsiString;
const
  HexData: array[0..9] of Integer = (186, 165, 20, 188, 61, 85, 171, 61, 244, 164);
var
  i, sKey, sRndCnt: Integer;
  strRet, strTemp: AnsiString;
  PWord: ^AnsiChar;
begin
  Randomize();
  sKey := Random(254);
  sRndCnt := Random(9) + 5;
  strRet := strRet + Format('%.2X', [((sRndCnt xor sKey) xor HexData[5])]);

	sKey := sKey xor HexData[9];

  for i := 1 to sRndCnt do
    strRet := strRet + Format('%.2X', [Random(254) xor sKey]);

	sKey := sKey xor HexData[5];

  i := 0;
  while(i < Length(aStr)) do
  begin
    PWord := Pointer(PAnsiChar(aStr) + i);
    strTemp := Format('%.2X', [(Ord(PWord^) xor sKey) xor HexData[i mod 10]]);
    strRet := strRet + strTemp;
    Inc(i);
  end;
  strTemp := Format('%.2X', [sKey]);
  Result := strTemp + strRet;
end;

//복호화
function StrDecrypt(const AStr: AnsiString): AnsiString;
const
  HexData: array[0..9] of Integer = (186, 165, 20, 188, 61, 85, 171, 61, 244, 164);
var
  i, sLen, iPos, sKey, sBaseKey, sRndCnt, iTmp: Integer;
  strRet, strTemp: AnsiString;
begin
  Result := '';
  sLen := Length(aStr);
  if sLen < 6 then Exit;

  sBaseKey := StrToInt('$' + Copy(aStr, 1, 2));
	sKey := sBaseKey xor HexData[5];
	sKey := sKey xor HexData[9];

  sRndCnt := ((StrToInt('$' + Copy(aStr, 3, 2)) xor HexData[5]) xor sKey);
	iPos := 4 + sRndCnt * 2 + 1;

	if sLen <= iPos then Exit;

	sKey := sBaseKey;
  i := 0;
  while iPos < sLen do
  begin
    strTemp := '$' + Copy(aStr, iPos, 2);
    iTmp := ((StrToInt(strTemp) xor HexData[i mod 10]) xor sKey);
    strRet := strRet + Chr(iTmp);
    Inc(i);
    iPos := iPos + 2;
  end;
  Result := strRet;
end;

//26. 2진수를 10진수로 바꾸는 방법
function Bin2Dec(BinString: string): LongInt;
var
  i : Integer;
  Num : LongInt;
begin

  Num := 0;
  for i := 1 to Length(BinString) do
    if BinString[i] = '1' then Num := (Num shl 1) + 1
                          else Num := (Num shl 1);

  Result := Num;
end;

function IsRunningProcess(const ProcName: String) : Boolean;
var
  Process32: TProcessEntry32;
  SHandle:   THandle;
  Next:      Boolean;

begin
  Result:=False;

  Process32.dwSize:=SizeOf(TProcessEntry32);
  SHandle         :=CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  // 프로세스 리스트를 돌면서 매개변수로 받은 이름과 같은 프로세스가 있을 경우 True를 반환하고 루프종료
  if Process32First(SHandle, Process32) then begin
    repeat
      Next:=Process32Next(SHandle, Process32);
      if AnsiCompareText(Process32.szExeFile, Trim(ProcName))=0 then begin
        Result:=True;
        break;
      end;
    until not Next;
  end;
  CloseHandle(SHandle);
end;

function KillProcess(const ProcName: String): Boolean;
var
  Process32: TProcessEntry32;
  SHandle:   THandle;
  Next:      Boolean;
  hProcess: THandle;
  i: Integer;
  bUse: Boolean;
begin
  Result:=True;

  Process32.dwSize       :=SizeOf(TProcessEntry32);
  Process32.th32ProcessID:=0;
  SHandle                :=CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  // 종료하고자 하는 프로세스가 실행중인지 확인하는 의미와 함께...
  bUse := False;
  if Process32First(SHandle, Process32) then begin
    repeat
      Next:=Process32Next(SHandle, Process32);
      if AnsiCompareText(Process32.szExeFile, Trim(ProcName)) = 0 then
      begin
        bUse := True;
        break;
      end;
    until not Next;
  end;
  CloseHandle(SHandle);

  if bUse = False then
  begin
    Result := False;
    Exit;
  end;

  // 프로세스가 실행중이라면 Open & Terminate
  if Process32.th32ProcessID<>0 then begin
    hProcess:=OpenProcess(PROCESS_TERMINATE, True, Process32.th32ProcessID);
    if hProcess<>0 then begin
      if not TerminateProcess(hProcess, 0) then Result:=False;
    end
    // 프로세스 열기 실패
    else Result:=False;

    CloseHandle(hProcess);
  end // if Process32.th32ProcessID<>0
  else Result:=False;
end;

function MD5Str(const S: String): String;
var
  IdMD5: TIdHashMessageDigest5;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  try
    Result := idmd5.HashStringAsHex(s);
  finally
    freeandnil(idmd5);
  end;

end;

end.
