if node["reldev"] == "devel"
  reldev = :dev
elsif node["reldev"] == "release"
  reldev = :rel
else
  raise "are the bbs_devel and bbs_release roles defined?"
end

bioc_version = node['bioc_version'][reldev]
r_version = node['r_version'][reldev]

execute "set time zone" do
  command "systemsetup -settimezone #{node['time_zone']}"
  not_if "systemsetup -gettimezone|grep -q #{node['time_zone']}"
end

execute "set host name" do
  command "hostname -s #{node['desired_hostname'][reldev]}"
  not_if "hostname | grep -q #{node['desired_hostname'][reldev]}"
end

user "biocbuild" do
    supports :manage_home => true
    home "/Users/biocbuild"
    shell "/bin/bash"
    action :create
end

execute "make biocbuild an admin" do
  command "dseditgroup -o edit -a biocbuild -t user admin"
  not_if "id biocbuild|grep -q '\(admin\)'"
end

control_group 'biocbuild' do
  control 'biocbuild user' do
    describe command("dscl . -ls /Users") do
      its(:stdout) { should match /biocbuild/}
    end
    it 'should exist' do
      expect(file('/Users/biocbuild')).to exist
      expect(file('/Users/biocbuild')).to be_directory
      expect(file('/Users/biocbuild')).to be_owned_by('biocbuild')
    end
  end
end

bbsdir = "/Users/biocbuild/bbs-#{node['bioc_version'][reldev]}-bioc"

directory bbsdir do
    owner "biocbuild"
    mode "0755"
    action :create
end

control_group "bbsdir group" do
  control bbsdir do
    it 'should exist' do
      expect(file(bbsdir)).to exist
      expect(file(bbsdir)).to be_directory
      expect(file(bbsdir)).to be_owned_by('biocbuild')
    end
  end
end

directory "/Users/biocbuild/.ssh" do
    owner "biocbuild"
    mode "0755"
    action :create
end

directory "/Users/biocbuild/.BBS" do
    owner "biocbuild"
    mode "0755"
    action :create
end

%w(log NodeInfo svninfo meat STAGE2_tmp).each do |dir|
    directory "#{bbsdir}/#{dir}" do
        owner "biocbuild"
        mode "0755"
        action :create
    end
end

# data experiment
dataexpdir = bbsdir.sub(/bioc$/, "data-experiment")

directory dataexpdir do
  action :create
  owner "biocbuild"
end

%w(log NodeInfo svninfo meat STAGE2_tmp).each do |dir|
    directory "#{dataexpdir}/#{dir}" do
        owner "biocbuild"
        mode "0755"
        action :create
    end
end


base_url = "https://hedgehog.fhcrc.org/bioconductor"
base_data_url = "https://hedgehog.fhcrc.org/bioc-data"
if reldev == :dev
    branch = 'trunk'
else
    branch = "branches/RELEASE_#{node['bioc_version'][reldev].sub(".", "_")}"
end

svn_meat_url = "#{base_url}/#{branch}/madman/Rpacks"

dataexp_meat_url = "#{base_data_url}/#{branch}/experiment/pkgs"

easy_install_package "pip"

execute "install jupyter" do
  command "pip install jupyter"
  not_if "which jupyter | grep -q jupyter"
end

execute "install ipython" do
  command "pip install ipython==4.1.2"
  not_if "pip freeze | grep -q ipython"
end

execute "install nbconvert" do
  command "pip install nbconvert==4.1.0"
  not_if "pip freeze | grep -q nbconvert"
end

argtable_tarball = node['argtable_url'].split('/').last
argtable_dir = argtable_tarball.sub(".tar.gz", "")

remote_file "/tmp/#{argtable_tarball}" do
  source node['argtable_url']
end

execute "build argtable" do
  command "tar zxf #{argtable_tarball.split('/').last} && cd #{argtable_dir} && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{argtable_dir}/config.log"}
end

clustalo_tarball = node['clustalo_url'].split('/').last
clustalo_dir = clustalo_tarball.sub(".tar.gz", "")

remote_file "/tmp/#{clustalo_tarball}" do
  source node['clustalo_url']
end

