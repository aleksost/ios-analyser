#!/bin/bash
## Script:    ios-analyser.sh
## Author:    Aleksander Østerud
## Purpose:   Gathers information from various sources on an acquired iDevice and presents it in a web report
##
## Usage:
##   bash ios-analyser.sh [-h] -c case_no [-d report_directory] [-o officer] evidence_directory
##
##       -h:			Displays this help message
##       -d directory: 	The output directory to use for all files.
##		 				The default value is "report/".
##		 -c case_no: 	The Case Number used in the organization
##		 -o officer: 	The name of the officer running the case.
##		 				


################################################################################
## Function:    OutputDirectory                                                #
## Purpose:     Output -d argument from user, using "report/" as default  	   #
################################################################################

function OutputDirectory {
	if [ -z "$OUTPUT_DIRECTORY" ]; then 
		echo "report/"
	else echo "$OUTPUT_DIRECTORY"
	fi
}


############################################################################################
## Function:    Officer                                                                    # 
## Purpose:     Output -o argument from user, otherwise output Officer Nobody			   #
############################################################################################

function Officer {
	NAME="Officer Nobody"
	if [ -z "$OFFICER" ]; then 
		echo "${NAME}"
	else echo "$OFFICER"
	fi
}


#############################################################################
## Function:    TableEntry		                                    		#
## Purpose:     Takes x amount of arguments and creates HTML table-entries  #
#############################################################################

function TableEntry () {
	echo "<tr>"
	for arg in "$@"; do
	    echo "<td>"$arg
	done
	echo "</tr>"
}


###############################################################################
## Function:    TableFormat                                            		  #
## Purpose:     Takes three arguments and creates content for an HTML-table   #
###############################################################################

function TableFormat () {
	echo "<html>
		<head><title>"$1"</title></head>
		<style>
		table {
		    width:"$2"px;
		}
		table, th, td {
		    border: 1px solid black;
		    border-collapse: collapse;
		}
		th, td {
		    padding: 5px;
		    text-align: left;
		}
		table#t01 tr:nth-child(even) {
		    background-color: #eee;
		}
		table#t01 tr:nth-child(odd) {
		   background-color:#fff;
		}
		table#t01 th	{
		    background-color: black;
		    color: white;
		}
		</style>
		<body>
		<h2>"$3"</h2>
		<hr><table id="t01">
		<tr>"
}


###############################################################################
## Function:    GetCaseInformation                                            #
## Purpose:     Creates a table with case information                         #
###############################################################################

function GetCaseInformation {
	DATE=$( date )
	echo "<h2>Case Information</h2>
	<hr><table id="t01">"
	TableEntry "Case Number" "$CASE_NO"
	TableEntry "Officer" "$(Officer)"
	TableEntry "Date" "${DATE}"
	TableEntry "Case Number" "$CASE_NO"
	echo "</table>
	<hr>"
}

###############################################################################
## Function:    GetSystemInformation                                          #
## Purpose:     Write system information to an HTML-file, main.html        	  #
###############################################################################

