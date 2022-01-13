program LicenseHeaderFix;

{$APPTYPE CONSOLE}

uses
  System.Types,
  System.IOUtils,
  System.Classes,
  System.SysUtils,
  System.RegularExpressions;

procedure ApplyFix(
  const ASearchPath: string;
  const AHeaderFileName: string
);
var
  I: Integer;
  VCount: Integer;
  VList: TStringDynArray;
  VText: string;
  VBytes: TBytes;
  VHeader: string;
  VRegEx: TRegEx;
  VMatch: TMatch;
begin
  VHeader := TFile.ReadAllText(AHeaderFileName) + #13#10;

  VRegEx := TRegEx.Create(
    '^unit (.*?);',
    [roIgnoreCase, roMultiLine, roCompiled, roNotEmpty]
  );

  VList := TDirectory.GetFiles(
    ASearchPath,
    '*.pas',
    TSearchOption.soAllDirectories
  );

  VCount := 0;
  for I := 0 to Length(VList) - 1 do begin
    VText := TFile.ReadAllText(VList[I]);
    VMatch := VRegEx.Match(VText);
    if VMatch.Success then begin
      VText := VHeader + Copy(VText, Pos(VMatch.Value, VText));

      VBytes := TEncoding.ANSI.GetBytes(AnsiString(VText)); // !

      TFile.WriteAllBytes(VList[I], VBytes);
      Inc(VCount);
    end else begin
      WriteLn('Match failed: ', VList[I]);
    end;
  end;

  Writeln('Processed: ', VCount, '/', Length(VList));
end;

type
  TAppConfig = record
    HeaderFileName: string;
    SearchPath: array of string;
  end;

function DoReadConfig(out AConfig: TAppConfig): Boolean;
var
  I: Integer;
begin
  Result := False;

  if ParamCount < 2 then begin
    Writeln('Not enough parameters!');
    Exit;
  end;

  AConfig.HeaderFileName := ParamStr(1);
  if not FileExists(AConfig.HeaderFileName) then begin
    Writeln('Header file does not exist: ', AConfig.HeaderFileName);
    Exit;
  end;

  SetLength(AConfig.SearchPath, ParamCount - 1);

  for I := 0 to Length(AConfig.SearchPath) - 1 do begin
    AConfig.SearchPath[I] := ParamStr(I + 1 + 1);
    if not DirectoryExists(AConfig.SearchPath[I]) then begin
      Writeln('Search path does not exist: ', AConfig.SearchPath[I]);
      Exit;
    end;
  end;

  Result := True;
end;

var
  I: Integer;
  VConfig: TAppConfig;
begin
  try
    if DoReadConfig(VConfig) then begin
      Writeln('Using header from file: ', VConfig.HeaderFileName);

      for I := 0 to Length(VConfig.SearchPath) - 1 do begin
        Writeln('Processing path: ', VConfig.SearchPath[I]);
        ApplyFix(VConfig.SearchPath[I], VConfig.HeaderFileName);
      end;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  Writeln('Press Enter to exit...');
  ReadLn;
end.
