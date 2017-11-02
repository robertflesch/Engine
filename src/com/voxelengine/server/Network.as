/*==============================================================================
  Copyright 2011-2017 Robert Flesch
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
	public static const LOCAL:String = "local";
	public static const PUBLIC:String = "public";
    public static const PRIVATE:String = "private";
    public static const STORE:String = "store";

	static private var _client:Client;	
	static public function get client():Client { return _client; }
	
	static private var _userId:String = LOCAL;
	static public function get userId():String { return _userId; }

    static private var _storeID:String = STORE;
    static public function get storeId():String { return _storeID; }

	// This was a test to see if I could make a client that didnt need user interaction.
	// This will allow me to do things like post to Facebook things that users create.
	static public function autoLogin( $startingRegionGuid:String ):void {
		PlayerIO.quickConnect.simpleConnect( Globals.g_app.stage
										   , ServerConfig.configGetCurrent().key
										   , "bob@me.com"
										   , "bob"
										   , connectSuccess
										   , function (error:PlayerIOError):void { 
												Log.out( "Network.autoLogin - FAILED TO AUTOLOGIN: " + error.message, Log.ERROR, error );
												LoginEvent.dispatch( new LoginEvent( LoginEvent.LOGIN_FAILURE ) ); }
										   );
										   
		function connectSuccess( $client:Client):void
		{
			Log.out("Network.autoLogin.connectSuccess - connection to server established using AUTOLOGIN", Log.DEBUG );
			_userId = $client.connectUserId;
			_client = $client;
			Globals.online = true;
			
			LoginEvent.dispatch( new LoginEvent( LoginEvent.LOGIN_SUCCESS, $startingRegionGuid ) );
		}
	}
	
	static public function login( $email:String, $password:String ):void {
		// If true, API Requests will be encrypted using TLS/SSL. 
		// Beware that this will cause a performance degredation by introducting secure connection negotiation latency for requests.
		// Need to run some timing tests on this to assess performance hit
		//PlayerIO.useSecureApiRequests = true;
		PlayerIO.quickConnect.simpleConnect( Globals.g_app.stage
										   , ServerConfig.configGetCurrent().key
										   , $email
										   , $password
										   , connectSuccess
										   , simpleConnectFailure );

		function simpleConnectFailure( $error:PlayerIOError ):void
		{
			var errorMsg:String = $error.name + ": " + $error.message;
			if ( 0 < errorMsg.indexOf( "user" ) )
				LoginEvent.dispatch( new LoginEvent( LoginEvent.LOGIN_FAILURE_EMAIL, errorMsg ) );
			else if ( 0 < errorMsg.indexOf( "password" ) )
				LoginEvent.dispatch( new LoginEvent( LoginEvent.LOGIN_FAILURE_PASSWORD, errorMsg ) );
			else
				LoginEvent.dispatch( new LoginEvent( LoginEvent.LOGIN_FAILURE, errorMsg ) );
		}
		
		function connectSuccess( $client:Client):void
		{
			//Log.out("Network.login - connection to server established", Log.DEBUG );
			_userId = $client.connectUserId;
			_client = $client;
			Globals.online = true;
			LoginEvent.dispatch( new LoginEvent( LoginEvent.LOGIN_SUCCESS ) );
		}
	}
	
	static public function recoverPassword( $email:String ):void {
		PlayerIO.quickConnect.simpleRecoverPassword( ServerConfig.configGetCurrent().key
													, $email
													, recoverySuccess
													, recoveryFailure );

		function recoverySuccess():void { 
			LoginEvent.dispatch( new LoginEvent( LoginEvent.PASSWORD_RECOVERY_SUCCESS ) );
		}

		function recoveryFailure( error:PlayerIOError ):void { 
			LoginEvent.dispatch( new LoginEvent( LoginEvent.PASSWORD_RECOVERY_FAILURE ) );
		}
	}
}	
}
