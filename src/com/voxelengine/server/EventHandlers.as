package com.voxelengine.server {

	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.events.ProjectileEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.Avatar;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import flash.geom.Vector3D;
	import playerio.Connection;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;
	import playerio.Message;
	
	public class EventHandlers
	{
		static private var _connection:Connection = null;
		static public function addEventHandlers(connection:Connection = null):void
		{
			if ( null != connection )
			{
				_connection = connection;
				
				// Add my avatar to your system
				_connection.addMessageHandler( Network.ADD_ME, addMeMessage );

				_connection.addMessageHandler( Network.MOVE_MESSAGE, handleMoveMessage );
				// Add message listener for users joining the room
				_connection.addMessageHandler( Network.USER_JOINED, userJoinedMessage );
				// A user (could be me ) shoots a projectile
				_connection.addMessageHandler( Network.PROJECTILE_SHOT_MESSAGE, handleProjectileEvent );
				//Listen to all messages using a private function
				//_connection.addMessageHandler("*", handleMessages)
				
				
				//Add message listener for users leaving the room
				connection.addMessageHandler("UserLeft", function(m:Message, userid:uint):void{
					Log.out("Player with the userid: " + userid + "just left the room", Log.DEBUG ); } );
					
				// Only need this if we are online
				Globals.g_app.addEventListener( ModelEvent.MOVED, sourceMovementEvent );
			}
				
			Globals.g_app.addEventListener( ProjectileEvent.PROJECTILE_SHOT, sourceProjectileEvent );
		}
		
		static private function sourceMovementEvent( event:ModelEvent ):void
		{
			//trace("EventHandler.handleMovementEvent - Received move event: " + event)
			var msg:Message = _connection.createMessage( Network.MOVE_MESSAGE );
			msg.add( Network.userId );
			msg.add( event.position.x, event.position.y, event.position.z );
			msg.add( event.rotation.x, event.rotation.y, event.rotation.z );
			_connection.sendMessage( msg );
		}
		
		static private function sourceProjectileEvent( event:ProjectileEvent ):void
		{
			if ( Globals.online )
			{
				var msg:Message = _connection.createMessage( Network.PROJECTILE_SHOT_MESSAGE );
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
		
		static private function handleProjectileEvent( msg:Message ):void
		{
			var pe:ProjectileEvent = new ProjectileEvent( ProjectileEvent.PROJECTILE_CREATED );
			var index:int = 0;
			pe.owner = msg.getString( index++ );
			pe.position = new Vector3D( msg.getNumber( index++ ), msg.getNumber( index++ ), msg.getNumber( index++ ) );			
			pe.direction = new Vector3D( msg.getNumber( index++ ), msg.getNumber( index++ ), msg.getNumber( index++ ) );			
			index = pe.ammo.fromMessage( msg, index );
			//trace( "handleProjjectileEvent: " + pe );
			Globals.g_app.dispatchEvent( pe );
		}
		
		
		static private function addMeMessage(m:Message):void
		{
			Log.out("EventHandler.addMeMessage - avatar for :" + m, Log.DEBUG );
			createAvatar( m.getString(1) );
		}
		
		static private function createPlayer( userid:String ):void
		{
			var ii:InstanceInfo = new InstanceInfo();
			ii.guid = userid;
			ii.guid = "Player";
			//ii.name = userid;
			ModelLoader.load( ii );
			Log.out("EventHandler.createPlayer - create player model for :" + userid, Log.DEBUG );
		}
		
		static private function createAvatar( userid:String ):void
		{
			var ii:InstanceInfo = new InstanceInfo();
			ii.guid = userid;
			ii.guid = "Player"; // Avatar
			//ii.name = userid;
			ModelLoader.load( ii );
			Log.out("EventHandler.createAvatar - create avatar for :" + userid, Log.DEBUG );
		}
		
		static private function userJoinedMessage( $m:Message, $userid:String):void
		{
			//trace("EventHandler.userJoinedMessage - Player with the userid", userid, "just joined the room -- Network.userId: " + Network.userId );
			if ( Network.userId != $userid )
			{
				Log.out("EventHandler.userJoinedMessage - ANOTHER PLAYER LOGGED ON", Log.DEBUG );
				createPlayer( $userid );
				
				var addMe:Message = _connection.createMessage( Network.ADD_ME );
				addMe.add( $userid );
				addMe.add( Network.userId );
				_connection.sendMessage( addMe );

				// We need to send a message to put our avatar in the correct starting location
				var ae:ModelEvent = new ModelEvent( 
				                 ModelEvent.MOVED
							   , Network.userId
							   , Globals.player.instanceInfo.positionGet
							   , Globals.player.instanceInfo.rotationGet );
				sourceMovementEvent( ae );			   
			}
			else 
			{
				// This is ME!
				Log.out("EventHandler.userJoinedMessage - Recieved message that I logged on " + $userid, Log.DEBUG );	
				if ( !Globals.player )
					if ( false == Globals.createPlayer() )
						Globals.g_app.addEventListener( RegionEvent.REGION_LOAD_BEGUN, createPlayerAfterRegionLoad );
				else	
					Log.out("EventHandler.userJoinedMessage - MY GHOST IS ALREADY ON!!!" + $userid, Log.DEBUG );	
			}
		}
		
		static private function createPlayerAfterRegionLoad( $e:RegionEvent ):void {
			Globals.g_app.removeEventListener( RegionEvent.REGION_LOAD_BEGUN, createPlayerAfterRegionLoad );
			Globals.createPlayer();
		}
				
		static private function handleMoveMessage(m:Message):void
		{
			var userid:String = m.getString(0);
			if ( Network.userId != userid ) {
				//trace("EventHandler.handleMoveMessage - Received move message", m);
				var am:Avatar = Globals.getModelInstance( userid ) as Avatar;
				if ( am )
				{
					var pos:Vector3D = new Vector3D( m.getNumber( 1 ), m.getNumber( 2 ), m.getNumber( 3 ) );
					am.instanceInfo.positionSet = pos;
				}
			}
			//else	
			//	trace("EventHandler.handleMoveMessage - Ignoring move messages for self")
		}
	}	
}
