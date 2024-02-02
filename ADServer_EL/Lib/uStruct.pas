unit uStruct;

interface

uses
  System.Generics.Collections, Classes;

const
  BUFFER_SIZE = 255;

type
  // AD 정보
  TADConfig = record
    StoreCode: String;
    UserId: String;
    //UserPw: String;

    ApiUrl: string;
    TcpPort: Integer;
    AgentTcpPort:Integer;
    AgentSendPort:Integer;
    AgentSendUse: String; //에이전트 송신이 별도인경우 - 임시
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

  // 가맹점	테이블명	STORE
  TStoreInfo = record
    StoreCd: String;
    StoreNm: String;

    StartTime: String;
    EndTime: String;

    //Close: String;
    StoreLastTM: String; //store 마지막수정시간
    StoreChgDate: String; //store 마지막수정시간ERP
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
    ChangeMin: Integer;
  end;

  // 타석테이블명 SEAT
  TTeeboxInfo = record
   	StoreCd: String;
    TeeboxNo: Integer;  //고유번호
    TeeboxNm: String;
    FloorCd: String;
    FloorNm: String;
    DeviceId: String;
    ZoneLeft: String;	//0:우타석, 1:좌타석, 2:좌우겸용 ?
    ZoneDiv: String;	//V : VIP 석, G:일반석, L:레슨타석, A:분석타석
    UseYn: String;

    UseStatusPre: String;   //이전 상태
    UseStatus: String;	    //USE_STATUS      이용 상태	   (0:대기, 1:이용중,2:종료,3:홀드,4:예약중,5:취소,7:볼회수,8:점검, 9:이용불가)

    RemainMinPre: Integer;  //이전 잔여시간
    RemainMinute: Integer;  //REMAIN_MINUTE   낭은 시간		N/A	INT	N

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
    //ComReceive: String;     //타석기마스터와 통신여부(최초 실행시 데이터 Receive 여부)

    HoldUse: Boolean;
    HoldUser: String;

    ChangeMin: integer;

    AgentIP_R: String;
    AgentIP_L: String;
    AgentCtlType: String; //N:없음, D:대기, S:시작, C:변경, E:종료
    AgentCtlYN: String; // 0:준비, 1:제어(응답받음), 2:재제어

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
    SeatUseStatus: String;      // 4: 예약
    //UseDiv: String;         // 1:배정, 2:추가
    MemberSeq: String;
    MemberNm: String;
    //MemberTel: String;
    //PurchaseSeq: Integer;
    ProductSeq: Integer;
    ProductNm: String;
    ReserveDiv: String;
    //ReceiptNo: String; //영수증번호, 매출취소시 예약타석 삭제용
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
