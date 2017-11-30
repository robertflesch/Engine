/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.panels
{
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.plaf.spas.VVUI;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelBase extends Box
	{
		protected const HEIGHT_BUTTON_DEFAULT:int = 25;
		protected const WIDTH_BUTTON_DEFAULT:int = 180;

		protected var _parent:PanelBase;
		protected const pbPadding:int = 5;
		
		public function PanelBase( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.GROOVE )
		{
			super( $widthParam, $heightParam );
			autoSize = true;
			//backgroundColor = 0xCCCCCC;
			backgroundColor = VVUI.DEFAULT_COLOR;
			layout.orientation = LayoutOrientation.VERTICAL;
			padding = pbPadding - 1;
			_parent = $parent;
			//Log.out( "PanelBase constructed for: " + this, Log.WARN );
        }
		
		public function topLevelGet():PanelBase {
			if ( _parent )
				return _parent.topLevelGet();
			return this;	
		}
		
		public function recalc( width:Number, height:Number ):void {
			if ( _parent )
				_parent.recalc( width, height );
			else if ( width < $width || height < $height ) {
				resize( $width, $height );
			}
		}
		
		// Override if additional clean up is needed
        override public function remove():void {
			super.remove();
			//Log.out( "PanelBase.close for: " + this, Log.WARN );
		}
	}
}