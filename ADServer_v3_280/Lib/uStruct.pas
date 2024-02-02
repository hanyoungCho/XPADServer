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

    PortCnt: integer; //2022-09-26
    DeviceCnt: integer; //장치ID 글자수
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

    DeviceType: Integer; //0:Fan, 1:Heat BB001 돔골프 전용
    HeatPort: Integer;
    HeatTcpIP: String;
    HeatTcpPort: Integer;
    HeatAuto: String;
    HeatTime: String;
    HeatOnTime: Integer;
    HeatOffTime: Integer;

    FanPort: Integer;

    SystemInstall: String;

    Emergency: Boolean; //긴급배정모드
    NetCheck: Boolean; // DNS 체크여부
    MultiCom: Boolean; // 멀티포트

    ReserveMode: Boolean; // 예약모드:예약시간에 배정여부, 타석기에서 발판터치로 시작이 가능한 경우
    //TimeCheckMode: String; // 0:AD기준, 1:타석기기준
    ErrorTimeReward: Boolean; //기기고장시 시간보상 여부
    //StoreMode: String; //0:실외, 1:실내
    CheckInUse: String; //체크인 사용여부
    XGM_VXUse: Boolean;
    BeamProjectorUse: Boolean;
  end;

  {가맹점	테이블명	STORE }
  TStoreInfo = record
    StoreCd: String;      //가맹점 코드
    StoreNm: String;      //가맹점 명
    StartTime: String;
    EndTime: String;
    ShutdownTimeout: String;

    ReserveTimeYn: String; //예약시작시간 사용여부
    ReserveStartTime: String; //예약시작시간

    //EndDBTime: String;
    UseRewardYn: String; // 시간보상-볼회수: 마지막 잔여시간 유지, 고장: 멈춤시간만큼 보상
    UseRewardException: String; // UseRewardYn=N :시간보상않하는경우, 정해진 볼회수시간외 볼회수시 마지막잔여시간 유지

    //12.08 - 수정해야 할 사항. 이종섭차장과 협의함. 동도 이후 버전부터 적용예정 - 미수정 상태
    // 1 이용시간 보상  UseRewardYn -> 기기고장만 해당
    // 2. 볼회수 1차, 2차 중 사용 체크되어 있으면 정기 볼회수로 판단. 볼회수 시간대에 해당하는 예약배정 시간 추가. 비정기적인 볼회수 인 경우 시간 보상 무조건

    Close: String;
    StoreLastTM: String; //store 마지막수정시간
    StoreChgDate: String; //store 마지막수정시간ERP

    ErrorSms: String; //2020-11-05 기기고장 1분유지시 문자발송여부

    ACS: String;
    ACS_1_Yn: String;
    ACS_1_Hp: String;
    ACS_2_Yn: String;
    ACS_3_Yn: String;
    ACS_1: Integer;  //1:타석기 고장
    ACS_2: Integer;  //2:KIOSK 고장
    ACS_3: Integer;  //3:KIOSK 용지 없음

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

    WOLTime: String; //Wake on Lan 가동시간
    WOLUnusedDt: String; //Wake on Lan 제외일(휴장)
  end;

  //타석예약 - 현재 배정대기(대기시간이 적용된) 또는 배정된 예약
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
    PrepareCtlYn: String; //준비시간 제어여부->XGM
    ReserveYn: String;
    AssignYn: String;
  end;

  { 타석테이블명 SEAT	}
  TTeeboxInfo = record
   	StoreCd: String;
    TeeboxNo: Integer;
    TeeboxNm: String;
    FloorZoneCode: String;  // 층 구분 코드
    FloorNm: String;
    TeeboxZoneCode: String;	//구역 구분 코드
    DeviceId: String;       //타석기 장치 ID
    RecvDeviceId: String;   //타석기 장치 ID		응답후 L인경우 좌우구분용
    UseStatusPre: String;
    UseStatus: String;	    //이용 상태	   (0:대기, 1:이용중,2:종료,3:홀드,4:예약중,5:취소,7:볼회수,8:점검, 9:이용불가)
    //UseRStatus: String;     //좌우겸용
    //UseLStatus: String;     //좌우겸용
    //UseApiStatus: String;	  // API 이용 상태	8:점검
    UseYn: String;
    DelYn: String; //2022-01-27 추가
    RemainMinPre: Integer;  //낭은 시간
    RemainMinute: Integer;  //낭은 시간
    RemainRMin: Integer;    //좌우겸용
    RemainLMin: Integer;    //좌우겸용
    RemainBall: Integer;    //남은 볼수
    RemainRBall: Integer;   //좌우겸용
    RemainLBall: Integer;   //좌우겸용
    TeeboxReserve: TTeeboxReserved;

    DelayMin: Integer;      //지연시간(분)
    PauseTime: TDateTime;   //지연시작시간(점검, 볼회수, 타석기고장)
    RePlayTime: TDateTime;  //지연종료시간(점검, 볼회수, 타석기고장 해제)
    ErrorReward: Boolean;   //기기고장 보상 여부, 최대 10분

    UseCancel: String;
    UseClose: String;
    UseReset: String;       //jehu 435 구형인 경우 시간변경이 않됨. 종료후 재설정해야 함.
    PrepareChk: Integer;    //예약대기유지용
    ComReceive: String;     //타석기마스터와 통신여부(최초 실행시 데이터 Receive 여부)

    ErrorCnt: Integer;
    ErrorYn: String;

    RecvData: AnsiString;
    SendData: AnsiString;

    HoldUse: Boolean;
    HoldUser: String;

    ErrorCd: Integer; //2020-06-29 양평추가, 2020-08-20 STR->INT 변경(저장용)
    ErrorCd2: String; //2022-04-21 파트너센터 전송용

    SendSMS: String; //2020-11-05 기기고장 sms 발송여부
    SendACS: String; //2021-02-16 기기고장 acs 발송여부

    ControlYn: String; //2020-12-16 빅토리아 반자동

    CheckCtrl: Boolean; //2021-06-02 점검시 제어체크용

    DeviceUseStatus: String; //0:정지, 1:이용중, D:대기
    DeviceRemainMin: Integer; //2021-09-01 타석기 잔여시간
    DeviceCtrlCnt: Integer; //타석기 제어횟수
    DeviceErrorCd: Integer;
    DeviceErrorCd2: String;

    AgentCtlType: String; //N:없음, D:대기, S:시작, C:변경, E:종료
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
    ErrorCd := 0; //확인되지 않은 에러, Default
    ErrorCd := 1; //볼걸림
    ErrorCd := 2; //볼없음
    ErrorCd := 4; //모터이상
    ErrorCd := 8; //통신이상-상태요청,제어시 응답없을 경우
    ErrorCd := 9; //통신에러

    ErrorCd := 10; // CALL
    ErrorCd := 11~; // 포스에서 앞자리 제외하고 코드로 표시, 12->Error 2
  }

  //배정 테이블 관련 정보
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
    //Json: String;  // 2021-10-05 EXPIRE_DAY, COUPON_CNT 컬럼추가로 제외

    AffiliateCd: String; //2020-08-18
    XgUserKey: String;  //2021-04-21
    AssignYn: String; //2021-08-06 체크인

    LessonProNm: String;
    LessonProPosColor: String;

    // 2021-10-13
    ExpireDay: String;
    CouponCnt: String;

    AccessBarcode: String; //출입바코드 2022-08-16
    AccessControlNm: String; //출입통제 구역명 2022-08-23

    AvailableZoneCd: String; //사용가능구역
  end;

  //임시데이터를 생성하거나 배정관련 매핑용
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
  //타석별 예약목록 관리용
  TReserveList = record
    TeeboxNo: Integer;
    TeeboxNm: String;
    CancelYn: String;
    ReserveList: TStringList; //TNextReserve
  end;

  //예약목록에서 관리하는 배정내역
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

    //2021-08-03 체크인용
    //FReserveDiv: String; //기간권, 쿠폰
    //FReserveRootDiv: String; //포스, 키오스크
    FAssignYn: String; //모바일인 경우 체크인 여부 확인 위해

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
    HeatCtl: String; //돔골프
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
