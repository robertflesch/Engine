	
	/*	
		
		//autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		//closeButtonEnabled = false; // this show it enabled, but doesnt allow it to be clicked
		//closeButtonActive = false;  // this greys it out, and doesnt allow it to be clicked
		
		
		//private var _transforms:Vector.<AnimationTransform>;
		//private var _attachments:Vector.<AnimationAttachment>;
		//private var _sound:AnimationSound;
		//private var _type:String;
		//// For loading local files only
		//public var ownerGuid:String;
		//public var guid:String; // File name if used locally, GUID from DB
		//public var model:String = MODEL_BIPEDAL_10;  // What class of models does this apply do BIPEDAL_10, DRAGON_9, PROPELLER
		//public var databaseObject:DatabaseObject;
		//public var name:String;
		//public var desc:String;
		//public var world:String;
		////public var model:String;
		//public var created:Date;
		//public var modified:Date;
		//
		addElement( new Spacer( WIDTH, 10 ) );
//		addElement( new ComponentTextInput( "Name", changeNameHandler, _ani.name, WIDTH ) );
//		addElement( new ComponentTextArea( "Desc", changeDescHandler, _ani.desc ? _ani.desc : "No Description", WIDTH ) );
	
	//private function changeNameHandler(event:TextEvent):void { _ani.name = event.target.text; }
	//private function changeDescHandler(event:TextEvent):void { _ani.desc = event.target.text; }

/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.animation
{
	import com.voxelengine.worldmodel.animation.Animation;
	import flash.geom.Vector3D;
	import flash.net.FileReference;
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.GUI.VVPopup;
	import com.voxelengine.GUI.LanguageManager;
	import com.voxelengine.server.Network;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ModelInfo;
	import com.voxelengine.worldmodel.models.makers.ModelLoader;
	import com.voxelengine.worldmodel.models.types.Player;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.models.ModelMetadata;
	
	public class WindowAnimationDetail extends VVPopup
	{
		private const _TOTAL_BUTTON_PANEL_HEIGHT:int = 100;
		private var _modelKey:String;
	private static const WIDTH:int = 300;
	private var _ani:Animation;
	private var _create:Boolean;
		
		public function WindowAnimationDetail( $ani:Animation )
		{
			var title:String;
			if ( $ani ) 	title = LanguageManager.localizedStringGet( "Edit_Animation" );
			else			title = LanguageManager.localizedStringGet( "New_Animation" );
			super( title );	
		
			if ( $ani ) {
				_ani = $ani;
			}
			else {
				_create = true
				_ani = new Animation();
			}
			
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			
			addMetadataPanel();
			//addAnimationsPanel();
			//addSoundPanel();
			//addAttachmentPanel();
			
			addButtonPanel();
			
			display();
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
			
        }
		
		private function addButtonPanel():void {
			var panelParentButton:Panel = new Panel( width, _TOTAL_BUTTON_PANEL_HEIGHT );
			panelParentButton.layout.orientation = LayoutOrientation.VERTICAL;
			panelParentButton.padding = 2;
			addElement( panelParentButton );
			
			var saveAnimation:Button = new Button( LanguageManager.localizedStringGet( "Save_Animation" ));
			saveAnimation.addEventListener(UIMouseEvent.CLICK, saveAnimationHandler );
			//saveAnimation.width = pbWidth - 2 * pbPadding;
			panelParentButton.addElement( saveAnimation );
		}

		private function saveAnimationHandler(event:UIMouseEvent):void  {
			// TODO FIXME
			// all changes are automattically saved, that is bad...
		}
		private function addAttachmentPanel():void {
			var b:Box = new Box();
			addElement( b );
		}
		
		private function addMetadataPanel():void {
			var b:Box = new Box();
			addElement( b );
		}
		private function addAnimationsPanel():void {
			var b:Box = new Box();
			addElement( b );
		}
		private function addSoundPanel():void {
			var b:Box = new Box();
			addElement( b );
		}
		
	}
}