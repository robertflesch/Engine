////////////////////////////////////////////////////////////////////////////////
//    
//    Swing Package for Actionscript 3.0 (SPAS 3.0)
//    Copyright (C) 2004-2011 BANANA TREE DESIGN & Pascal ECHEMANN.
//    
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//    
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//    GNU General Public License for more details.
//    
//    You should have received a copy of the GNU General Public License
//    along with this program. If not, see <http://www.gnu.org/licenses/>.
//    
////////////////////////////////////////////////////////////////////////////////

package org.flashapi.swing.effect {
	
	// -----------------------------------------------------------
	// ResizeIn.as
	// -----------------------------------------------------------
	
	/**
	* @author Pascal ECHEMANN
	* @version 1.0.1, 29/12/2008 23:07
	* @see http://www.flashapi.org/
	*/
	
	import org.flashapi.swing.effect.core.ResizeEffects;
	import org.flashapi.tween.event.MotionEvent;
	
	/**
	 * 	The <code>ResizeIn</code> class creates a resizing effect that changes both, width
	 * 	and height of an object, from 0 to 100%.
	 * 
	 * 	@see org.flashapi.swing.effect.ResizeOut
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class ResizeIn extends ResizeEffects implements Effect {
		
		//--------------------------------------------------------------------------
		//
		// Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Constructor. Creates e new <code>ResizeIn</code> effect with 
		 * 	the specified parameters.
		 * 
		 * 	@param	target		The target container for this effect.
		 * 	@param	duration	The effect duration, in milliseconds.
		 */
		public function ResizeIn(target:Object, duration:uint = 350) {
			super(target, duration);
			initObj(target);
		}
		
		//--------------------------------------------------------------------------
		//
		// Protected methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	@private
		 */
		override protected function motionFinish(e:MotionEvent):void {
			$target.width = $end[0];
			$target.height = $end[1];
			super.motionFinish(e);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Private methods
		//
		//--------------------------------------------------------------------------
		
		private function initObj(target:Object):void {
			$start = [10, 10];
			$end = [target.width, target.height];
			target.resize(10, 10);
		}
	}
}