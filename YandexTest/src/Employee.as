package
{
public class Employee
{

[Bindable] public var EmplID:int = 0;
[Bindable] public var DeptID:int = 0;	

[Bindable] public var FirstName:String = "";
[Bindable] public var LastName:String = "";	
[Bindable] public var Position:String = "";

public function Employee(EmplID:int = 0, DeptID:int = 0, FirstName:String = null, LastName:String = null, Position:String = null)
{
	this.EmplID    = EmplID;
	this.DeptID    = DeptID;	
	
	this.FirstName = FirstName;
	this.LastName  = LastName;	
	this.Position  = Position;
}



}}