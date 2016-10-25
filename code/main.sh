#!/bin/bash

# INFO --- - --- - --- - --- - --- - --- - --- - --- 
# Requirements: Pashua, Enable Access for Assistive devices for Terminal.app, ImageOptim App, JPEG Mini App (Registered), imageoptim CLI
# Setup: ssh keys, ImageOptim setting
# Input: folder of jpg Images
# Output: Related Items.csv, Enable.csv
# What it does: 

# TODOS 1.0 --- - --- - --- - --- - --- - --- - --- - --- 
# - X change order of checking with master & copying over
# - X 2016-09-27 Add checkbox for upload images
# - X 2016-09-27 Add override for r-agin skus
# - X 2016-09-28 Finished optim,
# - X 2016-09-28 Work on optim 
# - X Copy optim images to new directory so keywords aren't clobbered
# - X Put Cancel into a function
# - X Create a dialog to set up settings, add button to main 
# - X Read/Write from settings file
# - X Create while loop for settings

# TODOS 2.0 --- - --- - --- - --- - --- - --- - --- - ---

# - Use Associative arrays to match files with their suffixes
# - Create check for blank meta data
# - Check on imageoptim app settings, make sure strip data is off
# - Alert if D, but no H & vice versa is found
# - Check for recursive folders and warn
# - Add check for "optimized" folder already existing
# - remove any .DS_Store files

# Check how app was launched:
#		- Raw Open
#		- Items Open
#			- Folder Open
#			- Images Open
#				- Ask for more images

#cleanup
# TODOS POST PROJECT --- - --- - --- - --- - --- - --- - --- - ---

# - Store Pashua stuff in codebox

# PROGRESS --- - --- - --- - --- - --- - --- - --- - ---

# 2016-09-26 Added framework for yes/no
# 2016-09-27 Made the yes no dialog, separated pashua configs out into source, added info text to pashua, separated pashuamodal into functions
# 2016-09-28 Finished optim
# 2016-09-29 Started finishing up main functionality, moving to sub.
# 2016-10-05 Started settings modal, researched r/w settings securely.
# 2016-10-06 Finished beta csv_products, Started upload. Can only use sftp, no rsync/ssh. Will need to upload to sub folder, then mv files. (potential workaround with fuse: http://link.hagu.re/2e7hrOB)
# 2016-10-07 Cleaned up code. (went in & upgraded ram, not a lot of work today)
# 2016-10-10 Researched sftp stuff, Researched settings stuff, worked on Simple Cust stuff
# 2016-10-11 Separated output into different folder by variable, Finished upload, started settings r/w
# 2016-10-20 Finished Settings r/w, started final 1.0 testing

# NOTES --- - --- - --- - --- - --- - --- - --- - ---

# SAVEDIR/EXPORTDIR(Date)/optimized

# --- - --- - --- - --- - --- - --- - --- - --- INITIALIZE 

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CD="$HOME/Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog"
#DATEC=$(date +"%Y-%m-%dT%H%M")
DATEC=$(date +"%Y-%m-%d")
THEDATE=$DATEC

if [ -z "$1" ]
then
	IMAGEDIR="/Volumes/Kool-Aid Man/WorkBox/Work-Inbox/FG-Image-Upload-Tool/sandbox/example"
else
	IMAGEDIR="$1"
fi
echo "IMAGEDIR = $IMAGEDIR"

# --- - --- - --- - --- - --- - --- - --- - --- INCLUDES

# Include pashua.sh to be able to use the 2 functions defined in that file
source "$MYDIR/pashua.sh"

# --- - --- - --- - --- - --- - --- - --- - --- FUNCTIONS

cleanup() {
	rm ./temp_*.txt
	rm ./alt_text.csv
}

pashua_start() {
	if [ -d '/Volumes/Pashua/Pashua.app' ]
	then
		# Looks like the Pashua disk image is mounted. Run from there.
		customLocation='$HOME/Applications/Pashua'
	else
		# Search for Pashua in the standard locations
		customLocation=''
	fi
	pashua_run "$1" "$customLocation"
}

pashua_newline_convert() {
	input="$1"
	awk 1 ORS='[return]' "$input"
	return
}

# --- - --- - --- - --- - --- - --- - --- - --- MODAL DIALOG FUNCTIONS

