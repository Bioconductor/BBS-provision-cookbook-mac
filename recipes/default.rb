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

execute "install BiocInstaller" do
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


autoconf_tarball = node['autoconf_url'].split('/').last
autoconf_dir = autoconf_tarball.sub(".tar.gz", "")

remote_file "/tmp/#{autoconf_tarball}" do
  source node['autoconf_url']
end

execute "install autoconf" do
  command "tar zxf #{autoconf_tarball} && cd #{autoconf_dir} && ./configure && make && make install"
  cwd "/tmp"
  not_if "which autoconf | grep -q autoconf"
end

automake_tarball = node['automake_url'].split('/').last
automake_dir = automake_tarball.sub(".tar.gz", "")

remote_file "/tmp/#{automake_tarball}" do
  source node['automake_url']
end

execute "install automake" do
  command "tar zxf #{automake_tarball} && cd #{automake_dir} && ./configure && make && make install"
  cwd "/tmp"
  not_if "which automake | grep -q automake"
end


remote_file "/tmp/#{node['root_url'][reldev].split("/").last}" do
  source node['root_url'][reldev]
end

execute "install ROOT" do
  command "tar zxf /tmp/#{node['root_url'][reldev].split('/').last} -C /usr/local/"
  not_if {File.exists? "/usr/local/root"}
end

execute "add root to path" do
  command %Q(echo 'export PATH=\$PATH:/usr/local/root/bin' >> /etc/profile)
  not_if "grep -q /usr/local/root/bin /etc/profile"
end

execute "add rootsys" do
  command %Q(echo "export ROOTSYS=/usr/local/root" >> /etc/profile)
  not_if "grep -q ROOTSYS /etc/profile"

end

execute "add root to dyld_library_path" do
  command %Q(echo 'export DYLD_LIBRARY_PATH=\$DYLD_LIBRARY_PATH:\$ROOTSYS/lib' >> /etc/profile)
  not_if "grep -q DYLD_LIBRARY_PATH /etc/profile" # FIXME refine this a bit?
end

execute "add root to ld_library_path" do
  command %Q(echo 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$ROOTSYS/lib' >> /etc/profile)
  not_if "grep LD_LIBRARY_PATH /etc/profile| grep -qv DYLD" # FIXME refine this a bit?
end

link "/etc/root" do
  to '/usr/local/root/etc'
end


dmg_package node['jags_dir'] do
  source node['jags_url']
  volumes_dir node['jags_dir']
  type 'mpkg'
  dmg_name node['jags_dir']
  not_if {File.exists? "/usr/local/bin/jags"}
end


# FIXME don't install libsbml until we have sorted things out so rsbml builds


dmg_package node['libsbml_packagename'] do
  source node['libsbml_url']
  volumes_dir node['libsbml_dir']
  type 'pkg'
  dmg_name node['libsbml_packagename']
  not_if {File.exists? "/usr/local/include/sbml"}
end

execute "add libsbml.pc to PKG_CONFIG_PATH" do
  command "echo 'export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig' >> /etc/profile"
  not_if "grep -q /usr/local/lib/pkgconfig /etc/profile"
end

execute "tweak libsbml dylib" do
  cwd "/usr/local/lib"
  command %Q(install_name_tool -id "/usr/local/lib/libsbml.5.dylib" libsbml.5.dylib)
  # FIXME - this execute seems to be skipped mistakenly due to not_if even when grep returns 0
  # does not seem to hurt (or take long) to do this repeatedly...
  #not_if "otool -D /usr/local/lib/libsbml.5.dylib|grep -q /usr/local/lib"
end


for simon_tar in node['simon_tars']
  tarball, guardfile = simon_tar
  remote_file "/tmp/#{tarball}" do
    source "http://r.research.att.com/libs/#{tarball}"
  end
  execute "install #{tarball}" do
    command "tar zxf /tmp/#{tarball} -C /"
    not_if {File.exists? guardfile}
  end
end


remote_file "/tmp/#{node['gtk_url'].split('/').last}" do
  source node['gtk_url']
end

execute "install gtk" do
  command "installer -pkg /tmp/#{node['gtk_url'].split('/').last} -target /"
   not_if {File.exists? "/Library/Frameworks/GTK+.framework"}
end


execute "add GTK to PKG_CONFIG_PATH" do
  command %Q(echo 'export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:#{node['gtk_pkgconfig_dir']}' >> /etc/profile)
  not_if "grep -q #{node['gtk_pkgconfig_dir']} /etc/profile"
end

# FIXME latest Cairo (R package) binary
# FIXME cairo-1.12.16-darwin13-static-pkgconfig.patch
# FIXME http://r.research.att.com/libs/GTK_2.24.17-X11.pkg

# FIXME protobuf

# FIXME R_TEXI2DVICMD=/Users/biocbuild/BBS/utils/mactexi2dvi

# FIXME - gfortran

# FIXME - rsbml still does not build. contact mtr
# FIXME - see BBS/Docs about necessary tweaks to libsbml.dylib, and other stuff you need to do

# FIXME - come back to Vienna RNA later


# Vienna RNA

remote_file "/tmp/#{node['vienna_rna_dir']}.tar.gz" do
  source node["vienna_rna_url"]
end

execute "build ViennaRNA" do
  command "tar zxf #{node['vienna_rna_dir']}.tar.gz && cd #{node['vienna_rna_dir']}/ && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['vienna_rna_dir']}/config.log"}
