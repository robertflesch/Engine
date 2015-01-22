
package com.voxelengine.GUI.inventory {
	
import flash.display.BlendMode;
	
import org.flashapi.swing.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.*;

import com.voxelengine.Globals;
import com.voxelengine.GUI.*;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.events.InventoryVoxelEvent;

public class BoxInventory extends VVBox
{
	private var _count:Label
	private var _typeInfo:TypeInfo;
	public function BoxInventory( $widthParam:Number, $heightParam:Number, $borderStyle:String, $item:TypeInfo )
	{
		_typeInfo = $item;
		super( $widthParam, $heightParam, $borderStyle, $item.name );
		autoSize = false;
		dragEnabled = true;
		data = $item;
		//titlePosition = BorderPosition.BELOW_TOP;
		//titleAlignment = HorizontalAlignment.CENTER;
		//titleLabel.color = 0x00FF00;
		//x.titleLabel.textField.blendMode = BlendMode.INVERT;
		//titleLabel.textField.blendMode = BlendMode.ADD;
		backgroundTexture = "assets/textures/" + $item.image;
		
		_count = new Label( $item.name );
		_count.fontColor = 0xffffff;
		addElement(_count);
		
		Globals.inventoryManager.addEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, voxelCount ) ;
		Globals.inventoryManager.dispatchEvent( new InventoryVoxelEvent( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_REQUEST, _typeInfo.type, -1 ) );
	}		
	
	private function voxelCount(e:InventoryVoxelEvent):void 
	{
		if ( _typeInfo.type == e.id ) {
			Globals.inventoryManager.removeEventListener( InventoryVoxelEvent.INVENTORY_VOXEL_COUNT_RESULT, voxelCount ) ;
			_count.text = String( e.result );
		}
	}
}
}