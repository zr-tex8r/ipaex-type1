@echo off
pushd .
cd %~dp0
setlocal

:start
set OUT_DIR=..
set AFM_DIR=%OUT_DIR%\afm
set TFM_DIR=%OUT_DIR%\tfm
set PFB_DIR=%OUT_DIR%\type1
:pre
set PID=99
set EID=0
set PLANE=f0
set MAP_FILE=ipaex-vert.map
set MAP_FILE_M=ipaex-type1.map

if exist %MAP_FILE% ( del %MAP_FILE% )
call :onefont ipaexm ipxm IMFCTT1
call :onefont ipaexg ipxg IGFCTT1

move /Y *.afm %AFM_DIR%
move /Y *.tfm %TFM_DIR%
move /Y *.pfb %PFB_DIR%
move /Y *.fdx %OUT_DIR%
perl map-concat.pl %OUT_DIR%\%MAP_FILE_M% %MAP_FILE%
del %MAP_FILE%

:end
endlocal
popd
goto :EOF

:onefont
set FONT=%1
set FAM=%2
set PSFAM=%3
if not exist %FONT%.ttf (
  echo '%FONT%.ttf' not found.
  goto :EOF
)

set VERT_FILE=ipaex-vert.tsv
set CMAP_12_FILE=%FONT%-cmap12.tsv
set CHAR_MAP_FILE=%FONT%-v.code.map
set FDX_FILE=c70%FAM%.fdx
set FDXA_FILE=c70%FAM%a.fdx
if exist %FONT%*.ttx ( del %FONT%*.ttx )
if exist %FONT%-v*.ttf ( del %FONT%-v*.ttf )
zrotfdump cmap-12 %FONT%.ttf > %CMAP_12_FILE%
ttx -i -t cmap %FONT%.ttf
perl vhack_merge.pl %VERT_FILE% %CMAP_12_FILE% %FONT%.ttx %FAM% %PID% %EID% %PLANE% %FONT%-v.ttx %CHAR_MAP_FILE% %FDX_FILE% %FDXA_FILE%
if not exist %CHAR_MAP_FILE% (
  goto :EOF
)
ttx -m %FONT%.ttf %FONT%-v.ttx
set TFMNAME=%FAM%-r-u%PLANE%
ttf2pt1 -L"%CHAR_MAP_FILE%+pid=%PID%,eid=%EID%,u%PLANE%" %FONT%-v.ttf %TFMNAME%

perl fix-type1.pl %TFMNAME%.t1a __gen_inter.t1a %PSFAM% u%PLANE%
t1asm -b __gen_inter.t1a %TFMNAME%.pfb
fgrep -v -e .notdef %TFMNAME%.afm > __gen_inter.afm
afm2tfm __gen_inter -u __gen_in
tftopl __gen_in __gen_in
perl fix-pl.pl __gen_in.pl __gen_out.pl %PSFAM% u%PLANE% 0
pltotf __gen_out %TFMNAME%
echo %TFMNAME% %PSFAM%-u%PLANE% ^<%TFMNAME%.pfb>>%MAP_FILE%

del %FONT%*.ttx %FONT%-v*.ttf __gen_*.*
del %CMAP_12_FILE% %CHAR_MAP_FILE% %TFMNAME%.t1a %TFMNAME%.afm

goto :EOF
:exit
