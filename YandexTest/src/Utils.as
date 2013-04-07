package
{
import flash.globalization.LocaleID;
import flash.globalization.NumberFormatter;

public class Utils
{
public function Utils()
{
}

public static var number_formater:NumberFormatter = new NumberFormatter(new LocaleID("en").name/*LocaleID.DEFAULT*/);

protected static var _ini:Boolean = _init(); 

public static function _init():Boolean
{
	number_formater.fractionalDigits = 0;
	return true;
}

public static function fmt_int(n:int):String
{
	return number_formater.formatInt(n);
}


}}