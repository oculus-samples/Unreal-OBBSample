@echo off
REM ===============================================================
REM Copyright (c) Meta Platforms, Inc. and affiliates.
REM All rights reserved.
REM
REM This source code is licensed under the MIT license found in the
REM LICENSE file in the root directory of this source tree.
REM ===============================================================

REM ============================================================
REM This batch script configures the project environment and
REM performs several tasks necessary for building the project.
REM
REM Key tasks include:
REM - Generating a keystore for Android builds.
REM - Setting configuration values in DefaultEngine.ini.
REM - Running Unreal Editor commands to import generated BMPs.
REM
REM Note: This file involves Generating large BMP files totaling approximately 4GB
REM   in a temporary folder for testing purposes.
REM ============================================================


call "%~dp0config.bat" || (
    EXIT /B 1
)

if not exist "%KEYTOOL_PATH%" (
    echo "android's keytool.exe not found at %KEYTOOL_PATH%"
    EXIT /B 1
)

if not exist "Build\Android\" (
    mkdir "Build\Android"
)

if exist "Build\Android\ExampleKey.keystore" (
    del "Build\Android\ExampleKey.keystore"
)

"%KEYTOOL_PATH%" -genkey -v -keystore Build\Android\ExampleKey.keystore -alias %MY_KEYSTORE_ALIAS% -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=John Doe, OU=Engineering, O=MyCompany, L=MyCity, ST=MyState, C=US" -storepass %MY_KEYSTORE_PASSWORD% -keypass %MY_KEYSTORE_PASSWORD%

REM check if MY_PACKAGE_NAME is defined
if "%MY_PACKAGE_NAME%"=="" (
    echo "MY_PACKAGE_NAME is not defined"
    EXIT /B 1
)

if not exist "%DEFAULT_ENGINE_INI_FILE%" (
    echo Could not find DefaultEngine.ini.
    EXIT /B 1
)

powershell -File scripts\Set-IniVal.ps1 -IniKey PackageName -IniVal %MY_PACKAGE_NAME% -IniPath "%DEFAULT_ENGINE_INI_FILE%" || (
    echo "Failed to set PackageName in DefaultEngine.ini"
    EXIT /B 1
)
powershell -File scripts\Set-IniVal.ps1 -IniKey KeyAlias -IniVal %MY_KEYSTORE_ALIAS% -IniPath "%DEFAULT_ENGINE_INI_FILE%" || (
    echo "Failed to set KeyAlias in DefaultEngine.ini"
    EXIT /B 1
)
powershell -File scripts\Set-IniVal.ps1 -IniKey KeyStorePassword -IniVal %MY_KEYSTORE_PASSWORD% -IniPath "%DEFAULT_ENGINE_INI_FILE%" || (
    echo "Failed to set KeyStorePassword in DefaultEngine.ini"
    EXIT /B 1
)

if not exist "%UNREALEDITOR_CMD_EXE%" (
    echo "UnrealEditor-Cmd.exe not found at %UNREALEDITOR_CMD_EXE%"
    EXIT /B 1
)

@echo "building the big bmp files so we generate more than one obb"
mkdir tmp
for %%i in (bigfile, bigfile101, bigfile102, bigfile2, bigfile201, bigfile202) do (
    powershell -File scripts\GenBigBmp.ps1 -OutputPath tmp\%%i.bmp || (
        echo "Failed to generate big bmp file tmp\%%i.bmp"
        EXIT /B 1
    )
)

"%UNREALEDITOR_CMD_EXE%" "%~dp0OBBSample.uproject" -Run=pythonscript -script="%~dp0scripts\import_bmps.py" || (
    echo "Failed to import bmps"
    EXIT /B 1
)

rmdir /s /q tmp || (
    echo "Warning: Failed to delete tmp folder"
    EXIT /B 1
)

pause
