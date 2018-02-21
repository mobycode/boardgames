#!C/user/bin/perl
use strict;

require LWP::UserAgent;
require HTTP::Status;
use Cwd;
use JSON;
use XML::XML2JSON;
use List::MoreUtils qw(first_index);
use Data::Dumper;
use Scalar::Util qw(looks_like_number); # parseInt equalivent for bggxml numeric values
use Time::HiRes qw(time usleep); # getTimeStamp (time in microseconds), get_bgg_collection_json (sleep in microseconds)
use POSIX qw(strftime);          # getTimeStamp (easier time formatting)
use Firebase;                    # put data in firebase db
use Getopt::Long;

# always autoflush stderr/stdout
use IO::Handle;
STDERR->autoflush(1);
STDOUT->autoflush(1);

use constant TRUE  => JSON::true;
use constant FALSE => JSON::false;

use constant OPTION_NEWLINE => "newline";
use constant OPTION_APPEND  => "append";
use constant LOG_NONEWLINE => { OPTION_NEWLINE => FALSE, OPTION_APPEND => FALSE };
use constant LOG_APPEND => { OPTION_NEWLINE => TRUE, OPTION_APPEND => TRUE };
use constant LOG_APPEND_NONEWLINE => { OPTION_NEWLINE => FALSE, OPTION_APPEND => TRUE };

use constant ARG_ERROR => "error";
use constant ARG_PRODUCTION => "production";
use constant ARG_SKIP_THINGS => "skip_things";
use constant ARG_SKIP_HTTP => "skip_http";
use constant ARG_SKIP_BGGXML => "skip_bggxml";
use constant ARG_SKIP_ITEMS => "skip_items";
use constant ARG_SKIP_FIREBASE => "skip_firebase";

use constant DATABASE_BGG => "DATABASE_BGG";
use constant DATABASE_MOBYBEAVER => "DATABASE_MOBYBEAVER";
use constant DATABASE => &DATABASE_BGG;

use constant SUBTYPES => [
    "boardgame",
    "boardgameexpansion",
    "prevowned",
    "played"
];

use constant USERS_TO_OWNERS => {
    "mobybeaver" => "Justin",
    "flettz" => "Joe",
    "highexodus" => "Ian",
    "archleech" => "Jason"
};

#use constant MIN_KEYS => FALSE;
#if (&MIN_KEYS) {
#  use constant ITEM_KEY_NAME => "n";
#  use constant ITEM_KEY_DESCRIPTION => "d";
#  use constant ITEM_KEY_SUBTYPE => "t";
#  use constant ITEM_KEY_EXPANSIONS => "exps";
#  use constant ITEM_KEY_EXPANDS => "expds";
#  use constant ITEM_KEY_MINPLAYERS => "minp";
#  use constant ITEM_KEY_MAXPLAYERS => "maxp";
#  use constant ITEM_KEY_MINPLAYTIME => "mint";
#  use constant ITEM_KEY_MAXPLAYTIME => "maxt";
#  use constant ITEM_KEY_NUMPLAYS => "np";
#  use constant ITEM_KEY_OWNERS => "co";
#  use constant ITEM_KEY_PREVOWNERS => "po";
#  use constant ITEM_KEY_IMAGE => "img";
#  use constant ITEM_KEY_THUMBNAIL => "th";
#  use constant ITEM_KEY_PICTURE => "pic";
#  use constant ITEM_KEY_PICTURE_EXT => "pice";
#  use constant ITEM_KEY_YEARPBLISHED => "y";
#  use constant ITEM_KEY_WEIGHT => "w";
#  use constant ITEM_KEY_RATING => "rtg";
#  use constant ITEM_KEY_RANK => "rnk";
#  use constant ITEM_KEY_BEST_NUMPLAYERS => "bp";
#  use constant ITEM_KEY_RECOMMENDED_NUMPLAYERS => "rp";
#} else {
  use constant ITEM_KEY_NAME => "name";
  use constant ITEM_KEY_DESCRIPTION => "description";
  use constant ITEM_KEY_SUBTYPE => "subtype";
  use constant ITEM_KEY_EXPANSIONS => "expansions";
  use constant ITEM_KEY_EXPANDS => "expands";
  use constant ITEM_KEY_MINPLAYERS => "minplayers";
  use constant ITEM_KEY_MAXPLAYERS => "maxplayers";
  use constant ITEM_KEY_MINPLAYTIME => "minplaytime";
  use constant ITEM_KEY_MAXPLAYTIME => "maxplaytime";
  use constant ITEM_KEY_NUMPLAYS => "numplays";
  use constant ITEM_KEY_OWNERS => "owners";
  use constant ITEM_KEY_PREVOWNERS => "pevowners";
  use constant ITEM_KEY_IMAGE => "image";
  use constant ITEM_KEY_THUMBNAIL => "thumbnail";
  use constant ITEM_KEY_PICTURE => "picture";
  use constant ITEM_KEY_PICTURE_EXT => "pictureext";
  use constant ITEM_KEY_YEARPBLISHED => "yearpublished";
  use constant ITEM_KEY_WEIGHT => "weight";
  use constant ITEM_KEY_RATING => "rating";
  use constant ITEM_KEY_RANK => "rank";
  use constant ITEM_KEY_BEST_NUMPLAYERS => "bestplayers";
  use constant ITEM_KEY_RECOMMENDED_NUMPLAYERS => "recplayers";
#}


my $XML2JSON = XML::XML2JSON->new();
my $dir = cwd();


my $args_hash_ref = {};
my $json_hash_ref = {};
my $items_hash_ref = {};
my $comp_ids_hash_ref = {};


