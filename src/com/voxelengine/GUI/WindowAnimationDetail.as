
package com.voxelengine.GUI
{
import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.animation.Animation;

public class WindowAnimationDetail extends VVPopup
{
	private static const WIDTH:int = 300;
	
	private var _create:Boolean;
	private var _ani:Animation;
	
	public function WindowAnimationDetail( $ani:Animation )
	{
		var title:String;
		if ( $ani ) 	title = "Edit Animation";
		else			title = "New Animation";
		super( title );	
		
		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		//closeButtonEnabled = false; // this show it enabled, but doesnt allow it to be clicked
		//closeButtonActive = false;  // this greys it out, and doesnt allow it to be clicked
		
		if ( _ani ) {
			_ani = $ani;
		}
		else {
			_create = true
			_ani = new Animation();
		}
		
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
		
		display( 600, 20 );
	}
	
	private function changeNameHandler(event:TextEvent):void { _ani.name = event.target.text; }
	private function changeDescHandler(event:TextEvent):void { _ani.desc = event.target.text; }
}
}