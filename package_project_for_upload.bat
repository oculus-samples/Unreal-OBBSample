@echo off
REM ===============================================================
REM Copyright (c) Meta Platforms, Inc. and affiliates.
REM All rights reserved.
REM
REM This source code is licensed under the MIT license found in the
REM LICENSE file in the root directory of this source tree.
REM ===============================================================

REM ===================================================================
REM Automated Version Increment and Project Packaging Script
REM
REM This batch file automates two key processes for project shipping:
REM   1. Automatically increments the StoreVersion in DefaultEngine.ini
REM   2. Packages the project for distribution using Unreal's BuildCookRun
REM
REM The script handles version tracking to ensure each build has a unique
REM version number, which is important for proper deployment and updates.
REM ===================================================================


call "%~dp0config.bat" || (
    EXIT /B 1
)

if exist "%MY_SHIPPING_DIR%\" (
    rmdir /s /q "%MY_SHIPPING_DIR%" || (
        echo "failed to remove existing %MY_SHIPPING_DIR% directory and any potential existing builds, aborting."
        EXIT /B 1
    )
)
mkdir "%MY_SHIPPING_DIR%" || (
    echo "failed to create %MY_SHIPPING_DIR% directory, aborting."
    EXIT /B 1
)

powershell .\scripts\IncrementAndroidStoreVersion.ps1 "%DEFAULT_ENGINE_INI_FILE%" || (
    echo Failed to increment version.
    EXIT /B 1
)

for /F "delims=" %%A in ('echo prompt $E^| cmd') do set "ESC=%%A"
echo %ESC%[33m!!!! WARNING: the first time this runs it can potentially take a while building on a single machine. you may see warnings about workers waiting for results, please be patient !!!!%ESC%[0m

"%RUNAUT_BAT%" BuildCookRun ^
    -project="%~dp0OBBSample.uproject" ^
    -platform=Android ^
    -cookflavor=ASTC ^
    -clientconfig=Shipping ^
    -serverconfig=Shipping ^
    -cook ^
    -allmaps ^
    -build ^
    -stage ^
    -pak ^
    -package ^
    -archive ^
    -archivedirectory="%MY_SHIPPING_DIR%" ^
    -distribution