sub log_file {
    my ($i) = @_;
    return "$dir/logs/log$i.txt";
}
sub open_log {
    my $limit = 4;
    my $i;
    my $file;

    # keep up to $limit log files; re-index existing logfiles
    $file = log_file($i);
    if (-e "$file") {
    }
    for ($i=$limit; $i >= 0; $i--) {
        $file = log_file($i);
        if ($i == $limit) {
            if (-e $file) {
                unlink $file or warn "Could not unlink $file: $!";
            }
        } elsif (-e "$file") {
            rename $file, log_file($i+1);
        }
    }

    open LOG_FH, ">$file"
        or die "Failed to open log file: $!\n";
    _enterExit("open_log");
}
sub close_log {
    _enterExit("close_log");
    close LOG_FH;
}
sub getTimeStamp {
    my $t = time;
    my $ts = strftime("%Y%m%d %H:%M:%S", localtime($t));
    $ts .= sprintf(".%03d", ($t-int($t))*1000);
    return $ts;
}
sub _log {
    my ($msg, $options_ref) = @_;
    my %options = {};
    my $str = "$msg";
    my $time = getTimeStamp();

    if (ref($options_ref) eq "HASH") {
        %options = %{ $options_ref };
        if (not(exists($options{OPTION_APPEND})) || $options{OPTION_APPEND} == FALSE) {
            $str = "$time  $str";
        }
        if (not(exists($options{OPTION_NEWLINE})) || $options{OPTION_NEWLINE} == TRUE) {
            $str .= "\n";
        }
    } else {
        $str = "$time  $str\n";
    }

    {
        no warnings;
        print LOG_FH "$str";
        print "$str";
    }
}
sub _enter {
    my ($msg, $options_ref) = @_;
    _log("-> ".$msg, $options_ref);
}
sub _exit {
    my ($msg, $options_ref) = @_;
    _log("<- ".$msg, $options_ref);
}
sub _debug {
    my ($msg, $options_ref) = @_;
    if (ref($options_ref) eq "HASH") {
        my %options = %{ $options_ref };
        if (not(exists($options{OPTION_APPEND})) || $options{OPTION_APPEND} == FALSE) {
            $msg = "   ".$msg;
        }
    } else {
        $msg = "   ".$msg;
    }
    _log($msg, $options_ref);
}
sub _enterExit {
    my ($msg, $options_ref) = @_;
    _log("<> ".$msg, $options_ref);
}

sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }


sub stringify_bool {
    return ($_[0] ? "TRUE" : "FALSE");
}
sub stringify_hash {
    my ($hash_ref, $msg) = @_;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    my $str = Dumper(%$hash_ref);
    if (length($str) > 40) {
        $str = substr($str, 0, 40);
    }
    return "$str";
}


# get_bggxml_json - fetches bggxml for all users/types
#  -in: $json_hash_ref - reference to hash in which bgg xml will be stored
#           $json_hash_ref->{$user}->{$type} = "bggxml"
#       $args_hash_ref - reference to hash of parsed command line arguments
# -out: TRUE if all bggxml is successfully retrieved; FALSE otherwise 
sub get_bggxml_json {
    my ($rc, $url, $requests_ref, $responses_ref, $request_hash_ref, $response_hash_ref, @users, @subtypes, $user, $subtype, $temp_hash_ref, $i, $j);
    
    _enter("get_bggxml_json");

    $rc = TRUE;
    @users = keys %{ USERS_TO_OWNERS() };
    @subtypes = @{ SUBTYPES() };
    $requests_ref = [];
    $responses_ref = [];

    for ($i=0; $rc && $i < scalar(@users); $i++) {
        $user = $users[$i];
        _debug("get_bggxml_json: user ${user}...");

        $json_hash_ref->{$user} = {};

        for ($j=0; $rc && $j < scalar(@subtypes); $j++) {
            $subtype = $subtypes[$j];

            $url = "https://www.boardgamegeek.com/xmlapi2/collection?username=${user}";
            if ($subtype eq "played") {
                $url .= "&played=1&subtype=boardgame&stats=1";
            } elsif ($subtype eq "prevowned") {
                $url .= "&prevowned=1&subtype=boardgame&stats=1";
            } else {
                $url .= "&own=1&subtype=${subtype}&stats=1";
            }

            if ($args_hash_ref->{ARG_SKIP_BGGXML}) {
                # skip fetching bggxml files, load from file intead
                $temp_hash_ref = json_hash_from_file("${user}.${subtype}");
                _debug("get_bggxml_json:   loaded $subtype from file");
            } else {
                $request_hash_ref = {};
                $request_hash_ref->{"user"} = $user;
                $request_hash_ref->{"subtype"} = $subtype;
                $request_hash_ref->{"id"} = "$user.$subtype";
                $request_hash_ref->{"url"} = $url;
                $request_hash_ref->{"file"} = "${user}.${subtype}";
                push(@{$requests_ref}, $request_hash_ref); 
            }
        }
    }

    if ($args_hash_ref->{ARG_SKIP_BGGXML}) {
        $rc = TRUE;
        _exit("get_bggxml_json: $rc");
        return $rc;
    }


    ($rc, $responses_ref) = &fetch_bggxml_json($requests_ref);


    for ($i=0; $rc && $i < scalar(@{$responses_ref}); $i++) {
        $response_hash_ref = @{$responses_ref}[$i];
        $user = $response_hash_ref->{"request"}->{"user"};
        $subtype = $response_hash_ref->{"request"}->{"subtype"};
        $temp_hash_ref = $response_hash_ref->{"data"};

        #_debug("get_bggxml_json: response");
        #_debug("get_bggxml_json:    user: $user");
        #_debug("get_bggxml_json:    subtype: $subtype");
        #_debug("get_bggxml_json:    data: $temp_hash_ref");
        #_debug("get_bggxml_json:    data->items: ".$temp_hash_ref->{"items"});
        if (defined($temp_hash_ref)) {
            $json_hash_ref->{$user}->{$subtype} = $temp_hash_ref;
        } else {
            #_debug("get_bggxml_json: $subtype not fetched for user $user");
        }
    }

    _exit("get_bggxml_json: $rc");
    return $rc;
}


