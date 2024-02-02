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
    Port: integer;
    Baudrate: integer;

    ApiUrl: string;
    TcpPort: Integer;
    DBPort: Integer;
    ProtocolType: String;
    SystemInstall: String;
  end;

  {가맹점	정보}
  TStoreInfo = record
    StoreCd: String;
    StoreNm: String;
    StartTime: String;
    EndTime: String;
    EndDBTime: String;
    UseRewardYn: String;
    Close: String;
    StoreLastTM: String; //store 마지막수정시간
    StoreChgDate: String; //store 마지막수정시간ERP
    ErrorSms: String; //기기고장 1분유지시 문자발송여부
  end;

  {타석예약 }
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

  { 타석테이블명 SEAT	}
  TTeeboxInfo = record
   	StoreCd: String;
    TeeboxNo: Integer;
    TeeboxNm: String;
    FloorZoneCode: String;
    FloorNm: String;
    ZoneDiv: String;
    DeviceId: String;
    RecvDeviceId: String;   //타석기 장치 ID		응답후 L인경우 좌우구분용
    //UseStatusPre: String;
    UseStatus: String;	    // (0:대기, 1:이용중, 9:이용불가)
    //UseRStatus: String;     //좌우겸용
    //UseLStatus: String;     //좌우겸용
    //UseApiStatus: String;	  // API 이용 상태	8:점검
    UseYn: String;
    RemainMinPre: Integer;
    RemainMinute: Integer;
    //RemainRMin: Integer;  //좌우겸용
    //RemainLMin: Integer;  //좌우겸용
    RemainBall: Integer;
    //RemainRBall: Integer;    //좌우겸용
    //RemainLBall: Integer;    //좌우겸용
    Reserve: TReserved;
    DelayMin: Integer;      //지연시간(분)
    PauseTime: TDateTime;   //지연시작시간(점검, 볼회수, 타석기고장)
    RePlayTime: TDateTime;  //지연종료시간(점검, 볼회수, 타석기고장 해제)
    UseCancel: String;
    UseClose: String;
    //UseReset: String; //스타골프랜드 용
    //PrepareChk: Integer; //예약대기유지용
    ComReceive: String; //타석기마스터와 통신여부(최초 실행시 데이터 Receive 여부)

    ErrorCnt: Integer;
    ErrorYn: String;

    //RecvData: AnsiString;
    //SendData: AnsiString;

    HoldUse: Boolean;
    HoldUser: String;

    ErrorCd: Integer; //2020-06-29 양평추가, 2020-08-20 STR->INT 변경(저장용)

    SendSMS: String; //2020-11-05 기기고장 sms 발송여부

    DeviceUseStatus: String; //0:정지, 1:이용중, D:대기
    DeviceUseStatus_R: String;
    DeviceUseStatus_L: String;
    DeviceRemainMin: Integer; //2021-09-01 타석기 잔여시간
    DeviceRemainMin_R: Integer;
    DeviceRemainMin_L: Integer;
    DeviceRemainBall_R: Integer;
    DeviceRemainBall_L: Integer;
    DeviceCtrlCnt: Integer; //타석기 제어횟수
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
    SeatUseStatus: String;      // 4: 예약
    UseDiv: String;         // 1:배정, 2:추가
    MemberSeq: String;
    MemberNm: String;
    //MemberTel: String;
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
  //타석별 예약목록 관리용
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
