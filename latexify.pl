use 5.010;
use utf8;
use strict;
use warnings;

use File::Basename;
use vars qw($VERSION %IRSSI);
$VERSION = '0.001';
%IRSSI = (
  authors => 'Patrick Xia, Ricky Elrod',
  contact => 'patrick.xia@gmail.com, ricky@elrod.me',
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
my %latex_symbols;
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

sub load_data() {
  load_dict("$pfx/symbols", \%latex_symbols);
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

