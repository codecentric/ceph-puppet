class ceph::firstmon() {

#  class {'::ceph':
#    fsid => 'a49812c5-9873-47c8-9983-5b062454abce',
#    public_net => '172.16.0.0/24',
#   release => 'cuttlefish',
#    release => 'emperor',
#    cluster_id => 'ceph',
#    network_interface => 'eth0',
#    host_ipaddress => '172.16.0.32',
#    hostname => 'initcephmon',
#}
#  include '::ceph::mon'

  file { '/tmp/files':
        ensure  => directory,
        owner   => nobody,
        group   => nogroup,
        mode    => 777,
}

  file { 'copy-ceph.conf':
    path        => '/tmp/files/ceph.conf',
    source      => '/etc/ceph/ceph.conf',
    require     =>  Class['::ceph'],
  }

  file { 'copy-ceph.client.admin.keyring':
    path        => '/tmp/files/ceph.client.admin.keyring',
    source      => '/etc/ceph/ceph.client.admin.keyring',
    require     => Class['::ceph'],
  }


  ceph::osd {'share1':
    directory  => '/var/local/ceph1',
    require    => [File['copy-ceph.client.admin.keyring'],
                        Class['::ceph'],
                        ],
  }

  ceph::osd {'share2':
    directory  => '/var/local/ceph2',
    require    => [File['copy-ceph.client.admin.keyring'],
                        Class['::ceph'],
                        ],
  }

}

