install_data(
    'io.elementary.power-manager-daemon.service',
    install_dir: '/etc/systemd/system'
)

dbus_dep = dependency('dbus-1')
dbus_interfaces_dir = dbus_dep.get_pkgconfig_variable('interfaces_dir', define_variable: ['datadir', datadir])


install_data(
    'io.elementary.power-manager-daemon.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas')
)
