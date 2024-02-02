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
    //AgentTcpPort: Integer;
    ProtocolType: String;

    HeatPort: Integer;
    HeatTcpIP: String;
    HeatTcpPort: Integer;
    HeatAuto: String;
    HeatTime: String;

    SystemInstall: String;
    ErrorSms: String; //2020-11-05 ������ 1�������� ���ڹ߼ۿ���
    Emergency: Boolean; //��޹������
    NetCheck: Boolean; // DNS üũ����
  end;

  {������	���̺��	STORE }
  TStoreInfo = record
    StoreCd: String;      //STORE_CD	      ������ �ڵ�	N/A	VARCHAR(5)	Not Null		PK
    StoreNm: String;      //STORE_NM	      ������ ��	N/A	VARCHAR(100)	Not Null
    StoreDiv: String;     //STORE_DIV	      ������ ����	N/A	VARCHAR(1)	Not Null	'S'
    UpperStoreCd: String; //UPPER_STORE_CD	���� ������ �ڵ�	N/A	VARCHAR(5)	Not Null
    BizNo: String;        //BIZ_NO	        ����� ��ȣ	N/A	VARCHAR(20)	Not Null
    OwnerNm: String;      //OWNER_NM	      ��ǥ�� ��	N/A	VARCHAR(50)	Not Null
    TelNo: String;        //TEL_NO	        ��ȭ ��ȣ	N/A	VARCHAR(20)	Not Null
    ZipNo: String;        //ZIP_NO	        ���� ��ȣ	N/A	VARCHAR(10)
    Address: String;      //ADDRESS	        �ּ�	N/A	VARCHAR(100)
    AddressDesc: String;  //ADDRESS_DESC	  �ּ� ��	N/A	VARCHAR(100)
    EndYn: String;        //END_YN	        ���� ����	N/A	VARCHAR(1)	Not Null	'N'
    Memo: String;         //MEMO	          �޸�	N/A	VARCHAR(1000)
    StartTime: String;
    EndTime: String;
    EndDBTime: String;
    UseRewardYn: String;
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

    BallRecallStartTime: String;
    BallRecallEndTime: String;
    BallRecallTime: integer;

    DNSType: String; //KT, LG
    DNSError: Boolean;
    DNSCheckTime: TDateTime;
  end;

  //Ÿ������ - ���� �������(���ð��� �����) �Ǵ� ������ ����
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
    ReserveYn: String;
    ChangeMin: Integer;
    AssignYn: String;
  end;

  { Ÿ�����̺�� SEAT	}
  TTeeboxInfo = record
   	StoreCd: String;	      //STORE_CD        ������ �ڵ�	N/A	VARCHAR(5)	Not Null		PK
    TeeboxNo: Integer;	    //SEAT_NO         Ÿ�� ��ȣ	  N/A	INT	Not Null		PK
    TeeboxNm: String;	      //SEAT_NM         Ÿ�� ��	    N/A	VARCHAR(20)	Not Null
    FloorZoneCode: String;  //FLOOR_ZONE_CODE �� ���� �ڵ�N/A	VARCHAR(5)	Not Null
    FloorNm: String;
    TeeboxZoneCode: String;	//SEAT_ZONE_CODE  ���� ���� �ڵ�	N/A	VARCHAR(5)	Not Null
    DeviceId: String;       //DEVICE_ID       Ÿ���� ��ġ ID		N/A	VARCHAR(20)	N
    RecvDeviceId: String;   //DEVICE_ID       Ÿ���� ��ġ ID		������ L�ΰ�� �¿챸�п�
    UseStatusPre: String;
    UseStatus: String;	    //USE_STATUS      �̿� ����	   (0:���, 1:�̿���,2:����,3:Ȧ��,4:������,5:���,7:��ȸ��,8:����, 9:�̿�Ұ�)
    UseRStatus: String;     //�¿���
    UseLStatus: String;     //�¿���
    UseApiStatus: String;	  // API �̿� ����	8:����
    UseYn: String;	        //USE_YN          ��� ����	  N/A	VARCHAR(1)	Not Null	'Y'
    RemainMinPre: Integer;  //REMAIN_MINUTE   ���� �ð�		N/A	INT	N
    RemainMinute: Integer;  //REMAIN_MINUTE   ���� �ð�		N/A	INT	N
    RemainRMin: Integer;    //�¿���
    RemainLMin: Integer;    //�¿���
    RemainBall: Integer;    //REMAIN_BALL     ���� ����		N/A	INT	N
    RemainRBall: Integer;   //�¿���
    RemainLBall: Integer;   //�¿���
    TeeboxReserve: TTeeboxReserved;
    DelayMin: Integer;      //�����ð�(��)
    PauseTime: TDateTime;   //�������۽ð�(����, ��ȸ��, Ÿ�������)
    RePlayTime: TDateTime;  //��������ð�(����, ��ȸ��, Ÿ������� ����)
    UseCancel: String;
    UseClose: String;
    UseReset: String;       //��Ÿ�������� ��
    PrepareChk: Integer;    //������������
    ComReceive: String;     //Ÿ���⸶���Ϳ� ��ſ���(���� ����� ������ Receive ����)

    ErrorCnt: Integer;
    ErrorYn: String;

    RecvData: AnsiString;
    SendData: AnsiString;

    HoldUse: Boolean;
    HoldUser: String;

    ErrorCd: Integer; //2020-06-29 �����߰�, 2020-08-20 STR->INT ����(�����)
    ErrorCd2: String;

    SendSMS: String; //2020-11-05 ������ sms �߼ۿ���
    SendACS: String; //2021-02-16 ������ acs �߼ۿ���

    ControlYn: String; //2020-12-16 ���丮�� ���ڵ�

    CheckCtrl: Boolean; //2021-06-02 ���˽� ����üũ��
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

  //���� ���̺� ���� ����
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
    //Json: String; // 2021-10-05 EXPIRE_DAY, COUPON_CNT �÷��߰��� ����

    //2020-08-18
    AffiliateCd: String;

    //2021-04-21
    XgUserKey: String;

    AssignYn: String; //2021-08-06 üũ��

    //2021-10-05 ��������
    LessonProNm: String;
    LessonProPosColor: String;

    ExpireDay: String;
    CouponCnt: String;

    AccessBarcode: String; //���Թ��ڵ� 2023-03-24
    AccessControlNm: String; //�������� ������ 2023-03-24

    AvailableZoneCd: String; //��밡�ɱ���
  end;

  //�ӽõ����͸� �����ϰų� �������� ���ο�
  TSeatUseReserve = record
    ReserveNo: String;
    UseStatus: String;
    SeatNo: Integer;
    UseMinute: Integer;
    UseBalls: Integer;
    DelayMinute: Integer;
    ReserveDate: String;
    ReserveDateTm: TDateTime;
    StartTime: String;
    StartTimeTm: TDateTime;
    AssignYn: String;
  end;

  TCancelList = record
    TeeboxNo: Integer;
    ReserveNo: String;
  end;

  //Ÿ���� ������ ������
  TTeeboxReserveList = record
    TeeboxNo: Integer;
    //nCurrIdx: Integer;
    //nLastIdx: Integer;
    CancelYn: String;
    ReserveList: TStringList; //TNextReserve
  end;

  //�����Ͽ��� �����ϴ� ��������
  TNextReserve = class
  private
    FReserveNo: String;
    FUseStatus: String;
    FSeatNo: String;
    FUseMinute: String;
    FUseBalls: String;
    FDelayMinute: String;
    FReserveDate: String;
    //FReserveDateTm: TDateTime;
    FStartTime: String;
    //FStartTimeTm: TDateTime;

    //2021-08-03 üũ�ο�
    //FReserveDiv: String; //�Ⱓ��, ����
    //FReserveRootDiv: String; //����, Ű����ũ
    FAssignYn: String; //������� ��� üũ�� ���� Ȯ�� ����

  published
    property ReserveNo: string read FReserveNo write FReserveNo;
    property UseStatus: string read FUseStatus write FUseStatus;
    property SeatNo: string read FSeatNo write FSeatNo;
    property UseMinute: string read FUseMinute write FUseMinute;
    property UseBalls: string read FUseBalls write FUseBalls;
    property DelayMinute: string read FDelayMinute write FDelayMinute;
    property ReserveDate: string read FReserveDate write FReserveDate;
    property StartTime: string read FStartTime write FStartTime;

    property AssignYn: string read FAssignYn write FAssignYn;
  end;

  TSendApiErrorData = class
  private
    FApi: String;
    FJson: String;
  published
    property Api: string read FApi write FApi;
    property Json: string read FJson write FJson;
  end;

  THeatInfo = record
    HeatNo: Integer;
    TeeboxNm: String;
    //FloorNm: String;
    FloorZoneCode: String; //��Ī���� �ϸ� �� ���ڰ� ������
    UseStatus: String;
    UseAuto: String;
    StartTime: TDateTime;
    EndTime: TDateTime;
  end;

  TKioskInfo = record
    KioskNo: Integer;
    UserId: String;
    Status: Boolean;
    StatusTime: TDateTime;
    PrintError: Boolean;
    PrintErrorTime: TDateTime;
  end;

  TTeeboxEndError = class
  private
    FReserveNo: String;
    FCnt: Integer;
    FJson: String;
  published
    property ReserveNo: string read FReserveNo write FReserveNo;
    property Cnt: Integer read FCnt write FCnt;
    property Json: string read FJson write FJson;
  end;

implementation

end.
