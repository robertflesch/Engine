
package com.voxelengine.GUI.crafting {
	import com.voxelengine.events.CraftingItemEvent;
	import com.voxelengine.worldmodel.crafting.items.CraftedItem;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Globals;
	import com.voxelengine.GUI.PanelBase;
	import com.voxelengine.worldmodel.crafting.Recipe;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelPreview extends PanelBase
	{
		private	var _damageLabel:Label;
		private	var _speedLabel:Label;
		private	var _durabilityLabel:Label;
				
		public function PanelPreview( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
		{
			super( $parent, $widthParam, $heightParam );
			addEventListener(UIOEvent.REMOVED, onRemoved );
			
			Globals.craftingManager.addEventListener( CraftingItemEvent.STATS_UPDATED, onStatsUpdated );	
			
			addElement( new Label( "Preview" ) );
			if ( $recipe ) {
				var path:String = Globals.appPath + "assets/crafting/" + $recipe.preview;
				var image:Image = new Image( path, 128, 128 );
				addElement( image );
				_damageLabel = new Label( "Requirements not met", 128 );
				addElement( _damageLabel );
				_speedLabel = new Label( "Add non optional materials", 128 );
				addElement( _speedLabel );
				_durabilityLabel = new Label( "", 128 );
				addElement( _durabilityLabel );
			}
		}
		
		private function onRemoved(e:UIOEvent):void 
		{
			Globals.craftingManager.removeEventListener( CraftingItemEvent.STATS_UPDATED, onStatsUpdated );	
		}
		
		private function onStatsUpdated(e:CraftingItemEvent):void 
		{
			var ci:CraftedItem = (_parent as PanelRecipe).craftedItem;
			if ( ci.hasMetRequirements() ) {
				_damageLabel.text = "Damage: " + ci.estimate( "damage" );
				_speedLabel.text = "Speed: " + ci.estimate( "speed" );
				_durabilityLabel.text = "Durability: " + ci.estimate( "durability" );
			}
			else
			{
				_damageLabel.text = "Requirements not met";
				_speedLabel.text = "Add non optional materials";
				_durabilityLabel.text = "";
			}
			
			
		}
	}
}