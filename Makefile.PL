#!/usr/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR            => 'Pierre-Francois Carpentier <carpentier.pf@gmail.com>', 
    LICENSE           => 'MIT',
    NAME              => "TAPEMGR_124T::",
    VERSION_FROM      => "lib/TAPEMGR_124T/Actions.pm",
    EXE_FILES         => [ 'bin/124t-eject', 'bin/124t-load', 'bin/124t-move', 'bin/124t-status'],
    PREREQ_PM         => {
        'WWW::Mechanize'    => 0,
        'Getopt::Long'      => 0,
        'HTML::TreeBuilder' => 0,
    },
);
