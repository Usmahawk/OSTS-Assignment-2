#!/bin/bash

file="$1"
# Check if the argument is provided or not
if [[ -z $file ]]; then
    echo "Error CODE: No file provided"
    exit 1
fi

# Check if the file exists in the system
if [[ ! -f $file ]]; then
    echo "Error CODE: File not found: $file"
    exit 1
fi
#Sanity Check for date format
function DateFormatCheck {
	local date="$1"
	# Regular expression pattern for Month/Day/Year format
    local singledate=local singledate="^(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/[0-9]{4}$"
    
    # Regular expression pattern for Month/Day/Year-Month/Day/Year format
    local daterange="^(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/[0-9]{4}-(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/[0-9]{4}$"
    
    if [[ $date =~ $singledate || $date =~ $daterange ]]; then
        #echo "Date format is Month/Day/Year"
        return 0
    #elif [[ $date =~ $daterange ]]; then
    #	echo "Date format is Month/Day/Year RRRANGE"
    else
        #echo "Invalid date format"
        return 1
    fi	
}

#adding month and year
function ExtractMonthYear {
	local date="$1"
	local month
	local year
	
	if [[ $date =~ - ]]; then
		# Date range format (Month/Day/Year-Month/Day/Year)
		IFS=' -' read -r start_date _ <<< "$date"
		IFS='/' read -r month _ year <<< "$start_date"
	else
		# Single date format (Month/Day/Year)
		IFS='/' read -r month _ year <<< "$date"
	fi
	
	echo "$month $year"
}


function Pre_Processing_Type_of_Breach {
    local breach_type="$1"
    if [[ "$breach_type" =~ , ]]; then
        IFS=',' read -r first_part _ <<< "$breach_type"
        if [[ $first_part =~ / ]]; then
            IFS='/' read -r processed_first_part _ <<< "$first_part"
            echo "${processed_first_part}"       
        else
            echo "${first_part}"        
        fi
    elif [[ "$breach_type" =~ / ]]; then
        IFS='/' read -r first_part _ <<< "$breach_type"
        if [[ $first_part =~ , ]]; then
            IFS=',' read -r processed_first_part _ <<< "$first_part"
            echo "${processed_first_part}"       
        else
            echo "${first_part}"        
        fi       
    else
        echo "${breach_type}"
    fi
}

# Temporary file to store valid rows
valid_rows_file=$(mktemp)



# Read the file line by line 
# Store the header line in the valid rows file
head -n 1 "$file" | awk -F'\t' '{OFS="\t"; print $1, $2, $3, $4,"Month", "Year", $5}' >> "$valid_rows_file"

# Read the file line by line (excluding the header)
tail -n +2 "$file" | cut -f 1-$(($(awk -F '\t' '{print NF; exit}' "$file")-2)) "$file" | while IFS=$'\t' read -r -a fields; do

    Date_of_Breach="${fields[3]}"   

    if DateFormatCheck "$Date_of_Breach"; then

        month_year=$(ExtractMonthYear "$Date_of_Breach")
        read -r month year <<< "$month_year"

        # Modify the "Type_of_Breach" field
        type_of_breach="${fields[4]}"
        type_of_breach=$(Pre_Processing_Type_of_Breach "$type_of_breach")
        
        # Append the new column values (Month and Year) to the existing fields
        modified_fields=("${fields[@]:0:4}" "$type_of_breach" "$month" "$year" )
    	echo -e "${modified_fields[*]}" >> "$valid_rows_file"
    fi
    Date_of_Breach="${fields[3]}"
    


done 
# Print the contents of the valid rows file
cat "$valid_rows_file"






