<?php echo GenerativeHelperForSwift::defaultHeader($f,$d); ?>

<?php echo $imports.cr(1);?>

#if !USE_COCOA_BINDINGS

<?php echo $noBindingsBlocks; ?>

#else

<?php echo $blocksWithCocoaBindings; ?>

#endif