end

# mysql


dmg_package node['mysql_volume_dir'] do
  source node['mysql_url']
  volumes_dir node['mysql_volume_dir']
  type 'pkg'
  dmg_name node['mysql_volume_dir']
  not_if {File.exists? "/usr/local/mysql"}
end

# ensemblVEP

remote_file "/tmp/#{node['vep_dir'][reldev]}.zip" do
  source node['vep_url'][reldev]
end

execute "install cpanimus" do
  command "curl -L http://cpanmin.us | perl - --self-upgrade"
  not_if {File.exists? "/usr/local/bin/cpanm"}
end

execute "install VEP prerequisites (File::Copy::Recursive)" do
  command "cpanm File::Copy::Recursive"
  not_if "perldoc File::Copy::Recursive | grep -q File::Copy::Recursive"
end

execute "install VEP prerequisites (DBD::mysql)" do
  command "cpanm DBD::mysql"
  not_if "perldoc DBD::mysql | grep -q DBD::mysql"
end


execute "install VEP" do
  command "unzip #{node['vep_dir'][reldev]} && cd #{node['vep_dir'][reldev]}/scripts && mv variant_effect_predictor /usr/local/ && cd /usr/local/variant_effect_predictor  && sed -i.bak 's/^  test/  #test/' INSTALL.pl && perl INSTALL.pl --NO_HTSLIB -a a"
  cwd "/tmp"
  not_if {File.exists? "/usr/local/variant_effect_predictor"}
end


execute "add vep to path" do
  command "echo 'export PATH=$PATH:/usr/local/variant_effect_predictor' >> /etc/profile"
  not_if "grep -q variant_effect_predictor /etc/profile"
end

remote_file "/tmp/#{node['tabix_url'].split('/').last}" do
  source node['tabix_url']
  # FIXME need not_if?
end

execute "install tabix" do
  cwd "/tmp"
  command "tar xjf #{node['tabix_url'].split('/').last} && cd #{node['tabix_dir']} && make && cp ./tabix /usr/local/bin/"
  not_if {File.exists? "/usr/local/bin/tabix"}
end

# latex settings


execute "add shell_escape=t to texmf.cnf" do
  command "echo 'shell_escape = t' >> texmf.cnf && /Library/TeX/texbin/texhash"
  cwd "/usr/local/texlive/#{node['mactex_year']}"
  not_if "grep -q shell_escape /usr/local/texlive/#{node['mactex_year']}/texmf.cnf"
end


directory "/Users/biocbuild/.BBS" do
  owner "biocbuild"
  action :create
end

file "/Users/biocbuild/.BBS/id_rsa" do
  owner "biocbuild"
  mode "0400"
  content Chef::EncryptedDataBagItem.load('BBS',
    'incoming_private_key')['value']
end


# safe to assume that ~/.ssh exists, I think...
execute "add public key to authorized_keys" do
  user "biocbuild"
  command "echo #{Chef::EncryptedDataBagItem.load('BBS',
    'incoming_public_key')['value']} >> /Users/biocbuild/.ssh/authorized_keys"
  not_if %Q(grep -q "#{Chef::EncryptedDataBagItem.load('BBS',
    'incoming_public_key')['value']}" /Users/biocbuild/.ssh/authorized_keys)
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

