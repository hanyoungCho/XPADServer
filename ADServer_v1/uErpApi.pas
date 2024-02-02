unit uErpApi;

interface

uses
  System.SysUtils, System.Classes, JSON, IdHTTP, IdSSL, IdGlobal, IdSSLOpenSSL, IdSSLOpenSSLHeaders;

type
  TApiServer = class
  private
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FToken: String;
    FSocketError: Boolean;
    FJsonLog: String;

    FjObj: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;

    function GetOauth2(var AToken: AnsiString; AApiUrl, AUserId, AUserPw: String): String;
    function GetTokenChk(AApiUrl, AUserId, AUserPw, AADToken: String): String;

    function SetErpApiJsonData(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;
    function SetErpApiNoneData(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;
    function SetErpApiNoneDataEncoding(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;
    function GetErpApiNoneData(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;

    function SetErpApiK710TeeboxTime(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;

    //property IdHTTP: TIdHTTP read FIdHTTP write FIdHTTP;
    property SocketError: Boolean read FSocketError write FSocketError;
  end;

implementation

uses
  EncdDecd, IdURI,
  uFunction, uStruct, uGlobal;

{ TApiServer }

constructor TApiServer.Create;
begin
  //FIdHTTP := TIdHTTP.Create(nil);
  FSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

  FSSL.SSLOptions.Method := sslvSSLv23;
  FSSL.SSLOptions.Mode := sslmClient;
  //FIdHTTP.IOHandler := FSSL;

  FSocketError := False;
end;

destructor TApiServer.Destroy;
begin
  FSSL.Free;
  //FIdHTTP.Free;
  inherited;
end;

function TApiServer.GetOauth2(var AToken: AnsiString; AApiUrl, AUserId, AUserPw: String): String;
var
  ssData: TStringStream;
  ssTemp: TStringStream;
  jObj: TJSONObject;
  jValue: TJSONValue;
  sAuthorization: AnsiString;
  sOauthUtf8: UTF8String;
begin
  Result := 'Fail';

  with TIdHTTP.Create(nil) do
  try
    try
      IOHandler := FSSL;
      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      sOauthUtf8 := UTF8String(AUserId + ':' + AUserPw);
      //VDI5NDMwMDAwMTpjMGZkMWM1Ni0xZGY3LWE4ZmItZWJjZC0wZjQwYjEyODEzYzE=
      sAuthorization := EncdDecd.EncodeBase64(PAnsiChar(sOauthUtf8), Length(sOauthUtf8));

      //FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      //FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Basic ' + sAuthorization;
      Request.ContentType := 'application/x-www-form-urlencoded';
      Request.CustomHeaders.Values['Authorization'] := 'Basic ' + sAuthorization;

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      ssData.WriteString(TIdURI.ParamsEncode('grant_type=client_credentials'));
      //FIdHTTP.Post(AApiUrl + '/oauth/token', ssData, ssTemp);
      Post(AApiUrl + '/oauth/token', ssData, ssTemp);

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
    //FreeAndNil(jValue);
    Disconnect;
    Free;
  end;

end;

function TApiServer.GetTokenChk(AApiUrl, AUserId, AUserPw, AADToken: String): String;
var
  ssData: TStringStream;
  ssTemp: TStringStream;
  jObj: TJSONObject;
  //arrjObj: TJSONArray;
  jValue: TJSONValue;
  sAuthorization: AnsiString;
  sOauthUtf8: UTF8String;
  sStr: AnsiString;
begin
  Result := 'Fail';

  with TIdHTTP.Create(nil) do
  try
    try
      IOHandler := FSSL;
      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      sOauthUtf8 := UTF8String(AUserId + ':' + AUserPw);
      sAuthorization := EncdDecd.EncodeBase64(PAnsiChar(sOauthUtf8), Length(sOauthUtf8));

      //FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      //FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Basic ' + sAuthorization;
      Request.ContentType := 'application/x-www-form-urlencoded';
      Request.CustomHeaders.Values['Authorization'] := 'Basic ' + sAuthorization;

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      ssData.WriteString(TIdURI.ParamsEncode('token=' + AADToken));
      //FIdHTTP.Post(AApiUrl + '/oauth/check_token', ssData, ssTemp);
      Post(AApiUrl + '/oauth/check_token', ssData, ssTemp);

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
    //FreeAndNil(jValue);
    Disconnect;
    Free;
  end;

end;

function TApiServer.SetErpApiJsonData(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;
var
  ssData, ssTemp: TStringStream;
  sUrl: String;
  sRecvData: AnsiString;
begin
  with TIdHTTP.Create(nil) do
  try
    try
      Result := 'Fail';

      IOHandler := FSSL;

      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      ssData.WriteString(AJsonStr);
      //FIdHTTP.Request.ContentType := 'application/json';
      //FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      Request.ContentType := 'application/json';
      Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      sUrl := AApiUrl + '/wix/api/' + AErpApi;
      //FIdHTTP.Post(sUrl, ssData, ssTemp);
      Post(sUrl, ssData, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
          FSocketError := True;

        Result := 'Exception : ' + AErpApi + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;
end;

function TApiServer.SetErpApiNoneData(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;
var
  ssData, ssTemp: TStringStream;
  sUrl: String;
  sRecvData: AnsiString;
begin
  with TIdHTTP.Create(nil) do
  try
    try
      Result := 'Fail';
      IOHandler := FSSL;

      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      //FIdHTTP.Request.ContentType := 'application/json';
      //FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      ssData.WriteString(TIdURI.ParamsEncode('grant_type=client_credentials'));
      sUrl := AApiUrl + '/wix/api/' + AErpApi + AJsonStr;
      //FIdHTTP.Post(sUrl, ssData, ssTemp);
      Post(sUrl, ssData, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
          FSocketError := True;

        Result := 'Exception : ' + AErpApi + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;
end;

function TApiServer.SetErpApiNoneDataEncoding(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;
var
  ssData, ssTemp: TStringStream;
  sUrl: AnsiString;
  sRecvData: AnsiString;
begin
  with TIdHTTP.Create(nil) do
  try
    try
      Result := 'Fail';
      IOHandler := FSSL;

      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      ssData.WriteString(TIdURI.ParamsEncode('grant_type=client_credentials'));
      sUrl := TIdURI.URLEncode(AApiUrl + '/wix/api/' + AErpApi + AJsonStr);

      Post(sUrl, ssData, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
          FSocketError := True;

        Result := 'Exception : ' + AErpApi + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;
end;

function TApiServer.GetErpApiNoneData(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;
var
  ssTemp: TStringStream;
  sUrl: String;
  sRecvData: AnsiString;
begin
  with TIdHTTP.Create(nil) do
  try
    try
      Result := 'Fail';
      IOHandler := FSSL;

      ssTemp := TStringStream.Create('');

      //FIdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
      //FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      Request.ContentType := 'application/x-www-form-urlencoded';
      Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      sUrl := AApiUrl + '/wix/api/' + AErpApi + AJsonStr;
      //FIdHTTP.Get(sUrl, ssTemp);
      Get(sUrl, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
          FSocketError := True;

        Result := 'Exception : ' + AErpApi + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;
end;

function TApiServer.SetErpApiK710TeeboxTime(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String; AADToken: String): String;
var
  ssData, ssTemp: TStringStream;
  sUrl: String;
  sRecvData: AnsiString;
begin
  with TIdHTTP.Create(nil) do
  try
    try
      Result := 'Fail';
      IOHandler := FSSL;

      ssData := TStringStream.Create('');
      ssTemp := TStringStream.Create('');

      //FIdHTTP.Request.ContentType := 'application/json';
      //FIdHTTP.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;
      Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AADToken;

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      ssData.WriteString(TIdURI.ParamsEncode('grant_type=client_credentials'));
      sUrl := AApiUrl + '/wix/api/' + AErpApi + AJsonStr;

      //FIdHTTP.Post(sUrl, ssData, ssTemp);
      Post(sUrl, ssData, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
          FSocketError := True;

        Result := 'Exception : ' + AErpApi + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;
end;

end.
