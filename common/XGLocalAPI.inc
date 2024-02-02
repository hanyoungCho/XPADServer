const
  { 로컬 API Id }
  GC_API_TERMINAL         = 1001; //터미널 정보
  GC_API_STORE            = 1002; //사업장 정보
  GC_API_ACCOUNT          = 1003; //사용자 계정 정보
  GC_API_CODE             = 1004; //공통 코드
  GC_API_CONFIG           = 1005; //환경설정
  GC_API_TEEBOX           = 1006; //타석 정보
  GC_API_LOCKER           = 1007; //라커 정보
  GC_API_TABLE            = 1008; //테이블(룸) 정보
  GC_API_PROD_TEEBOX      = 1009; //타석 상품 정보
  GC_API_PROD_LOCKER      = 1010; //라커 상품 정보
  GC_API_PROD_GENERAL     = 1011; //일반 상품 정보
  GC_API_PLU_LIST         = 1012; //PLU  설정 정보
  GC_API_ADVERTISE        = 1013; //광고 정보
  GC_API_MEMBER           = 1014; //회원 정보
  GC_API_MEMBER_TEEBOX    = 1015; //회원별 타석 보유상품
  GC_API_MEMBER_LOCKER    = 1016; //회원별 라커 보유상품
  GC_API_LOCKER_STATUS    = 1017; //라커 운영 상황
  GC_API_SALE_RECEIPT     = 1018; //거래 내역
  GC_API_CALENDAR         = 1019; //휴일 정보
  GC_API_PROD_TEEBOX_TIME = 1020; //타석상품 사용시간

  GC_API_DATASET_COUNT    = 20;

  GC_API_LIVE_TEEBOX_AD     = 2001; //타석기AD 라이브 체크
  GC_API_SEND_SMS           = 2002; //문자메시지(SMS) 전송 요청
  GC_API_LOCKER_END         = 2003; //라커 정리
  GC_API_SEND_MEMBER_QRCODE = 2004; //회원 QR코드 전송 요청

  GC_RESULT_SUCCESS       = '0000';
  GC_RESULT_SERVER_DENIED = '9001';

  GC_API_METHOD_GET       = 'GET';
  GC_API_METHOD_POST      = 'POST';
  GC_API_METHOD_PUT       = 'PUT';

  { DBSync Flag }
  GC_DBSYNC_NEW           = 'N'; //신규 등록: 회원정보 등록, 타석예약 등록(K701)
  GC_DBSYNC_CHANGE        = 'U'; //수정: 회원정보 수정, 타석예약 변경(K703)
  GC_DBSYNC_ASSIGN        = 'I'; //배정: 타석 배정(K702)
  GC_DBSYNC_ASSIGN_END    = 'Q'; //종료: 타석배정 종료(K705)
  GC_DBSYNC_MOVE          = 'M'; //이동: 타석 이동(K706)
  GC_DBSYNC_DELETE        = 'D'; //삭제
  GC_DBSYNC_NEED_DETAIL   = 'S'; //상세내역 동기화 처리 필요
  GC_DBSYNC_APPROVE       = 'A'; //승인
  GC_DBSYNC_CANCEL        = 'X'; //취소: 거래승인 취소, 타석예약 취소(K704)
  GC_DBSYNC_CLEAR         = 'E'; //정리: 타석 정리, 라커 정리(K711)
  GC_DBSYNC_SALE_CHANGE   = 'R'; //전환상품 거래
  GC_DBSYNC_CASH_RECEIPT  = 'C'; //현금영수증 발행
  GC_DBSYNC_COMPLETE      = 'Y'; //완료

{ EOF }