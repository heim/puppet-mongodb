# Sample Usage:
#  class { mongodb:
#    replSet => "myReplicaSet",
#    ulimit_nofile => 20000,
#  }
#
class mongodb(
  $replSet = $mongodb::params::replSet,
  $ulimit_nofile = $mongodb::params::ulimit_nofile,
  $repository = $mongodb::params::repository,
  $package = $mongodb::params::package,
  $port = $mongodb::params::port
) inherits mongodb::params {

  #Resource ordering 
  Exec["10gen-apt-repo"] -> Exec["10gen-apt-key"] -> Exec["update-apt"] -> Package[$mongodb::params::package] -> Service["mongodb"]
  File["/etc/init/mongodb.conf"] ~> Service["mongodb"] <~ File["/etc/mongodb.conf"]


  exec { "10gen-apt-repo":
    path => "/bin:/usr/bin",
    command => "echo '${mongodb::params::repository}' >> /etc/apt/sources.list",
    unless => "cat /etc/apt/sources.list | grep '${mongodb::params::repository}'",
  }

  exec { "10gen-apt-key":
    path => "/bin:/usr/bin",
    command => "apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10",
    unless => "apt-key list | grep 10gen",
  }

  exec { "update-apt":
    path => "/bin:/usr/bin",
    command => "apt-get update",
    unless => "ls /usr/bin | grep mongo",
  }

  package { $mongodb::params::package:
    ensure => installed,
  }

  service { "mongodb":
    enable => true,
    ensure => running,
  }

  file { "/etc/mongodb.conf":
    content => template("mongodb/mongodb.conf.erb"),
    mode => "0644",
  }

  file { "/etc/init/mongodb.conf":
    content => template("mongodb/init.mongodb.conf.erb"),
    mode => "0644",
  }
}
