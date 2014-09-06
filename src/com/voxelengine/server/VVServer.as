﻿package com.voxelengine.server 
{
	import com.voxelengine.Globals;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.Log;
	import playerio.Client;
	import playerio.Connection;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;
	import playerio.Message;
	
	public class VVServer
	{
		static private var _connection:Connection = null;
		static public function connection():Connection { return _connection; }
		
		static public var regionId:String;
/*		
		static public function connect( email:String, password:String ):void
		{
			PlayerIO.connect(
				Globals.g_app.stage,				//Referance to stage
				"voxelverse-lpeje46xj0krryqaxq0vog",//Game id (Get your own at playerio.com)
				"public",							//Connection id, default is public
				email,								//Username
				"",									//User auth. Can be left blank if authentication is disabled on connection
				null,								//Current PartnerPay partner.
				connectSuccess,						//Function executed on successful connect
				connectFailure					//Function executed if we recive an error
			);   
		}
*/		
		static public function joinRoom( $regionId:String ):void
		{
			//trace("VVServer.connectSuccess - connection to server established");
			//
			//Set developmentsever (Comment out to connect to your server online)
			//$client.multiplayer.developmentServer = "localhost:8184";
			//Network.userId = $client.connectUserId;
			//Network.client = $client
			//Set developmentsever (Comment out to connect to your server online)
			//trace( "joinRoom: " + Network.client.multiplayer.developmentServer );
			Network.client.multiplayer.developmentServer = "localhost:8184";
			//trace( "joinRoom: " + Network.client.multiplayer.developmentServer );
			
			// Save the region id for when we need to load the region.
			regionId = $regionId;
			
			trace("VVServer.joinRoom - trying to join room at host: " + Network.client.multiplayer.developmentServer );
			//Create pr join the room test
			Network.client.multiplayer.createJoinRoom(
				regionId,							//Room id. If set to null a random roomid is used
				"VoxelVerse",							//The game type started on the server
				true,								//Should the room be visible in the lobby?
				{},									//Room data. This data is returned to lobby list. Variabels can be modifed on the server
				{},									//User join data
				handleJoin,							//Function executed on successful joining of the room
				handleJoinError						//Function executed if we got a join error
			);
		}
		
		static private function handleJoinError(error:PlayerIOError):void
		{
			trace("VVServer.handleJoinError",error)
			Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.LOGIN_FAILURE, error ) );
		}
		
		static private function handleJoin(connection:Connection):void
		{
			
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_LOAD, regionId ) );
			
			trace("VVServer.handleJoin. Sucessfully joined Room");
			_connection = connection;
			
			//Add disconnect listener
			_connection.addDisconnectHandler(handleDisconnect);
			
			EventHandlers.addEventHandlers( _connection );
		}
		
		// This disconnection from room server - Tested - RSF 9.6.14
		static private function handleDisconnect():void
		{
			Log.out ("VVServer.handleDisconnect - Disconnected from server", Log.WARN );
			Globals.online = false;
		}
		
	}	
}
