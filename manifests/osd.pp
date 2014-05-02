define ceph::osd(
  $directory,
  $type = 'ext4'
){
  include '::ceph'
  Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  }

  file{"create-${directory}":
    ensure  => directory,
    path    => $directory,
  }

  exec{"disk-prepare-${directory}":
    command    => "ceph-disk prepare --cluster ${ceph::cluster_id} --cluster-uuid ${ceph::fsid} --fs-type ${type} ${directory}",
    require    => File["create-${directory}"],
  }

  exec{"disk-activate-${directory}":
    command  => "ceph-disk activate ${directory}",
    require  => Exec["disk-prepare-${directory}"],
#    notify   => Exec['restart'],
  }

#  exec{"restart":
#    command  => "/sbin/service ceph restart",
#  }
}
