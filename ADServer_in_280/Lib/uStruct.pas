unit uStruct;

interface

uses
  System.Generics.Collections, Classes;

const
  BUFFER_SIZE = 255;

type
    { AD 정보 }
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

    StoreType: Integer; //0:실내, 1:레슨룸
    TcpPort: Integer;
    DBPort: Integer;

    TapoUse: Boolean;
    AgentUse: Boolean;
    AgentTcpPort: Integer;
    AgentSendPort: Integer;
    AgentSendUse: Boolean; //에이전트 송신이 별도인경우 - 신형
    AgentWOL: Boolean; //타석PC Wake-On-Lan

    //TapoStatus: Boolean; //tapo 상태요청 여부

    XGM_VXUse: string;
    XGM_TapoUse: String;

    BeamProjectorUse: Boolean;

    PrepareUse: String;
    SystemInstall: String;
    ErrorSms: String; //기기고장 1분유지시 문자발송여부
    Emergency: Boolean; //긴급배정모드
    CheckInUse: String; //체크인 사용여부
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
  {가맹점	테이블명	STORE }
  TStoreInfo = record
    StoreCd: String;
    StoreNm: String;
    //StoreDiv: String;
    EndYn: String;
    //Memo: String;
    StartTime: String;
    EndTime: String;
    ShutdownTimeout: String;
    //EndTimeIgnoreYn: String; //영업종료시간 미체크
    //EndDBTime: String;
    //UseRewardYn: String;
    Close: String;
    StoreLastTM: String; //store 마지막수정시간
    StoreChgDate: String; //store 마지막수정시간ERP
    ACS: String;
    ACS_1_Yn: String;
    ACS_1_Hp: String;
    ACS_2_Yn: String;
    ACS_3_Yn: String;
    ACS_1: Integer;  //1:타석기 고장
    ACS_2: Integer;  //2:KIOSK 고장
    ACS_3: Integer;  //3:KIOSK 용지 없음

    DNSType: String; //KT, LG
    DNSError: Boolean;
    DNSCheckTime: TDateTime;

    WOLTime: String; //Wake on Lan 가동시간
    WOLUnusedDt: String; //Wake on Lan 제외일(휴장)
  end;

  {타석예약 }
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
    PrepareYn: String; //준비시간 제어여부
    ReserveYn: String;
    //ChangeMin: Integer;
    AssignYn: String;
  end;

  { 타석테이블명 SEAT	}
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
    PrepareChk: Integer;    //예약대기유지용
    ComReceive: String;     //타석기마스터와 통신여부(최초 실행시 데이터 Receive 여부)

    DelayMin: Integer;      //지연시간(분)
    PauseTime: TDateTime;   //지연시작시간(점검, 볼회수, 타석기고장)
    RePlayTime: TDateTime;  //지연종료시간(점검, 볼회수, 타석기고장 해제)

    ErrorCnt: Integer;
    ErrorYn: String;

    HoldUse: Boolean;
    HoldUser: String;

    ErrorCd: Integer; // STR->INT 변경(저장용)

    SendSMS: String; // 기기고장 sms 발송여부
    SendACS: String; // 기기고장 acs 발송여부

    ChangeMin: integer;

    TapoMac: String;
    TapoIP: String;
    TapoOnOff: String;
    TapoError: Boolean;

    AgentIP_R: String;
    AgentIP_L: String;
    AgentMAC_R: String;
    AgentMAC_L: String;
    AgentCtlType: String; //N:없음, D:대기, S:시작, C:변경, E:종료
    AgentCtlYNPre: String; // 0:준비, 1:제어(응답받음), 2:재제어
    AgentCtlYN: String; // 0:준비, 1:제어(응답받음), 2:재제어

    BeamType: String;
    BeamPW: String;
    BeamIP: String;
    BeamStartDT: String;
    BeamEndDT: String;
    BeamReCtl: Boolean;

    TeeboxReserve: TTeeboxReserved;
  end;
  {
    ErrorCd := 0; //확인되지 않은 에러, Default
    ErrorCd := 1; //볼걸림
    ErrorCd := 2; //볼없음
    ErrorCd := 4; //모터이상
    ErrorCd := 8; //통신이상-상태요청,제어시 응답없을 경우
    ErrorCd := 9; //통신에러

    ErrorCd := 10; // CALL
    ErrorCd := 11~; // 포스에서 앞자리 제외하고 코드로 표시, 12->Error 2
  }

  TSeatUseInfo = record
    UseSeq: Integer;
    UseSeqDate: String;
    UseSeqNo: Integer;
   	StoreCd: String;
    SeatNo: Integer;
    SeatNm: String;
    FloorNm: String;
    SeatUseStatus: String;      // 4: 예약
    UseDiv: String;         // 1:배정, 2:추가
    MemberSeq: String;
    MemberNm: String;
    MemberTel: String;
    PurchaseSeq: Integer;
    ProductSeq: Integer;
    ProductNm: String;
    ReserveDiv: String;
    ReceiptNo: String; //영수증번호, 매출취소시 예약타석 삭제용
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

    //2021-10-05 레슨프로
    LessonProNm: String;
    LessonProPosColor: String;

    ExpireDay: String;
    CouponCnt: String;

    AccessBarcode: String; //출입바코드 2022-08-16
    AccessControlNm: String; //출입통제 구역명 2022-08-23

    AvailableZoneCd: String; //사용가능구역
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

  //타석별 예약목록 관리용
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
    FAssignYn: String; //모바일인 경우 체크인 여부 확인 위해
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

  { 레슨룸 }
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
    AgentCtlType: String; //N:없음, D:대기, S:시작, C:변경, E:종료
    AgentCtlYNPre: String; // 0:준비, 1:제어(응답받음), 2:재제어
    AgentCtlYN: String; // 0:준비, 1:제어(응답받음), 2:재제어

    BeamType: String;
    BeamIP: String;

    Reserve: TRoomReserved;
  end;

implementation

end.
