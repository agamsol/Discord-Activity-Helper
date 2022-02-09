@echo off
setlocal enabledelayedexpansion

set "yellow=[33m"
set "white=[37m"
set "grey=[90m"
set "brightred=[91m"
set "brightblue=[94m"
set "brightgreen=[92m"
set "green=[32m"
set "brightmagenta=[95m"

set "Project_Version=1.0"
set Project=Discord Activities Helper
set "config=%temp%\!Project!\config.yml"

: <Script Boot>
if not exist "!config!" (
    for /f "delims=" %%a in ("!config!") do (
        set "FilesPath=%%~dpa"
        if not exist "%%~dpa" md "%%~dpa"
    )
    call :LOGIN_TO_DISCORD
    call :CREATE_CONFIG
)

call :LOAD_CONFIG
: </Script Boot>

: <Check Login Status>
call :AUTHENTICATE_CONNECTION "!Token!"
: </Check Login Status>

: <Launch Activities Cycle>
if "%~1"=="--Activity-Socket" call :RECYCLE_ACTIVITIES --silent
if "%~1"=="--Activity-Socket" exit /b
start /b "cmd.exe" "%~f0" --Activity-Socket
: </Launch Activities Cycle>


:MAIN_MENU
title !Project! - Home Page
cls
echo:
echo -------------------------------------
echo:
echo  1. Set Status
echo:
echo  2. Set Status Activity
echo:
echo  3. Words to emojis
echo:
echo -------------------------------------
echo:

