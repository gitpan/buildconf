use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'buildconf',
    VERSION_FROM => 'buildconf.pl',
    PREREQ_PM    => { Getopt::Long => 0 },
    ($] >= 5.005 
      ? (ABSTRACT_FROM => 'buildconf.pl') : ()
    ),
);
