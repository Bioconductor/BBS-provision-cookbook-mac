default['bioc_version'] = {rel: '3.3', dev: '3.4'}
default['use_r_devel'] = {rel: false, dev: false}
default['r_version'] = {rel: '3.3', dev: '3.3'}
default['desired_hostname'] = {rel: "mac2.bioconductor.org",
  dev: "mac1.bioconductor.org"}
default['time_zone'] = "America/New_York"
default['bbs_repos'] = 'https://github.com/Bioconductor/BBS'
default['bbs_branch'] = 'feature/linux_builders_at_ub'
default['xquartz_url'] = "https://dl.bintray.com/xquartz/downloads/XQuartz-2.7.9.dmg"
default['mactex_url'] = 'http://tug.org/cgi-bin/mactex-download/MacTeX.pkg'
default['mactex_year'] = '2016'
default['r_url'] = {rel: 'https://cran.rstudio.com/bin/macosx/R-3.3.1.pkg',
  dev: 'https://cran.rstudio.com/bin/macosx/R-3.3.1.pkg'}
default['r_version_string'] = {rel: '3.3.1', dev: '3.3.1'}
default['autoconf_url'] = 'https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz'
default['automake_url'] = 'https://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.gz'
default['root_url'] = {dev: "https://s3.amazonaws.com/bioc-root-binary/mac-root-binary.tar.gz",
  rel: "https://s3.amazonaws.com/bioc-root-binary/mac-root-binary.tar.gz"}
default['jags_url'] = "http://ufpr.dl.sourceforge.net/project/mcmc-jags/JAGS/4.x/Mac%20OS%20X/JAGS-4.2.0.dmg"
default['jags_dir'] = "JAGS-4.2.0"
default['pkgconfig_url'] = "http://r.research.att.com/libs/pkg-config-0.25-darwin9-bin3.tar.gz"
default['libsbml_url']  = "http://iweb.dl.sourceforge.net/project/sbml/libsbml/5.10.2/stable/Mac%20OS%20X/libsbml-5.10.2-libxml2-macosx-mavericks.dmg"
default['libsbml_dir'] = "libsbml-5.10.2-libxml2"
default['libsbml_packagename'] = 'libSBML-5.10.2-libxml2-mavericks'
default['vienna_rna_url'] = "https://www.tbi.univie.ac.at/RNA/download/package=viennarna-src-tbi&flavor=sourcecode&dist=2_2_x&arch=src&version=2.2.5"
default['vienna_rna_dir'] = "ViennaRNA-2.2.5"
default['vep_url'] = {dev: "https://codeload.github.com/Ensembl/ensembl-tools/zip/release/84",
  rel: "https://codeload.github.com/Ensembl/ensembl-tools/zip/release/84"}
