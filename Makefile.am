share_perl5dir = $(datadir)/perl5
share_perl5_vyatta_configdir = $(datadir)/perl5/Vyatta/Config
currentdir = $(sysconfdir)/config-migrate/current
migratedir = $(sysconfdir)/config-migrate/migrate

sbin_SCRIPTS =
bin_SCRIPTS =
share_perl5_DATA =
share_perl5_vyatta_config_DATA =

sbin_SCRIPTS += scripts/vyatta_config_migrate.pl
sbin_SCRIPTS += scripts/vyatta_current_conf_ver.pl
sbin_SCRIPTS += scripts/XorpConfigMigrator.pl

share_perl5_DATA += scripts/XorpConfigParser.pm
share_perl5_vyatta_config_DATA += lib/Vyatta/Config/Migrate.pm

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | \
  cpio -0pd

# NOTE: using dummy-versions is just temporary. the version files there
# should be removed as the corresponding packages are moved to the new
# packaging/build system.
install-exec-hook:
	mkdir -p $(DESTDIR)$(currentdir)
	mkdir -p $(DESTDIR)$(migratedir)
	( cd dummy-versions ; $(cpiop) $(DESTDIR)$(currentdir) )
	( cd migrate; $(cpiop) $(DESTDIR)$(migratedir) )

