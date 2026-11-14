; FeatherCage Cheats - FULL installer (game + UE4SS + mod)
; Build:  installer\build_full.ps1
;
; Packs the whole game folder (as it is on this machine, already patched with
; UE4SS + the mod) into a single setup. Result: install -> play with cheats.
;
; NOTE: the resulting exe is ~0.8 GB. GitHub rejects files > 100 MB, so this
; installer is NOT stored in the repository - host it anywhere you like.

#ifndef GameDir
  #define GameDir "C:\Users\Dmitriy\Desktop\Project FeatherCage"
#endif

#define AppName "Project FeatherCage + Cheats"
#define AppVersion "1.0.0"
#define AppPublisher "gemerte"
#define AppURL "https://github.com/gemerte/HNRenovated-all-possibilities"

[Setup]
AppId={{C4D9A1E7-2B85-4F30-9A6C-7E1B3D8F5A24}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
DefaultDirName={autopf}\Project FeatherCage
DefaultGroupName=Project FeatherCage
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=FeatherCageCheats-Full-Setup-{#AppVersion}
Compression=lzma2/fast
SolidCompression=no
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\Project Feathercage.exe
VersionInfoVersion=1.0.0.0
VersionInfoDescription={#AppName} installer
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}
MinVersion=10.0
DiskSpanning=no

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: checkedonce

[Files]
; the game itself (UE4SS and the mod are already inside the folder)
Source: "{#GameDir}\*"; DestDir: "{app}"; Excludes: "*.log,ue4ss\UE4SS_ObjectDump.txt,ue4ss\Mods\FeatherCageCheats\commands.txt,actor_classes.txt,item_candidates.txt,world_actors.txt"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Project FeatherCage (with cheats)"; Filename: "{app}\Project Feathercage.exe"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Project FeatherCage (with cheats)"; Filename: "{app}\Project Feathercage.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Project Feathercage.exe"; Description: "Launch the game"; \
    Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  if not FileExists('{#GameDir}\HNRenovated\Binaries\Win64\HNRenovated-Win64-Shipping.exe') then
  begin
    MsgBox('Source game folder not found:' + #13#10 + '{#GameDir}' + #13#10 + #13#10 +
           'Rebuild with:  build_full.ps1 -GameDir "<path to Project FeatherCage>"',
           mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ModsFile: string;
  Lines: TArrayOfString;
  I: Integer;
begin
  if CurStep <> ssPostInstall then
    Exit;
  // make sure the mod is enabled even if the packed mods.txt was edited
  ModsFile := ExpandConstant('{app}\HNRenovated\Binaries\Win64\ue4ss\Mods\mods.txt');
  if not FileExists(ModsFile) then
    Exit;
  if not LoadStringsFromFile(ModsFile, Lines) then
    Exit;
  for I := 0 to GetArrayLength(Lines) - 1 do
    if Pos('FeatherCageCheats', Lines[I]) = 1 then
      Exit;
  SetArrayLength(Lines, GetArrayLength(Lines) + 1);
  Lines[GetArrayLength(Lines) - 1] := 'FeatherCageCheats : 1';
  SaveStringsToFile(ModsFile, Lines, False);
end;
