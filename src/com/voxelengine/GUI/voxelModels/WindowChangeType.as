/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.voxelModels
{
import com.voxelengine.worldmodel.oxel.Oxel;
import flash.events.MouseEvent;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.GUI.VVPopup;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class WindowChangeType extends VVPopup
{
	private var _cb:ComboBox;
	private var _cbTo:ComboBox;
	private var _vm:VoxelModel;

	public function WindowChangeType( vm:VoxelModel ):void 
	{ 
		//throw new Error("Nothing here"); 
		_vm = vm;
		
		super("Change Type");
		layout.orientation = LayoutOrientation.VERTICAL;
		autoSize = true;
		shadow = true;
		
		var panel:Panel = new Panel( 200, 80);
		panel.autoSize = true;
		panel.layout.orientation = LayoutOrientation.VERTICAL;
		
		_cb = new ComboBox( "Original Type" );
		panel.addElement( _cb );
		
		_cbTo = new ComboBox( "New Type" );
		panel.addElement( _cbTo );
		
		var item:TypeInfo;
		for ( var i:int = TypeInfo.MIN_TYPE_INFO; i < TypeInfo.MAX_TYPE_INFO; i++ )
		{
			item = TypeInfo.typeInfo[i];
			if ( null == item )
				continue;
			if ( "INVALID" != item.name && "AIR" != item.name && "BRAND" != item.name && -1 == item.name.indexOf( "EDIT" ) && item.placeable )
			{
				_cb.addItem( item.name, item.type );
				_cbTo.addItem( item.name, item.type );
			}
		}
		
		addElement( panel );
		
		var button:Button = new Button( "Change all Types" );
		button.addEventListener(MouseEvent.CLICK, change );

		addElement( button );
		
		display( 200, 150 );
		
		//var pg:PictureGallery = new PictureGallery( 200, 200, BorderStyle.SOLID );
		//for each (var item:TypeInfo in Globals.Info )
		//{
			//trace( Globals.appPath + item.thumbnail );
			//
			//var o:Object = { image: (Globals.appPath + item.thumbnail), caption: item.name, data: item };
			//pg.addItem( o, item );
		//}
		//pg.display()			
	} 
	
	private function change(event:UIMouseEvent):void 
	{
		if ( _vm )
		{
			if ( -1 == _cb.selectedIndex )
				return;
			var li:ListItem = _cb.getItemAt(_cb.selectedIndex );
			var fromType:int = li.data;
			if ( -1 == _cbTo.selectedIndex )
				return;
			li = _cbTo.getItemAt(_cbTo.selectedIndex );
			var toType:int = li.data;
			
			if ( _vm.modelInfo.oxelPersistence && _vm.modelInfo.oxelPersistence.oxelCount ) {
				var oxel:Oxel = _vm.modelInfo.oxelPersistence.oxel;
				oxel.changeTypeFromTo( fromType, toType );
				_vm.modelInfo.oxelPersistence.changed = true;
				_vm.modelInfo.oxelPersistence.save()
			}
			else
				Log.out( "WindowChangeType.change - modelInfo.oxelPersistence.oxel not found for guid: " + _vm.modelInfo.guid, Log.WARN );
		}
	}

}
}