execute "build clustalo" do
  command "tar zxf #{clustalo_tarball} && cd #{clustalo_dir} && ./configure && make && make install"
  not_if "which clustalo | grep -q clustalo"
  cwd "/tmp"
end

#require 'dmg'
include_recipe 'dmg'

dmg_package "Xquartz" do
  source node['xquartz_url']
  volumes_dir node['xquartz_name']
  type 'pkg'
  not_if {File.exists? "/Applications/Utilities/XQuartz.app"}
end

# package node['mactex_url']

remote_file "/tmp/#{node['mactex_url'].split('/').last}" do
  source node['mactex_url']
  #checksum node['mactex_checksum']
  use_conditional_get true
  use_etag true
  use_last_modified true
  # why is the not_if necessary?
  not_if {File.exists? "/tmp/#{node['mactex_url'].split('/').last}"}
end

execute "install MacTex" do
  command "sudo installer -pkg /tmp/#{node['mactex_url'].split('/').last} -target /"
  not_if {File.exists? "/usr/texbin/pdflatex"}
end

git "/Users/biocbuild/BBS" do
  repository node['bbs_repos']
  revision node['bbs_branch']
  user 'biocbuild'
end

execute "build chown-rootadmin" do
  cwd "/Users/biocbuild/BBS/utils"
  command "gcc chown-rootadmin.c -o chown-rootadmin &&  chown root:admin chown-rootadmin && sudo chmod 4750 chown-rootadmin"
  not_if {File.exists? "/Users/biocbuild/BBS/utils/chown-rootadmin"}
end

remote_file "/tmp/#{node['r_url'][reldev].split('/').last}" do
    source node['r_url'][reldev]
    not_if {File.exists? "/tmp/#{node['r_url'][reldev].split('/').last}"}
end

execute "install R" do
    command "installer -pkg /tmp/#{node['r_url'][reldev].split('/').last} -target /"
    not_if {File.exists? "/Library/Frameworks/R.framework"}
end

execute "modify flags" do
  user "biocbuild"
  cwd "/Library/Frameworks/R.framework/Versions/Current/Resources/etc"
  command "/Users/biocbuild/BBS/utils/mavericks-R-fix-flags.sh"
  not_if {File.exists? "/Library/Frameworks/R.framework/Versions/Current/Resources/etc/Makeconf.original"}
end

execute "install Bioconductor" do
  user "biocbuild"
  command %Q(echo 'source("https://bioconductor.org/biocLite.R")' | R -q --slave)
  not_if {File.exists? "/Library/Frameworks/R.framework/Versions/Current/Resources/library/BiocInstaller"}
end