function GetSystemInformation {
	DataArk=$EVIDENCE_DIR"/root/Library/Lockdown/data_ark.plist"
	GeneralLog=$EVIDENCE_DIR"/logs/AppleSupport/general.log"
	AccountsSqlite=$EVIDENCE_DIR"/mobile/Library/Accounts/Accounts3.sqlite"

	DeviceModel=$( 	cat ${GeneralLog} | grep Model | awk -F : '{print $2}' | head -1 )
	OSVersion=$( 	cat ${GeneralLog} | grep OS-Version | awk -F : '{print $2}' | head -1 )
	DeviceName=$( 	plutil -convert xml1 ${DataArk} -o - | grep DeviceName -A 1 | awk -F'[<>]' '{print $3}' | tail -1 )
	TimeZone=$( 	plutil -convert xml1 ${DataArk} -o - | grep TimeZone -A 1 | awk -F'[<>]' '{print $3}' | tail -1 )
	SerialNumber=$( cat ${GeneralLog} | grep Serial | awk -F : '{print $2}' | head -1 )
	Created=$( 		cat ${GeneralLog} | grep Created | awk  '{print $2,$3,$4}' | head -1 )
	CloudBackup=$( 	plutil -convert xml1 ${DataArk} -o - | grep CloudBackupEnabled -A 1 -b | awk -F'[<>]' '{print $2}' | tail -1 | tr -d '//')
	CloudAccount=$(	sqlite3 $AccountsSqlite "SELECT ZUSERNAME FROM ZACCOUNT;" | sort | uniq )

	echo "<h2>Device Information</h2>
	<hr><table id="t01">"
	TableEntry "<b>Type" "<b>Information" "<b>Source"
	TableEntry "Device-Model" "${DeviceModel}" "${GeneralLog}"
	TableEntry "OS Version" "${OSVersion}" "${GeneralLog}"
	TableEntry "Device Name" "${DeviceName}" "${DataArk}"
	TableEntry "TimeZone" "${TimeZone}" "${DataArk}"
	TableEntry "Serial Number" "${SerialNumber}" "${GeneralLog}"
	TableEntry "Time of Creation" "${Created}" "${GeneralLog}"
	TableEntry "Cloud Backup (True/False)" "${CloudBackup}" "${DataArk}"
	TableEntry "Cloud Account" "${CloudAccount}" "${AccountsSqlite}"

	echo "</tr>
	</table>
	<hr>"
}


###############################################################################
## Function:    GetEvidenceParsing                                            #
## Purpose:     Write parsed evidence to an HTML file, messages.html       	  #
###############################################################################

function GetEvidenceParsing {
	DataArk=$EVIDENCE_DIR"/root/Library/Lockdown/data_ark.plist"
	GeneralLog=$EVIDENCE_DIR"/logs/AppleSupport/general.log"

	DeviceModel=$( cat ${GeneralLog} | grep Model | awk -F : '{print $2}' | head -1 )
	OSVersion=$( cat ${GeneralLog} | grep OS-Version | awk -F : '{print $2}' | head -1 )
	DeviceName=$( plutil -convert xml1 ${DataArk} -o - | grep DeviceName -A 1 | awk -F'[<>]' '{print $3}' | tail -1 )
	TimeZone=$( plutil -convert xml1 ${DataArk} -o - | grep TimeZone -A 1 | awk -F'[<>]' '{print $3}' | tail -1 )
	SerialNumber=$( cat ${GeneralLog} | grep Serial | awk -F : '{print $2}' | head -1 )
	Created=$( cat ${GeneralLog} | grep Created | awk  '{print $2,$3,$4}' | head -1 )
	GetMessages > $(OutputDirectory)/messages.html
	GetContacts > $(OutputDirectory)/contacts.html
	GetWifi > $(OutputDirectory)/wifi.html
	GetApplications > $(OutputDirectory)/apps.html
	GetCallHistory > $(OutputDirectory)/callHistory.html
	GetNotes > $(OutputDirectory)/notes.html
	GetInterestingImages > $(OutputDirectory)/images.html
	GetKikInfo > $(OutputDirectory)/kik.html
	GetSafariInfo > $(OutputDirectory)/safari.html
	GetCalendar > $(OutputDirectory)/calendar.html

	echo "<h2>Parsed Evidence</h2>
	<hr><table id="t01">"
	TableEntry "<b>Type (with link)" "<b>Information" "<b>Source"
	TableEntry "<a href =messages.html>Messages</a>" "Messages from SMS and iMessage" ""$EVIDENCE_DIR"/mobile/Library/SMS/sms.db"
	TableEntry "<a href =contacts.html>Contacts</a>" "Contacts from iDevice" ""$EVIDENCE_DIR"/mobile/Library/AddressBook/AddressBook.sqlitedb"
	TableEntry "<a href =wifi.html>WiFi List</a>" "List of connected WiFi" "$EVIDENCE_DIR"/preferences/SystemConfiguration/com.apple.wifi.plist""
	TableEntry "<a href =apps.html>Applications</a>" "List of Applications" "Each app is presented with file path"
	TableEntry "<a href =callHistory.html>Call History</a>" "History of calls" ""$EVIDENCE_DIR"/mobile/Library/CallHistoryDB/CallHistory.storedata"
	TableEntry "<a href =notes.html>Notes</a>" "List of all notes" ""$EVIDENCE_DIR"/mobile/Library/Notes/notes.sqlite"
	TableEntry "<a href =images.html>Images</a>" "List of interesting images" "Each image is presented with file path"
	TableEntry "<a href =kik.html>KIK Info</a>" "Info from KIK Messenger" "`find $EVIDENCE_DIR/mobile/Containers/Data -iname "kik.sqlite"`"
	TableEntry "<a href =safari.html>Safari Artifacts</a>" "Safari History and Bookmarks" "BOOKMARKS: "$EVIDENCE_DIR"/mobile/Library/Safari/Bookmarks.db <br>HISTORY: `find $EVIDENCE_DIR/mobile/ -iname "history.db"`"
	TableEntry "<a href =calendar.html>Calendar Info</a>" "Info from the Calendar DB" ""$EVIDENCE_DIR"/mobile/Library/Calendar/Calendar.sqlitedb"


	echo "</table>
	<hr>"
}


