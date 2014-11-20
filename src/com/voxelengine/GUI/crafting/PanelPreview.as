
package com.voxelengine.GUI.crafting {
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Globals;
	import com.voxelengine.GUI.PanelBase;
	import com.voxelengine.worldmodel.crafting.Recipe;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelPreview extends PanelBase
	{
		public function PanelPreview( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
		{
			super( $parent, $widthParam, $heightParam );
			
			addElement( new Label( "Preview" ) );
			if ( $recipe ) {
				var path:String = Globals.appPath + "assets/crafting/" + $recipe.preview;
				var image:Image = new Image( path, 128, 128 );
				addElement( image );
			}
		}
	}
}