unit IPHelper;

{$WARN UNSAFE_TYPE off}
{$WARN UNSAFE_CAST off}
{$WARN UNSAFE_CODE off}
{$WARN SYMBOL_PLATFORM OFF}
{$WARN SYMBOL_LIBRARY OFF}
{$WARN SYMBOL_DEPRECATED OFF}

// must turn off range checking or various records declared array [0..0] die !!!!!
{$R-}
{$Q-}

// Magenta Systems Internet Protocol Helper Component
// 12th August 2011 - Release 2.5 (C) Magenta Systems Ltd, 2011
// based on work by by Dirk Claessens

// Copyright by Angus Robertson, Magenta Systems Ltd, England
// delphi@magsys.co.uk, http://www.magsys.co.uk/delphi/


(*
  ==========================
  Delphi IPHelper functions
  ==========================
  Requires : NT4/SP4 or higher, WIN98/WIN98se
  Originally Developed on: D4.03
  Originally Tested on   :  WIN-NT4/SP6, WIN98se, WIN95/OSR1

  Warning - currently only supports Delphi 5 and later unless int64 is removed
  (Int64 is only used to force Format to show unsigned 32-bit numbers)

  ================================================================
                    This software is FREEWARE
                    -------------------------
  If this software works, it was surely written by Dirk Claessens
  http://users.pandora.be/dirk.claessens2/
  (If it doesn't, I don't know anything about it.)
  ================================================================

  Version: 1.2 2000-12-03
{ List of Fixes & Additions

v1.1
-----
Fix :  wrong errorcode reported in GetNetworkParams()
Fix :  RTTI MaxHops 20 > 128
Add :  ICMP -statistics
Add :  Well-Known port numbers
Add :  RecentIP list
Add :  Timer update

v1.2
----
Fix :  Recent IP's correct update
ADD :  ICMP-error codes translated

v1.3 - 18th September 2001
----
  Angus Robertson, Magenta Systems Ltd, England
     delphi@magsys.co.uk, http://www.magsys.co.uk/delphi/
  Slowly converting procs into functions that can be used by other programs,
     ie Get_ becomes IpHlp
  Primary improvements are that current DNS server is now shown, also
     in/out bytes for each interface (aka adaptor)
  All functions are dynamically loaded so program can be used on W95/NT4
  Tested with Delphi 6 on Windows 2000 and XP

v1.4 - 28th February 2002 - Angus
----
  Fixed major memory leak in IpHlpIfTable (except instead of finally)
  Fixed major memory leak in Get_AdaptersInfo (incremented buffer pointer)
  Created IpHlpAdaptersInfo which returns TAdaptorRows

v 1.5 - 26 July 2002 - Angus
-----
  Using GetPerAdapterInfo to get DNS adapter info for each adapter

v 1.6 - 19 August 2002 - Angus
-----
  Added IpHlpTCPTable and IpHlpUDPTable which returns TConnRows
  On XP, use undocumented APIs for improved connections list adding process and EXE

v1.7 - 14th October 2003 - Angus
  Force range checking off to avoid errors in array [0..0], should really use pointers
  Validate dwForwardProto to check for bad values

v1.8 - 25th October 2005 - Angus
  Added extra elements to TConnInfo for end user application

v1.9 - 8th August 2006 - Angus
  Interfaces now show type description, adaptor correct type description


v2.0 - 25th February 2007 - Angus
   Many more IF_xx_ADAPTER type literals, thanks to Jean-Pierre Turchi

  Note: IpHlpNetworkParams returns dynamic DNS address (and other stuff)
  Note: IpHlpIfEntry returns bytes in/out for a network adaptor

v2.1 - 5th August 2008 - Angus
    Updated to be compatible with Delphi 2009

v2.2 - 16th January 2009 - Angus
    Added GetAdaptersAddresses (XP and later) has IPv6 addresses (bit not yet getting them)
      Note: gateway IPs don't seem to be returned by GetAdaptersAddresses
    Added GetExtendedTcpTable and GetExtendedUdpTable (XP SP2, W2K3 SP1, Vista and later),
      replacements for AllocateAndGetTcpExTableFromStack/etc, added connection start time
    Using WideString for program paths and adaptor descriptions for Unicode compatibility
    Added two public variables:
     ShowExePath if true displays full program path for connection tables
     UseAdressesAPI if true uses GetAdaptersAddresses instead of GetAdaptersInfo

v2.3 - 3rd August 2009
    Changed ULONGLONG to LONGLONG for Delphi 7 compatability

v2.4 - 8th August 2010
    Fixed various cast warning for Delphi 2009 and later

v2.5 - 12th August 2011
    Tested with 32-bit and 64-bit in Delphi XE2 

*)

interface

uses
  Windows, Messages, SysUtils, Classes, Dialogs, IpHlpApi, Psapi, Winsock,
  TypInfo ;

const
  NULL_IP       = '  0.  0.  0.  0';

//------conversion of well-known port numbers to service names----------------

type
  TWellKnownPort = record
    Prt: DWORD;
    Srv: string;
  end;

const
    // only most "popular" services...
  WellKnownPorts: array[1..27] of TWellKnownPort
  = ( ( Prt: 7; Srv: 'ECHO' ), {ping}
    ( Prt: 9; Srv: 'DISCRD' ), { Discard}
    ( Prt: 13; Srv: 'DAYTIM' ), {DayTime}
    ( Prt: 17; Srv: 'QOTD' ), {Quote Of The Day}
    ( Prt: 19; Srv: 'CHARGEN' ), {CharGen}
    ( Prt: 20; Srv: 'FTP ' ),
    ( Prt: 21; Srv: 'FTPC' ), { File Transfer Control Protocol}
    ( Prt: 23; Srv: 'TELNET' ), {TelNet}
    ( Prt: 25; Srv: 'SMTP' ), { Simple Mail Transfer Protocol}
    ( Prt: 37; Srv: 'TIME' ),
    ( Prt: 53; Srv: 'DNS ' ),
    ( Prt: 67; Srv: 'BOOTPS' ), { BOOTP Server }
    ( Prt: 68; Srv: 'BOOTPC' ), { BOOTP Client }
    ( Prt: 69; Srv: 'TFTP' ), { Trivial FTP  }
    ( Prt: 70; Srv: 'GOPHER' ), { Gopher       }
    ( Prt: 79; Srv: 'FING' ), { Finger       }
    ( Prt: 80; Srv: 'HTTP' ), { HTTP         }
    ( Prt: 88; Srv: 'KERB' ), { Kerberos     }
    ( Prt: 109; Srv: 'POP2' ), { Post Office Protocol Version 2 }
    ( Prt: 110; Srv: 'POP3' ), { Post Office Protocol Version 3 }
    ( Prt: 119; Srv: 'NNTP' ), { Network News Transfer Protocol }
    ( Prt: 123; Srv: 'NTP ' ), { Network Time protocol          }
    ( Prt: 135; Srv: 'LOCSVC'), { Location Service              }
    ( Prt: 137; Srv: 'NBNAME' ), { NETBIOS Name service          }
    ( Prt: 138; Srv: 'NBDGRAM' ), { NETBIOS Datagram Service     }
    ( Prt: 139; Srv: 'NBSESS' ), { NETBIOS Session Service        }
    ( Prt: 161; Srv: 'SNMP' ) { Simple Netw. Management Protocol }
    );


//-----------conversion of ICMP error codes to strings--------------------------
             {taken from www.sockets.com/ms_icmp.c }

const
  ICMP_ERROR_BASE = 11000;
  IcmpErr : array[1..22] of string =
  (
   'IP_BUFFER_TOO_SMALL','IP_DEST_NET_UNREACHABLE', 'IP_DEST_HOST_UNREACHABLE',
   'IP_PROTOCOL_UNREACHABLE', 'IP_DEST_PORT_UNREACHABLE', 'IP_NO_RESOURCES',
   'IP_BAD_OPTION','IP_HARDWARE_ERROR', 'IP_PACKET_TOO_BIG', 'IP_REQUEST_TIMED_OUT',
   'IP_BAD_REQUEST','IP_BAD_ROUTE', 'IP_TTL_EXPIRED_TRANSIT',
   'IP_TTL_EXPIRED_REASSEM','IP_PARAMETER_PROBLEM', 'IP_SOURCE_QUENCH',
   'IP_OPTION_TOO_BIG', 'IP_BAD_DESTINATION','IP_ADDRESS_DELETED',
   'IP_SPEC_MTU_CHANGE', 'IP_MTU_CHANGE', 'IP_UNLOAD'
  );


//----------conversion of diverse enumerated values to strings------------------

  ARPEntryType  : array[0..4] of string = ('', 'Other', 'Invalid',
    'Dynamic', 'Static'
    );
  TCPConnState  :
    array[0..12] of string =
    ('',  'closed', 'listening', 'syn_sent',
    'syn_rcvd', 'established', 'fin_wait1',
    'fin_wait2', 'close_wait', 'closing',
    'last_ack', 'time_wait', 'delete_tcb'
    );

  TCPToAlgo     : array[0..4] of string =
    ('',  'Const.Timeout', 'MIL-STD-1778',
    'Van Jacobson', 'Other' );

  IPForwTypes   : array[0..4] of string =
    ('',  'other', 'invalid', 'local', 'remote' );

  IPForwProtos  : array[0..18] of string =
    ('',  'OTHER', 'LOCAL', 'NETMGMT', 'ICMP', 'EGP',
    'GGP', 'HELO', 'RIP', 'IS_IS', 'ES_IS',
    'CISCO', 'BBN', 'OSPF', 'BGP', 'BOOTP',
    'AUTO_STAT', 'STATIC', 'NOT_DOD' );

type

// for IpHlpNetworkParams
  TNetworkParams = record
    HostName: string ;
    DomainName: string ;
    CurrentDnsServer: string ;
    DnsServerTot: integer ;
    DnsServerNames: array [0..9] of string ;
    NodeType: UINT;
    ScopeID: string ;
    EnableRouting: UINT;
    EnableProxy: UINT;
    EnableDNS: UINT;
  end;

  TIfRows = array of TMibIfRow ; // dynamic array of rows

// for IpHlpAdaptersInfo
  TAdaptorInfo = record
    AdapterName: WideString ;  // 14 Jan 2009, was string
    Description: WideString ;  // 14 Jan 2009, was string
    MacAddress: string ;
    Index: DWORD;
    aType: UINT;
    DHCPEnabled: UINT;
    CurrIPAddress: string ;
    CurrIPMask: string ;
    IPAddressTot: integer ;
    IPAddressList: array of string ;
    IPMaskList: array of string ;
    GatewayTot: integer ;
    GatewayList: array of string ;
    DHCPTot: integer ;
    DHCPServer: array of string ;
    HaveWINS: BOOL;
    PrimWINSTot: integer ;
    PrimWINSServer: array of string ;
    SecWINSTot: integer ;
    SecWINSServer: array of string ;
    LeaseObtained: LongInt ; // UNIX time, seconds since 1970
    LeaseExpires: LongInt;   // UNIX time, seconds since 1970
    AutoConfigEnabled: UINT ;  // next 4 from IP_Per_Adaptor_Info, W2K and later
    AutoConfigActive: UINT ;
    CurrentDNSServer: string ;
    DNSServerTot: integer ;
    DNSServerList: array of string ;
// following from GetAdaptersAddresses for Vista and later, a few for XP
    AnycastIPAddrList: array of string ;
    AnycastIPAddrTot: integer ;
    MulticastIPAddrList: array of string ;
    MulticastIPAddrTot: integer ;
    PrefixIPAddrList: array of string ;
    FriendlyName: WideString ;
    Mtu: DWORD;
    IfType: DWORD;
    OperStatus: TIF_OPER_STATUS;
    Ipv6Index: DWORD;
    XmitLinkSpeed: Int64;
    RecvLinkSpeed: Int64;
    Ipv4Metric: ULONG;
    Ipv6Metric: ULONG;
    Luid: IF_LUID;
    CompartmentId: NET_IF_COMPARTMENT_ID;
    NetworkGuid: NET_IF_NETWORK_GUID;
    ConnectionType: NET_IF_CONNECTION_TYPE;
    TunnelType: TUNNEL_TYPE;
  end ;

  TAdaptorRows = array of TAdaptorInfo ;

// for IpHlpTCPStatistics and IpHlpUDPStatistics
  TConnInfo = record
    State: Integer ;
    LocalAddr: String ;
    LocalPort: Integer ;
    RemoteAddr: String ;
    RemotePort: Integer ;
    ProcessID: DWORD ;
    LocalHost: string ;   // 13 Oct 2004 - not used in this component, but for DNS lookups and display
    RemoteHost: string ;
    DispRow: integer ;
    ProcName: WideString ;    // 15 Jan 2009 - Unicode
    CreateDT: TDateTime ;     // 15 Jan 2009
  end;

  TConnRows = array of TConnInfo ;

// NT process stuff
    TProcessObject = record
  				 	ProcessID: DWORD;       // this process
    				DefaultHeapID: DWORD;
    				ModuleID: DWORD;        // associated exe
    				CountThreads: DWORD;
    				ParentProcessID: DWORD; // this process's parent process
    				PriClassBase: Longint;	// Base priority of process's threads
    				Flags: DWORD;
    				ExeFile: string ;		// Path
 				end ;
  PTProcessObject = ^TProcessObject;

//---------------exported stuff-----------------------------------------------

function IpHlpAdaptersInfo(var AdpTot: integer;var AdpRows: TAdaptorRows): integer ;
procedure Get_AdaptersInfo( List: TStrings );
function IpHlpNetworkParams (var NetworkParams: TNetworkParams): integer ;
procedure Get_NetworkParams( List: TStrings );
procedure Get_ARPTable( List: TStrings );
procedure IpHlpTCPTable(var ConnRows: TConnRows);
procedure Get_TCPTable( List: TStrings );
function IpHlpTCPStatistics (var TCPStats: TMibTCPStats): integer ;
procedure Get_TCPStatistics( List: TStrings );
procedure IpHlpUDPTable(var ConnRows: TConnRows);
procedure Get_UDPTable( List: TStrings );
function IpHlpUdpStatistics (UdpStats: TMibUDPStats): integer ;
procedure Get_UDPStatistics( List: TStrings );
procedure Get_IPAddrTable( List: TStrings );
procedure Get_IPForwardTable( List: TStrings );
function IpHlpIPStatistics (var IPStats: TMibIPStats): integer ;
procedure Get_IPStatistics( List: TStrings );
function Get_RTTAndHopCount( IPAddr: DWORD; MaxHops: Longint;
  var RTT: longint; var HopCount: longint ): integer;
procedure Get_ICMPStats( ICMPIn, ICMPOut: TStrings );
function IpHlpIfTable(var IfTot: integer; var IfRows: TIfRows): integer ;
procedure Get_IfTable( List: TStrings );
function IpHlpIfEntry(Index: integer; var IfRow: TMibIfRow): integer ;
procedure Get_RecentDestIPs( List: TStrings );

// conversion utils
function MacAddr2Str( MacAddr: TMacAddress; size: integer): string;
function IpAddr2Str( IPAddr: DWORD; const AUsePadding: Boolean=False ): string;
function Str2IpAddr( IPStr: string ): DWORD;
function Port2Str( nwoPort: DWORD ): string;
function Port2Wrd( nwoPort: DWORD ): DWORD;
function Port2Svc( Port: DWORD ): string;
function ICMPErr2Str( ICMPErrCode: DWORD) : string;

var
    ShowExePath: boolean = false ;
    UseAdressesAPI: boolean = false ;

implementation

var
  RecentIPs     : TStringList;

//--------------General utilities-----------------------------------------------


{ extracts next "token" from string, then eats string }
function NextToken( var s: string; Separator: char ): string;
var
  Sep_Pos       : byte;
begin
  Result := '';
  if length( s ) > 0 then begin
    Sep_Pos := pos( Separator, s );
    if Sep_Pos > 0 then begin
      Result := copy( s, 1, Pred( Sep_Pos ) );
      Delete( s, 1, Sep_Pos );
    end
    else begin
      Result := s;
      s := '';
    end;
  end;
end;

//------------------------------------------------------------------------------
{ concerts numerical MAC-address to ww-xx-yy-zz string }
function MacAddr2Str( MacAddr: TMacAddress; size: integer ): string;
var
  i             : integer;
begin
  if Size = 0 then
  begin
    Result := '00-00-00-00-00-00';
    EXIT;
  end
  else Result := '';
  //
  for i := 1 to Size do
    Result := Result + IntToHex( MacAddr[i], 2 ) + '-';
  Delete( Result, Length( Result ), 1 );
end;

//------------------------------------------------------------------------------
{ converts IP-address in network byte order DWORD to dotted decimal string}
function IpAddr2Str( IPAddr: DWORD; const AUsePadding: Boolean ): string;
var
  i             : integer;
begin
  Result := '';
  for i := 1 to 4 do
  begin
    Result := Result + Format( '%3d.', [IPAddr and $FF] );
    IPAddr := IPAddr shr 8;
  end;
  Delete( Result, Length( Result ), 1 );
end;

//------------------------------------------------------------------------------
{ converts dotted decimal IP-address to network byte order DWORD}
function Str2IpAddr( IPStr: string ): DWORD;
var
  i             : integer;
  Num           : DWORD;
begin
  Result := 0;
  for i := 1 to 4 do
  try
    Num := ( StrToInt( NextToken( IPStr, '.' ) ) ) shl 24;
    Result := ( Result shr 8 ) or Num;
  except
    Result := 0;
  end;

end;

//------------------------------------------------------------------------------
{ converts port number in network byte order to DWORD }
function Port2Wrd( nwoPort: DWORD ): DWORD;
begin
  Result := Swap( WORD( nwoPort ) );
end;

//------------------------------------------------------------------------------
{ converts port number in network byte order to string }
function Port2Str( nwoPort: DWORD ): string;
begin
  Result := IntToStr( Port2Wrd( nwoPort ) );
end;

//------------------------------------------------------------------------------
{ converts well-known port numbers to service ID }
function Port2Svc( Port: DWORD ): string;
var
  i             : integer;
begin
  Result := Format( '%4d', [Port] ); // in case port not found
  for i := Low( WellKnownPorts ) to High( WellKnownPorts ) do
    if Port = WellKnownPorts[i].Prt then
    begin
      Result := WellKnownPorts[i].Srv;
      BREAK;
    end;
end;

//------------------------------------------------------------------------------
// swap any number of bytes, integer, double, extended, anything
// ByteSwaps (@value, sizeof (value)) ;

procedure ByteSwaps(DataPtr : Pointer;NoBytes : integer);
var
    i : integer;
    dp : PAnsiChar;
    tmp : AnsiChar;
begin
  // Perform a sanity check to make sure that the function was called properly
    if (NoBytes > 1) then
    begin
        Dec(NoBytes);
        dp := PAnsiChar(DataPtr);
    // we are now safe to perform the byte swapping
        for i := NoBytes downto (NoBytes div 2 + 1) do
        begin
            tmp := PAnsiChar(Integer(dp)+i)^;
            PAnsiChar(Integer(dp)+i)^ := PAnsiChar(Integer(dp)+NoBytes-i)^;
            PAnsiChar(Integer(dp)+NoBytes-i)^ := tmp;
        end;
    end;
end;

//------------------------------------------------------------------------------
function FileTimeToInt64 (const FileTime: TFileTime): Int64 ;
begin
    Move (FileTime, result, SizeOf (result)) ;
end;

//------------------------------------------------------------------------------
const
  FileTimeBase = -109205.0;   // days between years 1601 and 1900
  FileTimeStep: Extended = 24.0 * 60.0 * 60.0 * 1000.0 * 1000.0 * 10.0; // 100 nsec per Day

function FileTimeToDateTime(const FileTime: TFileTime): TDateTime;
begin
    Result := FileTimeToInt64 (FileTime) / FileTimeStep ;
    Result := Result + FileTimeBase ;
end;

//-----------------------------------------------------------------------------
{ general,  fixed network parameters }

procedure Get_NetworkParams( List: TStrings );
var
    NetworkParams: TNetworkParams ;
    I, ErrorCode: integer ;
begin
    if not Assigned( List ) then EXIT;
    List.Clear;
    ErrorCode := IpHlpNetworkParams (NetworkParams) ;
    if ErrorCode <> 0 then
    begin
        List.Add (SysErrorMessage (ErrorCode));
        exit;
    end ;
    with NetworkParams do
    begin
        List.Add( 'HOSTNAME          : ' + HostName );
        List.Add( 'DOMAIN            : ' + DomainName );
        List.Add( 'DHCP SCOPE        : ' + ScopeID );
        List.Add( 'NETBIOS NODE TYPE : ' + NETBIOSTypes[NodeType] );
        List.Add( 'ROUTING ENABLED   : ' + IntToStr( EnableRouting ) );
        List.Add( 'PROXY   ENABLED   : ' + IntToStr( EnableProxy ) );
        List.Add( 'DNS     ENABLED   : ' + IntToStr( EnableDNS ) );
        if DnsServerTot <> 0 then
        begin
            for I := 0 to Pred (DnsServerTot) do
                List.Add( 'DNS SERVER ADDR   : ' + DnsServerNames [I] ) ;
        end ;
    end ;
end ;

function IpHlpNetworkParams (var NetworkParams: TNetworkParams): integer ;
var
  FixedInfo     : PTFixedInfo;         // Angus
  InfoSize      : Longint;
  PDnsServer    : PTIP_ADDR_STRING ;   // Angus
begin
    InfoSize := 0 ;   // Angus
    result := ERROR_NOT_SUPPORTED ;
    if NOT LoadIpHlp then exit ;
    result := GetNetworkParams( Nil, @InfoSize );  // Angus
    if result <> ERROR_BUFFER_OVERFLOW then exit ; // Angus
    GetMem (FixedInfo, InfoSize) ;                    // Angus
    try
    result := GetNetworkParams( FixedInfo, @InfoSize );   // Angus
    if result <> ERROR_SUCCESS then exit ;
    NetworkParams.DnsServerTot := 0 ;
    with FixedInfo^ do
    begin
        NetworkParams.HostName := Trim (String (HostName)) ;      // 8 Aug 2010
        NetworkParams.DomainName := Trim (String (DomainName)) ;  // 8 Aug 2010
        NetworkParams.ScopeId := Trim (String (ScopeID)) ;        // 8 Aug 2010
        NetworkParams.NodeType := NodeType ;
        NetworkParams.EnableRouting := EnableRouting ;
        NetworkParams.EnableProxy := EnableProxy ;
        NetworkParams.EnableDNS := EnableDNS ;
        NetworkParams.DnsServerNames [0] := String (DNSServerList.IPAddress) ;  // 8 Aug 2010
        if NetworkParams.DnsServerNames [0] <> '' then
                                        NetworkParams.DnsServerTot := 1 ;
        PDnsServer := DnsServerList.Next;
        while PDnsServer <> Nil do
        begin
            NetworkParams.DnsServerNames [NetworkParams.DnsServerTot] :=
                                       String (PDnsServer^.IPAddress) ;   // 8 Aug 2010
            inc (NetworkParams.DnsServerTot) ;
            if NetworkParams.DnsServerTot >=
                            Length (NetworkParams.DnsServerNames) then exit ;
            PDnsServer := PDnsServer.Next ;
        end;
    end ;
    finally
       FreeMem (FixedInfo) ;                     // Angus
    end ;
end;

//------------------------------------------------------------------------------

function ICMPErr2Str( ICMPErrCode: DWORD) : string;
begin
   Result := 'UnknownError : ' + IntToStr( ICMPErrCode );
   dec( ICMPErrCode, ICMP_ERROR_BASE );
   if ICMPErrCode in [Low(ICMpErr)..High(ICMPErr)] then
     Result := ICMPErr[ ICMPErrCode];
end;


//------------------------------------------------------------------------------

// include bytes in/out for each adaptor

function IpHlpIfTable(var IfTot: integer; var IfRows: TIfRows): integer ;
var
  I,
  TableSize   : integer;
  pBuf, pNext : PAnsiChar;
begin
  result := ERROR_NOT_SUPPORTED ;
  if NOT LoadIpHlp then exit ;
  SetLength (IfRows, 0) ;
  IfTot := 0 ; // Angus
  TableSize := 0;
   // first call: get memsize needed
  result := GetIfTable (Nil, @TableSize, false) ;  // Angus
  if result <> ERROR_INSUFFICIENT_BUFFER then exit ;
  GetMem( pBuf, TableSize );
  try
      FillChar (pBuf^, TableSize, #0);  // clear buffer, since W98 does not

   // get table pointer
      result := GetIfTable (PTMibIfTable (pBuf), @TableSize, false) ;
      if result <> NO_ERROR then exit ;
      IfTot := PTMibIfTable (pBuf)^.dwNumEntries ;
      if IfTot = 0 then exit ;
      SetLength (IfRows, IfTot) ;
      pNext := pBuf + SizeOf(IfTot) ;
      for i := 0 to Pred (IfTot) do
      begin
         IfRows [i] := PTMibIfRow (pNext )^ ;
         inc (pNext, SizeOf (TMibIfRow)) ;
      end;
  finally
      FreeMem (pBuf) ;
  end ;
end;

procedure Get_IfTable( List: TStrings );
var
  IfRows        : TIfRows ;
  Error, I      : integer;
  NumEntries    : integer;
  sDescr, sIfName: string ;
begin
  if not Assigned( List ) then EXIT;
  List.Clear;
  SetLength (IfRows, 0) ;
  Error := IpHlpIfTable (NumEntries, IfRows) ;
  if (Error <> 0) then
      List.Add( SysErrorMessage( GetLastError ) )
  else if NumEntries = 0 then
      List.Add( 'no entries.' )
  else
  begin
      for I := 0 to Pred (NumEntries) do
      begin
          with IfRows [I] do
          begin
             if wszName [1] = #0 then
                 sIfName := ''
             else
                 sIfName := WideCharToString (@wszName) ;  // convert Unicode to string
             sIfName := Trim (sIfName) ;
             sDescr := Trim (String (bDescr)) ;   // 8 Aug 2010
             List.Add (Format (
               '%0.8x |%6s |%16s |%8d |%12d |%2d |%2d |%10d |%10d | %-s| %-s',
               [dwIndex, AdaptTypes[dwType], MacAddr2Str( TMacAddress( bPhysAddr ),
               dwPhysAddrLen ), dwMTU, dwSpeed, dwAdminStatus,
               dwOPerStatus, Int64 (dwInOctets), Int64 (dwOutOctets),  // counters are 32-bit
               sIfName, sDescr] )  // Angus, added in/out
               );
          end;
      end ;
  end ;
  SetLength (IfRows, 0) ;  // free memory
end ;

function IpHlpIfEntry(Index: integer; var IfRow: TMibIfRow): integer ;
begin
  result := ERROR_NOT_SUPPORTED ;
  if NOT LoadIpHlp then exit ;
  FillChar (IfRow, SizeOf (TMibIfRow), #0);  // clear buffer, since W98 does not
  IfRow.dwIndex := Index ;
  result := GetIfEntry (@IfRow) ;
end ;

//-----------------------------------------------------------------------------
{ Info on installed adapters }

function IpHlpAdaptersInfo(var AdpTot: integer;var AdpRows: TAdaptorRows): integer ;
var
  BufLen        : DWORD;
  AdapterInfo   : PTIP_ADAPTER_INFO;
  PIpAddr       : PTIP_ADDR_STRING;
  PBuf          : PAnsiChar ;
  I, J          : integer ;
  PerAdapterInfo: TIP_PER_ADAPTER_INFO ;
  ret, len      : integer ;
  Family, Flags : LongWord ;
  AdapterAddresses : PIP_ADAPTER_ADDRESSES;
  UnicastAddress   : PIP_ADAPTER_UNICAST_ADDRESS;
  AnycastAddress   : PIP_ADAPTER_ANYCAST_ADDRESS;
  MulticastAddress : PIP_ADAPTER_MULTICAST_ADDRESS;
  DnsServerAddress : PIP_ADAPTER_DNS_SERVER_ADDRESS;
  PrefixAddress    : PIP_ADAPTER_PREFIX;  // aka mask
  WinsServerAddress: PIP_ADAPTER_WINS_SERVER_ADDRESS;
  GatewayAddress   : PIP_ADAPTER_GATEWAY_ADDRESS;
  MaskIP           : LongWord ;
  AdapterAddressLen: integer;

  function ConvertSockAddr (MyAddress: SOCKET_ADDRESS): string ;
  begin
      result := '' ;
      if MyAddress.iSockaddrLength <> 16 then exit ; // sanity check
      if MyAddress.lpSockaddr.sin_family = AF_INET then  // IP4
            result := IpAddr2Str (MyAddress.lpSockaddr.sin_addr.S_addr) ;
  end;

begin
  result := ERROR_NOT_SUPPORTED ;
  if NOT LoadIpHlp then exit ;
  SetLength (AdpRows, 4) ;
  AdpTot := 0 ;
  BufLen := 0 ;
  if UseAdressesAPI and Assigned (GetAdaptersAddresses) then
  begin
      Family := AF_INET ;   // or AF_INET6 or AF_UNSPEC for IP4 and IP6
      Flags := GAA_FLAG_INCLUDE_PREFIX ;  // probably only flag that works on XP
      result := GetAdaptersAddresses ( Family, Flags, Nil, Nil, @BufLen) ;
      if (result <> ERROR_BUFFER_OVERFLOW) then exit ;
      GetMem( pBuf, BufLen );
      try
          FillChar (pBuf^, BufLen, #0);  // clear buffer
          result := GetAdaptersAddresses ( Family, Flags, Nil, PIP_ADAPTER_ADDRESSES(PBuf), @BufLen );
          if result = NO_ERROR then
          begin
             AdapterAddresses := PIP_ADAPTER_ADDRESSES(PBuf) ;
             while ( AdapterAddresses <> nil ) do
             begin
                AdapterAddressLen := AdapterAddresses^.Union.Length ; // 144 for XP SP3, 376 for Win7
                AdpRows [AdpTot].IPAddressTot := 0 ;
                SetLength (AdpRows [AdpTot].IPAddressList, 2) ;
                SetLength (AdpRows [AdpTot].IPMaskList, 2) ;
                AdpRows [AdpTot].GatewayTot := 0 ;
                SetLength (AdpRows [AdpTot].GatewayList, 2) ;
                AdpRows [AdpTot].DHCPTot := 0 ;
                SetLength (AdpRows [AdpTot].DHCPServer, 2) ;
                AdpRows [AdpTot].PrimWINSTot := 0 ;
                SetLength (AdpRows [AdpTot].PrimWINSServer, 2) ;
                AdpRows [AdpTot].SecWINSTot := 0 ;
                SetLength (AdpRows [AdpTot].SecWINSServer, 2) ;
                AdpRows [AdpTot].DNSServerTot := 0 ;
                SetLength (AdpRows [AdpTot].DNSServerList, 2) ;
                AdpRows [AdpTot].DNSServerList [0] := '' ;
                AdpRows [AdpTot].AnycastIPAddrTot := 0 ;
                SetLength (AdpRows [AdpTot].AnycastIPAddrList, 2) ;
                AdpRows [AdpTot].MulticastIPAddrTot := 0 ;
                SetLength (AdpRows [AdpTot].MulticastIPAddrList, 2) ;
                SetLength (AdpRows [AdpTot].PrefixIPAddrList, 2) ;
                AdpRows [AdpTot].CurrIPAddress := NULL_IP;
                AdpRows [AdpTot].CurrIPMask := NULL_IP;
                AdpRows [AdpTot].AdapterName := WideString (AdapterAddresses^.AdapterName) ; // 8 Aug 2010
                AdpRows [AdpTot].Description := AdapterAddresses^.Description ;
                AdpRows [AdpTot].FriendlyName := AdapterAddresses^.FriendlyName ;
                AdpRows [AdpTot].MacAddress := MacAddr2Str( TMacAddress(
                     AdapterAddresses^.PhysicalAddress ), AdapterAddresses^.PhysicalAddressLength ) ;
                AdpRows [AdpTot].Index := AdapterAddresses^.Union.IfIndex ;   // IP4 interface ID
                AdpRows [AdpTot].aType := AdapterAddresses^.IfType ;
                AdpRows [AdpTot].DHCPEnabled := 0 ;
                if ((AdapterAddresses^.Flags AND IP_ADAPTER_DHCP_ENABLED) =
                                    IP_ADAPTER_DHCP_ENABLED) then AdpRows [AdpTot].DHCPEnabled := 1 ;
                AdpRows [AdpTot].Mtu := AdapterAddresses^.Mtu ;
                AdpRows [AdpTot].IfType := AdapterAddresses^.IfType ;
                AdpRows [AdpTot].OperStatus := AdapterAddresses^.OperStatus ;

            // Unicast, IP for single interface, get list of IP addresses and masks for IPAddressList
                I := 0 ;
                UnicastAddress := AdapterAddresses^.FirstUnicastAddress ;
                while (UnicastAddress <> Nil) do
                begin
                    len := UnicastAddress.Union.Length ;
                    if len <> 48 then break ; // sanity check
                    AdpRows [AdpTot].IPAddressList [I] := ConvertSockAddr (UnicastAddress.Address) ;
                    UnicastAddress := UnicastAddress.Next ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].IPAddressList) <= I then
                    begin
                         SetLength (AdpRows [AdpTot].IPAddressList, I * 2) ;
                         SetLength (AdpRows [AdpTot].IPMaskList, I * 2) ;
                         SetLength (AdpRows [AdpTot].PrefixIPAddrList, I * 2) ;
                    end ;
                end ;
                AdpRows [AdpTot].IPAddressTot := I ;

            // Address Prefix, aka IP masks for IPAddressList - XP SP1 and later only
            // only one mask appears if they are all the same
                I := 0 ;
                PrefixAddress := AdapterAddresses^.FirstPrefix ;
                while (PrefixAddress <> Nil) do
                begin
                    len := PrefixAddress.Union.Length ;
                    if len <> 24 then break ; // sanity check
                    if PrefixAddress.PrefixLength < 32 then
                    begin
                         MaskIP := 1 ;
                         for J := 31 downto PrefixAddress.PrefixLength do MaskIP := MaskIP * 2 ;
                         MaskIP := MaxDWord - MaskIP + 1 ;
                         ByteSwaps (@MaskIP, 4) ; // convert to network order
                         AdpRows [AdpTot].IPMaskList [I] := IpAddr2Str (MaskIP) ;
                    end;
                    AdpRows [AdpTot].PrefixIPAddrList [I] := ConvertSockAddr (PrefixAddress.Address) ; // ie 192.168.0.0 for mask 255.255.0.0, len=16
                    PrefixAddress := PrefixAddress.Next ;
                    inc (I) ;
                    if I > AdpRows [AdpTot].IPAddressTot then break ;
                end ;

            // keep first IP as current, best we can do
                if AdpRows [AdpTot].IPAddressTot > 0 then
                begin
                    AdpRows [AdpTot].CurrIPAddress := AdpRows [AdpTot].IPAddressList [0] ;
                    AdpRows [AdpTot].CurrIPMask := AdpRows [AdpTot].IPMaskList [0] ;
                end ;

            // Anycast IP6, group of IP addresses
                I := 0 ;
                AnycastAddress := AdapterAddresses^.FirstAnycastAddress ;
                while (AnycastAddress <> Nil) do
                begin
                    len := AnycastAddress.Union.Length ;
                    if len <> 24 then break ; // sanity check
                    AdpRows [AdpTot].AnycastIPAddrList [I] := ConvertSockAddr (AnycastAddress.Address) ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].AnycastIPAddrList) <= I then
                         SetLength (AdpRows [AdpTot].AnycastIPAddrList, I * 2) ;
                    AnycastAddress := AnycastAddress.Next ;
                end ;
                AdpRows [AdpTot].AnycastIPAddrTot := I ;

            // Multicast IP6, broadcast IP addresses
                I := 0 ;
                MulticastAddress := AdapterAddresses^.FirstMulticastAddress ;
                while (MulticastAddress <> Nil) do
                begin
                    len := MulticastAddress.Union.Length ;
                    if len <> 24 then break ; // sanity check
                    AdpRows [AdpTot].MulticastIPAddrList [I] := ConvertSockAddr (MulticastAddress.Address) ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].MulticastIPAddrList) <= I then
                             SetLength (AdpRows [AdpTot].MulticastIPAddrList, I * 2) ;
                    MulticastAddress := MulticastAddress.Next ;
                end ;
                AdpRows [AdpTot].MulticastIPAddrTot := I ;

            // get list of DNS server addresses
                I := 0 ;
                DnsServerAddress := AdapterAddresses^.FirstDnsServerAddress ;
                while (DnsServerAddress <> Nil) do
                begin
                    len := DnsServerAddress.Union.Length ;
                    if len <> 24 then break ; // sanity check
                    AdpRows [AdpTot].DNSServerList [I] := ConvertSockAddr (DnsServerAddress.Address) ;
                    DnsServerAddress := DnsServerAddress.Next ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].DNSServerList) <= I then
                         SetLength (AdpRows [AdpTot].DNSServerList, I * 2) ;
                    AdpRows [AdpTot].CurrentDNSServer := AdpRows [AdpTot].DNSServerList [0] ;
                end ;
                AdpRows [AdpTot].DNSServerTot := I ;

            // stuff only available for Vista and later
             //   AdpRows [AdpTot].PrimWINSServer [0] := 'AddrLen=' + IntToStr (AdapterAddressLen) ; // !! TEMP
                if AdapterAddressLen > 144 then
                begin
                    AdpRows [AdpTot].Ipv6Index := AdapterAddresses^.Ipv6IfIndex ;
                    AdpRows [AdpTot].XmitLinkSpeed := AdapterAddresses^.TransmitLinkSpeed ;
                    AdpRows [AdpTot].RecvLinkSpeed := AdapterAddresses^.ReceiveLinkSpeed ;
                    AdpRows [AdpTot].Ipv4Metric := AdapterAddresses^.Ipv4Metric ;
                    AdpRows [AdpTot].Ipv6Metric := AdapterAddresses^.Ipv6Metric ;
                    AdpRows [AdpTot].Luid := AdapterAddresses^.Luid ;
                    AdpRows [AdpTot].CompartmentId := AdapterAddresses^.CompartmentId ;
                    AdpRows [AdpTot].NetworkGuid := AdapterAddresses^.NetworkGuid ;
                    AdpRows [AdpTot].ConnectionType := AdapterAddresses^.ConnectionType ;
                    AdpRows [AdpTot].TunnelType := AdapterAddresses^.TunnelType ;

                // get list of IP addresses for GatewayList
                    I := 0 ;
                    GatewayAddress := AdapterAddresses^.FirstGatewayAddress ;
               //     if (GatewayAddress = Nil) then AdpRows [AdpTot].GatewayList [0] := 'No FirstGatewayAddress' ;
                    while (GatewayAddress <> Nil) do
                    begin
                        len := GatewayAddress.Union.Length ;
                    //    AdpRows [AdpTot].GatewayList [0] :=  'Len=' + IntToStr (Len) ;
                        if len <> 24 then break ; // sanity check
                        AdpRows [AdpTot].GatewayList [I] := ConvertSockAddr (GatewayAddress.Address) ;
                        GatewayAddress := GatewayAddress.Next ;
                        inc (I) ;
                        if Length (AdpRows [AdpTot].GatewayList) <= I then
                                 SetLength (AdpRows [AdpTot].GatewayList, I * 2) ;
                    end ;
                    AdpRows [AdpTot].GatewayTot := I ;

                // get list of IP addresses for Primary WIIS Server
                    I := 0 ;
                    WinsServerAddress := AdapterAddresses^.FirstWinsServerAddress ;
                    while (WinsServerAddress <> Nil) do
                    begin
                        len := WinsServerAddress.Union.Length ;
                        if len <> 24 then break ; // sanity check
                        AdpRows [AdpTot].PrimWINSServer [I] := ConvertSockAddr (WinsServerAddress.Address) ;
                        WinsServerAddress := WinsServerAddress.Next ;
                        inc (I) ;
                        if Length (AdpRows [AdpTot].PrimWINSServer) <= I then
                                 SetLength (AdpRows [AdpTot].PrimWINSServer, I * 2) ;
                    end ;
                    AdpRows [AdpTot].PrimWINSTot := I ;

                end;

            // get ready for next adaptor
                inc (AdpTot) ;
                if Length (AdpRows) <= AdpTot then SetLength (AdpRows, AdpTot * 2) ;  // more memory
                AdapterAddresses := AdapterAddresses^.Next;
             end ;
             SetLength (AdpRows, AdpTot) ;
          end;
      finally
          FreeMem( pBuf );
      end;
  end
  else
  begin
      result := GetAdaptersInfo( Nil, @BufLen );
    //  if (result <> ERROR_INSUFFICIENT_BUFFER) and (result = NO_ERROR) then exit ;
      if (result <> ERROR_BUFFER_OVERFLOW) then exit ;  // 11 Jan 2009 should be the only result
      GetMem( pBuf, BufLen );
      try
          FillChar (pBuf^, BufLen, #0);  // clear buffer
          result := GetAdaptersInfo( PTIP_ADAPTER_INFO (PBuf), @BufLen );
          if result = NO_ERROR then
          begin
             AdapterInfo := PTIP_ADAPTER_INFO (PBuf) ;
             while ( AdapterInfo <> nil ) do
             begin
                AdpRows [AdpTot].IPAddressTot := 0 ;
                SetLength (AdpRows [AdpTot].IPAddressList, 2) ;
                SetLength (AdpRows [AdpTot].IPMaskList, 2) ;
                AdpRows [AdpTot].GatewayTot := 0 ;
                SetLength (AdpRows [AdpTot].GatewayList, 2) ;
                AdpRows [AdpTot].DHCPTot := 0 ;
                SetLength (AdpRows [AdpTot].DHCPServer, 2) ;
                AdpRows [AdpTot].PrimWINSTot := 0 ;
                SetLength (AdpRows [AdpTot].PrimWINSServer, 2) ;
                AdpRows [AdpTot].SecWINSTot := 0 ;
                SetLength (AdpRows [AdpTot].SecWINSServer, 2) ;
                AdpRows [AdpTot].DNSServerTot := 0 ;
                SetLength (AdpRows [AdpTot].DNSServerList, 2) ;
                AdpRows [AdpTot].DNSServerList [0] := '' ;
                AdpRows [AdpTot].CurrIPAddress := NULL_IP;
                AdpRows [AdpTot].CurrIPMask := NULL_IP;
                AdpRows [AdpTot].AdapterName := Trim( string( AdapterInfo^.AdapterName ) );
                AdpRows [AdpTot].Description := Trim( string( AdapterInfo^.Description ) );
                AdpRows [AdpTot].MacAddress := MacAddr2Str( TMacAddress(
                                     AdapterInfo^.Address ), AdapterInfo^.AddressLength ) ;
                AdpRows [AdpTot].Index := AdapterInfo^.Index ;
                AdpRows [AdpTot].aType := AdapterInfo^.aType ;
                AdpRows [AdpTot].DHCPEnabled := AdapterInfo^.DHCPEnabled ;
                if AdapterInfo^.CurrentIPAddress <> Nil then
                begin
                    AdpRows [AdpTot].CurrIPAddress := String (AdapterInfo^.CurrentIPAddress.IpAddress) ;   // 8 Aug 2010
                    AdpRows [AdpTot].CurrIPMask := String (AdapterInfo^.CurrentIPAddress.IpMask) ;   // 8 Aug 2010
                end ;

            // get list of IP addresses and masks for IPAddressList
                I := 0 ;
                PIpAddr := @AdapterInfo^.IPAddressList ;
                while (PIpAddr <> Nil) do
                begin
                    AdpRows [AdpTot].IPAddressList [I] := String (PIpAddr.IpAddress) ; // 8 Aug 2010
                    AdpRows [AdpTot].IPMaskList [I] := String (PIpAddr.IpMask) ;  // 8 Aug 2010
                    PIpAddr := PIpAddr.Next ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].IPAddressList) <= I then
                    begin
                         SetLength (AdpRows [AdpTot].IPAddressList, I * 2) ;
                         SetLength (AdpRows [AdpTot].IPMaskList, I * 2) ;
                    end ;
                end ;
                AdpRows [AdpTot].IPAddressTot := I ;

            // get list of IP addresses for GatewayList
                I := 0 ;
                PIpAddr := @AdapterInfo^.GatewayList ;
                while (PIpAddr <> Nil) do
                begin
                    AdpRows [AdpTot].GatewayList [I] := String (PIpAddr.IpAddress) ; // 8 Aug 2010
                    PIpAddr := PIpAddr.Next ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].GatewayList) <= I then
                                 SetLength (AdpRows [AdpTot].GatewayList, I * 2) ;
                end ;
                AdpRows [AdpTot].GatewayTot := I ;

            // get list of IP addresses for DHCP Server
                I := 0 ;
                PIpAddr := @AdapterInfo^.DHCPServer ;
                while (PIpAddr <> Nil) do
                begin
                    AdpRows [AdpTot].DHCPServer [I] := String (PIpAddr.IpAddress) ; // 8 Aug 2010
                    PIpAddr := PIpAddr.Next ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].DHCPServer) <= I then
                                 SetLength (AdpRows [AdpTot].DHCPServer, I * 2) ;
                end ;
                AdpRows [AdpTot].DHCPTot := I ;

            // get list of IP addresses for PrimaryWINSServer
                I := 0 ;
                PIpAddr := @AdapterInfo^.PrimaryWINSServer ;
                while (PIpAddr <> Nil) do
                begin
                    AdpRows [AdpTot].PrimWINSServer [I] := String (PIpAddr.IpAddress) ; // 8 Aug 2010
                    PIpAddr := PIpAddr.Next ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].PrimWINSServer) <= I then
                                 SetLength (AdpRows [AdpTot].PrimWINSServer, I * 2) ;
                end ;
                AdpRows [AdpTot].PrimWINSTot := I ;

           // get list of IP addresses for SecondaryWINSServer
                I := 0 ;
                PIpAddr := @AdapterInfo^.SecondaryWINSServer ;
                while (PIpAddr <> Nil) do
                begin
                    AdpRows [AdpTot].SecWINSServer [I] := String (PIpAddr.IpAddress) ; // 8 Aug 2010
                    PIpAddr := PIpAddr.Next ;
                    inc (I) ;
                    if Length (AdpRows [AdpTot].SecWINSServer) <= I then
                                 SetLength (AdpRows [AdpTot].SecWINSServer, I * 2) ;
                end ;
                AdpRows [AdpTot].SecWINSTot := I ;

                AdpRows [AdpTot].LeaseObtained := AdapterInfo^.LeaseObtained ;
                AdpRows [AdpTot].LeaseExpires := AdapterInfo^.LeaseExpires ;

           // get per adaptor info, W2K and later - 1.5 12 July 2002
                if Assigned (GetPerAdapterInfo) then
                begin
                    BufLen := SizeOf (PerAdapterInfo) ;
                    ret := GetPerAdapterInfo (AdpRows [AdpTot].Index, @PerAdapterInfo, @BufLen) ;
                    if ret = 0 then
                    begin
                        AdpRows [AdpTot].AutoConfigEnabled := PerAdapterInfo.AutoconfigEnabled ;
                        AdpRows [AdpTot].AutoConfigActive := PerAdapterInfo.AutoconfigActive ;
                        if PerAdapterInfo.CurrentDNSServer <> Nil then
                            AdpRows [AdpTot].CurrentDNSServer := String (PerAdapterInfo.CurrentDNSServer.IpAddress) ; // 8 Aug 2010

                    // get list of DNS IP addresses
                        I := 0 ;
                        PIpAddr := @PerAdapterInfo.DNSServerList ;
                        while (PIpAddr <> Nil) do
                        begin
                            AdpRows [AdpTot].DNSServerList [I] := String (PIpAddr.IpAddress) ; // 8 Aug 2010
                            PIpAddr := PIpAddr.Next ;
                            inc (I) ;
                            if Length (AdpRows [AdpTot].DNSServerList) <= I then
                            begin
                                 SetLength (AdpRows [AdpTot].DNSServerList, I * 2) ;
                            end ;
                        end ;
                        AdpRows [AdpTot].DNSServerTot := I ;
                    end ;
                end ;

            // get ready for next adaptor
                inc (AdpTot) ;
                if Length (AdpRows) <= AdpTot then
                                SetLength (AdpRows, AdpTot * 2) ;  // more memory
                AdapterInfo := AdapterInfo^.Next;
             end ;
             SetLength (AdpRows, AdpTot) ;
          end ;
      finally
          FreeMem( pBuf );
      end ;
  end;