default['vep_dir'] = {dev: "ensembl-tools-release-84", rel: "ensembl-tools-release-84"}
default['mysql_url'] = 'http://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.12-osx10.11-x86_64.dmg'
default['mysql_volume_dir'] = 'mysql-5.7.12-osx10.11-x86_64' # pkg name is the same
default['tabix_url'] = 'http://pilotfiber.dl.sourceforge.net/project/samtools/tabix/tabix-0.2.6.tar.bz2'
default['tabix_dir'] = 'tabix-0.2.6'
default['argtable_url'] = "http://prdownloads.sourceforge.net/argtable/argtable2-13.tar.gz"
default['clustalo_url'] = "http://www.clustal.org/omega/clustal-omega-1.2.1.tar.gz"
default['gtk_url'] = 'http://r.research.att.com/libs/GTK_2.24.17-X11.pkg'
default['gtk_pkgconfig_dir'] = '/Library/Frameworks/GTK+.framework/Versions/2.24.X11/Resources/lib/pkgconfig/'
default['simon_tars'] = [
    ['cairo-1.12.16-darwin10-bin2.tar.gz', '/usr/local/lib/libcairo.la'],
    ['fontconfig-2.11.1-darwin10-bin2.tar.gz','/usr/local/lib/pkgconfig/fontconfig.pc'],
    ['freetype-2.5.3-darwin10-bin2.tar.gz', '/usr/local/include/freetype2/freetype.h'],
    ['gfortran-4.8.2-darwin13.tar.bz2', '/usr/local/bin/gfortran'],
    ['gsl-1.16-darwin13-x86_64.tar.gz', '/usr/local/bin/gsl-config'],
    ['hdf5-1.8.14-darwin.13-x86_64.tar.gz', '/usr/local/bin/h5copy'],
    ['jpeg-v8d-darwin9-bin4.tar.gz', '/usr/local/bin/cjpeg'],
    ['libpng-1.5.8-darwin9-bin4.tar.gz', '/usr/local/bin/libpng-config'],
    ['netcdf-4.1.3-darwin9-bin3.tar.gz', '/usr/local/bin/nc-config'],
    ['pixman-0.32.4-darwin10-bin2.tar.gz', '/usr/local/lib/pkgconfig/pixman-1.pc'],
    ['pkg-config-0.25-darwin9-bin3.tar.gz', '/usr/local/bin/pkg-config'],
    ['protobuf-2.6.1-darwin.13-x86_64.tar.gz', '/usr/local/lib/libprotobuf.a'],
    ['tiff-4.0.2-darwin9-bin4.tar.gz', '/usr/local/bin/tiffinfo'],
    ['xz-5.0.5-darwin10-bin2.tar.gz', '/usr/local/bin/lzma']
]
default['pandoc_url'] = "https://github.com/jgm/pandoc/releases/download/1.17.0.2/pandoc-1.17.0.2-osx.pkg"
default['java_url'] = "http://download.oracle.com/otn-pub/java/jdk/8u92-b14/jdk-8u92-macosx-x64.dmg"
default['java_volume_dir'] = "JDK 8 Update 92" # this is also .pkg name
default['java_installed_pkg_name'] = 'com.oracle.jdk8u92'
default['java_home'] = "/Library/Java/JavaVirtualMachines/jdk1.8.0_92.jdk/Contents/Home/jre"
default['openbabel_url'] = 'https://sourceforge.net/projects/openbabel/files/openbabel/2.3.1/OpenBabel-2.3.1.mac.zip/download'
default['openbabel_zipname'] = 'OpenBabel-2.3.1.mac.zip'
default['openbabel_dir'] = 'Open Babel 2.3.1'
default['openbabel_pkg'] = 'OpenBabel.pkg'
default['imagemagick_url'] = 'https://s3.amazonaws.com/mac-provisioning/ImageMagick-6.8.8-6.pkg'
default['graphviz_url'] = 'http://www.graphviz.org/pub/graphviz/stable/macos/mountainlion/graphviz-2.36.0.pkg'

# cron info

def starhash(minute: '*', hour: '*', day: '*', month: '*', weekday: '*')
  {minute: minute.to_s, hour: hour.to_s, day: day.to_s,
    month: month.to_s, weekday: weekday.to_s}
end

# biocbuild

default['bioc_pre_run_time'] = {
  rel:
    starhash(minute: 20, hour: 19, weekday: '0,1,2,3,4,6'),
  dev:
    starhash(minute: 20, hour: 20, weekday: '0,1,2,3,4,6')
}

default['bioc_run_time'] = {
  rel:
    starhash(minute: 20, hour: 20, weekday: '0,1,2,3,4,6'),
  dev:
    starhash(minute: 0, hour: 21, weekday: '0,1,2,3,4,6')
}

default['bioc_post_run_time'] = {
  rel:
    starhash(minute: 45, hour: 13, weekday: '0,1,2,3,4,6'),
  dev:
    starhash(minute: 15, hour: 14, weekday: '0,1,2,3,4,6')
}

default['killproc_time'] = starhash(minute: 10)

default['bioc_send_notifications_time'] = starhash(minute: 10, hour: 14, weekday: 2)

default['test_coverage_time'] = {
  rel: starhash(minute: 30, hour: 13, weekday: "0,1,2,4,5"),
  dev: starhash(minute: 30, hour: 13, weekday: "0,1,2,4,5"),
}

default['build_report_archive_time'] = {
  rel: starhash(minute: 3, hour: 19, weekday: "0,1,2,3,4,6"),
  dev: starhash(minute: 3, hour: 20, weekday: "0,1,2,3,4,6")
}