continuemodal() {
	# Import source of config continue
	# xxx Todo Convert $input into Pashua readable format
	#input=$(cat $1)
	title="$1"
	input="$2"
	source "$MYDIR/pashua_config_continue.sh"
	pashua_start "$pashua_config_continue"
	
	# [CANCEL] Button pressed
	if [ $cb == 1 ]; then
		echo -e "\nｐｒｏｇｒａｍ　ｔｅｒｍｉｎａｔｅｄ"
		exit
	fi 
}

mainmodal() {
	
	# --- - --- - --- - --- - --- - --- - --- - --- READ SETTINGS
	settings_read 
	
	title="$1"
	source "$MYDIR/pashua_config_main.sh"
	pashua_start "$pashua_config_main"
	
	#--- - --- - --- - --- - --- - --- - --- - --- ECHO PASHUA VARS
	echo " --- - --- - --- "
	echo -e "Pashua variables:\n"
	echo "  imgdir = $imgdir"
	echo " --- - --- - --- "
	echo "  pathlist = $pathlist"
	echo "  filelist = $filelist"
	echo "  skulist = $skulist"
	echo " --- - --- - --- "
	echo "  agin = $agin"
	echo " --- - --- - --- "
	echo "  optimize = $optimize"
	echo "  master = $master"
	echo "  upload = $upload"
	echo " --- - --- - --- "
	echo "  alttext = $alttext"
	echo "  cpi = $cpi"
	echo "  products  = $products"
	echo " --- - --- - --- "
	echo "  cb = $cb"
	echo "  sb = $sb"
	echo "  db = $db"
	echo -e " --- - --- - --- \n"
	#--- - --- - --- - --- - --- - --- - --- - ---
	# CANCEL
	if [ $cb == 1 ]; then
		echo "ｐｒｏｇｒａｍ　ｔｅｒｍｉｎａｔｅｄ"
		exit
	fi 
	#--- - --- - --- - --- - --- - --- - --- - ---
	# SETTINGS
	if [ $sb == 1 ]; then
		echo "ｏｐｅｎｉｎｇ　ｓｅｔｔｉｎｇｓ"
		settingsmodal "Settings"
		exit
	fi
	
	#--- - --- - --- - --- - --- - --- - --- - ---
	# PROCESS FILES

	if [ $db == 1 ]; then
		echo -e "ｒｕｎ　ｔｈｅ　ｊｅｗｅｌｓ\n"
		processfiles
	fi 

}

settingsmodal() {
	
	# --- - --- - --- - --- - --- - --- - --- - --- READ SETTINGS
	settings_read 
	
	title="$1"
	input="$2"
	source "$MYDIR/pashua_config_settings.sh"
	pashua_start "$pashua_config_settings"
	
	echo " --- - --- - --- "
	echo -e "Pashua Settings variables:\n"
	echo "  masterdir = $masterdir"
	echo "  savedir = $savedir"
	echo " --- - --- - --- "
	echo "  serverip = $serverip"
	echo "  serveruser = $serveruser"
	echo "  serverpath = $serverpath"
	echo " --- - --- - --- "
	echo "  cb = $cb"
	echo "  sb = $sb"
	echo "  db = $db"
	echo -e " --- - --- - --- \n"
	
	if [ $db == 1 ]; then 
		settings_write
	fi
	
	#--- - --- - --- - --- - --- - --- - --- - ---
	# CANCEL

	if [ $cb == 1 ]; then
		echo "ｓｅｔｔｉｎｇｓ　ｕｎｃｈａｎｇｅｄ"
	fi 

	mainmodal "Finished Goods Image Processor BETA"
}

# --- - --- - --- - --- - --- - --- - --- - --- SETTINGS FUNCTIONS

settings_read() {
	# xxx If settings file doesn't exist
	# Write Default
		configfile="$HOME/.fg_uploader.conf"
		configfile_secured='/tmp/cool.cfg'

		# check if the file contains something we don't want
		if egrep -q -v '^#|^[^ ]*=[^;]*' "$configfile"; then
			echo "Config file is unclean, cleaning it..." >&2
			# filter the original to a new file
			egrep '^#|^[^ ]*=[^;&]*'  "$configfile" > "$configfile_secured"
			configfile="$configfile_secured"
		fi

		# now source it, either the original or the filtered variant
		source "$configfile"

		echo -e "\nReading Settings file at: $configfile\n"
		
		# --- - --- - --- - --- - --- - --- - --- - --- VARIABLES
		
		EXPORTDIR="$SAVEDIR/$THEDATE"
		OPTIMIZEDIR="$EXPORTDIR/optimized"
		
		echo "SAVEDIR: $SAVEDIR"
		echo "MASTERDIR: $MASTERDIR"
		echo "SERVER_USER: $SERVER_USER"
		echo "SERVER_IP: $SERVER_IP"
		echo "SERVER_PATH_IMAGES: $SERVER_PATH_IMAGES"

		echo -e "\n…Done Reading Settings.\n"

		echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
		
}

