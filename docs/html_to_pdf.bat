@echo off
REM Convert PROJECT_PROGRESS HTML to PDF using Edge
set HTML=%~dp0PROJECT_PROGRESS_Ahnaf_Tajwar_2207104.html
set PDF=%~dp0PROJECT_PROGRESS_Ahnaf_Tajwar_2207104.pdf
set EDGE=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe

for %%I in ("%HTML%") do set URI=file:///%%~fI
set URI=%URI:\=/%
set URI=%URI: =%%20%

"%EDGE%" --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf="%PDF%" "%URI%"
echo PDF saved to %PDF%
pause
