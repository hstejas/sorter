#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use Data::Dumper;
use File::Copy;
use JSON qw(decode_json);

my $url="http://www.omdbapi.com/";

my @names=@ARGV;#("Captain America", "forrest gump", 'thr___');

sub sanitize($)
{
   my $fname = shift;
   print "$fname === \n";
   $fname=~s/\.avi//i;
   $fname=~s/\.mkv//i;
   $fname=~s/\.mp4//i;
   $fname=~s/\.wmv//i;
   $fname=~s/_/ /gi;
   $fname=~s/\./ /gi;
   $fname=~s/-/ /gi;
   $fname=~s/[\[\]\(\)]/ /gi;
   $fname=~s/1080[p]//i;
   $fname=~s/720[p]//i;
   my $year="";
   $fname=~/(19..)/ and $year = $1;
   $fname=~/(20..)/ and $year = $1;
   $fname=~s/$year//;

   $fname=~s/([a-z]+)([A-Z]{1})/$1 $2/;
   $fname=~s/([a-zA-Z]+)([0-9]{1})/$1 $2/;
   #$fname=~/([a-zA-Z'\s]*[0-9]*[a-zA-Z'\s]*)/;
   my $name = $fname;
   $name =~ s/^\s+|\s+$//g ;
   return ($name, $year);
}

foreach(@names)
{
   my $fname = $_;
   my ($name, $year) = sanitize($fname);
   my $query='?t="'.$name.'"&type="movie"&y="'.$year.'"';
   #print "$name --> $year\n";
   my $response = get($url.$query) or print "Couldnt get $query" and next;
   my $dec_json = decode_json($response);
   #print Dumper $dec_json;
   if($dec_json->{"Response"} eq "True")
   {
      print $dec_json->{"Title"}." --> ".$dec_json->{"Year"}." --> ".$dec_json->{"Rated"}." \n";
      print "Skip? ";   
      print "Skipping\n" and next if(<STDIN>=~/y/);
      my $rating = $dec_json->{"Rated"};
      $rating=~s/[\/\\]//;
      my $dest = "../AM/$rating/";
      mkdir $dest if(! -d $dest);
      move("$fname", "$dest$fname") or print "Could not move $fname\n $!";
   }
   #print $response."\n\n\n";
}
