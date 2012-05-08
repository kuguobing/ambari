class hdp-oozie::service(
  $ensure,
  $setup,
  $initial_wait = undef
)
{
  include $hdp-oozie::params
  
  $user = "$hdp-oozie::params::oozie_user"
  $hadoop_home = $hdp-oozie::params::hadoop_prefix
  $oozie_tmp = $hdp-oozie::params::oozie_tmp_dir
  $cmd = "env HADOOP_HOME=${hadoop_home} /usr/sbin/oozie_server.sh"
  $pid_file = "${hdp-oozie::params::oozie_pid_dir}/oozie.pid" 
  $jar_location = $hdp::params::hadoop_jar_location
  $ext_js_path = "/tmp/HDP-artifacts/${hdp-oozie::params::ext_zip_name}"

  if ($ensure == 'running') {
    $daemon_cmd = "su - ${user} -c  'cd ${oozie_tmp} ; /usr/lib/oozie/bin/oozie-setup.sh -hadoop 0.20.200 $jar_location -extjs $ext_js_path; /usr/lib/oozie/bin/oozie-start.sh'"
    $no_op_test = "ls ${pid_file} >/dev/null 2>&1 && ps `cat ${pid_file}` >/dev/null 2>&1"
  } elsif ($ensure == 'stopped') {
    $daemon_cmd  = "su - ${user} -c  'cd ${oozie_tmp} ; /usr/lib/oozie/bin/oozie-stop.sh'"
    $no_op_test = undef
  } else {
    $daemon_cmd = undef
  }

  hdp-oozie::service::directory { $hdp-oozie::params::oozie_pid_dir : }
  hdp-oozie::service::directory { $hdp-oozie::params::oozie_log_dir : }
  hdp-oozie::service::directory { $hdp-oozie::params::oozie_tmp_dir : }
  hdp-oozie::service::directory { $hdp-oozie::params::oozie_data_dir : }
  hdp-oozie::service::directory { $hdp-oozie::params::oozie_lib_dir : }
  hdp-oozie::service::createsymlinks { '/usr/lib/oozie/oozie-server/lib/mapred-site.xml' : }

  anchor{'hdp-oozie::service::begin':} -> Hdp-oozie::Service::Directory<||> -> anchor{'hdp-oozie::service::end':}
  
  if ($daemon_cmd != undef) {
    hdp::exec { $daemon_cmd:
      command => $daemon_cmd,
      unless  => $no_op_test,
      initial_wait => $initial_wait
    }
    Hdp-oozie::Service::Directory<||> -> Hdp::Exec[$daemon_cmd] -> Anchor['hdp-oozie::service::end']
  }
}

define hdp-oozie::service::directory()
{
  hdp::directory_recursive_create { $name: 
    owner => $hdp-oozie::params::oozie_user,
    mode => '0755'
  }
}
define hdp-oozie::service::createsymlinks()
{
  file { '/usr/lib/oozie/oozie-server/lib/mapred-site.xml':
    ensure => present,
    target => "/etc/hadoop/conf/mapred-site.xml",
    mode => '0755'
  }
}