###############################################################################
## Function:    GetMessages                                            		  #
## Purpose:     Write message information to an HTML file, messages.html      #
###############################################################################

function GetMessages {
SmsDB=$EVIDENCE_DIR"/mobile/Library/SMS/sms.db"
	sql_query="SELECT m.ROWID as ID
		, m.text as Message
		, m.handle_id as HandleID
		, m.service as Service
		, m.account as Account
		, datetime(m.date+978307200, 'unixepoch', 'localtime') as Date
		, datetime(m.date_read+978307200, 'unixepoch','localtime') as 'Date Read'
		, datetime(m.date_delivered+978307200, 'unixepoch'
		, 'localtime') as 'Date Delivered'
		,case m.is_from_me when 0 then 'no' when 1 then 'yes' else 'unknown' end as is_from_me, h.id || 'LLL' 
	FROM message m, handle h 
	WHERE m.handle_id = h.ROWID;"

	#Had to install gnu-sed (gsed) because of issues with processing of "newline" \n, which apparently is really hard with the built-in "sed"
	query=$( sqlite3 $SmsDB -header "$sql_query" | tr '\n' ' ' | gsed 's/LLL/\n/g' | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done)
	TableFormat "Messages" "500" "Messages"
	echo ${query}
	echo "</tr><a href =main.html>Back</a>
	</body></html>"
}


###############################################################################
## Function:    GetContacts                                            		  #
## Purpose:     Write contacts information to a HTML file, contacts.HTML      #
###############################################################################

function GetContacts {
	ContactsDB=$EVIDENCE_DIR"/mobile/Library/AddressBook/AddressBook.sqlitedb"
	
	#Copied this query from https://gist.github.com/laacz/1180765
	sql_query="select ABPerson.ROWID
	, ABPerson.first
	, ABPerson.last
	, ABPerson.Organization as organization
	, ABPerson.Department as department
	, ABPerson.Birthday as birthday
	, ABPerson.JobTitle as jobtitle
	, (select value from ABMultiValue where property = 3 and record_id = ABPerson.ROWID and label = (select ROWID from ABMultiValueLabel where value = '_$!<Work>!$_')) as phone_work
	, (select value from ABMultiValue where property = 3 and record_id = ABPerson.ROWID and label = (select ROWID from ABMultiValueLabel where value = '_$!<Mobile>!$_')) as phone_mobile
	, (select value from ABMultiValue where property = 3 and record_id = ABPerson.ROWID and label = (select ROWID from ABMultiValueLabel where value = '_$!<Home>!$_')) as phone_home
	, (select value from ABMultiValue where property = 4 and record_id = ABPerson.ROWID and label is null) as email
	, (select value from ABMultiValueEntry where parent_id in (select ROWID from ABMultiValue where record_id = ABPerson.ROWID) and key = (select ROWID from ABMultiValueEntryKey where lower(value) = 'street')) as address
	, (select value from ABMultiValueEntry where parent_id in (select ROWID from ABMultiValue where record_id = ABPerson.ROWID) and key = (select ROWID from ABMultiValueEntryKey where lower(value) = 'city')) as city
	from ABPerson
	order by ABPerson.ROWID
	;"
	query=$( sqlite3 $ContactsDB -header "$sql_query" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done)

	TableFormat "Contacts" "500" "Contacts"
	echo ${query}
	echo "</tr><a href =main.html>Back</a>
	</body></html>"
}


