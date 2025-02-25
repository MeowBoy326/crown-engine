/*
 * Copyright (c) 2012-2023 Daniele Bartolini et al.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Gtk;
using Gee;

namespace Crown
{
[GtkTemplate (ui = "/org/crown/level_editor/ui/panel_projects_list.ui")]
public class PanelProjectsList : Gtk.ScrolledWindow
{
	// Data
	User _user;

	// Widgets
	[GtkChild]
	unowned Gtk.ListBox _list_projects;

	[GtkChild]
	unowned Gtk.Button _button_new_project;

	[GtkChild]
	unowned Gtk.Button _button_import_project;

	public PanelProjectsList(User user)
	{
		this.shadow_type = Gtk.ShadowType.NONE;

		// Data
		_user = user;

		_list_projects.set_sort_func((row1, row2) => {
				int64 mtime1 = int64.parse(row1.get_data("mtime"));
				int64 mtime2 = int64.parse(row2.get_data("mtime"));
				return mtime1 > mtime2 ? -1 : 1; // LRU
			});

		_button_new_project.clicked.connect(() => {
				var app = (LevelEditorApplication)GLib.Application.get_default();
				app.show_panel("panel_new_project", Gtk.StackTransitionType.SLIDE_DOWN);
			});

		_button_import_project.clicked.connect(() => {
				GLib.Application.get_default().activate_action("add-project", null);
			});

		_user.recent_project_added.connect(on_recent_project_added);
		_user.recent_project_touched.connect(on_recent_project_touched);
		// _user.recent_project_removed.connect(on_recent_project_remove);
	}

	public void on_recent_project_added(string source_dir, string name, string time)
	{
		Gtk.Widget widget;

		// Add row
		Gtk.ListBoxRow row = new Gtk.ListBoxRow();
		row.set_data("source_dir", source_dir);
		row.set_data("mtime", time);
		Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

		widget = new Gtk.Label(null);
		widget.set_margin_start(12);
		widget.set_margin_end(12);
		widget.set_margin_top(8);
		widget.set_margin_bottom(8);
		((Gtk.Label)widget).set_markup("<b>%s</b>".printf(name));
		((Gtk.Label)widget).set_xalign(0.0f);
		vbox.pack_start(widget);

		widget = new Gtk.Label(null);
		widget.set_margin_start(12);
		widget.set_margin_end(12);
		widget.set_margin_bottom(8);
		((Gtk.Label)widget).set_markup("<small>%s</small>".printf(source_dir));
		((Gtk.Label)widget).set_xalign(0.0f);
		vbox.pack_start(widget);

		Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		hbox.pack_start(vbox);

		Gtk.Button remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic");
		remove_button.get_style_context().add_class("flat");
		remove_button.get_style_context().add_class("destructive-action");
		remove_button.set_halign(Gtk.Align.CENTER);
		remove_button.set_valign(Gtk.Align.CENTER);
		remove_button.set_margin_end(12);
		remove_button.clicked.connect(() => {
				Gtk.MessageDialog md = new Gtk.MessageDialog((Gtk.Window)this.get_toplevel()
					, Gtk.DialogFlags.MODAL
					, Gtk.MessageType.WARNING
					, Gtk.ButtonsType.NONE
					, "Remove \"%s\" from the list?\n\nThis action removes the project from the list only, files on disk will not be deleted.".printf(source_dir)
					);
				md.add_button("_Cancel", ResponseType.CANCEL);
				md.add_button("_Remove", ResponseType.YES);
				md.set_default_response(ResponseType.CANCEL);
				int rt = md.run();
				md.destroy();

				if (rt == ResponseType.CANCEL)
					return;

				_user.remove_recent_project(row.get_data("source_dir"));
				_list_projects.remove(row);
			});
		hbox.pack_end(remove_button, false, false, 0);

		Gtk.Button button_open = new Gtk.Button.with_label("Open");
		button_open.get_style_context().add_class("flat");
		button_open.set_halign(Gtk.Align.CENTER);
		button_open.set_valign(Gtk.Align.CENTER);
		// button_open.set_margin_end(12);
		button_open.clicked.connect(() => {
				GLib.Application.get_default().activate_action("open-project", new GLib.Variant.string(source_dir));
			});
		hbox.pack_end(button_open, false, false, 0);

		row.add(hbox);
		_list_projects.add(row);
		_list_projects.show_all(); // Otherwise the list is not always updated...

		if (!GLib.FileUtils.test(source_dir, FileTest.EXISTS))
			button_open.sensitive = false;
	}

	public void on_recent_project_touched(string source_dir, string mtime)
	{
		_list_projects.foreach((row) => {
				if (row.get_data<string>("source_dir") == source_dir) {
					row.set_data("mtime", mtime);
					return;
				}
			});

		_list_projects.invalidate_sort();
	}
}

} /* namespace Crown */
