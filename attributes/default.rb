default['bioc_version'] = {rel: '3.3', dev: '3.4'}
default['use_r_devel'] = {rel: false, dev: false}
default['r_version'] = {rel: '3.3', dev: '3.3'}
default['desired_hostname'] = {rel: "mac2.bioconductor.org",
  dev: "mac1.bioconductor.org"}
default['time_zone'] = "America/New_York"
default['bbs_repos'] = 'https://github.com/Bioconductor/BBS'
default['bbs_branch'] = 'feature/linux_builders_at_ub'
default['xquartz_url'] = "https://dl.bintray.com/xquartz/downloads/XQuartz-2.7.9.dmg"
default['xquartz_name'] = "XQuartz-2.7.9"
default['mactex_url'] = 'http://mirrors.concertpass.com/tex-archive/systems/mac/mactex/mactex-20150613.pkg'
default['mactex_checksum'] = 'c5f5b0'
default['r_url'] = {rel: 'https://cran.rstudio.com/bin/macosx/R-3.3.0.pkg',
  dev: 'https://cran.rstudio.com/bin/macosx/R-3.3.0.pkg'}
default['autoconf_url'] = 'https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz'
default['automake_url'] = 'https://ftp.gnu.org/gnu/automake/automake-1.14.1.tar.gz'
default['r_src_dir'] = {rel: 'R-3.3.0', dev: 'R-3.3.0'}
default['root_url'] = {dev: "https://s3.amazonaws.com/bioc-root-binary/mac-root-binary.tar.gz",
  rel: "https://s3.amazonaws.com/bioc-root-binary/mac-root-binary.tar.gz"}
default['jags_url'] = "http://iweb.dl.sourceforge.net/project/mcmc-jags/JAGS/4.x/Mac%20OS%20X/JAGS-4.2.0.dmg"
default['jags_dir'] = "JAGS-4.2.0"
default['pkgconfig_url'] = "http://r.research.att.com/libs/pkg-config-0.25-darwin9-bin3.tar.gz"
default['libsbml_url']  = "http://pilotfiber.dl.sourceforge.net/project/sbml/libsbml/5.13.0/stable/Mac%20OS%20X/libsbml-5.13.0-libxml2-macosx-elcapitan.dmg"
default['libsbml_dir'] = "libsbml-5.13.0-libxml2"
default['libsbml_packagename'] = 'libSBML-5.13.0-libxml2-elcapitan'
default['vienna_rna_url'] = "https://www.tbi.univie.ac.at/RNA/download/package=viennarna-src-tbi&flavor=sourcecode&dist=1_8_x&arch=src&version=1.8.5"
default['vienna_rna_dir'] = "ViennaRNA-1.8.5"
default['vep_url'] = {dev: "https://codeload.github.com/Ensembl/ensembl-tools/zip/release/84",
  rel: "https://codeload.github.com/Ensembl/ensembl-tools/zip/release/84"}
default['vep_dir'] = {dev: "ensembl-tools-release-84", rel: "ensembl-tools-release-84"}
default['argtable_url'] = "http://prdownloads.sourceforge.net/argtable/argtable2-13.tar.gz"
default['clustalo_url'] = "http://www.clustal.org/omega/clustal-omega-1.2.1.tar.gz"
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