settings_write() {
	echo " --- - --- - --- "
	echo -e "Pashua Settings variables:\n"
	echo "  masterdir = $masterdir"
	echo "  savedir = $savedir"
	echo " --- - --- - --- "
	echo "  serverip = $serverip"
	echo "  serveruser = $serveruser"
	echo "  serverpath = $serverpath"
	echo " --- - --- - --- "
	echo "  cb = $cb"
	echo "  db = $db"
	echo -e " --- - --- - --- \n"
	echo "ｓｅｔｔｉｎｇｓ　ｓａｖｅｄ"
	
	configfile="$HOME/.fg_uploader.conf"
	configfilebackup="$HOME/.fg_uploader.bak"
	
	mv "$configfile" "$configfilebackup"
	echo -e "# Settings for FG Image Uploader by Terry McCall" > $configfile
	echo "MASTERDIR=\"$masterdir\"" >> $configfile
	echo "SAVEDIR=\"$savedir\"" >> $configfile
	echo "SERVER_IP=\"$serverip\"" >> $configfile
	echo "SERVER_USER=\"$serveruser\"" >> $configfile
	echo "SERVER_PATH_IMAGES=\"$serverpath\"" >> $configfile
}

# --- - --- - --- - --- - --- - --- - --- - --- PROCESS: MAIN FUNCTION

processfiles() {
	# --- - --- - --- - --- - --- - --- - --- - --- TEMP FILE SETUP
	
	mkdir "$EXPORTDIR"
	
	if [ $pathlist -eq 1 ] || [ $filelist -eq 1 ] || [ $skulist -eq 1 ]; then 
		echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
		echo "    TEMP FILE GENERATION"
		echo -e "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
	fi

	# Generate Path List File

	if [ $pathlist -eq 1 ]; then
		pathlist "$IMAGEDIR"
	fi

	# Generate File List File
	if [ $filelist -eq 1 ]; then
		filelist "$IMAGEDIR"
	fi

	# Generate SKU List File
	if [ $skulist -eq 1 ]; then
		skulist "$IMAGEDIR"
	fi

echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
	echo "    FILE NAME VALIDATION"
	echo -e "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"


	# --- - --- - --- - --- - --- - --- - --- - --- CHECK FILENAMES

	# Check Agin SKU
	if [ $agin -eq 1 ]; then
		aginname "$IMAGEDIR"
	fi

	# Check for Duplicate File names
	#if [ $same -eq 1 ]; then
	#	samename "$IMAGEDIR"
	#fi

	# --- - --- - --- - --- - --- - --- - --- - --- IMAGE PROCESSING

	if [ $optimize -eq 1 ] || [ $master -eq 1 ] || [ $upload -eq 1 ]; then 
		echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
		echo "    IMAGE PROCESSING"
		echo -e "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
	fi

	# Optimize Images
	if [ $optimize -eq 1 ]; then
		echo "uncomment for real optimization"
		optimize "$IMAGEDIR"
	fi

	# Copy Images to Master ƒ
	if [ $master -eq 1 ]; then
		copy_to_master "$IMAGEDIR"
	fi

	#--- - --- - --- - --- - --- - --- - --- - --- UPLOAD IMAGES

	if [ $upload -eq 1 ]; then
		if [ $optimize -eq 1 ]
		then
			echo -e "Using Optimized Images…\n"
			upload "$OPTIMIZEDIR"
		else
			echo -e "Using Original Images…\n"
			upload "$IMAGEDIR"
		fi
	fi

	# --- - --- - --- - --- - --- - --- - --- - --- GENERATE DATA CSV

	if [ $alttext -eq 1 ] || [ $cpi -eq 1 ] || [ $products -eq 1 ]; then 
		echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
		echo "    DATA CSV FILE GENERATION"
		echo -e "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
	fi

	# Generate alt_text.csv
	if [ $alttext -eq 1 ]; then
		csv_alttext "$IMAGEDIR"
	fi

	# Generate cpi.csv
	if [ $cpi -eq 1 ]; then
		csv_cpi "$EXPORTDIR/alt_text.csv"
	fi

	# Generate products.csv
	if [ $products -eq 1 ]; then
		csv_products "$EXPORTDIR/temp_skulist.txt"
	fi

	echo -e "All done! Double check the images & data files, then use urapidflow for the upload."

	#√ csv_enabled "$EXPORTDIR/temp_skulist.txt"

	#--- - --- - --- - --- - --- - --- - --- - ---

	#√ samename "$IMAGEDIR"

	#√ csv_alttext "$IMAGEDIR"


	#csv_cpi "./alt_text.csv"
	#csv_products "$IMAGEDIR"
	#√ csv_enabled "./temp_skulist.txt"
}

