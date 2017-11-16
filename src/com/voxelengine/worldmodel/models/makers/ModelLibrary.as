/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.worldmodel.crafting.items.Pick;
import com.voxelengine.worldmodel.models.types.EditCursor;

import flash.utils.getDefinitionByName;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.*;
	import com.voxelengine.worldmodel.models.*;
	import com.voxelengine.worldmodel.weapons.*;
	import com.voxelengine.worldmodel.models.types.*;
    
    public class ModelLibrary 
    {
        public function ModelLibrary() {}
        
        public static function getAsset ( assetLinkageID : String ) : Class
        {
			{
                //noinspection BadExpressionStatementJS
                Pick;
				//noinspection BadExpressionStatementJS
				Projectile;
				//noinspection BadExpressionStatementJS
				Gun;
				//noinspection BadExpressionStatementJS
				Barrel;
				//noinspection BadExpressionStatementJS
				Stand;
				//noinspection BadExpressionStatementJS
				Trigger;
				//noinspection BadExpressionStatementJS
				Player;
				//noinspection BadExpressionStatementJS
				Avatar;
				//noinspection BadExpressionStatementJS
				VoxelModel;
				//noinspection BadExpressionStatementJS
				Engine;
				//noinspection BadExpressionStatementJS
				Bomb;
				//noinspection BadExpressionStatementJS
				Ship;
				//noinspection BadExpressionStatementJS
				Beast;
				//noinspection BadExpressionStatementJS
				Dragon;
				//noinspection BadExpressionStatementJS
				Propeller;
				//noinspection BadExpressionStatementJS
				Target;
				//noinspection BadExpressionStatementJS
				EditCursor;
			}
			//
			var asset:Class = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.models.types.VoxelModel" ) );
			try 
			{
				asset = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.models.types." + assetLinkageID ) );
			}
			catch ( error:Error )
			{
				try
				{
					asset = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.weapons." + assetLinkageID ) );
				}
				catch ( error:Error )
				{
					Log.out( "ModelLibrary.getAsset - ERROR - ERROR - ERROR: " + error, Log.ERROR );
				}
			}
			
            return asset;
        }
    }   
}

