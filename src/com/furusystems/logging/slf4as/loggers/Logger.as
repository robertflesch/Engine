package com.furusystems.logging.slf4as.loggers {
	import com.furusystems.logging.slf4as.constants.Levels;
	import com.furusystems.logging.slf4as.constants.PatternTypes;
	import com.furusystems.logging.slf4as.ILogger;
	import com.furusystems.logging.slf4as.Logging;
	import com.furusystems.logging.slf4as.utils.LevelInfo;
	import com.furusystems.logging.slf4as.utils.PatternResolver;
	import com.furusystems.logging.slf4as.utils.TagCreator;
	import flash.utils.describeType;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Logger implements ILogger {
		private var _owner:Class;
		private var _tag:String;
		private var _patternType:int = PatternTypes.NONE;
		private var _inheritPattern:Boolean = true;
		private var _useAppName:Boolean = false;
		private var _enabled:Boolean = true;
		
		public function Logger(owner:*) {
			_owner = owner;
			if (_owner == Logging && Logging.getDefaultLoggerTag() != Logging.DEFAULT_APP_NAME) {
				_useAppName = true;
			} else {
				_tag = TagCreator.getTag(owner);
			}
		}
		
		/* INTERFACE com.furusystems.logging.slf4as.ILogger */
		
		public function info(... args:Array):void {
			log.apply(this, [DEBUG_COLORS.INFO].concat(args));
		}
		
		public function debug(... args:Array):void {
			log.apply(this, [DEBUG_COLORS.DEBUG].concat(args));
		}
		
		public function error(... args:Array):void {
			log.apply(this, [DEBUG_COLORS.ERROR].concat(args));
		}
		
		public function warn(... args:Array):void {
			log.apply(this, [DEBUG_COLORS.WARN].concat(args));
		}
		
		public function fatal(... args:Array):void {
			log.apply(this, [DEBUG_COLORS.FATAL].concat(args));
		}
		
		public function log(level:int, ... args:Array):void {
			if (Logging.getLevel() > level || !_enabled)
				return;
			var time:Number = getTimer();
			//var levelStr:String = LevelInfo.getName(level);
			var out:String = PatternResolver.resolve(getPatternType(), args);
			Logging.print(getTag(), level, out);
		}
		
		private function getTag():String {
			if (_useAppName) {
				return Logging.getDefaultLoggerTag();
			}
			return _tag;
		}
		
		public function setPatternType(type:int):void {
			_patternType = type;
			_inheritPattern = false;
		}
		
		public function getPatternType():int {
			if (_inheritPattern) {
				return Logging.getPatternType();
			}
			return _patternType;
		}
		
		/* INTERFACE com.furusystems.logging.slf4as.ILogger */
		
		public function get enabled():Boolean {
			return _enabled;
		}
		
		public function set enabled(value:Boolean):void {
			_enabled = value;
		}
	
	}

}


final class DEBUG_COLORS {
	public static const INFO:int = 0;
	public static const DEBUG:int = 1;
	public static const WARN:int = 3;
	public static const ERROR:int = 4;
	public static const FATAL:int = 5;
	public static const UGLY:int = 2; // This is an unreadable color
}