end ;

procedure Get_AdaptersInfo( List: TStrings );
var
  AdpTot: integer;
  AdpRows: TAdaptorRows ;
  Error: DWORD ;
  I, J: integer ;
  S: string ;
begin
  if not Assigned( List ) then EXIT;
  List.Clear;
  SetLength (AdpRows, 0) ;
  AdpTot := 0 ;
  Error := IpHlpAdaptersInfo(AdpTot, AdpRows) ;
  if (Error <> 0) then
      List.Add( SysErrorMessage( GetLastError ) )
  else if AdpTot = 0 then
      List.Add( 'no entries.' )
  else
  begin
      for I := 0 to Pred (AdpTot) do
      begin
        with AdpRows [I] do
        begin
            List.Add(AdapterName + '|' + Description + '|' + FriendlyName);   // 19 Jan 2009 added friendly name
            List.Add( Format('%8.8x|%-6s|%16s|%2d|%16s|%16s|%16s|%16s|%-30s',
                [Index, AdaptTypes[aType], MacAddress, DHCPEnabled,
                GatewayList [0], DHCPServer [0], PrimWINSServer [0], DNSServerList [0],
                GetEnumName (TypeInfo (TIF_OPER_STATUS), Ord (OperStatus)) ] ) );  // 19 Jan 2009 added OperStatus
            if IPAddressTot <> 0 then
            begin
                S := '' ;
                for J := 0 to Pred (IPAddressTot) do
                        S := S + IPAddressList [J] + '/' + IPMaskList [J] + ' | ' ;
                List.Add(IntToStr (IPAddressTot) + ' IP Addresse(s): ' + S);
            end ;
            List.Add( '  ' );
        end ;
      end ;
  end ;
  SetLength (AdpRows, 0) ;
