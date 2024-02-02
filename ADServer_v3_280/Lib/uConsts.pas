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
  JEU_CTL_FIN = #06; //6.0A ���� ���
  JEU_NAK = #15;
  JEU_SYN = #16;
  JEU_RECV_LENGTH = 15;
  JEU_RECV_LENGTH_17 = 17; //5.0A, 6.0A

  HEAT_MIN = 1;
  HEAT_MAX = 81;

  ERP_MAX = 29;

  JMS_ETX = $45;
  JMS_RECV_LENGTH = 5;

  MODEN_STX = #02;
  MODEN_ETX = #03;

  ERROR_CODE_1 = 1; //���ɸ�?
  ERROR_CODE_2 = 2; //������
  ERROR_CODE_3 = 3; //��������
  ERROR_CODE_4 = 4; //�����̻�
  ERROR_CODE_8 = 8; //����̻� - ���¿�û�ó� ����� ����������
  ERROR_CODE_9 = 9; //��źҷ�

  //����, ���
  ERROR_CODE_11 = 11; // error 1
  ERROR_CODE_12 = 12; // error 2
  ERROR_CODE_13 = 13; // error 3
  ERROR_CODE_14 = 14; // error 4
  ERROR_CODE_15 = 15; // error 5
  { ���� Ÿ���� �����ڵ�
  1. ����S/W  Error 1ǥ��
   Ƽ �������� (1������) Ÿ�� �� �� �ִ� ���� �غ� ��Ȳ��
   �����ϰ� ���� ������ ��ȣ�� ������ ����� ��
   (���� �̻�� 3�� �۵��� Error 1 ǥ��)

  2. ���� S/W Error 2ǥ��
   10 ~ 75mm ���� ������
   (���� �̻�� ���� :  ��, �� �)

  3. ���� S/W Error 3ǥ��
   �ӽ� ���� ������ ���� ���� ��� �� ������ũ�� ��ȣ�� ������ �������ش�
   (���� ����� ���� : Error ǥ��, �� �̼� ȣ���� ���� ���� ����� Error 3ǥ��)
  }

  { ��� Ÿ���� �����ڵ�
  1	������ �Է� �ð� �ʰ�
  2	���� ������ �Է½ð� �ʰ�(���� ��� �Ҹ�Ǿ���)
  3	����1(��ũ) ���� �Է½ð� �ʰ�
  4	����2(Ƽ��) ���� �Է½ð� �ʰ�
  5	���Լ��� �Է½ð� �ʰ�
  }

  INFOR_STX = #02;
  INFOR_ETX = #03;
  INFOR_REC = #06;

  NANO_ETX = $0D;

  COM_STX = #02;
  COM_ETX = #03;

implementation

end.
