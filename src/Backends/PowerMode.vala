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
    private int battery_level;
    private uint battery_status;
    private bool battery_present;
    private float powersave_cpu_load_threshold;

    construct {
        power_mode_settings = new GLib.Settings ("io.elementary.power-manager-daemon.powermode");
        core_count = Utils.CPUFreq.get_core_count ();
        available_cpu_governors = Utils.CPUFreq.get_available_governors ();
        battery_present = Utils.Battery.get_battery_present_by_index (0);
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
                set_power_saving_mode.begin (false, false);
                break;
                case 1:
                set_automatic_mode.begin ();
                break;
                case 2:
                set_performance_mode.begin ();
                break;
            }
            Thread.yield ();
            Thread.usleep (30000000);
        }
        return 0;
    }

    private async void set_power_saving_mode (bool on_demand_preference, bool turbo_preference) {
        float cpu_load = Utils.CPUFreq.get_cpu_load ();
        float cpu_powersave_threshold = Utils.CPUFreq.powersave_cpu_load_threshold;
        if (turbo_preference && cpu_load > cpu_powersave_threshold) {
            Utils.CPUFreq.set_cpu_governor (available_cpu_governors[2], core_count);
            debug ("High system load, Power Saving mode: ON");
            debug ("Suggesting Turbo: ON");
            Utils.CPUFreq.set_turbo (true);
        } else if (on_demand_preference && cpu_load > cpu_powersave_threshold && available_cpu_governors[1] != null) {
            debug ("High system load, On Demand mode: ON");
            Utils.CPUFreq.set_cpu_governor (available_cpu_governors[1], core_count);
            debug ("Suggesting Turbo: OFF");
            Utils.CPUFreq.set_turbo (false);
        } else {
            debug ("Power Saving mode turned: ON");
            Utils.CPUFreq.set_cpu_governor (available_cpu_governors[2], core_count);
            debug ("Suggesting Turbo: OFF");
            Utils.CPUFreq.set_turbo (false);
        }
    }

    private async void set_performance_mode () {
        float cpu_load = Utils.CPUFreq.get_cpu_load ();
        float cpu_performance_threshold = Utils.CPUFreq.performance_cpu_load_threshold;
        Utils.CPUFreq.set_cpu_governor (available_cpu_governors[0], core_count);

        if (cpu_load > cpu_performance_threshold) {
            debug ("High system load, Performance mode: ON");
            debug ("Suggesting Turbo: ON");
            Utils.CPUFreq.set_turbo (true);
        } else {
            debug ("High Performance mode: ON");
            debug ("Suggesting Turbo: OFF");
            Utils.CPUFreq.set_turbo (false);
        }
    }

    private async void set_automatic_mode () {
        debug ("Automatic mode: ON");
        if (battery_present) {
            battery_level = Utils.Battery.get_battery_percentage_by_index (0);
            battery_status = Utils.Battery.get_battery_status_by_index (0);
            
            if (battery_status != -1 && battery_level != -1) {
                switch (battery_status) {
                    case 0:
                    if (battery_level >= 80) {
                        set_power_saving_mode.begin (true, true);
                    } else if (battery_level >= 50) {
                        set_power_saving_mode.begin (true, false);
                    } else {
                        set_power_saving_mode.begin (false, false);
                    }
                    break;
                    case 1:
                    if (battery_level >= 50) {
                        set_performance_mode.begin ();
                    } else if (battery_level >= 20) {
                        set_power_saving_mode.begin (true, true);
                    } else {
                        set_power_saving_mode.begin (false, false);
                    }
                    break;
                    case 2:
                    set_performance_mode.begin ();
                    break;
                }
            } else {
                set_power_saving_mode.begin (true, true);
            }
        } else {
            set_performance_mode.begin ();
        }
    }
}