end ;

//-----------------------------------------------------------------------------
{ get round trip time and hopcount to indicated IP }
function Get_RTTAndHopCount( IPAddr: DWORD; MaxHops: Longint; var RTT: Longint;
  var HopCount: Longint ): integer;
begin
  result := ERROR_NOT_SUPPORTED ;
  if NOT LoadIpHlp then exit ;
  if not GetRTTAndHopCount( IPAddr, @HopCount, MaxHops, @RTT ) then
  begin
    Result := GetLastError;
    RTT := -1; // Destination unreachable, BAD_HOST_NAME,etc...
    HopCount := -1;
  end
  else
    Result := NO_ERROR;
end;

//-----------------------------------------------------------------------------
{ ARP-table lists relations between remote IP and remote MAC-address.
 NOTE: these are cached entries ;when there is no more network traffic to a
 node, entry is deleted after a few minutes.
}
procedure Get_ARPTable( List: TStrings );
var
  IPNetRow      : TMibIPNetRow;
  TableSize     : DWORD;
  NumEntries    : DWORD;
  ErrorCode     : DWORD;
  i             : integer;
  pBuf          : PAnsiChar;
begin
  if NOT LoadIpHlp then exit ;
  if not Assigned( List ) then EXIT;
  List.Clear;
  // first call: get table length
  TableSize := 0;
  ErrorCode := GetIPNetTable( Nil, @TableSize, false );   // Angus
  //
  if ErrorCode = ERROR_NO_DATA then
  begin
    List.Add( ' ARP-cache empty.' );
    EXIT;
  end;
  // get table
  GetMem( pBuf, TableSize );
  NumEntries := 0 ;
  try
  ErrorCode := GetIpNetTable( PTMIBIPNetTable( pBuf ), @TableSize, false );
  if ErrorCode = NO_ERROR then
  begin
    NumEntries := PTMIBIPNetTable( pBuf )^.dwNumEntries;
    if NumEntries > 0 then // paranoia striking, but you never know...
    begin
      inc( pBuf, SizeOf( DWORD ) ); // get past table size
      for i := 1 to NumEntries do
      begin
        IPNetRow := PTMIBIPNetRow( PBuf )^;
        with IPNetRow do
          List.Add( Format( '%8x | %12s | %16s| %10s',
                           [dwIndex, MacAddr2Str( bPhysAddr, dwPhysAddrLen ),
                           IPAddr2Str( dwAddr ), ARPEntryType[dwType]
                           ]));
        inc( pBuf, SizeOf( IPNetRow ) );
      end;
    end
    else
      List.Add( ' ARP-cache empty.' );
  end
  else
    List.Add( SysErrorMessage( ErrorCode ) );

  // we _must_ restore pointer!
  finally
      dec( pBuf, SizeOf( DWORD ) + NumEntries * SizeOf( IPNetRow ) );
      FreeMem( pBuf );
  end ;
