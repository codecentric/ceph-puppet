class ceph::addmon (
    $monid = "hostname",
    $monipaddress = "192.168.1.1",
    $monport = '6789',
    $tmpdir = '/tmp/addmon',
  ){

  Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  }

  file { "/var/lib/ceph/mon/ceph-${monid}":
    ensure  => directory,
  }

  file { "create-${tmpdir}":
    ensure  => directory,
    path    => $tmpdir,
  }

  exec { 'retrieve-keyring':
    command  => "/usr/bin/ceph auth get mon. -o ${tmpdir}/keyring",
    creates  => "${tmpdir}/keyring",
    require  => File["create-${tmpdir}"],
  }

  exec { 'retrieve-map':
    command  => "/usr/bin/ceph mon getmap -o ${tmpdir}/map",
    creates  => "${tmpdir}/map",
    require  => File["create-${tmpdir}"],
  }

  exec { 'prepare-data-directory':
    command  => "/usr/bin/ceph-mon -i ${monid} --mkfs --monmap ${tmpdir}/map --keyring ${tmpdir}/keyring",
    require  => [
      Exec['retrieve-keyring'],
      Exec['retrieve-map'],
      File["/var/lib/ceph/mon/ceph-${monid}"],
      ],
    user     => 'root',
#    unless
  }

  exec { 'monitor-address-binding':
    command  => "/usr/bin/ceph-mon -i ${monid} --public-addr ${monipaddress}:${monport}",
    require  => Exec['prepare-data-directory'],
  }

  exec { 'add-monitor':
    command  => "/usr/bin/ceph mon add ${monid} ${monipaddress}:${monport}",
    require  => Exec['monitor-address-binding'],
  }

  exec { 'pkill-ceph':
    command  => 'sudo pkill ceph',
    require  => Exec['add-monitor'],
  }

  exec { 'start-monitor':
    command => "start ceph-mon id=${monid}",
    require  => Exec["pkill-ceph"],
  }

  # remove tmpdir
}