if reldev == :dev
  execute "useDevel" do
    user "biocbuild"
    command %Q(echo "BiocInstaller::useDevel()" | R -q --slave )
    not_if %Q(echo "cat(as.character(BiocInstaller:::BIOC_VERSION))"|R -q --slave | grep -q #{node['bioc_version'][reldev]})
  end
end



__END__







directory "#{bbsdir}/rbuild" do
  action :create
  owner 'biocbuild'
end

remote_file "#{bbsdir}/rbuild/#{node['r_url'][reldev].split("/").last}" do
  source node['r_url'][reldev]
  owner 'biocbuild'
end

execute "untar R" do
  command "tar zxf #{bbsdir}/rbuild/#{node['r_url'][reldev].split("/").last}"
  user 'biocbuild'
  cwd "#{bbsdir}/rbuild"
  not_if {File.exists? "#{bbsdir}/rbuild/#{node['r_src_dir'][reldev]}"}
end


execute "build R" do
  command "#{bbsdir}/rbuild/#{node['r_src_dir'][reldev]}/configure --enable-R-shlib && make -j"
  user 'biocbuild'
  cwd "#{bbsdir}/R"
  not_if {File.exists? "#{bbsdir}/R/Makefile"}
end

execute "set R flags" do
  command "/home/biocbuild/BBS/utils/R-fix-flags.sh"
  user "biocbuild"
  cwd "#{bbsdir}/R/etc"
  not_if {File.exists? "#{bbsdir}/R/etc/Makeconf.original"}
end

execute "set up arp alias" do
  command %Q(echo 'alias arp="export PATH=$PATH:$HOME/bbs-#{node['bioc_version'][reldev]}-bioc/R/bin"' >> /home/biocbuild/.bash_profile)
  cwd "/home/biocbuild"
  user "biocbuild"
  not_if "grep -q arp /home/biocbuild/.bash_profile"
end

execute "install BiocInstaller" do
  command %Q(#{bbsdir}/R/bin/R -e "source('https://bioconductor.org/biocLite.R')")
  user "biocbuild"
  not_if {File.exists? "#{bbsdir}/R/library/BiocInstaller"}
end

if reldev == :dev
  execute "run useDevel()" do
    command %Q(#{bbsdir}/R/bin/R -e "BiocInstaller::useDevel()")
    user "biocbuild"
    not_if %Q(#{bbsdir}/R/bin/R --slave -q -e "BiocInstaller:::IS_USER" | grep -q FALSE)
  end
end

link "/var/www/html/BBS" do
    to "/home/biocbuild/public_html/BBS"
end


link "/usr/bin/aclocal-1.14" do
  to "/usr/bin/aclocal-1.15"
end

# biocadmin

user "biocadmin" do
    supports :manage_home => true
    home "/home/biocadmin"
    shell "/bin/bash"
    action :create
end


%W(bin InstalledPkgs tmp rbuild
PACKAGES/#{bioc_version}
PACKAGES/#{bioc_version}/biocViews
PACKAGES/#{bioc_version}/bioc
PACKAGES/#{bioc_version}/bioc/src/contrib
PACKAGES/#{bioc_version}/bioc/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/bioc/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/bioc/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment
PACKAGES/#{bioc_version}/data/experiment/src/contrib
PACKAGES/#{bioc_version}/data/experiment/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation
PACKAGES/#{bioc_version}/data/annotation/src/contrib
PACKAGES/#{bioc_version}/data/annotation/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra
PACKAGES/#{bioc_version}/extra/src/contrib
PACKAGES/#{bioc_version}/extra/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra/bin/macosx/mavericks/contrib/#{r_version}
cron.log/#{bioc_version}
).each do |dir|
  directory "/home/biocadmin/#{dir}" do
    owner "biocadmin"
    action :create
    recursive true
  end
end

%W(BiocInstaller biocViews DynDoc graph).each do |pkg|
  directory "/home/biocadmin/InstalledPkgs/#{pkg}" do
    action :create
    owner 'biocadmin'
  end
  subversion "/home/biocadmin/InstalledPkgs/#{pkg}" do
    user "biocadmin"
    svn_username "readonly"
    svn_password "readonly"
    repository "https://hedgehog.fhcrc.org/bioconductor/trunk/madman/Rpacks/#{pkg}"
    action :sync
  end
end

git "/home/biocadmin/BBS" do
  user "biocadmin"
  repository node['bbs_repos']
  revision node['bbs_branch']
end

link "/home/biocadmin/manage-BioC-repos"  do
  to "/home/biocadmin/BBS/manage-BioC-repos"
  owner "biocadmin"
end

%W(bioc data/annotation data/experiment extra).each do |dir|
  link "/home/biocadmin/PACKAGES/#{bioc_version}/#{dir}/bin/windows64" do
    to "/home/biocadmin/PACKAGES/#{bioc_version}/#{dir}/bin/windows"
    owner "biocadmin"
  end
end

# install R
# install knitcitations
# install all pkgs in ~/InstalledPkgs




remote_file "/home/biocadmin/rbuild/#{node['r_url'][reldev].split("/").last}" do
  source node['r_url'][reldev]
  owner 'biocadmin'
end

execute "untar R" do
  command "tar zxf /home/biocadmin/rbuild/#{node['r_url'][reldev].split("/").last} && mv #{node['r_src_dir'][reldev]} /home/biocadmin/R-#{r_version}"
  user 'biocadmin'
  cwd "/home/biocadmin/rbuild"
  not_if {File.exists? "/home/biocadmin/R-#{r_version}"}
end



execute "build R" do
  command "./configure --enable-R-shlib && make -j"
  user 'biocadmin'
  cwd "/home/biocadmin/R-#{r_version}/"
  not_if {File.exists? "/home/biocadmin/R-#{r_version}/config.log"}
end

# should really install these from ~/InstalledPkgs but this is easier.
execute "install pkgs needed by biocadmin" do
  user 'biocadmin'
  command %Q(/home/biocadmin/R-#{r_version}/bin/R -e "source('https://bioconductor.org/biocLite.R');biocLite(c('biocViews','DynDoc','graph','knitcitations'))")
  not_if {File.exists? "/home/biocadmin/R-#{r_version}/library/knitcitations"}
end

link "/home/biocadmin/bin/R-#{r_version}" do
  owner 'biocadmin'
  to "/home/biocadmin/R-#{r_version}/bin/R"
end


# ROOT

remote_file "/tmp/#{node['root_url'][reldev].split("/").last}" do
  source node['root_url'][reldev]
end

directory "/tmp/rootbuild" do
  action :create
end

execute "build root" do
  cwd "/tmp/rootbuild"
  command "tar zxf /tmp/#{node['root_url'][reldev].split("/").last} && cd root && ./configure --prefix=/usr/local/root && make && make install"
  not_if {File.exists? "/tmp/rootbuild/root"}
end


file "/etc/ld.so.conf.d/ROOT.conf" do
  content "/usr/local/root/lib/root"
end

execute "ldconfig" do
  command "ldconfig"
end

execute "add root to path" do
  command "echo 'export PATH=$PATH:/usr/local/root/bin' >> /etc/profile"
  not_if "grep -q /usr/local/root/bin /etc/profile"
end

execute "add rootsys" do
  command "echo 'export ROOTSYS=/usr/local/root' >> /etc/profile"
  not_if "grep -q ROOTSYS /etc/profile"
end

# jags

remote_file "/tmp/#{node['jags_url'][reldev].split('/').last}" do
  source node['jags_url'][reldev]
end

execute "build jags" do
  command "tar zxf #{node['jags_url'][reldev].split('/').last} && cd #{node['jags_dir'][reldev]} && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['jags_dir'][reldev]}/config.log"}
end

# libsbml

remote_file "/tmp/#{node['libsbml_url'].split('/').last}" do
  source node['libsbml_url']
end

execute "build libsbml" do
  command "tar zxf #{node['libsbml_url'].split('/').last} && cd #{node['libsbml_dir']} && ./configure --enable-layout && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['libsbml_dir']}/config.log"}
end

# Vienna RNA

remote_file "/tmp/#{node['vienna_rna_dir']}.tar.gz" do
  source node["vienna_rna_url"]
end

# commenting this out now as it fails to build.
# however, it seems like this is not needed at the moment because
# the RNAfold program is not actually called in an evaluted
# vignette chunk/example/test in GeneGA

# execute "build ViennaRNA" do
#   command "tar zxf #{node['vienna_rna_dir']}.tar.gz && cd #{node['vienna_rna_dir']}/ && ./configure && make && make install"
#   cwd "/tmp"
#   not_if {File.exists? "/tmp/#{node['vienna_rna_dir']}/config.log"}
# end

# ensemblVEP

remote_file "/tmp/#{node['vep_dir'][reldev]}.zip" do
  source node['vep_url'][reldev]
end

execute "install VEP" do
  command "unzip #{node['vep_dir'][reldev]} && cd #{node['vep_dir'][reldev]}/scripts && mv variant_effect_predictor /usr/local/ && cd /usr/local/variant_effect_predictor && perl INSTALL.pl --NO_HTSLIB -a a"
  cwd "/tmp"
  not_if {File.exists? "/usr/local/variant_effect_predictor"}
end

# add /usr/local/variant_effect_predictor to path

execute "add vep to path" do
  command "echo 'export PATH=$PATH:/usr/local/variant_effect_predictor' >> /etc/profile"
  not_if "grep -q variant_effect_predictor /etc/profile"
end

# TODO s:
# cron - pointer in crontab to crond
# ssh keys
# latex - enablewrite18 and changes below
# rgtk2? gtkmm?
# in encrypted data bags:
#  isr_login
#  google login
#  etc
# the above go in cron envs as well


# latex settings

file "/etc/texmf/texmf.d/01bioc.cnf" do
    content "shell_escape=t"
    owner "root"
    group "root"
    mode "0644"
end

execute "update-texmf" do
    action :run
    user "root"
    command "update-texmf"
end

# get stuff from encrypted data bags

directory "/home/biocbuild/.BBS" do
  owner "biocbuild"
  action :create
end

file "/home/biocbuild/.BBS/id_rsa" do
  owner "biocbuild"
  mode "0400"
  content Chef::EncryptedDataBagItem.load('BBS',
    'incoming_private_key')['value']
end

execute "add public key to authorized_keys" do
  user "biocbuild"
  command "echo #{Chef::EncryptedDataBagItem.load('BBS',
    'incoming_public_key')['value']} >> /home/biocbuild/.ssh/authorized_keys"
  not_if %Q(grep -q "#{Chef::EncryptedDataBagItem.load('BBS',
    'incoming_public_key')['value']}" /home/biocbuild/.ssh/authorized_keys)