end;

//------------------------------------------------------------------------------

// support routines to get NT processes

procedure ProcListFree (var ProcessLst: TList) ;
var
  i: integer ;
begin
  if Assigned (ProcessLst) then
  begin
      if ProcessLst.Count > 0 then
      begin
        for i := 0 To Pred (ProcessLst.Count) do
               Dispose(PTProcessObject(ProcessLst[i]));
      end;
{$IFDEF VER120} // D4
	  if Assigned (ProcessLst) then
      begin
       	 ProcessLst.Free ;
        ProcessLst := Nil ;
      end ;
{$ELSE}
      FreeAndNil (ProcessLst) ;
{$ENDIF}
  end ;
end ;

procedure ProcListGetNT (var ProcessLst: TList) ;
var
	Processes, Modules: array [0..1023] of DWORD;
	cbNeededP,cbNeededM: Cardinal;
	i,j: integer;
	hProcess: THandle;
	szProcessName: array [0..MAX_PATH-1] of WideChar;
    ProcObj: PTProcessObject;
    FileName: WideString ;  // 15 Jan 2009
begin
    if (Win32Platform <> VER_PLATFORM_WIN32_NT) then exit ;
//    if Assigned (ProcessLst) then ProcListFree (ProcessLst) ;
	if EnumProcesses (@Processes, SizeOf(Processes), cbNeededP) then
	begin
		for i := 0 to ((cbNeededP div SizeOf (DWORD)) - 1) do
		begin
			hProcess := OpenProcess (PROCESS_QUERY_INFORMATION or
               						PROCESS_VM_READ, FALSE, Processes [i] );
			if hProcess <> 0 then
			begin
				if EnumProcessModules (hProcess, @Modules,
                    			 sizeof (Modules), cbNeededM) then
				begin
					for j := 0 to ((cbNeededM div SizeOf (DWORD)) - 1) do
					begin
						if GetModuleFileNameExW (hProcess, Modules [j],
                            	 szProcessName, sizeof(szProcessName)) > 0 then
						begin
							FileName := szProcessName ;
                         // ignore DLLs, too many
                            if NOT (CompareText (ExtractFileExt
                           				 (FileName), '.exe') = 0) then continue ;
                            New(ProcObj);
                            with ProcObj^ do
                            begin
                                ProcessID := Processes [i] ;
                                DefaultHeapID := 0 ;
                                ModuleID := Modules [j] ;
                                CountThreads := 0 ;
                                ParentProcessID := 0 ;
                                PriClassBase := 0 ;
                                Flags := 0 ;
                                ExeFile := FileName ;
                            end ;
                            ProcessLst.Add (ProcObj) ;
						end;
					end;
					CloseHandle (hProcess);
				end;
			end;
		end ;
	end ;
