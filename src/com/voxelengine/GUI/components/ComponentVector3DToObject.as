/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.components {
import flash.geom.ColorTransform;
import flash.geom.Vector3D;
import org.flashapi.swing.color.Color;

import org.flashapi.swing.*
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.containers.*;
import org.flashapi.swing.plaf.spas.VVUI;

import com.voxelengine.Globals;
import com.voxelengine.Log;

public class ComponentVector3DToObject extends Box
{
	public function ComponentVector3DToObject( $markDirty:Function
									 , $origUpdate:Function
									 , $title:String
	                                 , $s1Label:String
									 , $s2Label:String
									 , $s3Label:String
									 , $vect:Vector3D
									 , $width:int
									 , $changeFunction:Function = null
									 , $decimalPlaces:int = 0 )
	{
		super();
		width = $width;
		height = 25;
		padding = 0;
		paddingTop = 2;
		borderStyle = BorderStyle.NONE;
		backgroundColor = VVUI.DEFAULT_COLOR;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		autoSize = false;
		
		if ( null == $changeFunction )
			$changeFunction = ComponentVector3DToObject.updateVal;
		
		var lbl:Label = new Label($title);
		lbl.width = int(width/5);
		lbl.height = 20;
		lbl.textAlign = TextAlign.LEFT;
		addElement( lbl )
		
		addSpinLabel( $s1Label
					, function($e:SpinButtonEvent):void { $origUpdate( cnto( $changeFunction($e), $vect.y, $vect.z ) ); }
					, function($e:TextEvent):void       { $origUpdate( cnto( Number( $e.target.text ), $vect.y, $vect.z ) ); $markDirty() }
					, $vect.x.toFixed($decimalPlaces) );
		addSpinLabel( $s2Label
					, function($e:SpinButtonEvent):void { $origUpdate( cnto( $vect.x, $changeFunction($e), $vect.z ) );  }
					, function($e:TextEvent):void       { $origUpdate( cnto( $vect.x, Number( $e.target.text ), $vect.z ) ); $markDirty()  }
					, $vect.y.toFixed($decimalPlaces) );
		addSpinLabel( $s3Label
					, function($e:SpinButtonEvent):void { $origUpdate( cnto( $vect.x, $vect.y, $changeFunction($e) ) );  }
					, function($e:TextEvent):void       { $origUpdate( cnto( $vect.x, $vect.y, Number( $e.target.text ) ) ); $markDirty()  }
					, $vect.z.toFixed($decimalPlaces) );
	}
	
	// cnto = componentNumbersToObject
	private function cnto( $x:Number, $y:Number, $z:Number ):Object {
			return { x:$x, y:$y, z:$z };
	}
	private function componentIntToObject( $x:int, $y:int, $z:int ):Object {
			return { x:$x, y:$y, z:$z };
	}	
	//override public function get height () : Number { return super.height + 5; }	
	
	static private function updateVal( $e:SpinButtonEvent ):int {
		var ival:int = int( $e.target.data.text );
		if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival--;
		else 											ival++;
		$e.target.data.text = ival.toString();
		return ival;
	}
	
	private function addSpinLabel( label:String, clickHandler:Function, textChanged:Function, initialValue:String ):TextInput
	{
		var lbl:Label = new Label(label);
		lbl.width = 15;
		lbl.height = 20;
		lbl.textAlign = TextAlign.CENTER;
		
		var src:TextInput = new TextInput(initialValue);
		src.width = (width/4)-40;
		src.height = 20;
		src.addEventListener( TextEvent.EDITED, textChanged );
		
		//var sb:SpinButton = new SpinButton( 20, 18 );
		var sb:SpinButton = new SpinButton( 20, 20 );
		sb.addEventListener( SpinButtonEvent.CLICK_DOWN, clickHandler );
		sb.addEventListener( SpinButtonEvent.CLICK_UP, clickHandler );
		sb.data = src;

		var panel:Container = new Container( width/4, 20 );
		panel.layout.orientation = LayoutOrientation.HORIZONTAL;
		
		panel.addElement( lbl );
		panel.addElement( src );
		panel.addElement( sb );
		addElement( panel );
		
		return src;
	}
}
}