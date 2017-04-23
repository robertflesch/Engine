/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.crafting {
import org.flashapi.swing.constants.BorderStyle;

public class BoxCharacterSlot extends BoxCraftingBase {
    public function BoxCharacterSlot($size:Number, $acceptsCategory:String, $acceptsSubCat:String = "", $borderStyle:String = BorderStyle.INSET) {
        super($size, $acceptsCategory, $acceptsSubCat, $borderStyle);
        data = $acceptsCategory;
    }
}
}