end ;

//------------------------------------------------------------------------------

// get list of current TCP connections, XP gets process Id so we can find EXE

procedure IpHlpTCPTable(var ConnRows: TConnRows);
var
  i, ExBufSize, NumEntries  : integer;
  TableSize, ModSize : DWORD;
  ErrorCode, ErrorCode2 : DWORD;
  pTCPTable     : PTMibTCPTable ;
  pTCPTableEx   : PTMibTCPTableEx;
  pTCPTableEx2  : PTMibTCPTableOwnerModule;
  ExFlag, ExFlag2 : boolean ;
  TcpIpOwnerModuleBasicInfoEx: TTcpIpOwnerModuleBasicInfoEx ;
  LocalFileTime: TFileTime ;
begin
  if NOT LoadIpHlp then exit ;
  TableSize := 0 ;
  ExBufSize := 0 ;
  SetLength (ConnRows, 0) ;
  ExFlag := false ;
  ExFlag2 := Assigned (GetExtendedTcpTable) ;
  if NOT ExFlag2 then ExFlag := Assigned (AllocateAndGetTcpExTableFromStack) ;
  pTCPTable := Nil ;
  pTCPTableEx2 := Nil ;

  try
      // use latest API XP SP2, W2K3 SP1, Vista and later, first call : get size of table
      if ExFlag2 then
      begin
          ErrorCode := GetExtendedTCPTable (Nil, @TableSize, false, AF_INET, TCP_TABLE_OWNER_MODULE_ALL, 0);
          if Errorcode <> ERROR_INSUFFICIENT_BUFFER then EXIT;

          // get required size of memory, call again
          GetMem (pTCPTableEx2, TableSize);
          // get table
          ErrorCode := GetExtendedTCPTable (pTCPTableEx2, @TableSize, true, AF_INET, TCP_TABLE_OWNER_MODULE_ALL, 0) ;
          if ErrorCode <> NO_ERROR then exit ;
          NumEntries := pTCPTableEx2^.dwNumEntries;
          if NumEntries = 0 then exit ;
          SetLength (ConnRows, NumEntries) ;
          for I := 0 to Pred (NumEntries) do
          begin
              with ConnRows [I], pTCPTableEx2^.Table [I] do
              begin
                  ProcName := '' ;
                  State := dwState ;
                  LocalAddr := IpAddr2Str (dwLocalAddr) ;
                  LocalPort := Port2Wrd (dwLocalPort) ;
                  RemoteAddr := IPAddr2Str (dwRemoteAddr) ;
                  RemotePort := Port2Wrd (dwRemotePort) ;
                  if dwRemoteAddr = 0 then RemotePort := 0;
                  FileTimeToLocalFileTime (liCreateTimestamp, LocalFileTime) ;
                  CreateDT := FileTimeToDateTime (LocalFileTime) ;
                  ProcessID := dwOwningPid ;
                  if ProcessID > 0 then
                  begin
                      ModSize := SizeOf (TcpIpOwnerModuleBasicInfoEx) ;
                      ErrorCode2 := GetOwnerModuleFromTcpEntry ( @pTCPTableEx2^.Table [I],
                            TcpIpOwnerModuleInfoClassBasic, @TcpIpOwnerModuleBasicInfoEx, @ModSize);
                      if ErrorCode2 = NO_ERROR then
                              ProcName := TcpIpOwnerModuleBasicInfoEx.TcpIpOwnerModuleBasicInfo.pModulePath ;
                  end;
              end;
          end ;
      end
    // use originally undocumented API, XP only, not Vista
      else if ExFlag then
      begin
          AllocateAndGetTcpExTableFromStack (pTCPTableEx, true, GetProcessHeap, 2, 2) ;
          ExBufSize := HeapSize (GetProcessHeap, 0, pTCPTableEx);
          if ExBufSize = 0 then exit ;  // dead, probably
          NumEntries := pTCPTableEx^.dwNumEntries ;
          if NumEntries = 0 then exit ;
          SetLength (ConnRows, NumEntries) ;
          for I := 0 to Pred (NumEntries) do
          begin
              with ConnRows [I], pTCPTableEx^.Table [I] do
              begin
                  ProcName := '' ;
                  CreateDT := 0 ;
                  State := dwState ;
                  LocalAddr := IpAddr2Str (dwLocalAddr) ;
                  LocalPort := Port2Wrd (dwLocalPort) ;
                  RemoteAddr := IPAddr2Str (dwRemoteAddr) ;
                  RemotePort := Port2Wrd (dwRemotePort) ;
                  if dwRemoteAddr = 0 then RemotePort := 0;
                  ProcessID := dwProcessID ;
              end;
          end ;
      end
      else
      begin

        // use older documented API, first call : get size of table
          ErrorCode := GetTCPTable (Nil, @TableSize, false );  // Angus
          if Errorcode <> ERROR_INSUFFICIENT_BUFFER then EXIT;

          // get required size of memory, call again
          GetMem (pTCPTable, TableSize);
          // get table
          ErrorCode := GetTCPTable (pTCPTable, @TableSize, true) ;
          if ErrorCode <> NO_ERROR then exit ;
          NumEntries := pTCPTable^.dwNumEntries;
          if NumEntries = 0 then exit ;
          SetLength (ConnRows, NumEntries) ;
          for I := 0 to Pred (NumEntries) do
          begin
              with ConnRows [I], pTCPTable^.Table [I] do
              begin
                  ProcName := '' ;
                  CreateDT := 0 ;
                  State := dwState ;
                  LocalAddr := IpAddr2Str (dwLocalAddr) ;
                  LocalPort := Port2Wrd (dwLocalPort) ;
                  RemoteAddr := IPAddr2Str (dwRemoteAddr) ;
                  RemotePort := Port2Wrd (dwRemotePort) ;
                  if dwRemoteAddr = 0 then RemotePort := 0;
                  ProcessID := 0 ;
              end;
          end ;
      end ;
  finally
    if ExFlag2 then
    begin
        if pTCPTableEx2 <> Nil then FreeMem (pTCPTableEx2) ;
    end
    else if ExFlag then
    begin
        if ExBufSize <> 0 then HeapFree (GetProcessHeap, 0, pTCPTableEx) ;
    end
    else
       if pTCPTable <> Nil then FreeMem (pTCPTable) ;
  end ;
