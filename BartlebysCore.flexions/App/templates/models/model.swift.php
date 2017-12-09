<?php
include  FLEXIONS_MODULES_DIR . '/Bartleby/templates/localVariablesBindings.php';
require_once FLEXIONS_MODULES_DIR . '/Bartleby/templates/Requires.php';
require_once FLEXIONS_MODULES_DIR . '/Languages/FlexionsSwiftLang.php';

/* @var $f Flexed */
/* @var $d EntityRepresentation */

if (isset ( $f )) {
    // We determine the file name.
    $f->fileName = GenerativeHelperForSwift::getCurrentClassNameWithPrefix($d).'.swift';
    // And its package.
    $f->package = 'xOS/';
}

//////////////////
// EXCLUSIONS
//////////////////

$exclusion = array();
$exclusionName = str_replace($h->classPrefix, '', $d->name);

if (isset($excludeEntitiesWith)) {
    $exclusion = $excludeEntitiesWith;
}
foreach ($exclusion as $exclusionString) {
    if (strpos($exclusionName, $exclusionString) !== false) {
        return NULL; // We return null
    }
}

/////////////////////////
// VARIABLES COMPUTATION
/////////////////////////

$isBaseObject = $d->isBaseObject();
/*
$inheritancePrefix = ($isBaseObject ? '' : 'override ');
$inversedInheritancePrefix = ($isBaseObject ? 'override ':'');
*/

// We use in this context an Hand Coded Model:Object that implements the base protocols
$inheritancePrefix = 'override ';
$inversedInheritancePrefix = $inheritancePrefix;

$blockRepresentation=$d;

// ManagedModel
$baseObjectBlock='';
if($isBaseObject && $d->name == GenerativeHelperForSwift::defaultBaseClass($d) ){
    $baseObjectBlock=stringFromFile(TEMPLATES_DIR.'/blocks/BaseObject.swift.block');
}


// CODABLE
$codableBlock='';
if( $modelsShouldConformToCodable ) {
    if($isBaseObject){
        $decodableblockEndContent="";
        $encodableblockEndContent="";
    }else{
        $decodableblockEndContent="";
        $encodableblockEndContent="";
    }
    // We define the context for the block
    Registry::Instance()->defineVariables(['blockRepresentation'=>$d,'isBaseObject'=>$isBaseObject,'decodableblockEndContent'=>$decodableblockEndContent,'encodableblockEndContent'=>$encodableblockEndContent]);
    $codableBlock=stringFromFile(FLEXIONS_MODULES_DIR.'/Bartleby/templates/blocks/Codable.swift.block.php');
}



$superInit = ($isBaseObject ? 'super.init()'.cr() : 'super.init()'.cr());

if (!defined('_propertyValueString_DEFINED')){
    define("_propertyValueString_DEFINED",true);
    function _propertyValueString(PropertyRepresentation $property){

        if ($property->isSupervisable===false){

            ////////////////////////////
            // Property isn't supervisable
            ////////////////////////////
            if(isset($property->default)){
                if($property->type==FlexionsTypes::STRING){
                    $stringDefaultValue = $property->default;
                    if (strpos($stringDefaultValue,'$')!==false){
                        $stringDefaultValue = ltrim($stringDefaultValue,'$');
                        return " = $stringDefaultValue"; // No quote
                    }else{
                        return " = \"$property->default\"";
                    }
                }else{
                    return " = $property->default";
                }
            }
            return "?";
        }else{

            $associatedCondition = $property->type == FlexionsTypes::DICTIONARY? '' :  "&& $property->name != oldValue";

            //////////////////////////
            // Property is supervisable
            //////////////////////////
            ///
        if(isset($property->default)){


            if($property->type==FlexionsTypes::STRING){
                $stringDefaultValue = $property->default;
                if (strpos($stringDefaultValue,'$')!==false){
                    $stringDefaultValue = ltrim($stringDefaultValue,'$');
                    $stringDefaultValue = "$stringDefaultValue"; // No quote
                }else {
                    $stringDefaultValue = "\"$property->default\""; // Quoted
                }
                return " = $stringDefaultValue {
    didSet { 
       if !self.wantsQuietChanges $associatedCondition {
            self.provisionChanges(forKey: \"$property->name\",oldValue: oldValue,newValue: $property->name) 
       } 
    }
}";
            }else{
                return " = $property->default  {
    didSet { 
       if !self.wantsQuietChanges $associatedCondition {
            self.provisionChanges(forKey: \"$property->name\",oldValue: oldValue".($property->type==FlexionsTypes::ENUM ? ".rawValue" : "" ).",newValue: $property->name".($property->type==FlexionsTypes::ENUM ? ".rawValue" : "" ).")  
       } 
    }
}";
}

        }
        return "? {
    didSet { 
       if !self.wantsQuietChanges $associatedCondition {
            self.provisionChanges(forKey: \"$property->name\",oldValue: oldValue".($property->type==FlexionsTypes::ENUM ? "?.rawValue" : "" ).",newValue: $property->name".( $property->type==FlexionsTypes::ENUM ? "?.rawValue" : "" ) .") 
       } 
    }
}";
        }
    }
}

// Include block
include dirname(__DIR__) . '/blocks/simpleIncludeBlock.swift.php';

//////////////////
// TEMPLATE
//////////////////

include __DIR__.'/model.swift.template.php';
