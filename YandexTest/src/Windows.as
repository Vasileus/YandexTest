package
{
import controls.DataGridEx;

import flash.events.Event;

import mx.events.CloseEvent;
import mx.managers.PopUpManager;

public class Windows
{

public static var _windows:Windows = null;
public static function get windows():Windows { return _windows != null ? _windows : (_windows = new Windows())};

public function Windows()
{
}


protected var wnd_departments:AppTitleWindow;

public function departments():void
{
	open_window(this, "wnd_departments", "Отделения",  400, 400, DepartmentsEditorWindow);
}

protected var wnd_about:AppTitleWindow;

public function about():void
{
	open_window(this, "wnd_about", "О программе",  300, 260, AboutWindow);
}

protected var wnd_add_employee:AppTitleWindow;	

public function add_employee():void
{
	open_window(this, "wnd_add_employee", "Добавить сотрудника",  480, 400, AddEmployeeWindow);
}

protected var wnd_confirm_delete:AppTitleWindow;

public function confirm_delete():void
{
	open_window(this, "wnd_confirm_delete", "Подтвердждение Увольнения",  340, 240, ConfirmDeleteWindow, true);
}


protected var wnd_edit_employee:AppTitleWindow;

public function edit_employee(dg:DataGridEx):void
{
	var f_first_ini:Boolean = wnd_edit_employee == null;
	open_window(this, "wnd_edit_employee", "Правка сотрудника",  480, 400, EditEmployeeWindow);
	if (f_first_ini) {
		var w:AppTitleWindow  = wnd_edit_employee;
		var o:EditEmployeeWindow = w.holder.getChildAt(0) as EditEmployeeWindow;
		o.set_dg(dg);
	}
}



protected function open_window(papa:Object, ref:String, title:String, width:int, height:int, clazz:Class, f_modal:Boolean = false, ini:Object = null):AppTitleWindow
{
	if (papa[ref] != null) {
		PopUpManager.bringToFront(papa[ref]);
		return papa[ref];
	}
	
	var w:AppTitleWindow  = papa[ref] = PopUpManager.createPopUp(AppWindow.app, AppTitleWindow, f_modal) as AppTitleWindow;
	w.addEventListener(CloseEvent.CLOSE, on_app_window_close);
	
	w.ref = ref;	
	w.height = height;
	w.width  = width;
	
	w.title = title;
	w.holder.addChild(new clazz());
	//	w.ctrl.addChild(new Button());
	
	w.area.setStyle("paddingLeft", 8);
	w.area.setStyle("paddingRight", 8);	
	w.area.setStyle("paddingTop", 8);
	w.area.setStyle("paddingBottom", 8);
	
	PopUpManager.centerPopUp(w);	
	return w;
}

protected function on_app_window_close(e:Event):void
{
	var w:AppTitleWindow = (e.currentTarget as AppTitleWindow); 
	
	w.removeEventListener(CloseEvent.CLOSE, on_app_window_close);
	this[w.ref] = null;
}











}}