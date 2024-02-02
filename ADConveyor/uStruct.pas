unit uStruct;

interface

uses
  System.Generics.Collections, Classes;

const
  BUFFER_SIZE = 255;

type
    { AD 정보 }
  TADConfig = record
    //BranchCode: String;
    StoreCode: String;
    ADToken: AnsiString;
    UserId: String;
    UserPw: String;
    Port: integer;
    Baudrate: integer;

    Port2: integer;
    Baudrate2: integer;

    Port3: integer;
    Baudrate3: integer;

    Port4: integer;
    Baudrate4: integer;

    ApiUrl: string;
    TcpPort: Integer;
    DBPort: Integer;
    AgentTcpPort: Integer;
    ProtocolType: String;
    HeatPort: Integer;
    HeatAuto: String;
    HeatTime: String;
    SystemInstall: String;

    //2020-11-05 기기고장 1분유지시 문자발송여부
    ErrorSms: String;
  end;


implementation

end.
