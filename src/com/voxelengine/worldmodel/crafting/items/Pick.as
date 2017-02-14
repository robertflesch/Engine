/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.crafting.items {
	import com.voxelengine.events.CraftingItemEvent;
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.crafting.Material;
	import com.voxelengine.worldmodel.crafting.Recipe;

	/**
	 * ...
	 * @author Bob
	 */
	public class Pick extends CraftedItem
	{
		public function Pick( $recipe:Recipe ) {
			super( $recipe );
		}
	}
}