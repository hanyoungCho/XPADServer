(*******************************************************************************

  Filename    : uTapoHelper.pas
  Author      : ÀÌ¼±¿ì
  Description : TP-Link Tapo SmartPlug Helper
  History     :
    Version   Date         Remark
    --------  ----------   -----------------------------------------------------
    1.0.0.0   2021-09-30   Initial Release.

*******************************************************************************)
unit uTapoHelper;

interface

uses
  { Native }
  System.Classes, System.SysUtils,
  { Python4Delphi }
  PythonEngine, PythonVersions;

const
  CS_APP_TYPE         = 'XPartners_TeeBoxAD';

  CS_GET_TOKEN        = 'getToken';
  CS_GET_DEVICE_LIST  = 'getDeviceList';
  CS_GET_DEVICE_INFO  = 'getDeviceInfo';
  CS_GET_RUNNING_INFO = 'getDeviceRunningInfo';
  CS_PLUG_ON          = 'plugOn';
  CS_PLUG_OFF         = 'plugOff';
  CS_SET_NICK_NAME    = 'setNickname';

type
  TTapoHelper = class
  private
    FPythonEngine: TPythonEngine;
    FPythonVar: TPythonDelphiVar;
    FPyScript: TStrings;
    FTapoHost: string;
    FTapoEmail: string;
    FTapoPwd: string;
    FTerminalUUID: string;
    FPythonEngineLoaded: Boolean;
    FNickName: string;

    function RunPythonScript(const ACommand, ATapoIP: string; var AResponse, AErrMsg: string): Boolean;
    procedure MakePythonScript(const ACommand, ATapoIP: string);
  public
    constructor Create(const ATapoHost, ATapoEmail, ATapoPwd, ATerminalUUID: string);
    destructor Destroy; override;

    function GetCloudToken(var AResponse, AErrMsg: string): Boolean;
    function GetDeviceList(var AResponse, AErrMsg: string): Boolean;
    function GetDeviceInfo(const ATapoIP: string; var AResponse, AErrMsg: string): Boolean;
    function GetDeviceRunningInfo(const ATapoIP: string; var AResponse, AErrMsg: string): Boolean;
    function SetDeviceOnOff(const ATapoIP: string; const APowerOn: Boolean; var AResponse, AErrMsg: string): Boolean;
    function SetNickName(const ATapoIP, ANickName: string; var AResponse, AErrMsg: string): Boolean;

    property PythonEngine: TPythonEngine read FPythonEngine write FPythonEngine;
    property PythonEngineLoaded: Boolean read FPythonEngineLoaded;

    property TapoHost: string read FTapoHost write FTapoHost;
    property TapoEmail: string read FTapoEmail write FTapoEmail;
    property TapoPwd: string read FTapoPwd write FTapoPwd;
    property TerminalUUID: string read FTerminalUUID write FTerminalUUID;
    property NickName: string read FNickName write FNickName;
  end;

implementation

{ TTapoHelper }

constructor TTapoHelper.Create(const ATapoHost, ATapoEmail, ATapoPwd, ATerminalUUID: string);
var
  PyVersion: TPythonVersion;
  PyVersions: TPythonVersions;
  PyVersionList: TStrings;
begin
  FTapoHost := ATapoHost;
  FTapoEmail := ATapoEmail;
  FTapoPwd := ATapoPwd;
  FTerminalUUID := ATerminalUUID;
  FNickName := '';

  FPyScript := TStringList.Create;
  FPythonEngine := TPythonEngine.Create(nil);
  FPythonVar := TPythonDelphiVar.Create(nil);

  PyVersionList := TStringList.Create;
  try
    PyVersions := GetRegisteredPythonVersions;
    for PyVersion in PyVersions do
      PyVersionList.Add(PyVersion.DisplayName);

    if (PyVersionList.Count < 0) then
      raise Exception.Create('Not detected Python.');

    PyVersions[0].AssignTo(FPythonEngine);

    FPythonVar.Engine := FPythonEngine;
    FPythonVar.VarName := 'retvar';
    FPythonEngine.LoadDll;
    FPythonEngineLoaded := True;
  finally
    FreeAndNil(PyVersionList);
  end;
end;

destructor TTapoHelper.Destroy;
begin
  FreeAndNil(FPyScript);
  FreeAndNil(FPythonVar);
  FreeAndNil(FPythonEngine);

  inherited;
end;

function TTapoHelper.GetCloudToken(var AResponse, AErrMsg: string): Boolean;
begin
  Result := RunPythonScript(CS_GET_TOKEN, '', AResponse, AErrMsg);
