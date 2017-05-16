/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship public     under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.oxel
{
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.TypeInfo;

/**
	 * ...
	 * @author Robert Flesch RSF hides the bit masking of the raw data
	 */
	public class OxelBitfields
	{
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//     Static Variables
		//
		//  0xf = 1111  0xe = 1110 0xd = 1101 0xc = 1100 0xb = 1011  0xa = 1010 0x9 = 1001 0x8 = 1000 0x7 = 0111
		//  
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		private static const OXEL_DATA_FLOW_INFO:uint				= 0x00000001;
		private static const OXEL_DATA_FLOW_INFO_CLEAR:uint			= 0xfffffffe;

		private static const OXEL_DATA_LIGHT_INFO:uint				= 0x00000002;
		private static const OXEL_DATA_LIGHT_INFO_CLEAR:uint		= 0xfffffffd;

		private static const OXEL_DATA_COLOR:uint					= 0x00000004;
		private static const OXEL_DATA_COLOR_CLEAR:uint				= 0xfffffffb;

		private static const OXEL_DATA_UNUSED:uint				    = 0x8001f9f8; // 1000 0000 0000 0001 1111 1001 1111 1100
		//private static const OXEL_DATA_UNUSED_CLEAR:uint		    = 0xfffffffd;

		private static const OXEL_DATA_FIRE:uint					= 0x00000200;
		private static const OXEL_DATA_FIRE_CLEAR:uint 				= 0xfffffdff;

		private static const OXEL_DATA_PARENT:uint					= 0x00000400;
		private static const OXEL_DATA_PARENT_MASK:uint 			= 0xfffffbff;

		private static const OXEL_DATA_FACE_BITS_CLEAR:uint  		= 0x8181ffff;
		private static const OXEL_DATA_CLEAR:uint					= 0x00000000;

		private static const OXEL_DATA_ADDITIONAL_CLEAR:uint  		= 0x7fffffff; // deprecated - used if oxel has flow or light data
		private static const OXEL_DATA_ADDITIONAL:uint  			= 0x80000000; // deprecated - used if oxel has flow or light data

		private static const OXEL_WRITE_DATA:uint  		            = 0x7e010607; // only these bits are valid for writing

		private static const OXEL_DATA_FACES_CLEAR:uint				= 0x81ffffff;
		private static const OXEL_DATA_FACES:uint  					= 0x7e000000;

		private static const OXEL_DATA_FACES_POSX:uint				= 0x40000000;
		private static const OXEL_DATA_FACES_NEGX:uint				= 0x20000000;
		private static const OXEL_DATA_FACES_POSY:uint				= 0x10000000;
		private static const OXEL_DATA_FACES_NEGY:uint				= 0x08000000;
		private static const OXEL_DATA_FACES_POSZ:uint				= 0x04000000;
		private static const OXEL_DATA_FACES_NEGZ:uint				= 0x02000000;

		private static const OXEL_DATA_FACES_POSX_CLEAR:uint		= 0xbfffffff;
		private static const OXEL_DATA_FACES_NEGX_CLEAR:uint		= 0xdfffffff;
		private static const OXEL_DATA_FACES_POSY_CLEAR:uint		= 0xefffffff;
		private static const OXEL_DATA_FACES_NEGY_CLEAR:uint		= 0xf7ffffff;
		private static const OXEL_DATA_FACES_POSZ_CLEAR:uint		= 0xfbffffff;
		private static const OXEL_DATA_FACES_NEGZ_CLEAR:uint		= 0xfdffffff;
		
		private static const OXEL_DATA_DIRTY_CLEAR:uint  			= 0xfeffffff;
		private static const OXEL_DATA_DIRTY:uint  					= 0x01000000;
		
		private static const OXEL_DATA_ADD_VERTEX_CLEAR:uint  		= 0xff7fffff;
		private static const OXEL_DATA_ADD_VERTEX:uint  			= 0x00800000;
		
		private static const OXEL_DATA_FACES_DIRTY_CLEAR:uint		= 0xff81ffff;
		private static const OXEL_DATA_FACES_DIRTY:uint  			= 0x007e0000;
		
		private static const OXEL_DATA_FACES_DIRTY_POSX:uint 		= 0x00400000;
		private static const OXEL_DATA_FACES_DIRTY_NEGX:uint		= 0x00200000;
		private static const OXEL_DATA_FACES_DIRTY_POSY:uint		= 0x00100000;
		private static const OXEL_DATA_FACES_DIRTY_NEGY:uint		= 0x00080000;
		private static const OXEL_DATA_FACES_DIRTY_POSZ:uint		= 0x00040000;
		private static const OXEL_DATA_FACES_DIRTY_NEGZ:uint		= 0x00020000;

		private static const OXEL_DATA_MODEL:uint					= 0x00010000;
		private static const OXEL_DATA_MODEL_CLEAR:uint				= 0xfffeffff;


	// bottom 10 bits not used. Used to be type data, now stored in its own full int

		private static const OXEL_DATA_TYPE_MASK_TEMP:uint			= 0xfe7fffff;
		
		// type 1
		private static const OXEL_DATA_TYPE_1_MASK_CLEAR:uint 		= 0xffff0000;
		private static const OXEL_DATA_TYPE_1_MASK:uint				= 0x0000ffff;

		private var _data:uint = 0;					// holds face data

		public function get dirty():Boolean 					{ return 0 < (_data & OXEL_DATA_DIRTY); }
		public function set dirty( $val:Boolean ):void { 
			_data &= OXEL_DATA_DIRTY_CLEAR;
			if ( $val )
				_data |= OXEL_DATA_DIRTY; 
		}

		public  function get hasModel():Boolean 		{ return 0 < (_data & OXEL_DATA_MODEL); }
		public  function set hasModel( $val:Boolean ):void {
			_data &= OXEL_DATA_MODEL_CLEAR;
			if ( $val )
				_data |= OXEL_DATA_MODEL;
		}

		protected  function get onFire():Boolean 		{ return 0 < (_data & OXEL_DATA_FIRE); }
		protected  function set onFire( $val:Boolean ):void {
			_data &= OXEL_DATA_FIRE_CLEAR;
			if ( $val )
				_data |= OXEL_DATA_FIRE;
		}

		protected  function get addedToVertex():Boolean 		{ return 0 < (_data & OXEL_DATA_ADD_VERTEX); }
		protected  function set addedToVertex( $val:Boolean ):void { 
			_data &= OXEL_DATA_ADD_VERTEX_CLEAR;
			if ( $val )
				_data |= OXEL_DATA_ADD_VERTEX; 
		}
		
		// Type is stored in the lower 2 bytes of the _type variable
		private var _type:uint = 0;					// holds type data
		public function get type():int 							{ return (_type & OXEL_DATA_TYPE_1_MASK); }
		public function set type( val:int ):void {
			if ( val > 1023 )
				val = TypeInfo.RED;
			_type &= OXEL_DATA_TYPE_1_MASK_CLEAR;
			_type |= (val & OXEL_DATA_TYPE_1_MASK); 
		}

		static protected const  DEFAULT_COLOR:uint = 0xff000000;
		private var _color:uint = DEFAULT_COLOR;				// holds color data
		public function get color():uint 						{ return _color; }
		public function set color( val:uint ):void 				{
			_color = val;
			if ( DEFAULT_COLOR == val )
				colorClear();
			else
				colorMark();
		}

		private static const OXEL_DATA_TYPE_MASK_CLEAR:uint 		= 0xfffffc00;
		private static const OXEL_DATA_TYPE_OLD_MASK:uint			= 0x000003ff;


			   protected 	function maskWriteData():uint 					{ return _data & OXEL_WRITE_DATA; }
			   protected 	function maskTempData():uint 					{ return _data & OXEL_DATA_TYPE_MASK_TEMP; }
		static public 		function type1FromData( $data:uint ):uint 		{ return $data & OXEL_DATA_TYPE_1_MASK; }
		static public 		function typeFromRawDataOld( $data:uint ):uint	{ return $data & OXEL_DATA_TYPE_OLD_MASK; }
		static public 		function dataFromRawDataOld( $data:uint ):uint	{ return $data & OXEL_DATA_TYPE_MASK_CLEAR; }
		
		// this is needed to initialize from byteArray
		public function dataRaw(value:uint,type:uint):void 					{ _data = value; _type = type }
		public function get data():uint 									{ return _data }
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//     operations
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		protected	function resetData():void 								{ _data &= OXEL_DATA_CLEAR; }
		public 		function facesCleanAllFaceBits():void 				{ _data &= OXEL_DATA_FACE_BITS_CLEAR; } //  doesnt touch dirty;
		// faces marked as dirty that need re-evaluation to determine if a face exists there.
		protected	function faceHasDirtyBits():Boolean 			{ return 0 < (_data & OXEL_DATA_FACES_DIRTY); }
//		public		function facesMarkAllClean():void 			{ _data &= OXEL_DATA_FACES_DIRTY_CLEAR; dirty = true; }
		public		function facesMarkAllClean():void 			{ _data &= OXEL_DATA_FACES_DIRTY_CLEAR; }
//		public		function facesSetAll():void 				{ _data |= OXEL_DATA_FACES;  dirty = true;}
		public		function facesSetAll():void 				{ _data |= OXEL_DATA_FACES;  }
		public		function facesClearAll():void 				{ _data &= OXEL_DATA_FACES_CLEAR;  dirty = true;	 }
		public		function facesMarkAllDirty():void 			{
			_data |= OXEL_DATA_FACES_DIRTY;
			dirty = true; 
		}
		// these bits tell engine if the oxel has a face at that location
		// that information is then used to clear out OR build the quads
		protected  	function faceMarkDirty( $guid:String, $face:uint, $propogateCount:int = 2 ):void {
			switch( $face ) {
				case Globals.POSX:
					_data |= OXEL_DATA_FACES_DIRTY_POSX; break;
				case Globals.NEGX:
					_data |= OXEL_DATA_FACES_DIRTY_NEGX; break;
				case Globals.POSY:
					_data |= OXEL_DATA_FACES_DIRTY_POSY; break;
				case Globals.NEGY:
					_data |= OXEL_DATA_FACES_DIRTY_NEGY; break;
				case Globals.POSZ:
					_data |= OXEL_DATA_FACES_DIRTY_POSZ; break;
				case Globals.NEGZ:
					_data |= OXEL_DATA_FACES_DIRTY_NEGZ; break;
			}
			dirty = true;
		}
		
		public  	function facesHas():Boolean					{  return 0 < (_data & OXEL_DATA_FACES);  }
		
		import flash.utils.Dictionary;
		private static var faceCountLookup:Dictionary = new Dictionary();
		{
			 faceCountLookup[0] = 0;
			 faceCountLookup[1] = 1;
			 faceCountLookup[2] = 1;
			 faceCountLookup[3] = 2;
			 faceCountLookup[4] = 1;
			 faceCountLookup[5] = 2;
			 faceCountLookup[6] = 2;
			 faceCountLookup[7] = 3;
		}
		
		public  	function faceCount():int					{  
			var faces:uint = _data & OXEL_DATA_FACES; 
			var lower:int = faces >>> 25;
			lower &= 0x000111;
			var higher:int = faces >>> 28;
			// strip leading bit
			var count:int = faceCountLookup[lower] + faceCountLookup[higher];
			return count;
		}
		
		protected  	function faceIsDirty( $face:uint ):Boolean {
			switch( $face ) {
				case Globals.POSX:
					return 0 < ( _data & OXEL_DATA_FACES_DIRTY_POSX ); break;
				case Globals.NEGX:
					return 0 < ( _data & OXEL_DATA_FACES_DIRTY_NEGX ); break;
				case Globals.POSY:
					return 0 < ( _data & OXEL_DATA_FACES_DIRTY_POSY ); break;
				case Globals.NEGY:
					return 0 < ( _data & OXEL_DATA_FACES_DIRTY_NEGY ); break;
				case Globals.POSZ:
					return 0 < ( _data & OXEL_DATA_FACES_DIRTY_POSZ ); break;
				case Globals.NEGZ:
					return 0 < ( _data & OXEL_DATA_FACES_DIRTY_NEGZ ); break;
			}
			return false;
		}
		public 		function faceSet( $face:uint ):void {
			switch( $face ) {
				case Globals.POSX:
					_data |= OXEL_DATA_FACES_POSX;
					break;
				case Globals.NEGX:
					_data |= OXEL_DATA_FACES_NEGX;
					break;
				case Globals.POSY:
					_data |= OXEL_DATA_FACES_POSY;
					break;
				case Globals.NEGY:
					_data |= OXEL_DATA_FACES_NEGY;
					break;
				case Globals.POSZ:
					_data |= OXEL_DATA_FACES_POSZ;
					break;
				case Globals.NEGZ:
					_data |= OXEL_DATA_FACES_NEGZ;
					break;
			}
		}
		protected  	function faceClear( $face:uint ):void {
			switch( $face ) {
				case Globals.POSX:
					_data &= OXEL_DATA_FACES_POSX_CLEAR;
					break;
				case Globals.NEGX:
					_data &= OXEL_DATA_FACES_NEGX_CLEAR;
					break;
				case Globals.POSY:
					_data &= OXEL_DATA_FACES_POSY_CLEAR;
					break;
				case Globals.NEGY:
					_data &= OXEL_DATA_FACES_NEGY_CLEAR;
					break;
				case Globals.POSZ:
					_data &= OXEL_DATA_FACES_POSZ_CLEAR;
					break;
				case Globals.NEGZ:
					_data &= OXEL_DATA_FACES_NEGZ_CLEAR;
					break;
			}
		}
		public  	function faceHas( $face:uint ):Boolean {
			switch( $face ) {
				case Globals.POSX:
					return 0 < ( _data & OXEL_DATA_FACES_POSX );
					break;
				case Globals.NEGX:
					return 0 < ( _data & OXEL_DATA_FACES_NEGX );
					break;
				case Globals.POSY:
					return 0 < ( _data & OXEL_DATA_FACES_POSY );
					break;
				case Globals.NEGY:
					return 0 < ( _data & OXEL_DATA_FACES_NEGY );
					break;
				case Globals.POSZ:
					return 0 < ( _data & OXEL_DATA_FACES_POSZ );
					break;
				case Globals.NEGZ:
					return 0 < ( _data & OXEL_DATA_FACES_NEGZ );
					break;
			}
			return false;
		}
		
		protected   function parentMarkAs():void 					{
			_data |= OXEL_DATA_PARENT;
			facesClearAll();
			facesMarkAllClean();
			type = TypeInfo.AIR;
			dirty = true;
			// should end up with 16778240 (0x1000400)
			// dirty and parent
		}
		protected   function parentClear():void 					{ _data &= OXEL_DATA_PARENT_MASK; }
		protected   function parentIs():Boolean 					{ return 0 < (_data & OXEL_DATA_PARENT) }
		
		public      function additionalDataMark():void				{ _data |= OXEL_DATA_ADDITIONAL;  }
		public      function additionalDataHas():Boolean			{ return 0 < ( _data & OXEL_DATA_ADDITIONAL );  }
		public      function additionalDataClear():void 			{ _data &= OXEL_DATA_ADDITIONAL_CLEAR; }

		static public function dataIsParent( $data:uint ):Boolean 	{ return 0 < ($data & OXEL_DATA_PARENT); }
		static public function dataHasAdditional( $data:uint ):Boolean { 
			var t:uint = ($data & OXEL_DATA_ADDITIONAL);
			t = t >> 1;
			return 0 < t; 
		}
		static public function dataAdditionalClear( $data:uint ):uint 	{ return $data & OXEL_DATA_ADDITIONAL_CLEAR }

		[inline] public function flowInfoMark():void								{ _data |= OXEL_DATA_FLOW_INFO;  }
		[inline] public function flowInfoClear():void							{ _data &= OXEL_DATA_FLOW_INFO_CLEAR }
		static public function flowInfoHas( $data:uint ):Boolean {
			var t:uint = ($data & OXEL_DATA_FLOW_INFO);
			return 0 < t;
		}

		[inline] public function lightInfoMark():void						{ _data |= OXEL_DATA_LIGHT_INFO;  }
		[inline] public function lightInfoClear():void						{ _data &= OXEL_DATA_LIGHT_INFO_CLEAR }
		static public function lightInfoHas( $data:uint ):Boolean {
			var t:uint = ($data & OXEL_DATA_LIGHT_INFO);
			t = t >> 1;
			return 0 < t;
		}

		[inline] public function colorMark():void						{ _data |= OXEL_DATA_COLOR;  }
		[inline] public function colorClear():void						{ _data &= OXEL_DATA_COLOR_CLEAR }
		static public function colorHas( $data:uint ):Boolean {
			var t:uint = ($data & OXEL_DATA_COLOR);
			t = t >> 1;
			return 0 < t;
		}
}
}
		
		