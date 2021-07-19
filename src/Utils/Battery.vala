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
