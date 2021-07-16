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

    // Used for automatic mode
    private bool smart;
    private bool power_source_connected;
    private uint battery_level;
    private uint cpu_load;

    construct {
        power_mode_settings = new GLib.Settings ("io.elementary.power-manager-daemon.powermode");
        core_count = Utils.CPUFreq.get_core_count ();
        available_cpu_governors = Utils.CPUFreq.get_available_governors ();
        //  print ("%s, %s, %s\n", available_cpu_governors[0], available_cpu_governors[1], available_cpu_governors[2]);

        power_mode_settings.changed.connect (() => {
            switch (power_mode_settings.get_int ("power-mode")) {
                case 0:
                smart = false;
                set_power_saving_mode.begin(true);
                break;
                case 1:
                set_smart_mode.begin();
                break;
                case 2:
                smart = false;
                set_power_saving_mode.begin(false);
                break;
            }
        });

        switch (power_mode_settings.get_int ("power-mode")) {
            case 0:
            smart = false;
            set_power_saving_mode.begin(true);
            break;
            case 1:
            set_smart_mode.begin();
            break;
            case 2:
            smart = false;
            set_power_saving_mode.begin(false);
            break;
        }
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

    private async void set_smart_mode () {
        if (!smart) {
            smart = true;
            new Thread<int> ("battery_monitor", battery_monitor);
        }
    }

    private int battery_monitor () {
        while (smart) {
            print ("Monitoring...\n");
            Thread.yield ();
            Thread.usleep (2000000);
        }
        return 0;
    }
}