end;

procedure Get_TCPTable( List: TStrings );
var
  ConnRows: TConnRows ;
  NumEntries, I, J: integer ;
  ProcessLst: TList ;
  ExFlag, ExFlag2: boolean ;
  DispName, DispTime: string ;
begin
  if not Assigned( List ) then EXIT;
  List.Clear;
  RecentIPs.Clear;
  IpHlpTCPTable (ConnRows) ;
  NumEntries := Length (ConnRows) ;
  if NumEntries = 0 then
  begin
      List.Add (SyserrorMessage (GetLastError)) ;
      exit ;
  end ;
  ProcessLst := TList.Create ;
  ExFlag := false ;
  ExFlag2 := Assigned (GetExtendedTcpTable) ;
  if NOT ExFlag2 then ExFlag := Assigned (AllocateAndGetTcpExTableFromStack) ;
  if ExFlag then ProcListGetNT (ProcessLst) ;  // don't need this for XP SP2, Vista and later
  for I := 0 to Pred (NumEntries) do
  begin
      with ConnRows [I] do
      begin
       // look for process ID match
          if (ProcessId <> 0) and ExFlag and (ProcessLst.Count <> 0) then
          begin
            for J := 0 to Pred (ProcessLst.Count) do
            begin
               if ProcessId = PTProcessObject (ProcessLst [J]).ProcessID then
               begin
                    ProcName := PTProcessObject (ProcessLst [J]).ExeFile ;
                    break ;
               end ;
            end ;
          end ;

        // build display for user
          if ShowExePath then       // 15 Jan 2009
              DispName := ProcName
          else
              DispName := ExtractFileName (ProcName) ;
          DispTime := '' ;
          if CreateDT > 0 then DispTime := DateTimeToStr (CreateDT) ;
          List.Add (Format( '%15s : %-7s|%15s : %-7s| %-16s| %8d|%-37s|%-20s',
                  [LocalAddr, Port2Svc (LocalPort),
                  RemoteAddr, Port2Svc (RemotePort),
                  TCPConnState[State], ProcessId, DispName, DispTime] ) );
          if (not (RemoteAddr = ''))
                 and ( RecentIps.IndexOf(RemoteAddr) = -1 ) then
                                            RecentIPs.Add (RemoteAddr) ;
      end ;
  end ;
  if Assigned (ProcessLst) then ProcListFree (ProcessLst) ;
end ;

//------------------------------------------------------------------------------
procedure Get_TCPStatistics( List: TStrings );
var
  TCPStats      : TMibTCPStats;
  ErrorCode     : DWORD;
