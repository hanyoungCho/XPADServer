unit uConsts;

interface

const
  COM_CTL = 1;
  COM_MON = 2;

  COM_CTL_MAX = 255;

  ZOOM_MON_STX = #01; //$01
  ZOOM_STX = #02; //$02
  ZOOM_CTL_STX = #05; //$05

  ZOOM_ETX = #03; //$03
  ZOOM_REQ_ETX = #04; //$04

  ZOOM_CC_SOH = #01;
  ZOOM_CC_STX = #02;
  ZOOM_CC_ETX = #03;
  ZOOM_CC_EOT = #04;
  ZOOM_CC_ENQ = #05;

  JEU_STX = #02;
  JEU_ETX = #03;
  JEU_MON_ERR = #04;
  JEU_ENQ = #05;
  JEU_CTL_FIN = #06; //6.0A 에서 사용
  JEU_NAK = #15;
  JEU_SYN = #16;
  JEU_RECV_LENGTH = 15;
  JEU_RECV_LENGTH_17 = 17; //5.0A, 6.0A

  HEAT_MIN = 1;
  HEAT_MAX = 81; //스타: 타석수보다 포인트가 많음

  ERP_MAX = 29;

  JMS_ETX = $45;
  JMS_RECV_LENGTH = 5;

  MODEN_STX = #02;
  MODEN_ETX = #03;

  ERROR_CODE_1 = 1; //볼걸림?
  ERROR_CODE_2 = 2; //볼없음
  ERROR_CODE_3 = 3; //수동제어
  ERROR_CODE_4 = 4; //모터이상
  ERROR_CODE_8 = 8; //통신이상 - 상태요청시나 제어시 응답없을경우
  ERROR_CODE_9 = 9; //통신불량

  //제우, 모던
  ERROR_CODE_11 = 11; // error 1
  ERROR_CODE_12 = 12; // error 2
  ERROR_CODE_13 = 13; // error 3
  ERROR_CODE_14 = 14; // error 4
  ERROR_CODE_15 = 15; // error 5
  { 제우 타석기 에러코드
  1. 조작S/W  Error 1표시
   티 감지센서 (1번센서) 타구 할 수 있는 공의 준비 상황을
   감지하고 다음 공정의 신호를 보내는 기능을 함
   (센서 이상시 3번 작동후 Error 1 표시)

  2. 조작 S/W Error 2표시
   10 ~ 75mm 높이 조절함
   (센서 이상시 증상 :  상, 하 운동)

  3. 조작 S/W Error 3표시
   임시 저장 공간에 볼이 없을 경우 볼 저장탱크에 신호를 보내서 공급해준다
   (센서 고장시 증상 : Error 표시, 볼 이송 호스에 볼이 막힘 현상시 Error 3표시)
  }

  { 모던 타석기 에러코드
  1	볼센서 입력 시간 초과
  2	레일 볼센서 입력시간 초과(공이 모두 소모되었슴)
  3	모터1(후크) 센서 입력시간 초과
  4	모터2(티업) 센서 입력시간 초과
  5	리밋센서 입력시간 초과
  }

  NANO_ETX = $0D;


implementation

end.
