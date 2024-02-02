unit uApi;

interface

uses
  System.SysUtils, System.Classes, JSON, IdHTTP, IdSSLOpenSSL;

type
  TApiServer = class
  private
    FIdHTTP: TIdHTTP;
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FToken: String;
    FSocketError: Boolean;
    FJsonLog: String;

    FjObj: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;

    function SetHttpSet: Boolean;

    function GetOauth2(var AToken: AnsiString; AApiUrl, AUserId, AUserPw: String): String;
    function GetTokenChk(AApiUrl, AUserId, AUserPw, AADToken: String): String;
    function GetStoreInfo(var AStoreNm: String; var AStartTime: String; var AEndTime: String; var AUseRewardYn: String; var AServerTime: String; AApiUrl: String; AADToken: String; AStoreCode: String): String;
    function GetTeeBoxVersion(var AVersion: String; AApiUrl: String; AADToken: String; AStoreCode: String): String; //타석기 정보 버전 조회
    function GetTeeBoxList(var AJsonArray: TJsonArray; AApiUrl: String; AADToken: String; AStoreCode: String): String; //타석기 정보 목록 조회
    function GetTeeBoxStatus(var AJsonArray: TJsonArray; AApiUrl: String; AADToken: String; AStoreCode: String): String;

    function SetTeeBoxStatus(var AJsonArray: TJsonArray; ASeatInfoStr: AnsiString; AApiUrl: String; AADToken: String): String; //타석기 가동 상황 전송

    property IdHTTP: TIdHTTP read FIdHTTP write FIdHTTP;
    property SocketError: Boolean read FSocketError write FSocketError;
  end;

implementation

uses
  EncdDecd, IdURI,
  uFunction, uStruct, uGlobal;

{ TApiServer }

constructor TApiServer.Create;
begin
  FIdHTTP := TIdHTTP.Create(nil);
  FSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

  FSSL.SSLOptions.Method := sslvSSLv23;
  FSSL.SSLOptions.Mode := sslmClient;
  FIdHTTP.IOHandler := FSSL;

  FSocketError := False;
end;

destructor TApiServer.Destroy;
begin
  FSSL.Free;
  FIdHTTP.Free;
  inherited;
end;

function TApiServer.SetHttpSet: Boolean;
begin
  FIdHTTP.Disconnect;
  FIdHTTP.Free;
  FSSL.Free;

  FIdHTTP := TIdHTTP.Create(nil);
  FSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

  FSSL.SSLOptions.Method := sslvSSLv23;
  FSSL.SSLOptions.Mode := sslmClient;
  FIdHTTP.IOHandler := FSSL;

  FSocketError := False;
end;

function TApiServer.GetOauth2(var AToken: AnsiString; AApiUrl, AUserId, AUserPw: String): String;
var
  ssData: TStringStream;
  ssTemp: TStringStream;
  jObj: TJSONObject;
  arrjObj: TJSONArray;
  jValue: TJSONValue;
  sAuthorization: AnsiString;
  sOauthUtf8: UTF8String;
begin
  Result := 'Fail';
  try
    try

      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      sOauthUtf8 := UTF8String(AUserId + ':' + AUserPw);
      //VDI5NDMwMDAwMTpjMGZkMWM1Ni0xZGY3LWE4ZmItZWJjZC0wZjQwYjEyODEzYzE=
      sAuthorization := EncdDecd.EncodeBase64(PAnsiChar(sOauthUtf8), Length(sOauthUtf8));

      FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Basic ' + sAuthorization;

      ssData.WriteString(TIdURI.ParamsEncode('grant_type=client_credentials'));
      FIdHTTP.Post(AApiUrl + '/oauth/token', ssData, ssTemp);

      jObj := TJSONObject.ParseJSONValue( ssTemp.DataString ) as TJSONObject;
      jValue := jObj.GetValue('access_token');
      AToken := jValue.Value; //'cc381b29-e731-4397-8b3e-74beee1211db'
      Result := 'Success';
    except
      //401 Unauthorized, 403 Forbidden, 404 Not Found,  505 HTTP Version Not
      on e: Exception do
      begin
        Result := 'GetOauth2 Exception : ' + e.Message;
      end;
    end
  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    FreeAndNil(jObj);
  end;

end;

