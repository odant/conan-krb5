#!/usr/athena/bin/perl -w

# Code initially generated by s2p
# Code modified to use strict and IO::File

eval 'exec /usr/athena/bin/perl -S $0 ${1+"$@"}'
    if 0; # line above evaluated when running under some shell (i.e., not perl)

use strict;
use IO::File;

my $verbose = 0;
my $error = 0;
if ( $ARGV[0] eq "-v" ) { $verbose = 1; shift @ARGV; }
my $h_filename = shift @ARGV || die "usage: $0 [-v] header-file [def-file]\n";
my $d_filename = shift @ARGV;

my $h = open_always($h_filename);
my $d = open_always($d_filename) if $d_filename;

sub open_always
{
    my $file = shift || die;
    my $handle = new IO::File "<$file";
    die "Could not open $file\n" if !$handle;
    return $handle;
}

my @convW = ();
my @convC = ();
my @convK = ();
my @convD = ();
my @vararg = ();

my $len1;
my %conv;
my $printit;
my $vararg;

LINE:
while (! $h->eof()) {
    $_ = $h->getline();
    s/(\r)?\n$//;
    # get calling convention info for function decls
    # what about function pointer typedefs?
    # need to verify unhandled syntax actually triggers a report, not ignored
    # blank lines
    if (/^[ \t\cZ]*$/) {
        next LINE;
    }
  Top:
    # drop KRB5INT_BEGIN_DECLS and KRB5INT_END_DECLS
    if (/^ *(KRB5INT|GSSAPI[A-Z]*)_(BEGIN|END)_DECLS/) {
        next LINE;
    }
    # drop preprocessor directives
    if (/^ *#/) {
	while (/\\$/) { $_ .= $h->getline(); }
        next LINE;
    }
    if (/^ *\?==/) {
        next LINE;
    }
    s/#.*$//;
    if (/^\} *$/) {
        next LINE;
    }
    # strip comments
  Cloop1:
    if (/\/\*./) {
	s;/\*[^*]*;/*;;
	s;/\*\*([^/]);/*$1;;
	s;/\*\*$;/*;;
	s;/\*\*/; ;g;
	goto Cloop1;
    }
    # multi-line comments?
    if (/\/\*$/) {
	$_ .= " ";
	$len1 = length;
	$_ .= $h->getline();
	s/(\r)?\n$// if $len1 < length;
	goto Cloop1 if /\/\*./;
    }
    # blank lines
    if (/^[ \t]*$/) {
        next LINE;
    }
    if (/^ *extern "C" \{/) {
        next LINE;
    }
    s/KRB5_ATTR_DEPRECATED//;
    # elide struct definitions
  Struct1:
    if (/\{[^}]*\}/) {
	s/\{[^}]*\}/ /g;
	goto Struct1;
    }
    # multi-line defs
    if (/\{/) {
	$_ .= "\n";
	$len1 = length;
	$_ .= $h->getline();
	s/(\r)?\n$// if $len1 < length;
	goto Struct1;
    }
  Semi:
    unless (/;/) {
	$_ .= "\n";
	$len1 = length;
	$_ .= $h->getline();
	s/(\r)?\n$// if $len1 < length;
	s/\n/ /g;
	s/[ \t]+/ /g;
	s/^[ \t]*//;
	goto Top;
    }
    if (/^typedef[^;]*;/) {
	s/^typedef[^;]*;//g;
	goto Semi;
    }
    if (/^struct[^\(\)]*;/) {
	s/^struct[^\(\)]*;//g;
	goto Semi;
    }
    # should just have simple decls now; split lines at semicolons
    s/ *;[ \t]*$//;
    s/ *;/\n/g;
    if (/^[ \t]*$/) {
        next LINE;
    }
    s/[ \t]*$//;
    goto Notfunct unless /\(.*\)/;
    # Get rid of KRB5_PROTOTYPE
    s/KRB5_PROTOTYPE//;
    s/KRB5_STDARG_P//;
    # here, is probably function decl
    # strip simple arg list - parens, no parens inside; discard, iterate.
    # the iteration should deal with function pointer args.
    $vararg = /\.\.\./;
  Striparg:
    if (/ *\([^\(\)]*\)/) {
	s/ *\([^\(\)]*\)//g;
	goto Striparg;
    }
    # Also strip out attributes, or what's left over of them.
    if (/__attribute__/) {
	s/[ \t]*__attribute__[ \t]*//g;
	goto Striparg;
    }
    # replace return type etc with one token indicating calling convention
    if (/CALLCONV/) {
	if (/\bKRB5_CALLCONV_WRONG\b/) {
	    s/^.*KRB5_CALLCONV_WRONG *//;
	    die "Invalid function name: '$_'" if (!/^[A-Za-z0-9_]+$/);
	    push @convW, $_;
	    push @vararg, $_ if $vararg;
	} elsif (/\bKRB5_CALLCONV_C\b/) {
	    s/^.*KRB5_CALLCONV_C *//;
	    die "Invalid function name: '$_'" if (!/^[A-Za-z0-9_]+$/);
	    push @convC, $_;
	    push @vararg, $_ if $vararg;
	} elsif (/\bKRB5_CALLCONV\b/) {
	    s/^.*KRB5_CALLCONV *//;
	    die "Invalid function name: '$_'" if (!/^[A-Za-z0-9_]+$/);
	    push @convK, $_;
	    push @vararg, $_ if $vararg;
	} else {
	    die "Unrecognized calling convention while parsing: '$_'\n";
	}
	goto Hadcallc;
    }
    # deal with no CALLCONV indicator
    s/^.* \**(\w+) *$/$1/;
    die "Invalid function name: '$_'" if (!/^[A-Za-z0-9_]+$/);
    push @convD, $_;
    push @vararg, $_ if $vararg;
  Hadcallc:
    goto Skipnotf;
  Notfunct:
    # probably a variable
    s/^/VARIABLE_DECL /;
  Skipnotf:
    # toss blank lines
    if (/^[ \t]*$/) {
        next LINE;
    }
}