# --- - --- - --- - --- - --- - --- - --- - --- PROCESS: TEMP FILE FUNCTIONS

pathlist() {
	if [ -z "$1" ]                           # Is parameter #1 zero length?
		then
			echo "Need a directory"  # No folder was chosen
		else
			dirname=$1
		fi
		variable=${1-$DEFAULT}       
		if [ "$2" ]
		then
			echo "There's a space in my boot"
		fi
		echo -e $"\nGenerating temp_pathlist.txt…\n"
		tempfile="$EXPORTDIR/temp_pathlist.txt"
		find "$dirname" -type f > "$tempfile"
		cat "$tempfile"
		echo -e "\n…Done Generating temp_pathlist.txt.\n\n--- --- --- --- --- --- ---\n"
}

filelist() {
	if [ -z "$1" ]                           # Is parameter #1 zero length?
		then
			echo "Need a directory"  # No folder was chosen
		else
			dirname=$1
		fi
		variable=${1-$DEFAULT}                   
		if [ "$2" ]
		then
			echo "There's a space in my boot"
		fi
		echo -e $"Generating temp_filelist.txt…\n"
		tempfile="$EXPORTDIR/temp_filelist.txt"
		find "$dirname" -type f | sed 's!.*/!!' | sort  > "$tempfile"
		cat "$tempfile"
		echo -e "\n…Done Generating temp_filelist.txt.\n\n--- --- --- --- --- --- ---\n"
}

skulist() {
# Prints out & exports a list of  skus as taken from the filenames

	if [ -z "$1" ]                           # Is parameter #1 zero length?
		then
			echo "Need a directory"  # No folder was chosen
		else
			dirname=$1
		fi
		variable=${1-$DEFAULT}                   
	#	echo "variable = $variable"              
		if [ "$2" ]
		then
			echo "There's a space in my boot"
		fi
		echo -e $"Generating temp_skulist.txt…\n"
		tempfile="$EXPORTDIR/temp_skulist.txt"
		find "$dirname" -type f | sed -e 's_.*/__' -e 's/.jpg//' -e 's/_.*//' | sort | uniq > "$tempfile"
		cat "$tempfile"
		echo -e "\n…Done Generating temp_skulist.txt.\n"
}

# --- - --- - --- - --- - --- - --- - --- - --- PROCESS: DATA VALIDATION FUNCTIONS

aginname() {
	# Prints Lists of files that have the Agin SKU format (7 digits). 
	# REQUIRES generation of "temp_pathlist.txt"
		if [ -z "$1" ]                           # Is parameter #1 zero length?
		then
			echo "Need a directory"  # No folder was chosen
		else
			dirname=$1
		fi
		variable=${1-$DEFAULT}                   
	#	If there's two variables aka a space
		if [ "$2" ]
		then
			echo "There's a space in my boot"
		fi
	#	do the thing
		echo -e "Checking for R-AGIN Skus…\n"
		tempfile="$EXPORTDIR/temp_agin.txt"
		
		cat ./temp_pathlist.txt | sed 's_.*/__' | sort | grep '\d\{7\}' > "$tempfile"
		echo -e "\n…Done Checking for R-AGIN Skus.\n\n"
		
	#	Print Result
		if [ -s "$tempfile" ]
		then
			echo "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
			echo "    WARNING: POTENTIAL AGIN SKUS FOUND…"
			echo "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
			cat "$tempfile"
			echo "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
			continuemodal "R-AGIN Skus were found. Continue?"
		else
			echo "No R-AGIN Skus found."
		fi
	}

