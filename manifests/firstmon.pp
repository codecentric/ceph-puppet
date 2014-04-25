class ceph::firstmon() {

#  include '::ceph'
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
#    require     =>  Class['::ceph::mon'],
  }

  file { 'copy-ceph.client.admin.keyring':
    path        => '/tmp/files/ceph.client.admin.keyring',
    source      => '/etc/ceph/ceph.client.admin.keyring',
#    require     => Class['::ceph::mon'],
  }


  ceph::osd {'share1':
    directory  => '/var/local/ceph1',
    require    => File['copy-ceph.client.admin.keyring'],
#                        Class['::ceph::mon'],
#                        ],
  }

  ceph::osd {'share2':
    directory  => '/var/local/ceph2',
    require    => File['copy-ceph.client.admin.keyring'],
#                        Class['::ceph::mon'],
#                        ],
  }

}

