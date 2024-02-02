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

    PortCnt: integer; //2022-09-26
    DeviceCnt: integer; //��ġID ���ڼ�
    Port: integer;
    Baudrate: integer;
    PortFloorCd: String;
    PortStart: integer;
    PortEnd: integer;
    Port2: integer;
    Baudrate2: integer;
    Port2FloorCd: String;
    Port2Start: integer;
    Port2End: integer;
    Port3: integer;
    Baudrate3: integer;
    Port3FloorCd: String;
    Port3Start: integer;
    Port3End: integer;
    Port4: integer;
    Baudrate4: integer;
    Port4FloorCd: String;
    Port4Start: integer;
    Port4End: integer;
    Port5: integer;
    Baudrate5: integer;
    Port5FloorCd: String;
    Port5Start: integer;
    Port5End: integer;
    Port6: integer;
    Baudrate6: integer;
    Port6FloorCd: String;
    Port6Start: integer;
    Port6End: integer;

    ApiUrl: string;
    TcpPort: Integer;
    DBPort: Integer;
    AgentTcpPort: Integer;
    AgentSendPort:Integer;
    AgentSendUse: Boolean;
    AgentWOL: Boolean;
    ProtocolType: String;

    DeviceType: Integer; //0:Fan, 1:Heat BB001 ������ ����
    HeatPort: Integer;
    HeatTcpIP: String;
    HeatTcpPort: Integer;
    HeatAuto: String;
    HeatTime: String;
    HeatOnTime: Integer;
    HeatOffTime: Integer;

    FanPort: Integer;

    SystemInstall: String;

    Emergency: Boolean; //��޹������
    NetCheck: Boolean; // DNS üũ����
    MultiCom: Boolean; // ��Ƽ��Ʈ

    ReserveMode: Boolean; // ������:����ð��� ��������, Ÿ���⿡�� ������ġ�� ������ ������ ���
    //TimeCheckMode: String; // 0:AD����, 1:Ÿ�������
    ErrorTimeReward: Boolean; //������� �ð����� ����
    //StoreMode: String; //0:�ǿ�, 1:�ǳ�
    CheckInUse: String; //üũ�� ��뿩��
    XGM_VXUse: Boolean;
    BeamProjectorUse: Boolean;
  end;

  {������	���̺��	STORE }
  TStoreInfo = record
    StoreCd: String;      //������ �ڵ�
    StoreNm: String;      //������ ��
    StartTime: String;
    EndTime: String;
    ShutdownTimeout: String;

    ReserveTimeYn: String; //������۽ð� ��뿩��
    ReserveStartTime: String; //������۽ð�

    //EndDBTime: String;
    UseRewardYn: String; // �ð�����-��ȸ��: ������ �ܿ��ð� ����, ����: ����ð���ŭ ����
    UseRewardException: String; // UseRewardYn=N :�ð�������ϴ°��, ������ ��ȸ���ð��� ��ȸ���� �������ܿ��ð� ����

    //12.08 - �����ؾ� �� ����. ����������� ������. ���� ���� �������� ���뿹�� - �̼��� ����
    // 1 �̿�ð� ����  UseRewardYn -> �����常 �ش�
    // 2. ��ȸ�� 1��, 2�� �� ��� üũ�Ǿ� ������ ���� ��ȸ���� �Ǵ�. ��ȸ�� �ð��뿡 �ش��ϴ� ������� �ð� �߰�. ���������� ��ȸ�� �� ��� �ð� ���� ������

    Close: String;
    StoreLastTM: String; //store �����������ð�
    StoreChgDate: String; //store �����������ð�ERP

    ErrorSms: String; //2020-11-05 ������ 1�������� ���ڹ߼ۿ���

    ACS: String;
    ACS_1_Yn: String;
    ACS_1_Hp: String;
    ACS_2_Yn: String;
    ACS_3_Yn: String;
    ACS_1: Integer;  //1:Ÿ���� ����
    ACS_2: Integer;  //2:KIOSK ����
    ACS_3: Integer;  //3:KIOSK ���� ����

    BallRecallYn: Boolean;
    BallRecallStartTime: String;
    BallRecallEndTime: String;
    BallRecallTime: integer;

    BallRecall2Yn: Boolean;
    BallRecall2StartTime: String;
    BallRecall2EndTime: String;
    BallRecall2Time: integer;

    DNSType: String; //KT, LG
    DNSError: Boolean;
    DNSCheckTime: TDateTime;

    WOLTime: String; //Wake on Lan �����ð�
    WOLUnusedDt: String; //Wake on Lan ������(����)
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
    PrepareCtlYn: String; //�غ�ð� �����->XGM
    ReserveYn: String;
    AssignYn: String;
  end;

  { Ÿ�����̺�� SEAT	}
  TTeeboxInfo = record
   	StoreCd: String;
    TeeboxNo: Integer;
    TeeboxNm: String;
    FloorZoneCode: String;  // �� ���� �ڵ�
    FloorNm: String;
    TeeboxZoneCode: String;	//���� ���� �ڵ�
    DeviceId: String;       //Ÿ���� ��ġ ID
    RecvDeviceId: String;   //Ÿ���� ��ġ ID		������ L�ΰ�� �¿챸�п�
    UseStatusPre: String;
    UseStatus: String;	    //�̿� ����	   (0:���, 1:�̿���,2:����,3:Ȧ��,4:������,5:���,7:��ȸ��,8:����, 9:�̿�Ұ�)
    //UseRStatus: String;     //�¿���
    //UseLStatus: String;     //�¿���
    //UseApiStatus: String;	  // API �̿� ����	8:����
    UseYn: String;
    DelYn: String; //2022-01-27 �߰�
    RemainMinPre: Integer;  //���� �ð�
    RemainMinute: Integer;  //���� �ð�
    RemainRMin: Integer;    //�¿���
    RemainLMin: Integer;    //�¿���
    RemainBall: Integer;    //���� ����
    RemainRBall: Integer;   //�¿���
    RemainLBall: Integer;   //�¿���
    TeeboxReserve: TTeeboxReserved;

    DelayMin: Integer;      //�����ð�(��)
    PauseTime: TDateTime;   //�������۽ð�(����, ��ȸ��, Ÿ�������)
    RePlayTime: TDateTime;  //��������ð�(����, ��ȸ��, Ÿ������� ����)
    ErrorReward: Boolean;   //������ ���� ����, �ִ� 10��

    UseCancel: String;
    UseClose: String;
    UseReset: String;       //jehu 435 ������ ��� �ð������� �ʵ�. ������ �缳���ؾ� ��.
    PrepareChk: Integer;    //������������
    ComReceive: String;     //Ÿ���⸶���Ϳ� ��ſ���(���� ����� ������ Receive ����)

    ErrorCnt: Integer;
    ErrorYn: String;

    RecvData: AnsiString;
    SendData: AnsiString;

    HoldUse: Boolean;
    HoldUser: String;

    ErrorCd: Integer; //2020-06-29 �����߰�, 2020-08-20 STR->INT ����(�����)
    ErrorCd2: String; //2022-04-21 ��Ʈ�ʼ��� ���ۿ�

    SendSMS: String; //2020-11-05 ������ sms �߼ۿ���
    SendACS: String; //2021-02-16 ������ acs �߼ۿ���

    ControlYn: String; //2020-12-16 ���丮�� ���ڵ�

    CheckCtrl: Boolean; //2021-06-02 ���˽� ����üũ��

    DeviceUseStatus: String; //0:����, 1:�̿���, D:���
    DeviceRemainMin: Integer; //2021-09-01 Ÿ���� �ܿ��ð�
    DeviceCtrlCnt: Integer; //Ÿ���� ����Ƚ��
    DeviceErrorCd: Integer;
    DeviceErrorCd2: String;

    AgentCtlType: String; //N:����, D:���, S:����, C:����, E:����
    AgentIP_R: String;
    AgentIP_L: String;
    AgentMAC_R: String;
    AgentMAC_L: String;

    BeamType: String;
    BeamPW: String;
    BeamIP: String;
    BeamStartDT: String;
    BeamEndDT: String;
    BeamSReCtl1: Boolean;
    BeamSReCtl2: Boolean;
    BeamEReCtl1: Boolean;
    BeamEReCtl2: Boolean;
    BeamEReCtl3: Boolean;
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
    //Json: String;  // 2021-10-05 EXPIRE_DAY, COUPON_CNT �÷��߰��� ����

    AffiliateCd: String; //2020-08-18
    XgUserKey: String;  //2021-04-21
    AssignYn: String; //2021-08-06 üũ��

    LessonProNm: String;
    LessonProPosColor: String;

    // 2021-10-13
    ExpireDay: String;
    CouponCnt: String;

    AccessBarcode: String; //���Թ��ڵ� 2022-08-16
    AccessControlNm: String; //�������� ������ 2022-08-23

    AvailableZoneCd: String; //��밡�ɱ���
  end;

  //�ӽõ����͸� �����ϰų� �������� ���ο�
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
  {
  TCancelList = record
    TeeboxNo: Integer;
    ReserveNo: String;
  end;
  }
  //Ÿ���� ������ ������
  TReserveList = record
    TeeboxNo: Integer;
    TeeboxNm: String;
    CancelYn: String;
    ReserveList: TStringList; //TNextReserve
  end;

  //�����Ͽ��� �����ϴ� ��������
  TNextReserve = class
  private
    FReserveNo: String;
    FUseStatus: String;
    FSeatNo: String;
    FSeatNm: String;
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
    property SeatNm: string read FSeatNm write FSeatNm;
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
    //FloorZoneCode: String;
    FloorNm: String;
    UseStatus: String;
    UseAuto: String;
    StartTime: TDateTime;
    EndTime: TDateTime;
    HeatCtl: String; //������
  end;

  TFanInfo = record
    FanNo: Integer;
    TeeboxNm: String;
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

  TInfoPLCInfo = record
    PLCNo: Integer;
    TeeboxNm: String;
    UseStatus: String;
  end;

implementation

end.
