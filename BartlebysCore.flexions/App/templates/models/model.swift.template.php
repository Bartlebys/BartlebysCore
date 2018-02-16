<?php echo GenerativeHelperForSwift::defaultHeader($f,$d); ?>

<?php echo $imports.cr(2) ?>
#if os(macOS) && USE_COCOA_BINDINGS
public typealias <?php echo ucfirst($d->name)?> = Dynamic<?php echo ucfirst($d->name).cr()?>
#else
public typealias <?php echo ucfirst($d->name)?> = Common<?php echo ucfirst($d->name).cr()?>
#endif

// MARK: <?php echo $d->description?>

open class Common<?php echo ucfirst($d->name)?> : <?php echo GenerativeHelperForSwift::getBaseClass($d); ?>, Payload, Result{

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

    $dynanic=($property->isDynamic ? '':''); // Dynamic has been transfered to mac Only DynamicEntities
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


    // MARK: - NSCopy aka CopyingProtocol

    /// Provides an unregistered copy (the instance is not held by the dataPoint)
    ///
    /// - Parameter zone: the zone
    /// - Returns: the copy
    override open func copy(with zone: NSZone? = nil) -> Any {
        guard let data = try? JSON.encoder.encode(self) else {
            return ObjectError.message(message: "Encoding issue on copy of: \(<?php echo ucfirst($d->name);?>.typeName) \(self.uid)")
        }
        guard let copy = try? JSON.decoder.decode(type(of:self), from: data) else {
            return ObjectError.message(message: "Decoding issue on copy of:\(<?php echo ucfirst($d->name);?>.typeName) \(self.uid)")
        }
        return copy
    }
}



#if os(macOS) && USE_COCOA_BINDINGS

// You Can use Dynamic Override to support Cocoa Bindings
// This class can be used in a CollectionOf<T>

@objc open class Dynamic<?php echo ucfirst($d->name)?>:Common<?php echo ucfirst($d->name)?>{
<?php
$d->resetPropertyIndex(); // Reset the iterator
while ( $d ->iterateOnProperties() === true ) {


    $property = $d->getProperty();
    if ($property->mutability != Mutability::IS_VARIABLE){
        // Skip the non mutable props
        continue;
    }
    $name = $property->name;
    $method = ($property->method == Method::IS_CLASS ? 'static ' : '');
    $scope = '';
    if ($property->scope == Scope::IS_PRIVATE) {
        $scope = 'private ';
    } else if ($property->scope == Scope::IS_PROTECTED) {
        $scope = 'internal ';
    } else {
        $scope = 'open '; // We could may be switch to public?
    }

    $prefix = '@objc override dynamic ' . $method . $scope . $mutable;


    if ($property->isDynamic) {
        $optionalOrNot='';
        if(!isset($property->default)){
            $optionalOrNot='?';
        }

        $typeName = '';
        if ($property->type == FlexionsTypes::ENUM) {
            $typeName = ucfirst($name);
        } else if ($property->type == FlexionsTypes::COLLECTION) {
            $instanceOf = FlexionsSwiftLang::nativeTypeFor($property->instanceOf);
            if ($instanceOf == FlexionsTypes::NOT_SUPPORTED) {
                $instanceOf = $property->instanceOf;
            }
            $typeName = '[' . ucfirst($instanceOf) . ']';
        } else if ($property->type == FlexionsTypes::OBJECT) {
            $typeName = ucfirst($property->instanceOf);
        } else {
            $nativeType = FlexionsSwiftLang::nativeTypeFor($property->type);
            if (strpos($nativeType, FlexionsTypes::NOT_SUPPORTED) === false) {
                $typeName = $nativeType;
            } else {
                $typeName = 'Not_Supported()';
            }
        }
            echo("
    $prefix $name : $typeName$optionalOrNot{
        set{ super.$name = newValue }
        get{ return super.$name }
    }
");



    }
}
?>
}

#endif