###############################################################################
## Function:    GetWifi			                                              #
## Purpose:     Write wifi information to a HTML file, wifi.html              #
###############################################################################

function GetWifi {
	WifiInfoFile=$EVIDENCE_DIR"/preferences/SystemConfiguration/com.apple.wifi.plist"

	plutil="plutil -convert xml1 $WifiInfoFile -o - "
	WiFi=$( $plutil | grep SSID_STR -A1 | grep string | awk -F'[<>]' '{print $3}' ) #| while read line; do echo "<tr><td>SSID<td>"$line ;done 
	WiFiLines=$( $plutil | grep SSID_STR -A1 | grep string | awk -F'[<>]' '{print $3}' | wc -l) 
	lastJoined=$( $plutil | grep lastJoined -A1 | grep date | awk -F'[<>]' '{print $3}' )
	lastAutoJoined=$( $plutil | grep lastAutoJoined -A1 | grep date | awk -F'[<>]' '{print $3}' )

	TableFormat "WiFi List" "600" "WiFi List"
	echo "<td><b>SSID<td><b>Last Joined<td><b>Last Auto Joined"
	#For every line in all of the commands above, parses information in HTML-table form
	for n in $(seq 1 $WiFiLines);
		do echo "<tr><td>"$WiFi "<td>"$lastJoined "<td>"$lastAutoJoined | sed -n ''$n'p'
	done
	echo "</tr><a href =main.html>Back</a>
	</body></html>"
}


###############################################################################
## Function:    GetApplication	                                              #
## Purpose:     Write app information to an HTML file, apps.html              #
###############################################################################

function GetApplications {
	
	TableFormat "List of Applications" "600" "Installed Applications"

	AllApps=$(find $EVIDENCE_DIR/stash/ -iname *.app -exec basename {} \;)
	AllAppsPath=$(find $EVIDENCE_DIR/stash/ -iname *.app )
	AllAppsLines=$( find $EVIDENCE_DIR/stash/ -iname *.app -exec basename {} \; | wc -l)
	InstalledApps=$(find $EVIDENCE_DIR/mobile/Containers/Bundle/Application -iname *.app -exec basename {} \;)
	InstalledAppsPath=$( find $EVIDENCE_DIR/mobile/Containers/Bundle/Application -iname *.app )
	InstalledAppsLines=$( find $EVIDENCE_DIR/mobile/Containers/Bundle/Application -iname *.app -exec basename {} \; | wc -l)

	echo "<td><b>Application<td><b>Full Path</tr>"


	for n in $(seq 1 $InstalledAppsLines); do 
		echo "<tr><td>" `find $EVIDENCE_DIR/mobile/Containers/Bundle/Application -iname *.app -exec basename {} \; | sed -n ''$n'p' `
		echo "<td>" `find $EVIDENCE_DIR/mobile/Containers/Bundle/Application -iname *.app | sed -n ''$n'p' ` "</tr>"
	done

	echo "</table>
	<hr><h2>All Applications</h2>
	<hr><table id="t01">
	<td><b>Application<td><b>Full Path</tr>"
	#for n in $(seq 1 $AllAppsLines); do 
	#	echo "<tr><td>" `find $EVIDENCE_DIR/stash/ -iname *.app -exec basename {} \; | sed -n ''$n'p' `
	#	echo "<td>" `find $EVIDENCE_DIR/stash/ -iname *.app | sed -n ''$n'p' ` "</tr>"
	#done

	echo "</tr><a href =main.html>Back</a>
	</body></html>"

}

###############################################################################
## Function:    GetCallHistory	                                              #
## Purpose:     Writes call information to an HTML file, apps.html            #
###############################################################################

function GetCallHistory {
	CallHistoryDB=$EVIDENCE_DIR"/mobile/Library/CallHistoryDB/CallHistory.storedata"
	
	sql_query="select datetime(ZDATE+978307200, 'unixepoch', 'localtime') as Date,ZDURATION as [Call Duration in Seconds],ZADDRESS as [Phone Number] from ZCALLRECORD;"

	query=$( sqlite3 $CallHistoryDB -header "$sql_query" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done)

	TableFormat "Call History" "500" "Call History"
	echo ${query}
	echo "</tr><a href =main.html>Back</a>
	</body></html>"

}


