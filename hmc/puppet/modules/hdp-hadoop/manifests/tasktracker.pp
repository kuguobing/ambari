class hdp-hadoop::tasktracker(
  $service_state = $hdp::params::cluster_service_state,
  $opts = {}
) inherits hdp-hadoop::params
{
  $hdp::params::service_exists['hdp-hadoop::tasktracker'] = true

  Hdp-hadoop::Common<||>{service_states +> $service_state}

  if ($hdp::params::use_32_bits_on_slaves == true) {
    Hdp-hadoop::Package<||>{include_32_bit => true}
    Hdp-hadoop::Configfile<||>{sizes +> 32}
  } else {
    Hdp-hadoop::Package<||>{include_64_bit => true}
    Hdp-hadoop::Configfile<||>{sizes +> 64}
  }

  if ($service_state == 'no_op') {
  } elsif ($service_state in ['running','stopped','installed_and_configured','uninstalled']) { 
    $mapred_local_dir = $hdp-hadoop::params::mapred_local_dir
  
    #adds package, users and directories, and common hadoop configs
    include hdp-hadoop::initialize
  
    hdp-hadoop::tasktracker::create_local_dirs { $mapred_local_dir: 
      service_state => $service_state
    }
    
    if ($hdp::params::service_exists['hdp-hadoop::jobtracker'] == true) {
      $create_pid_dir = false
      $create_log_dir = false
    } else {
      $create_pid_dir = true
      $create_log_dir = true
    }

    hdp-hadoop::service{ 'tasktracker':
      ensure => $service_state,
      user   => $hdp-hadoop::params::mapred_user,
      create_pid_dir => $create_pid_dir,
      create_log_dir => $create_log_dir
    }
  
    #top level does not need anchors
    Class['hdp-hadoop'] -> Hdp-hadoop::Service['tasktracker']
    Hdp-hadoop::Tasktracker::Create_local_dirs<||> -> Hdp-hadoop::Service['tasktracker']
  } else {
    hdp_fail("TODO not implemented yet: service_state = ${service_state}")
  }
}

define hdp-hadoop::tasktracker::create_local_dirs($service_state)
{
  if (($hdp::params::service_exists['hdp-hadoop::jobtracker'] != true) and ($service_state != 'uninstalled')) {
    $dirs = hdp_array_from_comma_list($name)    
    hdp::directory_recursive_create { $dirs :
      owner => $hdp-hadoop::params::mapred_user,
      mode => '0755'
    }
  }
}
