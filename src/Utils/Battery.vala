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

public class PowerManagerDaemon.Utils.Battery : Object {
    private const string BATTERY_FILE_LOCATION = "/sys/class/power_supply/BAT";

    public static bool get_battery_present_by_index (uint index) {
        return GLib.FileUtils.test (BATTERY_FILE_LOCATION + index.to_string (), GLib.FileTest.IS_DIR);
    }

    public static uint get_battery_count () {
        bool battery_available = false;
        uint count = 0;
        do {
            if (get_battery_present_by_index (count)) {
                battery_available = true;
                count++;
            } else {
                battery_available = false;
            }
        } while (battery_available);
        return count;
    }

    public static int get_battery_percentage_by_index (uint index) {
        var capacity_file = File.new_for_path (BATTERY_FILE_LOCATION + index.to_string () + "/capacity");
        try {
            var capacity_fs = new DataInputStream (capacity_file.read ());
            return int.parse (capacity_fs.read_line (null));
        } catch (Error e) {
            warning (e.message);
        }
        return -1;
    }

    public static uint get_battery_status_by_index (uint index) {
        var status_file = File.new_for_path (BATTERY_FILE_LOCATION + index.to_string () + "/status");
        try {
            var status_fs = new DataInputStream (status_file.read ());
            string status = status_fs.read_line (null);
            if (status.down () == "discharging") {
                return 0;
            } else if (status.down () == "charging") {
                return 1;
            } else if (status.down () == "full") {
                return 2;
            }
        } catch (Error e) {
            warning (e.message);
        }
        return -1;
    }
}
