(*******************************************************************************

  Filename    : uArpHelper.pas
  Author      : ÀÌ¼±¿ì
  Description : ARP using IPHelper
  History     :
    Version   Date         Remark
    --------  ----------   -----------------------------------------------------
    1.0.0.0   2021-09-30   Initial Release.

*******************************************************************************)
unit uArpHelper;

interface

uses
  System.Classes, System.SysUtils, Winapi.Windows, IPHelper, IPHlpAPI;

type
  TARPEntryType = (aetNone, aetOther, aetInvalid, aetDynamic, aetStatic);

  PARPInfo = ^TARPInfo;
  TARPInfo = record
    Index: DWORD;
    MAC: string;
    IP: string;
    EntryType: TARPEntryType;
  end;

  TARPTable = class
  private
    FList: TList;
    FLastUpdated: TDateTime;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Refresh;
    function IP(const AMAC: string): string;
    function MAC(const AIP: string): string;
    function EntryType(const AIndex: DWORD): TARPEntryType;

    function GetARPInfo(const AIndex: DWORD; var AMac, AIP: String): Boolean;

    property List: TList read FList;
    property LastUpdated: TDateTime read FLastUpdated write FLastUpdated;
  end;

implementation

{ TARPTable }

constructor TARPTable.Create;
begin
  inherited;

  FList := TList.Create;
  Refresh;
end;

destructor TARPTable.Destroy;
var
  I: Integer;
begin
  for I := 0 to Pred(FList.Count) do
    Dispose(PARPInfo(FList[I]));
  FList.Free;

  inherited;
end;

procedure TARPTable.Refresh;
var
  IPNetRow: TMIBIPNetRow;
  dwTableSize, dwNumEntries, dwErrorCode: DWORD;
  pBuffer: PAnsiChar;
  sMACAddr, sIPAddr: string;
  P: PARPInfo;
  I: Integer;
begin
  FList.Clear;
  if not LoadIpHlp then
    raise Exception.Create('IPHelper Error');
  if not Assigned(FList) then
    raise Exception.Create('Unassigned ARP-Table');

  dwTableSize := 0;
  dwErrorCode := GetIPNetTable(nil, @dwTableSize, False);
  if (dwErrorCode = ERROR_NO_DATA) then
    raise Exception.Create('ARP-cache Empty');

  GetMem(pBuffer, dwTableSize);
  dwNumEntries := 0;
  try
    dwErrorCode := GetIpNetTable(PTMIBIPNetTable(pBuffer), @dwTableSize, False);
    if (dwErrorCode = NO_ERROR) then
    begin
      dwNumEntries := PTMIBIPNetTable(pBuffer)^.dwNumEntries;
      if (dwNumEntries > 0) then
      begin
        Inc(pBuffer, SizeOf(DWORD)); // get past table size
        for I := 1 to dwNumEntries do
        begin
          IPNetRow := PTMIBIPNetRow(pBuffer)^;
          with IPNetRow do
          begin
            try
              New(P);
              P^.Index := dwIndex;
              P^.MAC := MacAddr2Str(bPhysAddr, dwPhysAddrLen);
              P^.IP := StringReplace(IPAddr2Str(dwAddr), ' ', '', [rfReplaceAll]);
              P^.EntryType := TARPEntryType(dwType);
              FList.Add(P);
            except
              Dispose(P);
            end;
          end;

          Inc(pBuffer, SizeOf(IPNetRow));
        end;
      end
      else
        raise Exception.Create('ARP-cache Empty');
    end
    else
      raise Exception.Create(SysErrorMessage(dwErrorCode));
  finally
    Dec(pBuffer, SizeOf(DWORD) + dwNumEntries * SizeOf(IPNetRow));
    FreeMem(pBuffer);
    FLastUpdated := Now;
  end ;
end;

function TARPTable.IP(const AMAC: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Pred(FList.Count) do
    if (PARPInfo(FList[I])^.MAC = AMAC) then
    begin
      Result := PARPInfo(FList[I])^.IP;
      Break;
    end;
end;

function TARPTable.MAC(const AIP: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Pred(FList.Count) do
    if (PARPInfo(FList[I])^.IP = AIP) then
    begin
      Result := PARPInfo(FList[I])^.MAC;
      Break;
    end;
end;

function TARPTable.EntryType(const AIndex: DWORD): TARPEntryType;
var
  I: Integer;
begin
  Result := aetNone;
  for I := 0 to Pred(FList.Count) do
    if (PARPInfo(FList[I])^.Index = AIndex) then
    begin
      Result := PARPInfo(FList[I])^.EntryType;
      Break;
    end;
end;

function TARPTable.GetARPInfo(const AIndex: DWORD; var AMac, AIP: String): Boolean;
begin
  Result := False;

  if (PARPInfo(FList[AIndex])^.EntryType = TARPEntryType.aetDynamic) then
  begin
    AMac := PARPInfo(FList[AIndex])^.MAC;
    AIP := PARPInfo(FList[AIndex])^.IP;
    Result := True;
  end;

end;

end.
