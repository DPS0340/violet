:: This source code is a part of Project Violet.
:: Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

:: copy build webview to assets subdirectory

rmdir ..\assets\webview /S /Q
mkdir ..\assets\webview

xcopy build ..\assets\webview /E