class vmwaretools {
  if $::operatingsystem == 'RedHat' {
    $ver = regsubst($::operatingsystemrelease,'(\d).(\d)','\1')
    $repo="rhel${ver}"
  }

  file{'/etc/pki/rpm-gpg/RPM-GPG-KEY-vmware-tools-dag':
    ensure=>file,
    source=>'puppet:///modules/vmwaretools/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
    owner =>root,
    group =>root,
    mode  =>'0644',
  } ->

  yumrepo {'vmware-tools':
    descr   =>'VMWare Tools RPMs',
    baseurl =>"http://packages.vmware.com/tools/esx/latest/${repo}/${::architecture}/",
    gpgkey  =>'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-vmware-tools-dag',
    enabled =>1,
    gpgcheck=>1,
  } ->

  package {['vmware-tools-esx-nox','vmware-tools-vmsync-common']:
    ensure=>latest,
  } ->

  service {['vmware-tools-services',]:
    ensure    =>running,
    enable    =>true,
    hasrestart=>true,
    hasstatus =>true,
    restart   =>'/sbin/initctl restart vmware-tools-services',
    start     =>'/sbin/initctl start vmware-tools-services',
    stop      =>'/sbin/initctl stop vmware-tools-services',
    status    =>'/sbin/initctl status vmware-tools-services |grep "/running" 1>/dev/null 2>&1',
    provider  =>base,
  }
}
