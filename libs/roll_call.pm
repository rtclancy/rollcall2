#!/usr/bin/perl
#!c:/cygwin/bin/perl.exe -Tw

package roll_call;

use strict;
use CGI;
use Fcntl;
my $app_root = "/var/lib/openshift/5294a7254382ec4ea2000234/app-root";
#$app_root = "..";
my $query = new CGI;

my $required_style="style=\"color:red;font-size:40px\"";
my $optional_style="style=\"color:black;font-size:20px\"";

my $data_file1 = "$app_root/data/roll_call_in.csv";
my $data_file2 = "$app_root/data/roll_call_out.csv";
my $data_file_blank = "$app_root/data/roll_call_blank.csv";
my $data_file_out1 = "$app_root/data/tmp_roll_call_in.csv";
my $data_file_out2 = "$app_root/data/tmp_roll_call_out.csv";
my $player_id;
my $day;
my $player;
my $player_delta;
my $action;
our $illegal_delta;
our $timestamp;
our $week_of;
our $stale=0;

######################################################################
######################################################################
sub check_for_stale 
{
  my $linein;
  my $ts;
  my @timestamp;

  sysopen (f_in1, $data_file1, O_RDONLY) or die "can't open $data_file1: $!";
  sysopen (f_in2, $data_file_out1, O_RDONLY) or die "can't open $data_file_out1: $!";
  sysopen (f_in3, $data_file2, O_RDONLY) or die "can't open $data_file2: $!";
  sysopen (f_in4, $data_file_out2, O_RDONLY) or die "can't open $data_file_out2: $!";

#read off first 3 lines of file in order to get to timestamp
  for ($day=0;$day<3;$day++)
    {
      $linein = <f_in1>;
      $linein = <f_in2>;
      $linein = <f_in3>;
      $linein = <f_in4>;
    }
  for ($ts=0;$ts<4;$ts++)
    {
      if ($ts == 0)
	{
	  $timestamp[$ts] = <f_in1>;
	}
      if ($ts == 1)
	{
	  $timestamp[$ts] = <f_in2>;
	}
      if ($ts == 2)
	{
	  $timestamp[$ts] = <f_in3>;
	}
      if ($ts == 3)
	{
	  $timestamp[$ts] = <f_in4>;
	}
#      print "<p>$timestamp[$ts]</p>";
    }

  if (($timestamp[0] != $timestamp[1]) || ($timestamp[2] != $timestamp[3]))
    {
      $stale=1;
    }
  
close(f_in1);close(f_in2);close(f_in3);close(f_in4);
return($stale);
}
######################################################################
######################################################################
sub player_delta
{
  my @in_player_list;
  my @in_player_list_tmp;
  my @out_player_list;
  my @out_player_list_tmp;
  my @day_array=("Monday", "Wednesday","Friday");
  my $linein;
  
  $illegal_delta=0;

  sysopen (f_in1, $data_file1, O_RDONLY) or die "can't open $data_file1: $!";
  sysopen (f_in2, $data_file_out1, O_RDONLY) or die "can't open $data_file_out1: $!";
  sysopen (f_in3, $data_file2, O_RDONLY) or die "can't open $data_file2: $!";
  sysopen (f_in4, $data_file_out2, O_RDONLY) or die "can't open $data_file_out2: $!";

  for ($day=0;$day<3;$day++)
    {
      $linein = <f_in1>;
      @in_player_list = split(/,/,$linein);
      $linein = <f_in2>;
      @in_player_list_tmp = split(/,/,$linein);
      $linein = <f_in3>;
      @out_player_list = split(/,/,$linein);
      $linein = <f_in4>;
      @out_player_list_tmp = split(/,/,$linein);
      for ($player=0;$player<20;$player++)
	{
	  if (($in_player_list_tmp[$player] ne '&nbsp') && ($out_player_list_tmp[$player] ne '&nbsp'))
	    {
	      print "<p>Day $day, Row $player, Can't be both in and out</p>";
	      $illegal_delta=1;
	    }
	  if ($in_player_list[$player] ne $in_player_list_tmp[$player])
	    {
	      if ($in_player_list[$player] eq '&nbsp') #legal replacement
		{
		  $player_delta=$in_player_list_tmp[$player];
		  close(f_in1);close(f_in2);close(f_in3);close(f_in4);
		  return($player_delta);
		}
	    }
	  if ($out_player_list[$player] ne $out_player_list_tmp[$player])
	    {
	      if ($out_player_list[$player] eq '&nbsp') #legal replacement
		{
		  $player_delta=$out_player_list_tmp[$player];
		  close(f_in1);close(f_in2);close(f_in3);close(f_in4);
		  return($player_delta);
		}
	    }
	}
    }
  close(f_in1);close(f_in2);close(f_in3);close(f_in4);
  return('null');
}
######################################################################
######################################################################
sub html_head
{
print "Content-type: text/html\n\n";
print <<"EndOfText";
<HTML>
<HEAD>
<TITLE>Roll Call</TITLE>
</HEAD>
EndOfText
}
######################################################################
######################################################################

