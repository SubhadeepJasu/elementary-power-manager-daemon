project('io.elementary.power-manager-daemon',
    'c', 'vala',
    version: '0.0.2',
    license: 'GPL3',
)

gio_dep = dependency ('gio-2.0')
glib_dep = dependency('glib-2.0')
granite_dep = dependency('granite', version: '>= 5.3.0')
i18n = import('i18n')

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required : false)

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))

symlink = join_paths(meson.current_source_dir (), 'meson', 'create-symlink.sh')

subdir('data')
subdir('src')

meson.add_install_script('meson/post_install.py')
