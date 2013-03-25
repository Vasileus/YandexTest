package
{
public class Department
{
[Bindable] [Column(name="DeptID")]   public var DeptID:int = 0;	
[Bindable] [Column(name="DeptName")] public var DeptName:String = "";

public function Department(id:int, name:String)
{
	DeptID = id;
	DeptName = name;
}



}}