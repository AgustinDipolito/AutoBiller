; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "biller"
#define MyAppVersion "1.0"
#define MyAppPublisher "Sunny Extreme Studio"
#define MyAppExeName "dist_v2.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{369ACB5A-34DF-4E9D-8AF3-CDEF02A5DBB3}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=C:\Users\agust\OneDrive - UNIVERSIDAD ABIERTA INTERAMERICANA\Desktop\flutter\dist_v2\installers
OutputBaseFilename=biller
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\agust\OneDrive - UNIVERSIDAD ABIERTA INTERAMERICANA\Desktop\flutter\dist_v2\build\windows\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\agust\OneDrive - UNIVERSIDAD ABIERTA INTERAMERICANA\Desktop\flutter\dist_v2\build\windows\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\agust\OneDrive - UNIVERSIDAD ABIERTA INTERAMERICANA\Desktop\flutter\dist_v2\build\windows\runner\Release\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\agust\OneDrive - UNIVERSIDAD ABIERTA INTERAMERICANA\Desktop\flutter\dist_v2\build\windows\runner\Release\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\agust\OneDrive - UNIVERSIDAD ABIERTA INTERAMERICANA\Desktop\flutter\dist_v2\build\windows\runner\Release\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\agust\OneDrive - UNIVERSIDAD ABIERTA INTERAMERICANA\Desktop\flutter\dist_v2\build\windows\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
