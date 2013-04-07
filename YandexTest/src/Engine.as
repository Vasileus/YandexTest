package
{
import controls.ObjectEx;

import flash.data.SQLConnection;
import flash.data.SQLMode;
import flash.data.SQLResult;
import flash.data.SQLStatement;
import flash.events.SQLErrorEvent;
import flash.events.SQLEvent;
import flash.filesystem.File;

import mx.collections.ArrayCollection;
import mx.utils.StringUtil;

public class Engine
{
public static var _engine:Engine = null;
public static function get engine():Engine { return _engine != null ? _engine : (_engine = new Engine())};

[Bindable] public var f_data_view:Boolean = false;
[Bindable] public var f_data_error:Boolean = false;
[Bindable] public var f_connected:Boolean = false;	
[Bindable] public var f_try_connect:Boolean = false;

private var _file_name:String = "";
[Bindable] public  var _disp_name:String = "";


public static function call_later(method:Function, args:Array = null):void
{
	AppWindow.app.callLater(method, args);
}
	
public function Engine()
{
}

public    var sql_connection:SQLConnection;
protected var sql_statement:SQLStatement;

public function open_close_database_connection():void
{
	if (f_connected) {
		close_database_connection();
	}
	else {
		open_database_connection(_file_name, _disp_name);
	}
}

public function close_database_connection():void
{
	if (sql_statement != null && sql_statement.executing) {
//		return; // ADOBEE BUG
	}
	
	if (sql_connection == null) return;
	sql_connection.removeEventListener(SQLEvent.OPEN, on_database_open);
	sql_connection.removeEventListener(SQLErrorEvent.ERROR, on_database_open_error);
	if (sql_statement != null) {
		sql_statement.removeEventListener(SQLEvent.RESULT, _internal_result);
		sql_statement.removeEventListener(SQLErrorEvent.ERROR, _internal_error);

		
		if (sql_statement.executing) {
			sql_statement.cancel();
		}
		sql_statement = null;
	}
	queue.splice(0);
	current_query = null;
	
	sql_connection.close();
	sql_connection = null;

	f_try_connect = false;	
	f_connected = false;
	f_data_error = false;
	f_data_view = false;
	
	f_executing_sql_statement = false;
	f_executing_sql_queue = false;
	
	
	emp_dp.source = [];
//	dep_dp.source = [];
}
	
	
public function open_database_connection(file_name:String = "", disp_name:String = ""):void
{
	close_database_connection();

	if (file_name == "") {
		file_name = PP.get_str("default_open_db_file_name", "");		
		disp_name = PP.get_str("default_open_db_disp_name", "");
		
		if (file_name == "") return;
	}
	
	_file_name = file_name;
	_disp_name = disp_name;
	
	f_try_connect = true;	
	
	// create new sqlConnection
	sql_connection = new SQLConnection();
	sql_connection.addEventListener(SQLEvent.OPEN, on_database_open);
	sql_connection.addEventListener(SQLErrorEvent.ERROR, on_database_open_error);
		 
	// get currently dir
    // var folder:File = File.applicationStorageDirectory;
	// folder = folder.resolvePath("data");
	
	var file:File = File.documentsDirectory.resolvePath(file_name);
		 
	// open exist database
	sql_connection.openAsync(file, SQLMode.UPDATE);
}

protected function on_database_open(event:SQLEvent):void
{
	PP.set_str("default_open_db_file_name", _file_name);
	PP.set_str("default_open_db_disp_name", _disp_name);
	f_try_connect = false;
	f_connected = sql_connection.connected;

	var ss:SQLStatement = sql_statement = new SQLStatement();
	ss.sqlConnection = sql_connection;
	
	ss.addEventListener(SQLEvent.RESULT, _internal_result);
	ss.addEventListener(SQLErrorEvent.ERROR, _internal_error);
	
	
	call_later(do_database_open);
}

protected function on_database_open_error(event:SQLErrorEvent):void
{
	PP.set_str("default_open_db_file_name", "");
	PP.set_str("default_open_db_disp_name", "");
	f_try_connect = false;
	f_connected = false;
}


// ----------------------------------------------------------------------------------------------------
protected function do_database_open():void
{
	query_departments();
	query_emploeyes();
	query_departments_emp_count();
}


// ----------------------------------------------------------------------------------------------------
// EMPLOYEE
[Bindable] public var f_use_filter:Boolean = false;
[Bindable] public var f_filter_like:Boolean = true;
[Bindable] public var filter:Employee = new Employee(0, 0, "", "", "");


[Bindable] public var page_limit:int = 100;
[Bindable] public var page_start:int = 0;
[Bindable] public var employee_num_records:int = 0;
[Bindable] public var page_total:int = 0;


public var employees:Array = [];
[Bindable] public var emp_dp:ArrayCollection  = new ArrayCollection();

public function query_departments_emp_count():void
{
	f_data_view = true;
	var sql:String = "SELECT DeptID, count(*) AS CNT FROM  Employees  GROUP BY  DeptID";
	query_execute(sql, null, query_departments_emp_count_result, query_departments_emp_count_error);
}

protected function query_departments_emp_count_result(e:SQLEvent):void
{
	var ss:SQLStatement = e.target as SQLStatement;

	f_data_view = false;	
	f_data_error = true;
}

protected function query_departments_emp_count_error(e:SQLErrorEvent):void
{
	f_data_view = false;
	f_data_error = true;
}


public function update_employee_field(id:int, name:String, value:*, done:Function = null):void
{
	var v:String = (value is String) ? ("'" + escape(value) + "'") : value;
	
	var sql:String = "UPDATE Employees SET " + name + "=" + v +" WHERE EmplID=" + id + "";
	
	query_execute(sql, null, common_result, common_error);	
}

public function query_emploeyes_page(dir:int):void
{
	if (dir == 0) page_start = 0;
	else {
		page_start += dir;
		if (page_start >= page_total) page_start = page_total - 1;
		if (page_start < 0) page_start = 0;
	}
	query_emploeyes();
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
	

public function query_emploeyes(done:Function = null):void
{
	emp_dp.source = [];
	employees.splice(0);
	employee_num_records = 0;
	
	if (page_start == 0) {
		page_total = 0;
	}
	
	
	var sql2:String = "SELECT count(*) AS cnt FROM Employees" + filter_string();
	query_execute(sql2, null, query_emploeyes_counter_result, common_error);	
	
	var sql:String = "SELECT * FROM Employees" + filter_string() + "ORDER BY EmplID ASC" + 
		" LIMIT " + page_start * page_limit + "," + page_limit + " ";	
	query_execute(sql, null, query_emploeyes_result, common_error);
}

protected function query_emploeyes_counter_result(e:SQLEvent):void
{
	var ss:SQLStatement = e.currentTarget as SQLStatement;
	var result:SQLResult = ss.getResult();
	var a:Array = result.data;	
	
	if (a != null && a.length > 0) {
		employee_num_records = a[0].cnt;
		page_total = Math.ceil(employee_num_records / page_limit);
	}
	
}

protected function query_emploeyes_result(e:SQLEvent):void
{
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
	
}

public function delete_employee(id:int):void
{
	var sql:String = "DELETE FROM Employees WHERE EmplID=" + id +  "";
	query_execute(sql, null, common_result, common_error);
}

public function delete_employees_by_filter():void
{
	var sql:String = "DELETE FROM Employees " + filter_string() +  "";
	query_execute(sql, null, common_result, common_error);
}

public function replace_employees_to_department_by_fllter(id:int):void
{
	var sql:String = "UPDATE  Employees SET DeptID=" + id + " " + filter_string() +  "";
	query_execute(sql, null, common_result, common_error);
}


public function add_employee(e:Employee):void
{
	var sql:String = "INSERT INTO Employees (DeptID,FirstName,LastName,Position) VALUES" +
		"(" + e.DeptID + ",'" + escape(e.FirstName) + "','" + escape(e.LastName) + "','" + escape(e.Position) + "')";
		
	query_execute(sql, null, common_result, common_error);
}
	
	
// ----------------------------------------------------------------------------------------------------
// DEPARTMENTS
public var departments:Array = [];
public var departments_index:Object = {};
[Bindable] public var departments_ac:ArrayCollection = new ArrayCollection();

protected var query_departments_done:Function = null;
protected var apply_departments_changes_count:int = 0;
protected var apply_departments_changes_done:Function = null;
[Bindable] public var departments_query_count:int = 0;

public function query_departments(done:Function = null):void
{
	query_departments_done = done;
	query_execute("SELECT * FROM Departments", null, query_departments_result, query_departments_error);
}


protected function query_departments_result(e:SQLEvent):void
{
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
	
	departments_query_count++;
	departments_ac.source = departments;
	if (query_departments_done != null) query_departments_done();
	return;
}

protected function query_departments_error(e:SQLErrorEvent):void
{
	if (query_departments_done != null) query_departments_done();	
}

public function apply_departments_changes(departments:Array, changes:ObjectEx, done:Function):void
{
	apply_departments_changes_count = 0;
	apply_departments_changes_done = done;
	
	for (var key:String in changes) {
		var id:int = int(key);		
		var ch:Changer = changes[key];
		
		if (ch.f_deleted && id >= 0) {
			apply_departments_changes_count++;
			query_execute("DELETE FROM Departments WHERE DeptID=" + id + "", null, 
				apply_departments_changes_result, apply_departments_changes_error);			
			
			
		}
		else {
			if (id >= 0) {
				var name:String = (departments[departments_index[id]] as  Department).DeptName;
				apply_departments_changes_count++;
				query_execute("UPDATE Departments SET DeptName='" + escape(name) +"' WHERE DeptID=" + id + "", null, 
					apply_departments_changes_result, apply_departments_changes_error);			
			}
		}
	}

// Добавляем поля
// Мульти вставки в SQLite нет -- ПОЗОРИЩЕ!!!, а я расчитывал на VALUES ('abc'),('abc'),('abc')  ;(((((((((( 
	
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
			apply_departments_changes_count++;
			query_execute("INSERT INTO Departments (DeptName) VALUES " + add + "", null, 
				apply_departments_changes_result, apply_departments_changes_error);		
		}
	}


}

protected function apply_departments_changes_result(e:SQLEvent):void
{
	if (--apply_departments_changes_count == 0)
		apply_departments_changes_done();
}
	
protected function apply_departments_changes_error(e:SQLErrorEvent):void
{
	if (--apply_departments_changes_count == 0)
		apply_departments_changes_done();
}







// ----------------------------------------------------------------------------------------------------
[Bindable] public var f_executing_sql_statement:Boolean = false;
[Bindable] public var f_executing_sql_queue:Boolean = false;

[Bindable] public var sql_log:String = "";

protected function log(s:String, cr:Boolean = true):void
{
	var limit:int = 4 * 1024;
	
	if (sql_log.length > limit) {
		var i:int = sql_log.indexOf("\n", sql_log.length - limit); 
		if (i >= 0) sql_log = sql_log.substring(i + 1);
	}
	
	
	sql_log += s;
	if (cr) {
		sql_log += "\n";
	}
}

protected var queue:Array = []; 


protected function query_execute(sql:String, params:Object, result:Function, error:Function):void
{
	f_executing_sql_queue = true;
	var o:Object = { sql:sql, params:params, result:result, error:error }	
	queue.push(o);
	if (queue.length == 1) {
		call_later(do_queue);
	}
}

protected function do_queue():void
{
	if (f_executing_sql_statement || sql_statement == null || sql_statement.executing) return;
	
	if (queue.length == 0) {
		f_executing_sql_queue = false;
		return;
	}
	
	var o:Object = current_query = queue.shift();
	do_query_execute();//o.sql, o.params, o.result, o.error);
}

protected var current_query:Object;

protected function do_query_execute():Boolean//sql:String, params:Object, result:Function, error:Function):Boolean
{
	if (sql_connection == null) {
		queue.splice(0);
		return false;
	}

	log("QUERY: " + current_query.sql );
	
	f_executing_sql_statement = true;	
	
	var ss:SQLStatement = sql_statement;// = new SQLStatement();
//	ss.sqlConnection = sql_connection;
	ss.text = current_query.sql;

//	ss.addEventListener(SQLEvent.RESULT, _internal_result);
//	ss.addEventListener(SQLErrorEvent.ERROR, _internal_error);
	
	
	
//	ss.addEventListener(SQLEvent.RESULT, result);
//	ss.addEventListener(SQLErrorEvent.ERROR, error);



	ss.execute();	
	return true;
}

protected function _internal_result(e:SQLEvent):void
{
	f_executing_sql_statement = false;
	var ss:SQLStatement = e.target as SQLStatement; 
	current_query.result(e);
//	ss.removeEventListener(SQLEvent.RESULT, _internal_result);
//	ss.removeEventListener(SQLErrorEvent.ERROR, _internal_error);
//	sql_statement = null;
	current_query = null;
	call_later(do_queue);
	
}

protected function _internal_error(e:SQLErrorEvent):void
{
	f_executing_sql_statement = false;
	var ss:SQLStatement = e.target as SQLStatement; 
	current_query.error(e);

	log("ERROR: " + e.error.details);
	
//	ss.removeEventListener(SQLEvent.RESULT, _internal_result);
//	ss.removeEventListener(SQLErrorEvent.ERROR, _internal_error);
//	sql_statement = null;
	current_query = null;
	call_later(do_queue);
}



protected function common_result(e:SQLEvent):void
{
	var ss:SQLStatement = e.target as SQLStatement;
}

protected function common_error(e:SQLErrorEvent):void
{
	var ss:SQLStatement = e.target as SQLStatement;
}

public static function escape(s:String):String
{
	return s.replace(/'/g, "''");
}
//SELECT * FROM Employees LEFT JOIN Departments ON Employees.DeptID != Departments.DeptID
//SELECT COUNT(*) FROM Employees LEFT JOIN Departments ON Employees.DeptID != Departments.DeptID
//SELECT * FROM Employees LEFT OUTER JOIN Departments ON Employees.DeptID = Departments.DeptID WHERE Employees.DeptID=null

}}