set /p "userinput=--> "
set int.1.userinput=
if !userinput! equ 1 (
    cls
    echo:
    echo   Set status for your account, options:
    echo      'idle', 'dnd', 'invisible', 'online'
    echo:
    set /p "int.1.userinput=--> "
    for %%a in (idle dnd invisible online) do (
        if /i "%%a"=="!int.1.userinput!" (
            call :SET_STATUS %%a
            echo:
            echo  Status has been successfully changed.
            timeout /t 4 /nobreak>nul
            goto :MAIN_MENU
        )
    )
)
if !userinput! equ 2 (
    :ACTIVITIES_MENU
    title !Project! - Activities Manager
    cls
    echo:
    echo  1 - Show Current Activities
    echo:
    echo  2 - Launch Activities [DEBUGGER]
    echo:
    echo  3 - Add activities
    echo:
    echo  Type 'BACK' for home menu.
    echo:
    set /p "int.2.userinput=--> "
    if !int.2.userinput! equ 1 (
        cls
        set Activities.length=0
        if /i "!Activities!"=="null" (
            echo:
            echo  ERROR: No Activities Found.
        ) else (
            for /f "tokens=1 delims==" %%a in ('set "Activity[" 1^>nul 2^>nul') do set %%a=
            for %%a in (!Activities!) do (
                set /a Activities.length+=1
                set "Activity[!Activities.length!]=%%a"
                for /f "tokens=2 delims=`" %%b in ("%%a") do (
                    echo !Activities.length!. %%~b
                )
            )
            if !Activities.length! equ 0 (
                echo:
                echo  ERROR: No Activities Found.
                timeout /t 4 /nobreak >nul
                goto :ACTIVITIES_MENU
            )
            echo:
            set /p "int.3.userinput=--> "
            for /f "delims=" %%a in ("!int.3.userinput!") do (
                if defined Activity[%%a] for /f "delims=" %%b in ("!Activity[%%a]!") do (
                    set Activities=!Activities:%%b=!
                    call :CREATE_CONFIG
                    call :LOAD_CONFIG
                )
            )
            goto :ACTIVITIES_MENU
        )
        timeout /t 4 /nobreak>nul
        goto :ACTIVITIES_MENU
    )
    if !int.2.userinput! equ 2 (
        call :RECYCLE_ACTIVITIES
        timeout /t 4 /nobreak>nul
        goto :ACTIVITIES_MENU
    )
    if !int.2.userinput! equ 3 (
        set NEW_ACTIVITY=
        set int.3.userinput=
        :BUILD_ACTIVITY
        cls
        echo:
        echo ---------------------------
        echo:
        echo    1. Add an Emoji
        if defined Emoji_Json echo     Current: !Emoji_Name!
        if "!Emoji_Invalid!"=="true" echo     Please Note: the emoji '!Emoji_Invalid_Name!' doesn't exist in the database.
        if defined NitroEmojiName echo     Current: !NitroEmojiName! - Nitro Emoji
        echo:
        echo    2. Set Activity Text
        if defined NEW_ACTIVITY echo     Current: !NEW_ACTIVITY!
        echo:
        echo    3. Save Activity
        echo:
        echo ---------------------------
        echo:
        set /p "int.3.userinput=--> "
        if !int.3.userinput! equ 1 (
            if defined premium_type (
                cls
                echo:
                echo  1. Add Default Emoji
                echo:
                echo  2. Add Nitro Emoji
                echo:
            ) else goto :SELECT_DEFAULT_EMOJI
            set /p "int.4.userinput=--> "
            if !int.4.userinput! equ 1 (
                :SELECT_DEFAULT_EMOJI
                for %%a in (Emoji_Json Emoji_Name NitroEmojiName NitroEmojiID Emoji_Invalid Emoji_Invalid_Name) do set %%a=
                cls
                echo:
                echo  Please provide your emoji
                echo:
                echo    Example: !brightblue!:!grey!smile!brightblue!:!white!
                echo:
                set /p "int.5.userinput=--> "
                for /f "tokens=1-2 delims=:" %%a in ("!int.5.userinput!") do (
                    call :CONVERT_EMOJI %%a
                    if not defined Emoji_Json (
                        set Emoji_Invalid=true
                        set Emoji_Invalid_Name=%%a
                    )
                )
                goto :BUILD_ACTIVITY
            )
            if !int.4.userinput! equ 2 (
                for %%a in (Emoji_Json Emoji_Name NitroEmojiName NitroEmojiID Emoji_Invalid Emoji_Invalid_Name) do set %%a=
                cls
                echo:
                echo  Please Provide your nitro emoji
                echo:
                echo     Example: ^<!brightblue!:!grey!troll!brightblue!:!grey!926959981419429968!white!^>
                echo:
                set /p "int.5.userinput=--> "
                for %%a in (">" "<") do set int.5.userinput=!int.5.userinput:%%~a=!
                for /f "tokens=1-2 delims=:" %%a in ("!int.5.userinput!") do (
                    set NitroEmojiName=%%a
                    set NitroEmojiID=%%b
                    if not defined NitroEmojiID set NitroEmojiName=
                )
                goto :BUILD_ACTIVITY
            )
        )
        if !int.3.userinput! equ 2 (
            echo:
            set /p "NEW_ACTIVITY=Type Your Activity: "
            goto :BUILD_ACTIVITY
        )
        if !int.3.userinput! equ 3 (
            if "!Activities!"=="null" set Activities=
            if defined Emoji_Json (
                set Emoji=!Emoji_Json!
                set EmojiID=null
            ) else (
                set Emoji=null
                set EmojiID=null
            )
            if defined NitroEmojiName if defined NitroEmojiID (
                set Emoji=!NitroEmojiName!
                set EmojiID=!NitroEmojiID!
            )
            if defined NEW_ACTIVITY (
                set ACTIVITY=!NEW_ACTIVITY!
            ) else set ACTIVITY=null
            set AtLeastOneProvided=0
            for %%a in (ACTIVITY Emoji) do if not "!%%a!"=="null" set /a AtLeastOneProvided+=1
            if !AtLeastOneProvided! geq 1 (
                set "Activities=!Activities! "!ACTIVITY!`!Emoji!`!EmojiID!""
            ) else goto :BUILD_ACTIVITY
            call :CREATE_CONFIG
            for %%a in (NEW_ACTIVITY Emoji_Invalid Emoji_Name Emoji_Json NitroEmojiName NitroEmojiID) do set %%a=
            echo:
            echo Changes Has been successfully saved.
            timeout /t 3 /nobreak>nul
            goto :ACTIVITIES_MENU
        )
        goto :ACTIVITIES_MENU
    )
    if /i "!int.2.userinput!"=="back" (
        goto :MAIN_MENU
    ) else (
        goto :ACTIVITIES_MENU
    )
)
if !userinput! equ 3 (
    set result=
    echo:
    echo  Provide text to convert . . .
    echo:
    set /p "int.1.userinput=--> "
    call :CONVERT_TEXT_TO_EMOJIS int.1.userinput
    echo !result! | clip
    echo:
    echo  Text has been copied to your clip-board
    timeout /t 4 /nobreak>nul
)
goto :MAIN_MENU


: <Collect & Save Discord Information>
:LOGIN_TO_DISCORD
title !Project! - Connect to discord account
cls
echo:
echo -------------------------------------------------------
echo:
echo     !grey!Welcome to !brightblue!!Project!!white!
echo:
echo         !grey!Please provide your discord !yellow!token!grey!.
echo:
echo -------------------------------------------------------!white!
set /p "Token=!brightmagenta!--> !grey!"
call :AUTHENTICATE_CONNECTION "!Token!"
exit /b
: </Collect & Save Discord Information>