#########################################################################
## Function:    GetNotes	                                            #  	
## Purpose:     Writes notes information to an HTML file, notes.html    #
#########################################################################

function GetNotes {
	NotesDB=$EVIDENCE_DIR"/mobile/Library/Notes/notes.sqlite"
	
	sql_query="select datetime(zn.ZCREATIONDATE+978307200, 'unixepoch', 'localtime') as Created,datetime(zn.ZMODIFICATIONDATE+978307200, 'unixepoch', 'localtime') as [Modified],zn.ZTITLE as Title, zb.zcontent as Content from ZNOTE zn, ZNOTEBODY zb;" 
	query=$( sqlite3 $NotesDB -header "$sql_query" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done )

	TableFormat "Call History" "500" "Call History"
	echo ${query}
	echo "</tr><a href =main.html>Back</a>
	</body></html>"

}


###################################################################################################################################################
## Function:    GetInterestingImages	                                            															  #
## Purpose:     Writes information about images to an HTML file, images.html. Also copys and gives a link to the image to open in the browser.    #
###################################################################################################################################################

function GetInterestingImages {
	images=$(find $EVIDENCE_DIR/mobile/Media/DCIM/ -iname *.jpg)
	
	TableFormat "Images" "500" "Images in the DCIM-folder"
	for image in $images; do
		cp $image $OUTPUT_DIRECTORY/
		echo "<td><a href ="`basename $image`">$image</a></tr>"
	done
	echo "</tr><a href =main.html>Back</a>
	</body></html>"
}


#########################################################################################################
## Function:    GetKikInfo	                                            								#  	
## Purpose:     Writes KIK information to an HTML file, kik.html. Outputs both contacts and messages    #
#########################################################################################################

function GetKikInfo {
	kikDB=$(find $EVIDENCE_DIR/mobile/Containers/Data -iname "kik.sqlite")
	sql_contacts="select zdisplayname as [Full Name],zjid as [KIK ID],zusername as [KIK-Username] from zkikuser;" 
	sql_messages="select datetime(zkikmessage.ZRECEIVEDTIMESTAMP+978307200, 'unixepoch', 'localtime') as Received, zkikuser.zusername as [KIK-Username], zkikmessage.zbody as Message 
		FROM zkikmessage 
		INNER JOIN zkikuser 
		ON zkikmessage.zuser = zkikuser.z_pk;" 
	query_contacts=$( sqlite3 $kikDB -header "$sql_contacts" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done )
	query_messages=$( sqlite3 $kikDB -header "$sql_messages" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done )

	TableFormat "KIK Info" "700" "KIK Contacts"
	echo ${query_contacts}
	echo "</tr><a href =main.html>Back</a>
	</table>
	<hr><h2>KIK Messages</h2>
	<hr><table id="t01">
	<tr>
	"${query_messages}"
	</body></html>"
}


#################################################################################################################
## Function:    GetSafariInfo	                                            								    #  	
## Purpose:     Writes safari information to an HTML file, safari.html. Outputs both bookmarks and visited URLs #
#################################################################################################################

function GetSafariInfo {
	BookmarksDB=$EVIDENCE_DIR/mobile/Library/Safari/Bookmarks.db
	HistoryDB=$(find $EVIDENCE_DIR/mobile/ -iname "history.db")

	sql_bookmarks="select url as Address, title as Title from Bookmarks;" 
	sql_history="select datetime(visits.visit_time+978307200, 'unixepoch', 'localtime') as Visited, items.id as ID, visits.title as [User Action], items.url as [Visited URL] from history_visits as visits, history_items as items where items.id = visits.id;" 
	query_bookmarks=$( sqlite3 $BookmarksDB -header "$sql_bookmarks" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done )
	query_history=$( sqlite3 $HistoryDB -header "$sql_history" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done )

	TableFormat "SafariInfo" "700" "Sarafi Bookmarks"
	echo ${query_bookmarks}
	echo "</tr><a href =main.html>Back</a>
	</table>
	<hr><h2>KIK Messages</h2>
	<hr><table id="t01">
	<tr>
	"${query_history}"
	</body></html>"
}


