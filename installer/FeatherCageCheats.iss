; FeatherCage Cheats - installer script (Inno Setup 6)
; Build:  installer\build.ps1   (or ISCC.exe FeatherCageCheats.iss)
;
; Installs into the game root:
;   <Game>\HNRenovated\Binaries\Win64\dwmapi.dll        (UE4SS proxy)
;   <Game>\HNRenovated\Binaries\Win64\ue4ss\*           (UE4SS v4.0.0)
;   <Game>\HNRenovated\Binaries\Win64\ue4ss\Mods\FeatherCageCheats\*
; and enables the mod in ue4ss\Mods\mods.txt

#define AppName "FeatherCage Cheats"
#define AppVersion "1.0.0"
#define AppPublisher "gemerte"
#define AppURL "https://github.com/gemerte/HNRenovated-all-possibilities"
#define ModName "FeatherCageCheats"

[Setup]
AppId={{A7E1C2F4-9B3D-4C58-8F1A-2D6B7E0C4A93}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
DefaultDirName={code:GetDefaultGameDir}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
DisableReadyPage=no
OutputDir=dist
OutputBaseFilename=FeatherCageCheats-Setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\HNRenovated\Binaries\Win64\HNRenovated-Win64-Shipping.exe
VersionInfoVersion=1.0.0.0
VersionInfoDescription={#AppName} installer
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}
MinVersion=10.0

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
; UE4SS proxy DLL
Source: "..\vendor\UE4SS_v4.0.0\dwmapi.dll"; DestDir: "{app}\HNRenovated\Binaries\Win64"; Flags: ignoreversion

; UE4SS core (user config and mods.txt are handled separately so they are never clobbered)
Source: "..\vendor\UE4SS_v4.0.0\ue4ss\*"; DestDir: "{app}\HNRenovated\Binaries\Win64\ue4ss"; \
    Excludes: "UE4SS-settings.ini,Mods\mods.txt"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\vendor\UE4SS_v4.0.0\ue4ss\UE4SS-settings.ini"; DestDir: "{app}\HNRenovated\Binaries\Win64\ue4ss"; \
    Flags: onlyifdoesntexist uninsneveruninstall
Source: "..\vendor\UE4SS_v4.0.0\ue4ss\Mods\mods.txt"; DestDir: "{app}\HNRenovated\Binaries\Win64\ue4ss\Mods"; \
    Flags: onlyifdoesntexist uninsneveruninstall

; The mod itself
Source: "..\mod\FeatherCageCheats\*"; DestDir: "{app}\HNRenovated\Binaries\Win64\ue4ss\Mods\{#ModName}"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

[INI]
; console + GUI console are handy for a cheat mod
Filename: "{app}\HNRenovated\Binaries\Win64\ue4ss\UE4SS-settings.ini"; Section: "Debug"; Key: "ConsoleEnabled"; String: "1"
Filename: "{app}\HNRenovated\Binaries\Win64\ue4ss\UE4SS-settings.ini"; Section: "Debug"; Key: "GuiConsoleEnabled"; String: "1"
Filename: "{app}\HNRenovated\Binaries\Win64\ue4ss\UE4SS-settings.ini"; Section: "Debug"; Key: "GuiConsoleVisible"; String: "1"

[Run]
Filename: "{app}\HNRenovated\Binaries\Win64\HNRenovated-Win64-Shipping.exe"; Description: "Launch the game"; \
    Flags: nowait postinstall skipifsilent

[Code]
const
  GameExe = '\HNRenovated\Binaries\Win64\HNRenovated-Win64-Shipping.exe';

function DetectGameDir: string;
var
  Candidates: array of string;
  Home: string;
  I: Integer;
begin
  Home := GetEnv('USERPROFILE');
  SetArrayLength(Candidates, 9);
  Candidates[0] := Home + '\Desktop\Project FeatherCage';
  Candidates[1] := Home + '\Downloads\Project FeatherCage';
  Candidates[2] := Home + '\Desktop\FeatherCage';
  Candidates[3] := Home + '\Downloads\FeatherCage';
  Candidates[4] := 'C:\Project FeatherCage';
  Candidates[5] := 'D:\Project FeatherCage';
  Candidates[6] := 'C:\Games\Project FeatherCage';
  Candidates[7] := 'D:\Games\Project FeatherCage';
  Candidates[8] := 'C:\Program Files\Project FeatherCage';
  Result := '';
  for I := 0 to GetArrayLength(Candidates) - 1 do
    if FileExists(Candidates[I] + GameExe) then
    begin
      Result := Candidates[I];
      Exit;
    end;
end;

function GetDefaultGameDir(Param: string): string;
begin
  Result := DetectGameDir;
  if Result = '' then
    Result := ExpandConstant('{userdocs}\..\Desktop\Project FeatherCage');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectDir) and (not FileExists(WizardDirValue + GameExe)) then
  begin
    if MsgBox('The game executable was not found in:' + #13#10 + WizardDirValue + #13#10 + #13#10 +
              'Expected: HNRenovated\Binaries\Win64\HNRenovated-Win64-Shipping.exe' + #13#10 + #13#10 +
              'Select the game root folder (the one containing "HNRenovated").' + #13#10 +
              'Continue anyway?', mbError, MB_YESNO) = IDNO then
      Result := False;
  end;
end;

procedure AddModToModsTxt;
var
  ModsFile: string;
  Lines: TArrayOfString;
  I, Count, InsertAt: Integer;
begin
  ModsFile := ExpandConstant('{app}\HNRenovated\Binaries\Win64\ue4ss\Mods\mods.txt');
  if not FileExists(ModsFile) then
  begin
    SetArrayLength(Lines, 1);
    Lines[0] := '{#ModName} : 1';
    SaveStringsToFile(ModsFile, Lines, False);
    Exit;
  end;
  if not LoadStringsFromFile(ModsFile, Lines) then
    Exit;
  Count := GetArrayLength(Lines);
  for I := 0 to Count - 1 do
    if Pos('{#ModName}', Lines[I]) = 1 then
      Exit; // already enabled

  // keep "Keybinds : 1" (built-in, must stay last) below our entry
  InsertAt := Count;
  for I := 0 to Count - 1 do
    if Pos('Keybinds', Lines[I]) = 1 then
    begin
      InsertAt := I;
      Break;
    end;

  SetArrayLength(Lines, Count + 1);
  for I := Count downto InsertAt + 1 do
    Lines[I] := Lines[I - 1];
  Lines[InsertAt] := '{#ModName} : 1';
  SaveStringsToFile(ModsFile, Lines, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    AddModToModsTxt;
end;
