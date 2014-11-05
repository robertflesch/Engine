package com.voxelengine.GUI
{
	import flash.events.MouseEvent;
	
	import com.enjoymondays.i18n.core.ILocale;
	import com.enjoymondays.i18n.core.ILocalizationManager;
	import com.enjoymondays.i18n.core.IResourceBundleProviderFactory;
	import com.enjoymondays.i18n.core.IResourceBundleProviderManager;
	import com.enjoymondays.i18n.events.LocalizationEvent;
	import com.enjoymondays.i18n.Locale;
	import com.enjoymondays.i18n.LocalizationManager;
	import com.enjoymondays.i18n.providers.DefaultProviderFactory;
	import com.enjoymondays.i18n.providers.DefaultProviderManager;
	import com.enjoymondays.i18n.ResourceBundle;
	
	import com.voxelengine.Log;

	public class LanguageManager
	{
		private var _localization				:ILocalizationManager;
		private var _provider					:IResourceBundleProviderManager;
		private var _factory					:IResourceBundleProviderFactory;
		private var _initialized				:Boolean;
		
		public function LanguageManager():void {
		}
		
		public function init():void {
			
			//var test:String = Capabilities.language;
			var currentLocale:ILocale = _getCurrentLocale( );
			var supportedCodes:Array  = _getSupportedCodes( );
			
			_provider = new DefaultProviderManager;
			_factory  = new DefaultProviderFactory;
			_localization = LocalizationManager.instance;
			_localization.setProviderStrategy( _provider, _factory );
			
			_localization.initialize( currentLocale, supportedCodes );
			
			/*
			 * Load the locale file for the current locale.
			 */
			_localization.addEventListener( LocalizationEvent.UPDATE_AVAILABLE, _onComplete );
			
			function _getSupportedCodes( ):Array {
				return [Locale.EN,Locale.ES];
			}
			
			function _getCurrentLocale():ILocale {
				return Locale.EN;
			}
			
			function _selectLocale(e:MouseEvent):void {
				
				var locale:ILocale = Locale.convert( e.target.name );
				Log.out( "LanguageManager._selectLocale: " + e.target.name + "  selected locale is " + locale.variant );
				_localization.setCurrentLocale( locale );
			}
			
			function _onComplete( e:LocalizationEvent ):void {		
				_initialized = true;
			}
		}
		
		
		public function resourceGet( $key:String, $default:String ):String {
			if ( _localization.currentBundle.hasResource( $key ) && _initialized ) {
				return _localization.currentBundle.getResourceString( $key );
			}
			else {
				Log.out( "LanguageManager.resourceGet - Not initialized or no translation found for: " + $key );
				return $default;
			}
		}
	}
}
