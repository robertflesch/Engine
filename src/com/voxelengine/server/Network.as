package com.voxelengine.server 
{
	import playerio.Client;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.LoginEvent;
	
	public class Network
	{
		// VV messages
		static public const MOVE_MESSAGE:String = "mov";
		static public const PROJECTILE_SHOT_MESSAGE:String = "psm";
		static public const YOUR_ID:String = "yid";
		static public const ADD_ME:String = "add";
		public static const PUBLIC:String = "public";
		
		// PlayerIO Messages
		static public const USER_JOINED:String = "UserJoined";

		static private var _client:Client;	
		static public function get client():Client { return _client; };
		static public function set client( val:Client ):void { _client = val; };
		
		static public var _userId:String;
		static public function get userId():String { return _userId; };
		static public function set userId( val:String ):void { _userId = val; };
		
		static private var _startingRegionGuid:String;
		// This was a test to see if I could make a client that didnt need user interaction.
		// This will allow me to do things like post to Facebook things that users create.
		static public function autoLogin( $startingRegionGuid:String ):void {
			_startingRegionGuid = $startingRegionGuid;
			PlayerIO.quickConnect.simpleConnect( Globals.g_app.stage
											   , Globals.g_gamesNetworkID
											   , "bob@me.com"
											   , "bob"
											   , connectSuccess
											   , function (error:PlayerIOError):void { Log.out( "Network.autoLogin - FAILED TO AUTOLOGIN: " + error.message, Log.ERROR, error ); }
											   );
											   
			function connectSuccess( $client:Client):void
			{
				Log.out("Network.connectSuccess - connection to server established using AUTOLOGIN", Log.DEBUG );
				Network.userId = $client.connectUserId;
				Network.client = $client
				Globals.online = true;
				
				Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.LOGIN_SUCCESS, null, _startingRegionGuid ) );
			}
		}
	}	
}
