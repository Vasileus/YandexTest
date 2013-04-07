package
{
import controls.ObjectEx;

import flash.data.SQLConnection;
import flash.data.SQLMode;
import flash.data.SQLResult;
import flash.data.SQLStatement;
import flash.events.SQLErrorEvent;
import flash.events.SQLEvent;

import mx.collections.ArrayCollection;
import mx.utils.StringUtil;

public class Engine extends SQLiteEngine
{

public function Engine()
{
	super();
}

	
public static var _engine:Engine = null;
public static function get engine():Engine { return _engine != null ? _engine : (_engine = new Engine())};

[Bindable] public var f_data_view:Boolean = false;
[Bindable] public var f_data_error:Boolean = false;

	


public override function close_database_connection():void
{
	super.close_database_connection();
	f_data_error = false;
	f_data_view = false;
	emp_dp.source = [];
	departments_ac.source = [];
	departments_employees_count = {};
	
	page_start = 0;
	page_total = 0;
	employee_num_records = 0;
}


protected var f_first_connection:Boolean = false;
// ----------------------------------------------------------------------------------------------------
protected override function do_database_open():void
{
	f_first_connection = true;
	f_data_view = true;	
	query_departments();
	query_emploeyes();
}


// ----------------------------------------------------------------------------------------------------
// EMPLOYEE
[Bindable] public var f_use_filter:Boolean = false;
[Bindable] public var f_filter_like:Boolean = true;
[Bindable] public var filter:Employee = new Employee(0, 0, "", "", "");


[Bindable] public var page_limit:int = 100;
[Bindable] public var page_start:int = 0;
protected var _page_start:int = 0;
[Bindable] public var employee_num_records:int = 0;
[Bindable] public var page_total:int = 0;


public var employees:Array = [];
[Bindable] public var emp_dp:ArrayCollection  = new ArrayCollection();

[Bindable] public var departments_employees_count:Object = {};
[Bindable] public var departments_employees_count_update_count:int = 0;

public function query_departments_emp_count():void
{
	f_data_view = true;
	departments_employees_count = {};
	var sql:String = "SELECT DeptID, count(*) AS count FROM  Employees  GROUP BY  DeptID";
	query_execute(sql, null, query_departments_emp_count_result);
}

protected function query_departments_emp_count_result(e:SQLEvent, error:SQLErrorEvent, params:Object):void
{
	f_data_view = false;
	if (e == null) return;  // error
	
	var ss:SQLStatement = e.target as SQLStatement;

	var result:SQLResult = ss.getResult();
	var a:Array = result.data;	
	
	if (a != null) {	
	for (var i:int = 0; i < a.length; i++) {
		var o:Object = a[i];
		departments_employees_count[int(o['DeptID'])] = int(o['count']);
	}}
	departments_employees_count_update_count++;
	
	f_data_error = check_departments_emp_indexes() != 0;
}

protected function check_departments_emp_indexes():int
{
	var count:int = 0;
	
	for (var key:String in departments_employees_count) {
		var DeptID:int = int(key);
		
		if (DeptID != 0 && departments_index[DeptID] == null)
			count += departments_employees_count[key];
	}

	return count;
}






protected function filter_string_add_cond_text_field(s:String, fn:String):String
{
	var v:String = filter[fn];
	
	if (v != "") {
		if (s != "") s += " AND ";
		
		//v = escape(v);
		// Если поиск начинается с первой буквы нижнего регистра, то добавляем дополнительный поиск с вернего регистра
		if (f_filter_like) {
			var ch:String = v.charAt(0);
			
			if (ch.toLocaleLowerCase() == ch) { 
				var v1:String = ch.toLocaleUpperCase() + v.substring(1);
				var v2:String = ch.toLocaleLowerCase() + v.substring(1);			
			
				s += "(" + fn + " LIKE " + "'" + escape(v1) + "%'" + " OR " + fn + " LIKE " + "'" + escape(v2) + "%'" + ")" ;
			}
			else {
				s += fn + " LIKE " + "'" + escape(v) + "%'";				
			}
			
		}
		else
			s += fn + "=" + "'" + escape(v) + "'";
	}
	
	return s;	
}

public function filter_string():String
{
	if (!f_use_filter) return " "; 
	var s:String = "";

	if (filter.DeptID > 0) {
		if (s != "") s += " AND ";
		s += "DeptID=" + filter.DeptID;
	}

	s = filter_string_add_cond_text_field(s, "FirstName");
	s = filter_string_add_cond_text_field(s, "LastName");	
	s = filter_string_add_cond_text_field(s, "Position");	

	s = StringUtil.trim(s);
	if ( s != "") {
		s = " WHERE " + s;
	}
	
	return s + " ";
}

public function query_emploeyes_page(dir:int):void
{
	if (dir == 0) _page_start = 0;
	else {
		if (dir == 1 || dir == -1)
			_page_start = page_start + dir;
		else 
			_page_start = dir;
		
		
		//		if (page_start >= page_total) page_start = page_total - 1;
		if (_page_start < 0) _page_start = 0;
	}
	query_emploeyes();
}


public function query_emploeyes():void
{
	emp_dp.source = [];
	employees.splice(0);
	employee_num_records = 0;
	
	page_total = 0;
	
	var sql:String = "SELECT count(*) AS cnt FROM Employees" + filter_string();
	
	query_execute(sql, null, query_emploeyes_counter_result);	
	
}

protected function query_emploeyes_counter_result(e:SQLEvent, error:SQLErrorEvent, params:Object):void
{
	if (e == null) return;  // error
	
	var ss:SQLStatement = e.currentTarget as SQLStatement;
	var result:SQLResult = ss.getResult();
	var a:Array = result.data;	
	
	if (a != null && a.length > 0) {
		employee_num_records = a[0].cnt;
		page_total = Math.ceil(employee_num_records / page_limit);
	}

	if (_page_start >= page_total) _page_start = page_total - 1;
	if (_page_start < 0) _page_start = 0;
	page_start = _page_start;

	var sql:String = "SELECT * FROM Employees" + filter_string() + "ORDER BY EmplID ASC" + 
		" LIMIT " + page_start * page_limit + "," + page_limit + " ";	
	
	query_execute(sql, null, query_emploeyes_result);
}

protected function query_emploeyes_result(e:SQLEvent, error:SQLErrorEvent, params:Object):void
{
	if (e == null) return;  // error
	
	var ss:SQLStatement = e.currentTarget as SQLStatement;
	
	var result:SQLResult = ss.getResult();
	
	var a:Array = result.data;	

	if (a != null) {	
	for (var i:int = 0; i < a.length; i++) {
		var o:Object = a[i];
		employees[i] = new Employee(o['EmplID'], o['DeptID'], o['FirstName'],  o['LastName'], o['Position']);
//		employees_index[employees[i].EmplID] = i;
	}}
	
	emp_dp.source = employees;

	if (f_first_connection) {
		f_first_connection = false;
		query_departments_emp_count();
	}
	
}


public function delete_employees_by_filter():void
{
	var sql:String = "DELETE FROM Employees " + filter_string() +  "";
	query_execute(sql, null, null);
}

public function replace_employees_to_department_by_fllter(id:int):void
{
	var sql:String = "UPDATE  Employees SET DeptID=" + id + " " + filter_string() +  "";
	query_execute(sql, null, null);
}

// Добавитить сотрудника
public function add_employee(v:Employee):void
{
	var sql:String = "INSERT INTO Employees (DeptID,FirstName,LastName,Position) VALUES" +
		"(" + v.DeptID + ",'" + escape(v.FirstName) + "','" + escape(v.LastName) + "','" + escape(v.Position) + "')";
		
	query_execute(sql, { v: v }, add_employee_result);
}
	
protected function add_employee_result(e:SQLEvent, error:SQLErrorEvent, params:Object):void 
{
	if (e == null) return;  // error
	var ss:SQLStatement = e.currentTarget as SQLStatement;

	var v:Employee = params.v;
	if ( departments_employees_count[v.DeptID] == null)
		departments_employees_count[v.DeptID] = 0;
	
	departments_employees_count[v.DeptID]++;
	departments_employees_count_update_count++;	
}

// Удалить сотрудника
public function del_employee(v:Employee):void
{
	var sql:String = "DELETE FROM Employees WHERE EmplID=" + v.EmplID +  "";
	query_execute(sql, { v: v }, del_employee_result);
}

protected function del_employee_result(e:SQLEvent, error:SQLErrorEvent, params:Object):void 
{
	if (e == null) return;  // error
	var ss:SQLStatement = e.currentTarget as SQLStatement;
	
	var v:Employee = params.v;
	if ( departments_employees_count[v.DeptID] == null)
		departments_employees_count[v.DeptID] = 1;
	
	departments_employees_count[v.DeptID]--;
	departments_employees_count_update_count++;	
}

// Изменить данные сотрудника
public function update_employee_field(v:Employee, fn:String, old_value:*):void
{
	var value:String = (v[fn] is String) ? ("'" + escape(v[fn]) + "'") : v[fn];
	var sql:String = "UPDATE Employees SET " + fn + "=" + value +" WHERE EmplID=" + v.EmplID + "";
	query_execute(sql, { v: v, fn:fn, old_value:old_value }, update_employee_field_result);	
}

protected function update_employee_field_result(e:SQLEvent, error:SQLErrorEvent, params:Object):void 
{
	var v:Employee = params.v;
	var fn:String = params.fn;
	
	if (e == null) { // error
		if (params.old_value != null)
			v[fn] = params.old_value; // Если ошибка - восстанавливаем поле (REVERT FIELD)
		return;  
	}

	if (params.fn != 'DeptID') return;
	
	var i:int =  params.old_value;
	
	if ( departments_employees_count[i] == null)
		departments_employees_count[i] = 1;
	
	departments_employees_count[i]--;

	i = v.DeptID;
	
	if ( departments_employees_count[i] == null)
		departments_employees_count[i] = 0;
	
	departments_employees_count[i]++;
	departments_employees_count_update_count++;
}



// ----------------------------------------------------------------------------------------------------
// DEPARTMENTS
public var departments:Array = [];
public var departments_index:Object = {};
[Bindable] public var departments_ac:ArrayCollection = new ArrayCollection();



[Bindable] public var departments_query_count:int = 0;

public function query_departments():void
{
	query_execute("SELECT * FROM Departments", null, query_departments_result);
}


protected function query_departments_result(e:SQLEvent, error:SQLErrorEvent, params:Object):void
{
	if (e == null) {
		departments_query_count++;
		return;
	}
	
	
	var ss:SQLStatement = e.currentTarget as SQLStatement;
	var result:SQLResult = ss.getResult();	

	var a:Array = result.data;
	departments.splice(0);
	departments_index = {};
	
	for (var i:int = 0; i < a.length; i++) {
		var o:Object = a[i];
		
		departments[i] = new Department(o['DeptID'], o['DeptName']);
		departments_index[departments[i].DeptID] = i;
	}
	
	
//	departments.push(new Department(-1, ""));
	

	departments_ac.source = departments;
	departments_query_count++;
	return;
}


public function apply_departments_changes(departments:Array, changes:ObjectEx, done:Function):void
{
	var params:Object = { count: 0, done: done  };
	
	for (var key:String in changes) {
		var id:int = int(key);		
		var ch:Changer = changes[key];
		
		if (ch.f_deleted && id >= 0) {
			params.count++;

			// Обновляем индекс в Employees
			var sql:String = "UPDATE  Employees SET DeptID=0 WHERE DeptID=" + id +  "";
			query_execute(sql, params, apply_departments_changes_result);

			params.count++;			
			query_execute("DELETE FROM Departments WHERE DeptID=" + id + "", params, apply_departments_changes_result);			
			
			
		}
		else {
			if (id >= 0) {
				var name:String = (departments[departments_index[id]] as  Department).DeptName;
				params.count++;
				query_execute("UPDATE Departments SET DeptName='" + escape(name) +"' WHERE DeptID=" + id + "", params, apply_departments_changes_result);			
			}
		}
	}

// Добавляем поля
// Мульти вставки в SQLite нет !!!, а я расчитывал на VALUES ('abc'),('abc'),('abc')  ;(((((((((( 
	
	var i:int;
	var dept:Department
	
	for (i = departments.length - 1; i >= 0; i--) {
		dept = departments[i] as Department;
		if (dept.DeptID >= 0) break;
		if (dept.DeptName == "") continue;		
	}
	
	for (i++; i < departments.length; i++) { 
		var add:String = "";
		
		dept = departments[i] as Department;
		if (dept.DeptName == "") continue;		
		
		add = "('" + escape(dept.DeptName) + "')" + (add.length == 0 ? '' : ',') + add;

		if (add.length != 0) {
			params.count++;
			query_execute("INSERT INTO Departments (DeptName) VALUES " + add + "", params, apply_departments_changes_result);		
		}
	}


}

protected function apply_departments_changes_result(e:SQLEvent, error:SQLErrorEvent, params:Object):void
{
	if (--params.count == 0) {
		if (params.done != null) params.done();
	}
}
	





//SELECT * FROM Employees LEFT JOIN Departments ON Employees.DeptID != Departments.DeptID
//SELECT COUNT(*) FROM Employees LEFT JOIN Departments ON Employees.DeptID != Departments.DeptID
//SELECT * FROM Employees LEFT OUTER JOIN Departments ON Employees.DeptID = Departments.DeptID WHERE Employees.DeptID=null

}}