samename() {
# Prints Lists of files that have the same name
	if [ -z "$1" ]                           # Is parameter #1 zero length?
	then
		echo "Need a directory"  # No folder was chosen
	else
		dirname=$1
	fi
	variable=${1-$DEFAULT}                   
	if [ "$2" ]
	then
		echo "There's a space in my boot"
	fi
	tempfile="$EXPORTDIR/temp_same.txt"
	find "$dirname" -type f  > "$tempfile"
	cat "$tempfile" | sed 's_.*/__' | sort > "$tempfile" 
	while read fileName
	do
	 grep "$fileName" "$tempfile"
	done
	#rm -f tempfile
	echo -e "\n…Done Checking for Same Filenames.\n\n--- --- --- --- --- --- ---\n"
}

# --- - --- - --- - --- - --- - --- - --- - --- PROCESS: IMAGE FUNCTIONS

optimize() {
	echo -e "Starting Image Optimization…\n"
	
	if [ -z "$1" ]		# Is parameter #1 zero length?
		then
			echo "Need a directory"  # No folder was chosen
		else
			dirname=$1
	fi
#	If there's two variables aka a space
	if [ "$2" ]
	then
		echo "There's a space in my boot"
	fi
	#	do the thing	
	tempfile="$EXPORTDIR/temp_optimize.txt"
	# Create ./optimized Directory in $EXPORTDIR
	echo -e "Creating folder for optimized images…\n"
	mkdir "$EXPORTDIR/optimized"
	echo -e "\n…Done Creating folder for optimized images.\n"
	echo "\n--- --- --- --- --- --- ---\n"
	# Copy Images to ./optimized
	echo -e "\nCopying images to optimized folder…\n"
	cp -v "$dirname"/* "$EXPORTDIR/optimized"
	echo -e "\n…Done Copying images to optimized folder.\n"
	echo "\n--- --- --- --- --- --- ---\n"
	# Optimize images with imageoptim
	echo -e "\nOptimizing Images…\n"
	imageoptim --verbose -j -q -d "$EXPORTDIR/optimized"
	echo -e "\n…Done Optimizing Images.\n"
	echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
}

copy_to_master() {
# Copies files in $SOURCE ƒ to $DESTINATION, without overwriting any files, and listing output to ./temp.txt
	echo -e "Copying to Master Folder…\n"
	if [ -z "$1" ]                           # Is parameter #1 zero length?
		then
			echo "Need a directory"  # No folder was chosen
		else
			dirname=$1
	fi
	variable=${1-$DEFAULT}                   
#	If there's two variables aka a space
	if [ "$2" ]
	then
		echo "There's a space in my boot"
	fi

	#	do the thing	
	tempfile="$EXPORTDIR/temp_master.txt"
	
	cp -Rnv "$dirname"/ "$MASTERDIR" > "$EXPORTDIR/temp_master_record.txt"
	cat "$EXPORTDIR/temp_master_record.txt" | grep '.*not overwritten$' | sed -e 's/.*\///' -e 's/ not overwritten//' > "$tempfile"
	echo -e "\n…Done Copying to Master Folder.\n"
	echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
	#	Print Result
	if [ -s "$tempfile" ]
	then
		warning="    WARNING: THESE FILES ALREADY EXIST IN MASTER FOLDER…"
		echo -e "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
		echo "$warning"
		echo "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
		cat "$tempfile"
		continuemodal "$warning" $(pashua_newline_convert "$tempfile")
		echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
	else
		echo "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
		echo "    FINISHED COPYING TO MASTER FOLDER…"
		echo "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---"
	fi
}

upload() {
# Takes in the Image Directory, and uploads it to the Live server using the credentials set in settings.
	#SERVER_PATH_IMAGES="feeds/urapidflow/import/images"
	echo -e "Generating temp_sftp_batch.txt…\n"

	if [ -z "$1" ]	# Is parameter #1 zero length?
		then
			echo "Need a directory"  # No folder was chosen
		else
			dirname=$1
	fi
	if [ "$2" ]		#	If there's two variables aka a space
	then
		echo "There's a space in my boot"
	fi
	#	do the thing	
	tempfile="$EXPORTDIR/temp_upload.txt"
	batchfile="$EXPORTDIR/temp_sftp_batch.txt"
	
	# Create the batchfile for sftp
	#echo "cd archive" >> "$batchfile"
	#echo "mkdir $THEDATE" >> "$batchfile"
	#echo "cd $THEDATE" >> "$batchfile"
	echo "lcd '$dirname'" >> "$batchfile"
	for files in $(ls -1 "$dirname");
	do
		echo "put $files" >> "$batchfile"
	done
	echo "quit" >> "$batchfile"
	
	echo "--- - --- - ---"
	echo -e "\nUploading Images…\n"
	
	sftp -b "$batchfile" "$SERVER_USER@$SERVER_IP:$SERVER_PATH_IMAGES" 2> "$EXPORTDIR/temp_sftp_errors.txt"
	
	echo -e "\n…Done Uploading Images.\n"
}

# --- - --- - --- - --- - --- - --- - --- - --- PROCESS: DATA GENERATION FUNCTIONS

csv_alttext() {
	echo -e "Generating alt_text.csv…\n"
	if [ -z "$1" ]      # Is parameter #1 zero length?
		then
			echo "Need a directory"  # No folder was chosen
		else
			dirname=$1
	fi
#	If there's two variables aka a space
	if [ "$2" ]
	then
		echo "There's a space in my boot"
	fi
	#	do the thing	
	tempfile="$EXPORTDIR/temp_csv_alttext.txt"
	outputfile="$EXPORTDIR/alt_text.csv"
	exiftool -csv -T -filename -keywords "$dirname" > "$outputfile"
	cat "$outputfile"
	echo -e "\n…Done generating alt_text.csv."
	echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
}

csv_cpi() {
	# Takes in "alt_text.csv" as input, and uses it to create CPI fixed row format spreadsheet, which is used in uRapidflow to associate images with products. 
	#	# CPI,sku,image name,image label,position
	#	Use position 1 for default, position 2 for alternates
	#	Use awk to rename columns:
		# - FileName > image name
		# - Keywords > image label
	#	Use awk to add columns:
	#		- #CPI
	#		- #sku
	#		- #position
	#	Calculated Columns
	#		- sku (taken from image name)
	#		 - position (if filename has d, then 1, else 2)
	
	# Copy input to "cpi.csv"
	echo -e "Generating cpi.csv…\n"
	tempfile="$EXPORTDIR/temp_cpi.txt"
	outputfile="$EXPORTDIR/cpi.csv"
	cp "$1" "$tempfile"
	awk 'BEGIN{FS=",";OFS="";}{sub(/^.*\//, "", $1); sub(/\.jpg/, "", $1); sub(/_.*/, "", $1); print "CPI" FS $1  FS $2 FS $3 FS,($2~/.*d/)?"1":"2"}' "$tempfile" | sed -e '1d' > "$outputfile"

	echo -e "#CPI,sku,image name,image label,position\n$(cat "$outputfile")" > "$outputfile"
	cat "$outputfile"
	echo -e "\n…Done Generating cpi.csv."
	echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
}