#############################################################################################################################
## Function:    GetCalendar	                                            								    				#  	
## Purpose:     Writes calendar information to an HTML file, calendar.html. Outputs different calendars and calendar events #
#############################################################################################################################

function GetCalendar {
	CalendarDB=$EVIDENCE_DIR/mobile/Library/Calendar/Calendar.sqlitedb

	sql_calendars="select title as [Calendar Name] from calendar;"
	
	#This query has not been field-tested, as the image of the assignment-iDevice does not contain any Calendar items.
	sql_calendarItems="select summary as Summary,datetime(start_date+978307200, 'unixepoch', 'localtime') as [Start Date], datetime(end_date+978307200, 'unixepoch', 'localtime') as [End Date],datetime(last_modified+978307200, 'unixepoch', 'localtime') as [Last Modified] from CalendarItem;"
	query_calendars=$( sqlite3 $CalendarDB -header "$sql_calendars" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done )
	query_calendarItems=$( sqlite3 $CalendarDB -header "$sql_calendarsItems" | while read line; do echo "<tr><td>"$line | sed -e 's/\|/\<td\>/g' ;done )

	TableFormat "CalendarInfo" "700" "List of Calendars"
	echo ${query_calendars}
	echo "</tr><a href =main.html>Back</a>
	</table>
	<hr><h2>Calendar Items</h2>
	<hr><table id="t01">
	<tr>
	"${query_calendarItems}"
	</body></html>"
}


###############################################################################
## Function:    GenerateWebReport                                             #
## Purpose:     Generates web-report to main.html                             #
###############################################################################

function GenerateWebReport {
	echo "<!DOCTYPE html>" > $(OutputDirectory)/main.html
	TableFormat "Case "$CASE_NO": Main Report" "1000" "" >> $(OutputDirectory)/main.html
	GetCaseInformation >> $(OutputDirectory)/main.html
	GetSystemInformation >> $(OutputDirectory)/main.html
	GetEvidenceParsing >> $(OutputDirectory)/main.html
	echo "</body></html>" >> $(OutputDirectory)/main.html
}


###############################################################################
#                                 MAIN CODE                                   #
###############################################################################

#Help-text if -h option is used
if [ "$1" == "-h" ]; then
	echo "bash ios-analyser.sh [-h] -c case_no [-d report_directory] [-o officer] evidence_directory

 -h:			Display this help message
 -c case_no:		The Case Number used in the organisation
 -o officer:		The name of the officer running the case.
 -d directory: 		The output directory to use for all files.
 evidence_directory 	Directory where the iDevice data resides. "
	exit 0
elif [ "$1" != "-c" ];then
	echo "Non-optional argument missing: -c case_no"
	exit 0
fi

#Assign arguments to letters through getopts
while getopts ":c:d:o:b:" opt; do
	case $opt in
		c)
			CASE_NO=$OPTARG
			;;
		\?)
			echo "Invalid option: -$OPTARG"
			;;
		d)
			OUTPUT_DIRECTORY=$OPTARG
			;;
		o)
			OFFICER=$OPTARG
			;;
    	:)
      		echo "Option -$OPTARG requires an argument." >&2
      		exit 1
      		;;
  		*)
			echo $OPTARG
      	;;
	esac
done

#Sets last argument as the Evidence Directory
EVIDENCE_DIR=${@: -1}

#Error messages if something is not as it should be.
if ! test -e "$EVIDENCE_DIR";then
	echo "ERROR: Evidence directory "$EVIDENCE_DIR" does not exist"
	exit 1
elif ! test -r "${@: -1}";then
	echo "ERROR: Evidence directory "$EVIDENCE_DIR" is not readable"
	exit 2
elif [ "$(find $(OutputDirectory) 2>/dev/null | wc -l)" -ge 2 ];then
	echo "ERROR: Output Directory "$(OutputDirectory)" is not empty"
	exit 3
else
	mkdir $(OutputDirectory) 2>/dev/null
fi

if ! [ -w $(OutputDirectory) ] ;then
	echo "ERROR: Directory "$(OutputDirectory)" is not writable"
	exit 4
fi

if test -z "$CASE_NO";then
	echo "ERROR: No case number supplied"
	exit 5
else
	GenerateWebReport
fi