use 5.010;
use utf8;
use strict;
use warnings;

use File::Basename;
use vars qw($VERSION %IRSSI);
$VERSION = '0.001';
%IRSSI = (
  authors => 'Patrick Xia',
  contact => 'patrick.xia@gmail.com',
  name => 'latexify',
  description => 'Latexify outgoing messages',
  license => 'BSD',
  url => 'none',
  modules => 'File::Basename'
);

sub evt_send_text {
  my ($line, $server_rec, $wi_item_rec) = @_;
  if (convert($line) ne $line) {
    Irssi::signal_emit('send text', convert($line), $server_rec, $wi_item_rec);
    Irssi::signal_stop();
  }
}

Irssi::signal_add_first('send text', 'evt_send_text');

# the following is just a direct no-brainer port of the python
# so some (or most!) of it may seem like a kludge

# except: 
# - latex_symbols is now a hash and not a flat array of pairs
# - process_starting_modifiers is no longer implemented

my $data_loaded = 0;
my 
  (%latex_symbols, 
   %superscripts, 
   %subscripts, 
   %textbb, 
   %textbf, 
   %textit,
   %textcal,
   %textfrak,
   %textmono);

my $dir = dirname(__FILE__);
my $pfx = "$dir/data";

sub convert($) {
  my $s = $_[0];

  unless ($data_loaded) {
    load_data();
    $data_loaded = 1;
  }

  my $ss = convert_single_symbol($s);
  return $ss if $ss;

  $s = convert_latex_symbols($s);
  $s = apply_all_modifiers($s);
  return $s;
}

# If s is just a latex code "alpha" or "beta" it converts it to its
# unicode representation.
sub convert_single_symbol($) {
  return $latex_symbols{'\\' . $_[0]};
}

# Replace each "\alpha", "\beta" and similar latex symbols with
# their unicode representation.
sub convert_latex_symbols($) {
  $_ = $_[0];
  for my $key (reverse sort {length $a <=> length $b} keys %latex_symbols) {
    s/\Q$key\E/$latex_symbols{$key}/g;
  }
  return $_;
}

sub apply_all_modifiers($) {
  $_ = $_[0];
  $_ = apply_modifier($_, "^", \%superscripts);
  $_ = apply_modifier($_, "_", \%subscripts);
  $_ = apply_modifier($_, "\\bb", \%textbb);
  $_ = apply_modifier($_, "\\bf", \%textbf);
  $_ = apply_modifier($_, "\\it", \%textit);
  $_ = apply_modifier($_, "\\cal", \%textcal);
  $_ = apply_modifier($_, "\\frak", \%textfrak);
  $_ = apply_modifier($_, "\\mono", \%textmono);
  return $_;
}

# Example: modifier = "^", D = superscripts
# This will search for the ^ signs and replace the next
# digit or (digits when {} is used) with its/their uppercase representation.
sub apply_modifier($$$) {
  $_ = shift;
  my $modifier = shift;
  my %D = %{shift @_};

  s/\Q$modifier\E/\^/;

  # whoo why am I porting this state machine
  my $newtext = "";
  my ($mode_normal, $mode_modified, $mode_long) = 0..2;
  my $mode = $mode_normal;
  for (split//) {
    if ($mode == $mode_normal && $_ eq '^') {
      $mode = $mode_modified;
      next;
    } elsif ($mode == $mode_modified && $_ eq '{') {
      $mode = $mode_long;
      next;
    } elsif ($mode == $mode_modified) {
      $newtext .= $D{$_} // $_;
      $mode = $mode_normal;
      next;
    } elsif ($mode == $mode_long && $_ eq '}') {
      $mode = $mode_normal;
      next;
    }

    if ($mode == $mode_normal) {
      $newtext .= $_;
    } else {
      $newtext .= $D{$_} // $_;
    }
  }
  return $newtext;
}

sub load_data() {
  load_dict("$pfx/symbols", \%latex_symbols);
	load_dict("$pfx/subscripts", \%subscripts);
	load_dict("$pfx/superscripts", \%superscripts);
	load_dict("$pfx/textbb", \%textbb);
	load_dict("$pfx/textbf", \%textbf);
	load_dict("$pfx/textit", \%textit);
	load_dict("$pfx/textcal", \%textcal);
	load_dict("$pfx/textfrak", \%textfrak);
	load_dict("$pfx/textmono", \%textmono);
}

sub load_dict($$) {
  my $filename = shift;
  my $D = shift;
  open(my $f, "<", $filename) or die "cannot open $filename: $!";
  while (<$f>) {
    my @words = split;
    my $code = $words[0];
    my $val = $words[1];
    $D->{$code} = $val;
  }
}

