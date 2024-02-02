program ADServer_v3_280;

uses
  FastMM4 in '..\..\FastMM4-master\FastMM4.pas',
  FastMM4Messages in '..\..\FastMM4-master\FastMM4Messages.pas',
  Vcl.Forms,
  System.SysUtils,
  uXGMainForm in 'uXGMainForm.pas' {MainForm},
  uGlobal in 'uGlobal.pas',
  uStruct in 'Lib\uStruct.pas',
  uConsts in 'Lib\uConsts.pas',
  uLogging in 'Lib\uLogging.pas',
  FILELOG in 'Lib\FILELOG.pas',
  uTeeboxInfo in 'Teebox\uTeeboxInfo.pas',
  uTeeboxThread in 'Teebox\uTeeboxThread.pas',
  uTeeboxReserveList in 'Teebox\uTeeboxReserveList.pas',
  uHeatControlTcp in 'uHeatControlTcp.pas',
  Frame.ItemStyle in 'Frame\Frame.ItemStyle.pas' {Frame1: TFrame},
  uFunction in '..\common\uFunction.pas',
  uXGClientDM in 'Api\uXGClientDM.pas' {XGolfDM: TDataModule},
  uXGServer in 'Api\uXGServer.pas',
  uErpApi in 'Api\uErpApi.pas',
  uHeatControlCom in 'Comport\uHeatControlCom.pas',
  uComZoom in 'Comport\uComZoom.pas',
  uComJehu435 in 'Comport\uComJehu435.pas',
  uComJMS in 'Comport\uComJMS.pas',
  uComJehu60A in 'Comport\uComJehu60A.pas',
  uComJehu50A in 'Comport\uComJehu50A.pas',
  uComModen in 'Comport\uComModen.pas',
  uComModenYJ in 'Comport\uComModenYJ.pas',
  uComSM in 'Comport\uComSM.pas',
  uComInfornet in 'Comport\uComInfornet.pas',
  uComInfornetPLC in 'Comport\uComInfornetPLC.pas',
  uComNano in 'Comport\uComNano.pas',
  uComNano2 in 'Comport\uComNano2.pas',
  uComWin in 'Comport\uComWin.pas',
  uComFan_DOME in 'Comport\uComFan_DOME.pas',
  uComHeat_DOME in 'Comport\uComHeat_DOME.pas',
  uDebug in 'uDebug.pas' {frmDebug},
  uComZoomCC in 'Comport\uComZoomCC.pas',
  uComHeat_A8003 in 'Comport\uComHeat_A8003.pas',
  uComFieldLo in 'Comport\uComFieldLo.pas',
  uXGAgentServer in 'Api\uXGAgentServer.pas',
  uComMagicShot in 'Comport\uComMagicShot.pas',
  uComHeat_D4001 in 'Comport\uComHeat_D4001.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
