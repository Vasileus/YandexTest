package 
{
public class Changer
{
[Bindable] public var f_deleted:Boolean = false;
[Bindable] public var value:String = null;
	
public function Changer(f_deleted:Boolean = false, value:String = null)
{
	this.f_deleted = f_deleted;
	this.value = value;
}

public function is_empty():Boolean
{
	return !f_deleted && value == null;
}


}}