sub player_id {
  my $nonnull;
  my $day=$_[0];
  my $player=$_[1];
  my $out_inb=$_[2];
  my $player_id;
  #  print "<p>$day:$player</p>";
  
  if ($day==0) 
    {
      if (!$out_inb)
	{
	  $player_id=$query->param("mon_player_list_in_$player");
	}
      else
	{
	  $player_id=$query->param("mon_player_list_out_$player");
	}
    }
  if ($day==1) 
    {
      if (!$out_inb)
	{
	  $player_id=$query->param("wed_player_list_in_$player");
	}
      else
	{
	  $player_id=$query->param("wed_player_list_out_$player");
	}
    }
  if ($day==2) 
    {
      if (!$out_inb)
	{
	  $player_id=$query->param("fri_player_list_in_$player");
	}
      else
	{
	  $player_id=$query->param("fri_player_list_out_$player");
	}
    }

  #strip leading &nbsp
  $nonnull = 0;
  while (length($player_id))
    {
      if (ord($player_id)== 0xa0)  #test leading character
	{
	  $player_id = substr($player_id,1); #delete leading character
	}
      else
	{
	  $nonnull=1;
	  last;
	}
    }
  if (!$nonnull) 
    {
      $player_id='&nbsp';
    }
  if (!($player_id =~ m/\w/))
    {
#      print "whitespace only";
      $player_id='&nbsp';
    }
      
#  print f_out "$player_id,";
#  print"<p>$day:$player:$player_id,</p>";
  return($player_id);
}

######################################################################
######################################################################
sub copy_files
  {
    my $i;
    my ($linein);
    sysopen (f_gd_out, $_[1], O_WRONLY|O_CREAT|O_TRUNC,666) or die "can't open $_[1]: $!";
    #flock(f_gd_out);
    sysopen (f_gd, $_[0], O_RDONLY) or die "can't open $_[0]: $!";
    #while ($linein = <f_gd>) {}
    for ($i=0;$i<3;$i++)
      {
	$linein=<f_gd>;
	print f_gd_out "$linein";
	#print f_gd_out (chomp($linein));
      }
#update timestamp
    $linein=<f_gd>;
    $linein=$linein+1;
    print f_gd_out "$linein\n";
    
    if ($_[2] == 1) #if resetting form update week of in data file
      {
	$linein=<f_gd>;
	print f_gd_out "$week_of\n";
      }
    else
      {
	$linein=<f_gd>;
	print f_gd_out "$linein";
      }
    
    #in count and out count
    $linein=<f_gd>;
    print f_gd_out "$linein";
    $linein=<f_gd>;
    print f_gd_out "$linein";

    close(f_gd_out);   
    close(f_gd);   
}

