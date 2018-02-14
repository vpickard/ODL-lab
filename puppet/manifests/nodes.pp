node basenode {

  exec { "yum_update":
    command => "/bin/yum -y update",
    timeout => '600'
  }
  

  # Ensure the above command runs before we attempt
  # to install any package in other manifests
  #Exec["yum_update"] -> Package<| |>

  $base_packages = [
                     "git",
                     "gcc",
                     "make",
                     "python-devel",
                     "python-twisted-core",
                     "python-zope-interface",
                     "python-sphinx",
                     "libcap-ng-devel",
                     "openssl-devel",
                     "kernel-devel-$kernelrelease",
                     "graphviz",
                     "desktop-file-utils",
                     "groff",
                     "kernel-debug-devel",
                     "autoconf",
                     "automake",
                     "rpm-build",
                     "redhat-rpm-config",
                     "libtool",
                     "python-six",
                     "checkpolicy",
                     "selinux-policy-devel",
                     "wget",
                     "redhat-lsb-core",
                     "java-1.8.0-openjdk",
                     "tcpdump",
                     "traceroute",
                   ]

  package { $base_packages:
    ensure => installed,
  }
  file { '/rpmbuild/':
    ensure => 'directory',
  }
  file { '/rpmbuild/SOURCES':
    ensure => 'directory',
  }
  file { '/rpmbuild/RPMS':
    ensure => 'directory',
  }
  file { '/rpmbuild/BUILD':
    ensure => 'directory',
  }
  file { '/rpmbuild/BUILDROOT':
    ensure => 'directory',
  }
  file { '/rpmbuild/SPECS':
    ensure => 'directory',
  }
  file { '/rpmbuild/SRPMS':
    ensure => 'directory',
  }

  exec { "download_ovs":
    #command => "/usr/bin/wget http://openvswitch.org/releases/openvswitch-2.6.1.tar.gz -O /rpmbuild/SOURCES/openvswitch-2.6.1.tar.gz",
    require => File['/rpmbuild/SOURCES'],
    command => "/usr/bin/wget http://openvswitch.org/releases/openvswitch-2.8.1.tar.gz -O /rpmbuild/SOURCES/openvswitch-2.8.1.tar.gz",
    creates => "/rpmbuild/SOURCES/openvswitch-2.8.1.tar.gz",
  }

  exec { "extract_ovs":
    cwd     => "/rpmbuild/SOURCES",
    command => "/bin/tar xvfz openvswitch-2.8.1.tar.gz",
    require => [
                  Exec["download_ovs"],
               ],
    creates => "/rpmbuild/SOURCES/openvswitch-2.8.1/rhel/openvswitch-kmod-fedora.spec",
  }

  file { "/rpmbuild/SPECS/openvswitch-fedora.spec":
    ensure => "present",
    source => "file:////rpmbuild/SOURCES/openvswitch-2.8.1/rhel/openvswitch-fedora.spec",
    require => [
                  Exec["extract_ovs"],
               ],
  }

  file { "/rpmbuild/SPECS/openvswitch-kmod-fedora.spec":
    ensure => "present",
    source => "file:////rpmbuild/SOURCES/openvswitch-2.8.1/rhel/openvswitch-kmod-fedora.spec",
    require => [
                  Exec["extract_ovs"],
               ],
  }

  exec { "fix_kernel_symlink":
    cwd     => "/lib/modules/$kernelrelease",
    command => "/usr/bin/rm /lib/modules/$kernelrelease/build && /usr/bin/ln -s /usr/src/kernels/$kernelrelease /lib/modules/$kernelrelease/build",
    logoutput   => true,
    loglevel    => verbose,
    timeout     => 0,
    creates     => "/lib/modules/$kernelrelease/build/",
    require     => [
                     Exec["extract_ovs"],
                   ],
  }

  exec { "build_ovs_kernel":
    cwd     => "/rpmbuild/SOURCES",
    command => "/usr/bin/rpmbuild -bb -D \"kversion $kernelrelease\" /rpmbuild/SPECS/openvswitch-kmod-fedora.spec",
    logoutput   => true,
    loglevel    => verbose,
    timeout     => 0,
    creates     => "/rpmbuild/RPMS/x86_64/openvswitch-kmod-2.8.1-1.el7.centos.x86_64.rpm",
    require     => [
                     Package["rpm-build"],
                     Package["python-six"],
                     Package[$base_packages],
                     Exec["fix_kernel_symlink"],
                   ],
  }

  exec { "build_ovs":
    cwd     => "/rpmbuild/SOURCES",
    command => "/usr/bin/rpmbuild -bb --without check /rpmbuild/SPECS/openvswitch-fedora.spec",
    logoutput   => true,
    loglevel    => verbose,
    timeout     => 0,
    creates     => "/root/openvswitch-common_2.8.1-1_amd64.deb",
    require     => [
                     Package["rpm-build"],
                     Package["python-six"],
                     Package[$base_packages],
                     Exec["build_ovs_kernel"],
                   ],
  }

  exec { "install_ovs":
    command     => "/usr/bin/rpm -ivh --nodeps /rpmbuild/RPMS/x86_64/openvswitch*.rpm",
    require => [
                  Exec["build_ovs"],
               ],
  }

  exec { "enable_ovs":
    command     => "/usr/bin/systemctl enable openvswitch",
    require => [
                  Exec["install_ovs"],
               ],
  }

  exec { "start_ovs":
    command     => "/usr/bin/systemctl start openvswitch",
    require => [
                  Exec["enable_ovs"],
               ],
  }

  exec { "status_ovs":
    command     => "/usr/bin/systemctl status openvswitch",
    require => [
                  Exec["start_ovs"],
               ],
  }



}

node devStack inherits basenode {

  #file { '/opt/devstack':
  #   ensure => 'directory',
  #   owner  => 'root'
  #}

  exec { "download_devstack":
    cwd     => "/opt/",
    creates => "/opt/devstack",
    #command => "/usr/bin/git clone https://git.openstack.org/openstack-dev/devstack -b stable/newton "
    command => "/usr/bin/git clone https://git.openstack.org/openstack-dev/devstack -b master "
  }
}


import 'nodes/*.pp'
