set "SOURCESDK=C:\Program Files (x86)\Steam\steamapps\common\Source SDK Base 2013 Multiplayer\customConfig"
set GAMEINFO_DIR=C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod
rm -rfv %SOURCESDK%\models\*
"C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin\studiomdl.exe" -nop4 -dumpmaterials electric_motor.qc
mkdir C:\Users\Rob\Documents\Projects\spacebuild\models\n3x15
cp -rv "%SOURCESDK%\models\n3x15" "C:\Users\Rob\Documents\Projects\spacebuild\models\"
..\..\..\bin\MDLTextureInfo "C:\Users\Rob\Documents\Projects\spacebuild\models\n3x15\motor\electric_motor.mdl"
pause