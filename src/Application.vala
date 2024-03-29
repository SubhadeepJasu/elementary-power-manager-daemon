/*
* Copyright 2021 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/


public class PowerManagerDaemon.Application : GLib.Application {
    public const OptionEntry[] OPTIONS = {
        { "version", 'v', 0, OptionArg.NONE, out show_version, "Display the version", null},
        { null }
    };

    public static bool show_version;

    private Application () {}

    private Backends.PowerMode power_mode;

    construct {
        application_id = Build.PROJECT_NAME;

        add_main_option_entries (OPTIONS);

        power_mode = new Backends.PowerMode ();
    }

    public override int handle_local_options (VariantDict options) {
        if (show_version) {
            print ("%s\n", Build.VERSION);
            return 0;
        }

        return -1;
    }

    public override void activate () {
        hold ();
    }

    public static int main (string[] args) {
        var application = new Application ();
        return application.run (args);
    }
}
