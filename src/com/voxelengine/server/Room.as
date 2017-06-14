/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.server 
{
import com.voxelengine.events.LoadingImageEvent;
import playerio.Connection;
import playerio.PlayerIOError;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.RoomEvent;

public class Room
{
	static private var _connection:Connection = null;
	static public function connection():Connection { return _connection; }
	
	static public function createJoinRoom( $guid:String ):void
	{
		// Reset the connection
		LoadingImageEvent.create( LoadingImageEvent.CREATE );
		RoomConnection.removeEventHandlers( _connection );
		
		//Set developmentServer (Comment out to connect to your server online)
		if ( ServerConfig.configGetCurrent().localServer ) {
			trace( "joinRoom: start " + Network.client.multiplayer.developmentServer );
			Network.client.multiplayer.developmentServer = "localhost:8184";
			trace( "joinRoom: end " + Network.client.multiplayer.developmentServer );
		}

		//trace("Room.joinRoom - trying to join room at host: " + Network.client.multi-player.developmentServer );
		//Create pr join the room test
		//public function createJoinRoom (roomId:String, roomType:String, visible:Boolean, roomData:Object, joinData:Object, callback:Function=null, errorHandler:Function=null) : void;
		Network.client.multiplayer.createJoinRoom(
			$guid,								//Room id. If set to null a random roomId is used
			ServerConfig.configGetCurrent().gameType, //The game type started on the server
			false,								//Should the room be visible in the lobby?
			{},									//Room data. This data is returned to lobby list. Variables can be modified on the server
			{},									//User join data
			handleJoin,							//Function executed on successful joining of the room
			handleJoinError						//Function executed if we got a join error
		);
		
		function handleJoin(connection:Connection):void {
			Log.out("Room.handleJoin. Successfully joined Room", Log.INFO );
			_connection = connection;
			
			//Add disconnect listener
			_connection.addDisconnectHandler(handleDisconnect);
			
			RoomConnection.addEventHandlers( _connection );
			Globals.inRoom = true;
			RoomEvent.dispatch( new RoomEvent( RoomEvent.ROOM_JOIN_SUCCESS, null, $guid ) );
			
			// This disconnection from room server - Tested - RSF 9.6.14
			function handleDisconnect():void {
				Log.out ("Room.handleDisconnect - Disconnected from server", Log.WARN );
				RoomConnection.removeEventHandlers( _connection );
				Globals.inRoom = false;
				RoomEvent.dispatch( new RoomEvent( RoomEvent.ROOM_DISCONNECT, null, $guid ) );
			}
			LoadingImageEvent.create( LoadingImageEvent.DESTROY );
		}
		
		function handleJoinError(error:PlayerIOError):void
		{
			Log.out( "Room.handleJoinError - Join Room Error: " + error.message, Log.ERROR, error );
			Globals.inRoom = false;
			RoomEvent.dispatch( new RoomEvent( RoomEvent.ROOM_JOIN_FAILURE, error, $guid ) );
			LoadingImageEvent.create( LoadingImageEvent.DESTROY );
		}
	}
	
	// Other possible Room functions
	//public function joinRoom (roomId:String, joinData:Object, callback:Function=null, errorHandler:Function=null) : void;
	//public function createRoom (roomId:String, roomType:String, visible:Boolean, roomData:Object, callback:Function=null, errorHandler:Function=null) : void;
	//public function listRooms (roomType:String, searchCriteria:Object, resultLimit:int, resultOffset:int, callback:Function=null, errorHandler:Function=null) : void;
}	
}
