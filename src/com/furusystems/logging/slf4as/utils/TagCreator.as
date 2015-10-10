package com.furusystems.logging.slf4as.utils {
	import flash.utils.describeType;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class TagCreator {
		static public function getTag(owner:Object):String {
			if (owner is Class) {
				try {
					return describeType(owner).@name.split("::").pop();
				} catch (e:Error) {
					return "" + owner;
				}
			} else {
				return "" + owner;
			}
		}
	
	}

}