######################################################################
sub display_form {
my $in_count;
my $out_count;
my $player_id;
my $linein;
my @tmp_player_list;
my @tmp_player_list_out;
my @mon_player_list;
my @wed_player_list;
my @fri_player_list;
my @mon_player_list_out;
my @wed_player_list_out;
my @fri_player_list_out;
# display the form	
print <<"EndofText";
<FORM METHOD="POST" ACTION="http://rollcall-sunriseshooters.rhcloud.com/">
<TABLE width=40% border="1"; style="font-size:14px;text-align:center;word-wrap;break-word;">
EndofText
###################################################################
#heading
###################################################################
print "<HR>\n";
my @day_array=("Monday", "Wednesday","Friday");
sysopen (f_in1, $data_file1, O_RDONLY) or die "can't open $data_file1: $!";
sysopen (f_in2, $data_file2, O_RDONLY) or die "can't open $data_file2: $!";

for ($day=0;$day<3;$day++)
  {
    if ($day == 0)
      {
	$linein = <f_in1>;
	@mon_player_list = split(/,/,$linein);
	$linein = <f_in2>;
	@mon_player_list_out = split(/,/,$linein);
      }
    if ($day == 0)
      {
	$linein = <f_in1>;
	@wed_player_list = split(/,/,$linein);
	$linein = <f_in2>;
	@wed_player_list_out = split(/,/,$linein);
      }
    if ($day == 0)
      {
	$linein = <f_in1>;
	@fri_player_list = split(/,/,$linein);
	$linein = <f_in2>;
	@fri_player_list_out = split(/,/,$linein);
      }
  }
my $in_timestamp = <f_in1>;
chomp($in_timestamp);
my $out_timestamp = <f_in2>;
chomp($out_timestamp);
my $week_of = <f_in2>;
chomp($week_of);

close(f_in1);
close(f_in2);

#print "<p>$in_timestamp</p>";
#print "<p>$out_timestamp</p><br>";

print <<"EndofText";
<TR>
<TD>Week of: <INPUT SIZE=20 TYPE="text" NAME="week_of" VALUE="$week_of" readonly/></TD>
<TD><INPUT SIZE=4 TYPE="submit" NAME="action" VALUE="submit_roll" /></TD>
<TD><INPUT SIZE=4 TYPE="submit" NAME="action" VALUE="reset_roll" /></TD>
</TR>
EndofText

for ($day=0;$day<3;$day++)
  {
print <<"EndofText";
<TH width=20% ALIGN="center" $optional_style><STRONG>$day_array[$day]</STRONG></TH>
EndofText
 }


print  "</HR>\n";

my $user_agent=$ENV{'HTTP_USER_AGENT'};
#print $user_agent;
my $mobile_device;
if (($user_agent =~ m/Mozilla/i) && (($user_agent =~ m/Firefox/i) || ($user_agent =~ m/windows/i) || ($user_agent =~ m/ipad/i)))
  {
    $mobile_device=0;
  }
else
  {
    $mobile_device=1;
  }



if (!($mobile_device))
{
print  "<TR>\n";
print "<TD><img width=150 height=150 src=../../image_files/sun_icon.gif></TD>\n";
print "<TD><img width=150 height=150 src=../../image_files/shooters.jpg></TD>\n";
print "<TD><img width=150 height=150 src=../../image_files/Basketball.JPG></TD>\n";
print  "</TR>\n";
}

#in versus out headings in table
print "<TR>\n";
for ($day=0;$day<3;$day++)
  {
    $in_count=0;
    $out_count=0;
    if ($day == 0)
      {
	@tmp_player_list=@mon_player_list;
	@tmp_player_list_out=@mon_player_list_out;
      }
    if ($day == 1)
      {
	@tmp_player_list=@wed_player_list;
	@tmp_player_list_out=@wed_player_list_out;
      }
    if ($day == 2)
      {
	@tmp_player_list=@fri_player_list;
	@tmp_player_list_out=@fri_player_list_out;
      }
    for ($player=0;$player<20;$player++)
      {	
	if (($tmp_player_list[$player] ne '&nbsp'))
	  {
	    $in_count=$in_count+1;
	  }
	if (($tmp_player_list_out[$player] ne '&nbsp'))
	  {
	    $out_count=$out_count+1;
	  }
      }
    
    print "<TD><TABLE width=80%><HR width=100%><TH width=50% align=CENTER>IN($in_count)</TH><TH width=50% align=CENTER>OUT($out_count)</TH></HR></TABLE></TD>\n";
  }
print "</TR>\n";


for ($player=0;$player<20;$player++)
  {
$player_id = $player+1;
    print  "<TR>\n";
    for ($day=0;$day<3;$day++)
      {
	if ($day==0)
	  {
	    print "<TD><TABLE><TR>\n";
print <<"EndofText";
<TD style="width:20px" ALIGN="left"> <p > $player_id:</p></TD>
<TD ALIGN="left" $optional_style> <p ><INPUT SIZE=10% border=none bg=none $optional_style NAME="mon_player_list_in_$player" value="$mon_player_list[$player]" /> </p> </TD>
EndofText
print <<"EndofText";
<TD ALIGN="left" $optional_style> <p > <INPUT SIZE=10% border=none bg=none $optional_style NAME="mon_player_list_out_$player" value="$mon_player_list_out[$player]" /> </p> </TD>
EndofText
	    print "</TR></HR></TABLE></TD>";
      }
	if ($day==1)
	  {
	    print "<TD><TABLE><TR>\n";
	    print << "EndofText";
<TD ALIGN="left" $optional_style> <p >  <INPUT SIZE=10% $optional_style NAME="wed_player_list_in_$player" value="$wed_player_list[$player]" /> </p> </TD>
EndofText
	    print << "EndofText";
<TD ALIGN="left" $optional_style> <p >  <INPUT SIZE=10% $optional_style NAME="wed_player_list_out_$player" value="$wed_player_list_out[$player]" /> </p> </TD>
EndofText
	    print "</TR></HR></TABLE></TD>";
      }
	if ($day==2)
	  {
	    print "<TD><TABLE><TR>\n";
	print << "EndofText";
<TD ALIGN="left" $optional_style> <p >  <INPUT SIZE=10% $optional_style NAME="fri_player_list_in_$player" value="$fri_player_list[$player]" /> </p> </TD>
EndofText
	print << "EndofText";
<TD ALIGN="left" $optional_style> <p >  <INPUT SIZE=10% $optional_style NAME="fri_player_list_out_$player" value="$fri_player_list_out[$player]" /> </p> </TD>
EndofText
	    print "</TR></HR></TABLE></TD>";
      }
      }
    print "</TR>\n";
  }

print  "</TABLE>\n";
print <<"EndOfText";
<INPUT SIZE=4 TYPE="hidden" NAME="in_ts" VALUE="$in_timestamp" /></TD>
<INPUT SIZE=4 TYPE="hidden" NAME="out_ts" VALUE="$out_timestamp" /></TD>
EndOfText

print <<"EndOfText";
</FORM>
EndOfText
}

1;
