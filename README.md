# Introduction

Pass Plugin let user change their own password from staff client.

## What is a Koha plugin

Koha's Plugin System (available in Koha 3.12+) allows you to add additional tools and reports to [Koha](http://koha-community.org) that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work.

# Downloading

From the [release page](https://github.com/kohawbibliotecepl/koha-plugin-pass/releases) you can download the relevant *.kpz file

# Installing

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

* Change `<enable_plugins>0<enable_plugins>` to `<enable_plugins>1</enable_plugins>` in your koha-conf.xml file
* Confirm that the path to `<pluginsdir>` exists, is correct, and is writable by the web server
* Restart your webserver

Once set up is complete you will need to alter your UseKohaPlugins system preference. On the Tools page you will see the Tools Plugins and on the Reports page you will see the Reports Plugins.

## Installation plugin

Upload the KPZ ( Koha Plugin Zip ) package _(downloaded in the previous step)_ by going to `Administration -> Manage plugins -> Upload plugin`. 

## Apache Configuration

First, add the following Alias Directive to your Apache configuration file under the Intranet section (on Debian, depending on your installation, the configuration file is typically located in `/etc/apache2/sites-enabled`)
```
Alias /plugin "/var/lib/koha/kohadev/plugins"
```
**Important**
The following directory stanza is only required in **Apache 2.4+**. `Require all granted` will result in breaks on **Apache 2.2 and below**.
```
<Directory /var/lib/koha/kohadev/plugins>
      Options Indexes FollowSymLinks ExecCGI
      AddHandler cgi-script .pl
      AllowOverride None
      Require all granted
</Directory>
```

## Used Example 1 - Add link on user menu to staff client view

Add JavaScript code in the Koha system preference `IntranetUserJS`.
```
/* Add link for redirection plugin script */
$("#toplevelmenu").append('<li><a href="/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::Com::MDudzik::Pass&method=tool">Change password</a></li>');
```

## Used Example 2 - Add information to change password every X days 

Add JavaScript code in the Koha system preference `IntranetUserJS`.
```
var change_pass_every = 1;
$.ajax({
	url: '/plugin/Koha/Plugin/Com/MDudzik/Pass/pass.pl',
	dataType: "json",
	type: 'POST',
	data: {
		days: change_pass_every,
	},
	success: function(output){ 
		if (output.data == 1){
			$("#header").prepend('<div style="border-left: 8px solid red;padding-left:8px;"><div style="float:left;padding:4px 8px;"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Belgian_road_sign_A51.svg/120px-Belgian_road_sign_A51.svg.png"></div><div style="float:left;padding:4px 8px;"><h2>User!</h2><p>CHANGE YOUR PASSWORD TO KOHA</p><p>YOU MUST CHANGE PASSWORD EVERY '+change_pass_every+' DAYS<p><a id="changepassword" class="btn btn-default" href="/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::Com::MDudzik::Pass&method=tool"><i class="fa fa-lock"></i> Change password</a></div></div>');
		}
	}
});
```
Script `pass.pl` is checking Koha log's (action - CHANGE PASS) when staff has change the last password. Default is defined for 30 days but we can change this value defining variable `days`. Script returns data => 0 if password has been changed and return data => 1 if not changed for X days. 

**Important** 
Script `pass.pl` need execute permissions.