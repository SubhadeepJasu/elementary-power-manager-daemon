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
* Authored by: Subhadeep Jasu <subhajasu@gmail.com>
*/

public class PowerManagerDaemon.Utils.CPUFreq {
    private const string CPU_INFO_FILE = "/proc/cpuinfo";
    private const string CPU_LOCATION = "/sys/devices/system/cpu";
    private const string CPU_LOAD_AVG = "/proc/loadavg";
    private const string INTEL_P_STATE = "/sys/devices/system/cpu/intel_pstate/no_turbo";
    private const string CPUFREQ_BOOST = "/sys/devices/system/cpu/cpufreq/boost";

    /* Code taken from auto-cpufreq */
    public static float powersave_cpu_load_threshold = 1.4f;
    public static float performance_cpu_load_threshold = 1.0f;

    /* Code taken from com.github.hannesschulze.optimizer */
    public static uint get_core_count () {
        var cpu_file = File.new_for_path (CPU_INFO_FILE);
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
        powersave_cpu_load_threshold = (70.0f * (float)cores) / 100.0f;
        performance_cpu_load_threshold = (50.0f * (float)cores) / 100.0f;
        return cores;
    }

    public static string[] get_available_governors () {
        string[] available_governors = new string[3];
        if (GLib.FileUtils.test(CPU_LOCATION + "/cpu0/cpufreq/", GLib.FileTest.IS_DIR)) {
            var scaling_file = File.new_for_path (CPU_LOCATION + "/cpu0/cpufreq/scaling_available_governors");
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
        for (int i = 0; i < core_count; i++) {
            debug ("Setting %s mode for CPU %u", mode_string, i);
            var ds = FileStream.open ("/sys/devices/system/cpu/cpu" + i.to_string () + "/cpufreq/scaling_governor", "r+");
            if (ds != null) {
                string line = ds.read_line ();
                if (!line.contains (mode_string)) {
                    ds.puts (mode_string + "\n");
                }
            } else {
                error ("Fatal: Cannot edit CPU governor, access is denied");
            }
        }
    }

    public static float get_cpu_load () {
        var load_file = File.new_for_path (CPU_LOAD_AVG);
        try {
            var dis = new DataInputStream (load_file.read ());
            var line = dis.read_line ();
            var sections = line.split (" ");
            return float.parse (sections[0]);
        } catch (Error e) {
            warning (e.message);
        }

        return -1.0f;
    }

    public static void set_turbo (bool turbo_on) {
        FileStream turbo_descriptor = null;

        bool inverted = false;
        if (GLib.FileUtils.test(INTEL_P_STATE, GLib.FileTest.EXISTS)) {
            turbo_descriptor = FileStream.open (INTEL_P_STATE, "w");
            inverted = true;
        } else if (GLib.FileUtils.test(CPUFREQ_BOOST, GLib.FileTest.EXISTS)) {
            turbo_descriptor = FileStream.open (CPUFREQ_BOOST, "w");
        } else {
            debug ("CPU Turbo not available");
        }
        
        if (turbo_descriptor != null) {
            if (turbo_descriptor.error () != 0) {
                warning ("Cannot suggest CPU Turbo!");
            } else {
                if (inverted) {
                    turbo_descriptor.puts (turbo_on ? "0\n" : "1\n");
                } else {
                    turbo_descriptor.puts (turbo_on ? "1\n" : "0\n");
                }
            }
        }
    }
}
