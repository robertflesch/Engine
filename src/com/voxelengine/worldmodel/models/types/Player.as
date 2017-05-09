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
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.LoginEvent;
import com.voxelengine.persistance.Persistence;
import com.voxelengine.worldmodel.RegionManager;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.inventory.ObjectAction;
import com.voxelengine.worldmodel.inventory.ObjectTool;
import com.voxelengine.worldmodel.models.types.Avatar;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateOxel;

import playerio.DatabaseObject;
import playerio.PlayerIOError;

import com.voxelengine.Log;

import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.server.Network;

import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube;

public class Player extends PersistenceObject
{
	private static var _s_player:Player;
	public static function get player():Player {
		if ( null == _s_player )
				_s_player = new Player();
		return _s_player; }
	//public static function set player( val:Player ):void { _s_player = val; }
	public static var _playerModel:Avatar;
	
	public function Player() {
		super( "local", "PlayerObjects" );
		Log.out( "Player.construct" );
		LoginEvent.addListener( LoginEvent.LOGIN_SUCCESS, onLogin );
		RegionEvent.addListener( RegionEvent.LOAD_COMPLETE, onRegionLoad );
		InventorySlotEvent.addListener( InventorySlotEvent.DEFAULT_REQUEST, defaultSlotDataRequest );

		function onLogin( $event:LoginEvent ):void {
			LoginEvent.removeListener( LoginEvent.LOGIN_SUCCESS, onLogin );
			Log.out( "Player.onLogin - retrieve player info from Persistence", Log.DEBUG );
			// request that the database load the player Object
			Persistence.loadMyPlayerObject( onPlayerLoadedAction, onPlayerLoadError );
		}
	}

	private function onRegionLoad( $re:RegionEvent ):void {
		if ( VoxelModel.controlledModel ) {
			if ( null == Region.currentRegion.modelCache.instanceGet( VoxelModel.controlledModel.instanceInfo.instanceGuid ) )
				RegionEvent.create( RegionEvent.ADD_MODEL, 0, Region.currentRegion.guid, VoxelModel.controlledModel );
		} else {
			ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, playerModelLoaded );
		}
	}



	static public const DEFAULT_PLAYER:String = "DefaultPlayer";
	public function onPlayerLoadedAction( $dbo:DatabaseObject ):void {
		dbo = $dbo;
		if ( $dbo ) {
			if ( null == $dbo.modelGuid ) {
				// Assign the Avatar the default avatar
				$dbo.modelGuid = DEFAULT_PLAYER;

				var userName:String = $dbo.key.substring( 6 );
				var firstChar:String = userName.substr(0, 1);
				var restOfString:String = userName.substr(1, userName.length);
				$dbo.userName = firstChar.toUpperCase() + restOfString.toLowerCase();
				$dbo.description = "New Player Avatar";
				$dbo.modifiedDate = new Date().toUTCString();
				$dbo.createdDate = new Date().toUTCString();
				$dbo.save();
			}
			// Dont modify the modelGuid, change it in the DB if needed
			createPlayer( $dbo.modelGuid, Network.userId );
		}
		else {
			Log.out( "Avatar.onPlayerLoadedAction - ERROR, failed to create new record for new players?" );
		}
	}

	public function createPlayer( $modelGuid:String, $userId:String ):void {

		var ii:InstanceInfo = new InstanceInfo();
		ii.modelGuid = $modelGuid;
		ii.instanceGuid = $userId;
		ii.centerSetComp(7.5, 0, 7.5);

		if (DEFAULT_PLAYER == $modelGuid) {
			//Log.out( "Avatar.createPlayer - creating DEFAULT_PLAYER from GenerateCube", Log.WARN )
			var model:Object = GenerateCube.script(4, TypeInfo.BLUE);
			model.modelClass = "Avatar";
			model.name = "Temp Avatar";
			new ModelMakerGenerate(ii, model)
		}
		else {
			ModelMakerBase.load(ii, false, false);
		}
	}

