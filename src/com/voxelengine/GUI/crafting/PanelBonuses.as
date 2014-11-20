
package com.voxelengine.GUI.crafting {
	import com.voxelengine.worldmodel.crafting.Bonus;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.GUI.PanelBase;	
	import com.voxelengine.worldmodel.crafting.Recipe;
	import com.voxelengine.GUI.VoxelVerseGUI;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelBonuses extends PanelBase
	{
		private const BOX_SIZE:int = 32;
		public function PanelBonuses( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
		{
			super( $parent, $widthParam, $heightParam );
			
			addElement( new Label( "Bonuses" ) );
			padding = 5;
			var optionals:Boolean;
			if ( $recipe ) {
				for each( var bonus:Bonus in $recipe.bonuses ) {
					optionals = bonus.optional;
					var lb:Label = new Label( VoxelVerseGUI.localizedStringGet( bonus.category ) + (bonus.optional ? "*" : "") );
					addElement( lb );
					var category:String = bonus.category.toUpperCase();

					var mb:Box;
					if ( Globals.MODIFIER_DAMAGE == category )
						mb = new BoxDamage( BOX_SIZE, BOX_SIZE );
					else if ( Globals.MODIFIER_SPEED == category )
						mb = new BoxSpeed( BOX_SIZE, BOX_SIZE );
					else if ( Globals.MODIFIER_DURABILITY == category )
						mb = new BoxDurability( BOX_SIZE, BOX_SIZE );
					else if ( Globals.MODIFIER_LUCK == category )
						mb = new BoxLuck( BOX_SIZE, BOX_SIZE );
					else {
						Log.out( "PanelMaterials - Unknown bonus type found in Recipe: " + $recipe.name, Log.WARN );
						mb = new Box( BOX_SIZE, BOX_SIZE );
					}
					
					
	//				mb.backgroundTexture = "assets/textures/blank.png";
					mb.dropEnabled = true;
					mb.borderStyle = BorderStyle.INSET;

					addElement( mb );
				}
				if ( optionals )
					addElement( new Label( "*=" + VoxelVerseGUI.localizedStringGet( "optional") ) );
			}
		}
	}
}