begin
  if not Assigned( List ) then EXIT;
  List.Clear;
  if NOT LoadIpHlp then exit ;
  ErrorCode := GetTCPStatistics( @TCPStats );
  if ErrorCode = NO_ERROR then
    with TCPStats do
    begin
      List.Add( 'Retransmission algorithm :' + TCPToAlgo[dwRTOAlgorithm] );
      List.Add( 'Minimum Time-Out         :' + IntToStr( dwRTOMin ) + ' ms' );
      List.Add( 'Maximum Time-Out         :' + IntToStr( dwRTOMax ) + ' ms' );
      List.Add( 'Maximum Pend.Connections :' + IntToStr( dwRTOAlgorithm ) );
      List.Add( 'Active Opens             :' + IntToStr( dwActiveOpens ) );
      List.Add( 'Passive Opens            :' + IntToStr( dwPassiveOpens ) );
      List.Add( 'Failed Open Attempts     :' + IntToStr( dwAttemptFails ) );
      List.Add( 'Established conn. Reset  :' + IntToStr( dwEstabResets ) );
      List.Add( 'Current Established Conn.:' + IntToStr( dwCurrEstab ) );
      List.Add( 'Segments Received        :' + IntToStr( dwInSegs ) );
      List.Add( 'Segments Sent            :' + IntToStr( dwOutSegs ) );
      List.Add( 'Segments Retransmitted   :' + IntToStr( dwReTransSegs ) );
      List.Add( 'Incoming Errors          :' + IntToStr( dwInErrs ) );
      List.Add( 'Outgoing Resets          :' + IntToStr( dwOutRsts ) );
      List.Add( 'Cumulative Connections   :' + IntToStr( dwNumConns ) );
    end
  else
    List.Add( SyserrorMessage( ErrorCode ) );
end;

function IpHlpTCPStatistics (var TCPStats: TMibTCPStats): integer ;
begin
    result := ERROR_NOT_SUPPORTED ;
    if NOT LoadIpHlp then exit ;
    result := GetTCPStatistics( @TCPStats );
end;

//------------------------------------------------------------------------------

// get list of current UDP connections, XP gets process Id so we can find EXE

procedure IpHlpUDPTable(var ConnRows: TConnRows);
var
  i, ExBufSize, NumEntries  : integer;
  TableSize, ModSize    : DWORD;
  ErrorCode, ErrorCode2 : DWORD;
  pUDPTable     : PTMibUDPTable ;
  pUDPTableEx   : PTMibUDPTableEx;
  pUDPTableEx2  : PTMibUDPTableOwnerModule;
  ExFlag, ExFlag2 : boolean ;
  TcpIpOwnerModuleBasicInfoEx: TTcpIpOwnerModuleBasicInfoEx ;
  LocalFileTime: TFileTime ;
begin
  if NOT LoadIpHlp then exit ;
  TableSize := 0 ;
  ExBufSize := 0 ;
  SetLength (ConnRows, 0) ;
  ExFlag := false ;
  ExFlag2 := Assigned (GetExtendedUdpTable) ;
  if NOT ExFlag2 then ExFlag := Assigned (AllocateAndGetUdpExTableFromStack) ;
  pUDPTable := Nil ;
  pUDPTableEx2 := Nil ;

// see if undocumented API available, XP and better
  try
      // use latest API XP SP2, W2K3 SP1, Vista and later, first call : get size of table
      if ExFlag2 then
      begin
          ErrorCode := GetExtendedUDPTable (Nil, @TableSize, false, AF_INET, UDP_TABLE_OWNER_MODULE, 0);
          if Errorcode <> ERROR_INSUFFICIENT_BUFFER then EXIT;

          // get required size of memory, call again
          GetMem (pUDPTableEx2, TableSize);
          // get table
          ErrorCode := GetExtendedUdpTable (pUDPTableEx2, @TableSize, true, AF_INET, UDP_TABLE_OWNER_MODULE, 0) ;
          if ErrorCode <> NO_ERROR then exit ;
          NumEntries := pUDPTableEx2^.dwNumEntries;
          if NumEntries = 0 then exit ;
          SetLength (ConnRows, NumEntries) ;
          for I := 0 to Pred (NumEntries) do
          begin
              with ConnRows [I], pUDPTableEx2^.Table [I] do
              begin
                  ProcName := '' ;
                  State := -1 ;
                  LocalAddr := IpAddr2Str (dwLocalAddr) ;
                  LocalPort := Port2Wrd (dwLocalPort) ;
                  RemoteAddr := '' ;
                  RemotePort := 0 ;
                  FileTimeToLocalFileTime (liCreateTimestamp, LocalFileTime) ;
                  CreateDT := FileTimeToDateTime (LocalFileTime) ;
                  ProcessID := dwOwningPid ;
                  if ProcessID > 0 then
                  begin
                      ModSize := SizeOf (TcpIpOwnerModuleBasicInfoEx) ;
                      ErrorCode2 := GetOwnerModuleFromUdpEntry ( @pUDPTableEx2^.Table [I],
                            TcpIpOwnerModuleInfoClassBasic, @TcpIpOwnerModuleBasicInfoEx, @ModSize);
                      if ErrorCode2 = NO_ERROR then
                              ProcName := TcpIpOwnerModuleBasicInfoEx.TcpIpOwnerModuleBasicInfo.pModulePath ;
                  end;
              end;
          end ;
      end
    // use originally undocumented API, XP only, not Vista
      else if ExFlag then
      begin
          AllocateAndGetUdpExTableFromStack (pUDPTableEx, true, GetProcessHeap, 2, 2) ;
          ExBufSize := HeapSize (GetProcessHeap, 0, pUDPTableEx);
          if ExBufSize = 0 then exit ;  // dead, probably
          NumEntries := pUDPTableEx^.dwNumEntries ;
          if NumEntries = 0 then exit ;
          SetLength (ConnRows, NumEntries) ;
          for I := 0 to Pred (NumEntries) do
          begin
              with ConnRows [I], pUDPTableEx^.Table [I] do
              begin
                  ProcName := '' ;
                  CreateDT := 0 ;
                  State := -1 ;
                  LocalAddr := IpAddr2Str (dwLocalAddr) ;
                  LocalPort := Port2Wrd (dwLocalPort) ;
                  RemoteAddr := '' ;
                  RemotePort := 0 ;
                  ProcessID := dwProcessID ;
              end;
          end ;
      end
      else
      begin

        // use older documented API, first call : get size of table
          ErrorCode := GetUDPTable (Nil, @TableSize, false );  // Angus
          if Errorcode <> ERROR_INSUFFICIENT_BUFFER then EXIT;

          // get required size of memory, call again
          GetMem (pUDPTable, TableSize);
          // get table
          ErrorCode := GetUDPTable (pUDPTable, @TableSize, true) ;
          if ErrorCode <> NO_ERROR then exit ;
          NumEntries := pUDPTable^.dwNumEntries;
          if NumEntries = 0 then exit ;
          SetLength (ConnRows, NumEntries) ;
          for I := 0 to Pred (NumEntries) do
          begin
              with ConnRows [I], pUDPTable^.Table [I] do
              begin
                  ProcName := '' ;
                  CreateDT := 0 ;
                  State := -1 ;
                  LocalAddr := IpAddr2Str (dwLocalAddr) ;
                  LocalPort := Port2Wrd (dwLocalPort) ;
                  RemoteAddr := '' ;
                  RemotePort := 0 ;
                  ProcessID := 0 ;
              end;
          end ;
      end ;
  finally
        if ExFlag2 then
    begin
        if pUdpTableEx2 <> Nil then FreeMem (pUdpTableEx2) ;
    end
    else if ExFlag then
    begin
        if ExBufSize <> 0 then HeapFree (GetProcessHeap, 0, pUDPTableEx) ;
    end
    else
        if pUDPTable <> Nil then FreeMem (pUDPTable) ;
  end ;
end;

procedure Get_UDPTable( List: TStrings );
var
  ConnRows: TConnRows ;
  NumEntries, I, J: integer ;
  ProcessLst: TList ;
  ExFlag, ExFlag2: boolean ;
  DispName, DispTime: string ;
begin
  if not Assigned( List ) then EXIT;
  List.Clear;
  IpHlpUDPTable (ConnRows) ;
  NumEntries := Length (ConnRows) ;
  if NumEntries = 0 then
  begin
      List.Add (SyserrorMessage (GetLastError)) ;
      exit ;
  end ;
  ProcessLst := TList.Create ;
  ExFlag := false ;
  ExFlag2 := Assigned (GetExtendedTcpTable) ;
  if NOT ExFlag2 then ExFlag := Assigned (AllocateAndGetUdpExTableFromStack) ;
  if ExFlag then ProcListGetNT (ProcessLst) ;
  for I := 0 to Pred (NumEntries) do
  begin
      with ConnRows [I] do
      begin
       // look for process ID match
          if (ProcessId <> 0) and ExFlag and (ProcessLst.Count <> 0) then
          begin
            for J := 0 to Pred (ProcessLst.Count) do
            begin
               if ProcessId = PTProcessObject (ProcessLst [J]).ProcessID then
               begin
                    ProcName := PTProcessObject (ProcessLst [J]).ExeFile ;
                    break ;
               end ;
            end ;
          end ;

        // build display for user
          if ShowExePath then       // 15 Jan 2009
              DispName := ProcName
          else
              DispName := ExtractFileName (ProcName) ;
          DispTime := '' ;
          if CreateDT > 0 then DispTime := DateTimeToStr (CreateDT) ;
          List.Add (Format( '%15s : %-7s| %8d|%-64s|%-20s',
                  [LocalAddr, Port2Svc (LocalPort),
                  ProcessId, DispName, DispTime] ) );
      end ;
  end ;
  if Assigned (ProcessLst) then ProcListFree (ProcessLst) ;
end ;

//------------------------------------------------------------------------------
procedure Get_IPAddrTable( List: TStrings );
var
  IPAddrRow     : TMibIPAddrRow;
  TableSize     : DWORD;
  ErrorCode     : DWORD;
  i             : integer;
  pBuf          : PAnsiChar;
  NumEntries    : DWORD;
begin
  if NOT LoadIpHlp then exit ;
  if not Assigned( List ) then EXIT;
  List.Clear;
  TableSize := 0; ;
  NumEntries := 0 ;
  // first call: get table length
  ErrorCode := GetIpAddrTable(Nil, @TableSize, true );  // Angus
  if Errorcode <> ERROR_INSUFFICIENT_BUFFER then
    EXIT;

  GetMem( pBuf, TableSize );
  // get table
  ErrorCode := GetIpAddrTable( PTMibIPAddrTable( pBuf ), @TableSize, true );
  if ErrorCode = NO_ERROR then
  begin
    NumEntries := PTMibIPAddrTable( pBuf )^.dwNumEntries;
    if NumEntries > 0 then
    begin
      inc( pBuf, SizeOf( DWORD ) );
      for i := 1 to NumEntries do
      begin
        IPAddrRow := PTMIBIPAddrRow( pBuf )^;
        with IPAddrRow do
          List.Add( Format( '%8.8x|%15s|%15s|%15s|%8.8d',
            [dwIndex,
            IPAddr2Str( dwAddr ),
              IPAddr2Str( dwMask ),
              IPAddr2Str( dwBCastAddr ),
              dwReasmSize
              ] ) );
        inc( pBuf, SizeOf( TMIBIPAddrRow ) );
      end;
    end
    else
      List.Add( 'no entries.' );
  end
  else
    List.Add( SysErrorMessage( ErrorCode ) );

  // we must restore pointer!
  dec( pBuf, SizeOf( DWORD ) + NumEntries * SizeOf( IPAddrRow ) );
  FreeMem( pBuf );