# get_bgg_things_json - fetches bgg collections for all users
#  -in: $json_hash_ref - reference to hash in which bgg xml will be stored
#           $json_hash_ref->{$user}->{"collection"} = "bggxml"
#       $args_hash_ref - reference to hash of parsed command line arguments
# -out: TRUE if all bggxml is successfully retrieved; FALSE otherwise 
sub get_bgg_things_json {
    my ($objectids_ref, $label) = @_;
    my ($rc, $collection_hash_ref, $item_hash_ref, @users, $user, $owner, @allobjectids, $objectid_count, @objectids, $objectid, $name, $own, $prevowned, $url, @allthings, $things_hash_ref, $i, $j, $batch_size);
    my ($requests_ref, $request_hash_ref, $responses_ref, $response_hash_ref);

    _enter("get_bgg_things_json($label)");

    $rc = TRUE;
    $j = 0;
    @allobjectids = @{$objectids_ref};
    $requests_ref = [];
    $responses_ref = [];

    if ($args_hash_ref->{ARG_SKIP_THINGS}) {
        $things_hash_ref = json_hash_from_file("bgg.$label");
        _debug("get_bgg_things_json: skipped; loaded from file - bgg.$label: ".scalar(@{$things_hash_ref->{"things"}}));

        @allobjectids = @{$objectids_ref};
        foreach my $bggitem_ref (@{$things_hash_ref->{"things"}}) {
            my $objectid = $bggitem_ref->{'@id'};
            my ($index) = grep { @allobjectids[$_] eq $objectid } 0..$#allobjectids;
            if (defined $index) {
                splice(@allobjectids, $index, 1);
            }
        }

        _debug("get_bgg_things_json: ".scalar(@allobjectids)." missing $label [@{allobjectids}]");
        $objectid_count = scalar(@allobjectids);
        $batch_size = 50;

        if ($objectid_count == 0) {
            _exit("get_bgg_things_json");
            return $things_hash_ref->{"things"};
        }

        @allthings = @{$things_hash_ref->{"things"}};
    } else {
        $objectid_count = scalar(@allobjectids);
        $batch_size = $args_hash_ref->{ARG_PRODUCTION} ? 50 : 2;
        @allthings = ();
    }

    _debug("get_bgg_things_json: \$batch_size [$batch_size] \$objectid_count [$objectid_count]");

    for ($i=0; $rc && $i < $objectid_count; $i++) {
        my $objectid = $allobjectids[$i];
        if ($i % $batch_size == 0) {
            @objectids = ();
        }
        push(@objectids, $objectid);

        if ($i % $batch_size == ($batch_size-1) || $i == ($objectid_count-1)) {
            #https://www.boardgamegeek.com/xmlapi2/thing?stats=1&id=41114,... 50 max ids 
            $url = "https://www.boardgamegeek.com/xmlapi2/thing?stats=1&id=".join(",", @objectids);
            #_debug("get_bgg_things_json: \$url = $url");

            $request_hash_ref = {};
            $request_hash_ref->{"id"} = "${label}_$j";
            $request_hash_ref->{"url"} = $url;
            $request_hash_ref->{"file"} = "${label}_$j";
            $j++;
            push(@$requests_ref,$request_hash_ref);
        }
    }

    ($rc, $responses_ref) = &fetch_bggxml_json($requests_ref);


    for ($i=0; $rc && $i < scalar(@{$responses_ref}); $i++) {
        $response_hash_ref = @{$responses_ref}[$i];
        $things_hash_ref = $response_hash_ref->{"data"};

        if (defined($things_hash_ref)) {
            #_debug("get_bgg_things_json: DEFINED");
            _debug("get_bgg_things_json: pre push size: ".@allthings." \$rc [".stringify_bool($rc)."]");
            #_debug("get_bgg_things_json: ref(item) ".ref($things_hash_ref->{"items"}->{"item"}));
            if (ref($things_hash_ref->{"items"}->{"item"}) eq "HASH") {
                my @temp;
                push(@temp, $things_hash_ref->{"items"}->{"item"});
                push(@allthings, @temp);
            } elsif (ref($things_hash_ref->{"items"}->{"item"}) eq "ARRAY") {
                push(@allthings, @{$things_hash_ref->{"items"}->{"item"}});
            }
            if (not($args_hash_ref->{ARG_PRODUCTION})) {
                $rc = FALSE;
                _debug("get_bgg_things_json: not production; only fetching one batch");
            }
            _debug("get_bgg_things_json: post push size: ".@allthings." \$rc [".stringify_bool($rc)."]");
        }
    }

    $things_hash_ref = {
        "things" => \@allthings
    };
    if (not($args_hash_ref->{ARG_SKIP_THINGS})) {
        json_hash_to_file($things_hash_ref, "bgg.$label");
    }

    _exit("get_bgg_things_json: things count: ".@{$things_hash_ref->{"things"}});
    return $things_hash_ref->{"things"};
}


