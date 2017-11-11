/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI.panels {
import com.voxelengine.GUI.VoxelVerseGUI;
import com.voxelengine.GUI.components.ComponentCheckBox;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.PermissionsModel;
import com.voxelengine.worldmodel.models.Role;
import com.voxelengine.worldmodel.models.types.Player;

import flash.external.ExternalInterface;
import flash.net.URLRequest;
import flash.net.navigateToURL;

import org.flashapi.swing.*
import org.flashapi.swing.color.Color;
import org.flashapi.swing.event.*
import org.flashapi.swing.constants.*
import org.flashapi.swing.plaf.spas.VVUI;

import com.voxelengine.Log;
import com.voxelengine.GUI.components.*
import com.voxelengine.GUI.panels.ExpandableBox
import com.voxelengine.worldmodel.PermissionsBase;

import org.flashapi.swing.util.URLLocator;
import org.flashapi.swing.wtk.WindowButtonHelp;

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
		if ( _permissions.blueprint )
			outString += "blue print: " + (_permissions.blueprint?"Yes ":"No ");
		else
            outString += "blue print: No ";
		//if ( _at.hasScale )
			//outString += formatVec3DToSummary( "scl:", _at.scale )
		//if ( outString == "" ) {
			//outString = "No changes to initial settings"
			//_ebco.itemBox.showReset = false
		//}
		//else
			//_ebco.itemBox.showReset = true
		
			
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
        b.addEventListener( UIMouseEvent.CLICK, function (UIMouseEvent):void { navigateToURL( new URLRequest("http://voxelverse.com/helpPermissions.html"), "_blank"); } );

        // navigateToURL (new URLRequest ("mailto: blog@activetofocus.com"), "_blank");
		_itemBox.addElement(b);
        // copyCount
        _itemBox.addElement( new ComponentLabelSide( "Copy Count", String( _permissions.copyCount ), _itemBox.width ) );
        // binding
        _itemBox.addElement( new ComponentLabelSide( "Binding", _permissions.binding, _itemBox.width ) );
		// is this item a blue print
        var bluePrintCB:ComponentCheckBox = new ComponentCheckBox( "Blueprint", _permissions.blueprint, _itemBox.width, changeBluePrint );
        if ( Network.userId != _permissions.creator ) {
            bluePrintCB.enabled = false;
        }
        _itemBox.addElement( bluePrintCB );

        // blueprintGuid
        _itemBox.addElement( new ComponentLabelSide( "Blue Print Guid", _permissions.blueprintGuid ? _permissions.blueprintGuid : "" , _itemBox.width ) );
		// can the user modify this
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
			
	private function changeBluePrint(event:UIMouseEvent):void {
		if ( Network.userId == _permissions.creator ) {
			_permissions.blueprint = (event.target as CheckBox).selected;
		}
		else
			(new Alert("You do not have permission to change the 'blue print' permission on this object")).display();		
	}
	
	override protected function setChanged():void {
	}
}
}

