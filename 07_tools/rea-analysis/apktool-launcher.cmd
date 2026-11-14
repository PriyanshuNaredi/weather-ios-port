@echo off
REM REA apktool launcher wrapper (project-local, no PATH changes).
REM Uses 8.3 short path segments because the real project path contains a
REM Unicode arrow that cmd.exe cannot represent in its codepage.
java -jar "C:\Users\naredi\DOWNLO~1\ANDROI~1\07_tools\apktool\apktool.jar" %*
