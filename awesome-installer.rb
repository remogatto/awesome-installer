require 'rubygems'
require 'rake'

BASEDIR = File.expand_path(File.dirname __FILE__)
LOGFILE = File.join(BASEDIR, '.awesome-installer.log')
GIT_AWESOME = "git://git.naquadah.org"
GIT_XORG = "git://anongit.freedesktop.org/git"
UBUNTU_DEPS = %w(build-essential autoconf automake libtool gperf xmlto git-core libx11-dev libxinerama-dev libxrandr-dev libpango1.0-dev libimlib2-dev libgtk2.0-dev libxcb-shm0-dev libxcb-render0-dev  libxcb-randr0-dev libxcb-shape0-dev libcairo2-dev libxcb-xinerama0-dev liblua5.1-filesystem0 liblua5.1-logging libdirectfb-dev libxt-dev libx11-xcb-dev cmake lua5.1 liblua5.1-0-dev libev3 libev-dev luadoc liblua5.1-doc0 libxcb-aux0 libxcb-keysyms0 libxcb-xtest0-dev imagemagick asciidoc)
TAR_GZ_XCB_UTIL = "http://xcb.freedesktop.org/dist/xcb-util-0.3.5.tar.gz"
TAR_GZ_XDG_BASEDIR = "http://n.ethz.ch/student/nevillm/download/libxdg-basedir/libxdg-basedir-1.0.1.tar.gz"
TAR_GZ_STARTUP_NOTIFICATION = "http://www.freedesktop.org/software/startup-notification/releases/startup-notification-0.10.tar.gz"
GIT_REPOS = { 
  'macros' => File.join(GIT_XORG, 'xorg/util/macros'),
  'libXau' => File.join(GIT_XORG, 'xorg/lib/libXau'),
  'x11proto' => File.join(GIT_XORG, 'xorg/proto/x11proto'),
  'pthread-stubs' => File.join(GIT_XORG, 'xcb/pthread-stubs'),
  'proto' => File.join(GIT_XORG, 'xcb/proto'),
  'libxcb' => File.join(GIT_XORG, 'xcb/libxcb'),
  'xextproto' => File.join(GIT_XORG, 'xorg/proto/xextproto'),
  'kbproto' => File.join(GIT_XORG, 'xorg/proto/kbproto'),
  'inputproto' => File.join(GIT_XORG, 'xorg/proto/inputproto'),
  'libxtrans' => File.join(GIT_XORG, 'xorg/lib/libxtrans'),
  'libX11' => File.join(GIT_XORG, 'xorg/lib/libX11'),
  'awesome' => File.join(GIT_AWESOME, 'awesome')
}
XSESSION = <<EOF
#!/usr/bin/env bash
xsetroot -solid black &
exec /usr/local/bin/awesome

EOF
def chdir(dirname, &blk)
  FileUtils.chdir(dirname)
  yield dirname if block_given?
  FileUtils.chdir '..'
end
def sudo_run(cmd); run "sudo #{cmd}" end
def run(cmd)
  puts "Execute #{cmd}"
  system "#{cmd} > #{LOGFILE} 2>&1"
end
def git_clone(url) 
  unless File.exists?(File.basename(url))
    run "git clone #{url}"
  else
    puts "Directory #{File.basename(url)} exists. Skipping clone."
  end
end
def untar(fn); run "tar xvzf #{fn}" end
def wget(url); run "wget #{url}" end
def autogen; run "./autogen.sh" end
def configure
  run "./configure" unless File.exists?('Makefile')
end
def make; run "make" end
def make_install; sudo_run "make install" end
def export_aclocal
  puts "Exporting aclocal"
  run "export ACLOCAL=\"aclocal -I /usr/local/share/aclocal\""
end
def make_make_install
  unless make && make_install
    raise "An error was raised during building. Please check #{LOGFILE}"
  end
end
def build
  unless File.exists?('Makefile')
    File.exists?('configure') ? configure : autogen
  end
  make_make_install
end
def clone_and_build(git_url, repo)
  puts "Cloning and installing #{repo}"
  git_clone git_url, repo
  chdir(File.basename(repo)) { build }
end
def install_ubuntu_deps
  sudo_run "apt-get install -y #{UBUNTU_DEPS.join(' ')}"
end
desc 'Install ubuntu dependecies'
task :ubuntu_deps do
  puts "Installing ubuntu deps..."
  install_ubuntu_deps
end
GIT_REPOS.each do |name, url|
  task "clone_#{name}" do
    git_clone url
  end
  desc "Build #{name}"
  task "build_#{name}" => "clone_#{name}" do
    chdir name do
      build
    end
  end
end

task 'export_aclocal' do
  export_aclocal
end

desc 'Build xcb/util'
task 'build_xcb_util' do
  wget TAR_GZ_XCB_UTIL
  untar 'xcb-util-0.3.5.tar.gz'
  chdir 'xcb-util-0.3.5' do 
    build
  end  
end

desc 'Build xdg-basedir'
task 'build_xdg-basedir' do
  wget TAR_GZ_XDG_BASEDIR
  untar 'libxdg-basedir-1.0.1.tar.gz'
  chdir 'libxdg-basedir-1.0.1' do 
    build
  end
end

desc 'Build startup-notification'
task 'build_startup-notification' do
  wget TAR_GZ_STARTUP_NOTIFICATION
  untar 'startup-notification-0.10.tar.gz'
  chdir 'startup-notification-0.10' do
    build
  end
end

desc 'Build awesome'
task :build_all => %w(build_macros export_aclocal build_libXau build_x11proto build_pthread-stubs build_proto build_libxcb build_xextproto build_kbproto build_inputproto build_libxtrans build_libX11 build_xcb_util build_xdg-basedir build_startup-notification build_awesome) do
  sudo_run 'ldconfig'
end

desc 'Configure awesome'
task :configure do
  File.open(File.expand_path('~/.xsession'), 'w') do |f|
    f << XSESSION
  end
  FileUtils.mkdir '~/.config/awesome'
  FileUtils.cp 'cp /usr/local/etc/xdg/awesome/rc.lua ~/.config/awesome/'
end


