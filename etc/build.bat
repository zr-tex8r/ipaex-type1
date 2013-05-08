@echo off
pushd .
cd %~dp0
setlocal

:start
set OUT_DIR=..
set AFM_DIR=%OUT_DIR%\afm
set TFM_DIR=%OUT_DIR%\tfm
set PFB_DIR=%OUT_DIR%\type1
set AUXBAT_FILE=__aux.bat
:pre
mkdir %AFM_DIR%
mkdir %TFM_DIR%
mkdir %PFB_DIR%
del %AFM_DIR%\*.afm
del %TFM_DIR%\*.tfm
del %PFB_DIR%\*.pfb
del %AUXBAT_FILE%
:first
perl gen-codemap.pl
if not exist %AUXBAT_FILE% (
  goto :EOF
)
call %AUXBAT_FILE%
rem set ALL_ENC=t1 u30
del %AUXBAT_FILE%

call :onefont ipaexm ipxm IMFCTT1 ipamp
call :onefont ipaexg ipxg IGFCTT1 ipagp

move /Y *.afm %AFM_DIR%
move /Y *.tfm %TFM_DIR%
move /Y *.pfb %PFB_DIR%
move /Y %MAP_FILE% %OUT_DIR%

:end
endlocal
popd
goto :EOF

:onefont
set FONT=%1
set FAM=%2
set PSFAM=%3
set FONTP=%4
if not exist %FONT%.ttf (
  echo '%FONT%.ttf' not found.
  goto :EOF
)
if not exist %FONTP%.ttf (
  echo '%FONTP%.ttf' not found.
  goto :EOF
)

ttf2pt1 -Lipaex.code.map+u00 %FONT%.ttf __gen_inter
perl -ne "print qq'set SPWD=$1\n' if /^C 160 ; WX (\d+)/" __gen_inter.afm > %AUXBAT_FILE%
set SPWD=300
call %AUXBAT_FILE%

for %%e in (%ALL_ENC%) do (
call :checkenc %%e %FAM%-r-%%e
perl fix-type1.pl %FAM%-r-%%e.t1a __gen_inter.t1a %PSFAM% %%e
t1asm -b __gen_inter.t1a %FAM%-r-%%e.pfb
fgrep -v -e .notdef %FAM%-r-%%e.afm > __gen_inter.afm
afm2tfm __gen_inter -u __gen_in
tftopl __gen_in __gen_in
perl fix-pl.pl __gen_in.pl __gen_out.pl %PSFAM% %%e %SPWD%
pltotf __gen_out %FAM%-r-%%e
afm2tfm __gen_inter -u -s %SLANT% __gen_in
tftopl __gen_in __gen_in
perl fix-pl.pl __gen_in.pl __gen_out.pl %PSFAM% %%e %SPWD%
pltotf __gen_out %FAM%-ro-%%e
del %FAM%-r-%%e_.afm %FAM%-r-%%e.t1a
)

del %AUXBAT_FILE% __gen_*.*

goto :EOF

:checkenc
set FONT1=%FONT%
set XXX=.%1
if "%XXX%"=="%XXX:.u=.z%" set FONT1=%FONTP%
ttf2pt1 -Lipaex.code.map+%1 %FONT1%.ttf %2

goto :EOF

:exit