//	private function modelLoadComplete( $mle:ModelLoadingEvent ):void {
//		if ( Globals.online ) {
//			if (dbo.modelGuid == $mle.modelGuid) {
//				ModelLoadingEvent.removeListener(ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete);
//				_playerModel = $mle.vm as Avatar;
//			}
//		}
//	}

	static public function onPlayerLoadError(error:PlayerIOError):void {
		Log.out("Avatar.onPlayerLoadError", Log.ERROR, error );
	}

	static private function playerModelLoaded( $mle:ModelLoadingEvent ):void {
		if ( $mle.vm && ( $mle.vm.instanceInfo.instanceGuid == Network.userId || $mle.vm.instanceInfo.instanceGuid == Network.LOCAL ) ){
			_playerModel = $mle.vm as Avatar;
			if ( null == Region.currentRegion.modelCache.instanceGet( $mle.vm.instanceInfo.instanceGuid ) ) {
				RegionEvent.create( RegionEvent.ADD_MODEL, 0, Region.currentRegion.guid, $mle.vm );

				// We dont want to remove this listener for the generated event.
				// Only for the model loaded from the DB.
				ModelLoadingEvent.removeListener(ModelLoadingEvent.MODEL_LOAD_COMPLETE, playerModelLoaded);
			}
			$mle.vm.takeControl( VoxelModel.controlledModel, false );
		}
	}

	static private function defaultSlotDataRequest( $ise:InventorySlotEvent ):void {
		// inventory is always on a instance guid.
		if ( VoxelModel.controlledModel.instanceInfo.instanceGuid == $ise.instanceGuid ) {
			InventorySlotEvent.removeListener( InventorySlotEvent.DEFAULT_REQUEST, defaultSlotDataRequest )
			Log.out( "Player.getDefaultSlotData - Loading default data into slots" , Log.WARN );

			var ot:ObjectTool = new ObjectTool( null, "D0D49F95-706B-0E76-C187-DCFD920B8883", "pickToolSlots", "pick.png", "pick" );
			InventorySlotEvent.create( InventorySlotEvent.CHANGE, Network.userId, Network.userId, 0, ot );
			var oa:ObjectAction = new ObjectAction( null, "noneSlots", "none.png", "Do nothing" );
			InventorySlotEvent.create( InventorySlotEvent.CHANGE, Network.userId, Network.userId, 1, oa );


//			for each ( var gun:Gun in _guns )
//				InventorySlotEvent.dispatch( new InventorySlotEvent( InventorySlotEvent.DEFAULT_REQUEST, instanceInfo.instanceGuid, gun.instanceInfo.instanceGuid, 0, null ) );
		}
	}

	/*
	 override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
	 Log.out( "Player.init instanceGuid: " + instanceInfo.instanceGuid + "  --------------------------------------------------------------------------------------------------------------------" );
	 super.init( $mi, $vmm );

	 hasInventory = true;
	 instanceInfo.usesCollision = true;
	 clipVelocityFactor = AVATAR_CLIP_FACTOR;
	 addEventHandlers();
	 takeControl( null );
	 torchToggle();
	 if ( _displayCollisionMarkers )
	 _ct.markersAdd();
	 }
	 */
	/*
	 // When the player stops editing, set movement speed to 1
	 private function changeCursorOperationEvent( e:CursorOperationEvent ):void	{
	 if ( this == VoxelModel.controlledModel ) {
	 VoxelModel.controlledModel.instanceInfo.setSpeedMultipler(1);
	 }
	 }
	 */



	/*
	// Be nice to have the UI driven
	public function torchAdd():void {
		Shader.lightsClear();
		var sl:Lamp = new Lamp();
		//var sl:Torch = new Torch();
		//sl.flicker = true;
		//var sl:RainbowLight = new RainbowLight();
		sl.position = instanceInfo.positionGet.clone();
		sl.position.y += 30;
		sl.position.x += 4;
		Shader.lightAdd( sl ); 
		_torchIndex = 0;
	}
	
	public function torchRemove():void {
		Shader.lightsClear();
	}
	*/
