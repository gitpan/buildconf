#! /usr/bin/perl

use strict;
use vars qw($VERSION $NAME);
use Getopt::Long;

$VERSION = '0.11';
$NAME = 'buildconf';

my %opt;

parse_args();
parse_conf();

sub parse_args {
    $Getopt::Long::autoabbrev = 0;
    $Getopt::Long::ignorecase = 0; 
    
    GetOptions(\%opt, 'h', 't=s', 'V') or $opt{'h'} = 1;
    
    if (not (@ARGV || %opt) || ($opt{'t'} && not $ARGV[0])) {
        $opt{'h'} = 1;
    }	

    if ($opt{'h'} || $opt{'V'}) {
        if ($opt{'h'}) {
            print <<"";
usage: $0 [options] file 
    -t string     string identifier 
    -h            this help screen
    -V            version info

        }
        else {
    print <<"";
 $NAME $VERSION

        }
        exit 0;
    }
    
    unless (-f $ARGV[0] && -r $ARGV[0]) { 
        die "Couldn't open $ARGV[0]: $!\n";
    }
}

sub parse_conf {
    my (%conf_set,
        $ident,
        $level_ident);
	
    $opt{'t'} =~ s/\W//g;
    
    while (<>) {
        next unless /^\Q#$/ || /^\w+/;
	chomp;
        # identifier and level parsing
        if (/^\Q#$/) { 	
            chomp( my $line2 = <> ); 
	    
            ($level_ident, my $level_value) = split '=';
            ($ident, my $value) = split '=', $line2; 
	    
            $level_ident = substr( $level_ident, 2, length $level_ident );
            $ident = substr( $ident, 2, length $ident );
	     
            for (my $i = $level_value; exists $conf_set{$level_ident}{$i}{$ident}; $i++) {
                delete $conf_set{$level_ident}{$i}{$ident};
            }
            $conf_set{$level_ident}{$level_value}{$ident} = $value;
        }
        # output hash string
        elsif (/^\w+/) {
            $opt{'t'} 
	      ? print qq~\$$opt{'t'}~    
              : print q~$Data{config}~;
	     
            for (my $i = 1; exists $conf_set{$level_ident}{$i}{$ident}; $i++) {
                print qq~{$conf_set{$level_ident}{$i}{$ident}}~;
            }
	    
            my ($ident_conf, $value_conf) = split ' = ';
	    
            print qq~{$ident_conf} =~;
	        
            $value_conf =~ /\'/ 
	      ? print qq~"$value_conf";\n~
              : print qq~'$value_conf';\n~;
        }
    }
    
    print <<''; 
    
1;

}

1;
__END__

=head1 NAME

buildconfig - Convert a subsectional configuration to hash strings

=head1 SYNOPSIS

 usage: buildconfig.pl [options] file
 
=head1 OPTIONS

 -t string            string identifier
 -h                   output usage
 -V                   version info

=head1 DATA FORMAT

=head2 INPUT

=over 4

=item Overall

To gain knowledge on how the configuration principle works, you might have
a look at the supplied user configuration. It is vital to understand, that the
level (declared by $level) and the identifier (declared by $identifier) are
essential factors on the creation of keys within a hash string.

Lines beginning with a leading # and no following $ are not essential for the
parsing process, but keep the visual and cognitive structure upright.

Lines beginning with a leading # and a following $ are vital to the process
of data parsing.

Lines beginning with alphanumeric characters equal key/value entries.

    # =============================
    # SECTION:          directories
    # =============================
    # INDEX:                    D.1
    # =============================
    #
    # Description:
    # 같같같같같같
    # Includes paths concerning
    # your directories.
    #
    ########
    #$level=1
    #$identifier=dir
    #############

    #--------------------
    # Path: log directory
    #--------------------
    log = /var/log

An overall appearance of a section entry and assigned key/value entry.

=item Structure/Index

    # =============================
    # SECTION:          directories
    # =============================
    # INDEX:                    D.1
    # =============================

Classifies the section level (SECTION, SUBSECTION, SUBSUBSECTION),
the identifier of the section, its index level which consists of the
first capitalized character of the section identifer and an integer from
1 - 3.

  [ 1 = SECTION,
    2 = SUBSECTION,
    3 = SUBSUBSECTION ]

=item Section description

    # Description:
    # 같같같같같같
    # Includes paths concerning
    # your directories.

A short section description.

=item Internal flags

    #$level=1
    #$identifier=dir

The flags which are of interest to the build script.
$level sets the section level, $identifier sets
an alphanumeric identifier.

=item Entry comment

    #--------------------
    # Path: log directory
    #--------------------

=item Key/Value

    log = /var/log

The value on the left side functions as key, while the the value on the right
functions as value.

=back

=head2 OUTPUT

=over 4

=item Example

An example hash string will look as following:

    $Data{config}{dir}{log} = '/var/log';

=item Parsing process

The parsing process follows a sequentiell logic.

The structure tree

    | + Level - 1
    | ++ Level - 2
      --------------
    | + Level - 1
    | ++ Level - 2
    | +++ Level - 3
      --------------
    | + Level - 1

is valid, while

    | + Level - 1
    | +++ Level - 3

proves to be invalid.

Ascending in level deepness allows skipping of levels, whereas descending in
level deepness requires that accordingly no level is skipped.

=item Hash string format

A "level 1" hash string:

    $Data{config}{dir}{log} = '/var/log';

A "level 2" hash string:

    $Data{config}{file}{system}{log} = '/etc/syslog.conf';

A "level 3" hash string:

    $Data{config}{file}{system}{user}{entries} = '/etc/master.passwd';

The last two values, in this case 'entries' & 'F</etc/master.passwd>'
correspond to the key & value pair, while the leading parts are
determined by an internal CONSTANT ( $Data{config} ) and three 
subsequent level identifiers.

=item Classification

 internal CONSTANT:                  $Data{config}
 Level 1 - identifier:               file
 Level 2 - identifier:               system
 Level 3 - identifier:               user
 Key:                                entries
 Value:                              /etc/master.passwd

=back

=cut
