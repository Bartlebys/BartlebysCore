<?php

$d = Registry::instance()->valueForKey('blockRepresentation');
$codableBlock = Registry::instance()->valueForKey('codableBlock');
$inheritancePrefix = Registry::instance()->valueForKey('inheritancePrefix');
$superInit = Registry::instance()->valueForKey('superInit');
$useCocoaBindings = Registry::instance()->valueForKey('useCocoaBindings');
?>// MARK: <?php echo $d->description?>

open class <?php echo ucfirst($d->name)?> : <?php echo GenerativeHelperForSwift::getBaseClass($d); ?>, Payload, Result{

    public typealias CollectedType = <?php echo ucfirst($d->name)?>

<?php

while ( $d ->iterateOnProperties() === true ) {
    $property = $d->getProperty();
    $name = $property->name;

    echo(cr());

    if($property->description!=''){
        echoIndent('//' .$property->description. cr(), 1);
    }
    // Infer consistant semantics.
    if($property->method==Method::IS_CLASS){
        // we can't currently serialize Static members.
        $property->isSerializable=false;
    }

    // Dynamism, method, scope, and mutability support

    $dynanic=($useCocoaBindings && $property->isDynamic ? '@objc dynamic ':''); // Dynamic has been transfered to mac Only DynamicEntities
    $method=($property->method==Method::IS_CLASS ? 'static ' : '' );
    $scope='';
    if($property->scope==Scope::IS_PRIVATE){
        $scope='private ';
    }else if ($property->scope==Scope::IS_PROTECTED){
        $scope='internal ';
    }else{
       $scope='open '; // We could may be switch to public?
    }
   $mutable=($property->mutability==Mutability::IS_VARIABLE ? 'var ':'let ');
    $prefix=$dynanic.$method.$scope.$mutable;


    //Generate the property line

    if($property->type==FlexionsTypes::ENUM){
        $enumTypeName=ucfirst($name);
        echoIndent('public enum ' .$enumTypeName.':'.ucfirst(FlexionsSwiftLang::nativeTypeFor($property->instanceOf)). '{', 1);
        foreach ($property->enumerations as $element) {
            if($property->instanceOf==FlexionsTypes::STRING){
                echoIndent('case ' .lcfirst($element).' = "'.$element.'"', 2);
            }elseif ($property->instanceOf==FlexionsTypes::INTEGER){
                echoIndent('case ' .lcfirst($element), 2);
            } else{
                echoIndent('case ' .lcfirst($element).' = '.$element, 2);
            }
        }
        echoIndent('}', 1);
        echoIndent($prefix. $name .':'.$enumTypeName._propertyValueString($property), 1);
    }else if($property->type==FlexionsTypes::COLLECTION){
        $instanceOf=FlexionsSwiftLang::nativeTypeFor($property->instanceOf);
        if ($instanceOf==FlexionsTypes::NOT_SUPPORTED){
            $instanceOf=$property->instanceOf;
        }
        echoIndent($prefix. $name .':['.ucfirst($instanceOf). ']'._propertyValueString($property), 1);
    }else if($property->type==FlexionsTypes::OBJECT){
        echoIndent($prefix. $name .':'.ucfirst($property->instanceOf)._propertyValueString($property), 1);
    }else{
        $nativeType=FlexionsSwiftLang::nativeTypeFor($property->type);
        if(strpos($nativeType,FlexionsTypes::NOT_SUPPORTED)===false){
            echoIndent($prefix. $name .':'.$nativeType._propertyValueString($property), 1);
        }else{
            echoIndent($prefix. $name .':Not_Supported = Not_Supported()//'. ucfirst($property->type), 1);
        }
    }
}
?>

<?php echo $codableBlock ?>


    // MARK: - Initializable

    required public init() {
        <?php echo $superInit ?>
    }
<?php
    $ImplementUniversalType = (GenerativeHelperForSwift::getBaseClass($d) == "Model" || GenerativeHelperForSwift::getBaseClass($d) == "ManagedModel" );
    if ($ImplementUniversalType == true ){
        echo("
    // MARK: - UniversalType

    $inheritancePrefix open class var typeName:String{
        return \"".ucfirst($d->name)."\"
    }

    $inheritancePrefix open class var collectionName:String{
        return \"".lcfirst(Pluralization::pluralize($d->name))."\"
    }

    $inheritancePrefix open var d_collectionName:String{
        return ".ucfirst($d->name).".collectionName
    }
");
    }
?>

<?php

$typeName = "";
if (GenerativeHelperForSwift::getBaseClass($d) != "CodableObject"){
    $typeName = "\($d->name.typeName)";
}
?>

    // MARK: - NSCopy aka CopyingProtocol

    /// Provides an unregistered copy (the instance is not held by the dataPoint)
    ///
    /// - Parameter zone: the zone
    /// - Returns: the copy
    override open func copy(with zone: NSZone? = nil) -> Any {
        guard let data = try? JSON.encoder.encode(self) else {
            return ObjectError.message(message: "Encoding issue on copy of: <?php echo $typeName;?> \(self.uid)")
        }
        guard let copy = try? JSON.decoder.decode(type(of:self), from: data) else {
            return ObjectError.message(message: "Decoding issue on copy of: <?php echo $typeName;?> \(self.uid)")
        }
        return copy
    }
}