# fetch_bggxml_json - fetches bgg collections for all users
#  -in: $requests_ref - reference to an array of request hashes; ech request hash must define an
#           id, url, and file properties
# -out: list of two values:
#       $rc - return code; TRUE if all bggxml is successfully retrieved; FALSE otherwise
#       $responses_ref - reference to an array of response objects with the following properties:
#           request - reference to its passed request hash
#           data - json strong response data if successful
sub fetch_bggxml_json {
    my ($requests_ref) = @_;
    my ($totalTodo, $totalDone, $request_hash_ref, $id, $url, $file, $content);
    my ($responses_ref, $response_hash_ref, $rc, $temp_json_hash_ref, $skip_http, $error, $ua, $response, $attempts, $max_attempts, $sleep, $i);
    
    _enter("fetch_bggxml_json");

    $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    $totalTodo = scalar(@{$requests_ref});
    $totalDone = 0;
    $responses_ref = [];
    $rc = TRUE;
    $skip_http = $args_hash_ref->{ARG_SKIP_HTTP};
    $error = $args_hash_ref->{ARG_ERROR};
    $max_attempts = ($skip_http ? 2 : 5);
    $sleep = ($skip_http ? 5 : 90)*1000000;

    foreach $request_hash_ref (@{$requests_ref}) {
        $url = $request_hash_ref->{"url"};
        $response_hash_ref = {};
        $response_hash_ref->{"request"} = $request_hash_ref;
        $response_hash_ref->{"done"} = FALSE;
        push(@{$responses_ref}, $response_hash_ref);
    }

    $attempts = 0; 
    while ($attempts < $max_attempts && $totalTodo != $totalDone) {
        $attempts += 1;
        _debug("fetch_ bggxml_json: start attempt ${attempts}/${max_attempts}");
        if ($attempts != 1) {
            usleep($sleep);
        }

        $i = -1;
        foreach $request_hash_ref (@{$requests_ref}) {
            $i++;
            $id = $request_hash_ref->{"id"};
            $url = $request_hash_ref->{"url"};
            $file = $request_hash_ref->{"file"};
            $response_hash_ref = @{$responses_ref}[$i];

            if (not($response_hash_ref->{"done"})) {
                _debug("fetch_ bggxml_json:   getting ${id}...", LOG_NONEWLINE);
                $response = $skip_http ? undef : $ua->get($url);
                $response_hash_ref->{"response"} = $response;

                if (not($skip_http) && $response->code == HTTP::Status->HTTP_OK) {
                    _debug("done", LOG_APPEND);
                    $response_hash_ref->{"done"} = TRUE;
                    $totalDone += 1;

                    $content = $response->decoded_content;
                    $response_hash_ref->{"data"} = JSON->new->utf8(1)->decode($XML2JSON->convert($content));
                    #json_hash_to_file($response_hash_ref->{"data"}, $file);
                } elsif ($skip_http && not($error)) { #&& int(rand(2)) == 1) {
                    _debug("done (skipped)", LOG_APPEND);
                    $response_hash_ref->{"done"} = TRUE;
                    $totalDone += 1;
                } else {
                    _debug($skip_http ? "skipped" : ($response->code == HTTP::Status->HTTP_ACCEPTED ? "accepted" : "???"), LOG_APPEND);
                    $rc = FALSE;
                }
            }
        }
        _debug("fetch_ bggxml_json: end attempt ${attempts}/${max_attempts}");
    }

    $rc = TRUE;
    if ($totalTodo != $totalDone) {
        _debug("fetch_ bggxml_json: FAILED requests");
        $i = -1;
        foreach $request_hash_ref (@{$requests_ref}) {
            $i++;
            $id = $request_hash_ref->{"id"};
            $response_hash_ref = @{$responses_ref}[$i];

            if (not($response_hash_ref->{"done"})) {
                _debug("fetch_ bggxml_json:   ${id}");
                $rc = FALSE;
            }
        }
    }

    _exit("fetch_bggxml_json: ".($rc ? "success" : "FAILED")." ($attempts/$max_attempts)");
    return ($rc, $responses_ref);
}


sub json_hash_to_file {
    my ($hash_ref, $name) = @_;
    my $file = "$dir/data/$name.json";

    open OUT_FH, ">$file" or die "$file ".$!;
    print OUT_FH encode_json($hash_ref);
    close OUT_FH;

    open OUT_FH, ">$file.pretty" or die "$file.pretty ".$!;
    print OUT_FH JSON->new->utf8(1)->pretty(1)->encode($hash_ref);
    close OUT_FH;
}


sub json_hash_from_file {
    my ($name, $subdir) = @_;
    if (not(defined($subdir))) {
        $subdir = "/data";
    }
    my $file = "$dir/$subdir/$name.json";
    my ($json, $hash_ref);

    open IN_FH, "<$file" or die "$file ".$!;
    $json = join '', <IN_FH>;
    close IN_FH;
    #print $json;
    
    $hash_ref = JSON->new->decode($json);
    #_enterExit("json_hash_from_file($name): hash keys [".keys(%$hash_ref)."]");
    return $hash_ref;
}


sub get_owners {
    my ($owners_ref, $owner, $owns) = @_;
    #_enter("get_owners([".stringify($owners_ref)."], $owner, $owns)");
    if ($owner ne "played") {
        my $e = $owners_ref->{$owner};
        if ($owns) {
            $owners_ref->{$owner} = TRUE;
        } else {
            delete $owners_ref->{$owner}
        }
    }
    #_exit("get_owners([".stringify($owners_ref)."], $owner, $owns): $a");
}


