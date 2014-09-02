# BUCKET PLUGIN

use BucketBase qw/say say_long Log Report config save post/;
use DBI;

#$lastalertcheck=time();


sub signals {
    return (qw/on_public heartbeat say do/);
}

sub devices_down {
	my $bag = shift;

	my $dbh = DBI->connect(config("db_observium_dsn"),config("db_observium_username"),config("db_observium_password"))
                or die "Couldn't connect to database: " . DBI->errstr;
	my $sth = $dbh->prepare('SELECT device_id,hostname FROM devices where devices.ignore=0 and status=0;')
                or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute()    
            or die "Couldn't execute statement: " . $sth->errstr;
	my @data;
	my $count = 0;
	while (@data = $sth->fetchrow_array()) {
	    my $device_id= $data[0];
            my $hostname = $data[1];
	    $count=$count+1;
	    if ($count<6 ) {
                &say( $bag->{chl} =>
                        "$hostname is down | http://observium.bath.ctwug.za.net/device/device=$device_id/"
                );
	    } elsif ($count == 6) { 
                &say( $bag->{chl} =>
                        "... more ..."
                );
	    }
          }
	if ($sth->rows == 0) {
		&say( $bag->{chl} =>
              		"$bag->{who}: No devices down."
        	);
	} else {
		&say( $bag->{chl} =>
              		"$bag->{who}: ".$sth->rows." devices down."
        	);	
	}
        $sth->finish;
        $dbh->disconnect;
}

sub ports_down {
        my $bag = shift;

        my $dbh = DBI->connect(config("db_observium_dsn"),config("db_observium_username"),config("db_observium_password"))
                or die "Couldn't connect to database: " . DBI->errstr;
        my $sth = $dbh->prepare("
				SELECT devices.device_id,hostname,port_id,ifName, ports.ifLastChange
				FROM observium.devices inner join ports on devices.device_id=ports.device_id
				where 
					observium.devices.ignore=0 
					and status=1 
					and ports.ifOperStatus='down' 
					and ports.ignore=0 and ifAdminStatus='up';
				")
                or die "Couldn't prepare statement: " . $dbh->errstr;
        $sth->execute()  
            or die "Couldn't execute statement: " . $sth->errstr;
        my @data;
        my $count = 0;
        while (@data = $sth->fetchrow_array()) {
            my $device_id= $data[0];
            my $hostname = $data[1];
	    my $port_id= $data[2];
	    my $port=$data[3];
            $count=$count+1;
            if ($count<6 ) {
                &say( $bag->{chl} =>
                        "$hostname | $port is down | http://observium.bath.ctwug.za.net/device/device=$device_id/tab=port/port=$port_id/"
                );
            } elsif ($count == 6) {
                &say( $bag->{chl} =>
                        "... more ..."
                );
            }
          }
        if ($sth->rows == 0) {
                &say( $bag->{chl} =>
                        "$bag->{who}: No ports down."
                );
        } else {
                &say( $bag->{chl} =>
                        "$bag->{who}: ".$sth->rows." ports down."
                );
        }
        $sth->finish;
        $dbh->disconnect;
}


sub commands {
    return (
	{
            label     => 'devices down',
            addressed => 1,
            operator  => 0,
            editable  => 0,
            re        => qr/^devices down/i,
            callback  => \&devices_down
        },
        {
            label     => 'ports down',
            addressed => 1,
            operator  => 0,
            editable  => 0,
            re        => qr/^ports down/i,
            callback  => \&ports_down
        },
    );
}


sub settings {
    return (
        db_observium_dsn => [ s => 'DBI:mysql:database=observium;host=localhost' ],
        db_observium_password  => [ s => 'password' ],
	db_observium_username =>  [ s => 'observium' ]
    );
}

sub route {
    my ( $package, $sig, $data ) = @_;


    return 0;
}
