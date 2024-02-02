
{$IFDEF WIN32}
const DLLName = 'CkAPI32.dll';
{$ELSE}
  {$IFDEF WIN64}
  const DLLName = 'CkAPI64.dll';
  {$ELSE}
  const DLLName = 'CkAPI32.dll';  //Older versions of Delphi
  {$ENDIF}
{$ENDIF}