function TApiServer.GetTokenChk(AApiUrl, AUserId, AUserPw, AADToken: String): String;
var
  ssData: TStringStream;
  ssTemp: TStringStream;
  jObj: TJSONObject;
  arrjObj: TJSONArray;
  jValue: TJSONValue;
  sAuthorization: AnsiString;
  sOauthUtf8: UTF8String;
  sStr: AnsiString;
begin
  Result := 'Fail';
  try
    try

      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      sOauthUtf8 := UTF8String(AUserId + ':' + AUserPw);
      sAuthorization := EncdDecd.EncodeBase64(PAnsiChar(sOauthUtf8), Length(sOauthUtf8));

      FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Basic ' + sAuthorization;

      ssData.WriteString(TIdURI.ParamsEncode('token=' + AADToken));
      FIdHTTP.Post(AApiUrl + '/oauth/check_token', ssData, ssTemp);

      jObj := TJSONObject.ParseJSONValue( ssTemp.DataString ) as TJSONObject;
      jValue := jObj.GetValue('client_id');
      Result := 'Success';
    except
      on e: Exception do
      begin
        Result := 'GetTokenChk Exception : ' + e.Message;
      end;
    end
  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    FreeAndNil(jObj);
  end;

end;

function TApiServer.GetStoreInfo(var AStoreNm: String; var AStartTime: String; var AEndTime: String; var AUseRewardYn: String; var AServerTime: String; AApiUrl: String; AADToken: String; AStoreCode: String): String;
var
  ssData: TStringStream;
  sUrl: String;
  jObj, jSubObj: TJSONObject;
  sResultCd, sResultMsg: String;
  sRecvData: AnsiString;
begin

  try
    try
      Result := 'Fail';

      ssData := TStringStream.Create('');

      FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      sUrl := AApiUrl + '/wix/api/K203_StoreInfo?store_cd=' + AStoreCode;
      FIdHTTP.Get(sUrl, ssData);

      sRecvData := TEncoding.UTF8.GetString(ssData.Bytes, 0, ssData.Size);

      jObj := TJSONObject.ParseJSONValue( sRecvData ) as TJSONObject;
      sResultCd := jObj.GetValue('result_cd').Value;
      sResultMsg := jObj.GetValue('result_msg').Value;
      if sResultMsg = 'Success' then
      begin
        jSubObj := jObj.GetValue('result_data') as TJSONObject;

        AStoreNm := jSubObj.GetValue('store_nm').Value;
        AStartTime := jSubObj.GetValue('start_time').Value;
        AEndTime := jSubObj.GetValue('end_time').Value;
        AUseRewardYn := jSubObj.GetValue('use_reward_yn').Value;
        AServerTime := jSubObj.GetValue('server_time').Value;

        Result := 'Success';
      end;
    except
      on e: Exception do
      begin
        Result := 'GetStoreInfo Exception : ' + e.Message;
      end;
    end;

  finally
    FreeAndNil(ssData);
    FreeAndNil(jObj);
  end;

end;

function TApiServer.GetTeeBoxVersion(var AVersion: String; AApiUrl: String; AADToken: String; AStoreCode: String): String;
var
  ssData: TStringStream;
  sUrl: String;
  jObj, jSubObj: TJSONObject;
  sResultCd, sResultMsg: String;
begin

  try
    try
      Result := 'Fail';

      ssData := TStringStream.Create('');

      FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      sUrl := AApiUrl + '/wix/api/K203_TeeBoxVersion?store_cd=' + AStoreCode;
      FIdHTTP.Get(sUrl, ssData);

      jObj := TJSONObject.ParseJSONValue( ssData.DataString ) as TJSONObject;
      sResultCd := jObj.GetValue('result_cd').Value;
      sResultMsg := jObj.GetValue('result_msg').Value;
      if sResultMsg = 'Success' then
      begin
        jSubObj := jObj.GetValue('result_data') as TJSONObject;
        AVersion := jSubObj.GetValue('version_no').Value;

        Result := 'Success';
      end;
    except
      on e: Exception do
      begin
        Result := 'GetTeeBoxVersion Exception : ' + e.Message;
      end;
    end;

  finally
    FreeAndNil(ssData);
  end;

end;