end

execute "add google api key to /etc/profile" do
  user "root"
  command %Q(echo "export GOOGLE_API_KEY=#{Chef::EncryptedDataBagItem.load('BBS',
    'google_api_key')['value']}" >> /etc/profile)
  not_if %Q(grep -q GOOGLE_API_KEY /etc/profile)
end

execute "add ISR_login to /etc/profile" do
  user "root"
  command %Q(echo "export ISR_login=#{Chef::EncryptedDataBagItem.load('BBS',
    'isr_credentials')['username']}" >> /etc/profile)
  not_if %Q(grep -q ISR_login /etc/profile)
end

execute "add ISR_pwd to /etc/profile" do
  user "root"
  command %Q(echo "export ISR_pwd=#{Chef::EncryptedDataBagItem.load('BBS',
    'isr_credentials')['password']}" >> /etc/profile)
  not_if %Q(grep -q ISR_pwd /etc/profile)
end

file "/home/biocbuild/.ssh/id_rsa" do
  owner "biocbuild"
  mode "0400"
  content Chef::EncryptedDataBagItem.load('BBS',
    'outgoing_private_key')['value']
end

# FIXME more stuff that needs to be in data bags:
# * github oauth token for codecov
# * codecov token
# * aws credentials for archiving build reports to s3


