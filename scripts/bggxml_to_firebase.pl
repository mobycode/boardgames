#!C/user/bin/perl
use strict;

require LWP::UserAgent;
require HTTP::Status;
use Cwd;
use JSON;
use XML::XML2JSON;
use List::MoreUtils qw(first_index uniq);

use Data::Dumper;
use Scalar::Util qw(looks_like_number); # parseInt equalivent for bggxml numeric values
use Time::HiRes qw(time usleep); # get_time_stamp (time in microseconds), get_bgg_collection_json (sleep in microseconds)
use POSIX qw(strftime);          # get_time_stamp (easier time formatting)
use Firebase;                    # put data in firebase db
use Getopt::Long;
use Date::Calc qw(Days_in_Month);
use DateTime;
use DateTime::Format::Duration;

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
use constant ARG_MONTHS_OF_PLAYS => "months_of_plays";

use constant DATABASE_BGG => "DATABASE_BGG";
use constant DATABASE_MOBYBEAVER => "DATABASE_MOBYBEAVER";
use constant DATABASE => &DATABASE_BGG;

use constant SUBTYPES => [
#    "collection",
    "boardgame",
    "boardgameexpansion",
    "prevowned",
    "played"
];

use constant USERS_TO_OWNERS => {
    "mobybeaver" => "Justin",
    "flettz" => "Joe",
    "highexodus" => "Ian",
    "archleech" => "Jason",
    "BoardGameArena" => "BoardGameArena",
    "yucata" => "Yucata"
};

