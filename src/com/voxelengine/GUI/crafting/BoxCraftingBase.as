/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.crafting {
import org.flashapi.swing.Box;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.dnd.DnDFormat;

public class BoxCraftingBase extends Box {
    private var _acceptsCategory:String;
    private var _acceptsSubCat:String;
    public function BoxCraftingBase( $size:Number, $acceptsCategory:String, $acceptsSubCat:String = "", $borderStyle:String = BorderStyle.INSET ) {
        super($size, $size, borderStyle);
        _acceptsCategory = $acceptsCategory;
        _acceptsSubCat = $acceptsSubCat;

        dropEnabled = true;
        dragEnabled = true;
        borderStyle = $borderStyle;
        var dndFmt:DnDFormat = new DnDFormat( _acceptsCategory, _acceptsSubCat );
        addDropFormat( dndFmt );
    }
}
}