sub process_user {
    my ($user, $users_hash_ref) = @_;

    _enter("process_user($user)");

    my %items_hash = %$items_hash_ref;
    my ($type, $owner, @items, $item_hash_ref, $objectid, $subtype, $own, $name, $minplayers, $maxplayers, $playingtime, $minplaytime, $maxplaytime, $numplays, $image, $thumbnail, $yearpublished);
    my (@subtypes, @bggitems, %bggitem, $bggitem_ref);
    $owner = USERS_TO_OWNERS->{$user};

    @subtypes = @{ SUBTYPES() };
    foreach $type (@subtypes) {
        #_debug("process_user: \$type [$type]");

        if (not(exists $users_hash_ref->{$type}->{"items"}->{"item"})) {
            _debug("process_user: $type items not found");
            next;
        }
        
        @bggitems = @{ $users_hash_ref->{$type}->{"items"}->{"item"} };
        _debug("process_user: \$type [$type] \@bggitems [".@bggitems."]");

        my $i = 0;
        foreach $bggitem_ref (@bggitems) {
            %bggitem = %$bggitem_ref;
            
            # reset key values
            $i += 1;
            $name = $bggitem{"name"}->{'$t'};
            $own = ($bggitem{"status"}->{'@own'} eq "1");
            $objectid = $bggitem{'@objectid'};
            $subtype = $bggitem{'@subtype'};
            $numplays = $type eq "played" ? int($bggitem{"numplays"}->{'$t'}) : -1;
            $minplayers = int($bggitem{"stats"}->{'@minplayers'});
            $maxplayers = int($bggitem{"stats"}->{'@maxplayers'});
            $playingtime = defined($bggitem{"stats"}->{'@playingtime'}) ? int($bggitem{"stats"}->{'@playingtime'}) : -1;
            $minplaytime = defined($bggitem{"stats"}->{'@minplaytime'}) ? int($bggitem{"stats"}->{'@minplaytime'}) : -1;
            $maxplaytime = defined($bggitem{"stats"}->{'@maxplaytime'}) ? int($bggitem{"stats"}->{'@maxplaytime'}) : -1;
            $image = $bggitem{"image"}->{'$t'};
            $thumbnail = $bggitem{"thumbnail"}->{'$t'};
            $yearpublished = int($bggitem{"yearpublished"}->{'$t'});

            if ($minplayers == 0 && $maxplayers != 0) {
                $minplayers = $maxplayers;
            }
            if ($maxplayers == 0 && $minplayers != 0) {
                $maxplayers = $minplayers;
            }

            if ($minplaytime == -1) {
                if ($maxplaytime != -1) {
                    $minplaytime = $maxplaytime;
                } else {
                    $minplaytime = $playingtime;
                }
            }
            if ($maxplaytime == -1) {
                if ($minplaytime != -1) {
                    $maxplaytime = $minplaytime;
                } else {
                    $maxplaytime = $playingtime;
                }
            }

            $item_hash_ref = $items_hash{$objectid};
            if (exists $items_hash{$objectid}) {
                if ($numplays != -1) {
                    $item_hash_ref->{&ITEM_KEY_NUMPLAYS}->{$owner} = $numplays;
                } else {
                    get_owners($item_hash_ref->{&ITEM_KEY_OWNERS}, $owner, $own);
                    if ($subtype eq "boardgameexpansion" && $item_hash_ref->{&ITEM_KEY_SUBTYPE} ne "boardgameexpansion") {
                        $item_hash_ref->{&ITEM_KEY_SUBTYPE} = $subtype;
                    }
                }
            } else {
            #} elsif ($type eq "boardgame" || $type eq "boardgameexpansion") {
                my $owners_ref = {};
                get_owners($owners_ref, $owner, $own);

                $item_hash_ref = {
                    &ITEM_KEY_SUBTYPE       => $subtype,
                    &ITEM_KEY_NAME          => $name,
                    &ITEM_KEY_EXPANSIONS    => {},
                    &ITEM_KEY_MINPLAYERS    => $minplayers,
                    &ITEM_KEY_MAXPLAYERS    => $maxplayers,
                    &ITEM_KEY_MINPLAYTIME   => $minplaytime,
                    &ITEM_KEY_MAXPLAYTIME   => $maxplaytime,
                    &ITEM_KEY_NUMPLAYS      => {},
                    &ITEM_KEY_OWNERS        => $owners_ref,
                    &ITEM_KEY_IMAGE         => $image,
                    &ITEM_KEY_THUMBNAIL     => $thumbnail,
                    &ITEM_KEY_YEARPBLISHED  => $yearpublished
                };

                if ($numplays != -1) {
                    $item_hash_ref->{&ITEM_KEY_NUMPLAYS}->{$owner} = $numplays;
                }

                #_debug("process_user: \$name [$name]");
                #_debug("process_user: \$items_hash_ref: ".stringify_hash($item_hash_ref));

                $items_hash_ref->{$objectid} = $item_hash_ref;
            }
        } #foreach @bggitems
    } # foreach @types

    _exit("process_user");
}


