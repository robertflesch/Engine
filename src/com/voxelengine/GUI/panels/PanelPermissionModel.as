/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels {
import flash.net.URLRequest;
import flash.net.navigateToURL;

import org.flashapi.swing.*
import org.flashapi.swing.event.*
import playerio.GameFS;
import playerio.PlayerIO;

import com.voxelengine.Log;
import com.voxelengine.GUI.components.*
import com.voxelengine.GUI.components.ComponentCheckBox;
import com.voxelengine.Globals;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.PermissionsModel;



public class PanelPermissionModel extends ExpandableBox
{
	private var _permissions:PermissionsModel;
	public function PanelPermissionModel( $parent:ExpandableBox, $ebco:ExpandableBoxConfigObject ) {		
		_permissions = $ebco.rootObject;
		super( $parent, $ebco )
	}
	
	//override protected function resetElement():void  { 
		//_at.resetInitialPosition()
		//changeMode()
	//}
	
	override protected function collapasedInfo():String  {
		var outString:String = "";
		
		outString += "creator: " + _permissions.creator + "   ";

		return outString
	}
	
	private function formatVec3DToSummaryBig( $title:String, $vec:Object ):String {
		return $title + "x:" + $vec.x + " y:" + $vec.y + " z:" + $vec.z + " "
	}

	private function formatVec3DToSummary( $title:String, $vec:Object ):String {
		return $title + "{" + $vec.x + ":" + $vec.y + ":" + $vec.z + "} "
	}
	
	override protected function hasElements():Boolean { return true; }
	
	override protected function expand():void {
		super.expand();

        _itemBox.addElement( new ComponentSpacer( _itemBox.width, 4 ) );
		//
		var b:Button = new Button( "Open help topic in new tab", _itemBox.width, 20 );
        //var b:WindowButtonHelp = new WindowButtonHelp( "Open help topic in new tab", _itemBox.width, 20 );
//		b.borderWidth = 0;
//		b.color = Color.DEFAULT;
        b.addEventListener( UIMouseEvent.CLICK, function (UIMouseEvent):void {
            var fs:GameFS = PlayerIO.gameFS(Globals.GAME_ID);
            var resolvedFilePath:String = fs.getUrl("/VoxelVerse/assets/help/permissions.html");
            navigateToURL( new URLRequest(resolvedFilePath), "_blank");
            //navigateToURL( new URLRequest("http://voxelverse.com/assets/help/permissions.html"), "_blank");
		} );

        // navigateToURL (new URLRequest ("mailto: blog@activetofocus.com"), "_blank");
		_itemBox.addElement(b);
        // copyCount
        _itemBox.addElement( new ComponentLabelSide( "Copy Count", String( _permissions.copyCount ), _itemBox.width ) );
        // binding
        _itemBox.addElement( new ComponentLabelSide( "Binding", _permissions.binding, _itemBox.width ) );
        Log.out( "PanelPermissionModel.expand - NOT SHOWING MODIFY OPTIONS", Log.WARN);

//        var modifyCB:ComponentCheckBox = new ComponentCheckBox( "Modify", _permissions.modify, _itemBox.width, changeModify )
//        if ( Network.userId != _permissions.creator ) {
//			modifyCB.enabled = false;
//        }
//		_itemBox.addElement( modifyCB );
        _itemBox.addElement( new ComponentLabelSide( "Modify Types", PermissionsModel.getTextFromModificationCode(_permissions.modify), _itemBox.width ) );

        // creator
        _itemBox.addElement( new ComponentLabelSide( "Creator", _permissions.creator, _itemBox.width ) );
        // createdDate
        _itemBox.addElement( new ComponentLabelSide( "Created Date", _permissions.createdDate , _itemBox.width ) );
        // modifyDate
        _itemBox.addElement( new ComponentLabelSide( "Modified Date", _permissions.modifiedDate, _itemBox.width ) );
	}
	
//	private function changeModify(event:UIMouseEvent):void {
//		if ( Network.userId == _permissions.creator ) {
//			_permissions.modify = (event.target as CheckBox).selected;
//		}
//		else
//			(new Alert("You do not have permission to change the 'modify' permission on this object")).display();
//	}
			
	override protected function setChanged():void {
	}
}
}

