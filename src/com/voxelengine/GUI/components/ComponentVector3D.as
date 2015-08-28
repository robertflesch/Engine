
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
	public function ComponentVector3D( $markDirty:Function
									 , $title:String
	                                 , $s1Label:String
									 , $s2Label:String
									 , $s3Label:String
									 , $vect:Vector3D
									 , $changeFunction:Function = null
									 , $decimalPlaces:int = 0 )
	{
		super();
		width = 300;
		height = 30;
		padding = 5;
		paddingTop = 8
		title = $title;
		borderStyle = BorderStyle.GROOVE;
		backgroundColor = SpasUI.DEFAULT_COLOR;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
		if ( null == $changeFunction )
			$changeFunction = ComponentVector3D.updateVal;
		
		addSpinLabel( $s1Label
					, function($e:SpinButtonEvent):void { $vect.setTo( $changeFunction($e), $vect.y, $vect.z ); }
					, function($e:TextEvent):void       { $vect.setTo( int( $e.target.text ), $vect.y, $vect.z ); $markDirty() }
					, $vect.x.toFixed($decimalPlaces) );
		addSpinLabel( $s2Label
					, function($e:SpinButtonEvent):void { $vect.setTo( $vect.x, $changeFunction($e), $vect.z );  }
					, function($e:TextEvent):void       { $vect.setTo( $vect.x, int( $e.target.text ), $vect.z ); $markDirty()  }
					, $vect.y.toFixed($decimalPlaces) );
		addSpinLabel( $s3Label
					, function($e:SpinButtonEvent):void { $vect.setTo( $vect.x, $vect.y, $changeFunction($e) );  }
					, function($e:TextEvent):void       { $vect.setTo( $vect.x, $vect.y, int( $e.target.text ) ); $markDirty()  }
					, $vect.z.toFixed($decimalPlaces) );
	}
	
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
		src.width = 50;
		src.height = 20;
		src.addEventListener( TextEvent.EDITED, textChanged );
		
		var sb:SpinButton = new SpinButton( 20, 18 );
		sb.addEventListener( SpinButtonEvent.CLICK_DOWN, clickHandler );
		sb.addEventListener( SpinButtonEvent.CLICK_UP, clickHandler );
		sb.data = src;

		var panel:Container = new Container( 90, 20 );
		panel.layout.orientation = LayoutOrientation.HORIZONTAL;
		
		panel.addElement( lbl );
		panel.addElement( src );
		panel.addElement( sb );
		addElement( panel );
		
		return src;
	}
}
}