if ( $verbose ) {
    print join("\n\t", "Using default calling convention:", sort(@convD));
    print join("\n\t", "\nUsing KRB5_CALLCONV:", sort(@convK));
    print join("\n\t", "\nUsing KRB5_CALLCONV_C:", sort(@convC));
    print join("\n\t", "\nUsing KRB5_CALLCONV_WRONG:", sort(@convW));
    print "\n","-"x70,"\n";
}

%conv = ();
map { $conv{$_} = "default"; } @convD;
map { $conv{$_} = "KRB5_CALLCONV"; } @convK;
map { $conv{$_} = "KRB5_CALLCONV_C"; } @convC;
map { $conv{$_} = "KRB5_CALLCONV_WRONG"; } @convW;

my %vararg = ();
map { $vararg{$_} = 1; } @vararg;

if (!$d) {
    print "No .DEF file specified\n" if $verbose;
    exit 0;
}

LINE2:
while (! $d->eof()) {
    $_ = $d->getline();
    s/[\r\n]+$//;
    #
    if (/^;/) {
        $printit = 0;
        next LINE2;
    }
    if (/^[ \t]*$/) {
        $printit = 0;
        next LINE2;
    }
    if (/^EXPORTS/ || /^DESCRIPTION/ || /^HEAPSIZE/) {
        $printit = 0;
        next LINE2;
    }
    s/[ \t]*//g;
    s/@[0-9]+//;
    my($xconv);
    if (/PRIVATE/ || /INTERNAL/) {
	$xconv = "PRIVATE";
    } elsif (/DATA/) {
	$xconv = "DATA";
    } elsif (/!CALLCONV/ || /KRB5_CALLCONV_WRONG/) {
	$xconv = "KRB5_CALLCONV_WRONG";
    } elsif ($vararg{$_}) {
	$xconv = "KRB5_CALLCONV_C";
    } else {
	$xconv = "KRB5_CALLCONV";
    }
    s/;.*$//;

    if ($xconv eq "PRIVATE") {
	print "\t private $_\n" if $verbose;
	next LINE2;
    }
    if ($xconv eq "DATA") {
	print "\t data $_\n" if $verbose;
	next LINE2;
    }
    if (!defined($conv{$_})) {
	print "No calling convention specified for $_!\n";
	$error = 1;
    } elsif (! ($conv{$_} eq $xconv)) {
	print "Function $_ should have calling convention '$xconv', but has '$conv{$_}' instead.\n";
	$error = 1;
    } else {
#	print "Function $_ is okay.\n";
    }
}

#print "Calling conventions defined for: ", keys(%conv);
exit $error;