use constant PLAYS_USERS_TO_OWNERS => {
    "mobybeaver" => "Justin",
    "highexodus" => "Ian"
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
  use constant ITEM_KEY_LASTPLAYED => "lastplayed";
  use constant ITEM_KEY_OWNERS => "owners";
  use constant ITEM_KEY_PREVOWNERS => "prevowners";
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
sub get_time_stamp {
    my $t = time;
    my $ts = strftime("%Y%m%d %H:%M:%S", localtime($t));
    $ts .= sprintf(".%03d", ($t-int($t))*1000);
    return $ts;
}
sub get_month_and_year {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    return($mon+1,$year+1900);
}
sub get_previous_month_and_year {
    my ($month, $year) = @_;
    my ($previous_month, $previous_year) = ($month-1, $year);

    if ($month == 1) {
        $previous_month = 12;
        $previous_year = $year-1;
    }

    return ($previous_month, $previous_year);
}
sub get_months_ago {
    my ($date_string) = @_;
    my ($year, $month, $day, $then, $now, $duration, $months_ago);

    ($year, $month, $day) = ( $date_string =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)$/ );
    $year = int($year);
    $month = int($month);
    $day = int($day);

    $then = DateTime->new(year => $year, month => $month, day => $day, hour => 0, minute => 0, second => 0, time_zone  => 'UTC');
    $now = DateTime->now(time_zone  => 'UTC');
    $duration = $now - $then;
    $months_ago = ($duration->years() *12) + $duration->months();

    _debug("<> get_months_ago(${date_string}) = ${months_ago}");
    return $months_ago;
}
sub date_to_epoch {
    my ($date_string) = @_;
    my ($year, $month, $day);

    ($year, $month, $day) = ( $date_string =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)$/ );
    $year = int($year);
    $month = int($month);
    $day = int($day);

    return DateTime->new(year => $year, month => $month, day => $day, hour => 0, minute => 0, second => 0, time_zone  => 'UTC')->epoch();
}
sub _log {
    my ($msg, $options_ref) = @_;
    my %options = {};
    my $str = "$msg";
    my $time = get_time_stamp();

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
            } elsif ($subtype ne "collection") {
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
            if (not($args_hash_ref->{ARG_PRODUCTION})) {
                last;
            }
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


# get_bgg_plays_json - fetches bgg collections for all users
#  -in: $json_hash_ref - reference to hash in which bgg xml will be stored
#           $json_hash_ref->{$user}->{"collection"} = "bggxml"
#       $args_hash_ref - reference to hash of parsed command line arguments
# -out: TRUE if all bggxml is successfully retrieved; FALSE otherwise
sub get_bgg_plays_json {
    my ($objectids_ref, $label) = @_;
    my ($rc, $collection_hash_ref, $item_hash_ref, @users, $user, $owner, @allobjectids, $objectid_count, @objectids,
        $objectid, $name, $own, $prevowned, $url, $plays_hash_ref, $data_hash_ref, $month, $year, $end, $done,
        $month_count, $min_date, $max_date, $i, $j, $batch_size);
    my ($requests_ref, $request_hash_ref, $responses_ref, $response_hash_ref);

    _enter("get_bgg_plays_json($label)");

    $rc = TRUE;
    @users = keys %{ PLAYS_USERS_TO_OWNERS() };
    $requests_ref = [];
    $responses_ref = [];

    $plays_hash_ref = json_hash_from_file("plays");

    for ($i=0; $rc && $i < scalar(@users); $i++) {
        $user = $users[$i];
        _debug("get_bgg_plays_json: user ${user}...");

        if (not(defined($plays_hash_ref->{$user}))) {
            $plays_hash_ref->{$user} = {};
        }

        ($month, $year) = get_month_and_year();
        $end = FALSE;
        $month_count = 0;
        for ($j=0; $rc && $j < $args_hash_ref->{ARG_MONTHS_OF_PLAYS} && !$end; $j++) {
            if ($j != 0) {
                $month--;
                if ($month < 1) {
                     $month = 12;
                     $year--;
                }
            }

            $min_date = sprintf("%4s-%02s-01", $year, $month);
            $max_date = sprintf("%4s-%02s-%02s", $year, $month, Days_in_Month($year, $month));
            $url = "https://www.boardgamegeek.com/xmlapi2/plays?username=${user}&mindate=${min_date}&maxdate=${max_date}";
            $end = ($month == 11 && $year == 2013);
            #_debug("get_bggxml_json:   ${year} ${month} ${min_date} ${max_date} ".stringify_bool($end)." ...");

            $request_hash_ref = {};
            $request_hash_ref->{"id"} = "${user}_${min_date}";
            $request_hash_ref->{"user"} = $user;
            $request_hash_ref->{"min_date"} = $min_date;
            $request_hash_ref->{"url"} = $url;
            $request_hash_ref->{"file"} = "${user}_${min_date}";

            push(@$requests_ref,$request_hash_ref);
        }
    }

    ($rc, $responses_ref) = &fetch_bggxml_json($requests_ref);

    _debug("get_bgg_plays_json: request count: ".scalar(@{$requests_ref}));
    for ($i=0; $rc && $i < scalar(@{$responses_ref}); $i++) {
        $response_hash_ref = @{$responses_ref}[$i];
        $data_hash_ref = $response_hash_ref->{"data"};

        $request_hash_ref = @{$requests_ref}[$i];
        $user = $request_hash_ref->{"user"};
        $min_date = $request_hash_ref->{"min_date"};

        my $dataplays_ref = ();
        if (defined($data_hash_ref)) {
            if (ref($data_hash_ref->{"plays"}->{"play"}) eq "HASH") {
                push(@{$dataplays_ref}, $data_hash_ref->{"plays"}->{"play"});
            } else {
                $dataplays_ref = $data_hash_ref->{"plays"}->{"play"};
            }
            foreach my $dataplay_hash_ref (@{$dataplays_ref}) {
                my $id = $dataplay_hash_ref->{'@id'};
                my $date = $dataplay_hash_ref->{'@date'};
                my $objectid = $dataplay_hash_ref->{"item"}->{'@objectid'};
                if (not(exists($plays_hash_ref->{$user}->{$id}))) {
                    my $play_hash_ref = {};
                    $plays_hash_ref->{$user}->{$id} = $play_hash_ref;
                    $play_hash_ref->{"date"} = date_to_epoch($date);
                    $play_hash_ref->{"objectid"} = $dataplay_hash_ref->{"item"}->{'@objectid'};
                    #_debug("added $id: $date $objectid ".date_to_epoch($date));
                }
            }
        }
        #_debug("get_bgg_plays_json: $user $min_date plays: ".scalar(@{$dataplays_ref}));
    }

    foreach $user (@users) {
        _debug("get_bgg_plays_json: $user plays count: ".keys(%{$plays_hash_ref->{$user}}));
    }

    json_hash_to_file($plays_hash_ref, "plays");

    _exit("get_bgg_plays_json");
    return $plays_hash_ref;
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
    my ($responses_ref, $response_hash_ref, $rc, $temp_json_hash_ref, $skip_http, $error, $ua, $response, $attempts, $max_attempts, $sleep_s, $sleep_ms, $i);

    _enter("fetch_bggxml_json: request count: "+scalar @$requests_ref);

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
    $sleep_s= ($skip_http ? 5 : 90);
    $sleep_ms = $sleep_s*1000000;

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
        if ($attempts != 1) {
            _debug("fetch_bggxml_json: sleeping for ${sleep_s} seconds...");
            usleep($sleep_ms);
        }
        _debug("fetch_bggxml_json: start attempt ${attempts}/${max_attempts}");

        $i = -1;
        foreach $request_hash_ref (@{$requests_ref}) {
            $i++;
            $id = $request_hash_ref->{"id"};
            $url = $request_hash_ref->{"url"};
            $file = $request_hash_ref->{"file"};
            $response_hash_ref = @{$responses_ref}[$i];

            if (not($response_hash_ref->{"done"})) {
                _debug("fetch_bggxml_json:   getting ${id}...", LOG_NONEWLINE);
                $response = $skip_http ? undef : $ua->get($url);
                $response_hash_ref->{"response"} = $response;

                if (not($skip_http) && $response->code == HTTP::Status->HTTP_OK) {
                    _debug("done", LOG_APPEND);
                    $response_hash_ref->{"done"} = TRUE;
                    $totalDone += 1;

                    $content = $response->decoded_content;
                    $response_hash_ref->{"data"} = JSON->new->utf8(1)->decode($XML2JSON->convert($content));
                    json_hash_to_file($response_hash_ref->{"data"}, $file);
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
        _debug("fetch_bggxml_json: end attempt ${attempts}/${max_attempts}");
    }

    $rc = TRUE;
    if ($totalTodo != $totalDone) {
        _debug("fetch_bggxml_json: FAILED requests");
        $i = -1;
        foreach $request_hash_ref (@{$requests_ref}) {
            $i++;
            $id = $request_hash_ref->{"id"};
            $response_hash_ref = @{$responses_ref}[$i];

            if (not($response_hash_ref->{"done"})) {
                _debug("fetch_bggxml_json:   ${id}");
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
    #_enter("get_owners([".stringify_hash($owners_ref)."], $owner, $owns)");
    if ($owner ne "played") {
        my $e = $owners_ref->{$owner};
        if ($owns) {
            $owners_ref->{$owner} = TRUE;
        } else {
            delete $owners_ref->{$owner}
        }
    }
    #_exit("get_owners([".stringify_hash($owners_ref)."], $owner, $owns): $a");
}


sub process_user {
    my ($user, $users_hash_ref) = @_;

    _enter("process_user($user)");

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

            add_item($owner, $own, $objectid, $name, $subtype, $numplays, $minplayers, $maxplayers, $playingtime, $minplaytime, $maxplaytime, $image, $thumbnail, $yearpublished);
        } #foreach @bggitems
    } # foreach @types

    _exit("process_user");
}


sub add_item {
    my ($owner, $own, $objectid, $name, $subtype, $numplays, $minplayers, $maxplayers, $playingtime, $minplaytime, $maxplaytime, $image, $thumbnail, $yearpublished) = @_;
    my ($item_hash_ref);

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

    $item_hash_ref = $items_hash_ref->{$objectid};
    if (exists $items_hash_ref->{$objectid}) {
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
            &ITEM_KEY_LASTPLAYED    => {},
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

    my ($item_hash_ref, $objectid, $name, $update);
    my (%bggitem, $bggitem_ref);
    my ($ratings_hash_ref, $ranks_ref, $boardgame_rank_ref, $rank, $rank_hash_ref);
    my (@bestplayers, @recplayers, $total, $votes, $best, $rec, $np, $poll_hash_ref, $temp_hash_ref, $result_hash_ref, $playercount_result_hash_ref, $key, $np, $expands_ref);

    _debug("process_things: bggitems ".@{$things_ref});

    my $i = 0;
    foreach $bggitem_ref (@$things_ref) {
        $i += 1;
        $objectid = $bggitem_ref->{'@id'};
        if ($compilations) {
            $objectid = $comp_ids_hash_ref->{$objectid};
        }
        $item_hash_ref = $items_hash_ref->{$objectid};
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
                    if (exists($item_hash_ref->{&ITEM_KEY_EXPANDS})) {
                        $expands_ref = $item_hash_ref->{&ITEM_KEY_EXPANDS};
                    } else {
                        $expands_ref = [];
                        $item_hash_ref->{&ITEM_KEY_EXPANDS} = $expands_ref;
                    }
                    push(@{$expands_ref}, $link_ref->{'@id'});
                    #if ($i < 10) {
                    #    _debug("process_things: $objectid ".$item_hash_ref->{&ITEM_KEY_NAME}." expands ".$link_ref->{'@id'}." ".$item_hash_ref->{$link_ref->{'@id'}}->{&ITEM_KEY_NAME});
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


# process_plays - update items lastplayed property based on given plays by users hash
#  -in: $plays_by_users_hash_ref - reference to a hash in which includes users plays
#           $plays_by_users_hash_ref->{$user}->{$playId}->{date|objectid}
sub process_plays {
    my ($plays_by_users_hash_ref) = @_;

    _enter("process_plays");

    foreach my $user (keys %$plays_by_users_hash_ref) {
        my $owner = PLAYS_USERS_TO_OWNERS->{$user};
        _debug("process_plays: user [${user}] plays [".keys(%{$plays_by_users_hash_ref->{$user}})."]");

        foreach my $play_id (keys %{$plays_by_users_hash_ref->{$user}}) {
            my $play_hash_ref = $plays_by_users_hash_ref->{$user}->{$play_id};
            my $date = $play_hash_ref->{"date"};
            my $objectid = $play_hash_ref->{"objectid"};
            #if ($objectid eq "102794") { _debug("$user played $date"); }
            if (exists($items_hash_ref->{$objectid})) {
                my $item_hash_ref = $items_hash_ref->{$objectid};
                if ($date > $item_hash_ref->{&ITEM_KEY_LASTPLAYED}->{$owner}) {
                    #if ($objectid eq "102794") { _debug("$owner lastplayed updated from ".$item_hash_ref->{&ITEM_KEY_LASTPLAYED}->{$owner}." to ${date}"); }
                    $item_hash_ref->{&ITEM_KEY_LASTPLAYED}->{$owner} = $date;
                }
            }
        }
    }

    #my $item_hash_ref = $items_hash_ref->{"102794"};
    #_debug("mobybeaver ".$item_hash_ref->{&ITEM_KEY_LASTPLAYED}->{"Justin"});
    #_debug("highexodus ".$item_hash_ref->{&ITEM_KEY_LASTPLAYED}->{"Ian"});

    _exit("process_plays");
}

sub process_expansions {
    my (@allobjectids, $objectid, $updates, $base_item_ref, $exp_item_ref, $str, $i, $j);
    my (@base_ids, $base_id, $base_name, $base_minplayers, $base_maxplayers, $exp_name, $exp_minplayers, $exp_maxplayers);
    my (@base_rec, @base_best, @exp_rec, @exp_best, $diff_players, $diff_best, $diff_rec, $message);

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

        if ($exp_item_ref->{&ITEM_KEY_SUBTYPE} ne "boardgameexpansion") {
            next;
        }

        if (exists($exp_item_ref->{&ITEM_KEY_EXPANDS})) {
            @base_ids = @{$exp_item_ref->{&ITEM_KEY_EXPANDS}};
            for $base_id (@base_ids) {
                $base_item_ref = $items_hash_ref->{$base_id};

                if (not(defined($base_item_ref))) {
                    next;
                }

                $base_name = $base_item_ref->{&ITEM_KEY_NAME};
                $exp_name  =  $exp_item_ref->{&ITEM_KEY_NAME};
                $base_minplayers = $base_item_ref->{&ITEM_KEY_MINPLAYERS};
                $base_maxplayers = $base_item_ref->{&ITEM_KEY_MAXPLAYERS};
                 $exp_minplayers =  $exp_item_ref->{&ITEM_KEY_MINPLAYERS};
                 $exp_maxplayers =  $exp_item_ref->{&ITEM_KEY_MAXPLAYERS};

                # merge best/recommended lists
                 @base_rec = defined($base_item_ref->{&ITEM_KEY_RECOMMENDED_NUMPLAYERS}) ? @{$base_item_ref->{&ITEM_KEY_RECOMMENDED_NUMPLAYERS}} : ();
                  @exp_rec = defined( $exp_item_ref->{&ITEM_KEY_RECOMMENDED_NUMPLAYERS}) ? @{ $exp_item_ref->{&ITEM_KEY_RECOMMENDED_NUMPLAYERS}} : ();
                @base_best = defined($base_item_ref->{&ITEM_KEY_BEST_NUMPLAYERS       }) ? @{$base_item_ref->{&ITEM_KEY_BEST_NUMPLAYERS       }} : ();
                 @exp_best = defined( $exp_item_ref->{&ITEM_KEY_BEST_NUMPLAYERS       }) ? @{ $exp_item_ref->{&ITEM_KEY_BEST_NUMPLAYERS       }} : ();

                # create new arrays for each item
                my @merged_best = map($_ * 1, sort(uniq((@base_best, @exp_best))));
                my @merged_rec  = map($_ * 1, sort(uniq((@base_rec,  @exp_rec ))));

                $exp_minplayers = ($exp_minplayers  > 0 && $exp_minplayers < $base_minplayers ? $exp_minplayers : $base_minplayers);
                $exp_maxplayers = ($exp_maxplayers  > 0 && $exp_maxplayers > $base_maxplayers ? $exp_maxplayers : $base_maxplayers);

                # update base game and log changes
                $base_item_ref->{&ITEM_KEY_EXPANSIONS}->{$objectid} = TRUE;
                my $diff_players = ( ($base_minplayers != $exp_minplayers) || ($base_maxplayers != $exp_maxplayers) );
                my $diff_best = ($#base_best != $#merged_best);
                my $diff_rec  = ($#base_rec  != $#merged_rec );
                if ( $diff_players || $diff_best || $diff_rec ) {
                    $updates++;

                    my $message = "process_expansions: ${base_name} with ${exp_name}";
                    if ( $diff_players ) {
                        $base_item_ref->{&ITEM_KEY_MINPLAYERS } = $exp_minplayers ;
                        $base_item_ref->{&ITEM_KEY_MAXPLAYERS } = $exp_maxplayers ;
                        $message = "$message, ${base_minplayers}-${base_maxplayers}p -> ${exp_minplayers}-${exp_maxplayers}p";
                    }
                    if ( $diff_best ) {
                        $base_item_ref->{&ITEM_KEY_BEST_NUMPLAYERS } = \@merged_best;
                        $message = "$message, best ".to_json(\@base_best)." -> ".to_json(\@merged_best);
                    }
                    if ( $diff_rec ) {
                        $base_item_ref->{&ITEM_KEY_RECOMMENDED_NUMPLAYERS } = \@merged_rec;
                        $message = "$message, rec ".to_json(\@base_rec)." -> ".to_json(\@merged_rec);
                    }
                    _debug($message);
                }
            }
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

        if ($picture_hash_ref->{"none"} eq "true") {
            $pictureless_ref->{$objectid} = "1";
        } else {
            if (exists($picture_hash_ref->{"id"})) {
                $item_hash_ref->{&ITEM_KEY_PICTURE} = $picture_hash_ref->{"id"};
            } elsif (exists($picture_hash_ref->{"uri"})) {
                $item_hash_ref->{&ITEM_KEY_PICTURE} = $picture_hash_ref->{"uri"};
            }
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
              && keys %{$item_hash_ref->{&ITEM_KEY_OWNERS}} > 0
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

            #_debug("process_prevowned: BEFORE owners = [".stringify_hash($owners_ref)."]");
            #_debug("process_prevowned: BEFORE prevowners = [".stringify_hash($prevowners_ref)."]");
            if ($item_hash_ref->{&ITEM_KEY_OWNERS}->{$owner}) {
                _debug("process_prevowned: Prevowned game $objectid ".$item_hash_ref->{&ITEM_KEY_NAME}." is still owned by $owner");
            } else {
                get_owners($prevowners_ref, $owner, TRUE);
                get_owners($item_hash_ref->{&ITEM_KEY_OWNERS}, $owner, FALSE);
            }
            #_debug("process_prevowned: AFTER  owners = [".stringify_hash($owners_ref)."]");
            #_debug("process_prevowned: AFETR  prevowners = [".stringify_hash($prevowners_ref)."]");
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

    add_online_items();

    process_things(get_bgg_things_json([keys(%$items_hash_ref)], "things"));
    process_things(get_bgg_things_json([keys(%$comp_ids_hash_ref)], "compilations"), TRUE);

    process_expansions();

    process_pictures();

    process_plays(get_bgg_plays_json());

    json_hash_to_file($items_hash_ref, "items");

    _exit("bggxml_to_items");
}


sub add_online_items {
    _enter("add_online_items");

    my ($online_games_hash_ref, $things_ref, $bggitem_ref, $name_obj, $owner, $own, $objectid, $name, $subtype, $numplays, $minplayers, $maxplayers, $playingtime, $minplaytime, $maxplaytime, $image, $thumbnail, $yearpublished);

    $online_games_hash_ref = json_hash_from_file("online_games", "");

    _debug("keys = " . keys(%$online_games_hash_ref));
    foreach my $owner (keys(%$online_games_hash_ref)) {
        _debug("add_online_items: online game owner: $owner (" . length($online_games_hash_ref->{"$owner"}) . ")");
        $things_ref = get_bgg_things_json($online_games_hash_ref->{"$owner"}, "online_games.${owner}");

        foreach $bggitem_ref (@$things_ref) {
            if (ref($bggitem_ref->{"name"}) eq "ARRAY") {
                foreach $name_obj (@{$bggitem_ref->{"name"}}) {
                    if ($name_obj->{'@type'} eq "primary") {
                        $name = $name_obj->{'@value'};
                    }
                }
            } else {
                $name = $bggitem_ref->{"name"}->{'@value'};
            }

            $own = TRUE;
            $objectid = $bggitem_ref->{'@id'};
            $subtype = $bggitem_ref->{'@type'};
            $numplays = -1;
            $minplayers = int($bggitem_ref->{'minplayers'}->{'@value'});
            $maxplayers = int($bggitem_ref->{"maxplayers"}->{'@value'});
            $playingtime = defined($bggitem_ref->{'playingtime'}->{'@value'}) ? int($bggitem_ref->{'playingtime'}->{'@value'}) : -1;
            $minplaytime = defined($bggitem_ref->{'minplaytime'}->{'@value'}) ? int($bggitem_ref->{'minplaytime'}->{'@value'}) : -1;
            $maxplaytime = defined($bggitem_ref->{'maxplaytime'}->{'@value'}) ? int($bggitem_ref->{'maxplaytime'}->{'@value'}) : -1;
            $image = $bggitem_ref->{"image"}->{'$t'};
            $thumbnail = $bggitem_ref->{"thumbnail"}->{'$t'};
            $yearpublished = int($bggitem_ref->{"yearpublished"}->{'@value'});

            #_debug("add_online_items: $owner, $own, $objectid, $name, $subtype, $numplays, $minplayers, $maxplayers, $playingtime, $minplaytime, $maxplaytime, $image, $thumbnail, $yearpublished");

            add_item($owner, $own, $objectid, $name, $subtype, $numplays, $minplayers, $maxplayers, $playingtime, $minplaytime, $maxplaytime, $image, $thumbnail, $yearpublished);
        }
    }

    _exit("add_online_items");
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
    my ($production, $error, $skip_http, $skip_bggxml, $skip_things, $skip_items, $skip_firebase, $months_of_plays) = (FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, 2);

    _enter("parse_arguments");

    # parse options
    GetOptions (
        "production"        => \$production,
        "error"             => \$error,
        "http"              => \$skip_http,
        "bggxml"            => \$skip_bggxml,
        "things"            => \$skip_things,
        "items"             => \$skip_items,
        "firebase"          => \$skip_firebase,
        "months-of-plays=i" => \$months_of_plays
    ) or die("Error in command line arguments\n");

    if (!$skip_things) {
        _debug("parse_arguments: skipping things by default");
    }
    if ($skip_http && !$skip_firebase) {
        _debug("parse_arguments: auto-skipping firebase because HTTP requests are skipped");
        $skip_firebase = TRUE;
    }

    $args_hash_ref->{ARG_PRODUCTION}      = $production;
    $args_hash_ref->{ARG_ERROR}           = $error;
    $args_hash_ref->{ARG_SKIP_HTTP}       = $skip_http;
    $args_hash_ref->{ARG_SKIP_BGGXML}     = $skip_bggxml;
    $args_hash_ref->{ARG_SKIP_THINGS}     = !$skip_things;
    $args_hash_ref->{ARG_SKIP_ITEMS}      = $skip_items;
    $args_hash_ref->{ARG_SKIP_FIREBASE}   = $skip_firebase;
    $args_hash_ref->{ARG_MONTHS_OF_PLAYS} = $months_of_plays;

    _exit("parse_arguments: "
        . "production [".stringify_bool($args_hash_ref->{ARG_PRODUCTION})."] "
        . "error [".stringify_bool($args_hash_ref->{ARG_ERROR})."] "
        . "skip_http [".stringify_bool($args_hash_ref->{ARG_SKIP_HTTP})."] "
        . "skip_bggxml [".stringify_bool($args_hash_ref->{ARG_SKIP_BGGXML})."] "
        . "skip_things [".stringify_bool($args_hash_ref->{ARG_SKIP_THINGS})."] "
        . "skip_items [".stringify_bool($args_hash_ref->{ARG_SKIP_ITEMS})."] "
        . "skip_firebase: [".stringify_bool($args_hash_ref->{ARG_SKIP_FIREBASE})."] "
        . "months_of_plays: [".$args_hash_ref->{ARG_MONTHS_OF_PLAYS}."]"
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
