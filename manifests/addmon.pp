#
class ceph::addmon (
    $monport = '6789',
    $tmpdir = '/tmp/addmon',
){

  include '::ceph'

  Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  }

  package { 'sshpass':
    ensure   => installed,
  }

  exec { 'copy-ceph.conf':
    command  => "sshpass -p 'toor' rsync -e 'ssh -o StrictHostKeyChecking=no' root@${ceph::firstmonip}:/etc/ceph/ceph.conf /etc/ceph/ceph.conf",
    creates  => '/etc/ceph/ceph.conf',
  }

  file{'/etc/ceph/ceph.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec['copy-ceph.conf'],
  }

  exec { 'copy-ceph.client.admin.keyring':
    command  => "sshpass -p 'toor' rsync -e 'ssh -o StrictHostKeyChecking=no' root@${ceph::firstmonip}:/etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring",
    creates  => '/etc/ceph/ceph.client.admin.keyring',
  }

  file{'/etc/ceph/ceph.client.admin.keyring':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec['copy-ceph.client.admin.keyring'],
  }

  file { "/var/lib/ceph/mon/ceph-${hostname}":
    ensure  => directory,
    require => File['/etc/ceph/ceph.client.admin.keyring'],
  }

  file { "create-${tmpdir}":
    ensure  => directory,
    path    => $tmpdir,
    require => File["/var/lib/ceph/mon/ceph-${hostname}"],
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
    command  => "/usr/bin/ceph-mon -i ${hostname} --mkfs --monmap ${tmpdir}/map --keyring ${tmpdir}/keyring",
    require  => [
      Exec['retrieve-keyring'],
      Exec['retrieve-map'],
      File["/var/lib/ceph/mon/ceph-${hostname}"],
      ],
    user     => 'root',
  }

  exec { 'monitor-address-binding':
    command  => "/usr/bin/ceph-mon -i ${hostname} --public-addr ${ipaddress}:${monport}",
    require  => Exec['prepare-data-directory'],
  }

  exec { 'add-monitor':
    command  => "/usr/bin/ceph mon add ${hostname} ${ipaddress}:${monport}",
    require  => Exec['monitor-address-binding'],
  }

  exec { 'pkill-ceph':
    command  => 'sudo pkill ceph',
    require  => Exec['add-monitor'],
  }

  exec { 'start-monitor':
    command  => "start ceph-mon id=${hostname}",
    require  => Exec['pkill-ceph'],
  }

  ceph::osd {'share3':
    directory  => '/var/local/ceph3',
    require    => [
                        Exec['start-monitor'],
                ],
  }

  ceph::osd {'share4':
    directory  => '/var/local/ceph4',
    require    => [
                        Exec['start-monitor'],
                ],
  }

}
