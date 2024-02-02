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

  HEAT_MIN = 1;
  HEAT_MAX = 81;

  ERP_MAX = 29;

  NANO_ETX = $0D;

implementation

end.
