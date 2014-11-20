
package com.voxelengine.GUI {
	
import flash.display.BlendMode;
	
import com.voxelengine.worldmodel.TypeInfo;
import org.flashapi.swing.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.*;

import com.voxelengine.Globals;

public class BoxInventory extends VVBox
{
	public function BoxInventory( $widthParam:Number, $heightParam:Number, $borderStyle:String, $item:TypeInfo )
	{
		super( $widthParam, $heightParam, $borderStyle, $item.name );
		autoSize = false;
		dragEnabled = true;
		data = $item;
		titlePosition = BorderPosition.BELOW_TOP;
		titleAlignment = HorizontalAlignment.CENTER;
		titleLabel.color = 0x00FF00;
		//x.titleLabel.textField.blendMode = BlendMode.INVERT;
		titleLabel.textField.blendMode = BlendMode.ADD;
		backgroundTexture = "assets/textures/" + $item.image;
	}		
}
}