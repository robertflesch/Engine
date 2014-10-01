/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine
{
	import com.furusystems.dconsole2.DConsole;
	import com.furusystems.logging.slf4as.Logging;
	import com.furusystems.logging.slf4as.ILogger;
	import com.voxelengine.server.Network;
	import playerio.ErrorLog;
	
	public class Log {
		
		public static const DEBUG:int = 0;
		public static const INFO:int = 1;
		public static const WARN:int = 2;
		public static const ERROR:int = 3;
		public static const FATAL:int = 4;
		
		private static var _showing:Boolean = false;
		private static var _initialized:Boolean = false;
		
		public static function get showing():Boolean { return _showing; }
		public static function hide():void {
			
			DConsole.hide();
			_showing = false;
		}
		
		public static function show():void {
			
			if ( !_initialized )
			{
				_initialized = true;
				
				Globals.g_app.addChild(DConsole.view);
				DConsole.createCommand( "hide", hide );
				ConsoleCommands.addCommands();
				out( "Type 'hide' to hide the console", Log.WARN );
			}
			DConsole.show();
			_showing = true;
		}
		
		public static function writeError( $errorType:String, $details:String, $error:Error, $extraData:Object = null, callback:Function = null, errorHandler:Function = null):void {
			
			var stackTrace:String = "unknown stack trace";
			if ( $error ) {
				stackTrace = $error.getStackTrace();
				var split:Array = stackTrace.split("\n");
				split.shift();
				stackTrace = "Stack trace: \n\t" + split.join("\n\t");
			}
			if ( Network.client )
				Network.client.errorLog.writeError( $errorType, $details, stackTrace, $extraData );
			else {
				Logging.getLogger(Log).error( $errorType + "  " + $details + "  " + stackTrace );
			}
		}
		
		
		public static function out( $msg:String, type:int = INFO ):void {
			
			const L:ILogger = Logging.getLogger(Log);

			trace( $msg );
			
			if ( INFO < type )
				show();

			if ( _showing )
			{
				switch ( type )
				{ 
					//case DEBUG:
						//Log.L.debug(msg); //These are general debugging messages (your commonplace traces)
						//break;
					//case INFO:
						//Log.L.info(msg); //These are general debugging messages (your commonplace traces)
						//break;
					case WARN:
						L.warn( $msg );
						break;
					case ERROR:
						L.error("*** " + $msg );
						writeError( "Error", $msg, null );
						break;
					case FATAL:
						L.fatal( $msg );
						break;
				}
			}
		}
	}
}