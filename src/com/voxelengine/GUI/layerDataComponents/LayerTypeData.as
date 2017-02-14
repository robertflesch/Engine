/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.layerDataComponents
{
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.TypeInfo;

import org.flashapi.swing.ComboBox;
import org.flashapi.swing.Label;
import org.flashapi.swing.event.*;
	import org.flashapi.swing.containers.*;
	import flash.geom.Vector3D;

	class LayerTypeData extends SimpleContainerBase
	{
		public function LayerTypeData( $label:String, $value:String, callBack:Function, $width:int = 180, $height:int = 20 ):void
		{
			super( $width, $height );
			padding = 0;
			autoSize = false;
			addElement( new Label( "Made of Type" ) );
			
			var cbType:ComboBox = new ComboBox( $value, 80, 10 );
			cbType.addEventListener( ListEvent.LIST_CHANGED, callBack );
			cbType.x = $width - 80;
			for each (var nitem:TypeInfo in TypeInfo.typeInfo )
			{
				//if ( "INVALID" != nitem.name && "AIR" != nitem.name && "BRAND" != nitem.name && -1 == nitem.name.indexOf( "EDIT" ) && -1 == nitem.name.indexOf( "UNNAMED" ) )
				if ( "INVALID" != nitem.name && "AIR" != nitem.name && "BRAND" != nitem.name && -1 == nitem.name.indexOf( "EDIT" ) )
				{
					cbType.addItem( nitem.name, nitem.type );
				}
			}
			cbType.selectedIndex = 0;
			addElement( cbType );
		}
	}
}

