package com.furusystems.logging.slf4as.bindings {
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class TraceBinding implements ILogBinding {
		
		/* INTERFACE com.furusystems.logging.slf4as.bindings.ILogBinding */
		
		public function print(owner:Object, level:int, str:String):void {
			trace( String(level) + ":" +  str);
			//trace( String(DEBUG) + ":" + $msg );
			
		}
	}

}