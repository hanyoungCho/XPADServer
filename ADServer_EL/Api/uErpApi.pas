unit uErpApi;

interface

uses
  System.SysUtils, System.Classes, JSON, IdHTTP, IdSSL, IdGlobal, IdSSLOpenSSL, IdSSLOpenSSLHeaders, IdTCPClient;

type
  TApiServer = class
  private
    FSSL: TIdSSLIOHandlerSocketOpenSSL;

  public
    constructor Create;
    destructor Destroy; override;

    function GetErpApi(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String): String;
    function PostErpApi(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String): String;

    function PostBeamApi(AType: String; ACtrl: String): String;

    //XGM
    function PostVXApi(AUrl: String; ACtrl: String): String;
    function PostPlugApi(AUrl, AJson: String): String;
    function GetPlugApi: String;

    //Agnet
    function SendAgentApi(AIP, AJsonText: string): string;

    function PostBeamHitachiApi(AIP: String; AType: Integer): String;
    function PostBeamPJLinkApi(AIP, APW: String; AType: Integer): Boolean;
  end;

implementation

uses
  EncdDecd, IdURI,
  uFunction, uStruct, uGlobal;

{ TApiServer }

constructor TApiServer.Create;
begin
  FSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

  FSSL.SSLOptions.Method := sslvSSLv23;
  FSSL.SSLOptions.Mode := sslmClient;
end;

destructor TApiServer.Destroy;
begin
  FSSL.Free;

  inherited;
end;

function TApiServer.GetErpApi(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String): String;
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

      if Global.ADConfig.StoreCode = 'E0001' then //이룸골프 잠실점
        Request.CustomHeaders.Values['x-api-key'] := '4c4c8gsw0wss44w4kos8gk4wswoo40wko0oogw08'
      else if Global.ADConfig.StoreCode = 'E0008' then //이룸골프 동탄라크몽
        Request.CustomHeaders.Values['x-api-key'] := 'gwg8o8c48kccsw0w0ksoks0go8gcgogssgo04ccs'
      else if Global.ADConfig.StoreCode = 'E0009' then //강남
        Request.CustomHeaders.Values['x-api-key'] := 'ok480gwokokgw4co0gcocwgkooswkgg8gwgcwokg'
      else if Global.ADConfig.StoreCode = 'E0011' then //구리갈매센터
        Request.CustomHeaders.Values['x-api-key'] := 'k0cgkgcsw4848ocscoso4okc0404owog0wo484w8'
      else
        Request.CustomHeaders.Values['x-api-key'] := 'owgss0w4008wk0cgks8cog00kok0k0kw40sk4kck';

      Request.ContentType := 'application/json';

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      sUrl := AApiUrl + AErpApi + AJsonStr;
      Get(sUrl, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        Result := 'Exception : ' + AErpApi + ' / ' + e.Message;
      end;
    end

  finally
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;
end;


function TApiServer.PostErpApi(AJsonStr: AnsiString; AErpApi: String; AApiUrl: String): String;
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

      if Global.ADConfig.StoreCode = 'E0001' then //이룸골프 잠실점
        Request.CustomHeaders.Values['x-api-key'] := '4c4c8gsw0wss44w4kos8gk4wswoo40wko0oogw08'
      else if Global.ADConfig.StoreCode = 'E0008' then //이룸골프 동탄라크몽
        Request.CustomHeaders.Values['x-api-key'] := 'gwg8o8c48kccsw0w0ksoks0go8gcgogssgo04ccs'
      else if Global.ADConfig.StoreCode = 'E0009' then //강남
        Request.CustomHeaders.Values['x-api-key'] := 'ok480gwokokgw4co0gcocwgkooswkgg8gwgcwokg'
      else if Global.ADConfig.StoreCode = 'E0011' then //구리갈매센터
        Request.CustomHeaders.Values['x-api-key'] := 'k0cgkgcsw4848ocscoso4okc0404owog0wo484w8'
      else
        Request.CustomHeaders.Values['x-api-key'] := 'owgss0w4008wk0cgks8cog00kok0k0kw40sk4kck';
      Request.ContentType := 'application/json';

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      ssData.WriteString(AJsonStr);
      sUrl := AApiUrl + AErpApi;
      Post(sUrl, ssData, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        Result := 'Exception : ' + AErpApi + ' / ' + e.Message;
      end;
    end;

  finally
    FreeAndNil(ssData);
    FreeAndNil(ssTemp);
    Disconnect;
    Free;
  end;
end;

function TApiServer.PostBeamApi(AType: String; ACtrl: String): String;
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

      //Request.ContentType := 'application/json';

      ConnectTimeout := 2000;
      ReadTimeout := 2000;

      if AType = '1' then //'Hitachi'
        sUrl := 'http://IP/cgi-bin/webctrl.cgi.elf?&p:1,c:4627,v:2,v:23'
      else //'Sony'
        sUrl := 'http://IP/cgi-bin/webctrl_user.cgi?&t:26,c:5,p:196614';

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

      ConnectTimeout := 3000; //10000;
      ReadTimeout := 3000; //10000;

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

function TApiServer.GetPlugApi: String;
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

      Request.ContentType := 'application/json';
      Request.Accept := '*/*';

      ConnectTimeout := 5000;
      ReadTimeout := 5000;

      sUrl := 'http://localhost:8000/plug/select/list';
      Get(sUrl, ssTemp);

      sRecvData := TEncoding.UTF8.GetString(ssTemp.Bytes, 0, ssTemp.Size);

      Result := sRecvData;
    except
      on e: Exception do
      begin
        Result := 'Exception : ' + sUrl + ' / ' + e.Message;
      end;
    end

  finally
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