function TApiServer.GetTeeBoxList(var AJsonArray: TJsonArray; AApiUrl: String; AADToken: String; AStoreCode: String): String;
var
  ssData: TStringStream;
  sUrl: String;
  //jObj, jSubObj: TJSONObject;
  jObjArr: TJsonArray;
  sResultCd, sResultMsg: String;
  sRecvData: AnsiString;
begin

  try
    try
      Result := 'Fail';
      ssData := TStringStream.Create('');

      FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      sUrl := AApiUrl + '/wix/api/K204_TeeBoxlist?store_cd=' + AStoreCode;
      FIdHTTP.Get(sUrl, ssData);

      sRecvData := TEncoding.UTF8.GetString(ssData.Bytes, 0, ssData.Size);

      FreeAndNil(FjObj);
      FjObj := TJSONObject.ParseJSONValue(sRecvData) as TJSONObject;
      sResultCd := FjObj.GetValue('result_cd').Value;
      sResultMsg := FjObj.GetValue('result_msg').Value;

      if sResultMsg = 'Success' then
      begin
        AJsonArray := FjObj.GetValue('result_data') as TJsonArray;
        Result := 'Success';
      end;
    except
      on e: Exception do
      begin
        Result := 'GetTeeBoxList Exception : ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
  end;

end;

function TApiServer.SetTeeBoxStatus(var AJsonArray: TJsonArray; ASeatInfoStr: AnsiString; AApiUrl: String; AADToken: String): String;
var
  ssData, ssTemp: TStringStream;
  //jObj: TJSONObject;
  sResultCd, sResultMsg: String;
  sUrl: String;
  SeatInfo: TSeatInfo;
  I: Integer;
  sLog: String;
begin
  try
    try
      Result := 'Fail';
      sLog := '0';
      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      sLog := '1';
      ssData.WriteString(ASeatInfoStr);
      sLog := '1-1';
      FIdHTTP.Request.ContentType := 'application/json';
      FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      sUrl := AApiUrl + '/wix/api/K401_TeeBoxStatus';
      sLog := '1-2';
      FIdHTTP.Post(sUrl, ssData, ssTemp);

      sLog := '2';
      FreeAndNil(FjObj);
      FjObj := TJSONObject.ParseJSONValue( ssTemp.DataString ) as TJSONObject;
      sResultCd := FjObj.GetValue('result_cd').Value;
      sResultMsg := FjObj.GetValue('result_msg').Value;

      //log
     { if FJsonLog <> ssTemp.DataString then
      begin
        Global.LogJsonWrite(ASeatInfoStr);
        Global.LogJsonWrite(ssTemp.DataString + #13);
        FJsonLog := ssTemp.DataString;
      end;
      }
      Global.DebugLogWrite(ssTemp.DataString + #13);
      sLog := '3';
      if sResultMsg = 'Success' then
      begin
        AJsonArray := FjObj.GetValue('result_data') as TJsonArray;
        Result := 'Success';
      end;
    except
      on e: Exception do
      begin
        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
          FSocketError := True;

        Result := 'SetTeeBoxStatus Exception : ' + sLog + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
  end;
end;

function TApiServer.GetTeeBoxStatus(var AJsonArray: TJsonArray; AApiUrl: String; AADToken: String; AStoreCode: String): String;
var
  ssData: TStringStream;
  sUrl: String;
  //jObj: TJSONObject;
  jObjArr: TJsonArray;
  sResultCd, sResultMsg: String;
  sRecvData: AnsiString;
begin
  try
    try
      Result := 'Fail';
      ssData := TStringStream.Create('');

      FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      sUrl := AApiUrl + '/wix/api/K402_TeeBoxStatus?store_cd=' + AStoreCode;
      FIdHTTP.Get(sUrl, ssData);

      sRecvData := TEncoding.UTF8.GetString(ssData.Bytes, 0, ssData.Size);

      FreeAndNil(FjObj);
      FjObj := TJSONObject.ParseJSONValue( sRecvData ) as TJSONObject;
      sResultCd := FjObj.GetValue('result_cd').Value;
      sResultMsg := FjObj.GetValue('result_msg').Value;

      if sResultMsg = 'Success' then
      begin
        AJsonArray := FjObj.GetValue('result_data') as TJsonArray;
        Result := 'Success';
      end;
    except
      on e: Exception do
      begin
        Result := 'GetTeeBoxStatus Exception! : ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
  end;
end;

end.