/*
	private function onRegionUnload( le:RegionEvent ):void {
		lastCollisionModelReset();
	}
*/
	private function onCriticalModelLoaded( le:ModelLoadingEvent ):void {
		//ModelEvent.removeListener( ModelEvent.CRITICAL_MODEL_LOADED, onCriticalModelLoaded );
		Log.out( "Player.onCriticalModelLoaded - CRITICAL model" );
		// if there is a critical model, don't turn on gravity until it is loaded 
		// NOTE- RSF - I think this needs to be the OXEL loaded
		gravityOn()
	}

	private function gravityOn():void {
		if ( true == Region.currentRegion.gravity )
			VoxelModel.controlledModel.usesGravity = true;
		else
			VoxelModel.controlledModel.usesGravity = false;
	}

	/*
*/
	/*
	// returns -1 if new position is valid, returns 0-2 if there was collision
	// 0-2 is the number of steps back to take in position queue
	override protected function collisionCheckNew( $elapsedTimeMS:Number, $loc:Location, $collisionCandidate:VoxelModel, $stepUpCheck:Boolean = true ):int {

		//if ( $loc.velocityGet.y != 0 )
		//	Log.out( "Player.collisionCheckNew - ENTER: vel.y: " + instanceInfo.velocityGet.y );
		var foot:int = 0;
		var body:int = 0;
		var head:int = 0;
		var fall:int = 0;
		// reset all the points to be in a non collided state
		_ct.setValid();
		var points:Vector.<CollisionPoint> = _ct.collisionPoints();
		// the amount that the test point pushes forward from current position
		// currently basing it on velocity in Z dir
		const LOOK_AHEAD:int = 10;
		var velocityScale:Number = $loc.velocityGet.z * LOOK_AHEAD;
		
		for each ( var cp:CollisionPoint in points )
		{
			if ( cp.scaled )
				cp.scale( velocityScale );
				
			// takes the cp point which is in model space, and puts it in world space
			var posWs:Vector3D = $loc.modelToWorld( cp.pointScaled );
			
			// pass in the world space coordinate to get back whether the oxel at the location is solid
			$collisionCandidate.isSolidAtWorldSpace( cp, posWs, MIN_COLLISION_GRAIN, this );
			// if collided, increment the count on that collision point set
			if ( true == cp.collided )
			{
				if ( FALL == cp.name ) fall++;
				else if ( FOOT == cp.name ) foot++;
				else if ( BODY == cp.name ) body++;
				else if ( HEAD == cp.name ) head++;
			}
		}
		// fall point is in space! falling....
		if ( !fall )
		{
			//Log.out( "Player.collisionCheckNew - fall" );
			//Log.out( "Player.collisionCheckNew - FALL fall = 0, foot=0, stepUp: " + $stepUpCheck + " velocityGet.y: " + $loc.velocityGet.y );
			if ( usesGravity )
			{
				this.fall( $loc, $elapsedTimeMS );
			}
			
			onSolidGround = false;
			if ( foot || body || head )
			{
				if ( mMaxFallRate > $loc.velocityGet.y && usesGravity )
					$loc.velocitySetComp( 0, $loc.velocityGet.y + (0.0033333333333333 * $elapsedTimeMS) + 0.5, 0 );
				
				return -1;
			}
			return -1;
		}
		
		// Everything is clear
		if ( !head && !foot && !body )
		{
			//Log.out( "Player.collisionCheckNew - all good" );
			return -1;
		}
		else if ( foot && !body && !head )
		{
			//Log.out( "Player.collisionCheckNew - foot" );
			lastCollisionModel = $collisionCandidate;
			onSolidGround = true;
			$loc.velocityResetY();
			
			// oxel that fall point is in
			var go:Oxel = points[0].oxel;
			// its localation in MS (ModelSpace)
			var msCoord:int = go.gc.getModelY();
			// add its height in MS
			msCoord += go.size_in_world_coordinates();
			// if foot oxel, then there are two choices
			// 1) foot is in ground, in which case we should adjust avatars position
			// 2) there is a step up chance
			
			// oxel that foot point is in
			var fo:Oxel = points[1].oxel;
			var msCoordFoot:int = fo.gc.getModelY();
			msCoordFoot += fo.size_in_world_coordinates();
			// we need to do minor adjustment on foot position?
			if ( fo.gc.grain == go.gc.grain && fo.gc.grainY == go.gc.grainY || msCoord == msCoordFoot )
			{
				//Log.out( "Player.collisionCheckNew - FOOT in solid ground adjusting foot height" );
				// add its height in MS
				msCoord = msCoordFoot;
				_sScratchVector.setTo( 0, msCoord, 0 );
				var wsCoord:Vector3D = $collisionCandidate.modelToWorld( _sScratchVector );
				$loc.positionSetComp( $loc.positionGet.x, wsCoord.y, $loc.positionGet.z );	
				//Log.out( "Player.collisionCheckNew - FOOT in solid ground adjusting foot height to: " + wsCoord.y );
				return -1;
			}
			else // step up chance
			{
				var stepUpSize:int = msCoordFoot - msCoord;
				if ( 0 == stepUpSize )
				{
					Log.out( "Player.collisionCheckNew - REJECT - step up size is 0 why? " + stepUpSize );
					return 0;
				}
				else if ( STEP_UP_MAX < stepUpSize )
				{
					Log.out( "Player.collisionCheckNew - REJECT - step TOO large: " + stepUpSize );
					return 0;
				}
				
				const STEP_SIZE_GRAIN:int = 4;
				if ( STEP_SIZE_GRAIN == fo.gc.grain )
				{
					var stepUpOxel:Oxel = fo.neighbor(Globals.POSY);
					if ( stepUpOxel.childrenHas() )
					{
						Log.out( "Player.collisionCheckNew - REJECT - step has kids or is solid: " + stepUpSize + " need a more detailed examination of children" );
						return 0;
					}
				}
				else if ( STEP_SIZE_GRAIN > fo.gc.grain ) // This grain is too small, bump up to STEP_SIZE
				{
					Log.out( "Player.collisionCheckNew - step smaller then l meter:" );
					var stepUpOxel1:Oxel = fo.neighbor(Globals.POSY);
					if ( Globals.BAD_OXEL != stepUpOxel1 )
					{
						var msCoordFoot1:int = stepUpOxel1.gc.getModelY();
						msCoordFoot1 += stepUpOxel1.size_in_world_coordinates();
						_sScratchVector.setTo( 0, msCoordFoot1, 0 );
						var wsCoord1:Vector3D = $collisionCandidate.modelToWorld( _sScratchVector );
						$loc.positionSetComp( $loc.positionGet.x, wsCoord1.y, $loc.positionGet.z );	
						Log.out( "Player.collisionCheckNew - step  too small: adjusting foot height to: " + wsCoord1.y );
						return -1;
//						Log.out( "Player.collisionCheckNew - REJECT - step  too small: " + fo.gc.grain + " need a more detailed examination of children" );
//						return 0;
					}
				}
				//Log.out( "Player.collisionCheckNew - PASS stepupSize: " + stepUpSize + " ADDING transform" );
				
				// Dont like adding this to instance info... when everything else is using loc
				jump( 1 );
			}
		}
		else if ( ( head || body ) && !foot )
		{
			// We probably jumped up into something
			//Log.out( "Player.collisionCheckNew - HEAD failed to clear" );
			return 2;
		}
		else if ( head && body && foot )
		{
			// Wall crawling
			//Log.out( "Player.collisionCheckNew - EVERYTHING failed to clear" );
			return 0;
		}
		else if ( head || body || foot )
		{
			Log.out( "Player.collisionCheckNew - something failed to clear foot:" + foot + " body: " + body + " head: " + head );
			return 1;
		}
		Log.out( "Player.collisionCheckNew - ALL CLEAR" );
		return -1;
	}
	*/
	/*
	public function collisionCheckOLD():void {
		var collided:Boolean = false;
		var pt:PositionTest = isPositionValid( lastCollisionModel );
		if ( pt.isNotValid() )
		{
//				Log.out( "Player.collisionCheck PositionTest: " + pt.toString() );

			// head is clear, chest is clear, foot is blocked
//			if ( pt.head && pt.chest && !pt.foot )
//			{
//				trace( "Player.collisionCheck step up chance" );
//				// if a step up pts in a legal foot position, then test with that foot position
//				if ( pt.footHeight <= instanceInfo.positionGet.y + STEP_UP_MAX )
//				{
//					// now I need to retest head, chest and foot in new position
//					instanceInfo.positionSetComp( instanceInfo.positionGet.x, pt.footHeight, instanceInfo.positionGet.z );
//					pt = isPositionValid( lastCollisionModel );
//					// if the body in the new position is not all valid, we will get stuck
//					if ( !pt.head || !pt.chest || !pt.foot )
//						collided = true;
//				}
//				else
//					collided = true;
//
//				//resetVelocities();
//			}
//			// if head OR chest OR foot is blocked, we are blocked
//			else if ( !pt.head || !pt.chest || !pt.foot )
//			{
//				// TODO Should consider redirecting the velocity to an angle orthagonal to the face
//				collided = true;
//				// ok I see why you continue up to wall after you hit the first time.
//				// since the velocity is being reset, the slower speed alows you to get a bit closer before colliding.
//			}
		}
//			else
//				trace( "Player.collisionCheck NO Collided at: " + pt.position );
	
		if ( usesGravity && lastCollisionModel )
		{
			// if the model is falling, let it, RSF I think this is supposed to be where the parent model is falling.
			if ( instanceInfo.positionGet.y < instanceInfo.positionGet.y )
			{
				Log.out( "Player.collisionCheck instanceInfo.usesGravity && lastCollisionModel: " + pt.toString() );
				instanceInfo.positionSetComp( instanceInfo.positionGet.x, instanceInfo.positionGet.y, instanceInfo.positionGet.z );
			}
		}
		
//			if ( $collisionModel )
//			{
//				Log.out( "InstanceInfo.collisionCheck - What is this doing here??? " + $collisionModel.worldToModel( instanceInfo.positionGet ), Log.ERROR );
			//lastModelPosition = $collisionModel.worldToModel( positionGet );
			//lastModelRotation = $collisionModel.instanceInfo.rotationGet;
//			}
		
		// if collided set position back to original
		if ( pt.isNotValid() )
		{
			instanceInfo.restoreOld();
			instanceInfo.velocityReset();
		}
	}		
	*/
	/* applyGravityNew
	private	function applyGravityNew( $elapsedTimeMS:int ):void
	{
		onSolidGround = false;
		var leastFallDistance:Vector3D = new Vector3D( 0, 1, 0 );
		// if we are not in any models influence, then reset lastModelInfo
		// Test of position for use in object movement				
		for each ( var collisionCandidate:VoxelModel in _collisionCandidates )
		{
			if ( instanceInfo.usesGravity )
			{
				var fallDistance:Vector3D = calculateFallDueToGravity( collisionCandidate, $elapsedTimeMS );
				//trace( "Player.applyGravity: " + fallDistance.length );
				if ( 0 == fallDistance.length )
				{
					leastFallDistance = fallDistance;
					lastCollisionModel = collisionCandidate;
					onSolidGround = true;
					Log.out( "Player.applyGravity - OnSolidGround keys: " + InstanceInfo.s_velocityFromKeys.y + "  vel: " + instanceInfo.velocity.y );
					break;
				}
				else if ( fallDistance.length < leastFallDistance.length ) 
				{
					leastFallDistance = fallDistance;
					lastCollisionModel = collisionCandidate;
					onSolidGround = true;
					instanceInfo.velocityResetY();
					Log.out( "Player.applyGravity - FALLING", Log.ERROR );
				}
			}
			else
			{
				// TODO Take the last model in the list, yuck!
				lastCollisionModel = collisionCandidate;
			}
		}
		
		if ( instanceInfo.usesGravity && !onSolidGround )
		{
			// Still nothing at a full 2 units, so fall baby, fall.
			if ( -5 < instanceInfo.velocity.y )
				instanceInfo.velocity.y = leastFallDistance.y;
//					instanceInfo.velocity.y += leastFallDistance.y;
			// You have fallen off something, keep going till you hit!
			if ( instanceInfo.positionGet.y < -10000 )
				instanceInfo.reset();
		}
	}
	*/
	/* calculateFallDueToGravityNew
	public function calculateFallDueToGravityNew( collisionModel:VoxelModel, elapsedTimeMS:int ):Vector3D
	{
		var result:Vector3D = new Vector3D();
		var hitSolid:Boolean = false;
		var points:Vector.<CollisionPoint> = _ct.collisionPoints();
		for each ( var cp:CollisionPoint in points )
		{
			if ( FOOT == cp.name )
			{
				// takes the cp point which is in model space, and puts it in world space
				var fallPoint:Vector3D = cp.point.clone();
				fallPoint.y -= 2;
				var posWs:Vector3D = modelToWorld( fallPoint );
				// pass in the world space coordinate to get back whether the oxel at the location is solid
				if ( collisionModel.isSolidAtWorldSpace( posWs, MIN_COLLISION_GRAIN ) )
				{
					hitSolid = true;
					break;
				}
			}
		}
		
		if ( hitSolid )
		{
			// what is first valid spot beneath me?
			result.setTo( _gravityScalar.x, _gravityScalar.y, _gravityScalar.z );
		}
		return result;
	}
	*/
	/* applyGravity
	private	function applyGravity( $elapsedTimeMS:int ):void
	{
		onSolidGround = false;
		var leastFallDistance:Vector3D = new Vector3D( 0, 1, 0 );
		// if we are not in any models influence, then reset lastModelInfo
		// Test of position for use in object movement				
		for each ( var collisionCandidate:VoxelModel in _collisionCandidates )
		{
			if ( instanceInfo.usesGravity )
			{
				var fallDistance:Vector3D = calculateFallDueToGravity( collisionCandidate, $elapsedTimeMS );
				//trace( "Player.applyGravity: " + fallDistance.length );
				if ( fallDistance.length < leastFallDistance.length ) 
				{
					leastFallDistance = fallDistance;
					// IS this needed for anything?
					//if ( lastCollisionModel != collisionCandidate )
					//{
						//if ( _lastCollisionModel )
							//Log.out( "Player.update - changing collision model from: " + _lastCollisionModel.instanceInfo.modelGuid + " to " + collisionCandidate.instanceInfo.modelGuid );
						//else	
							//Log.out( "Player.update - first collision model: " );
		
							
						//instanceInfo.lastModelPosition = collisionCandidate.worldToModel( instanceInfo.positionGet );
						//instanceInfo.lastModelRotation = collisionCandidate.instanceInfo.rotationGet;
					//}
					lastCollisionModel = collisionCandidate;
					onSolidGround = true;
					//trace( "Player.applyGravity: velocityResetY" );
					instanceInfo.velocityResetY();
					//Log.out( "Player.applyGravity - velocityResetY??? ", Log.ERROR );
				}
			}
			else
			{
				lastCollisionModel = collisionCandidate;
			}
		}
		
		if ( instanceInfo.usesGravity && 0 < leastFallDistance.length )
		{
			// Still nothing at a full 2 units, so fall baby, fall.
			if ( -5 < instanceInfo.velocityGet.y )
				instanceInfo.velocitySetComp( instanceInfo.velocityGet.x, instanceInfo.velocityGet.y + leastFallDistance.y, instanceInfo.velocityGet.z );
			// You have fallen off something, keep going till you hit!
			if ( instanceInfo.positionGet.y < -10000 )
				instanceInfo.reset();
		}
	}
	
	public function calculateFallDueToGravity( collisionModel:VoxelModel, elapsedTimeMS:int ):Vector3D
	{
		var result:Vector3D = new Vector3D();
		if ( collisionModel )
		{
			var eyeLevelModelSpacePosition:Vector3D = collisionModel.worldToModel( instanceInfo.positionGet );
			var leftFoot:Vector3D  = instanceInfo.lookRightVector( HIPWIDTH );
			leftFoot.x = eyeLevelModelSpacePosition.x + leftFoot.x;
			leftFoot.y = eyeLevelModelSpacePosition.y - Globals.AVATAR_HEIGHT_FOOT;
			leftFoot.z = eyeLevelModelSpacePosition.z + leftFoot.z;

			var rightFoot:Vector3D = instanceInfo.lookRightVector(  -HIPWIDTH );
			rightFoot.x = eyeLevelModelSpacePosition.x + rightFoot.x;
			rightFoot.y = eyeLevelModelSpacePosition.y - Globals.AVATAR_HEIGHT_FOOT;
			rightFoot.z = eyeLevelModelSpacePosition.z + rightFoot.z;
			
			var gct0:GrainCursor = GrainCursorPool.poolGet( collisionModel.oxel.gc.bound );
			const collideAtGrain:int = 2; // collide at 1/4 meter level, TODO how to get this in UNITS_PER_METER? too latein the night
			
			// This is a grain 2 down from my foot.
			var pt:PositionTest = new PositionTest();
			pt.type = PositionTest.FOOT;
			const testDistance:int = 2;
			var leftFootEmpty:Boolean = collisionModel.isPassableAvatar( leftFoot.x, leftFoot.y - testDistance, leftFoot.z, gct0, collideAtGrain, pt );
			var rightFootEmpty:Boolean = collisionModel.isPassableAvatar( rightFoot.x, rightFoot.y - testDistance, rightFoot.z, gct0, collideAtGrain, pt );

			if ( leftFootEmpty && rightFootEmpty )
			{
				//Log.out( "ApplyGravity - both feet are not solid" );
				// lets do a sanity check and check between the feet too
				var betweenFeet:Boolean = collisionModel.isPassableAvatar( eyeLevelModelSpacePosition.x, rightFoot.y - testDistance, eyeLevelModelSpacePosition.z, gct0, collideAtGrain, pt );
				if ( betweenFeet )
				{
					leftFoot.incrementBy( _gravityScalar );
					leftFootEmpty = collisionModel.isPassableAvatar( leftFoot.x, leftFoot.y , leftFoot.z, gct0, collideAtGrain, pt );
					if ( leftFootEmpty )
					{
						result.setTo( _gravityScalar.x, _gravityScalar.y, _gravityScalar.z );
					}
					else
					{
						result.setTo( _gravityScalar.x, _gravityScalar.y, _gravityScalar.z );
						result.scaleBy(0.5);
					}
				}
			}
			GrainCursorPool.poolDispose( gct0 );
		}
		else
		{
			result.setTo( _gravityScalar.x, _gravityScalar.y, _gravityScalar.z );
		}
		return result;
	}
	*/
	
}
}
