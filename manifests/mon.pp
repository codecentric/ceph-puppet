class ceph::mon(

){
  include '::ceph'

  Exec{
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]
  }

  $mon_keyring = '/tmp/ceph.mon.keyring'
  $admin_keyring = '/etc/ceph/ceph.client.admin.keyring'
  $mon_tmp = '/tmp/monmap'

  file{ "${ceph::cluster_id}.conf":
    path     => "/etc/ceph/${ceph::cluster_id}.conf",
    content  => template('ceph/ceph.erb'),
  }

  exec{ 'create-keyring-monitor':
    command => "ceph-authtool --create-keyring ${mon_keyring} --gen-key -n mon. --cap mon 'allow *'",
    creates => $mon_keyring,
    require => File["${ceph::cluster_id}.conf"],
  }

  exec{'create-keyring-admin':
    command  => "ceph-authtool --create-keyring ${admin_keyring} --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'",
    creates  => $admin_keyring,
    require  => Exec['create-keyring-monitor'],
  }

  exec{'add-admin-to-monitor-keyring':
    command => "ceph-authtool ${mon_keyring} --import-keyring ${admin_keyring}",
    require => Exec['create-keyring-admin'],
  }

  file{'ceph.client.admin.keyring':
    ensure  => present,
    path    => $admin_keyring,
    mode    => '0644',
    require => Exec['add-admin-to-monitor-keyring'],
  }

#  $ipaddress_nic = inline_template("<%= @ipaddress_${ceph::network_interface} %>")

  exec{'create-monitor-map':
    command  => "monmaptool --create --add ${ceph::hostname} ${ceph::host_ipaddress} --fsid ${ceph::fsid} ${mon_tmp}",
    creates  => $mon_tmp,
#    require  => File['ceph.client.admin.keyring'],
  }

  file{'monitor-directory':
    ensure   => directory,
    path     => "/var/lib/ceph/mon/${ceph::cluster_id}-${ceph::hostname}",
#    require  => Exec['create-monitor-map'],
  }

  exec{'populate-monitor':
    command  => "ceph-mon --mkfs -i ${ceph::hostname} --monmap ${mon_tmp} --keyring ${mon_keyring}",
    require  => [
 #       File['monitor-directory'],
        Exec['create-monitor-map'],
      ],
    unless   => "test -f /var/lib/ceph/mon/${ceph::cluster_id}-${ceph::hostname}/store.db/LOCK"
  }

#  Wont work, as ceph-mon returns exit code 1 instead of 3 (as described in LSB init scripts) for status call to new nodes. 'sic
#  service {"ceph-mon":
#    name  => "ceph-mon id=${ceph::hostname}",
#    ensure  => running,
#    provider => upstart,
#    require  => Exec["populate-monitor"]
#  }

  exec{'start-monitor':
    command  => "start ceph-mon id=${ceph::hostname}",
    require  => Exec['populate-monitor'],
    unless   => "status ceph-mon id=${ceph::hostname}",
  }
}
