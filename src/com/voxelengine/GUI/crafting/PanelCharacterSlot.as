/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.crafting {
import org.flashapi.swing.*;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.dnd.DnDFormat;
import org.flashapi.swing.event.*;

import com.voxelengine.events.CraftingItemEvent;
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.worldmodel.TypeInfo;

public class PanelCharacterSlot extends PanelBase {
    private const BOX_SIZE:int = 32;

    public function PanelCharacterSlot($parent:PanelBase, $widthParam:Number, $heightParam:Number, $slotName:String )
    {
        super( $parent, $widthParam, $heightParam );

        addElement( new Label( "Bonuses" ) );
        padding = 5;
        var lb:Label = new Label( "LeftHand" );
        addElement( lb );
        addElement( new BoxCraftingBase( BOX_SIZE, "Model" ) );
    }

    private function doDrag(e:UIMouseEvent):void
    {
        // reset the material
        var mb:Box = e.target as Box;
        mb.backgroundTexture = null;
        var ti:TypeInfo = mb.data;
        CraftingItemEvent.dispatch( new CraftingItemEvent( CraftingItemEvent.BONUS_REMOVED, ti ) );
    }

}
}