/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.crafting {
import com.voxelengine.events.CraftingEvent;
import com.voxelengine.worldmodel.TypeInfo;

import org.flashapi.swing.*;
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.worldmodel.crafting.Recipe;
import com.voxelengine.events.CraftingItemEvent;

public class PanelPreview extends PanelBase
{
	private	var _damageLabel:Label;
	private	var _speedLabel:Label;
	private	var _durabilityLabel:Label;

	public function PanelPreview( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
	{
		super( $parent, $widthParam, $heightParam );

		CraftingItemEvent.addListener( CraftingItemEvent.STATS_UPDATED, onStatsUpdated );

		addElement( new Label( "Preview" ) );
		if ( $recipe ) {
			var path:String = $recipe.preview;
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

	override public function remove():void
	{
		CraftingItemEvent.removeListener( CraftingItemEvent.STATS_UPDATED, onStatsUpdated );
	}

	private function onStatsUpdated(e:CraftingItemEvent):void
	{
		var ci:Recipe = (_parent as PanelRecipe).recipe;
		if ( ci.hasMetRequirements() ) {
			_damageLabel.text = "Damage: " + ci.estimate( "damage" );
			_speedLabel.text = "Speed: " + ci.estimate( "speed" );
			_durabilityLabel.text = "Durability: " + ci.estimate( "durability" );
			CraftingItemEvent.create( CraftingItemEvent.REQUIREMENTS_MET, null );
		}
		else
		{
			_damageLabel.text = "Requirements not met";
			_speedLabel.text = "Add non optional materials";
			_durabilityLabel.text = "";
            CraftingItemEvent.create( CraftingItemEvent.REQUIREMENTS_MET, TypeInfo.typeInfo[100] );
		}


	}
}
}