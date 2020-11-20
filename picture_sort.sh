#!/bin/bash

# TODO check for files in origin folder and remove spaces

# Function that validates the input
validate_input () {

    if [[ ! "$delete_after_sort_tmp" == "T"* ]]
    then
        delete_after_sort=true

    elif [[ ! "$delete_after_sort_tmp" == "F"* ]]
    then

        delete_after_sort=false

    else

        echo "Bad value for 'delete_after_sort'. Setting the default value 'false'"

        delete_after_sort=false

    fi

    # If there are no medias
    if [ -z "$origin_folder_tmp" ]
    then
        echo "ERR: origin folder path does not exist"
    else
        origin_folder=$origin_folder_tmp
    fi

    destination_folder=$destination_folder_tmp

}

# Reading arguments
if [ $# -eq 0 ]
then

    echo "No arguments supplied"

    read -p 'Origin folder: ' origin_folder_tmp
    read -p 'Destionation folder: ' destination_folder_tmp
    read -p 'Delete after sort: ' delete_after_sort_tmp

    validate_input    

else

    while [ "$1" != "" ]
    do
        case "$1" in
            --origin) shift
                origin_folder_tmp=$1  
                # echo $origin_folder_tmp
                ;;
            --destination) 
                shift
                destination_folder_tmp=$1
                # echo $destination_folder_tmp
                ;;
            --delete) 
                shift
                delete_after_sort_tmp=$1
                # echo $delete_after_sort_tmp
                ;;
            *) echo "Bad arguments, please insert manually" 
                ./picture_sort.sh
                exit 0
                ;;
        esac
        shift 

    done

    validate_input

fi

# Folder on the computer that contains the backup
destination_main_path="/home/$USER/Pictures/${destination_folder}"
destination_raw_path="/RAW"

# Creating bck folder in computer
mkdir -p $destination_main_path

# Getting the file formats that interest me
img_ext="$(cat params.json | jq -r '.img_extensions')"
raw_ext="$(cat params.json | jq -r '.raw_extensions')"

# Removing special characters
img_ext_list="$(echo $img_ext | tr -d '\[\]\",')"
raw_ext_list="$(echo $raw_ext | tr -d '\[\]\",')"

# Splitting the list in an array
img_ext_array=' ' read -ra IMG_EXT_ARRAY <<< "$img_ext_list"
raw_ext_array=' ' read -ra RAW_EXT_ARRAY <<< "$raw_ext_list"

# Find command tail with all the find names
find_files=""

for extension in ${IMG_EXT_ARRAY[@]}
do
    find_files="$find_files -name \"*.${extension,,}\" -o"
    find_files="$find_files -name \"*.${extension^^}\" -o"
done

# Setting regex for raw files in later for cycle
raw_regex="["

for extension in ${RAW_EXT_ARRAY[@]}
do
    find_files="$find_files -name \"*.${extension,,}\" -o"
    find_files="$find_files -name \"*.${extension^^}\" -o"

    raw_regex="$raw_regex|${extension,,}|${extension^^}"

done

raw_regex="${raw_regex::-1}]"

# Removing last -o from string
find_files=${find_files::-2}

# echo $origin_folder
# echo $find_files

# Arrays with the files that interest me
#files=($(find "$origin_folder" -type f $($find_files 2> /dev/null)))

files=$(find "$origin_folder" -type f $($find_files 2> /dev/null))

# Copying images
for image in ${files[@]}
do

    image_data="$(ls -lit $image)"

    # Splitting the images string and gettin them in IMAGE_DATA_ARRAY
    image_data_array=' ' read -ra IMAGE_DATA_ARRAY <<< "$image_data"

    # Fixing the date of the folder

    file_year=""
    file_month=""
    file_day=""

    # Fixing day number
    if (( ${IMAGE_DATA_ARRAY[7]} < 10 ))
    then
        file_day=0${IMAGE_DATA_ARRAY[7]}
    else
        file_day=${IMAGE_DATA_ARRAY[7]}
    fi

    # Fixing month name
    case ${IMAGE_DATA_ARRAY[6]} in
        "gen") file_month_num="01" ; file_month="January" ;;
        "feb") file_month_num="02" ; file_month="February" ;;
        "mar") file_month_num="03" ; file_month="March" ;;
        "apr") file_month_num="04" ; file_month="April" ;;
        "mag") file_month_num="05" ; file_month="May" ;;
        "giu") file_month_num="06" ; file_month="June" ;;
        "lug") file_month_num="07" ; file_month="July" ;;
        "ago") file_month_num="08" ; file_month="August" ;;
        "set") file_month_num="09" ; file_month="September" ;;
        "ott") file_month_num="10" ; file_month="October" ;;
        "nov") file_month_num="11" ; file_month="November" ;;
        "dic") file_month_num="12" ; file_month="December" ;;
        *) echo "${IMAGE_DATA_ARRAY[6]}" ;;
    esac

    if [[ "${IMAGE_DATA_ARRAY[8]}" == *":"* ]]
    then
        file_year="$(date +%Y)" 
    else
        file_year=${IMAGE_DATA_ARRAY[8]}
    fi

    # echo $file_day
    # echo $file_month
    # echo $file_year

    # Dependinding on the type of file
    curr_file_folder="$destination_main_path/$file_year/$file_month_num $file_month/$file_day $file_month $file_year"

    if [[ "$image" =~ *".$raw_regex" ]]
    then
        curr_file_folder="$curr_file_folder$destination_raw_path"
    fi

    if [ ! -f "$curr_file_folder$image" ]
    then
    
        echo "Copying $image in "
        echo $curr_file_folder
        
        # Create directory if it does not exist
        mkdir -p "$curr_file_folder"

        # The -n prevents the file to be overwritten
        cp -n "$image" "$curr_file_folder"

        # if del variable set delete file from sd card
        if [ "$delete_after_copy" = true ] ; then
            echo "Deleting $image from origin folder"
            # rm $image
        fi

        echo ""

    fi

    done

echo "DONE!"
