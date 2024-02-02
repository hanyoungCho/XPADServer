program ADServer_EL;

uses
  FastMM4 in '..\..\..\FastMM4-master\FastMM4.pas',
  FastMM4Messages in '..\..\..\FastMM4-master\FastMM4Messages.pas',
  Vcl.Forms,
  System.SysUtils,
  uXGMainForm in 'uXGMainForm.pas' {MainForm},
  uGlobal in 'uGlobal.pas',
  uStruct in 'Lib\uStruct.pas',
  uConsts in 'Lib\uConsts.pas',
  FILELOG in 'Lib\FILELOG.pas',
  uLogging in 'Lib\uLogging.pas',
  uTeeboxInfo in 'Teebox\uTeeboxInfo.pas',
  uTeeboxReserveList in 'Teebox\uTeeboxReserveList.pas',
  uTeeboxThread in 'Teebox\uTeeboxThread.pas',
  uFunction in '..\common\uFunction.pas',
  uXGClientDM in 'Api\uXGClientDM.pas' {XGolfDM: TDataModule},
  uXGServer in 'Api\uXGServer.pas',
  uErpApi in 'Api\uErpApi.pas',
  uXGAgentServer in 'Api\uXGAgentServer.pas',
  Frame.ItemStyle in 'Frame\Frame.ItemStyle.pas' {Frame1: TFrame},
  CkGlobal in 'Tapo\CkGlobal.pas',
  CkJsonArray in 'Tapo\CkJsonArray.pas',
  CkJsonObject in 'Tapo\CkJsonObject.pas',
  IPHelper in 'Tapo\IPHelper.pas',
  IPHlpAPI in 'Tapo\IPHlpAPI.pas',
  uArpHelper in 'Tapo\uArpHelper.pas',
  uCommonLib in 'Tapo\uCommonLib.pas',
  uTapoHelper in 'Tapo\uTapoHelper.pas',
  uTapo in 'Tapo\uTapo.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
