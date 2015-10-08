/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.oxel
{
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.events.LightEvent;
import com.voxelengine.renderer.Chunk;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import flash.display3D.Context3D;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.geom.Matrix3D;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import com.developmentarc.core.tasks.tasks.ITask;
import com.developmentarc.core.tasks.groups.TaskGroup;


import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ImpactEvent;
import com.voxelengine.utils.Plane;
//	import com.voxelengine.renderer.VertexManager;
import com.voxelengine.renderer.Quad;
import com.voxelengine.renderer.shaders.Shader;
import com.voxelengine.pools.*;
import com.voxelengine.worldmodel.InteractionParams;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.models.ModelStatisics;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.tasks.landscapetasks.TreeGenerator;
import com.voxelengine.worldmodel.tasks.lighting.LightRemove;
import com.voxelengine.worldmodel.tasks.lighting.LightAdd;
import com.voxelengine.worldmodel.tasks.flowtasks.Flow;
import com.voxelengine.worldmodel.tasks.flowtasks.FlowFlop;

/**
 * ...
 * @author Robert Flesch RSF Oxel - An OctTree / Voxel - model
 */
public class Oxel extends OxelBitfields
{
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     Static Variables
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private static const OXEL_CHILD_COUNT:int = 8;
	
	private static		const ALL_NEGZ_CHILD:uint						= 0x0f;
	private static		const ALL_POSZ_CHILD:uint						= 0xf0;
	private static		const ALL_NEGY_CHILD:uint						= 0x33;
	private static		const ALL_POSY_CHILD:uint						= 0xcc;
	private static		const ALL_NEGX_CHILD:uint						= 0x55;
	private static		const ALL_POSX_CHILD:uint						= 0xaa;
	
	private static		const MAX_BUILD_TIME:int                        = 14000;
	
	static private 		var _s_scratchGrain:GrainCursor 				= new GrainCursor();
	static private 		var _s_scratchVector:Vector3D 					= null;

	// How do I manage this for unique values for each face?
	static private 		var _s_nodes:int 								= 0;
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     Member Variables
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private var _childCount:uint;
	private var _gc:GrainCursor; 			// Object that give us our location allocates memory for the grain
	private var _parent:Oxel;				// passed to use when created
	private var _children:Vector.<Oxel>; 	// These are created when needed
	private var _neighbors:Vector.<Oxel>;	// 8 children but 6 neighbors, created when needed
	private var _quads:Vector.<Quad>;		// Quads that are drawn on card, created when needed
	private var _chunk:Chunk; 	// created when needed
	private var _lighting:Lighting;
	private var _flowInfo:FlowInfo; 		// used to count up and out in flowing oxel ( only uses 2 bytes, down, out )
	
	override public function set dirty( $isDirty:Boolean ):void { 
		// mark oxel as dirty using the super function which just sets the dirty bit.
		super.dirty = $isDirty;
		// also mark parent as dirty recursively until you hit an oxel that has a chunk.
		// so if null == chunk, mark your parent oxel dirty
		// but if chunk is not null, just mark the oxel AND chunk dirty
		if ( true == $isDirty ) {
			if ( _parent && !_parent.dirty && null == _chunk ) 
				_parent.dirty = true;
				
			var ch:Chunk = chunkGet(); // Get the parent chunk
			if ( ch ) 
				ch.dirtySet( type );
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     Getters/Setters
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function get quads():Vector.<Quad> { return _quads; }
	public function quad( $face:int ):Quad { return _quads[$face]; }
	public function get children():Vector.<Oxel> { return _children; }

	// Type is stored in the lower 2 bytes ( or 1 ) of the _data variable
	// TODO, I am using 16 bits here, I think the dirty faces are using some of these already.
	// need to reduce it down to 10 bits
	override public function set type( $val:int ):void { 
		// Make sure its not the same as current type
		if ( $val != type ) 
		{
			if ( TypeInfo.INVALID == $val )
			{
				Log.out( "Oxel.type - Trying to set type on oxel to INVALID" );
				return;
			}
			if ( childrenHas() && TypeInfo.AIR != $val )
				Log.out( "Oxel.type - Trying to set type on oxel with children" );
				
			// uses the OLD type since _data has not been set yet
			if ( TypeInfo.AIR != type )
				chunkRemoveOxel();
			
			super.type = $val;
			
			if ( TypeInfo.AIR == $val ) 
			{
				facesCleanAllFaceBits();
				// Todo - this CAN leave behind empty oxels, need to add some kind of flag or check for them.
				//if ( _parent ) 
				//	return _parent.mergeRecursive()					
			}
			else
				facesMarkAllDirty();
		}
	}

	public function get gc():GrainCursor { return _gc; }
	public function set gc(val:GrainCursor):void { _gc = val; throw new Error( "Oxel - trying to assign new GC to existing" ); }
	
	// Using a static here since I dont want to carry around the huge guid string with each oxel
	// Am I being penny wise and pound foolish??? RSF
	
	static public function get nodes():int { return _s_nodes; }
	static public function set nodes(value:int):void { _s_nodes = value; }
	
	public function get flowInfo():FlowInfo { return _flowInfo; }
	public function set flowInfo(value:FlowInfo):void { _flowInfo = value; }
	
	public function get lighting():Lighting { return _lighting; }
	public function set lighting(value:Lighting):void { _lighting = value; }
	
	public function get parent():Oxel { return _parent; }
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     End Online liners
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function chunkGet():Chunk { return _chunk ? _chunk : _parent ? _parent.chunkGet() : null; }
	public function set chunk( $chunk:Chunk ):void 	{ _chunk = $chunk; }

	// This defines a one (1) meter cube in world
	public function size_in_world_coordinates():uint { return GrainCursor.get_the_g0_size_for_grain(gc.grain); }
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//     Member Functions 
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
//		public function get isLight():Boolean { return TypeInfo.typeInfo[type].lightInfo.lightSource; }
	
	
	public function get childCount():uint  						{ return _childCount; }
	public function set childCount(value:uint):void { 
		if ( _parent )
			_parent.childCount = value; 
		_childCount += value;	
	}
	
	
	// Intentionally empty, since these are allocated enmase in pool
	public function Oxel() {
	}

	static public function validLightable( $o:Oxel ):Boolean {
		
		if ( Globals.BAD_OXEL == $o ) // This is expected, if oxel is on edge of model
			return false;
		
		if ( !$o.lighting ) { // does this oxel already have a brightness?
			$o.lighting = LightingPool.poolGet( Lighting.defaultBaseLightAttn );
			$o.lighting.materialFallOffFactor = TypeInfo.typeInfo[$o.type].lightInfo.fallOffFactor;
		}

		return true;
	}
	
	static public function initializeRoot( $grainBound:int, $baseLightLevel:int ):Oxel
	{
		try {
			var gct:GrainCursor = GrainCursorPool.poolGet( $grainBound )
			gct.grain = $grainBound;
			var oxel:Oxel = OxelPool.poolGet();
			oxel.initialize(null, gct, 0, TypeInfo.AIR);
			GrainCursorPool.poolDispose( gct );
			
			oxel.lighting = LightingPool.poolGet( $baseLightLevel );
			Lighting.defaultBaseLightAttn = $baseLightLevel;
		}
		catch (e:Error) {
			Log.out( "Oxel.initialize_root_oxel - grain: " + oxel.gc.grain );					
		}
		return oxel;
		//Log.out( "VoxelModel.initialize_root_oxel - instanceInfo.guid: " + instanceInfo.guid + " grain: " + gc.grain + "(" + oxel.size_in_world_coordinates() + ") out of " + Globals.Info[type].name );					
	}
	
	// This is used to initialize all oxel nodes that are read from the byte array
	public function initialize( $parent:Oxel, $gc:GrainCursor, $data:uint, $type:uint ):void {

		_parent = $parent;
		dataRaw( $data, $type );
		_gc = GrainCursorPool.poolGet( $gc.bound );
		_gc.copyFrom( $gc );
		
		// Since this is from byteArray, I dont need to perform operations on the chunks.
		super.dirty = true;
		
		if ( TypeInfo.flowable( type ) )
		{
			if ( $parent && $parent.flowInfo )
				flowInfo = $parent.flowInfo.clone();
			else
				flowInfo = TypeInfo.typeInfo[type].flowInfo.clone();
		}
	}
	

	public function validate():void
	{
		// validate gc?
		if ( childrenHas() )
		{
			if ( TypeInfo.AIR != type )
				throw new Error( "Oxel.validate - Bad type for parent" );
			// what else needs to be true for a parent?	
			for each ( var child:Oxel in children )
			{
				if ( null == child )
					throw new Error( "Oxel.validate - null child" );
				
				child.validate();
			}
		}
		else
		{
			// type is valid
			// flow for correct types
			// brightness if needed
			Log.out("Oxel.validate - need checks" );
		}
	}
	
	// release all vertex buffer assests and send back to the pool
	public function release():void	{
		//trace( "Oxel.release" + gc.toString() );

		if ( _flowInfo ) { 
			FlowPool.poolReturn( _flowInfo );
			_flowInfo = null;
		}
		if ( _lighting ) { 
			LightingPool.poolReturn( _lighting );
			_lighting = null;
		}
		
		// kill any existing family, you can be parent type OR physical type, not both
		if ( childrenHas() )
		{
			// If there are children, then the neighbors might point to the children
			// Since they are being deleted, we have to make sure any pointers to them are removed.
			childrenPrune();
		}
		
		// removes all quad and the quads vector
		// removed the brightness
		chunkRemoveOxel();
		
		//if ( _chunk )
		//{
			//_chunk.release();
			//_chunk = null;
		//}

		if ( gc )
		{
			GrainCursorPool.poolDispose( gc );
			_gc = null;
		}
		
		resetData();
		_parent = null;
		if ( _neighbors )
		{
			NeighborPool.poolDispose( _neighbors );
			_neighbors = null;
		}
		OxelPool.poolDispose( this );
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Children function START
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function childGetOrCreate( $gc:GrainCursor ):Oxel {
		if ( !$gc.is_inside( gc ) )
			return Globals.BAD_OXEL;
			
		if ( $gc.is_equal( gc ) )
			return this;
			
		if ( !childrenHas() )
		{
			// become octa-mom
			childrenCreate();
		}
		
		for each ( var child:Oxel in _children )
		{	
			if ( $gc.is_equal( child.gc ) )
				return child;
			if ( $gc.is_inside( child.gc ) )
				return child.childGetOrCreate( $gc );
		}

		return Globals.BAD_OXEL;
	}

	// find locates a oxel within a tree
	// return can be 
	// 1) the oxel bring searched for ( is_equal )
	// 2) parent oxel that contains the searched for oxel ( is_inside )
	// 3) BAD_OXEL - not found for some reason
	
	// this could be called childGetClosest
	[inline]
	public function childFind( $gc:GrainCursor ):Oxel {
		if ( $gc.grain > gc.grain )
		{
			throw new Error("Looking for a larger grain within a smaller grain");
			return Globals.BAD_OXEL;
		}
			
		if ( $gc.is_equal( gc ) ) 
			return this;

		if ( 0 == gc.grain || $gc.grain == gc.grain )
			return Globals.BAD_OXEL;
		
		for each ( var child:Oxel in _children ) 
		{
			if ( $gc.is_equal( child.gc ) )
				return child;
			if ( $gc.is_inside( child.gc ) ) 
				return child.childFind( $gc );
		}
		
		// $gc is inside of a grain that doesnt have children at that level, so return the topmost grain that holds that child
		if ( $gc.is_inside( gc ) )
			return this;

		return Globals.BAD_OXEL;
	}

	public function childrenForKittyCorner( $face:int, $af:int ):Object {
		var oxelPair:Object = new Object();
		
		if ( Globals.POSX == $face ) {
			if ( Globals.POSY == $af ) {
				oxelPair.a = children[0];
				oxelPair.b = children[4];
			}
			else if ( Globals.NEGY == $af ) {
				oxelPair.a = children[2];
				oxelPair.b = children[6];
			}
			else if ( Globals.POSZ == $af ) {
				oxelPair.a = children[0];
				oxelPair.b = children[2];
			}
			else if ( Globals.NEGZ == $af ) {
				oxelPair.a = children[4];
				oxelPair.b = children[6];
			}
		}
		else if ( Globals.NEGX == $face ) {
			if ( Globals.POSY == $af ) {
				oxelPair.a = children[1];
				oxelPair.b = children[5];
			}
			else if ( Globals.NEGY == $af ) {
				oxelPair.a = children[3];
				oxelPair.b = children[7];
			}
			else if ( Globals.POSZ == $af ) {
				oxelPair.a = children[3];
				oxelPair.b = children[1];
			}
			else if ( Globals.NEGZ == $af ) {
				oxelPair.a = children[7];
				oxelPair.b = children[5];
			}
		}
		else if ( Globals.POSY == $face ) {
			if ( Globals.POSX == $af ) {
				oxelPair.a = children[0];
				oxelPair.b = children[4];
			}
			else if ( Globals.NEGX == $af ) {
				oxelPair.a = children[1];
				oxelPair.b = children[4];
			}
			else if ( Globals.POSZ == $af ) {
				oxelPair.a = children[4];
				oxelPair.b = children[5];
			}
			else if ( Globals.NEGZ == $af ) {
				oxelPair.a = children[0];
				oxelPair.b = children[1];
			}
		}
		else if ( Globals.NEGY == $face ) {
			if ( Globals.POSX == $af ) {
				oxelPair.a = children[2];
				oxelPair.b = children[6];
			}
			else if ( Globals.NEGX == $af ) {
				oxelPair.a = children[3];
				oxelPair.b = children[7];
			}
			else if ( Globals.POSZ == $af ) {
				oxelPair.a = children[2];
				oxelPair.b = children[3];
			}
			else if ( Globals.NEGZ == $af ) {
				oxelPair.a = children[6];
				oxelPair.b = children[7];
			}
		}
		else if ( Globals.POSZ == $face ) {
			if ( Globals.POSX == $af ) {
				oxelPair.a = children[0];
				oxelPair.b = children[2];
			}
			else if ( Globals.NEGX == $af ) {
				oxelPair.a = children[1];
				oxelPair.b = children[3];
			}
			else if ( Globals.POSY == $af ) {
				oxelPair.a = children[0];
				oxelPair.b = children[1];
			}
			else if ( Globals.NEGY == $af ) {
				oxelPair.a = children[2];
				oxelPair.b = children[3];
			}
		}
		else if ( Globals.NEGZ == $face ) {
			if ( Globals.POSX == $af ) {
				oxelPair.a = children[5];
				oxelPair.b = children[7];
			}
			else if ( Globals.NEGX == $af ) {
				oxelPair.a = children[4];
				oxelPair.b = children[6];
			}
			else if ( Globals.POSY == $af ) {
				oxelPair.a = children[4];
				oxelPair.b = children[5];
			}
			else if ( Globals.NEGY == $af ) {
				oxelPair.a = children[6];
				oxelPair.b = children[7];
			}
		}
		return oxelPair;
	}
	
	// this get the child in that direction whether it exists or not. if not makes them
	public function childGetFromDirection( $dir:int, $level:int, opposite:Boolean ):Oxel {
		
		if ( !childrenHas() )
			childrenCreate();

		if ( opposite )
		{
			if ( 0 == $level )
			{
				if ( Globals.POSX == $dir )
					return _children[5];
				else if ( Globals.NEGX == $dir )
					return _children[0];
				else if ( Globals.POSZ == $dir )
					return _children[4];
				else if ( Globals.NEGZ == $dir )
					return _children[1];
			}
			else
			{
				if ( Globals.POSX == $dir )
					return _children[6];
				else if ( Globals.NEGX == $dir )
					return _children[3];
				else if ( Globals.POSZ == $dir )
					return _children[7];
				else if ( Globals.NEGZ == $dir )
					return _children[2];
			}
		}
		else 
		{
			if ( 0 == $level )
			{
				if ( Globals.POSX == $dir )
					return _children[1];
				else if ( Globals.NEGX == $dir )
					return _children[4];
				else if ( Globals.POSZ == $dir )
					return _children[5];
				else if ( Globals.NEGZ == $dir )
					return _children[0];
			}
			else
			{
				if ( Globals.POSX == $dir )
					return _children[3];
				else if ( Globals.NEGX == $dir )
					return _children[6];
				else if ( Globals.POSZ == $dir )
					return _children[7];
				else if ( Globals.NEGZ == $dir )
					return _children[2];
			}
		}
			
		return Globals.BAD_OXEL;
	}

	public function childrenForDirection( dir:int ):Vector.<Oxel> {
		
		if ( !childrenHas() )
			childrenCreate();

		var childrenDirectional:Vector.<Oxel> = new Vector.<Oxel>;
		var mask:uint = 0;
		if      ( Globals.POSX == dir )	mask = ALL_POSX_CHILD
		else if ( Globals.NEGX == dir ) mask = ALL_NEGX_CHILD
		else if ( Globals.POSY == dir ) mask = ALL_POSY_CHILD
		else if ( Globals.NEGY == dir ) mask = ALL_NEGY_CHILD
		else if ( Globals.POSZ == dir ) mask = ALL_POSZ_CHILD
		else if ( Globals.NEGZ == dir ) mask = ALL_NEGZ_CHILD

		for ( var i:int = 0; i < OXEL_CHILD_COUNT; i++)
		{
			if( mask & ( 1 << i ) ) // is bit i set
				childrenDirectional.push( _children[i] );
		}
		
		return childrenDirectional;
	}
	
	// Get just the IDs of the children in that direction, used in getting brightness
	static public function childIDsForDirection( dir:int ):Vector.<uint> {
		
		var childIDsDirectional:Vector.<uint> = new Vector.<uint>;
		var mask:uint = 0;
		if      ( Globals.POSX == dir )	mask = ALL_POSX_CHILD
		else if ( Globals.NEGX == dir ) mask = ALL_NEGX_CHILD
		else if ( Globals.POSY == dir ) mask = ALL_POSY_CHILD
		else if ( Globals.NEGY == dir ) mask = ALL_NEGY_CHILD
		else if ( Globals.POSZ == dir ) mask = ALL_POSZ_CHILD
		else if ( Globals.NEGZ == dir ) mask = ALL_NEGZ_CHILD

		for ( var i:int = 0; i < OXEL_CHILD_COUNT; i++)
		{
			if( mask & ( 1 << i ) ) // is bit i set
				childIDsDirectional.push( i );
		}
		
		return childIDsDirectional;
	}
	
	public function childrenHas():Boolean { return null != _children; }
	
	// this releases the children
	public function childrenPrune():void {
		if ( null != _children )
		{
			for  ( var i:int = 0; i < OXEL_CHILD_COUNT; i++ ) 
			{
				if ( children[i] )
				{
					children[i].release();
					children[i] = null;
				}
			}
			
			ChildOxelPool.poolReturn( _children );
			_children = null;
		}
		
		parentClear();
	}
	
	public function childrenCreate( $invalidateNeighbors:Boolean = true ):void {
		if ( childrenHas() )
		   return;

		//trace( "childrenCreate to grain: " + gc.grain+ " (" + gc.size() + ") to grain: " + (gc.grain- 1) + );
		_children = ChildOxelPool.poolGet();
		var gct:GrainCursor = GrainCursorPool.poolGet(root_get().gc.bound );
		facesClearAll();

		for ( var i:int = 0; i < OXEL_CHILD_COUNT; i++ )
		{
			_children[i]  = OxelPool.poolGet();
			gct.copyFrom( gc );
			gct.become_child( i );   
			_children[i].initialize( this, gct, 0, type );
			// use the super so you dont start a flow event on flowable types.
			// No longer used, not sure if above comment is valid.
			//super.facesMarkAllDirty();
			_children[i].facesMarkAllDirty();
			
			if ( _lighting )
			{
				_children[i].lighting = LightingPool.poolGet( Lighting.defaultBaseLightAttn );
				lighting.childGetAllLights( gct.childId(), _children[i].lighting );
				// child should attenuate light at same rate.
				_children[i].lighting.materialFallOffFactor = lighting.materialFallOffFactor;
				_children[i].lighting.color = lighting.color;
			}
			// Special case for grass, leave upper oxels as grass.
			if ( TypeInfo.GRASS == type && ( 0 == gct.grainY % 2 ) )
				_children[i].type = TypeInfo.DIRT;
		}

		this.parentMarkAs();
		// Dont do this when generating terrain
		if ( $invalidateNeighbors )
			this.neighborsInvalidate();
		this.type = TypeInfo.AIR;
		this.dirty = true;

		GrainCursorPool.poolDispose( gct );
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Children function END
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// This only writes into empty voxel.
	public function write_empty( $instanceGuid:String, $gc:GrainCursor, $type:int ):Boolean {
		// have we arrived?
		if ( $gc.is_equal( gc ) )
		{			
			// this only writes into empty voxels
			if ( type != TypeInfo.AIR )
				return true;
				
			// If we are not changing anything, head home.
			// RSF - This doesnt handle the grain size change done in editCursor
			if ( $type == type && $gc.bound == gc.bound && !childrenHas() )
				return true;
				
			// kill any existing family, you can be parent type OR physical type, not both
			if ( childrenHas() )
			{
				// If there are children, then the neighbors might point to the children
				// Since they are being deleted, we have to make sure any pointers to them are removed.
				childrenPrune();
				neighborsInvalidate();
			}
			
			// set our material type
			type = $type;
			
			facesMarkAllDirty();
			return true;
		}
		
		var child:Oxel = childGetOrCreate( $gc );
		if ( Globals.BAD_OXEL == child )
			return false;
		
		return child.write_empty( $instanceGuid, $gc, $type );
		
	}
	
	public function writeFromHeightMap( $gc:GrainCursor, $newType:int ):void {
		
		var co:Oxel = childGetOrCreate( $gc );
		super.type = $newType;
		dirty = true;
	}

	private function updateInventory( $newType:int ):void {
		
		// If this is a parent oxel
		if ( childrenHas() ) {
			for ( var i:int = 0; i < 8; i++ )
				children[i].updateInventory( $newType );
			return;	
		} 

		var amountInGrain0:int = Math.pow( 1 << Math.abs(gc.grain), 3 );
		var typeIdToUse:int;
		if ( TypeInfo.AIR == $newType ) {
			typeIdToUse = type;
			amountInGrain0 = amountInGrain0;
		}
		else {
			typeIdToUse = $newType;
			amountInGrain0 = -amountInGrain0;
		}
			
		InventoryVoxelEvent.dispatch( new InventoryVoxelEvent( InventoryVoxelEvent.CHANGE, Network.userId, typeIdToUse, amountInGrain0 ) );
	}
	
	private function writeInternal( $instanceGuid:String, $newType:int, $onlyChangeType:Boolean ):Oxel {
		
		nodes++;

		// so I am changing type to new type
		// if type == air then I am removing x amount of newType from inventory
		const EDIT_CURSOR_MIN:int = 990;
		// we dont want to add edit cursor to our inventory
		// also if we have a scripts that generates blocks, not sure how to handle that.
		// TODO how do we handle scripts the generate blocks, need to take inventory status first?
		if ( EditCursor.EDIT_CURSOR != $instanceGuid && false == $onlyChangeType )
			updateInventory( $newType );
		
		// kill any existing family, you can be parent type OR physical type, not both
		if ( childrenHas() )
		{
			// If there are children, then the neighbors might point to the children
			// Since they are being deleted, we have to make sure any pointers to them are removed.
			childrenPrune();
			neighborsInvalidate();
		}
		
		additionalDataClear();
		
			
		// Now we can change type
		type = $newType;
		
		// This is only used by terrain builder scripts.
		if ( $onlyChangeType ) 
			return this;
		
		// anytime oxel changes, neighbors need to know
		neighborsMarkDirtyFaces( $instanceGuid, gc.size() );
		
		var p:Oxel = _parent;
		// This is only a two level merge, brain not up to a n level recursive today...
		if ( TypeInfo.AIR == type && p )
		{
			// make a copy since this oxel may be going away.
			if ( p.checkForMerge() )
			{
				p = p.parent;
				if ( p && p.checkForMerge() ) {
					if ( null == p )
						Log.out( "out" );
					return p;
					
				}
				else 
					if ( null == p )
						Log.out( "out1" );
					return p;
			}
		}
		
		return this;
	}
	
	// This write to a child if it is a valid child of the oxel
	// if the child does not exist, it is created
	public function write( $instanceGuid:String, $gc:GrainCursor, $newType:int, $onlyChangeType:Boolean = false ):Oxel	{
		
		// this finds the closest oxel, could be target oxel, could be parent
		var co:Oxel = childFind( $gc );
		
		if ( co.type != $newType && !gc.is_equal( $gc ) )
			// this gets the exact oxel we are looking for if it is different from returned type.
			co = co.childGetOrCreate( $gc );
			
		if ( Globals.BAD_OXEL == co )
		{
			Log.out( "Oxel.write - cant find child!", Log.ERROR );
			return co;
		}
		
		if ( $newType == co.type && $gc.bound == co.gc.bound && !co.childrenHas() )
			return co;
		
		return co.writeInternal( $instanceGuid, $newType, $onlyChangeType );	
	}
			
	//public function dispose():void {
		//if ( _chunk ) 
			//_chunk.dispose();
		//
		//if ( vm_get().minGrain <= gc.grain ) {
			//if ( childrenHas() ) {
				//for each ( var cchild:Oxel in _children ) 
					//cchild.dispose();
			//}
		//}
	//}

	public function mergeAndRebuild():void {
		var _timer:int = getTimer();
		Oxel.nodes = 0;
		mergeRecursive();
		Log.out("Oxel.mergeAndRebuild - merge took: " + (getTimer() - _timer) + " count " + Oxel.nodes );
		
		_timer = getTimer();
		Oxel.nodes = 0;
		mergeRecursive();
		Log.out("Oxel.mergeAndRebuild - merge 2 took: " + (getTimer() - _timer) + " count " + Oxel.nodes );
		
		_timer = getTimer();
		rebuildAll();
		Log.out("Oxel.mergeAndRebuild - rebuildAll took: " + (getTimer() - _timer));
	}
	
	public function mergeAirAndRebuild():void {
		var _timer:int = getTimer();
		Oxel.nodes = 0;
		mergeAirRecursive();
		Log.out("Oxel.mergeAirAndRebuild - merge took: " + (getTimer() - _timer) + " count " + Oxel.nodes );
		
		_timer = getTimer();
		rebuildAll();
		Log.out("Oxel.mergeAirAndRebuild - rebuildAll took: " + (getTimer() - _timer));
	}

	public function checkForMerge():Boolean	{
		const childType:uint = _children[0].type;
		var hasBrightnessData:Boolean = false;
		// see if all of the child are the same type of node
		for each ( var child:Oxel in _children ) 
		{
			if ( childType != child.type )
				return false; // Not the same, get out
			if ( child.childrenHas() )
				return false; // Dont delete parents!
			
			if ( null != child._lighting )
				hasBrightnessData = true;
		}
		
		//Log.out( "Oxel.merge - removed children with type: " + Globals.Info[child.type].name + " of grain: " + gc.grain );
		
		/// merge the brightness data into parent.
		if ( hasBrightnessData ) {
			if ( null == _lighting )
				_lighting = LightingPool.poolGet( Lighting.defaultBaseLightAttn );
			for each ( var childForBrightness:Oxel in _children ) 
			{
				if ( childForBrightness._lighting ) {
					_lighting.mergeChildren( childForBrightness.gc.childId(), childForBrightness._lighting, childForBrightness.gc.size(), TypeInfo.hasAlpha( type ) );
					// Need to set this from a valid child
					// Parent should have same brightness attn as children did.
					_lighting.materialFallOffFactor = childForBrightness.lighting.materialFallOffFactor;
					_lighting.color = childForBrightness.lighting.color;
				}
			}
		}
		nodes += 8;
		childrenPrune();
		neighborsInvalidate();
		
		if ( childType != type )
			type = childType;
			
		return true;	
	}
	
	public function mergeRecursive():Boolean {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in _children ) 
			{
				if ( child.mergeRecursive() )
				return false;
			}
		}
		else
		{
			if ( _parent )
				return _parent.checkForMerge();
		}
		return false;
	}
	
	public function mergeAirRecursive():Boolean {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in _children ) 
			{
				if ( child.mergeRecursive() )
				return false;
			}
		}
		else
		{
			if ( _parent && TypeInfo.AIR == type )
				return _parent.checkForMerge();
		}
		return false;
	}
	
	public function changeGrainSize( changeSize:int, newBound:int ):void {
		if ( childrenHas() )
		{
			gc.bound = newBound;
			gc.grain = gc.grain + changeSize;
			//  if our new size is 0, and we have children, prune them
			if ( 0 == gc.grain )
			{
				childrenPrune();
				neighborsInvalidate();
				return;
			}
				
			for each ( var child:Oxel in _children ) 
			{
				child.changeGrainSize( changeSize, newBound );
			}
		}
		else
		{
			gc.bound = newBound;
			gc.grain = gc.grain + changeSize;
		}
		return;
	}
	
	public function print():void {
		trace( "Oxel - print: " + toString() );
		for each ( var child:Oxel in _children ) {
			child.print();
		}
	}
	
	public function toString():String {
		var p:String = _parent ? " has parent" : "  no parent";
		var c:String = childrenHas() ? (" has " + _children.length + " kids") : "  no children";
		var t:String = "";
		if ( null != root_get().gc )
		{
			var bg:uint = root_get().gc.grain;
			for ( var i:int = 0; i < bg - gc.grain; i++ ) {
				t += "\t";
			}
		var r:String;
		if ( TypeInfo.INVALID == type )
			r = "\t\t oxel of type: " + TypeInfo.typeInfo[type].name;
		else
			var str:String = "";
			str = maskTempData().toString(16)
			var hex:String = ("0x00000000").substr(2,8 - str.length) + str;
			r = t + " oxel of type: " + TypeInfo.typeInfo[type].name + "\t location: " + gc.toString() + "  data: " + hex + " parent: " + p + " children: " + c;
		}
		else
			r = "Uninitialized Oxel" + p + c;

		return r;
	}
	
	public function toStringShort():String {
		return "oxel of type: " + TypeInfo.typeInfo[type].name + "\t location: " + gc.toString();
	}
	
	public function rebuildAll():void
	{
		if ( childrenHas() )
		{
			if ( TypeInfo.AIR != type )
			{
				Log.out( "Oxel.rebuildAll - parent with TYPE: " + TypeInfo.typeInfo[type].name, Log.ERROR );
				type = TypeInfo.AIR; 
			}
			for each ( var child:Oxel in _children )
			{
				child.rebuildAll();
			}
		}
		else
		{
			facesMarkAllDirty();
			quadsDeleteAll();
		}
	}
	
	public function root_get():Oxel {
		if ( _parent )
			return _parent.root_get();
		else
			return this;
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Neighbors function START
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function neighbor( $face:int ):Oxel { 
		if ( !_neighbors )
			_neighbors = NeighborPool.poolGet();
		
		// lazy evaluation
		var no:Oxel = _neighbors[ $face ];
		//if ( no && no != Globals.BAD_OXEL && no.gc.grain > gc.grain && no.childrenHas() )
		//	Log.out( "Oxel.neighbor - this should never happen this:" + toString() + "  no: " + no.toString() );
		if ( null == no )
		{
			// This uses the _s_scratchGrain
			if ( neighborsIsValid( $face ) ) {
				_neighbors[ $face ] = root_get().childFind( _s_scratchGrain );
			}
			else
				_neighbors[ $face ] = Globals.BAD_OXEL;
		}
		return _neighbors[ $face ];
	}
	
	protected function neighborsIsValid( dir:int ):Boolean {
		_s_scratchGrain.copyFrom( gc );
		var result:Boolean = false;
		if ( Globals.POSX == dir )
			result = _s_scratchGrain.move_posx();
		else if ( Globals.NEGX == dir )
			result = _s_scratchGrain.move_negx();
		else if ( Globals.POSY == dir )
			result = _s_scratchGrain.move_posy();
		else if ( Globals.NEGY == dir )
			result = _s_scratchGrain.move_negy();
		else if ( Globals.POSZ == dir )
			result = _s_scratchGrain.move_posz();
		else if ( Globals.NEGZ == dir )
			result = _s_scratchGrain.move_negz();
			
		return result;
	}

	private function breakToSize( $levelsToBreak:int ):void {
		// just doing a single level break for now
		// pretty sure I wrote a get opposite oxel somewhere in the lighting system.
		// should use it to continue multi level breakdown.
		childrenCreate(true);
	}
	
	// Mark all of the faces opposite this oxel as dirty
	// propogate count is to keep it from spreading too far, by maybe this should be distance, rather then hard count?
	public function neighborsMarkDirtyFaces( $instanceGuid:String, $size:int, $propogateCount:int = 2 ):void {
		var no:Oxel;
		$propogateCount--;
		for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ )
		{
			no = neighbor(face);
			if ( Globals.BAD_OXEL == no )
				continue;
				
			// if I have alpha, then see if neighbor is same size, if no=()t break it up.
			if ( TypeInfo.hasAlpha( type ) ) {				
				if ( gc.grain < no.gc.grain  )
					no.breakToSize( no.gc.grain - gc.grain );
			}
				
			// RSF - 10.2.14 This just got way easier, always mark the neighbor face!
			no.faceMarkDirty( $instanceGuid, Oxel.face_get_opposite( face ), $propogateCount );
			// now test if we need to propagate it.
			// Why do alpha faces have to propagate? Is it because of light changes?
			if ( TypeInfo.hasAlpha( no.type ) ) {
				// So now I can mark my neighbors dirty, decrementing each time.
				if ( 0 < $size && 0 < $propogateCount )
					no.neighborsMarkDirtyFaces( $instanceGuid, $size, $propogateCount );
			}
		}
	}
	
	// I am breaking up, so get rid of any reference to me
	public function neighborsInvalidate():void {
		// regardless of whether or not I have neighbors, I need to create them so them I can tell them I have changed!
		for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ ) {
			var no:Oxel = neighbor(face);
			if ( no && Globals.BAD_OXEL != no ) {
				no.neighborInvalidate( Oxel.face_get_opposite( face ) );
			}
		}
	}

	// set old neighbor to null
	protected function neighborInvalidate( face:int ):void {
		dirty = true;
		if ( _neighbors ) 
			_neighbors[face] = null;
		
		if ( childrenHas() ) {
			//const dchildren:Vector.<Oxel> = childrenForDirection( Oxel.face_get_opposite( face ) );
			const dchildren:Vector.<Oxel> = childrenForDirection( face );
			for each ( var dchild:Oxel in dchildren ) 
				dchild.neighborInvalidate( face );
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Neighbors function END
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// face function
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	override protected function faceMarkDirty( $instanceGuid:String, $face:uint, $propogateCount:int = 2 ):void {
		
		if ( childrenHas() ) {
			const children:Vector.<Oxel> = childrenForDirection( $face );
			for each ( var child:Oxel in children ) {
				child.faceMarkDirty( $instanceGuid, $face, $propogateCount );
			}
		}
		else {
			var ti:TypeInfo = TypeInfo.typeInfo[type];
			// TODO This needs to be refactored to remove this from this function, so more likely go in the write function of the voxelModel.
			// TODO also be nice to pass in the flow direction if possible. We know which face, so we know flow dir...
			// 1 = $propogateCount means only the oxel directly next to the effect oxel will have flow tasks generated.
			if ( ti.flowable && Globals.autoFlow && EditCursor.EDIT_CURSOR != $instanceGuid && 1 == $propogateCount )
				Flow.addTask( $instanceGuid, gc, type, null != flowInfo ? flowInfo : ti.flowInfo.clone(), 1 );
				
			if ( _quads && _quads[$face] )
				_quads[$face].dirty = 1;

			if ( lighting )
				lighting.occlusionResetFace( $face );

			super.faceMarkDirty( $instanceGuid, $face, $propogateCount );
		}
	}

	override protected function facesMarkAllDirty():void { 
		super.facesMarkAllDirty();
		facesClearAll();
	}
	
	public function faces_rebuild( $instanceGuid:String ):void {
		quadsDeleteAll();
		
		// anytime oxel changes, neighbors need to know
		neighborsMarkDirtyFaces( $instanceGuid, gc.size() );
		facesMarkAllDirty();
	}

	//private function facesBuildWater():void {
		//_s_oxelsEvaluated++;
		//var no:Oxel = null;
		//for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ ) {
			//no = neighbor( face );
			//if ( Globals.BAD_OXEL == no ) 
				//continue;
			//if ( TypeInfo.WATER == no.type && !no.childrenHas() )
				//continue;
			//
			//// so the neighbor has children, are all the children facing us water oxels?
			//// if there is anything other then a water oxel facing this face, it needs to break up into smaller oxel
			//const dchildren:Vector.<Oxel> = no.childrenForDirection( Oxel.face_get_opposite( face ) );
			//var breakup:Boolean;
			//for each ( var dchild:Oxel in dchildren ) {
				//if ( TypeInfo.WATER != dchild.type ) {
					//breakup = true;
					//break;
				//}
			//}
			//if ( breakup && 0 < gc.grain  ) {
				//childrenCreate();
				//_s_oxelsCreated += 8;
				//facesBuild();
			//}
		//}
	//}

	public function facesBuild():void {
		if ( dirty ) {
			if ( childrenHas() ) {
				// parents dont have faces!
				if ( facesHas() )
					facesClearAll();
					
				for each ( var child:Oxel in _children )
					if ( child.dirty )
						child.facesBuild();
			}
			else
				facesBuildTerminal();
		}
	}
	
	private function facesBuildTerminal():void {
		//trace( "Oxel.facesBuildTerminal");
		if ( TypeInfo.AIR == type )
			facesMarkAllClean();
		else  if ( TypeInfo.LEAF == type )
			facesSetAll();
		//else  if ( TypeInfo.WATER == type )
		//	facesBuildWater();
		else if ( faceHasDirtyBits() ) {
			var no:Oxel = null ;
			for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ )
			{
				// only check the faces marked as dirty
				if ( faceIsDirty( face ) )
				{
					no = neighbor( face );
					if ( Globals.BAD_OXEL == no ) {
						// this is an external face. that is on the edge of the grain space
						faceSet( face );
					}
					else if ( no.type == type ) {
						// nieghbor oxel is the same, we are done? nope, the neighbor might have different scaling.. for flowable type.
						// do we both have flow info?
						if ( no.flowInfo && flowInfo ) {
							// verify both have scaling
							if ( no.flowInfo.flowScaling && flowInfo.flowScaling ) {
								// so now I need the equivelent spots on each face to compare.
								var p1:Point = flowInfo.flowScaling.faceGet( face );
								var p2:Point = no.flowInfo.flowScaling.faceGet( face_get_opposite( face ) );
								if ( p1.equals( p2 ) )
									faceClear( face );
								else 
									faceSet( face );
							}
						}
						else
							faceClear( face );
					}
					else if ( no.childrenHas() ) {
						// so I am a larger face looking to see if there is visability to me.
						// if I am solid, and any neighbors has alpha, then I am visible.
						var rface:int;
						if ( !TypeInfo.hasAlpha( type ) ) {
							rface = Oxel.face_get_opposite( face );
							// get the children of my neighbor, that touch me.
							const dchildren:Vector.<Oxel> = no.childrenForDirection( rface );
							for each ( var dchild:Oxel in dchildren ) 
							{
								// Need to gather the alpha info from each child
								// if a neighbor child has alpha, then I need to generate a face
								// if all neighbors are opaque, that face is not needed
								if ( true == dchild.faceHasAlpha( rface ) ) {
									faceSet( face );
									continue;
								}
							}
						}
						else {
							faceClear( face );
							if ( faceAlphaNeedsFace( face, type, no ) )
								faceSet( face );
						}
						
						//var rface:int = Oxel.face_get_opposite( face );
						//if ( no.faceHasAlpha( rface ) )
							//face_set( face );
					}
					// no children, so just check against type
					else
					{
						if ( ( TypeInfo.hasAlpha( no.type ) ) )
							faceSet( face );
						else if ( flowInfo ) // All water and lava have flow info.
						{ 
							if ( flowInfo.flowScaling.scalingHas() ) 	// for scaled lava or other non alpha flowing types
								faceSet( face );
							else {
								faceClear( face );
								/*
								if ( TypeInfo.WATER == type ) {
									//face_set( face ) This adds an interior face, but z buffer conflicts makes it not work well.
									if ( no.lighting ) {
										var li:LightInfo = no.lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
										li.color = 0x0000ff;
										no.dirty = true;
									}
								}
								*/
							}
						}
						else if ( no.flowInfo )	// for scaled lava or other non alpha flowing types
						{
							if ( no.flowInfo.flowScaling.scalingHas() )
								faceSet( face );
							else
								faceClear( face );
						}
						else {
							faceClear( face );;
						}
					}
				}
			}
		}
		facesMarkAllClean();
	}
	
	static public function face_get_opposite( dir:int ):int	{
		if      ( Globals.POSX == dir )
			return Globals.NEGX;
		else if ( Globals.NEGX == dir )
			return Globals.POSX;
		else if ( Globals.POSY == dir )
			return Globals.NEGY;
		else if ( Globals.NEGY == dir )
			return Globals.POSY;
		else if ( Globals.POSZ == dir )
			return Globals.NEGZ;
		else if ( Globals.NEGZ == dir )
			return Globals.POSZ;

		trace( "Oxel - face_get_opposite - ERROR - Invalid face", Log.ERROR );
		return 1;
	}

	public function faceHasAlpha( dir:int ):Boolean	{
		//	If no children, then is this an opaque type
		if ( !childrenHas() )
		{
			return TypeInfo.hasAlpha( type );
		}
		else // I have children, so check each child on that face
		{
			const dchildren:Vector.<Oxel> = childrenForDirection( dir );
			for each ( var dchild:Oxel in dchildren ) 
			{
				// Need to gather the alpha info from each child
				if ( true == dchild.faceHasAlpha( dir ) )
					return true;
			}
		}
			
		// all children for that direction are opaque, so this face is opaque
		return false;	
	}
	
	public function faceHasWater( dir:int ):Boolean	{
		//	If no children, then is this an opaque type
		if ( !childrenHas() )
		{
			return ( TypeInfo.WATER == type );
		}
		else // I have children, so check each child on that face
		{
			const dchildren:Vector.<Oxel> = childrenForDirection( dir );
			for each ( var dchild:Oxel in dchildren ) 
			{
				// Need to gather the alpha info from each child
				if ( true == dchild.faceHasWater( dir ) )
					return true;
			}
		}
			
		// all children for that direction are opaque, so this face is opaque
		return false;	
	}
	
	// returns true if face is required
	// works like a charm!
	public function faceAlphaNeedsFace( $face:int, $type:int, $no:Oxel ):Boolean	{

		//	we only need a face here is the nieghbor is alpha of a different type
		if ( !$no.childrenHas() ) {
			if ( TypeInfo.hasAlpha( $no.type ) )
				return !( $type == $no.type );
			else
				return false;
		}

		// get the children touching $face
		const dchildren:Vector.<Oxel> = $no.childrenForDirection( Oxel.face_get_opposite( $face ) );
		for each ( var dchild:Oxel in dchildren ) 
		{
			// if any of the children have alpha of a different type
			if ( faceAlphaNeedsFace( $face, $type, dchild ) )
				return true;
		}

		// all children for that direction are opaque, so this face is opaque
		return false;	
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// face function END
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// lighting START
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public static var _s_oxelsCreated:int = 0;
	public static var _s_oxelsEvaluated:int = 0;
	public static var _s_lightsFound:int = 0;
	
	private function quadLighting( $face:int, $ti:TypeInfo ):void {
		
		if ( !_lighting ) {
			_lighting = LightingPool.poolGet( Lighting.defaultBaseLightAttn );
			if ( _lighting.lightHas( Lighting.DEFAULT_LIGHT_ID ) ) {
				var li:LightInfo = _lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
				// break down for debugging
				//var rootAttn:uint = root_get()._lighting.lightGet( Lighting.DEFAULT_LIGHT_ID ).avg
				var rootAttn:uint = Lighting.defaultBaseLightAttn
				var root:Oxel = root_get();
				if ( root && root._lighting )
					rootAttn = root._lighting.lightGet( Lighting.DEFAULT_LIGHT_ID ).avg
				else
					Log.out( "Oxel.quadLighting - root or root lighting not found", Log.WARN );
				li.setAll( rootAttn );
			}
			_lighting.materialFallOffFactor = $ti.lightInfo.fallOffFactor;
			_lighting.color = $ti.color;
		}
		
		if ( true == $ti.lightInfo.fullBright && false == $ti.lightInfo.lightSource )
			_lighting.lightFullBright();
		
		_lighting.evaluateAmbientOcculusion( this, $face, Lighting.AMBIENT_ADD );
	}

	public function lightingFromSun( $instanceGuid:String, $face:int ):void {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in _children )
				child.lightingFromSun( $instanceGuid, $face );
		}
		else
		{
			// Does this oxel have the a face in the $face direction, if not move on
			if ( faceHas( $face ) )
			{
				_s_oxelsEvaluated++;
				//LightSunCheck.addTask( $instanceGuid, gc, 1, $face );
			}

		}
	}
	
	// This would only be run once when model loads
	// set the activeVoxelinstanceGuid before calling
	public function lightsStaticCount( $instanceGuid:String ):void {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in _children )
				child.lightsStaticCount( $instanceGuid );
		}
		else
		{
			if ( TypeInfo.isLight( type ) ) // had & quads, but that doesnt matter with this style
				_s_lightsFound++;
		}
	}
	
	// This should be called from voxelModel
	public function lightsStaticSetDefault( $attn:uint ):void {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in _children )
				child.lightsStaticSetDefault( $attn );
		}
		else
		{
			if ( _lighting && _lighting.lightHas( Lighting.DEFAULT_LIGHT_ID ) ) {
				var li:LightInfo = _lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
				li.setAll( $attn );
				quadsRebuildAll();
			}
		}
	}

	
	public function faceCenterGet( face:int ):Vector3D
	{
		const size:int = gc.size() / 2;
		var faceCenter:Vector3D = new Vector3D( gc.getModelX() + size, gc.getModelY() + size, gc.getModelZ() + size );
		if ( Globals.POSX == face )
			faceCenter.x += size;
		else if ( Globals.NEGX == face ) 	
			faceCenter.x -= size;
		else if ( Globals.POSY == face ) 	
			faceCenter.y += size;
		else if ( Globals.NEGY == face ) 	
			faceCenter.y -= size;
		else if ( Globals.POSZ == face ) 	
			faceCenter.z += size;
		else if ( Globals.NEGZ == face ) 	
			faceCenter.z -= size;
		
		return faceCenter;
	}
	
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// lighting END
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Begin Quad functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function quadsBuild( $plane_facing:int = 1 ):void {
		if ( dirty ) {
			if ( childrenHas() ) {
				// parents dont have quads!
				if ( dirty  && _quads )
					chunkRemoveOxel();

				facesCleanAllFaceBits();

				for each ( var child:Oxel in _children )
					if ( child.dirty )
						child.quadsBuild( $plane_facing );
				dirty = false;
			}
			else
				quadsBuildTerminal( $plane_facing );
		}
	}
	
	protected function quadsBuildTerminal( $plane_facing:int = 1 ):void {
		var changeCount:int = 0;
		// Does this oxel have faces
		if ( facesHas() )
		{
			if ( null == _quads )
				_quads = QuadsPool.poolGet();
			
			var ti:TypeInfo = TypeInfo.typeInfo[type];
			// We have to go thru each one, since some may be added, and others removed.
			for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ )
				changeCount += quadAddOrRemoveFace( face, $plane_facing, gc.grain, ti );
		}
		else  // if no faces release all quads
			changeCount = quadsDeleteAll();
		
		// did any of the quads change?
		if ( changeCount ) {
			// if those this oxel has not been added to vertex manager do it now.
			if ( !addedToVertex ) 
				chunkAddOxel();
		}
		else if ( addedToVertex ) // I was added to vertex, but I lost all my face, so remove oxel
			chunkRemoveOxel();

		dirty = false;
	}
	
	protected function quadAddOrRemoveFace( $face:int, $plane_facing:int, $grain:uint, $ti:TypeInfo ):int {
		var validFace:Boolean = faceHas($face);
		var quad:Quad = _quads[$face];
		
		// has face and quad
		if ( validFace && quad ) {
			if ( quad.dirty ) {
				quadLighting( $face, $ti );
				quad.rebuild( type, gc.getModelX(), gc.getModelY(), gc.getModelZ(), $face, $plane_facing, $grain, _lighting );
			}
			return 1;
		}
		// face but no quad
		else if ( validFace && !quad ) 
		{
			quadLighting( $face, $ti );				
			quad = QuadPool.poolGet();
			if ( flowInfo && TypeInfo.flowable( type ) ) {
				if ( !quad.buildScaled( type, gc.getModelX(), gc.getModelY(), gc.getModelZ(), $face, $plane_facing, $grain, _lighting, flowInfo ) ) {
					QuadPool.poolDispose( quad );
					return 0;
				}
			}
			else {
				if ( !quad.build( type, gc.getModelX(), gc.getModelY(), gc.getModelZ(), $face, $plane_facing, $grain, _lighting ) ) {
					QuadPool.poolDispose( quad );
					return 0;
				}
			}
			_quads[$face] = quad;
			return 1;
		}
		// no face but has a quad
		else if ( !validFace && quad )
		{
			quadDelete( quad, $face, TypeInfo.INVALID );
			return 0;
		}
		// last case is no face and no quad		
		return 0;	
	}
	
	public function quadDeleteFace( $face:int ):void {
		if  ( !_quads )
			return;
		dirty = true;
		var quad:Quad = _quads[$face];
		if ( quad )
			quadDelete( quad, $face, type );
	}

	public function quadRebuild( $face:int ):void {
		if  ( !_quads )
			return;
		dirty = true;
		var quad:Quad = _quads[$face];
		if ( quad )
		{
			var plane_facing:int = 1;
			quad.rebuild( type, gc.getModelX(), gc.getModelY(), gc.getModelZ(), $face, plane_facing, gc.grain, _lighting );
		}
	}

	public function quadMarkDirty( $face:int ):void {
		if  ( !_quads )
			return;
		dirty = true;
		var quad:Quad = _quads[$face];
		if ( quad )
			quad.dirty = 1;
	}
	
	public function quadsRebuildAll():void {
		if  ( !_quads )
			return;
			
		for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ )
			quadRebuild( face );
	}
	
	////////////////////////////////////////
	public function quadsDeleteAll():int {
		var changeCount:int;
		if  ( _quads )
		{
			//Log.out( "Oxel.quadsDeleteAll" );
			dirty = true;
			for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ ) {
				var quad:Quad = _quads[face];
				if ( quad ) {
					quadDelete( quad, face, type );
					changeCount++;
				}
			}
		}
		return changeCount;
	}

	// TODO, I see some risk here when I am changing oxel type from things like sand to glass
	// Its going to assume that it was solid, which works for sand to glass
	// how about water to sand? the oxel would lose all its faces, but never go away.
	protected function quadDelete( quad:Quad, face:int, type:int ):void {
		QuadPool.poolDispose( quad );
		_quads[face] = null;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// End Quad functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Vertex Manager functions START
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private function chunkRemoveOxel():void {
		if ( _quads )
		{
			quadsDeleteAll();
			QuadsPool.poolDispose( _quads );
			_quads = null;
		}
		// Air can have brightness but not quads
		//if ( _brightness )
		//{
			//BrightnessPool.poolReturn( _brightness );
			//_brightness = null;
		//}
		
		if ( addedToVertex )
		{
			// Todo - this should just mark the oxels, and clean up should happen later
			chunkGet().oxelRemove( this );
			addedToVertex = false;
		}
	}
	
	private function chunkAddOxel():void {
		addedToVertex = true;
		chunkGet().oxelAdd( this );
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Vertex Manager END
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	 * FLOW FUNCTIONS
	 * three different kinds of flow
	 * 1) pressurized flow, $gc unlimited oxels are produced (rate limited?), this could fill a cavity then go over the top
	 * 2) continuous gravity flow, a spring for example, this flow always goes downhill, but doesnt run out
	 * 3) limited flow, like a bucket of water being poured out, this has a set number of oxels.
	 *
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/
	private const MIN_FLOW_GRAIN:int = 2;
	public function flowFindCandidates( $instanceGuid:String, $countDown:int = 8, $countOut:int = 8):void {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in children )
				if ( MIN_FLOW_GRAIN <= child.gc.grain )
					child.flowFindCandidates( $instanceGuid, $countDown, $countOut);
		}
		else
		{
			if ( TypeInfo.flowable( type ) )
			{
				Log.out( "Oxel.flowFindCandidates - gc: " + gc.toString() );
				//flowTerminal();
				Flow.addTask( $instanceGuid, gc, type, flowInfo, 1 );
			}
		}
	}

	//public function flowTerminal():void { }
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// END FLOW FUNCTIONS
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Saving and Restoring from File
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function toByteArray( $ba:ByteArray ):ByteArray {
		//  n unsigned char root grain size
		$ba.writeByte( gc.bound );
		//  n+1 oxel data
		toByteArrayRecursive( $ba );
		$ba.position = 0;
		return $ba;
	}
	
	private function toByteArrayRecursive( $ba:ByteArray ):void 
	{
		//trace( Oxel.data_mask_temp( _data ) );
		if ( childrenHas() && TypeInfo.AIR != type )	{
			Log.out( "Oxel.writeData - parent with TYPE: " + TypeInfo.typeInfo[type].name, Log.ERROR );
			type = TypeInfo.AIR; 
		}
		
		// If it has flow or lighting, we have to save both.
		if ( flowInfo || lighting )	{
			// I only have 1 bit for additional data...
			additionalDataMark();
			$ba.writeUnsignedInt( maskTempData() );
			$ba.writeUnsignedInt( type );
			
			if ( !flowInfo )
				flowInfo = FlowPool.poolGet();
			flowInfo.toByteArray( $ba );
			
			if ( !lighting )
				lighting = LightingPool.poolGet( Lighting.defaultBaseLightAttn );
			lighting.toByteArray( $ba );
		}
		else {
			additionalDataClear();
			$ba.writeUnsignedInt( maskTempData() );
			$ba.writeUnsignedInt( type );
		}
		
		if ( childrenHas() ) {
			for each ( var child:Oxel in _children ) 
				child.toByteArrayRecursive( $ba );
		}
	}
	
	public function readVersionedData( $version:int, $parent:Oxel, $gc:GrainCursor, $ba:ByteArray, $stats:ModelStatisics ):ByteArray 
	{
		var faceData:uint = $ba.readUnsignedInt();
		if ( $version <= Globals.VERSION_006 )
			initialize( $parent, $gc, OxelBitfields.dataFromRawDataOld( faceData ), OxelBitfields.typeFromRawDataOld( faceData ) );	
		else {
			var typeData:uint = $ba.readUnsignedInt();
			initialize( $parent, $gc, faceData, typeData );	
		}
		
		// Bad data check
		if ( OxelBitfields.dataIsParent( faceData ) && TypeInfo.AIR != type )
		{
			Log.out( "Oxel.readVersionedData - parent with TYPE: " + TypeInfo.typeInfo[type].name, Log.ERROR );
			type = TypeInfo.AIR;
		}
		// Check for flow and brightnessInfo
		if ( OxelBitfields.dataHasAdditional( faceData ) )
		{
			if ( !flowInfo )
				flowInfo = FlowPool.poolGet();
			$ba = flowInfo.fromByteArray( $version, $ba );
			
			// hack warning
			// the baseLightLevel gets overridden by data from byte array.
			// so if there is no parent, I need to save off the baseLightLevel
			// and restore it after the data has been read.
			if ( !lighting )
				lighting = LightingPool.poolGet( Lighting.defaultBaseLightAttn );
			$ba = lighting.fromByteArray( $version, $ba );
			
			if ( $parent ) {
				// override the stored data with the baseLightLevel set in the instance.
				var li:LightInfo = lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
				var avgLight:uint = root_get().lighting.avg;
				if ( li )
					li.setAll( avgLight );
			}
			else {
				var baseLightLevel:uint = Lighting.defaultBaseLightAttn //lighting.avg;
				lighting.lightGet( Lighting.DEFAULT_LIGHT_ID ).setAll( baseLightLevel );
			}
			lighting.materialFallOffFactor = TypeInfo.typeInfo[type].lightInfo.fallOffFactor;
		}
		
		if ( OxelBitfields.dataIsParent( faceData ) )
		{
			childCount = 8;
			_children = ChildOxelPool.poolGet();
			var gct:GrainCursor = GrainCursorPool.poolGet( $stats.largest );
			for ( var i:int = 0; i < OXEL_CHILD_COUNT; i++ )
			{
				_children[i]  = OxelPool.poolGet();
				gct.copyFrom( $gc );
				gct.become_child(i);   
				_children[i].readVersionedData( $version, this, gct, $ba, $stats );
			}
			GrainCursorPool.poolDispose( gct );
		}
		else {
			childCount = 1;
			$stats.statAdd( type, gc.grain );
		}

		return $ba;
	}

	public function readData( $parent:Oxel, $gc:GrainCursor, $ba:ByteArray, $stats:ModelStatisics ):ByteArray 
	{
		var oxelData:uint = $ba.readInt();
		//trace( intToHexString() + "  " + oxelData );
		initialize( $parent, $gc, oxelData, OxelBitfields.typeFromRawDataOld( oxelData ) );
		if ( OxelBitfields.dataIsParent( oxelData ) && TypeInfo.AIR != type )
		{
			Log.out( "Oxel.readData - parent with TYPE: " + TypeInfo.typeInfo[type].name, Log.ERROR );
			type = TypeInfo.AIR;
		}
		if ( OxelBitfields.dataIsParent( oxelData ) )
		{
			_children = ChildOxelPool.poolGet();
			var gct:GrainCursor = GrainCursorPool.poolGet( gc.bound );
			for ( var i:int = 0; i < OXEL_CHILD_COUNT; i++ )
			{
				_children[i]  = OxelPool.poolGet();
				gct.copyFrom( $gc );
				gct.become_child(i);   
				_children[i].readData( this, gct, $ba, $stats );
			}
			GrainCursorPool.poolDispose( gct );
		}
		
		return $ba;
	}
	
	private function intToHexString( $val:int ):String
	{
		var str:String = $val.toString(16)
		var hex:String = ("0x00000000").substr(2,8 - str.length) + str;
		return hex;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// End Saving and Restoring from File
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Intersection functions START
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function lineIntersect( $msStartPoint:Vector3D, $msEndPoint:Vector3D, $msIntersections:Vector.<GrainCursorIntersection> ):void {
		if ( TypeInfo.AIR == type && !childrenHas() )
			return;
		gc.lineIntersect( this, $msStartPoint, $msEndPoint, $msIntersections );
	}

	public function lineIntersectWithChildren( $msStartPoint:Vector3D, $msEndPoint:Vector3D, $msIntersections:Vector.<GrainCursorIntersection>, $minSize:int = 2 ):void	{
		if ( !childrenHas() )
		{
			if ( TypeInfo.AIR != type )
				gc.lineIntersect( this, $msStartPoint, $msEndPoint, $msIntersections );
		}
		else if ( gc.grain <=  $minSize	)			
			gc.lineIntersect( this, $msStartPoint, $msEndPoint, $msIntersections );

		// find the oxel that is closest to the start point, and is solid?
		// first do a quick check to see if ray hits any children.
		// then for any children it hits, do a hit test with its children
		else if ( childrenHas() )
		{
			// have to seperate childIntersections from totalIntersections
			var childIntersections:Vector.<GrainCursorIntersection> = new Vector.<GrainCursorIntersection>();
			var totalIntersections:Vector.<GrainCursorIntersection> = new Vector.<GrainCursorIntersection>();
			for each ( var child:Oxel in _children ) 
			{
				child.lineIntersect( $msStartPoint, $msEndPoint, childIntersections );
				for each ( var gcIntersection:GrainCursorIntersection in childIntersections )
				{
					gcIntersection.oxel = child;
					totalIntersections.push( gcIntersection );
				}
				childIntersections.splice( 0, childIntersections.length );
			}
			// if nothing to work with leave early
			if ( 0 == totalIntersections.length )
				return;
			
			// scratchVector is used by sort function
			_s_scratchVector = $msStartPoint;
			// sort getting closest ones first
			totalIntersections.sort( intersectionsSort );
			
			for each ( var gci:GrainCursorIntersection in totalIntersections )
			{
				// closest child might be empty, if no intersection with this child, try the next one.
				gci.oxel.lineIntersectWithChildren( $msStartPoint, $msEndPoint, $msIntersections, $minSize );
				// does this bail after the first found interesection?
				if ( 0 != $msIntersections.length )
				{
					return;
				}
			}
		}
	}
	
	private function intersectionsSort( pointModel1:GrainCursorIntersection, pointModel2:GrainCursorIntersection ):Number {
		// TODO subtract is SLOW
		var point1Rel:Number = _s_scratchVector.subtract( pointModel1.point ).length;
		var point2Rel:Number = _s_scratchVector.subtract( pointModel2.point ).length;
		if ( point1Rel < point2Rel )
			return -1;
		else if ( point1Rel > point2Rel ) 
			return 1;
		else 
			return 0;			
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Intersection functions END
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	/*
	 * This function will build a list of all Oxels that have any part inside
	 * the sphere described by the parameters:  cx,cy,cz, radius  (g0 units) 
	 * The typical context for this function is a culling method $gc the sphere
	 * is g0 point of the camera and the caller only wants to render Oxels inside
	 * some maximum distance from the camera
	 */
	public function select_all_inside_sphere( cx:int, cy:int, cz:int,  radius:int,  the_list:Vector.<Oxel> ):void {
		var child:Oxel;
		
		// our first test is the simplest case where this grain is
		// entirely inside the parameter sphere
		if ( true == GrainCursorUtils.is_inside_sphere( gc, cx, cy, cz, radius ))
		{
			// this grain and 100% of children (if any) are inside the radius
			// so if the grain has children or it has an opaque type it will be selected
			if(false
				|| true == childrenHas()
				|| true == TypeInfo.hasAlpha( type )
			)
			the_list.push(this);
			return;
		}
		
		// ok so this grain is not enclosed by the sphere which leaves only 3 cases
		// intersection,  disjoint,  encloses
		
		// the next thing we need to know is the sphere is completely inside this grain
		if ( true == GrainCursorUtils.contains_sphere(gc, cx, cy, cz, radius))
		{
			// the sphere is entirely enclosed by the grain
			if ( false == childrenHas() )
			{
				// leaf grain with no children
				// add it to the list if it is an opaque material type
				if ( TypeInfo.hasAlpha( type ) )
					the_list.push(this);
				return;
			}
			
			// the sphere is entirely enclosed by the grain that has children
			// so we must visit each child
			for each ( child in _children )
				child.select_all_inside_sphere( cx, cy, cz, radius, the_list );
			
			// all done
			return;
		}
		
		// ok so the sphere is NOT entirely inside this grain which means
		// it is completely dis-joint or it intersects the grain in some way
		
		
		// ok so the sphere and grain do not enclose one another
		// the only 2 remaining cases are intersection and disjointed
	
		// check this grain to see if it completely outside the sphere
		if ( true == GrainCursorUtils.is_outside_sphere(gc,cx,cy,cz,radius))
		{
			// the sphere and this grain and children (if any) do not intersect
			// so we want to completely cull this grain space from the list
			return;
		}

			
		// ok so this grain intersects the sphere partially 
		// so if we have no children then we're done
		if ( false == childrenHas() )
		{
			// leaf grain with no children
			// add it to the list if it is an opaque material type
			if ( TypeInfo.hasAlpha( type ) )
				the_list.push(this);
			return;
		}

		// this grain intersects the sphere 
		// and the grain has children
		// so we vist each child
		for each ( child in _children )
			child.select_all_inside_sphere( cx, cy, cz, radius, the_list );
			
		// all done

	}
	
	public function select_all_above_plane( p:Plane,  the_list:Vector.<Oxel> ):void	{
		var c:int = GrainCursorUtils.classify_from_plane( gc, p );
		
		if ( c == -1 )
		{
			// the grain is entirely below the plane so reject it
			return;
		}
		
		if ( c == +1 )
		{
			// the grain is entirely above the plane so accept it
			the_list.push(this);
			return;
		}
		
		// c == 0
		// the grain straddles the plain
		
		if (false == childrenHas())
		{
			// leaf grain with no children so accept it
			the_list.push(this);
			return;
		}
		
		// the grain straddles the plane
		// the grain has children
		// so visit each child
		for each ( var child:Oxel in _children )
			child.select_all_above_plane( p, the_list );

		// all done
	}
	
	static public function static_select_all_above_plane( p:Plane,  src_list:Vector.<Oxel> ):Vector.<Oxel> {
		var dst_list:Vector.<Oxel> = new Vector.<Oxel>;
		for each ( var child:Oxel in src_list )
			child.select_all_above_plane( p, dst_list );
		return dst_list;
	}
	
	static public function static_select_all_inside_frustrum( f:Vector.<Plane>,  src_list:Vector.<Oxel> ):Vector.<Oxel>	{
		var temp:Vector.<Oxel> = src_list;
		
		for each ( var p:Plane in f )
		{
			// use the current list as the source for the next test
			// doing so means the list will be getting smaller and smaller
			// due to the culling process of rejecting grains outside the planes
			temp = static_select_all_above_plane( p, temp );
		}
		
		// the final list should be grains that are either entirely inside
		// or partially inside the defined frustrum
		return temp;
	}
	
	public function write_sphere( $instanceGuid:String, cx:int, cy:int, cz:int, radius:int, $newType:int, gmin:uint = 0 ):void {
		if ( true == GrainCursorUtils.is_inside_sphere( gc, cx, cy, cz, radius ))
		{
			write( $instanceGuid, gc, $newType );
			return;
		}
		
		if ( true == GrainCursorUtils.is_outside_sphere( gc, cx, cy, cz, radius ))
			return;
		
		if ( gc.grain <= gmin )
			return;	

		if ( false == childrenHas() )
			childrenCreate();
		
		if ( false == childrenHas() )
		{
			throw new Error("Oxel.write_sphere - ERROR - children expected");
			return;
		}

		for each ( var child:Oxel in _children )
		{
			// make sure child has not already been released.
			if ( child && child.gc )
				child.write_sphere( $instanceGuid, cx, cy, cz, radius, $newType, gmin );
		}
	}
	
	public function writeHalfSphere( $instanceGuid:String, cx:int, cy:int, cz:int, radius:int, $newType:int, gmin:uint = 0 ):void {
		
		if ( true == GrainCursorUtils.is_inside_sphere( gc, cx, cy, cz, radius ) )
		{
			if ( gc.getModelY() < cy && gc.getModelY() + gc.size() > cy ) {
				childrenCreate();
				for each ( var newChild:Oxel in _children )
				{
					if ( newChild && newChild.gc )
						newChild.writeHalfSphere( $instanceGuid, cx, cy, cz, radius, $newType, gmin );
				}
				// if I put a return here, the top layer stays the same, but changes occur below the surface.
				//return;
			} 
			else if ( gc.getModelY() + gc.size() > cy )
				return;
				
//				Log.out( "writeHalfSphere gc: " + gc.toString() + "  cy: " + cy + " gc.getModelY(): " + gc.getModelY() + "  gc.size: " + gc.size() );
			write( $instanceGuid, gc, $newType );
			return;
		}
		
		if ( true == GrainCursorUtils.is_outside_sphere( gc, cx, cy, cz, radius ))
			return;
		
		if ( gc.grain <= gmin )
			return;	

		if ( false == childrenHas() )
			childrenCreate();
		
		if ( false == childrenHas() )
		{
			throw new Error("Oxel.write_sphere - ERROR - children expected");
			return;
		}

		for each ( var child:Oxel in _children )
		{
			// make sure child has not already been released.
			if ( child && child.gc )
				child.writeHalfSphere( $instanceGuid, cx, cy, cz, radius, $newType, gmin );
		}
	}
	
	public function writeCylinder( $instanceGuid:String, cx:int, cy:int, cz:int, radius:int, $newType:int, axis:int, gmin:uint, startTime:int, runTime:int, startingSize:int ):Boolean {
		var result:Boolean = true;
		var timer:int = getTimer();
		if ( startTime + runTime < timer )
			return false;
			
		if ( true == GrainCursorUtils.isInsideCircle( gc, cx, cy, cz, radius, axis ))
		{
			write( $instanceGuid, gc, $newType );
			return result;
		}
		else if ( gc.grain < startingSize && true == GrainCursorUtils.isOutsideCircle( gc, cx, cy, cz, radius, axis ))
		{
			return result;
		}
		else if ( gc.grain <= gmin )
			return result;	

		childrenCreate();
		
		if (!_children)
			throw new Error( "No kids");
		for each ( var child:Oxel in _children )
		{
			if ( child )
			{
				result = child.writeCylinder( $instanceGuid, cx, cy, cz, radius, $newType, axis, gmin, startTime, runTime, startingSize );
				if ( !result )
					return result;
			}
		}
		
		return result
	}
	
	public function empty_square( $instanceGuid:String, cx:int, cy:int, cz:int, radius:int, gmin:uint=0 ):void {
		if ( true == GrainCursorUtils.is_inside_square( gc, cx, cy, cz, radius ))
		{
			write( $instanceGuid, gc, TypeInfo.AIR );
			return;
		} 
		if ( true == GrainCursorUtils.is_outside_square( gc, cx, cy, cz, radius ))
		{
			return;
		}
		
		if ( gc.grain <= gmin )
		{
			write( $instanceGuid, gc, TypeInfo.AIR );
			return;	
		}

		childrenCreate();
		
		for each ( var child:Oxel in _children )
		{
			child.empty_square( $instanceGuid, cx, cy, cz, radius, gmin );
		}
	}

	public function effect_sphere( $instanceGuid:String, cx:int, cy:int, cz:int, ie:ImpactEvent ):void {
		var radius:int = ie.radius
		var writeType:int = 0;
		var ip:InteractionParams = null;
		// I never see this get called - RSF
		if ( true == GrainCursorUtils.is_inside_sphere( gc, cx, cy, cz, radius ))
		{
			ip = TypeInfo.typeInfo[type].interactions.IOGet( ie.type );
			writeType = TypeInfo.getTypeId( ip.type );
			if ( type == writeType )
				return;
			write( $instanceGuid, gc, writeType, false );
			return;
		} 
		
		if ( true == GrainCursorUtils.is_outside_sphere( gc, cx, cy, cz, radius ))
		{
			return;
		}
		
		if ( gc.grain <= ie.detail )
		{
			ip = TypeInfo.typeInfo[type].interactions.IOGet( ie.type );
			writeType = TypeInfo.getTypeId( ip.type );
			if ( type == writeType )
				return;
//				if ( "melt" == ip.script )
//					flowInfo.type = FlowInfo.FLOW_TYPE_MELT;
			write( $instanceGuid, gc, writeType, false );
			//else if ( "" != ip.script )
				//Log.out( "Oxel.effect_sphere - " + ip.script + " source type: " + type +  " writeType: " + writeType );
			return;	
		}

		if ( false == childrenHas() )
		{
			if ( type == TypeInfo.AIR )
				return;
			childrenCreate();
		}
		
		for each ( var child:Oxel in _children )
		{
			if ( child && child.gc )
				child.effect_sphere( $instanceGuid, cx, cy, cz, ie );
		}
	}
	
	// pass in 8 levels of height maps.
	public function write_height_map( $instanceGuid:String 
									, $type:int
									, minHeightMapArray:Vector.<Array>
									, maxHeightMapArray:Vector.<Array>
									, gmin:uint
									, heightMapOffset:int
									, ignoreSolid:Boolean ):void {
		if ( TypeInfo.typeInfo[type].solid && !ignoreSolid )
			return;

		// this fills in the grains that are not too high, and not too short.
		if ( gc.grain < gmin )
		{
			// This adds extra voxels, whats up there? RSF
			//var oxel:Oxel = childFind( gc, true );
			//oxel.set_type( Globals.get_debug_type( gc.grain ) );
			return;	
		}

		var grainSize:uint = GrainCursor.get_the_g0_size_for_grain(gc.grain);
		var bottom:uint = gc.grainY * grainSize;
		var top:uint = bottom + grainSize;

		if ( top <= minHeightMapArray[heightMapOffset][gc.grainX][gc.grainZ] )
		{
			if ( childrenHas() && gc.grain > gmin )
			{
				for each ( var child1:Oxel in _children )
				{
					child1.write_height_map( $instanceGuid, $type, minHeightMapArray, maxHeightMapArray, gmin, heightMapOffset - 1, ignoreSolid );
				}
			}
			else
			{
				if ( ignoreSolid )
					//write( $instanceGuid, gc, $type, true );
					writeFromHeightMap( gc, $type );
				else
					writeFromHeightMap( gc, $type );
					//write_empty( $instanceGuid, gc, $type );
			}
			return;
		}
		else if ( bottom >= maxHeightMapArray[heightMapOffset][gc.grainX][gc.grainZ] )
		{
			//trace("************ WRITE HEIGHTMAP OVER THE TOP: " + gc.toString() + " ");
			return;
		}
		
		if ( 0 < gc.grain && gc.grain > gmin  )
		{
			childrenCreate( false );
		
			for each ( var child:Oxel in _children )
			{
				child.write_height_map( $instanceGuid, $type, minHeightMapArray, maxHeightMapArray, gmin, heightMapOffset - 1, ignoreSolid );
			}
		}
	}

	public function resetFlowInfo():void {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in _children )
			{
				child.resetFlowInfo();
			}
		}
		else
		{
			if ( null != _flowInfo )
				_flowInfo.reset( this );
		}
	}
	
	public function rotateCCW():void
	{
		var range:uint = gc.bound - gc.grain;
		range = (1 << range) - 1;
		// 6 - 6 => 0
		// ( 2 ^ 0 ) - 1 => 0
		// 6 - 5 => 1
		// ( 2 ^ 1 ) - 1 => 1
		// 6 - 4 => 2
		// ( 2 ^ 2 ) - 1 => 3
		var x:uint = range - gc.grainZ;
		var z:uint = gc.grainX;
		gc.grainX = x;
		gc.grainZ = z;
		
		facesMarkAllDirty();
		quadsDeleteAll();
		
		if ( _children )
		{
			// ClockWise
			//var toxel:Oxel = null;
			//var toxel2:Oxel = null;
			//toxel = _children[0];
			//_children[0] = _children[1];
			//toxel2 = _children[4];
			//_children[4] = toxel;
			//toxel = _children[5];
			//_children[5] = toxel2;
			//_children[1] = toxel;
//
			//toxel = _children[2];
			//_children[2] = _children[3];
			//toxel2 = _children[6];
			//_children[6] = toxel;
			//toxel = _children[7];
			//_children[7] = toxel2;
			//_children[3] = toxel;

			// Counter ClockWise
			var toxel:Oxel = null;
			var toxel2:Oxel = null;
			toxel = _children[0];
			_children[0] = _children[4];
			toxel2 = _children[1];
			_children[1] = toxel;
			toxel = _children[5];
			_children[5] = toxel2;
			_children[4] = toxel;

			toxel = _children[2];
			_children[2] = _children[6];
			toxel2 = _children[3];
			_children[3] = toxel;
			toxel = _children[7];
			_children[7] = toxel2;
			_children[6] = toxel;

			for each ( var child:Oxel in _children )
			{
				child.rotateCCW();
			}
		}
	}
	
	
	static private var _x_max:int = 512;
	static private var _x_min:int = 512;
	static private var _y_max:int = 512;
	static private var _y_min:int = 512;
	static private var _z_max:int = 512;
	static private var _z_min:int = 512;
	static private var _o_max:int = 0;
	static private var _o_min:int = 31;
	public function centerOxel():void
	{
		_x_max = 0;
		_x_min = gc.size();
		_y_max = 0;
		_y_min = gc.size();
		_z_max = 0;
		_z_min = gc.size();
		_o_max = 0;
		_o_min = gc.size();
		// first determine extends
		for each ( var child:Oxel in _children )
		{
			child.extents();
		}
		trace( "Oxel.centerOxel" );
		trace( _x_max );
		trace( _x_min );
		trace( "x range: " + (_x_max - _x_min) );
		trace( "oxel center is: " + gc.size()/2 + "  model center is: " + (_x_max + _x_min)/2 );
		trace( _y_min );
		trace( _y_max );
		trace( "y range: " + (_y_max - _y_min) );
		trace( "oxel center is: " + gc.size()/2 + "  model center is: " + (_y_max + _y_min)/2 );
		trace( _z_max );
		trace( _z_min );
		trace( "z range: " + (_z_max - _z_min) );
		trace( "oxel center is: " + gc.size() / 2 + "  model center is: " + (_z_max + _z_min) / 2 );
		trace( "smallest oxel is " + _o_min + "  largest is " + _o_max );
		
		breakdown(2);
	}
	
	public function fullBright( $attn:uint ):void {
		var timer:int = getTimer();
		lightsStaticSetDefault( $attn );
		Log.out("Oxel.fullBright - rebuildAll took: " + (getTimer() - timer));
	}
	
	public function breakdown( smallest: int ):void {
		if ( smallest < gc.grain && !childrenHas() )
		{
			childrenCreate();
			for each ( var child:Oxel in _children )
			{
				child.breakdown( smallest );
			}
		}
		else
		{
			if ( childrenHas() )
			{
				for each ( var child1:Oxel in _children )
				{
					child1.breakdown( smallest );
				}
			}
			
		}
	}
	
	private function extents():void {
		if ( childrenHas() )
		{
			// first determine extends
			for each ( var child:Oxel in _children )
			{
				child.extents();
			}
		}
		else if ( !childrenHas() )
		{
			if ( _o_min > gc.grain )
				_o_min = gc.grain;
			if ( _o_max < gc.grain )
				_o_max = gc.grain;
			if ( _x_min > gc.getWorldCoordinate( 0 ) )
				_x_min = gc.getWorldCoordinate( 0 );
			if ( _x_max < gc.getWorldCoordinate( 0 ) + gc.size() )
				_x_max = gc.getWorldCoordinate( 0 ) + gc.size();
				
			if ( _y_min > gc.getWorldCoordinate( 1 ) )
				_y_min = gc.getWorldCoordinate( 1 );
			if ( _y_max < gc.getWorldCoordinate( 1 ) + gc.size() )
				_y_max = gc.getWorldCoordinate( 1 ) + gc.size();
				
			if ( _z_min > gc.getWorldCoordinate( 2 ) )
				_z_min = gc.getWorldCoordinate( 2 );
			if ( _z_max < gc.getWorldCoordinate( 2 ) + gc.size() )
				_z_max = gc.getWorldCoordinate( 2 ) + gc.size();
		}
		// otherwise its air and doest not count
	}
	
	public function changeAllButAirToType( $toType:int, changeAir:Boolean = false ):void {
		if ( childrenHas() ) {
			for each ( var child:Oxel in _children )
				child.changeAllButAirToType( $toType );
		}
		else {
			// dont change the air to solid!
			if ( TypeInfo.AIR == type )  {
				if ( changeAir ) {
					type = $toType; 
					// if AIR no quads to delete
					facesMarkAllDirty();
				}
			}
			else
				type = $toType; 
		}
	}

	public function changeTypeFromTo( fromType:int, toType:int ):void {
		if ( type == fromType )
			type = toType;
			
		if ( childrenHas() ) {
			for each ( var child:Oxel in _children )
				child.changeTypeFromTo( fromType, toType );
		}
	}
	
	private function reboundAll( newBound:int ):void {
		gc.bound = newBound;
		for each ( var child:Oxel in _children )
		{
			child.reboundAll( newBound );
		}
	}
	/*
	// { oxel:Globals.BAD_OXEL, gci:gci, positive:posMove, negative:negMove };
	// RSF - This only works correctly on the + sides, fails for some reason on neg side.
	public function grow( result:Object ):Oxel {
		if ( null != _parent )
			throw new Error( "Oxel.grow - Trying to grow a child");
			
		var newOxel:Oxel = OxelPool.poolGet();
		// change the bound on all children to the larger size
		reboundAll( gc.bound + 1 );
		var newGC:GrainCursor = GrainCursorPool.poolGet( gc.bound );
		newGC.copyFrom( gc );
		newGC.become_parent();
		newOxel._gc = newGC;
		newOxel.parentMarkAs();
		newOxel.type = TypeInfo.AIR;
		// TODO - RSF 
		// This is potential problem - might need to change level _vertexManagers are created at. 
		// Otherwise all new oxels will be created off this one vertexManager
		newOxel._chunk = this._chunk;
		newOxel.childrenCreate();
		
		this._parent = newOxel;
		this._chunk = null;

		// depending on what axis, and what movement it was, we choose which child to replace.
		switch ( result.gci.axis )
		{
			case Globals.AXIS_X: // x
				if ( 0 == result.gci.gc.grainX ) // going off neg side
				{
					this.gc.copyFrom( newOxel._children[1].gc );
					newOxel._children[1].release();
					newOxel._children[1] = this;
				}
				else
				{
					newOxel._children[0].release(); // This works
					newOxel._children[0] = this;
				}
				break;
			case Globals.AXIS_Y: // y
				if ( 0 == result.gci.gc.grainY ) // going off neg side
				{
					this.gc.copyFrom( newOxel._children[2].gc );
					newOxel._children[2].release();
					newOxel._children[2] = this;
				}
				else
				{
					newOxel._children[0].release(); // This works
					newOxel._children[0] = this;
				}
				break;
			case Globals.AXIS_Z: // z
				if ( 0 == result.gci.gc.grainZ ) // going off neg side
				{
					this.gc.copyFrom( newOxel._children[4].gc );
					newOxel._children[4].release();
					newOxel._children[4] = this;
				}
				else
				{
					newOxel._children[0].release(); // This works
					newOxel._children[0] = this;
				}
				break;
		}
		
		return newOxel;
	}
	*/
	public function growTreesOn( $instanceGuid:String, $type:int, $chance:int = 2000 ):void {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in children )
				child.growTreesOn( $instanceGuid, $type, $chance );
		}
		else if ( $type == type )
		{
			var upperNeighbor:Oxel = neighbor( Globals.POSY );
			if ( Globals.BAD_OXEL != upperNeighbor && TypeInfo.AIR == upperNeighbor.type ) // false == upperNeighbor.hasAlpha
			{
				TreeGenerator.generateTree( $instanceGuid, this, $chance );
			}
		}
	}
	
	public function growTreesOnAnything( $instanceGuid:String, $chance:int = 2000 ):void {
		if ( childrenHas() )
		{
			for each ( var child:Oxel in children )
				child.growTreesOnAnything( $instanceGuid, $chance );
		}
		else
		{
			var upperNeighbor:Oxel = neighbor( Globals.POSY );
			if ( Globals.BAD_OXEL != upperNeighbor && TypeInfo.AIR == upperNeighbor.type )
			{
				TreeGenerator.generateTree( $instanceGuid, this, $chance );
			}
		}
	}
	
	private function dirtAndGrassToSand( $dir:int ):void {
		var no:Oxel = neighbor( $dir );
		if ( Globals.BAD_OXEL == no )
			return;
			
		var noType:int = no.type;
		if ( TypeInfo.WATER == noType )
			type = TypeInfo.SAND;
		else if ( no.childrenHas() )
		{
			if ( no.faceHasWater( Oxel.face_get_opposite( $dir ) ) )
				type = TypeInfo.SAND;
		}
	}
	
	public function dirtToGrassAndSand():void {

		if ( childrenHas() )
		{
			for each ( var child:Oxel in children )
				child.dirtToGrassAndSand();
		}
		else if ( TypeInfo.DIRT == type || TypeInfo.GRASS == type )
		{
			// See if we have water around us, if so change to sand
			for each ( var dir:int in Globals.allButDownDirections )
			{
				dirtAndGrassToSand( dir );	
			}
			
			// if this is still dirt meaning no water, see if we have air above us, change to grass
			if ( TypeInfo.DIRT == type )
			{
				var no:Oxel = neighbor( Globals.POSY );
				if ( Globals.BAD_OXEL == no )
					return;
					
				if ( TypeInfo.AIR == no.type )
				{
					if ( null == no._children )
						type = TypeInfo.GRASS;
					else
					{
						var kids:Vector.<Oxel> = no.childrenForDirection( Globals.NEGY );
						for each ( var kid:Oxel in kids )
						{
							if ( TypeInfo.AIR == kid.type )
							{
								type = TypeInfo.GRASS;
								break;
							}
						}
					}
				}
			}
		}
	}
	
	public function vines( $instanceGuid:String ):void {

		if ( childrenHas() )
		{
			for each ( var child:Oxel in children )
				child.vines( $instanceGuid );
		}
		else if ( 152 == type  )
		{
			var nou:Oxel = neighbor( Globals.POSY )
			if ( Globals.BAD_OXEL == nou && TypeInfo.AIR == nou.type && !nou.childrenHas() && nou.gc.grain <= 4 )
				nou.write( $instanceGuid, gc, 152 );
			var nod:Oxel = neighbor( Globals.NEGY )
			if ( Globals.BAD_OXEL != nod && TypeInfo.AIR == nod.type && !nod.childrenHas() && nod.gc.grain <= 4 )
				nou.write( $instanceGuid, gc, 152 );
		}
	}
	
	public function harvestTrees( $instanceGuid:String ):void {

		if ( childrenHas() )
		{
			for each ( var child:Oxel in children )
			{
				child.harvestTrees( $instanceGuid );
				// harvesting trees can cause air oxels to merge. So we need to make sure we still have a valid parent.
				if ( !children )
					return;
			}
		}
		else if ( TypeInfo.LEAF == type || TypeInfo.BARK == type )
		{
			write( $instanceGuid, gc, TypeInfo.AIR );
		}
	}
	
	public function reset():void {
		if ( _lighting )
			_lighting.reset()
		if ( _flowInfo )
			_flowInfo.reset( this );			
		quadsDeleteAll();
		facesClearAll();
		facesMarkAllClean();
	}
	
	public function lightingReset():void {

		if ( childrenHas() )
		{
			for each ( var child:Oxel in children )
			{
				child.lightingReset();
			}
		}
		else if ( _lighting )
		{
			if ( _lighting.reset() )
				quadsRebuildAll();
		}
	}
	
	public function lightingSunGatherList( ol:Vector.<Oxel> ):void {

		if ( childrenHas() )
		{
			for each ( var child:Oxel in children )
				child.lightingSunGatherList( ol );
		}
		else if ( TypeInfo.AIR != type )
		{
			var no:Oxel = neighbor( Globals.POSY );
			if ( Globals.BAD_OXEL == no ) {
				ol.push( this );
				//trace( "light it - Globals.BAD_OXEL" + "  gc: " + gc.toString() );
			}
			else if ( no.childrenHas() )
			{
				// check opposite face to see if it has alpha
				if ( no.faceHasAlpha( Globals.NEGY ) ) {
					ol.push( this );
					//trace( "light it has hole - notype: " + no.type + "  gc: " + gc.toString() + "  no.gc: " + no.gc.toString() );
				}
			}
			else if ( !TypeInfo.isSolid( no.type ) )	{
				ol.push( this );
				//trace( "light it - notype: " + no.type + "  gc: " + gc.toString() + "  no.gc: " + no.gc.toString() );
			}
			//else if ( !no.isSolid )	
			//	trace( "ignore - : " + type + "  gc: " + gc.toString() );

		}
	}
	
	public static var TEMP_COUNT:int = 0;
	public function layDownWater( $waterHeight:int ):void
	{
		// If this is below water height it should be full of water.
		var bottom_height:int = gc.getModelY();
		var top_height:int = gc.getModelY() + gc.size();
		var child:Oxel;
		// bottom of oxel is at water height or greater
		if ( childrenHas() )
		{
			for each ( child in children )
				child.layDownWater( $waterHeight );
		}
		else if ( bottom_height >= $waterHeight )
		{
			// This is oxel above water height, nothing to see here
			return;
		}
		else if ( top_height <= $waterHeight )
		{
			// This is oxel is below the water height, it better be full
			// if it has children keep on digging down
			if ( childrenHas() )
			{
				for each ( child in children )
					child.layDownWater( $waterHeight );
			}
			else if ( TypeInfo.AIR == type )
			{
				type = TypeInfo.WATER;
				//writeFromHeightMap( gc, TypeInfo.AIR );
			}
//				else if ( TypeInfo.DIRT != type )
//					Log.out( "what did I hit? type: " + Globals.Info[type].name );
		}
		else if ( top_height >= $waterHeight && bottom_height < $waterHeight )
		{
			// Still something wrong here...
			
			// This is on the boarder, it needs to be broken up
			// I am seeing app trying to create children on a grain 0 here.
			if ( 0 == gc.grain ) {
				var s:uint = gc.size();	
				s = gc.size();	
			}
			
			if ( !childrenHas() )
			{
				TEMP_COUNT += 8;
				//Log.out( "Oxel.layDownWater - CREATED CHILDREN: " + TEMP_COUNT );
				childrenCreate();
			}

			for each ( child in children)
				child.layDownWater( $waterHeight );
		}
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Explosion Event Helpers START
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Not sure what this does - RSF
	public function breakFromParent():void
	{
		gc.bound = _parent.gc.bound - 1;
		gc.grainX = 0;
		gc.grainY = 0;
		gc.grainZ = 0;
		if ( childrenHas() )
			calculateGC();
		Log.out( "Oxel.breakFromParent - This should NEVER happen " );
		// God know what this should be at this point
//			_vertMan = new VertexManager( gc, null );
		_parent = null;
	}
	
	public function calculateGC():void
	{
		var gct:GrainCursor = GrainCursorPool.poolGet(root_get().gc.bound );
		for ( var i:int = 0; i < OXEL_CHILD_COUNT; i++ )
		{
			gct.copyFrom( gc );
			gct.become_child( i );   
			children[i].gc.copyFrom( gct );
			if ( true == children[i].childrenHas() )
				children[i].calculateGC();
		}
		GrainCursorPool.poolDispose( gct );
		
	}
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Explosion Event Helpers END
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function generateID( $instanceGuid:String ):String {
		return $instanceGuid + _gc.toID();
	}
	
	static public function childIdOpposite( $face:uint, $childID:uint ):uint {
		if ( 0 == $childID ) {
			if ( Globals.NEGX == $face ) return 1;
			if ( Globals.NEGY == $face ) return 2;
			if ( Globals.NEGZ == $face ) return 4;
			trace( "GrainCursor.childIdOpposite - unknown face for childId: " + $childID + "  face: " + $face );
		}
		else if ( 1 == $childID ) {
			if ( Globals.POSX == $face ) return 0;
			if ( Globals.NEGY == $face ) return 3;
			if ( Globals.NEGZ == $face ) return 5;
			trace( "GrainCursor.childIdOpposite - unknown face for childId: " + $childID + "  face: " + $face );
		}
		else if ( 2 == $childID ) {
			if ( Globals.NEGX == $face ) return 3;
			if ( Globals.POSY == $face ) return 0;
			if ( Globals.NEGZ == $face ) return 6;
			trace( "GrainCursor.childIdOpposite - unknown face for childId: " + $childID + "  face: " + $face );
		}
		else if ( 3 == $childID ) {
			if ( Globals.POSX == $face ) return 2;
			if ( Globals.POSY == $face ) return 1;
			if ( Globals.NEGZ == $face ) return 7;
			trace( "GrainCursor.childIdOpposite - unknown face for childId: " + $childID + "  face: " + $face );
		}
		else if ( 4 == $childID ) {
			if ( Globals.NEGX == $face ) return 5;
			if ( Globals.NEGY == $face ) return 6;
			if ( Globals.POSZ == $face ) return 0;
			trace( "GrainCursor.childIdOpposite - unknown face for childId: " + $childID + "  face: " + $face );
		}
		else if ( 5 == $childID ) {
			if ( Globals.POSX == $face ) return 4;
			if ( Globals.NEGY == $face ) return 7;
			if ( Globals.POSZ == $face ) return 1;
			trace( "GrainCursor.childIdOpposite - unknown face for childId: " + $childID + "  face: " + $face );
		}
		else if ( 6 == $childID ) {
			if ( Globals.NEGX == $face ) return 7;
			if ( Globals.POSY == $face ) return 4;
			if ( Globals.POSZ == $face ) return 2;
			trace( "GrainCursor.childIdOpposite - unknown face for childId: " + $childID + "  face: " + $face );
		}
		else if ( 7 == $childID ) {
			if ( Globals.POSX == $face ) return 6;
			if ( Globals.POSY == $face ) return 5;
			if ( Globals.POSZ == $face ) return 3;
			trace( "GrainCursor.childIdOpposite - unknown face for childId: " + $childID + "  face: " + $face );
		}
		else
			trace( "GrainCursor.childIdOpposite - unknown $childID for childId: " + $childID + "  face: " + $face );
		
		return 0;	
	}
	
	static public function locationRandomGet( $o:Oxel ):Vector3D {
		var extent:int = $o.gc.size();
		var loc:Vector3D = new Vector3D();
		loc.x = extent * Math.random();
		loc.y = extent * Math.random();
		loc.z = extent * Math.random();
		return loc;
	}
	
	static public function merge( $o:Oxel ):void {
		var stillNodes:Boolean = true;
		var timer:int;
		while ( stillNodes )
		{
			timer = getTimer();
			Oxel.nodes = 0;
			$o.mergeRecursive();
			if ( 50 > Oxel.nodes )
				stillNodes = false;
			Log.out( "Oxel.LandscapeTask - merging recovered: " + Oxel.nodes + " took: " + (getTimer() - timer) );
		}
	}
	
	
	// This function writes to the root oxel, and lets the root find the correct target
	// it also add flow and lighting
	public function changeOxel( $modelGuid:String, $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean
	{
		// pass in the oxel directly here?
		// requires some refactoring but not hard - RSF
		var oldOxel:Oxel = childGetOrCreate( $gc );
		var oldType:int = oldOxel.type;
		var oldTypeInfo:TypeInfo = TypeInfo.typeInfo[oldType];
		if ( oldOxel.lighting ) {
			if ( oldTypeInfo.lightInfo.lightSource )
				var oldLightID:uint = oldOxel.lighting.lightIDGet();
			if ( oldOxel.lighting.ambientOcculsionHas() ) {
				// We have to do this here before the model changes, this clears out the ambient occulusion from the removed oxel
				for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ ) {
					if ( oldOxel.quads && oldOxel.quads[face] )
						oldOxel.lighting.evaluateAmbientOcculusion( oldOxel, face, Lighting.AMBIENT_REMOVE );
				}
			}
		}
		
		var result:Boolean;
		var changedOxel:Oxel = write( $modelGuid, $gc, $type, $onlyChangeType );
		
		if ( Globals.BAD_OXEL != changedOxel ) {
			changedOxel.dirty = true;
			result = true;
			var typeInfo:TypeInfo = TypeInfo.typeInfo[$type];
		
			if ( typeInfo.flowable ) {
				if ( null == changedOxel.flowInfo ) // if it doesnt have flow info, get some! This is from placement of flowable oxels
					changedOxel.flowInfo = typeInfo.flowInfo.clone();
					
				//if ( Globals.autoFlow && EditCursor.EDIT_CURSOR != $modelGuid )
				if ( Globals.autoFlow  )
					Flow.addTask( $modelGuid, changedOxel.gc, changedOxel.type, changedOxel.flowInfo, 1 );
			}
			else {
				if ( changedOxel.flowInfo )
					changedOxel.flowInfo = null;  // If it has flow info, release it, no need to check first
			}
				
			if ( oldTypeInfo.lightInfo.lightSource )
				LightEvent.dispatch( new LightEvent( LightEvent.REMOVE, $modelGuid, $gc, oldLightID ) );
			if ( typeInfo.lightInfo.lightSource )
				LightEvent.dispatch( new LightEvent( LightEvent.ADD, $modelGuid, $gc, Math.random() * 0xffffffff ) );
			
			if ( TypeInfo.isSolid( oldType ) && TypeInfo.hasAlpha( $type ) ) {
				// we removed a solid block, and are replacing it with air or transparent
				if ( changedOxel.lighting && changedOxel.lighting.valuesHas() )
					LightEvent.dispatch( new LightEvent( LightEvent.SOLID_TO_ALPHA, $modelGuid, changedOxel.gc ) );
			} 
			else if ( TypeInfo.isSolid( $type ) && TypeInfo.hasAlpha( oldType ) ) {
				
				// we added a solid block, and are replacing the transparent block that was there
				if ( changedOxel.lighting && changedOxel.lighting.valuesHas() )
					LightEvent.dispatch( new LightEvent( LightEvent.ALPHA_TO_SOLID, $modelGuid, changedOxel.gc ) );
			}
		}
		
		return result;
	}
} // end of class Oxel
} // end of package
