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

package org.flashapi.tween.motion {

	// -----------------------------------------------------------
	// Exponential.as
	// -----------------------------------------------------------
	
	/**
	* @author Pascal ECHEMANN
	* @version 1.0.1, 09/03/2010 12:11
	* @see http://www.flashapi.org/
	* credit: Based upon Robert Penner's Easing Equations v1.3
	*  - Oct. 29, 2002 - (c) 2002 Robert Penner.
	* @see http://www.robertpenner.com/profmx
	*/
	
	import org.flashapi.tween.core.AbstractEasing;
	import org.flashapi.tween.core.Easing;
	
	/**
	 * 	The <code>Exponential</code> class defines three easing functions to implement
	 * 	motion with SPAS 3.0 BeeTween animations. It produces an effect similar to
	 * 	the popular "Zeno's paradox" style of scripted easing, where each interval
	 * 	of time decreases the remaining distance by a constant proportion.
	 * 
	 * 	@langversion ActionScript 3.0
	 * 	@playerversion Flash Player 9
	 * 	@productversion SPAS 3.0 alpha
	 */
	public class Exponential extends AbstractEasing implements Easing {
		
		//--------------------------------------------------------------------------
		//
		// Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Constructor. 	Creates a new <code>Exponential</code> object with the 
		 * 					specified parameters.
		 * 
		 * 	@param	type	The type of "ease" process that defines this
		 * 					<code>Easing</code> object. Possible values are:
		 * 					<code>EaseType.IN</code>, <code>EaseType.OUT</code> and
		 * 					<code>EaseType.BOTH</code>.
		 * 					Default value is <code>EaseType.IN</code>.
		 */
		public function Exponential(type:String = "in") {
			super(this, type);
		}
		
		//--------------------------------------------------------------------------
		//
		// Public methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * 	Starts motion slowly and then accelerates motion as it executes.
		 * 
		 * 	@param	t	Specifies the current time, between <code>0</code> and duration
		 * 				inclusive.
		 * 	@param	b	Specifies the initial value of the animation property.
		 * 	@param	c	Specifies the total change in the animation property.
		 * 	@param	d	Specifies the duration of the motion.
		 * 
		 * 	@return	The value of the interpolated property at the specified time.
		 * 
		 *  @see http://www.robertpenner.com/profmx
		 */
		public static function easeIn(t:Number, b:Number, c:Number, d:Number):Number {
			return (t == 0) ? b : c * Math.pow(2, 10 * (t / d - 1)) + b;
		}
		
		/**
		 * 	Starts motion fast and then decelerates motion to a zero velocity as it executes.
		 * 
		 * 	@param	t	Specifies the current time, between <code>0</code> and duration
		 * 				inclusive.
		 * 	@param	b	Specifies the initial value of the animation property.
		 * 	@param	c	Specifies the total change in the animation property.
		 * 	@param	d	Specifies the duration of the motion.
		 * 
		 * 	@return	The value of the interpolated property at the specified time.
		 * 
		 *  @see http://www.robertpenner.com/profmx
		 */
		public static function easeOut(t:Number, b:Number, c:Number, d:Number):Number {
			return (t == d) ? b + c : c * ( -Math.pow(2, -10 * t / d) + 1) + b;
		}
		
		/**
		 * 	Combines the motion of the <code>easeIn()</code> and <code>easeOut()</code>
		 * 	methods to start the motion from a zero velocity, accelerate motion, then
		 * 	decelerate to a zero velocity.
		 * 
		 * 	@param	t	Specifies the current time, between <code>0</code> and duration
		 * 				inclusive.
		 * 	@param	b	Specifies the initial value of the animation property.
		 * 	@param	c	Specifies the total change in the animation property.
		 * 	@param	d	Specifies the duration of the motion.
		 * 
		 * 	@return	The value of the interpolated property at the specified time.
		 * 
		 *  @see http://www.robertpenner.com/profmx
		 */
		public static function easeBoth(t:Number, b:Number, c:Number, d:Number):Number {
			if (t == 0) return b;
			if (t == d) return b + c;
			if ((t /= d / 2) < 1) return c / 2 * Math.pow(2, 10 * (t - 1)) + b;
			return c / 2 * ( -Math.pow(2, -10 * --t) + 2) + b;
		}
	}
}