/**
 * Created by dev on 4/22/2017.
 */
package com.voxelengine.GUI.crafting {

import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.constants.LayoutOrientation;

import com.voxelengine.GUI.VVPopup;
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.renderer.Renderer;

public class WindowCharacter extends VVPopup
{
    private var _panelBase:PanelBase;
    private var _panelSlots:PanelBase;

    public function WindowCharacter() {
        super( "Character Stuff");
     //   super( $parent, $widthParam, $heightParam );
        borderStyle = BorderStyle.NONE;
        autoSize = true;
        padding = 0;
        layout.orientation = LayoutOrientation.VERTICAL;

        _panelBase = new PanelBase( null, width, height  );
        _panelBase.layout.orientation = LayoutOrientation.HORIZONTAL;
        addElement( _panelBase );

        _panelSlots = new PanelCharacterSlot( _panelBase, width, height, "Left Hand" );
        _panelSlots.borderStyle = BorderStyle.NONE;
        _panelBase.addElement( _panelSlots );

        _panelSlots = new PanelCharacterSlot( _panelBase, width, height, "Right Hand" );
        _panelSlots.borderStyle = BorderStyle.NONE;
        _panelBase.addElement( _panelSlots );

        display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
    }

    override public function remove():void {
        super.remove();
    }

    public function close():void
    {
        //super.onRemoved(e);
    //    _craftedItem.cancel();
    //    _craftedItem = null;
    //    _panelForumla.remove();
    //    _panelBonuses.remove();
    //    _panelMaterials.remove();
    //    _panelPreview.remove();
    //    _panelButtons.remove();

    }

}
}