# set up cron.d entries for biocbuild

# first, indicate in crontab to look elsewhere:
execute "tell viewers of crontab to look in /etc/cron.d" do
  command %Q(echo "# scheduled tasks are defined in /etc/cron.d, not here" | crontab -)
  user "biocbuild"
  not_if %Q(crontab -l |grep -q "# scheduled tasks are defined in /etc/cron.d")
end

# cron_d "pre-build-script" do
#
# end



# FIXME - set up pkgbuild stuff if this is a devel builder
# github_chef_key (from data bag)



%w(ack-grep libnetcdf-dev libhdf5-serial-dev sqlite libfftw3-dev libfftw3-doc
    libopenbabel-dev fftw3 fftw3-dev pkg-config xfonts-100dpi xfonts-75dpi
    libopenmpi-dev openmpi-bin mpi-default-bin openmpi-common
    libexempi3 openmpi-doc texlive-science python-mpi4py
    texlive-bibtex-extra texlive-fonts-extra fortran77-compiler gfortran
    libreadline-dev libx11-dev libxt-dev texinfo apache2 libxml2-dev
    libcurl4-openssl-dev libcurl4-nss-dev xvfb  libpng12-dev
    libjpeg62-dev libcairo2-dev libcurl4-gnutls-dev libtiff5-dev
    tcl8.5-dev tk8.5-dev libicu-dev libgsl2 libgsl0-dev
    libgtk2.0-dev gcj-4.8 openjdk-8-jdk texlive-latex-extra
    texlive-fonts-recommended pandoc libgl1-mesa-dev libglu1-mesa-dev
    htop libgmp3-dev imagemagick unzip libhdf5-dev libncurses-dev libbz2-dev
    libxpm-dev liblapack-dev libv8-3.14-dev libperl-dev
    libarchive-extract-perl libfile-copy-recursive-perl libcgi-pm-perl tabix
    libdbi-perl libdbd-mysql-perl ggobi libgtkmm-2.4-dev libssl-dev byacc
    automake libmysqlclient-dev postgresql-server-dev-all pandoc-citeproc
    firefox graphviz python-pip libxml-simple-perl
).each do |pkg|
    package pkg do
        action :install
    end
end

package 'libnetcdf-dev'
