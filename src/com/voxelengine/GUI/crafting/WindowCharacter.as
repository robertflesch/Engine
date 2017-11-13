/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.crafting {

import com.voxelengine.GUI.VVBox;
import com.voxelengine.events.CharacterSlotEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.server.Network;

import org.flashapi.swing.Image;
import org.flashapi.swing.constants.BorderStyle;

import com.voxelengine.GUI.VVPopup;
import com.voxelengine.renderer.Renderer;

import org.flashapi.swing.layout.AbsoluteLayout;

public class WindowCharacter extends VVPopup {

    static public const HAND_RIGHT:String = "ArmRight";
    static public const HAND_LEFT:String = "ArmLeft";
    static private const BOX_SIZE:int = 48;
    public function WindowCharacter() {
        super( "Character Stuff");
     //   super( $parent, $widthParam, $heightParam );
        borderStyle = BorderStyle.NONE;
        autoSize = true;
        padding = 0;
        layout = new AbsoluteLayout();
        width = 230;
        height = 436;
        backgroundTexture = "characterBackgroundMale.jpg";
        var i:Image = new Image( "characterBackgroundMale.jpg" );
        i.width = 230;
        i.height = 426;
        addElement(i);

//        var lh:BoxCharacterSlot = new BoxCharacterSlot( BOX_SIZE, "Head" );
//        lh.x = 85;
//        lh.y = 10;
//        addElement( lh );

//        var lg:BoxCharacterSlot = new BoxCharacterSlot( BOX_SIZE, "Gauntlet" );
//        lg.x = 25;
//        lg.y = 150;
//        addElement( lg );

        var lh:BoxCharacterSlot = new BoxCharacterSlot( BOX_SIZE, HAND_LEFT );
        lh.x = 15;
        lh.y = 210;
        addElement( lh );
        CharacterSlotEvent.addListener(CharacterSlotEvent.RESULT, lhSlotResult );
        CharacterSlotEvent.create(CharacterSlotEvent.REQUEST, Network.userId, HAND_LEFT, "");

//        var rg:BoxCharacterSlot = new BoxCharacterSlot( BOX_SIZE, "Gauntlet" );
//        rg.x = 150;
//        rg.y = 150;
//        addElement( rg );

        var rh:BoxCharacterSlot = new BoxCharacterSlot( BOX_SIZE, HAND_RIGHT );
        rh.x = 160;
        rh.y = 210;
        addElement( rh );
        CharacterSlotEvent.addListener(CharacterSlotEvent.RESULT, rhSlotResult );
        CharacterSlotEvent.create(CharacterSlotEvent.REQUEST, Network.userId, HAND_RIGHT, "");

        display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );

        function lhSlotResult( $cse:CharacterSlotEvent ):void {
            CharacterSlotEvent.removeListener(CharacterSlotEvent.RESULT, lhSlotResult );
            if ( $cse.guid ) {
                ModelInfoEvent.addListener( ModelBaseEvent.RESULT, lhSlotResultMetadata );
                ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, $cse.guid, null );
            }

            function lhSlotResultMetadata( $mde:ModelInfoEvent ):void {
                ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, lhSlotResultMetadata );
                if ( $mde.modelInfo ) {
                    lh.backgroundTexture = VVBox.drawScaled( $mde.modelInfo.thumbnail, BOX_SIZE, BOX_SIZE );
                }
            }
        }

        function rhSlotResult( $cse:CharacterSlotEvent ):void {
            CharacterSlotEvent.removeListener(CharacterSlotEvent.RESULT, lhSlotResult );
            if ( $cse.guid ) {
                ModelInfoEvent.addListener( ModelBaseEvent.RESULT, lhSlotResultMetadata );
                ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, $cse.guid, null );
            }

            function lhSlotResultMetadata( $mde:ModelInfoEvent ):void {
                ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, lhSlotResultMetadata );
                if ( $mde.modelInfo ) {
                    rh.backgroundTexture = VVBox.drawScaled( $mde.modelInfo.thumbnail, BOX_SIZE, BOX_SIZE );
                }
            }
        }

    }

    override public function remove():void {
        super.remove();
    }

    public function close():void { }

}
}