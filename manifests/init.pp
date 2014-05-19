class ceph (
    $cluster_id = 'ceph',
    $firstmonflag = true,
    $firstmonip = '172.16.0.9',
    $fsid = 'a49812c5-9873-47c8-9983-5b062454abce',
    $public_net = '172.16.0.0/24',
    $release = 'emperor',
){

  if $firstmonflag == true {
    include ceph::firstmon
  }
  elsif $firstmonflag == false {
    include ceph::addmon
  }

  Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]
  }

  apt::key { 'ceph':
    key        => '17ED316D',
    key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
  }

  apt::key { 'radosgw':
    key     => '6EAEAE2203C3951A'
  }

  Apt::Source {
    require  => Apt::Key['ceph', 'radosgw'],
    release  => $::lsbdistcodename,
  }

  apt::source { 'ceph':
    location => "http://ceph.com/debian-${release}/",
  }

  apt::source { 'radosgw-apache2':
    location => 'http://gitbuilder.ceph.com/apache2-deb-quantal-x86_64-basic/ref/master/',
  }

  apt::source { 'radosgw-fastcgi':
    location => 'http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-quantal-x86_64-basic/ref/master/',
  }

  # update and source installation
  exec { 'apt-update':
    command  => '/usr/bin/apt-get update',
    require  => [
      Apt::Source['ceph'],
      Apt::Source['radosgw-apache2'],
      Apt::Source['radosgw-fastcgi'],
    ],
  }

  package { 'ceph':
    ensure   => installed,
    require  => Exec['apt-update'],
  }

  if $firstmonflag == true {
    Class['ceph'] -> Class['ceph::firstmon']
  }
  elsif $firstmonflag == false {
    Class['ceph'] -> Class['ceph::addmon']
  }

}
