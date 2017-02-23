/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.*;
import com.voxelengine.events.TriggerEvent;
import com.voxelengine.pools.GrainCursorPool;
import flash.display3D.Context3D;
import flash.geom.Vector3D;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;

/**
 * ...
 * @author Robert Flesch - RSF 
 * The world model holds the active oxels
 */
public class Trigger extends VoxelModel 
{
	private var _inside:Boolean = false;
	
	public function Trigger( $ii:InstanceInfo ) { 
		super( $ii );
	}

	static public function buildExportObject( obj:Object ):Object {
		VoxelModel.buildExportObject( obj )
		return obj;
	}
	
	override public function update(context:Context3D, elapsedTimeMS:int):void {
		super.update(context, elapsedTimeMS);
		
		if ( !VoxelModel.controlledModel || !modelInfo.oxelPersistance || 0 == modelInfo.oxelPersistance.oxelCount )
			return;
			
		var wsPositionCenter:Vector3D = VoxelModel.controlledModel.instanceInfo.worldSpaceMatrix.transformVector( VoxelModel.controlledModel.instanceInfo.center );
			
		var msPos:Vector3D;
		if ( instanceInfo.controllingModel )
		{
			msPos = instanceInfo.controllingModel.worldToModel( wsPositionCenter );
			msPos = msPos.subtract( this.instanceInfo.positionGet );
		}
		else
			msPos = worldToModel( wsPositionCenter );

		var ox:Oxel = modelInfo.oxelPersistance.oxel;
		var gct:GrainCursor = GrainCursorPool.poolGet( ox.gc.bound );
		gct.getGrainFromVector( msPos, 0 );
		if ( gct.is_inside( ox.gc ) ) {
			// Only want to dispatch the event once per transition
			if ( !_inside ) {
				_inside = true;
				//Log.out( "Trigger.update - INSIDE" );
				TriggerEvent.dispatch( new TriggerEvent( TriggerEvent.INSIDE, instanceInfo.instanceGuid ) );
			}
		} 
		else {
			if ( _inside ) {
				_inside = false;
				//Log.out( "Trigger.update - OUTSIDE" );
				TriggerEvent.dispatch( new TriggerEvent( TriggerEvent.OUTSIDE, instanceInfo.instanceGuid ) );
			}
		}
		GrainCursorPool.poolDispose( gct );
	}
}
}

/*
			var selected:Boolean = VoxelModel.selectedModel == this ? true : false;
			if ( selected )
			{
				// the oxel.write prunes all of the children
				// so we have to save the byte array from what was inside.
				if ( !_was_selected && null == _ba )
				{
					// this is a raw byte array, just oxel data.
					_ba = ox.toByteArray(_ba);
				}
				
				var loco:GrainCursor = GrainCursorPool.poolGet(ox.gc.bound);
				// this prunes the children oxel
				ox.write( instanceInfo.instanceGuid, loco.set_values( 0, 0, 0, grain ), TypeInfo.LEAF, true );
				GrainCursorPool.poolDispose( loco );
				ox.facesSetAll();
				ox.faces_rebuild( instanceInfo.instanceGuid );
				ox.quadsBuild();
				_was_selected = true;
			}
			else if ( _was_selected )
			{
				_was_selected = false;
				var loco1:GrainCursor = GrainCursorPool.poolGet(ox.gc.bound);
				Log.out( "Trigger.update - How to do this with new oxel model?", Log.ERROR );
				// this prunes the children oxel
				//loco1.set_values( 0, 0, 0, oxel.gc.grain );
				//_ba.position = 0;
				//oxel.readData( null, loco1, _ba, statisics );
				//GrainCursorPool.poolDispose( loco1 );
				//// this cleans up outside, but saddle is gone
				//oxel.faces_rebuild( instanceInfo.instanceGuid );
				//oxel.faces_clean_all_face_bits();
				//oxel.dirty = true;
				//oxel.quadsBuild();
			}
			*/