file "/Users/biocbuild/.ssh/id_rsa" do
  owner "biocbuild"
  mode "0400"
  content Chef::EncryptedDataBagItem.load('BBS',
    'outgoing_private_key')['value']
end

# pandoc

remote_file "/tmp/#{node['pandoc_url'].split('/').last}" do
  source node['pandoc_url']
end

execute "install pandoc" do
  command "installer -pkg /tmp/#{node['pandoc_url'].split('/').last} -target /"
  not_if {File.exists? "/usr/local/bin/pandoc"}
end

execute "download java" do
  cwd "/tmp"
  command %Q(curl -v -j -k -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" #{node['java_url']})
  not_if {File.exists? "/tmp/#{node['java_url'].split('/').last}"}
end


dmg_package node['java_volume_dir'] do
  file "/tmp/#{node['java_url'].split('/').last}"
  volumes_dir node['java_volume_dir']
  type 'pkg'
  dmg_name node['java_volume_dir']
  not_if "pkgutil --pkgs |grep -q #{node['java_installed_pkg_name']}"
end

execute "R CMD javareconf" do
  command "R CMD javareconf"
  not_if "R CMD config JAVA_HOME | grep -q #{node['java_home']}"
end


execute "tell viewers of crontab not to edit it manually" do
  user "biocbuild"
  command %Q(echo '# DO NOT EDIT THIS FILE BY HAND! Chef modifies it.' | crontab - )
  not_if "crontab -l|grep -q 'DO NOT EDIT'"
end


cron 'noop' do
  hour '6'
  minute '0'
  command '/bin/true'
  user "biocbuild"
end


# FIXME - need to manually clear out old crontab entries?? (if name contains version-specific stuff)


# FIXME - don't uncomment the following cron entry until
# 1) we are ready to run scheduled builds every day; and
# 2) The build code actually has relevant files in BBS/X.Y/bioc/mac[1,2].bioconductor.org

# cron "bioc #{node['bioc_version'][reldev]} software builds" do
#   command %W{
#     /bin/bash --login -c
#     'cd
#     /Users/biocbuild/BBS/#{node['bioc_version'][reldev]}/bioc/#{node['desired_hostname'][reldev]}/
#     && ./run.sh >>
#     /Users/biocbuild/bbs-#{node['bioc_version'][reldev]}-bioc/log/#{node['desired_hostname'][reldev]}.log
#     2>&1'
#   }.join(' ')
#   user "biocbuild"
#   minute  node['bioc_run_time'][reldev][:minute]
#   hour    node['bioc_run_time'][reldev][:hour]
#   day     node['bioc_run_time'][reldev][:day]
#   month   node['bioc_run_time'][reldev][:month]
#   weekday node['bioc_run_time'][reldev][:weekday]
# end

cron "kill R processes that have run too long"  do
    command %W{
        /usr/bin/python
        /Users/biocbuild/BBS/utils/killproc.py
        >>
        /Users/biocbuild/bbs-#{node['bioc_version'][reldev]}-bioc/log/killproc.log
        2>&1
    }.join(' ')
    user "biocbuild"
    minute  node['killproc_time'][:minute]
    hour    node['killproc_time'][:hour]
    day     node['killproc_time'][:day]
    month   node['killproc_time'][:month]
    weekday node['killproc_time'][:weekday]
end

# launchd is an alternate way to schedule tasks, but it has some
# limitations compared to what we're used to. just for the record:
# launchd 'org.bioconductor.killproc' do
#   program "/usr/bin/python"
#   program_arguments %W(/Users/biocbuild/BBS/utils/killproc.py)
#   username "biocbuild"
#   standard_out_path
#     "/Users/biocbuild/bbs-#{node['bioc_version'][reldev]}-bioc/log/killproc-#{Time.now.strftime("%Y%m%d")}.log"
#   standard_error_path
#     "/Users/biocbuild/bbs-#{node['bioc_version'][reldev]}-bioc/log/killproc-#{Time.now.strftime("%Y%m%d")}.log"
#   start_calendar_interval node['killproc_time']
# end



# FIXME no experiment data builds for now?


__END__




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



# get stuff from encrypted data bags




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