# process_things - using the last-fetched list of all things, update items with
#     properties only defined by the things (description, subtype, expands,
#     weight, best/recommended stats)
#  -in: $json_hash_ref - reference to hash in which bgg xml will be stored
#           $json_hash_ref->{$user}->{"collection"} = "bggxml"
#       $args_hash_ref - reference to hash of parsed command line arguments
# -out: TRUE if all bggxml is successfully retrieved; FALSE otherwise 
sub process_things {
    my ($things_ref, $compilations) = @_;

    _enter("process_things: ".($compilations ? "compilations" : ""));

    my %items_hash = %$items_hash_ref;
    my ($item_hash_ref, $objectid, $name, $update);
    my (%bggitem, $bggitem_ref);
    my ($ratings_hash_ref, $ranks_ref, $boardgame_rank_ref, $rank, $rank_hash_ref);
    my (@bestplayers, @recplayers, $total, $votes, $best, $rec, $np, $poll_hash_ref, $temp_hash_ref, $result_hash_ref, $playercount_result_hash_ref, $key, $np);

    _debug("process_things: bggitems ".@{$things_ref});

    my $i = 0;
    foreach $bggitem_ref (@$things_ref) {
        $i += 1;
        $objectid = $bggitem_ref->{'@id'};
        if ($compilations) {
            $objectid = $comp_ids_hash_ref->{$objectid};
        }
        $item_hash_ref = $items_hash{$objectid};
        $name = $item_hash_ref->{&ITEM_KEY_NAME};

        $ratings_hash_ref = $bggitem_ref->{"statistics"}->{"ratings"};

        # bgg rank; ratings>ranks>rank object may be an array of ranks or a single rank
        $boardgame_rank_ref = undef;
        $ranks_ref = $ratings_hash_ref->{"ranks"}->{"rank"};
        if (ref($ranks_ref) eq "HASH") {
            if ($ranks_ref->{'@name'} eq "boardgame") {
                $boardgame_rank_ref = $ranks_ref;
            }
        } else {
            for $rank_hash_ref (@{$ranks_ref}) {
                if ($rank_hash_ref->{'@name'} eq "boardgame") {
                    $boardgame_rank_ref = $rank_hash_ref;
                }
            }
        }

        $rank = -1;
        if (defined($boardgame_rank_ref)) {
            $rank = $boardgame_rank_ref->{'@value'};
            if ($rank eq "Not Ranked") {
                $rank = -1;
            } else {
                $rank = $rank + 0;
            }
        }
        if ($compilations) {
            $update = "compilation id [$objectid] name [$name] rank [".$item_hash_ref->{&ITEM_KEY_RANK}." -> $rank]"; 
        }
        $item_hash_ref->{&ITEM_KEY_RANK} = $rank;
        #end bgg rank

        # weight (averageweight), bgg rating (average)
        my ($curWeight, $curRating, $weight, $rating);
        $curWeight = defined($item_hash_ref->{&ITEM_KEY_WEIGHT}) ? $item_hash_ref->{&ITEM_KEY_WEIGHT} : -1;
        $curRating = defined($item_hash_ref->{&ITEM_KEY_RATING}) ? $item_hash_ref->{&ITEM_KEY_RATING} : -1;
        $weight = $ratings_hash_ref->{"averageweight"}->{'@value'}+0;
        $rating = $ratings_hash_ref->{"average"}->{'@value'}+0;
        if ($curWeight < $weight) { $item_hash_ref->{&ITEM_KEY_WEIGHT} = $weight; $update .= " weight [$curWeight -> $weight]"; }
        if ($curRating < $rating) { $item_hash_ref->{&ITEM_KEY_RATING} = $rating; $update .= " rating [$curRating -> $rating]"; }

        # only process rank/weight/rating for compilations
        if ($compilations) {
            _debug($update); 
            next;
        }

        $item_hash_ref->{&ITEM_KEY_DESCRIPTION} = $bggitem_ref->{"description"}->{'$t'};
        $item_hash_ref->{&ITEM_KEY_SUBTYPE} = $bggitem_ref->{'@type'};

        if ($item_hash_ref->{&ITEM_KEY_SUBTYPE} eq "boardgameexpansion") {
            for my $link_ref (@{$bggitem_ref->{"link"}}) {
                if ($link_ref->{'@type'} eq "boardgameexpansion") {
                    $item_hash_ref->{&ITEM_KEY_EXPANDS} = $link_ref->{'@id'};
                    #if ($i < 10) {
                    #    _debug("process_things: $objectid ".$item_hash_ref->{&ITEM_KEY_NAME}." expands ".$item_hash_ref->{&ITEM_KEY_EXPANDS}." ".$item_hash_ref->{$item_hash_ref->{&ITEM_KEY_EXPANDS}}->{&ITEM_KEY_NAME});
                    #}
                }
            }
        }

        # best/recommended
        $poll_hash_ref = undef;
        for $temp_hash_ref (@{$bggitem_ref->{"poll"}}) {
            if ($temp_hash_ref->{'@name'} eq "suggested_numplayers") {
                $poll_hash_ref = $temp_hash_ref;
            }
        }
        if (defined($poll_hash_ref) && ref($poll_hash_ref->{"results"}) eq "ARRAY") {
            $item_hash_ref->{&ITEM_KEY_BEST_NUMPLAYERS} = ();
            $item_hash_ref->{&ITEM_KEY_RECOMMENDED_NUMPLAYERS} = ();
            #if ($objectid eq "11") { _debug("VOTES: >> total = $total"); }
            #_debug("process_things: $objectid ref(\$poll_hash_ref->{\"results\"}) [".ref($poll_hash_ref->{"results"})."]");
            for $playercount_result_hash_ref (@{$poll_hash_ref->{"results"}}) {
                $np = $playercount_result_hash_ref->{'@numplayers'};
                #if ($objectid eq "11") { _debug("VOTES:    \$np = $np"); }
                # ignore the n+ vote counts; int("5+") eq "5+" returns false
                if (int($np) eq $np) {
                    $np = int($np);
                    $total = 0;
                    $best = 0;
                    $rec = 0;
                    for my $result_hash_ref (@{$playercount_result_hash_ref->{"result"}}) {
                        $votes = int($result_hash_ref->{'@numvotes'});
                        $total += $votes;
                        if ($result_hash_ref->{'@value'} eq "Best") {
                            $best = $votes;
                        } elsif ($result_hash_ref->{'@value'} eq "Recommended") {
                            $rec = $votes;
                        }
                    }
                    #if ($objectid eq "11") { _debug("VOTES:       $key: best (\$best > (\$total/2)) ? ($best > (".($total/2).")) ? ".stringify_bool($best > ($total/2))); }
                    #if ($objectid eq "11") { _debug("VOTES:       $key: rec  (\$rec > (\$total/2)) ? ($rec > (".($total/2).")) ? ".stringify_bool($rec > ($total/2))); }
                    if ($best >= ($total/2)) {
                        push(@{$item_hash_ref->{&ITEM_KEY_BEST_NUMPLAYERS}}, $np);
                        push(@{$item_hash_ref->{&ITEM_KEY_RECOMMENDED_NUMPLAYERS}}, $np);
                    } elsif ($rec >= ($total/2)) {
                        push(@{$item_hash_ref->{&ITEM_KEY_RECOMMENDED_NUMPLAYERS}}, $np);
                    }
                }
            }
            #if ($objectid eq "11") { _debug("VOTES:    best: ".join(',', @bestplayers)); }
            #if ($objectid eq "11") { _debug("VOTES:    rec:  ".join(',', $recplayers)); }
            #if ($objectid eq "11") { _debug("VOTES: <<"); }
        }
        #end best/recommended

        #compilations (big box games)
        if ($rank == -1 && $item_hash_ref->{&ITEM_KEY_SUBTYPE} eq "boardgame") {
            my ($base_game_id, $base_game_name, $link_hash_ref);
            $base_game_id = undef;
            $base_game_name = undef;
            for $link_hash_ref (@{$bggitem_ref->{"link"}}) {
                if ($link_hash_ref->{'@type'} eq "boardgamecompilation") {
                    if (not(defined($base_game_id)) || $base_game_id > int($link_hash_ref->{'@id'})) {
                        $base_game_id = int($link_hash_ref->{'@id'});
                        $base_game_name = $link_hash_ref->{'@value'};
                    }
                }
            }
            if (defined($base_game_id)) { # && $objectid eq "11") {
                $comp_ids_hash_ref->{$base_game_id} = $objectid;
                _debug("process_things: item id [$objectid] name [".$item_hash_ref->{&ITEM_KEY_NAME}."] contains id [$base_game_id] name [$base_game_name]"); 
            }
        }
        #end compilations
    } #foreach @$things_ref

    if (!$compilations) {
        _debug("process_things: compilation count (".keys(%$comp_ids_hash_ref).")");
    }

    _exit("process_things");
}


