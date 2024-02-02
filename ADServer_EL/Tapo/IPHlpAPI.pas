unit IPHlpAPI;

{$WARN UNSAFE_TYPE off}
{$WARN UNSAFE_CAST off}
{$WARN UNSAFE_CODE off}
{$WARN SYMBOL_PLATFORM OFF}
{$WARN SYMBOL_LIBRARY OFF}
{$WARN SYMBOL_DEPRECATED OFF}

// Magenta Systems Internet Protocol Helper Component
// 12th August 2011 - Release 2.5 (C) Magenta Systems Ltd, 2011
// based on work by by Dirk Claessens

// Copyright by Angus Robertson, Magenta Systems Ltd, England
// delphi@magsys.co.uk, http://www.magsys.co.uk/delphi/

//------------------------------------------------------------------------------
//     Partial translation of  IPHLPAPI.DLL ( IP-Helper API )
// http://users.pandora.be/dirk.claessens2/
//     D. Claessens
//------------------------------------------------------------------------------
{
v1.3 - 18th September 2001
  Angus Robertson, Magenta Systems Ltd, England
     delphi@magsys.co.uk, http://www.magsys.co.uk/delphi/
  All functions are dynamically loaded so program can be used on W95/NT4
  Added GetFriendlyIfIndex

v1.4 - 28th February 2002 - Angus
  Minor change to TIP_ADAPTER_INFO

v 1.5 - 26 July 2002 - Angus
  Added GetPerAdapterInfo and TIP_PER_ADAPTER_INFO

v 1.6 - 19 August 2002 - Angus
  Added AllocateAndGetTcpExTableFromStack and AllocateAndGetUdpExTableFromStack,
  which are APIs for XP only (not Vista), info from Netstatp at www.sysinternals.com
  Added MIB_TCP_STATE constants

v1.8 - 25th October 2005 - Angus

v1.9 - 8th August 2006 - Angus
   Corrected IF_xx_ADAPTER type literals, thanks to Jean-Pierre Turchi

v2.0 - 25th February 2007 - Angus
   Many more IF_xx_ADAPTER type literals, thanks to Jean-Pierre Turchi

v2.1 - 5th August 2008 - Angus
    Updated to be compatible with Delphi 2009
    Note there are only ANSI versions of the IP Helper APIs, no Wide/Unicode versions

v2.2 - 16th January 2009 - Angus
    Added GetAdaptersAddresses (XP and later) has IPv6 addresses (but IPv6 structures not done yet)
    Added GetExtendedTcpTable and GetExtendedUdpTable (XP SP2, W2K3 SP1, Vista and later),
      replacements for AllocateAndGetTcpExTableFromStack/etc

v2.3 - 3rd August 2009
    Changed ULONGLONG to LONGLONG for Delphi 7 compatability

v2.4 - 8th August 2010
    Fixed various cast warning for Delphi 2009 and later

v2.5 - 12th August 2011
    Removed packed for 64-bit compatibility in Delphi XE2 and later

}

{$ALIGN ON}
{$MINENUMSIZE 4}
{$WEAKPACKAGEUNIT}

interface
uses
  Windows, winsock {, winsock2} ;

const
  VERSION = '2.5';

//------------- headers from Microsoft IPTYPES.H--------------------------------

const
  ANY_SIZE = 1;
  TCPIP_OWNING_MODULE_SIZE = 16;
  MAX_ADAPTER_DESCRIPTION_LENGTH = 128; // arb.
  MAX_ADAPTER_NAME_LENGTH = 256; // arb.
  MAX_ADAPTER_ADDRESS_LENGTH = 8; // arb.
  DEFAULT_MINIMUM_ENTITIES = 32; // arb.
  MAX_HOSTNAME_LEN = 128; // arb.
  MAX_DOMAIN_NAME_LEN = 128; // arb.
  MAX_SCOPE_ID_LEN = 256; // arb.
  MAX_DHCPV6_DUID_LENGTH = 130; // RFC 3315

 // Node Types ( NETBIOS)
  BROADCAST_NODETYPE = 1;
  PEER_TO_PEER_NODETYPE = 2;
  MIXED_NODETYPE = 4;
  HYBRID_NODETYPE = 8;

  NETBIOSTypes  : array[0..8] of string =
    ( 'UNKNOWN', 'BROADCAST', 'PEER_TO_PEER', '', 'MIXED', '', '', '', 'HYBRID'
      );

// Adapter Types
{  IF_OTHER_ADAPTERTYPE = 1;    // 8 August 2006 corrected literals to
MIB_IF_TYPE_xx in ipifcons.h
  IF_ETHERNET_ADAPTERTYPE = 6;
  IF_TOKEN_RING_ADAPTERTYPE = 9;
  IF_FDDI_ADAPTERTYPE = 15;
  IF_PPP_ADAPTERTYPE = 23;
  IF_LOOPBACK_ADAPTERTYPE = 24;
  IF_SLIP_ADAPTERTYPE = 28;   }

