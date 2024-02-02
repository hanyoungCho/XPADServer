program ADServer_in_280;

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
  uTeeboxReserveList in 'Teebox\uTeeboxReserveList.pas',
  uTeeboxThread in 'Teebox\uTeeboxThread.pas',
  Frame.ItemStyle in 'Frame\Frame.ItemStyle.pas' {Frame1: TFrame},
  uFunction in '..\common\uFunction.pas',
  uXGClientDM in 'Api\uXGClientDM.pas' {XGolfDM: TDataModule},
  uXGServer in 'Api\uXGServer.pas',
  uErpApi in 'Api\uErpApi.pas',
  uXGAgentServer in 'Api\uXGAgentServer.pas',
  uArpHelper in 'Tapo\uArpHelper.pas',
  uTapoHelper in 'Tapo\uTapoHelper.pas',
  IPHelper in 'Tapo\IPHelper.pas',
  IPHlpAPI in 'Tapo\IPHlpAPI.pas',
  CkGlobal in 'Tapo\CkGlobal.pas',
  uCommonLib in 'Tapo\uCommonLib.pas',
  CkJsonObject in 'Tapo\CkJsonObject.pas',
  CkJsonArray in 'Tapo\CkJsonArray.pas',
  uTapo in 'Tapo\uTapo.pas',
  Frame.ItemStyleTop in 'Frame\Frame.ItemStyleTop.pas' {Frame2: TFrame},
  uRoomInfo in 'Room\uRoomInfo.pas',
  uRoomThread in 'Room\uRoomThread.pas',
  uPassForm in 'uPassForm.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
