class hdp()
{
  import 'params.pp'
  include hdp::params
  
  group { $hdp::params::hadoop_user_group :
    ensure => present
  }

  #TODO: think not needed and also there seems to be a puppet bug around this and ldap
  hdp::user { $hdp::params::hadoop_user:
    gid => $hdp::params::hadoop_user_group
  }
  Group[$hdp::params::hadoop_user_group] -> Hdp::User[$hdp::params::hadoop_user] 

  class { 'hdp::package::epel_rpm' :}

  class { 'hdp::set_hdp_yum_repo': }

  class { 'hdp::snmp': service_state => 'running'}

  class { 'hdp::create_smoke_user': }

  #turns off selinux
  class { 'hdp::set_selinux': }

  if ($hdp::params::lzo_enabled == true) {
    @hdp::lzo::package{ 32:}
    @hdp::lzo::package{ 64:}
    hdp::artifact_dir { 'hdp::lzo::package::tar':}
  }
  #TODO: treat consistently 
  if ($hdp::params::snappy_enabled == true) {
    include hdp::snappy::package
  }

  Hdp::Package<|title == 'hadoop 32'|> ->   Hdp::Package<|title == 'hbase'|>
  Hdp::Package<|title == 'hadoop 64'|> ->   Hdp::Package<|title == 'hbase'|>

  #TODO: just for testing
  class{ 'hdp::iptables': 
    ensure => stopped,
  }

}

class hdp::set_hdp_yum_repo()
{
  $repo_target = "/etc/yum.repos.d/${hdp::params::hdp_yum_repo}"
  hdp::configfile { $repo_target:
    component => 'base',
    owner     => 'root',
    group     => 'root'
  }
}

class hdp::create_smoke_user()
{
  $smoke_group = $hdp::params::smoke_user_group
  $smoke_user = $hdp::params::smokeuser

  group { $smoke_group :
    ensure => present
  }

  hdp::user { $smoke_user:}

  $cmd = "usermod -g  $smoke_group  $smoke_user"
  $check_group_cmd = "id -gn $smoke_user | grep $smoke_group"
  hdp::exec{ $cmd:
     command => $cmd,
     unless => $check_group_cmd
  }
 
  Group[$smoke_group] -> Hdp::User[$smoke_user] -> Hdp::Exec[$cmd] 
}


class hdp::set_selinux()
{
 $cmd = "/bin/echo 0 > /selinux/enforce"
 hdp::exec{ $cmd:
    command => $cmd,
    unless => "head -n 1 /selinux/enforce | grep ^0$"
  }
}

class hdp::package::epel_rpm()
{
 $epel_url = $hdp::params::epel_url
 $epel_package = regsubst($epel_url,'^.+/(.+)\.noarch\.rpm','\1')
 $cmd = "rpm -Uvh ${epel_url}"
 hdp::exec{ $cmd:
    command => $cmd,
    unless => "rpm -qa | grep $epel_package"
  }
}
  
define hdp::user(
  $gid = $hdp::params::hadoop_user_group,
  $just_validate = undef
)
{
  $user_info = $hdp::params::user_info[$name]
  if ($just_validate != undef) {
    $just_val  = $just_validate
  } elsif (($user_info == undef) or ("|${user_info}|" == '||')){ #tests for different versions of Puppet
    $just_val = false
  } else {
    $just_val = $user_info[just_validate]
  }
  
  if ($just_val == true) {
    exec { "user ${name} exists":
      command => "su - ${name} -c 'ls /dev/null' >/dev/null 2>&1",
      path    => ['/bin']
    }
  } else {
    user { $name:
      ensure     => present,
      managehome => true,
      #gid        => $gid, #TODO either remove this to support LDAP env or fix it
      shell      => '/bin/bash'
    }
  }
}
     
define hdp::directory(
  $owner = $hdp::params::hadoop_user,
  $group = $hdp::params::hadoop_user_group,
  $mode  = undef
  )
{
  file { $name :
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => $mode
  }
}
#TODO: check on -R flag and use of recurse
define hdp::directory_recursive_create(
  $owner = $hdp::params::hadoop_user,
  $group = $hdp::params::hadoop_user_group,
  $mode = undef,
  $context_tag = undef
  )
{
  hdp::exec {"mkdir -p ${name}" :
    command => "mkdir -p ${name}",
    creates => $name
  }
  #to take care of setting ownership and mode
  hdp::directory { $name :
    owner => $owner,
    group => $group,
    mode  => $mode
  }
  Hdp::Exec["mkdir -p ${name}"] -> Hdp::Directory[$name]
}

### helper to do exec
define hdp::exec(
  $command,
  $refreshonly = undef,
  $unless = undef,
  $path = $hdp::params::exec_path,
  $user = undef,
  $creates = undef,
  $tries = 1,
  $timeout = undef,
  $try_sleep = undef,
  $initial_wait = undef,
  $logoutput = undef,
  $cwd = undef
)
{
     
  if (($initial_wait != undef) and ($initial_wait != "undef")) {
    #passing in creates and unless so dont have to wait if condition has been acheived already
    hdp::wait { "service ${name}" : 
      wait_time => $initial_wait,
      creates   => $creates,
      unless    => $unless,
      path      => $path
    }
  }
  
  exec { $name :
    command     => $command,
    refreshonly => $refreshonly,
    path        => $path,
    user        => $user,
    creates     => $creates,
    unless      => $unless,
    tries       => $tries,
    timeout     => $timeout,
    try_sleep   => $try_sleep,
    logoutput   => $logoutput,
    cwd         => $cwd
  }
  
  anchor{ "hdp::exec::${name}::begin":} -> Exec[$name] -> anchor{ "hdp::exec::${name}::end":} 
  if (($initial_wait != undef) and ($initial_wait != "undef")) {
    Anchor["hdp::exec::${name}::begin"] -> Hdp::Wait["service ${name}"] -> Exec[$name]
  }
}

#### utilities for waits
define hdp::wait(
  $wait_time,
  $creates = undef,
  $unless = undef,
  $path = undef #used for unless
)   
{
  exec { "wait ${name} ${wait_time}" :
    command => "/bin/sleep ${wait_time}",
    creates => $creates,
    unless  => $unless,
    path    => $path
  } 
}

#### artifact_dir
define hdp::artifact_dir()
{
  include artifact_dir_shared
}
class artifact_dir_shared()
{
  file{ $hdp::params::artifact_dir:
    ensure  => directory
  }
}

##### temp

class hdp::iptables($ensure)
{
  #TODO: just temp so not considering things like saving firewall rules
  service { 'iptables':
    ensure => $ensure
  }
}