//  Adapted from Ipifcons.h : // JP Turchi, 9 Feb 2007

  //MIN_IF_TYPE                     = 1;

  IF_TYPE_OTHER                   = 1;   // None of the below
  IF_TYPE_REGULAR_1822            = 2;
  IF_TYPE_HDH_1822                = 3;
  IF_TYPE_DDN_X25                 = 4;
  IF_TYPE_RFC877_X25              = 5;
  IF_TYPE_ETHERNET_CSMACD         = 6;
  IF_TYPE_IS088023_CSMACD         = 7;
  IF_TYPE_ISO88024_TOKENBUS       = 8;
  IF_TYPE_ISO88025_TOKENRING      = 9;
  IF_TYPE_ISO88026_MAN            = 10;
  IF_TYPE_STARLAN                 = 11;
  IF_TYPE_PROTEON_10MBIT          = 12;
  IF_TYPE_PROTEON_80MBIT          = 13;
  IF_TYPE_HYPERCHANNEL            = 14;
  IF_TYPE_FDDI                    = 15;
  IF_TYPE_LAP_B                   = 16;
  IF_TYPE_SDLC                    = 17;
  IF_TYPE_DS1                     = 18;  // DS1-MIB
  IF_TYPE_E1                      = 19;  // Obsolete; see DS1-MIB
  IF_TYPE_BASIC_ISDN              = 20;
  IF_TYPE_PRIMARY_ISDN            = 21;
  IF_TYPE_PROP_POINT2POINT_SERIAL = 22;  // proprietary serial
  IF_TYPE_PPP                     = 23;
  IF_TYPE_SOFTWARE_LOOPBACK       = 24;
  IF_TYPE_EON                     = 25;  // CLNP over IP
  IF_TYPE_ETHERNET_3MBIT          = 26;
  IF_TYPE_NSIP                    = 27;  // XNS over IP
  IF_TYPE_SLIP                    = 28;  // Generic Slip
  IF_TYPE_ULTRA                   = 29;  // ULTRA Technologies
  IF_TYPE_DS3                     = 30;  // DS3-MIB
  IF_TYPE_SIP                     = 31;  // SMDS, coffee
  IF_TYPE_FRAMERELAY              = 32;  // DTE only
  IF_TYPE_RS232                   = 33;
  IF_TYPE_PARA                    = 34;  // Parallel port
  IF_TYPE_ARCNET                  = 35;
  IF_TYPE_ARCNET_PLUS             = 36;
  IF_TYPE_ATM                     = 37;  // ATM cells
  IF_TYPE_MIO_X25                 = 38;
  IF_TYPE_SONET                   = 39;  // SONET or SDH
  IF_TYPE_X25_PLE                 = 40;
  IF_TYPE_ISO88022_LLC            = 41;
  IF_TYPE_LOCALTALK               = 42;
  IF_TYPE_SMDS_DXI                = 43;
  IF_TYPE_FRAMERELAY_SERVICE      = 44;  // FRNETSERV-MIB
  IF_TYPE_V35                     = 45;
  IF_TYPE_HSSI                    = 46;
  IF_TYPE_HIPPI                   = 47;
  IF_TYPE_MODEM                   = 48;  // Generic Modem
  IF_TYPE_AAL5                    = 49;  // AAL5 over ATM
  IF_TYPE_SONET_PATH              = 50;
  IF_TYPE_SONET_VT                = 51;
  IF_TYPE_SMDS_ICIP               = 52;  // SMDS InterCarrier Interface
  IF_TYPE_PROP_VIRTUAL            = 53;  // Proprietary virtual/internal
  IF_TYPE_PROP_MULTIPLEXOR        = 54;  // Proprietary multiplexing
  IF_TYPE_IEEE80212               = 55;  // 100BaseVG
  IF_TYPE_FIBRECHANNEL            = 56;
  IF_TYPE_HIPPIINTERFACE          = 57;
  IF_TYPE_FRAMERELAY_INTERCONNECT = 58;  // Obsolete, use 32 or 44
  IF_TYPE_AFLANE_8023             = 59;  // ATM Emulated LAN for 802.3
  IF_TYPE_AFLANE_8025             = 60;  // ATM Emulated LAN for 802.5
  IF_TYPE_CCTEMUL                 = 61;  // ATM Emulated circuit
  IF_TYPE_FASTETHER               = 62;  // Fast Ethernet (100BaseT)
  IF_TYPE_ISDN                    = 63;  // ISDN and X.25
  IF_TYPE_V11                     = 64;  // CCITT V.11/X.21
  IF_TYPE_V36                     = 65;  // CCITT V.36
  IF_TYPE_G703_64K                = 66;  // CCITT G703 at 64Kbps
  IF_TYPE_G703_2MB                = 67;  // Obsolete; see DS1-MIB
  IF_TYPE_QLLC                    = 68;  // SNA QLLC
  IF_TYPE_FASTETHER_FX            = 69;  // Fast Ethernet (100BaseFX)
  IF_TYPE_CHANNEL                 = 70;
  IF_TYPE_IEEE80211               = 71;  // Radio spread spectrum
  IF_TYPE_IBM370PARCHAN           = 72;  // IBM System 360/370 OEMI Channel
  IF_TYPE_ESCON                   = 73;  // IBM Enterprise Systems Connection
  IF_TYPE_DLSW                    = 74;  // Data Link Switching
  IF_TYPE_ISDN_S                  = 75;  // ISDN S/T interface
  IF_TYPE_ISDN_U                  = 76;  // ISDN U interface
  IF_TYPE_LAP_D                   = 77;  // Link Access Protocol D
  IF_TYPE_IPSWITCH                = 78;  // IP Switching Objects
  IF_TYPE_RSRB                    = 79;  // Remote Source Route Bridging
  IF_TYPE_ATM_LOGICAL             = 80;  // ATM Logical Port
  IF_TYPE_DS0                     = 81;  // Digital Signal Level 0
  IF_TYPE_DS0_BUNDLE              = 82;  // Group of ds0s on the same ds1
  IF_TYPE_BSC                     = 83;  // Bisynchronous Protocol
  IF_TYPE_ASYNC                   = 84;  // Asynchronous Protocol
  IF_TYPE_CNR                     = 85;  // Combat Net Radio
  IF_TYPE_ISO88025R_DTR           = 86;  // ISO 802.5r DTR
  IF_TYPE_EPLRS                   = 87;  // Ext Pos Loc Report Sys
  IF_TYPE_ARAP                    = 88;  // Appletalk Remote Access Protocol
  IF_TYPE_PROP_CNLS               = 89;  // Proprietary Connectionless Proto
  IF_TYPE_HOSTPAD                 = 90;  // CCITT-ITU X.29 PAD Protocol
  IF_TYPE_TERMPAD                 = 91;  // CCITT-ITU X.3 PAD Facility
  IF_TYPE_FRAMERELAY_MPI          = 92;  // Multiproto Interconnect over FR
  IF_TYPE_X213                    = 93;  // CCITT-ITU X213
  IF_TYPE_ADSL                    = 94;  // Asymmetric Digital Subscrbr Loop
  IF_TYPE_RADSL                   = 95;  // Rate-Adapt Digital Subscrbr Loop
  IF_TYPE_SDSL                    = 96;  // Symmetric Digital Subscriber Loop
  IF_TYPE_VDSL                    = 97;  // Very H-Speed Digital Subscrb Loop
  IF_TYPE_ISO88025_CRFPRINT       = 98;  // ISO 802.5 CRFP
  IF_TYPE_MYRINET                 = 99;  // Myricom Myrinet
  IF_TYPE_VOICE_EM                = 100; // Voice recEive and transMit
  IF_TYPE_VOICE_FXO               = 101; // Voice Foreign Exchange Office
  IF_TYPE_VOICE_FXS               = 102; // Voice Foreign Exchange Station
  IF_TYPE_VOICE_ENCAP             = 103; // Voice encapsulation
  IF_TYPE_VOICE_OVERIP            = 104; // Voice over IP encapsulation
  IF_TYPE_ATM_DXI                 = 105; // ATM DXI
  IF_TYPE_ATM_FUNI                = 106; // ATM FUNI
  IF_TYPE_ATM_IMA                 = 107; // ATM IMA
  IF_TYPE_PPPMULTILINKBUNDLE      = 108; // PPP Multilink Bundle
  IF_TYPE_IPOVER_CDLC             = 109; // IBM ipOverCdlc
  IF_TYPE_IPOVER_CLAW             = 110; // IBM Common Link Access to Workstn
  IF_TYPE_STACKTOSTACK            = 111; // IBM stackToStack
  IF_TYPE_VIRTUALIPADDRESS        = 112; // IBM VIPA
  IF_TYPE_MPC                     = 113; // IBM multi-proto channel support
  IF_TYPE_IPOVER_ATM              = 114; // IBM ipOverAtm
  IF_TYPE_ISO88025_FIBER          = 115; // ISO 802.5j Fiber Token Ring
  IF_TYPE_TDLC                    = 116; // IBM twinaxial data link control
  IF_TYPE_GIGABITETHERNET         = 117;
  IF_TYPE_HDLC                    = 118;
  IF_TYPE_LAP_F                   = 119;
  IF_TYPE_V37                     = 120;
  IF_TYPE_X25_MLP                 = 121; // Multi-Link Protocol
  IF_TYPE_X25_HUNTGROUP           = 122; // X.25 Hunt Group
  IF_TYPE_TRANSPHDLC              = 123;
  IF_TYPE_INTERLEAVE              = 124; // Interleave channel
  IF_TYPE_FAST                    = 125; // Fast channel
  IF_TYPE_IP                      = 126; // IP (for APPN HPR in IP networks)
  IF_TYPE_DOCSCABLE_MACLAYER      = 127; // CATV Mac Layer
  IF_TYPE_DOCSCABLE_DOWNSTREAM    = 128; // CATV Downstream interface
  IF_TYPE_DOCSCABLE_UPSTREAM      = 129; // CATV Upstream interface
  IF_TYPE_A12MPPSWITCH            = 130; // Avalon Parallel Processor
  IF_TYPE_TUNNEL                  = 131; // Encapsulation interface
  IF_TYPE_COFFEE                  = 132; // Coffee pot
  IF_TYPE_CES                     = 133; // Circuit Emulation Service
  IF_TYPE_ATM_SUBINTERFACE        = 134; // ATM Sub Interface
  IF_TYPE_L2_VLAN                 = 135; // Layer 2 Virtual LAN using 802.1Q
  IF_TYPE_L3_IPVLAN               = 136; // Layer 3 Virtual LAN using IP
  IF_TYPE_L3_IPXVLAN              = 137; // Layer 3 Virtual LAN using IPX
  IF_TYPE_DIGITALPOWERLINE        = 138; // IP over Power Lines
  IF_TYPE_MEDIAMAILOVERIP         = 139; // Multimedia Mail over IP
  IF_TYPE_DTM                     = 140; // Dynamic syncronous Transfer Mode
  IF_TYPE_DCN                     = 141; // Data Communications Network
  IF_TYPE_IPFORWARD               = 142; // IP Forwarding Interface
  IF_TYPE_MSDSL                   = 143; // Multi-rate Symmetric DSL
  IF_TYPE_IEEE1394                = 144; // IEEE1394 High Perf Serial Bus
  IF_TYPE_RECEIVE_ONLY            = 145; // TV adapter type

  //MAX_IF_TYPE                     = 145;

  AdaptTypes    : array[1..145] of string = (    // 9 February 2007
    'Other',
    'Reg_1822',
    'HDH_1822',
    'DDN_X25',
    'RFC877X25',
    'Ethernet',
    'ISO88023',
    'ISO88024',
    'TokenRing',
    'ISO88026',
    'StarLan',
    'Proteon10',
    'Proteon80',
    'HyperChnl',
    'FDDI',
    'LAP_B',
    'SDLC',
    'DS1',
    'E1',
    'BasicISDN',
    'PrimISDN',
    'Prop_P2P',
    'PPP',
    'Loopback',
    'EON',
    'Eth_3MB',
    'NSIP',
    'SLIP',
    'Ultra',
    'DS3',
    'SIP',
    'FrameRly',
    'RS232',
    'Para',
    'Arcnet',
    'Arcnet+',
    'ATM',
    'MIO_X25',
    'Sonet',
    'X25_PLE',
    'ISO88022',
    'LocalTalk',
    'SMDS_DXI',
    'FrmRlySrv',
    'V35',
    'HSSI',
    'HIPPI',
    'Modem',
    'AAL5',
    'SonetPath',
    'Sonet_VT',
    'SMDS_ICIP',
    'Prop_Virt',
    'Prop_Mux',
    'IEEE80212',
    'FibreChnl',
    'HIPPIifce',
    'FrmRlyIcn',
    'ALanE8023',
    'ALanE8025',
    'CCT_Emul',
    'FastEther',
    'ISDN',
    'V11',
    'V36',
    'G703_64K',
    'G703_2MB',
    'QLLC',
    'FastEthFX',
    'Channel',
    'IEEE80211',
    'IBM370',
    'Escon',
    'DSLW',
    'ISDN_S',
    'ISDN_U',
    'LAP_D',
    'IPSwitch',
    'RSRB',
    'ATM_Logic',
    'DSO',
    'DOSBundle',
    'BSC',
    'Async',
    'CNR',
    'ISO88025',
    'EPLRS',
    'ARAP',
    'Prop_CNLS',
    'HostPad',
    'TermPad',
    'FrmRlyMPI',
    'X213',
    'ADSL',
    'RADSL',
    'SDSL',
    'VDSL',
    'ISO88025',
    'Myrinet',
    'Voice_EM',
    'Voice_FX0',
    'Voice_FXS',
    'Voice_Cap',
    'VOIP',
    'ATM_DXI',
    'ATM_FUNI',
    'ATM_IMA',
    'PPPMulti',
    'IpOvCDLC',
    'IpOvCLAW',
    'Stck2Stck',
    'VirtIPAdr',
    'MPC',
    'IpOv_ATM',
    '88025Fibr',
    'TDLC',
    'GigaBit',
    'HDLC',
    'LAP_F',
    'V37',
    'X25_MLP',
    'X25_Hunt',
    'TransHDLC',
    'InterLeav',
    'Fast',
    'IP',
    'CATV_MACL',
    'CATV_DwnS',
    'CATV_UpSt',
    'A12MPP_Sw',
    'Tunnel',
    'Coffee',
    'CES',
    'ATM_SubIF',
    'L2_VLAN',
    'L3_IPVLAN',
    'L3_IPXVLN',
    'PowerLine',
    'MedaiMail',
    'DTM',
    'DCN',
    'IPForward',
    'MSDSL',
    'IEEE1394',
    'TV_RcvOly'
    );

