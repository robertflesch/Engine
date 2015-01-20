package com.voxelengine.GUI
{
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

	// Localization Manager which wraps the i18n classes.
	public class LanguageManager
	{
		static private var _localization				:ILocalizationManager;
		static private var _provider					:IResourceBundleProviderManager;
		static private var _factory					:IResourceBundleProviderFactory;
		static private var _initialized				:Boolean;
		
		public function LanguageManager():void {
		}
		
		static public function init():void {
			
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
			
			
			function _onComplete( e:LocalizationEvent ):void {		
				_initialized = true;
			}
		}
		
		static public function selectLocale( $localName:String ):void {
				
				var locale:ILocale = Locale.convert( $localName );
				Log.out( "LanguageManager.selectLocale: " + $localName + "  selected locale is " + locale.variant );
				_localization.setCurrentLocale( locale );
			}
		
		static public function localizedStringGet( $key:String ):String {
			var lowerKey:String = $key.toLowerCase()
			if ( _localization.currentBundle.hasResource( lowerKey ) && _initialized ) {
				return _localization.currentBundle.getResourceString( lowerKey );
			}
			else {
				Log.out( "LanguageManager.localizeStringGet - no translation found for: " + lowerKey, Log.INFO );
				return $key;
			}
		}
	}
}
