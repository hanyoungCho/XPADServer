unit uStruct;

interface

uses
  System.Generics.Collections, Classes;

const
  BUFFER_SIZE = 255;

type
    { AD ���� }
  TADConfig = record
    StoreCode: String;
    ADToken: AnsiString;
    UserId: String;
    UserPw: String;
    ApiUrl: string;

    TapoHost: string;
    TapoEmail: string;
    TapoPwd: string;
    IPV4_C_Class: string;

    StoreType: Integer; //0:�ǳ�, 1:������
    TcpPort: Integer;
    DBPort: Integer;

    TapoUse: Boolean;
    AgentUse: Boolean;
    AgentTcpPort: Integer;
    AgentSendPort: Integer;
    AgentSendUse: Boolean; //������Ʈ �۽��� �����ΰ�� - ����
    AgentWOL: Boolean; //Ÿ��PC Wake-On-Lan

    //TapoStatus: Boolean; //tapo ���¿�û ����

    XGM_VXUse: string;
    XGM_TapoUse: String;

    BeamProjectorUse: Boolean;

    PrepareUse: String;
    SystemInstall: String;
    ErrorSms: String; //������ 1�������� ���ڹ߼ۿ���
    Emergency: Boolean; //��޹������
    CheckInUse: String; //üũ�� ��뿩��
  end;
  {
  TTAPO = record
    IP1: String;
    IP2: String;
    IP3: String;
    IP4: String;
    IP5: String;
    IP6: String;
    IP7: String;
    IP8: String;
  end;
  }
  {������	���̺��	STORE }
  TStoreInfo = record
    StoreCd: String;
    StoreNm: String;
    //StoreDiv: String;
    EndYn: String;
    //Memo: String;
    StartTime: String;
    EndTime: String;
    ShutdownTimeout: String;
    //EndTimeIgnoreYn: String; //��������ð� ��üũ
    //EndDBTime: String;
    //UseRewardYn: String;
    Close: String;
    StoreLastTM: String; //store �����������ð�
    StoreChgDate: String; //store �����������ð�ERP
    ACS: String;
    ACS_1_Yn: String;
    ACS_1_Hp: String;
    ACS_2_Yn: String;
    ACS_3_Yn: String;
    ACS_1: Integer;  //1:Ÿ���� ����
    ACS_2: Integer;  //2:KIOSK ����
    ACS_3: Integer;  //3:KIOSK ���� ����

    DNSType: String; //KT, LG
    DNSError: Boolean;
    DNSCheckTime: TDateTime;

    WOLTime: String; //Wake on Lan �����ð�
    WOLUnusedDt: String; //Wake on Lan ������(����)
  end;

  {Ÿ������ }
  TTeeboxReserved = record
    ReserveNo: String;
    AssignMin: Integer;
    AssignBalls: Integer;
    PrepareMin: Integer;
    ReserveDate: String;
    PrepareStartDate: String;
    ReserveStartDate: String;
    //ReserveStartTime: TDateTime;
    ReserveEndDate: String;
    PrepareEndTime: TDateTime;
    PrepareYn: String; //�غ�ð� �����
    ReserveYn: String;
    //ChangeMin: Integer;
    AssignYn: String;
  end;

  { Ÿ�����̺�� SEAT	}
  TTeeboxInfo = record
   	StoreCd: String;
    TeeboxNo: Integer;
    TeeboxNm: String;
    FloorZoneCode: String;
    FloorNm: String;
    TeeboxZoneCode: String;

    RecvDeviceId: String;
    UseStatusPre: String;
    UseStatus: String;
    UseYn: String;
    DelYn: String;
    RemainMinPre: Integer;
    RemainMinute: Integer;
    UseCancel: String;
    UseClose: String;
    PrepareChk: Integer;    //������������
    ComReceive: String;     //Ÿ���⸶���Ϳ� ��ſ���(���� ����� ������ Receive ����)

    DelayMin: Integer;      //�����ð�(��)
    PauseTime: TDateTime;   //�������۽ð�(����, ��ȸ��, Ÿ�������)
    RePlayTime: TDateTime;  //��������ð�(����, ��ȸ��, Ÿ������� ����)

    ErrorCnt: Integer;
    ErrorYn: String;

    HoldUse: Boolean;
    HoldUser: String;

    ErrorCd: Integer; // STR->INT ����(�����)

    SendSMS: String; // ������ sms �߼ۿ���
    SendACS: String; // ������ acs �߼ۿ���

    ChangeMin: integer;

    TapoMac: String;
    TapoIP: String;
    TapoOnOff: String;
    TapoError: Boolean;

    AgentIP_R: String;
    AgentIP_L: String;
    AgentMAC_R: String;
    AgentMAC_L: String;
    AgentCtlType: String; //N:����, D:���, S:����, C:����, E:����
    AgentCtlYNPre: String; // 0:�غ�, 1:����(�������), 2:������
    AgentCtlYN: String; // 0:�غ�, 1:����(�������), 2:������

    BeamType: String;
    BeamPW: String;
    BeamIP: String;
    BeamStartDT: String;
    BeamEndDT: String;
    BeamReCtl: Boolean;

    TeeboxReserve: TTeeboxReserved;
  end;
  {
    ErrorCd := 0; //Ȯ�ε��� ���� ����, Default
    ErrorCd := 1; //���ɸ�
    ErrorCd := 2; //������
    ErrorCd := 4; //�����̻�
    ErrorCd := 8; //����̻�-���¿�û,����� ������� ���
    ErrorCd := 9; //��ſ���

    ErrorCd := 10; // CALL
    ErrorCd := 11~; // �������� ���ڸ� �����ϰ� �ڵ�� ǥ��, 12->Error 2
  }

  TSeatUseInfo = record
    UseSeq: Integer;
    UseSeqDate: String;
    UseSeqNo: Integer;
   	StoreCd: String;
    SeatNo: Integer;
    SeatNm: String;
    FloorNm: String;
    SeatUseStatus: String;      // 4: ����
    UseDiv: String;         // 1:����, 2:�߰�
    MemberSeq: String;
    MemberNm: String;
    MemberTel: String;
    PurchaseSeq: Integer;
    ProductSeq: Integer;
    ProductNm: String;
    ReserveDiv: String;
    ReceiptNo: String; //��������ȣ, ������ҽ� ����Ÿ�� ������
    AssignMin: Integer;
    AssignBalls: Integer;
    PrepareMin: Integer;
    RemainMin: Integer;
    ReserveDate: String;
    ReserveRootDiv: String;
    MoveYn: String; //2021-07-14
    ReserveNo: String;
    StartTime: String;
    Memo: String;
    RegId: String;
    ChgId: String;
    //Json: String;
    AffiliateCd: String;
    XgUserKey: String;
    AssignYn: String;

    //2021-10-05 ��������
    LessonProNm: String;
    LessonProPosColor: String;

    ExpireDay: String;
    CouponCnt: String;

    AccessBarcode: String; //���Թ��ڵ� 2022-08-16
    AccessControlNm: String; //�������� ������ 2022-08-23

    AvailableZoneCd: String; //��밡�ɱ���
  end;

  TSeatUseReserve = record
    ReserveNo: String;
    UseStatus: String;
    SeatNo: Integer;
    SeatNm: String;
    UseMinute: Integer;
    UseBalls: Integer;
    DelayMinute: Integer;
    ReserveDate: String;
    ReserveDateTm: TDateTime;
    StartTime: String;
    StartTimeTm: TDateTime;
    AssignYn: String;
  end;

  //Ÿ���� ������ ������
  TReserveList = record
    TeeboxNo: Integer;
    TeeboxNm: String;
    CancelYn: String;
    ReserveList: TStringList;
  end;

  TNextReserve = class
  private
    FReserveNo: String;
    FTeeboxNo: String;
    FTeeboxNm: String;
    FUseStatus: String;
    FUseMinute: String;
    FDelayMinute: String;
    FReserveDate: String;
    FStartTime: String;
    FAssignYn: String; //������� ��� üũ�� ���� Ȯ�� ����
  published
    property ReserveNo: string read FReserveNo write FReserveNo;
    property TeeboxNo: string read FTeeboxNo write FTeeboxNo;
    property TeeboxNm: string read FTeeboxNm write FTeeboxNm;
    property UseStatus: string read FUseStatus write FUseStatus;
    property UseMinute: string read FUseMinute write FUseMinute;
    property DelayMinute: string read FDelayMinute write FDelayMinute;
    property ReserveDate: string read FReserveDate write FReserveDate;
    property StartTime: string read FStartTime write FStartTime;
    property AssignYn: string read FAssignYn write FAssignYn;
  end;

  TKioskInfo = record
    KioskNo: Integer;
    UserId: String;
    Status: Boolean;
    StatusTime: TDateTime;
    PrintError: Boolean;
    PrintErrorTime: TDateTime;
  end;

  TDeviceInfo = class
  private
    FMAC: string;
    FIP: string;
    FDeviceType: string;
    FDeviceName: string;
    FDeviceAlias: string;
    FDeviceOn: Boolean;
    FOverHeated: Boolean;
    FOnTimes: Integer;
    FStatus: Integer;
  public
    property MAC: string read FMAC write FMAC;
    property IP: string read FIP write FIP;
    property DeviceType: string read FDeviceType write FDeviceType;
    property DeviceName: string read FDeviceName write FDeviceName;
    property DeviceAlias: string read FDeviceAlias write FDeviceAlias;
    property DeviceOn: Boolean read FDeviceOn write FDeviceOn;
    property OverHeated: Boolean read FOverHeated write FOverHeated;
    property OnTimes: Integer read FOnTimes write FOnTimes;
    property Status: Integer read FStatus write FStatus;
  end;

  TSetDeviceOnOffErrorData = class
  private
    FIP: String;
    FPower: Boolean;
  published
    property IP: string read FIP write FIP;
    property Power: Boolean read FPower write FPower;
  end;

  { ������ }
  TRoomReserved = record
    ReserveNo: String;
    AssignMin: Integer;
    StartTime: String;
    EndTime: String;
    EndDate: TDateTime;
    ReserveYn: String;
  end;

  TRoomInfo = record
   	StoreCd: String;
    RoomNo: Integer;
    RoomNm: String;
    UseStatusPre: String;
    UseStatus: String;
    UseYn: String;
    DelYn: String;
    RemainMinPre: Integer;
    RemainMinute: Integer;
    UseCancel: String;
    UseClose: String;
    RecvYn: String;

    TapoIP: String;
    TapoMac: String;
    TapoOnOff: String;
    TapoError: Boolean;

    AgentIP_R: String;
    AgentIP_L: String;
    AgentMAC_R: String;
    AgentMAC_L: String;
    AgentCtlType: String; //N:����, D:���, S:����, C:����, E:����
    AgentCtlYNPre: String; // 0:�غ�, 1:����(�������), 2:������
    AgentCtlYN: String; // 0:�غ�, 1:����(�������), 2:������

    BeamType: String;
    BeamIP: String;

    Reserve: TRoomReserved;
  end;

implementation

end.
