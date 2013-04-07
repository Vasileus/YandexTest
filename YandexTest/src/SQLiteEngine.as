package
{
import flash.data.SQLConnection;
import flash.data.SQLMode;
import flash.data.SQLResult;
import flash.data.SQLStatement;
import flash.events.SQLErrorEvent;
import flash.events.SQLEvent;
import flash.filesystem.File;

import mx.collections.ArrayCollection;
import mx.utils.StringUtil;

public class SQLiteEngine
{

[Bindable] public var f_connected:Boolean = false;	
[Bindable] public var f_try_connect:Boolean = false;

private var _file_name:String = "";
[Bindable] public  var _disp_name:String = "";


public static function call_later(method:Function, args:Array = null):void
{
	AppWindow.app.callLater(method, args);
}
	
public function SQLiteEngine()
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
//		return; // ADOBEE DEBUG BUG
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
	
	f_executing_sql_statement = false;
	f_executing_sql_queue = false;
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
}


// ----------------------------------------------------------------------------------------------------
	





// ----------------------------------------------------------------------------------------------------
[Bindable] public var f_executing_sql_statement:Boolean = false;
[Bindable] public var f_executing_sql_queue:Boolean = false;

[Bindable] public var sql_log:String = "";
public var sql_log_limit:int = 4 * 1024;


protected function log(s:String, cr:Boolean = true):void
{
	if (sql_log.length > sql_log_limit) {
		var i:int = sql_log.indexOf("\n", sql_log.length - sql_log_limit); 
		if (i >= 0) sql_log = sql_log.substring(i + 1);
	}
	
	
	sql_log += s;
	if (cr) {
		sql_log += "\n";
	}
}

protected var queue:Array = []; 


protected function query_execute(sql:String, params:Object, responder:Function):void
{
	if (sql_connection == null)
		return;
	
	f_executing_sql_queue = true;
	var o:Object = { sql:sql, params:params, responder:responder }	
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

protected function do_query_execute():Boolean
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
	if (current_query != null && current_query.responder != null) {
		current_query.responder(e, null, current_query.params);
	}
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
	if (current_query != null && current_query.responder != null) {
		current_query.responder(null, e, current_query.params);
	}
	log("ERROR: " + e.error.details);
	
//	ss.removeEventListener(SQLEvent.RESULT, _internal_result);
//	ss.removeEventListener(SQLErrorEvent.ERROR, _internal_error);
//	sql_statement = null;
	current_query = null;
	call_later(do_queue);
}


/*
protected function common_result(e:SQLEvent):void
{
	var ss:SQLStatement = e.target as SQLStatement;
}

protected function common_error(e:SQLErrorEvent):void
{
	var ss:SQLStatement = e.target as SQLStatement;
}
*/

public static function escape(s:String):String
{
	return s.replace(/'/g, "''");
}


}}