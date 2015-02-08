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

sub uptime_best {
        my $bag = shift;

        my $dbh = DBI->connect(config("db_observium_dsn"),config("db_observium_username"),config("db_observium_password"))
                or die "Couldn't connect to database: " . DBI->errstr;
        my $sth = $dbh->prepare("
				select devices.device_id, hostname, round(devices.uptime/60/60/24,1) as days
				from devices 
				where devices.ignore=0
				order by uptime desc
				limit 3;
				")
                or die "Couldn't prepare statement: " . $dbh->errstr;
        $sth->execute()  
            or die "Couldn't execute statement: " . $sth->errstr;
        my @data;
        my $count = 0;
        while (@data = $sth->fetchrow_array()) {
            my $device_id= $data[0];
            my $hostname = $data[1];
            my $days = $data[2];
            $count=$count+1;
                &say( $bag->{chl} =>
                        "$count. $hostname | $days days| http://observium.bath.ctwug.za.net/graphs/type=device_uptime/device=$device_id/")
            
          
        }
        $sth->finish;
        $dbh->disconnect;
}

sub uptime_worst {
        my $bag = shift;

        my $dbh = DBI->connect(config("db_observium_dsn"),config("db_observium_username"),config("db_observium_password"))
                or die "Couldn't connect to database: " . DBI->errstr;
        my $sth = $dbh->prepare("
				select devices.device_id, hostname, round(devices.uptime/60) as minutes
				from devices 
				where devices.ignore=0
				order by uptime asc
				limit 3;
				")
                or die "Couldn't prepare statement: " . $dbh->errstr;
        $sth->execute()  
            or die "Couldn't execute statement: " . $sth->errstr;
        my @data;
        my $count = 0;
        while (@data = $sth->fetchrow_array()) {
            my $device_id= $data[0];
            my $hostname = $data[1];
            my $minutes = $data[2];
            $count=$count+1;
                &say( $bag->{chl} =>
                        "$count. $hostname | $minutes minutes | http://observium.bath.ctwug.za.net/graphs/type=device_uptime/device=$device_id/")
            
          
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
        {
            label     => 'uptime best',
            addressed => 1,
            operator  => 0,
            editable  => 0,
            re        => qr/^uptime best/i,
            callback  => \&uptime_best
        },
        {
            label     => 'uptime worst',
            addressed => 1,
            operator  => 0,
            editable  => 0,
            re        => qr/^uptime worst/i,
            callback  => \&uptime_worst
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


=for comment 


use observium;

select 
	devices.hostname
	,devices.device_id
	,devices.status as device_status
	,devices.ignore
	,TIMESTAMPDIFF(minute,devices.last_polled,now()) as lastpollmin
	,alerts_bucket_devices.device_status as device_status_old
	,alerts_bucket_devices.modifiedtimestamp
	,concat(hostname,' is ',case when devices.status=1 then 'UP' else 'DOWN' end ,' since ',devices.last_polled,'! | http://observium.bath.ctwug.za.net/device/device=',devices.device_id,'/') as message
from
	devices
	left join 
		alerts_bucket_devices
		on devices.device_id=alerts_bucket_devices.device_id


=cut
