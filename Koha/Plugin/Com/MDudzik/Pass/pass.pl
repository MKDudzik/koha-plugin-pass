#!/usr/bin/perl

use Modern::Perl;
use CGI;
use utf8;
use C4::Auth qw/check_cookie_auth/;
use JSON;

binmode STDOUT, ":encoding(utf8)";
my $input = new CGI;
my ($auth_status, $sessionID) = check_cookie_auth($input->cookie('CGISESSID'), { catalogue => 1 });

unless ($auth_status eq "ok") {
	print $input->header(-type => 'text/plain', -status => '403 Forbidden');
	exit 0;
}

print $input->header( -type => 'text/plain', -charset => 'UTF-8' );

my $userenv = C4::Context->userenv;
my $userid = $userenv->{'number'};
my $days = $input->param('days') || 30;
my $info;

my $count = GetInfoChangePassword($userid,$days);

if (defined($count) && $count == 0){
	$info={ 'data' => 1 }
}else{
	$info={ 'data' => 0 }
}

print to_json($info);

sub GetInfoChangePassword {
	my ( $userid, $days ) = @_;
	(defined($userid) && $userid ne '') || return();
	my $dbh = C4::Context->dbh;
	my $query = "SELECT * FROM `action_logs` WHERE `action` = 'CHANGE PASS' AND `object` = ? and `timestamp` BETWEEN DATE_SUB(NOW(), INTERVAL ? DAY)AND NOW() ORDER BY `timestamp` DESC";
	my $sth = $dbh->prepare($query);
	$sth->execute($userid, $days);
	return $sth->rows;
}
