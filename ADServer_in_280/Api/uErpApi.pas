unit uErpApi;

interface

uses
  System.SysUtils, System.Classes, JSON, IdHTTP, IdSSL, IdGlobal, IdSSLOpenSSL, IdSSLOpenSSLHeaders, IdTCPClient;

const
  CN_WOL_PORT = 9;

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

    function PostVXApi(AUrl: String; ACtrl: String): String;
    function PostPlugApi(AUrl, AJson: String): String;

    function SendAgentApi(AIP, AJsonText: string): string;
    function WakeOnLan(const AMACAddress: string): string;

    function PostBeamHitachiApi(AIP: String; AType: Integer): String;
    function PostBeamPJLinkApi(AIP, APW: String; AType: Integer): Boolean;

    //property IdHTTP: TIdHTTP read FIdHTTP write FIdHTTP;
    property SocketError: Boolean read FSocketError write FSocketError;
  end;

implementation

uses
  EncdDecd, IdURI,
  uFunction, uStruct, uGlobal,
  IdUDPClient;

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

function TApiServer.PostVXApi(AUrl: String; ACtrl: String): String;
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

      Request.ContentType := 'application/json';
      Request.Accept := '*/*';

      ConnectTimeout := 5000;
      ReadTimeout := 5000;

      sUrl := AUrl;
      ssData.WriteString(ACtrl);
      Post(sUrl, ssData, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        Result := 'Exception : ' + sUrl + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;
end;

function TApiServer.PostPlugApi(AUrl, AJson: String): String;
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

      Request.ContentType := 'application/json';
      Request.Accept := '*/*';

      ConnectTimeout := 5000;
      ReadTimeout := 5000;

      //sUrl := 'http://localhost:8000/plug/on';
      //sUrl := 'http://localhost:8000/plug/off';
      sUrl := AUrl;

      ssData.WriteString(AJson);
      Post(sUrl, ssData, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        Result := 'Exception : ' + sUrl + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;

end;

function TApiServer.SendAgentApi(AIP, AJsonText: string): string;
var
  Indy: TIdTCPClient;
  sMsg: string;
begin
  try
    try
      Result := EmptyStr;
      Indy := TIdTCPClient.Create(nil);
      Indy.Host := AIP;
      Indy.Port := Global.ADConfig.AgentSendPort;
      Indy.ConnectTimeout := 5000;
      Indy.ReadTimeout := 5000;
      Indy.Connect;

      if Indy.Connected then
      begin
        Indy.IOHandler.Writeln(AJsonText, IndyTextEncoding_UTF8);
        Result := Indy.IOHandler.ReadLn(IndyTextEncoding_UTF8);
      end;
    except
      on E: Exception do
      begin
        Result := 'Exception : ' + AIP + ' / ' + e.Message;
      end;
    end;
  finally
    Indy.Disconnect;
    Indy.Free;
  end;
end;

function TApiServer.WakeOnLan(const AMACAddress: string): string;
var
  lBuffer: TIdBytes;
  sMACAddr: string;
  i, j: Byte;
begin
  Result := '';
  sMACAddr := StringReplace(StringReplace(UpperCase(AMacAddress), '-', '', [rfReplaceAll]), ':', '', [rfReplaceAll]);

  try
    SetLength(lbuffer, 117);
    for i := 1 to 6 do
      lBuffer[i] := StrToIntDef('$' + sMACAddr[(i * 2) - 1] + sMACAddr[i * 2], 0);

    lBuffer[7] := $00;
    lBuffer[8] := $74;
    lBuffer[9] := $FF;
    lBuffer[10] := $FF;
    lBuffer[11] := $FF;
    lBuffer[12] := $FF;
    lBuffer[13] := $FF;
    lBuffer[14] := $FF;

    for i := 1 to 16 do
      for j := 1 to 6 do
        lBuffer[15 + (i - 1) * 6 + (j - 1)] := lBuffer[j];

    lBuffer[116] := $00;
    lBuffer[115] := $40;
    lBuffer[114] := $90;
    lBuffer[113] := $90;
    lBuffer[112] := $00;
    lBuffer[111] := $40;

    with TIdUDPClient.Create(nil) do
    try
      BroadcastEnabled := True;
      Host := '255.255.255.255';
      Port := CN_WOL_PORT;
      SendBuffer(lBuffer);
    finally
      Free;
    end;
  except
    on E: Exception do
      Result := Format('Error: %s'+E.Message+', WakeUp: %s', [E.Message, sMACAddr]);
  end;
end;

function TApiServer.PostBeamHitachiApi(AIP: String; AType: Integer): String;
var
  lBuffer, Buf: TIdBytes;
  sSendData, strAnsi: AnsiString;
  i: integer;
begin
  SetLength(lbuffer, 13);

  lBuffer[0] := $BE;
  lBuffer[1] := $EF;
  lBuffer[2] := $03;
  lBuffer[3] := $06;
  lBuffer[4] := $00;
  if AType = 1 then
  begin
    lBuffer[5] := $BA;
    lBuffer[6] := $D2;
  end
  else
  begin
    lBuffer[5] := $2A;
    lBuffer[6] := $D3;
  end;

  lBuffer[7] := $01;
  lBuffer[8] := $00;
  lBuffer[9] := $00;
  lBuffer[10] := $60;

  if AType = 1 then
    lBuffer[11] := $01
  else
    lBuffer[11] := $00;

  lBuffer[12] := $00;

  //on
  //BE EF 03 06 00 BA D2 01  00 00 60 01 00 06

  //off
  //BE EF 03 06 00 2A D3 01  00 00 60 00 00 06

  with TIdTCPClient.Create(nil) do
  try
    Host := AIP;
    Port := 23;
    ConnectTimeout := 5000;
    ReadTimeout := 5000;
    Connect;

    if Connected then
    begin
      IOHandler.Write(lBuffer);

      sSendData := '';
      for i := 0 to Length(lBuffer) - 1 do
      begin
        if i > 0 then
          sSendData := sSendData + ' ';

        sSendData := sSendData + IntToHex(lBuffer[i]);
      end;
      Global.Log.LogCtrlWrite('w:' + sSendData);

      IOHandler.ReadBytes(Buf, 1, False);
      SetString(strAnsi, PAnsiChar(@Buf[0]), 1);
      Global.Log.LogCtrlWrite('R:' + IntToHex(Buf[0]));
    end;

  finally
    Disconnect;
    Free;
  end;

end;

function TApiServer.PostBeamPJLinkApi(AIP, APW: String; AType: Integer): Boolean;
var
  sRec, sType: AnsiString;
  sSendData: AnsiString;
  i: integer;

  iReadSize: integer;
  Buffer: TIdBytes;
  strAnsi: AnsiString;
  sToken: AnsiString;
  lBuffer: TIdBytes;
begin

  Result := False;

  with TIdTCPClient.Create(nil) do
  try
    Host := AIP;
    Port := 4352;
    ConnectTimeout := 2000;
    ReadTimeout := 2000;

    try
      Connect;
    except
      on E: exception do
      begin
        Global.Log.LogCtrlWrite('Connect exception:' + E.Message);
        Exit;
      end;
    end;

    while True do
    begin
      try
        IOHandler.CheckForDataOnSource(5);
      except
        Exit;
      end;

      iReadSize := IOHandler.InputBuffer.Size;
      if iReadSize > 0 then begin
         IOHandler.ReadBytes(Buffer, iReadSize, False);
         SetString(strAnsi, PAnsiChar(@Buffer[0]), iReadSize);
         Global.Log.LogCtrlWrite('R:' + strAnsi);

         sType := Copy(strAnsi, 1, 8);
         if sType = 'PJLINK 1' then
          sToken := Copy(strAnsi, 10, 8);

         Break;
      end;

      sleep(10);
    end;

    if Connected then
    begin
      try
        if sType = 'PJLINK 1' then
        begin
          //sRec := sToken + 'JBMIAProjectorLink';
          sRec := sToken + APW;
          sSendData := LowerCase(MD5Str(sRec)) + '%1POWR ';
          if AType = 0 then
            sSendData := sSendData + '0'
          else if AType = 1 then
            sSendData := sSendData + '1';

          IOHandler.WriteLn(sSendData);
          Global.Log.LogCtrlWrite('W:'+sSendData);
        end
        else
        begin

          //PJLINK 0
          //sSendData := '%1POWR ?$0D';
          //IOHandler.WriteLn(sSendData);

          SetLength(lbuffer, 9);

          lBuffer[0] := $25;
          lBuffer[1] := $31;
          lBuffer[2] := $50;
          lBuffer[3] := $4F;
          lBuffer[4] := $57;
          lBuffer[5] := $52;
          lBuffer[6] := $20;

          if AType = 0 then
            lBuffer[7] := $30
          else if AType = 1 then
            lBuffer[7] := $31;
          //else if Adata = '?' then
            //lBuffer[7] := $3F;
          lBuffer[8] := $0D;

          IOHandler.Write(lBuffer);
        end;

      except
        on E: exception do
        begin
          Global.Log.LogCtrlWrite('WriteLn exception:' + E.Message);
          Exit;
        end;
      end;

      while True do
      begin
        try
          IOHandler.CheckForDataOnSource(5);
        except
          Exit;
        end;

        iReadSize := IOHandler.InputBuffer.Size;
        if iReadSize > 0 then begin
           IOHandler.ReadBytes(Buffer, iReadSize, False);
           SetString(strAnsi, PAnsiChar(@Buffer[0]), iReadSize);
           Global.Log.LogCtrlWrite('R:'+strAnsi);

           //PJLINK 0 -> on 후 off 시 완료되기전?
           //R:%1POWR=ERR3

           {
           Successful execution            OK
           Undefined command              ERR1   정의되지 않은 명령
           Out of parameter               ERR2   매개변수 부족
           Unavailable time               ERR3   이용 불가 시간
           Projector/Display failure*     ERR4   프로젝터/디스플레이 오류*
           }

           Result := True;
           Break;
        end;
        sleep(10);
      end;

    end;

  finally
    Disconnect;
    Free;
    //mmTest.Lines.Add('Disconnect');
  end;
end;


end.
