#!MC 1100
$!VarSet |MFBD| = 'FOLDER_PLACEHOLDER'
$!OPENLAYOUT  "FOLDER_PLACEHOLDER/tmp.lay" 
$!EXPORTSETUP EXPORTFORMAT = PNG
$!EXPORTSETUP EXPORTREGION = ALLFRAMES
$!EXPORTSETUP IMAGEWIDTH = 951
$!EXPORTSETUP EXPORTFNAME = 'FOLDER_PLACEHOLDER/OUTPUT_PLACEHOLDER.png'
$!EXPORT 
  EXPORTREGION = ALLFRAMES
$!RemoveVar |MFBD|
$!Quit
