
package com.voxelengine.GUI.components {
import flash.geom.ColorTransform;
import flash.geom.Vector3D;
import org.flashapi.swing.color.Color;

import org.flashapi.swing.*
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.containers.*;
import org.flashapi.swing.plaf.spas.SpasUI;

import com.voxelengine.Globals;
import com.voxelengine.Log;

public class ComponentVector3D extends Box
{
	public function ComponentVector3D( $title:String, $s1Label:String, $s2Label:String, $s3Label:String, $vect:Vector3D )
	{
		super();
		width = 300;
		padding = 15;
		title = $title;
		borderStyle = BorderStyle.GROOVE;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		
		addSpinLabel( $s1Label
					, function($e:SpinButtonEvent):void { $vect.setTo( updateVal($e), $vect.y, $vect.z ); }
					, function($e:TextEvent):void       { $vect.setTo( int( $e.target.text ), $vect.y, $vect.z ); }
					, $vect.x.toFixed(0) );
		addSpinLabel( $s2Label
					, function($e:SpinButtonEvent):void { $vect.setTo( $vect.x, updateVal($e), $vect.z ); }
					, function($e:TextEvent):void       { $vect.setTo( $vect.x, int( $e.target.text ), $vect.z ); }
					, $vect.y.toFixed(0) );
		addSpinLabel( $s3Label
					, function($e:SpinButtonEvent):void { $vect.setTo( $vect.x, $vect.y, updateVal($e) ); }
					, function($e:TextEvent):void       { $vect.setTo( $vect.x, $vect.y, int( $e.target.text ) ); }
					, $vect.z.toFixed(0) );
					
		layout.orientation = LayoutOrientation.VERTICAL;
	}
	
	private function updateVal( $e:SpinButtonEvent ):int {
		var ival:int = int( $e.target.data.text );
		if ( "clickDown" == $e.type ) 	ival--;
		else 							ival++;
		$e.target.data.text = ival.toString();
		return ival;
	}
	
	private function addSpinLabel( label:String, clickHandler:Function, textChanged:Function, initialValue:String ):TextInput
	{
		var lbl:Label = new Label(label);
		lbl.width = 150;
		lbl.height = 20;
		lbl.textAlign = TextAlign.CENTER;
		
		var src:TextInput = new TextInput(initialValue);
		src.width = 50;
		src.height = 20;
		src.addEventListener( TextEvent.EDITED, textChanged );
		
		var sb:SpinButton = new SpinButton( 20, 20 );
		sb.addEventListener( SpinButtonEvent.CLICK_DOWN, clickHandler );
		sb.addEventListener( SpinButtonEvent.CLICK_UP, clickHandler );
		sb.data = src;

		var panel:Container = new Container( 300, 20 );
		panel.layout.orientation = LayoutOrientation.HORIZONTAL;
		
		panel.addElement( lbl );
		panel.addElement( src );
		panel.addElement( sb );
		addElement( panel );
		
		return src;
	}
}
}