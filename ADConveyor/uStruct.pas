unit uStruct;

interface

uses
  System.Generics.Collections, Classes;

const
  BUFFER_SIZE = 255;

type
    { AD ���� }
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

    //2020-11-05 ������ 1�������� ���ڹ߼ۿ���
    ErrorSms: String;
  end;


implementation

end.
