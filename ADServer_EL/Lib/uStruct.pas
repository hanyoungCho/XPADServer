unit uStruct;

interface

uses
  System.Generics.Collections, Classes;

const
  BUFFER_SIZE = 255;

type
  // AD ����
  TADConfig = record
    StoreCode: String;
    UserId: String;
    //UserPw: String;

    ApiUrl: string;
    TcpPort: Integer;
    AgentTcpPort:Integer;
    AgentSendPort:Integer;
    AgentSendUse: String; //������Ʈ �۽��� �����ΰ�� - �ӽ�
    DBPort: Integer;

    TapoUse: Boolean;
    VXUse: string;
    XGMTapoUse: String;

    BeamProjectorUse: Boolean;

    TapoHost: string;
    TapoEmail: string;
    TapoPwd: string;
    IPV4_C_Class: string;
  end;

  // ������	���̺��	STORE
  TStoreInfo = record
    StoreCd: String;
    StoreNm: String;

    StartTime: String;
    EndTime: String;

    //Close: String;
    StoreLastTM: String; //store �����������ð�
    StoreChgDate: String; //store �����������ð�ERP
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
    ChangeMin: Integer;
  end;

  // Ÿ�����̺�� SEAT
  TTeeboxInfo = record
   	StoreCd: String;
    TeeboxNo: Integer;  //������ȣ
    TeeboxNm: String;
    FloorCd: String;
    FloorNm: String;
    DeviceId: String;
    ZoneLeft: String;	//0:��Ÿ��, 1:��Ÿ��, 2:�¿��� ?
    ZoneDiv: String;	//V : VIP ��, G:�Ϲݼ�, L:����Ÿ��, A:�м�Ÿ��
    UseYn: String;

    UseStatusPre: String;   //���� ����
    UseStatus: String;	    //USE_STATUS      �̿� ����	   (0:���, 1:�̿���,2:����,3:Ȧ��,4:������,5:���,7:��ȸ��,8:����, 9:�̿�Ұ�)

    RemainMinPre: Integer;  //���� �ܿ��ð�
    RemainMinute: Integer;  //REMAIN_MINUTE   ���� �ð�		N/A	INT	N

    TapoMac: String;
    TapoIP: String;
    TapoOnOff: String;
    TapoError: Boolean;

    BeamType: String;
    BeamPW: String;
    BeamIP: String;
    BeamStartDT: String;
    BeamEndDT: String;
    BeamReCtl: Boolean;

    UseCancel: String;
    UseClose: String;
    //ComReceive: String;     //Ÿ���⸶���Ϳ� ��ſ���(���� ����� ������ Receive ����)

    HoldUse: Boolean;
    HoldUser: String;

    ChangeMin: integer;

    AgentIP_R: String;
    AgentIP_L: String;
    AgentCtlType: String; //N:����, D:���, S:����, C:����, E:����
    AgentCtlYN: String; // 0:�غ�, 1:����(�������), 2:������

    TeeboxReserve: TTeeboxReserved;
  end;

  TSeatUseInfo = record
    UseSeq: Integer;
    UseSeqDate: String;
    UseSeqNo: Integer;
   	StoreCd: String;
    SeatNo: Integer;
    SeatNm: String;
    FloorNm: String;
    SeatUseStatus: String;      // 4: ����
    //UseDiv: String;         // 1:����, 2:�߰�
    MemberSeq: String;
    MemberNm: String;
    //MemberTel: String;
    //PurchaseSeq: Integer;
    ProductSeq: Integer;
    ProductNm: String;
    ReserveDiv: String;
    //ReceiptNo: String; //��������ȣ, ������ҽ� ����Ÿ�� ������
    AssignMin: Integer;
    //AssignBalls: Integer;
    PrepareMin: Integer;
    RemainMin: Integer;
    ReserveDate: String;
    ReserveRootDiv: String;
    ReserveNo: String;
    StartTime: String;
    //Memo: String;
    RegId: String;
    ChgId: String;
    //Json: String;
  end;

  TSeatUseReserve = record
    ReserveNo: String;
    UseStatus: String;
    SeatNo: Integer;
    SeatNm: String;
    UseMinute: Integer;
    DelayMinute: Integer;
    ReserveDate: String;
    ReserveDateTm: TDateTime;
    StartTime: String;
    StartTimeTm: TDateTime;
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
  published
    property ReserveNo: string read FReserveNo write FReserveNo;
    property TeeboxNo: string read FTeeboxNo write FTeeboxNo;
    property TeeboxNm: string read FTeeboxNm write FTeeboxNm;
    property UseStatus: string read FUseStatus write FUseStatus;
    property UseMinute: string read FUseMinute write FUseMinute;
    property DelayMinute: string read FDelayMinute write FDelayMinute;
    property ReserveDate: string read FReserveDate write FReserveDate;
    property StartTime: string read FStartTime write FStartTime;
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

implementation

end.
