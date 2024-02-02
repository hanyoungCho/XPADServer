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
    Port: integer;
    Baudrate: integer;

    ApiUrl: string;
    TcpPort: Integer;
    DBPort: Integer;
    ProtocolType: String;
    SystemInstall: String;
  end;

  {������	����}
  TStoreInfo = record
    StoreCd: String;
    StoreNm: String;
    StartTime: String;
    EndTime: String;
    EndDBTime: String;
    UseRewardYn: String;
    Close: String;
    StoreLastTM: String; //store �����������ð�
    StoreChgDate: String; //store �����������ð�ERP
    ErrorSms: String; //������ 1�������� ���ڹ߼ۿ���
  end;

  {Ÿ������ }
  TReserved = record
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
    //ChangeMin: Integer;
  end;

  { Ÿ�����̺�� SEAT	}
  TTeeboxInfo = record
   	StoreCd: String;
    TeeboxNo: Integer;
    TeeboxNm: String;
    FloorZoneCode: String;
    FloorNm: String;
    ZoneDiv: String;
    DeviceId: String;
    RecvDeviceId: String;   //Ÿ���� ��ġ ID		������ L�ΰ�� �¿챸�п�
    //UseStatusPre: String;
    UseStatus: String;	    // (0:���, 1:�̿���, 9:�̿�Ұ�)
    //UseRStatus: String;     //�¿���
    //UseLStatus: String;     //�¿���
    //UseApiStatus: String;	  // API �̿� ����	8:����
    UseYn: String;
    RemainMinPre: Integer;
    RemainMinute: Integer;
    //RemainRMin: Integer;  //�¿���
    //RemainLMin: Integer;  //�¿���
    RemainBall: Integer;
    //RemainRBall: Integer;    //�¿���
    //RemainLBall: Integer;    //�¿���
    Reserve: TReserved;
    DelayMin: Integer;      //�����ð�(��)
    PauseTime: TDateTime;   //�������۽ð�(����, ��ȸ��, Ÿ�������)
    RePlayTime: TDateTime;  //��������ð�(����, ��ȸ��, Ÿ������� ����)
    UseCancel: String;
    UseClose: String;
    //UseReset: String; //��Ÿ�������� ��
    //PrepareChk: Integer; //������������
    ComReceive: String; //Ÿ���⸶���Ϳ� ��ſ���(���� ����� ������ Receive ����)

    ErrorCnt: Integer;
    ErrorYn: String;

    //RecvData: AnsiString;
    //SendData: AnsiString;

    HoldUse: Boolean;
    HoldUser: String;

    ErrorCd: Integer; //2020-06-29 �����߰�, 2020-08-20 STR->INT ����(�����)

    SendSMS: String; //2020-11-05 ������ sms �߼ۿ���

    DeviceUseStatus: String; //0:����, 1:�̿���, D:���
    DeviceUseStatus_R: String;
    DeviceUseStatus_L: String;
    DeviceRemainMin: Integer; //2021-09-01 Ÿ���� �ܿ��ð�
    DeviceRemainMin_R: Integer;
    DeviceRemainMin_L: Integer;
    DeviceRemainBall_R: Integer;
    DeviceRemainBall_L: Integer;
    DeviceCtrlCnt: Integer; //Ÿ���� ����Ƚ��
    DeviceErrorCd: Integer;
    DeviceErrorCd_R: Integer;
    DeviceErrorCd_L: Integer;
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
    UseDiv: String;         // 1:����, 2:�߰�
    MemberSeq: String;
    MemberNm: String;
    //MemberTel: String;
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
    ReserveNo: String;
    StartTime: String;
    Memo: String;
    RegId: String;
    ChgId: String;
    Json: String;

    //2020-08-18
    AffiliateCd: String;
  end;

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
  end;
  {
  TCancelList = record
    TeeboxNo: Integer;
    ReserveNo: String;
  end;
  }
  //Ÿ���� ������ ������
  TTeeboxReserveList = record
    TeeboxNo: Integer;
    //nCurrIdx: Integer;
    //nLastIdx: Integer;
    CancelYn: String;
    ReserveList: TStringList;
  end;

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
  published
    property ReserveNo: string read FReserveNo write FReserveNo;
    property UseStatus: string read FUseStatus write FUseStatus;
    property SeatNo: string read FSeatNo write FSeatNo;
    property UseMinute: string read FUseMinute write FUseMinute;
    property UseBalls: string read FUseBalls write FUseBalls;
    property DelayMinute: string read FDelayMinute write FDelayMinute;
    property ReserveDate: string read FReserveDate write FReserveDate;
    property StartTime: string read FStartTime write FStartTime;
  end;

implementation

end.
