
package com.voxelengine.GUI
{
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.plaf.spas.SpasUI;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelBase extends Box
	{
		protected var _parent:PanelBase;
		protected const pbPadding:int = 5;
		
		public function PanelBase( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.GROOVE )
		{
			super( $widthParam, $heightParam );
			autoSize = true;
			//backgroundColor = 0xCCCCCC;
			backgroundColor = SpasUI.DEFAULT_COLOR;
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
		public function close():void {
			Log.out( "PanelBase.close for: " + this, Log.WARN );
		}
	}
}