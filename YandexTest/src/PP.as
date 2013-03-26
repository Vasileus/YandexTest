package
{
import flash.net.SharedObject;


public class PP
{

public static var so:SharedObject = SharedObject.getLocal("appSettings");
//
public static function get_str(prop:String, def:String):String
{
	if (so == null || !so.data.hasOwnProperty(prop)) return def;
	return so.data[prop];
}

public static function set_str(prop:String, value:String):void
{
	if (so != null) so.data[prop] = value;
}

public static function get_int(prop:String, def:int):int
{
	if (so == null || !so.data.hasOwnProperty(prop)) return def;
	return int(so.data[prop]);
}

public static function set_int(prop:String, value:int):void
{
	if (so != null) so.data[prop] = value;
}


public static function get_obj(prop:String):Object
{
	if (so == null || !so.data.hasOwnProperty(prop)) return null;
	return so.data[prop];
}


public static function set_obj(prop:String, value:Object):void
{
	if (so != null) so.data[prop] = value;
}






}}