end;

//-----------------------------------------------------------------------------
{ gets entries in routing table; equivalent to "Route Print" }
procedure Get_IPForwardTable( List: TStrings );
var
  IPForwRow     : TMibIPForwardRow;
  TableSize     : DWORD;
  ErrorCode     : DWORD;
  i             : integer;
  pBuf          : PAnsiChar;
  NumEntries    : DWORD;
begin
  if NOT LoadIpHlp then exit ;
  if not Assigned( List ) then EXIT;
  List.Clear;
  TableSize := 0;

  // first call: get table length
  NumEntries := 0 ;
  ErrorCode := GetIpForwardTable(Nil, @TableSize, true);
  if Errorcode <> ERROR_INSUFFICIENT_BUFFER then
    EXIT;

  // get table
  GetMem( pBuf, TableSize );
  ErrorCode := GetIpForwardTable( PTMibIPForwardTable( pBuf ), @TableSize, true);
  if ErrorCode = NO_ERROR then
  begin
    NumEntries := PTMibIPForwardTable( pBuf )^.dwNumEntries;
    if NumEntries > 0 then
    begin
      inc( pBuf, SizeOf( DWORD ) );
      for i := 1 to NumEntries do
      begin
        IPForwRow := PTMibIPForwardRow( pBuf )^;
        with IPForwRow do
        begin
          if (dwForwardType > 4) then dwForwardType := 0 ;     // Angus, allow for bad value
          if (dwForwardProto > 18) then dwForwardProto := 0 ;  // Angus, allow for bad value
          List.Add( Format(
            '%15s|%15s|%15s|%8.8x|%7s|   %5.5d|    %7s|        %2.2d',
            [IPAddr2Str( dwForwardDest ),
            IPAddr2Str( dwForwardMask ),
              IPAddr2Str( dwForwardNextHop ),
              dwForwardIFIndex,
              IPForwTypes[dwForwardType],
              dwForwardNextHopAS,
              IPForwProtos[dwForwardProto],
              dwForwardMetric1
              ] ) );
        end ;
        inc( pBuf, SizeOf( TMibIPForwardRow ) );
      end;
    end
    else
      List.Add( 'no entries.' );
  end
  else
    List.Add( SysErrorMessage( ErrorCode ) );
  dec( pBuf, SizeOf( DWORD ) + NumEntries * SizeOf( TMibIPForwardRow ) );
  FreeMem( pBuf );
end;

//------------------------------------------------------------------------------
procedure Get_IPStatistics( List: TStrings );
var
  IPStats       : TMibIPStats;
  ErrorCode     : integer;
begin
  if not Assigned( List ) then EXIT;
  if NOT LoadIpHlp then exit ;
  ErrorCode := GetIPStatistics( @IPStats );
  if ErrorCode = NO_ERROR then
  begin
    List.Clear;
    with IPStats do
    begin
      if dwForwarding = 1 then
        List.add( 'Forwarding Enabled      : ' + 'Yes' )
      else
        List.add( 'Forwarding Enabled      : ' + 'No' );
      List.add( 'Default TTL             : ' + inttostr( dwDefaultTTL ) );
      List.add( 'Datagrams Received      : ' + inttostr( dwInReceives ) );
      List.add( 'Header Errors     (In)  : ' + inttostr( dwInHdrErrors ) );
      List.add( 'Address Errors    (In)  : ' + inttostr( dwInAddrErrors ) );
      List.add( 'Datagrams Forwarded     : ' + inttostr( dwForwDatagrams ) );   // Angus
      List.add( 'Unknown Protocols (In)  : ' + inttostr( dwInUnknownProtos ) );
      List.add( 'Datagrams Discarded     : ' + inttostr( dwInDiscards ) );
      List.add( 'Datagrams Delivered     : ' + inttostr( dwInDelivers ) );
      List.add( 'Requests Out            : ' + inttostr( dwOutRequests ) );
      List.add( 'Routings Discarded      : ' + inttostr( dwRoutingDiscards ) );
      List.add( 'No Routes          (Out): ' + inttostr( dwOutNoRoutes ) );
      List.add( 'Reassemble TimeOuts     : ' + inttostr( dwReasmTimeOut ) );
      List.add( 'Reassemble Requests     : ' + inttostr( dwReasmReqds ) );
      List.add( 'Succesfull Reassemblies : ' + inttostr( dwReasmOKs ) );
      List.add( 'Failed Reassemblies     : ' + inttostr( dwReasmFails ) );
      List.add( 'Succesful Fragmentations: ' + inttostr( dwFragOKs ) );
      List.add( 'Failed Fragmentations   : ' + inttostr( dwFragFails ) );
      List.add( 'Datagrams Fragmented    : ' + inttostr( dwFRagCreates ) );
      List.add( 'Number of Interfaces    : ' + inttostr( dwNumIf ) );
      List.add( 'Number of IP-addresses  : ' + inttostr( dwNumAddr ) );
      List.add( 'Routes in RoutingTable  : ' + inttostr( dwNumRoutes ) );
    end;
  end
  else
    List.Add( SysErrorMessage( ErrorCode ) );
end;

function IpHlpIPStatistics (var IPStats: TMibIPStats): integer ;      // Angus
begin
    result := ERROR_NOT_SUPPORTED ;
    if NOT LoadIpHlp then exit ;
    result := GetIPStatistics( @IPStats );
end ;

//------------------------------------------------------------------------------
procedure Get_UdpStatistics( List: TStrings );
var
  UdpStats      : TMibUDPStats;
  ErrorCode     : integer;
begin
  if NOT LoadIpHlp then exit ;
  if not Assigned( List ) then EXIT;
  ErrorCode := GetUDPStatistics( @UdpStats );
  if ErrorCode = NO_ERROR then
  begin
    List.Clear;
    with UDPStats do
    begin
      List.add( 'Datagrams (In)    : ' + inttostr( dwInDatagrams ) );
      List.add( 'Datagrams (Out)   : ' + inttostr( dwOutDatagrams ) );
      List.add( 'No Ports          : ' + inttostr( dwNoPorts ) );
      List.add( 'Errors    (In)    : ' + inttostr( dwInErrors ) );
      List.add( 'UDP Listen Ports  : ' + inttostr( dwNumAddrs ) );
    end;
  end
  else
    List.Add( SysErrorMessage( ErrorCode ) );
end;

function IpHlpUdpStatistics (UdpStats: TMibUDPStats): integer ;          // Angus
begin
    result := ERROR_NOT_SUPPORTED ;
    if NOT LoadIpHlp then exit ;
    result := GetUDPStatistics (@UdpStats) ;
end ;

//------------------------------------------------------------------------------
procedure Get_ICMPStats( ICMPIn, ICMPOut: TStrings );
var
  ErrorCode     : DWORD;
  ICMPStats     : PTMibICMPInfo;
begin
  if NOT LoadIpHlp then exit ;
  if ( ICMPIn = nil ) or ( ICMPOut = nil ) then EXIT;
  ICMPIn.Clear;
  ICMPOut.Clear;
  New( ICMPStats );
  ErrorCode := GetICMPStatistics( ICMPStats );
  if ErrorCode = NO_ERROR then
  begin
    with ICMPStats.InStats do
    begin
      ICMPIn.Add( 'Messages received    : ' + IntToStr( dwMsgs ) );
      ICMPIn.Add( 'Errors               : ' + IntToStr( dwErrors ) );
      ICMPIn.Add( 'Dest. Unreachable    : ' + IntToStr( dwDestUnreachs ) );
      ICMPIn.Add( 'Time Exceeded        : ' + IntToStr( dwTimeEcxcds ) );
      ICMPIn.Add( 'Param. Problems      : ' + IntToStr( dwParmProbs ) );
      ICMPIn.Add( 'Source Quench        : ' + IntToStr( dwSrcQuenchs ) );
      ICMPIn.Add( 'Redirects            : ' + IntToStr( dwRedirects ) );
      ICMPIn.Add( 'Echo Requests        : ' + IntToStr( dwEchos ) );
      ICMPIn.Add( 'Echo Replies         : ' + IntToStr( dwEchoReps ) );
      ICMPIn.Add( 'Timestamp Requests   : ' + IntToStr( dwTimeStamps ) );
      ICMPIn.Add( 'Timestamp Replies    : ' + IntToStr( dwTimeStampReps ) );

      ICMPIn.Add( 'Addr. Masks Requests : ' + IntToStr( dwAddrMasks ) );
      ICMPIn.Add( 'Addr. Mask Replies   : ' + IntToStr( dwAddrReps ) );
    end;
     //
//    with ICMPStats^.OutStats do
    with ICMPStats.OutStats do
    begin
      ICMPOut.Add( 'Messages sent        : ' + IntToStr( dwMsgs ) );
      ICMPOut.Add( 'Errors               : ' + IntToStr( dwErrors ) );
      ICMPOut.Add( 'Dest. Unreachable    : ' + IntToStr( dwDestUnreachs ) );
      ICMPOut.Add( 'Time Exceeded        : ' + IntToStr( dwTimeEcxcds ) );
      ICMPOut.Add( 'Param. Problems      : ' + IntToStr( dwParmProbs ) );
      ICMPOut.Add( 'Source Quench        : ' + IntToStr( dwSrcQuenchs ) );
      ICMPOut.Add( 'Redirects            : ' + IntToStr( dwRedirects ) );
      ICMPOut.Add( 'Echo Requests        : ' + IntToStr( dwEchos ) );
      ICMPOut.Add( 'Echo Replies         : ' + IntToStr( dwEchoReps ) );
      ICMPOut.Add( 'Timestamp Requests   : ' + IntToStr( dwTimeStamps ) );
      ICMPOut.Add( 'Timestamp Replies    : ' + IntToStr( dwTimeStampReps ) );
      ICMPOut.Add( 'Addr. Masks Requests : ' + IntToStr( dwAddrMasks ) );
      ICMPOut.Add( 'Addr. Mask Replies   : ' + IntToStr( dwAddrReps ) );
    end;
  end
  else
    IcmpIn.Add( SysErrorMessage( ErrorCode ) );
  Dispose( ICMPStats );
end;

//------------------------------------------------------------------------------
procedure Get_RecentDestIPs( List: TStrings );
begin
  if Assigned( List ) then
    List.Assign( RecentIPs )
end;

initialization
  RecentIPs := TStringList.Create;
finalization
  RecentIPs.Free;
end.


