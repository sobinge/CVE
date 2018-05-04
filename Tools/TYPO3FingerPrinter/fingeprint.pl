#!/usr/bin/perl

use 5.10.0;

use strict;
use warnings;

no warnings 'experimental';

use Term::ANSIColor qw(colored color);
use Scalar::Util qw/reftype/;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Cookies;
use HTTP::Response;
use Getopt::Long;

=pod

=head1 0

=head2 Date
<DATE>

=head2 Reporter(s)
<AUTHOR>

=head2 Description 
<DESCRIPTION>

=cut

# Display The Header
header();

# Run The MOFO Fingerprinter
fingerprint();


sub header {
    print "\n\n";
    my $title = "=================================[ TYPO3 Version Fingeprint ]=================================";
    
    print qq{
$title
    
                       ______  __    __  ____    _____      __         
                      /\\__  _\\/\\ \\  /\\ \\/\\  _`\\ /\\  __`\\  /'__`\\       
                      \\/_/\\ \\/\\ `\\`\\\\/'/\\ \\ \\L\\ \\ \\ \\/\\ \\/\\_\\L\\ \\      
                         \\ \\ \\ `\\ `\\ /'  \\ \\ ,__/\\ \\ \\ \\ \\/_/_\\_<_     
                          \\ \\ \\  `\\ \\ \\   \\ \\ \\/  \\ \\ \\_\\ \\/\\ \\L\\ \\    
                           \\ \\_\\   \\ \\_\\   \\ \\_\\   \\ \\_____\\ \\____/    
                            \\/_/    \\/_/    \\/_/    \\/_____/\\/___/   

                ____                                                                  __      
               /\\  _`\\   __                                                __        /\\ \\__   
               \\ \\ \\L\\_\\/\\_\\    ___      __      __   _ __   _____   _ __ /\\_\\    ___\\ \\ ,_\\  
                \\ \\  _\\/\\/\\ \\ /' _ `\\  /'_ `\\  /'__`\\/\\`'__\\/\\ '__`\\/\\`'__\\/\\ \\ /' _ `\\ \\ \\/  
                 \\ \\ \\/  \\ \\ \\/\\ \\/\\ \\/\\ \\L\\ \\/\\  __/\\ \\ \\/ \\ \\ \\L\\ \\ \\ \\/ \\ \\ \\/\\ \\/\\ \\ \\ \\_ 
                  \\ \\_\\   \\ \\_\\ \\_\\ \\_\\ \\____ \\ \\____\\\\ \\_\\  \\ \\ ,__/\\ \\_\\  \\ \\_\\ \\_\\ \\_\\ \\__\\
                   \\/_/    \\/_/\\/_/\\/_/\\/___L\\ \\/____/ \\/_/   \\ \\ \\/  \\/_/   \\/_/\\/_/\\/_/\\/__/
                                         /\\____/               \\ \\_\\                          
                                         \\_/__/                 \\/_/                          

    By gottburgm (https://github.com/gottburgm/)
    Deutschland Über Alles !
};
    print "="x(length($title)) . "\n\n";
}

sub exploit_header {
    system("clear");
    print color("red");

    
    print color("green");
    print "\nGithub : https://github.com/gottburgm/\n";
    print "\n\n";
}

sub Help {
    print "\n";
    print qq {  

        # Usage
            perl $0  --url URL [OPTIONS]
        
        # Arguments

            --url [VALUE]           : The Target URL [Format: scheme://host]
            --urls-file [FILE]      : The path to the list of urls to test
            --user-agent [VALUE]    : User-Agent To Send To Server
            --cookie [VALUE]        : Cookie String To Use
            --proxy [VALUE]         : Proxy Server To Use [Format: scheme://host:port]
            --timeout [VALUE]       : Max Timeout For The HTTP Requests
            --auth [VALUE]          : Credentials To Use For HTTP Login [Format: username:password]
            --help                  : Display The Help Menu
            --verbose               : Be More Verbose
            --debug                 : Debug Mode
    };
    print "\n\n";
    exit;
}

sub buildRequester {
    my ($timeout, $useragent, $cookie_string, $proxy ) = @_;
    $cookie_string = 0 if(!defined($cookie_string));
    $proxy = 0 if(!defined($proxy));
    my $browser = 0;
    my $cookie_jar = 0;
    
    $cookie_jar = HTTP::Cookies->new(
        file     => "/tmp/cookies.lwp",
        autosave => 1,
    );
    
    $browser = LWP::UserAgent->new();
    $browser->protocols_allowed( [qw( http https ftp )] );
    $browser->requests_redirectable(['GET', 'PUT', 'DELETE', 'POST', 'HEAD', 'OPTIONS']);
    $browser->cookie_jar( $cookie_jar);
    
    ### Custom Options
    $browser->timeout($timeout);
    $browser->agent($useragent);
    $browser->default_header('Cookie' => $cookie_string) if($cookie_string);
    
    if($proxy) {
        if($proxy =~ /([a-z])+:\/\/.*:([0-9])+/i) {
            $browser->proxy( [qw( http https ftp ftps )] => $proxy);
        } else {
            error("Wrong Proxy String Given, Use Format : scheme://host:port");
        }
    }
    
    return $browser;
}

sub buildRequest {
    my ( $url, $method, $payload, $content_type) = @_;
    $content_type = 'application/x-www-form-urlencoded' if(!defined($content_type));
    $payload = '' if(!defined($payload));
    $method = uc($method);
    my $request = 0;
    
    if($method eq "GET") {
        $payload = '?' . $payload if($payload);
        $request = new HTTP::Request $method, $url . $payload;
        $request->header(Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
    } else {
        $request = new HTTP::Request $method, $url;
        $request->content($payload) if($payload);
        $request->content_type($content_type);
    }
    
    return $request;
}

sub fingerprint {
    my $browser = 0;

    my $proxy = 0;          # Command Argument : proxy
    my $timeout = 30;       # Command Argument : timeout
    my $single_url = 0;     # Command Argument : url
    my $urls_file = 0;      # Command Argument : urls-file
    my $cookie_string = 0;  # Command Argument : cookie
    my $useragent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:54.0) Gecko/20100101 Firefox/54.0";   # Command Argument : user-agent
    my $auth = 0;           # Command Argument : auth
    my $verbose = 0;        # Command Argument : verbose
    my $debug = 0;          # Command Argument : debug
    my $content_type = 0;   # 
    my $payload = 0;        # If we need to support POST/PUT/.. requests
    
    my @urls = ();
    
    GetOptions(
    	"proxy=s"		=> \$proxy,
    	"debug!"		=> \$debug,
    	"verbose!"		=> \$verbose,
    	"timeout=i"		=> \$timeout,
    	"url=s"		    => \$single_url,
    	"urls-file=s"   => \$urls_file,
    	"cookie=s"		=> \$cookie_string,
    	"help!"		    => \&Help,
    	"user-agent=s"	=> \$useragent,
    ) or error("Bad Value(s) Provided In Command Line Arguments");

    ### Required Arguments
    die error("Required Argument(s) Missing .") if(!$single_url && !$urls_file);    
    exploit_header();
    
    if($single_url) {
        push(@urls, $single_url);
    } elsif($urls_file) {
        push(@urls, read_file($urls_file, 1));
    }
    
    ### Setting Up The Requester
    $browser = buildRequester($timeout, $useragent, $cookie_string, $proxy);
    
    # Data
    my $REQUESTS = {
        'VERSIONFILE1' => {
            TEXT => 'Requesting TYPO3 Default File  : backend.php' ,
            METHOD => 'GET',
            PATH => 'backend.php',
        },
        
        'VERSIONFILE2' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3/ChangeLog' ,
            METHOD => 'GET',
            PATH => 'typo3/ChangeLog',
        },
        
        'VERSIONFILE3' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3_src/ChangeLog' ,
            METHOD => 'GET',
            PATH => 'typo3_src/ChangeLog',
        },
        
        'VERSIONFILE4' => {
            TEXT => 'Requesting TYPO3 Default File  : ChangeLog',
            METHOD => 'GET',
            PATH => 'ChangeLog',
        },
        
        'VERSIONFILE5' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/GPL.txt',
            METHOD => 'GET',
            PATH => 't3lib/GPL.txt',
        },
            
        'VERSIONFILE6' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3/GPL.txt',
            METHOD => 'GET',
            PATH => 'typo3/GPL.txt',
        },
            
        'VERSIONFILE7' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3/contrib/extjs/LICENSE.txt',
            METHOD => 'GET',
            PATH => 'typo3/contrib/extjs/LICENSE.txt',
        },
        
        'VERSIONFILE8' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/config_default.php',
            METHOD => 'GET',
            PATH => 't3lib/config_default.php',
        },
        
        'VERSIONFILE9' => {
            TEXT => 'Requesting TYPO3 Default File  : Build/Gruntfile.js',
            METHOD => 'GET',
            PATH => 'Build/Gruntfile.js',
        },
        
        'VERSIONFILE10' => {
            TEXT => 'Requesting TYPO3 Default File  : CVSreadme.txt',
            METHOD => 'GET',
            PATH => 'CVSreadme.txt',
        },
        
        'VERSIONFILE11' => {
            TEXT => 'Requesting TYPO3 Default File  : GPL.txt',
            METHOD => 'GET',
            PATH => 'GPL.txt',
        },
        
        'VERSIONFILE12' => {
            TEXT => 'Requesting TYPO3 Default File  : INSTALL.txt',
            METHOD => 'GET',
            PATH => 'INSTALL.txt',
        },
        
        'VERSIONFILE13' => {
            TEXT => 'Requesting TYPO3 Default File  : LICENSE.txt',
            METHOD => 'GET',
            PATH => 'LICENSE.txt',
        },
        
        'VERSIONFILE14' => {
            TEXT => 'Requesting TYPO3 Default File  : misc/example_MM_relationTables.sql',
            METHOD => 'GET',
            PATH => 'misc/example_MM_relationTables.sql',
        },
        
        'VERSIONFILE15' => {
            TEXT => 'Requesting TYPO3 Default File  : NEWS.txt',
            METHOD => 'GET',
            PATH => 'NEWS.txt',
        },
        
        'VERSIONFILE16' => {
            TEXT => 'Requesting TYPO3 Default File  : README.txt',
            METHOD => 'GET',
            PATH => 'README.txt',
        },
        
        'VERSIONFILE17' => {
            TEXT => 'Requesting TYPO3 Default File  : SVNreadme.txt',
            METHOD => 'GET',
            PATH => 'SVNreadme.txt',
        },
        
        'VERSIONFILE18' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/cache/backend/resources/dbbackend-layout-cache.sql',
            METHOD => 'GET',
            PATH => 't3lib/cache/backend/resources/dbbackend-layout-cache.sql',
        },
        
        'VERSIONFILE19' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/cache/backend/resources/dbbackend-layout-tags.sql',
            METHOD => 'GET',
            PATH => 't3lib/cache/backend/resources/dbbackend-layout-tags.sql',
        },
        
        'VERSIONFILE20' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/cache/backend/resources/ddl.sql',
            METHOD => 'GET',
            PATH => 't3lib/cache/backend/resources/ddl.sql',
        },
        
        'VERSIONFILE21' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/csconvtbl/readme.txt',
            METHOD => 'GET',
            PATH => 't3lib/csconvtbl/readme.txt',
        },
        
        'VERSIONFILE22' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/fonts/readme.txt',
            METHOD => 'GET',
            PATH => 't3lib/fonts/readme.txt',
        },
        
        'VERSIONFILE23' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/gfx/fileicons/CREDITS.txt',
            METHOD => 'GET',
            PATH => 't3lib/gfx/fileicons/CREDITS.txt',
        },
        
        'VERSIONFILE24' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/gfx/flags/CREDITS.txt',
            METHOD => 'GET',
            PATH => 't3lib/gfx/flags/CREDITS.txt',
        },
        
        'VERSIONFILE25' => {
            TEXT => 'Requesting TYPO3 Default File  : t3lib/GPL.txt',
            METHOD => 'GET',
            PATH => 't3lib/GPL.txt',
        },
        
        'VERSIONFILE26' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3/contrib/extjs/LICENSE.txt',
            METHOD => 'GET',
            PATH => 'typo3/contrib/extjs/LICENSE.txt',
        },
        
        'VERSIONFILE27' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3/sysext/workspaces/LICENSE.txt',
            METHOD => 'GET',
            PATH => 'typo3/sysext/workspaces/LICENSE.txt',
        },
        
        'VERSIONFILE28' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3/tab.js',
            METHOD => 'GET',
            PATH => 'typo3/tab.js',
        },
        
        'VERSIONFILE29' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3/tree.js' ,
            METHOD => 'GET',
            PATH => 'typo3/tree.js',
        },
        
        'VERSIONFILE30' => {
            TEXT => 'Requesting TYPO3 Default File  : typo3/contrib/extjs/license.txt',
            METHOD => 'GET',
            PATH => 'typo3/contrib/extjs/license.txt',
        },
    };
    
    my @VERSION_REGEXES = (
        qr/\* Version (\d[.\d]*)?/i,
        qr/RELEASE NOTES FOR TYPO3 (\d[\.\d]*)?/i,
        qr/IMPROVEMENTS between TYPO3 \d\.\d and (\d[\.\d]*)?/i,
        qr/IMPROVEMENTS in TYPO3 (\d[\.\d]*)?/i,
        qr/Raised version to (\d[\.\d]*)?/i,
        qr/Release of TYPO3 (\d[\.\d]*)?/i,
        qr/version="(\d[\.\d]*)?">TYPO3</i,
        qr/TYPO3 (\d[.\d]*)?/i,
    );
    
    my @EXTENSIONS_REGEXES = (
        qr/((?:[a-zA-Z0-9\/\\_\-\.\:]+)?\/(?:sys)?ext\/[^"'>< ]*)/i,
    );
    
    URLS: foreach my $url (@urls) {
        info("Testing: $url");
        my $version = 0;
        
        ### Build/send the requests
        foreach my $request_name (sort keys %{ $REQUESTS }) {
            my $method = $REQUESTS->{$request_name}->{METHOD};
            my $request_url = $url . $REQUESTS->{$request_name}->{PATH};
            
            info($REQUESTS->{$request_name}->{TEXT});
            my $request = buildRequest($request_url, $method, $payload, $content_type);
            my $response = $browser->request($request);
            
            if($debug || $verbose) {
                displayResponse($response);
            }
            
            foreach my $regex (@VERSION_REGEXES) {
                if($response->content =~ /$regex/i) {
                    ($version) = $response->content =~ /$regex/i;
                }
            }
            
            if($version) {
                result("Version Found: $url " . color("yellow") . '(' . color("red") . $version . color("yellow") . ')');
                $request_url = $url . 'index.php';
                $request = buildRequest($request_url, $method, $payload, $content_type);
                $response = $browser->request($request);
                
                my @extensions = ();
                
                foreach my $extensions_regex (@EXTENSIONS_REGEXES) {
                    @extensions = $response->content =~ m/$extensions_regex/sgi;
                }
                
                if(0+@extensions) {
                    foreach my $extension (uniq(@extensions)) {
                        result("Extension Found: $extension");
                    }
                }
                next URLS;
            }
            
        }
        
        warning("Version not found for: $url");
    }
}

sub uniq {
    my ( @array ) = @_;
    
    return keys { map { $_ => 1 } @array };
}

sub read_file {
    my ($file, $chomp) = @_;
    $chomp = 0 if(!defined($chomp));
    
    my @final_content = ();
    
    open FILE, $file or die error("$file couldn't be read  .");
    my @content = <FILE>;
    close FILE;
    
    if($chomp) {
        foreach my $line (@content) {
            chomp $line;
            push(@final_content, $line);
        }
    } else {
        @final_content = @content;   
    }
    
    return @final_content;
}

sub write_file {
    my ( $file, @content ) = @_;
    
    open FILE, ">", $file or die error("$file couldn't be open : " . $@);
    
    foreach my $line (@content) {
        print FILE $line if($line);
    }
    
    close FILE;
}

sub displayResponse {
    my ( $response ) = @_;
    my $request = $response->request;
    
    ### Request
    print "\n\n" . color("yellow") . "--> " . color("blue") .  uc($request->method) . color("cyan") . ' ' . $request->uri->path . color("white") . " HTTP/1.1\n";
    print color("yellow") . "--> "  . color("white") . "Host: " .  color("cyan") . $request->uri->host . "\n";
    
    foreach my $header_name (keys %{ $request->headers }) {
        next if(reftype($request->header($header_name)));
        print color("yellow") . "--> "  . color("white") . $header_name . ": " . color("cyan") . $request->header($header_name) . "\n";
    }
    
    if($request->content) {
        print color("yellow") . "--> "  . color("white") . $request->content . "\n";
    }
    print "\n\n";
    
    
    ### Response
    print color("green") . "<-- "  . color("white") . "HTTP/1.1 " . color("cyan") . $response->status_line . "\n";
    
    foreach my $header_name (keys %{ $response->headers }) {
        next if(reftype($response->header($header_name)));
        print color("green") . "<-- "  . color("white") . $header_name . ": " . color("cyan") . $response->header($header_name) . "\n";
    }
    print "\n" . color("white") . $response->decoded_content . "\n";
}

sub info {
    my ( $text ) = @_;
    print color("white") . "[" . color("blue") . "*" . color("white") . "]" . color("blue") . " INFO" . color("white") . ": " . color("blue") . " $text\n";
}

sub warning {
    my ( $text ) = @_;
    print color("white") . "[" . color("yellow") . "!" . color("white") . "]" . color("yellow") . " WARNING" . color("white") . ": " . color("blue") . "$text\n";
}

sub error {
    my ( $text ) = @_;
    print color("white") . "[" . color("red") . "-" . color("white") . "]" . color("red") . " ERROR" . color("white") . ": " . color("blue") . "$text\n";
    exit;
}