sub process_expansions {
    my (@allobjectids, $objectid, $updated, $updates, $base_item_ref, $exp_item_ref, $str, $name, $i, $j);
    my ($base_minplayers, $base_maxplayers, $base_minplaytime, $base_maxplaytime);
    my ($exp_minplayers, $exp_maxplayers, $exp_minplaytime, $exp_maxplaytime);

    _enter("process_expansions(".keys(%$items_hash_ref).")");

    @allobjectids = keys(%$items_hash_ref);
    $j = 0;
    $updates = 0;
    my $objectid_count = scalar(@allobjectids);
    for ($i=0; $i < $objectid_count; $i++) {
        $objectid = $allobjectids[$i];

        if (not(exists($items_hash_ref->{$objectid}))) {
            next;
        }

        $exp_item_ref = $items_hash_ref->{$objectid};
        $base_item_ref = undef;
        $updated = FALSE;

        if ($exp_item_ref->{&ITEM_KEY_SUBTYPE} ne "boardgameexpansion") {
            next;
        }

        if (exists($exp_item_ref->{"expands"})) {
            $base_item_ref = $items_hash_ref->{$exp_item_ref->{"expands"}};
        }

        if (not(defined($base_item_ref))) {
            next;
        }

        $name = $base_item_ref->{&ITEM_KEY_NAME};
        $base_minplayers  = $base_item_ref->{&ITEM_KEY_MINPLAYERS };
        $base_maxplayers  = $base_item_ref->{&ITEM_KEY_MAXPLAYERS };
        $base_minplaytime = $base_item_ref->{&ITEM_KEY_MINPLAYTIME};
        $base_maxplaytime = $base_item_ref->{&ITEM_KEY_MAXPLAYTIME};
        $exp_minplayers   =  $exp_item_ref->{&ITEM_KEY_MINPLAYERS };
        $exp_maxplayers   =  $exp_item_ref->{&ITEM_KEY_MAXPLAYERS };
        $exp_minplaytime  =  $exp_item_ref->{&ITEM_KEY_MINPLAYTIME};
        $exp_maxplaytime  =  $exp_item_ref->{&ITEM_KEY_MAXPLAYTIME};

        if ( ($exp_minplayers != -1  && $base_minplayers  > $exp_minplayers )
          || ($exp_maxplayers != -1  && $base_maxplayers  < $exp_maxplayers ) 
          || ($exp_minplaytime != -1 && $base_minplaytime < $exp_minplaytime) 
          || ($exp_maxplaytime != -1 && $base_maxplaytime > $exp_maxplaytime) )
        {
            $updated = TRUE;
        } else {
        }

        $base_item_ref->{&ITEM_KEY_EXPANSIONS}->{$objectid} = TRUE;
        if ($updated) {
            $updates++;
            $base_item_ref->{&ITEM_KEY_MINPLAYERS };
            $base_item_ref->{&ITEM_KEY_MAXPLAYERS };
            $base_item_ref->{&ITEM_KEY_MINPLAYTIME};
            $base_item_ref->{&ITEM_KEY_MAXPLAYTIME};
            #_debug("process_expansions: added stats to base game $name for expansion " . $exp_item_ref->{&ITEM_KEY_NAME});
            #_debug("process_expansions:     ${base_minplayers}-${base_maxplayers}p ${base_minplaytime}-${base_maxplaytime}min");
            #_debug("process_expansions:     ${exp_minplayers}-${exp_maxplayers}p ${exp_minplaytime}-${exp_maxplaytime}min");
        }
    }
    _exit("process_expansions: $updates updates");
};# end process_expansions


sub process_pictures {
    my ($pictures_hash_ref, $picture_hash_ref, $item_hash_ref, @allobjectids, $objectid, $objectid_count, $updates, $i);

    _enter("process_pictures(".keys(%$items_hash_ref).")");

    $pictures_hash_ref = json_hash_from_file("pictures", "");

    my $pictureless_ref = {};
    @allobjectids = keys(%$pictures_hash_ref);
    $updates = 0;
    $objectid_count = scalar(@allobjectids);
    #_debug("process_pictures: \$objectid_count = $objectid_count");

    for ($i=0; $i < $objectid_count; $i++) {
        $objectid = $allobjectids[$i];

        if (not(exists($items_hash_ref->{$objectid}))) {
            next;
        }
        $item_hash_ref = $items_hash_ref->{$objectid};
        $picture_hash_ref = $pictures_hash_ref->{$objectid};

        if ($picture_hash_ref->{"id"} eq "") {
            $pictureless_ref->{$objectid} = "1";
        } else {
            $item_hash_ref->{&ITEM_KEY_PICTURE} = $picture_hash_ref->{"id"};
            if (exists($picture_hash_ref->{"ext"})) {
                $item_hash_ref->{&ITEM_KEY_PICTURE_EXT} = $picture_hash_ref->{"ext"};
            }
            $updates++;
            #_debug("process_pictures: added picture ".$pictures_hash_ref->{$objectid}." for $objectid");
        }
    }
    
    _debug("process_pictures: $updates updates");

    @allobjectids = keys(%$items_hash_ref);
    $objectid_count = scalar(@allobjectids);
    for ($i=0; $i < $objectid_count; $i++) {
        $objectid = $allobjectids[$i];
        if (not(exists($pictureless_ref->{$objectid}))) {
            $item_hash_ref = $items_hash_ref->{$objectid};

            if ( $item_hash_ref->{&ITEM_KEY_SUBTYPE} eq "boardgame"
              && exists($item_hash_ref->{&ITEM_KEY_OWNERS})
              && not(exists($item_hash_ref->{&ITEM_KEY_PICTURE})) ) 
            {
                _debug("process_pictures: Missing picture for $objectid ".$item_hash_ref->{&ITEM_KEY_NAME});
            }
        }
    }

    _exit("process_pictures");
};# end process_pictures


sub process_prevowned {
    my ($prevowned_items_ref, $owner) = @_;
    _enter("process_prevowned(".keys(%$items_hash_ref).",".@$prevowned_items_ref.",$owner)");

    my ($prevowned_item_ref, $item_hash_ref, $objectid);

    # loop over prevowned items objects
    for $prevowned_item_ref (@$prevowned_items_ref) {
        $objectid = $prevowned_item_ref->{'@objectid'};
        if (exists $items_hash_ref->{$objectid}) {
            $item_hash_ref = $items_hash_ref->{$objectid};
            #_debug("process_prevowned: ".$item_hash_ref->{&ITEM_KEY_NAME});
            my $owners_ref = $item_hash_ref->{&ITEM_KEY_OWNERS};
            my $prevowners_ref;
            if (exists $item_hash_ref->{&ITEM_KEY_PREVOWNERS}) {
                $prevowners_ref = $item_hash_ref->{&ITEM_KEY_PREVOWNERS};
            } else {
                $prevowners_ref = {};
                $item_hash_ref->{&ITEM_KEY_PREVOWNERS} = $prevowners_ref;
            }
            #_debug("process_prevowned: BEFORE owners = [".stringify($owners_ref)."]");
            #_debug("process_prevowned: BEFORE prevowners = [".stringify($prevowners_ref)."]");
            get_owners($prevowners_ref, $owner, TRUE);
            get_owners($item_hash_ref->{&ITEM_KEY_OWNERS}, $owner, FALSE);
            #_debug("process_prevowned: AFTER  owners = [".stringify($owners_ref)."]");
            #_debug("process_prevowned: AFETR  prevowners = [".stringify($prevowners_ref)."]");
        }
    }

    _exit("process_prevowned");
}# end process_prevowned