end;

function TTapoHelper.GetDeviceList(var AResponse, AErrMsg: string): Boolean;
begin
  Result := RunPythonScript(CS_GET_DEVICE_LIST, '', AResponse, AErrMsg);
end;

function TTapoHelper.GetDeviceInfo(const ATapoIP: string; var AResponse, AErrMsg: string): Boolean;
begin
  Result := RunPythonScript(CS_GET_DEVICE_INFO, ATapoIP, AResponse, AErrMsg);
end;

function TTapoHelper.GetDeviceRunningInfo(const ATapoIP: string; var AResponse, AErrMsg: string): Boolean;
begin
  Result := RunPythonScript(CS_GET_RUNNING_INFO, ATapoIP, AResponse, AErrMsg);
end;

function TTapoHelper.SetDeviceOnOff(const ATapoIP: string; const APowerOn: Boolean; var AResponse, AErrMsg: string): Boolean;
begin
  if APowerOn then
    Result := RunPythonScript(CS_PLUG_ON, ATapoIP, AResponse, AErrMsg)
  else
    Result := RunPythonScript(CS_PLUG_OFF, ATapoIP, AResponse, AErrMsg);
end;

function TTapoHelper.SetNickName(const ATapoIP, ANickName: string; var AResponse, AErrMsg: string): Boolean;
begin
  try
    NickName := ANickName;
    Result := RunPythonScript(CS_SET_NICK_NAME, ATapoIP, AResponse, AErrMsg);
  finally
    NickName := '';
  end;
end;

