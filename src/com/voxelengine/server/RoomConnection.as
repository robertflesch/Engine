/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.server {

	import com.voxelengine.events.AmmoEvent;
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.worldmodel.models.types.Player;
	import flash.geom.Vector3D;
	import playerio.Connection;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;
	import playerio.Message;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.ProjectileEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.models.types.Avatar;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	
	public class RoomConnection
	{
		// VV messages
		static public const MOVE_MESSAGE:String = "mov";
		static public const PROJECTILE_SHOT_MESSAGE:String = "psm";
		static public const YOUR_ID:String = "yid";
		static public const ADD_ME:String = "add";
		
		// PlayerIO Messages
		static public const USER_JOINED:String = "UserJoined";
		
		static private var _connection:Connection = null;
		static public function addEventHandlers( $connection:Connection = null ):void
		{
			if ( null != $connection )
			{
				_connection = $connection;
				
				// Add my avatar to your system
				_connection.addMessageHandler( ADD_ME, addMeMessage );

				_connection.addMessageHandler( MOVE_MESSAGE, handleMoveMessage );
				// Add message listener for users joining the room
				_connection.addMessageHandler( USER_JOINED, userJoinedMessage );
				// A user (could be me ) shoots a projectile
				_connection.addMessageHandler( PROJECTILE_SHOT_MESSAGE, handleProjectileEvent );
				//Listen to all messages using a private function
				//_connection.addMessageHandler("*", handleMessages)
				
				
				//Add message listener for users leaving the room
				_connection.addMessageHandler("UserLeft", function(m:Message, userid:uint):void{
					Log.out("Player with the userid: " + userid + "just left the room", Log.DEBUG ); } );
					
				// Only need this if we are online
				ModelEvent.addListener( ModelEvent.MOVED, sourceMovementEvent );
			}
				
			Globals.g_app.addEventListener( ProjectileEvent.PROJECTILE_SHOT, sourceProjectileEvent );
		}
		
		static public function removeEventHandlers( $connection:Connection = null ):void {
			if ( null != $connection )
			{
				// Add my avatar to your system
				$connection.removeMessageHandler( ADD_ME, addMeMessage );

				$connection.removeMessageHandler( MOVE_MESSAGE, handleMoveMessage );
				// Add message listener for users joining the room
				$connection.removeMessageHandler( USER_JOINED, userJoinedMessage );
				// A user (could be me ) shoots a projectile
				$connection.removeMessageHandler( PROJECTILE_SHOT_MESSAGE, handleProjectileEvent );
				//Listen to all messages using a private function
				//$connection.removeMessageHandler("*", handleMessages)
				
				
				//Add message listener for users leaving the room
				$connection.removeMessageHandler("UserLeft", function(m:Message, userid:uint):void{
					Log.out("Player with the userid: " + userid + "just left the room", Log.DEBUG ); } );
					
				// Only need this if we are online
				ModelEvent.removeListener( ModelEvent.MOVED, sourceMovementEvent );
			}
				
			Globals.g_app.removeEventListener( ProjectileEvent.PROJECTILE_SHOT, sourceProjectileEvent );
		}
		
		static private function sourceMovementEvent( event:ModelEvent ):void
		{
			//trace("RoomConnection.handleMovementEvent - Received move event: " + event)
			var msg:Message = _connection.createMessage( MOVE_MESSAGE );
			msg.add( Network.userId );
			msg.add( event.position.x, event.position.y, event.position.z );
			msg.add( event.rotation.x, event.rotation.y, event.rotation.z );
			_connection.sendMessage( msg );
		}
		
		static private function sourceProjectileEvent( event:ProjectileEvent ):void
		{
			if ( Globals.online )
			{
				var msg:Message = _connection.createMessage( PROJECTILE_SHOT_MESSAGE );
				msg.add( Network.userId );
				msg.add( event.position.x, event.position.y, event.position.z );
				msg.add( event.direction.x, event.direction.y, event.direction.z );
				event.ammo.addToMessage( msg );
				//trace( "sourceProjjectileEvent: " + msg );
				_connection.sendMessage( msg );
			}
			else
			{
				// Since server is not handling it, change type here
				var pe:ProjectileEvent = event.changeType( ProjectileEvent.PROJECTILE_CREATED );
				Globals.g_app.dispatchEvent( pe );
			}
		}
		
		// I dont like this, but it is expident.
		static private var _s_pe:ProjectileEvent;
		static private function handleProjectileEvent( msg:Message ):void
		{
			
			_s_pe = new ProjectileEvent( ProjectileEvent.PROJECTILE_CREATED );
			var index:int = 0;
			_s_pe.owner = msg.getString( index++ );
			_s_pe.position = new Vector3D( msg.getNumber( index++ ), msg.getNumber( index++ ), msg.getNumber( index++ ) );			
			_s_pe.direction = new Vector3D( msg.getNumber( index++ ), msg.getNumber( index++ ), msg.getNumber( index++ ) );			
			var ammoGuid:String = msg.getString( index );
			AmmoEvent.addListener( ModelBaseEvent.RESULT, ammoDataRecieved );
			AmmoEvent.dispatch( new AmmoEvent( ModelBaseEvent.REQUEST, 0, ammoGuid, null ) );
			//index = _s_pe.ammo.fromMessage( msg, index );
			//trace( "handleProjjectileEvent: " + pe );
		}
		
		static private function ammoDataRecieved(e:AmmoEvent):void {
			AmmoEvent.removeListener( ModelBaseEvent.RESULT, ammoDataRecieved );
			_s_pe.ammo = e.ammo;
			Globals.g_app.dispatchEvent( _s_pe );
			_s_pe = null;
		}
		
		
		static private function addMeMessage(m:Message):void
		{
			Log.out("RoomConnection.addMeMessage - avatar for :" + m, Log.DEBUG );
			createAvatar( m.getString(1) );
		}
		
		static private function createPlayer( userid:String ):void
		{
			throw new Error( "RoomConnection.createPlayer - NOT IMPLMENTED" );
			Log.out("RoomConnection.createPlayer - create player model for :" + userid, Log.DEBUG );
		}
		
		static private function createAvatar( userid:String ):void
		{
			throw new Error( "RoomConnection.createAvatar - NOT IMPLMENTED" );
			Log.out("RoomConnection.createAvatar - create avatar for :" + userid, Log.DEBUG );
		}
		
		static private function userJoinedMessage( $m:Message, $userid:String):void
		{
			Log.out("RoomConnection.userJoinedMessage - Player with the userid: " + $userid + "  just joined the room -- Network.userId: " + Network.userId );
			if ( Network.userId != $userid )
			{
				Log.out("RoomConnection.userJoinedMessage - ANOTHER PLAYER LOGGED ON", Log.DEBUG );
				createPlayer( $userid );
				
				var addMe:Message = _connection.createMessage( ADD_ME );
				addMe.add( $userid );
				addMe.add( Network.userId );
				_connection.sendMessage( addMe );

				// We need to send a message to put our avatar in the correct starting location
				var ae:ModelEvent = new ModelEvent( 
				                 ModelEvent.MOVED
							   , Network.userId
							   , Player.player.instanceInfo.positionGet
							   , Player.player.instanceInfo.rotationGet );
				sourceMovementEvent( ae );			   
			}
		}
		
		//static private function createPlayerAfterRegionLoad( $e:RegionEvent ):void {
			//RegionEvent.removeListener( RegionEvent.LOAD_BEGUN, createPlayerAfterRegionLoad );
			//Globals.createPlayer();
		//}
				
		static private function handleMoveMessage(m:Message):void
		{
			var userid:String = m.getString(0);
			if ( Network.userId != userid ) {
				//trace("RoomConnection.handleMoveMessage - Received move message", m);
				var am:Avatar = Region.currentRegion.modelCache.instanceGet( userid ) as Avatar;
				if ( am )
				{
					var pos:Vector3D = new Vector3D( m.getNumber( 1 ), m.getNumber( 2 ), m.getNumber( 3 ) );
					am.instanceInfo.positionSet = pos;
				}
			}
			//else	
			//	trace("RoomConnection.handleMoveMessage - Ignoring move messages for self")
		}
	}	
}
