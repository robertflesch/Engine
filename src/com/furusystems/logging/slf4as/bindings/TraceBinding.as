package com.furusystems.logging.slf4as.bindings {
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class TraceBinding implements ILogBinding {
		
		/* INTERFACE com.furusystems.logging.slf4as.bindings.ILogBinding */
		
		public function print(owner:Object, level:int, str:String):void {
			trace( String(level) + ":" +  str);
//
			//trace( String(0) + ":0" );
			//trace( String(1) + ":1" );
			//trace( String(2) + ":2" );
			//trace( String(3) + ":3" );
			//trace( String(4) + ":4" );
			//trace( String(5) + ":5" );
			//trace( String(6) + ":6" );
			//trace( String(7) + ":7" );
			
			//trace( String(DEBUG) + ":" + $msg );
			
		}
	}

}