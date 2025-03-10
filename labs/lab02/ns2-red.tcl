set ns [new Simulator]

set node_(s1) [$ns node]
set node_(s2) [$ns node]
set node_(r1) [$ns node]
set node_(r2) [$ns node]
set node_(s3) [$ns node]
set node_(s4) [$ns node]

$ns duplex-link $node_(s1) $node_(r1) 10Mb 2ms DropTail
$ns duplex-link $node_(s2) $node_(r1) 10Mb 3ms DropTail
$ns duplex-link $node_(r1) $node_(r2) 1.5Mb 20ms RED
$ns queue-limit $node_(r1) $node_(r2) 25 
$ns queue-limit $node_(r2) $node_(r1) 25 
$ns duplex-link $node_(s3) $node_(r2) 10Mb 4ms DropTail
$ns duplex-link $node_(s4) $node_(r2) 10Mb 5ms DropTail



set tcp1 [$ns create-connection TCP/Newreno $node_(s1) TCPSink $node_(s3) 0]
$tcp1 set window_ 15
set tcp2 [$ns create-connection TCP/Reno $node_(s2) TCPSink $node_(s3) 1]
$tcp2 set window_ 15
set ftp1 [$tcp1 attach-source FTP]
set ftp2 [$tcp2 attach-source FTP]

set windowVsTime [open WindowVsTimenewReno w]
puts $windowVsTime "0.Color: Aqua"
puts $windowVsTime \ "sizeofwindow"

set qmon [$ns monitor-queue $node_(r1) $node_(r2) [open "qm.out" w] 0.1]
[$ns link $node_(r1) $node_(r2)] queue-sample-timeout;

set redq [[$ns link $node_(r1) $node_(r2)] queue]
set tchan_ [open all.q w]
$redq trace curq_
$redq trace ave_
$redq attach $tchan_


$ns at 0.0 "$ftp1 start"
$ns at 1.1 "plotWindow $tcp1 $windowVsTime"
$ns at 3.0 "$ftp2 start"
$ns at 10 "finish"

proc plotWindow {tcpSource file} {
	global ns
	set time 0.01
	set now [$ns now]
	set cwnd [$tcpSource set cwnd_]
	puts $file "$now $cwnd"
	$ns at [expr $now+$time] "plotWindow $tcpSource $file"
}


proc finish {} {
    global tchan_

    set awkCode {
        {
            if ($1 == "Q" && NF>2) {
                print $2, $3 >> "temp.q"; 
            } 
            else if ($1 == "a" && NF>2) {
                print $2, $3 >> "temp.a"; 
            }
        }
    }

    set f [open temp.queue w]
    puts $f "0.Color: orange"  
    puts $f "1.Color: cyan"   
    puts $f \"Queue_Stats"

    if { [info exists tchan_] } {
        close $tchan_
    }

    exec rm -f temp.q temp.a
    exec touch temp.a temp.q

    exec awk $awkCode all.q
    puts $f \"ochered"
    exec cat temp.q >@ $f
    puts $f \n\"cred_queue"
    exec cat temp.a >@ $f
    close $f

    exec xgraph -bb -tk -fg gold -bg black -x time -t "TCPNewRenoCWND" WindowVsTimenewReno &
    exec xgraph -bb -tk -fg gold -bg black -x time -y queue temp.queue &
    exit 0
}

$ns run