: <Check Login Credentials>
:AUTHENTICATE_CONNECTION
if "%~1"=="null" goto :LOGIN_TO_DISCORD
curl -sX GET --header "authorization: %~1" "https://discord.com/api/v7/users/@me" -o "!FilesPath!AccountInfo.json"
for /f "delims=" %%a in ('type "!FilesPath!AccountInfo.json"') do (
    echo %%a | findstr /c:"401: Unauthorized">nul && (
        echo   !brightred!ERROR!white!: !grey!Invalid Account Token . . .
        set token=null
        call :CREATE_CONFIG
        timeout /t 4 /nobreak>nul
        goto :LOGIN_TO_DISCORD
    )
)
set "ParseFile=!FilesPath!AccountInfo.json"
call :PARSE_JSON premium_type

exit /b
: </Check Login Credentials>

: <Set Status>
:SET_STATUS <name>
curl --silent "https://canary.discord.com/api/v9/users/@me/settings" -X "PATCH" -H "content-type: application/json" -H "accept-language: en-US,en-IL;q=0.9,he;q=0.8" -H "authorization: !Token!" --data-raw "^{^\^"status^\^":^\^"%~1^\^"^}" -o /dev/null
exit /b
: <Set Status for account>

: <Set Activity>
:SET_ACTIVITY <activity> <emoji_name> <nitro emoji ID> [--silent]

set Build_Activity_Json[1]=
set Build_Activity_Json[2]=
set Build_Activity_Json[3]=
set ACTIVITY_TEXT=

set "ACTIVITY_TEXT=%~1"
if defined ACTIVITY_TEXT (
    if not "!ACTIVITY_TEXT!"=="null" (
        set "Build_Activity_Json[1]="text":"!ACTIVITY_TEXT!""
    )
)

if /i "%~3"=="null" (
    if not "%~2"=="null" (
        set "Build_Activity_Json[2]="emoji_name":"%~2""
    )
) else (
    set "Build_Activity_Json[2]="emoji_name":"%~2""
    set "Build_Activity_Json[2]="emoji_id":"%~3""
)

set "Build_Activity_Json={"custom_status":{!Build_Activity_Json[1]!!Build_Activity_Json[2]!!Build_Activity_Json[3]!}}"

set Build_Activity_Json=!Build_Activity_Json:""=","!

curl -s "https://canary.discord.com/api/v9/users/@me/settings" -X "PATCH" -H "content-type: application/json" -H "accept-language: en-US,en-IL;q=0.9,he;q=0.8" -H "authorization: !Token!" --data-raw "!Build_Activity_Json:"=\"!" -o /dev/null
if not "%~4"=="--silent" (
    echo:
    echo    !grey![!brightblue!ACTIVITY SOCKET!grey!] !white!Displaying Activity . . .
    if defined Build_Activity_Json[1] echo        !grey!- TEXT: '!brightblue!%~1!grey!'.!white!
    if defined Build_Activity_Json[2] echo        !grey!- EMOJI: !brightblue!:%~2:!white!
    if defined Build_Activity_Json[3] echo        !grey!- EMOJI: !brightblue!:%~2:!grey! - With ID: '!brightblue!%~3!grey!'.!white!
)
exit /b
: </Set Activity>

: <Emoji Converter>
:CONVERT_EMOJI <Emoji_Name>
set Emoji_Name=
set Emoji_Json=
for /f "tokens=1,2 delims=`" %%a in ('curl -s "https://raw.githubusercontent.com/agamsol/Discord-Activity-Helper/main/src/Default-Emojis.inf"') do (
    if /i "%%a"=="%~1" (
        set Emoji_Name=%%a
        set Emoji_Json=%%b
    )
)
exit /b
: </Emoji Converter>


: <Create Config>
:CREATE_CONFIG
>"!config!" (
    echo # DONT CHANGE THIS IF YOU DON'T KNOW WHAT YOU ARE DOING.
    echo Version: !Project_Version!
    echo:
    echo ########################################
    echo #                                      #
    echo #                CONFIG                #
    echo #                                      #
    echo ########################################
    echo:
    echo Token: !Token!
    echo:
    echo ########################################
    echo #                                      #
    echo #       ACTIVITY CYCLING SYSTEM        #
    echo #                                      #
    echo ########################################
    echo:
    if not defined Activities set Activities=null
    echo Activities: !Activities!
    if not defined Refresh set Refresh=5
    echo Refresh: !Refresh!
)
rem "My Status`NitroEmoji`ID" "My Status 2`NitroEmoji`ID"
exit /b
: </Create Config>

