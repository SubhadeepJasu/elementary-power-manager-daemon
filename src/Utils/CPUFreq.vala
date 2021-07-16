
/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
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
* Authored by: Subhadeep Jasu <subhajasu@gmail.com>
*/

public class PowerManagerDaemon.Utils.CPUFreq {
    /* Code taken from com.github.hannesschulze.optimizer */
    public static uint get_core_count () {
        var cpu_file = File.new_for_path ("/proc/cpuinfo");
        uint cores = 0U;
        try {
            var dis = new DataInputStream (cpu_file.read ());
            string line;
            while ((line = dis.read_line ()) != null) {
                if (line.has_prefix ("model name")) {
                        cores++;
                }
            }
        } catch (Error e) {
            warning (e.message);
        }

        return cores;
    }

    public static string[] get_available_governors () {
        string[] available_governors = new string[3];
        if (GLib.FileUtils.test("/sys/devices/system/cpu/cpu0/cpufreq/", GLib.FileTest.IS_DIR)) {
            var scaling_file = File.new_for_path ("/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors");
            try {
                var dis = new DataInputStream (scaling_file.read ());
                string line = dis.read_line ();
                string[] scaling_modes = line.split (" ");
                for (int i = 0; i < scaling_modes.length; i++) {
                    if (scaling_modes[i] == "performance") {
                        available_governors[0] = "performance";
                        break;
                    }
                }
                for (int i = 0; i < scaling_modes.length; i++) {
                    if (scaling_modes[i] == "ondemand") {
                        available_governors[1] = "ondemand";
                        break;
                    }
                }
                for (int i = 0; i < scaling_modes.length; i++) {
                    if (scaling_modes[i] == "powersave") {
                        available_governors[2] = "powersave";
                        break;
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }
        } else {
            warning ("CPU scaling governors not available");
        }
        return available_governors;
    }

    public static void set_cpu_governor (string mode_string, uint core_count) {
        try {
            for (int i = 0; i < core_count; i++) {
                print ("Setting %s mode for CPU %u\n", mode_string, i);
                //  var governor_file = File.new_for_path ("/sys/devices/system/cpu/cpu" + i.to_string () + "/cpufreq/scaling_governor");
                var ds = FileStream.open ("/sys/devices/system/cpu/cpu" + i.to_string () + "/cpufreq/scaling_governor", "r+");
                if (ds != null) {
                    string line = ds.read_line ();
                    if (!line.contains (mode_string)) {
                        ds.puts (mode_string + "\n");
                    }
                } else {
                    error ("Fatal: Cannot edit CPU governor, access is denied");
                }
                print ("Done!\n");
            }
        } catch (Error e) {
            warning ("CPU Governor change failed: %s", e.message);
        }
    }
}