sub bggxml_to_items {
    if ($args_hash_ref->{ARG_SKIP_ITEMS}) {
        $items_hash_ref = json_hash_from_file("items");
        _enterExit("bggxml_to_items: skipped; items loaded [".keys(%$items_hash_ref)."]");
        _debug("weird chars???? ".$items_hash_ref->{"153242"}->{&ITEM_KEY_NAME});
        return;
    }

    _enter("bggxml_to_items");

    foreach my $user (keys %$json_hash_ref) {
        _debug("bggxml_to_items: user: $user...");
        process_user($user, $json_hash_ref->{"$user"});
    }
    _debug("bggxml_to_items: ".(keys %$items_hash_ref));

    foreach my $user (keys %$json_hash_ref) {
        if (exists $json_hash_ref->{"$user"}->{"prevowned"}->{"items"}->{"item"}) {
            process_prevowned($json_hash_ref->{"$user"}->{"prevowned"}->{"items"}->{"item"}, USERS_TO_OWNERS->{$user});
        }
    }

    process_things(get_bgg_things_json([keys(%$items_hash_ref)], "things"));
    process_things(get_bgg_things_json([keys(%$comp_ids_hash_ref)], "compilations"), TRUE);

    process_expansions();

    process_pictures();

    json_hash_to_file($items_hash_ref, "items");

    _exit("bggxml_to_items");
}


sub upload_to_firebase {
    my ($database, $secret, %user_data);

    _enter("upload_to_firebase");

    if (&DATABASE eq DATABASE_MOBYBEAVER) {
        _enter("upload_to_firebase: using mobybeaver-games");
        $database = "mobybeaver-games";
    } else {
        _enter("upload_to_firebase: using bgg-games");
        $database = "bgg-games";
    }

    # read db secret from file
    open IN_FH, "<$dir/firebase-secrets.txt"
        or die "Failed to open secrets file: $!\n";
    while (<IN_FH>) {
        if ( $_ =~ /^$database\=(.*)\n/ ) {
            $secret = $1;
        }
    }

    # HTTP::Message content must be bytes at C:/Perl64/lib/HTTP/Request/Common.pm line 95.
    # caused by XML2JSON->convert
    json_hash_to_file($items_hash_ref, "temp");
    $items_hash_ref = json_hash_from_file("temp");
 
    my $data_hash_ref = {};
    $data_hash_ref->{"items"}=$items_hash_ref;
    $data_hash_ref->{"time"}=time*1000;

    my $fb = Firebase->new(
        firebase => $database,
        auth => { 
            secret => $secret, 
            data => { 
                uid => 'xxx',
                username => 'fred' 
            }, 
            admin => \1
        }
    );
    _debug("upload_to_firebase: connected  \$fb = $fb");

    $fb->put('data', $data_hash_ref);

    _exit("upload_to_firebase");
}


sub parse_arguments {
    my ($production, $error, $skip_http, $skip_bggxml, $skip_things, $skip_items, $skip_firebase) = (FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);

    _enter("parse_arguments");

    # parse options
    GetOptions (
        "production" => \$production,
        "error"      => \$error,
        "http"       => \$skip_http,
        "bggxml"     => \$skip_bggxml,
        "things"     => \$skip_things,
        "items"      => \$skip_items,
        "firebase"   => \$skip_firebase
    ) or die("Error in command line arguments\n");

    if (!$skip_things) {
        _debug("parse_arguments: skipping things by default");
    }
    if ($skip_http && !$skip_firebase) {
        _debug("parse_arguments: auto-skipping firebase because HTTP requests are skipped");
        $skip_firebase = TRUE;
    }

    $args_hash_ref->{ARG_PRODUCTION}    = $production;
    $args_hash_ref->{ARG_ERROR}         = $error;
    $args_hash_ref->{ARG_SKIP_HTTP}     = $skip_http;
    $args_hash_ref->{ARG_SKIP_BGGXML}   = $skip_bggxml;
    $args_hash_ref->{ARG_SKIP_THINGS}   = !$skip_things;
    $args_hash_ref->{ARG_SKIP_ITEMS}    = $skip_items;
    $args_hash_ref->{ARG_SKIP_FIREBASE} = $skip_firebase;

    _exit("parse_arguments: "
        . "production [".stringify_bool($args_hash_ref->{ARG_PRODUCTION})."] "
        . "error [".stringify_bool($args_hash_ref->{ARG_ERROR})."] "
        . "skip_http [".stringify_bool($args_hash_ref->{ARG_SKIP_HTTP})."] "
        . "skip_bggxml [".stringify_bool($args_hash_ref->{ARG_SKIP_BGGXML})."] "
        . "skip_things [".stringify_bool($args_hash_ref->{ARG_SKIP_THINGS})."] "
        . "skip_items [".stringify_bool($args_hash_ref->{ARG_SKIP_ITEMS})."] "
        . "skip_firebase: [".stringify_bool($args_hash_ref->{ARG_SKIP_FIREBASE})."]"
    );
}

sub main {
    open_log();
    _enter("main");

    parse_arguments();

    get_bggxml_json()
        or die "get_bggxml_json failed";
    bggxml_to_items();

    if (not($args_hash_ref->{ARG_SKIP_FIREBASE})) {
        # update database with new data
        upload_to_firebase();
    }

    _exit("main");
    close_log();
}


main();
1;