{  AdaptTypes    : array[1..28] of string =     // 8 August 2006
    ( 'Other', '', '', '', '', 'Ethernet', '', '', 'TokenRing',
     '', '', '', '', '', 'FDDI', '', '', '', '', '', '', '', 'PPP',
     'Loopback', '', '', '', 'SLIP' );
}

//-------------from other MS header files---------------------------------------

  MAX_INTERFACE_NAME_LEN = 256; { mrapi.h }
  MAXLEN_PHYSADDR = 8; { iprtrmib.h }
  MAXLEN_IFDESCR = 256; { --"---     }

// Microsoft Windows Extended data types required for the functions to
// convert   back  and  forth  between  binary  and  string  forms  of
// addresses.   from winsock2

type
  LPSOCKADDR = ^sockaddr_in;

// SockAddr Information from winsock2

type
  LPSOCKET_ADDRESS = ^SOCKET_ADDRESS;
  PSOCKET_ADDRESS = ^SOCKET_ADDRESS;
  _SOCKET_ADDRESS = record
    lpSockaddr: LPSOCKADDR;
    iSockaddrLength: Integer;
  end;
  SOCKET_ADDRESS = _SOCKET_ADDRESS;
  TSocketAddress = SOCKET_ADDRESS;
  PSocketAddress = PSOCKET_ADDRESS;


//------------------------------------------------------------------------------

type
  TMacAddress = array[1..MAX_ADAPTER_ADDRESS_LENGTH] of byte;

//------IP address structures---------------------------------------------------

  PTIP_ADDRESS_STRING = ^TIP_ADDRESS_STRING;
  TIP_ADDRESS_STRING = array[0..15] of AnsiChar; //  IP as string
  //
  PTIP_ADDR_STRING = ^TIP_ADDR_STRING;
  TIP_ADDR_STRING = record // for use in linked lists
    Next: PTIP_ADDR_STRING;
    IpAddress: TIP_ADDRESS_STRING;
    IpMask: TIP_ADDRESS_STRING;
    Context: DWORD;
  end;

//----------Fixed Info STRUCTURES---------------------------------------------

  PTFixedInfo = ^TFixedInfo;
  TFixedInfo = record
    HostName: array[1..MAX_HOSTNAME_LEN + 4] of AnsiChar;    // Angus
    DomainName: array[1..MAX_DOMAIN_NAME_LEN + 4] of AnsiChar;   // Angus
    CurrentDNSServer: PTIP_ADDR_STRING;
    DNSServerList: TIP_ADDR_STRING;
    NodeType: UINT;
    ScopeID: array[1..MAX_SCOPE_ID_LEN + 4] of AnsiChar;   // Angus
    EnableRouting: UINT;
    EnableProxy: UINT;
    EnableDNS: UINT;
  end;

//----------INTERFACE STRUCTURES-------------------------------------------------

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// The following are the the operational states for WAN and LAN interfaces. //
// The order of the states seems weird, but is done for a purpose. All      //
// states >= CONNECTED can transmit data right away. States >= DISCONNECTED //
// can tx data but some set up might be needed. States < DISCONNECTED can   //
// not transmit data.                                                       //
// A card is marked UNREACHABLE if DIM calls InterfaceUnreachable for       //
// reasons other than failure to connect.                                   //
//                                                                          //
// NON_OPERATIONAL -- Valid for LAN Interfaces. Means the card is not       //
//                      working or not plugged in or has no address.        //
// UNREACHABLE     -- Valid for WAN Interfaces. Means the remote site is    //
//                      not reachable at this time.                         //
// DISCONNECTED    -- Valid for WAN Interfaces. Means the remote site is    //
//                      not connected at this time.                         //
// CONNECTING      -- Valid for WAN Interfaces. Means a connection attempt  //
//                      has been initiated to the remote site.              //
// CONNECTED       -- Valid for WAN Interfaces. Means the remote site is    //
//                      connected.                                          //
// OPERATIONAL     -- Valid for LAN Interfaces. Means the card is plugged   //
//                      in and working.                                     //
//                                                                          //
// It is the users duty to convert these values to MIB-II values if they    //
// are to be used by a subagent                                             //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

const
// Angus added from ipifcons.h
  IF_OPER_STATUS_NON_OPERATIONAL = 0 ;
  IF_OPER_STATUS_UNREACHABLE = 1 ;
  IF_OPER_STATUS_DISCONNECTED = 2 ;
  IF_OPER_STATUS_CONNECTING = 3 ;
  IF_OPER_STATUS_CONNECTED = 4 ;
  IF_OPER_STATUS_OPERATIONAL = 5 ;

  MIB_IF_TYPE_OTHER = 1 ;
  MIB_IF_TYPE_ETHERNET = 6 ;
  MIB_IF_TYPE_TOKENRING = 9 ;
  MIB_IF_TYPE_FDDI = 15 ;
  MIB_IF_TYPE_PPP = 23 ;
  MIB_IF_TYPE_LOOPBACK = 24 ;
  MIB_IF_TYPE_SLIP = 28 ;

  MIB_IF_ADMIN_STATUS_UP = 1 ;
  MIB_IF_ADMIN_STATUS_DOWN = 2 ;
  MIB_IF_ADMIN_STATUS_TESTING = 3 ;

  MIB_IF_OPER_STATUS_NON_OPERATIONAL = 0 ;
  MIB_IF_OPER_STATUS_UNREACHABLE = 1 ;
  MIB_IF_OPER_STATUS_DISCONNECTED = 2 ;
  MIB_IF_OPER_STATUS_CONNECTING = 3 ;
  MIB_IF_OPER_STATUS_CONNECTED = 4 ;
  MIB_IF_OPER_STATUS_OPERATIONAL = 5 ;

  MIB_TCP_STATE_CLOSED = 1 ;
  MIB_TCP_STATE_LISTEN = 2 ;
  MIB_TCP_STATE_SYN_SENT = 3 ;
  MIB_TCP_STATE_SYN_RCVD = 4 ;
  MIB_TCP_STATE_ESTAB = 5 ;
  MIB_TCP_STATE_FIN_WAIT1 = 6 ;
  MIB_TCP_STATE_FIN_WAIT2 = 7 ;
  MIB_TCP_STATE_CLOSE_WAIT = 8 ;
  MIB_TCP_STATE_CLOSING = 9 ;
  MIB_TCP_STATE_LAST_ACK = 10 ;
  MIB_TCP_STATE_TIME_WAIT = 11 ;
  MIB_TCP_STATE_DELETE_TCB = 12 ;

type
  PTMibIfRow = ^TMibIfRow;
  TMibIfRow = record
    wszName: array[1..MAX_INTERFACE_NAME_LEN] of WCHAR;
    dwIndex: DWORD;
    dwType: DWORD;       // see MIB_IF_TYPE
    dwMTU: DWORD;
    dwSpeed: DWORD;
    dwPhysAddrLen: DWORD;
    bPhysAddr: array[1..MAXLEN_PHYSADDR] of byte;
    dwAdminStatus: DWORD;    // see MIB_IF_ADMIN_STATUS
    dwOperStatus: DWORD;     // see MIB_IF_OPER_STATUS
    dwLastChange: DWORD;
    dwInOctets: DWORD;
    dwInUcastPkts: DWORD;
    dwInNUCastPkts: DWORD;
    dwInDiscards: DWORD;
    dwInErrors: DWORD;
    dwInUnknownProtos: DWORD;
    dwOutOctets: DWORD;
    dwOutUCastPkts: DWORD;
    dwOutNUCastPkts: DWORD;
    dwOutDiscards: DWORD;
    dwOutErrors: DWORD;
    dwOutQLen: DWORD;
    dwDescrLen: DWORD;
    bDescr: array[1..MAXLEN_IFDESCR] of AnsiChar; //byte;
  end;

 //
  PTMibIfTable = ^TMIBIfTable;
  TMibIfTable = record
    dwNumEntries: DWORD;
    Table: array[0..ANY_SIZE - 1] of TMibIfRow;
  end;

//------ADAPTER INFO STRUCTURES-------------------------------------------------

  PTIP_ADAPTER_INFO = ^TIP_ADAPTER_INFO;
  TIP_ADAPTER_INFO = record
    Next: PTIP_ADAPTER_INFO;
    ComboIndex: DWORD;
    AdapterName: array[1..MAX_ADAPTER_NAME_LENGTH + 4] of AnsiChar;       // Angus
    Description: array[1..MAX_ADAPTER_DESCRIPTION_LENGTH + 4] of AnsiChar;    // Angus
    AddressLength: UINT;
    Address: array[1..MAX_ADAPTER_ADDRESS_LENGTH] of byte;      // Angus
    Index: DWORD;
    aType: UINT;
    DHCPEnabled: UINT;
    CurrentIPAddress: PTIP_ADDR_STRING;
    IPAddressList: TIP_ADDR_STRING;
    GatewayList: TIP_ADDR_STRING;
    DHCPServer: TIP_ADDR_STRING;
    HaveWINS: BOOL;
    PrimaryWINSServer: TIP_ADDR_STRING;
    SecondaryWINSServer: TIP_ADDR_STRING;
    LeaseObtained: LongInt ; // UNIX time, seconds since 1970
    LeaseExpires: LongInt;   // UNIX time, seconds since 1970
    SpareStuff: array [1..200] of AnsiChar ;   // Angus - space for IP address lists
  end;

  PTIP_PER_ADAPTER_INFO = ^TIP_PER_ADAPTER_INFO;  // Angus
  TIP_PER_ADAPTER_INFO = record
    AutoconfigEnabled: UINT;
    AutoconfigActive: UINT;
    CurrentDnsServer: PTIP_ADDR_STRING;
    DnsServerList: TIP_ADDR_STRING;
    SpareStuff: array [1..200] of AnsiChar ;   // space for IP address lists
  end;

// 12 Jan 2009 new stuff for GetAdaptersAddresses, requires winsock2

type
 IP_PREFIX_ORIGIN = (
    IpPrefixOriginOther,
    IpPrefixOriginManual,
    IpPrefixOriginWellKnown,
    IpPrefixOriginDhcp,
    IpPrefixOriginRouterAdvertisement);
  TIpPrefixOrigin = IP_PREFIX_ORIGIN;

  IP_SUFFIX_ORIGIN = (
    IpSuffixOriginOther,
    IpSuffixOriginManual,
    IpSuffixOriginWellKnown,
    IpSuffixOriginDhcp,
    IpSuffixOriginLinkLayerAddress,
    IpSuffixOriginRandom);
  TIpSuffixOrigin = IP_SUFFIX_ORIGIN;

  IP_DAD_STATE = (
    IpDadStateInvalid,
    IpDadStateTentative,
    IpDadStateDuplicate,
    IpDadStateDeprecated,
    IpDadStatePreferred);
  TIpDadState = IP_DAD_STATE;

  PIP_ADAPTER_UNICAST_ADDRESS = ^_IP_ADAPTER_UNICAST_ADDRESS;
  _IP_ADAPTER_UNICAST_ADDRESS = record
    Union: record
    case Integer of
        0: (Alignment: Int64);
        1: (Length: DWORD; Flags: DWORD);
    end;
    Next: PIP_ADAPTER_UNICAST_ADDRESS;
    Address: SOCKET_ADDRESS;
    PrefixOrigin: IP_PREFIX_ORIGIN;
    SuffixOrigin: IP_SUFFIX_ORIGIN;
    DadState: IP_DAD_STATE;
    ValidLifetime: ULONG;
    PreferredLifetime: ULONG;
    LeaseLifetime: ULONG;
  end;
  IP_ADAPTER_UNICAST_ADDRESS = _IP_ADAPTER_UNICAST_ADDRESS;
  TIpAdapterUnicastAddress = IP_ADAPTER_UNICAST_ADDRESS;
  PIpAdapterUnicastAddress = PIP_ADAPTER_UNICAST_ADDRESS;

  PIP_ADAPTER_ANYCAST_ADDRESS = ^_IP_ADAPTER_ANYCAST_ADDRESS;
  _IP_ADAPTER_ANYCAST_ADDRESS = record
    Union: record
      case Integer of
        0: (Alignment: int64);
        1: (Length: DWORD; Flags: DWORD);
    end;
    Next: PIP_ADAPTER_ANYCAST_ADDRESS;
    Address: SOCKET_ADDRESS;
  end;
  IP_ADAPTER_ANYCAST_ADDRESS = _IP_ADAPTER_ANYCAST_ADDRESS;
  TIpAdapterAnycaseAddress = IP_ADAPTER_ANYCAST_ADDRESS;
  PIpAdapterAnycaseAddress = PIP_ADAPTER_ANYCAST_ADDRESS;

  PIP_ADAPTER_MULTICAST_ADDRESS = ^_IP_ADAPTER_MULTICAST_ADDRESS;
  _IP_ADAPTER_MULTICAST_ADDRESS = record
    Union: record
      case Integer of
        0: (Alignment: Int64);
        1: (Length: DWORD; Flags: DWORD);
    end;
    Next: PIP_ADAPTER_MULTICAST_ADDRESS;
    Address: SOCKET_ADDRESS;
  end;
  IP_ADAPTER_MULTICAST_ADDRESS = _IP_ADAPTER_MULTICAST_ADDRESS;
  TIpAdapterMulticastAddress = IP_ADAPTER_MULTICAST_ADDRESS;
  PIpAdapterMulticastAddress = PIP_ADAPTER_MULTICAST_ADDRESS;

  PIP_ADAPTER_DNS_SERVER_ADDRESS = ^_IP_ADAPTER_DNS_SERVER_ADDRESS;
  _IP_ADAPTER_DNS_SERVER_ADDRESS = record
    Union: record
      case Integer of
        0: (Alignment: Int64);
        1: (Length: DWORD; Reserved: DWORD);
    end;
    Next: PIP_ADAPTER_DNS_SERVER_ADDRESS;
    Address: SOCKET_ADDRESS;
  end;
  IP_ADAPTER_DNS_SERVER_ADDRESS = _IP_ADAPTER_DNS_SERVER_ADDRESS;
  TIpAdapterDnsServerAddress = IP_ADAPTER_DNS_SERVER_ADDRESS;
  PIpAdapterDnsServerAddress = PIP_ADAPTER_DNS_SERVER_ADDRESS;

  PIP_ADAPTER_PREFIX = ^IP_ADAPTER_PREFIX;
  _IP_ADAPTER_PREFIX = record
    Union: record
    case Integer of
      0: (Alignment: LONGLONG);
      1: (Length: ULONG; Flags: DWORD);
    end;
    Next: PIP_ADAPTER_PREFIX;
    Address: SOCKET_ADDRESS;
    PrefixLength: ULONG;
  end;
  IP_ADAPTER_PREFIX = _IP_ADAPTER_PREFIX;
  TIpAdapterPrefix = IP_ADAPTER_PREFIX;
  PIpAdapterPrefix = PIP_ADAPTER_PREFIX;

  PIP_ADAPTER_WINS_SERVER_ADDRESS = ^_IP_ADAPTER_WINS_SERVER_ADDRESS;
  _IP_ADAPTER_WINS_SERVER_ADDRESS = record
   Union: record
      case Integer of
        0: (Alignment: Int64);
        1: (Length: DWORD; Reserved: DWORD);
    end;
    Next: PIP_ADAPTER_WINS_SERVER_ADDRESS;
    Address: SOCKET_ADDRESS;
  end;
  IP_ADAPTER_WINS_SERVER_ADDRESS = _IP_ADAPTER_WINS_SERVER_ADDRESS;
  TIpAdapterWinsServerAddress = IP_ADAPTER_WINS_SERVER_ADDRESS;
  PIpAdapterWinsServerAddress = PIP_ADAPTER_WINS_SERVER_ADDRESS;

  PIP_ADAPTER_GATEWAY_ADDRESS = ^_IP_ADAPTER_GATEWAY_ADDRESS;
  _IP_ADAPTER_GATEWAY_ADDRESS = record
    Union: record
      case Integer of
        0: (Alignment: Int64);
        1: (Length: DWORD; Reserved: DWORD);
    end;
    Next: PIP_ADAPTER_GATEWAY_ADDRESS;
    Address: SOCKET_ADDRESS;
  end;
  IP_ADAPTER_GATEWAY_ADDRESS = _IP_ADAPTER_GATEWAY_ADDRESS;
  TIpAdapterGatewayAddress = IP_ADAPTER_GATEWAY_ADDRESS;
  PIpAdapterGatewayAddress = PIP_ADAPTER_GATEWAY_ADDRESS;

type
  NET_LUID = record
    case Word of
     1: (Value: Int64;);
     2: (Reserved: Int64;);
     3: (NetLuidIndex: Int64;);
     4: (IfType: Int64;);
  end;
 IF_LUID = NET_LUID;

// Bit values of IP_ADAPTER_UNICAST_ADDRESS Flags field.

const
  IP_ADAPTER_ADDRESS_DNS_ELIGIBLE   = $01;
  IP_ADAPTER_ADDRESS_TRANSIENT      = $02;

// Bit values of IP_ADAPTER_ADDRESSES Flags field.

const
  IP_ADAPTER_DDNS_ENABLED               = $00000001;
  IP_ADAPTER_REGISTER_ADAPTER_SUFFIX    = $00000002;
  IP_ADAPTER_DHCP_ENABLED               = $00000004;
  IP_ADAPTER_RECEIVE_ONLY               = $00000008;
  IP_ADAPTER_NO_MULTICAST               = $00000010;
  IP_ADAPTER_IPV6_OTHER_STATEFUL_CONFIG = $00000020;
  IP_ADAPTER_NETBIOS_OVER_TCPIP_ENABLED = $00000040;
  IP_ADAPTER_IPV4_ENABLED               = $00000080;
  IP_ADAPTER_IPV6_ENABLED               = $00000100;
  IPV6MANAGEDADDRESSCONFIGURATIONSUPPORTED = $00000200;

// Flags used as argument to GetAdaptersAddresses().
// "SKIP" flags are added when the default is to include the information.
// "INCLUDE" flags are added when the default is to skip the information.

const
  GAA_FLAG_SKIP_UNICAST = $0001;
  GAA_FLAG_SKIP_ANYCAST = $0002;
  GAA_FLAG_SKIP_MULTICAST = $0004;
  GAA_FLAG_SKIP_DNS_SERVER = $0008;
  GAA_FLAG_INCLUDE_PREFIX = $0010;
  GAA_FLAG_SKIP_FRIENDLY_NAME = $0020;
  GAA_FLAG_INCLUDE_WINS_INFO = $0040;
  GAA_FLAG_INCLUDE_GATEWAYS = $0080;
  GAA_FLAG_INCLUDE_ALL_INTERFACES = $0100;
  GAA_FLAG_INCLUDE_ALL_COMPARTMENTS = $0200;
  GAA_FLAG_INCLUDE_TUNNEL_BINDINGORDER = $0400;

type
// OperStatus for GetAdaptersAddresses().
  TIF_OPER_STATUS = (
    IF_OPER_STATUS_NONE,
    IF_OPER_STATUS_UP {= 1},
    IF_OPER_STATUS_DOWN {= 2},
    IF_OPER_STATUS_TESTING {= 3},
    IF_OPER_STATUS_UNKNOWN {= 4},
    IF_OPER_STATUS_DORMANT {= 5},
    IF_OPER_STATUS_NOT_PRESENT {= 6},
    IF_OPER_STATUS_LOWER_LAYER_DOWN {= 7 } );

{/// Define compartment ID type: }
type
    Puint32 = ^DWORD;
    NET_IF_COMPARTMENT_ID = Puint32;
    NET_IF_NETWORK_GUID = TGUID;

const
  NET_IF_COMPARTMENT_ID_UNSPECIFIED = 0;
  NET_IF_COMPARTMENT_ID_PRIMARY = 1;

// Define datalink interface access types.
type
  NET_IF_ACCESS_TYPE = (
    NET_IF_ACCESS_UNKNOWN,
    NET_IF_ACCESS_LOOPBACK,
    NET_IF_ACCESS_BROADCAST,
    NET_IF_ACCESS_POINT_TO_POINT,
    NET_IF_ACCESS_POINT_TO_MULTI_POINT,
    NET_IF_ACCESS_MAXIMUM );

// Define datalink interface direction types.
  NET_IF_DIRECTION_TYPE = (
    NET_IF_DIRECTION_SENDRECEIVE,
    NET_IF_DIRECTION_SENDONLY,
    NET_IF_DIRECTION_RECEIVEONLY,
    NET_IF_DIRECTION_MAXIMUM  );

  NET_IF_CONNECTION_TYPE = (
    NET_IF_CONNECTION_UNKNOWN,
    NET_IF_CONNECTION_DEDICATED,
    NET_IF_CONNECTION_PASSIVE,
    NET_IF_CONNECTION_DEMAND,
    NET_IF_CONNECTION_MAXIMUM );

  NET_IF_MEDIA_CONNECT_STATE = (
    MediaConnectStateUnknown,
    MediaConnectStateConnected,
    MediaConnectStateDisconnected  );

// Types of tunnels (sub-type of IF_TYPE when IF_TYPE is IF_TYPE_TUNNEL). }
  TUNNEL_TYPE = (
    TUNNEL_TYPE_NONE {= 0},
    TUNNEL_TYPE_OTHER {= 1},
    TUNNEL_TYPE_DIRECT {= 2},
    unused3,
    unused4,
    unused5,
    unused6,
    unused7,
    unused8,
    unused9,
    unused10,
    TUNNEL_TYPE_6TO4 {= 11},
    unused12,
    TUNNEL_TYPE_ISATAP {= 13},
    TUNNEL_TYPE_TEREDO {= 14} );

const
  NET_IF_LINK_SPEED_UNKNOWN: Int64 = -1;


// linked records (NEXT) filled by GetAdaptersAddresses(), XP and later, some elements XP SP1, some Vista
// length: XP SP3=144, Vista= 
type
  PIP_ADAPTER_ADDRESSES = ^_IP_ADAPTER_ADDRESSES;
  _IP_ADAPTER_ADDRESSES = record
    Union: record
      case Integer of
        0: (Alignment: int64);
        1: (Length: DWORD;
            IfIndex: DWORD);
    end;
    Next: PIP_ADAPTER_ADDRESSES;
    AdapterName: PAnsiChar;
    FirstUnicastAddress: PIP_ADAPTER_UNICAST_ADDRESS;
    FirstAnycastAddress: PIP_ADAPTER_ANYCAST_ADDRESS;
    FirstMulticastAddress: PIP_ADAPTER_MULTICAST_ADDRESS;
    FirstDnsServerAddress: PIP_ADAPTER_DNS_SERVER_ADDRESS;
    DnsSuffix: PWCHAR;
    Description: PWCHAR;
    FriendlyName: PWCHAR;
    PhysicalAddress: array [0..MAX_ADAPTER_ADDRESS_LENGTH - 1] of BYTE;
    PhysicalAddressLength: DWORD;
    Flags: DWORD;
    Mtu: DWORD;
    IfType: DWORD;
    OperStatus: TIF_OPER_STATUS;        // last element for XP no SP
    Ipv6IfIndex: DWORD;
    ZoneIndices: array [0..15] of DWORD;
    FirstPrefix: PIP_ADAPTER_PREFIX;    // last element for XP SP1
    TransmitLinkSpeed: Int64;           // following elements Vista and later
    ReceiveLinkSpeed: Int64;
    FirstWinsServerAddress: PIP_ADAPTER_WINS_SERVER_ADDRESS;
    FirstGatewayAddress: PIP_ADAPTER_GATEWAY_ADDRESS;
    Ipv4Metric: ULONG;
    Ipv6Metric: ULONG;
    Luid: IF_LUID;
    Dhcpv4Server: SOCKET_ADDRESS;
    CompartmentId: NET_IF_COMPARTMENT_ID;
    NetworkGuid: NET_IF_NETWORK_GUID;
    ConnectionType: NET_IF_CONNECTION_TYPE;
    TunnelType: TUNNEL_TYPE;
    // DHCP v6 Info.
    Dhcpv6Server: SOCKET_ADDRESS;
    Dhcpv6ClientDuid: array [0..MAX_DHCPV6_DUID_LENGTH] of byte;
    Dhcpv6ClientDuidLength: ULONG;
    Dhcpv6Iaid: ULONG;
  end;
  IP_ADAPTER_ADDRESSES = _IP_ADAPTER_ADDRESSES;
  TIpAdapterAddresses = IP_ADAPTER_ADDRESSES;
  PIpAdapterAddresses = PIP_ADAPTER_ADDRESSES;


//----------------TCP STRUCTURES------------------------------------------------

  PTMibTCPRow = ^TMibTCPRow;
  TMibTCPRow = record
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
  end;
  //
  PTMibTCPTable = ^TMibTCPTable;
  TMibTCPTable = record
    dwNumEntries: DWORD;
    Table: array[0..0] of TMibTCPRow;
  end;
  //
  PTMibTCPStats = ^TMibTCPStats;
  TMibTCPStats = record
    dwRTOAlgorithm: DWORD;
    dwRTOMin: DWORD;
    dwRTOMax: DWORD;
    dwMaxConn: DWORD;
    dwActiveOpens: DWORD;
    dwPassiveOpens: DWORD;
    dwAttemptFails: DWORD;
    dwEstabResets: DWORD;
    dwCurrEstab: DWORD;
    dwInSegs: DWORD;
    dwOutSegs: DWORD;
    dwRetransSegs: DWORD;
    dwInErrs: DWORD;
    dwOutRsts: DWORD;
    dwNumConns: DWORD;
  end;

// undocumented, XP and better, info from Netstatp at www.sysinternals.com
  PTMibTCPRowEx = ^TMibTCPRowEx ;
  TMibTCPRowEx = record
    dwState: DWord;
    dwLocalAddr: DWord;
    dwLocalPort: DWord;
    dwRemoteAddr: DWord;
    dwRemotePort: DWord;
    dwProcessID: DWord;
  end;

  PTMibTCPTableEx = ^TMibTCPTableEx;
  TMibTCPTableEx = record
    dwNumEntries: Integer;
    Table: array [0..0] of TMibTCPRowEx;
  end;

//---------UDP STRUCTURES-------------------------------------------------------

  PTMibUDPRow = ^TMibUDPRow;
  TMibUDPRow = record
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
  end;
 //
  PTMibUDPTable = ^TMIBUDPTable;
  TMIBUDPTable = record
    dwNumEntries: DWORD;
    Table: array[0..ANY_SIZE - 1] of TMibUDPRow;
  end;
 //
  PTMibUdpStats = ^TMIBUdpStats;
  TMIBUdpStats = record
    dwInDatagrams: DWORD;
    dwNoPorts: DWORD;
    dwInErrors: DWORD;
    dwOutDatagrams: DWORD;
    dwNumAddrs: DWORD;
  end;

// originally undocumented, XP only (not Vista), info from Netstatp at www.sysinternals.com
  PTMibUDPRowEx = ^TMibUDPRowEx;
  TMibUDPRowEx = record
    dwLocalAddr: DWord;
    dwLocalPort: DWord;
    dwProcessID: DWord;
  end;

  PTMibUDPTableEx = ^TMIBUDPTableEx;
  TMIBUDPTableEx = record
      dwNumEntries: Integer;
      Table: array [0..0] of TMibUDPRowEx;
  end;


//-----------IP STRUCTURES------------------------------------------------------

 //
  PTMibIPNetRow = ^TMibIPNetRow;
  TMibIPNetRow = record
    dwIndex: DWord;
    dwPhysAddrLen: DWord;
    bPhysAddr: TMACAddress;
    dwAddr: DWord;
    dwType: DWord;
  end;
  //
  PTMibIPNetTable = ^TMibIPNetTable;
  TMibIPNetTable = record
    dwNumEntries: DWORD;
    Table: array[0..ANY_SIZE - 1] of TMibIPNetRow;
  end;
  //
  PTMibIPStats = ^TMibIPStats;
  TMibIPStats = record
    dwForwarding: DWORD;
    dwDefaultTTL: DWORD;
    dwInReceives: DWORD;
    dwInHdrErrors: DWORD;
    dwInAddrErrors: DWORD;
    dwForwDatagrams: DWORD;
    dwInUnknownProtos: DWORD;
    dwInDiscards: DWORD;
    dwInDelivers: DWORD;
    dwOutRequests: DWORD;
    dwRoutingDiscards: DWORD;
    dwOutDiscards: DWORD;
    dwOutNoRoutes: DWORD;
    dwReasmTimeOut: DWORD;
    dwReasmReqds: DWORD;
    dwReasmOKs: DWORD;
    dwReasmFails: DWORD;
    dwFragOKs: DWORD;
    dwFragFails: DWORD;
    dwFragCreates: DWORD;
    dwNumIf: DWORD;
    dwNumAddr: DWORD;
    dwNumRoutes: DWORD;
  end;
  //
  PTMibIPAddrRow = ^TMibIPAddrRow;
  TMibIPAddrRow = record
    dwAddr: DWORD;
    dwIndex: DWORD;
    dwMask: DWORD;
    dwBCastAddr: DWORD;
    dwReasmSize: DWORD;
    Unused1,
    Unused2: WORD;
  end;
  //
  PTMibIPAddrTable = ^TMibIPAddrTable;
  TMibIPAddrTable = record
    dwNumEntries: DWORD;
    Table: array[0..ANY_SIZE - 1] of TMibIPAddrRow;
  end;

  //
  PTMibIPForwardRow = ^TMibIPForwardRow;
  TMibIPForwardRow = record
    dwForwardDest: DWORD;
    dwForwardMask: DWORD;
    dwForwardPolicy: DWORD;
    dwForwardNextHop: DWORD;
    dwForwardIFIndex: DWORD;
    dwForwardType: DWORD;
    dwForwardProto: DWORD;
    dwForwardAge: DWORD;
    dwForwardNextHopAS: DWORD;
    dwForwardMetric1: DWORD;
    dwForwardMetric2: DWORD;
    dwForwardMetric3: DWORD;
    dwForwardMetric4: DWORD;
    dwForwardMetric5: DWORD;
  end;
  //
  PTMibIPForwardTable = ^TMibIPForwardTable;
  TMibIPForwardTable = record
    dwNumEntries: DWORD;
    Table: array[0..ANY_SIZE - 1] of TMibIPForwardRow;
  end;

//--------ICMP-STRUCTURES------------------------------------------------------

  PTMibICMPStats = ^TMibICMPStats;
  TMibICMPStats = record
    dwMsgs: DWORD;
    dwErrors: DWORD;
    dwDestUnreachs: DWORD;
    dwTimeEcxcds: DWORD;
    dwParmProbs: DWORD;
    dwSrcQuenchs: DWORD;
    dwRedirects: DWORD;
    dwEchos: DWORD;
    dwEchoReps: DWORD;
    dwTimeStamps: DWORD;
    dwTimeStampReps: DWORD;
    dwAddrMasks: DWORD;
    dwAddrReps: DWORD;
  end;

  PTMibICMPInfo = ^TMibICMPInfo;
  TMibICMPInfo = record
    InStats: TMibICMPStats;
    OutStats: TMibICMPStats;
  end;

// 13 Jan 2009 - GetExtendedTcpTable and GetExtendedUdpTable structures, XP SP2, Vista and better

type
   TTcpTableClass = (
    TCP_TABLE_BASIC_LISTENER,
    TCP_TABLE_BASIC_CONNECTIONS,
    TCP_TABLE_BASIC_ALL,
    TCP_TABLE_OWNER_PID_LISTENER,
    TCP_TABLE_OWNER_PID_CONNECTIONS,
    TCP_TABLE_OWNER_PID_ALL,
    TCP_TABLE_OWNER_MODULE_LISTENER,
    TCP_TABLE_OWNER_MODULE_CONNECTIONS,
    TCP_TABLE_OWNER_MODULE_ALL) ;

  TUdpTableClass = (
    UDP_TABLE_BASIC,
    UDP_TABLE_OWNER_PID,
    UDP_TABLE_OWNER_MODULE );

  TTcpIpOwnerModuleInfoClass = (
    TcpIpOwnerModuleInfoClassBasic  );

  _TCPIP_OWNER_MODULE_BASIC_INFO = record
    pModuleName: PWCHAR;
    pModulePath: PWCHAR;
  end;
  TTcpIpOwnerModuleBasicInfo = _TCPIP_OWNER_MODULE_BASIC_INFO;
  PTcpIpOwnerModuleBasicInfo = ^_TCPIP_OWNER_MODULE_BASIC_INFO;

  TTcpIpOwnerModuleBasicInfoEx = record
    TcpIpOwnerModuleBasicInfo: TTcpIpOwnerModuleBasicInfo ;
    Buffer: Array[0..1024] of byte;  // space for module name and path
  end;
  _MIB_TCPROW_OWNER_PID = record
    dwState: LongInt;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
    dwOwningPid: DWORD;
  end;
  TMibTcpRowOwnerPID = _MIB_TCPROW_OWNER_PID;
  PTMibTcpRowOwnerPID = ^_MIB_TCPROW_OWNER_PID;

  _MIB_TCPTABLE_OWNER_PID = record
    dwNumEntries: DWORD;
    table: Array[0..ANY_SIZE-1] of TMibTcpRowOwnerPID;
  end;
  TMibTcpTableOwnerPID = _MIB_TCPTABLE_OWNER_PID;
  PTMibTcpTableOwnerPID = ^_MIB_TCPTABLE_OWNER_PID;

  _MIB_TCPROW_OWNER_MODULE = record
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
    dwOwningPid: DWORD;
    liCreateTimestamp: TFileTime; {LARGE_INTEGER}
    OwningModuleInfo: Array[0..TCPIP_OWNING_MODULE_SIZE-1] of LONGLONG;
  end;
  TMibTcpRowOwnerModule = _MIB_TCPROW_OWNER_MODULE;
  PTMibTcpRowOwnerModule = ^_MIB_TCPROW_OWNER_MODULE;

  _MIB_TCPTABLE_OWNER_MODULE = record
    dwNumEntries: DWORD;
    table: Array[0..ANY_SIZE-1] of TMibTcpRowOwnerModule;
  end;
  TMibTcpTableOwnerModule = _MIB_TCPTABLE_OWNER_MODULE;
  PTMibTcpTableOwnerModule = ^_MIB_TCPTABLE_OWNER_MODULE;

  _MIB_UDPROW_OWNER_PID = record
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwOwningPid: DWORD;
  end;
  TMibUdpRowOwnerPID = _MIB_UDPROW_OWNER_PID;
  PTMibUdpRowOwnerPID = ^_MIB_UDPROW_OWNER_PID;

  _MIB_UDPTABLE_OWNER_PID = record
    dwNumEntries: DWORD;
    table: Array[0..ANY_SIZE-1] of TMibUdpRowOwnerPID;
  end;
  TMibUdpTableOwnerPID = _MIB_UDPTABLE_OWNER_PID;
  PTMibUdpTableOwnerPID = ^_MIB_UDPTABLE_OWNER_PID;

  _MIB_UDPROW_OWNER_MODULE = record
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwOwningPid: DWORD;
    unknown: DWORD;  // Angus - had to add this dummy element so the record is the correct length and timestamp works
    liCreateTimestamp: TFileTime; {LARGE_INTEGER}
    SpecificPortBind: integer;
    OwningModuleInfo: Array[0..TCPIP_OWNING_MODULE_SIZE-1] of LONGLONG;
  end;
  TMibUdpRowOwnerModule = _MIB_UDPROW_OWNER_MODULE;
  PTMibUdpRowOwnerModule = ^_MIB_UDPROW_OWNER_MODULE;

  _MIB_UDPTABLE_OWNER_MODULE = record
    dwNumEntries: DWORD;
    table: Array[0..ANY_SIZE-1] of TMibUdpRowOwnerModule;
  end;
  TMibUdpTableOwnerModule = _MIB_UDPTABLE_OWNER_MODULE;
  PTMibUdpTableOwnerModule = ^_MIB_UDPTABLE_OWNER_MODULE;

//------------------imports from IPHLPAPI.DLL-----------------------------------

var

GetAdaptersInfo: function ( pAdapterInfo: PTIP_ADAPTER_INFO;
  pOutBufLen: PULONG ): DWORD; stdcall;

GetPerAdapterInfo: function (IfIndex: ULONG; pPerAdapterInfo: PTIP_PER_ADAPTER_INFO;
  pOutBufLen: PULONG):DWORD; stdcall;

GetNetworkParams: function ( FixedInfo: PTFixedInfo; pOutPutLen: PULONG ):
        DWORD; stdcall;

GetTcpTable: function ( pTCPTable: PTMibTCPTable; pDWSize: PDWORD;
  bOrder: BOOL ): DWORD; stdcall;

GetTcpStatistics: function ( pStats: PTMibTCPStats ): DWORD; stdcall;

GetUdpTable: function ( pUdpTable: PTMibUDPTable; pDWSize: PDWORD;
 bOrder: BOOL ): DWORD; stdcall;

GetUdpStatistics: function ( pStats: PTMibUdpStats ): DWORD; stdcall;

GetIpStatistics: function ( pStats: PTMibIPStats ): DWORD; stdcall;

GetIpNetTable: function ( pIpNetTable: PTMibIPNetTable;
  pdwSize: PULONG;  bOrder: BOOL ): DWORD; stdcall;

GetIpAddrTable: function ( pIpAddrTable: PTMibIPAddrTable;
  pdwSize: PULONG; bOrder: BOOL ): DWORD; stdcall;

GetIpForwardTable: function ( pIPForwardTable: PTMibIPForwardTable;
  pdwSize: PULONG; bOrder: BOOL ): DWORD; stdCall;

GetIcmpStatistics: function ( pStats: PTMibICMPInfo ): DWORD; stdCall;

GetRTTAndHopCount: function ( DestIPAddress: DWORD; HopCount: PULONG;
  MaxHops: ULONG; RTT: PULONG ): BOOL; stdCall;

GetIfTable: function ( pIfTable: PTMibIfTable; pdwSize: PULONG;
  bOrder: boolean ): DWORD; stdCall;

GetIfEntry: function ( pIfRow: PTMibIfRow ): DWORD; stdCall;

// warning - documentation is vague about where the result is provided
GetFriendlyIfIndex: function (var IfIndex: DWORD): DWORD; stdcall;

// originally undocumented APIs (in 2002), XP only (not Vista), info from Netstatp at www.sysinternals.com

AllocateAndGetTcpExTableFromStack: procedure (var pTCPTableEx: PTMibTCPTableEx;
        bOrder: Bool; Heap: THandle; Zero, Flags: DWORD); stdcall;

AllocateAndGetUdpExTableFromStack: procedure (var pUdpTableEx: PTMibUDPTableEx;
        bOrder: Bool; Heap: THandle; Zero, Flags: DWORD); stdcall;

// 12 Jan 2009 replacement for GetAdaptersInfo, XP and later

GetAdaptersAddresses: function ( Family: LongWord; Flags: LongWord; Reserved: Pointer;
         AdapterAddresses: PIP_ADAPTER_ADDRESSES; SizePointer: PULONG): DWORD stdcall ;

// 12 Jan 2009 - replacement for AllocateAndGetTcpExTableFromStack - XP SP2, W2K3 SP1, Vista and later

GetExtendedTcpTable: function ( pTCPTable: Pointer; pDWSize: PDWORD;
  bOrder: BOOL; ulAf: LongWord; TableClass: TTcpTableClass; Reserved: LongWord): DWORD; stdcall;

GetOwnerModuleFromTcpEntry: function( pTcpEntry: PTMibTcpRowOwnerModule;
  InfoClass: TTcpIpOwnerModuleInfoClass; pBuffer: Pointer; pdwSize: PDWORD): LongInt stdcall ;

GetExtendedUdpTable: function ( pUdpTable: Pointer; pdwSize: PDWORD;
  bOrder: BOOL; ulAf: LongWord; TableClass: TUdpTableClass; Reserved: LongWord): LongInt stdcall ;

GetOwnerModuleFromUdpEntry: function ( pUdpEntry: PTMibUdpRowOwnerModule;
  InfoClass: TTcpIpOwnerModuleInfoClass; pBuffer: Pointer; pdwSize: PDWORD): LongInt stdcall ;


const
    IpHlpDLL = 'IPHLPAPI.DLL';
var
    IpHlpModule: THandle;

    function LoadIpHlp: Boolean;

implementation

function LoadIpHlp: Boolean;
begin
    Result := True;
    if IpHlpModule <> 0 then Exit;

// open DLL
    IpHlpModule := LoadLibrary (IpHlpDLL);
    if IpHlpModule = 0 then
    begin
        Result := false;
        exit ;
    end ;
    GetAdaptersInfo := GetProcAddress (IpHlpModule, 'GetAdaptersInfo') ;
    GetNetworkParams := GetProcAddress (IpHlpModule, 'GetNetworkParams') ;
    GetTcpTable := GetProcAddress (IpHlpModule, 'GetTcpTable') ;
    GetTcpStatistics := GetProcAddress (IpHlpModule, 'GetTcpStatistics') ;
    GetUdpTable := GetProcAddress (IpHlpModule, 'GetUdpTable') ;
    GetUdpStatistics := GetProcAddress (IpHlpModule, 'GetUdpStatistics') ;
    GetIpStatistics := GetProcAddress (IpHlpModule, 'GetIpStatistics') ;
    GetIpNetTable := GetProcAddress (IpHlpModule, 'GetIpNetTable') ;
    GetIpAddrTable := GetProcAddress (IpHlpModule, 'GetIpAddrTable') ;
    GetIpForwardTable := GetProcAddress (IpHlpModule, 'GetIpForwardTable') ;
    GetIcmpStatistics := GetProcAddress (IpHlpModule, 'GetIcmpStatistics') ;
    GetRTTAndHopCount := GetProcAddress (IpHlpModule, 'GetRTTAndHopCount') ;
    GetIfTable := GetProcAddress (IpHlpModule, 'GetIfTable') ;
    GetIfEntry := GetProcAddress (IpHlpModule, 'GetIfEntry') ;
    GetFriendlyIfIndex := GetProcAddress (IpHlpModule, 'GetFriendlyIfIndex') ;
    GetPerAdapterInfo := GetProcAddress (IpHlpModule, 'GetPerAdapterInfo') ;
    AllocateAndGetTcpExTableFromStack := GetProcAddress (IpHlpModule,
                                     'AllocateAndGetTcpExTableFromStack') ;
    AllocateAndGetUdpExTableFromStack := GetProcAddress (IpHlpModule,
                                     'AllocateAndGetUdpExTableFromStack') ;
    GetAdaptersAddresses := GetProcAddress (IpHlpModule, 'GetAdaptersAddresses') ;
    GetExtendedTcpTable := GetProcAddress (IpHlpModule, 'GetExtendedTcpTable') ;
    GetOwnerModuleFromTcpEntry := GetProcAddress (IpHlpModule, 'GetOwnerModuleFromTcpEntry') ;
    GetExtendedUdpTable := GetProcAddress (IpHlpModule, 'GetExtendedUdpTable') ;
    GetOwnerModuleFromUdpEntry := GetProcAddress (IpHlpModule, 'GetOwnerModuleFromUdpEntry') ;

end;

initialization
    IpHlpModule := 0 ;
finalization
    if IpHlpModule <> 0 then
    begin
        FreeLibrary (IpHlpModule) ;
        IpHlpModule := 0 ;
    end ;

end.
