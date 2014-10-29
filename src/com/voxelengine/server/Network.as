/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
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
		
		static private var _userId:String;
		static public function get userId():String { return _userId; };
		static public function set userId( val:String ):void { _userId = val; };
		
		// This was a test to see if I could make a client that didnt need user interaction.
		// This will allow me to do things like post to Facebook things that users create.
		static public function autoLogin( $startingRegionGuid:String ):void {
			PlayerIO.quickConnect.simpleConnect( Globals.g_app.stage
											   , Globals.g_gamesNetworkID
											   , "bob@me.com"
											   , "bob"
											   , connectSuccess
											   , function (error:PlayerIOError):void { 
													Log.out( "Network.autoLogin - FAILED TO AUTOLOGIN: " + error.message, Log.ERROR, error );
													Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.LOGIN_FAILURE ) ); }
											   );
											   
			function connectSuccess( $client:Client):void
			{
				Log.out("Network.autoLogin.connectSuccess - connection to server established using AUTOLOGIN", Log.DEBUG );
				Network.userId = $client.connectUserId;
				Network.client = $client
				Globals.online = true;
				
				Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.LOGIN_SUCCESS, $startingRegionGuid ) );
			}
		}
		
		static public function login( $email:String, $password:String ):void {
			// If true, API Requests will be encrypted using TLS/SSL. 
			// Beware that this will cause a performance degredation by introducting secure connection negotiation latency for requests.
			// Need to run some timing tests on this to assess performance hit
			//PlayerIO.useSecureApiRequests = true;
			PlayerIO.quickConnect.simpleConnect( Globals.g_app.stage
											   , Globals.g_gamesNetworkID
											   , $email
											   , $password
											   , connectSuccess
											   , simpleConnectFailure );

			function simpleConnectFailure( $error:PlayerIOError ):void
			{
				var errorMsg:String = $error.name + ": " + $error.message;
				if ( 0 < errorMsg.indexOf( "user" ) )
					Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.LOGIN_FAILURE_EMAIL, errorMsg ) );
				else if ( 0 < errorMsg.indexOf( "password" ) )
					Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.LOGIN_FAILURE_PASSWORD, errorMsg ) );
				else
					Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.LOGIN_FAILURE, errorMsg ) );
			}
			
			function connectSuccess( $client:Client):void
			{
				Log.out("Network.login - connection to server established", Log.WARN );
				Network.userId = $client.connectUserId;
				Network.client = $client
				Globals.online = true;
				Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.LOGIN_SUCCESS ) );
			}
		}
		
		static public function recoverPassword( $email:String ):void {
			PlayerIO.quickConnect.simpleRecoverPassword( Globals.g_gamesNetworkID
														, $email
														, recoverySuccess
														, recoveryFailure );

			function recoverySuccess():void { 
				Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.PASSWORD_RECOVERY_SUCCESS ) );
			}

			function recoveryFailure( error:PlayerIOError ):void { 
				Globals.g_app.dispatchEvent( new LoginEvent( LoginEvent.PASSWORD_RECOVERY_FAILURE ) );
			}
		}
	}	
}
