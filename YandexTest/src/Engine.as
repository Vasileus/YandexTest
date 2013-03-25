package
{
import flash.data.SQLConnection;
import flash.data.SQLResult;
import flash.data.SQLStatement;
import flash.events.SQLErrorEvent;
import flash.events.SQLEvent;
import flash.filesystem.File;

import mx.collections.ArrayCollection;

public class Engine
{
public static var _engine:Engine = null;
public static function get engine():Engine { return _engine != null ? _engine : (_engine = new Engine())};

[Bindable] public var f_connected:Boolean = false;	
[Bindable] public var f_try_connect:Boolean = false;

public var data_provider:ArrayCollection;
public var dep_dp:ArrayCollection;

public function Engine()
{
}

public var sqlConnection:SQLConnection;

public function open_close_database_connection():void
{
	if (f_connected) {
		close_database_connection();
	}
	else {
		open_database_connection();
	}
}

public function close_database_connection():void
{
	if (sqlConnection == null) return;
	sqlConnection.removeEventListener(SQLEvent.OPEN, on_database_open);
	sqlConnection.removeEventListener(SQLErrorEvent.ERROR, on_database_open_error);
	sqlConnection.close();
	
	sqlConnection = null;

	f_try_connect = false;	
	f_connected = false;
	
	data_provider.source = [];
	dep_dp.source = [];
}
	
	
public function open_database_connection():void
{
	close_database_connection();
	f_try_connect = true;
	f_connected = false;
	
	// create new sqlConnection
	sqlConnection = new SQLConnection();
	sqlConnection.addEventListener(SQLEvent.OPEN, on_database_open);
	sqlConnection.addEventListener(SQLErrorEvent.ERROR, on_database_open_error);
		 
	// get currently dir
	var folder:File = File.applicationStorageDirectory;
	//folder = folder.resolvePath("data");
	
	var file:File = folder.resolvePath("C:\\Users\\Vasiliy\\Downloads\\staff.db");
		 
	// open database,If the file doesn't exist yet, it will be created
	sqlConnection.openAsync(file);
}

private function on_database_open(event:SQLEvent):void
{
	f_try_connect = false;
	f_connected = sqlConnection.connected;
	do_database_open();
}

private function on_database_open_error(event:SQLErrorEvent):void
{
	f_try_connect = false;
	f_connected = false;
}



private function do_database_open():void
{
	query_departments();

	var sql:String = "SELECT * FROM Employees ORDER BY EmplID ASC LIMIT 0,100";	
	query_execute(sql, statResult, common_error);
	
}

// ----------------------------------------------------------------------------------------------------
// DEPARTMENTS
public var departments:Array = [];

protected function query_departments():void
{
	query_execute("SELECT * FROM Departments", query_departments_result, query_departments_error);
}


protected function query_departments_result(e:SQLEvent):void
{
	var ss:SQLStatement = e.currentTarget as SQLStatement;
	var result:SQLResult = ss.getResult();	

	var a:Array = result.data;
	departments.splice(0);
	
	for (var i:int = 0; i < a.length; i++) {
		departments[i] = new Department(a[i]['DeptID'], a[i]['DeptName']);
	}
	
	dep_dp.source = departments;
	
	return;
}

protected function query_departments_error(e:SQLErrorEvent):void
{
	
}


//private var sqlStat:SQLStatement;
protected function query_execute(sql:String, result:Function, error:Function):void
{
	var ss:SQLStatement = new SQLStatement();
	ss.sqlConnection = sqlConnection;
	ss.text = sql;
	ss.addEventListener(SQLEvent.RESULT, result);
	ss.addEventListener(SQLErrorEvent.ERROR, error);
	ss.execute();	
}


protected function statResult(e:SQLEvent):void
{
	var ss:SQLStatement = e.currentTarget as SQLStatement;

	var result:SQLResult = ss.getResult();
	data_provider.source = result.data;
}

protected function common_error(e:SQLErrorEvent):void
{
	var a:int = 0;
}



}}