: <Load Config>
:LOAD_CONFIG
for /f "delims=" %%a in ('type "!config!"') do (
    set "current=%%a"
    for /F "delims=#`" %%. in ("!current:~0,1!") do (
        if not "!current:*: =!"=="!current!" (
            for /f "tokens=1 delims=:" %%b in ("%%a") do set "key=%%b"
            for %%c in ("!key!") do (
                set "!key!=!current:*: =!"
            )
        )
    )
)
exit /b
: </Load Config>

: <Json File Parser>
:PARSE_JSON [key1] [key2]
if exist "!ParseFile!" (
    for %%a in (%*) do set "ParseKeys=!ParseKeys!; $ValuePart = '%%~a=' + $Value.%%~a ; $ValuePart"
    for /f "delims=" %%a in ('powershell "$Value = (Get-Content '!ParseFile!' | Out-String | ConvertFrom-Json) !ParseKeys!"') do set %%a
) else echo ERROR: File not found.
set ParseFile=
set ParseKeys=
exit /b
: <Json File Parser>

: <Convert Text To Emojis>
:CONVERT_TEXT_TO_EMOJIS
set current=
set "source=!%~1!"
for %%a in ("a:regional_indicator_a" "b:regional_indicator_b" "c:regional_indicator_c" "d:regional_indicator_d" "e:regional_indicator_e" "f:regional_indicator_f" "g:regional_indicator_g" "h:regional_indicator_h" "i:regional_indicator_i" "j:regional_indicator_j" "k:regional_indicator_k" "l:regional_indicator_l" "m:regional_indicator_m" "n:regional_indicator_n" "o:regional_indicator_o" "p:regional_indicator_p" "q:regional_indicator_q" "r:regional_indicator_r" "s:regional_indicator_s" "t:regional_indicator_t" "u:regional_indicator_u" "v:regional_indicator_v" "w:regional_indicator_w" "x:regional_indicator_x" "y:regional_indicator_y" "z:regional_indicator_z" "1:one" "2:two" "3:three" "4:four" "5:five" "6:six" "7:seven" "8:eight" "9:nine" "0:zero" "#:hash" " :black_large_square") do (
    for /F "tokens=1,2 delims=:" %%b in ("%%~a") do (
        set "lookup[%%b]=%%c"
    )
)
:LOOP_STRING
if not defined source (
    endlocal
    set "result=%result%"
    exit /b
)
set "current=lookup[!source:~0,1!]"
if defined !current! (
    set "result=!result!:!%current%!: "
) else if "!source:~0,1!"=="^!" (
    set "result=!result!:exclamation: "
) else if "!source:~0,1!"=="?" (
    set "result=!result!:question: "
)
set "source=!source:~1!"
goto :LOOP_STRING
: </Convert Text To Emojis>


: <Activity Cycling System>
:RECYCLE_ACTIVITIES [--silent]
tasklist /fi "ImageName eq Activity-Socket" /fo csv 2>NUL | find /I "Activity-Socket">NUL
if !ERRORLEVEL! equ 0 (
    if not "%~4"=="--silent" (
        echo:
        echo Socket Already Running, Restarting . . .
    )
    TASKKILL /F /FI "WINDOWTITLE ne Activity-Socket"
    goto :RECYCLE_ACTIVITIES
)

title Activity-Socket
if exist "!config!" (
    call :LOAD_CONFIG
) else exit /b
if defined Activities (
    if "!Activities!"=="null" (
        if not "%~4"=="--silent" echo: Nothing to set as activity
        exit /b
    )
)
if defined Refresh (
    set NotNumber=
    for /f "delims=0123456789" %%a in ("!Refresh!") do set NotNumber=%%a
    if not defined NotNumber set Refresh=5
) else set Refresh=5

for %%a in (!Activities!) do (
    for /f "tokens=1,2,3 delims=`" %%b in ("%%~a") do (
        set "Build_Activity_Json[1]=%%b"
        set "Build_Activity_Json[2]=%%c"
        set "Build_Activity_Json[3]=%%d"

        for /L %%e in (1 1 3) do (
            if not defined Build_Activity_Json[%%e] set Build_Activity_Json[%%e]=null
        )

        call :SET_ACTIVITY "!Build_Activity_Json[1]!" "!Build_Activity_Json[2]!" "!Build_Activity_Json[3]!" %~1

        timeout /t !Refresh! /nobreak>nul
    )
)
timeout /t !Refresh! /nobreak>nul
goto :RECYCLE_ACTIVITIES
: </Activity Cycling System>