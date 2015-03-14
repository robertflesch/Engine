package com.furusystems.logging.slf4as.bindings {
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public interface ILogBinding {
		function print(owner:Object, level:int, str:String):void;
	}

}