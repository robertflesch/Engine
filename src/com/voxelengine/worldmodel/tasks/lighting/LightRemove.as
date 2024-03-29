/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.lighting
{
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LightEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.oxel.OxelBad;

/**
 * ...
 * @author Robert Flesch
 */
public class LightRemove extends LightTask
{
	static public function init():void {
		LightEvent.addListener( LightEvent.REMOVE, handleLightEventRemove );
	}

	static public function handleLightEventRemove( $le:LightEvent ):void {
		Log.out( "LightRemove.handleLightEventRemove - remove light id: " + $le.lightID );

		var lor:Oxel = LightTask.isValidOxel( $le );
		if ( !lor )
			return;

		lor.lighting.remove( $le.lightID );
		var alphaCountr:int;
		// walk thru the neighbors, if the no has less light then remove that light (just that or all lights?)
		for ( var facer:uint = Globals.POSX; facer <= Globals.NEGZ; facer++ ) {
			var nor:Oxel = lor.neighbor(facer);
			if ( OxelBad.INVALID_OXEL == nor )
				continue;

			if ( TypeInfo.hasAlpha( nor.type ) && nor.lighting ) {
				shineBackOnRemovedLight( lor, nor, facer, $le.lightID );
				alphaCountr++;
			}
		}
		addTask( $le.instanceGuid, $le.gc, $le.lightID );
		// Now relight the oxel that the light was removed from using the new values.
		if ( 0 < alphaCountr ) {
			var lights:Vector.<uint> = lor.lighting.lightIDNonDefaultUsedGet();
			for each ( var lightsOnThisOxel:uint in lights ) {
				var le:LightEvent = new LightEvent( LightEvent.ADD, $le.instanceGuid, lor.gc, lightsOnThisOxel );
				Globals.g_app.dispatchEvent( le );
			}
		}
	}

	static private function addTask( $instanceGuid:String, $gc:GrainCursor, $lightID:uint ):void {
		//Log.out( "Light.addTask: for gc: " + $gc.toString() + "  taskId: " + $gc.toID() );
		var lt:LightRemove = new LightRemove( $instanceGuid, $gc, $lightID, $gc.toID(), $gc.grain );
		lt.selfOverride = true;
		Globals.taskController.addTask( lt );
	}

	// NEVER use this, use the static function
	public function LightRemove( $instanceGuid:String, $gc:GrainCursor, $lightID:uint, $taskType:String, $taskPriority:int ):void {
		super( $instanceGuid, $gc, $lightID, $taskType, $taskPriority );
	}


	/**
	 * @param $taskType The Task type.
	 * @param $taskPriority The priority of the task, 0 is the highest priority, int.MAX_VALUE is the lowest.
	 */
	private function remove( $o:Oxel ):void {
		LightRemove.addTask( _guid, $o.gc, lightID );
	}

	override public function start():void {
		super.start();

		var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( _guid );
		if ( vm ) {
			var lo:Oxel = vm..modelInfo.oxelPersistence.oxel.childFind( _gc );
			if ( LightTask.valid( lo ) ) {
				lo.lighting.remove( lightID );
				removeFromNeighbors( lo );
			}
			else
				Log.out( "LightRemove.start - valid failed", Log.ERROR );
		}
		else
			Log.out( "LightRemove.start - VoxelModel not found: " + _guid, Log.ERROR );

		super.complete();
	}


	private function removeFromNeighbors( $lo:Oxel ):void {

		//Log.out( "LightRemove.spreadToNeighbors - $lo: " + $lo.toStringShort() + "  brightness: " + $lo.brightness.toString() );
		for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ )
		{
			var no:Oxel = $lo.neighbor(face);

			if ( OxelBad.INVALID_OXEL == no )
				continue;

			if ( no.childrenHas() )
				removeFromChildren( no, face );
			else if ( no.lighting )
				terminalLightRemove( no, face );
//				else
//					Log.out( "LightRemove.spreadToNeighbors - Light doesnt exist: " + lightID );
		}
	}

	// This just applies to the light oxel that has been removed.
	static private function shineBackOnRemovedLight( $lo:Oxel, $no:Oxel, $face:uint, excludedID:uint ):void {
		var lightIDs:Vector.<uint> = $no.lighting.lightIDNonDefaultUsedGet();
		// Default ID excluded
		// Adds the light from our alpha neighbor back into the recently emptied space.
		for each ( var oxelLightID:uint in lightIDs ) {
			if ( excludedID == oxelLightID )
				continue;
			$lo.lighting.influenceAdd( oxelLightID, $no.lighting, Oxel.face_get_opposite( $face ), false, $lo.gc.size() );
		}
	}

	private function removeFromChildren( $no:Oxel, $face:int ):void {
		var of:int = Oxel.face_get_opposite( $face );
		var dchild:Vector.<Oxel> = $no.childrenForDirection( of );
		for ( var childIndex:int = 0; childIndex < 4; childIndex++ )
		{
			var noChild:Oxel = dchild[childIndex];

			if ( noChild.childrenHas() )
				removeFromChildren( noChild, $face );
			else
				terminalLightRemove( noChild, $face );
		}
	}

	private function terminalLightRemove( $o:Oxel, $face:int ):void {

		if ( null == $o.lighting ) {
			Log.out( "LightRemove.terminalLightRemove - STOPPING NO BRIGHTNESS" );
			return;
		}

		//Log.out( "LightRemove.terminal gc: " + $o.gc.toString() );
		if ( $o.lighting.remove( lightID ) ) {
			if ( $o.quads ) // this oxel has faces which were lit
				rebuildFaces( $o );

			if ( TypeInfo.hasAlpha( $o.type ) ) // this oxel transmits light
				remove( $o );
		}
	}

	static private function rebuildFace( $o:Oxel, $faceFrom:int ):void {

		if ( $o.quads && 0 < $o.quads.length )
			$o.quadRebuild( Oxel.face_get_opposite( $faceFrom ) );
	}

	static private function rebuildFaces( $o:Oxel ):void {

		if ( $o.quads && 0 < $o.quads.length )
			$o.facesBuild( true );
			$o.quadsBuild( true );
	}

	/*
	static private function pathToParent( $o:Oxel, $face:uint, targetGrainSize:uint ):Vector.<uint> {
		var childIDPath:Vector.<uint> = new Vector.<uint>;
		var gct:GrainCursor = GrainCursorPool.poolGet( $o.gc.bound );
		gct.copyFrom( $o.gc ); // light oxel location
		gct.move( $face ); // now move it to location that we need the brightness from
		// get a vector with the parent/child id relationships
		while ( gct.grain < targetGrainSize ) {
			childIDPath.push( gct.childId() );
			gct.become_parent();
		}
		GrainCursorPool.poolDispose( gct );

		return childIDPath;
	}

	static private function childBrightnessGet( $lob:Brightness, path:Vector.<uint>, $bt:Brightness ):void {

		var btp:Brightness = BrightnessPool.poolGet();
		btp.copyFrom( $lob );
		var childIDPathIndex:int = path.length - 1;
		for ( var i:int = childIDPathIndex ; i >= 0;  i-- )
		{
			btp.childGetAllLights( path[i], $bt );
			btp.copyFrom( $bt );
		}
		$bt.copyFrom( btp );
		BrightnessPool.poolReturn( btp );
	}
	*/

}
}

import com.voxelengine.worldmodel.oxel.GrainCursor;

internal class BlockageCandidates {
public function BlockageCandidates( $guid:String, $gc:GrainCursor, $ID:uint ):void {
	guid = $guid;
	gc = $gc;
	ID = $ID;
}
public var guid:String;
public var gc:GrainCursor;
public var ID:uint;
}