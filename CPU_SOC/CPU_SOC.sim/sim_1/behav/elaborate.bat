@echo off
set xv_path=D:\\xlinix\\Vivado\\2016.4\\bin
call %xv_path%/xelab  -wto 4dca591097cc43d4bf5ed6a63fbd71b8 -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L secureip --snapshot top_behav xil_defaultlib.top -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