csv_products() {
#	11. Create product update import spreadsheet to assign image roles. Search for "d" and "h" in the image folder using Finder
#	sku,image,small_image,thumbnail,hover
#	Use default image path for all except hover
#	Use hover image path for hover
#	Confirm that default images line up with hover images
	
	# Create 4 columns of skulist
	echo -e "Generating products.csv…\n"
	tempfile="$EXPORTDIR/temp_products.txt"
	outputfile="$EXPORTDIR/products.csv"
	# Can probably be rolled into awk
	lam "$EXPORTDIR/temp_skulist.txt" -s "," "$EXPORTDIR/temp_skulist.txt" -s "," "$EXPORTDIR/temp_skulist.txt" -s "," "$EXPORTDIR/temp_skulist.txt" -s "," "$EXPORTDIR/temp_skulist.txt" > "$tempfile"
	awk 'BEGIN{FS=",";OFS=",";}{$2 = $2 "_d.jpg";$3 = $3 "_d.jpg";$4 = $4 "_d.jpg";$5 = $5 "_g1h.jpg";$6 = "enabled"; print}' "$tempfile" | sed -e '1d' > "$outputfile"
	echo -e "sku,image,small_image,thumbnail,hover,status\n$(cat "$outputfile")" > "$outputfile"
	cat "$outputfile"
	echo -e "\n…Done Generating products.csv."

echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
}

csv_enabled() {
#	13. Create product update import spreadsheet to activate successfully loaded products
#	Format: sku,status(enabled)
	cat "$1" | sed 's/$/,enabled/' "$1" > products.csv
	echo -e "sku,status\n$(cat products.csv)" > products.csv
	echo -e "\n…Done Generating products.csv.\n"
	echo -e "\n--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n"
}

# --- - --- - --- - --- - --- - --- - --- - ---
# --- - --- - --- - --- - --- - --- - --- - --- MAIN
# --- - --- - --- - --- - --- - --- - --- - ---

mainmodal "Finished Goods Image Processor BETA"

# --- - --- - --- - --- - --- - --- - --- - --- CLEAN UP & EXIT
