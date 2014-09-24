﻿package com.voxelengine.server 
{
	import playerio.Client;
	
	public class Network
	{
		// VV messages
		public static const MOVE_MESSAGE:String = "mov";
		public static const PROJECTILE_SHOT_MESSAGE:String = "psm";
		public static const YOUR_ID:String = "yid";
		public static const ADD_ME:String = "add";
		static public const PUBLIC:String = "public";
		
		// PlayerIO Messages
		public static const USER_JOINED:String = "UserJoined";

		private static var _client:Client;	
		public static function get client():Client { return _client; };
		public static function set client( val:Client ):void { _client = val; };
		
		public static var _userId:String;
		public static function get userId():String { return _userId; };
		public static function set userId( val:String ):void { _userId = val; };
	}	
}
