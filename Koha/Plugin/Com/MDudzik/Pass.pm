package Koha::Plugin::Com::MDudzik::Pass;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw( Koha::Plugins::Base );

## We will also need to include any Koha libraries we want to access
use CGI;
use C4::Auth;
use C4::Context;
use C4::Output;
use Koha::AuthUtils qw(hash_password);
use C4::Languages qw(getlanguage);

## Here we set our plugin version
our $VERSION = "0.2";

## Here is our metadata. Some keys are required while some are optional.
our $metadata = {
	name            => 'Change Pass Plugin',
	author          => 'Michal Dudzik',
	description     => 'Plugin let user change their own password from staff interface',
	date_authored   => '2019-11-04',
	date_updated    => '2019-11-04',
	minimum_version => '17.11',
	maximum_version => undef,
	version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method.
## More can be added but none should be removed.
sub new {
	my ( $class, $args ) = @_;
	
	## We need to add our metadata here so our base class can access it.
	$args->{'metadata'} = $metadata;
	$args->{'metadata'}->{'class'} = $class;
	
	## Here, we call the 'new' method for our base class.
	## This runs some additional magic and checking and
	## returns our actual $self
	my $self = $class->SUPER::new( $args );
	
	return $self;
}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
	my ( $self, $args ) = @_;

	return 1;
	
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
	my ( $self, $args ) = @_;

	return 1;
	
}

## The existance of a 'tool' subroutine means the plugin is capable
## of running a tool. The difference between a tool and a report is
## primarily semantic, but in general any plugin that modifies the
## Koha database should be considered a tool.
sub tool {

	my ( $self, $args ) = @_;
	
	my $query = $self->{'cgi'};
	my @errors;
	my $digest;
	my $template_name;
	my $lang = getlanguage($query);
	my $koha_ver = C4::Context->preference('Version');
	my $newpassword  = $query->param('newpassword');
	my $newpassword2 = $query->param('newpassword2');
	my $userenv = C4::Context->userenv;
	my $loggedinuser = $userenv->{'number'};
	my $patron = Koha::Patrons->find( $loggedinuser );

	if ($lang ge 'pl-PL') {
		$template_name = 'pass_pl.tt';
	}else{
		$template_name = 'pass_en.tt';
	}
	
	my $template = $self->get_template( { file => $template_name } );
	
	push( @errors, 'NOMATCH' ) if ( ( $newpassword && $newpassword2 ) && ( $newpassword ne $newpassword2 ) );
	if ( $newpassword and not @errors ) {
		my ( $is_valid, $error ) = Koha::AuthUtils::is_password_valid( $newpassword );
		unless ( $is_valid ) {
			push @errors, 'ERROR_password_too_short' if $error eq 'too_short';
			push @errors, 'ERROR_password_too_weak' if $error eq 'too_weak';
			push @errors, 'ERROR_password_has_whitespaces' if $error eq 'has_whitespaces';
		}
	}
	
	if ( $newpassword and not @errors) {
		if ( $koha_ver < 18.11){
			$digest = hash_password( scalar $newpassword );
		}else{
			$digest = $newpassword;
		}
		if ( $koha_ver >= 19.05){
			$patron->Koha::Patron::set_password({ password => $digest });
		}else{
			$patron->Koha::Patron::update_password($patron->userid, $digest) 
		}
		print $query->redirect("/cgi-bin/koha/mainpage.pl?logout.x=1&pass_change=1");	
	}
	
	if ( scalar(@errors) ) {
		$template->param( errormsg => 1 );
		foreach my $error (@errors) {
			$template->param($error) || $template->param( $error => 1 );
		}
	}
	
	$template->param(
		patron	=> $patron,
		class	=> $self->{'class'},
		method	=> 'tool'
	);
	
	$self->output_html($template->output());
}
1;
