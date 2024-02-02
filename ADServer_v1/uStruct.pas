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
    //AgentTcpPort: Integer;
    ProtocolType: String;

    HeatPort: Integer;
    HeatTcpIP: String;
    HeatTcpPort: Integer;
    HeatAuto: String;
    HeatTime: String;

    SystemInstall: String;
    ErrorSms: String; //2020-11-05 기기고장 1분유지시 문자발송여부
    Emergency: Boolean; //긴급배정모드
    NetCheck: Boolean; // DNS 체크여부
  end;

  {가맹점	테이블명	STORE }
  TStoreInfo = record
    StoreCd: String;      //STORE_CD	      가맹점 코드	N/A	VARCHAR(5)	Not Null		PK
    StoreNm: String;      //STORE_NM	      가맹점 명	N/A	VARCHAR(100)	Not Null
    StoreDiv: String;     //STORE_DIV	      가맹점 구분	N/A	VARCHAR(1)	Not Null	'S'
    UpperStoreCd: String; //UPPER_STORE_CD	상위 가맹점 코드	N/A	VARCHAR(5)	Not Null
    BizNo: String;        //BIZ_NO	        사업자 번호	N/A	VARCHAR(20)	Not Null
    OwnerNm: String;      //OWNER_NM	      대표자 명	N/A	VARCHAR(50)	Not Null
    TelNo: String;        //TEL_NO	        전화 번호	N/A	VARCHAR(20)	Not Null
    ZipNo: String;        //ZIP_NO	        우편 번호	N/A	VARCHAR(10)
    Address: String;      //ADDRESS	        주소	N/A	VARCHAR(100)
    AddressDesc: String;  //ADDRESS_DESC	  주소 상세	N/A	VARCHAR(100)
    EndYn: String;        //END_YN	        해지 여부	N/A	VARCHAR(1)	Not Null	'N'
    Memo: String;         //MEMO	          메모	N/A	VARCHAR(1000)
    StartTime: String;
    EndTime: String;
    EndDBTime: String;
    UseRewardYn: String;
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

    BallRecallStartTime: String;
    BallRecallEndTime: String;
    BallRecallTime: integer;

    DNSType: String; //KT, LG
    DNSError: Boolean;
    DNSCheckTime: TDateTime;
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
    ReserveYn: String;
    ChangeMin: Integer;
    AssignYn: String;
  end;

  { 타석테이블명 SEAT	}
  TTeeboxInfo = record
   	StoreCd: String;	      //STORE_CD        가맹점 코드	N/A	VARCHAR(5)	Not Null		PK
    TeeboxNo: Integer;	    //SEAT_NO         타석 번호	  N/A	INT	Not Null		PK
    TeeboxNm: String;	      //SEAT_NM         타석 명	    N/A	VARCHAR(20)	Not Null
    FloorZoneCode: String;  //FLOOR_ZONE_CODE 층 구분 코드N/A	VARCHAR(5)	Not Null
    FloorNm: String;
    TeeboxZoneCode: String;	//SEAT_ZONE_CODE  구역 구분 코드	N/A	VARCHAR(5)	Not Null
    DeviceId: String;       //DEVICE_ID       타석기 장치 ID		N/A	VARCHAR(20)	N
    RecvDeviceId: String;   //DEVICE_ID       타석기 장치 ID		응답후 L인경우 좌우구분용
    UseStatusPre: String;
    UseStatus: String;	    //USE_STATUS      이용 상태	   (0:대기, 1:이용중,2:종료,3:홀드,4:예약중,5:취소,7:볼회수,8:점검, 9:이용불가)
    UseRStatus: String;     //좌우겸용
    UseLStatus: String;     //좌우겸용
    UseApiStatus: String;	  // API 이용 상태	8:점검
    UseYn: String;	        //USE_YN          사용 여부	  N/A	VARCHAR(1)	Not Null	'Y'
    RemainMinPre: Integer;  //REMAIN_MINUTE   낭은 시간		N/A	INT	N
    RemainMinute: Integer;  //REMAIN_MINUTE   낭은 시간		N/A	INT	N
    RemainRMin: Integer;    //좌우겸용
    RemainLMin: Integer;    //좌우겸용
    RemainBall: Integer;    //REMAIN_BALL     남은 볼수		N/A	INT	N
    RemainRBall: Integer;   //좌우겸용
    RemainLBall: Integer;   //좌우겸용
    TeeboxReserve: TTeeboxReserved;
    DelayMin: Integer;      //지연시간(분)
    PauseTime: TDateTime;   //지연시작시간(점검, 볼회수, 타석기고장)
    RePlayTime: TDateTime;  //지연종료시간(점검, 볼회수, 타석기고장 해제)
    UseCancel: String;
    UseClose: String;
    UseReset: String;       //스타골프랜드 용
    PrepareChk: Integer;    //예약대기유지용
    ComReceive: String;     //타석기마스터와 통신여부(최초 실행시 데이터 Receive 여부)

    ErrorCnt: Integer;
    ErrorYn: String;

    RecvData: AnsiString;
    SendData: AnsiString;

    HoldUse: Boolean;
    HoldUser: String;

    ErrorCd: Integer; //2020-06-29 양평추가, 2020-08-20 STR->INT 변경(저장용)
    ErrorCd2: String;

    SendSMS: String; //2020-11-05 기기고장 sms 발송여부
    SendACS: String; //2021-02-16 기기고장 acs 발송여부

    ControlYn: String; //2020-12-16 빅토리아 반자동

    CheckCtrl: Boolean; //2021-06-02 점검시 제어체크용
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
    //Json: String; // 2021-10-05 EXPIRE_DAY, COUPON_CNT 컬럼추가로 제외

    //2020-08-18
    AffiliateCd: String;

    //2021-04-21
    XgUserKey: String;

    AssignYn: String; //2021-08-06 체크인

    //2021-10-05 레슨프로
    LessonProNm: String;
    LessonProPosColor: String;

    ExpireDay: String;
    CouponCnt: String;

    AccessBarcode: String; //출입바코드 2023-03-24
    AccessControlNm: String; //출입통제 구역명 2023-03-24

    AvailableZoneCd: String; //사용가능구역
  end;

  //임시데이터를 생성하거나 배정관련 매핑용
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

  //타석별 예약목록 관리용
  TTeeboxReserveList = record
    TeeboxNo: Integer;
    //nCurrIdx: Integer;
    //nLastIdx: Integer;
    CancelYn: String;
    ReserveList: TStringList; //TNextReserve
  end;

  //예약목록에서 관리하는 배정내역
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

    //2021-08-03 체크인용
    //FReserveDiv: String; //기간권, 쿠폰
    //FReserveRootDiv: String; //포스, 키오스크
    FAssignYn: String; //모바일인 경우 체크인 여부 확인 위해

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
    FloorZoneCode: String; //명칭으로 하면 층 글자가 문제됨
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
