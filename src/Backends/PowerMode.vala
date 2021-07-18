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

//  [DBus (name = "org.freedesktop.systemd1.Manager")]
//  public interface SystemdManager : Object {
//      public abstract async void set_power_mode (int power_mode) throws GLib.Error;
//  }

public class PowerManagerDaemon.Backends.PowerMode : Object {
    private GLib.Settings power_mode_settings;
    private string[] available_cpu_governors;
    private uint core_count;
    bool monitoring;

    // Used for automatic mode
    private bool power_source_connected;
    private uint battery_level;
    private uint cpu_load;

    construct {
        power_mode_settings = new GLib.Settings ("io.elementary.power-manager-daemon.powermode");
        core_count = Utils.CPUFreq.get_core_count ();
        available_cpu_governors = Utils.CPUFreq.get_available_governors ();
        start_monitoring.begin ();
    }

    private async void start_monitoring () {
        if (!monitoring) {
            monitoring = true;
            new Thread<int> ("settings_monitor", settings_monitor);
        }
    }
    private int settings_monitor () {
        while (monitoring) {
            print ("Monitoring...\n");
            string user_string;
            string user = "";
            string settings_string = "0";
            int settings = 0;
            try {
                Process.spawn_command_line_sync ("who", out user_string);
                var regex = new Regex ("(.*) tty7");
                MatchInfo match_info;

                if (regex.match (user_string, 0, out match_info)) {
                    user = match_info.fetch (1);
                }
                if (user != "" && user != "root") {
                    Process.spawn_command_line_sync ("sudo -u " + user + " gsettings get io.elementary.power-manager-daemon.powermode power-mode", out settings_string);
                }
                settings = int.parse (settings_string);
            } catch (Error e) {
                warning (e.message);
            }

            switch (settings) {
                case 0:
                set_power_saving_mode.begin (true);
                break;
                case 1:
                break;
                case 2:
                set_power_saving_mode.begin (false);
                break;
            }
            Thread.yield ();
            Thread.usleep (30000000);
        }
        return 0;
    }

    private async void set_power_saving_mode (bool mode) {
        if (mode) {
            print ("Power Saving mode turned on\n");
            Utils.CPUFreq.set_cpu_governor (available_cpu_governors[2], core_count);
        } else {
            print ("High Performance mode turned on\n");
            Utils.CPUFreq.set_cpu_governor (available_cpu_governors[0], core_count);
        }
    }
}