function TTapoHelper.RunPythonScript(const ACommand, ATapoIP: string; var AResponse, AErrMsg: string): Boolean;
begin
  Result := False;
  AErrMsg := '';
  try
    MakePythonScript(ACommand, ATapoIP);
    FPyScript.SaveToFile('.\log\PyScript.py');
    FPythonEngine.ExecStrings(FPyScript);
    AResponse := FPythonVar.ValueAsString;
    AResponse := StringReplace(AResponse, 'False', 'false', [rfReplaceAll]);
    AResponse := StringReplace(AResponse, 'True', 'true', [rfReplaceAll]);
    AResponse := StringReplace(AResponse, #39, #34, [rfReplaceAll]);
    Result := True;
  except
    on E: Exception do
      AErrMsg := E.Message;
  end;
end;

procedure TTapoHelper.MakePythonScript(const ACommand, ATapoIP: string);
begin
  FPyScript.Clear;
  FPyScript.Add('from python.PublicKey import RSA');
  FPyScript.Add('from python.Cipher import AES');
  FPyScript.Add('from python.Cipher import PKCS1_v1_5');
  FPyScript.Add('from python.pkcs7 import PKCS7Encoder');
  FPyScript.Add('from python import requests');
  FPyScript.Add('import hashlib');
  FPyScript.Add('import base64');
  FPyScript.Add('import json');
  FPyScript.Add('import time');

  FPyScript.Add(Format('tapoEmail = "%s"', [TapoEmail]));
  FPyScript.Add(Format('tapoPassword = "%s"', [TapoPwd]));
  FPyScript.Add(Format('terminalUUID = "%s"', [TerminalUuid]));
  FPyScript.Add(Format('nickname = "%s"', [NickName]));
  FPyScript.Add('device = {');
  FPyScript.Add('    "tapoIp": "' + ATapoIP + '",');
  FPyScript.Add('    "tapoEmail": tapoEmail,');
  FPyScript.Add('    "tapoPassword": tapoPassword,');
  FPyScript.Add('    "nickname": nickname');
  FPyScript.Add('}');

  FPyScript.Add('def generateKeyPair():');
  FPyScript.Add('  key = RSA.generate(1024)');
  FPyScript.Add('  privateKey = key.export_key(pkcs=8)');
  FPyScript.Add('  publicKey = key.publickey().export_key(pkcs=8)');
  FPyScript.Add('  tapoKeyPair = {');
  FPyScript.Add('    "publicKey": publicKey.decode("utf-8"),');
  FPyScript.Add('    "privateKey": privateKey.decode("utf-8")');
  FPyScript.Add('  }');
  FPyScript.Add('  return tapoKeyPair');

  FPyScript.Add('def decodeTapoKey(tapoKey, tapoKeyPair):');
  FPyScript.Add('  try:');
  FPyScript.Add('    encrypt_data = base64.b64decode(tapoKey)');
  FPyScript.Add('    rsa_key = RSA.importKey(tapoKeyPair["privateKey"])');
  FPyScript.Add('    cipher = PKCS1_v1_5.new(rsa_key)');
  FPyScript.Add('    decryptedBytes = cipher.decrypt(encrypt_data, None)');
  FPyScript.Add('    decodedTapoKey = {');
  FPyScript.Add('      "secretKeySpec": decryptedBytes[:16],');
  FPyScript.Add('      "ivParameterSpec": decryptedBytes[16:32]');
  FPyScript.Add('    }');
  FPyScript.Add('    return decodedTapoKey');
  FPyScript.Add('  except Exception as e:');
  FPyScript.Add('    raise e');

  FPyScript.Add('def shaDigestEmail(email):');
  FPyScript.Add('  email = str.encode(email)');
  FPyScript.Add('  emailHash = hashlib.sha1(email).hexdigest()');
  FPyScript.Add('  return emailHash');

  FPyScript.Add('def encryptJsonData(decodedTapoKey, jsonData):');
  FPyScript.Add('  try:');
  FPyScript.Add('    PKCS7 = PKCS7Encoder()');
  FPyScript.Add('    aes = AES.new(decodedTapoKey["secretKeySpec"], AES.MODE_CBC, IV=decodedTapoKey["ivParameterSpec"])');
  FPyScript.Add('    padJsonData = PKCS7.encode(jsonData).encode()');
  FPyScript.Add('    encryptedJsonData = aes.encrypt(padJsonData)');
  FPyScript.Add('    return base64.b64encode(encryptedJsonData).decode();');
  FPyScript.Add('  except Exception as e:');
  FPyScript.Add('    raise e');

  FPyScript.Add('def decryptJsonData(decodedTapoKey, encryptedJsonData):');
  FPyScript.Add('    encryptedJsonData = base64.b64decode(encryptedJsonData)');
  FPyScript.Add('    aes = AES.new(decodedTapoKey["secretKeySpec"], AES.MODE_CBC, IV=decodedTapoKey["ivParameterSpec"])');
  FPyScript.Add('    decryptedJsonData = aes.decrypt(encryptedJsonData)');
  FPyScript.Add('    return decryptedJsonData.decode().strip()');

  FPyScript.Add('def getToken(email, password):');
  FPyScript.Add('  URL = "' + FTapoHost + '"');
  FPyScript.Add('  Payload = {');
  FPyScript.Add('      "method": "login",');
  FPyScript.Add('      "params": {');
  FPyScript.Add('          "appType": "' + CS_APP_TYPE + '",');
  FPyScript.Add('          "cloudUserName": email,');
  FPyScript.Add('          "cloudPassword": password,');
  FPyScript.Add('          "terminalUUID": terminalUUID');
  FPyScript.Add('      }');
  FPyScript.Add('  }');
  FPyScript.Add('  response = requests.post(URL, json=Payload).json()["result"]["token"]');
  FPyScript.Add('  return response');

  FPyScript.Add('def getDeviceList(email, password):');
  FPyScript.Add('  URL = "' + FTapoHost + '?token=" + getToken(email, password)');
  FPyScript.Add('  Payload = {');
  FPyScript.Add('      "method": "getDeviceList"');
  FPyScript.Add('  }');
  FPyScript.Add('  response = requests.post(URL, json=Payload).json()');
  FPyScript.Add('  return response');

  FPyScript.Add('def getDeviceInfo(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "get_device_info",');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def getDeviceRunningInfo(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "get_device_running_info",');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def plugOn(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "set_device_info",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "device_on": True');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def plugOff(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "set_device_info",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "device_on": False');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def getDiagnoseStatus(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "get_diagnose_status",');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def getPlugUsage(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  deviceID = json.loads(getDeviceInfo(deviceInfo))["result"]["device_id"]');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "get_device_usage",');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def qsComponentNego(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  deviceID = json.loads(getDeviceInfo(deviceInfo))["result"]["device_id"]');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "qs_component_nego",');
  FPyScript.Add('    "params":   {');
  FPyScript.Add('       "device_id":deviceID');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def setNickname(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  deviceID = json.loads(getDeviceInfo(deviceInfo))["result"]["device_id"]');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "set_device_info",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "device_id": deviceID,');
  FPyScript.Add('      "nickname": deviceInfo["nickname"]');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def getLedInfo(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "get_led_info",');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def ledOff(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "set_led_info",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('        "led_status": False,');
  FPyScript.Add('        "led_rule": "never",');
  FPyScript.Add('        "night_mode": {');
  FPyScript.Add('          "night_mode_type": "unknown",');
  FPyScript.Add('          "sunrise_offset": 0,');
  FPyScript.Add('          "sunset_offset": 0,');
  FPyScript.Add('          "start_time": 0,');
  FPyScript.Add('          "end_time": 0');
  FPyScript.Add('        }');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def ledOn(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "set_led_info",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('        "led_status": True,');
  FPyScript.Add('        "led_rule": "always",');
  FPyScript.Add('        "night_mode": {');
  FPyScript.Add('          "night_mode_type": "unknown",');
  FPyScript.Add('          "sunrise_offset": 0,');
  FPyScript.Add('          "sunset_offset": 0,');
  FPyScript.Add('          "start_time": 0,');
  FPyScript.Add('          "end_time": 0');
  FPyScript.Add('        }');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def plugOffCountdown(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "add_countdown_rule",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('       "delay":int(deviceInfo["delay"]),');
  FPyScript.Add('       "desired_states": {');
  FPyScript.Add('        "on": False');
  FPyScript.Add('       },');
  FPyScript.Add('       "enable": True,');
  FPyScript.Add('       "remain": int(deviceInfo["delay"])');
  FPyScript.Add('     },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def plugOnCountdown(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "add_countdown_rule",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "delay": int(deviceInfo["delay"]),');
  FPyScript.Add('      "desired_states": {');
  FPyScript.Add('        "on": True');
  FPyScript.Add('     },');
  FPyScript.Add('     "enable": True,');
  FPyScript.Add('      "remain": int(deviceInfo["delay"])');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def getPlugLog(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "get_device_log",');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def getWirelessScanInfo(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "get_wireless_scan_info",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "start_index": 0');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def setWirelessInfo(deviceInfo):');
  FPyScript.Add('  keys = loadKeys(deviceInfo)');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "set_qs_info",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "account": {');
  FPyScript.Add('          "password": base64.b64encode(deviceInfo["tapoEmail"].encode()).decode("utf-8"),');
  FPyScript.Add('          "username": base64.b64encode(deviceInfo["tapoPassword"].encode()).decode("utf-8")');
  FPyScript.Add('      },');
  FPyScript.Add('      "time": {');
  FPyScript.Add('          "latitude": 90,');
  FPyScript.Add('          "longitude": -135,');
  FPyScript.Add('          "region": deviceInfo["region"],');
  FPyScript.Add('          "time_diff": 60,');
  FPyScript.Add('          "timestamp": 1619885501');
  FPyScript.Add('      },');
  FPyScript.Add('      "wireless": {');
  FPyScript.Add('          "key_type": deviceInfo["key_type"],');
  FPyScript.Add('          "password": base64.b64encode(deviceInfo["password"].encode()).decode("utf-8"),');
  FPyScript.Add('          "ssid": base64.b64encode(deviceInfo["ssid"].encode()).decode("utf-8")');
  FPyScript.Add('      }');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0,');
  FPyScript.Add('    "terminalUUID": terminalUUID');
  FPyScript.Add('  }');
  FPyScript.Add('  return data');
  FPyScript.Add('  response = execRequest(deviceInfo, keys, data)');
  FPyScript.Add('  return response');

  FPyScript.Add('def generateHandshake(tapoIP, publicKey):');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "handshake",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "key": publicKey');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0');
  FPyScript.Add('  }');
  FPyScript.Add('  response = requests.post("http://{}/app".format(tapoIP), data=json.dumps(data), verify=False)');
  FPyScript.Add('  if response.status_code != 200:');
  FPyScript.Add('    error = {');
  FPyScript.Add('      "code": response.status_code,');
  FPyScript.Add('      "error": "Somthing is wrong."');
  FPyScript.Add('    }');
  FPyScript.Add('  return response');

  FPyScript.Add('def loginRequest(deviceInfo, decodedTapoKey, tapoCookie):');
  FPyScript.Add('  emailHash = shaDigestEmail(deviceInfo["tapoEmail"])');
  FPyScript.Add('  data = {');
  FPyScript.Add('    "method": "login_device",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "username": base64.b64encode(emailHash.encode()).decode("utf-8"),');
  FPyScript.Add('      "password": base64.b64encode(deviceInfo["tapoPassword"].encode()).decode("utf-8")');
  FPyScript.Add('    },');
  FPyScript.Add('    "requestTimeMils": 0');
  FPyScript.Add('  }');
  FPyScript.Add('  encyptedJsonData = encryptJsonData(decodedTapoKey, json.dumps(data))');
  FPyScript.Add('  secureData = {');
  FPyScript.Add('    "method": "securePassthrough",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "request": encyptedJsonData');
  FPyScript.Add('      }');
  FPyScript.Add('    }');
  FPyScript.Add('  cookies = {');
  FPyScript.Add('    tapoCookie[0] : tapoCookie[1]');
  FPyScript.Add('  }');
  FPyScript.Add('  response = requests.post("http://{}/app".format(deviceInfo["tapoIp"]), cookies=cookies, data=json.dumps(secureData), verify=False)');
  FPyScript.Add('  if response.status_code != 200:');
  FPyScript.Add('    error = {');
  FPyScript.Add('      "code": response.status_code,');
  FPyScript.Add('      "error": "Somthing is wrong."');
  FPyScript.Add('    }');
  FPyScript.Add('  encryptedJsonResponse = json.loads(response.content.decode("utf-8"))["result"]["response"]');
  FPyScript.Add('  decryptedJsonData = decryptJsonData(decodedTapoKey, encryptedJsonResponse)');
  FPyScript.Add('  authToken = json.loads(decryptedJsonData)["result"]["token"]');
  FPyScript.Add('  return authToken');

  FPyScript.Add('def execRequest(deviceInfo, keys, data):');
  FPyScript.Add('  encyptedJsonData = encryptJsonData(keys["decodedTapoKey"], json.dumps(data))');
  FPyScript.Add('  secureData = {');
  FPyScript.Add('    "method": "securePassthrough",');
  FPyScript.Add('    "params": {');
  FPyScript.Add('      "request": encyptedJsonData');
  FPyScript.Add('      }');
  FPyScript.Add('  }');
  FPyScript.Add('  cookies = {');
  FPyScript.Add('    keys["tapoCookie"][0]: keys["tapoCookie"][1]');
  FPyScript.Add('  }');
  FPyScript.Add('  response = requests.post("http://{}/app?token={}".format(deviceInfo["tapoIp"],keys["tapoAuthToken"]), cookies=cookies, data=json.dumps(secureData), verify=False)');
  FPyScript.Add('  if response.status_code != 200:');
  FPyScript.Add('    error = {');
  FPyScript.Add('      "code": response.status_code,');
  FPyScript.Add('      "error": "Somthing is wrong."');
  FPyScript.Add('    }');
  FPyScript.Add('  encryptedJsonResponse = json.loads(response.content.decode("utf-8"))["result"]["response"]');
  FPyScript.Add('  decryptedJsonData = decryptJsonData(keys["decodedTapoKey"], encryptedJsonResponse)');
  FPyScript.Add('  return "".join(n for n in decryptedJsonData if ord(n) >= 32 and ord(n) <= 126)');

  FPyScript.Add('def loadKeys(deviceInfo):');
  FPyScript.Add('  tapoKeyPair = generateKeyPair()');
  FPyScript.Add('  handshakeRequest = generateHandshake(deviceInfo["tapoIp"], tapoKeyPair["publicKey"])');
  FPyScript.Add('  tapoKey = json.loads(handshakeRequest.content.decode("utf-8"))["result"]["key"]');
  FPyScript.Add('  tapoCookie = handshakeRequest.headers["Set-Cookie"].split(";")[0].split("=")');
  FPyScript.Add('  decodedTapoKey = decodeTapoKey(tapoKey, tapoKeyPair)');
  FPyScript.Add('  tapoAuthToken = loginRequest(deviceInfo, decodedTapoKey, tapoCookie)');
  FPyScript.Add('  keys = {');
  FPyScript.Add('    "tapoKeyPair": tapoKeyPair,');
  FPyScript.Add('    "tapoKey": tapoKey,');
  FPyScript.Add('    "decodedTapoKey": decodedTapoKey,');
  FPyScript.Add('    "tapoCookie": tapoCookie,');
  FPyScript.Add('    "tapoAuthToken": tapoAuthToken');
  FPyScript.Add('  }');
  FPyScript.Add('  return keys');

  if (ACommand = CS_GET_TOKEN) or (ACommand = CS_GET_DEVICE_LIST) then
    FPyScript.Add(Format('retvar.Value = %s(tapoEmail, tapoPassword)', [ACommand]))
  else
    FPyScript.Add(Format('retvar.Value = %s(device)', [ACommand]));

  FPyScript.Add('print(retvar.Value)');
end;

end.
