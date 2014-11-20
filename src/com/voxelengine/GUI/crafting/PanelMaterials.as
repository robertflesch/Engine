
package com.voxelengine.GUI.crafting {
	import com.voxelengine.worldmodel.crafting.Material;
	import com.voxelengine.worldmodel.crafting.Recipe;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
	import org.flashapi.swing.event.ListEvent;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	import org.flashapi.swing.dnd.DnDOperation;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.GUI.PanelBase;	
	import com.voxelengine.GUI.VoxelVerseGUI;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelMaterials extends PanelBase
	{
		private const BOX_SIZE:int = 64;
		public function PanelMaterials( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
		{
			super( $parent, $widthParam, $heightParam );
			
			addElement( new Label( VoxelVerseGUI.localizedStringGet( "Materials" ) ) );
			padding = 5;
			var optionals:Boolean;
			if ( $recipe ) {
				for each( var mat:Material in $recipe.materials ) {
					optionals = mat.optional;
					var lb:Label = new Label( "(" + mat.quantity + ") " + VoxelVerseGUI.localizedStringGet( mat.category ) + (mat.optional ? "*" : "") );
					addElement( lb );
					var category:String = mat.category.toUpperCase();
					var mb:Box;
					if ( Globals.CATEGORY_PLANT == category )
						mb = new BoxWood( BOX_SIZE, BOX_SIZE );
					else if ( Globals.CATEGORY_METAL == category )
						mb = new BoxMetal( BOX_SIZE, BOX_SIZE );
					else if ( Globals.CATEGORY_LEATHER == category )
						mb = new BoxLeather( BOX_SIZE, BOX_SIZE );
					else {
						Log.out( "PanelMaterials - Unknown material type found in Recipe: " + $recipe.name, Log.WARN );
						mb = new Box( BOX_SIZE, BOX_SIZE );
					}
						
					mb.dropEnabled = true;
					mb.addEventListener( DnDEvent.DND_DROP, onDrop );
					mb.borderStyle = BorderStyle.INSET;

					addElement( mb );
				}
				if ( optionals )
					addElement( new Label( "*=" + VoxelVerseGUI.localizedStringGet( "optional") ) );
			}
		}
		
		private function onDrop(e:DnDEvent):void 
		{
			Log.out( "PanelMaterials.onDrop" );
		}
	}
}