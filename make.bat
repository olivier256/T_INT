@cls
@..\compile\asm68k /p /m t_int.asm,t_int.bin,Z:\TEMP\t_int.symb,Z:\TEMP\t_int.lis
@if errorlevel 1 goto fin
@..\compile\checksum t_int.bin
:fin
