#!/usr/bin/perl
# ---------------------------
#         order.cgi
# ---------------------------

use DBI;
use CGI qw/:standard/;
use MIME::Base64;
use Cos::auth qw(auth_prop);

my($user) = param('user');
my($pass) = param('pass');

print "Content-type: text/plain\n\n";
print <<"EOF";
#
# Version 1.0 getprop.cgi information
# User: $user 
#
EOF

auth_prop($user, $pass);

print <<'EOF';
types: 5

type1: support
mask1: (.*)
repl1: $1

type2: property
mask2: (.*)
repl2: $1

#ubs3: /^(.{8}\\...)./\\1/
type3: rdt
mask3: ^(.{8}\\...).
repl3: $1

type4: rx
mask4: ^(.*)\\.[a-z][a-z]
repl4: $1

type5: hou
mask5: ^(.*)
repl5: $1

EOF
