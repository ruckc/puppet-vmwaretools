class puppetmaster {
  $passenger_loglevel=hiera('passenger_loglevel',0)

  include httpd

  package{'puppet-server':
    ensure=>latest,
    notify=>Service['httpd'],
  } ->

  augeas{'setup puppet master puppet.conf':
    context=>'/files/etc/puppet/puppet.conf',
    notify =>Service['httpd'],
    changes=>[
      'set master/ssl_client_header SSL_CLIENT_S_DN',
      'set master/ssl_client_verify_header SSL_CLIENT_VERIFY',
      'set main/confdir /etc/puppet',
      'set main/rundir /var/run/puppet',
      'set main/vardir /var/lib/puppet',
      'set main/ssldir /var/lib/puppet/ssl',
      'set master/pluginsync true',
    ],
  }

  file{'/usr/share/selinux/targeted/puppet-master.pp':
    ensure=>present,
    owner =>root,
    group =>root,
    mode  =>'0440',
    source=>'puppet:///modules/puppetmaster/puppet-master.pp',
    notify=>Selmodule['puppet-master'],
  } ->

  selmodule{'puppet-master':
    ensure     =>present,
    syncversion=>true,
  }

  selboolean{'httpd_setrlimit':
    value     =>on,
    persistent=>true,
    notify    =>Service['httpd'],
  }

  file{['/usr/share/puppet-master','/usr/share/puppet-master/public']:
    ensure    =>directory,
    owner     =>root,
    group     =>apache,
    mode      =>'0555',
    purge     =>true,
    recurse   =>true,
    force     =>true,
    notify    =>Service['httpd'],
  }

  file{['/usr/share/puppet-master/config.ru']:
    ensure =>file,
    owner  =>puppet,
    group  =>apache,
    mode   =>'0750',
    notify =>Service['httpd'],
    content=>template('puppetmaster/config.ru.erb'),
  }

  httpd::conf{'puppet-master':
    content=>template('puppetmaster/puppet-master.conf.erb'),
  }
}
# su - puppet -s /bin/bash -c "puppet master
# --no-daemonize --verbose --confdir /etc/puppet"
