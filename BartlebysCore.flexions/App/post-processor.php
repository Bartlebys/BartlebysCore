<?php

// We can deploy the files per version and stage
// And keep a copy in the out.YouDubApi-flexions-App folder.
require_once FLEXIONS_MODULES_DIR . '/Deploy/LocalDeploy.php';

$h = Hypotypose::Instance();
$r = Registry::Instance();
$CorexOS_exportPath=$r->valueForKey('CorexOS_exportPath');
$eraseFilesOnGeneration=$r->valueForKey('$eraseFilesOnGeneration');
if (isset($CorexOS_exportPath)){
    if ($h->stage==DefaultStages::STAGE_DEVELOPMENT){
        $deploy=new LocalDeploy($h);
        $deploy->copyFilesInPackage('/xOS/',$CorexOS_exportPath,true);
    }
}else{
    fLog('MWxOS_exportPath is not defined check your build configuration constants.',true);
}
